# Steam Frame LSFG: Quickstart Guide

Lossless Scaling Frame Generation (LSFG) for the **Valve Steam Frame** (Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, running SteamOS ARM64).

---

## 📋 Prerequisites
1. **Lossless Scaling (`lsfg-vk.dll`)**: Purchased on Steam (App ID `993090`). Right-click **Lossless Scaling** in Steam $\to$ **Properties** $\to$ **Betas** $\to$ select **`lsfg-vk`** branch.
2. **ARM64 Vulkan Layer**: Built `liblsfg-vk-layer.so` targeting `aarch64` (see [Build Guide in README.md](README.md#-building-liblsfg-vk-layer-so-for-steam-frame-arm64)).
3. **Valve Steam Frame**: Running SteamOS ARM64.

---

## 🚀 Step 1: Install
1. Clone or download this repository onto your Steam Frame:
```bash
git clone https://github.com/SylanaZero/steam-frame-lsfg.git
cd steam-frame-lsfg
```
2. Run the installer:
```bash
bash scripts/install.sh
```
*If `liblsfg-vk-layer.so` is not already compiled, `install.sh` will automatically clone upstream `lsfg-vk` and compile it natively for the Snapdragon 8 Gen 3!*
*(Optional: If you cross-compiled on an x86 PC, you can drop your precompiled `liblsfg-vk-layer.so` into `layer/` before running the installer to skip compilation).*
The installer sets up your `~/lsfg` launcher wrapper, auto-discovers `lsfg-vk.dll`, registers the Vulkan layer, applies anti-flicker presentation settings, and configures default per-game profiles.

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
* **Adjust Config Profiles**:
  * Global settings: `~/.config/steam-frame-lsfg/config.toml`
  * Per-game presets: `~/.config/steam-frame-lsfg/profiles/<appid>.toml`
