class_name LandmarkSfAlcatraz
extends RefCounted

## Alcatraz Island: the 540 x 205 m rock in the Bay with the 1912 Main
## Cellhouse, the 1909 lighthouse on the summit knoll, the dock, the
## industries and powerhouse at the north-west end, the water tower and
## the burned ruins. Built along +X (bearing 125 degrees, the island's
## long axis; yaw_deg 35) with y = 0 at sea level (`base: sea`). The
## rock follows the mapped shoreline, with a continuous cliff slope, a
## 40 m cellhouse/lighthouse terrace and lower dock/parade ground. The
## lighthouse is 29 m tall (NPS: 95 feet), its tip at 69 m ASL.
## Layout: https://www.nps.gov/goga/planyourvisit/upload/Alcatraz-map-Access-508.pdf
## Heights: https://www.nps.gov/places/000/alcatraz-lighthouse.htm
## This is an exterior reconstruction, not a surveyed terrain model.

static var ISLAND := PackedVector2Array([
	Vector2(64.6, -99.1),
	Vector2(37.9, -93.3),
	Vector2(15.2, -92.7),
	Vector2(-3.3, -89.3),
	Vector2(-44.5, -98.7),
	Vector2(-59.3, -100.3),
	Vector2(-77.7, -106.6),
	Vector2(-106.8, -101.0),
	Vector2(-125.0, -88.7),
	Vector2(-137.5, -91.4),
	Vector2(-146.9, -90.3),
	Vector2(-167.8, -92.9),
	Vector2(-175.9, -87.3),
	Vector2(-182.2, -76.4),
	Vector2(-200.0, -70.4),
	Vector2(-208.2, -63.7),
	Vector2(-210.8, -58.2),
	Vector2(-220.0, -58.2),
	Vector2(-225.3, -52.6),
	Vector2(-235.7, -49.0),
	Vector2(-239.8, -37.9),
	Vector2(-247.4, -38.1),
	Vector2(-257.2, -25.8),
	Vector2(-261.1, -13.1),
	Vector2(-259.3, -3.9),
	Vector2(-256.8, 1.7),
	Vector2(-252.6, 4.0),
	Vector2(-251.4, 8.3),
	Vector2(-240.6, 12.7),
	Vector2(-237.4, 19.9),
	Vector2(-213.7, 17.5),
	Vector2(-211.2, 11.7),
	Vector2(-203.4, 11.6),
	Vector2(-180.2, 21.0),
	Vector2(-176.9, 23.4),
	Vector2(-176.3, 26.8),
	Vector2(-136.8, 52.9),
	Vector2(-114.2, 59.4),
	Vector2(-94.7, 55.6),
	Vector2(-89.3, 71.8),
	Vector2(-90.4, 76.8),
	Vector2(-88.2, 80.2),
	Vector2(-68.9, 81.6),
	Vector2(-60.6, 71.5),
	Vector2(-38.0, 68.8),
	Vector2(-35.2, 62.7),
	Vector2(-27.9, 56.2),
	Vector2(-16.0, 58.6),
	Vector2(-11.7, 61.4),
	Vector2(-2.2, 76.0),
	Vector2(1.2, 85.3),
	Vector2(10.2, 89.0),
	Vector2(44.2, 83.5),
	Vector2(54.0, 85.8),
	Vector2(78.3, 77.0),
	Vector2(85.7, 78.3),
	Vector2(99.6, 75.9),
	Vector2(118.8, 91.1),
	Vector2(121.6, 90.9),
	Vector2(140.9, 83.5),
	Vector2(172.2, 80.9),
	Vector2(208.8, 81.9),
	Vector2(216.4, 79.9),
	Vector2(225.3, 75.4),
	Vector2(253.0, 51.6),
	Vector2(256.0, 52.3),
	Vector2(272.3, 29.3),
	Vector2(279.0, 16.5),
	Vector2(279.7, -10.5),
	Vector2(272.0, -46.4),
	Vector2(240.8, -76.5),
	Vector2(224.7, -81.5),
	Vector2(190.2, -87.6),
	Vector2(190.5, -91.4),
	Vector2(164.1, -95.9),
	Vector2(166.7, -107.5),
	Vector2(164.8, -109.9),
	Vector2(115.6, -113.7),
	Vector2(115.5, -102.1),
	Vector2(81.4, -101.4),
	Vector2(81.3, -93.1),
	Vector2(75.4, -93.0)])

