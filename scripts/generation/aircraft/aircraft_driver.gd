class_name AircraftDriver
extends Node

## Drives live airport & helipad traffic (taxiing, takeoff roll, climb-out,
## final approach, touchdown rollout, and helicopter vertical takeoff/landing).
## Follows the RouteBoatDriver pattern: attached directly to the `AirTraffic`
## subtree with `@export var flights`, so cached worlds preserve it with zero
## wiring in `View360`. Time advances deterministically via `advance(delta)`.

const MAX_STEP_S := 0.15
const GEAR_RETRACT_AGL_M := 25.0
const SHADOW_FADE_AGL_M := 40.0
const APPROACH_DIST_M := 4200.0
const CLIMB_DIST_M := 4500.0
const GLIDE_TAN := 0.0524  # tan(3 deg)
const CLIMB_TAN := 0.1405  # tan(8 deg)
const HELI_HOVER_M := 26.0
const HELI_OUT_M := 2600.0

@export var flights: Array = []

var _nodes: Dictionary = {}      # id -> Node3D
var _rwy_owner: Dictionary = {}  # runway_id -> flight id holding the runway (-1 free)
var _clock := 0.0
var _bound := false

func _process(delta: float) -> void:
	var parent := get_parent() as Node3D
	if parent != null and parent.is_visible_in_tree():
		advance(delta)

func _bind() -> void:
	_bound = true
	_nodes.clear()
	_rwy_owner.clear()
	var parent := get_parent()
	if parent != null:
		for c in parent.get_children():
			if c is Node3D and c.has_meta("flight_id"):
				_nodes[int(c.get_meta("flight_id"))] = c
	for f: Dictionary in flights:
		_init_flight(f)
	# Pre-warm staggered phase offsets so airports open with live activity
	for f: Dictionary in flights:
		var off := float(f.get("phase_offset_s", 0.0))
		if off > 0.0:
			var rem := off
			while rem > 0.0:
				var dt := minf(rem, 0.5)
				rem -= dt
				_step_flight(f, dt)
	for f: Dictionary in flights:
		_apply_pose(f)

## Advances every flight by `delta` seconds deterministically.
func advance(delta: float) -> void:
	if flights.is_empty():
		return
	if not _bound:
		_bind()
	var left := maxf(delta, 0.0)
	while left > 0.0:
		var dt := minf(left, MAX_STEP_S)
		left -= dt
		_clock += dt
		for f: Dictionary in flights:
			_step_flight(f, dt)
	for f: Dictionary in flights:
		_apply_pose(f)

func state_of(id: int) -> String:
	if not _bound:
		_bind()
	for f: Dictionary in flights:
		if int(f["id"]) == id:
			return str(f.get("state", ""))
	return ""

func position_of(id: int) -> Vector3:
	if not _bound:
		_bind()
	for f: Dictionary in flights:
		if int(f["id"]) == id:
			return f.get("pos", Vector3.ZERO)
	return Vector3.ZERO

func _init_flight(f: Dictionary) -> void:
	if f.has("state"):
		return
	var mode := str(f.get("mode", "departure"))
	f["rotor_ang"] = 0.0
	f["rotor_rpm"] = 0.0
	f["pitch"] = 0.0
	f["bank"] = 0.0
	f["visible"] = true
	if mode == "helicopter":
		var pad: Vector3 = f["pad_pos"]
		f["state"] = "IDLE_PAD"
		f["t"] = 0.0
		f["pos"] = pad
		f["yaw"] = float(f.get("heading", 0.0))
		f["agl"] = 0.0
		return
	var rwy_a: Vector2 = f["rwy_a"]
	var rwy_b: Vector2 = f["rwy_b"]
	var rwy_dir := (rwy_b - rwy_a).normalized()
	f["rwy_dir"] = rwy_dir
	f["rwy_len"] = rwy_a.distance_to(rwy_b)
	f["yaw"] = atan2(rwy_dir.y, rwy_dir.x)
	f["speed"] = 0.0
	f["s"] = 0.0
	f["agl"] = 0.0
	var taxi: PackedVector2Array = f.get("taxi_pts", PackedVector2Array())
	f["taxi_len"] = _poly_len(taxi)
	if mode == "departure":
		if taxi.size() >= 2:
			f["state"] = "TAXI_OUT"
			f["pos"] = Vector3(taxi[0].x, float(f["rwy_y"]), taxi[0].y)
		else:
			f["state"] = "HOLD_SHORT"
			f["pos"] = Vector3(rwy_a.x, float(f["rwy_y"]), rwy_a.y)
	else:
		f["state"] = "APPROACH"
		var start := rwy_a - rwy_dir * APPROACH_DIST_M
		f["s"] = -APPROACH_DIST_M
		f["agl"] = APPROACH_DIST_M * GLIDE_TAN
		f["pos"] = Vector3(start.x, float(f["rwy_y"]) + float(f["agl"]), start.y)

