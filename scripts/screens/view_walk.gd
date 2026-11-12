class_name ViewWalk
extends RefCounted

## On foot inside the built area: the eye stands EYE_M over the ground
## and walks at a walker's pace. Hold W A S D (arrows keep looking) to
## walk and Shift to run, or on a touch screen push the left stick to walk
## and the right one sideways to turn (DroneSticks); tap or click the
## ground to glide there. Buildings, parked cars, tree trunks, street
## furniture and standing trams are solid: a step into one slides along
## it, and a tap or a drone landing inside one sets down at the nearest
## open ground. Climbing is the drone's. All of it stays
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
## Footprint side (metres) of a tree trunk and of a piece of street
## furniture (a bench, a bin, a shelter post): small, but not walk-through.
const TREE_M := 0.7
const PROP_M := 0.9
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
## Static non-building solids (cars, trunks, furniture) for this data,
## with their reaches, cached until the data's counts change.
var _solids: Array = []
var _solid_spans := PackedVector3Array()
var _solids_for: LocationData
var _solids_sig := ""
## Tunnelled segments for this data, cached with the solids.
var _tunnel_segs: Array = []
var _tunnels_for: LocationData
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
		ViewChrome._on_look_changed(v, false), 0.0, 1.0, maxf(UiPrefs.motion(seconds), 0.01))
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

## A solid with a rectangular footprint: `centre` facing `forward`,
## `length` along it and `width` across, as a building-shaped dict
## (blocked/step/free_spot treat it exactly like a building).
static func rect_solid(centre: Vector2, forward: Vector2, length: float, width: float,
		kind: String) -> Dictionary:
	var f := forward.normalized()
	if f == Vector2.ZERO:
		f = Vector2(1, 0)
	var side := Vector2(-f.y, f.x)
	var hl := f * length * 0.5
	var hw := side * width * 0.5
	return {"footprint": PackedVector2Array([centre - hl - hw, centre + hl - hw,
		centre + hl + hw, centre - hl + hw]),
		"x": centre.x, "z": centre.y, "kind": kind}

## A square solid of side `side_m` at (x, z) — a trunk, a bench, a post.
static func point_solid(x: float, z: float, side_m: float, kind: String) -> Dictionary:
	return rect_solid(Vector2(x, z), Vector2(1, 0), side_m, side_m, kind)

## Every non-building solid a place's data names: the parked cars the
## world was built with (the same ParkedCars.plan, on the presets that
## build them), mapped tree trunks and mapped street furniture. Moving
## trams and trains arrive per frame from VehicleMover.walker_solids.
static func static_solids(data: LocationData, ground: GroundTruth) -> Array:
	var out: Array = []
	if data == null or ground == null:
		return out
	if RenderQuality.ultra_desktop(data.quality_preset) and not data.roads.is_empty():
		for car in ParkedCars.plan(data, ground, WorldScale.metres_to_units()):
			var pos: Vector3 = car[0]
			var basis: Basis = car[1]
			var kind := str(car[2])
			var forward := Vector2(basis.x.x, basis.x.z)
			out.append(rect_solid(Vector2(pos.x, pos.z), forward,
				CarSpecs.length_m(kind) * Vector3(basis.x).length(),
				CarSpecs.width_m(kind) * Vector3(basis.z).length(), "car"))
	for t in data.trees:
		if t is Dictionary:
			out.append(point_solid(float(t.get("x", 0.0)), float(t.get("z", 0.0)), TREE_M, "tree"))
	for f in data.street_furniture:
		if f is Dictionary:
			out.append(point_solid(float(f.get("x", 0.0)), float(f.get("z", 0.0)), PROP_M, "furniture"))
	# Gates, rails, fences, hedges and walls: every mapped barrier line
	# is solid along its segments (a gate in the line included — it is
	# shut). Only knee-high lines (tagged under 0.5 m) may be stepped over.
	for br in data.barriers:
		if not (br is Dictionary):
			continue
		var pts: PackedVector2Array = br.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var row: Array = StreetProps.BARRIERS.get(str(br.get("class", "")), [])
		var height := float(br.get("height_m", NAN))
		if is_nan(height):
			height = float(row[1]) if not row.is_empty() else 1.2
		if height < 0.5:
			continue
		var thick := maxf(float(row[2]) if not row.is_empty() else 0.35, 0.3)
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			if a.distance_to(b) < 0.05:
				continue
			out.append(rect_solid((a + b) * 0.5, b - a, a.distance_to(b) + thick, thick, "barrier"))
	out.append_array(_landmark_solids(data))
	return out

