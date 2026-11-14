class_name LandmarkFhAaltoMain
extends RefCounted

## Alvar Aalto's Undergraduate Centre, the former Helsinki University of
## Technology main building (Otakaari 1, 1953–1966), in true metres about
## the centre of its auditorium fan: +X east, +Z south, the registry
## yaw_deg 0. The wings follow the outline of OSM relation 4148
## (LandmarkFhMallFootprints) with its two closed courtyards open: red
## brick on a black granite course, three storeys of windows, copper
## fascias and copper roofs, bitumen on the low blocks with round roof
## lights, the Student Hub's roof lanterns and the observatory dome.
## Auditorium A's fan, fitted to the OSM step rings, rises north from the
## stage at its apex: the granite seats of the open-air theatre, three
## roof steps whose risers are clerestory strips, the sloping copper
## velarium and its curved brick back, with brick flanks falling to the
## square on either side. Sources and estimates:
## docs/espoo-landmark-sources.md.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const TYPE := "aalto_university_main"
## Three storeys to the copper fascia.
const EAVE := 11.8
## Copper rim of the fan (the registry height_m).
const TOP := 21.1
## Fan edges, degrees counter-clockwise from east, and its radii.
const FAN_A0 := 49.0
const FAN_A1 := 145.0
const ARC_SEGS := 48
const STAGE_R := 3.8
const SEAT_STEPS := 10
const SEAT_RISE := 0.46
const STAGE_Y := 0.15
## Riser radii of the roof steps and the tread height inside each: the
## open-air seats end at the first, the copper velarium starts at the last.
const STEP_R := [11.8, 15.4, 19.3, 23.4]
const STEP_Y := [9.0, 12.0, 15.0, 18.0]
const REAR_R := 33.9
## Within FLANK_R of the stage the wings' brick roofs slope from FLANK_Y
## at the apex up to the eave.
const FLANK_R := 30.0
const FLANK_Y := 1.2
const COURTS := [
	[5.0, -42.0, 10.5, -40.2, 11.1, -42.0, 25.8, -37.6, 26.7, -40.6, 29.5, -39.8, 39.6, -71.1,
		15.9, -78.2],
	[46.3, -35.4, 62.0, -30.5, 71.6, -59.6, 55.3, -64.5],
]
## Student Hub (OSM way 514232691): its roof carries glazed lanterns.
const HUB := [40.5, -124.2, 56.1, -119.1, 42.2, -74.9, 26.6, -79.7]
## Low flat roofs in bitumen rather than copper: the east block, the
## block south of the central wing, the Student Hub and the low wing by
## the fan (aerial imagery).
const BITUMEN := [
	[96.0, -220.0, 170.0, -220.0, 170.0, 0.0, 96.0, 0.0],
	[15.0, -16.0, 43.5, -7.0, 51.0, -31.0, 24.0, -40.0],
	HUB,
	[-2.0, -89.0, 15.0, -84.0, 3.0, -44.0, -14.0, -49.0],
]
## Round roof lights, grids over these rectangles [x0, z0, x1, z1].
const ROOF_LIGHTS := [[20.0, -34.0, 48.0, -10.0], [140.0, -88.0, 156.0, -70.0]]
const DOME := Vector2(58.0, -107.9)
const MAIN_DOOR := [Vector2(48.6, -25.1), Vector2(75.3, -16.9)]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#87412F", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#2F3130", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5E8F7E", 2.0, 0.55, 0.45))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4F4642", 2.0, 0.85))
	lm.use("Steps", LandmarkMaterials.pbr("concrete", "#55595A", 2.0, 0.85))
	lm.use("Seats", LandmarkMaterials.pbr("stone", "#8E8C86", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A3C"))
	lm.use("Metal", LandmarkMaterials.paint("#3A3F3E"))
	_wings(lm)
	_fan(lm)
	_roof_details(lm)
	_entrance(lm)
	lm.commit(model)

## A fan point at radius r, bearing `deg`, height y.
static func _at(r: float, deg: float, y: float) -> Vector3:
	var a := deg_to_rad(deg)
	return Vector3(r * cos(a), y, -r * sin(a))

static func _deg(i: int) -> float:
	return lerpf(FAN_A0, FAN_A1, float(i) / float(ARC_SEGS))

## Wing roof height at p: the eave, sloping down toward the stage.
static func _top(p: Vector2) -> float:
	return FLANK_Y + (EAVE - FLANK_Y) * clampf((p.length() - STAGE_R) / (FLANK_R - STAGE_R), 0.0, 1.0)

static func _poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out

static func _circle(r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		out.append(Vector2.from_angle(TAU * float(k) / float(n)) * r)
	return out

static func _sector() -> PackedVector2Array:
	var out := PackedVector2Array([Vector2.ZERO])
	for i in ARC_SEGS + 1:
		var p := _at(REAR_R, _deg(i), 0.0)
		out.append(Vector2(p.x, p.z))
	return out

## Wing masses as simple polygons, [flat, sloping]: the outline less the
## courtyards and the fan, split at the flank circle. Each cut is first
## halved by a band seam so no clip can leave a hole.
static func _pieces() -> Array:
	var outer := F.outline(TYPE)
	var cuts: Array[PackedVector2Array] = [_poly(COURTS[0]), _poly(COURTS[1]), _sector()]
	var circle := _circle(FLANK_R, 64)
	var seams: Array[float] = [-INF]
	for c: PackedVector2Array in [cuts[0], cuts[1], cuts[2], circle]:
		var lo := INF
		var hi := -INF
		for p in c:
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
		seams.append((lo + hi) * 0.5 + 0.37)
	seams.sort()
	seams.append(INF)
	var pieces: Array[PackedVector2Array] = []
	for i in seams.size() - 1:
		var band := PackedVector2Array([Vector2(-1000, maxf(seams[i], -1000)), Vector2(1000, maxf(seams[i], -1000)),
			Vector2(1000, minf(seams[i + 1], 1000)), Vector2(-1000, minf(seams[i + 1], 1000))])
		pieces.append_array(Geometry2D.intersect_polygons(outer, band))
	for c in cuts:
		var next: Array[PackedVector2Array] = []
		for p in pieces:
			for q in Geometry2D.clip_polygons(p, c):
				if not Geometry2D.is_polygon_clockwise(q):
					next.append(q)
		pieces = next
	var flat: Array[PackedVector2Array] = []
	var slope: Array[PackedVector2Array] = []
	for p in pieces:
		for q in Geometry2D.clip_polygons(p, circle):
			if not Geometry2D.is_polygon_clockwise(q):
				flat.append(q)
		slope.append_array(Geometry2D.intersect_polygons(p, circle))
	return [flat, slope]

## True for an edge on the real outline or a courtyard (not a seam or cut).
static func _real(a: Vector2, b: Vector2, rings: Array) -> bool:
	var m := (a + b) * 0.5
	for ring: PackedVector2Array in rings:
		for i in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(m, ring[i], ring[(i + 1) % ring.size()])
			if q.distance_to(m) < 0.05 and Geometry2D.get_closest_point_to_segment(a, ring[i],
					ring[(i + 1) % ring.size()]).distance_to(a) < 0.05:
				return true
	return false

static func _wings(lm: LandmarkMesh) -> void:
	var outer := F.outline(TYPE)
	var rings := [outer, _poly(COURTS[0]), _poly(COURTS[1])]
	var split := _pieces()
	for flat: PackedVector2Array in split[0]:
		_walls(lm, flat, rings, false)
		_cap(lm, "Copper", flat, EAVE)
		# Bitumen laid over the copper where the low blocks are, clipped exactly.
		for zone in BITUMEN:
			for q in Geometry2D.intersect_polygons(flat, _poly(zone)):
				if not Geometry2D.is_polygon_clockwise(q):
					_cap(lm, "Roof", q, EAVE + 0.03)
	for slope: PackedVector2Array in split[1]:
		_walls(lm, slope, rings, true)
		var idx := Geometry2D.triangulate_polygon(slope)
		for t in range(0, idx.size(), 3):
			_slope_tri(lm, slope[idx[t]], slope[idx[t + 1]], slope[idx[t + 2]], 0)

static func _cap(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)

static func _bitumen(p: Vector2) -> bool:
	for flat in BITUMEN:
		if Geometry2D.is_point_in_polygon(p, _poly(flat)):
			return true
	return false

## Brick roof of the flanks, split until it follows the slope.
static func _slope_tri(lm: LandmarkMesh, a: Vector2, b: Vector2, c: Vector2, depth: int) -> void:
	var longest := maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a)))
	if longest > 3.0 and depth < 8:
		var ab := (a + b) * 0.5
		var bc := (b + c) * 0.5
		var ca := (c + a) * 0.5
		for t in [[a, ab, ca], [ab, b, bc], [ca, bc, c], [ab, bc, ca]]:
			_slope_tri(lm, t[0], t[1], t[2], depth + 1)
		return
	var pa := Vector3(a.x, _top(a), a.y)
	var pb := Vector3(b.x, _top(b), b.y)
	var pc := Vector3(c.x, _top(c), c.y)
	var n := (pb - pa).cross(pc - pa).normalized()
	if n.y < 0.0:
		n = -n
	lm.tri("Wall", pa, pb, pc, n, n, n, a, b, c)

