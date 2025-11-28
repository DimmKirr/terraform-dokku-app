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
resource "null_resource" "dokku_cert" {
  count = var.cloudflare_origin_certificate_enabled ? 1 : 0

  triggers = {
    cert_id = cloudflare_origin_ca_certificate.app[0].id
  }

  provisioner "remote-exec" {
    connection {
      host        = var.host
      user        = var.ssh_root_user # Needs root for file operations (mkdir, cat, tar, rm)
      private_key = var.ssh_private_key
    }

    inline = [
      "set -e",
      "mkdir -p /tmp/dokku-certs-${dokku_app.this.app_name}",
      "cat > /tmp/dokku-certs-${dokku_app.this.app_name}/server.crt <<'CERT_EOF'\n${cloudflare_origin_ca_certificate.app[0].certificate}\nCERT_EOF",
      "cat > /tmp/dokku-certs-${dokku_app.this.app_name}/server.key <<'KEY_EOF'\n${tls_private_key.origin_ca[0].private_key_pem}\nKEY_EOF",
      "cd /tmp/dokku-certs-${dokku_app.this.app_name} && tar cf certificate.tar server.crt server.key",
      "dokku certs:add ${dokku_app.this.app_name} < /tmp/dokku-certs-${dokku_app.this.app_name}/certificate.tar",
      "rm -rf /tmp/dokku-certs-${dokku_app.this.app_name}"
    ]
  }

  depends_on = [
    dokku_app.this,
    cloudflare_origin_ca_certificate.app,
    tls_private_key.origin_ca
  ]
}
