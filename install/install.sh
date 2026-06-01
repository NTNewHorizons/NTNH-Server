#!/bin/bash
set -e

# NTNH Server Installer
# Usage: ./install.sh          - First-time install (clone + setup)
#        ./install.sh --update - Update existing server (syncs tracked files, preserves world/ and all untracked data)

# Check for Java 8 (Minecraft 1.7.10 requires exactly Java 8)
echo "Checking Java version..."
java -version 2>&1 | grep -q "1.8" || {
    echo "ERROR: Java 8 is required. Found:"
    java -version 2>&1 | head -n 1
    exit 1
}
echo "Java 8 detected."

# Check for Git LFS
LFS_AVAILABLE=false
if git lfs version >/dev/null 2>&1; then
    LFS_AVAILABLE=true
    echo "Git LFS detected."
else
    echo "WARNING: Git LFS not found. Large files will be downloaded manually (slower)."
    echo "Install Git LFS for better performance: sudo apt install git-lfs"
fi

# Function to resolve LFS pointers to actual files
resolve_lfs_pointers() {
    if [ "$LFS_AVAILABLE" = true ]; then
        git lfs pull
        return
    fi

    echo "Resolving LFS pointers manually..."
    find mods -name "*.jar" -type f | while read -r pointer; do
        # Check if file is an LFS pointer
        if head -n 1 "$pointer" | grep -q "version https://git-lfs.github.com/spec/v1"; then
            filename=$(basename "$pointer")
            echo "  Downloading: $filename"
            encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$filename'))" 2>/dev/null || echo "$filename")
            curl -sL -o "$pointer" "https://github.com/NTNewHorizons/NTNH-Server/raw/main/mods/$encoded" || {
                echo "  FAILED: $filename"
            }
        fi
    done
}

# Update mode: force-sync tracked files with upstream, leave untracked data untouched
if [ "$1" == "--update" ]; then
    echo "Updating server files from NTNH-Server..."

    # If an .updateignore exists, preserve matching tracked files across the update
    if [ -f .updateignore ]; then
        echo "Found .updateignore — preserving matching tracked files..."

        # Gather matching tracked files using Python (supports ** globs via pathlib)
        matches=$(python3 - <<'PY'
import sys,subprocess
from pathlib import PurePath
patterns=[]
with open('.updateignore') as fh:
    for line in fh:
        line=line.strip()
        if not line or line.startswith('#'):
            continue
        patterns.append(line)
if not patterns:
    sys.exit(0)
proc = subprocess.run(['git','ls-files'], stdout=subprocess.PIPE, text=True)
files = proc.stdout.splitlines()
out=[]
for f in files:
    p = PurePath(f)
    for pat in patterns:
        if p.match(pat):
            out.append(f)
            break
print('\n'.join(out))
PY
)

        if [ -n "$matches" ]; then
            # Save list of originally-preserved files
            echo "$matches" > .updateignore.orig
            backup_dir=$(mktemp -d .ntnh_update_backup.XXXX)
            echo "Backing up $(echo "$matches" | wc -l) files to $backup_dir"
            echo "$matches" | while IFS= read -r f; do
                mkdir -p "$backup_dir/$(dirname "$f")"
                cp -p -- "$f" "$backup_dir/$f" 2>/dev/null || true
            done
        fi
    fi

    git fetch origin main
    git reset --hard origin/main
    resolve_lfs_pointers

    # If we backed up files, restore them and remove any newly-added files that match patterns
    if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
        echo "Restoring preserved files..."
        (cd "$backup_dir" && tar -cpf - .) | tar -xpf - -C . || true
        rm -rf "$backup_dir"

        if [ -f .updateignore ]; then
            # Remove newly-added tracked files that match .updateignore but were not present before
            newfiles=$(python3 - <<'PY'
import sys,subprocess,os
from pathlib import PurePath
patterns=[]
with open('.updateignore') as fh:
    for line in fh:
        line=line.strip()
        if not line or line.startswith('#'):
            continue
        patterns.append(line)
orig=set()
if os.path.exists('.updateignore.orig'):
    with open('.updateignore.orig') as fh:
        for l in fh:
            orig.add(l.strip())
proc = subprocess.run(['git','ls-files'], stdout=subprocess.PIPE, text=True)
files = proc.stdout.splitlines()
for f in files:
    p = PurePath(f)
    for pat in patterns:
        if p.match(pat) and f not in orig:
            print(f)
            break
PY
)
            echo "$newfiles" | while IFS= read -r f; do
                [ -z "$f" ] && continue
                git rm -f --ignore-unmatch -- "$f" 2>/dev/null || true
                rm -f -- "$f" 2>/dev/null || true
            done
        fi

        # cleanup
        rm -f .updateignore.orig 2>/dev/null || true
    fi

    echo "Update complete. Restart the server to apply changes."
    exit 0
fi

# First-time install
if [ ! -d ".git" ]; then
    echo "Cloning NTNH-Server repository..."
    if [ "$LFS_AVAILABLE" = true ]; then
        git lfs install
    fi
    git clone https://github.com/NTNewHorizons/NTNH-Server.git .
    resolve_lfs_pointers
else
    echo "Already in NTNH-Server repository, skipping clone..."
    if [ "$LFS_AVAILABLE" = true ]; then
        git lfs install
        git lfs pull
    else
        resolve_lfs_pointers
    fi
fi

# Accept Mojang EULA automatically
echo "eula=true" > eula.txt

# Create the server startup script
cat > start.sh <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
java -Xms4G -Xmx8G \
     -XX:+UseG1GC \
     -XX:+UnlockExperimentalVMOptions \
     -XX:MaxGCPauseMillis=100 \
     -jar forge-1.7.10-10.13.4.1614-1.7.10-universal.jar \
     nogui
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
