#!/bin/bash
set -e

# NTNH Server Installer
# Usage: ./install.sh          - First-time install (clone + setup)
#        ./install.sh --update - Update existing server (preserves world/)

# Check for Java 8 (Minecraft 1.7.10 requires exactly Java 8)
echo "Checking Java version..."
java -version 2>&1 | grep -q "1.8" || {
    echo "ERROR: Java 8 is required. Found:"
    java -version 2>&1 | head -n 1
    exit 1
}
echo "Java 8 detected."

# Update mode: just pull latest server files and exit
if [ "$1" == "--update" ]; then
    echo "Updating server files from NTNH-Server..."
    git pull origin main
    echo "Update complete. Restart the server to apply changes."
    exit 0
fi

# First-time install
if [ ! -d ".git" ]; then
    echo "Cloning NTNH-Server repository..."
    git clone https://github.com/NTNewHorizons/NTNH-Server.git .
else
    echo "Already in NTNH-Server repository, skipping clone..."
fi

# Accept Mojang EULA automatically
echo "eula=true" > eula.txt

# Create the server startup script
cat > start.sh <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
java -Xms4G -Xmx8G      -XX:+UseG1GC      -XX:+UnlockExperimentalVMOptions      -XX:MaxGCPauseMillis=100      -jar forge-1.7.10-10.13.4.1614-1.7.10-universal.jar      nogui
EOF
chmod +x start.sh

echo ""
echo "========================================"
echo "  NTNH Server installed successfully!"
echo "========================================"
echo ""
echo "Start the server: ./start.sh"
echo "Edit settings:    nano server.properties"
echo ""
echo "IMPORTANT: Back up your world/ directory regularly!"
