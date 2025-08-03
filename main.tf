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
    status =  var.enable_checks ? "enabled" : "disabled"
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
      host        = var.node_ip_address
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
      host        = var.node_ip_address
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
