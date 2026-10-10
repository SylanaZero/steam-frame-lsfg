# Steam Frame LSFG: Lossless Scaling Frame Generation for Valve Steam Frame

[![Architecture](https://img.shields.io/badge/Architecture-ARM64%2Faarch64-blue.svg)](#)
[![GPU Target](https://img.shields.io/badge/GPU-Qualcomm%20Adreno%20750-orange.svg)](#)
[![Driver](https://img.shields.io/badge/Driver-Mesa%20Turnip%20(Vulkan%201.3)-green.svg)](#)
[![Platform](https://img.shields.io/badge/OS-SteamOS%20ARM64-purple.svg)](#)

A dedicated, hardware-optimized project providing **Lossless Scaling Frame Generation (LSFG)** support on the **Valve Steam Frame** (Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, running SteamOS ARM64).

---

## 🎯 Architectural Overview: Which Approach is Best?

When bringing `lsfg-vk` to the Valve Steam Frame, three strategies were evaluated:

### 1. Updating Decky Loader to be compatible and loading `lsfg-vk`
* **Assessment**: Necessary for the best user experience (in-game QAM sliders), but **insufficient on its own**. Decky Loader is merely a UI injection layer into Steam's CEF interface. It cannot intercept Vulkan draw/present calls without the underlying native ARM64 Vulkan layer (`libVkLayer_lsfg.so`). Relying solely on Decky also causes breaks every time Valve updates the Steam Client.

### 2. Creating a standalone plugin that runs per-app (`~/lsfg %command%`)
* **Assessment**: Extremely robust and resilient to Steam updates. It interfaces directly with Vulkan, Proton, and FEX-Emu via environment variables (`ENABLE_LSFG=1`, `VK_INSTANCE_LAYERS=VK_LAYER_LS_frame_generation`). However, adjusting settings requires quitting the game to edit text config files.

### 3. The Recommended Solution: Hybrid Dual-Tier Architecture
This repository implements a **Hybrid Dual-Tier Architecture**:
* **Tier 1 (Core Engine & Wrapper)**: A native ARM64 Vulkan layer with Adreno 750 / Turnip optimizations, auto-detection for licensed `Lossless.dll`, per-AppID TOML profiles, and a robust standalone launcher (`~/lsfg %command%`).
* **Tier 2 (Control Surface)**: A native Decky Loader plugin for Steam Frame that interfaces with the same configuration files, allowing on-the-fly toggling and multiplier adjustments from the Steam Quick Access Menu (QAM) without quitting your game.

---

## 📦 Project Structure

```
steam-frame-lsfg/
├── README.md                      # Complete setup and user guide
├── docs/
│   └── ARCHITECTURE.md            # In-depth architectural analysis & driver deep-dive
├── layer/
│   └── VkLayer_lsfg.json          # Vulkan Layer specification manifest (ARM64)
├── scripts/
│   ├── install.sh                 # One-click installation & deployment script
│   ├── lsfg-frame                 # Production launch wrapper (~/lsfg)
│   └── verify-env.sh              # System diagnostic & environment check script
├── config/
│   ├── config.default.toml        # Adreno 750 tuned global configuration
│   └── profiles/                  # Per-game AppID optimization profiles
│       ├── default.toml
│       ├── 1091500.toml           # Cyberpunk 2077
│       └── 1145360.toml           # Hades II
└── decky-plugin/                  # Optional Decky Loader Quick Access Menu UI
    ├── plugin.json
    ├── package.json
    ├── main.py                    # Python backend managing configs & AppIDs
    └── src/
        └── index.tsx              # React UI for SteamOS Gamepad QAM
```

---

## 🚀 Quickstart Guide

### Step 1: Prerequisites
1. **Lossless Scaling Ownership**: Purchase and download [Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) on Steam. The proprietary `Lossless.dll` model is required and legally verified from your local Steam library.
2. **Proton ARM64 & FEX-Emu**: Pre-installed on SteamOS for Steam Frame.

### Step 2: Installation
Clone or copy this project to your Steam Frame and run:
```bash
cd steam-frame-lsfg
chmod +x scripts/*.sh scripts/lsfg-frame
./scripts/install.sh
```

The installer will:
1. Validate ARM64 architecture and detect your Snapdragon 8 Gen 3 / Turnip driver.
2. Locate `Lossless.dll` in your Steam directories (`~/.steam/steam/steamapps/common/...`).
3. Deploy the Vulkan layer manifest to `~/.local/share/vulkan/implicit_layer.d/`.
4. Install the launch wrapper to `~/lsfg` and `~/.local/bin/lsfg-frame`.
5. Automatically detect and deploy the Decky Loader plugin if Decky is installed.

### Step 3: Enabling in Games
In the Steam client:
1. Navigate to your desired game -> **Settings / Properties**.
2. In **Launch Options**, prepend the wrapper:
   ```bash
   ~/lsfg %command%
   ```
3. Launch the game!

---

## ⚙️ Snapdragon 8 Gen 3 & Adreno 750 Optimization

Steam Frame features dual 2160 × 2160 displays operating at **72 Hz, 90 Hz, 120 Hz, or 144 Hz**. This project includes hardware-specific tuning in `config/config.default.toml`:

| Setting | Recommended Value | Rationale |
| :--- | :--- | :--- |
| **`multiplier`** | `2` (or `3`) | Converts 45 FPS -> 90 FPS, 60 FPS -> 120 FPS, or 72 FPS -> 144 FPS. |
| **`flow_scale`** | `0.75` | Computes optical flow at 75% resolution to save memory bandwidth while preserving edges. |
| **`performance_mode`**| `true` | Enforces FP16 half-precision ALU compute, cutting shader execution time in half on Adreno 750. |
| **`TU_DEBUG`** | `noconform` | Avoids conformance overhead in Mesa Turnip for custom swapchain presentations. |
| **`direct_rendering`**| `true` | Bypasses GMEM tile memory for full-screen frame generation passes, avoiding tile stall penalty. |

---

## 🛠️ Diagnostics & Troubleshooting

Run the verification tool to diagnose any configuration issues:
```bash
./scripts/verify-env.sh
```

* **Game fails to start?** Check if `Lossless.dll` is properly detected by checking `~/.config/steam-frame-lsfg/config.toml`.
* **High latency?** Set `performance_mode = true` and `flow_scale = 0.65` in the game's profile to reduce optical flow overhead.
