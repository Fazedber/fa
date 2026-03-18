#!/usr/bin/env bash
# Build macOS DMG Installer with beautiful UI
# Requires: macOS, Xcode, create-dmg

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BRAND="${BRAND:-Nebula}"
VERSION="${VERSION:-1.0.0}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist/macos}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NexusVPN macOS Installer Builder${NC}"
echo -e "${BLUE}Brand: $BRAND | Version: $VERSION${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Checking prerequisites...${NC}"

if [ ! -f "/System/Library/CoreServices/SystemVersion.plist" ]; then
    echo -e "${RED}Error: This script must run on macOS${NC}"
    exit 1
fi

if ! command -v create-dmg >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing create-dmg...${NC}"
    brew install create-dmg
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing xcodegen...${NC}"
    brew install xcodegen
fi

echo -e "${GREEN}  All prerequisites met${NC}"

echo -e "${YELLOW}[1/4] Building macOS app...${NC}"
if [ "${SKIP_APP_BUILD:-0}" != "1" ]; then
    bash "$SCRIPT_DIR/build-macos.sh"
fi

echo -e "${YELLOW}[2/4] Signing app...${NC}"
APP_PATH="$OUTPUT_DIR/$BRAND/NexusVPN.app"

if [ -n "${DEVELOPER_ID:-}" ]; then
    echo "  Signing with Developer ID: $DEVELOPER_ID"
    codesign --force --deep --sign "Developer ID Application: $DEVELOPER_ID" "$APP_PATH"
    codesign --verify --verbose "$APP_PATH"
else
    echo -e "${YELLOW}  Skipping code signing (set DEVELOPER_ID)${NC}"
fi

echo -e "${YELLOW}[3/4] Preparing DMG resources...${NC}"
ASSETS_DIR="$REPO_ROOT/assets"
mkdir -p "$ASSETS_DIR"

echo -e "${YELLOW}[4/4] Creating DMG installer...${NC}"

DMG_NAME="${BRAND}VPN-${VERSION}-macOS.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
APP_ICON="$APP_PATH/Contents/Resources/AppIcon.icns"
STAGING_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$STAGING_DIR/"

rm -f "$DMG_PATH"

CREATE_DMG_ARGS=(
    --volname "${BRAND} VPN Installer"
    --window-pos 200 120
    --window-size 800 400
    --icon-size 100
    --icon "NexusVPN.app" 200 190
    --hide-extension "NexusVPN.app"
    --app-drop-link 600 185
    --no-internet-enable
)

if [ -f "$APP_ICON" ]; then
    CREATE_DMG_ARGS+=(--volicon "$APP_ICON")
fi

create-dmg "${CREATE_DMG_ARGS[@]}" "$DMG_PATH" "$STAGING_DIR" 2>/dev/null || {
    echo -e "${YELLOW}  Using fallback DMG creation...${NC}"
    hdiutil create -srcfolder "$STAGING_DIR" -volname "${BRAND} VPN" -fs HFS+ -format UDZO "$DMG_PATH"
}

rm -rf "$STAGING_DIR"

if [ -n "${APPLE_ID:-}" ] && [ -n "${APP_SPECIFIC_PASSWORD:-}" ] && [ -n "${TEAM_ID:-}" ]; then
    echo -e "${YELLOW}Notarizing DMG...${NC}"
    xcrun notarytool submit "$DMG_PATH" --apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD" --team-id "$TEAM_ID" --wait
    xcrun stapler staple "$DMG_PATH"
fi

FILE_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SUCCESS! Installer created:${NC}"
echo -e "${BLUE}$DMG_PATH${NC}"
echo -e "${GREEN}Size: $FILE_SIZE${NC}"
echo -e "${GREEN}========================================${NC}"
