extends SceneTree

## Shutdown guard: godot --headless --script tests/shutdown_guard_test.gd
## Background work or a raw network handle that outlives its owner aborts
## the engine on quit ("Pure virtual function called"): a bare HTTPClient
## left its DNS lookup queued on the resolver thread after IP was torn
## down, and map_pan/zoom_search printed OK, then exited 134. HTTPRequest
## closes itself on exit tree; nothing else here does. This test fails if
## a script under scripts/ creates one of these without its teardown:
##  - HTTPClient / StreamPeerTCP / StreamPeerTLS / WebSocketPeer: closed
##    on NOTIFICATION_PREDELETE
##  - Thread: joined (wait_to_finish)
##  - WorkerThreadPool task: waited for, and on NOTIFICATION_PREDELETE
##  - HTTPRequest: parented (add_child), so exit tree cancels it
## Fork-join scripts (JOINED_IN_CALL) wait for every task they add before
## the adding call returns, so no task can outlive a caller to need the
## PREDELETE join; they must still wait (wait_for_).

## [creates, required tokens (all), what is missing]
const RULES := [
	[["HTTPClient.new()", "StreamPeerTCP.new()", "StreamPeerTLS.new()", "WebSocketPeer.new()"],
		["NOTIFICATION_PREDELETE", ".close()"], "close it on NOTIFICATION_PREDELETE"],
	[["Thread.new()"], ["wait_to_finish("], "join it with wait_to_finish()"],
	[["WorkerThreadPool.add_task(", "WorkerThreadPool.add_group_task("],
		["wait_for_", "NOTIFICATION_PREDELETE"], "wait for the task, also on NOTIFICATION_PREDELETE"],
	[["HTTPRequest.new()"], ["add_child("], "add_child() it so exit tree cancels it"],
]
const JOINED_IN_CALL := ["res://scripts/generation/world_build_graph.gd",
	"res://scripts/generation/road_builder.gd", "res://scripts/data/ground_tiff.gd"]

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var files: Array[String] = []
	_collect("res://scripts", files)
	var guarded := 0
	for path in files:
		var code := _code_of(path)
		for rule: Array in RULES:
			var creates: Array = rule[0]
			if not creates.any(func(c: String) -> bool: return code.contains(c)):
				continue
			guarded += 1
			for need: String in rule[1]:
				if need == "NOTIFICATION_PREDELETE" and path in JOINED_IN_CALL:
					continue
				if not code.contains(need):
					failures.append("%s creates %s but lacks %s: %s"
						% [path, "/".join(creates), need, rule[2]])
	if files.is_empty():
		failures.append("no scripts found under res://scripts")
	if failures.is_empty():
		print("SHUTDOWN GUARD OK: %d threaded/network owners in %d scripts all tear down" % [guarded, files.size()])
		quit(0)
	else:
		for f in failures:
			printerr("SHUTDOWN GUARD FAIL: ", f)
		quit(1)

## Source without comment lines, so a doc comment naming a class neither
## trips nor satisfies a rule.
func _code_of(path: String) -> String:
	var out := PackedStringArray()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if not line.strip_edges().begins_with("#"):
			out.append(line)
	return "\n".join(out)

func _collect(dir_path: String, files: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			_collect(full, files)
		elif entry.ends_with(".gd"):
			files.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
