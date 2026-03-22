# Printarr — Deployment Runbook

## Prerequisites

Before running `tofu apply`, ensure the following are in place:

| Requirement | Notes |
|---|---|
| Proxmox 9.x | API token with `PVEAdmin` role on target node |
| Ubuntu 24.04 LXC template | Downloaded to Proxmox storage (`pveam update && pveam download local ubuntu-24.04-standard_24.04-1_amd64.tar.zst`) |
| OpenTofu 1.11+ | `brew install opentofu` or see opentofu.org |
| Tailscale account | Free tier sufficient; create ACL tag `tag:printarr` in admin console |
| Google Cloud project | OAuth2 credentials with authorized redirect URIs for each service |
| External PostgreSQL | Running and reachable from LXC subnet; database `manyfold` created |
| SSH agent running | `eval $(ssh-agent) && ssh-add ~/.ssh/id_ed25519` |

---

## Step 1 — Prepare Proxmox API Token

```bash
# On Proxmox host (or via web UI)
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
pveum user add terraform@pam
pveum aclmod / -user terraform@pam -role TerraformProv
pveum user token add terraform@pam printarr --privsep=0
# Copy the token secret shown — it is only displayed once
```

---

## Step 2 — Prepare Tailscale ACL Tag

In the [Tailscale admin console](https://login.tailscale.com/admin/acls), add to your ACL policy:

```json
{
  "tagOwners": {
    "tag:printarr": ["autogroup:admin"]
  }
}
```

---

## Step 3 — Configure OpenTofu Variables

```bash
cd tofu/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox endpoint, API token,
# Tailscale key, SSH key, domain, etc.
```

Key values to set:
- `proxmox_endpoint` — e.g., `https://192.168.1.10:8006`
- `proxmox_api_token` — from Step 1
- `tailscale_api_key` — from Tailscale admin > Settings > Keys
- `tailscale_tailnet` — your tailnet name (e.g., `example.ts.net`)
- `ssh_public_key` — your public key (`cat ~/.ssh/id_ed25519.pub`)
- `domain` — base domain for Traefik (e.g., `home.example.com`)

---

## Step 4 — Deploy Phase 1 (Core)

```bash
cd tofu/
tofu init
tofu validate       # Should report: Success! The configuration is valid.

# Plan and review Phase 1 only
tofu plan -target=module.phase1_core

# Apply Phase 1
tofu apply -target=module.phase1_core -target=tailscale_tailnet_key.phase1_core
```

**Verify Phase 1:**
```bash
# Traefik responds
curl -k https://192.168.1.200/ping

# Tailscale — LXC appears in tailnet
tailscale status | grep printarr-core

# Create the shared Docker network (done once on core, or per-host)
ssh root@192.168.1.200 "docker network create proxy"
```

---

## Step 5 — Configure DNS / Wildcard

Point `*.home.example.com` to `192.168.1.200` (Traefik).

For internal-only setups, use your router's local DNS (e.g., AdGuard Home, Pi-hole, or Unbound) to create a wildcard A record.

---

## Step 6 — Deploy Phase 2 (DAM)

```bash
# Set up .env files on target LXCs first
scp docker/phase2-dam/manyfold/.env.example root@192.168.1.210:/opt/printarr/.env
ssh root@192.168.1.210 "nano /opt/printarr/.env"   # fill in secrets

scp docker/phase2-dam/makers-vault/.env.example root@192.168.1.211:/opt/printarr/.env
ssh root@192.168.1.211 "nano /opt/printarr/.env"

# Apply Phase 2
tofu apply -target=module.phase2_manyfold -target=tailscale_tailnet_key.phase2_manyfold \
           -target=module.phase2_vault -target=tailscale_tailnet_key.phase2_vault
```

**Verify Phase 2:**
```bash
# Manyfold — OIDC login flow
open https://manyfold.home.example.com
# Should redirect to Google login, then back to Manyfold dashboard

# Makers Vault — oauth2-proxy gate
open https://vault.home.example.com
```

---

## Step 7 — Deploy Phase 3 (Slicing)

```bash
scp docker/phase3-slicing/.env.example root@192.168.1.220:/opt/printarr/.env
ssh root@192.168.1.220 "nano /opt/printarr/.env"

# Copy printer profiles to LXC
scp -r /path/to/local/prusaslicer/profiles root@192.168.1.220:/data/slicer/profiles/

tofu apply -target=module.phase3_slicer -target=tailscale_tailnet_key.phase3_slicer
```

**Verify Phase 3:**
```bash
# Health check
curl https://slicer.home.example.com/healthz -H "X-Api-Key: $SLICER_API_KEY"
# {"status": "ok"}

# List profiles
curl https://slicer.home.example.com/profiles -H "X-Api-Key: $SLICER_API_KEY"

# Test slice
curl -X POST https://slicer.home.example.com/slice \
  -H "X-Api-Key: $SLICER_API_KEY" \
  -F "file=@/tmp/test.stl" \
  -F "profile=my_printer" \
  -o test.gcode
```

---

## Step 8 — Prepare Klipper for Remote TCP

On the printer Raspberry Pi, edit `/etc/klipper/moonraker.conf` (or equivalent) to allow remote connections:

```ini
[server]
host: 0.0.0.0    # Listen on all interfaces, not just localhost
port: 7125

[authorization]
trusted_clients:
    192.168.1.0/24
    100.64.0.0/10
```

Restart Moonraker: `sudo systemctl restart moonraker`

---

## Step 9 — Deploy Phase 4 (Orchestration)

```bash
scp docker/phase4-orchestration/.env.example root@192.168.1.230:/opt/printarr/.env
ssh root@192.168.1.230 "nano /opt/printarr/.env"   # set KLIPPY_HOST to RPi IP

tofu apply -target=module.phase4_orchestrator -target=tailscale_tailnet_key.phase4_orchestrator \
           -target=module.phase4_inventory -target=tailscale_tailnet_key.phase4_inventory
```

**Verify Phase 4:**
```bash
# Moonraker — printer status via API
curl https://moonraker.home.example.com/printer/info

# Spoolman — spool list
curl https://spoolman.home.example.com/api/v1/spool

# HomeBox — should load UI
open https://homebox.home.example.com
```

**Configure Spoolman ↔ Moonraker webhook:**

The `[spoolman]` section in `moonraker.conf` handles this automatically.
Verify in Moonraker logs: `docker logs moonraker | grep spoolman`

---

## Step 10 — Deploy Phase 5 (Fleet & AI)

```bash
scp docker/phase5-fleet/.env.example root@192.168.1.240:/opt/printarr/.env
ssh root@192.168.1.240 "nano /opt/printarr/.env"

tofu apply -target=module.phase5_fleet -target=tailscale_tailnet_key.phase5_fleet
```

**Link OctoEverywhere:**
```bash
ssh root@192.168.1.240
docker exec octoeverywhere-agent python3 -m octoeverywhere --link
# Follow the URL shown to associate with your OctoEverywhere account
```

---

## Step 11 — End-to-End Smoke Test

```bash
# 1. Upload STL to Makers Vault via API
curl -X POST https://vault.home.example.com/api/models \
  -H "Authorization: Bearer $VAULT_TOKEN" \
  -F "file=@benchy.stl"

# 2. Trigger slice via Slicer API
curl -X POST https://slicer.home.example.com/slice \
  -H "X-Api-Key: $SLICER_API_KEY" \
  -F "file=@benchy.stl" \
  -F "profile=prusa_mk4" \
  -o benchy.gcode

# 3. Upload G-code to Moonraker
curl -X POST https://moonraker.home.example.com/server/files/upload \
  -H "X-Api-Key: $MOONRAKER_API_KEY" \
  -F "file=@benchy.gcode"

# 4. Verify file appears in Moonraker file list
curl https://moonraker.home.example.com/server/files/list
```

---

## Maintenance

### Updating Services

```bash
# On the target LXC
ssh root@192.168.1.210
cd /opt/printarr
docker compose pull
docker compose up -d
```

### Viewing Logs

```bash
# Traefik access log
ssh root@192.168.1.200 "docker logs traefik -f"

# Moonraker
ssh root@192.168.1.230 "docker logs moonraker -f"

# Slicer API
ssh root@192.168.1.220 "docker logs slicer-api -f"
```

### Teardown

```bash
cd tofu/
tofu destroy   # Destroys all LXC containers — data volumes on host are preserved
```

To also remove data:
```bash
ssh root@<proxmox-host> "rm -rf /data/manyfold /data/makers-vault /data/slicer"
```
