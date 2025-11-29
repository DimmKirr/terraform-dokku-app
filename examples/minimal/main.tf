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

# Deploy a minimal app
module "minimal_app" {
  source = "../.."

  name            = "minimal-app"
  root_domain     = var.root_domain
  node_ip_address = var.node_ip_address

  environment = {
    NODE_ENV = "production"
  }
}
