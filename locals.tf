locals {
  # If app subdomain is enabled we create a subdomain as well, otherwise we just pass a list of domains
  domains = var.manage_subdomain ? concat(["${var.name}.${var.root_domain}"], var.domains) : var.domains
  storage = {
    data = {
      mount_path = var.data_dir
    }
  }
}
