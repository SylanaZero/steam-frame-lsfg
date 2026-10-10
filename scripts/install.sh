#!/usr/bin/env bash
# Steam Frame LSFG Installation Script
# Deploys ARM64 Vulkan layer, wrapper script, profiles, and optional Decky plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Installing Steam Frame LSFG Support ==="

# 1. Setup Directories
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/steam-frame-lsfg"
VULKAN_LAYER_DIR="$HOME/.local/share/vulkan/implicit_layer.d"
LIB_DIR="$HOME/.local/share/steam-frame-lsfg/lib"

mkdir -p "$CONFIG_DIR/profiles"
mkdir -p "$VULKAN_LAYER_DIR"
mkdir -p "$LIB_DIR"
mkdir -p "$HOME/.local/bin"

# 2. Deploy bundled Lossless.dll if included in package
if [ -f "$ROOT_DIR/Lossless.dll" ]; then
    echo "Installing bundled Lossless.dll..."
    cp "$ROOT_DIR/Lossless.dll" "$LIB_DIR/Lossless.dll"
    STEAM_DIR="$HOME/.local/share/Steam/steamapps/common/Lossless Scaling"
    mkdir -p "$STEAM_DIR"
    cp "$ROOT_DIR/Lossless.dll" "$STEAM_DIR/Lossless.dll"
    echo "Lossless.dll deployed to: $STEAM_DIR/Lossless.dll"
fi

# 3. Run Environment Verification
if [ -f "$SCRIPT_DIR/verify-env.sh" ]; then
    bash "$SCRIPT_DIR/verify-env.sh"
fi

# 4. Copy Default Configurations if not already present
if [ ! -f "$CONFIG_DIR/config.toml" ]; then
    echo "Creating default configuration at $CONFIG_DIR/config.toml..."
    cp "$ROOT_DIR/config/config.default.toml" "$CONFIG_DIR/config.toml"
fi

cp -r "$ROOT_DIR/config/profiles/"* "$CONFIG_DIR/profiles/"
echo "Default game profiles installed to $CONFIG_DIR/profiles/"

# 5. Install Vulkan Layer Library and Manifests
echo "Installing Vulkan Layer binary and manifests..."
if [ -f "$ROOT_DIR/layer/liblsfg-vk-layer.so" ]; then
    cp "$ROOT_DIR/layer/liblsfg-vk-layer.so" "$LIB_DIR/liblsfg-vk-layer.so"
    cp "$ROOT_DIR/layer/liblsfg-vk-layer.so" "$LIB_DIR/libVkLayer_lsfg.so"
fi
if [ -f "$ROOT_DIR/layer/VkLayer_LSFGVK_frame_generation.json" ]; then
    cp "$ROOT_DIR/layer/VkLayer_LSFGVK_frame_generation.json" "$VULKAN_LAYER_DIR/VkLayer_LSFGVK_frame_generation.json"
fi
if [ -f "$ROOT_DIR/layer/VkLayer_lsfg.json" ]; then
    cp "$ROOT_DIR/layer/VkLayer_lsfg.json" "$VULKAN_LAYER_DIR/VkLayer_lsfg.json"
fi

# 6. Install Launch Wrapper
chmod +x "$SCRIPT_DIR/lsfg-frame"
cp "$SCRIPT_DIR/lsfg-frame" "$HOME/.local/bin/lsfg-frame"
chmod +x "$HOME/.local/bin/lsfg-frame"

# Create standard user shortcut: ~/lsfg pointing to permanent installed copy
ln -sf "$HOME/.local/bin/lsfg-frame" "$HOME/lsfg"
echo "Launch wrapper installed to: $HOME/.local/bin/lsfg-frame"
echo "User shortcut created:       $HOME/lsfg"

# 7. Optional Decky Loader Integration
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
