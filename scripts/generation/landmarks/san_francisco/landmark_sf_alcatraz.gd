class_name LandmarkSfAlcatraz
extends RefCounted

## Alcatraz Island: the 540 x 205 m rock in the Bay with the 1912 Main
## Cellhouse, the 1909 lighthouse on the summit knoll, the dock, the
## industries and powerhouse at the north-west end, the water tower and
## the burned ruins. Built along +X (bearing 125 degrees, the island's
## long axis; yaw_deg 35) with y = 0 at the water (`base: water`). The
## rock is a stack of inset copies of the real OSM shoreline (cliffs to
## 24 m, plateau at 28 m, summit knoll at 40 m), thinner terraces beside
## the dock; every building takes its pad height from that stack. The
## lighthouse tip stands at 66 m.

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

const SHORE_TOPS := [3.0, 8.0, 13.0, 18.0, 24.0, 28.0]
const SHORE_INSET := [0.0, 3.0, 6.0, 9.0, 12.0, 16.0]
## Terraces beside the dock (x 30..175): the layer k only starts north of
## this z, so the ground climbs from the pier to the plateau.
const DOCK_CUT := [-140.0, -97.0, -90.0, -80.0, -68.0, -56.0]
const KNOLL_C := Vector2(103.0, 3.0)
const KNOLL_R := [24.0, 19.0, 14.0]
const KNOLL_TOPS := [33.0, 37.0, 40.0]
const SUMMIT_M := 40.0
const LIGHT_M := 26.0
const DOCK_POLY := [Vector2(81.4, -95.0), Vector2(81.4, -101.4), Vector2(115.5, -102.1), Vector2(115.6, -113.7),
	Vector2(164.8, -109.9), Vector2(166.7, -107.5), Vector2(164.1, -95.9)]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wet", LandmarkMaterials.pbr("rock", "#4C4A46", 5.0))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7B7165", 6.0))
	lm.use("Ground", LandmarkMaterials.pbr("grass", "#666A43", 4.0))
	lm.use("Yard", LandmarkMaterials.pbr("gravel", "#85816F", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B6B3AA", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#CFC3A8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4B4D50", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2C363C"))
	lm.use("Rust", LandmarkMaterials.paint("#8A4B32", 0.7, 0.35))
	lm.use("White", LandmarkMaterials.pbr("render", "#ECE8DE", 3.0))
	lm.use("Light", LandmarkMaterials.lit("#FFE7A8", 1.0))
	lm.use("Ruin", LandmarkMaterials.pbr("concrete", "#78726A", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#4A4F52", 0.55, 0.45))
	lm.use("Asphalt", LandmarkMaterials.pbr("asphalt", "#3E3E3E", 4.0))
	var g := _rock(lm)
	var gy := func(p: Vector2) -> float: return _ground(g, p)
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
	B.dock(lm, dock, SHORE_TOPS[0])
	_roads(lm, gy)
	_boulders(lm, g)
	lm.commit(model)

## Rock: shoreline slab, cliff shells, plateau and the summit knoll.
## Returns {"layers": [[poly...] per level], "knoll": [[poly...] per level]}.
static func _rock(lm: LandmarkMesh) -> Dictionary:
	var layers: Array = []
	var knoll: Array = []
	for k in SHORE_TOPS.size():
		var polys := _layer(k)
		layers.append(polys)
		var y0 := 0.0 if k == 0 else float(SHORE_TOPS[k - 1]) - 0.3
		var y1 := float(SHORE_TOPS[k])
		for p in polys:
			var poly: PackedVector2Array = p
			lm.poly_prism("Wet" if k == 0 else "Rock", poly, y0, y1, false)
			_cap(lm, "Wet" if k == 0 else ("Ground" if k < 5 else "Yard"), poly, y1)
	for k in KNOLL_R.size():
		var poly := PackedVector2Array()
		var rng := RandomNumberGenerator.new()
		rng.seed = 90 + k
		for i in 28:
			var a := TAU * float(i) / 28.0
			var r: float = float(KNOLL_R[k]) * (1.0 + (rng.randf() - 0.5) * 0.14)
			poly.append(KNOLL_C + Vector2(cos(a) * r * 1.15, sin(a) * r))
		knoll.append([poly])
		var y0 := 28.0 if k == 0 else float(KNOLL_TOPS[k - 1]) - 0.3
		lm.poly_prism("Rock", poly, y0, float(KNOLL_TOPS[k]), false)
		_cap(lm, "Ground", poly, float(KNOLL_TOPS[k]))
	return {"layers": layers, "knoll": knoll}

## Polygons of one shell: the shoreline inset, roughened a little, and
## cut off the dock terrace strip above its step.
static func _layer(k: int) -> Array:
	var raw: Array = [ISLAND] if float(SHORE_INSET[k]) == 0.0 else Geometry2D.offset_polygon(ISLAND, -float(SHORE_INSET[k]), Geometry2D.JOIN_ROUND)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + k
	var out: Array = []
	for p in raw:
		var poly: PackedVector2Array = p
		if poly.size() < 3:
			continue
		if k > 0:
			for i in poly.size():
				poly[i] += Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * 1.6
		var cut := PackedVector2Array([Vector2(30.0, -160.0), Vector2(175.0, -160.0),
			Vector2(175.0, float(DOCK_CUT[k])), Vector2(30.0, float(DOCK_CUT[k]))])
		for q in Geometry2D.clip_polygons(poly, cut):
			var piece: PackedVector2Array = q
			if not Geometry2D.is_polygon_clockwise(piece) and piece.size() >= 3:
				out.append(piece)
	return out

static func _cap(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a * 0.5, b * 0.5, c * 0.5)

## Height of the ground at an island point (highest level covering it),
## -1 off the island.
static func _ground(g: Dictionary, p: Vector2) -> float:
	for k in range(KNOLL_R.size() - 1, -1, -1):
		for poly in (g["knoll"] as Array)[k]:
			if Geometry2D.is_point_in_polygon(p, poly):
				return float(KNOLL_TOPS[k])
	var layers: Array = g["layers"]
	for k in range(layers.size() - 1, -1, -1):
		for poly in layers[k]:
			if Geometry2D.is_point_in_polygon(p, poly):
				return float(SHORE_TOPS[k])
	return -1.0

## The switchback road from the dock to the cellhouse, each leg a flat
## graded strip at the highest ground along it.
static func _roads(lm: LandmarkMesh, gy: Callable) -> void:
	var pts: Array[Vector2] = [Vector2(120.0, -97.0), Vector2(92.0, -86.0), Vector2(58.0, -74.0),
		Vector2(44.0, -62.0), Vector2(66.0, -48.0), Vector2(52.0, -30.0), Vector2(70.0, -16.0)]
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var top := 0.0
		for s in 6:
			top = maxf(top, float(gy.call(a.lerp(b, float(s) / 5.0))))
		if top <= 0.0:
			continue
		var d := b - a
		var len := d.length()
		var mid := (a + b) * 0.5
		var ang := atan2(-d.y, d.x)
		lm.box("Asphalt", Vector3(mid.x, top - 0.2, mid.y), Vector3(len + 3.0, 0.4, 4.2), Basis(Vector3.UP, ang), 0.0)
		lm.box("Concrete", Vector3(mid.x, top - 1.8, mid.y), Vector3(len + 2.0, 3.0, 3.6), Basis(Vector3.UP, ang), 0.0)

## Rocks along the cliff ledges, to break the stepped outline.
static func _boulders(lm: LandmarkMesh, g: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var layers: Array = g["layers"]
	for k in range(1, 5):
		for poly in layers[k]:
			var pl: PackedVector2Array = poly
			var step := 2 if k < 3 else 3
			for i in range(0, pl.size(), step):
				var s := 1.8 + rng.randf() * 2.6
				var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, (rng.randf() - 0.5) * 0.6)
				lm.box("Rock", Vector3(pl[i].x, float(SHORE_TOPS[k]) - s * 0.15, pl[i].y),
					Vector3(s * 1.3, s * 0.9, s), b, 0.0)
