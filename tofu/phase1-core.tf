# ── Phase 1: Core (LXC 200) ─────────────────────────────────────────────────
# Traefik reverse proxy + Tailscale subnet router

resource "tailscale_tailnet_key" "phase1_core" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
  description   = "printarr-core bootstrap key"
}

module "phase1_core" {
  source = "./modules/printarr-lxc"

  vm_id     = 200
  hostname  = "printarr-core"
  cores     = 2
  memory    = 1024
  disk_size = 10

  ip_address = "${var.subnet_prefix}.200/24"
  gateway    = var.gateway
  dns_server = var.dns_server

  ssh_public_key     = var.ssh_public_key
  tailscale_auth_key = tailscale_tailnet_key.phase1_core.key

  proxmox_node     = var.proxmox_node
  proxmox_bridge   = var.proxmox_bridge
  storage_pool     = var.proxmox_storage_pool
  template_file    = var.proxmox_lxc_template
  template_storage = var.proxmox_template_storage

  compose_source_root = var.compose_source_path
  compose_phase_dir   = "phase1-core"

  tags = ["core", "traefik", "tailscale"]
}
