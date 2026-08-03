@echo off
setlocal enabledelayedexpansion

rem NTNH Server — single entry point (Windows)
rem First run: git clone <url> && start.bat
rem Update:    start.bat --update
rem Normal:    start.bat

if "%1"=="--update" (
    git fetch origin main
    git reset --hard origin/main
    echo Updated to latest version. Run start.bat to start.
    pause
    exit /b 0
)

rem Java 8 (Minecraft 1.7.10 requires exactly Java 8)
java -version 2>&1 | findstr "1.8" >nul
if errorlevel 1 (
    echo ERROR: Java 8 is required.
    java -version 2>&1
    pause
    exit /b 1
)

rem Accept EULA
echo eula=true > eula.txt

rem Resolve LFS pointers by downloading raw files from raw.githubusercontent.com (no Git LFS required)
set "RAW_BASE=https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/"

rem Use PowerShell for robust URL encoding, retries and download
powershell -NoProfile -Command "& {
  $base = $env:RAW_BASE
  Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\\.git' } | ForEach-Object {
    try {
      $first = Get-Content -Path $_.FullName -TotalCount 1 -ErrorAction Stop
    } catch { $first = $null }
    if ($first -and $first.Trim() -match 'version https://git-lfs.github.com/spec/v1') {
      $rel = $_.FullName.Substring((Get-Location).Path.Length + 1)
      Write-Host ('  Downloading: ' + $rel)
      $enc = [System.Uri]::EscapeDataString($rel)
      $url = $base + $enc
      $attempt = 0
      $max = 3
      $success = $false
      while ($attempt -lt $max) {
        try {
          Invoke-WebRequest -Uri $url -OutFile $_.FullName -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
          Write-Host ('    OK')
          $success = $true
          break
        } catch {
          Write-Host ('    Attempt ' + ($attempt+1) + ' failed: ' + $_.Exception.Message)
          Start-Sleep -Seconds (2 * ($attempt+1))
        }
        $attempt++
      }
      if (-not $success) { Write-Host ('    FAILED: ' + $rel) }
    }
  }
}"

rem JVM options from server-args.txt (can be overridden via JVM_OPTS env var)
if exist server-args.txt (
    for /f "usebackq delims=" %%A in ("server-args.txt") do set JVM_OPTS=%%A
)

java %JVM_OPTS% -jar server.jar nogui
pause
