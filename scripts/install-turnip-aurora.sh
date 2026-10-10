#!/usr/bin/env bash
# Steam Frame LSFG: Balemuni's Aurora Turnip Driver Installer
# Installs and configures the optimized Mesa Turnip driver (Universal build)
# for Qualcomm Snapdragon 8 Gen 3 / Adreno 750.

set -e

DRIVER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/drivers"
mkdir -p "$DRIVER_DIR"

COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_BLUE}=== Balemuni's Aurora Turnip Driver Installer ===${COLOR_RESET}"
echo "Target: Qualcomm Snapdragon 8 Gen 3 (Adreno 750 GPU)"
echo "Target Directory: $DRIVER_DIR"
echo ""

ZIP_FILE="$1"

if [ -n "$ZIP_FILE" ] && [ -f "$ZIP_FILE" ]; then
    echo -e "${COLOR_GREEN}Installing from local archive:${COLOR_RESET} $ZIP_FILE"
    TEMP_DIR=$(mktemp -d)
    unzip -q "$ZIP_FILE" -d "$TEMP_DIR"
else
    echo -e "${COLOR_YELLOW}No local file specified. Fetching latest Aurora Universal release from GitHub...${COLOR_RESET}"
    REPO="Balemuni/Balemunis-Aurora"
    TEMP_DIR=$(mktemp -d)
    
    # Query GitHub releases API for latest Universal asset
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$REPO/releases" | \
        grep -i "browser_download_url" | grep -i "universal" | head -n1 | cut -d '"' -f 4 || true)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${COLOR_YELLOW}Notice: Could not automatically resolve release asset via API.${COLOR_RESET}"
        echo "Please download the UNIVERSAL build zip from: https://github.com/Balemuni/Balemunis-Aurora/releases"
        echo "and run:"
        echo "  bash scripts/install-turnip-aurora.sh <path-to-zip>"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    echo "Downloading: $DOWNLOAD_URL"
    curl -L -o "$TEMP_DIR/aurora-universal.zip" "$DOWNLOAD_URL"
    unzip -q "$TEMP_DIR/aurora-universal.zip" -d "$TEMP_DIR"
fi

# Locate the Vulkan shared object (.so)
SO_PATH=$(find "$TEMP_DIR" -name "*vulkan*freedreno*.so" -o -name "libvulkan_freedreno.so" -o -name "vulkan.adreno.so" | head -n1)

if [ -z "$SO_PATH" ] || [ ! -f "$SO_PATH" ]; then
    echo "ERROR: Could not find libvulkan_freedreno.so or vulkan.adreno.so in archive."
    rm -rf "$TEMP_DIR"
    exit 1
fi

DEST_SO="$DRIVER_DIR/libvulkan_freedreno.so"
cp "$SO_PATH" "$DEST_SO"
chmod +x "$DEST_SO"

# Generate ICD manifest pointing to this custom driver
ICD_JSON="$DRIVER_DIR/freedreno_icd.aarch64.json"
cat <<EOF > "$ICD_JSON"
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "$DEST_SO",
        "api_version": "1.3.0"
    }
}
EOF

rm -rf "$TEMP_DIR"

echo -e "${COLOR_GREEN}✓ Driver installed successfully:${COLOR_RESET}"
echo "  Shared Library: $DEST_SO"
echo "  Vulkan ICD:     $ICD_JSON"
echo ""
echo "The launch wrapper (scripts/lsfg-frame) will automatically prioritize this custom Turnip driver!"
