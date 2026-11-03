#!/bin/sh
# Export the Godot Android app as an .apk in ../build/android/.
# Needs JDK 17 and the Android SDK (ANDROID_HOME / ANDROID_SDK_ROOT)
# plus Godot's export templates; CI sets all of that up (see
# .github/workflows/android.yml). Signing:
#   ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_USER, ANDROID_KEYSTORE_PASSWORD
#                        release keystore; without one the export falls
#                        back to Godot's debug keystore. Either way the
#                        .apk is for sideload/direct distribution —
#                        Google Play requires an .aab, not produced here
#   VERSION, BUILD_NUMBER  override the preset's version/name / version/code
# Secrets are injected into the export preset for the export only, then
# the committed (blank) preset is restored. Pass --debug for a debug build.
set -e
cd "$(dirname "$0")/.."

MODE=--export-release
[ "$1" = "--debug" ] && MODE=--export-debug
OUT=../build/android/PlanetRender360.apk

. tools/version_stamp.sh
stamp_version

PRESET_BACKUP="$(mktemp)"
cp export_presets.cfg "$PRESET_BACKUP"
restore_preset() { cp "$PRESET_BACKUP" export_presets.cfg; rm -f "$PRESET_BACKUP"; restore_version; }
trap restore_preset EXIT INT TERM

# Only the Android preset (preset.1) has these keys. perl edits work the
# same under BSD and GNU userlands, unlike `sed -i`.
if [ -n "$VERSION" ]; then
	VERSION="$VERSION" perl -pi -e 'BEGIN { $in = 0 } $in = 1 if /^\[preset\.1\.options\]/; $in = 0 if /^\[preset\.2\]/; $_ = "version/name=\"$ENV{VERSION}\"\n" if $in && /^version\/name=/' export_presets.cfg
fi
if [ -n "$BUILD_NUMBER" ]; then
	BUILD_NUMBER="$BUILD_NUMBER" perl -pi -e 'BEGIN { $in = 0 } $in = 1 if /^\[preset\.1\.options\]/; $in = 0 if /^\[preset\.2\]/; $_ = "version/code=$ENV{BUILD_NUMBER}\n" if $in && /^version\/code=/' export_presets.cfg
fi
if [ -n "$ANDROID_KEYSTORE_PATH" ]; then
	perl -pi -e 's/^\[preset\.1\.options\]$/$&\nkeystore\/debug="$ENV{ANDROID_KEYSTORE_PATH}"\nkeystore\/debug_user="$ENV{ANDROID_KEYSTORE_USER}"\nkeystore\/debug_password="$ENV{ANDROID_KEYSTORE_PASSWORD}"\nkeystore\/release="$ENV{ANDROID_KEYSTORE_PATH}"\nkeystore\/release_user="$ENV{ANDROID_KEYSTORE_USER}"\nkeystore\/release_password="$ENV{ANDROID_KEYSTORE_PASSWORD}"/' export_presets.cfg
fi

mkdir -p ../build/android
rm -f "$OUT"
godot --headless --path . $MODE "Android" "$OUT"
restore_preset
trap - EXIT INT TERM
[ -f "$OUT" ] || { echo "Export failed: $OUT not written" >&2; exit 1; }
echo "Built: $(cd ../build/android && pwd)/PlanetRender360.apk"
