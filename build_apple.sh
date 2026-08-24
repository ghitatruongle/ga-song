#!/bin/bash
# G.A - Song Apple (macOS & iOS) Release Build Script
# Usage: ./build_apple.sh [version] [target]
# Example: ./build_apple.sh 1.0.0 macos
# Example: ./build_apple.sh 1.0.0 ios
# Example: ./build_apple.sh 1.0.0 all

set -e

# Disable dot-underscore files on non-native file systems
export COPYFILE_DISABLE=1

# Ensure PATH includes Homebrew for cmake and build tools
export PATH="/opt/homebrew/bin:$PATH"

# Ensure Xcode 26.6 / developer directory is used
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION=${1:-"1.0.0"}
TARGET=${2:-"all"}

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      G.A - Song Apple Build System v${VERSION}                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Clean dot-underscore metadata junk files
echo -e "${YELLOW}Cleaning AppleDouble metadata files...${NC}"
find macos ios -name "._*" -delete 2>/dev/null || true

# Verify Flutter & Xcode environment
command -v flutter >/dev/null 2>&1 || { echo -e "${RED}Flutter not found in PATH${NC}" >&2; exit 1; }
xcodebuild -version >/dev/null 2>&1 || { echo -e "${RED}xcodebuild failed using DEVELOPER_DIR=${DEVELOPER_DIR}${NC}" >&2; exit 1; }

echo -e "${GREEN}✓${NC} Xcode: $(xcodebuild -version | head -n 1)"
echo -e "${GREEN}✓${NC} Flutter: $(flutter --version | head -n 1)"

RELEASE_DIR="release_artifacts/v${VERSION}"
mkdir -p "${RELEASE_DIR}"

# Check if current working directory is on non-APFS volume (e.g. ExFAT)
FS_TYPE=$(df -P . | tail -n 1 | awk '{print $1}')
IS_EXFAT=false
if mount | grep "$FS_TYPE" | grep -qi "exfat"; then
    IS_EXFAT=true
fi

BUILD_ROOT="$(pwd)"
if [ "$IS_EXFAT" = true ]; then
    echo -e "${YELLOW}Detected ExFAT filesystem at current location. Staging build in APFS temp directory (/tmp/ga_song_build) for full Xcode & codesign compatibility...${NC}"
    STAGE_DIR="/tmp/ga_song_build"
    rm -rf "$STAGE_DIR"
    mkdir -p "$STAGE_DIR"
    rsync -a --exclude='.git' --exclude='build' --exclude='.dart_tool' --exclude='release_artifacts' ./ "$STAGE_DIR/"
    cd "$STAGE_DIR"
    find macos ios -name "._*" -delete 2>/dev/null || true
    PATH="/opt/homebrew/bin:$PATH" COPYFILE_DISABLE=1 flutter pub get >/dev/null
    cd macos && DEVELOPER_DIR="${DEVELOPER_DIR}" COPYFILE_DISABLE=1 pod install >/dev/null && cd ..
    cd ios && DEVELOPER_DIR="${DEVELOPER_DIR}" COPYFILE_DISABLE=1 pod install >/dev/null && cd ..
fi

