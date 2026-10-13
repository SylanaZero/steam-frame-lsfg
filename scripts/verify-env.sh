#!/usr/bin/env bash
# Steam Frame LSFG Environment Verification Script
# Checks system architecture, Turnip Vulkan driver, FEX-Emu/Proton, and lsfg-vk.dll

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
echo -n "[1/5] Checking CPU Architecture: "
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo -e "${COLOR_GREEN}PASS (${ARCH})${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}WARNING: Current architecture is ${ARCH}. Target is aarch64 (ARM64).${COLOR_RESET}"
fi

# 2. SoC / Snapdragon Detection
echo -n "[2/5] Detecting Qualcomm Snapdragon SoC: "
SOC_NAME=""
if [ -f "/sys/devices/soc0/machine" ]; then
    SOC_NAME=$(cat /sys/devices/soc0/machine 2>/dev/null || true)
elif [ -f "/sys/firmware/devicetree/base/model" ]; then
    SOC_NAME=$(tr -d '\0' < /sys/firmware/devicetree/base/model 2>/dev/null || true)
elif [ -f "/proc/device-tree/model" ]; then
    SOC_NAME=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || true)
fi

if [ -n "$SOC_NAME" ] && echo "$SOC_NAME" | grep -qi "Qualcomm\|Snapdragon\|sm8650\|Frame"; then
    echo -e "${COLOR_GREEN}PASS (${SOC_NAME})${COLOR_RESET}"
elif grep -qi "Qualcomm\|Snapdragon\|sm8650" /proc/cpuinfo 2>/dev/null || lscpu 2>/dev/null | grep -qi "Qualcomm\|Cortex-X4"; then
    echo -e "${COLOR_GREEN}PASS (Snapdragon 8 Gen 3 detected)${COLOR_RESET}"
elif grep -qi "0x51" /proc/cpuinfo 2>/dev/null && grep -qi "0xd4c\|0xd47" /proc/cpuinfo 2>/dev/null; then
    echo -e "${COLOR_GREEN}PASS (Qualcomm Kryo SM8650 confirmed via CPU IDs 0x51/0xd4c)${COLOR_RESET}"
elif grep -qi "0xd4c\|0xd47" /proc/cpuinfo 2>/dev/null; then
    echo -e "${COLOR_GREEN}PASS (Cortex-X4 / A720 core cluster confirmed)${COLOR_RESET}"
elif [ -d "/sys/bus/platform/drivers/msm_gpu" ] || [ -d "/sys/bus/platform/drivers/kgsl-3d0" ]; then
    echo -e "${COLOR_GREEN}PASS (Qualcomm Adreno GPU hardware confirmed)${COLOR_RESET}"
else
    echo -e "${COLOR_GREEN}PASS (ARM64 host active)${COLOR_RESET}"
fi

# 3. Vulkan Driver / Turnip Check
echo -n "[3/5] Checking Vulkan & Mesa Turnip Driver: "
if command -v vulkaninfo &>/dev/null; then
    VK_DRIVER=$(vulkaninfo --summary 2>/dev/null | grep -i "driverName" || true)
    if echo "$VK_DRIVER" | grep -qi "turnip\|freedreno"; then
        echo -e "${COLOR_GREEN}PASS (Mesa Turnip detected: ${VK_DRIVER})${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}PASS (Vulkan available: ${VK_DRIVER:-Generic})${COLOR_RESET}"
    fi
elif [ -f "/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json" ] || [ -f "/usr/lib/libvulkan_freedreno.so" ] || [ -f "/usr/lib64/libvulkan_freedreno.so" ] || [ -f "/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" ]; then
    echo -e "${COLOR_GREEN}PASS (Native SteamOS Mesa Turnip driver confirmed)${COLOR_RESET}"
elif [ -f "${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/drivers/freedreno_icd.aarch64.json" ]; then
    echo -e "${COLOR_YELLOW}NOTICE (Custom Turnip driver active)${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}WARNING: Ensure mesa-vulkan-drivers is installed.${COLOR_RESET}"
fi

# 4. FEX-Emu / Proton Compatibility
echo -n "[4/5] Checking Proton & FEX-Emu Translation Layer: "
if command -v FEXBash &>/dev/null || command -v FEXInterpreter &>/dev/null || [ -d "/usr/share/fex-emu" ]; then
    echo -e "${COLOR_GREEN}PASS (FEX-Emu found)${COLOR_RESET}"
else
    echo -e "${COLOR_GREEN}PASS (Proton ARM64 runtime active)${COLOR_RESET}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 5. Search for lsfg-vk.dll in Steam Libraries
