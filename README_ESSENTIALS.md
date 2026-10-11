# Steam Frame LSFG (Essentials)

Minimal standalone distribution of Lossless Scaling Frame Generation for the Valve Steam Frame (Qualcomm Snapdragon 8 Gen 3, Adreno 750, SteamOS ARM64).

## Prerequisites
1. You must own and install **Lossless Scaling** (Steam App ID `993090`) on this device via Steam.
   - Alternatively, place `Lossless.dll` or `lsfg-vk.dll` directly into this folder.

## Installation
Run the installer from your terminal:
```bash
bash install.sh
```
The installer will:
- Locate `Lossless.dll` and set up the neural shaders.
- Install the ARM64 Vulkan layer and manifest.
- Configure anti-flicker presentation (`override_present_mode = false`, `mailbox` queue).
- Create the `~/lsfg` launcher shortcut.

## Using in Games
In your Steam Library:
1. Open any game's **Properties**.
2. Under **Launch Options**, enter:
   ```text
   ~/lsfg %command%
   ```
3. Start the game.

## Troubleshooting / Debug Logging
To enable verbose logging if troubleshooting a specific title:
```text
LSFG_DEBUG=1 ~/lsfg %command%
```
