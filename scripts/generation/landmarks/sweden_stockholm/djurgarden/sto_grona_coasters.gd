class_name StoGronaCoasters
extends RefCounted

## The two older Gröna Lund coasters for grona_lund_park (true metres, model
## frame = the OSM metre frame of the Eclipse entry minus ORIGIN, +X east,
## +Z south; ORIGIN is the centre of the theatre building the park entry is
## placed on).
##
## Twister (wooden): the plan is the closed OSM circuit of ways 1080776146 (ground), 1080776144 (layer 1),
## 1175531318 and 1080776145 (layer 2), walked in that order. OSM layers are
## crossing order, not altitudes, so the vertical profile (station, lift hill
## to the apex, camel-back hills, layer-1 and layer-2 overpasses, brake run)
## is approximated from the photo in visual-plan/refs/landmarks/
## grona_lund_park/twister.jpg: a plank deck between red steel handrails on
## white painted timber lattice bents (two posts, X-braced every 3.5 m).
## Warm bulbs run up the lift hill.
## Jetline (steel, pale-blue lattice frame with teal track): the plan follows
## the 56 x 42 m outline of OSM way 240080461 inset 2.5 m, one outer lap and
## one inner lap with a lift hill beside the station (way 240080462). The
## vertical profile is approximated from jetline.jpg. The ride closed in 2023
## but is still mapped: set JETLINE to false to leave it out.

const ORIGIN := Vector2(22.9, -143.5)
const JETLINE := true
const TWISTER_APEX := 22.7
const RAIL_H := 1.3
const JET_APEX := 13.5

const TWISTER := [
	# way 1080776146
	[-47.9, 47.3], [-47.4, 45.6], [-47.8, 43.9], [-48.9, 40.5], [-49.9, 38.0], [-50.7, 36.4], [-52.1, 34.9],
	[-56.7, 30.7], [-61.8, 25.6], [-68.7, 18.3], [-71.4, 15.6], [-72.5, 14.7], [-73.8, 14.5], [-75.4, 15.1],
	[-76.6, 16.8], [-77.1, 19.8], [-76.9, 24.2], [-76.1, 28.3], [-73.1, 32.4], [-67.5, 38.5], [-62.1, 45.0],
	[-54.9, 53.6], [-49.3, 60.1], [-45.1, 64.3], [-40.0, 66.6], [-35.2, 67.5], [-29.9, 66.8], [-25.4, 64.1],
	[-23.6, 61.2], [-23.0, 56.4], [-24.2, 51.6], [-25.6, 46.7], [-27.3, 41.1], [-28.1, 38.6], [-29.0, 36.7],
	[-30.6, 34.7], [-33.3, 33.1], [-36.5, 32.5], [-39.3, 32.9], [-41.6, 34.5], [-42.8, 37.1], [-42.1, 40.5],
	[-40.5, 42.7], [-38.1, 43.6], [-35.3, 44.3], [-32.3, 45.5], [-30.5, 47.3], [-29.9, 49.3], [-30.0, 51.3],
	[-30.5, 54.5], [-31.8, 57.1], [-34.0, 58.3], [-36.3, 58.7], [-39.2, 58.5], [-41.5, 57.4], [-43.2, 56.0],
	[-44.9, 53.3], [-45.2, 50.4], [-45.1, 45.9], [-45.3, 39.2], [-45.6, 32.7], [-45.8, 28.2], [-46.2, 26.0],
	[-47.1, 24.3], [-48.6, 23.0], [-50.3, 22.2], [-52.1, 21.8], [-54.5, 21.4], [-58.2, 21.6], [-60.9, 22.8],
	[-62.3, 23.7],
	# way 1080776144 (layer 1)
	[-64.1, 25.5], [-65.5, 27.3], [-66.6, 29.8], [-66.8, 32.7], [-66.2, 35.4], [-64.6, 38.4], [-62.3, 41.1],
	[-57.6, 46.0], [-52.9, 51.3], [-48.3, 57.1], [-45.2, 61.1], [-42.7, 63.5], [-39.9, 64.5], [-37.3, 64.7],
	[-35.3, 63.3], [-34.3, 60.9], [-34.0, 58.1], [-33.9, 54.8], [-33.6, 50.1], [-33.3, 47.5], [-32.8, 44.5],
	[-32.9, 41.5], [-33.8, 39.4], [-35.8, 37.8], [-38.2, 36.7],
	# way 1175531318 (layer 2)
	[-40.1, 36.5], [-41.8, 36.9], [-43.6, 38.0], [-46.2, 40.5], [-48.8, 42.7], [-51.8, 44.3], [-54.4, 44.5],
	[-56.9, 43.3], [-58.4, 40.8], [-58.6, 38.0], [-57.7, 35.7], [-55.9, 34.1], [-52.7, 33.6], [-50.0, 34.1],
	[-47.4, 34.9], [-44.1, 35.6], [-42.5, 35.6], [-40.7, 35.0], [-39.4, 33.7], [-38.8, 32.4], [-38.8, 30.6],
	# way 1080776145 (layer 2)
	[-39.4, 28.9], [-40.3, 27.7], [-41.9, 26.3], [-43.3, 25.8], [-45.2, 25.5], [-47.2, 25.5], [-50.4, 25.5],
	[-53.2, 25.2], [-55.8, 24.9], [-58.4, 25.3], [-61.3, 26.7], [-63.5, 29.2], [-64.1, 32.4], [-63.3, 35.2],
	[-59.8, 39.5], [-57.9, 42.2], [-55.4, 45.1], [-52.6, 47.8], [-50.9, 48.7], [-49.6, 48.4], [-47.9, 47.3],
]

