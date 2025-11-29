output "app_url" {
  description = "Application URL"
  value       = module.app_with_db.fqdn
}

output "database_services" {
  description = "Created database services"
  value       = module.app_with_db.database_services
}

output "database_connection_info" {
  description = "Database connection environment variables"
  value       = module.app_with_db.database_connection_info
}
