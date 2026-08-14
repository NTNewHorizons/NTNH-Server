# NTNH Server

Server-side version of the **Nuclear Tech: New Horizons** modpack for Minecraft 1.7.10.

> ⚠️ This repository is **auto-generated** from the [client repo](https://github.com/NTNewHorizons/NTNH). Files in `mods/`, `config/`, `scripts/`, `serverutilities/` are overwritten on each release, and a distribution **release** (zip of the whole repo) is published automatically with every sync.

---

## Quick Start

### Linux

**Requirements:** Linux with `curl` + `unzip`, Java 8, 4 GB+ RAM

```bash
mkdir ntnh-server && cd ntnh-server
curl -fsSL https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/install.sh | bash
./start.sh
```

That's it - no `git`, no Git LFS. The installer downloads the latest release zip, unpacks it into the current folder, writes a default `server-args.txt`, and `start.sh` checks Java, accepts the EULA, and launches the server.

### Windows

**Requirements:** Windows 10/11 with PowerShell 5.1+, Java 8, 4 GB+ RAM

1. Create a dedicated folder, e.g. `C:\ntnh-server`.
2. Download `install.bat` into it:
   ```powershell
   Invoke-WebRequest -Uri https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/install.bat -OutFile install.bat
   ```
   (or just save `https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/install.bat` as `install.bat`).
3. Double-click `install.bat` (or run it from a command prompt). It downloads the latest release zip, unpacks it into the current folder, and writes a default `server-args.txt`.
4. Double-click `start.bat` to launch the server.

No `git`, no Git LFS, no WSL required. `install.bat` and `update.bat` are self-extracting batch+PowerShell scripts - no extra tools needed.

### Updating

**Linux:**
```bash
./update.sh
```

**Windows:** double-click `update.bat` (or run `start.bat --update`).

Both check for a newer release and replace `mods/`, `config/`, `scripts/`, `serverutilities/`, `libraries/`, `falsepattern/`, `hbmComputerUpload/` and the jars with the new versions. Your `world/`, `server.properties`, `ops.json`, `whitelist.json`, `logs/`, `server-args.txt` and other instance data are **never touched**.

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

`start.bat` launches the server; `install.bat` / `update.bat` handle install and update on Windows (PowerShell 5.1+ built in).

### Docker

The old `docker/` folder was removed during an upstream sync. Bring it back if you need it.

---

## How releases work (for maintainers)

1. A release is published on the [client repo](https://github.com/NTNewHorizons/NTNH).
2. `sync-server.yml` (client) pushes the modpack content into this repo.
3. The same workflow builds `ntnh-server-<version>.zip` (with the real HBM mod jar - the LFS pointer is materialized via `git lfs pull`) and creates a GitHub Release here.
4. End users run `install.sh` / `update.sh` (Linux) or `install.bat` / `update.bat` (Windows), which fetch that release.
