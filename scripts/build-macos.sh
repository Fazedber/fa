#!/usr/bin/env bash
# NexusVPN macOS Build Script
# Requires: Go 1.22+, Xcode 15+

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BRAND="${BRAND:-Nebula}"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-1}}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist/macos}"
CONFIGURATION="${CONFIGURATION:-Release}"
GOMOBILE_VERSION="${GOMOBILE_VERSION:-v0.0.0-20240716161057-1ad2df20a8b6}"
BUILD_PHASE="${BUILD_PHASE:-all}"

echo "========================================"
echo "NexusVPN macOS Build Script"
echo "Brand: $BRAND"
echo "Version: $VERSION ($BUILD_NUMBER)"
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
ACTIVE_PROJECT_SPEC="$PROJECT_SPEC"

select_project_spec() {
    ACTIVE_PROJECT_SPEC="$PROJECT_SPEC"
}

escape_workflow_message() {
    local value
    value="$1"
    value="${value//'%'/'%25'}"
    value="${value//$'\r'/'%0D'}"
    value="${value//$'\n'/'%0A'}"
    printf '%s' "$value"
}

emit_failure_annotation() {
    local title
    local log_file
    local excerpt
    local error_lines
    local note_lines

    title="$1"
    log_file="$2"

    if [ -f "$log_file" ]; then
        error_lines="$(grep -E '(^|[^[:alpha:]])error:' "$log_file" | tail -n 12 || true)"
        note_lines="$(grep -E '(^|[^[:alpha:]])note:' "$log_file" | tail -n 8 || true)"

        if [ -n "$error_lines" ]; then
            excerpt="$error_lines"
            if [ -n "$note_lines" ]; then
                excerpt="$excerpt"$'\n'"$note_lines"
            fi
        else
            excerpt="$(tail -n 20 "$log_file")"
        fi
    else
        excerpt="No log output was captured."
    fi

    echo "::error title=$(escape_workflow_message "$title")::$(escape_workflow_message "$excerpt")"
}

run_with_log() {
    local title
    local log_file

    title="$1"
    log_file="$2"
    shift 2

    mkdir -p "$(dirname "$log_file")"

    set +e
    "$@" 2>&1 | tee "$log_file"
    local status=${PIPESTATUS[0]}
    set -e

    if [ "$status" -ne 0 ]; then
        emit_failure_annotation "$title" "$log_file"
        return "$status"
    fi
}

downgrade_project_format_for_xcode15() {
    local pbxproj_path

    pbxproj_path="$PROJECT_DIR/NexusVPN.xcodeproj/project.pbxproj"
    if [ ! -f "$pbxproj_path" ]; then
        return
    fi

    python3 - "$pbxproj_path" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
updated = text.replace("objectVersion = 77;", "objectVersion = 60;")
updated = updated.replace("preferredProjectObjectVersion = 77;", "preferredProjectObjectVersion = 60;")
if updated != text:
    path.write_text(updated, encoding="utf-8")
PY
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

    if [ ! -f "$ACTIVE_PROJECT_SPEC" ]; then
        echo -e "${RED}Missing XcodeGen spec: $ACTIVE_PROJECT_SPEC${NC}"
        exit 1
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
        run_with_log \
            "XcodeGen failed for $BRAND" \
            "$BUILD_DIR/xcodegen.log" \
            xcodegen generate --spec "$ACTIVE_PROJECT_SPEC"
    )
    downgrade_project_format_for_xcode15

    if [ ! -d "$PROJECT_DIR/NexusVPN.xcodeproj" ]; then
        echo -e "${RED}Failed to generate Xcode project at $PROJECT_DIR/NexusVPN.xcodeproj${NC}"
        exit 1
    fi
}

build_app_with_xcodebuild() {
    echo -e "${YELLOW}[3/3] Building macOS App...${NC}"

    cd "$PROJECT_DIR"

    run_with_log \
        "xcodebuild -list failed for $BRAND" \
        "$BUILD_DIR/xcodebuild-list.log" \
        xcodebuild -list -project NexusVPN.xcodeproj

    run_with_log \
        "xcodebuild build failed for $BRAND" \
        "$BUILD_DIR/xcodebuild.log" \
        xcodebuild -project NexusVPN.xcodeproj \
        -scheme NexusVPN \
        -configuration "$CONFIGURATION" \
        -destination "platform=macOS" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        MARKETING_VERSION="$VERSION" \
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
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

apply_app_icon() {
    local app_dir
    local iconset_dir
    local generated_icns

    app_dir="$BUILD_DIR/NexusVPN.app"
    iconset_dir="$PROJECT_DIR/NexusVPN/AppIcon.iconset"
    generated_icns="$BUILD_DIR/AppIcon.icns"

    if [ ! -d "$iconset_dir" ] || [ ! -d "$app_dir" ]; then
        return
    fi

    mkdir -p "$app_dir/Contents/Resources"
    iconutil -c icns "$iconset_dir" -o "$generated_icns"
    cp "$generated_icns" "$app_dir/Contents/Resources/AppIcon.icns"
}

verify_app_bundle() {
    local app_dir
    local executable_path
    local extension_path
    local bundle_size_kb

    app_dir="$BUILD_DIR/NexusVPN.app"
    executable_path="$app_dir/Contents/MacOS/NexusVPN"
    extension_path="$app_dir/Contents/PlugIns/NexusVPNExtension.appex"

    if [ ! -d "$app_dir" ]; then
        echo -e "${RED}Missing app bundle: $app_dir${NC}"
        exit 1
    fi

    if [ ! -x "$executable_path" ]; then
        echo -e "${RED}Missing app executable: $executable_path${NC}"
        exit 1
    fi

    if [ ! -d "$extension_path" ]; then
        echo -e "${RED}Missing packet tunnel extension: $extension_path${NC}"
        exit 1
    fi

    if [ ! -f "$app_dir/Contents/Resources/AppIcon.icns" ]; then
        echo -e "${RED}Missing app icon inside bundle${NC}"
        exit 1
    fi

    bundle_size_kb="$(du -sk "$app_dir" | cut -f1)"
    if [ "${bundle_size_kb:-0}" -lt 512 ]; then
        echo -e "${RED}App bundle is unexpectedly small (${bundle_size_kb} KB)${NC}"
        exit 1
    fi
}

build_app() {
    prepare_xcode_project
    build_app_with_xcodebuild
    apply_app_icon
    verify_app_bundle
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
