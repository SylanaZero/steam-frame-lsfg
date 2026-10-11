# Steam Frame LSFG (Lossless Scaling Frame Generation) Architecture

## 1. Executive Summary & Device Profile

The **Valve Steam Frame** represents Valve's standalone ARM64 spatial/handheld computing platform, powered by:
- **SoC**: Qualcomm Snapdragon 8 Gen 3 (SM8650-AB)
- **CPU**: 1x Cortex-X4 @ 3.3 GHz, 5x Cortex-A720 @ 3.2 GHz, 2x Cortex-A520 @ 2.3 GHz (ARMv9.2-A)
- **GPU**: Adreno 750 (770 MHz / 1000 MHz peak)
- **Memory**: 16 GB LPDDR5X Unified RAM (75 GB/s bandwidth)
- **Display**: Dual 2160 × 2160 displays operating at 72 Hz, 90 Hz, 120 Hz, or 144 Hz
- **Operating System**: SteamOS ARM64 (Arch Linux base, systemd, Wayland / Gamescope compositor)
- **Runtime Stack**: Proton 11+ ARM64 (Wine + DXVK/VKD3D-Proton + FEX-Emu CPU translation)
- **Graphics Driver**: Mesa Turnip (`freedreno_turnip`) Vulkan ICD

### The Frame Generation Imperative on Steam Frame
Driving high-resolution displays (2160×2160 per eye) at 90Hz, 120Hz, or 144Hz on a mobile SoC requires immense GPU fill-rate and compute. Running games natively at 90+ FPS often leads to thermal throttling or reduced visual fidelity. 
Lossless Scaling Frame Generation (LSFG) allows the SoC to render games at a stable **45 FPS** (interpolated to **90 FPS**) or **60 FPS** (interpolated to **120 FPS**), drastically lowering CPU/GPU rendering overhead and heat dissipation while maintaining display smoothness.

---

## 2. Comparison of Implementation Approaches

The user posed three architectural avenues:

| Criterion | Option 1: Update Decky Loader Only | Option 2: Standalone Per-App Plugin / CLI Wrapper | Option 3: Hybrid Layered Architecture (Recommended) |
| :--- | :--- | :--- | :--- |
| **How It Works** | Port `decky-loader` and load existing `decky-lsfg-vk` | Build a standalone launch wrapper (`lsfg %command%`) & Vulkan layer | Deploy a hardware-tuned native ARM64 Vulkan layer + robust CLI wrapper + optional Decky QAM UI |
| **Decky Independence** | ❌ Hard dependency on Decky Loader | ✅ 100% independent of Decky | ✅ Independent; works via CLI even if Decky is broken or absent |
| **Steam Client Resiliency** | ⚠️ Breaks when Steam Client CEF updates | ✅ Immune to Steam Client CEF updates | ✅ Core stays functional; UI recovers on plugin update |
| **In-Game Quick Access** | ✅ Quick Access Menu (QAM) sliders | ❌ Requires quitting game to edit launch options | ✅ QAM sliders when Decky is active; config fallback otherwise |
| **Driver & SoC Tuning** | ❌ Generic x86 port, lacks Adreno 750 tuning | ⚠️ Manual env variables required | ✅ Automatic Adreno 750 / Turnip optimizations baked in |
| **`Lossless.dll` FEX Bridge** | ⚠️ Fails if not properly handled across FEX boundary | ⚠️ Depends on manual file copying | ✅ Automated detection from Steam Library + Wine/FEX path mapping |

### Why Option 3 (Hybrid Layered Architecture) is Optimal:
1. **Separation of Concerns**: The Vulkan frame interception layer (`lsfg-vk`) must execute close to the GPU driver (Mesa Turnip). Decky Loader is merely a UI frontend running in the Steam CEF browser. Tying driver-level frame generation strictly to a web plugin causes severe fragility.
2. **ArmadaOS Precedent**: In ArmadaOS on Snapdragon 8 Gen 2 / 8 Elite (Odin 2/3 and Thor), community ports (e.g., `Janleyx/decky-lsfg-vk-for-Ayn-Odin-2` and `BakaPute/ArmadaLSFG`) proved that packaging a dedicated ARM64 Vulkan layer with a standalone wrapper script (`~/lsfg`) is mandatory for stability, while the Decky plugin acts as a control surface.
3. **Turnip & Adreno 750 Specifics**: The Adreno 750 GPU has specific GMEM tile limitations and compute shader synchronization primitives that benefit from dedicated Vulkan layer tuning.

