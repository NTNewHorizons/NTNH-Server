#!/bin/bash
set -euo pipefail

# NTNH Server updater.
#
# Downloads the latest release archive and replaces the modpack files
# (mods, config, scripts, ...) with the new versions. Your world data,
# server.properties, ops/whitelist, eula.txt and server-args.txt are
# never touched.

cd "$(dirname "$0")"

REPO="NTNewHorizons/NTNH-Server"
API="${NTNH_API_URL:-https://api.github.com/repos/$REPO/releases/latest}"

if [ ! -f .ntnh-version ]; then
    echo "ERROR: this directory does not look like an NTNH server install (missing .ntnh-version)."
    echo "Install it first:  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
    exit 1
fi

CURRENT="$(cat .ntnh-version)"

# --- Prerequisites ----------------------------------------------------------
for cmd in curl unzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: required command '$cmd' is missing."
        exit 1
    fi
done

# --- Latest release -----------------------------------------------------------
echo "Fetching latest release info from $API ..."
RELEASE_JSON="$(curl -fsSL "$API")"

LATEST="$(printf '%s' "$RELEASE_JSON" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
ZIP_URL="$(printf '%s' "$RELEASE_JSON" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\.zip\)".*/\1/p' | head -n1)"

if [ -z "$LATEST" ] || [ -z "$ZIP_URL" ]; then
    echo "ERROR: could not fetch the latest release from $REPO."
    exit 1
fi

echo "Installed: $CURRENT"
echo "Latest:    $LATEST"

# Version compare (sort -V handles 2.9.0 -> 2.10.0 correctly).
NEWER="$(printf '%s\n%s\n' "$CURRENT" "$LATEST" | sort -V | tail -n1)"
if [ "$NEWER" = "$CURRENT" ] && [ "$CURRENT" != "$LATEST" ]; then
    echo "The installed version is newer than the latest release. Nothing to do."
    exit 0
fi
if [ "$CURRENT" = "$LATEST" ]; then
    echo "Already up to date."
    exit 0
fi

echo "Updating $CURRENT -> $LATEST ..."
echo "Downloading $ZIP_URL ..."

ZIP="/tmp/ntnh-server-$LATEST.zip"
rm -f "$ZIP"
curl -fL --retry 3 --retry-delay 2 -o "$ZIP" "$ZIP_URL"

# --- Checksum (optional) ------------------------------------------------------
SUM_URL="${ZIP_URL}.sha256"
if SUM="$(curl -fsSL "$SUM_URL" 2>/dev/null)"; then
    EXPECTED="$(printf '%s' "$SUM" | awk '{print $1}')"
    ACTUAL="$(sha256sum "$ZIP" | awk '{print $1}')"
    if [ "$EXPECTED" != "$ACTUAL" ]; then
        echo "ERROR: SHA256 mismatch for $ZIP"
        echo "  expected: $EXPECTED"
        echo "  actual:   $ACTUAL"
        exit 1
    fi
    echo "Checksum verified."
else
    echo "WARNING: could not fetch the checksum; skipping verification."
fi

echo "Extracting new release ..."
# Stage inside the install dir so 'mv' below is an atomic rename on the same
# filesystem (the running update.sh is replaced via rename, never via copy).
STAGE="$PWD/.ntnh-update-$$"
rm -rf "$STAGE"
mkdir -p "$STAGE"
unzip -q -o "$ZIP" -d "$STAGE"

# --- Replace modpack files -----------------------------------------------------
# Directories are replaced wholesale (removed mods / configs get cleaned up).
REPLACE_DIRS="mods config scripts serverutilities libraries falsepattern hbmComputerUpload"
for d in $REPLACE_DIRS; do
    rm -rf "./$d"
    if [ -e "$STAGE/$d" ]; then
        cp -a "$STAGE/$d" "./$d"
    fi
done

# Single files that come from the release.
rm -f ./forge-*.jar ./minecraft_server*.jar
for pattern in "forge-*.jar" "minecraft_server*.jar" "Mary-TTS.zip" "start.bat" "README.md"; do
    for f in "$STAGE"/$pattern; do
        [ -e "$f" ] || continue
        cp -f "$f" "./$(basename "$f")"
    done
done

# --- Finalize ------------------------------------------------------------------
echo "$LATEST" > .ntnh-version
chmod +x start.sh 2>/dev/null || true

cat <<EOF

========================================================
 Updated NTNH Server to $LATEST
 Your world data, server.properties, ops/whitelist and
 server-args.txt were left untouched.
 Run  ./start.sh  to start the server.
========================================================
EOF

# --- Replace launcher scripts (atomic rename, keeps this script readable) -----
for f in start.sh update.sh install.sh; do
    if [ -e "$STAGE/$f" ]; then
        mv -f "$STAGE/$f" "./$f"
        chmod +x "./$f" 2>/dev/null || true
    fi
done

rm -rf "$STAGE" "$ZIP"
