output "fqdn" {
  value = "${var.name}.${var.root_domain}" # likely insufficient for cases with app domain enabled, but it's OK for now.
}

output "origin_certificate_id" {
  description = "ID of the Cloudflare Origin CA certificate"
  value       = var.cloudflare_origin_certificate_enabled ? cloudflare_origin_ca_certificate.app[0].id : null
}

output "origin_certificate_expires_on" {
  description = "Expiry date of the Cloudflare Origin CA certificate"
  value       = var.cloudflare_origin_certificate_enabled ? cloudflare_origin_ca_certificate.app[0].expires_on : null
}

output "cloudflare_tunnel_cname" {
  description = "Cloudflare Tunnel CNAME target (if tunnel is enabled)"
  value       = var.cloudflare_tunnel_enabled ? "${var.cloudflare_tunnel_id}.cfargotunnel.com" : null
}

output "cloudflare_tunnel_id" {
  description = "Cloudflare Tunnel ID (if tunnel is enabled)"
  value       = var.cloudflare_tunnel_enabled ? var.cloudflare_tunnel_id : null
}
