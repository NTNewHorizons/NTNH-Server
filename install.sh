#!/bin/bash
set -euo pipefail

# NTNH Server installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/install.sh | bash
#   ./install.sh                        (re-run to restore missing files)
#
# Downloads the latest release archive and unpacks it into the current
# directory. No git or Git LFS required.

REPO="NTNewHorizons/NTNH-Server"
API="${NTNH_API_URL:-https://api.github.com/repos/$REPO/releases/latest}"
INSTALL_ROOT="$(pwd)"

# --- Prerequisites --------------------------------------------------------
for cmd in curl unzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: required command '$cmd' is missing."
        echo "Please install it and re-run the installer."
        exit 1
    fi
done

if ! command -v java >/dev/null 2>&1; then
    echo "WARNING: java not found. Install Java 8 before running ./start.sh"
fi

# --- Target directory ------------------------------------------------------
if [ -n "$(ls -A "$INSTALL_ROOT" 2>/dev/null)" ]; then
    if [ -f "$INSTALL_ROOT/start.sh" ] && [ -f "$INSTALL_ROOT/.ntnh-version" ]; then
        echo "Existing NTNH server install detected; restoring any missing files."
    else
        echo "ERROR: the current directory is not empty."
        echo "Install into a dedicated (empty) folder, e.g.:"
        echo "  mkdir ntnh-server && cd ntnh-server"
        exit 1
    fi
fi

# --- Latest release ---------------------------------------------------------
echo "Fetching latest release info from $API ..."
RELEASE_JSON="$(curl -fsSL "$API")"

TAG="$(printf '%s' "$RELEASE_JSON" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
ZIP_URL="$(printf '%s' "$RELEASE_JSON" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\.zip\)".*/\1/p' | head -n1)"

if [ -z "$TAG" ] || [ -z "$ZIP_URL" ]; then
    echo "ERROR: could not find a release archive for $REPO."
    echo "If no release exists yet, you can still install from git:"
    echo "  git clone https://github.com/$REPO.git && cd $REPO && ./start.sh"
    exit 1
fi

echo "Latest release: $TAG"
echo "Downloading $ZIP_URL ..."

ZIP="/tmp/ntnh-server-$TAG.zip"
rm -f "$ZIP"
curl -fL --retry 3 --retry-delay 2 -o "$ZIP" "$ZIP_URL"

# --- Checksum (optional) ----------------------------------------------------
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

# --- Extract ------------------------------------------------------------------
# Stage inside the install dir so 'mv' below is an atomic rename on the same
# filesystem (an in-place ./install.sh run is replaced via rename, never via copy).
echo "Extracting archive ..."
STAGE="$INSTALL_ROOT/.ntnh-install-$$"
rm -rf "$STAGE"
mkdir -p "$STAGE"
unzip -q -o "$ZIP" -d "$STAGE"
rm -f "$ZIP"

# Copy everything except the launcher scripts (they are placed last).
(cd "$STAGE" && for e in * .[!.]*; do
    [ -e "$e" ] || continue
    case "$e" in
        start.sh|start.bat|update.sh|install.sh) continue ;;
    esac
    if [ -e "$INSTALL_ROOT/$e" ]; then
        rm -rf "$INSTALL_ROOT/$e"
    fi
    cp -a "$e" "$INSTALL_ROOT/"
done)

echo "$TAG" > "$INSTALL_ROOT/.ntnh-version"

# Default JVM options if server-args.txt was not shipped (it is preserved on updates).
if [ ! -f "$INSTALL_ROOT/server-args.txt" ]; then
    echo "-Xms4G -Xmx8G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100" > "$INSTALL_ROOT/server-args.txt"
    echo "Created default server-args.txt (edit it to change memory / JVM settings)."
fi

cat <<EOF

========================================================
 NTNH Server $TAG installed into $INSTALL_ROOT
   - Run  ./start.sh   to start the server
   - Run  ./update.sh  to check for and apply updates
========================================================
EOF

# --- Place launcher scripts (atomic rename) ----------------------------------
for f in start.sh start.bat update.sh install.sh; do
    if [ -e "$STAGE/$f" ]; then
        mv -f "$STAGE/$f" "$INSTALL_ROOT/$f"
        chmod +x "$INSTALL_ROOT/$f" 2>/dev/null || true
    fi
done

rm -rf "$STAGE"
