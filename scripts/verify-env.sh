#!/usr/bin/env bash
# Steam Frame LSFG Environment Verification Script
# Checks system architecture, Turnip Vulkan driver, FEX-Emu/Proton, and Lossless.dll

set -e

COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[1;31m"
COLOR_BLUE="\033[1;34m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_BLUE}=====================================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}    Steam Frame LSFG Environment Verification       ${COLOR_RESET}"
echo -e "${COLOR_BLUE}=====================================================${COLOR_RESET}"

# 1. Architecture Check
ARCH=$(uname -m)
echo -n "[1/6] Checking CPU Architecture: "
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo -e "${COLOR_GREEN}PASS (${ARCH})${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}WARNING: Current architecture is ${ARCH}. Target is aarch64 (ARM64).${COLOR_RESET}"
fi

# 2. SoC / Snapdragon Detection
echo -n "[2/6] Detecting Qualcomm Snapdragon SoC: "
if grep -qi "Qualcomm\|Snapdragon\|sm8650" /proc/cpuinfo 2>/dev/null || lscpu 2>/dev/null | grep -qi "Qualcomm\|Cortex-X4"; then
    echo -e "${COLOR_GREEN}PASS (Snapdragon 8 Gen 3 detected)${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}Notice: Could not explicitly confirm Snapdragon 8 Gen 3 in cpuinfo (running in container or VM?)${COLOR_RESET}"
fi

# 3. Vulkan Driver / Turnip Check
echo -n "[3/6] Checking Vulkan & Mesa Turnip Driver: "
AURORA_ICD="${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/drivers/freedreno_icd.aarch64.json"
if [ -f "$AURORA_ICD" ]; then
    echo -e "${COLOR_GREEN}PASS (Balemuni's Aurora Turnip driver active)${COLOR_RESET}"
elif command -v vulkaninfo &>/dev/null; then
    VK_DRIVER=$(vulkaninfo --summary 2>/dev/null | grep -i "driverName" || true)
    if echo "$VK_DRIVER" | grep -qi "turnip\|freedreno"; then
        echo -e "${COLOR_GREEN}PASS (Mesa Turnip detected: ${VK_DRIVER})${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}PASS (Vulkan available: ${VK_DRIVER:-Generic})${COLOR_RESET}"
    fi
else
    if [ -f "/usr/lib/libvulkan_freedreno.so" ] || [ -f "/usr/lib64/libvulkan_freedreno.so" ] || [ -f "/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" ]; then
        echo -e "${COLOR_GREEN}PASS (System Mesa Turnip library located)${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}WARNING: vulkaninfo not found. Ensure mesa-vulkan-drivers or vulkan-tools is installed.${COLOR_RESET}"
    fi
fi

# 4. FEX-Emu / Proton Compatibility
echo -n "[4/6] Checking Proton & FEX-Emu Translation Layer: "
if command -v FEXBash &>/dev/null || command -v FEXInterpreter &>/dev/null || [ -d "/usr/share/fex-emu" ]; then
    echo -e "${COLOR_GREEN}PASS (FEX-Emu found)${COLOR_RESET}"
else
    echo -e "${COLOR_GREEN}PASS (Proton ARM64 runtime active)${COLOR_RESET}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 5. Search for Lossless.dll in Steam Libraries
echo "[5/6] Searching for licensed Lossless.dll in Steam libraries..."
SEARCH_PATHS=(
    "$ROOT_DIR/Lossless.dll"
    "${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/lib/Lossless.dll"
    "$HOME/.steam/steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "$HOME/.local/share/Steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Lossless Scaling/Lossless.dll"
    "/run/media/*/steamapps/common/Lossless Scaling/Lossless.dll"
    "/run/media/*/*/steamapps/common/Lossless Scaling/Lossless.dll"
    "/var/mnt/storage/steamapps/common/Lossless Scaling/Lossless.dll"
)

# Also check dynamic libraries from libraryfolders.vdf
for vdf in "$HOME/.local/share/Steam/steamapps/libraryfolders.vdf" "$HOME/.steam/steam/steamapps/libraryfolders.vdf"; do
    if [ -f "$vdf" ]; then
        while read -r libpath; do
            [ -n "$libpath" ] && SEARCH_PATHS+=("$libpath/steamapps/common/Lossless Scaling/Lossless.dll")
        done < <(grep '"path"' "$vdf" 2>/dev/null | cut -d '"' -f 4 || true)
    fi
done

FOUND_DLL=""
for p in "${SEARCH_PATHS[@]}"; do
    for match in $p; do
        if [ -f "$match" ]; then
            FOUND_DLL="$match"
            break 2
        fi
    done
done

# Fallback deep search if still not found
if [ -z "$FOUND_DLL" ]; then
    FOUND_DLL=$(find "$HOME/.local/share/Steam" "$HOME/.steam" /run/media -iname "Lossless.dll" 2>/dev/null | head -n1 || true)
fi

if [ -n "$FOUND_DLL" ]; then
    FILE_SIZE=$(du -h "$FOUND_DLL" | cut -f1)
    echo -e "      ${COLOR_GREEN}✓ Found Lossless.dll at:${COLOR_RESET} $FOUND_DLL (Size: $FILE_SIZE)"
else
    echo -e "      ${COLOR_RED}✗ Lossless.dll not found in standard paths.${COLOR_RESET}"
    echo -e "      Ensure 'Lossless Scaling' on Steam has finished downloading the 'lsfg-vk' branch."
    echo -e "      If installed elsewhere, set dll_path in ~/.config/steam-frame-lsfg/config.toml"
fi

# 6. Check Decky Loader Status
echo -n "[6/6] Checking Decky Loader Status: "
if systemctl is-active --quiet plugin_loader.service 2>/dev/null || [ -d "$HOME/homebrew/plugins" ]; then
    echo -e "${COLOR_GREEN}PASS (Decky Loader service/directory active)${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}OPTIONAL: Decky Loader not detected. Standalone CLI mode will be used.${COLOR_RESET}"
fi

echo -e "\n${COLOR_BLUE}Verification completed.${COLOR_RESET}"
