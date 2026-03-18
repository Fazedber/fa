#!/usr/bin/env bash
# NexusVPN Android Build Script
# Requires: Go 1.22+, Android SDK, gomobile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BRAND="${BRAND:-nebula}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/dist/android}"
BUILD_TYPE="${BUILD_TYPE:-debug}"
GOMOBILE_VERSION="${GOMOBILE_VERSION:-v0.0.0-20240716161057-1ad2df20a8b6}"
BUILD_PHASE="${BUILD_PHASE:-all}"

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

check_prereqs() {
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

    if [ "$BUILD_PHASE" != "aar" ]; then
        if [ -x "$ANDROID_PROJECT_DIR/gradlew" ]; then
            GRADLE_BIN="$ANDROID_PROJECT_DIR/gradlew"
        elif command -v gradle >/dev/null 2>&1; then
            GRADLE_BIN="gradle"
        else
            echo -e "${RED}Neither ./gradlew nor gradle is available${NC}"
            exit 1
        fi
    fi

    echo -e "${GREEN}  All prerequisites met${NC}"
}

prepare_mobile_env() {
    mkdir -p "$BUILD_DIR"

    export CGO_ENABLED=1
    export ANDROID_SDK="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"

    if [ -z "${ANDROID_NDK_HOME:-}" ] && [ -d "$ANDROID_SDK/ndk" ]; then
        ANDROID_NDK_HOME="$(find "$ANDROID_SDK/ndk" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
        export ANDROID_NDK_HOME
    fi

    if [ -z "${ANDROID_NDK_HOME:-}" ] || [ ! -d "${ANDROID_NDK_HOME}" ]; then
        echo -e "${RED}ANDROID_NDK_HOME is not set to a valid NDK directory${NC}"
        exit 1
    fi
}

build_aar() {
    echo -e "${YELLOW}[1/3] Building Go Core (AAR)...${NC}"
    cd "$CORE_DIR"
    go mod download

    gomobile bind -javapkg=api -target=android/arm64,android/arm \
        -o "$BUILD_DIR/core.aar" \
        -ldflags="-s -w" \
        ./mobileapi

    echo -e "${GREEN}  Core AAR built: $BUILD_DIR/core.aar${NC}"
}

prepare_android_project() {
    echo -e "${YELLOW}[2/3] Preparing Android project...${NC}"
    mkdir -p "$ANDROID_APP_LIBS_DIR"
    cp "$BUILD_DIR/core.aar" "$ANDROID_APP_LIBS_DIR/core.aar"
}

build_apk() {
    if [ ! -f "$ANDROID_APP_LIBS_DIR/core.aar" ]; then
        echo -e "${RED}Android library is missing: $ANDROID_APP_LIBS_DIR/core.aar${NC}"
        exit 1
    fi

    cd "$ANDROID_PROJECT_DIR"

    echo -e "${YELLOW}[3/3] Building Android APK...${NC}"

    if [ "$BUILD_TYPE" = "release" ]; then
        "$GRADLE_BIN" --no-daemon --stacktrace assemble${BRAND^}Release
        APK_PATH="app/build/outputs/apk/${BRAND}/release/app-${BRAND}-release-unsigned.apk"

        if [ -f "$APK_PATH" ]; then
            cp "$APK_PATH" "$BUILD_DIR/${BRAND}-unsigned.apk"
            echo -e "${YELLOW}  Note: APK is unsigned. Sign it before distribution.${NC}"
        fi
    else
        "$GRADLE_BIN" --no-daemon --stacktrace assemble${BRAND^}Debug
        APK_PATH="app/build/outputs/apk/${BRAND}/debug/app-${BRAND}-debug.apk"

        if [ -f "$APK_PATH" ]; then
            cp "$APK_PATH" "$BUILD_DIR/${BRAND}-debug.apk"
            echo -e "${GREEN}  APK built: $BUILD_DIR/${BRAND}-debug.apk${NC}"
        fi
    fi
}

check_prereqs
prepare_mobile_env

case "$BUILD_PHASE" in
    aar)
        build_aar
        prepare_android_project
        ;;
    apk)
        build_apk
        ;;
    all)
        build_aar
        prepare_android_project
        build_apk
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
echo "========================================"
