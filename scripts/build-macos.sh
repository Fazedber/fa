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
CI_PROJECT_SPEC="$PROJECT_DIR/project.ci.yml"
PROJECT_FILE="$PROJECT_DIR/NexusVPN.xcodeproj/project.pbxproj"
BUILD_DIR="$OUTPUT_DIR/$BRAND"
ACTIVE_PROJECT_SPEC="$PROJECT_SPEC"
USE_DIRECT_APP_BUNDLE=0

select_project_spec() {
    if [ "${MACOS_SIGNED_BUILD:-0}" = "1" ] || [ -n "${DEVELOPER_ID:-}" ]; then
        ACTIVE_PROJECT_SPEC="$PROJECT_SPEC"
        USE_DIRECT_APP_BUNDLE=0
    elif [ -f "$CI_PROJECT_SPEC" ]; then
        ACTIVE_PROJECT_SPEC="$CI_PROJECT_SPEC"
        USE_DIRECT_APP_BUNDLE=1
    else
        ACTIVE_PROJECT_SPEC="$PROJECT_SPEC"
        USE_DIRECT_APP_BUNDLE=0
    fi
}

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

    if ! command -v gomobile >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing gomobile...${NC}"
        go install golang.org/x/mobile/cmd/gomobile@"${GOMOBILE_VERSION}"
    fi

    if [ "$USE_DIRECT_APP_BUNDLE" = "0" ]; then
        if [ ! -f "$ACTIVE_PROJECT_SPEC" ]; then
            echo -e "${RED}Missing XcodeGen spec: $ACTIVE_PROJECT_SPEC${NC}"
            exit 1
        fi

        if ! command -v xcodegen >/dev/null 2>&1; then
            echo -e "${YELLOW}Installing xcodegen...${NC}"
            brew install xcodegen
        fi
    elif ! command -v swiftc >/dev/null 2>&1; then
        echo -e "${RED}swiftc is not installed${NC}"
        exit 1
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
        xcodegen generate --spec "$ACTIVE_PROJECT_SPEC"
    )

    if [ ! -d "$PROJECT_DIR/NexusVPN.xcodeproj" ]; then
        echo -e "${RED}Failed to generate Xcode project at $PROJECT_DIR/NexusVPN.xcodeproj${NC}"
        exit 1
    fi
}

build_app_with_xcodebuild() {
    echo -e "${YELLOW}[3/3] Building macOS App...${NC}"

    cd "$PROJECT_DIR"

    xcodebuild -list -project NexusVPN.xcodeproj >/dev/null

    xcodebuild -project NexusVPN.xcodeproj \
        -scheme NexusVPN \
        -configuration "$CONFIGURATION" \
        -destination "platform=macOS" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY= \
        DEVELOPMENT_TEAM= \
        CODE_SIGN_ENTITLEMENTS= \
        build

    APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "NexusVPN.app" -type d | head -1)

    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}Failed to find built app${NC}"
        exit 1
    fi

    cp -R "$APP_PATH" "$BUILD_DIR/"
}

build_app_bundle_directly() {
    echo -e "${YELLOW}[3/3] Building macOS App bundle directly...${NC}"

    local sdk_path
    local app_dir
    local arm64_dir
    local x86_64_dir
    local sources

    sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
    app_dir="$BUILD_DIR/NexusVPN.app"
    arm64_dir="$BUILD_DIR/swiftc/arm64"
    x86_64_dir="$BUILD_DIR/swiftc/x86_64"
    sources=(
        "$PROJECT_DIR/NexusVPN/NexusVPNApp.swift"
        "$PROJECT_DIR/NexusVPN/ContentView.swift"
    )

    rm -rf "$app_dir" "$BUILD_DIR/swiftc"
    mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources" "$arm64_dir" "$x86_64_dir"

    xcrun swiftc \
        -sdk "$sdk_path" \
        -target arm64-apple-macos14.0 \
        -framework SwiftUI \
        -framework AppKit \
        -framework NetworkExtension \
        "${sources[@]}" \
        -o "$arm64_dir/NexusVPN"

    xcrun swiftc \
        -sdk "$sdk_path" \
        -target x86_64-apple-macos14.0 \
        -framework SwiftUI \
        -framework AppKit \
        -framework NetworkExtension \
        "${sources[@]}" \
        -o "$x86_64_dir/NexusVPN"

    lipo -create \
        "$arm64_dir/NexusVPN" \
        "$x86_64_dir/NexusVPN" \
        -output "$app_dir/Contents/MacOS/NexusVPN"

    cp "$PROJECT_DIR/NexusVPN/Info.plist" "$app_dir/Contents/Info.plist"
    chmod +x "$app_dir/Contents/MacOS/NexusVPN"
}

build_app() {
    if [ "$USE_DIRECT_APP_BUNDLE" = "1" ]; then
        build_app_bundle_directly
    else
        prepare_xcode_project
        build_app_with_xcodebuild
    fi
}

select_project_spec
check_prereqs
prepare_build_dir

case "$BUILD_PHASE" in
    xcframework)
        build_xcframework
        ;;
    app)
        build_app
        ;;
    all)
        build_xcframework
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
