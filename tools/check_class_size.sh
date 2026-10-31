#!/bin/sh
# Fails if any class file under scripts/ exceeds the 1000-line budget
# documented in AGENTS.md. Tests and scenes are not classes; only the
# reusable GDScript classes are measured.
set -u
limit=1000
fail=0
max=0
max_file=""
for f in $(find scripts -name '*.gd' | sort); do
	lines=$(wc -l < "$f" | tr -d ' ')
	if [ "$lines" -gt "$max" ]; then
		max=$lines
		max_file=$f
	fi
	if [ "$lines" -gt "$limit" ]; then
		echo "TOO LARGE: $f has $lines lines (limit $limit) — split it into a focused class"
		fail=1
	fi
done
if [ "$fail" -eq 0 ]; then
	echo "CLASS SIZE OK: largest is $max_file at $max/$limit lines"
fi
exit $fail
