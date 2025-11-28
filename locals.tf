locals {
  # If app subdomain is enabled we create a subdomain as well, otherwise we just pass a list of domains
  domains = var.manage_subdomain ? concat(["${var.name}.${var.root_domain}"], var.domains) : var.domains

  # Storage logic: custom storage → use it, storage_enabled → use default, else → null
  storage = var.storage != null ? var.storage : (
    var.storage_enabled ? {
      (var.name) = {
        mount_path = "/data"
      }
    } : null
  )

  # Auto-generate database names from app name + database key
  database_names = {
    for k, v in var.databases : k => "${var.name}-${k}"
  }

  # Generate storage paths for databases with storage configured
  database_storage_paths = {
    for k, v in var.databases :
    k => v.storage != null ? {
      host_path = coalesce(
        v.storage.host_path,
        "/var/lib/dokku/data/storage/${var.name}-${k}"
      )
      mount_path = v.storage.mount_path
    } : null
  }
}
