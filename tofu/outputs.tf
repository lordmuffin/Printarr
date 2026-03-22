output "phase1_core" {
  description = "Phase 1 core LXC details"
  value = {
    ip_address   = module.phase1_core.ip_address
    container_id = module.phase1_core.container_id
  }
}

output "phase2_manyfold" {
  description = "Phase 2 Manyfold LXC details"
  value = {
    ip_address   = module.phase2_manyfold.ip_address
    container_id = module.phase2_manyfold.container_id
  }
}

output "phase2_vault" {
  description = "Phase 2 Makers Vault LXC details"
  value = {
    ip_address   = module.phase2_vault.ip_address
    container_id = module.phase2_vault.container_id
  }
}

output "phase3_slicer" {
  description = "Phase 3 headless slicer LXC details"
  value = {
    ip_address   = module.phase3_slicer.ip_address
    container_id = module.phase3_slicer.container_id
  }
}

output "phase4_orchestrator" {
  description = "Phase 4 orchestrator LXC details (Moonraker + Spoolman)"
  value = {
    ip_address   = module.phase4_orchestrator.ip_address
    container_id = module.phase4_orchestrator.container_id
  }
}

output "phase4_inventory" {
  description = "Phase 4 inventory LXC details (HomeBox)"
  value = {
    ip_address   = module.phase4_inventory.ip_address
    container_id = module.phase4_inventory.container_id
  }
}

output "phase5_fleet" {
  description = "Phase 5 fleet LXC details (OctoEverywhere + AI)"
  value = {
    ip_address   = module.phase5_fleet.ip_address
    container_id = module.phase5_fleet.container_id
  }
}

output "all_ip_addresses" {
  description = "All LXC IP addresses keyed by hostname"
  value = {
    printarr-core         = module.phase1_core.ip_address
    printarr-manyfold     = module.phase2_manyfold.ip_address
    printarr-vault        = module.phase2_vault.ip_address
    printarr-slicer       = module.phase3_slicer.ip_address
    printarr-orchestrator = module.phase4_orchestrator.ip_address
    printarr-inventory    = module.phase4_inventory.ip_address
    printarr-fleet        = module.phase5_fleet.ip_address
  }
}
