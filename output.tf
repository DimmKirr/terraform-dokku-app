output "fqdn" {
  value = "${var.name}.${var.root_domain}" # likely insufficient for cases with app domain enabled, but it's OK for now.
}

output "origin_certificate_id" {
  description = "ID of the Cloudflare Origin CA certificate"
  value       = var.manage_origin_certificate ? cloudflare_origin_ca_certificate.app[0].id : null
}

output "origin_certificate_expires_on" {
  description = "Expiry date of the Cloudflare Origin CA certificate"
  value       = var.manage_origin_certificate ? cloudflare_origin_ca_certificate.app[0].expires_on : null
}
