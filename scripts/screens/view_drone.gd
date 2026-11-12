class_name ViewDrone
extends RefCounted

## Drone mode (G, or the drone button): the camera hovers over the whole
## detailed ground instead of walking. W A S D (or the left stick) fly
## with momentum, so the drone eases in and drifts to a stop; E / Q (or
## the right stick up and down) climb and descend, and the right stick
## turns; Shift boosts. The drone holds its height over the terrain as it
## flies, never drops below AGL_MIN_M or the roofs beside it, and bobs
## gently while it hovers (still under Reduce motion). One instance per
## view; steering, floor and roam rules are static so tests can drive
## them. ViewChrome builds the button, readout and sticks into it.

## Cruise (full-stick) speed: 100 km/h. Shift still sprints past it
## at BOOST_MULT, as before.
const CRUISE_MPS := 100.0 / 3.6
const BOOST_MULT := 3.0
const CLIMB_MPS := 8.0
## Per second: how fast the drone reaches the wished speed, and how fast
## it drifts to a stop with nothing held.
const ACCEL := 3.0
const DRAG := 1.6
## Height over the terrain (metres): the lowest it hovers, and its ceiling.
const AGL_MIN_M := 8.0
const AGL_MAX_M := 500.0
## Height the drone starts at on takeoff: high enough to take the
## place in (roofs beside it can still push the floor higher).
const START_AGL_M := 100.0
## Roam radius, inside the ±1200 m detailed ground (GroundTruth.extent_m).
const EDGE_M := 1100.0
const BOB_M := 0.3
const BOB_HZ := 0.35
## Camera roll (radians) at full sideways speed.
const BANK_MAX := 0.06
## Steepest look (radians, up or down) a landing keeps.
const LAND_PITCH := 0.3
## Right stick turn rate, radians per second.
const YAW_RATE := 1.2
## The roof floor is re-measured this often, under the drone and where
## it will be LOOKAHEAD_S on, so it rises before it reaches a tower;
## the readout refreshes at 5 Hz.
const FLOOR_EVERY_S := 0.12
const LOOKAHEAD_S := 1.0
## The buildings the floor checks are those within reach of where the
## drone was last NEAR_REFRESH_M ago, re-gathered as it flies on.
const NEAR_REFRESH_M := 150.0
const READOUT_EVERY_S := 0.2
## Below this speed (m/s) the drone counts as hovering.
const SETTLED_MPS := 0.05
## A hover re-captures the reflections only this far (metres) from where
## they were last taken: each capture renders every probe's cube faces.
const PROBE_MOVE_M := 40.0

var on := false
## Joystick deflection (DroneSticks), -1..1 in screen axes: `stick_move`
## flies (up is forward), `stick_aux` x turns and up climbs.
var stick_move := Vector2.ZERO
var stick_aux := Vector2.ZERO
# HUD parts, built by ViewChrome.
var button: Button
var panel: PanelContainer
var altitude: Readout
var speed: Readout
var sticks: DroneSticks

var _vel := Vector2.ZERO
var _agl := 30.0
var _clock := 0.0
var _floor_clock := 0.0
var _floor_target := -INF
var _floor_here := -INF
var _near: Array = []
var _spans := PackedVector3Array()
var _spans_for: LocationData
var _near_at := Vector2.INF
var _readout_clock := 0.0
var _moving := false
var _probe_at := Vector3.INF
## A glide (Go there) moved the camera: pick its height up afterwards.
var _resync := false

## Horizontal velocity after `delta` seconds wishing `wish` (unit-length
## or less, metres x / z): eases towards the cruise speed, and drifts to
## a stop when nothing is held.
static func steer(vel: Vector2, wish: Vector2, delta: float, boost: bool = false) -> Vector2:
	if wish.length_squared() < 0.0001:
		return vel * exp(-DRAG * delta)
	var target := wish.limit_length(1.0) * CRUISE_MPS * (BOOST_MULT if boost else 1.0)
	return vel.lerp(target, 1.0 - exp(-ACCEL * delta))

## Lowest Y the drone may hover at over `xz`: AGL_MIN_M over the terrain,
## and View360's roof clearance over `buildings` beside it.
static func floor_y(buildings: Array, ground: GroundTruth, xz: Vector2) -> float:
	return maxf(ground.height_at_world(xz.x, xz.y) + AGL_MIN_M,
		View360.roof_clearance_among(buildings, ground, xz))

