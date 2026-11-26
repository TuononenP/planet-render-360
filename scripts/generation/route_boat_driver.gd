class_name RouteBoatDriver
extends Node

## Drives the route boats of HarbourFerries along their lines. A child of the
## world next to the boats it moves, so a cached world carries it as it
## carries the meshes: the boats (and their wakes) hold a "boat_id" meta, and
## `boats` holds one row each: "id", "pts" (the route, world XZ), "s" (arc
## length where it stands), "lo"/"hi" (the stretch of the route its hull
## stays in open water and clear of the other boats of the line), "dir"
## (+1 along the line, -1 back), "across" (its offset from the line), "speed",
## "y" (the water level) and "length" (m). Optional "accel"/"brake" (m/s2),
## "turn" (rad/s) and "dwell" (s) override the defaults for large ships.
## A boat accelerates to its cruising speed, brakes for the end of its
## stretch, dwells there turning round, and goes back; the wake shows
## while it makes way. Time is the sum of the deltas given to advance(), so a
## test or a capture steps it exactly. Scenery, not live positions.
const ACCEL_MS2 := 0.35
const BRAKE_MS2 := 0.5
const TURN_RAD_S := 0.45
const DWELL_S := 8.0
## Half the chord (m) the heading is read from.
const HEADING_M := 8.0
const MAX_STEP_S := 0.25
## Closer to its stretch's end than this (m) a boat has arrived.
const ARRIVE_M := 0.6
## The wake shows above this speed (m/s).
const WAKE_MS := 0.4

@export var boats: Array = []

var _cum := {}
var _nodes := {}
var _clock := 0.0

func _process(delta: float) -> void:
	var parent := get_parent() as Node3D
	if parent != null and parent.is_visible_in_tree():
		advance(delta)

## Finds each boat's nodes (hull parts and wake) and its route's arc lengths.
func _bind() -> void:
	_cum.clear()
	_nodes.clear()
	for b: Dictionary in boats:
		var pts: PackedVector2Array = b["pts"]
		var cum := PackedFloat32Array([0.0])
		for i in range(1, pts.size()):
			cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
		_cum[int(b["id"])] = cum
		_nodes[int(b["id"])] = []
	var parent := get_parent()
	if parent == null:
		return
	for c in parent.get_children():
		if c is Node3D and c.has_meta("boat_id") and _nodes.has(int(c.get_meta("boat_id"))):
			(_nodes[int(c.get_meta("boat_id"))] as Array).append(c)

## Moves every boat on by `delta` seconds.
func advance(delta: float) -> void:
	if boats.is_empty():
		return
	if _cum.is_empty():
		_bind()
	var left := maxf(delta, 0.0)
	while left > 0.0:
		var dt := minf(left, MAX_STEP_S)
		left -= dt
		_clock += dt
		for b: Dictionary in boats:
			_step(b, dt)
	for b: Dictionary in boats:
		_pose(b)

## Where boat `id` stands (world XZ), or Vector2.INF when it is unknown.
func position_of(id: int) -> Vector2:
	if _cum.is_empty():
		_bind()
	for b: Dictionary in boats:
		if int(b["id"]) == id:
			return _place(b)
	return Vector2.INF

func _step(b: Dictionary, dt: float) -> void:
	var yaw_goal := _heading(b)
	if not b.has("yaw"):
		b["yaw"] = yaw_goal
		b["v"] = 0.0
		b["wait"] = 0.0
	var accel := float(b.get("accel", ACCEL_MS2))
	var brake := float(b.get("brake", BRAKE_MS2))
	var turn_rate := float(b.get("turn", TURN_RAD_S))
	var dwell := float(b.get("dwell", DWELL_S))
	var wait := float(b["wait"])
	if wait > 0.0:
		b["wait"] = wait - dt
		b["v"] = 0.0
	else:
		var dir := float(b["dir"])
		var s := float(b["s"])
		var room := (float(b["hi"]) - s) if dir > 0.0 else (s - float(b["lo"]))
		var v := minf(float(b["v"]) + accel * dt, float(b["speed"]))
		v = minf(v, sqrt(2.0 * brake * maxf(room, 0.0)) + 0.3)
		s += dir * v * dt
		b["s"] = clampf(s, float(b["lo"]), float(b["hi"]))
		b["v"] = v
		if room - v * dt <= ARRIVE_M:
			b["dir"] = -dir
			b["wait"] = dwell
			b["v"] = 0.0
	var turn := wrapf(yaw_goal - float(b["yaw"]), -PI, PI)
	b["yaw"] = float(b["yaw"]) + clampf(turn, -turn_rate * dt, turn_rate * dt)

## The boat's place: the route at `s`, `across` to the side.
func _place(b: Dictionary) -> Vector2:
	var at: Vector2 = _at(b, float(b["s"]))
	var ahead: Vector2 = _at(b, float(b["s"]) + 1.0)
	var line := (ahead - at).normalized() if ahead != at else Vector2.RIGHT
	return at + Vector2(-line.y, line.x) * float(b["across"])

## The travel heading at the boat's place, as a yaw.
func _heading(b: Dictionary) -> float:
	var s := float(b["s"])
	var m := HEADING_M * WorldScale.metres_to_units()
	var d := _at(b, s + m) - _at(b, s - m)
	if d == Vector2.ZERO:
		d = Vector2.RIGHT
	d *= float(b["dir"])
	return atan2(-d.y, d.x)

func _at(b: Dictionary, s: float) -> Vector2:
	var pts: PackedVector2Array = b["pts"]
	var cum: PackedFloat32Array = _cum[int(b["id"])]
	var total := cum[cum.size() - 1]
	s = clampf(s, 0.0, total)
	var i := clampi(cum.bsearch(s) - 1, 0, pts.size() - 2)
	var seg := cum[i + 1] - cum[i]
	return pts[i].lerp(pts[i + 1], (s - cum[i]) / seg if seg > 0.0 else 0.0)

func _pose(b: Dictionary) -> void:
	var p: Vector2 = _place(b)
	var moving := float(b["v"]) > WAKE_MS * WorldScale.metres_to_units()
	for n: Node3D in _nodes.get(int(b["id"]), []):
		n.position = Vector3(p.x, float(b["y"]), p.y)
		n.rotation.y = float(b["yaw"])
		if n.name == &"VesselWake":
			n.visible = moving
