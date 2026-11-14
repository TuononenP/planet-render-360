class_name RevealWave
extends RefCounted

## Endless walk & fly: after a streamed swap, the ground that is new (past
## the old world's square) fades in from the camera outward instead of
## appearing all at once. Each new piece small enough to range (building
## cells, trees, props: LodRing.MAX_RANGED_SIZE_M) gets a temporary
## visibility range end that grows at SPEED_MPS with the renderer's
## dithered fade (VISIBILITY_RANGE_FADE_SELF); once the wave has passed a
## piece it gets its own LodRing range back. Terrain, roads and water are
## single large meshes and switch at the swap (the same ground, finer).
##
## The pieces are found while the world waits staged (prepare, then pump
## a subtree at a time), so the swap frame only sets their ranges.

const SPEED_MPS := 900.0
const MARGIN_M := 200.0
## Layers that never fade in: whole bands or rings (LodRing ranges them
## by its own rules) and the water sheet.
const SKIP_LAYERS := ["FarCity", "FarTerrain", "Water"]

var _world: Node3D
## The old square's centre in the new world's frame.
var _old_centre := Vector2.ZERO
var _cursor := 0
## [GeometryInstance3D, layer] per new piece, then sorted by distance.
var _pieces: Array = []
var _radius := 0.0
## Where the camera stood at the swap: the wave spreads from here, so the
## nearest-first order of _pieces holds however the camera moves on.
var _origin := Vector2.ZERO
var _running := false
var _preset := 0

func active() -> bool:
	return _running

## Starts finding `world`'s new pieces; `old_centre` is where the old
## square's centre lies in `world`'s frame.
func prepare(world: Node3D, old_centre: Vector2) -> void:
	finish(_preset)  # a wave still running hands its pieces back first
	_world = world
	_old_centre = old_centre
	_cursor = 0
	_pieces.clear()

## Whether `world` is the one being prepared and every subtree is walked.
func prepared(world: Node3D) -> bool:
	return world != null and _world == world and _cursor >= world.get_child_count()

## Walks at least one more top-level subtree, and more within `budget_us`.
func pump(budget_us: int = 1000) -> void:
	if _world == null or not is_instance_valid(_world) or _running:
		return
	var t := Time.get_ticks_usec()
	var first := _cursor
	while _cursor < _world.get_child_count() \
			and (_cursor == first or Time.get_ticks_usec() - t < budget_us):
		var c := _world.get_child(_cursor)
		_collect(c, str(c.get_meta("lod_layer", c.name)), Transform3D.IDENTITY)
		_cursor += 1

## `parent_xf`: the world-frame transform of `node`'s parent.
func _collect(node: Node, layer: String, parent_xf: Transform3D) -> void:
	var l := str(node.get_meta("lod_layer", layer))
	if l in SKIP_LAYERS:
		return
	var xf := parent_xf * (node as Node3D).transform if node is Node3D else parent_xf
	if node is GeometryInstance3D and not node.has_meta("lod_own"):
		var gi := node as GeometryInstance3D
		var box := xf * gi.get_aabb()
		if maxf(box.size.x, box.size.z) <= LodRing.MAX_RANGED_SIZE_M:
			var c := box.get_center()
			if not WorldStreamer.inside_detailed(Vector2(c.x, c.z) - _old_centre):
				_pieces.append([gi, l, Vector2(c.x, c.z)])
	for ch in node.get_children():
		_collect(ch, l, xf)

## The swap happened with the camera at `eye` (the new frame): hide the
## new pieces past the nearest one and start the wave there.
func start(world: Node3D, eye: Vector2, preset: int) -> void:
	_preset = preset
	if world != _world or world == null:
		stop()
		return
	pump(1 << 30)
	_pieces.sort_custom(func(a: Array, b: Array) -> bool:
		return eye.distance_squared_to(a[2]) < eye.distance_squared_to(b[2]))
	if _pieces.is_empty():
		stop()
		return
	_origin = eye
	_radius = maxf(eye.distance_to(_pieces[0][2]) - MARGIN_M, 0.0)
	for p in _pieces:
		var gi: GeometryInstance3D = p[0]
		gi.visibility_range_begin = 0.0
		gi.visibility_range_end = _radius + MARGIN_M
		gi.visibility_range_end_margin = MARGIN_M
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_cursor = 0
	_running = true

## Grows the wave and hands each piece it passed back to LodRing.
func tick(_eye: Vector2, delta: float, preset: int) -> void:
	if not _running:
		return
	_preset = preset
	if _world == null or not is_instance_valid(_world):
		stop()
		return
	_radius += SPEED_MPS * delta
	var end := _radius + MARGIN_M
	while _cursor < _pieces.size():
		var p: Array = _pieces[_cursor]
		if _origin.distance_to(p[2]) > _radius - MARGIN_M:
			break
		if is_instance_valid(p[0]):
			LodRing.range_one(p[0], preset, p[1])
		_cursor += 1
	# Only the band the wave is crossing needs its end moved: pieces past
	# it are still hidden by the end they got at start (nearest first).
	for i in range(_cursor, _pieces.size()):
		var p: Array = _pieces[i]
		if _origin.distance_to(p[2]) > end + MARGIN_M:
			break
		if is_instance_valid(p[0]):
			(p[0] as GeometryInstance3D).visibility_range_end = end
	if _cursor >= _pieces.size():
		stop()

## Ends the wave at once: every piece not yet passed gets its own range.
func finish(preset: int) -> void:
	if _running:
		for i in range(_cursor, _pieces.size()):
			if is_instance_valid(_pieces[i][0]):
				LodRing.range_one(_pieces[i][0], preset, _pieces[i][1])
	stop()

## Stops preparing or running for `world` only (a staged world dropped).
func forget(world: Node3D) -> void:
	if world == _world:
		finish(_preset)

func stop() -> void:
	_running = false
	_world = null
	_pieces.clear()
	_cursor = 0
