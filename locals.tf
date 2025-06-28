locals {
  domains = concat(["${var.name}.${var.root_domain}"], var.extra_domains)
}
