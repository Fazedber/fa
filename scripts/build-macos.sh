#!/usr/bin/env bash
# NexusVPN macOS Build Script
# Requires: Go 1.22+, Xcode 15+

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BRAND="${BRAND:-Nebula}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist/macos}"
CONFIGURATION="${CONFIGURATION:-Release}"
GOMOBILE_VERSION="${GOMOBILE_VERSION:-v0.0.0-20231127183840-76ac6878022f}"

echo "========================================"
echo "NexusVPN macOS Build Script"
echo "Brand: $BRAND"
echo "Configuration: $CONFIGURATION"
echo "========================================"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$REPO_ROOT/apps/macos"
PROJECT_FILE="$PROJECT_DIR/NexusVPN.xcodeproj/project.pbxproj"
BUILD_DIR="$OUTPUT_DIR/$BRAND"

echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v go >/dev/null 2>&1; then
    echo -e "${RED}Go is not installed${NC}"
    exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo -e "${RED}Xcode is not installed${NC}"
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}Missing Xcode project: $PROJECT_FILE${NC}"
    exit 1
fi

if ! command -v gomobile >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing gomobile...${NC}"
    go install golang.org/x/mobile/cmd/gomobile@"${GOMOBILE_VERSION}"
    gomobile init
fi

echo -e "${GREEN}  All prerequisites met${NC}"

mkdir -p "$BUILD_DIR"

echo -e "${YELLOW}[1/3] Building Go Core (XCFramework)...${NC}"
cd "$REPO_ROOT/core"
go mod download

gomobile bind -target=macos/arm64,macos/amd64 \
    -o "$BUILD_DIR/Api.xcframework" \
    -ldflags="-s -w" \
    ./api

echo -e "${GREEN}  Core XCFramework built${NC}"

echo -e "${YELLOW}[2/3] Preparing Xcode project...${NC}"
rm -rf "$PROJECT_DIR/NexusVPN/Api.xcframework" 2>/dev/null || true
cp -R "$BUILD_DIR/Api.xcframework" "$PROJECT_DIR/NexusVPN/"

cd "$PROJECT_DIR"

echo -e "${YELLOW}[3/3] Building macOS App...${NC}"

xcodebuild -project NexusVPN.xcodeproj \
    -scheme NexusVPN \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "NexusVPN.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Failed to find built app${NC}"
    exit 1
fi

cp -R "$APP_PATH" "$BUILD_DIR/"

echo ""
echo "========================================"
echo -e "${GREEN}Build complete!${NC}"
echo "Output: $BUILD_DIR"
echo "App: $BUILD_DIR/NexusVPN.app"
echo "========================================"