## Walls, granite course, copper fascia and window rows along the real
## edges of one wing piece.
static func _walls(lm: LandmarkMesh, poly: PackedVector2Array, rings: Array, sloped: bool) -> void:
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 0.05 or not _real(a, b, rings):
			continue
		var along := (b - a).normalized()
		var out := Vector2(along.y, -along.x)
		if Geometry2D.is_point_in_polygon((a + b) * 0.5 + out * 0.2, poly):
			out = -out
		var o3 := Vector3(out.x, 0.0, out.y)
		var n := maxi(ceili(a.distance_to(b) / 3.0), 1) if sloped else 1
		for k in n:
			var p := a.lerp(b, float(k) / float(n))
			var q := a.lerp(b, float(k + 1) / float(n))
			var hp := _top(p) if sloped else EAVE
			var hq := _top(q) if sloped else EAVE
			var p0 := Vector3(p.x, 0.0, p.y)
			var q0 := Vector3(q.x, 0.0, q.y)
			lm.quad("Wall", p0, q0, q0 + Vector3.UP * hq, p0 + Vector3.UP * hp, o3)
			var g := o3 * 0.05
			lm.quad("Granite", p0 + g, q0 + g, q0 + g + Vector3.UP * minf(0.9, hq), p0 + g + Vector3.UP * minf(0.9, hp), o3)
			# Copper fascia, its top folded back over the wall head.
			var f := o3 * 0.08
			var top_p := p0 + Vector3.UP * (hp + 0.12)
			var top_q := q0 + Vector3.UP * (hq + 0.12)
			lm.quad("Copper", p0 + f + Vector3.UP * (hp - 0.6), q0 + f + Vector3.UP * (hq - 0.6),
				top_q + f, top_p + f, o3)
			lm.quad("Copper", top_p, top_q, top_q + f, top_p + f, Vector3.UP)
		if sloped or a.distance_to(b) < 3.0:
			continue
		var count := int(a.distance_to(b) / 2.7)
		if count < 1:
			continue
		var w0 := a + along * 0.7
		var w1 := b - along * 0.7
		U.window_grid(lm, "Glass", Vector3(w0.x, 0, w0.y), Vector3(w1.x, 0, w1.y), o3, 1.6, 3, 3.3, count, 1.7, 1.9)

