# terraform-dokku-app

A Terraform module to provision and configure a Dokku application with domain and DNS management, supporting Cloudflare integration.

## Features
- Provisions a Dokku app with specified name and domains
- Configures Dokku domains (including LAN and extra domains)
- Manages build directory via remote-exec
- Integrates with Cloudflare for DNS zone and IP range data

## Usage
```hcl
module "dokku_app" {
  source            = "./terraform-dokku-app"
  name              = "myapp"
  root_domain       = "example.com"
  hostname          = "dokku.example.com"
  ssh_private_key   = file("~/.ssh/id_rsa")
  node_ip_address   = "203.0.113.1"
}
```

## Variables
| Name                | Description                                | Type         | Default   |
|---------------------|--------------------------------------------|--------------|-----------|
| name                | App name                                   | string       | -         |
| root_domain         | Root domain for the app                    | string       | -         |
| extra_domains       | Additional domains                         | list(string) | []        |
| hostname            | Hostname for remote-exec                   | string       | -         |
| ssh_private_key     | SSH private key for Dokku user             | string       | -         |
| container_port      | App container port                         | number       | 5000      |
| dns_record_proxied  | Whether Cloudflare DNS is proxied          | bool         | true      |
| dns_record_ttl      | TTL for Cloudflare DNS                     | number       | 1         |
| node_ip_address     | IP address of the Dokku node               | string       | -         |

## Providers
- `aliksend/dokku` >= 1.0.24

## Requirements
- Terraform >= 0.13
- Access to a Dokku server
- SSH key with root access to the Dokku server
- Cloudflare account (if using DNS integration)

## Resources
- `dokku_domain`
- `dokku_app`
- `null_resource` (for build dir setup)
  - `cloudflare_zone` (data)
- `cloudflare_ip_ranges` (data)

## Notes
- Extra domains are currently only partially supported due to provider limitations.
- Make sure your SSH key is properly configured and accessible.

## License
MIT
