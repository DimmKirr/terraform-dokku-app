output "fqdn" {
  value = cloudflare_dns_record.app_record[var.domains[0]].name
}