## Auditorium A: stage, open-air seats, clerestory steps, velarium, the
## curved back and the two flank walls.
static func _fan(lm: LandmarkMesh) -> void:
	for i in ARC_SEGS:
		var d0 := _deg(i)
		var d1 := _deg(i + 1)
		lm.tri("Seats", Vector3(0, STAGE_Y, 0), _at(STAGE_R, d0, STAGE_Y), _at(STAGE_R, d1, STAGE_Y),
			Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2(STAGE_R, 0), Vector2(0, STAGE_R))
	var tread := (float(STEP_R[0]) - STAGE_R) / float(SEAT_STEPS)
	for k in SEAT_STEPS:
		var r0 := STAGE_R + tread * float(k)
		var y := STAGE_Y + SEAT_RISE * float(k + 1)
		_riser(lm, "Seats", r0, y - SEAT_RISE, y)
		_band(lm, "Seats", r0, r0 + tread, y, y)
	var seat_top := STAGE_Y + SEAT_RISE * float(SEAT_STEPS)
	for s in STEP_R.size():
		var r: float = STEP_R[s]
		var y0: float = seat_top if s == 0 else float(STEP_Y[s - 1])
		var y1: float = STEP_Y[s]
		_riser(lm, "Wall", r, y0, y0 + 0.4)
		_riser(lm, "Glass", r, y0 + 0.4, y1 - 0.5)
		_riser(lm, "Copper", r, y1 - 0.5, y1, 0.04)
		for i in range(0, ARC_SEGS + 1, 2):
			lm.beam("Metal", _at(r - 0.05, _deg(i), y0 + 0.4), _at(r - 0.05, _deg(i), y1 - 0.5), 0.07, 0.09)
		if s < STEP_R.size() - 1:
			_band(lm, "Steps", r, float(STEP_R[s + 1]), y1, y1)
	# Copper velarium rising to the rim, standing seams on every bay.
	var vel_r: float = STEP_R[STEP_R.size() - 1]
	var vel_y: float = STEP_Y[STEP_Y.size() - 1]
	_band(lm, "Copper", vel_r, REAR_R, vel_y, TOP - 0.25)
	for i in ARC_SEGS + 1:
		lm.beam("Copper", _at(vel_r, _deg(i), vel_y + 0.03), _at(REAR_R, _deg(i), TOP - 0.22), 0.05, 0.07)
	# Curved brick back with a copper coping.
	for i in ARC_SEGS:
		var p := _at(REAR_R, _deg(i), 0.0)
		var q := _at(REAR_R, _deg(i + 1), 0.0)
		var out := ((p + q) * 0.5).normalized()
		lm.quad("Wall", p, q, q + Vector3.UP * (TOP - 0.25), p + Vector3.UP * (TOP - 0.25), out)
		lm.quad("Copper", p + out * 0.08 + Vector3.UP * (TOP - 0.7), q + out * 0.08 + Vector3.UP * (TOP - 0.7),
			q + out * 0.08 + Vector3.UP * TOP, p + out * 0.08 + Vector3.UP * TOP, out)
		lm.quad("Copper", p - out * 0.3 + Vector3.UP * TOP, q - out * 0.3 + Vector3.UP * TOP,
			q + out * 0.08 + Vector3.UP * TOP, p + out * 0.08 + Vector3.UP * TOP, Vector3.UP)
	_flank(lm, FAN_A0, 1.0)
	_flank(lm, FAN_A1, -1.0)

