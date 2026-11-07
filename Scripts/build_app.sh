#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🔨 Building XAMPP Helper (Release)..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/XamppHelper"

if [ ! -f "$BIN_PATH" ]; then
    echo "❌ Binary not found at $BIN_PATH"
    exit 1
fi

APP_NAME="XAMPP Helper.app"
DIST_DIR="$DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME"

echo "📦 Assembling $APP_NAME..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/XamppHelper"
chmod +x "$APP_BUNDLE/Contents/MacOS/XamppHelper"

# Copy Info.plist
cp "$DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy Icon
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Write PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Code sign ad-hoc
echo "🔏 Code-signing application..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Successfully built $APP_BUNDLE"
echo ""
echo "🚀 To run the app:"
echo "   open \"$APP_BUNDLE\""
echo ""
echo "📂 Or install to Applications folder:"
echo "   cp -R \"$APP_BUNDLE\" /Applications/"