---

## 3. System Architecture & Component Diagram

```
+-----------------------------------------------------------------------------------+
|                              USER INTERACTION LEVEL                               |
|                                                                                   |
|   [ Steam Deck / Frame QAM ]                         [ Steam Launch Options ]     |
|   (Decky Plugin UI: Multiplier,                     (Launch via `~/lsfg %command%`|
|    Flow Scale, Perf Mode)                               or standalone wrapper)    |
+-----------------------------------------------------------------------------------+
                                       |                                    |
                                       v                                    v
+-----------------------------------------------------------------------------------+
|                        ORCHESTRATION & CONFIGURATION LAYER                        |
|                                                                                   |
|   ~/.config/steam-frame-lsfg/config.toml  <--->  scripts/lsfg-frame wrapper       |
|   - Per-AppID Profiles (profiles/<appid>.toml)                                    |
|   - Auto-locates Lossless.dll in Steam Library                                    |
+-----------------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------------+
|                             GAME EXECUTION RUNTIME                                |
|                                                                                   |
|   Windows x86_64 Game Executable (e.g., Cyberpunk 2077, Hades II, etc.)           |
|                                  |                                                |
|   FEX-Emu / Box64 CPU Translation Bridge (x86_64 -> ARM64)                       |
|                                  |                                                |
|   Wine 9/10 / Proton 11 Graphics Pipeline (DXVK / VKD3D-Proton)                   |
+-----------------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------------+
|                        VULKAN FRAME GENERATION LAYER                              |
|                                                                                   |
|   VK_LAYER_LSFGVK_frame_generation (Native ARM64 `liblsfg-vk-layer.so`)           |
|   - Hooks vkQueuePresentKHR & vkCreateSwapchainKHR                                |
|   - Loads frame-generation model from licensed Lossless.dll                       |
|   - Executes optical flow & intermediate frame synthesis                          |
|   - Tuned for Adreno 750 FP16 Compute Shaders                                     |
+-----------------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------------+
|                        HARDWARE & DRIVER LEVEL (ARM64)                            |
|                                                                                   |
|   Mesa Turnip Driver (`libvulkan_freedreno.so`) + KGSL / DRM                      |
|                                  |                                                |
|   Qualcomm Adreno 750 GPU  --->  Gamescope / SteamVR Compositor (72/90/120/144Hz) |
+-----------------------------------------------------------------------------------+
```

---

## 4. Hardware & Driver Considerations (Snapdragon 8 Gen 3)

1. **Mesa Turnip (`freedreno_turnip`) Compatibility**:
   - Turnip supports Vulkan 1.3 with full compute shader capabilities.
   - For LSFG optical flow compute passes, FP16 arithmetic (`VK_KHR_shader_float16_int8`) allows 2x compute throughput on the Adreno 750 ALUs, cutting frame generation latency down to <4ms.
2. **Thermal & Power Budget**:
   - The Snapdragon 8 Gen 3 operates within a 15W–25W thermal envelope on handhelds and active-cooled headsets.
   - Setting LSFG to `Performance Mode` (lower optical flow grid resolution) saves ~3W of power without perceptible loss in visual motion clarity.
3. **Display Refresh Rates**:
   - Target 90 Hz: 45 FPS base -> 2x LSFG -> 90 FPS
   - Target 120 Hz: 60 FPS base -> 2x LSFG -> 120 FPS
   - Target 144 Hz: 72 FPS base -> 2x LSFG -> 144 FPS
   - Target 90 Hz (heavy titles): 30 FPS base -> 3x LSFG -> 90 FPS