## Horizontal or sloping ring r0..r1 across the fan, y0 at r0, y1 at r1.
static func _band(lm: LandmarkMesh, key: String, r0: float, r1: float, y0: float, y1: float) -> void:
	for i in ARC_SEGS:
		var a := _at(r0, _deg(i), y0)
		var b := _at(r0, _deg(i + 1), y0)
		var c := _at(r1, _deg(i + 1), y1)
		var d := _at(r1, _deg(i), y1)
		var n := (b - a).cross(d - a).normalized()
		if n.y < 0.0:
			n = -n
		lm.quad(key, a, b, c, d, n)

## Vertical face at radius r facing the stage, y0..y1, `proud` toward it.
static func _riser(lm: LandmarkMesh, key: String, r: float, y0: float, y1: float, proud: float = 0.0) -> void:
	for i in ARC_SEGS:
		var a := _at(r - proud, _deg(i), y0)
		var b := _at(r - proud, _deg(i + 1), y0)
		var inward := -Vector3(a.x + b.x, 0.0, a.z + b.z).normalized()
		lm.quad(key, a, b, b + Vector3.UP * (y1 - y0), a + Vector3.UP * (y1 - y0), inward)

## Brick flank wall on the fan edge at bearing `deg`: its top steps with
## the roof and rises as a cheek above the open-air seats. `side` is +1
## on the east edge (outside lies toward smaller bearings), -1 on the west.
static func _flank(lm: LandmarkMesh, deg: float, side: float) -> void:
	var seat_top := STAGE_Y + SEAT_RISE * float(SEAT_STEPS)
	var prof := PackedVector2Array([Vector2(STAGE_R, 0.0), Vector2(STAGE_R, 0.9),
		Vector2(STEP_R[0], seat_top + 0.6), Vector2(STEP_R[0], STEP_Y[0])])
	for s in range(1, STEP_R.size()):
		prof.append(Vector2(STEP_R[s], STEP_Y[s - 1]))
		prof.append(Vector2(STEP_R[s], STEP_Y[s]))
	prof.append(Vector2(REAR_R, TOP))
	prof.append(Vector2(REAR_R, 0.0))
	var a := deg_to_rad(deg)
	var radial := Vector3(cos(a), 0.0, -sin(a))
	var out := Vector3(sin(a), 0.0, cos(a)) * side
	var idx := Geometry2D.triangulate_polygon(prof)
	for face: float in [0.0, -0.45]:
		var n := out if face == 0.0 else -out
		var shift := out * face
		for t in range(0, idx.size(), 3):
			var v: Array[Vector3] = []
			for j in 3:
				var p := prof[idx[t + j]]
				v.append(radial * p.x + Vector3.UP * p.y + shift)
			lm.tri("Wall", v[0], v[1], v[2], n, n, n, prof[idx[t]], prof[idx[t + 1]], prof[idx[t + 2]])
	# Close the wall head between its two faces.
	for i in prof.size() - 1:
		var p := radial * prof[i].x + Vector3.UP * prof[i].y
		var q := radial * prof[i + 1].x + Vector3.UP * prof[i + 1].y
		if p.distance_to(q) < 0.01 or (prof[i].y == 0.0 and prof[i + 1].y == 0.0):
			continue
		# Treads and slopes face up; risers face the stage, the back end away.
		var up := (q - p).cross(out).normalized()
		if absf(prof[i].x - prof[i + 1].x) < 0.01:
			up = radial if prof[i].x >= REAR_R - 0.01 else -radial
		elif up.y < 0.0:
			up = -up
		lm.quad("Copper" if i > 2 else "Wall", p, q, q - out * 0.45, p - out * 0.45, up)

