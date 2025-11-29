# Minimal Example

This example demonstrates the minimal configuration required to deploy an application using the terraform-dokku-app module.

## What This Creates

- A Dokku application named `minimal-app`
- DNS A record pointing to your Dokku server's IP
- Cloudflare DNS management and SSL configuration
- Application domain: `minimal-app.example.com`

## Prerequisites

1. A Dokku server with SSH access
2. Cloudflare account with API token
3. Domain managed by Cloudflare

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

After Terraform creates the app, deploy your code to Dokku:

```bash
# Add Dokku remote to your git repository
git remote add dokku dokku@dokku.example.com:minimal-app

# Deploy
git push dokku main
```

## Cleaning Up

To destroy all resources:

```bash
terraform destroy
```

**Note:** This will not delete the Dokku application itself, only the DNS records and Cloudflare configuration. To completely remove the app from Dokku:

```bash
ssh dokku@dokku.example.com apps:destroy minimal-app
```
