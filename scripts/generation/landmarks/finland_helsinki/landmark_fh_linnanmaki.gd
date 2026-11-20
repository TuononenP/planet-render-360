extends RefCounted

## Linnanmäki amusement park (Helsinki, 1950) on the Alppila hill. Origin at
## the registry point, yaw 0 (+X east, +Z south).
##
## Built: the Vuoristorata timber coaster along its mapped centreline, the
## Kingi drop tower (75 m), Raketti and Panoraama towers (positions from the
## inner footprints), and, from OSM nodes (2026-11), the big wheel Rinkeli at
## (-134.4, 80.3) (34 m) and the blue steel coaster Taiga whose station node is
## at (-137.5, 33.7). From the photographs (visual-plan/refs/landmarks/
## linnanmaki/): Taiga is a bright blue twisting steel track on black
## tubular supports; Rinkeli has a blue rim and spokes with open gondolas.
##
## Measured: tower and node positions, the 34 m and 75 m heights, the
## Vuoristorata line. Estimated: Taiga's route and heights (a closed
## Catmull-Rom loop through eleven waypoints: it reads as a tall blue
## coaster, not as the real layout), the wheel's axis direction, gondola
## count, Vuoristorata's hill profile. The round brick water reservoir with
## its grass roof (OSM way 126775587, 17 m, 32 m radius) is left to the OSM
## buildings.

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const LINNANMAKI_M := 75.0
const COASTER_M := 24.0
## Vuoristorata's track height (m) at fractions of its mapped centreline:
## the station, the lift to 24 m, then falling hills (estimated profile).
const COASTER_PROFILE := [[0.0, 7.0], [0.1, 8.0], [0.3, 24.0], [0.42, 11.0], [0.55, 18.0],
	[0.68, 9.0], [0.8, 14.0], [0.92, 8.0], [1.0, 7.0]]

