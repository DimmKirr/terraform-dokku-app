resource "cloudflare_dns_record" "this" {
  for_each = toset(local.domains)
  zone_id  = data.cloudflare_zone.this.zone_id
  comment  = "${each.value} host"
  content  = var.node_ip_address
  name     = each.value
  proxied  = var.dns_record_proxied

  ttl  = var.dns_record_ttl
  type = "A"
}

resource "cloudflare_page_rule" "http_to_https" {
  for_each = toset(local.domains)
  zone_id  = data.cloudflare_zone.this.zone_id
  target   = "http://${each.value}/*"
  actions = {
    forwarding_url = {
      url         = "https://${each.value}/$1"
      status_code = 301
    }
  }
  priority = 1
}
