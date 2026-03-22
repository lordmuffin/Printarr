locals {
  bare_ip   = split("/", var.ip_address)[0]
  tags_full = concat(["printarr"], var.tags)
}

resource "proxmox_virtual_environment_container" "this" {
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  description = "Printarr — ${var.hostname}"
  tags        = local.tags_full

  initialization {
    hostname = var.hostname

    dns {
      server = var.dns_server
    }

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = null # Key-only authentication
    }
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = 512
  }

  disk {
    datastore_id = var.storage_pool
    size         = var.disk_size
  }

  network_interface {
    name   = "eth0"
    bridge = var.proxmox_bridge
  }

  operating_system {
    template_file_id = "${var.template_storage}:vztmpl/${var.template_file}"
    type             = "ubuntu"
  }

  features {
    nesting = true # Required for Docker-in-LXC
    keyctl  = true # Required for Docker image layer caching
  }

  unprivileged  = true
  start_on_boot = true

  lifecycle {
    ignore_changes = [
      # Template may be updated upstream; don't force re-create
      operating_system[0].template_file_id,
    ]
  }
}

# ── Provisioners ────────────────────────────────────────────────────────────

resource "null_resource" "bootstrap" {
  depends_on = [proxmox_virtual_environment_container.this]

  triggers = {
    container_id = proxmox_virtual_environment_container.this.id
  }

  connection {
    type        = "ssh"
    host        = local.bare_ip
    user        = "root"
    private_key = null # Relies on ssh-agent
    timeout     = "5m"
  }

  # 1. Install Docker CE + compose plugin + curl
  provisioner "remote-exec" {
    inline = [
      "apt-get update -qq",
      "apt-get install -y -qq ca-certificates curl gnupg lsb-release",
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list",
      "apt-get update -qq",
      "apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "systemctl enable --now docker",
    ]
  }

  # 2. Copy compose files
  provisioner "file" {
    source      = "${var.compose_source_root}/${var.compose_phase_dir}/"
    destination = "/opt/printarr"
  }

  # 3. Start compose stack
  provisioner "remote-exec" {
    inline = [
      "cd /opt/printarr && docker compose up -d --remove-orphans",
    ]
  }
}
