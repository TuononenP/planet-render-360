extends RefCounted

## Helsinki Ice Hall (Helsingin jäähalli, Nordenskiöldinkatu 11-13, 1966).
## Origin at the centroid of OSM way 99404270 (9337 m2, 60.189276 N
## 24.92253 E), yaw -40.6 so the hall's long walls run along the model axes.
##
## From the photographs (visual-plan/refs/landmarks/helsinki_ice_hall/): a
## wide, low arena whose bowed outer walls are one continuous curtain wall of
## glass on a grid of slender mullions and transoms, under a deep dark
## graphite fascia with round vents, and a shallow barrel-vaulted roof of
## dark grey sheet metal. A concrete pier and low concrete plinth stand at
## the corners, with entrance doors on the low front.
##
## Measured: the outline (OSM, 22 points simplified to 0.7 m, 105 x 105 m)
## and its orientation. Estimated: the 11 m glazing height, the fascia, the
## roof rise (to 20 m, the registry value), mullion spacing. The registry
## point was 370 m south of the building.

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const ENTRY := {"type": "helsinki_ice_hall", "name": "Helsinki Ice Hall", "lat": 60.189276, "lon": 24.92253,
	"radius_m": 1500.0, "wiki_title": "Helsinki Ice Hall", "height_m": 20.0, "clear_m": 70.0,
	"yaw_deg": -40.6, "kind": "Arena", "aliases": ["helsinki ice hall", "helsingin jäähalli", "nordis", "helsingfors ishall"]}

const OUTLINE := [Vector2(-44.4, 55.9), Vector2(-49.2, 39.0), Vector2(-52.9, 9.1), Vector2(-50.8, -13.1),
	Vector2(-42.7, -40.1), Vector2(-29.7, -39.5), Vector2(-29.1, -44.4), Vector2(-18.2, -44.6), Vector2(24.7, -43.6),
	Vector2(24.9, -39.0), Vector2(38.2, -39.6), Vector2(44.3, -14.1), Vector2(45.6, 4.2), Vector2(52.0, 5.0),
	Vector2(51.9, 10.6), Vector2(45.4, 10.1), Vector2(44.6, 21.9), Vector2(37.5, 55.9), Vector2(23.4, 55.8),
	Vector2(23.3, 60.5), Vector2(-29.4, 60.5), Vector2(-29.5, 56.4)]
const WALL := 11.5
const TOP := 20.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A7A9A6", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#7FA2B2", 0.18, 0.3))
	lm.use("Frame", LandmarkMaterials.paint("#7E8588", 0.5, 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#4C5053", 0.55, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1CC", 1.2))
	var poly := PackedVector2Array(OUTLINE)
	lm.poly_prism("Concrete", F.offset(poly, 0.2), 0.0, 1.1)
	lm.poly_prism("Glass", poly, 1.1, WALL, false)
	for i in poly.size():
		_curtain(lm, poly, i)
	# Dark graphite fascia band and shallow barrel-vault arch roof with structural ribs.
	lm.poly_prism("Roof", F.offset(poly, 0.8), WALL, WALL + 2.4, false)
	_barrel_vault(lm, F.offset(poly, 0.8), WALL + 2.4, TOP - 0.3)
	# Fascia vents (round, lit).
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 14.0:
			continue
		var o := FhP.edge_out(poly, i)
		var n := int(a.distance_to(b) / 7.0)
		for k in n:
			var p := a.lerp(b, (float(k) + 0.5) / float(n)) + Vector2(o.x, o.z) * 0.85
			lm.disc("Lamp", Vector3(p.x, WALL + 1.2, p.y), o, 0.4, 10)
	# Corner pier of the entrance block.
	lm.box("Concrete", Vector3(48.0, 6.0, 8.0), Vector3(5.0, 12.0, 8.0))
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-68.0, 1.5, 6.0), Vector3(-44.0, 11.0, 6.0), 50.0, 0.9, 70.0, warm],
		[Vector3(68.0, 1.5, 6.0), Vector3(42.0, 11.0, 6.0), 50.0, 0.9, 70.0, warm],
		[Vector3(-2.0, 1.5, 76.0), Vector3(-2.0, 13.0, 52.0), 52.0, 0.95, 75.0, warm],
		[Vector3(-2.0, 1.5, -62.0), Vector3(-2.0, 13.0, -38.0), 52.0, 0.85, 75.0, warm],
	])

