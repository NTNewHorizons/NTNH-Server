#!/bin/bash
set -e

# NTNH Server — single entry point
# First run: git clone <url> && ./start.sh
# Update:    ./start.sh --update
# Normal:    ./start.sh

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

# Resolve LFS pointers by downloading raw files from raw.githubusercontent.com (no Git LFS required)
RAW_BASE="https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/"

download_pointer() {
    rel="$1"
    # Try python3 for robust URL-encoding, fall back to simple replacements
    if command -v python3 >/dev/null 2>&1; then
        enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$rel")
    else
        enc=$(printf "%s" "$rel" | sed -e 's/ /%20/g' -e 's/\[/%5B/g' -e 's/\]/%5D/g' -e 's/(/%28/g' -e 's/)/%29/g')
    fi
    url="$RAW_BASE$enc"
    mkdir -p "$(dirname "$rel")"
    echo "  Downloading: $rel"
    # Use curl with retries, fail on HTTP errors
    if curl --fail --retry 3 --retry-delay 2 -sS -L -o "$rel" "$url"; then
        # quick sanity check: pointer files are usually small; ensure downloaded file is > 1KB
        sz=$(stat -c%s "$rel" 2>/dev/null || echo 0)
        if [ "$sz" -lt 1024 ]; then
            echo "    WARNING: download size for $rel is suspicious ($sz bytes)"
        fi
        return 0
    else
        echo "    FAILED: $rel"
        return 1
    fi
}

# Walk files and replace any Git LFS pointer files with the real content from the raw GitHub URL.
find . -type f -not -path './.git/*' -print0 | while IFS= read -r -d '' f; do
    if head -n1 "$f" 2>/dev/null | grep -q "version https://git-lfs.github.com/spec/v1"; then
        rel="${f#./}"
        download_pointer "$rel" || true
    fi
done

# Ensure critical files exist (try direct raw downloads as a fallback)
if [ ! -f server.jar ]; then
    echo "server.jar missing — attempting to download directly..."
    download_pointer "server.jar" || true
fi

if [ ! -f minecraft_server.1.7.10.jar ]; then
    echo "minecraft_server.1.7.10.jar missing — attempting to download directly..."
    download_pointer "minecraft_server.1.7.10.jar" || true
fi

# JVM options from server-args.txt (can be overridden via JVM_OPTS env var)
if [ -f server-args.txt ] && [ -z "${JVM_OPTS+set}" ]; then
    JVM_OPTS=$(tr '\n' ' ' < server-args.txt)
fi

exec java $JVM_OPTS -jar server.jar nogui
