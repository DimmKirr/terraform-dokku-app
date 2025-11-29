terraform {
  required_providers {
    dokku = {
      source  = "registry.terraform.io/DimmKirr/dokku"
      version = ">= 1.2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

# Configure the Dokku provider
provider "dokku" {
  ssh_host        = var.dokku_host
  ssh_user        = "dokku"
  ssh_private_key = var.ssh_private_key

  # Required for database plugin installation
  root_ssh_user        = "root"
  root_ssh_private_key = var.ssh_private_key
}

# Configure the Cloudflare provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Deploy an app with PostgreSQL and Redis
module "app_with_db" {
  source = "../.."

  name            = "myapp"
  root_domain     = var.root_domain
  node_ip_address = var.node_ip_address

  # Database configuration with custom settings
  databases = {
    postgres = {
      type    = "postgres"
      version = "16"
      config = {
        "postgres-memory" = "1g"
        "postgres-shm-size" = "128m"
      }
      storage = {
        mount_path = "/var/lib/postgresql/data"
      }
    }
    redis = {
      type    = "redis"
      version = "7"
      config = {
        "redis-maxmemory"        = "512mb"
        "redis-maxmemory-policy" = "allkeys-lru"
      }
      storage = {
        mount_path = "/data"
      }
    }
  }

  environment = {
    NODE_ENV = "production"
  }
}
