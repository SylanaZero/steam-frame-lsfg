# CMake toolchain file for cross-compiling Steam Frame LSFG (ARM64 / aarch64)
# Target: Qualcomm Snapdragon 8 Gen 3 (Cortex-X4 / Cortex-A720 / Adreno 750)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Cross compilers
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_AR aarch64-linux-gnu-ar)
set(CMAKE_STRIP aarch64-linux-gnu-strip)
set(CMAKE_RANLIB aarch64-linux-gnu-ranlib)

# Hardware-tuned compiler flags for Snapdragon 8 Gen 3 (ARMv9.2-A / FP16 compute)
set(CMAKE_C_FLAGS_INIT "-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -fPIC")
set(CMAKE_CXX_FLAGS_INIT "-O3 -march=armv8.2-a+fp16 -mtune=cortex-a720 -fPIC")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-static-libstdc++ -static-libgcc")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
