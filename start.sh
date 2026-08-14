#!/bin/bash
set -e

# NTNH Server - single entry point
# Install: curl -fsSL https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/install.sh | bash
# Update:  ./update.sh   (or: ./start.sh --update)
# Start:   ./start.sh

cd "$(dirname "$0")"

if [ "${1:-}" = "--update" ]; then
    exec ./update.sh
fi

SERVER_JAR="forge-1.7.10-10.13.4.1614-1.7.10-universal.jar"

# Java 8 (Minecraft 1.7.10 requires exactly Java 8)
java -version 2>&1 | grep -q "1.8" || {
    echo "ERROR: Java 8 is required."
    java -version 2>&1 | head -n1
    exit 1
}

# Accept EULA
echo "eula=true" > eula.txt

# Sanity check: the launch jar must exist and be a real jar, not a Git LFS pointer.
if [ ! -f "$SERVER_JAR" ]; then
    echo "ERROR: required file $SERVER_JAR is missing. Re-run the installer or update."
    exit 1
fi
if head -n1 "$SERVER_JAR" | grep -q "git-lfs"; then
    echo "ERROR: $SERVER_JAR is a Git LFS pointer file (incomplete install). Re-run the installer."
    exit 1
fi

# JVM options from server-args.txt (can be overridden via JVM_OPTS env var)
if [ -f server-args.txt ] && [ -z "${JVM_OPTS+set}" ]; then
    JVM_OPTS=$(tr '\n' ' ' < server-args.txt)
fi

exec java $JVM_OPTS -jar "$SERVER_JAR" nogui