## Hub lanterns, round roof lights and the observatory dome.
static func _roof_details(lm: LandmarkMesh) -> void:
	var hub := _poly(HUB)
	# HUB runs north end (0, 1) to south end (3, 2); lanterns span its width.
	var s0 := (hub[0] + hub[1]) * 0.5
	var s1 := (hub[3] + hub[2]) * 0.5
	var across := (hub[1] - hub[0]).normalized()
	var width := hub[0].distance_to(hub[1]) - 3.0
	var yaw := atan2(-across.y, across.x)
	var count := int(s0.distance_to(s1) / 6.0)
	for k in count:
		var c := s0.lerp(s1, (float(k) + 0.5) / float(count))
		lm.box("Glass", Vector3(c.x, EAVE + 0.45, c.y), Vector3(width, 0.9, 1.8), Basis(Vector3.UP, yaw), 0.0)
		lm.box("Metal", Vector3(c.x, EAVE + 0.95, c.y), Vector3(width, 0.1, 0.25), Basis(Vector3.UP, yaw), 0.0)
	var outer := F.outline(TYPE)
	for rect in ROOF_LIGHTS:
		var x: float = rect[0] + 2.0
		while x < float(rect[2]):
			var z: float = rect[1] + 2.0
			while z < float(rect[3]):
				var p := Vector2(x, z)
				if Geometry2D.is_point_in_polygon(p, outer) and _bitumen(p) and _clear_of_courts(p):
					lm.frustum("Glass", Vector3(x, EAVE, z), 0.75, 0.4, 0.45, 10)
				z += 4.0
			x += 4.0
	lm.frustum("Wall", Vector3(DOME.x, EAVE, DOME.y), 3.4, 3.4, 1.4, 24)
	lm.lathe("Copper", Vector3(DOME.x, EAVE + 1.4, DOME.y), U.dome_prof(3.5, 3.1), 24)
	lm.box("Metal", Vector3(DOME.x, EAVE + 3.0, DOME.y - 1.6), Vector3(0.9, 2.6, 1.2), Basis(Vector3.UP, 0.0), 0.0)

static func _clear_of_courts(p: Vector2) -> bool:
	for flat in COURTS:
		if Geometry2D.is_point_in_polygon(p, F.offset(_poly(flat), 1.5)):
			return false
	return true

## Glazed main entrance and its copper canopy on the south front of the
## central wing, facing the festival square.
static func _entrance(lm: LandmarkMesh) -> void:
	var a: Vector2 = MAIN_DOOR[0]
	var b: Vector2 = MAIN_DOOR[1]
	var along := (b - a).normalized()
	var out := Vector2(along.y, -along.x)
	if Geometry2D.is_point_in_polygon((a + b) * 0.5 + out * 0.5, F.outline(TYPE)):
		out = -out
	var c := (a + b) * 0.5
	var yaw := atan2(-along.y, along.x)
	var basis := Basis(Vector3.UP, yaw)
	var face := c + out * 0.12
	lm.box("Glass", Vector3(face.x, 1.6, face.y), Vector3(8.0, 3.2, 0.1), basis, 0.0)
	for k in 6:
		var m := face + along * (-4.0 + 1.6 * float(k))
		lm.box("Metal", Vector3(m.x, 1.6, m.y), Vector3(0.08, 3.2, 0.14), basis, 0.0)
	var cc := c + out * 1.9
	lm.box("Copper", Vector3(cc.x, 3.55, cc.y), Vector3(10.0, 0.3, 3.8), basis, 0.0)
	for s: float in [-4.6, 4.6]:
		var post := c + out * 3.5 + along * s
		lm.box("Metal", Vector3(post.x, 1.7, post.y), Vector3(0.14, 3.4, 0.14), basis, 0.0)
	var step := c + out * 0.9
	lm.box("Granite", Vector3(step.x, 0.08, step.y), Vector3(9.0, 0.16, 1.6), basis, 0.0)
