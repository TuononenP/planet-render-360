class_name ViewWalk
extends RefCounted

## On foot inside the built area: the eye stands EYE_M over the ground
## and walks at a walker's pace. Hold W A S D (arrows keep looking) to
## walk and Shift to run, or on a touch screen push the left stick to walk
## and the right one sideways to turn (DroneSticks); tap or click the
## ground to glide there. Buildings are solid: a step into one slides
## along its wall, and a tap or a drone landing inside one sets down at
## the nearest open ground. Climbing is the drone's. All of it stays
## within View360.can_move_in_place, where the buildings and trees still
## surround the camera; farther places are for Go there. One instance per
## view holds the walking state; the ray march, the glide, the footing
## and the tap rules are static so tests can drive them.

## Eye over the ground, walking pace (m/s) and the Shift run multiplier.
const EYE_M := 1.7
const WALK_MPS := 4.0
const RUN_MULT := 2.5
## How close (metres) the eye may come to a wall, and how far from a
## spot inside a building the open ground is looked for.
const BODY_M := 0.5
const FREE_SEARCH_M := 120.0
## Water shallower than this (metres) is ground a walker is set down on.
const DRY_M := 0.2
## Buildings within reach are re-gathered once the walker has gone this
## far from where they last were.
const NEAR_REFRESH_M := 20.0
## A press that stays within TAP_MAX_PX and TAP_MAX_S is a tap; it acts
## after TAP_WAIT_S so a double click (reset zoom) cancels it.
const TAP_MAX_PX := 8.0
const TAP_MAX_S := 0.35
const TAP_WAIT_S := 0.28
const MAX_RAY_M := 1500.0
const GLIDE_MIN_S := 0.6
const GLIDE_MAX_S := 2.2

var _tap_at := Vector2.ZERO
var _tap_ms := -1
var _tap_seq := 0
var _moving := false
var _near: Array = []
var _near_at := Vector2.INF
var _spans := PackedVector3Array()
var _spans_for: LocationData
## Touch stick deflection (DroneSticks), -1..1 in screen axes:
## `stick_move` walks (up is forward), `stick_aux` x turns.
var stick_move := Vector2.ZERO
var stick_aux := Vector2.ZERO

## Where the ray from `origin` along `dir` meets the terrain, in metres
## (x, z); Vector2.INF when it never does inside the detailed ground.
static func ground_hit(origin: Vector3, dir: Vector3, ground: GroundTruth,
		max_m: float = MAX_RAY_M) -> Vector2:
	if ground == null or dir.y >= -0.0005:
		return Vector2.INF
	var d := dir.normalized()
	var t := 0.0
	var prev_t := 0.0
	var step := 2.0
	while t < max_m:
		var p := origin + d * t
		if not ground.is_inside(p.x, p.z):
			return Vector2.INF
		if p.y <= ground.height_at_world(p.x, p.z):
			# Crossed between prev_t and t: bisect to the surface.
			var lo := prev_t
			var hi := t
			for i in 8:
				var mid := (lo + hi) * 0.5
				var q := origin + d * mid
				if q.y <= ground.height_at_world(q.x, q.z):
					hi = mid
				else:
					lo = mid
			var hit := origin + d * hi
			return Vector2(hit.x, hit.z)
		prev_t = t
		step = maxf(2.0, t * 0.01)
		t += step
	return Vector2.INF

## Whether a press-release pair is a tap, not a drag or a long press.
static func is_tap(down: Vector2, up: Vector2, held_ms: int) -> bool:
	return down.distance_to(up) <= TAP_MAX_PX and held_ms <= int(TAP_MAX_S * 1000.0)

## Glide duration for a move of `metres`.
static func glide_seconds(metres: float) -> float:
	return clampf(metres / 60.0, GLIDE_MIN_S, GLIDE_MAX_S)

## Moves the camera to `to`, turning to (yaw, pitch), over `seconds`
## (instant under Reduce motion); the reflection probe follows at the end.
static func glide(v: View360, to: Vector3, yaw_to: float, pitch_to: float, seconds: float) -> void:
	if v._visit_tween != null:
		v._visit_tween.kill()
	var from := v._rig.position
	var yaw_from := v._rig.yaw
	var pitch_from := v._rig.pitch
	var yaw_end := yaw_from + wrapf(yaw_to - yaw_from, -PI, PI)
	v._visit_tween = v.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	v._visit_tween.tween_method(func(k: float) -> void:
		v._rig.position = from.lerp(to, k)
		v._rig.set_look(lerpf(yaw_from, yaw_end, k), lerpf(pitch_from, pitch_to, k))
		v._on_look_changed(), 0.0, 1.0, maxf(UiPrefs.motion(seconds), 0.01))
	v._visit_tween.tween_callback(func() -> void: v._atmos.set_probe_origin(v._rig.position))

# --- Footing ---

