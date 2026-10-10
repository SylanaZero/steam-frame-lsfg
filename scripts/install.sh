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

# 2. Check for Lossless.dll in Steam libraries; deploy bundled fallback only if not present
EXISTING_DLL=""
SEARCH_PATHS=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/lib/Lossless.dll"
    "$HOME/.steam/steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "$HOME/.local/share/Steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "/run/media/*/steamapps/common/Lossless Scaling/Lossless.dll"
    "/run/media/*/*/steamapps/common/Lossless Scaling/Lossless.dll"
)
for p in "${SEARCH_PATHS[@]}"; do
    for match in $p; do
        if [ -f "$match" ]; then
            EXISTING_DLL="$match"
            break 2
        fi
    done
done

if [ -n "$EXISTING_DLL" ]; then
    echo "Existing Lossless.dll detected: $EXISTING_DLL"
    [ ! -f "$LIB_DIR/Lossless.dll" ] && cp "$EXISTING_DLL" "$LIB_DIR/Lossless.dll"
elif [ -f "$ROOT_DIR/Lossless.dll" ]; then
    echo "No existing Steam Lossless.dll found. Deploying bundled fallback Lossless.dll..."
    cp "$ROOT_DIR/Lossless.dll" "$LIB_DIR/Lossless.dll"
    STEAM_DIR="$HOME/.local/share/Steam/steamapps/common/Lossless Scaling"
    mkdir -p "$STEAM_DIR"
    cp "$ROOT_DIR/Lossless.dll" "$STEAM_DIR/Lossless.dll"
    echo "Lossless.dll deployed to: $LIB_DIR/Lossless.dll"
fi

# 3. Run Environment Verification
if [ -f "$SCRIPT_DIR/verify-env.sh" ]; then
    bash "$SCRIPT_DIR/verify-env.sh"
fi

# 4. Copy Default Configurations (Schema Version 2 for lsfg-vk layer)
echo "Deploying canonical Schema Version 2 configuration..."
cp "$ROOT_DIR/config/config.default.toml" "$CONFIG_DIR/config.toml"

# Upstream lsfg-vk config path symlink
mkdir -p "$HOME/.config/lsfg-vk"
ln -sf "$CONFIG_DIR/config.toml" "$HOME/.config/lsfg-vk/conf.toml"

# 5. Install Vulkan Layer Library and Manifests
echo "Installing Vulkan Layer binary and manifests..."
# Remove legacy/conflicting layer manifests
rm -f "$VULKAN_LAYER_DIR/VkLayer_lsfg.json"
rm -f "$LIB_DIR/libVkLayer_lsfg.so"

if [ -f "$ROOT_DIR/layer/liblsfg-vk-layer.so" ]; then
    cp "$ROOT_DIR/layer/liblsfg-vk-layer.so" "$LIB_DIR/liblsfg-vk-layer.so"
    cp "$ROOT_DIR/layer/liblsfg-vk-layer.so" "$VULKAN_LAYER_DIR/liblsfg-vk-layer.so"
fi

# Write canonical Vulkan 1.3 layer manifest with absolute library path
cat <<EOF > "$VULKAN_LAYER_DIR/VkLayer_LSFGVK_frame_generation.json"
{
  "file_format_version": "1.1.0",
  "layer": {
    "name": "VK_LAYER_LSFGVK_frame_generation",
    "description": "Lossless Scaling frame generation layer",
    "implementation_version": "2",
    "library_path": "$LIB_DIR/liblsfg-vk-layer.so",
    "type": "GLOBAL",
    "api_version": "1.3.0",
    "disable_environment": {
      "DISABLE_LSFGVK": "1"
    }
  }
}
EOF

# Clean up any custom Turnip driver overrides (e.g. from install-turnip-aurora.sh)
# to ensure Valve's native SteamOS Turnip driver is used
if [ -d "$HOME/.local/share/steam-frame-lsfg/drivers" ]; then
    echo "Restoring native SteamOS Mesa Turnip driver (removing custom driver override)..."
    rm -rf "$HOME/.local/share/steam-frame-lsfg/drivers"
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
