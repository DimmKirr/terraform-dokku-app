output "fqdn" {
  value = cloudflare_dns_record.app_record[var.domains[0]].name
}

output "origin_certificate_id" {
  description = "ID of the Cloudflare Origin CA certificate"
  value       = var.manage_origin_certificate ? cloudflare_origin_ca_certificate.app[0].id : null
}

output "origin_certificate_expires_on" {
  description = "Expiry date of the Cloudflare Origin CA certificate"
  value       = var.manage_origin_certificate ? cloudflare_origin_ca_certificate.app[0].expires_on : null
}
