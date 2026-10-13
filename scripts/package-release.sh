#!/usr/bin/env bash
# Steam Frame LSFG: Release Packaging Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
STAGING="$WORKSPACE/dist/staging/release"

echo "Creating clean staging directory: $STAGING"
rm -rf "$STAGING"
mkdir -p "$STAGING/config/profiles" "$STAGING/scripts"

# Copy root documentation & license
cp "$WORKSPACE/README.md" "$STAGING/"
cp "$WORKSPACE/LICENSE" "$STAGING/"

# Copy root installer
cp "$WORKSPACE/install.sh" "$STAGING/"

# Copy runtime and diagnostic scripts
cp "$WORKSPACE/scripts/lsfg-frame" "$STAGING/scripts/"
cp "$WORKSPACE/scripts/verify-env.sh" "$STAGING/scripts/"
cp "$WORKSPACE/scripts/smoke-test-layer.sh" "$STAGING/scripts/"

# Copy configs
cp "$WORKSPACE/config/config.default.toml" "$STAGING/config/"
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
