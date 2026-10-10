#!/usr/bin/env bash
# Steam Frame LSFG Installation Script
# Deploys ARM64 Vulkan layer, wrapper script, profiles, and optional Decky plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Installing Steam Frame LSFG Support ==="

# 1. Run Verification
if [ -f "$SCRIPT_DIR/verify-env.sh" ]; then
    bash "$SCRIPT_DIR/verify-env.sh"
fi

# 2. Setup Directories
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/steam-frame-lsfg"
VULKAN_LAYER_DIR="$HOME/.local/share/vulkan/implicit_layer.d"
LIB_DIR="$HOME/.local/share/steam-frame-lsfg/lib"

mkdir -p "$CONFIG_DIR/profiles"
mkdir -p "$VULKAN_LAYER_DIR"
mkdir -p "$LIB_DIR"
mkdir -p "$HOME/.local/bin"

# 3. Copy Default Configurations if not already present
if [ ! -f "$CONFIG_DIR/config.toml" ]; then
    echo "Creating default configuration at $CONFIG_DIR/config.toml..."
    cp "$ROOT_DIR/config/config.default.toml" "$CONFIG_DIR/config.toml"
fi

cp -r "$ROOT_DIR/config/profiles/"* "$CONFIG_DIR/profiles/"
echo "Default game profiles installed to $CONFIG_DIR/profiles/"

# 4. Install Vulkan Layer Manifest
echo "Installing Vulkan Layer manifest..."
cp "$ROOT_DIR/layer/VkLayer_lsfg.json" "$VULKAN_LAYER_DIR/VkLayer_lsfg.json"

# 5. Install Launch Wrapper
chmod +x "$SCRIPT_DIR/lsfg-frame"
cp "$SCRIPT_DIR/lsfg-frame" "$HOME/.local/bin/lsfg-frame"

# Create standard user shortcut: ~/lsfg
ln -sf "$SCRIPT_DIR/lsfg-frame" "$HOME/lsfg"
echo "Launch wrapper installed to: $HOME/lsfg"

# 6. Optional Decky Loader Integration
DECKY_PLUGIN_DIR="$HOME/homebrew/plugins"
if [ -d "$DECKY_PLUGIN_DIR" ]; then
    echo "Decky Loader detected! Installing Steam Frame LSFG plugin..."
    TARGET_PLUGIN="$DECKY_PLUGIN_DIR/steam-frame-lsfg"
    rm -rf "$TARGET_PLUGIN"
    mkdir -p "$TARGET_PLUGIN"
    cp -r "$ROOT_DIR/decky-plugin/"* "$TARGET_PLUGIN/"
    echo "Decky plugin installed to $TARGET_PLUGIN"
    if systemctl is-active --quiet plugin_loader.service 2>/dev/null; then
        echo "Restarting Decky Loader service..."
        sudo systemctl restart plugin_loader.service || true
    fi
else
    echo "Decky Loader not found. Standalone mode ready."
fi

echo ""
echo "=== Installation Complete ==="
echo "To use LSFG in any game on Steam Frame:"
echo "1. Open the game's Properties in Steam"
echo "2. Add the following to Launch Options:"
echo "   ~/lsfg %command%"
echo ""
