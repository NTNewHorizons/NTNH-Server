#!/bin/bash
set -euo pipefail

PACKWIZ_URL="${PACKWIZ_URL:-https://raw.githubusercontent.com/NTNewHorizons/NTNH-Server/main/pack.toml}"
BOOTSTRAP_URL="${PACKWIZ_BOOTSTRAP_URL:-https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar}"
ROOT="$(pwd)"

for cmd in curl java; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: required command '$cmd' is missing."; exit 1; }
done

java -version 2>&1 | grep -q '1\.8' || { echo "ERROR: Java 8 is required."; exit 1; }

echo "Installing NTNH server from $PACKWIZ_URL"
curl -fL --retry 3 --retry-delay 2 -o packwiz-installer-bootstrap.jar "$BOOTSTRAP_URL"
java -jar packwiz-installer-bootstrap.jar -g -s server "$PACKWIZ_URL"

if [ ! -f server-args.txt ]; then
    echo '-Xms4G -Xmx8G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100' > server-args.txt
fi

chmod +x start.sh install-packwiz.sh 2>/dev/null || true
echo "NTNH Server installed into $ROOT. Run ./start.sh"
