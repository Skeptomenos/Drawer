#!/bin/bash
#
# create-dmg.sh
# Creates a distributable DMG for Drawer.app
#
# Usage: ./scripts/create-dmg.sh [--release]
#
# Options:
#   --release    Build in Release configuration (default: Debug)
#
# Requirements:
#   - Xcode command line tools
#   - create-dmg (optional, for fancy DMG): brew install create-dmg
#

set -e

# Configuration
APP_NAME="Drawer"
SCHEME="Drawer"
PROJECT="Hidden Bar.xcodeproj"
BUILD_DIR="build"
DMG_DIR="dist"

# Parse arguments
CONFIGURATION="Debug"
if [[ "$1" == "--release" ]]; then
    CONFIGURATION="Release"
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=== Drawer DMG Builder ==="
echo "Configuration: $CONFIGURATION"
echo ""

# Step 1: Clean and build
echo "Step 1: Building $APP_NAME..."
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    clean build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | grep -E "(Building|Compiling|Linking|BUILD)" || true

# Find the built app
APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME.app" -type d | head -1)

if [[ -z "$APP_PATH" ]]; then
    echo "Error: Could not find $APP_NAME.app in build output"
    exit 1
fi

echo "Built app: $APP_PATH"

# Step 2: Get version info
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP_PATH/Contents/Info.plist")
DMG_NAME="${APP_NAME}-${VERSION}"

echo "Version: $VERSION (build $BUILD)"

# Step 3: Create dist directory
mkdir -p "$DMG_DIR"

# Step 4: Create DMG
echo ""
echo "Step 2: Creating DMG..."

# Check if create-dmg is available for fancy DMG
if command -v create-dmg &> /dev/null; then
    echo "Using create-dmg for styled DMG..."
    
    # Remove existing DMG if present
    rm -f "$DMG_DIR/$DMG_NAME.dmg"
    
    create-dmg \
        --volname "$APP_NAME" \
        --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 190 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 450 190 \
        --no-internet-enable \
        "$DMG_DIR/$DMG_NAME.dmg" \
        "$APP_PATH" \
        2>/dev/null || {
            echo "create-dmg failed, falling back to hdiutil..."
            # Fallback to simple DMG
            TEMP_DMG_DIR=$(mktemp -d)
            cp -R "$APP_PATH" "$TEMP_DMG_DIR/"
            ln -s /Applications "$TEMP_DMG_DIR/Applications"
            hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_DIR/$DMG_NAME.dmg"
            rm -rf "$TEMP_DMG_DIR"
        }
else
    echo "Using hdiutil for simple DMG..."
    echo "(Install create-dmg for styled DMG: brew install create-dmg)"
    
    # Create temporary directory with app and Applications symlink
    TEMP_DMG_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$TEMP_DMG_DIR/"
    ln -s /Applications "$TEMP_DMG_DIR/Applications"
    
    # Create DMG
    rm -f "$DMG_DIR/$DMG_NAME.dmg"
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$TEMP_DMG_DIR" \
        -ov \
        -format UDZO \
        "$DMG_DIR/$DMG_NAME.dmg"
    
    # Cleanup
    rm -rf "$TEMP_DMG_DIR"
fi

# Step 5: Verify
if [[ -f "$DMG_DIR/$DMG_NAME.dmg" ]]; then
    DMG_SIZE=$(du -h "$DMG_DIR/$DMG_NAME.dmg" | cut -f1)
    echo ""
    echo "=== Success ==="
    echo "DMG created: $DMG_DIR/$DMG_NAME.dmg"
    echo "Size: $DMG_SIZE"
    echo ""
    echo "To notarize (requires Apple Developer account):"
    echo "  xcrun notarytool submit $DMG_DIR/$DMG_NAME.dmg --keychain-profile \"AC_PASSWORD\" --wait"
    echo "  xcrun stapler staple $DMG_DIR/$DMG_NAME.dmg"
else
    echo "Error: DMG creation failed"
    exit 1
fi
