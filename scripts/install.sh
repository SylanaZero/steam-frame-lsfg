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

# 2. Check for lsfg-vk.dll in Steam libraries
EXISTING_DLL=""
SEARCH_PATHS=(
    "$HOME/.local/share/Steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "$HOME/.steam/steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "/var/mnt/storage/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "$ROOT_DIR/lsfg-vk.dll"
    "$SCRIPT_DIR/lsfg-vk.dll"
)

# Also check dynamic libraries from libraryfolders.vdf
for vdf in "$HOME/.local/share/Steam/steamapps/libraryfolders.vdf" "$HOME/.steam/steam/steamapps/libraryfolders.vdf"; do
    if [ -f "$vdf" ]; then
        while read -r libpath; do
            [ -n "$libpath" ] && SEARCH_PATHS+=("$libpath/steamapps/common/Lossless Scaling/lsfg-vk.dll")
        done < <(grep '"path"' "$vdf" 2>/dev/null | cut -d '"' -f 4 || true)
    fi
done

for p in "${SEARCH_PATHS[@]}"; do
    if [ -f "$p" ]; then
        EXISTING_DLL="$p"
        break
    fi
done

# Check removable media / SD card paths with wildcards
if [ -z "$EXISTING_DLL" ]; then
    for match in /run/media/*/steamapps/common/Lossless\ Scaling/lsfg-vk.dll /run/media/*/*/steamapps/common/Lossless\ Scaling/lsfg-vk.dll; do
        if [ -f "$match" ]; then
            EXISTING_DLL="$match"
            break
        fi
    done
fi

# Fallback deep search across Steam directories if still not found
if [ -z "$EXISTING_DLL" ]; then
    EXISTING_DLL=$(find "$HOME/.local/share/Steam" "$HOME/.steam" /run/media -iname "lsfg-vk.dll" 2>/dev/null | head -n1 || true)
fi

# Clean up any stale or duplicated DLL in LIB_DIR to ensure in-place usage from Steam
rm -f "$LIB_DIR/lsfg-vk.dll" "$LIB_DIR/Lossless.dll"

