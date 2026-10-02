#!/usr/bin/env bash
# Installs a Godot editor binary and its web export templates on Linux CI.
# Usage: scripts/ci_install_godot.sh 4.7.2
set -euo pipefail
VERSION="$1"
mkdir -p ~/godot
curl -sSfL -o /tmp/godot.zip \
  "https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_linux.x86_64.zip"
unzip -q -o /tmp/godot.zip -d ~/godot
mv "$HOME/godot/Godot_v${VERSION}-stable_linux.x86_64" ~/godot/godot
chmod +x ~/godot/godot
python3 "$(dirname "$0")/fetch_web_templates.py" "$VERSION" \
  "$HOME/.local/share/godot/export_templates/${VERSION}.stable"
