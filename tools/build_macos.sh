#!/bin/sh
# Export the Godot macOS app as a .dmg in ../build/macos/.
# Unsigned by default (ad-hoc). Signing stays local or in CI secrets:
#   MACOS_SIGN_IDENTITY  "Developer ID Application: ..." in your keychain
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH  App Store Connect API key,
#                        notarizes and staples the .dmg (needs the identity)
#   VERSION, BUILD_NUMBER  override the preset's short_version / version
# Secrets are injected into the export preset for the export only, then
# the committed (blank) preset is restored. Pass --debug for a debug build.
set -e
cd "$(dirname "$0")/.."

MODE=--export-release
[ "$1" = "--debug" ] && MODE=--export-debug
OUT=../build/macos/PlanetRender360.dmg

PRESET_BACKUP="$(mktemp)"
cp export_presets.cfg "$PRESET_BACKUP"
restore_preset() { cp "$PRESET_BACKUP" export_presets.cfg; rm -f "$PRESET_BACKUP"; }
trap restore_preset EXIT INT TERM

# Only the macOS preset (preset.0) has these keys, so a plain sed is safe.
if [ -n "$VERSION" ]; then
	sed -i '' "/^\[preset.0.options\]/,/^\[preset.1\]/s/^application\/short_version=.*/application\/short_version=\"$VERSION\"/" export_presets.cfg
fi
if [ -n "$BUILD_NUMBER" ]; then
	sed -i '' "/^\[preset.0.options\]/,/^\[preset.1\]/s/^application\/version=.*/application\/version=\"$BUILD_NUMBER\"/" export_presets.cfg
fi
if [ -n "$MACOS_SIGN_IDENTITY" ]; then
	# codesign/codesign: 3 = Xcode codesign (hardened runtime, Godot's entitlements).
	perl -pi -e 's/^display\/high_res=true$/$&\ncodesign\/codesign=3\ncodesign\/identity="$ENV{MACOS_SIGN_IDENTITY}"/' export_presets.cfg
fi

mkdir -p ../build/macos
rm -f "$OUT"
godot --headless --path . $MODE "macOS" "$OUT"
restore_preset
trap - EXIT INT TERM
[ -f "$OUT" ] || { echo "Export failed: $OUT not written" >&2; exit 1; }

if [ -n "$MACOS_SIGN_IDENTITY" ] && [ -n "$ASC_KEY_ID" ]; then
	: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID to notarize}"
	: "${ASC_KEY_PATH:?Set ASC_KEY_PATH to the .p8 key to notarize}"
	xcrun notarytool submit "$OUT" --key "$ASC_KEY_PATH" \
		--key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" --wait
	xcrun stapler staple "$OUT"
	spctl -a -vv -t open --context context:primary-signature "$OUT"
fi
echo "Built: $(cd ../build/macos && pwd)/PlanetRender360.dmg"