# Build macOS
# Optional (Track 3 / Phase 3.2-3.3):
#   UNIVERSAL=1  -> build universal binary (arm64 + x64, needs `flutter build macos --universal`)
#   CODE_SIGN_IDENTITY="Developer ID Application: ..." NOTARIZE=1 #   APPLE_ID=you@apple.com APPLE_PASSWORD=app-specific-password APPLE_TEAM_ID=XXXXXXXXXX
#                  -> sign with hardened runtime + notarize + staple
if [ "${TARGET}" == "all" ] || [ "${TARGET}" == "macos" ]; then
    if [ "${UNIVERSAL}" == "1" ]; then
        echo -e "${YELLOW}Building macOS Release (universal: arm64 + x64)...${NC}"
        flutter build macos --release --universal
    else
        echo -e "${BLUE}Building macOS Release...${NC}"
        flutter build macos --release
    fi

    MACOS_APP_PATH="build/macos/Build/Products/Release/ga_song.app"
    MACOS_ALT_PATH="build/macos/Build/Products/Release/GA Song.app"
    
    APP_TO_ZIP=""
    if [ -d "${MACOS_APP_PATH}" ]; then
        APP_TO_ZIP="ga_song.app"
        APP_PARENT="build/macos/Build/Products/Release"
    elif [ -d "${MACOS_ALT_PATH}" ]; then
        APP_TO_ZIP="GA Song.app"
        APP_PARENT="build/macos/Build/Products/Release"
    fi

    if [ -n "${APP_TO_ZIP}" ]; then
        # Sign with hardened runtime (only when an identity is provided).
        if [ -n "${CODE_SIGN_IDENTITY}" ]; then
            echo -e "${YELLOW}Signing ${APP_TO_ZIP} (${CODE_SIGN_IDENTITY}) with hardened runtime...${NC}"
            codesign --force --options runtime --sign "${CODE_SIGN_IDENTITY}" "${APP_PARENT}/${APP_TO_ZIP}"
        fi

        cd "${APP_PARENT}"
        zip -q -r "${BUILD_ROOT}/${RELEASE_DIR}/GA_Song_v${VERSION}_macOS.zip" "${APP_TO_ZIP}"
        cd - > /dev/null
        echo -e "${GREEN}✓${NC} Created ${RELEASE_DIR}/GA_Song_v${VERSION}_macOS.zip"

        # Notarize + staple (only when explicitly requested).
        if [ -n "${CODE_SIGN_IDENTITY}" ] && [ "${NOTARIZE}" == "1" ]; then
            if [ -z "${APPLE_ID}" ] || [ -z "${APPLE_PASSWORD}" ] || [ -z "${APPLE_TEAM_ID}" ]; then
                echo -e "${RED}NOTARIZE=1 requires APPLE_ID, APPLE_PASSWORD and APPLE_TEAM_ID${NC}"
                exit 1
            fi
            echo -e "${YELLOW}Submitting for notarization...${NC}"
            xcrun notarytool submit "${BUILD_ROOT}/${RELEASE_DIR}/GA_Song_v${VERSION}_macOS.zip"                 --apple-id "${APPLE_ID}"                 --password "${APPLE_PASSWORD}"                 --team-id "${APPLE_TEAM_ID}"                 --wait
            echo -e "${YELLOW}Stapling notarization ticket...${NC}"
            xcrun stapler staple "${APP_PARENT}/${APP_TO_ZIP}"
            # Re-zip so the stapled ticket ships inside the archive.
            cd "${APP_PARENT}"
            zip -q -r -u "${BUILD_ROOT}/${RELEASE_DIR}/GA_Song_v${VERSION}_macOS.zip" "${APP_TO_ZIP}"
            cd - > /dev/null
            echo -e "${GREEN}✓${NC} Notarized + stapled (verify with: spctl --assess --type execute)"
        fi
    fi
fi

# Build iOS
# Optional (Track 4 / Phase 4.6): IOS_TESTFLIGHT=1 -> `flutter build ipa`
# (signed archive for App Store Connect / TestFlight; requires Xcode + certs).
if [ "${TARGET}" == "all" ] || [ "${TARGET}" == "ios" ]; then
    if [ "${IOS_TESTFLIGHT}" == "1" ]; then
        echo -e "${YELLOW}Building iOS archive for TestFlight...${NC}"
        flutter build ipa || true
    else
        echo -e "${BLUE}Building iOS App & Archive (no-codesign)...${NC}"
        flutter build ios --no-codesign --release || true
    fi

    RUNNER_APP=$(find build/ios -name "Runner.app" -type d | head -n 1)

    if [ -n "${RUNNER_APP}" ] && [ -d "${RUNNER_APP}" ]; then
        mkdir -p Payload
        cp -r "${RUNNER_APP}" Payload/Runner.app
        zip -q -r "${BUILD_ROOT}/${RELEASE_DIR}/GA_Song_v${VERSION}_iOS_unsigned.ipa" Payload
        rm -rf Payload
        echo -e "${GREEN}✓${NC} Created ${RELEASE_DIR}/GA_Song_v${VERSION}_iOS_unsigned.ipa"
    else
        echo -e "${RED}iOS build output Runner.app not found.${NC}"
        exit 1
    fi
fi

if [ "$IS_EXFAT" = true ]; then
    cd "$BUILD_ROOT"
    rm -rf "$STAGE_DIR"
fi

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║             APPLE BUILD COMPLETE                             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
