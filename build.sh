#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy/release"
APP_NAME="Hum"
APP_BUNDLE="$DEPLOY_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

VERSION="${1:-dev}"

echo "Building $APP_NAME (release)..."
swift build --package-path "$SCRIPT_DIR" -c release

BIN=$(swift build --package-path "$SCRIPT_DIR" -c release --show-bin-path)/$APP_NAME

# Create .app bundle
echo "Creating $APP_NAME.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$SCRIPT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"
cp "$SCRIPT_DIR/Resources/Hum.icns" "$APP_BUNDLE/Contents/Resources/"

# Update version in Info.plist if provided
if [[ "$VERSION" != "dev" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"
fi

# Ad-hoc code sign
echo "Code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

# Create .dmg
echo "Creating $DMG_NAME..."
rm -f "$DEPLOY_DIR/$DMG_NAME"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_BUNDLE" \
    -ov -format UDZO \
    "$DEPLOY_DIR/$DMG_NAME"

echo "Done:"
echo "  App    → $APP_BUNDLE"
echo "  DMG    → $DEPLOY_DIR/$DMG_NAME"
