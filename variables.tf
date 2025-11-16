variable "name" {
  description = "Name of the Dokku application to be deployed"
  type        = string
}

variable "root_domain" {
  description = "Root domain for the application (used for DNS records and app domains)"
  type        = string
}

variable "manage_subdomain" {
  description = "Whether to enable a subdomain for the application"
  type        = bool
  default     = true
}


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

variable "dns_record_proxied" {
  description = "Whether the Cloudflare DNS record should be proxied"
  type        = bool
  default     = true
}

variable "dns_record_ttl" {
  description = "TTL for the Cloudflare DNS record (only applies when dns_record_proxied is false)"
  type        = number
  default     = 1 # for proxied records
}

variable "node_ip_address" {
  type        = string
  description = "The IP address of the dokku node for DNS record creation"
}

variable "environment" {
  description = "Map of environment variables to set for the Dokku application"
  type        = map(string)
  default     = {}
}

variable "manage_cloudflare" {
  description = "Whether to manage Cloudflare resources (DNS records and page rules)"
  type        = bool
  default     = true
}


variable "manage_https_redirect" {
  description = "Whether to manage Cloudflare http to https redurect"
  type        = bool
  default     = true
}

variable "data_dir" {
  description = "Storage directory on the host"
  type        = string
  default     = "/data"
}

variable "extra_storage" {
  description = "Extra storage mounts"
  type = map(any)
  default = {}
}

variable "docker_options" {
  description = "Additional docker options ( # https://dokku.com/docs/advanced-usage/docker-options/)"
  type = map(any)
  default = {}
}


variable "dns_records" {
  description = "DNS Records for the app"
  type = list(object({
    type = string
    name = string
    content = string
    priority = number
    ttl = number
    proxied = bool
  }))
  default = []
}


variable "domains" {
  description = "The list of domains for the app."
  type = list(string)
  default = []
}

variable "enable_proxy" {
  type = bool
  default = true
}

variable "enable_checks" {
  description = "Enable health checks (Defined in app.json)"
  type = bool
  default = true
}

variable "manage_origin_certificate" {
  description = "Whether to create and manage a Cloudflare Origin CA certificate for the application"
  type        = bool
  default     = false
}

variable "origin_certificate_validity_days" {
  description = "Validity period for the Cloudflare Origin CA certificate in days (7, 30, 90, 365, 730, 1825, 5475)"
  type        = number
  default     = 5475
}
