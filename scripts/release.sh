#!/bin/sh
# Builds Pulsar, zips it and publishes a GitHub release tagged with MARKETING_VERSION.
# Usage: scripts/release.sh [release notes file]
set -eu
cd "$(dirname "$0")/.."

version=$(xcodebuild -project Pulsar.xcodeproj -scheme Pulsar -configuration Release -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ MARKETING_VERSION / { print $2; exit }')
tag="v$version"
if git rev-parse "$tag" >/dev/null 2>&1; then
  echo "$tag already exists; bump MARKETING_VERSION first" >&2
  exit 1
fi

rm -rf build/DerivedData/Build/Products/Release
xcodebuild -project Pulsar.xcodeproj -scheme Pulsar -configuration Release \
  -derivedDataPath build/DerivedData build | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
app=build/DerivedData/Build/Products/Release/Pulsar.app
[ -d "$app" ] || { echo "Build failed" >&2; exit 1; }

archive="build/Pulsar-$version.zip"
rm -f "$archive"
ditto -c -k --keepParent "$app" "$archive"

notes=${1:-}
if [ -n "$notes" ]; then
  gh release create "$tag" "$archive" --title "Pulsar $version" --notes-file "$notes"
else
  gh release create "$tag" "$archive" --title "Pulsar $version" --generate-notes
fi
