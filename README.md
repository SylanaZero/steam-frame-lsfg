# Steam Frame LSFG: Lossless Scaling Frame Generation for Valve Steam Frame

[![Architecture](https://img.shields.io/badge/Architecture-ARM64%2Faarch64-blue.svg)](#)
[![GPU Target](https://img.shields.io/badge/GPU-Qualcomm%20Adreno%20750-orange.svg)](#)
[![Driver](https://img.shields.io/badge/Driver-Mesa%20Turnip%20(Vulkan%201.3)-green.svg)](#)
[![Platform](https://img.shields.io/badge/OS-SteamOS%20ARM64-purple.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A dedicated, hardware-optimized companion project providing **Lossless Scaling Frame Generation (LSFG)** runtime orchestration, launcher scripts, and configuration on the **Valve Steam Frame** (Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, running SteamOS ARM64).

---

> [!CAUTION]
> ### ⚠️ CRITICAL PREREQUISITE & LICENSE COMPLIANCE NOTICE
> **The scripts, installer, and launch wrapper in this repository WILL NOT WORK without an ARM64-compiled `liblsfg-vk-layer.so` binary.**
>
> **Why are precompiled binaries NOT provided here?**
> * Upstream **`lsfg-vk`** is developed by **PancakeTAS** and licensed under **[Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)](https://creativecommons.org/licenses/by-nc-nd/4.0/)**. This license strictly prohibits distributing modified versions or precompiled derivative binaries.
> * **`lsfg-vk.dll`** is proprietary commercial software developed by **THS** (available on Steam, App ID `993090`, via the `lsfg-vk` beta branch).
>
> To maintain strict license compliance:
> 1. **This repository DOES NOT distribute precompiled `liblsfg-vk-layer.so` binaries.**
> 2. **This repository DOES NOT host proprietary shader binaries (`lsfg-vk.dll`).**
>
> **Important Note on `lsfg-vk.dll` vs. `Lossless.dll`:**
> On Linux / SteamOS, `Lossless.dll` is **not used**. `Lossless.dll` is the Windows package containing DirectX 11/12 bytecode. The Linux Vulkan layer requires **`lsfg-vk.dll`** (the stripped 2.1 MB Vulkan SPIR-V shader model), which is officially downloaded by switching *Lossless Scaling* in Steam to the **`lsfg-vk` beta branch**. Because `lsfg-vk.dll` is designed natively for `lsfg-vk`, **no shader pipeline patches are needed**—you only need to cross-compile stock upstream `lsfg-vk` for the ARM64 architecture!

---

## 🛠️ Building `liblsfg-vk-layer.so` for Steam Frame (ARM64)

Because upstream precompiled binaries from [lsfg-vk.dev](https://lsfg-vk.dev) are built for `x86_64` (standard PCs and Steam Deck), you must compile the layer for `aarch64` (ARM64) to run on the Snapdragon 8 Gen 3 SoC.

When building from upstream source ([`PancakeTAS/lsfg-vk`](https://git.lsfg-vk.dev/lsfg-vk.git)):

### 1. Stock Shader Compatibility (No Code Patches Needed)
When using **`lsfg-vk.dll`** from the Steam beta branch:
* Shaders start at Resource IDs `1..99` and Resource ID `2147488584U` for `mipmaps` is present natively.
* **Stock upstream code (`library.cpp`) parses `lsfg-vk.dll` cleanly without any code modifications.**

### 2. Linker Configuration for SteamOS ARM64
When cross-compiling with GCC for ARM64, dynamic `libstdc++.so` or `libgcc_s.so` links can fail at runtime due to `GLIBCXX` symbol mismatches against SteamOS's system libraries.

Ensure standard C++ runtime libraries are linked statically:
```cmake
# In lsfg-vk-layer/CMakeLists.txt (or via -DCMAKE_SHARED_LINKER_FLAGS)
target_link_options(lsfg-vk-layer PRIVATE
  "-static-libstdc++"
  "-static-libgcc"
  "LINKER:--exclude-libs,ALL")
```

### 3. Compiler Flags for Snapdragon 8 Gen 3 (Adreno 750)
* Target architecture: `aarch64-linux-gnu`
* Optimization flags: `-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -fPIC`
* For a complete step-by-step cross-compilation walkthrough, see [`docs/REPLICATION_GUIDE.md`](docs/REPLICATION_GUIDE.md).

---

## 📁 Package Contents & File Reference

This repository contains the runtime launcher, system scripts, hardware configurations, and diagnostic tools:

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
│   └── REPLICATION_GUIDE.md          # In-depth technical developer replication guide
├── layer/
│   └── VkLayer_LSFGVK_frame_generation.json # Vulkan 1.3 layer manifest template
└── scripts/
    ├── install.sh                    # [Core] Primary installer script
    ├── lsfg-frame                    # [Core] Production launch wrapper (~/lsfg)
    ├── verify-env.sh                 # [Core] System diagnostic & environment check script
    ├── smoke-test-layer.sh           # [Diagnostics] Vulkan layer registration test
    ├── build-cross-layer.sh          # [Developer] Reference build script for ARM64/x86_64 host
    └── install-turnip-aurora.sh      # [Experimental] Alternative Turnip driver installer
```

### Detailed Component Reference

| File / Component | Category | Purpose & Description |
| :--- | :--- | :--- |
| **`scripts/install.sh`** | **Core Installer** | **Primary installation script.** Automatically compiles `liblsfg-vk-layer.so` on-device if not present, configures Vulkan loader manifests, sets up default configuration profiles, and installs `~/lsfg`. |
| **`scripts/lsfg-frame`** | **Core Runtime** | **Launch wrapper.** Installed to `~/lsfg` and `~/.local/bin/lsfg-frame`. Handles `lsfg-vk.dll` auto-discovery, per-game TOML profile resolution, and flicker-free presentation pacing. |
| **`layer/VkLayer_LSFGVK_frame_generation.json`** | **Core Runtime** | **Vulkan layer manifest template.** Registered with SteamOS's Vulkan loader (`implicit_layer.d` and `explicit_layer.d`) for layer discovery. |
| **`scripts/verify-env.sh`** | **Diagnostics** | **Environment verifier.** Checks CPU architecture, Snapdragon 8 Gen 3 core clusters, Mesa Turnip driver status, FEX-Emu, and `lsfg-vk.dll`. |
| **`scripts/smoke-test-layer.sh`** | **Diagnostics** | **Diagnostic test.** Verifies layer ELF architecture, manifest validity, and Vulkan loader discovery via `vulkaninfo`. |
| **`scripts/build-cross-layer.sh`** | **Developer Tool** | **Reference build script.** Demonstrates building the layer from upstream `lsfg-vk` source using `aarch64-linux-gnu-g++`. |
| **`scripts/install-turnip-aurora.sh`** | **Experimental Tool** | **Alternative driver installer.** Downloads and installs community Balemuni Aurora Turnip driver builds for testing bleeding-edge driver fixes. |
| **`config/config.default.toml`** | **Configuration** | **Default configuration template.** Deployed to `~/.config/steam-frame-lsfg/config.toml`. Pre-tuned with `override_present_mode = false` and `mailbox` presentation. |
| **`config/profiles/*.toml`** | **Configuration** | **Per-game optimization profiles.** Presets deployed by the installer (`1091500.toml` for Cyberpunk 2077, `1145360.toml` for Hades II, `default.toml`). |
| **`decky-plugin/`** | **Optional UI** | **Decky Loader plugin.** Experimental Quick Access Menu (QAM) slider panel for adjusting multipliers and optical flow scale on the fly. |
| **`docs/ARCHITECTURE.md`** | **Documentation** | **Hardware architecture guide.** Comprehensive technical documentation on Snapdragon 8 Gen 3, Adreno 750 GMEM tile memory, and Gamescope WSI. |
| **`docs/REPLICATION_GUIDE.md`** | **Documentation** | **Developer guide.** Full technical walkthrough of building, configuring, and tuning the layer for ARM64. |

---

## 🚀 Quickstart & Setup Guide

### Step 1: Prerequisites
1. **Lossless Scaling Ownership (`lsfg-vk.dll`)**:
   * Purchase [Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) on Steam (App ID `993090`).
   * In your Steam Library, right-click **Lossless Scaling** $\to$ **Properties** $\to$ **Betas**.
   * Under **Beta Participation**, select the **`lsfg-vk`** branch. Steam will download `lsfg-vk.dll`.
2. **ARM64 Vulkan Layer (`liblsfg-vk-layer.so`)**:
   * Build the ARM64 layer from upstream [PancakeTAS/lsfg-vk](https://git.lsfg-vk.dev/lsfg-vk.git) following the [Build Guide](#-building-liblsfg-vk-layer-so-for-steam-frame-arm64).
3. **Valve Steam Frame**:
   * Running SteamOS ARM64 with native Mesa Turnip Vulkan driver.

### Step 2: Place the Compiled Layer & Run Installer
1. Clone this repository on your Steam Frame:
   ```bash
   git clone https://github.com/SylanaZero/steam-frame-lsfg.git
   cd steam-frame-lsfg
   ```
2. Copy your compiled ARM64 `liblsfg-vk-layer.so` into the `layer/` directory (or `~/.local/share/steam-frame-lsfg/lib/`):
   ```bash
   cp /path/to/your/liblsfg-vk-layer.so layer/liblsfg-vk-layer.so
   ```
3. Run the installer:
   ```bash
   bash scripts/install.sh
   ```

The installer will:
* Verify the ARM64 environment and Mesa Turnip Vulkan driver.
* Auto-discover `lsfg-vk.dll` from your Steam library.
* Install and link `liblsfg-vk-layer.so` into system Vulkan directories.
* Generate valid Vulkan 1.3 explicit and implicit layer manifests.
* Install the launch wrapper to `~/lsfg` and `~/.local/bin/lsfg-frame`.
* Deploy the Decky Loader plugin if Decky Loader is present.

### Step 3: Enabling in Games
In the Steam client:
1. Right-click your game $\to$ **Properties**.
2. Under **Launch Options**, enter:
   ```text
   ~/lsfg %command%
   ```
   *(or `/home/steamos/lsfg %command%`)*
3. Launch the game!

#### For Non-Steam Games & Custom Drivers:
Keep environment variables (like `VK_ICD_FILENAMES=...`) before `~/lsfg`:
```text
VK_ICD_FILENAMES=/path/to/custom_icd.json ~/lsfg %command%
```

---

## ⚙️ Recommended In-Game Settings (Flicker-Free & Smooth)

To avoid compositor collisions and frame pacing judder in Gamescope:
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

* **Test Layer Registration**:
  ```bash
  bash scripts/smoke-test-layer.sh
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

## 📄 License & Upstream Policy

This project's original tooling, scripts, configuration profiles, and documentation are licensed under the [MIT License](LICENSE).
* **Lossless Scaling**: Proprietary software developed by THS (available on Steam, App ID `993090`).
* **`lsfg-vk`**: Upstream Vulkan compatibility layer developed by [PancakeTAS](https://lsfg-vk.dev), licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/).

### ⚠️ Upstream Compliance Notice
* **Independent Companion:** This repository is an independent companion configuration and launch wrapper for the Valve Steam Frame. It does not distribute, fork, or host `lsfg-vk` binaries or proprietary shaders.
* **Official Layer:** Users must obtain official source code from [lsfg-vk.dev](https://lsfg-vk.dev) / [git.lsfg-vk.dev](https://git.lsfg-vk.dev/lsfg-vk.git).
* **No Derivative Distribution:** In accordance with the CC BY-NC-ND 4.0 license, this repository hosts no precompiled layer binaries and no patch files.

---

## 🙏 Acknowledgements & Credits

This project builds upon the pioneering work of the open-source Linux gaming and handheld emulation communities:

* **[PancakeTAS](https://git.lsfg-vk.dev/lsfg-vk.git)**: Creator of `lsfg-vk`, the foundational Vulkan compatibility layer that makes frame generation possible on Linux.
* **[xXJSONDeruloXx](https://github.com/xXJSONDeruloXx/decky-lsfg-vk)**: Author of `decky-lsfg-vk`, which established the Decky Loader UI integration and configuration model.
* **[ArmadaOS Project](https://github.com/armada-os/armada)** *(and community contributors Janleyx & BakaPute)*: For groundbreaking work pioneering SteamOS on ARM64 and proving that Lossless Scaling could run on Qualcomm Snapdragon processors.
* **[Balemuni](https://github.com/Balemuni/Balemunis-Aurora)**: Creator of the Aurora Turnip driver packages used for experimental Adreno Vulkan driver testing.
* **[Mesa 3D & Freedreno Team](https://docs.mesa3d.org/drivers/freedreno.html)**: The developers behind the open-source `freedreno_turnip` driver providing Vulkan 1.3 support on Qualcomm Adreno GPUs.
* **[Decky Loader Team](https://github.com/SteamDeckHomebrew/decky-loader)**: For the homebrew plugin framework enabling seamless SteamOS Quick Access Menu integration.
* **[THS](https://store.steampowered.com/app/993090/Lossless_Scaling/)**: Developer of the original Lossless Scaling software and optical flow frame generation technology on Steam.

---

## ⚠️ Disclaimer

This is an independent open-source community project. It is not affiliated with, sponsored by, or endorsed by Valve Corporation, Qualcomm, or THS. Valve, Steam, and Steam Frame are trademarks or registered trademarks of Valve Corporation. All other trademarks are property of their respective owners.

---

## Repository owner's message

This repository exists because I wanted to enable frame generation on the Steam Frame and couldn't find any existing projects to do so.  I don't have the skills to do this, so I asked `Gemini 3.8 Flash High` through Antigravity IDE to take a look at existing open source projects and see if it could figure out how to enable LSFG on Steam Frame given that frame generation has already been proven to work on Snapdragon 8 processors through projects such as ArmadaOS, GameNative, etc.  It took about 9 hours of back-and-forth testing, log generation, and analysis for LSFG to work successfully on a handful of titles (Scarlet Nexus, Jedi: Fallen Order, and Wow: Forever).  I can't tell you if it'll work on your favorite game, but as a proof of concept, it works.  I've tried to provide as much of the generated files and documentation as I can so others can pick up this work and improve it in ways I cannot.

I've never published anything open source before, so please be gentle with feedback.

Here's the prompt I used to kick off this project:

```text
Let's create a new project.

I'd like to see about adding Lossless Scaling Frame Generation (LSFG) support to the Valve "Steam Frame".  It's currently supported on the Steam Deck, but I can't find any projects that enable it on the Steam Frame, which is running on an ARM64 processor (Snapdragon 8, Gen 3 with an Adreno 750 GPU).  

1. On the Steam Deck, you would typically purchase Lossless Scaling:
https://store.steampowered.com/app/993090/Lossless_Scaling/

2. Then install the Decky Loader:
https://github.com/steamdeckhomebrew/decky-loader

3. Then install the decky-lsfg-vk Decky plugin
https://github.com/xXJSONDeruloXx/decky-lsfg-vk

4. Then you would add the following string to the Launch Options of an individual game before launching it which would enable frame generation:
~/lsfg %command%

However, there is a version of SteamOS that has been adapted to ARM64 Platforms like the AYN Thor (Snapdragon 8, Gen 2) and the AYN Odin 3 (Snapdragon 8 Elite, Gen 5) called ArmadaOS.  They've managed to add decky-lsfg-vk support to this ARM64 version of SteamOS.
https://github.com/armada-os/armada

There are also ARM64 compatible android apps that enable LSFG framegen like:
GameNative: https://github.com/utkarshdalal/GameNative
DroidDeck: https://github.com/Droid-Deck/DroidDeck

What would be the best way to go about adding lsfg-vk support to the Steam Frame?  

1. Updating decky-loader to be compatible with Steam Frame and then loading lsfg-vk?
2. Creating a standalone plugin that can be run per app on the Steam Frame?
3. Something else?
```

Antigravity responded:

```text
Analysis of Your Three Options

Option 1: Updating Decky Loader to be compatible, then loading lsfg-vk
Verdict: Necessary for GUI convenience, but insufficient on its own.
Why: Decky Loader is strictly a frontend UI plugin manager injecting into Steam’s Chromium Embedded Framework (CEF). It does not intercept graphics calls or execute Vulkan layers. Even if Decky Loader is ported to Steam Frame (which is straightforward since its Python backend already runs on ARM64 platforms like ArmadaOS), you still need the underlying native ARM64 Vulkan layer (libVkLayer_lsfg.so) and driver hooks. Furthermore, Decky Loader frequently breaks whenever Valve updates SteamOS/CEF.

Option 2: Creating a standalone plugin / wrapper that runs per app
Verdict: Essential for rock-solid reliability.
Why: Wrapping game execution via launch options (~/lsfg %command%) or hooking into Proton directly bypasses the Steam UI layer entirely. It communicates directly with Vulkan and FEX-Emu/Proton via environment variables (ENABLE_LSFG=1, VK_INSTANCE_LAYERS=VK_LAYER_LS_frame_generation). However, its drawback is that players cannot adjust multipliers or flow scale on the fly without exiting the game.

Option 3: The Recommended Strategy — Hybrid Dual-Tier Architecture

Following the lessons from ArmadaOS (e.g., Janleyx/decky-lsfg-vk-for-Ayn-Odin-2 and BakaPute/ArmadaLSFG) and GameNative/DroidDeck, the gold standard is decoupling the engine from the UI:

Tier 1 (Core Engine & Wrapper):
A native ARM64 Vulkan layer (libVkLayer_lsfg.so + VkLayer_lsfg.json).
Snapdragon 8 Gen 3 / Adreno 750 Tuning: Enforces FP16 half-precision compute shaders on Adreno ALUs and bypasses GMEM tile stall penalties (direct_rendering = true) in the Mesa Turnip driver.
Automatic Lossless.dll Linking: Scans Steam libraries for the user's purchased copy of Lossless Scaling (App ID 993090) to load the proprietary model legally.
Launch Wrapper: scripts/lsfg-frame, invoked as ~/lsfg %command% with support for per-game TOML profiles.

Tier 2 (Optional In-Game Control Surface):
A dedicated Steam Frame LSFG Decky Plugin (decky-plugin/) that reads and modifies the exact same configuration files in real time.
Lets players toggle frame generation and switch multipliers (2x, 3x, 4x) directly in the Quick Access Menu (QAM) while playing. If Decky is disabled or broken by a Steam update, the core system continues working seamlessly.
```

...and we proceeded from there.  I never got Decky to work on the Steam Frame, but Antigravity/Gemini still ended up generating a decky-plugin anyway (I have no idea if it works).
