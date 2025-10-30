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

# Generate private key for Origin CA certificate
resource "tls_private_key" "origin_ca" {
  count     = var.manage_cloudflare && var.manage_origin_certificate ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create certificate signing request
resource "tls_cert_request" "origin_ca" {
  count           = var.manage_cloudflare && var.manage_origin_certificate ? 1 : 0
  private_key_pem = tls_private_key.origin_ca[0].private_key_pem

  subject {
    common_name  = local.domains[0]
    organization = var.name
  }

  dns_names = local.domains
}

# Cloudflare Origin CA Certificate for Dokku app
resource "cloudflare_origin_ca_certificate" "app" {
  count              = var.manage_cloudflare && var.manage_origin_certificate ? 1 : 0
  csr                = tls_cert_request.origin_ca[0].cert_request_pem
  hostnames          = local.domains
  request_type       = "origin-rsa"
  requested_validity = var.origin_certificate_validity_days
}

# Set SSL mode to Full (strict) when using Origin CA certificate
resource "cloudflare_zone_setting" "ssl_mode" {
  count      = var.manage_cloudflare && var.manage_origin_certificate ? 1 : 0
  zone_id    = data.cloudflare_zone.this.zone_id
  setting_id = "ssl"
  value      = "strict"
}