func _claim_runway(rwy_id: int, fid: int) -> bool:
	var cur := int(_rwy_owner.get(rwy_id, -1))
	if cur == -1 or cur == fid:
		_rwy_owner[rwy_id] = fid
		return true
	return false

func _release_runway(rwy_id: int, fid: int) -> void:
	if int(_rwy_owner.get(rwy_id, -1)) == fid:
		_rwy_owner[rwy_id] = -1

func _step_flight(f: Dictionary, dt: float) -> void:
	var mode := str(f["mode"])
	if mode == "helicopter":
		_step_helicopter(f, dt)
		return
	var fid := int(f["id"])
	var rwy_id := int(f["runway_id"])
	var sp := AircraftSpecs.spec(str(f["kind"]))
	var rwy_a: Vector2 = f["rwy_a"]
	var rwy_dir: Vector2 = f["rwy_dir"]
	var rwy_len := float(f["rwy_len"])
	var rwy_y := float(f["rwy_y"])
	var taxi: PackedVector2Array = f.get("taxi_pts", PackedVector2Array())
	var state := str(f["state"])

	match state:
		"TAXI_OUT":
			var spd := float(sp["taxi_ms"])
			f["s"] = float(f["s"]) + spd * dt
			var tlen := float(f["taxi_len"])
			if float(f["s"]) >= tlen:
				f["s"] = 0.0
				f["state"] = "HOLD_SHORT"
			else:
				var sample := _sample_poly(taxi, float(f["s"]))
				f["pos"] = Vector3(sample["p"].x, rwy_y, sample["p"].y)
				f["yaw"] = atan2(sample["d"].y, sample["d"].x)
				f["pitch"] = 0.0
				f["agl"] = 0.0
		"HOLD_SHORT":
			f["pos"] = Vector3(rwy_a.x, rwy_y, rwy_a.y)
			f["yaw"] = atan2(rwy_dir.y, rwy_dir.x)
			f["pitch"] = 0.0
			f["agl"] = 0.0
			if _claim_runway(rwy_id, fid):
				f["state"] = "TAKEOFF_ROLL"
				f["speed"] = 4.0
				f["s"] = 0.0
		"TAKEOFF_ROLL":
			var v := float(f["speed"]) + float(sp["accel_ms2"]) * dt
			var vr := float(sp["takeoff_ms"])
			var s := float(f["s"]) + v * dt
			f["speed"] = v
			f["s"] = s
			var p2 := rwy_a + rwy_dir * s
			f["pos"] = Vector3(p2.x, rwy_y, p2.y)
			f["yaw"] = atan2(rwy_dir.y, rwy_dir.x)
			f["agl"] = 0.0
			# Gentle rotation right before liftoff
			f["pitch"] = deg_to_rad(float(sp["rotate_deg"])) * clampf((v - vr * 0.85) / (vr * 0.15), 0.0, 1.0)
			if v >= vr or s >= rwy_len * 0.85:
				f["state"] = "CLIMB"
				f["climb_s"] = 0.0
		"CLIMB":
			var v := minf(float(f["speed"]) + 1.5 * dt, float(sp["climb_ms"]))
			var cs := float(f["climb_s"]) + v * dt
			var s := float(f["s"]) + v * dt
			var agl := cs * CLIMB_TAN
			f["speed"] = v
			f["climb_s"] = cs
			f["s"] = s
			f["agl"] = agl
			if agl > 35.0:
				_release_runway(rwy_id, fid)
			var p2 := rwy_a + rwy_dir * s
			f["pos"] = Vector3(p2.x, rwy_y + agl, p2.y)
			f["yaw"] = atan2(rwy_dir.y, rwy_dir.x)
			f["pitch"] = deg_to_rad(float(sp["rotate_deg"]) * 0.78)
			if cs >= CLIMB_DIST_M:
				_release_runway(rwy_id, fid)
				f["s"] = 0.0
				f["agl"] = 0.0
				f["pitch"] = 0.0
				f["state"] = "TAXI_OUT" if taxi.size() >= 2 else "HOLD_SHORT"
		"APPROACH":
			var v := float(sp["approach_ms"])
			var s := float(f["s"])
			# Claim runway before entering short final; hold at 1200 m if busy
			if s < -1200.0 or _claim_runway(rwy_id, fid):
				s += v * dt
				f["s"] = s
				f["visible"] = true
			else:
				f["visible"] = false
			var agl := maxf(-s * GLIDE_TAN, 0.0)
			f["agl"] = agl
			var p2 := rwy_a + rwy_dir * s
			f["pos"] = Vector3(p2.x, rwy_y + agl, p2.y)
			f["yaw"] = atan2(rwy_dir.y, rwy_dir.x)
			# Flare right above touchdown
			f["pitch"] = deg_to_rad(3.5) if agl < 15.0 else deg_to_rad(-2.5)
			if s >= 60.0:
				f["state"] = "ROLLOUT"
				f["speed"] = v
				f["agl"] = 0.0
		"ROLLOUT":
			var taxi_v := float(sp["taxi_ms"])
			var v := maxf(float(f["speed"]) - float(sp["brake_ms2"]) * dt, taxi_v)
			var s := float(f["s"]) + v * dt
			f["speed"] = v
			f["s"] = s
			f["agl"] = 0.0
			f["pitch"] = 0.0
			var p2 := rwy_a + rwy_dir * s
			f["pos"] = Vector3(p2.x, rwy_y, p2.y)
			f["yaw"] = atan2(rwy_dir.y, rwy_dir.x)
			if s >= rwy_len * 0.92 or (v <= taxi_v + 0.2 and s >= rwy_len * 0.55):
				_release_runway(rwy_id, fid)
				f["s"] = 0.0
				f["state"] = "TAXI_IN" if taxi.size() >= 2 else "DWELL"
				f["dwell"] = 6.0
		"TAXI_IN":
			var spd := float(sp["taxi_ms"])
			f["s"] = float(f["s"]) + spd * dt
			var tlen := float(f["taxi_len"])
			if float(f["s"]) >= tlen:
				f["state"] = "DWELL"
				f["dwell"] = 8.0
			else:
				var sample := _sample_poly(taxi, float(f["s"]))
				f["pos"] = Vector3(sample["p"].x, rwy_y, sample["p"].y)
				f["yaw"] = atan2(sample["d"].y, sample["d"].x)
				f["pitch"] = 0.0
				f["agl"] = 0.0
		"DWELL":
			f["dwell"] = float(f.get("dwell", 0.0)) - dt
			if float(f["dwell"]) <= 0.0:
				f["state"] = "APPROACH"
				f["s"] = -APPROACH_DIST_M
				f["agl"] = APPROACH_DIST_M * GLIDE_TAN
				f["visible"] = true

