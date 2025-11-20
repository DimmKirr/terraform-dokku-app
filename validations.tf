locals {
  # Validation: ensure cloudflare_tunnel_id is set when tunnel is enabled
  validate_tunnel_config = (
    var.manage_cloudflare && var.cloudflare_tunnel_enabled && var.cloudflare_tunnel_id == "" ?
    tobool("ERROR: cloudflare_tunnel_id is required when cloudflare_tunnel_enabled is true") : true
  )

  # Validation: ensure node_ip_address is set when tunnel is disabled
  validate_ip_config = (
    var.manage_cloudflare && !var.cloudflare_tunnel_enabled && var.node_ip_address == "" ?
    tobool("ERROR: node_ip_address is required when cloudflare_tunnel_enabled is false") : true
  )
}
