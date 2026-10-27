#!/bin/sh
# Export the Godot iOS project and build a signed device .app.
# Signing stays local: set APPLE_TEAM_ID in your environment (never
# commit it). The script temporarily injects it into the local export
# preset for the Godot export, then restores the committed (blank)
# preset, and lets Xcode automatic signing create the provisioning
# profile for the bundle ID.
set -e
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to your Apple Developer Team ID}"
cd "$(dirname "$0")/.."

PRESET_BACKUP="$(mktemp)"
cp export_presets.cfg "$PRESET_BACKUP"
restore_preset() { cp "$PRESET_BACKUP" export_presets.cfg; rm -f "$PRESET_BACKUP"; }
trap restore_preset EXIT INT TERM
sed -i '' "s/application\/app_store_team_id=\"\"/application\/app_store_team_id=\"$APPLE_TEAM_ID\"/" export_presets.cfg

mkdir -p ../build/ios
godot --headless --export-debug "iOS" ../build/ios/PlanetRender360.zip
restore_preset
trap - EXIT INT TERM

cd ../build/ios
xcodebuild -project PlanetRender360.xcodeproj \
  -scheme PlanetRender360 -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/pr360-dev -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" PROVISIONING_PROFILE_SPECIFIER="" build
echo "Built: /tmp/pr360-dev/Build/Products/Debug-iphoneos/PlanetRender360.app"
echo "Install with: xcrun devicectl device install app --device <DEVICE_ID> /tmp/pr360-dev/Build/Products/Debug-iphoneos/PlanetRender360.app"
