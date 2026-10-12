#!/usr/bin/env bash
# Steam Frame LSFG Installation Script
# Deploys ARM64 Vulkan layer, wrapper script, profiles, and optional Decky plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/scripts" ]; then
    ROOT_DIR="$SCRIPT_DIR"
elif [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
    ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    ROOT_DIR="$SCRIPT_DIR"
fi

echo "=== Installing Steam Frame LSFG Support ==="

# 1. Setup Directories
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/steam-frame-lsfg"
VULKAN_IMPLICIT_DIR="$HOME/.local/share/vulkan/implicit_layer.d"
VULKAN_EXPLICIT_DIR="$HOME/.local/share/vulkan/explicit_layer.d"
LIB_DIR="$HOME/.local/share/steam-frame-lsfg/lib"

mkdir -p "$CONFIG_DIR/profiles"
mkdir -p "$VULKAN_IMPLICIT_DIR"
mkdir -p "$VULKAN_EXPLICIT_DIR"
mkdir -p "$LIB_DIR"
mkdir -p "$HOME/.local/bin"

# 2. Check for Lossless.dll in Steam libraries; deploy bundled fallback
EXISTING_DLL=""
SEARCH_PATHS=(
    "$HOME/.steam/steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "$HOME/.steam/steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "$HOME/.local/share/Steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "$HOME/.local/share/Steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "/run/media/*/steamapps/common/Lossless Scaling/Lossless.dll"
    "/run/media/*/*/steamapps/common/Lossless Scaling/Lossless.dll"
    "${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/lib/Lossless.dll"
    "${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/lib/lsfg-vk.dll"
    "$ROOT_DIR/Lossless.dll"
    "$ROOT_DIR/lsfg-vk.dll"
    "$SCRIPT_DIR/Lossless.dll"
    "$SCRIPT_DIR/lsfg-vk.dll"
)
for p in "${SEARCH_PATHS[@]}"; do
    for match in $p; do
        if [ -f "$match" ]; then
            EXISTING_DLL="$match"
            break 2
        fi
    done
done

safe_copy_file() {
    local src="$1"
    local dst="$2"
    if [ ! -f "$src" ]; then
        return 0
    fi
    # If source and destination paths are identical, do nothing
    if [ "$src" = "$dst" ]; then
        return 0
    fi
    # If both exist and point to the same physical file / inode, do nothing
    if [ -f "$dst" ]; then
        local src_canon dst_canon
        src_canon="$(realpath "$src" 2>/dev/null || echo "$src")"
        dst_canon="$(realpath "$dst" 2>/dev/null || echo "$dst")"
        if [ "$src_canon" = "$dst_canon" ]; then
            return 0
        fi
    fi
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst" 2>/dev/null || true
}

deploy_dual_dll() {
    local src="$1"
    local dest_dir="$2"
    safe_copy_file "$src" "$dest_dir/Lossless.dll"
    safe_copy_file "$src" "$dest_dir/lsfg-vk.dll"
}

if [ -n "$EXISTING_DLL" ]; then
    echo "Existing framegen DLL detected: $EXISTING_DLL"
    EXISTING_DIR="$(dirname "$EXISTING_DLL")"
    deploy_dual_dll "$EXISTING_DLL" "$LIB_DIR"
    deploy_dual_dll "$EXISTING_DLL" "$EXISTING_DIR"
    echo "Confirmed framegen DLLs ready in: $LIB_DIR"
else
    echo ""
    echo "=========================================================="
    echo "  ERROR: Lossless Scaling DLL was not found!"
    echo "=========================================================="
    echo "Lossless Scaling Frame Generation requires the proprietary"
    echo "shader model from Lossless Scaling (Steam App ID 993090)."
    echo ""
    echo "Please do one of the following:"
    echo "  1. Install 'Lossless Scaling' from your Steam library."
    echo "  2. Or place 'Lossless.dll' or 'lsfg-vk.dll' in this folder."
    echo ""
    echo "Then re-run install.sh."
    echo "=========================================================="
    exit 1
fi

# 3. Run Environment Verification (if bundled)
if [ -f "$SCRIPT_DIR/verify-env.sh" ]; then
    bash "$SCRIPT_DIR/verify-env.sh"
elif [ -f "$ROOT_DIR/scripts/verify-env.sh" ]; then
    bash "$ROOT_DIR/scripts/verify-env.sh"
fi

# 4. Copy Default Configurations (Schema Version 2 for lsfg-vk layer)
echo "Deploying canonical Schema Version 2 configuration..."
CONFIG_SRC=""
for c in "$ROOT_DIR/config/config.default.toml" "$ROOT_DIR/config/config.toml" "$ROOT_DIR/config.toml" "$SCRIPT_DIR/config.toml"; do
    if [ -f "$c" ]; then
        CONFIG_SRC="$c"
        break
    fi
done
if [ -n "$CONFIG_SRC" ]; then
    cp "$CONFIG_SRC" "$CONFIG_DIR/config.toml"
else
    echo "Warning: No config template found, generating minimal config.toml..."
    cat <<EOF > "$CONFIG_DIR/config.toml"
schema_version = 2
enabled = true
multiplier = 2
flow_mode = "quality"
override_present_mode = false
EOF
fi

# Upstream lsfg-vk config path symlink
mkdir -p "$HOME/.config/lsfg-vk"
ln -sf "$CONFIG_DIR/config.toml" "$HOME/.config/lsfg-vk/conf.toml"

# 5. Install Vulkan Layer Library and Manifests
echo "Installing Vulkan Layer binary and manifests..."
# Remove legacy/conflicting layer manifests
rm -f "$VULKAN_IMPLICIT_DIR/VkLayer_lsfg.json" "$VULKAN_EXPLICIT_DIR/VkLayer_lsfg.json"
rm -f "$LIB_DIR/libVkLayer_lsfg.so"

LAYER_SO=""
for s in "$ROOT_DIR/layer/liblsfg-vk-layer.so" "$SCRIPT_DIR/layer/liblsfg-vk-layer.so" "$LIB_DIR/liblsfg-vk-layer.so" "$VULKAN_IMPLICIT_DIR/liblsfg-vk-layer.so" "/usr/lib/liblsfg-vk-layer.so" "/usr/local/lib/liblsfg-vk-layer.so"; do
    if [ -f "$s" ]; then
        LAYER_SO="$s"
        break
    fi
done

if [ -n "$LAYER_SO" ]; then
    safe_copy_file "$LAYER_SO" "$LIB_DIR/liblsfg-vk-layer.so"
    safe_copy_file "$LAYER_SO" "$VULKAN_IMPLICIT_DIR/liblsfg-vk-layer.so"
    safe_copy_file "$LAYER_SO" "$VULKAN_EXPLICIT_DIR/liblsfg-vk-layer.so"
    echo "Configured Vulkan layer from: $LAYER_SO"
else
    echo "Notice: Upstream liblsfg-vk-layer.so not found."
    echo "Please download or install the official lsfg-vk layer from https://lsfg-vk.dev"
    echo "and place liblsfg-vk-layer.so in $LIB_DIR/ or layer/liblsfg-vk-layer.so."
fi


# Write canonical Vulkan 1.3 layer manifest with absolute library path to both directories
for target_dir in "$VULKAN_IMPLICIT_DIR" "$VULKAN_EXPLICIT_DIR"; do
    cat <<EOF > "$target_dir/VkLayer_LSFGVK_frame_generation.json"
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
done

# Clean up any custom Turnip driver overrides (e.g. from install-turnip-aurora.sh)
# to ensure Valve's native SteamOS Turnip driver is used
if [ -d "$HOME/.local/share/steam-frame-lsfg/drivers" ]; then
    echo "Restoring native SteamOS Mesa Turnip driver (removing custom driver override)..."
    rm -rf "$HOME/.local/share/steam-frame-lsfg/drivers"
fi

# 6. Install Launch Wrapper
WRAPPER_SRC=""
for w in "$SCRIPT_DIR/lsfg-frame" "$ROOT_DIR/scripts/lsfg-frame" "$ROOT_DIR/lsfg-frame"; do
    if [ -f "$w" ]; then
        WRAPPER_SRC="$w"
        break
    fi
done

if [ -n "$WRAPPER_SRC" ]; then
    chmod +x "$WRAPPER_SRC"
    cp "$WRAPPER_SRC" "$HOME/.local/bin/lsfg-frame"
    chmod +x "$HOME/.local/bin/lsfg-frame"
    # Create standard user shortcut: ~/lsfg pointing to permanent installed copy
    ln -sf "$HOME/.local/bin/lsfg-frame" "$HOME/lsfg"
    echo "Launch wrapper installed to: $HOME/.local/bin/lsfg-frame"
    echo "User shortcut created:       $HOME/lsfg"
else
    echo "ERROR: lsfg-frame wrapper not found!"
    exit 1
fi

# 7. Optional Decky Loader Integration
DECKY_PLUGIN_DIR="$HOME/homebrew/plugins"
if [ -d "$DECKY_PLUGIN_DIR" ] && [ -d "$ROOT_DIR/decky-plugin" ]; then
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
elif [ -d "$DECKY_PLUGIN_DIR" ]; then
    echo "Decky Loader detected (standalone mode active, plugin not bundled)."
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
