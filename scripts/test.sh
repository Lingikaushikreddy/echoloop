#!/usr/bin/env bash
# Runs every GUT test headless.
# Usage: scripts/test.sh [extra GUT args], e.g. scripts/test.sh -gselect=test_player
# Set GODOT to use a specific Godot binary.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# Importing first builds .godot/ (the class_name cache and imported textures).
"$GODOT" --headless --import
# --fixed-fps 60 makes every frame exactly one 1/60 s physics tick, as fast as the CPU allows.
LOG="$(mktemp)"
set +e
"$GODOT" --headless --fixed-fps 60 -s addons/gut/gut_cmdln.gd "$@" 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}
set -e
# GUT skips a test file that fails to parse ("does not extend GutTest") and still
# exits 0, so a broken test would silently drop out of the suite. Fail instead.
if grep -qE 'SCRIPT ERROR|Failed to load script|\[GUT ERROR\]|does not extend GutTest' "$LOG"; then
  echo "scripts/test.sh: script errors above; failing the run." >&2
  STATUS=1
fi
rm -f "$LOG"
exit "$STATUS"
