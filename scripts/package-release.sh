#!/usr/bin/env bash
# Steam Frame LSFG: Release Packaging Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
STAGING="$WORKSPACE/dist/staging/release"

echo "Creating clean staging directory: $STAGING"
rm -rf "$STAGING"
mkdir -p "$STAGING/config/profiles" "$STAGING/layer" "$STAGING/scripts"

# Copy root documents
cp "$WORKSPACE/README.md" "$STAGING/"
cp "$WORKSPACE/QUICKSTART.md" "$STAGING/"
cp "$WORKSPACE/LICENSE" "$STAGING/"

# Copy install script to root and scripts/
cp "$WORKSPACE/scripts/install.sh" "$STAGING/install.sh"
cp "$WORKSPACE/scripts/install.sh" "$STAGING/scripts/install.sh"

# Copy scripts
cp "$WORKSPACE/scripts/lsfg-frame" "$STAGING/scripts/lsfg-frame"
cp "$WORKSPACE/scripts/verify-env.sh" "$STAGING/scripts/verify-env.sh"
cp "$WORKSPACE/scripts/smoke-test-layer.sh" "$STAGING/scripts/smoke-test-layer.sh"

# Copy layer manifest
cp "$WORKSPACE/layer/VkLayer_LSFGVK_frame_generation.json" "$STAGING/layer/VkLayer_LSFGVK_frame_generation.json"

# Copy configs
cp "$WORKSPACE/config/config.default.toml" "$STAGING/config/config.default.toml"
cp "$WORKSPACE/config/profiles/"*.toml "$STAGING/config/profiles/"

# Ensure executable permissions
chmod +x "$STAGING/install.sh" "$STAGING/scripts/"*

ZIP_INSTALLER="$WORKSPACE/steam-frame-lsfg-installer.zip"
ZIP_RELEASE="$WORKSPACE/steam-frame-lsfg-v1.0.0.zip"

rm -f "$ZIP_INSTALLER" "$ZIP_RELEASE"

cd "$STAGING"
tar -a -c -f "$ZIP_INSTALLER" .
tar -a -c -f "$ZIP_RELEASE" .

echo "Generated release archives successfully:"
ls -lh "$ZIP_INSTALLER" "$ZIP_RELEASE"
