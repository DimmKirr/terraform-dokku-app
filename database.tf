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
    user        = "root" # Plugin installation requires root
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
    database_name    = each.value.name
    database_type    = each.value.type
    database_version = try(each.value.version, "")
    # Trigger recreation if config changes (use hash to avoid map ordering issues)
    database_config = md5(jsonencode(each.value.config))
  }

  connection {
    host        = var.host
    user        = "root" # Database creation requires root
    private_key = var.ssh_private_key
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        # Build create command with version and config flags
        CREATE_CMD="dokku ${each.value.type}:create ${each.value.name}"

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
        $CREATE_CMD || echo 'Database ${each.value.name} already exists'
      EOT
    ]
  }

  depends_on = [
    null_resource.database_plugin,
    dokku_app.this
  ]
}

# Link each database to app
# This sets environment variables like MONGO_URL, DATABASE_URL, REDIS_URL, etc.
resource "null_resource" "database_link" {
  for_each = var.databases

  triggers = {
    database_name = each.value.name
    app_name      = dokku_app.this.app_name
    # Force relink if database service changes
    database_service_id = null_resource.database_service[each.key].id
  }

  connection {
    host        = var.host
    user        = "root"
    private_key = var.ssh_private_key
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "dokku ${each.value.type}:link ${each.value.name} ${dokku_app.this.app_name} || echo 'Database already linked'"
    ]
  }

  depends_on = [
    null_resource.database_service,
    dokku_app.this
  ]
}
