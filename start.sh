#!/bin/bash
set -e

# NTNH Server — single entry point
# First run: git clone <url> && ./start.sh
# Update:    ./start.sh --update
# Normal:    ./start.sh

cd "$(dirname "$0")"

if [ "$1" = "--update" ]; then
    git fetch origin main
    git reset --hard origin/main
    echo "Updated to latest version. Run ./start.sh to start."
    exit 0
fi

# Java 8 (Minecraft 1.7.10 requires exactly Java 8)
java -version 2>&1 | grep -q "1.8" || {
    echo "ERROR: Java 8 is required."
    java -version 2>&1 | head -n1
    exit 1
}

# Accept EULA
echo "eula=true" > eula.txt

# Resolve Git LFS pointer files (mods/, server jars) using the GitHub LFS batch API.
# No git-lfs required. If python3 is missing, fall back to `git lfs pull`.
echo "Checking for Git LFS pointer files..."
if command -v python3 >/dev/null 2>&1; then
    python3 resolve-lfs.py
elif command -v git-lfs >/dev/null 2>&1 || git lfs version >/dev/null 2>&1; then
    git lfs pull || true
else
    echo "WARNING: python3 not found; cannot resolve LFS pointer files."
fi

# Critical files must exist and be real jars (not LFS pointers).
for f in server.jar minecraft_server.1.7.10.jar; do
    if [ ! -f "$f" ]; then
        echo "ERROR: required file $f is missing."
        exit 1
    fi
    if head -n1 "$f" | grep -q "version https://git-lfs.github.com/spec/v1"; then
        echo "ERROR: $f is still a Git LFS pointer (download failed)."
        exit 1
    fi
done

# JVM options from server-args.txt (can be overridden via JVM_OPTS env var)
if [ -f server-args.txt ] && [ -z "${JVM_OPTS+set}" ]; then
    JVM_OPTS=$(tr '\n' ' ' < server-args.txt)
fi

exec java $JVM_OPTS -jar server.jar nogui