## (fraction of the circuit, deck height m): station, lift hill, apex, hills,
## the layer overpasses over the ground-level wing, brake run.
const TWISTER_PROFILE := [
	[0.00, 4.5], [0.05, 4.5], [0.17, 21.0], [0.20, TWISTER_APEX], [0.27, 8.5], [0.33, 16.0], [0.39, 6.5],
	[0.47, 13.0], [0.53, 6.0], [0.60, 10.5], [0.63, 10.5], [0.70, 14.5], [0.77, 12.0], [0.83, 16.5],
	[0.89, 15.0], [0.96, 7.0], [1.00, 4.5],
]

const JET_OUTLINE := [
	[-71.3, -10.6], [-75.3, -4.0], [-75.1, 3.6], [-71.0, 9.9], [-67.0, 11.8], [-65.8, 12.7], [-61.4, 16.0],
	[-44.9, 10.5], [-46.4, 5.7], [-26.3, -1.1], [-21.3, -9.7], [-19.8, -15.8], [-23.6, -24.5], [-24.7, -24.8],
	[-29.3, -26.2], [-68.1, -11.9],
]

const JET_PROFILE := [
	[0.00, 4.5], [0.04, 4.5], [0.14, JET_APEX], [0.18, JET_APEX], [0.26, 5.5], [0.34, 9.5], [0.42, 5.0],
	[0.50, 8.5], [0.58, 4.8], [0.66, 7.5], [0.74, 4.8], [0.86, 6.5], [1.00, 4.5],
]

static func add(lm: LandmarkMesh) -> void:
	var tw := _frame_points(TWISTER)
	_twister(lm, tw, _heights(tw, TWISTER_PROFILE))
	if JETLINE:
		var jp := _jet_path()
		_jetline(lm, jp, _heights(jp, JET_PROFILE))