## Shallow parabolic barrel-vault roof over `roof_poly` peaking at `y_crown`,
## closed along the perimeter from `y_spring` and crossed by structural arch ribs.
static func _barrel_vault(lm: LandmarkMesh, roof_poly: PackedVector2Array, y_spring: float, y_crown: float) -> void:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in roof_poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var mid_x := (lo.x + hi.x) * 0.5
	var half_x := maxf((hi.x - lo.x) * 0.5, 1.0)
	var vault_y := func(x: float) -> float:
		var t := clampf((x - mid_x) / half_x, -1.0, 1.0)
		return lerpf(y_spring, y_crown, 1.0 - t * t)
	var vault_n := func(x: float) -> Vector3:
		var t := clampf((x - mid_x) / half_x, -1.0, 1.0)
		var dydx := -2.0 * (y_crown - y_spring) * t / half_x
		return Vector3(-dydx, 1.0, 0.0).normalized()
	var nx := 18
	var nz := 14
	for ix in nx:
		var x0 := lerpf(lo.x, hi.x, float(ix) / float(nx))
		var x1 := lerpf(lo.x, hi.x, float(ix + 1) / float(nx))
		for iz in nz:
			var z0 := lerpf(lo.y, hi.y, float(iz) / float(nz))
			var z1 := lerpf(lo.y, hi.y, float(iz + 1) / float(nz))
			var cell := PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])
			for piece in Geometry2D.intersect_polygons(roof_poly, cell):
				var idx := Geometry2D.triangulate_polygon(piece)
				for t in range(0, idx.size(), 3):
					var pa := piece[idx[t]]
					var pb := piece[idx[t + 1]]
					var pc := piece[idx[t + 2]]
					var va := Vector3(pa.x, vault_y.call(pa.x), pa.y)
					var vb := Vector3(pb.x, vault_y.call(pb.x), pb.y)
					var vc := Vector3(pc.x, vault_y.call(pc.x), pc.y)
					lm.tri("Roof", va, vb, vc, vault_n.call(pa.x), vault_n.call(pb.x), vault_n.call(pc.x),
						Vector2(pa.x, pa.y), Vector2(pb.x, pb.y), Vector2(pc.x, pc.y))
	# Vertical tympanum closure from fascia top up to the curved barrel vault.
	for i in roof_poly.size():
		var a := roof_poly[i]
		var b := roof_poly[(i + 1) % roof_poly.size()]
		var o := FhP.edge_out(roof_poly, i)
		var segs := maxi(1, int(ceil(a.distance_to(b) / 3.0)))
		for k in segs:
			var p0 := a.lerp(b, float(k) / float(segs))
			var p1 := a.lerp(b, float(k + 1) / float(segs))
			lm.quad("Roof", Vector3(p0.x, y_spring, p0.y), Vector3(p1.x, y_spring, p1.y),
				Vector3(p1.x, vault_y.call(p1.x), p1.y), Vector3(p0.x, vault_y.call(p0.x), p0.y), o)
	# Structural steel arch ribs spanning across the barrel vault.
	var rib_count := 7
	for r in rib_count:
		var z := lerpf(lo.y + 10.0, hi.y - 10.0, float(r) / float(rib_count - 1))
		var xs: Array[float] = []
		for i in roof_poly.size():
			var a := roof_poly[i]
			var b := roof_poly[(i + 1) % roof_poly.size()]
			if (a.y <= z and b.y > z) or (b.y <= z and a.y > z):
				var u := (z - a.y) / (b.y - a.y)
				xs.append(lerpf(a.x, b.x, u))
		if xs.size() < 2:
			continue
		xs.sort()
		var rx0 := xs[0] + 0.5
		var rx1 := xs[xs.size() - 1] - 0.5
		var segs := 16
		var prev := Vector3(rx0, vault_y.call(rx0) + 0.05, z)
		for k in range(1, segs + 1):
			var x := lerpf(rx0, rx1, float(k) / float(segs))
			var cur := Vector3(x, vault_y.call(x) + 0.05, z)
			lm.beam("Frame", prev, cur, 0.55, 0.6, Vector3(0, 0, 1))
			prev = cur

## One wall edge of the curtain: mullions every 2.4 m, transoms every 2.6 m.
static func _curtain(lm: LandmarkMesh, poly: PackedVector2Array, i: int) -> void:
	var a := poly[i]
	var b := poly[(i + 1) % poly.size()]
	if a.distance_to(b) < 6.0:
		return
	var o := FhP.edge_out(poly, i)
	var a3 := Vector3(a.x, 0, a.y) + o * 0.04
	var b3 := Vector3(b.x, 0, b.y) + o * 0.04
	FhP.ribs(lm, "Frame", a3, b3, o, 1.1, WALL, 2.4, 0.1, 0.12)
	for k in 4:
		FhP.band(lm, "Frame", a3, b3, o, 1.1 + 2.6 * float(k), 0.1, 0.12)
	FhP.band(lm, "Frame", a3, b3, o, WALL - 0.2, 0.3, 0.2)
