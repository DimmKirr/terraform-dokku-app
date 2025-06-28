variable "name" {}
variable "root_domain" {}
variable "extra_domains" {
  type    = list(string)
  default = []
}

variable "hostname" {
  type = string
}

variable "ssh_private_key" {
  type = string
  description = "SSH private key contents for dokku user"
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "dns_record_proxied" {
  description = "Whether the Cloudflare DNS record should be proxied."
  type        = bool
  default     = true
}

variable "dns_record_ttl" {
  description = "TTL for the Cloudflare DNS record."
  type        = number
  default     = 1 # for proxied records
}

variable "node_ip_address" {
  type = string
  description = "The IP address of the dokku node"
}

