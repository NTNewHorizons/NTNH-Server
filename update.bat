@echo off
setlocal
cd /d "%~dp0"

rem ============================================================
rem  NTNH Server - updater (Windows)
rem  Self-extracting: this file is also a PowerShell script.
rem  It downloads the latest NTNH-Server release zip and replaces
rem  the modpack files. Your world, server.properties, ops.json,
rem  whitelist.json, server-args.txt and other instance data are
rem  NEVER touched.
rem ============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command "$l = Get-Content -LiteralPath '%~f0'; $i = [Array]::IndexOf($l, 'rem ==== PowerShell body starts here ====') + 1; if ($i -le 0) { Write-Host 'ERROR: PowerShell body marker not found.'; exit 1 }; $code = ($l[$i..($l.Length - 1)]) -join [Environment]::NewLine; Invoke-Expression $code" & goto :eof

rem ==== PowerShell body starts here ====
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo   = "NTNewHorizons/NTNH-Server"
$apiUrl = if ($env:NTNH_API_URL) { $env:NTNH_API_URL } else { "https://api.github.com/repos/$repo/releases/latest" }
$root   = (Get-Location).Path

Write-Host "NTNH Server updater"
Write-Host ""

if (-not (Test-Path "$root\.ntnh-version")) {
    Write-Host "ERROR: this folder does not look like an NTNH server install (missing .ntnh-version)."
    Write-Host "Run install.bat first."
    exit 1
}
$current = (Get-Content "$root\.ntnh-version" -Raw).Trim()

# --- fetch latest release ---------------------------------------------------
Write-Host "Fetching latest release from GitHub ..."
$release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "ntnh-updater" } -UseBasicParsing
$latest = $release.tag_name
if (-not $latest) {
    Write-Host "ERROR: could not determine the latest version."
    exit 1
}

Write-Host "Installed: $current"
Write-Host "Latest:    $latest"

# --- version compare (semver-ish; falls back to plain string) ---------------
$upToDate = $false
$newerThanLatest = $false
try {
    $cv = [version]::Parse(($current -replace "^[vV]", ""))
    $lv = [version]::Parse(($latest -replace "^[vV]", ""))
    if ($cv -lt $lv) { } elseif ($cv -gt $lv) { $newerThanLatest = $true } else { $upToDate = $true }
} catch {
    if ($current -eq $latest) { $upToDate = $true }
}

if ($upToDate) {
    Write-Host "Already up to date."
    exit 0
}
if ($newerThanLatest) {
    Write-Host "The installed version is newer than the latest release. Nothing to do."
    exit 0
}

$asset = $release.assets | Where-Object { $_.name -like "ntnh-server-*.zip" } | Select-Object -First 1
if (-not $asset) {
    Write-Host "ERROR: no ntnh-server-*.zip asset found in release $latest."
    exit 1
}

$zipUrl  = $asset.browser_download_url
$zipName = $asset.name

Write-Host "Updating $current -> $latest ..."
Write-Host "Downloading $zipName ..."

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "ntnh-update-$PID"
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
Write-Host "Extracting new release ..."
$stage = Join-Path $root ".ntnh-update-$PID"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $stage)

# --- replace modpack directories --------------------------------------------
$replaceDirs = @("mods", "config", "scripts", "serverutilities", "libraries", "falsepattern", "hbmComputerUpload")
foreach ($d in $replaceDirs) {
    $src = Join-Path $stage $d
    $dst = Join-Path $root $d
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    if (Test-Path $src) { Copy-Item $src $dst -Recurse }
}

# --- replace single files (launchers are moved last) ------------------------
$launchers = @("start.bat", "start.sh", "install.bat", "update.bat", "install.sh", "update.sh")
Get-ChildItem -Path $root -Filter "forge-*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -Path $root -Filter "minecraft_server*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force
foreach ($f in @("Mary-TTS.zip", "README.md")) {
    $src = Join-Path $stage $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $root $f) -Force }
}
Get-ChildItem -Path $stage -Filter "forge-*.jar" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $root $_.Name) -Force
}
Get-ChildItem -Path $stage -Filter "minecraft_server*.jar" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $root $_.Name) -Force
}

# --- version marker ---------------------------------------------------------
Set-Content -Path "$root\.ntnh-version" -Value $latest -Encoding ASCII -NoNewline

Write-Host ""
Write-Host "========================================================"
Write-Host " Updated NTNH Server to $latest"
Write-Host " Your world, server.properties, ops.json, whitelist.json,"
Write-Host " server-args.txt and other instance data were untouched."
Write-Host "   - run  start.bat  to start the server"
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

