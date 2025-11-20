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

  config = merge({ APP_NAME = var.name }, var.environment)
  storage = merge(local.storage, var.extra_storage)


  domains = local.domains

  docker_options = var.docker_options
}

resource "null_resource" "set_build_dir" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "remote-exec" {
    connection {
      host        = var.host
      user        = "root"
      private_key = var.ssh_private_key
      timeout     = "2m"
    }

    inline = [
      "dokku builder:set ${dokku_app.this.app_name} build-dir apps/${dokku_app.this.app_name}"
    ]
  }
}

resource "null_resource" "config_set" {
  for_each = var.environment
  provisioner "remote-exec" {
    connection {
      host        = var.host
      user        = "root"
      private_key = var.ssh_private_key
    }

    inline = [
      "dokku config:set --no-restart ${dokku_app.this.app_name} ${each.key}='${each.value}'"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
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
      # host        = var.node_ip_address
      user        = "root"
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
