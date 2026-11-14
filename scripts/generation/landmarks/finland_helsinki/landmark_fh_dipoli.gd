class_name LandmarkFhDipoli
extends RefCounted

## Reima Pietilä and Raili Paatelainen's Dipoli (1966), since 2017 Aalto
## University's main building, origin at the registry point (yaw 17),
## parts after the OSM 3D outline (way 4252954, building:parts
## 1573787789–816). Every block stands on timber-framed glazing over a
## dark-stained sill, under a tall fascia of dark weathered copper boards
## that leans out over the glass on a warm timber soffit; low copper roofs
## climb behind the fascias to the main hall at 10 m and the copper
## lanterns at 11 m, and the south-west block carries its long rooflit
## bays. Heaps of pink rapakivi granite boulders bank the walls and lie
## scattered round the building, and the steel pinecone stands before the
## Käpyovi entrance (OSM node 1433646676). Sources and estimates:
## docs/espoo-landmark-sources.md.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

## How far the fascia foot stands out from the glass, and how much more
## its top leans out.
const OVERHANG := 0.9
const LEAN := 0.7
## The steel pinecone before the Käpyovi entrance on the main block.
const PINECONE := Vector2(-8.5, 31.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#434C47", 2.0, 0.55, 0.35))
	lm.use("Roof", LandmarkMaterials.pbr("copper", "#4B5550", 2.5, 0.6, 0.3))
	lm.use("Seam", LandmarkMaterials.paint("#2B322F", 0.6, 0.3))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#A86B3C", 2.0))
	lm.use("Soffit", LandmarkMaterials.pbr("wood", "#8C5E38", 2.0))
	lm.use("Panel", LandmarkMaterials.pbr("wood", "#3A3632", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Plinth", LandmarkMaterials.pbr("concrete", "#6F6C66", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("rock", "#7A5E57", 2.5))
	lm.use("Steel", LandmarkMaterials.paint("#C9CDCF", 0.3, 0.8))
	var blocks := _blocks()
	var polys: Array[PackedVector2Array] = []
	for b in blocks:
		polys.append(b[0])
	# [outline, glass top, fascia top, roof top, roof scale]
	for b in blocks:
		var poly: PackedVector2Array = b[0]
		var glaze: float = b[1]
		var top: float = b[2]
		_walls(lm, poly, glaze)
		var foot := _grow(poly, OVERHANG)
		var head := _grow(poly, OVERHANG + LEAN)
		_underside(lm, "Soffit", foot, glaze)
		_fascia(lm, foot, head, glaze, top)
		if float(b[3]) > top:
			FhP.slope_roof(lm, "Roof", head, FhP.centre(head), float(b[4]), top, float(b[3]))
		else:
			lm.poly_prism("Roof", head, top - 0.02, top)
	_rooflights(lm)
	_boulders(lm, polys)
	_pinecone(lm)
	lm.commit(model)

static func _blocks() -> Array:
	var main := PackedVector2Array([Vector2(11.3, -5.5), Vector2(14.3, -7.6), Vector2(20.1, -7.4),
		Vector2(29.2, -8.8), Vector2(38.9, -9.1), Vector2(44.9, -11.7), Vector2(41.5, -6.3), Vector2(39.8, -3.5),
		Vector2(39.1, 2.5), Vector2(41.6, 9.9), Vector2(34.5, 10.6), Vector2(32.7, 13.8), Vector2(26.6, 18.5),
		Vector2(24.6, 26.8), Vector2(20.5, 35.5), Vector2(21.4, 44.9), Vector2(16.8, 43.3), Vector2(12.7, 43.2),
		Vector2(7.4, 46.5), Vector2(4.4, 49.7), Vector2(1.7, 35.7), Vector2(-3.5, 27.3), Vector2(-8.3, 26.6),
		Vector2(-11.7, 26.8), Vector2(-17.3, 28.1), Vector2(-18.2, 25.5), Vector2(-23.8, 31.5), Vector2(-25.0, 37.3),
		Vector2(-25.3, 41.2), Vector2(-30.3, 41.0), Vector2(-32.6, 43.3), Vector2(-37.0, 38.6), Vector2(-43.3, 35.0),
		Vector2(-46.6, 35.0), Vector2(-45.1, 22.7), Vector2(-47.7, 9.8), Vector2(-36.7, 15.6), Vector2(-31.0, 16.8),
		Vector2(-25.4, 16.7), Vector2(-21.8, 16.5), Vector2(-17.4, 14.3), Vector2(-14.2, 12.7), Vector2(-11.9, 11.5),
		Vector2(-7.0, 9.3), Vector2(-4.2, 6.6), Vector2(-0.9, 3.4), Vector2(0.9, 1.1), Vector2(3.2, -1.9),
		Vector2(5.9, -0.1), Vector2(9.2, -0.2), Vector2(11.4, -3.1)])
	var west := PackedVector2Array([Vector2(-21.3, -7.2), Vector2(-21.8, 16.5), Vector2(-25.4, 16.7),
		Vector2(-31.0, 16.8), Vector2(-36.7, 15.6), Vector2(-39.0, 9.0), Vector2(-40.4, 9.0), Vector2(-39.1, 6.4),
		Vector2(-36.1, 5.7), Vector2(-36.1, -3.4), Vector2(-34.4, -3.4), Vector2(-34.4, -14.3), Vector2(-32.0, -14.3),
		Vector2(-32.0, -15.8), Vector2(-46.0, -15.8), Vector2(-46.0, -18.5), Vector2(-47.3, -18.5),
		Vector2(-47.3, -29.4), Vector2(-32.9, -26.6), Vector2(-21.4, -26.6)])
	var se := PackedVector2Array([Vector2(2.3, -37.0), Vector2(7.1, -39.9), Vector2(7.1, -22.0), Vector2(11.6, -21.9),
		Vector2(15.0, -22.1), Vector2(18.3, -25.3), Vector2(23.8, -19.7), Vector2(24.2, -17.7), Vector2(22.5, -15.6),
		Vector2(18.7, -12.0), Vector2(14.1, -11.9), Vector2(12.7, -8.4), Vector2(11.3, -5.5), Vector2(11.4, -3.1),
		Vector2(9.2, -0.2), Vector2(5.9, -0.1), Vector2(3.2, -1.9)])
	var east := PackedVector2Array([Vector2(17.0, -26.5), Vector2(30.1, -40.0), Vector2(31.7, -37.9),
		Vector2(31.5, -34.6), Vector2(33.8, -30.8), Vector2(37.1, -25.0), Vector2(41.4, -20.7), Vector2(36.7, -16.1),
		Vector2(34.8, -14.2), Vector2(30.9, -13.4), Vector2(31.4, -8.0), Vector2(21.3, -8.4), Vector2(14.3, -7.6),
		Vector2(12.7, -8.4), Vector2(14.1, -11.9), Vector2(18.7, -12.0), Vector2(22.5, -15.6), Vector2(24.2, -17.7)])
	var sw := PackedVector2Array([Vector2(-21.5, -37.0), Vector2(3.2, -37.0), Vector2(3.2, 1.1),
		Vector2(-17.4, 14.3), Vector2(-21.5, 14.3)])
	return [[main, 5.2, 9.0, 10.0, 0.55], [west, 3.0, 5.6, 6.0, 0.8], [se, 2.6, 4.7, 5.0, 0.8],
		[east, 3.0, 5.6, 6.0, 0.8], [sw, 2.8, 5.5, 5.5, 1.0]]

## `poly` grown by d with a mitred offset per vertex (same vertex count, so
## the fascia foot and head rings pair up edge for edge).
static func _grow(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var a := _edge_n(poly, (i + n - 1) % n)
		var b := _edge_n(poly, i)
		var m := a + b
		m = b if m.length() < 0.01 else m.normalized()
		out.append(poly[i] + m * d * clampf(1.0 / maxf(m.dot(b), 0.01), 1.0, 2.0))
	return out

static func _edge_n(poly: PackedVector2Array, i: int) -> Vector2:
	var o := FhP.edge_out(poly, i)
	return Vector2(o.x, o.z)

## Glass walls with timber mullions and transoms on a dark-stained sill;
## about a third of the runs are dark-stained timber instead of glass.
static func _walls(lm: LandmarkMesh, poly: PackedVector2Array, glaze: float) -> void:
	lm.poly_prism("Plinth", poly, 0.0, 0.4, false)
	lm.poly_prism("Glass", poly, 0.4, glaze, false)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 2.0 or _hash(i * 13 + poly.size()) > 0.32:
			continue
		var o := FhP.edge_out(poly, i) * 0.06
		var a3 := Vector3(a.x, 0.0, a.y) + o
		var b3 := Vector3(b.x, 0.0, b.y) + o
		lm.quad("Panel", a3 + Vector3.UP * 0.4, b3 + Vector3.UP * 0.4, b3 + Vector3.UP * glaze,
			a3 + Vector3.UP * glaze, o.normalized())
	W.ribbons(lm, "Panel", poly, 0.4, 0.7, 1, 1.0, 0.04)
	W.ribs(lm, "Timber", poly, 1.1, glaze, 1.7, 0.16, 0.12)
	var rows := maxi(int(glaze / 2.8), 1)
	W.ribbons(lm, "Timber", poly, 1.1, 0.16, rows + 1, (glaze - 1.3) / float(rows), 0.09)

## The leaning copper fascia from `foot` at y0 to `head` at y1, with board
## seams and a coping lip.
static func _fascia(lm: LandmarkMesh, foot: PackedVector2Array, head: PackedVector2Array, y0: float,
		y1: float) -> void:
	var h := y1 - y0
	for i in foot.size():
		var j := (i + 1) % foot.size()
		var a := Vector3(foot[i].x, y0, foot[i].y)
		var b := Vector3(foot[j].x, y0, foot[j].y)
		var c := Vector3(head[j].x, y1, head[j].y)
		var d := Vector3(head[i].x, y1, head[i].y)
		var o := FhP.edge_out(foot, i)
		var n := (o * h + Vector3.DOWN * LEAN).normalized()
		lm.quad("Copper", a, b, c, d, n)
		if a.distance_to(b) < 1.0:
			continue
		var seams := int(h / 0.7)
		for k in range(1, seams):
			var t := float(k) / float(seams)
			var p := a.lerp(d, t) + n * 0.03
			var q := b.lerp(c, t) + n * 0.03
			lm.quad("Seam", p, q, q + Vector3.UP * 0.06, p + Vector3.UP * 0.06, n)
		lm.quad("Seam", d, c, c + Vector3.UP * 0.12 + o * 0.08, d + Vector3.UP * 0.12 + o * 0.08, Vector3.UP)

## Downward-facing cap of `poly` at height y (seen from below).
static func _underside(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(c.x, y, c.y), Vector3(b.x, y, b.y),
			Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, c, b)

## Glazed skillion bays on the south-west block, the copper strip where it
## meets the west wing, and the copper roof lanterns with glazed sides.
static func _rooflights(lm: LandmarkMesh) -> void:
	for r in [[-20.15, 2.7, 6.0], [-12.9, 2.6, 12.0], [-5.25, 2.1, 8.0], [1.7, 3.0, 0.5]]:
		var x: float = r[0]
		var hw: float = float(r[1]) * 0.5
		FhU.wedge(lm, "Glass", "Roof", x - hw, x + hw, -36.6, float(r[2]), 5.5, 0.5, 1.0)
	FhU.wedge(lm, "Copper", "Roof", -21.8, -17.4, -7.2, 14.3, 5.5, 2.5, 2.5)
	for q in [[8.75, 10.0, 5.9, 4.6, 11.0], [19.15, 10.35, 5.9, 7.5, 11.0], [26.55, 9.45, 4.3, 5.1, 11.0],
			[31.7, -2.25, 3.4, 2.7, 10.5], [15.25, -15.7, 2.5, 2.4, 6.5], [25.9, -16.15, 3.0, 2.3, 6.5]]:
		var top: float = q[4]
		FhU.blk(lm, "Copper", float(q[0]), top - 2.2, float(q[1]), float(q[2]), 2.2, float(q[3]))
		FhU.blk(lm, "Glass", float(q[0]), top - 1.8, float(q[1]), float(q[2]) + 0.1, 1.0, float(q[3]) + 0.1)

## Granite boulders heaped against the outer walls, two or three deep,
## and a scatter of single stones in the ground round the building.
static func _boulders(lm: LandmarkMesh, polys: Array[PackedVector2Array]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1966
	for poly in polys:
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var run := a.distance_to(b)
			if run < 2.5 or rng.randf() > 0.55:
				continue
			var o := _edge_n(poly, i)
			if _inside_any((a + b) * 0.5 + o * 2.0, polys):
				continue
			var t0 := rng.randf_range(0.0, 0.3)
			var t1 := rng.randf_range(0.7, 1.0)
			var count := maxi(int(run * (t1 - t0) / 1.1), 1)
			for k in count:
				var p := a.lerp(b, lerpf(t0, t1, (float(k) + rng.randf()) / float(count)))
				var s := rng.randf_range(1.1, 2.0)
				var top := _rock(lm, rng, p + o * (s * 0.45), s, 0.0)
				if rng.randf() < 0.55:
					top = _rock(lm, rng, p + o * (s * 0.35), s * 0.75, top * 0.75)
				if rng.randf() < 0.3:
					_rock(lm, rng, p + o * (s * 0.3), s * 0.55, top * 0.8)
				if rng.randf() < 0.7:
					var f := rng.randf_range(0.7, 1.2)
					_rock(lm, rng, p + o * (s * 1.0 + f * 0.5), f, 0.0)
	var placed := 0
	var tries := 0
	while placed < 70 and tries < 400:
		tries += 1
		var poly: PackedVector2Array = polys[rng.randi() % polys.size()]
		var i := rng.randi() % poly.size()
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var p := a.lerp(b, rng.randf()) + _edge_n(poly, i) * rng.randf_range(2.5, 4.5)
		if _inside_any(p, polys, 2.0):
			continue
		_rock(lm, rng, p, rng.randf_range(0.6, 1.4), 0.0)
		placed += 1

## One angular boulder about `s` across at p, its lowest corner `lift`
## above the ground; returns the height of its top.
static func _rock(lm: LandmarkMesh, rng: RandomNumberGenerator, p: Vector2, s: float, lift: float) -> float:
	var basis := Basis.from_euler(Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU,
		rng.randf_range(-0.35, 0.35)))
	var size := Vector3(s * rng.randf_range(0.8, 1.3), s * rng.randf_range(0.6, 0.95), s * rng.randf_range(0.7, 1.1))
	var half := (absf(basis.x.y) * size.x + absf(basis.y.y) * size.y + absf(basis.z.y) * size.z) * 0.5
	lm.box("Granite", Vector3(p.x, lift + half, p.y), size, basis)
	return lift + half * 2.0

static func _inside_any(p: Vector2, polys: Array[PackedVector2Array], margin: float = 0.0) -> bool:
	for poly in polys:
		if Geometry2D.is_point_in_polygon(p, poly):
			return true
		if margin > 0.0:
			for i in poly.size():
				if Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()]).distance_to(p) < margin:
					return true
	return false

## Steel pinecone on its stem: five tiers of petals round a core.
static func _pinecone(lm: LandmarkMesh) -> void:
	var c := Vector3(PINECONE.x, 0.0, PINECONE.y)
	lm.frustum("Plinth", c, 0.6, 0.6, 0.3, 12)
	lm.frustum("Steel", c + Vector3.UP * 0.3, 0.09, 0.09, 2.2, 8)
	var base := c + Vector3.UP * 2.5
	lm.lathe("Steel", base, FhU.dome_prof(0.55, 1.4, 6), 12)
	for tier in 5:
		var y := 0.15 + 0.32 * float(tier)
		var r := 0.55 + 0.75 * sin(PI * (float(tier) + 0.8) / 6.0)
		var tilt := lerpf(1.1, 0.35, float(tier) / 4.0)
		for k in 10:
			var ang := TAU * (float(k) + 0.5 * float(tier % 2)) / 10.0
			var d := Vector3(cos(ang), 0.0, sin(ang))
			var basis := Basis(Vector3.UP, -ang) * Basis(Vector3.BACK, tilt)
			lm.box("Steel", base + d * (r * 0.55) + Vector3.UP * y, Vector3(r * 0.9, 0.04, 0.5), basis, 0.0)

static func _hash(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
