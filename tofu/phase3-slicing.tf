# ── Phase 3: Headless Slicing (LXC 220) ─────────────────────────────────────
# PrusaSlicer CLI + FastAPI REST wrapper

resource "tailscale_tailnet_key" "phase3_slicer" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
  description   = "printarr-slicer bootstrap key"
}

module "phase3_slicer" {
  source = "./modules/printarr-lxc"

  vm_id     = 220
  hostname  = "printarr-slicer"
  cores     = 4
  memory    = 4096
  disk_size = 30

  ip_address = "${var.subnet_prefix}.220/24"
  gateway    = var.gateway
  dns_server = var.dns_server

  ssh_public_key     = var.ssh_public_key
  tailscale_auth_key = tailscale_tailnet_key.phase3_slicer.key

  proxmox_node     = var.proxmox_node
  proxmox_bridge   = var.proxmox_bridge
  storage_pool     = var.proxmox_storage_pool
  template_file    = var.proxmox_lxc_template
  template_storage = var.proxmox_template_storage

  compose_source_root = var.compose_source_path
  compose_phase_dir   = "phase3-slicing"

  tags = ["slicing", "prusaslicer"]
}
