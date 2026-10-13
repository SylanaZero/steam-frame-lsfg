# Steam Frame LSFG: Comprehensive Build & Replication Guide

This guide documents the end-to-end engineering process used to bring **Lossless Scaling Frame Generation (LSFG)** to the **Valve Steam Frame** (Qualcomm Snapdragon 8 Gen 3 SoC, Adreno 750 GPU, SteamOS ARM64).

If you are a developer or power user who wants to replicate this work, build the layer from scratch, apply custom patches, or adapt this to other ARM64 devices, follow the steps below.

---

## 📋 System Architecture & Target Specifications

* **Target Device**: Valve Steam Frame (standalone spatial/handheld computing platform)
* **Host SoC**: Qualcomm Snapdragon 8 Gen 3 (SM8650-AB)
* **CPU Cores**: 1× Cortex-X4 @ 3.3 GHz, 5× Cortex-A720 @ 3.2 GHz, 2× Cortex-A520 @ 2.3 GHz (ARMv9.2-A / `aarch64`)
* **GPU**: Qualcomm Adreno 750 (770–1000 MHz peak)
* **Operating System**: SteamOS ARM64 (Arch Linux base, Wayland / Gamescope compositor)
* **Display Output**: Fixed 90 Hz compositor in 2D flat mode (72, 90, 120, 144 Hz in direct VR mode)
* **Graphics Driver**: Mesa Turnip (`freedreno_turnip`) Vulkan 1.3 ICD

---

## 🧰 Development Host Requirements & Environment Setup

You can build the project from an **x86_64 PC** using cross-compilation (Windows 11 with WSL2, or native Linux), or **natively on an ARM64 Linux system**.

### Option A: Cross-Compiling on Windows 11 via WSL2 (Debian / Ubuntu)

1. **Install WSL2**:
   ```powershell
   wsl --install -d Debian
   ```
2. **Install Required Build Tools & ARM64 Cross-Compiler**:
   Inside WSL (Debian/Ubuntu):
   ```bash
   sudo apt-get update
   sudo apt-get install -y \
       build-essential \
       gcc-aarch64-linux-gnu \
       g++-aarch64-linux-gnu \
       binutils-aarch64-linux-gnu \
       cmake \
       ninja-build \
       git \
       pkg-config \
       python3 \
       file
   ```

### Option B: Docker Container Cross-Compilation

If you prefer building in an isolated container without installing host tools, use the provided `Dockerfile.cross`:
```bash
docker build -f Dockerfile.cross -t steam-frame-lsfg-builder .
docker run --rm -v "$(pwd)":/workspace steam-frame-lsfg-builder
```

---

## 📦 Upstream Repositories

