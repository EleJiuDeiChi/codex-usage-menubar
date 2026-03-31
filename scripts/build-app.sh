#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Codex Usage"
PRODUCT_NAME="CodexMenuBarApp"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$PRODUCT_NAME" "$MACOS_DIR/$PRODUCT_NAME"
cp "$ROOT_DIR/resources/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "Built app bundle at:"
echo "$APP_DIR"
