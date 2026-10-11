# Steam Frame LSFG: Lossless Scaling Frame Generation for Valve Steam Frame

[![Architecture](https://img.shields.io/badge/Architecture-ARM64%2Faarch64-blue.svg)](#)
[![GPU Target](https://img.shields.io/badge/GPU-Qualcomm%20Adreno%20750-orange.svg)](#)
[![Driver](https://img.shields.io/badge/Driver-Mesa%20Turnip%20(Vulkan%201.3)-green.svg)](#)
[![Platform](https://img.shields.io/badge/OS-SteamOS%20ARM64-purple.svg)](#)

A dedicated, hardware-optimized project providing **Lossless Scaling Frame Generation (LSFG)** support on the **Valve Steam Frame** (Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, running SteamOS ARM64).

---

## 📁 Package Contents & File Reference

This release archive contains everything needed for one-click installation, plus diagnostic and developer tools:

```text
steam-frame-lsfg/
├── QUICKSTART.md                     # Step-by-step setup guide for Steam Frame
├── README.md                         # Project documentation and component reference
├── config/
│   ├── config.default.toml           # Global configuration template (Schema Version 2)
│   └── profiles/                     # Per-game optimization profiles
│       ├── default.toml              # Fallback profile for all Proton/Windows titles
│       ├── 1091500.toml              # Profile: Cyberpunk 2077
│       └── 1145360.toml              # Profile: Hades II
├── decky-plugin/                     # Optional Decky Loader Quick Access Menu UI
│   ├── plugin.json / package.json    # Decky manifest and metadata
│   ├── main.py                       # Python backend managing configs & AppIDs
│   └── src/index.tsx                 # React UI for SteamOS Gamepad QAM
├── docs/
│   ├── ARCHITECTURE.md               # Technical hardware deep-dive for developers
│   └── REPLICATION_GUIDE.md          # Step-by-step build & replication guide
├── layer/
│   ├── liblsfg-vk-layer.so           # Pre-compiled ARM64 Vulkan layer binary
│   └── VkLayer_LSFGVK_frame_generation.json # Vulkan 1.3 layer manifest
└── scripts/
    ├── install.sh                    # [Core] Primary installer script
    ├── lsfg-frame                    # [Core] Production launch wrapper (~/lsfg)
    ├── verify-env.sh                 # [Core] System diagnostic & environment check script
    ├── smoke-test-layer.sh           # [Diagnostics] 4-point Vulkan layer registration test
    ├── build-cross-layer.sh          # [Developer] Recompilation script (ARM64 or x86_64 host)
    └── install-turnip-aurora.sh      # [Experimental] Alternative Turnip driver installer
```

### Detailed Component Reference

| File / Component | Category | Purpose & Description |
| :--- | :--- | :--- |
| **`scripts/install.sh`** | **Core Installer** | **Primary installation script.** Deploys the layer library to `~/.local/share/steam-frame-lsfg/lib/`, writes Vulkan loader manifests, sets up default configuration profiles, and installs the `~/lsfg` launcher wrapper. |
| **`scripts/lsfg-frame`** | **Core Runtime** | **Launch wrapper.** Installed to `~/lsfg` and `/usr/local/bin/lsfg-frame`. Handles `Lossless.dll` auto-discovery, per-game TOML profile resolution, and flicker-free presentation pacing. |
| **`layer/liblsfg-vk-layer.so`** | **Core Binary** | **Compiled ARM64 Vulkan layer.** Stripped 2.4 MB binary compiled with the Lossless Scaling v3.2.2.0 SPIR-V resource offset fix, Adreno 750 compute optimizations, and Vulkan 1.3 swapchain wrapping. |
| **`layer/VkLayer_LSFGVK_frame_generation.json`** | **Core Runtime** | **Vulkan layer manifest.** Registered with SteamOS's Vulkan loader (`implicit_layer.d` and `explicit_layer.d`) so the layer can intercept swapchain calls. |
| **`scripts/verify-env.sh`** | **Diagnostics** | **Environment verifier.** Checks CPU architecture, Qualcomm Snapdragon 8 Gen 3 core clusters, Mesa Turnip driver status, FEX-Emu, and Steam libraries. (Run automatically by `install.sh`). |
| **`scripts/smoke-test-layer.sh`** | **Diagnostics** | **Quick diagnostic test.** Validates the ARM64 ELF header of `liblsfg-vk-layer.so`, checks manifest syntax, and tests Vulkan loader discovery via `vulkaninfo` without launching a game. |
| **`scripts/build-cross-layer.sh`** | **Developer Tool** | **Recompilation script.** Clones upstream `lsfg-vk` and builds `liblsfg-vk-layer.so` from source. Supports cross-compiling on x86_64 Linux/WSL with `aarch64-linux-gnu-g++` or compiling natively on ARM64. |
| **`scripts/install-turnip-aurora.sh`** | **Experimental Tool** | **Alternative driver installer.** Downloads and installs community Balemuni Aurora Turnip driver builds into `~/.local/share/steam-frame-lsfg/drivers/` for testing bleeding-edge driver fixes. |
| **`config/config.default.toml`** | **Configuration** | **Default configuration template.** Deployed to `~/.config/steam-frame-lsfg/config.toml`. Pre-tuned with `override_present_mode = false` and `mailbox` presentation for smooth, flicker-free delivery. |
| **`config/profiles/*.toml`** | **Configuration** | **Per-game optimization profiles.** Game-specific presets deployed by the installer (`1091500.toml` for Cyberpunk 2077, `1145360.toml` for Hades II, `default.toml`). |
| **`decky-plugin/`** | **Optional UI** | **Decky Loader plugin.** Provides an on-screen Quick Access Menu (QAM) slider panel for adjusting multipliers, optical flow scale, and performance mode on the fly. |
| **`docs/ARCHITECTURE.md`** | **Documentation** | **Hardware architecture guide.** Comprehensive technical documentation on Snapdragon 8 Gen 3, Adreno 750 GMEM tile memory, memory bandwidth constraints, and Gamescope WSI. |
| **`docs/REPLICATION_GUIDE.md`** | **Documentation** | **Build & replication guide.** Step-by-step developer guide documenting cross-compilation toolchains, shader resource reverse-engineering, and presentation pacing patches. |
| **`QUICKSTART.md`** | **Documentation** | **Quickstart guide.** Step-by-step instructions for extracting, installing, and configuring Steam launch options. |

---

## 🚀 Quickstart Guide

### Step 1: Prerequisites
1. **Lossless Scaling Ownership**: Purchase and download [Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) on Steam.
   * *Branch Note*: The standard branch provides `Lossless.dll`; the `lsfg-vk` beta branch (Properties $\to$ Betas) provides `lsfg-vk.dll`. The installer automatically searches for either and mirrors both names so either branch works out of the box.
2. **Valve Steam Frame**: Running SteamOS ARM64 with native Mesa Turnip Vulkan driver.

### Step 2: Installation
Download or transfer `steam-frame-lsfg-release.zip` to your Steam Frame, extract into a dedicated directory, and run:

```bash
unzip -o steam-frame-lsfg-release.zip -d steam-frame-lsfg
cd steam-frame-lsfg
bash scripts/install.sh
```

The installer will:
1. Verify the ARM64 environment and Mesa Turnip Vulkan driver.
2. Locate `Lossless.dll` / `lsfg-vk.dll` in your Steam library directories and mirror both into place.
3. Deploy the pre-compiled Vulkan layer to `~/.local/share/vulkan/implicit_layer.d/` and explicit layer directories.
4. Install the launch wrapper to `~/lsfg` and `~/.local/bin/lsfg-frame`.
5. Deploy the Decky Loader plugin if Decky is installed.

### Step 3: Enabling in Games

In the Steam client:
1. Right-click your game $\to$ **Properties**.
2. Under **Launch Options**, enter:
   ```text
   ~/lsfg %command%
   ```
   *(or `/home/steamos/lsfg %command%`)*
3. Launch the game!

#### For Non-Steam Games & Custom Drivers (e.g., Battle.net / WoW Forever):
Keep environment variables (like `VK_ICD_FILENAMES=...`) before `~/lsfg`:
```text
VK_ICD_FILENAMES=/path/to/custom_icd.json ~/lsfg %command%
```

---

## ⚙️ Recommended In-Game Settings (Flicker-Free & Smooth)

To avoid compositor collisions and frame pacing judder:
* **In-Game V-Sync**: **OFF** (the LSFG layer uses smooth Mailbox presentation).
* **Display Mode**: **Borderless Windowed** (or Windowed Fullscreen).
* **Motion Blur**: **OFF** (prevents optical flow motion blur noise).
* **SteamOS Performance Overlay**: Set **Framerate Limit** to **Off / Unlimited**.

---

## 🛠️ Diagnostics & Debug Logging

By default, disk logging is **disabled** to avoid generating large log files on your drive during extended gameplay.

* **Enable Debug Logging for a Session**:
  Launch the game with `LSFG_DEBUG=1`:
  ```text
  LSFG_DEBUG=1 ~/lsfg %command%
  ```
  Inspect logs:
  ```bash
  cat ~/.local/share/steam-frame-lsfg/lsfg.log
  ```

* **Verify System Health**:
  ```bash
  bash scripts/verify-env.sh
  ```

* **FP32 Quality Shader Mode**:
  If you ever notice half-float precision shimmer on complex scenes, force FP32 shaders:
  ```text
  LSFGVK_PERFORMANCE_MODE=0 ~/lsfg %command%
  ```

---

## 📁 Configuration

Configuration files are located in `~/.config/steam-frame-lsfg/`:
* Global configuration: `config.toml`
* Per-game profiles: `profiles/<AppID>.toml` (e.g. `1091500.toml` for Cyberpunk 2077, `default.toml`)

Parameters:
* `multiplier`: Frame generation multiplier (`2` = 2x, `3` = 3x).
* `flow_scale`: Optical flow resolution scale (`0.75` = 75%, `1.0` = full resolution).
* `performance_mode`: `true` for fast FP16 compute shaders, `false` for FP32.
* `override_present_mode`: `false` (recommended default for flicker-free presentation).

---

## 📄 License

This project's tooling, scripts, configuration, and documentation are licensed under the [MIT License](LICENSE).
* **Lossless Scaling**: Proprietary software developed by THS (available on Steam, App ID `993090`).
* **`lsfg-vk`**: The upstream Vulkan compatibility layer submodule is licensed under CC BY-NC-ND 4.0 by PancakeTAS.
