# Local values for database operations
locals {
  # Get unique database types to install plugins for
  database_types = toset([for k, v in var.databases : v.type])

  # Group databases by type for dynamic resource creation
  databases_by_type = {
    mongo         = { for k, v in var.databases : k => v if v.type == "mongo" }
    postgres      = { for k, v in var.databases : k => v if v.type == "postgres" }
    mysql         = { for k, v in var.databases : k => v if v.type == "mysql" }
    redis         = { for k, v in var.databases : k => v if v.type == "redis" }
    mariadb       = { for k, v in var.databases : k => v if v.type == "mariadb" }
    rabbitmq      = { for k, v in var.databases : k => v if v.type == "rabbitmq" }
    elasticsearch = { for k, v in var.databases : k => v if v.type == "elasticsearch" }
    clickhouse    = { for k, v in var.databases : k => v if v.type == "clickhouse" }
    couchdb       = { for k, v in var.databases : k => v if v.type == "couchdb" }
    nats          = { for k, v in var.databases : k => v if v.type == "nats" }
    rethinkdb     = { for k, v in var.databases : k => v if v.type == "rethinkdb" }
  }
}

# Install database plugin for each unique database type
# Provider v1.2.1+ supports plugin installation via dokku_plugin resource
# Requires root_ssh_user to be configured in the provider
resource "dokku_plugin" "database" {
  for_each = local.database_types

  name = each.value
  url  = lookup(var.database_plugin_urls, each.value)
}

# Create MongoDB databases
resource "dokku_mongo" "this" {
  for_each = local.databases_by_type.mongo

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "mongo:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create PostgreSQL databases
resource "dokku_postgres" "this" {
  for_each = local.databases_by_type.postgres

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "postgres:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create MySQL databases
resource "dokku_mysql" "this" {
  for_each = local.databases_by_type.mysql

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "mysql:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create Redis databases
resource "dokku_redis" "this" {
  for_each = local.databases_by_type.redis

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "redis:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create MariaDB databases
resource "dokku_mariadb" "this" {
  for_each = local.databases_by_type.mariadb

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "mariadb:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create RabbitMQ databases
resource "dokku_rabbitmq" "this" {
  for_each = local.databases_by_type.rabbitmq

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "rabbitmq:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create Elasticsearch databases
resource "dokku_elasticsearch" "this" {
  for_each = local.databases_by_type.elasticsearch

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "elasticsearch:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create ClickHouse databases
resource "dokku_clickhouse" "this" {
  for_each = local.databases_by_type.clickhouse

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "clickhouse:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create CouchDB databases
resource "dokku_couchdb" "this" {
  for_each = local.databases_by_type.couchdb

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "couchdb:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create NATS databases
resource "dokku_nats" "this" {
  for_each = local.databases_by_type.nats

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "nats:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Create RethinkDB databases
resource "dokku_rethinkdb" "this" {
  for_each = local.databases_by_type.rethinkdb

  service_name = local.database_names[each.key]
  image        = try(each.value.version, null) != null ? "rethinkdb:${each.value.version}" : null

  depends_on = [dokku_plugin.database]
}

# Mount storage for databases (if configured)
resource "null_resource" "database_storage_mount" {
  for_each = {
    for k, v in local.database_storage_paths : k => v
    if v != null
  }

  triggers = {
    database_name = local.database_names[each.key]
    host_path     = each.value.host_path
    mount_path    = each.value.mount_path
  }

  connection {
    host        = var.host
    user        = var.ssh_root_user # Requires root: needs shell commands (mkdir, chown) and access to /var/lib/dokku
    private_key = var.ssh_private_key
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      # Create host directory with appropriate permissions
      "mkdir -p ${each.value.host_path}",
      "chown -R dokku:dokku ${each.value.host_path}",
      # Mount storage to database service
      "dokku storage:mount ${var.databases[each.key].type}.${local.database_names[each.key]} ${each.value.host_path}:${each.value.mount_path} || echo 'Storage already mounted'",
      # Rebuild database container to apply mount
      "dokku ps:rebuild ${var.databases[each.key].type}.${local.database_names[each.key]} || echo 'Rebuild skipped or already running'"
    ]
  }

  depends_on = [
    dokku_mongo.this,
    dokku_postgres.this,
    dokku_mysql.this,
    dokku_redis.this,
    dokku_mariadb.this,
    dokku_rabbitmq.this,
    dokku_elasticsearch.this,
    dokku_clickhouse.this,
    dokku_couchdb.this,
    dokku_nats.this,
    dokku_rethinkdb.this
  ]
}

# Link MongoDB databases to app
resource "dokku_mongo_link" "this" {
  for_each = local.databases_by_type.mongo

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_mongo.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link PostgreSQL databases to app
resource "dokku_postgres_link" "this" {
  for_each = local.databases_by_type.postgres

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_postgres.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link MySQL databases to app
resource "dokku_mysql_link" "this" {
  for_each = local.databases_by_type.mysql

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_mysql.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link Redis databases to app
resource "dokku_redis_link" "this" {
  for_each = local.databases_by_type.redis

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_redis.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link MariaDB databases to app
resource "dokku_mariadb_link" "this" {
  for_each = local.databases_by_type.mariadb

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_mariadb.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link RabbitMQ databases to app
resource "dokku_rabbitmq_link" "this" {
  for_each = local.databases_by_type.rabbitmq

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_rabbitmq.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link Elasticsearch databases to app
resource "dokku_elasticsearch_link" "this" {
  for_each = local.databases_by_type.elasticsearch

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_elasticsearch.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link ClickHouse databases to app
resource "dokku_clickhouse_link" "this" {
  for_each = local.databases_by_type.clickhouse

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_clickhouse.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link CouchDB databases to app
resource "dokku_couchdb_link" "this" {
  for_each = local.databases_by_type.couchdb

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_couchdb.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link NATS databases to app
resource "dokku_nats_link" "this" {
  for_each = local.databases_by_type.nats

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_nats.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}

# Link RethinkDB databases to app
resource "dokku_rethinkdb_link" "this" {
  for_each = local.databases_by_type.rethinkdb

  app_name     = dokku_app.this.app_name
  service_name = local.database_names[each.key]

  depends_on = [
    dokku_rethinkdb.this,
    null_resource.database_storage_mount,
    dokku_app.this
  ]
}
