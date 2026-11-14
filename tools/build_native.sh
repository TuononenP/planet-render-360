#!/bin/bash
# Builds the native build kernels (native/, GDExtension) and writes
# native/bin/planet_render.gdextension next to them. Without a build the
# app runs the GDScript versions of the same loops.
#
#   tools/build_native.sh                 macOS (universal), debug + release
#   tools/build_native.sh macos ios android
#
# Needs CMake and Xcode; Android needs the NDK (ANDROID_NDK_ROOT, or the
# newest under ~/Library/Android/sdk/ndk).
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
ROOT="$PWD/native"
BUILD="$ROOT/build"
mkdir -p "$BUILD" "$ROOT/bin"
touch "$BUILD/.gdignore"
[ -f "$ROOT/godot-cpp/CMakeLists.txt" ] || git submodule update --init native/godot-cpp

platforms=("$@")
[ ${#platforms[@]} -eq 0 ] && platforms=(macos)

build() {  # name target [cmake args...]
	local name=$1 target=$2
	shift 2
	cmake -S "$ROOT" -B "$BUILD/$name-$target" -DCMAKE_BUILD_TYPE=Release \
		-DGODOTCPP_TARGET="$target" "$@" >/dev/null
	cmake --build "$BUILD/$name-$target" --parallel >/dev/null
	echo "built $name $target"
}

for p in "${platforms[@]}"; do
	for target in template_debug template_release; do
		case $p in
			macos)
				build macos $target -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
					-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 ;;
			ios)
				# A plain dylib: Godot's iOS export wraps it in a framework.
				# 15.0 is the oldest target the SDK's libc++ still supports.
				build ios $target -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$(xcrun --sdk iphoneos --show-sdk-path)" \
					-DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_SYSTEM_PROCESSOR=arm64 \
					-DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 ;;
			android)
				ndk="${ANDROID_NDK_ROOT:-$(ls -d "$HOME"/Library/Android/sdk/ndk/* 2>/dev/null | sort -V | tail -1)}"
				if [ ! -f "$ndk/build/cmake/android.toolchain.cmake" ]; then
					echo "android: no NDK found; set ANDROID_NDK_ROOT or install one under ~/Library/Android/sdk/ndk" >&2
					exit 1
				fi
				build android $target \
					-DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" \
					-DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 ;;
			*) echo "unknown platform: $p" >&2; exit 1 ;;
		esac
	done
done

# One entry per library that exists, so a partial build loads cleanly.
{
	echo "[configuration]"
	echo
	echo 'entry_symbol = "planet_render_init"'
	echo 'compatibility_minimum = "4.7"'
	echo
	echo "[libraries]"
	echo
	for f in "$ROOT"/bin/libplanet_render.*; do
		n=$(basename "$f")
		case $n in
			*.macos.template_debug.*) key=macos.debug ;;
			*.macos.template_release.*) key=macos.release ;;
			*.ios.template_debug.*) key=ios.debug ;;
			*.ios.template_release.*) key=ios.release ;;
			*.android.template_debug.arm64.*) key=android.debug.arm64 ;;
			*.android.template_release.arm64.*) key=android.release.arm64 ;;
			*) continue ;;
		esac
		echo "$key = \"res://native/bin/$n\""
	done
} > "$ROOT/bin/planet_render.gdextension"

# Godot loads only the extensions its import lists.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
echo "wrote native/bin/planet_render.gdextension"
