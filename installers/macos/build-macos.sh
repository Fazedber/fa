#!/bin/bash
# NexusVPN macOS Build Script
# Requires: Go 1.22+, Xcode 15+

set -e

BRAND="${BRAND:-Nebula}"
OUTPUT_DIR="${OUTPUT_DIR:-../dist/macos}"
CONFIGURATION="${CONFIGURATION:-Release}"

echo "========================================"
echo "NexusVPN macOS Build Script"
echo "Brand: $BRAND"
echo "Configuration: $CONFIGURATION"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v go &> /dev/null; then
    echo -e "${RED}Go is not installed${NC}"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Xcode is not installed${NC}"
    exit 1
fi

if ! command -v gomobile &> /dev/null; then
    echo -e "${YELLOW}Installing gomobile...${NC}"
    go install golang.org/x/mobile/cmd/gomobile@latest
    gomobile init
fi

echo -e "${GREEN}  All prerequisites met${NC}"

# Create output directory
mkdir -p "$OUTPUT_DIR"
BUILD_DIR="$OUTPUT_DIR/$BRAND"
mkdir -p "$BUILD_DIR"

# Build Go Core as XCFramework
echo -e "${YELLOW}[1/3] Building Go Core (XCFramework)...${NC}"
cd ../core

gomobile bind -target=macos/arm64,macos/amd64 \
    -o "$BUILD_DIR/Core.xcframework" \
    -ldflags="-s -w" \
    ./api

echo -e "${GREEN}  Core XCFramework built${NC}"

# Copy to Xcode project
echo -e "${YELLOW}[2/3] Preparing Xcode project...${NC}"
rm -rf ../apps/macos/NexusVPN/Core.xcframework 2>/dev/null || true
cp -R "$BUILD_DIR/Core.xcframework" ../apps/macos/NexusVPN/

cd ../apps/macos

# Build App
echo -e "${YELLOW}[3/3] Building macOS App...${NC}"

xcodebuild -project NexusVPN.xcodeproj \
    -scheme NexusVPN \
    -configuration $CONFIGURATION \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    build

# Find built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "NexusVPN.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Failed to find built app${NC}"
    exit 1
fi

# Copy to output
cp -R "$APP_PATH" "$BUILD_DIR/"

# Create DMG if release build
if [ "$CONFIGURATION" = "Release" ]; then
    echo -e "${YELLOW}Creating DMG installer...${NC}"
    
    DMG_NAME="${BRAND}-macOS.dmg"
    TEMP_DMG="$BUILD_DIR/temp.dmg"
    
    # Create temporary DMG
    hdiutil create -srcfolder "$BUILD_DIR/NexusVPN.app" \
        -volname "$BRAND VPN" \
        -fs HFS+ \
        -format UDRW \
        "$TEMP_DMG"
    
    # Convert to compressed DMG
    hdiutil convert "$TEMP_DMG" -format UDZO -o "$BUILD_DIR/$DMG_NAME"
    rm "$TEMP_DMG"
    
    echo -e "${GREEN}  DMG created: $BUILD_DIR/$DMG_NAME${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}Build complete!${NC}"
echo "Output: $BUILD_DIR"
echo "App: $BUILD_DIR/NexusVPN.app"
echo "========================================"
