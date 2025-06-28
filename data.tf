data "cloudflare_zone" "this" {
  filter = {
    name = var.root_domain
  }
}

data "cloudflare_ip_ranges" "this" {
  networks = "networks"
}
