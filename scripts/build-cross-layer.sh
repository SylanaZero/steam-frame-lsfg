#!/usr/bin/env bash
# Steam Frame LSFG: Automated Cross-Compilation Script
# Builds liblsfg-vk-layer.so (aarch64 / ARM64) from an x86_64 host.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SUBMODULE_DIR="$ROOT_DIR/submodules/lsfg-vk"
LAYER_DIR="$ROOT_DIR/layer"
TOOLCHAIN_FILE="$ROOT_DIR/cmake/aarch64-toolchain.cmake"

echo "=== Building Steam Frame LSFG Layer (ARM64 / aarch64) ==="

# 1. Ensure upstream lsfg-vk is cloned / initialized
if [ ! -d "$SUBMODULE_DIR" ] || [ ! -f "$SUBMODULE_DIR/CMakeLists.txt" ]; then
    echo "[1/4] Cloning upstream lsfg-vk into submodules/lsfg-vk..."
    mkdir -p "$ROOT_DIR/submodules"
    git clone --depth 1 https://git.lsfg-vk.dev/lsfg-vk.git "$SUBMODULE_DIR"
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

# 3. Configure CMake with Snapdragon 8 Gen 3 cross profile
BUILD_DIR="$SUBMODULE_DIR/build-arm64"
echo "[2/4] Configuring CMake with Snapdragon 8 Gen 3 cross toolchain..."
cmake -B "$BUILD_DIR" -S "$SUBMODULE_DIR" \
    -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLSFGVK_BUILD_LAYER=ON \
    -DLSFGVK_BUILD_CLI=ON \
    -DLSFGVK_BUILD_UI=OFF

# 4. Compile with Ninja
echo "[3/4] Compiling ARM64 Vulkan layer..."
cmake --build "$BUILD_DIR" --target lsfg-vk-layer -j"$(nproc 2>/dev/null || echo 4)"

# 5. Extract output binary & manifest to layer/ directory
echo "[4/4] Deploying compiled binary and manifest..."
mkdir -p "$LAYER_DIR"

OUTPUT_SO=$(find "$BUILD_DIR" -name "liblsfg-vk-layer.so" | head -n1)
if [ -z "$OUTPUT_SO" ] || [ ! -f "$OUTPUT_SO" ]; then
    echo "ERROR: liblsfg-vk-layer.so was not found in the build directory."
    exit 1
fi

cp "$OUTPUT_SO" "$LAYER_DIR/liblsfg-vk-layer.so"
# Also symlink or copy to libVkLayer_lsfg.so for alias compatibility
cp "$OUTPUT_SO" "$LAYER_DIR/libVkLayer_lsfg.so"

OUTPUT_JSON=$(find "$BUILD_DIR" -name "VkLayer_LSFGVK_frame_generation.json" | head -n1)
if [ -n "$OUTPUT_JSON" ] && [ -f "$OUTPUT_JSON" ]; then
    cp "$OUTPUT_JSON" "$LAYER_DIR/VkLayer_LSFGVK_frame_generation.json"
fi

echo ""
echo "=== Build Successful! ==="
echo "Layer library:  $LAYER_DIR/liblsfg-vk-layer.so"
echo "Layer manifest: $LAYER_DIR/VkLayer_LSFGVK_frame_generation.json"
if command -v file &>/dev/null; then
    file "$LAYER_DIR/liblsfg-vk-layer.so"
fi
