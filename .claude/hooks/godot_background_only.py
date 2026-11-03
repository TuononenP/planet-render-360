#!/usr/bin/env python3
"""PreToolUse hook: refuse Godot runs that block or bypass the wrapper.

Agents must start Godot with run_in_background and through the focus-safe
wrapper (see AGENTS.md): the .app binary, /opt/homebrew/bin/godot and
GODOT_FOREGROUND=1 skip it, and a full-screen launch blacks out the
user's Space. Quick --version/--help/--import calls may block.
"""
import json
import os
import re
import shlex
import sys

QUICK = {"--version", "--help", "-h", "--import"}
BYPASS = ("/opt/homebrew/bin/godot",)
NAMES = {"godot", "godot_bg.sh", "Godot"}

data = json.load(sys.stdin)
if data.get("tool_name") != "Bash":
	sys.exit(0)
inp = data.get("tool_input", {})

for seg in re.split(r"&&|\|\||[;|\n(]", inp.get("command", "")):
	try:
		words = shlex.split(seg)
	except ValueError:
		continue
	env = []
	while words and re.match(r"^\w+=", words[0]):
		env.append(words.pop(0))
	if not words or os.path.basename(words[0]) not in NAMES:
		continue
	if QUICK & set(words):
		continue
	if "GODOT_FOREGROUND=1" in env or words[0] in BYPASS or ".app/" in words[0]:
		print(
			"Launch Godot through the wrapper: plain `godot` or "
			"tools/godot_bg.sh, without GODOT_FOREGROUND or the .app path. "
			"See AGENTS.md.",
			file=sys.stderr,
		)
		sys.exit(2)
	if not inp.get("run_in_background"):
		print(
			"Godot must not run in the foreground. Re-run this Bash call with "
			"run_in_background: true (always with --headless unless the test "
			"needs a window) and check the result when notified. See AGENTS.md.",
			file=sys.stderr,
		)
		sys.exit(2)
