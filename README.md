# NTNH Server

Server-side version of the **Nuclear Tech: New Horizons** modpack for Minecraft 1.7.10.

> ⚠️ **This repository is auto-generated** from the [client repository](https://github.com/NTNewHorizons/NTNH). Do not edit files in `mods/`, `config/`, `scripts/` or `serverutilities/` manually - they will be overwritten on the next update.

---

## How It Works

We maintain **two repositories**:

| Repository | Purpose | What lives there |
|---|---|---|
| `NTNewHorizons/NTNH` | Client pack | All mods, configs, scripts |
| `NTNewHorizons/NTNH-Server` | Server pack | Same files minus client-only mods, plus server installer & Docker files |

Whenever a **release** is published on the client repo, a GitHub Action automatically:
1. Reads `server/client-only.txt` from the client repo
2. Copies everything **except** the listed client-only files
3. Pushes the result here

---

## Quick Start

### Requirements
- **Java 8** (OpenJDK or Oracle, exactly version 8 - newer versions will crash 1.7.10)
- **4 GB RAM** minimum, **8 GB** recommended
- Linux, macOS, or Windows

### First-Time Install

```bash
git clone https://github.com/NTNewHorizons/NTNH-Server.git ntnh-server
cd ntnh-server
chmod +x ./install/install.sh
./install/install.sh
```

The installer checks your Java version, clones the server files, accepts the Mojang EULA, and creates `start.sh`.

### Updating an Existing Server

The updater force-syncs **tracked files** (everything stored in this repo) to the latest upstream version. **Untracked files are never touched.**

**Preserved (untracked):**
- `world/` - map, player data, inventories
- `server.properties`, `eula.txt`
- `ops.json`, `whitelist.json`, `banned-*.json`
- `logs/`, `crash-reports/`, `backups/`, `dynmap/`
- Any custom files or plugins you added

**Overwritten (tracked):**
- `mods/`, `config/`, `scripts/`, `serverutilities/`
- `install/`, `README.md`, `knownkeys.txt`, etc.

```bash
cd ntnh-server
./install/install.sh --update
```

This runs `git fetch origin main && git reset --hard origin/main`, which guarantees the update succeeds even if you previously deleted or modified tracked files locally. Restart the server after updating.

> **Tip:** If you customized a tracked config file and want to keep those edits, back it up before updating. Consider moving persistent custom settings into untracked files or scripts where possible.

---

## Docker

If you prefer containers:

```bash
cd install/docker
docker compose up -d
```

The world and backups are stored in local volumes (`./world`, `./backups`).

To update:
```bash
git pull
docker compose up -d --build
```

---

## Client-Only Mods

The client repo maintains a file called `server/client-only.txt` that lists mods which should never exist on a server (e.g. minimaps, HUD mods, visual effects).

If a mod is missing here and you think it should be, open an issue on the **client repository** - that is where the list is maintained.

---

## Support

- **Bugs & mod issues:** [NTNH Issues](https://github.com/NTNewHorizons/NTNH/issues)
- **Server setup issues:** [NTNH-Server Issues](https://github.com/NTNewHorizons/NTNH-Server/issues)
