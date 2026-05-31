#!/bin/bash
set -euo pipefail

# NTNH Server Updater
# Syncs tracked files from upstream while preserving all local server data.
# Safe to run at any time; never touches untracked files like world/, server.properties, etc.

cd "$(dirname "$0")"

if [ ! -d ".git" ]; then
    echo "ERROR: No .git directory found in $(pwd)"
    echo "This script must be placed in the server root directory."
    exit 1
fi

echo "Fetching latest NTNH-Server files from GitHub..."
git fetch origin main

echo "Syncing tracked files with upstream (mods/, config/, scripts/, README.md, etc.)..."
git reset --hard origin/main

echo ""
echo "========================================"
echo "  NTNH Server updated successfully!"
echo "========================================"
echo ""
echo "Updated tracked files from repo:"
echo "  - mods/"
echo "  - config/"
echo "  - scripts/"
echo "  - install/"
echo "  - README.md, knownkeys.txt, etc."
echo ""
echo "Preserved all local/untracked data:"
echo "  - world/"
echo "  - server.properties, eula.txt"
echo "  - ops.json, whitelist.json, banned-*.json"
echo "  - logs/, crash-reports/, backups/"
echo "  - Any other custom files"
echo ""
echo "Restart the server to apply changes."
