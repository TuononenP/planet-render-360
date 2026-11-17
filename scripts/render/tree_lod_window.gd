class_name TreeLodWindow
extends RefCounted

## Keeps the tree LOD rings (TreeLod) centred on the camera. A world's
## trees are assigned around its build eye; once the camera has moved a
## fraction of the full-mesh radius away (walking, flying, a capture
## teleport), a worker re-assigns them around the camera and the swap
## writes the new MultiMesh buffers into the nodes already there — no
## world rebuild, so the trees near the camera are always full meshes
## rather than far-ring impostors. The writes are spread over frames,
## a species/sector bundle at a time within WRITE_BUDGET_US: in one
## frame they stalled flight for up to ~90 ms while a streamed build
## kept the rendering server busy.

## The camera may move this fraction of the full-mesh radius before the
## rings follow (High: 0.2 x 140 m = 28 m).
const REFRESH_FRAC := 0.2
## Main-thread microseconds a frame for writing the new rings (at least
## one bundle a frame).
const WRITE_BUDGET_US := 1000

var _set: Node3D
var _st: Dictionary
var _centre := Vector2.ZERO
var _task := -1
var _result: Dictionary = {}
## The assignment being written, and its bundles still to write.
var _writing: Dictionary = {}
var _todo: Array = []

## A window over `root`'s tree set; null when the world has none (older
## cached worlds, headless fixtures without trees).
static func attach(root: Node) -> TreeLodWindow:
	if root == null:
		return null
	var s := root.find_child(TreeLod.SET_NAME, true, false) as Node3D
	if s == null or not s.has_meta("tree_lod"):
		return null
	var w := TreeLodWindow.new()
	w._set = s
	w._st = s.get_meta("tree_lod")
	w._centre = s.get_meta("tree_eye", Vector2.ZERO)
	return w

## The eye the current rings are centred on (world units).
func centre() -> Vector2:
	return _centre

## True while a re-assignment is running or still being written.
func busy() -> bool:
	return _task >= 0 or not _todo.is_empty()

func needs_refresh(eye: Vector2) -> bool:
	return eye.distance_to(_centre) > float(_st["full_u"]) * REFRESH_FRAC

## Once a frame: writes part of a finished assignment, takes one that has
## just finished, or starts one if the eye has moved on. `preset` sets
## the written nodes' LodRing range.
func tick(eye: Vector2, preset: int) -> void:
	if not _todo.is_empty():
		_write(preset)
		return
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		if is_instance_valid(_set) and not _result.is_empty():
			_writing = _result
			_todo = TreeLod.bundles(_set, _writing)
			_write(preset)
		_result = {}
		return
	if not is_instance_valid(_set) or not needs_refresh(eye):
		return
	var st := _st
	_task = WorkerThreadPool.add_task(func() -> void: _result = TreeLod.assign(st, eye),
		false, "TreeLod")

## Writes bundles until the frame's share is spent; the rings count as
## moved once the last one is in.
func _write(preset: int) -> void:
	if not is_instance_valid(_set):
		_todo.clear()
		_writing = {}
		return
	var t0 := Time.get_ticks_usec()
	while not _todo.is_empty():
		TreeLod.write_bundle(_set, _st, _writing, _todo.pop_back(), preset)
		if Time.get_ticks_usec() - t0 >= WRITE_BUDGET_US:
			break
	if _todo.is_empty():
		_centre = _writing["eye"]
		_set.set_meta("tree_eye", _centre)
		_writing = {}

## Waits out a running assignment and drops any half-written one (world
## replaced or view closing).
func stop() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	_result = {}
	_todo.clear()
	_writing = {}

## A window dropped mid-assignment still joins its task before it is freed.
func _notification(what: int) -> void:
	# Inline, not stop(): a RefCounted's methods are gone by PREDELETE.
	if what == NOTIFICATION_PREDELETE and _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
