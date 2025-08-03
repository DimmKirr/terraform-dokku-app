# Terraform Dokku App Module

A Terraform module to provision and configure a Dokku application with domain and DNS management, supporting Cloudflare integration.

## Overview

This module simplifies the deployment and configuration of applications on a Dokku server with integrated DNS management through Cloudflare. It handles the creation of the Dokku application, domain configuration, environment variables, and DNS record management.

## Features

- Provisions a Dokku app with specified name and domains
- Configures application environment variables
- Sets up build directory configuration
- Manages DNS records via Cloudflare integration
- Creates HTTP to HTTPS redirect rules
- Supports multiple domains for a single application

## Usage

```hcl
module "dokku_app" {
  source          = "github.com/DimmKirr/terraform-dokku-app"
  name            = "myapp"
  root_domain     = "example.com"
  hostname        = "dokku.example.com"
  ssh_private_key = file("~/.ssh/id_rsa")
  node_ip_address = "203.0.113.1"
  
  environment = {
    NODE_ENV = "production"
    PORT     = "5000"
  }
  
  extra_domains = [
    "app.example.org",
    "myapp.example.net"
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | 5.6.0 |
| <a name="requirement_dokku"></a> [dokku](#requirement\_dokku) | >= 1.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 5.6.0 |
| <a name="provider_dokku"></a> [dokku](#provider\_dokku) | 1.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_dns_record.this](https://registry.terraform.io/providers/cloudflare/cloudflare/5.6.0/docs/resources/dns_record) | resource |
| [cloudflare_page_rule.http_to_https](https://registry.terraform.io/providers/cloudflare/cloudflare/5.6.0/docs/resources/page_rule) | resource |
| dokku_app.this | resource |
| [null_resource.config_set](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.set_build_dir](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [cloudflare_ip_ranges.this](https://registry.terraform.io/providers/cloudflare/cloudflare/5.6.0/docs/data-sources/ip_ranges) | data source |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/5.6.0/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Container port that the application listens on | `number` | `5000` | no |
| <a name="input_dns_record_proxied"></a> [dns\_record\_proxied](#input\_dns\_record\_proxied) | Whether the Cloudflare DNS record should be proxied | `bool` | `true` | no |
| <a name="input_dns_record_ttl"></a> [dns\_record\_ttl](#input\_dns\_record\_ttl) | TTL for the Cloudflare DNS record (only applies when dns\_record\_proxied is false) | `number` | `1` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Map of environment variables to set for the Dokku application | `map(string)` | `{}` | no |
| <a name="input_extra_domains"></a> [extra\_domains](#input\_extra\_domains) | List of additional domains to be configured for the application | `list(string)` | `[]` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Hostname of the Dokku server for SSH connections | `string` | n/a | yes |
| <a name="input_manage_cloudflare"></a> [manage\_cloudflare](#input\_manage\_cloudflare) | Whether to manage Cloudflare resources (DNS records and page rules) | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Dokku application to be deployed | `string` | n/a | yes |
| <a name="input_node_ip_address"></a> [node\_ip\_address](#input\_node\_ip\_address) | The IP address of the dokku node for DNS record creation | `string` | n/a | yes |
| <a name="input_root_domain"></a> [root\_domain](#input\_root\_domain) | Root domain for the application (used for DNS records and app domains) | `string` | n/a | yes |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | SSH private key contents for dokku user to establish connection to the server | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Resources

| Name | Type |
|------|------|
| [dokku_app.this](https://registry.terraform.io/providers/DimmKirr/dokku/latest/docs/resources/app) | resource |
| [cloudflare_dns_record.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_page_rule.http_to_https](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/page_rule) | resource |
| [null_resource.set_build_dir](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.config_set](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |
| [cloudflare_ip_ranges.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/ip_ranges) | data source |

## Notes

- This module requires SSH access to the Dokku server with sufficient permissions to create and configure applications
- The Cloudflare integration requires a valid Cloudflare API token with appropriate permissions
- For proxied DNS records, Cloudflare automatically sets the TTL to 1
- The module automatically creates a LAN domain for local access

## License

MIT
