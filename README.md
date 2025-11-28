# Terraform Dokku App Module

A Terraform module to provision and configure a Dokku application with domain and DNS management, supporting Cloudflare integration.

## Overview

This module simplifies the deployment and configuration of applications on a Dokku server with integrated DNS management through Cloudflare. It handles the creation of the Dokku application, domain configuration, environment variables, and DNS record management.

## Features

- Provisions a Dokku app with specified name and domains
- Configures application environment variables
- Sets up build directory configuration
- Manages DNS records via Cloudflare integration
- Supports both traditional IP-based (A records) and Cloudflare Tunnel (CNAME records) routing
- Creates HTTP to HTTPS redirect rules
- Supports multiple domains for a single application

## Usage

### Basic Example

```hcl
module "dokku_app" {
  source = "github.com/DimmKirr/terraform-dokku-app"

  # Required variables
  name            = "myapp"
  root_domain     = "example.com"
  host            = "dokku.example.com"
  ssh_private_key = file("~/.ssh/id_rsa")
  node_ip_address = "203.0.113.1"
}
```

### With Additional Configuration

```hcl
module "dokku_app" {
  source = "github.com/DimmKirr/terraform-dokku-app"

  # Required variables
  name            = "myapp"
  root_domain     = "example.com"
  host            = "dokku.example.com"
  ssh_private_key = file("~/.ssh/id_rsa")
  node_ip_address = "203.0.113.1"

  # Optional configuration
  environment = {
    NODE_ENV = "production"
    PORT     = "5000"
  }

  domains = [
    "app.example.org",
    "myapp.example.net"
  ]
}
```

### Tunnel Mode (Cloudflare Tunnel)

```hcl
module "dokku_app" {
  source                    = "github.com/DimmKirr/terraform-dokku-app"
  name                      = "myapp"
  root_domain               = "example.com"
  host                      = "dokku.example.com"
  ssh_private_key           = file("~/.ssh/id_rsa")
  cloudflare_tunnel_enabled = true
  cloudflare_tunnel_id      = "abc123-def456-ghi789"

  environment = {
    NODE_ENV = "production"
  }
}
```

**Note:** The Cloudflare Tunnel must be created and configured separately. This module only handles the DNS configuration.

### Database Support

The module supports automatic provisioning and linking of database services using Dokku plugins.

#### Supported Database Types

- **mongo** - MongoDB (dokku-mongo plugin)
- **postgres** - PostgreSQL (dokku-postgres plugin)
- **mysql** - MySQL (dokku-mysql plugin)
- **redis** - Redis (dokku-redis plugin)
- **mariadb** - MariaDB (dokku-mariadb plugin)

#### Single Database Example (MongoDB for Rocket.Chat)

```hcl
module "rocketchat" {
  source = "github.com/DimmKirr/terraform-dokku-app"

  name            = "rocketchat"
  root_domain     = "example.com"
  host            = "dokku.example.com"
  ssh_private_key = file("~/.ssh/id_rsa")

  # Single database
  databases = {
    "mongo" = {
      type    = "mongo"
      name    = "rocketchat-db"
      version = "7.0"
      config  = {
        "memory"   = "1024m"
        "shm-size" = "256m"
      }
    }
  }

  environment = {
    ROOT_URL = "https://chat.example.com"
  }
}
```

#### Multiple Databases Example (PostgreSQL + Redis)

```hcl
module "rails_app" {
  source = "github.com/DimmKirr/terraform-dokku-app"

  name            = "myapp"
  root_domain     = "example.com"
  host            = "dokku.example.com"
  ssh_private_key = file("~/.ssh/id_rsa")

  # Multiple databases
  databases = {
    "postgres" = {
      type    = "postgres"
      name    = "myapp-db"
      version = "15"
      config  = {
        "postgres-memory" = "1024m"
      }
    }
    "redis" = {
      type    = "redis"
      name    = "myapp-redis"
      version = "7.0"
      config  = {
        "redis-maxmemory"        = "512mb"
        "redis-maxmemory-policy" = "allkeys-lru"
      }
    }
  }

  environment = {
    RAILS_ENV = "production"
  }
}
```

#### How It Works

