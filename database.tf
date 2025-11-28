# Local values for database operations
locals {
  # Get unique database types to install plugins for
  database_types = toset([for k, v in var.databases : v.type])
}

# Install database plugin for each unique database type
resource "null_resource" "database_plugin" {
  for_each = local.database_types

  triggers = {
    database_type = each.value
  }

  connection {
    host        = var.host
    user        = var.ssh_root_user # Plugin installation requires root
    private_key = var.ssh_private_key
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "dokku plugin:install ${lookup(var.database_plugin_urls, each.value)} ${each.value} || echo 'Plugin ${each.value} already installed'"
    ]
  }
}

# Create each database service
resource "null_resource" "database_service" {
  for_each = var.databases

  triggers = {
    database_name    = local.database_names[each.key]
    database_type    = each.value.type
    database_version = try(each.value.version, "")
    # Trigger recreation if config changes (use hash to avoid map ordering issues)
    database_config = md5(jsonencode(each.value.config))
  }

  connection {
    host        = var.host
    user        = var.ssh_user # Regular dokku command
    private_key = var.ssh_private_key
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        # Build create command with version and config flags
        CREATE_CMD="dokku ${each.value.type}:create ${local.database_names[each.key]}"

        # Add version if specified
        if [ -n "${try(each.value.version, "")}" ]; then
          CREATE_CMD="$CREATE_CMD --image-version ${each.value.version}"
        fi

        # Add additional config flags
        %{for k, v in each.value.config~}
        CREATE_CMD="$CREATE_CMD --${k} '${v}'"
        %{endfor~}

        # Execute (idempotent - fails gracefully if exists)
        echo "Executing: $CREATE_CMD"
        $CREATE_CMD || echo 'Database ${local.database_names[each.key]} already exists'
      EOT
    ]
  }

  depends_on = [
    null_resource.database_plugin,
    dokku_app.this
  ]
}

# Mount storage for databases (if configured)
resource "null_resource" "database_storage_mount" {
  for_each = {
    for k, v in local.database_storage_paths : k => v
    if v != null
  }

  triggers = {
    database_name = local.database_names[each.key]
    host_path     = each.value.host_path
    mount_path    = each.value.mount_path
  }

  connection {
    host        = var.host
    user        = var.ssh_root_user # Needs root for chown and mkdir in /var/lib/dokku
    private_key = var.ssh_private_key
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      # Create host directory with appropriate permissions
      "mkdir -p ${each.value.host_path}",
      "chown -R dokku:dokku ${each.value.host_path}",
      # Mount storage to database service
      "dokku storage:mount ${var.databases[each.key].type}.${local.database_names[each.key]} ${each.value.host_path}:${each.value.mount_path} || echo 'Storage already mounted'",
      # Rebuild database container to apply mount
      "dokku ps:rebuild ${var.databases[each.key].type}.${local.database_names[each.key]} || echo 'Rebuild skipped or already running'"
    ]
  }

  depends_on = [
    null_resource.database_service
  ]
}

# Link each database to app
# This sets environment variables like MONGO_URL, DATABASE_URL, REDIS_URL, etc.
resource "null_resource" "database_link" {
  for_each = var.databases

  triggers = {
    database_name = local.database_names[each.key]
    app_name      = dokku_app.this.app_name
    # Force relink if database service changes
    database_service_id = null_resource.database_service[each.key].id
  }

  connection {
    host        = var.host
    user        = var.ssh_user # Regular dokku command
    private_key = var.ssh_private_key
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "dokku ${each.value.type}:link ${local.database_names[each.key]} ${dokku_app.this.app_name} || echo 'Database already linked'"
    ]
  }

  depends_on = [
    null_resource.database_storage_mount,
    null_resource.database_service,
    dokku_app.this
  ]
}
