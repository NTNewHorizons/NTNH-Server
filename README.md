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
./install/install.sh
./start.sh
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

### Preserving Tracked Files During Updates

You can create a `.updateignore` file in the server directory to mark tracked files you do NOT want the updater to modify, add, or remove. Patterns use shell-style globs with `**` support; see the example `.updateignore` in the repo root.

Behavior during `./install/install.sh --update` when `.updateignore` exists:
- Matching tracked files are backed up before the update and restored afterward (your local contents preserved).
- Any new files added by the upstream update that match `.updateignore` will be removed after the update.

This allows you to keep local customizations for specific tracked files while still receiving other upstream changes.

### Preventing Client Sync from Overwriting Server-Only Mods

The client repository's sync workflow now respects a `server/server-only.txt` file stored in the server repository. If present, the sync will preserve any tracked files matching those patterns (they will not be overwritten or removed by the sync). See [server/server-only.txt](server/server-only.txt) for examples.

Example — ForgeEssentials split

- To keep `ForgeEssentials-Client` only on the client side, add this line in the client repo's `server/client-only.txt`:

  mods/ForgeEssentials-Client*.jar

- To keep `ForgeEssentials-Server` only on the server side, add this line in the server repo's `server/server-only.txt` and also to the server's `.updateignore` if you want the installer to preserve it during `--update`:

  mods/ForgeEssentials-Server*.jar

Quick local steps (examples)

Client repo (mark client-only):

```bash
cd path/to/ntnh-client
git checkout -b chore/client-only-forgeessentials
echo 'mods/ForgeEssentials-Client*.jar' >> server/client-only.txt
git add server/client-only.txt
git commit -m "chore: mark ForgeEssentials-Client as client-only"
git push --set-upstream origin HEAD
```

Server repo (mark server-only):

```bash
cd path/to/NTNH-Server
git checkout -b chore/server-only-forgeessentials
echo 'mods/ForgeEssentials-Server*.jar' >> server/server-only.txt
echo 'mods/ForgeEssentials-Server*.jar' >> .updateignore
git add server/server-only.txt .updateignore
git commit -m "chore: mark ForgeEssentials-Server as server-only"
git push --set-upstream origin HEAD
```

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