const KNOLL_C := Vector2(103.0, 3.0)
const SUMMIT_M := 40.0
const LIGHT_M := 29.0
const SHORE_M := 3.0
const SURFACE_STEP_M := 5.0
static var _terraces: Array = []
const DOCK_POLY := [Vector2(81.4, -95.0), Vector2(81.4, -101.4), Vector2(115.5, -102.1), Vector2(115.6, -113.7),
	Vector2(164.8, -109.9), Vector2(166.7, -107.5), Vector2(164.1, -95.9)]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wet", LandmarkMaterials.pbr("rock", "#4C4A46", 5.0))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7B7165", 6.0))
	lm.use("Ground", LandmarkMaterials.pbr("grass", "#666A43", 4.0))
	lm.use("Terrain", LandmarkMaterials.pbr("grass", "#666A43", 4.0))
	lm.use("Yard", LandmarkMaterials.pbr("gravel", "#85816F", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("render", "#B6B3AA", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#CFC3A8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4B4D50", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2C363C"))
	lm.use("Rust", LandmarkMaterials.paint("#8A4B32", 0.7, 0.35))
	lm.use("White", LandmarkMaterials.pbr("render", "#ECE8DE", 3.0))
	lm.use("Light", LandmarkMaterials.lit("#FFE7A8", 1.0))
	lm.use("Ruin", LandmarkMaterials.pbr("render", "#9B9384", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#4A4F52", 0.55, 0.45))
	lm.use("Asphalt", LandmarkMaterials.pbr("asphalt", "#3E3E3E", 4.0))
	_rock(lm)
	var gy := ground_height
	var B := LandmarkSfAlcatrazBuildings
	B.cellhouse(lm, gy, Vector2(24.0, 2.1))
	B.admin(lm, gy, Vector2(71.5, 4.0))
	B.lighthouse(lm, KNOLL_C + Vector2(-2.0, 0.4), SUMMIT_M, LIGHT_M)
	B.sally_port(lm, gy, Vector2(38.3, -84.8))
	B.guard_tower(lm, gy, Vector2(83.9, -97.9), 135.0)
	B.guard_tower(lm, gy, Vector2(70.0, 38.0), 135.0, 9.5)
	B.guard_tower(lm, gy, Vector2(-78.0, 42.0), 135.0, 9.5)
	B.guard_tower(lm, gy, Vector2(-212.0, -30.0), 150.0, 9.0)
	B.apartments(lm, gy, Vector2(115.2, -68.5))
	B.ruin(lm, gy, Vector2(124.8, -22.6), Vector2(18.0, 13.0), 140.0, 8.5)
	B.chapel(lm, gy, Vector2(20.9, -82.1))
	B.ruin(lm, gy, Vector2(-61.0, -85.5), Vector2(32.0, 14.0), 123.0, 7.5)
	B.hall(lm, gy, Vector2(-31.2, -9.2), Vector2(48.0, 20.0), 141.0, 9.0, Vector2(1.9, 3.2), 4.4, 4.4, "Concrete")
	B.water_tower(lm, gy, Vector2(-100.7, -33.4))
	B.quartermaster(lm, gy, Vector2(-148.1, -70.4))
	B.powerhouse(lm, gy, Vector2(-187.5, -57.7))
	B.hall(lm, gy, Vector2(-158.3, 6.9), Vector2(90.0, 22.0), 148.0, 9.5, Vector2(2.6, 2.6), 4.5, 4.0, "Concrete", true)
	B.hall(lm, gy, Vector2(-228.0, 0.0), Vector2(40.0, 24.0), 151.0, 11.0, Vector2(1.8, 2.4), 3.6, 3.6, "Concrete")
	var dock := PackedVector2Array()
	for p in DOCK_POLY:
		dock.append(p)
	B.dock(lm, dock, SHORE_M)
	_roads(lm, gy)
	_boulders(lm)
	for part in lm.commit(model):
		if part.name == "Terrain":
			part.set_surface_override_material(0, LandmarkSfAlcatrazSurface.material())

## Continuous relief: steep coastal rock, the summit prison terrace,
## the lower parade ground at the SE tip and the east-side dock climb.
## Shared with the camera so walking never falls into the DEM underneath.
static func ground_height(p: Vector2) -> float:
	if p.x < -262.0 or p.x > 281.0 or p.y < -115.0 or p.y > 92.0:
		return -1.0
	if not Geometry2D.is_point_in_polygon(p, ISLAND):
		return -1.0
	return _height_inside(p)

static func _shore_distance(p: Vector2) -> float:
	var d := INF
	for i in ISLAND.size():
		var q := Geometry2D.get_closest_point_to_segment(p, ISLAND[i], ISLAND[(i + 1) % ISLAND.size()])
		d = minf(d, p.distance_to(q))
	return d

static func _height_inside(p: Vector2) -> float:
	var top := lerpf(16.0, SUMMIT_M, smoothstep(-235.0, -65.0, p.x))
	top = lerpf(top, 16.0, smoothstep(120.0, 205.0, p.x))
	if p.x > 30.0 and p.x < 175.0:
		top = lerpf(SHORE_M, top, smoothstep(-97.0, -30.0, p.y))
	var shore := _shore_distance(p)
	var bank := smoothstep(0.0, 20.0, shore)
	var strata := sin(p.x * 0.19 + sin(p.y * 0.23)) * sin(p.y * 0.37 + p.x * 0.07)
	var y := maxf(SHORE_M, lerpf(SHORE_M, top, bank) + strata * bank * (1.0 - bank) * 2.0)
	for pad in _building_terraces():
		var d: Vector2 = p - (pad[0] as Vector2)
		var axis: Vector2 = pad[2]
		var along := absf(d.dot(axis)) - (pad[1] as Vector2).x
		var across := absf(d.dot(Vector2(-axis.y, axis.x))) - (pad[1] as Vector2).y
		var blend := smoothstep(0.0, 6.0, maxf(along, across))
		y = lerpf(float(pad[3]), y, blend)
	return lerpf(SHORE_M, y, smoothstep(0.0, 3.0, shore))

## Local grading around the buildings: the barracks and gatehouse stand
## below the summit, rather than on giant foundations reaching up to it.
## Heights are exterior-model approximations; footprints follow the model.
static func _building_terraces() -> Array:
	if not _terraces.is_empty():
		return _terraces
	var rows := [
		[Vector2(38.3, -84.8), Vector2(14, 9.5), 136.0, 8.0],
		[Vector2(115.2, -68.5), Vector2(36, 9), 135.0, 14.0],
		[Vector2(20.9, -82.1), Vector2(10, 7.5), 107.0, 10.0],
		[Vector2(-148.1, -70.4), Vector2(18, 7.5), 130.0, 14.0],
		[Vector2(-187.5, -57.7), Vector2(21, 13), 78.0, 14.0],
		[Vector2(-158.3, 6.9), Vector2(46, 12), 148.0, 19.0],
		[Vector2(-228, 0), Vector2(21, 13), 151.0, 15.0],
		[Vector2(-61, -85.5), Vector2(17, 8), 123.0, 18.0],
		[Vector2(124.8, -22.6), Vector2(10, 7.5), 140.0, 37.0],
		[Vector2(-31.2, -9.2), Vector2(25, 11), 141.0, 40.0],
		[Vector2(24, 2.1), Vector2(69.5, 16), 137.0, 40.0],
		[Vector2(71.5, 4), Vector2(19, 10.5), 53.0, 40.0],
	]
	var out: Array = []
	for row in rows:
		var a := deg_to_rad(float(row[2]) - LandmarkSfAlcatrazBuildings.ISLAND_BEARING)
		out.append([row[0], row[1], Vector2(cos(a), sin(a)), row[3]])
	_terraces = out
	return _terraces

static func _normal(p: Vector2) -> Vector3:
	var dx := _height_inside(p + Vector2(0.5, 0)) - _height_inside(p - Vector2(0.5, 0))
	var dz := _height_inside(p + Vector2(0, 0.5)) - _height_inside(p - Vector2(0, 0.5))
	return Vector3(-dx, 1.0, -dz).normalized()

static func _rock(lm: LandmarkMesh) -> void:
	lm.poly_prism("Wet", ISLAND, -2.0, SHORE_M, false)
	var pts := PackedVector2Array()
	# Densify the actual coastline, then triangulate a fine interior grid.
	for i in ISLAND.size():
		var a := ISLAND[i]
		var b := ISLAND[(i + 1) % ISLAND.size()]
		var steps := maxi(1, ceili(a.distance_to(b) / SURFACE_STEP_M))
		for j in steps:
			pts.append(a.lerp(b, float(j) / float(steps)))
	for z in range(-110, 91, int(SURFACE_STEP_M)):
		for x in range(-260, 280, int(SURFACE_STEP_M)):
			var p := Vector2(x, z)
			if Geometry2D.is_point_in_polygon(p, ISLAND) and _shore_distance(p) > 1.0:
				pts.append(p)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for p in pts:
		verts.append(Vector3(p.x, _height_inside(p), p.y))
		normals.append(_normal(p))
	var idx := Geometry2D.triangulate_delaunay(pts)
	for i in range(0, idx.size(), 3):
		var a := idx[i]
		var b := idx[i + 1]
		var c := idx[i + 2]
		var mid := (pts[a] + pts[b] + pts[c]) / 3.0
		if not Geometry2D.is_point_in_polygon(mid, ISLAND):
			continue
		lm.tri("Terrain", verts[a], verts[b], verts[c], normals[a], normals[b], normals[c], pts[a], pts[b], pts[c])

## The switchback climb follows the relief in short graded segments.
static func _roads(lm: LandmarkMesh, gy: Callable) -> void:
	var pts: Array[Vector2] = [Vector2(120.0, -97.0), Vector2(92.0, -86.0), Vector2(58.0, -74.0),
		Vector2(44.0, -62.0), Vector2(66.0, -48.0), Vector2(52.0, -30.0), Vector2(70.0, -16.0)]
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var steps := maxi(1, ceili(a.distance_to(b) / 2.0))
		var d := (b - a).normalized()
		var side := Vector3(-d.y, 0, d.x)
		for j in steps:
			var p := a.lerp(b, float(j) / float(steps))
			var q := a.lerp(b, float(j + 1) / float(steps))
			var p3 := Vector3(p.x, float(gy.call(p)) + 0.18, p.y)
			var q3 := Vector3(q.x, float(gy.call(q)) + 0.18, q.y)
			lm.beam("Asphalt", p3, q3, 4.2, 0.2, side)
			for s in [-1.0, 1.0]:
				var off := side * float(s) * 2.2 + Vector3.UP * 0.12
				lm.beam("Concrete", p3 + off, q3 + off, 0.22, 0.3, side)

## Low outcrops break up the cliff foot without regular shelf rings.
static func _boulders(lm: LandmarkMesh) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in range(0, ISLAND.size(), 2):
		var p := ISLAND[i].lerp(Vector2.ZERO, 0.035)
		var y := ground_height(p)
		if y < SHORE_M:
			continue
		var s := rng.randf_range(1.0, 2.6)
		var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3))
		lm.box("Rock", Vector3(p.x, y - s * 0.25, p.y), Vector3(s * 1.6, s, s), basis, 0.15)
