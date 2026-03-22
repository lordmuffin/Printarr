# ── Phase 5: Fleet & AI (LXC 240) ───────────────────────────────────────────
# OctoEverywhere companion agent + AI vision sidecar for HomeBox

resource "tailscale_tailnet_key" "phase5_fleet" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
  description   = "printarr-fleet bootstrap key"
}

module "phase5_fleet" {
  source = "./modules/printarr-lxc"

  vm_id     = 240
  hostname  = "printarr-fleet"
  cores     = 2
  memory    = 2048
  disk_size = 10

  ip_address = "${var.subnet_prefix}.240/24"
  gateway    = var.gateway
  dns_server = var.dns_server

  ssh_public_key     = var.ssh_public_key
  tailscale_auth_key = tailscale_tailnet_key.phase5_fleet.key

  proxmox_node     = var.proxmox_node
  proxmox_bridge   = var.proxmox_bridge
  storage_pool     = var.proxmox_storage_pool
  template_file    = var.proxmox_lxc_template
  template_storage = var.proxmox_template_storage

  compose_source_root = var.compose_source_path
  compose_phase_dir   = "phase5-fleet"

  tags = ["fleet", "octoeverywhere", "ai"]
}