## Eye Y on foot at `xz`: EYE_M over the ground (or over the water a
## quay stands at, LandmarkTerrain.floor_y).
static func foot_y(data: LocationData, ground: GroundTruth, xz: Vector2) -> float:
	return LandmarkTerrain.floor_y(data, ground, xz) + EYE_M

## Whether `b` has walls a walker meets: not a roof on posts (building
## roof or carport) nor a part raised clear over the eye (an overhang, a
## bridge between blocks).
static func walls_at_foot(b: Dictionary) -> bool:
	return str(b.get("kind", "")) not in ["roof", "carport"] \
		and float(b.get("min_height_m", 0.0)) <= EYE_M and int(b.get("min_level", 0)) == 0

## Whether a walker at `xz` would stand inside one of `buildings`, or
## closer than BODY_M to its wall. A courtyard (an inner ring) is open
## ground, its own walls kept at BODY_M too.
static func blocked(buildings: Array, xz: Vector2) -> bool:
	for b in buildings:
		var d := b as Dictionary
		var fp: PackedVector2Array = d.get("footprint", PackedVector2Array())
		if fp.size() < 3 or not walls_at_foot(d):
			continue
		var out := View360._ring_distance(xz, fp)
		if out >= BODY_M:
			continue
		if out > 0.0:
			return true
		var in_yard := false
		for h in d.get("holes", []):
			var hole := h as PackedVector2Array
			if hole.size() >= 3 and Geometry2D.is_point_in_polygon(xz, hole):
				in_yard = _edge_distance(xz, hole) >= BODY_M
				break
		if not in_yard:
			return true
	return false

## Distance from `p` to the nearest edge of `ring`, inside it or out.
static func _edge_distance(p: Vector2, ring: PackedVector2Array) -> float:
	var best := INF
	for i in ring.size():
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])))
	return best

## Where a walker at `here` heading for `next` ends up among `buildings`:
## the whole step when it is clear, else its part along the nearest wall
## (none when walking straight at it), else `here`. A walker already
## inside a building (set down there) may step anywhere, so it can walk out.
static func step(buildings: Array, here: Vector2, next: Vector2) -> Vector2:
	if not blocked(buildings, next) or blocked(buildings, here):
		return next
	var wall := Vector2.ZERO
	var best := INF
	for b in buildings:
		var d := b as Dictionary
		if not walls_at_foot(d):
			continue
		var rings: Array = [d.get("footprint", PackedVector2Array())]
		rings.append_array(d.get("holes", []))
		for r in rings:
			var ring := r as PackedVector2Array
			if ring.size() < 3:
				continue
			for i in ring.size():
				var a: Vector2 = ring[i]
				var c: Vector2 = ring[(i + 1) % ring.size()]
				var dist := here.distance_to(Geometry2D.get_closest_point_to_segment(here, a, c))
				if dist < best and a != c:
					best = dist
					wall = (c - a).normalized()
	var slid := here + wall * (next - here).dot(wall)
	return slid if not blocked(buildings, slid) else here

## `xz` when a walker may stand there and `ok` (when given) accepts it,
## else the nearest such ground within FREE_SEARCH_M (rings 2 m apart),
## else `xz`.
static func free_spot(buildings: Array, xz: Vector2, ok: Callable = Callable()) -> Vector2:
	if not blocked(buildings, xz) and (not ok.is_valid() or ok.call(xz)):
		return xz
	var r := 2.0
	while r <= FREE_SEARCH_M:
		for k in 16:
			var p := xz + Vector2.from_angle(k * TAU / 16.0) * r
			if not blocked(buildings, p) and (not ok.is_valid() or ok.call(p)):
				return p
		r += 2.0
	return xz

## The buildings that could block a walker within `radius` of `at`.
func buildings_near(v: View360, at: Vector2, radius: float) -> Array:
	if _spans_for != v._data or _spans.size() != v._data.buildings.size():
		_spans_for = v._data
		_spans = ViewDrone.reaches(v._data.buildings)
		_near_at = Vector2.INF
	return ViewDrone.nearby(v._data.buildings, _spans, at, radius + BODY_M)

## Where a walker set down at `xz` stands: the nearest open ground
## inside the walking area and out of the water, at eye height on foot.
func landing(v: View360, xz: Vector2) -> Vector3:
	var ground := v._ground
	var p := free_spot(buildings_near(v, xz, FREE_SEARCH_M), xz, func(q: Vector2) -> bool:
		return View360.can_move_in_place(q, ground) and ground.water_at(q.x, q.y) <= DRY_M)
	return Vector3(p.x, foot_y(v._data, v._ground, p), p.y)

## Glides to ground point `xz` (or the open ground beside it) keeping the
## look; false when it is past the built area.
func walk_to(v: View360, xz: Vector2) -> bool:
	if v._data == null or v._rig == null or not View360.can_move_in_place(xz, v._ground):
		return false
	var to := landing(v, xz)
	glide(v, to, v._rig.yaw, v._rig.pitch, glide_seconds(v._rig.position.distance_to(to)))
	return true

