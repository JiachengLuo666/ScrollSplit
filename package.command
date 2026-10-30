#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(dirname "$0")"
if [[ "$PROJECT_DIR" != /* ]]; then PROJECT_DIR="$PWD/$PROJECT_DIR"; fi
APP_DIR="${1:-$PROJECT_DIR/../ScrollSplit.app}"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")
RELEASE="${VERSION%.0}"
OUTPUT="$PROJECT_DIR/../ScrollSplit-$RELEASE.dmg"
PACK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/scrollsplit-package.XXXXXX")"
trap 'rm -rf "$PACK_TMP"' EXIT
codesign --verify --strict "$APP_DIR"
python3 -m venv "$PACK_TMP/venv"
"$PACK_TMP/venv/bin/python" -m pip install --disable-pip-version-check --quiet "dmgbuild==1.6.5"
xcrun swiftc -module-cache-path "$PACK_TMP/Modules" "$PROJECT_DIR/Tools/RenderAssets.swift" -o "$PACK_TMP/render-assets"
"$PACK_TMP/render-assets" "$PACK_TMP" "$RELEASE"
sips -z 500 640 "$PACK_TMP/dmg-background.png" --out "$PACK_TMP/background.png" >/dev/null
"$PACK_TMP/venv/bin/python" "$PROJECT_DIR/Tools/BuildDMG.py" \
    "$APP_DIR" "$PACK_TMP/background.png" "$PACK_TMP/ScrollSplit-$RELEASE.dmg"
hdiutil verify "$PACK_TMP/ScrollSplit-$RELEASE.dmg"
cp "$PACK_TMP/ScrollSplit-$RELEASE.dmg" "$OUTPUT"
printf '已生成：%s\n' "$OUTPUT"
