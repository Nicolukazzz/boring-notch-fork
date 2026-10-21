#!/bin/zsh
# Build this fork in Release and install it as the only copy in /Applications.
# Ad-hoc signed without hardened runtime: embedded frameworks have no Team ID,
# and library validation would otherwise refuse to load them.
set -euo pipefail
cd "$(dirname "$0")/.."

PRODUCT="build/Build/Products/Release/Boring Notch.app"

xcodebuild -project boringNotch.xcodeproj -scheme boringNotch -configuration Release \
  -derivedDataPath build CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
  ENABLE_HARDENED_RUNTIME=NO build | grep -E "error:|BUILD (SUCCEEDED|FAILED)"

[[ -d "$PRODUCT" ]] || { echo "Build product not found: $PRODUCT"; exit 1; }

osascript -e 'tell application id "theboringteam.boringnotch" to quit' 2>/dev/null || true
sleep 2
# Also stops the media adapter and helper processes left behind by the app.
pkill -f "oring ?[Nn]otch.app/Contents/" 2>/dev/null || true

# Remove both the legacy and the current bundle name so only one copy exists.
rm -rf "/Applications/boringNotch.app" "/Applications/Boring Notch.app"
ditto "$PRODUCT" "/Applications/Boring Notch.app"
rm -rf "$PRODUCT"
open "/Applications/Boring Notch.app"
echo "Installed /Applications/Boring Notch.app"