1. **Core Vulkan Layer (`lsfg-vk`)**:
   * Upstream Repository: `https://git.lsfg-vk.dev/lsfg-vk.git` (mirror of PancakeTAS's project)
   * Role: Intercepts Vulkan swapchain presentation (`vkQueuePresentKHR`, `vkCreateSwapchainKHR`), unpacks shaders from `lsfg-vk.dll`, and executes optical flow compute passes.
2. **Decky Loader UI Plugin**:
   * Upstream Repository: `https://github.com/xXJSONDeruloXx/decky-lsfg-vk`
   * Role: Optional frontend providing Quick Access Menu (QAM) sliders when Decky Loader is present.
3. **Proprietary Model**:
   * Steam App ID `993090` ([Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/))
   * Source: `lsfg-vk.dll` (v3.2.2.0, 2.1 MB Vulkan PE binary available via the `lsfg-vk` Steam beta branch)

---

## 🔍 Key Discoveries & Technical Challenges

### Discovery 1: Why Linux Uses `lsfg-vk.dll` Instead of `Lossless.dll`

* **`Lossless.dll` (Windows Multi-API Package)**:
  Contains Direct3D 11 (101–200), Direct3D 12 (201–300), and Vulkan shaders (301–400). It lacks resource `2147488584U` and has all Vulkan shaders shifted by `+300`.
* **`lsfg-vk.dll` (Linux Vulkan Package via Steam `lsfg-vk` Beta Branch)**:
  Contains strictly the 99 Vulkan SPIR-V shaders (IDs 1–99) and includes resource ID `2147488584U` for `mipmaps`.
* **Key Finding**:
  Because upstream `lsfg-vk` was written specifically to parse `lsfg-vk.dll`, **stock upstream source code requires ZERO shader or pipeline patches** when using `lsfg-vk.dll`. The project is fully decoupled from Windows `Lossless.dll`.

---

### Discovery 2: The Screen Flickering in Gamescope & Wayland WSI

#### The Symptom:
Frame generation produced higher framerates, but users experienced severe, rapid screen flickering (strobing) in games like *Scarlet Nexus* and *Star Wars Jedi: Fallen Order*.

#### The Root Cause:
* In `modes/vsync.cpp`, the layer presents **two frames in rapid succession** for every game render:
  1. `vkQueuePresentKHR(Generated Frame)`
  2. `vkQueuePresentKHR(Real Frame)`
* When `override_present_mode = true` was active, the layer forced `VK_PRESENT_MODE_FIFO_KHR`. Additionally, the launch wrapper forced `MESA_VK_WSI_PRESENT_MODE="fifo"`.
* In `FIFO` mode, every present call MUST wait for a hardware vertical blanking interval (VBLANK). Submitting two presentations within microseconds caused the Wayland presentation queue to block. One frame stalled, swapchain buffer starvation occurred, and Gamescope alternated between dropping the synthetic frame or presenting stale buffers.

#### The Fix:
1. In `config/config.default.toml`, set:
   ```toml
   override_present_mode = false
   ```
2. In `scripts/lsfg-frame`, default `MESA_VK_WSI_PRESENT_MODE` to `mailbox` instead of `fifo`:
   ```bash
   if [ "$LSFGVK_OVERRIDE_PRESENT_MODE" = "1" ]; then
       export MESA_VK_WSI_PRESENT_MODE="${MESA_VK_WSI_PRESENT_MODE:-fifo}"
   else
       export MESA_VK_WSI_PRESENT_MODE="${MESA_VK_WSI_PRESENT_MODE:-mailbox}"
   fi
   ```
Under `mailbox` presentation, frames flow into Gamescope smoothly without backpressure or dropped frames, completely eliminating the flickering.

---

## 🛠️ Step-by-Step Compilation Guide

Follow these steps to build the ARM64 layer binary from stock upstream source:

### Step 1: Clone Upstream Source
```bash
git clone --depth 1 https://git.lsfg-vk.dev/lsfg-vk.git submodules/lsfg-vk
```

*(Note: No C++ code patches to `library.cpp` are needed because `lsfg-vk.dll` is parsed natively!)*

### Step 3: Configure the CMake ARM64 Toolchain
Create `cmake/aarch64-toolchain.cmake`:
```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_AR aarch64-linux-gnu-ar)
set(CMAKE_STRIP aarch64-linux-gnu-strip)
set(CMAKE_RANLIB aarch64-linux-gnu-ranlib)

# Optimize for Qualcomm Snapdragon 8 Gen 3 (ARMv9.2-A / FP16 compute)
set(CMAKE_C_FLAGS_INIT "-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -fPIC")
set(CMAKE_CXX_FLAGS_INIT "-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -fPIC")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-static-libstdc++ -static-libgcc")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
```

### Step 4: Configure & Build
```bash
cmake -B submodules/lsfg-vk/build-arm64 -S submodules/lsfg-vk \
    -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=cmake/aarch64-toolchain.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DLSFGVK_BUILD_LAYER=ON \
    -DLSFGVK_BUILD_CLI=OFF \
    -DLSFGVK_BUILD_UI=OFF

# Compile the Vulkan layer target
cmake --build submodules/lsfg-vk/build-arm64 --target lsfg-vk-layer -j$(nproc)
```

### Step 5: Strip & Deploy Output
```bash
mkdir -p layer
# Strip unneeded debug symbols (cuts size from ~18MB to 2.4MB)
aarch64-linux-gnu-strip --strip-unneeded submodules/lsfg-vk/build-arm64/lsfg-vk-layer/liblsfg-vk-layer.so -o layer/liblsfg-vk-layer.so

# Copy the Vulkan layer JSON manifest
cp submodules/lsfg-vk/build-arm64/lsfg-vk-layer/VkLayer_LSFGVK_frame_generation.json layer/
```

*(All of the above build steps are automated by running `bash scripts/build-cross-layer.sh`)*.

---

## 🧪 Verification & Smoke Testing

To test the compiled layer binary before transferring it to the Steam Frame:
```bash
bash scripts/smoke-test-layer.sh
```
This script validates:
1. That `layer/liblsfg-vk-layer.so` is a valid 64-bit ARM ELF shared object.
2. That `layer/VkLayer_LSFGVK_frame_generation.json` manifest syntax is valid.
3. That Vulkan loader registration succeeds with `VK_LAYER_PATH`.
4. That TOML configuration profiles are present and well-formed.

---

## 📦 Packaging for Distribution

When packaging a release zip file for Linux/SteamOS:
1. **Use standard PKZIP format** (header `50-4B-03-04`). Avoid GNU `tar -a`, which produces a POSIX tarball with a `.zip` extension that Linux `unzip` rejects.
2. **Normalize directory separators to POSIX forward slashes (`/`)** so `unzip` creates proper subdirectories on Linux.
3. **Include the 19 core items**:
   * `QUICKSTART.md`, `README.md`, `docs/`
   * `config/` (templates and profiles)
   * `layer/` (`liblsfg-vk-layer.so` and `VkLayer_LSFGVK_frame_generation.json`)
   * `scripts/` (`install.sh`, `lsfg-frame`, `verify-env.sh`, `smoke-test-layer.sh`, `build-cross-layer.sh`, `install-turnip-aurora.sh`)
   * `decky-plugin/`

---

## 🚀 Deployment on Steam Frame

On the Steam Frame:
```bash
git clone https://github.com/SylanaZero/steam-frame-lsfg.git
cd steam-frame-lsfg
bash scripts/install.sh
```


In Steam Game Launch Options:
* Standard games: `~/lsfg %command%`
* Non-Steam games with custom drivers: `VK_ICD_FILENAMES=/path/to/icd.json ~/lsfg %command%`
* Debug logging (opt-in): `LSFG_DEBUG=1 ~/lsfg %command%`
