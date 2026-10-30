#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(dirname "$0")"
if [[ "$PROJECT_DIR" != /* ]]; then PROJECT_DIR="$PWD/$PROJECT_DIR"; fi
APP_DIR="${1:-$PROJECT_DIR/../ScrollSplit.app}"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Info.plist")
BUILD_TMP="$(mktemp -d "${TMPDIR:-/tmp}/scrollsplit-build.XXXXXX")"
trap 'rm -rf "$BUILD_TMP"' EXIT
mkdir -p "$BUILD_TMP/Modules" "$BUILD_TMP/ScrollSplit.app/Contents/MacOS" "$BUILD_TMP/ScrollSplit.app/Contents/Resources" "$BUILD_TMP/AppIcon.iconset"
xcrun swiftc -module-cache-path "$BUILD_TMP/Modules" "$PROJECT_DIR/Tools/RenderAssets.swift" -o "$BUILD_TMP/render-assets"
"$BUILD_TMP/render-assets" "$BUILD_TMP" "${VERSION%.0}"
for SIZE in 16 32 128 256 512; do
    sips -z "$SIZE" "$SIZE" "$BUILD_TMP/AppIcon-1024.png" --out "$BUILD_TMP/AppIcon.iconset/icon_${SIZE}x${SIZE}.png" >/dev/null
    DOUBLE_SIZE=$((SIZE * 2))
    sips -z "$DOUBLE_SIZE" "$DOUBLE_SIZE" "$BUILD_TMP/AppIcon-1024.png" --out "$BUILD_TMP/AppIcon.iconset/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$BUILD_TMP/AppIcon.iconset" -o "$BUILD_TMP/ScrollSplit.app/Contents/Resources/AppIcon.icns"
for ARCH in arm64 x86_64; do
    xcrun swiftc -O -target "$ARCH-apple-macos13.0" \
        -module-cache-path "$BUILD_TMP/Modules" \
        "$PROJECT_DIR"/Sources/*.swift \
        -o "$BUILD_TMP/ScrollSplit-$ARCH"
done
xcrun lipo -create "$BUILD_TMP/ScrollSplit-arm64" "$BUILD_TMP/ScrollSplit-x86_64" \
    -output "$BUILD_TMP/ScrollSplit.app/Contents/MacOS/ScrollSplit"
cp "$PROJECT_DIR/Info.plist" "$BUILD_TMP/ScrollSplit.app/Contents/Info.plist"
codesign --force --sign - --identifier local.scrollsplit.app "$BUILD_TMP/ScrollSplit.app"
"$BUILD_TMP/render-assets" --require-app-closed "$APP_DIR"
ditto "$BUILD_TMP/ScrollSplit.app" "$APP_DIR"
codesign --verify --strict "$APP_DIR"
printf '已生成：%s\n' "$APP_DIR"
