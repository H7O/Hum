#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy/release"

echo "Building Hum (release)..."
swift build --package-path "$SCRIPT_DIR" -c release

BIN=$(swift build --package-path "$SCRIPT_DIR" -c release --show-bin-path)/Hum

mkdir -p "$DEPLOY_DIR"
cp "$BIN" "$DEPLOY_DIR/Hum"
chmod +x "$DEPLOY_DIR/Hum"

echo "Done → $DEPLOY_DIR/Hum"