static func _frame_points(raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in raw:
		out.append(Vector2(float(p[0]), float(p[1])) - ORIGIN)
	return out

## Deck height at each point from a (fraction, height) profile by the
## cumulative path length, eased between control points.
static func _heights(pts: PackedVector2Array, profile: Array) -> PackedFloat32Array:
	var total := 0.0
	var cum := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
		cum.append(total)
	var out := PackedFloat32Array()
	for i in pts.size():
		var u := cum[i] / maxf(total, 0.001)
		var h: float = float((profile[profile.size() - 1] as Array)[1])
		for k in profile.size() - 1:
			var a: Array = profile[k]
			var b: Array = profile[k + 1]
			if u >= float(a[0]) and u <= float(b[0]):
				var t := (u - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
				h = lerpf(float(a[1]), float(b[1]), 0.5 - 0.5 * cos(PI * t))
				break
		out.append(h)
	return out

static func _lateral(a: Vector3, b: Vector3) -> Vector3:
	var t := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if t.length() < 0.001:
		return Vector3.RIGHT
	return Vector3.UP.cross(t.normalized()).normalized()

static func _twister(lm: LandmarkMesh, pts: PackedVector2Array, hs: PackedFloat32Array) -> void:
	var n := pts.size()
	for i in n - 1:
		var a := Vector3(pts[i].x, hs[i], pts[i].y)
		var b := Vector3(pts[i + 1].x, hs[i + 1], pts[i + 1].y)
		var side := _lateral(a, b)
		lm.beam("Deck", a, b, 1.9, 0.28, side)
		for s in [-1.0, 1.0]:
			var off: Vector3 = side * 1.0 * float(s)
			lm.beam("RedRail", a + off + Vector3.UP * RAIL_H, b + off + Vector3.UP * RAIL_H, 0.16, 0.2, side)
			if i % 3 == 0:
				lm.beam("Lattice", a + off, a + off + Vector3.UP * RAIL_H, 0.14, 0.14)
		if i % 2 == 0:
			_bent(lm, a, side)
		# Warm bulbs up the lift hill.
		if i < 30 and i > 3 and i % 3 == 0 and hs[i] > 6.0 and hs[i] < TWISTER_APEX - 0.5 and hs[i + 1] > hs[i]:
			lm.box("Lit", a + side * 1.15 + Vector3.UP * (RAIL_H + 0.2), Vector3(0.22, 0.22, 0.22), Basis(), 0.0)

## One timber bent under the deck at `a`: two posts to the ground, a cap,
## and X-braces every 3.5 m.
static func _bent(lm: LandmarkMesh, a: Vector3, side: Vector3) -> void:
	var top := a.y - 0.14
	if top < 0.8:
		return
	var l := a + side * 0.9
	var r := a - side * 0.9
	lm.beam("Lattice", Vector3(l.x, 0.0, l.z), Vector3(l.x, top, l.z), 0.28, 0.28)
	lm.beam("Lattice", Vector3(r.x, 0.0, r.z), Vector3(r.x, top, r.z), 0.28, 0.28)
	lm.beam("Lattice", Vector3(l.x, top, l.z), Vector3(r.x, top, r.z), 0.3, 0.3)
	var y := 0.0
	while y + 3.5 < top:
		lm.beam("Lattice", Vector3(l.x, y, l.z), Vector3(r.x, y + 3.5, r.z), 0.14, 0.14)
		lm.beam("Lattice", Vector3(r.x, y, r.z), Vector3(l.x, y + 3.5, l.z), 0.14, 0.14)
		y += 3.5

## Outer lap on the inset outline, then an inner lap at half scale.
static func _jet_path() -> PackedVector2Array:
	var poly := _frame_points(JET_OUTLINE)
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= float(poly.size())
	# Start on the station edge (vertex 6 -> 7).
	var ring := PackedVector2Array()
	for k in poly.size():
		var p := poly[(k + 6) % poly.size()]
		ring.append(p + (c - p).normalized() * 2.5)
	var path := PackedVector2Array()
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		var steps := maxi(int(a.distance_to(b) / 3.0), 1)
		for s in steps:
			path.append(a.lerp(b, float(s) / float(steps)))
	var inner := PackedVector2Array()
	for k in ring.size():
		inner.append(c + (ring[k] - c) * 0.5)
	for k in inner.size():
		var a := inner[k]
		var b := inner[(k + 1) % inner.size()]
		var steps := maxi(int(a.distance_to(b) / 3.0), 1)
		for s in steps:
			path.append(a.lerp(b, float(s) / float(steps)))
	path.append(path[0])
	return path

static func _jetline(lm: LandmarkMesh, pts: PackedVector2Array, hs: PackedFloat32Array) -> void:
	for i in pts.size() - 1:
		var a := Vector3(pts[i].x, hs[i], pts[i].y)
		var b := Vector3(pts[i + 1].x, hs[i + 1], pts[i + 1].y)
		var side := _lateral(a, b)
		lm.beam("JetTrack", a, b, 1.5, 0.3, side)
		for s in [-1.0, 1.0]:
			var off: Vector3 = side * 0.75 * float(s)
			lm.beam("JetTrack", a + off - Vector3.UP * 0.2, b + off - Vector3.UP * 0.2, 0.12, 0.14, side)
		if i % 3 == 0 and a.y > 1.0:
			var l := a + side * 0.7
			var r := a - side * 0.7
			lm.beam("JetFrame", Vector3(l.x, 0.0, l.z), Vector3(l.x, a.y - 0.2, l.z), 0.24, 0.24)
			lm.beam("JetFrame", Vector3(r.x, 0.0, r.z), Vector3(r.x, a.y - 0.2, r.z), 0.24, 0.24)
			lm.beam("JetFrame", Vector3(l.x, a.y - 0.25, l.z), Vector3(r.x, a.y - 0.25, r.z), 0.22, 0.22)
			if a.y > 7.0:
				lm.beam("JetFrame", Vector3(l.x, 0.0, l.z), Vector3(r.x, a.y - 0.4, r.z), 0.12, 0.12)
				lm.beam("JetFrame", Vector3(r.x, 0.0, r.z), Vector3(l.x, a.y - 0.4, l.z), 0.12, 0.12)
	# Flagpoles along the lift hill, as in the photo.
	for k in 5:
		var i := 2 + k * 3
		if i >= pts.size():
			break
		lm.beam("JetFrame", Vector3(pts[i].x, hs[i], pts[i].y), Vector3(pts[i].x, hs[i] + 4.0, pts[i].y), 0.1, 0.1)
