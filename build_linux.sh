#!/bin/bash
set -e

export PATH="/home/ghitatruongle/flutter/bin:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="1.0.1-beta"
STAGE_DIR="/tmp/ga_song_linux_build"

echo "=== G.A - Song Linux Release Builder v${VERSION} ==="
echo "Source: ${SCRIPT_DIR}"
echo "Staging build in: ${STAGE_DIR}"

# Stage to native Linux ext4 filesystem to support symlinks
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}"
rsync -a \
  --filter='- /.git/' \
  --filter='- /.dart_tool/' \
  --filter='- /build/' \
  --filter='- /release_artifacts/' \
  --filter='- /android/' \
  --filter='- /ios/' \
  --filter='- /macos/' \
  --filter='- /windows/' \
  --filter='- /web/' \
  --filter='- /test_project/' \
  "${SCRIPT_DIR}/" "${STAGE_DIR}/"

cd "${STAGE_DIR}"

echo "=== Flutter Version ==="
flutter --version | head -n 3

echo "=== Dependencies ==="
flutter pub get

echo "=== Building Linux Release ==="
flutter build linux --release

echo "=== Packaging Linux Release ==="
BUNDLE_DIR="${STAGE_DIR}/build/linux/x64/release/bundle"
OUT_DIR="${SCRIPT_DIR}/build/linux/installer"
mkdir -p "${OUT_DIR}"
mkdir -p "${SCRIPT_DIR}/build/linux/x64/release"
rm -rf "${SCRIPT_DIR}/build/linux/x64/release/bundle"
cp -r "${BUNDLE_DIR}" "${SCRIPT_DIR}/build/linux/x64/release/"

# Create compressed tar.gz installer archive
TAR_NAME="GA_Song_v${VERSION}_Linux_x64.tar.gz"
cd "${STAGE_DIR}/build/linux/x64/release"
tar -czf "${OUT_DIR}/${TAR_NAME}" bundle

echo "=== Copying to Windows Desktop ==="
if [ -d "/mnt/c/Users/Acer/Desktop" ]; then
    cp -f "${OUT_DIR}/${TAR_NAME}" "/mnt/c/Users/Acer/Desktop/${TAR_NAME}"
    echo "✓ Copied ${TAR_NAME} to Desktop"
fi

echo "=== Build & Packaging Complete! ==="
echo "Installer Archive: ${OUT_DIR}/${TAR_NAME}"

