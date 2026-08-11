#!/bin/bash
export PATH="/home/ghitatruongle/flutter/bin:$PATH"
cd "/mnt/e/G.A - Song"
echo "=== Flutter Version ==="
flutter --version 2>&1 | head -3
echo "=== Pub Get ==="
flutter pub get 2>&1 | tail -5
echo "=== Build Linux ==="
flutter build linux 2>&1 | tail -15
