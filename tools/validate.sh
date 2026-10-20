#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p build
"$GODOT_BIN" --headless --editor --import --quit 2>&1 | tee build/import.log
if rg 'SCRIPT ERROR:|Parse Error:|Failed to load script' build/import.log; then exit 1; fi
"$GODOT_BIN" --headless --script res://tests/test_economy.gd 2>&1 | tee build/economy-tests.log
"$GODOT_BIN" --headless --script res://tests/test_gameplay.gd 2>&1 | tee build/gameplay-tests.log
if rg 'SCRIPT ERROR:|FAIL:|^ERROR:' build/economy-tests.log build/gameplay-tests.log; then exit 1; fi
