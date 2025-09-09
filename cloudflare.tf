resource "cloudflare_dns_record" "app_record" {
  for_each = var.manage_cloudflare ? toset(local.domains) : toset([])
  zone_id  = data.cloudflare_zone.this.zone_id
  comment  = "${each.value} host"
  content  = var.node_ip_address
  name     = each.value
  proxied  = var.dns_record_proxied

  ttl  = var.dns_record_ttl
  type = "A"
}

resource "cloudflare_page_rule" "http_to_https" {
  for_each = var.manage_cloudflare && var.manage_https_redirect ? toset(local.domains) : toset([])

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


resource "cloudflare_dns_record" "dns_records" {
  for_each = var.manage_cloudflare ? { for idx, record in var.dns_records : idx => record } : {}
  zone_id  = data.cloudflare_zone.this.zone_id
  comment  = "${var.name} DNS Record"
  content  = each.value.content
  name     = each.value.name
  proxied  = each.value.proxied
  priority = try(each.value.priority, null)
  ttl      = each.value.ttl
  type     = each.value.type
}
