# NTNH Server

Server-side version of the **Nuclear Tech: New Horizons** modpack for Minecraft 1.7.10.

> ⚠️ This repository is **auto-generated** from the [client repo](https://github.com/NTNewHorizons/NTNH). Files in `mods/`, `config/`, `scripts/`, `serverutilities/` are overwritten on each release, and a distribution **release** (zip of the whole repo) is published automatically with every sync.

---

## Quick Start

**Requirements:** Linux with `curl` + `unzip`, Java 8, 4 GB+ RAM

```bash
mkdir ntnh-server && cd ntnh-server
curl -fsSL https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/install.sh | bash
./start.sh
```

That's it - no `git`, no Git LFS. The installer downloads the latest release zip, unpacks it into the current folder, writes a default `server-args.txt`, and `start.sh` checks Java, accepts the EULA, and launches the server.

### Updating

```bash
./update.sh
```

Checks for a newer release and replaces `mods/`, `config/`, `scripts/`, `serverutilities/`, `libraries/`, `falsepattern/`, `hbmComputerUpload/` and the jars with the new versions. Your `world/`, `server.properties`, `ops.json`, `whitelist.json`, `logs/`, `server-args.txt` and other instance data are **never touched**.

### Java Arguments

JVM options are read from `server-args.txt` (edit this file to change memory allocation or GC settings). To override for a single launch, set the `JVM_OPTS` environment variable:

```bash
JVM_OPTS="-Xms2G -Xmx4G" ./start.sh
```

---

## Running from a Git clone (maintainers / forkers)

```bash
git clone https://github.com/NTNewHorizons/NTNH-Server.git
cd NTNH-Server
./start.sh
```

`./start.sh --update` delegates to `./update.sh`. Note that a `git pull` will **not** update `mods/`/`config/` correctly by itself - the modpack content only changes through the sync/release process.

### Windows

`start.bat` launches the server, but the install/update tooling is Linux-only for now (use WSL or a Linux box with `install.sh`/`update.sh`).

### Docker

The old `docker/` folder was removed during an upstream sync. Bring it back if you need it.

---

## How releases work (for maintainers)

1. A release is published on the [client repo](https://github.com/NTNewHorizons/NTNH).
2. `sync-server.yml` (client) pushes the modpack content into this repo.
3. The same workflow builds `ntnh-server-<version>.zip` (with the real HBM mod jar - the LFS pointer is materialized via `git lfs pull`) and creates a GitHub Release here.
4. End users run `install.sh` / `update.sh`, which fetch that release.
