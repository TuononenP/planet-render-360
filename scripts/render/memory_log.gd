class_name MemoryLog
extends Node

## The app's memory in the stream log (WorldStreamer._log), to find what
## runs when iOS ends the app for using too much: it does that with no
## crash report, so the log's last lines are the only record. Checks once
## a second and writes a line when the footprint moved by STEP_BYTES or
## QUIET_S passed; mark() writes one at a moment worth seeing (a world
## cache save starting and ending). Off in headless runs.

const POLL_S := 1.0
const STEP_BYTES := 32 << 20
const QUIET_S := 30.0
const MB := 1 << 20

var _last_bytes := -1
var _last_s := -INF
var _wait := 0.0

func _ready() -> void:
	set_process(DisplayServer.get_name() != "headless")

func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = POLL_S
	var now := Time.get_ticks_msec() / 1000.0
	var bytes := footprint()
	if absi(bytes - _last_bytes) >= STEP_BYTES or now - _last_s >= QUIET_S:
		_last_bytes = bytes
		_last_s = now
		WorldStreamer._log("MEM " + summary())

## Writes the memory now, with what is happening.
static func mark(what: String) -> void:
	if DisplayServer.get_name() != "headless":
		WorldStreamer._log("MEM %s: %s" % [what, summary()])

## The OS footprint in bytes, else Godot's own allocations.
static func footprint() -> int:
	if ClassDB.class_exists("MemoryStats"):
		var b := int(ClassDB.class_call_static("MemoryStats", "footprint_bytes"))
		if b >= 0:
			return b
	return OS.get_static_memory_usage()

## "footprint 2,345 MB, left 1,210 MB, engine 812 MB, video 1,034 MB,
## objects 9262, limit 3,300 MB, headroom 955 MB, tier T1".
static func summary() -> String:
	var parts: Array[String] = []
	var native := ClassDB.class_exists("MemoryStats")
	var foot := int(ClassDB.class_call_static("MemoryStats", "footprint_bytes")) if native else -1
	if foot >= 0:
		parts.append("footprint %s MB" % UiTheme.grouped(foot / MB))
	var left := int(ClassDB.class_call_static("MemoryStats", "available_bytes")) if native else -1
	if left >= 0:
		parts.append("left %s MB" % UiTheme.grouped(left / MB))
	parts.append("engine %s MB" % UiTheme.grouped(OS.get_static_memory_usage() / MB))
	parts.append("video %s MB" % UiTheme.grouped(int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / MB))
	parts.append("objects %d" % int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	parts.append(MemoryBudget.summary(foot))
	return ", ".join(parts)