const ENTRY := {"type": "linnanmaki", "name": "Linnanmäki", "lat": 60.188632, "lon": 24.941667,
	"radius_m": 4000.0, "wiki_title": "Linnanmäki", "height_m": 75.0, "clear_m": 9.0,
	"clear_offsets_m": [[-40.4, -37.9], [-41.8, -49.2], [-33.4, -56.2], [-22.0, -55.1], [-14.4, -46.0],
		[-7.7, -36.1], [-1.0, -26.1], [5.7, -16.2], [12.4, -6.2], [19.1, 3.7], [25.8, 13.7],
		[30.8, 24.5], [24.9, 34.5], [13.4, 33.9], [8.0, 30.7], [-5.4, 90.2], [-31.4, 115.5],
		[-63.9, -26.3]],
	"kind": "Amusement park", "aliases": ["linnanmäki", "linnanmaki", "borgbacken", "linnanmäki amusement park",
		"vuoristorata", "linnanmäki roller coaster", "kingi", "panoraama", "raketti"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#6B4A32", 2.0))
	lm.use("Steel", LandmarkMaterials.paint("#D6DADB", 0.45, 0.5))
	lm.use("Red", LandmarkMaterials.paint("#C23B2E", 0.5, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#3A4C55"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59D", 3.0))
	lm.use("Blue", LandmarkMaterials.paint("#2F7FE0", 0.4, 0.5))
	lm.use("Black", LandmarkMaterials.paint("#22262A", 0.5, 0.6))
	_coaster(lm)
	_taiga(lm)
	_wheel(lm)
	# Kingi: the 75 m drop tower, its seat ring waiting at the base.
	var k := I.KINGI
	lm.poly_prism("Concrete", I.circle(k, 3.0), 0.0, 0.6)
	lm.frustum("Steel", Vector3(k.x, 0.6, k.y), 1.9, 1.6, LINNANMAKI_M - 3.6, 16)
	lm.frustum("Red", Vector3(k.x, LINNANMAKI_M - 3.0, k.y), 2.4, 2.4, 3.0, 16)
	lm.frustum("Red", Vector3(k.x, 1.4, k.y), 4.0, 4.0, 1.6, 20)
	# Raketti: a slim tower under a rocket's nose cone.
	var r := I.RAKETTI
	lm.poly_prism("Concrete", I.circle(r, 2.6), 0.0, 0.6)
	lm.frustum("Steel", Vector3(r.x, 0.6, r.y), 1.6, 1.4, 53.4, 14)
	lm.frustum("Red", Vector3(r.x, 54.0, r.y), 2.2, 0.0, 6.0, 14)
	lm.frustum("Red", Vector3(r.x, 1.4, r.y), 3.4, 3.4, 1.4, 18)
	# Panoraama: the observation gondola ring on its column.
	var p := I.PANORAAMA
	lm.poly_prism("Concrete", I.circle(p, 2.4), 0.0, 0.6)
	lm.frustum("Steel", Vector3(p.x, 0.6, p.y), 1.4, 1.2, 49.4, 14)
	lm.frustum("Steel", Vector3(p.x, 50.0, p.y), 1.8, 1.8, 3.0, 14)
	lm.frustum("Red", Vector3(p.x, 18.0, p.y), 5.0, 5.0, 0.6, 24)
	lm.frustum("Glass", Vector3(p.x, 18.6, p.y), 4.9, 4.9, 2.0, 24)
	lm.frustum("Red", Vector3(p.x, 20.6, p.y), 5.0, 5.0, 0.5, 24)
	lm.commit(model, "Linnanmaki_")

## Bents of timber posts every few metres along the centreline, X-braced
## side walls up to the track, cross ties, and two track decks on top.
static func _coaster(lm: LandmarkMesh) -> void:
	var line := I.coaster_line()
	var length := 0.0
	for i in line.size() - 1:
		length += line[i].distance_to(line[i + 1])
	var steps := int(length / 4.5)
	var half := I.COASTER_HALF_M - 1.0
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_h := 0.0
	for s in steps + 1:
		var t := float(s) / float(steps)
		var at := _along(line, t * length)
		var c: Vector2 = at[0]
		var side: Vector2 = at[1]
		var h := _coaster_height(t)
		# Feet a little above the ground so member ends do not dip below it.
		var l := Vector3(c.x + side.x * half, 0.3, c.y + side.y * half)
		var r := Vector3(c.x - side.x * half, 0.3, c.y - side.y * half)
		lm.beam("Timber", l, l + Vector3.UP * h, 0.4)
		lm.beam("Timber", r, r + Vector3.UP * h, 0.4)
		var y := 4.5
		while y < h:
			lm.beam("Timber", l + Vector3.UP * y, r + Vector3.UP * y, 0.25)
			y += 4.5
		if s > 0:
			var cells := maxi(1, int(maxf(h, prev_h) / 4.5))
			lm.lattice_panel("Timber", prev_l, l, prev_l + Vector3.UP * prev_h, l + Vector3.UP * h, 0.22, cells)
			lm.lattice_panel("Timber", prev_r, r, prev_r + Vector3.UP * prev_h, r + Vector3.UP * h, 0.22, cells)
			for k: float in [-0.45, 0.45]:
				var a := prev_l.lerp(prev_r, 0.5 + k) + Vector3.UP * (prev_h + 0.3)
				var b := l.lerp(r, 0.5 + k) + Vector3.UP * (h + 0.3)
				lm.beam("Timber", a, b, 2.0, 0.35)
		prev_l = l
		prev_r = r
		prev_h = h

## Point and left-hand normal `dist` metres along the polyline.
static func _along(line: PackedVector2Array, dist: float) -> Array:
	var left := dist
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var seg := a.distance_to(b)
		if left <= seg or i == line.size() - 2:
			var d := (b - a).normalized()
			return [a + d * minf(left, seg), Vector2(-d.y, d.x)]
		left -= seg
	return [line[0], Vector2.UP]

static func _coaster_height(t: float) -> float:
	for i in COASTER_PROFILE.size() - 1:
		var a: Array = COASTER_PROFILE[i]
		var b: Array = COASTER_PROFILE[i + 1]
		if t <= float(b[0]):
			var k := smoothstep(float(a[0]), float(b[0]), t)
			return lerpf(float(a[1]), float(b[1]), k)
	return float(COASTER_PROFILE[-1][1])

## Taiga: a closed blue track through waypoints (x, z, rail height) with
## black tubular supports every few metres and a white lift chain stretch.
const TAIGA := [Vector3(-165.0, 30.0, 4.0), Vector3(-148.0, 28.0, 5.0), Vector3(-126.0, 27.0, 16.0),
	Vector3(-108.0, 29.0, 29.0), Vector3(-97.0, 38.0, 20.0), Vector3(-97.0, 50.0, 8.0), Vector3(-110.0, 59.0, 12.0),
	Vector3(-128.0, 64.0, 21.0), Vector3(-150.0, 60.0, 14.0), Vector3(-166.0, 50.0, 7.0), Vector3(-171.0, 38.0, 4.0)]

static func _spline(pts: Array, t: float) -> Vector3:
	var n := pts.size()
	var f := t * float(n)
	var i := int(floor(f)) % n
	var u: float = f - floor(f)
	var p0: Vector3 = pts[(i + n - 1) % n]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[(i + 1) % n]
	var p3: Vector3 = pts[(i + 2) % n]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)

static func _taiga(lm: LandmarkMesh) -> void:
	var steps := 220
	var prev: Vector3 = _spline(TAIGA, 0.0)
	var prev_side := Vector3.ZERO
	for k in range(1, steps + 1):
		var cur: Vector3 = _spline(TAIGA, float(k) / float(steps))
		var dir := (cur - prev)
		var side := Vector3(dir.z, 0.0, -dir.x).normalized() * 0.75
		if k == 1:
			prev_side = side
		var a_l := Vector3(prev.x, prev.y, prev.z) + prev_side
		var a_r := Vector3(prev.x, prev.y, prev.z) - prev_side
		var b_l := Vector3(cur.x, cur.y, cur.z) + side
		var b_r := Vector3(cur.x, cur.y, cur.z) - side
		lm.beam("Blue", a_l, b_l, 0.28)
		lm.beam("Blue", a_r, b_r, 0.28)
		lm.beam("Blue", Vector3(prev.x, prev.y - 0.5, prev.z), Vector3(cur.x, cur.y - 0.5, cur.z), 0.35)
		if k % 3 == 0:
			lm.beam("Blue", Vector3(cur.x, cur.y, cur.z) + side, Vector3(cur.x, cur.y - 0.5, cur.z), 0.18)
			lm.beam("Blue", Vector3(cur.x, cur.y, cur.z) - side, Vector3(cur.x, cur.y - 0.5, cur.z), 0.18)
		if k % 16 == 0 and cur.y > 6.0:
			lm.beam("Black", Vector3(cur.x, 0.2, cur.z), Vector3(cur.x, cur.y - 0.6, cur.z), 0.45)
			lm.beam("Black", Vector3(cur.x + 2.0, 0.2, cur.z + 1.5), Vector3(cur.x, cur.y - 0.6, cur.z), 0.3)
		prev = cur
		prev_side = side

## Rinkeli: the 34 m big wheel at (-134.4, 80.3); wheel plane along X.
static func _wheel(lm: LandmarkMesh) -> void:
	var c := Vector3(-134.4, 18.0, 80.3)
	var r := 15.9
	var n := 32
	for k in n:
		var a0 := TAU * float(k) / float(n)
		var a1 := TAU * float(k + 1) / float(n)
		var p0 := c + Vector3(cos(a0) * r, sin(a0) * r, 0.0)
		var p1 := c + Vector3(cos(a1) * r, sin(a1) * r, 0.0)
		for z in [-1.2, 1.2]:
			lm.beam("Blue", p0 + Vector3(0, 0, z), p1 + Vector3(0, 0, z), 0.3)
		if k % 2 == 0:
			for z in [-1.2, 1.2]:
				lm.beam("Steel", c + Vector3(0, 0, z), p0 + Vector3(0, 0, z), 0.12)
			var g := c + Vector3(cos(a0) * (r + 0.4), sin(a0) * (r + 0.4) - 1.0, 0.0)
			lm.box("Red", g, Vector3(1.8, 1.2, 1.6))
	lm.box("Steel", c, Vector3(1.6, 1.6, 3.2))
	for sx in [-1.0, 1.0]:
		lm.beam("Black", Vector3(c.x + sx * 6.0, 0.2, c.z - 2.4), c, 0.5)
		lm.beam("Black", Vector3(c.x + sx * 6.0, 0.2, c.z + 2.4), c, 0.5)
