class_name ViewWalk
extends RefCounted

## Free movement inside the built area: tap or click the ground to glide
## there, hold W A S D (arrows keep looking) to walk. Both stay within
## View360.can_move_in_place, where the buildings and trees still surround
## the camera; farther places are for Go there. The eye keeps its height
## over the ground and over the roofs beside it (View360.eye_y). One
## instance per view holds the walking state; the ray march, the glide
## and the tap rules are static so tests can drive them.

const WALK_MPS := 14.0
const RUN_MULT := 3.0
## A press that stays within TAP_MAX_PX and TAP_MAX_S is a tap; it acts
## after TAP_WAIT_S so a double click (reset zoom) cancels it.
const TAP_MAX_PX := 8.0
const TAP_MAX_S := 0.35
const TAP_WAIT_S := 0.28
const MAX_RAY_M := 1500.0
const GLIDE_MIN_S := 0.6
const GLIDE_MAX_S := 2.2
## The eye height is re-measured over the roofs this often while walking.
const EYE_EVERY_S := 0.12

var _tap_at := Vector2.ZERO
var _tap_ms := -1
var _tap_seq := 0
var _eye_clock := 0.0
var _eye_target := 0.0
var _moving := false

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

## Glides to ground point `xz` keeping the look; false when it is past
## the built area.
func walk_to(v: View360, xz: Vector2) -> bool:
	if v._data == null or v._rig == null or not View360.can_move_in_place(xz, v._ground):
		return false
	var to := Vector3(xz.x, View360.eye_y(v._data, v._ground, xz, false), xz.y)
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

## Walk to the ground under screen point `pos`.
func tap(v: View360, pos: Vector2) -> void:
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

## Per-frame W A S D walking (Shift runs). Called from View360._process.
func process_keys(v: View360, delta: float) -> void:
	if v._data == null or v._ground == null or v._rig == null or not v.is_visible_in_tree():
		return
	var fwd := int(Input.is_key_pressed(KEY_W)) - int(Input.is_key_pressed(KEY_S))
	var side := int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	if fwd == 0 and side == 0:
		if _moving:
			_moving = false
			v._atmos.set_probe_origin(v._rig.position)
		return
	if v._visit_tween != null:
		v._visit_tween.kill()
	var yaw := v._rig.yaw
	var forward := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	var dir := (forward * float(fwd) + right * float(side)).normalized()
	var speed := WALK_MPS * (RUN_MULT if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	var here := Vector2(v._rig.position.x, v._rig.position.z)
	var next := here + dir * speed * delta
	if not View360.can_move_in_place(next, v._ground):
		# Slide along the edge instead of stopping dead.
		next = here + dir.slide(next.normalized()) * speed * delta \
			if next.length() > 0.0 else here
		if not View360.can_move_in_place(next, v._ground):
			return
	_eye_clock -= delta
	if not _moving or _eye_clock <= 0.0:
		_eye_clock = EYE_EVERY_S
		_eye_target = View360.eye_y(v._data, v._ground, next, false)
	_moving = true
	var y := lerpf(v._rig.position.y, _eye_target, 1.0 - exp(-8.0 * delta))
	v._rig.position = Vector3(next.x, y, next.y)
	v._on_look_changed()
