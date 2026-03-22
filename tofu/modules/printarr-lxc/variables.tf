variable "vm_id" {
  description = "Proxmox container ID (100–999)"
  type        = number
}

variable "hostname" {
  description = "LXC hostname"
  type        = string
}

variable "cores" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 1024
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 10
}

variable "ip_address" {
  description = "Static IPv4 address with CIDR (e.g., 192.168.1.200/24)"
  type        = string
}

variable "gateway" {
  description = "Default gateway for the LXC"
  type        = string
}

variable "dns_server" {
  description = "DNS server for the LXC"
  type        = string
  default     = "1.1.1.1"
}

variable "ssh_public_key" {
  description = "SSH public key for root access"
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale pre-auth key for this container"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "proxmox_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "storage_pool" {
  description = "Proxmox storage pool for the root disk"
  type        = string
  default     = "local-lvm"
}

variable "template_file" {
  description = "LXC template filename"
  type        = string
  default     = "ubuntu-24.04-standard_24.04-1_amd64.tar.zst"
}

variable "template_storage" {
  description = "Proxmox storage containing the template"
  type        = string
  default     = "local"
}

variable "compose_phase_dir" {
  description = "Relative path (from compose_source_root) to the phase's compose directory"
  type        = string
}

variable "compose_source_root" {
  description = "Absolute local path to the docker/ directory"
  type        = string
}

variable "tags" {
  description = "Additional Proxmox tags to apply to the container"
  type        = list(string)
  default     = []
}