1. **Plugin Installation**: Installs the Dokku database plugin if not present
2. **Service Creation**: Creates the database service (idempotent - safe to run multiple times)
3. **Automatic Linking**: Links database to app, which sets environment variables:
   - MongoDB: `MONGO_URL`, `MONGO_OPLOG_URL`
   - PostgreSQL/MySQL/MariaDB: `DATABASE_URL`
   - Redis: `REDIS_URL`

#### Database Configuration Options

Each database can have a `config` field that accepts options converted to command-line flags:

```hcl
databases = {
  "mongo" = {
    type    = "mongo"
    name    = "rocketchat-db"
    version = "7.0"
    config  = {
      "memory"   = "1024m"
      "shm-size" = "256m"
    }
  }
}
# Becomes: dokku mongo:create rocketchat-db --image-version 7.0 --memory 1024m --shm-size 256m
```

**Common Options by Database Type:**

| Database | Option | Description | Example |
|----------|--------|-------------|---------|
| MongoDB | `memory` | Container memory limit | `"1024m"` |
| MongoDB | `shm-size` | Shared memory size | `"256m"` |
| PostgreSQL | `postgres-memory` | Container memory limit | `"512m"` |
| PostgreSQL | `postgres-shm-size` | Shared memory size | `"128m"` |
| MySQL | `memory` | Container memory limit | `"512m"` |
| Redis | `redis-maxmemory` | Max memory limit | `"512mb"` |
| Redis | `redis-maxmemory-policy` | Eviction policy | `"allkeys-lru"` |
| MariaDB | `memory` | Container memory limit | `"512m"` |

#### MongoDB Replica Sets (Rocket.Chat, etc.)

Some applications require MongoDB replica sets. The module creates the MongoDB service, but **replica set initialization is handled by the application** in its entrypoint script.

