#!/bin/sh
# Export the Godot iOS project, archive it for the App Store and upload
# it to TestFlight (tools/build_ios.sh stays the local dev-device build).
# Signing is automatic through an App Store Connect API key, so no
# profiles or certificates are needed:
#   APPLE_TEAM_ID                          Apple Developer Team ID
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH  App Store Connect API key (.p8)
#   VERSION, BUILD_NUMBER   override short_version / version (TestFlight
#                           needs a higher BUILD_NUMBER on every upload)
#   IOS_UPLOAD=0            export the .ipa to ../build/ios/ instead of uploading
# Secrets are injected into the export preset for the export only, then
# the committed (blank) preset is restored.
set -e
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to your Apple Developer Team ID}"
: "${ASC_KEY_ID:?Set ASC_KEY_ID to the App Store Connect API key ID}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID to the App Store Connect issuer ID}"
: "${ASC_KEY_PATH:?Set ASC_KEY_PATH to the App Store Connect .p8 key}"
cd "$(dirname "$0")/.."

PRESET_BACKUP="$(mktemp)"
cp export_presets.cfg "$PRESET_BACKUP"
restore_preset() { cp "$PRESET_BACKUP" export_presets.cfg; rm -f "$PRESET_BACKUP"; }
trap restore_preset EXIT INT TERM
IOS_OPTS='/^\[preset.2.options\]/,$'
sed -i '' "s/application\/app_store_team_id=\"\"/application\/app_store_team_id=\"$APPLE_TEAM_ID\"/" export_presets.cfg
# Godot writes the Xcode project only; xcodebuild below archives and signs it.
sed -i '' "s/application\/export_project_only=false/application\/export_project_only=true/" export_presets.cfg
if [ -n "$VERSION" ]; then
	sed -i '' "${IOS_OPTS}s/^application\/short_version=.*/application\/short_version=\"$VERSION\"/" export_presets.cfg
fi
if [ -n "$BUILD_NUMBER" ]; then
	sed -i '' "${IOS_OPTS}s/^application\/version=.*/application\/version=\"$BUILD_NUMBER\"/" export_presets.cfg
fi

mkdir -p ../build/ios
godot --headless --path . --export-release "iOS" ../build/ios/PlanetRender360.zip
restore_preset
trap - EXIT INT TERM

cd ../build/ios
AUTH="-allowProvisioningUpdates -authenticationKeyPath $ASC_KEY_PATH \
	-authenticationKeyID $ASC_KEY_ID -authenticationKeyIssuerID $ASC_ISSUER_ID"
rm -rf PlanetRender360.xcarchive
xcodebuild -project PlanetRender360.xcodeproj \
	-scheme PlanetRender360 -configuration Release \
	-destination 'generic/platform=iOS' \
	-archivePath PlanetRender360.xcarchive $AUTH \
	CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
	CODE_SIGN_IDENTITY="Apple Development" PROVISIONING_PROFILE_SPECIFIER="" archive

DESTINATION=upload
[ "$IOS_UPLOAD" = "0" ] && DESTINATION=export
cat > ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>$DESTINATION</string>
	<key>teamID</key><string>$APPLE_TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
</dict>
</plist>
EOF
xcodebuild -exportArchive -archivePath PlanetRender360.xcarchive \
	-exportOptionsPlist ExportOptions.plist -exportPath export $AUTH
if [ "$DESTINATION" = "upload" ]; then
	echo "Uploaded to App Store Connect; the build shows in TestFlight after processing."
else
	echo "Built: $(pwd)/export/PlanetRender360.ipa"
fi
