@echo off
setlocal
cd /d "%~dp0"

rem ============================================================
rem  NTNH Server - installer (Windows)
rem  Self-extracting: this file is also a PowerShell script.
rem  It downloads the latest NTNH-Server release zip and unpacks
rem  it into the CURRENT folder. No git or Git LFS required.
rem ============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command "$l = Get-Content -LiteralPath '%~f0'; $i = [Array]::IndexOf($l, 'rem ==== PowerShell body starts here ====') + 1; if ($i -le 0) { Write-Host 'ERROR: PowerShell body marker not found.'; exit 1 }; $code = ($l[$i..($l.Length - 1)]) -join [Environment]::NewLine; Invoke-Expression $code" & goto :eof

rem ==== PowerShell body starts here ====
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo    = "NTNewHorizons/NTNH-Server"
$apiUrl  = if ($env:NTNH_API_URL) { $env:NTNH_API_URL } else { "https://api.github.com/repos/$repo/releases/latest" }
$root    = (Get-Location).Path

Write-Host "NTNH Server installer"
Write-Host "Target folder: $root"
Write-Host ""

# --- target folder guard ----------------------------------------------------
$items = @(Get-ChildItem -Force -ErrorAction SilentlyContinue)
if ($items.Count -gt 0) {
    $existingInstall = (Test-Path "$root\start.bat") -and (Test-Path "$root\.ntnh-version")
    if (-not $existingInstall) {
        Write-Host "ERROR: the current folder is not empty."
        Write-Host "Install into a dedicated, empty folder (or an existing install)."
        exit 1
    }
    Write-Host "Existing install detected; restoring missing files."
}

# --- find latest release ----------------------------------------------------
Write-Host "Fetching latest release from GitHub ..."
$release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "ntnh-installer" } -UseBasicParsing
$tag = $release.tag_name
if (-not $tag) {
    Write-Host "ERROR: could not determine the latest version."
    exit 1
}

$asset = $release.assets | Where-Object { $_.name -like "ntnh-server-*.zip" } | Select-Object -First 1
if (-not $asset) {
    Write-Host "ERROR: no ntnh-server-*.zip asset found in release $tag."
    exit 1
}

$zipUrl  = $asset.browser_download_url
$zipName = $asset.name

Write-Host "Latest release: $tag"
Write-Host "Downloading $zipName ..."

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "ntnh-install-$PID"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$zipPath = Join-Path $tempDir $zipName
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

# --- checksum (best effort) -------------------------------------------------
$sumUrl = "$zipUrl.sha256"
$sumPath = Join-Path $tempDir "$zipName.sha256"
try {
    Invoke-WebRequest -Uri $sumUrl -OutFile $sumPath -UseBasicParsing
    $sumLine = (Get-Content $sumPath -Raw).Trim()
    $expected = ($sumLine -split "\s+")[0]
    $actual = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($expected -ne $actual) {
        Write-Host "ERROR: SHA256 mismatch for $zipName"
        Write-Host "  expected: $expected"
        Write-Host "  actual:   $actual"
        exit 1
    }
    Write-Host "Checksum verified."
} catch {
    Write-Warning "Could not verify checksum ($sumUrl); continuing anyway."
}

# --- extract ----------------------------------------------------------------
Write-Host "Extracting ..."
$stage = Join-Path $root ".ntnh-install-$PID"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $stage)

# --- copy everything except launcher scripts (they are moved last) ----------
$launchers = @("start.bat", "start.sh", "install.bat", "update.bat", "install.sh", "update.sh")
Get-ChildItem -Force $stage | Where-Object { $launchers -notcontains $_.Name } | ForEach-Object {
    $dest = Join-Path $root $_.Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $_.FullName $dest -Recurse
}

# --- default server-args.txt if missing ------------------------------------
if (-not (Test-Path "$root\server-args.txt")) {
    Set-Content -Path "$root\server-args.txt" -Value "-Xms4G -Xmx8G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100" -Encoding ASCII -NoNewline
    Write-Host "Created default server-args.txt (edit it to change memory / JVM settings)."
}

# --- version marker ---------------------------------------------------------
Set-Content -Path "$root\.ntnh-version" -Value $tag -Encoding ASCII -NoNewline

Write-Host ""
Write-Host "========================================================"
Write-Host " NTNH Server $tag installed into $root"
Write-Host "   - run  start.bat   to start the server"
Write-Host "   - run  update.bat  to update it later"
Write-Host "========================================================"
Write-Host ""

# --- place launcher scripts last (best effort: the running .bat may be locked)
try {
    Get-ChildItem -Force $stage | Where-Object { $launchers -contains $_.Name } | ForEach-Object {
        Move-Item -Path $_.FullName -Destination (Join-Path $root $_.Name) -Force
    }
} catch {
    Write-Warning "Could not replace launcher scripts: $($_.Exception.Message)"
}
Remove-Item $stage -Recurse -Force
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