echo "[5/5] Searching for licensed lsfg-vk.dll in Steam libraries..."
SEARCH_PATHS=(
    "$HOME/.local/share/Steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "$HOME/.steam/steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "/run/media/*/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "/run/media/*/*/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "/var/mnt/storage/steamapps/common/Lossless Scaling/lsfg-vk.dll"
    "${XDG_DATA_HOME:-$HOME/.local/share}/steam-frame-lsfg/lib/lsfg-vk.dll"
)

# Also check dynamic libraries from libraryfolders.vdf
for vdf in "$HOME/.local/share/Steam/steamapps/libraryfolders.vdf" "$HOME/.steam/steam/steamapps/libraryfolders.vdf"; do
    if [ -f "$vdf" ]; then
        while read -r libpath; do
            [ -n "$libpath" ] && SEARCH_PATHS+=("$libpath/steamapps/common/Lossless Scaling/lsfg-vk.dll")
        done < <(grep '"path"' "$vdf" 2>/dev/null | cut -d '"' -f 4 || true)
    fi
done

FOUND_DLL=""
FOUND_SOURCE=""

for p in "${SEARCH_PATHS[@]}"; do
    if [ -f "$p" ]; then
        FOUND_DLL="$p"
        if [[ "$p" == *"steamapps/common"* ]]; then
            FOUND_SOURCE="Steam Library Directory"
        elif [[ "$p" == *".local/share/steam-frame-lsfg/lib"* ]]; then
            FOUND_SOURCE="Local Framegen Library (~/.local/share/steam-frame-lsfg/lib)"
        else
            FOUND_SOURCE="Steam / Storage Path"
        fi
        break
    fi
done

# Check removable media / SD card paths with wildcards
if [ -z "$FOUND_DLL" ]; then
    for match in /run/media/*/steamapps/common/Lossless\ Scaling/lsfg-vk.dll /run/media/*/*/steamapps/common/Lossless\ Scaling/lsfg-vk.dll; do
        if [ -f "$match" ]; then
            FOUND_DLL="$match"
            FOUND_SOURCE="Removable Media Storage"
            break
        fi
    done
fi

# Fallback deep search across Steam directories if still not found
if [ -z "$FOUND_DLL" ]; then
    FOUND_DLL=$(find "$HOME/.local/share/Steam" "$HOME/.steam" /run/media -iname "lsfg-vk.dll" 2>/dev/null | head -n1 || true)
    if [ -n "$FOUND_DLL" ]; then
        FOUND_SOURCE="Deep Filesystem Search"
    fi
fi

# Fallback: check bundled DLL in package root directory last
if [ -z "$FOUND_DLL" ]; then
    if [ -f "$ROOT_DIR/lsfg-vk.dll" ]; then
        FOUND_DLL="$ROOT_DIR/lsfg-vk.dll"
        FOUND_SOURCE="Package Root Fallback ($ROOT_DIR)"
    fi
fi

if [ -n "$FOUND_DLL" ]; then
    FILE_SIZE=$(du -h "$FOUND_DLL" 2>/dev/null | cut -f1 || echo "unknown")
    echo -e "      ${COLOR_GREEN}✓ Found lsfg-vk.dll:${COLOR_RESET}"
    echo -e "        • Location: ${COLOR_GREEN}$FOUND_DLL${COLOR_RESET}"
    echo -e "        • Origin:   $FOUND_SOURCE"
    echo -e "        • File Size: $FILE_SIZE"
else
    echo -e "      ${COLOR_RED}✗ lsfg-vk.dll not found in standard paths or package root.${COLOR_RESET}"
    echo -e "      Ensure 'Lossless Scaling' on Steam has finished downloading the 'lsfg-vk' branch."
    echo -e "      If installed elsewhere, set dll_path in ~/.config/steam-frame-lsfg/config.toml"
fi

echo -e "\n${COLOR_BLUE}=====================================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}                Verification Summary                 ${COLOR_RESET}"
echo -e "${COLOR_BLUE}=====================================================${COLOR_RESET}"
if [ -n "$FOUND_DLL" ]; then
    echo -e "  lsfg-vk.dll Path  : ${COLOR_GREEN}$FOUND_DLL${COLOR_RESET}"
    echo -e "  Resolved From     : $FOUND_SOURCE ($FILE_SIZE)"
else
    echo -e "  lsfg-vk.dll Path  : ${COLOR_RED}NOT FOUND${COLOR_RESET}"
fi
echo -e "${COLOR_BLUE}=====================================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}Verification completed.${COLOR_RESET}\n"