**Example pattern (in your app's entrypoint.sh):**
```bash
# Check if replica set is initialized
if mongosh "$MONGO_URL" --eval "rs.status()" | grep -q "no replset config"; then
  # Initialize replica set
  mongosh "$MONGO_URL" --eval "rs.initiate({_id:'rs0',members:[{_id:0,host:'localhost:27017'}]})"
fi

# Add replicaSet parameter to URL
export MONGO_URL="${MONGO_URL}?replicaSet=rs0"
```

#### Database Lifecycle

- **Creation**: Database created on `tofu apply`
- **Updates**: Database version updates require manual intervention (Dokku limitation)
- **Deletion**: Database service NOT deleted on `tofu destroy` to prevent data loss
  - To delete: `ssh root@host dokku <type>:destroy <name>`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~>5 |
| <a name="requirement_dokku"></a> [dokku](#requirement\_dokku) | >= 1.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 5.6.0 |
| <a name="provider_dokku"></a> [dokku](#provider\_dokku) | 1.2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_dns_record.app_record](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_dns_record.dns_records](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_origin_ca_certificate.app](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/origin_ca_certificate) | resource |
| [cloudflare_page_rule.http_to_https](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/page_rule) | resource |
| [cloudflare_zone_setting.ssl_mode](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone_setting) | resource |
| dokku_app.this | resource |
| [null_resource.config_set](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.dokku_cert](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.set_build_dir](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [tls_cert_request.origin_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_private_key.origin_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [cloudflare_ip_ranges.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/ip_ranges) | data source |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudflare_dns_record_proxied"></a> [cloudflare\_dns\_record\_proxied](#input\_cloudflare\_dns\_record\_proxied) | Whether the Cloudflare DNS record should be proxied | `bool` | `true` | no |
| <a name="input_cloudflare_dns_record_ttl"></a> [cloudflare\_dns\_record\_ttl](#input\_cloudflare\_dns\_record\_ttl) | TTL for the Cloudflare DNS record (only applies when dns\_record\_proxied is false) | `number` | `1` | no |
| <a name="input_cloudflare_dns_records"></a> [cloudflare\_dns\_records](#input\_cloudflare\_dns\_records) | Additional DNS records for the app | <pre>list(object({<br/>    type     = string<br/>    name     = string<br/>    content  = string<br/>    priority = number<br/>    ttl      = number<br/>    proxied  = bool<br/>  }))</pre> | `[]` | no |
| <a name="input_cloudflare_manage_https_redirect"></a> [cloudflare\_manage\_https\_redirect](#input\_cloudflare\_manage\_https\_redirect) | Whether to manage Cloudflare http to https redirect | `bool` | `true` | no |
| <a name="input_cloudflare_origin_certificate_enabled"></a> [cloudflare\_origin\_certificate\_enabled](#input\_cloudflare\_origin\_certificate\_enabled) | Whether to create and manage a Cloudflare Origin CA certificate for the application | `bool` | `false` | no |
| <a name="input_cloudflare_origin_certificate_validity_days"></a> [cloudflare\_origin\_certificate\_validity\_days](#input\_cloudflare\_origin\_certificate\_validity\_days) | Validity period for the Cloudflare Origin CA certificate in days (7, 30, 90, 365, 730, 1825, 5475) | `number` | `5475` | no |
| <a name="input_cloudflare_tunnel_enabled"></a> [cloudflare\_tunnel\_enabled](#input\_cloudflare\_tunnel\_enabled) | Whether to use Cloudflare Tunnel for DNS routing (CNAME) instead of direct IP (A record) | `bool` | `false` | no |
| <a name="input_cloudflare_tunnel_id"></a> [cloudflare\_tunnel\_id](#input\_cloudflare\_tunnel\_id) | Cloudflare Tunnel UUID (required when cloudflare\_tunnel\_enabled is true) | `string` | `""` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Container port that the application listens on | `number` | `5000` | no |
| <a name="input_data_dir"></a> [data\_dir](#input\_data\_dir) | Storage directory on the host | `string` | `"/data"` | no |
| <a name="input_docker_options"></a> [docker\_options](#input\_docker\_options) | Additional docker options ( # https://dokku.com/docs/advanced-usage/docker-options/) | `map(any)` | `{}` | no |
| <a name="input_domains"></a> [domains](#input\_domains) | The list of domains for the app. | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Map of environment variables to set for the Dokku application | `map(string)` | `{}` | no |
| <a name="input_extra_storage"></a> [extra\_storage](#input\_extra\_storage) | Extra storage mounts | `map(any)` | `{}` | no |
| <a name="input_health_checks_enabled"></a> [health\_checks\_enabled](#input\_health\_checks\_enabled) | Enable health checks (Defined in app.json) | `bool` | `true` | no |
| <a name="input_host"></a> [host](#input\_host) | Hostname of the Dokku server for SSH connections | `string` | n/a | yes |
| <a name="input_manage_cloudflare"></a> [manage\_cloudflare](#input\_manage\_cloudflare) | Whether to manage Cloudflare resources (DNS records and page rules) | `bool` | `true` | no |
| <a name="input_manage_subdomain"></a> [manage\_subdomain](#input\_manage\_subdomain) | Whether to enable a subdomain for the application | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Dokku application to be deployed | `string` | n/a | yes |
| <a name="input_node_ip_address"></a> [node\_ip\_address](#input\_node\_ip\_address) | The IP address of the dokku node for DNS record creation (required when cloudflare\_tunnel\_enabled is false) | `string` | `""` | no |
| <a name="input_proxy_enabled"></a> [proxy\_enabled](#input\_proxy\_enabled) | Enable Dokku proxy for the application | `bool` | `true` | no |
| <a name="input_root_domain"></a> [root\_domain](#input\_root\_domain) | Root domain for the application (used for DNS records and app domains) | `string` | n/a | yes |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | SSH private key contents for dokku user to establish connection to the server | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudflare_tunnel_cname"></a> [cloudflare\_tunnel\_cname](#output\_cloudflare\_tunnel\_cname) | Cloudflare Tunnel CNAME target (if tunnel is enabled) |
| <a name="output_cloudflare_tunnel_id"></a> [cloudflare\_tunnel\_id](#output\_cloudflare\_tunnel\_id) | Cloudflare Tunnel ID (if tunnel is enabled) |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | n/a |
| <a name="output_origin_certificate_expires_on"></a> [origin\_certificate\_expires\_on](#output\_origin\_certificate\_expires\_on) | Expiry date of the Cloudflare Origin CA certificate |
| <a name="output_origin_certificate_id"></a> [origin\_certificate\_id](#output\_origin\_certificate\_id) | ID of the Cloudflare Origin CA certificate |
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
