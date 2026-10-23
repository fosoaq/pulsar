#!/bin/sh
# Builds a Release copy of Pulsar and installs it into /Applications.
set -eu
cd "$(dirname "$0")/.."

xcodebuild -project Pulsar.xcodeproj -scheme Pulsar -configuration Release \
  -derivedDataPath build/DerivedData build | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
app=build/DerivedData/Build/Products/Release/Pulsar.app
[ -d "$app" ] || { echo "Build failed" >&2; exit 1; }

osascript -e 'tell application id "io.github.fosoaq.Pulsar" to quit' 2>/dev/null || true
sleep 1
rm -rf /Applications/Pulsar.app
ditto "$app" /Applications/Pulsar.app
open /Applications/Pulsar.app
echo "Installed /Applications/Pulsar.app"
