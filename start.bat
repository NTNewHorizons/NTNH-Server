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

rem Resolve LFS pointers by downloading raw files from GitHub (no Git LFS required)
set RAW_BASE=https://github.com/NTNewHorizons/NTNH-Server/raw/main/

rem Use PowerShell for robust URL encoding and download
powershell -NoProfile -Command "Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\\.git' } | ForEach-Object { $first = Select-String -Path $_.FullName -Pattern 'version https://git-lfs.github.com/spec/v1' -SimpleMatch -Quiet; if ($first) { $rel = $_.FullName.Substring((Get-Location).Path.Length + 1); Write-Host ('  Downloading: ' + $rel); $enc = [System.Uri]::EscapeDataString($rel); try { Invoke-WebRequest -Uri ($env:RAW_BASE + $enc) -OutFile $_.FullName -ErrorAction Stop } catch { Write-Host ('  FAILED: ' + $rel) } } }"

rem JVM options from server-args.txt (can be overridden via JVM_OPTS env var)
if exist server-args.txt (
    for /f "usebackq delims=" %%A in ("server-args.txt") do set JVM_OPTS=%%A
)

java %JVM_OPTS% -jar server.jar nogui
pause
