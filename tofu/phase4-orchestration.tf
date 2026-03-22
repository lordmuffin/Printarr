# ── Phase 4: Orchestration (LXC 230 + 231) ──────────────────────────────────
# LXC 230: Moonraker proxy + Spoolman
# LXC 231: HomeBox inventory

resource "tailscale_tailnet_key" "phase4_orchestrator" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
  description   = "printarr-orchestrator bootstrap key"
}

resource "tailscale_tailnet_key" "phase4_inventory" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
  description   = "printarr-inventory bootstrap key"
}

module "phase4_orchestrator" {
  source = "./modules/printarr-lxc"

  vm_id     = 230
  hostname  = "printarr-orchestrator"
  cores     = 2
  memory    = 2048
  disk_size = 20

  ip_address = "${var.subnet_prefix}.230/24"
  gateway    = var.gateway
  dns_server = var.dns_server

  ssh_public_key     = var.ssh_public_key
  tailscale_auth_key = tailscale_tailnet_key.phase4_orchestrator.key

  proxmox_node     = var.proxmox_node
  proxmox_bridge   = var.proxmox_bridge
  storage_pool     = var.proxmox_storage_pool
  template_file    = var.proxmox_lxc_template
  template_storage = var.proxmox_template_storage

  compose_source_root = var.compose_source_path
  compose_phase_dir   = "phase4-orchestration"

  tags = ["orchestration", "moonraker", "spoolman"]
}

module "phase4_inventory" {
  source = "./modules/printarr-lxc"

  vm_id     = 231
  hostname  = "printarr-inventory"
  cores     = 1
  memory    = 1024
  disk_size = 20

  ip_address = "${var.subnet_prefix}.231/24"
  gateway    = var.gateway
  dns_server = var.dns_server

  ssh_public_key     = var.ssh_public_key
  tailscale_auth_key = tailscale_tailnet_key.phase4_inventory.key

  proxmox_node     = var.proxmox_node
  proxmox_bridge   = var.proxmox_bridge
  storage_pool     = var.proxmox_storage_pool
  template_file    = var.proxmox_lxc_template
  template_storage = var.proxmox_template_storage

  compose_source_root = var.compose_source_path
  compose_phase_dir   = "phase4-orchestration"

  tags = ["inventory", "homebox"]
}
