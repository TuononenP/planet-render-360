class_name BuildingBasement
extends RefCounted

## What the foundation wall of a house on a steep street shows. Where the
## hill lifts a building's floor by more than a basement window's height,
## the plinth is a storey of its own: small lights along the downhill
## wall, a garage or cellar door where the ground is level enough, and on
## the tallest walls a second row of windows above.

## Visible wall (floor line down to the ground) needed for each opening.
const WINDOW_MIN_M := 1.9
const DOOR_MIN_M := 2.8
const UPPER_MIN_M := 4.2
## Openings sit in slots this far apart, this far in from the corners.
const SLOT_M := 3.4
const INSET_M := 1.0
const EDGE_MIN_M := 3.0
## Odds that a wall gets doors, every DOOR_EVERY slots, and the ground a door's width may span.
const DOOR_ODDS := 0.8
const DOOR_EVERY := 3
const DOOR_SLOPE_M := 0.9
const DOOR_W_M := 2.6
const DOOR_H_M := 2.3
const LIGHT_W_M := 1.2
const LIGHT_H_M := 0.8
const LIGHT_SILL_M := 0.9
const UPPER_H_M := 1.0
const UPPER_SILL_M := 2.8
## Surround around an opening, and how far each layer stands off the wall.
const SURROUND_M := 0.12
const FRAME_OFFSET_M := 0.02
const PANE_OFFSET_M := 0.05
const DOOR_COLOURS: Array[Color] = [Color("#5b3f2c"), Color("#3f5a4a"),
	Color("#7a7d80"), Color("#e4e0d6")]
static var _mats: Dictionary = {}

static func _mat(key: String, colour: Color, rough: float) -> Material:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = colour
		m.roughness = rough
		m.metallic_specular = 0.3
		_mats[key] = m
	return _mats[key]

## Openings on the plinth of `ring` (outer ring only), downhill walls that
## no neighbour covers (`party`, per edge, may be empty).
static func dress(root: Node3D, ring: PackedVector2Array, footing: Dictionary,
		ground: GroundTruth, party: PackedByteArray = PackedByteArray()) -> void:
	var m := WorldScale.metres_to_units()
	var y1 := float(footing["floor"]) - BuildingFoundation.SINK_M * m
	if float(footing.get("plinth", 0.0)) / m - BuildingFoundation.SINK_M < WINDOW_MIN_M:
		return
	var ccw := RingGeometry.signed_area(ring) > 0.0
	var frames := _arrays()
	var panes := _arrays()
	var doors: Array = []
	for _i in DOOR_COLOURS.size():
		doors.append(_arrays())
	for i in ring.size():
		if party.size() == ring.size() and party[i] == 1:
			continue
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < EDGE_MIN_M * m:
			continue
		var dir := (b - a) / length
		var n := Vector2(dir.y, -dir.x) if ccw else Vector2(-dir.y, dir.x)
		var count := floori((length / m - 2.0 * INSET_M) / SLOT_M)
		if count < 1:
			continue
		# A door in every third slot, the first at a place the wall picks.
		var door_phase := int(TerrainBuilder._hash(a.y + 7.3, a.x - 1.1) * float(DOOR_EVERY))
		var doors_here := TerrainBuilder._hash(a.x * 1.7 + 3.1, a.y * 2.3 - 5.9) < DOOR_ODDS
		var first := (length / m - float(count - 1) * SLOT_M) * 0.5
		for s in count:
			var c := a + dir * ((first + float(s) * SLOT_M) * m)
			var reach := dir * (DOOR_W_M * 0.5 * m)
			var low := minf(ground.height_at_world(c.x, c.y),
				minf(ground.height_at_world(c.x - reach.x, c.y - reach.y),
				ground.height_at_world(c.x + reach.x, c.y + reach.y)))
			var high := maxf(ground.height_at_world(c.x - reach.x, c.y - reach.y),
				ground.height_at_world(c.x + reach.x, c.y + reach.y))
			var wall_m := (y1 - low) / m
			if wall_m < WINDOW_MIN_M:
				continue
			var mid := ground.height_at_world(c.x, c.y)
			var colour := int(TerrainBuilder._hash(c.x * 3.3, c.y * 1.9) * float(DOOR_COLOURS.size())) % DOOR_COLOURS.size()
			if doors_here and (s + door_phase) % DOOR_EVERY == 0 and wall_m >= DOOR_MIN_M and (high - low) / m <= DOOR_SLOPE_M:
				_opening(frames, doors[colour], c, dir, n, DOOR_W_M, low, low + DOOR_H_M * m, false)
			else:
				var sill := mid + LIGHT_SILL_M * m
				_opening(frames, panes, c, dir, n, LIGHT_W_M, sill, sill + LIGHT_H_M * m, true)
			if wall_m >= UPPER_MIN_M:
				var up := mid + UPPER_SILL_M * m
				_opening(frames, panes, c, dir, n, LIGHT_W_M, up, up + UPPER_H_M * m, true)
	BuildingWalls._emit(root, frames, _mat("frame", Color("#76726b"), 0.8))
	BuildingWalls._emit(root, panes, _mat("glass", Color("#1d2a33"), 0.15))
	for k in DOOR_COLOURS.size():
		BuildingWalls._emit(root, doors[k], _mat("door%d" % k, DOOR_COLOURS[k], 0.7))

static func _arrays() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]

## A surround and its pane (or door leaf) on the wall at `c`; a door's
## surround has no sill.
static func _opening(frame: Array, pane: Array, c: Vector2, dir: Vector2, n: Vector2,
		width_m: float, y0: float, y1: float, sill: bool) -> void:
	var m := WorldScale.metres_to_units()
	var s := SURROUND_M * m
	_rect(frame, c, dir, n, width_m * m + 2.0 * s, y0 - (s if sill else 0.0), y1 + s, FRAME_OFFSET_M * m)
	_rect(pane, c, dir, n, width_m * m, y0, y1, PANE_OFFSET_M * m)

static func _rect(arr: Array, c: Vector2, dir: Vector2, n: Vector2, width: float,
		y0: float, y1: float, off: float) -> void:
	var at := c + n * off
	BuildingWalls._quad(arr, at - dir * width * 0.5, at + dir * width * 0.5, y0, y1, n,
		Vector2(1.0, 1.0))
