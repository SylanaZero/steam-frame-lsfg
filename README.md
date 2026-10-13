# Steam Frame LSFG: Lossless Scaling Frame Generation for Valve Steam Frame

[![Architecture](https://img.shields.io/badge/Architecture-ARM64%2Faarch64-blue.svg)](#)
[![GPU Target](https://img.shields.io/badge/GPU-Qualcomm%20Adreno%20750-orange.svg)](#)
[![Driver](https://img.shields.io/badge/Driver-Mesa%20Turnip%20(Vulkan%201.3%2F1.4)-green.svg)](#)
[![Platform](https://img.shields.io/badge/OS-SteamOS%20ARM64-purple.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An automated installer and hardware-optimized companion project providing **Lossless Scaling Frame Generation (LSFG)** on the **Valve Steam Frame** (Qualcomm Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, running SteamOS ARM64).

---

## ⚡ Highlights

* **Automated On-Device Build:** No cross-compilation toolchains required. The installer automatically clones stock upstream `lsfg-vk` and compiles the native ARM64 Vulkan layer directly on your Steam Frame in seconds.
* **100% License Compliant:** Upstream `lsfg-vk` source code is compiled locally on your device—no precompiled derivative binaries or proprietary shader files are distributed.
* **Snapdragon 8 Gen 3 Hardware Optimization:** Compiled with `-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -static-libstdc++ -static-libgcc` for optimal scheduling on Adreno 750 / Cortex clusters with zero runtime `GLIBCXX` library mismatches.
* **In-Place Steam Discovery:** Automatically finds the official 2.1 MB Linux `lsfg-vk.dll` directly inside your Steam library without copying or duplicating files.
* **Flicker-Free Wayland / Gamescope Pacing:** Pre-configured with anti-flicker presentation modes (`override_present_mode = false`) to prevent compositor stuttering, frame drops, or display blanking.

---

## 📋 Prerequisites

1. **Lossless Scaling Ownership on Steam:**
   * Purchase [Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) on Steam (App ID `993090`).
   * In your Steam Library on the Steam Frame, right-click **Lossless Scaling** $\to$ **Properties** $\to$ **Betas**.
   * Under **Beta Participation**, select the **`lsfg-vk`** branch.
   * Wait for Steam to download the update (which provides the official 2.1 MB Linux `lsfg-vk.dll` neural model).
2. **Valve Steam Frame:**
   * Running SteamOS ARM64 (development tools such as GCC, CMake, Ninja, and the Mesa Turnip driver are included out-of-the-box).

---

## 🚀 Installation

### Option A: Using the Standalone Installer Archive (Recommended)

1. Download [`steam-frame-lsfg-installer.zip`](steam-frame-lsfg-installer.zip) onto your Steam Frame.
2. In Desktop Mode, open a terminal (Konsole) and run:
   ```bash
   unzip steam-frame-lsfg-installer.zip -d steam-frame-lsfg-installer
   cd steam-frame-lsfg-installer
   bash install.sh
   ```

### Option B: From Git Repository

```bash
git clone https://github.com/SylanaZero/steam-frame-lsfg.git
cd steam-frame-lsfg
bash scripts/install.sh
```

---

## 🔧 What `install.sh` Does Automatically

The installer automates the complete setup pipeline in a single pass:

1. **Environment Verification:** Validates your ARM64 CPU architecture (`aarch64`), Qualcomm Snapdragon 8 Gen 3 SoC, Mesa Turnip Vulkan driver, and FEX-Emu translation environment.
2. **In-Place Shader Discovery:** Locates and verifies the official 2.1 MB Linux `lsfg-vk.dll` inside your Steam library (`~/.local/share/Steam/steamapps/common/Lossless Scaling/`).
3. **Native ARM64 `lsfg-vk` Compilation:** Clones stock upstream [`PancakeTAS/lsfg-vk`](https://git.lsfg-vk.dev/lsfg-vk.git) and compiles `liblsfg-vk-layer.so` on-device with GCC 15 and Ninja using Snapdragon 8 Gen 3 optimization flags and static C++ runtime linking.
4. **Vulkan Layer Manifest Registration:** Installs `liblsfg-vk-layer.so` to `~/.local/share/steam-frame-lsfg/lib/` and registers the layer JSON manifest in both implicit and explicit directories (`~/.local/share/vulkan/implicit_layer.d/` and `~/.local/share/vulkan/explicit_layer.d/`).
5. **FrameGen Configuration & Game Profiles:** Installs tuned configuration (`~/.config/steam-frame-lsfg/config.toml`) with anti-flicker presentation (`override_present_mode = false`) and per-game presets.
6. **Launch Wrapper Setup:** Installs `~/.local/bin/lsfg-frame` and creates the convenient shortcut `~/lsfg`.
7. **Automated Smoke Test:** Runs a 4-point verification check to confirm the system Vulkan loader successfully discovers the newly installed layer.

---

## 🎮 How to Use in Games

Once installed, enable frame generation on any game in Steam:

1. In Steam, open the game's **Properties** (gear icon).
2. Under **Launch Options**, enter:
   ```text
   ~/lsfg %command%
   ```
3. Launch the game!

### Recommended In-Game Settings (Smooth & Flicker-Free)

* **In-Game V-Sync:** **OFF** (frame pacing is managed smoothly via Vulkan Mailbox without compositor stalls).
* **Display Mode:** **Borderless Windowed** (or Windowed Fullscreen).
* **Motion Blur:** **OFF** (reduces optical flow motion vector noise).
* **SteamOS Performance Overlay:** Set **Framerate Limit** to **Off / Unlimited**.

---

## ⚙️ Configuration & Game Profiles

Configuration files are located in `~/.config/steam-frame-lsfg/`:
* **Global Configuration:** `~/.config/steam-frame-lsfg/config.toml`
* **Per-Game Profiles:** `~/.config/steam-frame-lsfg/profiles/<AppID>.toml` (e.g. `1091500.toml` for *Cyberpunk 2077*, `default.toml` for general fallback)

### Key Parameters:
* `multiplier`: Frame generation multiplier (`2` = 2x, `3` = 3x).
* `flow_mode`: Optical flow resolution (`"quality"` or `"performance"`).
* `performance_mode`: `true` for FP16 compute shaders (recommended for Adreno 750), `false` for FP32.
* `override_present_mode`: `false` (required for flicker-free presentation on Wayland/Gamescope).

---

## 🛠️ Diagnostics & Troubleshooting

* **Verify Layer Discovery (Smoke Test):**
  ```bash
  bash scripts/smoke-test-layer.sh
  ```
* **Verify System Environment:**
  ```bash
  bash scripts/verify-env.sh
  ```
* **Enable Debug Logging During Gameplay:**
  Prefix the launch option with `LSFG_DEBUG=1`:
  ```text
  LSFG_DEBUG=1 ~/lsfg %command%
  ```
  Runtime logs are saved to: `~/.local/share/steam-frame-lsfg/lsfg.log`.

---

## 📁 Repository Structure

```text
steam-frame-lsfg/
├── QUICKSTART.md                     # Condensed quickstart guide
├── README.md                         # Project documentation
├── config/
│   ├── config.default.toml           # Global configuration template
│   └── profiles/                     # Per-game optimization profiles
│       ├── default.toml              # Fallback profile for all Proton/Windows titles
│       ├── 1091500.toml              # Profile: Cyberpunk 2077
│       └── 1145360.toml              # Profile: Hades II
├── layer/
│   └── VkLayer_LSFGVK_frame_generation.json # Vulkan layer manifest template
├── scripts/
│   ├── install.sh                    # [Core] Automated on-device build & installer script
│   ├── lsfg-frame                    # [Core] Launch wrapper (~/lsfg)
│   ├── verify-env.sh                 # [Diagnostics] System verification script (5-point check)
│   └── smoke-test-layer.sh           # [Diagnostics] Vulkan layer registration test
└── steam-frame-lsfg-installer.zip    # Standalone release archive for Steam Frame users
```

---

## 📄 License & Upstream Policy

This project's tooling, scripts, configuration profiles, and documentation are licensed under the [MIT License](LICENSE).

* **Lossless Scaling**: Proprietary commercial software developed by THS (available on Steam, App ID `993090`).
* **`lsfg-vk`**: Upstream Vulkan compatibility layer developed by [PancakeTAS](https://lsfg-vk.dev), licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/).

### ⚠️ Upstream Compliance Notice
* **Independent Companion:** This repository is an independent companion configuration and launch wrapper for the Valve Steam Frame.
* **No Precompiled Binary Distribution:** In accordance with the CC BY-NC-ND 4.0 license, this repository does not distribute precompiled derivative binaries or proprietary shader files. The installer compiles stock upstream source code locally on the user's device.

---

## 🙏 Acknowledgements & Credits

* **[PancakeTAS](https://git.lsfg-vk.dev/lsfg-vk.git)**: Creator of `lsfg-vk`, the foundational Vulkan compatibility layer enabling frame generation on Linux.
* **[ArmadaOS Project](https://github.com/armada-os/armada)**: For pioneering work demonstrating Lossless Scaling on ARM64 Snapdragon platforms.
* **[Mesa 3D & Freedreno Team](https://docs.mesa3d.org/drivers/freedreno.html)**: The developers behind the open-source `turnip` driver providing Vulkan 1.3/1.4 on Qualcomm Adreno GPUs.
* **[THS](https://store.steampowered.com/app/993090/Lossless_Scaling/)**: Developer of the original Lossless Scaling software on Steam.

---

## ⚠️ Disclaimer

This is an independent open-source community project. It is not affiliated with, sponsored by, or endorsed by Valve Corporation, Qualcomm, or THS. Valve, Steam, and Steam Frame are trademarks or registered trademarks of Valve Corporation. All other trademarks are property of their respective owners.
