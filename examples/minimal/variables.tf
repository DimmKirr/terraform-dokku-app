variable "dokku_host" {
  description = "Hostname of the Dokku server"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private key for authentication. Supports: ~/path, /absolute/path, env:VAR_NAME, $VAR_NAME, or raw:-----BEGIN..."
  type        = string
  sensitive   = true
}

variable "root_domain" {
  description = "Root domain for the application (e.g., example.com)"
  type        = string
}

variable "node_ip_address" {
  description = "IP address of the Dokku server for DNS records"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS permissions"
  type        = string
  sensitive   = true
}
