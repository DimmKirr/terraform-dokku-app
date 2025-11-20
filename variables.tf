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
  description = "SSH private key contents for dokku user to establish connection to the server"
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