## Landmark stone a walker meets, for the Seoul gates whose models have
## real openings: Gwanghwamun's piers (its three arches stay open) and
## the Gyeongbokgung palace walls either side of it. The shapes come
## from the models' own constants, moved to each site in the registry.
static func _landmark_solids(data: LocationData) -> Array:
	var out: Array = []
	for entry in LocationData.landmarks():
		var type := str(entry.get("type", ""))
		if type != "gwanghwamun" and type != "gyeongbokgung_walls":
			continue
		var pos := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]),
			data.latitude, data.longitude)
		if pos.length() > 1300.0:
			continue
		var yaw := float(entry.get("yaw_deg", 0.0))
		if type == "gwanghwamun":
			var hx := LandmarkGwanghwamun.BASE.x * 0.5
			var depth := LandmarkGwanghwamun.BASE.z
			var x0 := -hx
			for a in LandmarkGwanghwamun.ARCHES:
				var left := float(a[0]) - float(a[1]) * 0.5
				out.append(_moved(rect_solid(Vector2((x0 + left) * 0.5, 0),
					Vector2(1, 0), left - x0, depth, "gate"), pos, yaw))
				x0 = float(a[0]) + float(a[1]) * 0.5
			out.append(_moved(rect_solid(Vector2((x0 + hx) * 0.5, 0),
				Vector2(1, 0), hx - x0, depth, "gate"), pos, yaw))
		else:
			for run in [LandmarkTsPalaceWalls.WEST, LandmarkTsPalaceWalls.EAST]:
				var pts: Array = run
				for i in pts.size() - 1:
					var a := _to_world(pts[i], pos, yaw)
					var b := _to_world(pts[i + 1], pos, yaw)
					out.append(rect_solid((a + b) * 0.5, b - a, a.distance_to(b) + 2.0, 2.0, "wall"))
	return out

## A model-frame point in world XZ (the landmark root turns by -yaw).
static func _to_world(local: Vector2, centre: Vector2, yaw_deg: float) -> Vector2:
	return centre + local.rotated(-deg_to_rad(yaw_deg))

## A solid built in a landmark's model frame, moved to its site.
static func _moved(solid: Dictionary, centre: Vector2, yaw_deg: float) -> Dictionary:
	var fp := PackedVector2Array()
	for p in (solid["footprint"] as PackedVector2Array):
		fp.append(_to_world(p, centre, yaw_deg))
	var c := _to_world(Vector2(float(solid["x"]), float(solid["z"])), centre, yaw_deg)
	return {"footprint": fp, "x": c.x, "z": c.y, "kind": str(solid["kind"])}

## Where a step from `here` to `next` ends with the water respected:
## deep water (past DRY_M) refuses the step, or slides it along the
## shore axis-wise; a walker already in the water may always walk out.
static func dry_step(ground: GroundTruth, here: Vector2, next: Vector2) -> Vector2:
	if ground == null or ground.water_at(next.x, next.y) <= DRY_M \
			or ground.water_at(here.x, here.y) > DRY_M:
		return next
	for candidate in [Vector2(next.x, here.y), Vector2(here.x, next.y)]:
		if ground.water_at(candidate.x, candidate.y) <= DRY_M:
			return candidate
	return here

## Tunnelled segments of a place as [a, b, half-width] rows.
static func tunnel_segments(data: LocationData) -> Array:
	var out: Array = []
	if data == null:
		return out
	for w in data.roads + data.railways:
		if not (w is Dictionary) or not bool(w.get("tunnel", false)):
			continue
		var pts: PackedVector2Array = w.get("points", PackedVector2Array())
		var half := maxf(float(w.get("width_m", 6.0)), 2.0) * 0.5 + BODY_M
		for i in pts.size() - 1:
			out.append([pts[i], pts[i + 1], half])
	return out

## Whether `xz` lies on one of `segments` (tunnel_segments rows).
static func on_tunnel(segments: Array, xz: Vector2) -> bool:
	for row in segments:
		if Geometry2D.get_closest_point_to_segment(xz, row[0], row[1]).distance_to(xz) <= float(row[2]):
			return true
	return false

