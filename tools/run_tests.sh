#!/bin/bash
# Runs every headless test in tests/ and reports which fail.
#
#   tools/run_tests.sh                run them all
#   tools/run_tests.sh osm search     only tests whose name contains a word
#
# GODOT picks the binary (default: `godot` on PATH; locally that is the
# no-activation wrapper, see tools/godot_bg.sh). Each test gets
# TEST_TIMEOUT seconds (default 300) before it is killed and counted as
# failed. A test also fails when its log holds a "SCRIPT ERROR:" line, even
# if it exited 0. Logs of failing tests are kept in TEST_LOG_DIR
# (default: a fresh temp directory, printed at the end).
#
# Skipped: tests that need a real window, and tests that call live
# network services. Run those by hand; the README lists them.
# Exit status is 1 when any test fails.

set -u
cd "$(dirname "$0")/.."

GODOT=${GODOT:-godot}
LIMIT=${TEST_TIMEOUT:-300}
LOGS=${TEST_LOG_DIR:-$(mktemp -d)}
mkdir -p "$LOGS"

# Window needed: the headless dummy renderer cannot draw.
WINDOWED="screenshot_test world_cache_test panorama_render_test"
# Live services: results depend on the network and on rate limits.
NETWORK="dem_test fidelity_scorecard_test preset_snapshot_test"
SKIP=" $WINDOWED $NETWORK "

pass=0
fail=0
skipped=0
failed=()

for file in tests/*_test.gd; do
	name=$(basename "$file" .gd)
	if [ "$#" -gt 0 ]; then
		match=0
		for word in "$@"; do
			case "$name" in *"$word"*) match=1 ;; esac
		done
		[ "$match" = 1 ] || continue
	fi
	case "$SKIP" in *" $name "*) skipped=$((skipped + 1)); continue ;; esac

	log="$LOGS/$name.log"
	"$GODOT" --headless --path . --script "$file" > "$log" 2>&1 &
	pid=$!
	# macOS has no `timeout`: a watchdog kills a test that runs too long.
	# It takes its sleep down with it, so nothing keeps our stdout open.
	(
		sleep "$LIMIT" &
		nap=$!
		trap 'kill "$nap" 2>/dev/null; exit 0' TERM
		wait "$nap"
		kill "$pid" 2>/dev/null
	) > /dev/null 2>&1 &
	watchdog=$!
	wait "$pid"
	rc=$?
	kill "$watchdog" 2>/dev/null
	wait "$watchdog" 2>/dev/null

	# A script that fails to compile, or hits a runtime error, can still
	# exit 0 (and even print its OK line), so the log is checked as well.
	why="exit $rc"
	if [ "$rc" -eq 0 ] && grep -q 'SCRIPT ERROR:' "$log"; then
		rc=1
		why="script errors in the log"
	fi

	if [ "$rc" -eq 0 ]; then
		pass=$((pass + 1))
		rm -f "$log"
	else
		fail=$((fail + 1))
		failed+=("$name ($why)")
		echo "FAIL $name ($why)"
	fi
done

echo "TESTS: $pass passed, $fail failed, $skipped skipped"
if [ "$fail" -gt 0 ]; then
	printf '  %s\n' "${failed[@]}"
	echo "Logs: $LOGS"
	exit 1
fi
exit 0
