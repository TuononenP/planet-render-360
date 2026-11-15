#!/bin/bash
# Godot launcher that keeps windowed runs in the background on macOS.
#
# Godot activates itself on launch (activateIgnoringOtherApps), so
# `open -g` alone can't keep it behind your editor. When the
# godot_noactivate.dylib shim is installed (see tools/godot_noactivate.m)
# the wrapper injects it and Godot never takes focus at all; --script
# runs also never order their window on screen, so nothing flashes.
# Without the shim it falls back to running the real binary directly
# (stdout and exit code preserved) and handing focus back to whatever
# app was in front whenever Godot grabs it, which flickers.
#
#   --headless                                -> shimmed when available
#   --version, --help, the editor             -> passed through untouched
#   --script runs (tests, captures)            -> guarded for the whole run
#   plain app runs                             -> guarded for the first
#                                                 GODOT_FOCUS_GUARD_SECS (5),
#                                                 then you can click into it
#   plain app runs typed in a terminal (a tty) -> not guarded: it is your
#                                                 own run, and bouncing
#                                                 focus back flickers it
#
# Also: strips --always-on-top, adds --windowed unless a window mode is
# given (projects that start full screen would otherwise take a Space).
# GODOT_FOREGROUND=1 bypasses all of this; GODOT_BIN points at a
# Godot binary installed somewhere else; GODOT_NOACTIVATE_DYLIB points
# at the shim (default ~/.local/lib/godot_noactivate.dylib).
#
# Batch runs (--headless, --script, --import, --export) are killed when
# their memory footprint (compressed and swapped pages included) passes
# GODOT_MEM_CAP_GB (default 24; 0 turns the cap off): a runaway script
# loop in an agent's capture once filled 100+ GB of swap and froze the Mac.
#
# Install it ahead of Homebrew's godot on PATH so every caller gets it:
#   cp tools/godot_bg.sh ~/.local/bin/godot

REAL=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}

headless=0
headless_run=0
editor=0
scripted=0
has_mode=0
args=()
for a in "$@"; do
	case "$a" in
		--headless) headless_run=1 ;;
	esac
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

cap_gb=${GODOT_MEM_CAP_GB:-24}

# Physical footprint of a process in KB, compressed and swapped pages included.
footprint_kb() {
	footprint -p "$1" 2>/dev/null | awk '/phys_footprint:/ {
		v = $2; gsub(",", "", v); u = $3
		if (u == "MB") v *= 1024; else if (u == "GB") v *= 1048576
		printf "%d", v; exit }'
}

# Kills Godot `$1` once its footprint passes the cap; sets `watch` to its pid.
watch_memory() {
	watch=
	[ "$cap_gb" = 0 ] && return
	command -v footprint >/dev/null || return
	(
		cap_kb=$((cap_gb * 1048576))
		while kill -0 "$1" 2>/dev/null; do
			kb=$(footprint_kb "$1")
			if [ -n "$kb" ] && [ "$kb" -gt "$cap_kb" ]; then
				echo "godot_bg: Godot $1 passed the ${cap_gb} GB memory cap ($((kb / 1048576)) GB); killed it. GODOT_MEM_CAP_GB raises the cap." >&2
				kill -9 "$1"
				break
			fi
			sleep 2
		done
	) &
	watch=$!
}

# Runs a batch job under the memory cap, keeping its exit code.
capped() {
	if [ "$cap_gb" = 0 ] || ! command -v footprint >/dev/null; then
		exec "$REAL" "$@"
	fi
	"$REAL" "$@" &
	pid=$!
	trap 'kill -TERM "$pid" 2>/dev/null' INT TERM HUP
	watch_memory "$pid"
	wait "$pid"
	rc=$?
	while kill -0 "$pid" 2>/dev/null; do
		wait "$pid"
		rc=$?
	done
	[ -n "$watch" ] && kill "$watch" 2>/dev/null
	exit $rc
}

# Headless batch jobs can still initialize macOS application APIs. Apply the
# same no-activation protection without changing their command-line arguments.
shim=${GODOT_NOACTIVATE_DYLIB:-$HOME/.local/lib/godot_noactivate.dylib}
if [ "${GODOT_FOREGROUND:-0}" != 1 ] && [ "$headless_run" = 1 ] && [ -f "$shim" ]; then
	export DYLD_INSERT_LIBRARIES="$shim${DYLD_INSERT_LIBRARIES:+:$DYLD_INSERT_LIBRARIES}"
	capped "$@"
fi

# An interactive editor launch is yours; --import/--export are batch jobs.
if [ "${GODOT_FOREGROUND:-0}" = 1 ] \
		|| { [ "$editor" = 1 ] && [ "$scripted" = 0 ]; }; then
	exec "$REAL" "$@"
fi
if [ "$headless" = 1 ]; then
	capped "$@"
fi

[ "$has_mode" = 0 ] && args=(--windowed "${args[@]}")

# Scripted runs stay in the background for their whole lifetime. A normal
# app run must not load the shim: it also prevents the user from focusing
# the window after the initial guard has expired.
if [ -f "$shim" ] && [ "$scripted" = 1 ]; then
	export GODOT_NOACTIVATE_HIDE=1
	export DYLD_INSERT_LIBRARIES="$shim${DYLD_INSERT_LIBRARIES:+:$DYLD_INSERT_LIBRARIES}"
	capped "${args[@]}"
fi

front_field() { lsappinfo info -only "$1" "$(lsappinfo front)" 2>/dev/null; }
prev=$(front_field bundleID | sed -n 's/.*bundleID="\([^"]*\)".*/\1/p')

"$REAL" "${args[@]}" &
pid=$!
trap 'kill -TERM "$pid" 2>/dev/null' INT TERM HUP
[ "$scripted" = 1 ] && watch_memory "$pid"

mine=0
[ -t 0 ] && [ "$scripted" = 0 ] && mine=1

if [ -n "$prev" ] && [ "$mine" = 0 ]; then
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
[ -n "$watch" ] && kill "$watch" 2>/dev/null
exit $rc
