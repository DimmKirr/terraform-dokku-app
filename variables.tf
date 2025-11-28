# ==============================================================================
# Application Configuration
# ==============================================================================

variable "name" {
  description = "Name of the Dokku application to be deployed"
  type        = string
}

variable "root_domain" {
  description = "Root domain for the application (used for DNS records and app domains)"
  type        = string
}

variable "domains" {
  description = "The list of domains for the app."
  type        = list(string)
  default     = []
}

variable "manage_subdomain" {
  description = "Whether to enable a subdomain for the application"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Map of environment variables to set for the Dokku application"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Dokku Server Configuration
# ==============================================================================

variable "host" {
  description = "Hostname of the Dokku server for SSH connections"
  type        = string
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key contents for establishing SSH connections to the server"
}

variable "ssh_user" {
  type        = string
  description = "SSH user for regular Dokku operations (dokku commands). IMPORTANT: Must have an unrestricted shell (not the default dokku restricted shell) because Terraform's remote-exec uploads temporary scripts. Use 'root' if you haven't configured a custom user with unrestricted shell access."
  default     = "dokku"
}

variable "ssh_root_user" {
  type        = string
  description = "SSH user for privileged operations that require root access or shell commands (plugin installation, mkdir, chown, file operations in /var/lib/dokku)"
  default     = "root"
}

variable "container_port" {
  description = "Container port that the application listens on"
  type        = number
  default     = 5000
}

variable "storage_enabled" {
  description = "Enable persistent storage for the application"
  type        = bool
  default     = false
}

variable "data_dir" {
  description = "Storage directory on the host (used for default storage mount when storage variable is not set)"
  type        = string
  default     = "/var/lib/dokku/data/storage"
}

variable "storage" {
  description = "Storage mounts configuration. If set, overrides default storage. Map key is host path (absolute) or volume name, value has mount_path (container path)"
  type        = map(any)
  default     = null
}

variable "docker_options" {
  description = "Additional docker options ( # https://dokku.com/docs/advanced-usage/docker-options/)"
  type        = map(any)
  default     = {}
}

variable "health_checks_enabled" {
  description = "Enable health checks (Defined in app.json)"
  type        = bool
  default     = true
}

variable "node_ip_address" {
  type        = string
  description = "The IP address of the dokku node for DNS record creation (required when cloudflare_tunnel_enabled is false)"
  default     = ""
}

variable "proxy_enabled" {
  description = "Enable Dokku proxy for the application"
  type        = bool
  default     = true
}

# ==============================================================================
# Cloudflare Configuration
# ==============================================================================

variable "cloudflare_dns_record_proxied" {
  description = "Whether the Cloudflare DNS record should be proxied"
  type        = bool
  default     = true
}

variable "cloudflare_dns_record_ttl" {
  description = "TTL for the Cloudflare DNS record (only applies when dns_record_proxied is false)"
  type        = number
  default     = 1 # for proxied records
}

variable "cloudflare_dns_records" {
  description = "Additional DNS records for the app"
  type = list(object({
    type     = string
    name     = string
    content  = string
    priority = number
    ttl      = number
    proxied  = bool
  }))
  default = []
}

variable "cloudflare_manage_https_redirect" {
  description = "Whether to manage Cloudflare http to https redirect"
  type        = bool
  default     = true
}

variable "cloudflare_origin_certificate_enabled" {
  description = "Whether to create and manage a Cloudflare Origin CA certificate for the application"
  type        = bool
  default     = false
}

variable "cloudflare_origin_certificate_validity_days" {
  description = "Validity period for the Cloudflare Origin CA certificate in days (7, 30, 90, 365, 730, 1825, 5475)"
  type        = number
  default     = 5475
}

variable "cloudflare_tunnel_enabled" {
  description = "Whether to use Cloudflare Tunnel for DNS routing (CNAME) instead of direct IP (A record)"
  type        = bool
  default     = false
}

variable "cloudflare_tunnel_id" {
  description = "Cloudflare Tunnel UUID (required when cloudflare_tunnel_enabled is true)"
  type        = string
  default     = ""
}

variable "manage_cloudflare" {
  description = "Whether to manage Cloudflare resources (DNS records and page rules)"
  type        = bool
  default     = true
}

# ==============================================================================
# Database Configuration
# ==============================================================================

variable "databases" {
  description = "Map of database services to create and link. Key is the database identifier (database name will be auto-generated as {{app_name}}-{{key}})."
  type = map(object({
    type    = string                    # "mongo", "postgres", "mysql", "redis", "mariadb", "rabbitmq", "elasticsearch", "clickhouse", "couchdb", "nats", "rethinkdb"
    version = optional(string)          # Database version (e.g., "7.0" for mongo)
    config  = optional(map(string), {}) # Additional creation options (memory, etc.)
    storage = optional(object({
      host_path  = optional(string) # Host path (defaults to /var/lib/dokku/data/storage/{{APP_NAME}}-{{KEY}})
      mount_path = string           # Container mount path (e.g., "/data/db" for mongo)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.databases : contains(
        ["mongo", "postgres", "mysql", "redis", "mariadb", "rabbitmq", "elasticsearch", "clickhouse", "couchdb", "nats", "rethinkdb"],
        v.type
      )
    ])
    error_message = "Database type must be one of: mongo, postgres, mysql, redis, mariadb, rabbitmq, elasticsearch, clickhouse, couchdb, nats, rethinkdb"
  }

  validation {
    condition = alltrue([
      for k, v in var.databases :
      v.storage != null ? (v.storage.host_path == null || startswith(v.storage.host_path, "/")) : true
    ])
    error_message = "If storage.host_path is provided, it must be an absolute path starting with '/'"
  }
}

variable "database_plugin_urls" {
  description = "Custom URLs for Dokku database plugins (override defaults)"
  type        = map(string)
  default = {
    mongo         = "https://github.com/dokku/dokku-mongo.git"
    postgres      = "https://github.com/dokku/dokku-postgres.git"
    mysql         = "https://github.com/dokku/dokku-mysql.git"
    redis         = "https://github.com/dokku/dokku-redis.git"
    mariadb       = "https://github.com/dokku/dokku-mariadb.git"
    rabbitmq      = "https://github.com/dokku/dokku-rabbitmq.git"
    elasticsearch = "https://github.com/dokku/dokku-elasticsearch.git"
    clickhouse    = "https://github.com/dokku/dokku-clickhouse.git"
    couchdb       = "https://github.com/dokku/dokku-couchdb.git"
    nats          = "https://github.com/dokku/dokku-nats.git"
    rethinkdb     = "https://github.com/dokku/dokku-rethinkdb.git"
  }
}
