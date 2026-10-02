#!/usr/bin/env bash
# Exports the single-threaded web build to build/web/.
# Needs the web templates (scripts/fetch_web_templates.py). Set GODOT to choose the binary.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
rm -rf build/web
mkdir -p build/web
"$GODOT" --headless --import
"$GODOT" --headless --export-release "Web" build/web/index.html
for f in index.html index.js index.wasm index.pck; do
  test -f "build/web/$f" || { echo "missing build/web/$f" >&2; exit 1; }
done
echo "Web build ready in build/web"
