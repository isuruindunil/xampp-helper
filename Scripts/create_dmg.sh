#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

# 1. First ensure app is built
"$DIR/Scripts/build_app.sh"

APP_NAME="XAMPP Helper"
DMG_NAME="XAMPP-Helper-1.0.0.dmg"
DIST_DIR="$DIR/dist"
STAGING_DIR="/tmp/xampp_helper_dmg_staging_$$"

echo "💿 Creating DMG installer package..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy app bundle into staging
cp -R "$DIST_DIR/$APP_NAME.app" "$STAGING_DIR/"

# Create Applications symlink for drag-and-drop installation
ln -s /Applications "$STAGING_DIR/Applications"

# Output DMG path
DMG_PATH="$DIST_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

# Build DMG using hdiutil
hdiutil create -volname "$APP_NAME" \
               -srcfolder "$STAGING_DIR" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

# Clean up staging
rm -rf "$STAGING_DIR"

echo "✅ DMG installer created successfully:"
echo "   $DMG_PATH"
echo ""
echo "🚀 To mount and test:"
echo "   open \"$DMG_PATH\""

