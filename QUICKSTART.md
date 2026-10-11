# Steam Frame LSFG: Quickstart Guide

Lossless Scaling Frame Generation (LSFG) for the **Valve Steam Frame** (Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, running SteamOS ARM64).

---

## 🚀 Step 1: Install
1. Transfer `steam-frame-lsfg-release.zip` to your Steam Frame.
2. In a terminal or via SSH, extract into a dedicated folder and run the installer:
```bash
unzip -o steam-frame-lsfg-release.zip -d steam-frame-lsfg
cd steam-frame-lsfg
bash scripts/install.sh
```
The installer automatically deploys the pre-compiled ARM64 Vulkan layer, configures the `~/lsfg` launcher, and sets up your default profiles. **No compilation or root/sudo required.**

> [!NOTE]
> **Lossless Scaling Branch Details:**
> In Steam, *Lossless Scaling* provides the framegen model as `Lossless.dll` on the default branch, or as `lsfg-vk.dll` if you opt into the `lsfg-vk` beta branch (Properties $\to$ Betas).
> `install.sh` automatically checks for **both** and mirrors both filenames into `~/.local/share/steam-frame-lsfg/lib/`, so either branch works out of the box.

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
