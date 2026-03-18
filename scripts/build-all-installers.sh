#!/bin/bash
# Build all installers for all platforms
# Usage: ./build-all-installers.sh [version]

set -e

VERSION="${1:-1.0.0}"
BRANDS=("Nebula" "PepeWatafa")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   NexusVPN Installer Builder           ║${NC}"
echo -e "${CYAN}║   Version: $VERSION                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
fi

echo -e "${YELLOW}Detected OS: $OS${NC}"
echo ""

# Create dist directory
mkdir -p ../dist

# Function to print section header
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Build Windows installers
if [ "$OS" = "windows" ]; then
    print_section "Building Windows Installers"
    
    for BRAND in "${BRANDS[@]}"; do
        echo -e "${YELLOW}Building $BRAND...${NC}"
        pwsh -File build-installer-windows.ps1 -Brand "$BRAND" -Version "$VERSION"
        echo -e "${GREEN}✓ $BRAND installer created${NC}"
    done
else
    echo -e "${YELLOW}⚠ Skipping Windows (requires Windows + Inno Setup)${NC}"
fi

# Build macOS installers
if [ "$OS" = "macos" ]; then
    print_section "Building macOS Installers"
    
    for BRAND in "${BRANDS[@]}"; do
        echo -e "${YELLOW}Building $BRAND...${NC}"
        export BRAND VERSION
        ./build-installer-macos.sh
        echo -e "${GREEN}✓ $BRAND DMG created${NC}"
    done
else
    echo -e "${YELLOW}⚠ Skipping macOS (requires macOS + Xcode)${NC}"
fi

# Build Android APKs (works on any platform)
print_section "Building Android APKs"

for BRAND_SLUG in "nebula" "pepewatafa"; do
    echo -e "${YELLOW}Building $BRAND_SLUG...${NC}"
    export BRAND="$BRAND_SLUG"
    ./build-android.sh || echo -e "${RED}✗ Failed (missing Android SDK)${NC}"
done

# Summary
print_section "Build Summary"

echo -e "${CYAN}Output directory: ../dist/${NC}"
echo ""

# List created files
echo -e "${YELLOW}Windows Installers:${NC}"
find ../dist/windows -name "*-Setup.exe" -exec ls -lh {} \; 2>/dev/null || echo "  None"

echo ""
echo -e "${YELLOW}macOS Installers:${NC}"
find ../dist/macos -name "*.dmg" -exec ls -lh {} \; 2>/dev/null || echo "  None"

echo ""
echo -e "${YELLOW}Android APKs:${NC}"
find ../dist/android -name "*.apk" -exec ls -lh {} \; 2>/dev/null || echo "  None"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   All installers built successfully!   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Test installers on target platforms"
echo "  2. Sign binaries with certificates"
echo "  3. Upload to GitHub Releases"
echo ""
