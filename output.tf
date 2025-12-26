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

output "database_services" {
  description = "Map of created database services with their details"
  value = {
    for k, v in var.databases : k => {
      type = v.type
      name = local.database_names[k]
      connection_env_vars = {
        mongo = {
          primary = "MONGO_URL"
          oplog   = "MONGO_OPLOG_URL"
        }
        postgres = {
          primary = "DATABASE_URL"
        }
        mysql = {
          primary = "DATABASE_URL"
        }
        redis = {
          primary = "REDIS_URL"
        }
        mariadb = {
          primary = "DATABASE_URL"
        }
      }[v.type]
    }
  }
}

output "database_connection_info" {
  description = "Summary of environment variables set by database linking"
  value = length(var.databases) > 0 ? {
    for k, v in var.databases : k => {
      mongo = {
        MONGO_URL       = "Set by dokku mongo:link"
        MONGO_OPLOG_URL = "Set by dokku mongo:link"
      }
      postgres = {
        DATABASE_URL = "Set by dokku postgres:link"
      }
      mysql = {
        DATABASE_URL = "Set by dokku mysql:link"
      }
      redis = {
        REDIS_URL = "Set by dokku redis:link"
      }
      mariadb = {
        DATABASE_URL = "Set by dokku mariadb:link"
      }
    }[v.type]
  } : {}
  sensitive = false
}
