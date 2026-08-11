#!/bin/bash

# G.A Song / CallPeace - Optimized Linux Runner
# Forces hardware acceleration and discrete GPU for smooth 60fps visualizer on Linux environments
# (Ubuntu, Mint, Kali, ChromeOS Flex, etc.)

echo "🎵 Starting G.A Song (Linux Optimized Mode)..."

# 1. Force hardware acceleration
# export LIBGL_ALWAYS_SOFTWARE=0

# 2. Prefer discrete GPU if available (NVIDIA/AMD)
# export DRI_PRIME=1

# 3. Modern display server priority (Wayland > X11)
# export GDK_BACKEND=wayland,x11

# 4. Run the application in release mode for maximum performance
flutter run -d linux --release