## Whether `xz` is on a tunnelled way (a road or railway the map marks
## tunnel): the corridor under whatever stands above it.
static func in_tunnel(data: LocationData, xz: Vector2) -> bool:
	return on_tunnel(tunnel_segments(data), xz)

## Buildings and static solids that could block a walker within
## `radius` of `at` — what step() and free_spot() should respect.
func solids_near(v: View360, at: Vector2, radius: float) -> Array:
	var out := buildings_near(v, at, radius)
	if v._data == null or v._ground == null:
		return out
	var sig := "%d/%d/%d/%d/%d/%s" % [v._data.trees.size(), v._data.street_furniture.size(),
		v._data.roads.size(), v._data.quality_preset, v._data.barriers.size(), v._data.landmark_type]
	if _solids_for != v._data or _solids_sig != sig:
		_solids_for = v._data
		_solids_sig = sig
		_solids = static_solids(v._data, v._ground)
		_solid_spans = ViewDrone.reaches(_solids)
	out.append_array(ViewDrone.nearby(_solids, _solid_spans, at, radius + BODY_M))
	return out

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
	var p := free_spot(solids_near(v, xz, FREE_SEARCH_M), xz, func(q: Vector2) -> bool:
		return v.stream_enterable(q) and ground.water_at(q.x, q.y) <= DRY_M)
	return Vector3(p.x, foot_y(v._data, v._ground, p), p.y)

## Glides to ground point `xz` (or the open ground beside it) keeping the
## look; false when it is past the built area (past the detailed square
## while streaming — a longer trip remains a Go there trip).
func walk_to(v: View360, xz: Vector2) -> bool:
	if v._data == null or v._rig == null or not v.stream_glide_enterable(xz):
		return false
	var to := landing(v, xz)
	if v._ground.water_at(to.x, to.z) > DRY_M:
		return false  # No dry ground within reach of the tap: not a walk.
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
		if v._ground.water_at(hit.x, hit.y) > DRY_M:
			ViewTools.say(v, "That's water", "You can't walk on water.", "neutral")
		elif v._streamer.enabled:
			ViewTools.say(v, "Too far to tap", "Walk or fly there — the way ahead builds as you go.", "neutral")
		else:
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
	if v._streamer.enabled:
		# Endless: any ground inside the stream limit, capped (visibly,
		# via the streamer notice) only past the detailed edge.
		var step_vec := WorldStreamer.capped_velocity(dir * speed, here) * delta
		next = here + step_vec
		if not v.stream_enterable(next):
			if here.length() > WorldStreamer.STREAM_LIMIT_M:
				if next.length() >= here.length():
					next = here
			else:
				var slid := (here + step_vec.slide(next.normalized())) \
					.limit_length(WorldStreamer.STREAM_LIMIT_M) if next.length() > 0.0 else here
				next = slid if v.stream_enterable(slid) else here
	elif not View360.can_move_in_place(next, v._ground):
		# A camera outside the walking circle must still be able to return.
		if here.length() > View360.IN_PLACE_M:
			if next.length() >= here.length():
				next = here
		else:
			var slid := (here + dir.slide(next.normalized()) * speed * delta) \
				.limit_length(View360.IN_PLACE_M) if next.length() > 0.0 else here
			next = slid if View360.can_move_in_place(slid, v._ground) else here
	if here.distance_to(_near_at) > NEAR_REFRESH_M or _spans_for != v._data:
		_near = solids_near(v, here, NEAR_REFRESH_M * 2.0)
		_near_at = here
	var solids := _near
	if v._mover != null:
		# Trams and trains move: their solids are re-asked every frame.
		solids = _near.duplicate()
		solids.append_array(v._mover.walker_solids())
	if _tunnels_for != v._data:
		_tunnels_for = v._data
		_tunnel_segs = tunnel_segments(v._data)
	if on_tunnel(_tunnel_segs, next):
		pass  # In a tunnel the way is open under whatever stands above.
	else:
		next = step(solids, here, next)
		next = dry_step(v._ground, here, next)
	_moving = true
	var y := lerpf(v._rig.position.y, foot_y(v._data, v._ground, next), 1.0 - exp(-10.0 * delta))
	v._rig.position = Vector3(next.x, y, next.y)
	v._on_look_changed()
