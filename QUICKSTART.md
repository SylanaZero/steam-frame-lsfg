# Steam Frame LSFG: Quickstart Guide

## Step 1: Extract & Install
On your Valve Steam Frame, open a terminal (or SSH) in the extracted folder:

```bash
# Run the main installer (sets up configs, launcher, and ARM64 Vulkan layer):
bash scripts/install.sh
```

*(Note: SteamOS on Steam Frame already includes Valve's official Mesa Turnip Vulkan driver preinstalled. Decky Loader is NOT required—the system operates standalone.)*

---

## Step 2: Verify Installation
Run the verification script to confirm everything is healthy:

```bash
bash scripts/verify-env.sh
```

---

## Step 3: Enable in Steam Games
1. In Steam, navigate to your game and click the **Gear Icon (Properties)**.
2. Under the **General** tab, find **Launch Options**.
3. Enter:
   ```text
   /home/steamos/lsfg %command%
   ```
4. Start your game!

---

## Verifying & Logs
To verify that frame generation is actively running for your game:
```bash
cat ~/.local/share/steam-frame-lsfg/lsfg.log
```

---

## Customizing Settings
Settings are stored in:
* Global config: `~/.config/steam-frame-lsfg/config.toml`
* Per-game presets: `~/.config/steam-frame-lsfg/profiles/<appid>.toml`

You can edit these files directly to adjust frame generation multipliers (`2`, `3`), optical flow scale (`0.75`), or performance modes.