func _step_helicopter(f: Dictionary, dt: float) -> void:
	var pad: Vector3 = f["pad_pos"]
	var out_dir: Vector2 = f["out_dir"]
	var state := str(f["state"])
	f["t"] = float(f.get("t", 0.0)) + dt
	var t := float(f["t"])
	var rpm := float(f.get("rotor_rpm", 0.0))

	match state:
		"IDLE_PAD":
			rpm = maxf(rpm - 0.5 * dt, 0.0)
			f["pos"] = pad
			f["agl"] = 0.0
			f["pitch"] = 0.0
			if t >= 10.0:
				f["state"] = "SPOOL_UP"
				f["t"] = 0.0
		"SPOOL_UP":
			rpm = minf(rpm + 0.28 * dt, 1.0)
			f["pos"] = pad
			f["agl"] = 0.0
			f["pitch"] = 0.0
			if rpm >= 1.0 and t >= 4.0:
				f["state"] = "HOVER_CLIMB"
				f["t"] = 0.0
		"HOVER_CLIMB":
			rpm = 1.0
			var agl := minf(t * 5.2, HELI_HOVER_M)
			f["agl"] = agl
			f["pos"] = Vector3(pad.x, pad.y + agl, pad.z)
			f["yaw"] = atan2(out_dir.y, out_dir.x)
			f["pitch"] = 0.0
			if agl >= HELI_HOVER_M:
				f["state"] = "HELI_OUT"
				f["t"] = 0.0
		"HELI_OUT":
			rpm = 1.0
			var dist := t * 38.0
			var agl := HELI_HOVER_M + dist * 0.10
			f["agl"] = agl
			f["pos"] = Vector3(pad.x + out_dir.x * dist, pad.y + agl, pad.z + out_dir.y * dist)
			f["yaw"] = atan2(out_dir.y, out_dir.x)
			f["pitch"] = deg_to_rad(-8.0)  # nose-down forward flight tilt
			if dist >= HELI_OUT_M:
				f["state"] = "HELI_APPROACH"
				f["t"] = 0.0
		"HELI_APPROACH":
			rpm = 1.0
			var dist := maxf(HELI_OUT_M - t * 34.0, 0.0)
			var agl := HELI_HOVER_M + dist * 0.10
			f["agl"] = agl
			f["pos"] = Vector3(pad.x + out_dir.x * dist, pad.y + agl, pad.z + out_dir.y * dist)
			f["yaw"] = atan2(-out_dir.y, -out_dir.x)
			f["pitch"] = deg_to_rad(5.0) if dist < 140.0 else deg_to_rad(-5.0)
			if dist <= 1.0:
				f["state"] = "HOVER_DESCEND"
				f["t"] = 0.0
		"HOVER_DESCEND":
			rpm = 1.0
			var agl := maxf(HELI_HOVER_M - t * 4.5, 0.0)
			f["agl"] = agl
			f["pos"] = Vector3(pad.x, pad.y + agl, pad.z)
			f["pitch"] = 0.0
			if agl <= 0.05:
				f["state"] = "IDLE_PAD"
				f["t"] = 0.0

	f["rotor_rpm"] = rpm
	f["rotor_ang"] = fmod(float(f.get("rotor_ang", 0.0)) + rpm * 22.0 * dt, TAU)

