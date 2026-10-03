@echo off
setlocal
cd /d "%~dp0"

if not defined PACKWIZ_URL set "PACKWIZ_URL=https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/pack.toml"
if not defined PACKWIZ_BOOTSTRAP_URL set "PACKWIZ_BOOTSTRAP_URL=https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"

java -version 2>&1 | findstr /c:"1.8" >nul
if errorlevel 1 (
    echo ERROR: Java 8 is required.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri $env:PACKWIZ_BOOTSTRAP_URL -OutFile 'packwiz-installer-bootstrap.jar'"
if errorlevel 1 exit /b 1

java -jar packwiz-installer-bootstrap.jar -g -s server "%PACKWIZ_URL%"
if errorlevel 1 exit /b 1

if not exist server-args.txt >server-args.txt echo -Xms4G -Xmx8G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100
echo NTNH Server installed. Run start.bat
