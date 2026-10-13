# Steam Frame LSFG: Quickstart Guide

Lossless Scaling Frame Generation (LSFG) for the **Valve Steam Frame** (Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, running SteamOS ARM64).

---

## 📋 Prerequisites

1. **Lossless Scaling (`lsfg-vk.dll`)**: Purchased on Steam (App ID `993090`). Right-click **Lossless Scaling** in Steam $\to$ **Properties** $\to$ **Betas** $\to$ select **`lsfg-vk`** branch.
2. **Valve Steam Frame**: Running SteamOS ARM64.

---

## 🚀 Step 1: Install

### Option A: Using the Installer Release Archive (Recommended)
1. Download [`steam-frame-lsfg-installer.zip`](steam-frame-lsfg-installer.zip) onto your Steam Frame.
2. In Desktop Mode, extract and run:
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

*The installer automatically validates your system, auto-discovers `lsfg-vk.dll`, clones and compiles `liblsfg-vk-layer.so` for ARM64 on-device, registers Vulkan layer manifests, deploys tuned anti-flicker configs, and sets up your `~/lsfg` launcher wrapper.*

---

## 🎮 Step 2: Enable in Games

### Standard Steam Games
1. In Steam, go to your game's **Properties** (gear icon).
2. Under **Launch Options**, enter:
```text
~/lsfg %command%
```
*(or `/home/steamos/lsfg %command%`)*

### Non-Steam Games & Custom Drivers (e.g., WoW Forever / Battle.net)
If your game uses custom driver paths (such as `VK_ICD_FILENAMES=...`), keep environment variables at the front:
```text
VK_ICD_FILENAMES=/path/to/icd.json ~/lsfg %command%
```

---

## ⚙️ Recommended In-Game Settings (Smooth & Flicker-Free)

To ensure smooth frame pacing and avoid compositor conflicts:
1. **In-Game V-Sync**: **OFF** (presentation is paced smoothly via Vulkan Mailbox).
2. **Display Mode**: **Borderless Windowed** (or Windowed Fullscreen).
3. **Motion Blur**: **OFF** (prevents optical flow motion vector noise).
4. **SteamOS Performance Overlay**: Ensure **Framerate Limit** is set to **Off / Unlimited**.

---

## 🛠️ Debugging & Logs

By default, disk logging is **disabled** to avoid filling storage during long play sessions.

* **Enable Debug Logging for a session**:
  ```text
  LSFG_DEBUG=1 ~/lsfg %command%
  ```
  Inspect output with:
  ```bash
  cat ~/.local/share/steam-frame-lsfg/lsfg.log
  ```
* **Verify System Health**:
  ```bash
  bash scripts/verify-env.sh
  ```
* **Verify Layer Discovery**:
  ```bash
  bash scripts/smoke-test-layer.sh
  ```
* **Adjust Config Profiles**:
  * Global settings: `~/.config/steam-frame-lsfg/config.toml`
  * Per-game presets: `~/.config/steam-frame-lsfg/profiles/<appid>.toml`