func _apply_pose(f: Dictionary) -> void:
	var node: Node3D = _nodes.get(int(f["id"]), null)
	if node == null:
		return
	node.visible = bool(f.get("visible", true))
	if not node.visible:
		return
	var pos: Vector3 = f.get("pos", Vector3.ZERO)
	var yaw := float(f.get("yaw", 0.0))
	var pitch := float(f.get("pitch", 0.0))
	# Model frame: +X nose, +Y up, +Z right wing.
	# Heading `yaw` in XZ plane (0 -> +X, +PI/2 -> +Z) = rotation around Y by -yaw.
	# Positive pitch (nose up) = rotation around local Z by +pitch.
	var basis := Basis(Vector3.UP, -yaw) * Basis(Vector3.BACK, pitch)
	node.transform = Transform3D(basis, pos)

	var agl := float(f.get("agl", 0.0))
	var gear := node.get_node_or_null("Gear") as Node3D
	if gear != null:
		gear.visible = agl < GEAR_RETRACT_AGL_M

	var shadow := node.get_node_or_null("Shadow") as Node3D
	if shadow != null:
		shadow.visible = agl < SHADOW_FADE_AGL_M
		if shadow.visible:
			shadow.position.y = -agl + 0.06

	if str(f["mode"]) == "helicopter":
		var rpm := float(f.get("rotor_rpm", 0.0))
		var ang := float(f.get("rotor_ang", 0.0))
		var mr := node.get_node_or_null("MainRotor") as Node3D
		if mr != null:
			mr.rotation.y = ang
		var tr := node.get_node_or_null("TailRotor") as Node3D
		if tr != null:
			tr.rotation.z = ang * 3.5
		var disc := node.get_node_or_null("RotorDisc") as Node3D
		if disc != null:
			disc.visible = rpm > 0.65

static func _poly_len(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in range(1, pts.size()):
		s += pts[i].distance_to(pts[i - 1])
	return s

static func _sample_poly(pts: PackedVector2Array, dist: float) -> Dictionary:
	var acc := 0.0
	for i in range(1, pts.size()):
		var seg := pts[i].distance_to(pts[i - 1])
		if seg < 0.01:
			continue
		if acc + seg >= dist or i == pts.size() - 1:
			var t := clampf((dist - acc) / seg, 0.0, 1.0)
			return {
				"p": pts[i - 1].lerp(pts[i], t),
				"d": (pts[i] - pts[i - 1]) / seg,
			}
		acc += seg
	return {"p": pts[0], "d": Vector2.RIGHT}
