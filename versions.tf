terraform {
  required_providers {
    dokku = {
      source  = "aliksend/dokku"
      version = "1.0.24"
    }

    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.6.0"
    }
  }
}
