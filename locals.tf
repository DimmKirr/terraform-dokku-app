locals {
  # If app subdomain is enabled we create a subdomain as well, otherwise we just pass a list of domains
  domains = var.manage_subdomain ? concat(["${var.name}.${var.root_domain}"], var.domains) : var.domains

  # Use custom storage if provided, otherwise use default storage based on data_dir
  storage = var.storage != null ? var.storage : {
    "${var.data_dir}/${var.name}" = {
      mount_path = "/data"
    }
  }
}
