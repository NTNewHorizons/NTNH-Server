# NTNH Server

Server-side version of the **Nuclear Tech: New Horizons** modpack for Minecraft 1.7.10.

> ⚠️ This repository is **auto-generated** from the [client repo](https://github.com/NTNewHorizons/NTNH). Files in `mods/`, `config/`, `scripts/`, `serverutilities/` are overwritten on each release.

---

## Quick Start

**Requirements:** Java 8, 4 GB+ RAM

### Linux

```bash
git clone https://github.com/NTNewHorizons/NTNH-Server.git
cd NTNH-Server
./start.sh
```

That's it. `start.sh` checks Java, accepts the EULA, replaces any Git LFS pointer files with the real files (via GitHub's LFS object API — no git-lfs install required), and launches the server.

### Windows

```batch
git clone https://github.com/NTNewHorizons/NTNH-Server.git
cd NTNH-Server
./start.bat
```

> If you can't install Git LFS, `start.bat` will automatically download large files using PowerShell.

### Java Arguments

JVM options are read from `server-args.txt` (edit this file to change memory allocation or GC settings). To override for a single launch, set the `JVM_OPTS` environment variable:

```bash
JVM_OPTS="-Xms2G -Xmx4G" ./start.sh
```

> If the repository ran out of Git LFS bandwidth or you cannot install Git LFS, don't worry — the start scripts will fetch the real files automatically via GitHub's LFS object API.

### Updating

```bash
./start.sh --update
```

Force-syncs all tracked files to the latest upstream version. Your `world/`, `server.properties`, `ops.json`, `whitelist.json`, `logs/`, and other untracked data are never touched.

### Customizing (Forking)

Want to tweak the modpack for your server - add/remove mods, change configs, edit scripts?

1. **Fork** this repo on GitHub
2. `git clone https://github.com/YOUR_USER/NTNH-Server.git`
3. Make your changes, commit, push
4. Run `./start.sh` on your server

When the upstream NTNH-Server releases an update, sync your fork:

```bash
git remote add upstream https://github.com/NTNewHorizons/NTNH-Server.git
git fetch upstream
git merge upstream/main
```

Resolve any conflicts (your custom files vs new upstream changes) and push.

> ⚠️ Files under `mods/`, `config/`, `scripts/`, `serverutilities/` are overwritten on each upstream release. If you customize them, expect merge conflicts.

### Docker

```bash
cd docker
docker compose up -d
```

---
