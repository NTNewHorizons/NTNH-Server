@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

rem NTNH Server - single entry point (Windows)
rem Install: download install.bat into an empty folder and run it.
rem Update:  update.bat   (or: start.bat --update)
rem Start:   start.bat
rem Edit server-args.txt to change memory / JVM settings.

if /i "%~1"=="--update" (
    call update.bat
    exit /b !ERRORLEVEL!
)

set "SERVER_JAR=forge-1.7.10-10.13.4.1614-1.7.10-universal.jar"

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

if not exist "%SERVER_JAR%" (
    echo ERROR: required file %SERVER_JAR% is missing.
    pause
    exit /b 1
)

rem Use JVM_OPTS from the environment; otherwise read server-args.txt.
if not defined JVM_OPTS if exist server-args.txt set /p "JVM_OPTS="<server-args.txt

java %JVM_OPTS% -jar "%SERVER_JAR%" nogui
set "EXIT_CODE=%ERRORLEVEL%"
pause
exit /b %EXIT_CODE%


