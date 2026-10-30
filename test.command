#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(dirname "$0")"
if [[ "$PROJECT_DIR" != /* ]]; then PROJECT_DIR="$PWD/$PROJECT_DIR"; fi
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/scrollsplit-tests.XXXXXX")"
trap 'rm -rf "$TEST_TMP"' EXIT
xcrun swiftc -module-cache-path "$TEST_TMP/Modules" \
    "$PROJECT_DIR/Sources/ScrollFilter.swift" "$PROJECT_DIR/Sources/ScrollState.swift" \
    "$PROJECT_DIR/Sources/AppVersion.swift" "$PROJECT_DIR/Tests/main.swift" \
    -o "$TEST_TMP/ScrollFilterTests"
"$TEST_TMP/ScrollFilterTests"
