#!/usr/bin/env bash
# Steam Frame LSFG: Automated Cross-Compilation Script
# Builds libVkLayer_lsfg.so (aarch64 / ARM64) from an x86_64 host.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SUBMODULE_DIR="$ROOT_DIR/submodules/lsfg-vk"
LAYER_DIR="$ROOT_DIR/layer"
CROSS_FILE="$ROOT_DIR/meson/aarch64-cross.txt"

echo "=== Building Steam Frame LSFG Layer (ARM64 / aarch64) ==="

# 1. Ensure upstream PancakeTAS/lsfg-vk is cloned / initialized
if [ ! -d "$SUBMODULE_DIR" ] || [ ! -f "$SUBMODULE_DIR/meson.build" ]; then
    echo "[1/4] Cloning upstream PancakeTAS/lsfg-vk into submodules/lsfg-vk..."
    mkdir -p "$ROOT_DIR/submodules"
    git clone --depth 1 https://github.com/PancakeTAS/lsfg-vk.git "$SUBMODULE_DIR"
else
    echo "[1/4] Upstream source found at $SUBMODULE_DIR"
fi

# 2. Check for cross compiler
if ! command -v aarch64-linux-gnu-g++ &>/dev/null; then
    echo "ERROR: 'aarch64-linux-gnu-g++' cross compiler not found on this host."
    echo ""
    echo "To build inside a clean container on an x86_64 host, run:"
    echo "  docker build -f Dockerfile.cross -t steam-frame-lsfg-builder ."
    echo "  docker run --rm -v \"$ROOT_DIR\":/workspace steam-frame-lsfg-builder"
    echo ""
    exit 1
fi

# 3. Configure Meson build directory
BUILD_DIR="$SUBMODULE_DIR/build-arm64"
echo "[2/4] Configuring Meson build with Snapdragon 8 Gen 3 cross profile..."
if [ -d "$BUILD_DIR" ]; then
    meson setup "$BUILD_DIR" "$SUBMODULE_DIR" --cross-file "$CROSS_FILE" --buildtype=release --reconfigure
else
    meson setup "$BUILD_DIR" "$SUBMODULE_DIR" --cross-file "$CROSS_FILE" --buildtype=release
fi

# 4. Compile with Ninja
echo "[3/4] Compiling ARM64 Vulkan layer..."
ninja -C "$BUILD_DIR"

# 5. Extract output binary to layer/ directory
echo "[4/4] Deploying compiled binary..."
OUTPUT_BIN=$(find "$BUILD_DIR" -name "libVkLayer_lsfg.so" | head -n1)
if [ -z "$OUTPUT_BIN" ] || [ ! -f "$OUTPUT_BIN" ]; then
    echo "ERROR: libVkLayer_lsfg.so was not found in the build directory."
    exit 1
fi

mkdir -p "$LAYER_DIR"
cp "$OUTPUT_BIN" "$LAYER_DIR/libVkLayer_lsfg.so"

echo ""
echo "=== Build Successful! ==="
echo "Artifact generated: $LAYER_DIR/libVkLayer_lsfg.so"
if command -v file &>/dev/null; then
    file "$LAYER_DIR/libVkLayer_lsfg.so"
fi
