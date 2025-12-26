# Example with Database

This example demonstrates deploying an application with PostgreSQL and Redis databases using the terraform-dokku-app module.

## What This Creates

- A Dokku application named `myapp`
- PostgreSQL 16 database (`myapp-postgres`) with:
  - Automatic plugin installation
  - Memory limit: 1GB
  - Shared memory: 128MB
  - Persistent storage
- Redis 7 database (`myapp-redis`) with:
  - Automatic plugin installation
  - Max memory: 512MB
  - Eviction policy: allkeys-lru
  - Persistent storage
- DNS A record pointing to your Dokku server
- Cloudflare DNS management and SSL configuration
- Application domain: `myapp.example.com`

**Note:** Database plugins are installed automatically. If plugins are already installed on your server, you can disable automatic installation by adding `manage_dokku_plugins = false` to the module configuration.

## Database Features

### Automatic Configuration

The module automatically:
- Installs database plugins (dokku-postgres, dokku-redis)
- Creates database services
- Configures persistent storage with auto-generated paths
- Links databases to the application
- Sets environment variables in your app

### Environment Variables

Your application will have these environment variables set automatically:

- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string

### Storage Paths

With the configuration in this example:

- **PostgreSQL data**: `/var/lib/dokku/data/storage/myapp-postgres-data` (host) → `/var/lib/postgresql/data` (container)
- **Redis data**: `/var/lib/dokku/data/storage/myapp-redis-data` (host) → `/data` (container)

## Prerequisites

1. A Dokku server with SSH access
2. Root SSH access for database plugin installation
3. Cloudflare account with API token
4. Domain managed by Cloudflare

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   dokku_host         = "dokku.example.com"
   ssh_private_key    = "~/.ssh/id_rsa"
   root_domain        = "example.com"
   node_ip_address    = "203.0.113.1"
   cloudflare_api_token = "your-cloudflare-api-token"
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Deploying Your Application

After Terraform creates the app and databases, deploy your code:

```bash
# Add Dokku remote to your git repository
git remote add dokku dokku@dokku.example.com:myapp

# Deploy
git push dokku main
```

Your application can now use the `DATABASE_URL` and `REDIS_URL` environment variables to connect to the databases.

## Database Management

### Accessing Databases

```bash
# PostgreSQL console
ssh dokku@dokku.example.com postgres:connect myapp-postgres

# Redis CLI
ssh dokku@dokku.example.com redis:connect myapp-redis
```

### Database Backups

```bash
# Create backup
ssh dokku@dokku.example.com postgres:export myapp-postgres > backup.dump

# Restore backup
cat backup.dump | ssh dokku@dokku.example.com postgres:import myapp-postgres
```

## Cleaning Up

To destroy all resources:

```bash
terraform destroy
```

**Note:** Databases are NOT automatically deleted to prevent data loss. To manually remove them:

```bash
ssh dokku@dokku.example.com postgres:destroy myapp-postgres
ssh dokku@dokku.example.com redis:destroy myapp-redis
ssh dokku@dokku.example.com apps:destroy myapp
```
