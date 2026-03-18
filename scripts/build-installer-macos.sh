#!/bin/bash
# Build macOS DMG Installer with beautiful UI
# Requires: macOS, Xcode, create-dmg (brew install create-dmg)

set -e

BRAND="${BRAND:-Nebula}"
VERSION="${VERSION:-1.0.0}"
OUTPUT_DIR="${OUTPUT_DIR:-../dist/macos}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NexusVPN macOS Installer Builder${NC}"
echo -e "${BLUE}Brand: $BRAND | Version: $VERSION${NC}"
echo -e "${BLUE}========================================${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if [ ! -f "/System/Library/CoreServices/SystemVersion.plist" ]; then
    echo -e "${RED}Error: This script must run on macOS${NC}"
    exit 1
fi

if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Installing create-dmg...${NC}"
    brew install create-dmg || {
        echo -e "${RED}Failed to install create-dmg. Install manually: brew install create-dmg${NC}"
        exit 1
    }
fi

echo -e "${GREEN}  All prerequisites met${NC}"

# Step 1: Build app
echo -e "${YELLOW}[1/4] Building macOS app...${NC}"
cd "$(dirname "$0")"
./build-macos.sh "$BRAND"

# Step 2: Sign app (optional, requires Developer ID)
echo -e "${YELLOW}[2/4] Signing app...${NC}"
APP_PATH="../dist/macos/$BRAND/NexusVPN.app"

if [ -n "$DEVELOPER_ID" ]; then
    echo "  Signing with Developer ID: $DEVELOPER_ID"
    codesign --force --deep --sign "Developer ID Application: $DEVELOPER_ID" "$APP_PATH"
    codesign --verify --verbose "$APP_PATH"
else
    echo -e "${YELLOW}  Skipping code signing (set DEVELOPER_ID environment variable)${NC}"
    echo "  Users will see 'unidentified developer' warning"
fi

# Step 3: Create DMG background
echo -e "${YELLOW}[3/4] Preparing DMG resources...${NC}"
ASSETS_DIR="../assets"
mkdir -p "$ASSETS_DIR"

# Create background image for DMG
DMG_BACKGROUND="$ASSETS_DIR/dmg-background.png"
if [ ! -f "$DMG_BACKGROUND" ]; then
    echo "  Creating DMG background..."
    # Create a simple background using sips and built-in tools
    # Or use a placeholder
    touch "$DMG_BACKGROUND"
fi

# Step 4: Create DMG
echo -e "${YELLOW}[4/4] Creating DMG installer...${NC}"

DMG_NAME="${BRAND}VPN-${VERSION}-macOS.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
TEMP_DMG="$OUTPUT_DIR/temp-${BRAND}.dmg"

# Remove old DMG
rm -f "$DMG_PATH"

# Create DMG using create-dmg
create-dmg \
    --volname "${BRAND} VPN Installer" \
    --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" 2>/dev/null || echo "" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "NexusVPN.app" 200 190 \
    --hide-extension "NexusVPN.app" \
    --app-drop-link 600 185 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH" 2>/dev/null || {
    
    # Fallback to hdiutil if create-dmg fails
    echo -e "${YELLOW}  Using fallback DMG creation...${NC}"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$TEMP_DIR/"
    
    # Create DMG
    hdiutil create -srcfolder "$TEMP_DIR" -volname "${BRAND} VPN" -fs HFS+ -format UDZO "$DMG_PATH"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Notarize (optional, requires Apple ID)
if [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ]; then
    echo -e "${YELLOW}Notarizing DMG...${NC}"
    xcrun notarytool submit "$DMG_PATH" --apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD" --team-id "$TEAM_ID" --wait
    xcrun stapler staple "$DMG_PATH"
fi

# File size
FILE_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SUCCESS! Installer created:${NC}"
echo -e "${BLUE}$DMG_PATH${NC}"
echo -e "${GREEN}Size: $FILE_SIZE${NC}"
echo -e "${GREEN}========================================${NC}"

echo ""
echo -e "${YELLOW}Installation instructions:${NC}"
echo "  1. Open $DMG_NAME"
echo "  2. Drag 'NexusVPN.app' to 'Applications' folder"
echo "  3. Launch from Applications"
echo "  4. Approve System Extension in Settings → Privacy & Security"
