output "ip_address" {
  description = "Static IP address of the LXC container"
  value       = split("/", var.ip_address)[0]
}

output "container_id" {
  description = "Proxmox container VM ID"
  value       = proxmox_virtual_environment_container.this.vm_id
}

