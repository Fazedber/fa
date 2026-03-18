#!/usr/bin/env bash
# NexusVPN macOS Build Script
# Requires: Go 1.22+, Xcode 15+

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BRAND="${BRAND:-Nebula}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist/macos}"
CONFIGURATION="${CONFIGURATION:-Release}"
GOMOBILE_VERSION="${GOMOBILE_VERSION:-v0.0.0-20240716161057-1ad2df20a8b6}"
BUILD_PHASE="${BUILD_PHASE:-all}"

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
PROJECT_SPEC="$PROJECT_DIR/project.yml"
PROJECT_FILE="$PROJECT_DIR/NexusVPN.xcodeproj/project.pbxproj"
BUILD_DIR="$OUTPUT_DIR/$BRAND"

check_prereqs() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    if ! command -v go >/dev/null 2>&1; then
        echo -e "${RED}Go is not installed${NC}"
        exit 1
    fi

    if ! command -v xcodebuild >/dev/null 2>&1; then
        echo -e "${RED}Xcode is not installed${NC}"
        exit 1
    fi

    if [ ! -f "$PROJECT_SPEC" ]; then
        echo -e "${RED}Missing XcodeGen spec: $PROJECT_SPEC${NC}"
        exit 1
    fi

    if ! command -v gomobile >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing gomobile...${NC}"
        go install golang.org/x/mobile/cmd/gomobile@"${GOMOBILE_VERSION}"
    fi

    if ! command -v xcodegen >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing xcodegen...${NC}"
        brew install xcodegen
    fi

    echo -e "${GREEN}  All prerequisites met${NC}"
}

prepare_build_dir() {
    mkdir -p "$BUILD_DIR"
}

build_xcframework() {
    echo -e "${YELLOW}[1/3] Building Go Core (XCFramework)...${NC}"
    cd "$REPO_ROOT/core"
    go mod download

    gomobile bind -target=macos/arm64,macos/amd64 \
        -o "$BUILD_DIR/Api.xcframework" \
        -ldflags="-s -w" \
        ./mobileapi

    echo -e "${GREEN}  Core XCFramework built${NC}"
}

prepare_xcode_project() {
    if [ ! -d "$BUILD_DIR/Api.xcframework" ]; then
        echo -e "${RED}Missing XCFramework: $BUILD_DIR/Api.xcframework${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[2/3] Preparing Xcode project...${NC}"
    rm -rf "$PROJECT_DIR/NexusVPN/Api.xcframework" 2>/dev/null || true
    cp -R "$BUILD_DIR/Api.xcframework" "$PROJECT_DIR/NexusVPN/"
    (
        cd "$PROJECT_DIR"
        xcodegen generate --spec "$PROJECT_SPEC"
    )

    if [ ! -d "$PROJECT_DIR/NexusVPN.xcodeproj" ]; then
        echo -e "${RED}Failed to generate Xcode project at $PROJECT_DIR/NexusVPN.xcodeproj${NC}"
        exit 1
    fi
}

build_app() {
    echo -e "${YELLOW}[3/3] Building macOS App...${NC}"

    cd "$PROJECT_DIR"

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
}

check_prereqs
prepare_build_dir

case "$BUILD_PHASE" in
    xcframework)
        build_xcframework
        ;;
    app)
        prepare_xcode_project
        build_app
        ;;
    all)
        build_xcframework
        prepare_xcode_project
        build_app
        ;;
    *)
        echo -e "${RED}Unknown BUILD_PHASE: $BUILD_PHASE${NC}"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo -e "${GREEN}Build complete!${NC}"
echo "Output: $BUILD_DIR"
echo "App: $BUILD_DIR/NexusVPN.app"
echo "========================================"
