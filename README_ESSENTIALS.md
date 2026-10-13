# Steam Frame LSFG (Essentials)

Minimal standalone distribution of Lossless Scaling Frame Generation for the Valve Steam Frame (Qualcomm Snapdragon 8 Gen 3, Adreno 750, SteamOS ARM64).

## Prerequisites
1. You must own **Lossless Scaling** (Steam App ID `993090`) and switch to the **`lsfg-vk`** beta branch in Steam (Properties $\to$ Betas) to download `lsfg-vk.dll`.
   - Alternatively, place `lsfg-vk.dll` directly into this folder.

## Installation
Run the installer from your terminal:
```bash
bash install.sh
```
The installer will:
- Locate `lsfg-vk.dll` and configure the neural shaders.
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

---

## 🙏 Credits & Acknowledgements
Built upon upstream work by **PancakeTAS** (`lsfg-vk`), **xXJSONDeruloXx** (`decky-lsfg-vk`), the **ArmadaOS** ARM64 community, **Balemuni** (Aurora Turnip), the **Mesa/Turnip** team, and **THS** (Lossless Scaling).

---

## 📄 License & Upstream Notice
- **Project tooling, configurations & scripts**: [MIT License](https://opensource.org/licenses/MIT).
- **`lsfg-vk`**: Upstream Vulkan compatibility layer created by [PancakeTAS](https://lsfg-vk.dev), licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/). This repository does not distribute, fork, or modify lsfg-vk binaries.
- **Lossless Scaling**: Proprietary software developed by THS (Steam App ID `993090`).


---

## ⚠️ Disclaimer
This is an independent open-source community project. It is not affiliated with, sponsored by, or endorsed by Valve Corporation, Qualcomm, or THS. Valve, Steam, and Steam Frame are trademarks or registered trademarks of Valve Corporation.
