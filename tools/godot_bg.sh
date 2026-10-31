#!/bin/bash
# Godot launcher that keeps windowed runs in the background on macOS.
#
# Godot activates itself on launch (activateIgnoringOtherApps), so
# `open -g` alone can't keep it behind your editor. This wrapper runs
# the real binary directly (stdout and exit code preserved) and hands
# focus back to whatever app was in front whenever Godot grabs it.
#
#   --headless, --version, --help, the editor  -> passed through untouched
#   --script runs (tests, captures)            -> guarded for the whole run
#   plain app runs                             -> guarded for the first
#                                                 GODOT_FOCUS_GUARD_SECS (5),
#                                                 then you can click into it
#
# Also: strips --always-on-top, adds --windowed unless a window mode is
# given (projects that start full screen would otherwise take a Space).
# GODOT_FOREGROUND=1 bypasses all of this; GODOT_BIN points at a
# Godot binary installed somewhere else.
#
# Install it ahead of Homebrew's godot on PATH so every caller gets it:
#   cp tools/godot_bg.sh ~/.local/bin/godot

REAL=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}

headless=0
editor=0
scripted=0
has_mode=0
args=()
for a in "$@"; do
	case "$a" in
		--headless|--version|-h|--help|--doctool|--dump-*) headless=1 ;;
		-e|--editor|-p|--project-manager) editor=1 ;;
		-s|--script|--quit|--quit-after|--import|--export-*) scripted=1 ;;
		-f|--fullscreen|-m|--maximized|-w|--windowed) has_mode=1 ;;
	esac
	case "$a" in
		-t|--always-on-top) ;;
		*) args+=("$a") ;;
	esac
done

# An interactive editor launch is yours; --import/--export are batch jobs.
if [ "${GODOT_FOREGROUND:-0}" = 1 ] || [ "$headless" = 1 ] \
		|| { [ "$editor" = 1 ] && [ "$scripted" = 0 ]; }; then
	exec "$REAL" "$@"
fi

[ "$has_mode" = 0 ] && args=(--windowed "${args[@]}")

front_field() { lsappinfo info -only "$1" "$(lsappinfo front)" 2>/dev/null; }
prev=$(front_field bundleID | sed -n 's/.*bundleID="\([^"]*\)".*/\1/p')

"$REAL" "${args[@]}" &
pid=$!
trap 'kill -TERM "$pid" 2>/dev/null' INT TERM HUP

if [ -n "$prev" ]; then
	(
		limit=${GODOT_FOCUS_GUARD_SECS:-5}
		start=$SECONDS
		while kill -0 "$pid" 2>/dev/null; do
			if [ "$scripted" = 0 ] && [ $((SECONDS - start)) -ge "$limit" ]; then
				break
			fi
			front_pid=$(front_field pid | sed -n 's/.*pid = \([0-9]*\).*/\1/p')
			[ "$front_pid" = "$pid" ] && open -b "$prev"
			sleep 0.1
		done
	) &
	guard=$!
fi

wait "$pid"
rc=$?
[ -n "$guard" ] && kill "$guard" 2>/dev/null
exit $rc
