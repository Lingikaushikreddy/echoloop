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
"$GODOT" --headless --fixed-fps 60 -s addons/gut/gut_cmdln.gd "$@"
