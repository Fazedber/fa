#!/usr/bin/env bash
# NexusVPN Android Build Script
# Requires: Go 1.22+, Android SDK, gomobile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BRAND="${BRAND:-nebula}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist/android}"
BUILD_TYPE="${BUILD_TYPE:-debug}"
GOMOBILE_VERSION="${GOMOBILE_VERSION:-v0.0.0-20231127183840-76ac6878022f}"

echo "========================================"
echo "NexusVPN Android Build Script"
echo "Brand: $BRAND"
echo "Build Type: $BUILD_TYPE"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CORE_DIR="$REPO_ROOT/core"
ANDROID_PROJECT_DIR="$REPO_ROOT/apps/android"
ANDROID_APP_LIBS_DIR="$ANDROID_PROJECT_DIR/app/libs"
BUILD_DIR="$OUTPUT_DIR/$BRAND"

echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v go >/dev/null 2>&1; then
    echo -e "${RED}Go is not installed${NC}"
    exit 1
fi

if ! command -v gomobile >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing gomobile...${NC}"
    go install golang.org/x/mobile/cmd/gomobile@"${GOMOBILE_VERSION}"
    gomobile init
fi

if [ -z "${ANDROID_SDK_ROOT:-}" ] && [ -z "${ANDROID_HOME:-}" ]; then
    echo -e "${RED}ANDROID_SDK_ROOT or ANDROID_HOME not set${NC}"
    exit 1
fi

if [ -x "$ANDROID_PROJECT_DIR/gradlew" ]; then
    GRADLE_BIN="$ANDROID_PROJECT_DIR/gradlew"
elif command -v gradle >/dev/null 2>&1; then
    GRADLE_BIN="gradle"
else
    echo -e "${RED}Neither ./gradlew nor gradle is available${NC}"
    exit 1
fi

echo -e "${GREEN}  All prerequisites met${NC}"

mkdir -p "$BUILD_DIR"

echo -e "${YELLOW}[1/3] Building Go Core (AAR)...${NC}"
cd "$CORE_DIR"
go mod download

export CGO_ENABLED=1
export ANDROID_SDK="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"

gomobile bind -javapkg=api -target=android/arm64,android/arm \
    -o "$BUILD_DIR/core.aar" \
    -ldflags="-s -w" \
    ./api

echo -e "${GREEN}  Core AAR built: $BUILD_DIR/core.aar${NC}"

echo -e "${YELLOW}[2/3] Preparing Android project...${NC}"
mkdir -p "$ANDROID_APP_LIBS_DIR"
cp "$BUILD_DIR/core.aar" "$ANDROID_APP_LIBS_DIR/core.aar"

cd "$ANDROID_PROJECT_DIR"

echo -e "${YELLOW}[3/3] Building Android APK...${NC}"

if [ "$BUILD_TYPE" = "release" ]; then
    "$GRADLE_BIN" assemble${BRAND^}Release
    APK_PATH="app/build/outputs/apk/${BRAND}/release/app-${BRAND}-release-unsigned.apk"

    if [ -f "$APK_PATH" ]; then
        cp "$APK_PATH" "$BUILD_DIR/${BRAND}-unsigned.apk"
        echo -e "${YELLOW}  Note: APK is unsigned. Sign it before distribution.${NC}"
    fi
else
    "$GRADLE_BIN" assemble${BRAND^}Debug
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
