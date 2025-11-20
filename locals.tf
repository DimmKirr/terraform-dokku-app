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
}
