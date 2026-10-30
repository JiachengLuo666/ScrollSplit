#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(dirname "$0")"
if [[ "$PROJECT_DIR" != /* ]]; then PROJECT_DIR="$PWD/$PROJECT_DIR"; fi
APP_DIR="${1:-$PROJECT_DIR/../ScrollSplit.app}"
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/scrollsplit-launch-tests.XXXXXX")"
trap 'rm -rf "$TEST_TMP"' EXIT
TEST_ID="local.scrollsplit.launchtest.$(uuidgen)"
mkdir -p "$TEST_TMP/Old/ScrollSplit.app/Contents/MacOS" "$TEST_TMP/Installed"
ditto "$APP_DIR" "$TEST_TMP/Installed/ScrollSplit.app"
cp "$APP_DIR/Contents/Info.plist" "$TEST_TMP/Old/ScrollSplit.app/Contents/Info.plist"
for BUNDLE in "$TEST_TMP/Old/ScrollSplit.app" "$TEST_TMP/Installed/ScrollSplit.app"; do
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $TEST_ID" "$BUNDLE/Contents/Info.plist"
done
/usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString 2.0.0' "$TEST_TMP/Old/ScrollSplit.app/Contents/Info.plist"
xcrun swiftc -parse-as-library -module-cache-path "$TEST_TMP/Modules" \
    "$PROJECT_DIR/Tests/LegacyFixture.swift" -o "$TEST_TMP/Old/ScrollSplit.app/Contents/MacOS/ScrollSplit"
codesign --force --sign - "$TEST_TMP/Old/ScrollSplit.app"
codesign --force --sign - "$TEST_TMP/Installed/ScrollSplit.app"
xcrun swiftc -parse-as-library -module-cache-path "$TEST_TMP/Modules" \
    "$PROJECT_DIR/Tests/LaunchIntegration.swift" -o "$TEST_TMP/LaunchIntegration"
"$TEST_TMP/LaunchIntegration" "$TEST_ID" "$TEST_TMP/Old/ScrollSplit.app" "$TEST_TMP/Installed/ScrollSplit.app"
