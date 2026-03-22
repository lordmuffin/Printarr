# ── Phase 2: Digital Asset Management ───────────────────────────────────────
# LXC 210: Manyfold + oauth2-proxy (Google OIDC)
# LXC 211: Makers Vault

resource "tailscale_tailnet_key" "phase2_manyfold" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
  description   = "printarr-manyfold bootstrap key"
}

resource "tailscale_tailnet_key" "phase2_vault" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
  description   = "printarr-vault bootstrap key"
}

module "phase2_manyfold" {
  source = "./modules/printarr-lxc"

  vm_id     = 210
  hostname  = "printarr-manyfold"
  cores     = 2
  memory    = 2048
  disk_size = 20

  ip_address = "${var.subnet_prefix}.210/24"
  gateway    = var.gateway
  dns_server = var.dns_server

  ssh_public_key     = var.ssh_public_key
  tailscale_auth_key = tailscale_tailnet_key.phase2_manyfold.key

  proxmox_node     = var.proxmox_node
  proxmox_bridge   = var.proxmox_bridge
  storage_pool     = var.proxmox_storage_pool
  template_file    = var.proxmox_lxc_template
  template_storage = var.proxmox_template_storage

  compose_source_root = var.compose_source_path
  compose_phase_dir   = "phase2-dam/manyfold"

  tags = ["dam", "manyfold", "oidc"]
}

module "phase2_vault" {
  source = "./modules/printarr-lxc"

  vm_id     = 211
  hostname  = "printarr-vault"
  cores     = 1
  memory    = 1024
  disk_size = 20

  ip_address = "${var.subnet_prefix}.211/24"
  gateway    = var.gateway
  dns_server = var.dns_server

  ssh_public_key     = var.ssh_public_key
  tailscale_auth_key = tailscale_tailnet_key.phase2_vault.key

  proxmox_node     = var.proxmox_node
  proxmox_bridge   = var.proxmox_bridge
  storage_pool     = var.proxmox_storage_pool
  template_file    = var.proxmox_lxc_template
  template_storage = var.proxmox_template_storage

  compose_source_root = var.compose_source_path
  compose_phase_dir   = "phase2-dam/makers-vault"

  tags = ["dam", "makers-vault"]
}
