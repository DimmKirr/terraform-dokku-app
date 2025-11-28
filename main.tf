# Add domain config via terraform dokku resource
resource "dokku_app" "this" {
  app_name = var.name
  ports = {
    80 = {
      scheme         = "http"
      container_port = var.container_port
    }
  }

  checks = {
    status = var.health_checks_enabled ? "enabled" : "disabled"
  }

  # https://dokku.com/docs/deployment/builders/builder-management/
  builder = {
    build_dir = "apps/${var.name}" # For monorepo deployments
  }

  config  = merge({ APP_NAME = var.name }, var.environment)
  storage = local.storage

  domains = local.domains

  docker_options = var.docker_options
}

# Upload Cloudflare Origin CA certificate to Dokku
resource "dokku_cert" "app" {
  count = var.cloudflare_origin_certificate_enabled ? 1 : 0

  app_name        = dokku_app.this.app_name
  certificate     = cloudflare_origin_ca_certificate.app[0].certificate
  private_key_pem = tls_private_key.origin_ca[0].private_key_pem

  depends_on = [
    dokku_app.this,
    cloudflare_origin_ca_certificate.app,
    tls_private_key.origin_ca
  ]
}
