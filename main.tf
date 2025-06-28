# Add domain config via terraform dokku resource
resource "dokku_domain" "this" {
    domain = var.root_domain
}

resource "dokku_app" "this" {
    app_name = var.name
    ports = {
        80 = {
            scheme = "http"
            container_port = var.container_port
        }
    }

    domains = ["${var.name}.${var.root_domain}", "${var.name}.lan"] # TODO: Make extra domains working (provider type issue)
}

resource "null_resource" "set_build_dir" {
    triggers = {
        always_run = "${timestamp()}"
    }
    provisioner "remote-exec" {
        connection {
            host    = var.hostname
            user    = "root"
            private_key = var.ssh_private_key
            timeout = "2m"
        }

        inline = [
            "dokku builder:set ${var.name} build-dir apps/${var.name}"
        ]
    }
}

