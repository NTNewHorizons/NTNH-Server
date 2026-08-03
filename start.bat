@echo off
setlocal
cd /d "%~dp0"

rem NTNH Server - single entry point (Windows)
rem Update: start.bat --update
rem Start:  start.bat

if /i "%~1"=="--update" (
    git fetch origin main || goto :fail
    git reset --hard origin/main || goto :fail
    echo Updated to latest version. Run start.bat to start.
    pause
    exit /b 0
)

rem Minecraft 1.7.10 requires Java 8.
java -version 2>&1 | findstr /c:"1.8" >nul
if errorlevel 1 (
    echo ERROR: Java 8 is required.
    java -version 2>&1
    pause
    exit /b 1
)

rem Accept the Minecraft EULA.
>eula.txt echo eula=true

rem Replace Git LFS pointer files with the real files from GitHub.
rem Uses the LFS batch API via PowerShell; no git-lfs install required.
echo Checking for Git LFS pointer files...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0resolve-lfs.ps1"
if errorlevel 1 (
    echo.
    echo ERROR: One or more server files could not be downloaded correctly.
    pause
    exit /b 1
)

rem Critical files must exist and be real jars (not LFS pointers).
for %%F in (server.jar minecraft_server.1.7.10.jar) do (
    if not exist "%%F" (
        echo ERROR: required file %%F is missing.
        pause
        exit /b 1
    )
    powershell.exe -NoLogo -NoProfile -Command "$l = Get-Content -LiteralPath '%%~F' -TotalCount 1 -ErrorAction SilentlyContinue; if ($l -and $l.Trim() -eq 'version https://git-lfs.github.com/spec/v1') { exit 1 }"
    if errorlevel 1 (
        echo ERROR: %%F is still a Git LFS pointer ^(download failed^).
        pause
        exit /b 1
    )
)

rem Use JVM_OPTS from the environment; otherwise read server-args.txt.
if not defined JVM_OPTS if exist server-args.txt set /p "JVM_OPTS="<server-args.txt

java %JVM_OPTS% -jar server.jar nogui
set "EXIT_CODE=%ERRORLEVEL%"
pause
exit /b %EXIT_CODE%

:fail
echo ERROR: The requested operation failed.
pause
exit /b 1
