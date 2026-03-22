# Proxmox
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL (e.g., https://192.168.1.10:8006)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form user@realm!token=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for self-signed Proxmox certificates"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node name to provision LXC containers on"
  type        = string
  default     = "pve"
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox node (used by provisioners)"
  type        = string
  default     = "root"
}

variable "proxmox_bridge" {
  description = "Network bridge for LXC containers"
  type        = string
  default     = "vmbr0"
}

variable "proxmox_storage_pool" {
  description = "Proxmox storage pool for LXC root disks"
  type        = string
  default     = "local-lvm"
}

variable "proxmox_lxc_template" {
  description = "Ubuntu 24.04 LXC template name in Proxmox"
  type        = string
  default     = "ubuntu-24.04-standard_24.04-1_amd64.tar.zst"
}

variable "proxmox_template_storage" {
  description = "Proxmox storage pool containing the LXC template"
  type        = string
  default     = "local"
}

# Tailscale
variable "tailscale_api_key" {
  description = "Tailscale API key for managing pre-auth keys"
  type        = string
  sensitive   = true
}

variable "tailscale_tailnet" {
  description = "Tailscale tailnet name (e.g., example.com or example.ts.net)"
  type        = string
}

variable "tailscale_tag" {
  description = "Tailscale ACL tag applied to all Printarr nodes"
  type        = string
  default     = "tag:printarr"
}

# Networking
variable "subnet_prefix" {
  description = "First three octets of the LAN subnet (e.g., 192.168.1)"
  type        = string
  default     = "192.168.1"
}

variable "gateway" {
  description = "LAN gateway IP"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_server" {
  description = "DNS server IP injected into LXC containers"
  type        = string
  default     = "1.1.1.1"
}

# SSH
variable "ssh_public_key" {
  description = "SSH public key injected into all LXC containers"
  type        = string
}

# Domain
variable "domain" {
  description = "Base domain for Traefik routing (e.g., home.example.com)"
  type        = string
}

# Docker Compose source path (local)
variable "compose_source_path" {
  description = "Absolute local path to the docker/ directory (copied to LXCs via provisioner)"
  type        = string
  default     = "../docker"
}