# --- Taps ---

## A press on the scene (mouse or touch).
func press(pos: Vector2) -> void:
	_tap_at = pos
	_tap_ms = Time.get_ticks_msec()

## The matching release: a tap walks to the ground under it after
## TAP_WAIT_S unless a double click or another tap supersedes it.
func release(v: View360, pos: Vector2) -> void:
	if _tap_ms < 0:
		return
	var held := Time.get_ticks_msec() - _tap_ms
	_tap_ms = -1
	if not is_tap(_tap_at, pos, held):
		return
	_tap_seq += 1
	var seq := _tap_seq
	await v.get_tree().create_timer(TAP_WAIT_S).timeout
	if seq == _tap_seq and is_instance_valid(v) and v.is_visible_in_tree():
		tap(v, pos)

## A second click inside the wait: zoom reset owns it, not a walk.
func cancel_tap() -> void:
	_tap_seq += 1
	_tap_ms = -1

## Walk to the ground under screen point `pos`, unless the tap landed
## on a landmark: then it toggles that landmark's callout instead.
func tap(v: View360, pos: Vector2) -> void:
	if v._callouts != null and v._callouts.toggle_at(_to_viewport(v, pos)):
		return
	var cam := v._rig.camera
	if cam == null or v._ground == null:
		return
	# Screen point in the container's viewport (the SubViewport scales).
	var hit := ground_hit(cam.global_position, cam.project_ray_normal(_to_viewport(v, pos)), v._ground)
	if hit == Vector2.INF:
		return
	if not walk_to(v, hit):
		ViewTools.say(v, "Too far to walk", "Open a landmark and choose Go there to travel farther.", "neutral")

## View-local `pos` in the SubViewport's own pixel space.
static func _to_viewport(v: View360, pos: Vector2) -> Vector2:
	return pos * Vector2(v._viewport.size) / Vector2(maxf(v.size.x, 1.0), maxf(v.size.y, 1.0))

# --- Keys ---

## The bare letter keys are the view's: not while Cmd, Ctrl or Alt is held
## (Cmd+W, Ctrl+S and the like belong to the system), and not while a text
## field has the keyboard.
static func keys_free(v: View360) -> bool:
	if Input.is_key_pressed(KEY_META) or Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT):
		return false
	var focus := v.get_viewport().gui_get_focus_owner() if v.is_inside_tree() else null
	return not (focus is LineEdit or focus is TextEdit)

## Per-frame W A S D walking (Shift runs) and the touch sticks: the
## left walks, the right turns. Called from View360._process.
func process_keys(v: View360, delta: float) -> void:
	if v._data == null or v._ground == null or v._rig == null or not v.is_visible_in_tree():
		return
	var fwd := -stick_move.y
	var side := stick_move.x
	if keys_free(v):
		fwd += float(int(Input.is_key_pressed(KEY_W)) - int(Input.is_key_pressed(KEY_S)))
		side += float(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)))
	fwd = clampf(fwd, -1.0, 1.0)
	side = clampf(side, -1.0, 1.0)
	if stick_aux.x != 0.0:
		v._rig.set_look(v._rig.yaw - stick_aux.x * ViewDrone.YAW_RATE * delta, v._rig.pitch)
		v._on_look_changed()
	if fwd == 0.0 and side == 0.0:
		if _moving:
			_moving = false
			v._atmos.set_probe_origin(v._rig.position)
		return
	if v._visit_tween != null:
		v._visit_tween.kill()
	var yaw := v._rig.yaw
	var forward := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	# A half-pushed stick walks at half pace; keys stay at full.
	var wish := (forward * fwd + right * side).limit_length(1.0)
	var dir := wish.normalized()
	var speed := WALK_MPS * (RUN_MULT if Input.is_key_pressed(KEY_SHIFT) else 1.0) * wish.length()
	var here := Vector2(v._rig.position.x, v._rig.position.z)
	var next := here + dir * speed * delta
	if not View360.can_move_in_place(next, v._ground):
		# A camera outside the walking circle must still be able to return.
		if here.length() > View360.IN_PLACE_M:
			if next.length() >= here.length():
				next = here
		else:
			var slid := (here + dir.slide(next.normalized()) * speed * delta) \
				.limit_length(View360.IN_PLACE_M) if next.length() > 0.0 else here
			next = slid if View360.can_move_in_place(slid, v._ground) else here
	if here.distance_to(_near_at) > NEAR_REFRESH_M or _spans_for != v._data:
		_near = buildings_near(v, here, NEAR_REFRESH_M * 2.0)
		_near_at = here
	next = step(_near, here, next)
	_moving = true
	var y := lerpf(v._rig.position.y, foot_y(v._data, v._ground, next), 1.0 - exp(-10.0 * delta))
	v._rig.position = Vector3(next.x, y, next.y)
	v._on_look_changed()
