# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Printarr is the **orchestration glue** for a 3D printing automation stack analogous to the media *arr-stack (Sonarr, Radarr, etc.). Its goal is to automate the full SDLC from model discovery through fabrication and inventory — replacing manual file handling, slicing, and machine prep with automated, API-driven handoffs between specialized tools.

### Pipeline Architecture

The stack maps digital media automation concepts to 3D printing:

| Role | Media Stack | 3D Printing Equivalent | Tools |
|---|---|---|---|
| Asset Discovery | Prowlarr | Repository scrapers | Manyfold, Makers Vault |
| Library Management | Radarr/Sonarr | Digital Asset Manager (DAM) | Manyfold, STLVault |
| Processing Engine | Download client | Headless slicer | PrusaSlicer CLI, OrcaSlicer |
| Execution | Plex/Jellyfin | Printer interface | OctoPrint, Mainsail, Fluidd |
| Notifications | Discord/Telegram | Webhooks/IoT | OctoEverywhere, Home Assistant |
| Metadata/Logistics | Bazarr | Filament/inventory | Spoolman, HomeBox |

Printarr is **the missing glue** — the automated orchestration between these layers.

### Key Integration Points

- **Manyfold** (Ruby/Rails/PostgreSQL): federated DAM with ActivityPub support; 2026 roadmap includes a Printer API for direct G-code/model transmission to OctoPrint and Moonraker
- **Makers Vault** (Python/FastAPI/SQLite): folder-centric DAM with a "Slicer Bridge" executable for direct desktop slicer handoff
- **Moonraker API**: preferred integration target for printer orchestration (JSON API, lower overhead than OctoPrint plugin system); bridges Klipper firmware to Mainsail/Fluidd UIs
- **Spoolman**: real-time filament consumption tracking; receives extrusion data from Moonraker/OctoPrint and maintains spool records across multiple printers
- **HomeBox**: physical inventory (hardware, tools, spare parts); 2026 AI vision integration for automatic item tagging

### Deployment Model

Docker Compose is the intended deployment strategy — Manyfold, Moonraker, Spoolman, and HomeBox run as containers. Services communicate over the local network. OIDC handles unified authentication.

## Intended Stack (inferred from .gitignore)

- **Language**: Python
- **Linting**: Ruff
- **Testing**: pytest
- **Package management**: likely Poetry, pip, or UV

## Commands

Update this section once the project structure is established:

```bash
# Install dependencies
pip install -e .
# or: poetry install / uv sync

# Run tests
pytest

# Run a single test
pytest path/to/test_file.py::test_name

# Lint
ruff check .
ruff format .
```
