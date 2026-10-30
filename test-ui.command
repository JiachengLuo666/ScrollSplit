#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(dirname "$0")"
if [[ "$PROJECT_DIR" != /* ]]; then PROJECT_DIR="$PWD/$PROJECT_DIR"; fi
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/scrollsplit-ui-tests.XXXXXX")"
trap 'rm -rf "$TEST_TMP"' EXIT
xcrun swiftc -D UI_TEST -module-cache-path "$TEST_TMP/Modules" \
    -target "$(uname -m)-apple-macos13.0" \
    "$PROJECT_DIR"/Sources/*.swift "$PROJECT_DIR/Tests/UITests.swift" \
    -o "$TEST_TMP/ScrollSplitUITests"
"$TEST_TMP/ScrollSplitUITests"
