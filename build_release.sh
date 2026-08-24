#!/bin/bash
# G.A - Song Release Build Script
# Usage: ./build_release.sh [version]
# Example: ./build_release.sh 1.0.0

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse version argument
VERSION=${1:-"1.0.0"}
VERSION_TAG="v${VERSION}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         G.A - Song Release Builder v${VERSION}                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

command -v flutter >/dev/null 2>&1 || { echo -e "${RED}Flutter not found in PATH${NC}" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo -e "${RED}Git not found in PATH${NC}" >&2; exit 1; }

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✓${NC} Flutter: ${FLUTTER_VERSION}"

if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo -e "${GREEN}✓${NC} Java: ${JAVA_VERSION}"
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Run from project root.${NC}"
    exit 1
fi

# Verify current version matches
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ')
if [ "${CURRENT_VERSION}" != "${VERSION}" ]; then
    echo -e "${YELLOW}Warning: pubspec.yaml version (${CURRENT_VERSION}) != requested version (${VERSION})${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create release tag
TAG="v${VERSION}"
echo -e "${BLUE}Creating release tag: ${TAG}${NC}"

# Check if tag already exists
if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo -e "${YELLOW}Tag ${TAG} already exists.${NC}"
    read -p "Overwrite tag? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    git tag -d "${TAG}"
    git push origin :refs/tags/"${TAG}" 2>/dev/null || true
fi

# Create and push tag
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin "v${VERSION}"

echo -e "${GREEN}✓${NC} Tag ${TAG} created and pushed"

# Run tests
echo -e "${BLUE}Running tests...${NC}"
flutter test --coverage

# Check formatting
echo -e "${BLUE}Checking code formatting...${NC}"
dart format --set-exit-if-changed --output=none .

# Static analysis
echo -e "${BLUE}Running static analysis...${NC}"
flutter analyze --fatal-infos

# Build all platforms
echo -e "${BLUE}Building all platforms...${NC}"

# Build Windows
echo -e "${BLUE}Building Windows...${NC}"
flutter build windows --release --target-platform=windows-x64

# Build Android
# NOTE: product_flavors (playstore/github/fdroid) exist only in
# android_build_config.yaml (documentation) — android/app/build.gradle.kts
# does NOT declare them, so `--flavor` would fail the build. Build the
# default (no-flavor) release instead.
echo -e "${BLUE}Building Android...${NC}"
flutter build appbundle --release
flutter build apk --release --split-per-abi

# Build Linux
echo -e "${BLUE}Building Linux...${NC}"
flutter build linux --release

# Create release artifacts directory
RELEASE_DIR="release_artifacts/v${VERSION}"
mkdir -p "${RELEASE_DIR}"

# Copy Windows artifacts
if [ -d "build/windows/x64/runner/Release" ]; then
    cp -r "build/windows/x64/runner/Release" "${RELEASE_DIR}/GA_Song_v${VERSION}_Windows_Portable"
    cd "${RELEASE_DIR}"
    zip -r "GA_Song_v${VERSION}_Windows_Portable.zip" "GA_Song_v${VERSION}_Windows_Portable"
    rm -rf "GA_Song_v${VERSION}_Windows_Portable"
    cd - > /dev/null
fi

# Copy Android artifacts
if [ -d "build/app/outputs/bundle/playstoreRelease" ]; then
    cp "build/app/outputs/bundle/playstoreRelease/app-playstore-release.aab" "${RELEASE_DIR}/GA_Song_v${VERSION}_Android_AAB.aab"
fi

if [ -d "build/app/outputs/apk/release" ]; then
    cp build/app/outputs/apk/release/*.apk "${RELEASE_DIR}/" 2>/dev/null || true
fi

# Linux artifacts
if [ -d "build/linux/x64/release/bundle" ]; then
    cd "build/linux/x64/release"
    tar -czf "../../../${RELEASE_DIR}/GA_Song_v${VERSION}_Linux_x64.tar.gz" bundle
    cd - > /dev/null
    
    # Create AppImage if appimagetool available
    if command -v appimagetool &> /dev/null; then
        cd "build/linux/x64/release/bundle"
        # Create AppImage (requires appimagetool)
        wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool 2>/dev/null
        chmod +x appimagetool
        # ... AppImage creation would go here
        cd - > /dev/null
    fi
fi

# Generate checksums
echo -e "${BLUE}Generating checksums...${NC}"
cd "${RELEASE_DIR}"
sha256sum * > SHA256SUMS.txt
cd - > /dev/null

# Summary
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    BUILD COMPLETE                                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}Release artifacts in: ${RELEASE_DIR}${NC}"
ls -la "${RELEASE_DIR}"
echo
cat "${RELEASE_DIR}/SHA256SUMS.txt"
echo
echo -e "${GREEN}✓ Release v${VERSION} built successfully!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Create GitHub release with tag v${VERSION}"
echo "  2. Upload artifacts to GitHub Release"
echo "  3. Upload AAB to Play Console"
echo "  4. Publish MSIX to Microsoft Store"
echo "  5. Publish Linux artifacts to GitHub Releases"