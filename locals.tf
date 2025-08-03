locals {
  # If app subdomain is enabled we create a subdomain for the app as well
  domains = var.enable_app_subdomain ? concat(["${var.name}.${var.root_domain}"], var.domains) : var.domains
  storage = {
    data = {
      mount_path = var.data_dir
    }
  }
}
