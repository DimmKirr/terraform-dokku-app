# Local values for database operations
locals {
  # Get unique database types to install plugins for
  database_types = toset([for k, v in var.databases : v.type])
}

# Install database plugin for each unique database type
# Requires root_ssh_user to be configured in the provider
resource "dokku_plugin" "database" {
  for_each = local.database_types

  name = each.value
  url  = lookup(var.database_plugin_urls, each.value)
}

# Create database services using unified dokku_db resource
# Supports all database types through the plugin parameter
# Storage is configured inline, no need for separate null_resource
resource "dokku_db" "this" {
  for_each = var.databases

  plugin       = each.value.type
  service_name = local.database_names[each.key]
  image        = each.value.version != null ? "${each.value.type}:${each.value.version}" : null

  # Configure storage if specified
  # The storage map key is arbitrary (using "data" as convention)
  # host_path can be omitted (defaults to {service_name}-data),
  # relative (stored under /var/lib/dokku/data/storage/), or absolute
  storage = each.value.storage != null ? {
    data = {
      host_path  = each.value.storage.host_path
      mount_path = each.value.storage.mount_path
    }
  } : null

  depends_on = [dokku_plugin.database]
}

# Link database services to app using unified dokku_db_link resource
# Works with all database types through the plugin parameter
resource "dokku_db_link" "this" {
  for_each = var.databases

  plugin       = dokku_db.this[each.key].plugin
  app_name     = dokku_app.this.app_name
  service_name = dokku_db.this[each.key].service_name

  depends_on = [
    dokku_db.this,
    dokku_app.this
  ]
}
