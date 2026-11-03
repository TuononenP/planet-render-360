#!/usr/bin/env python3
"""PreToolUse hook: refuse Godot runs that block the foreground.

Agents must start Godot with run_in_background (see AGENTS.md). Quick
--version/--help/--import calls are allowed to block.
"""
import json
import os
import re
import shlex
import sys

QUICK = {"--version", "--help", "-h", "--import"}
NAMES = {"godot", "godot_bg.sh", "Godot"}

data = json.load(sys.stdin)
if data.get("tool_name") != "Bash":
	sys.exit(0)
inp = data.get("tool_input", {})
if inp.get("run_in_background"):
	sys.exit(0)

for seg in re.split(r"&&|\|\||[;|\n(]", inp.get("command", "")):
	try:
		words = shlex.split(seg)
	except ValueError:
		continue
	while words and re.match(r"^\w+=", words[0]):
		words.pop(0)
	if not words or os.path.basename(words[0]) not in NAMES:
		continue
	if QUICK & set(words):
		continue
	print(
		"Godot must not run in the foreground. Re-run this Bash call with "
		"run_in_background: true (always with --headless unless the test "
		"needs a window) and check the result when notified. See AGENTS.md.",
		file=sys.stderr,
	)
	sys.exit(2)
