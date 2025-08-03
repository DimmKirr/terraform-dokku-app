terraform {
  required_providers {
    dokku = {
      source  = "registry.terraform.io/DimmKirr/dokku" # Until provider is published to opentofu registry
      version = ">= 1.2.0"
    }

    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.6.0"
    }
  }
}