## Each building's centre and reach (its farthest corner from the
## centre) as (x, z, reach), -1 reach for one without a footprint.
## Measured once per scene so re-gathering the nearby ones is a pass
## over plain floats.
static func reaches(buildings: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(buildings.size())
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		var fp: PackedVector2Array = b.get("footprint", PackedVector2Array())
		var c := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
		var reach := -1.0
		if fp.size() >= 3:
			for q in fp:
				reach = maxf(reach, c.distance_to(q))
		out[i] = Vector3(c.x, c.y, reach)
	return out

## The buildings whose footprint comes within `radius` of `at`, with
## `spans` from reaches(buildings).
static func nearby(buildings: Array, spans: PackedVector3Array, at: Vector2, radius: float) -> Array:
	var out: Array = []
	for i in mini(buildings.size(), spans.size()):
		var s := spans[i]
		if s.z >= 0.0 and Vector2(s.x, s.y).distance_to(at) - s.z <= radius:
			out.append(buildings[i])
	return out

static func can_roam(xz: Vector2, ground: GroundTruth) -> bool:
	return xz.length() <= EDGE_M and ground != null and ground.is_inside(xz.x, xz.y)

## `next` when the drone may fly there from `here`; at the edge it slides
## along it, else it stays at `here`.
static func clamp_roam(here: Vector2, next: Vector2, ground: GroundTruth) -> Vector2:
	if can_roam(next, ground):
		return next
	if next.length() > 0.0:
		# A step along the edge's tangent ends just outside the circle:
		# pulled back onto it, the drone keeps gliding round.
		var slid := (here + (next - here).slide(next.normalized())).limit_length(EDGE_M)
		if can_roam(slid, ground):
			return slid
	return here

## Hover bob (metres) at `t` seconds; none under Reduce motion.
static func bob(t: float) -> float:
	return 0.0 if UiPrefs.reduce_motion else sin(TAU * BOB_HZ * t) * BOB_M

## Takes off from where the camera stands.
func enter(v: View360) -> void:
	on = true
	if v._visit_tween != null:
		v._visit_tween.kill()
	v._walk.cancel_tap()
	v._walk.stick_move = Vector2.ZERO
	v._walk.stick_aux = Vector2.ZERO
	_vel = Vector2.ZERO
	_clock = 0.0
	_floor_clock = 0.0
	_moving = false
	_near_at = Vector2.INF
	_probe_at = v._rig.position if v._rig != null else Vector3.INF
	if v._ground != null and v._rig != null:
		# Take off to START_AGL_M (keeping a higher stance it already has):
		# process() eases the camera up to it over the first second.
		_agl = clampf(maxf(v._rig.position.y - v._ground.height_at_world(v._rig.position.x, v._rig.position.z),
			START_AGL_M), AGL_MIN_M, AGL_MAX_M)
	sync_hud(v)
	_update_readout(v)

## Lands: back on foot inside the walking area, on the open ground
## nearest the drone (`glide_home`), or where it is when a new scene replaces this one.
func exit(v: View360, glide_home: bool = true) -> void:
	on = false
	stick_move = Vector2.ZERO
	stick_aux = Vector2.ZERO
	_vel = Vector2.ZERO
	if v._rig != null and v._rig.camera != null:
		v._rig.camera.rotation.z = 0.0
	_near.clear()
	sync_hud(v)
	if not glide_home or v._data == null or v._ground == null or v._rig == null:
		return
	var here := Vector2(v._rig.position.x, v._rig.position.z)
	var xz := here
	if v._streamer.enabled:
		# Land where the drone is: the centre follows, so there is no
		# walking circle to glide back inside.
		if not v.stream_enterable(xz):
			xz = xz.limit_length(WorldStreamer.STREAM_LIMIT_M)
	elif not View360.can_move_in_place(xz, v._ground):
		xz = xz.limit_length(View360.IN_PLACE_M - 1.0)
	# On foot, on open ground: never inside a building.
	var to := v._walk.landing(v, xz)
	if to.distance_to(v._rig.position) < 0.5:
		v._atmos.set_probe_origin(v._rig.position)
		return
	# A walker looks about, not down from a drone's height.
	ViewWalk.glide(v, to, v._rig.yaw, clampf(v._rig.pitch, -LAND_PITCH, LAND_PITCH),
		ViewWalk.glide_seconds(to.distance_to(v._rig.position)))

## Shows the button's state, the readout and (touch screens) the sticks,
## which fly while the drone is up and walk once it lands.
func sync_hud(v: View360) -> void:
	if button != null:
		HudParts.apply_icon_button(button, on)
		button.tooltip_text = "Land (G)" if on else "Drone (G)"
	if panel != null:
		panel.visible = on
	if sticks != null:
		# Shown by ViewChrome.layout, which also keeps them off sheets.
		sticks.visible = DroneSticks.wanted()
		sticks.set_flying(on)
		sticks.reset()
	# The hint's new text first, so the layout centres it.
	ViewChrome._show_hint(v)
	ViewChrome.layout(v)

## Per-frame flight. Called from View360._process while `on`.
func process(v: View360, delta: float) -> void:
	if v._data == null or v._ground == null or v._rig == null or not v.is_visible_in_tree():
		return
	var fwd := -stick_move.y
	var side := stick_move.x
	var climb := -stick_aux.y
	var boost := false
	if ViewWalk.keys_free(v):
		fwd += float(int(Input.is_key_pressed(KEY_W)) - int(Input.is_key_pressed(KEY_S)))
		side += float(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)))
		climb += float(int(Input.is_key_pressed(KEY_E)) - int(Input.is_key_pressed(KEY_Q)))
		boost = Input.is_key_pressed(KEY_SHIFT)
	climb = clampf(climb, -1.0, 1.0)
	var held := absf(fwd) > 0.0 or absf(side) > 0.0 or absf(climb) > 0.0 or absf(stick_aux.x) > 0.0
	if v._visit_tween != null and v._visit_tween.is_running():
		if not held:
			_resync = true
			return
		v._visit_tween.kill()
	var here := Vector2(v._rig.position.x, v._rig.position.z)
	var ground_y := v._ground.height_at_world(here.x, here.y)
	if _resync:
		_resync = false
		_vel = Vector2.ZERO
		_agl = clampf(v._rig.position.y - ground_y, AGL_MIN_M, AGL_MAX_M)
	if stick_aux.x != 0.0:
		v._rig.set_look(v._rig.yaw - stick_aux.x * YAW_RATE * delta, v._rig.pitch)
	var yaw := v._rig.yaw
	var forward := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	_vel = steer(_vel, forward * fwd + right * side, delta, boost)
	if v._streamer.enabled:
		_vel = WorldStreamer.capped_velocity(_vel, here)
	var next := v.stream_roam(here, here + _vel * delta)
	if delta > 0.0:
		_vel = (next - here) / delta
	ground_y = v._ground.height_at_world(next.x, next.y)
	if climb != 0.0:
		# Climb from where the drone is, not from a floor it rose above.
		var now := v._rig.position.y - ground_y
		_agl = maxf(_agl, now) if climb > 0.0 else minf(_agl, now)
		_agl = clampf(_agl + climb * CLIMB_MPS * (BOOST_MULT if boost else 1.0) * delta,
			AGL_MIN_M, AGL_MAX_M)
	_floor_clock -= delta
	if _floor_clock <= 0.0:
		_floor_clock = FLOOR_EVERY_S
		var ahead := v.stream_roam(next, next + _vel * LOOKAHEAD_S)
		if next.distance_to(_near_at) > NEAR_REFRESH_M:
			if _spans_for != v._data or _spans.size() != v._data.buildings.size():
				_spans_for = v._data
				_spans = reaches(v._data.buildings)
			_near_at = next
			_near = nearby(v._data.buildings, _spans, next, View360.CLEAR_RADIUS_M + NEAR_REFRESH_M
				+ CRUISE_MPS * BOOST_MULT * LOOKAHEAD_S)
		_floor_here = floor_y(_near, v._ground, next)
		_floor_target = maxf(_floor_here, floor_y(_near, v._ground, ahead))
	_clock += delta
	var target := maxf(_floor_target, ground_y + _agl) + bob(_clock)
	var y := lerpf(v._rig.position.y, target, 1.0 - exp(-6.0 * delta))
	# Never inside a roof: the clearance over the roofs here may be eased
	# into, the roofs themselves not.
	var hard := maxf(ground_y + 1.0, _floor_here - View360.CLEAR_ABOVE_M + 1.0)
	v._rig.position = Vector3(next.x, maxf(y, hard), next.y)
	var bank := 0.0 if UiPrefs.reduce_motion \
		else -BANK_MAX * clampf(_vel.dot(right) / CRUISE_MPS, -1.0, 1.0)
	if v._rig.camera != null:
		v._rig.camera.rotation.z = lerpf(v._rig.camera.rotation.z, bank, 1.0 - exp(-4.0 * delta))
	var moving := _vel.length() > SETTLED_MPS or climb != 0.0
	if moving or stick_aux.x != 0.0:
		v._on_look_changed()
	elif _moving and v._rig.position.distance_to(_probe_at) > PROBE_MOVE_M:
		# Settled into a hover well away from the last capture: the
		# reflections catch up.
		_probe_at = v._rig.position
		v._atmos.set_probe_origin(_probe_at)
	_moving = moving
	_readout_clock -= delta
	if _readout_clock <= 0.0:
		_readout_clock = READOUT_EVERY_S
		_update_readout(v)

## Altitude over the ground and ground speed, as the readout shows them.
func _update_readout(v: View360) -> void:
	if altitude == null or v._ground == null or v._rig == null:
		return
	var p := v._rig.position
	altitude.set_value(UiTheme.elevation(maxf(p.y - v._ground.height_at_world(p.x, p.z), 0.0)))
	speed.set_value(UiTheme.speed(_vel.length()))
