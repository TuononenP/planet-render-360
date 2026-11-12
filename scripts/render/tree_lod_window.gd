class_name TreeLodWindow
extends RefCounted

## Keeps the tree LOD rings (TreeLod) centred on the camera. A world's
## trees are assigned around its build eye; once the camera has moved a
## fraction of the full-mesh radius away (walking, flying, a capture
## teleport), a worker re-assigns them around the camera and the swap
## writes one MultiMesh buffer per species/LOD/sector group — no world
## rebuild, so the trees near the camera are always full meshes rather
## than far-ring impostors.

## The camera may move this fraction of the full-mesh radius before the
## rings follow (High: 0.2 x 140 m = 28 m).
const REFRESH_FRAC := 0.2

var _set: Node3D
var _st: Dictionary
var _centre := Vector2.ZERO
var _task := -1
var _result: Dictionary = {}

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

## True while a re-assignment is running.
func busy() -> bool:
	return _task >= 0

func needs_refresh(eye: Vector2) -> bool:
	return eye.distance_to(_centre) > float(_st["full_u"]) * REFRESH_FRAC

## Once a frame: swaps in a finished assignment, or starts one if the
## eye has moved on. `preset` sets the swapped nodes' LodRing range.
func tick(eye: Vector2, preset: int) -> void:
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		if is_instance_valid(_set) and not _result.is_empty():
			TreeLod.emit(_set, _st, _result, preset)
			_centre = _result["eye"]
		_result = {}
		return
	if not is_instance_valid(_set) or not needs_refresh(eye):
		return
	var st := _st
	_task = WorkerThreadPool.add_task(func() -> void: _result = TreeLod.assign(st, eye),
		false, "TreeLod")

## Waits out a running assignment (world replaced or view closing).
func stop() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	_result = {}
