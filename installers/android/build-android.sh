#!/bin/bash
# NexusVPN Android Build Script
# Requires: Go 1.22+, Android SDK, gomobile

set -e

BRAND="${BRAND:-nebula}"
OUTPUT_DIR="${OUTPUT_DIR:-../dist/android}"
BUILD_TYPE="${BUILD_TYPE:-release}"

echo "========================================"
echo "NexusVPN Android Build Script"
echo "Brand: $BRAND"
echo "Build Type: $BUILD_TYPE"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v go &> /dev/null; then
    echo -e "${RED}Go is not installed${NC}"
    exit 1
fi

if ! command -v gomobile &> /dev/null; then
    echo -e "${YELLOW}Installing gomobile...${NC}"
    go install golang.org/x/mobile/cmd/gomobile@latest
    gomobile init
fi

if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
    echo -e "${RED}ANDROID_SDK_ROOT or ANDROID_HOME not set${NC}"
    exit 1
fi

echo -e "${GREEN}  All prerequisites met${NC}"

# Create output directory
mkdir -p "$OUTPUT_DIR"
BUILD_DIR="$OUTPUT_DIR/$BRAND"
mkdir -p "$BUILD_DIR"

# Build Go Core as AAR
echo -e "${YELLOW}[1/3] Building Go Core (AAR)...${NC}"
cd ../core

export CGO_ENABLED=1
export ANDROID_SDK=$(echo ${ANDROID_SDK_ROOT:-$ANDROID_HOME})

gomobile bind -target=android/arm64,android/arm \
    -o "$BUILD_DIR/core.aar" \
    -ldflags="-s -w" \
    ./mobileapi

echo -e "${GREEN}  Core AAR built: $BUILD_DIR/core.aar${NC}"

# Copy AAR to Android project
echo -e "${YELLOW}[2/3] Preparing Android project...${NC}"
mkdir -p ../apps/android/app/libs
cp "$BUILD_DIR/core.aar" ../apps/android/app/libs/

cd ../apps/android

# Build APK
echo -e "${YELLOW}[3/3] Building Android APK...${NC}"

if [ "$BUILD_TYPE" = "release" ]; then
    # Release build (requires signing)
    ./gradlew assemble${BRAND^}Release
    APK_PATH="app/build/outputs/apk/${BRAND}/release/app-${BRAND}-release-unsigned.apk"
    
    if [ -f "$APK_PATH" ]; then
        cp "$APK_PATH" "$BUILD_DIR/${BRAND}-unsigned.apk"
        echo -e "${YELLOW}  Note: APK is unsigned. Sign with:${NC}"
        echo -e "    apksigner sign --ks mykey.jks $BUILD_DIR/${BRAND}-unsigned.apk"
    fi
else
    # Debug build
    ./gradlew assemble${BRAND^}Debug
    APK_PATH="app/build/outputs/apk/${BRAND}/debug/app-${BRAND}-debug.apk"
    
    if [ -f "$APK_PATH" ]; then
        cp "$APK_PATH" "$BUILD_DIR/${BRAND}-debug.apk"
        echo -e "${GREEN}  APK built: $BUILD_DIR/${BRAND}-debug.apk${NC}"
    fi
fi

echo ""
echo "========================================"
echo -e "${GREEN}Build complete!${NC}"
echo "Output: $BUILD_DIR"
echo "========================================"