safe_copy_file() {
    local src="$1"
    local dst="$2"
    if [ ! -f "$src" ]; then
        return 0
    fi
    if [ "$src" = "$dst" ]; then
        return 0
    fi
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

if [ -n "$EXISTING_DLL" ]; then
    echo "Found official lsfg-vk.dll in Steam: $EXISTING_DLL"
    DLL_SIZE=$(stat -c%s "$EXISTING_DLL" 2>/dev/null || wc -c < "$EXISTING_DLL" 2>/dev/null || echo 0)
    if [ "$DLL_SIZE" -gt 5000000 ]; then
        echo "WARNING: File size ($DLL_SIZE bytes) resembles Windows Lossless.dll (~7.2 MB) rather than Linux lsfg-vk.dll (~2.1 MB)."
        echo "Please make sure Lossless Scaling in Steam is set to the 'lsfg-vk' beta branch."
    else
        echo "Validated official 2.1 MB Linux Vulkan shader model (used in-place from Steam)."
    fi
else
    echo ""
    echo "=========================================================="
    echo "  ERROR: lsfg-vk.dll was not found!"
    echo "=========================================================="
    echo "Lossless Scaling Frame Generation on Linux requires the official"
    echo "lsfg-vk.dll model from Lossless Scaling (Steam App ID 993090)."
    echo ""
    echo "To download it:"
    echo "  1. In Steam, right-click 'Lossless Scaling' -> Properties -> Betas."
    echo "  2. Under 'Beta Participation', select the 'lsfg-vk' branch."
    echo "  3. Wait for Steam to download the update (which provides lsfg-vk.dll)."
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
rm -f "$VULKAN_IMPLICIT_DIR/liblsfg-vk-layer.so" "$VULKAN_EXPLICIT_DIR/liblsfg-vk-layer.so"

LAYER_SO=""
for s in "$ROOT_DIR/layer/liblsfg-vk-layer.so" "$SCRIPT_DIR/layer/liblsfg-vk-layer.so"; do
    if [ -f "$s" ]; then
        LAYER_SO="$s"
        break
    fi
done

# If precompiled binary is not present or rebuild requested, compile natively on-device
if [ -z "$LAYER_SO" ] || [ "${1:-}" = "--rebuild" ]; then
    echo ""
    echo "=========================================================="
    echo " Native Compilation: Building liblsfg-vk-layer.so for Steam Frame"
    echo " Platform: Qualcomm Snapdragon 8 Gen 3 (ARM64 / aarch64)"
    echo "=========================================================="

    MISSING_TOOLS=()
    for tool in git cmake ninja; do
        if ! command -v "$tool" &>/dev/null; then MISSING_TOOLS+=("$tool"); fi
    done
    if ! command -v g++ &>/dev/null && ! command -v clang++ &>/dev/null; then
        MISSING_TOOLS+=("g++/clang++")
    fi

    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        echo "ERROR: Missing required build tools: ${MISSING_TOOLS[*]}"
        echo "Please install base development packages (or enable Developer Mode)."
        exit 1
    fi

    SUBMODULE_DIR="$ROOT_DIR/submodules/lsfg-vk"
    if [ ! -d "$SUBMODULE_DIR" ] || [ ! -f "$SUBMODULE_DIR/CMakeLists.txt" ]; then
        echo "[1/3] Cloning upstream lsfg-vk from https://git.lsfg-vk.dev/lsfg-vk.git..."
        mkdir -p "$ROOT_DIR/submodules"
        git clone --depth 1 https://git.lsfg-vk.dev/lsfg-vk.git "$SUBMODULE_DIR"
    else
        echo "[1/3] Upstream source found at $SUBMODULE_DIR"
    fi

    BUILD_DIR="$SUBMODULE_DIR/build-native"
    echo "[2/3] Configuring CMake with Snapdragon 8 Gen 3 native flags..."
    mkdir -p "$BUILD_DIR"
    cmake -B "$BUILD_DIR" -S "$SUBMODULE_DIR" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -static-libstdc++ -static-libgcc -fPIC" \
        -DCMAKE_C_FLAGS="-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -static-libstdc++ -static-libgcc -fPIC" \
        -DLSFGVK_BUILD_LAYER=ON \
        -DLSFGVK_BUILD_CLI=ON \
        -DLSFGVK_BUILD_UI=OFF

    echo "[3/3] Compiling native ARM64 Vulkan layer on Steam Frame..."
    cmake --build "$BUILD_DIR" --target lsfg-vk-layer -j"$(nproc 2>/dev/null || echo 4)"

    OUTPUT_SO=$(find "$BUILD_DIR" -name "liblsfg-vk-layer.so" | head -n1)
    if [ -z "$OUTPUT_SO" ] || [ ! -f "$OUTPUT_SO" ]; then
        echo "ERROR: liblsfg-vk-layer.so build failed."
        exit 1
    fi

    if command -v strip &>/dev/null; then
        strip --strip-unneeded "$OUTPUT_SO"
    fi

    mkdir -p "$ROOT_DIR/layer"
    cp "$OUTPUT_SO" "$ROOT_DIR/layer/liblsfg-vk-layer.so"
    LAYER_SO="$ROOT_DIR/layer/liblsfg-vk-layer.so"
    echo "Build successful! Created: $LAYER_SO"
    echo "=========================================================="
    echo ""
fi

safe_copy_file "$LAYER_SO" "$LIB_DIR/liblsfg-vk-layer.so"
echo "Configured Vulkan layer from: $LAYER_SO"


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


echo ""
echo "=== Installation Complete ==="
echo "To use LSFG in any game on Steam Frame:"
echo "1. Open the game's Properties in Steam"
echo "2. Add the following to Launch Options:"
echo "   ~/lsfg %command%"
echo ""
