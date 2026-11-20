class_name StoIslandModerna
extends RefCounted

## Moderna Museet on Skeppsholmen (Rafael Moneo, 1998), 14 m to the top of
## the ventilation tower. True metres, origin at the centroid of the mapped
## outline (OSM way 24968443, 11,149 m2, `building:colour=lightsalmon`,
## `roof:colour=gray`), +X on the 146.5 deg axis (registry yaw 56.5). The
## plan below is that outline, rotated into the model frame, so the long
## band, the notched edges and the broad museum block are as mapped.
##
## From the photos (visual-plan/refs/landmarks/moderna_museet/):
## - Walls: a continuous terracotta-pink rendered wall 9.2 m high with no
##   storeys or window rhythm of its own, finished with a slim grey zinc
##   edge; the roof is flat zinc grey.
## - The long straight wall (125 m) and every other long edge carry a low
##   ribbon of glazing under the wall, set back in a steel frame with
##   mullions every 2.8 m, a transom and a thin steel awning above.
## - Roof: rows of roof lights on a 14 m grid, tapered glass-and-steel
##   louvre towers 4.4 m wide and 3.6 m high with a flat steel cap. At night
##   they glow warm, as the real museum's do.
## - A square ventilation tower 3.4 m wide rises to 14 m near the west end.
## The old brick buildings round the museum are left to the map. The OSM
## `height=24` tag is not what the photos show (wall about 9 m, lights
## 3.6 m), so the registry height is the 14 m the model stands.
## Surfaces (5): Wall, Roof, Glass, Steel, Lamp.

const OUTLINE := [
	Vector2(-140.6, 16.1), Vector2(-130.9, 15.4), Vector2(-131.8, 9.1), Vector2(-125.0, 8.5), Vector2(-111.9, 7.2),
	Vector2(-104.2, 6.4), Vector2(-100.0, 6.0), Vector2(-100.7, -1.7), Vector2(-84.7, -2.7), Vector2(-74.2, -3.4),
	Vector2(-64.1, -4.0), Vector2(-59.9, -4.3), Vector2(-60.0, -6.1), Vector2(-60.5, -13.7), Vector2(-53.4, -14.2),
	Vector2(-40.2, -15.2), Vector2(-27.6, -16.0), Vector2(-21.6, -16.5), Vector2(-22.2, -21.3), Vector2(-14.5, -21.8),
	Vector2(-20.1, -33.2), Vector2(13.5, -46.0), Vector2(16.0, -41.2), Vector2(20.7, -41.9), Vector2(38.4, -44.6),
	Vector2(39.8, -32.3), Vector2(59.0, -33.5), Vector2(66.4, -34.0), Vector2(78.9, -34.0), Vector2(79.2, -37.5),
	Vector2(75.8, -37.9), Vector2(76.9, -45.8), Vector2(122.2, -38.9), Vector2(121.9, -37.5), Vector2(119.2, -27.6),
	Vector2(111.2, -28.3), Vector2(110.0, -26.9), Vector2(94.9, -29.8), Vector2(99.2, -19.7), Vector2(82.5, -15.1),
	Vector2(82.4, -17.8), Vector2(77.8, -18.3), Vector2(78.4, -25.6), Vector2(67.1, -25.0), Vector2(67.2, -23.6),
	Vector2(69.7, 4.1), Vector2(79.0, 3.5), Vector2(80.3, 20.2), Vector2(81.1, 30.8), Vector2(81.5, 36.3),
	Vector2(60.3, 37.1), Vector2(60.5, 42.3), Vector2(47.4, 42.9), Vector2(47.0, 38.1), Vector2(27.5, 38.9),
	Vector2(26.8, 23.8), Vector2(26.7, 20.1), Vector2(22.4, 20.7), Vector2(-102.3, 30.4), Vector2(-113.0, 31.2),
	Vector2(-123.1, 32.0), Vector2(-139.2, 33.3),
]
const WALL_H := 9.2
const LIGHT_H := 3.6
const LIGHT_W := 4.4
const TOWER := Vector2(-45.0, 6.0)
const TOWER_TOP := 14.0
## Roof-light grid pitch and the clearance kept from every wall (m).
const PITCH := 14.0
const MARGIN := 5.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	var poly := PackedVector2Array(OUTLINE)
	_shell(lm, poly)
	_glazing(lm, poly)
	_roof_lights(lm, poly)
	_tower(lm)
	lm.commit(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C07A58", 3.0, 0.85))
	lm.use("Roof", LandmarkMaterials.paint("#6A7075", 0.6, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#26343A"))
	lm.use("Steel", LandmarkMaterials.paint("#8C9498", 0.5, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2B0", 0.8))

## The extruded outline: rendered walls and a zinc roof with a slim edge.
static func _shell(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	lm.poly_prism("Wall", poly, 0.0, WALL_H, false)
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri("Roof", Vector3(a.x, WALL_H, a.y), Vector3(b.x, WALL_H, b.y), Vector3(c.x, WALL_H, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		var out := _out(poly, i)
		lm.beam("Steel", Vector3(p.x, WALL_H + 0.08, p.y) + out * 0.05, Vector3(q.x, WALL_H + 0.08, q.y) + out * 0.05,
			0.22, 0.16, Vector3.UP)

## Outward horizontal normal of edge i (the polygon's winding is unknown).
static func _out(poly: PackedVector2Array, i: int) -> Vector3:
	var p := poly[i]
	var q := poly[(i + 1) % poly.size()]
	var mid := (p + q) * 0.5
	var e := (q - p).normalized()
	var n := Vector2(e.y, -e.x)
	if Geometry2D.is_point_in_polygon(mid + n * 0.5, poly):
		n = -n
	return Vector3(n.x, 0.0, n.y)

## A ribbon of glazing and an awning along every edge longer than 18 m.
static func _glazing(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		var len := p.distance_to(q)
		if len < 18.0:
			continue
		var out := _out(poly, i)
		var dir := Vector3(q.x - p.x, 0.0, q.y - p.y).normalized()
		var a := Vector3(p.x, 0.0, p.y) + dir * len * 0.1 + out * 0.08
		var b := Vector3(p.x, 0.0, p.y) + dir * len * 0.9 + out * 0.08
		lm.quad("Glass", a + Vector3(0, 0.5, 0), b + Vector3(0, 0.5, 0), b + Vector3(0, 4.3, 0), a + Vector3(0, 4.3, 0), out)
		var span := a.distance_to(b)
		var cols := maxi(int(span / 2.8), 1)
		var basis := Basis(Vector3.UP.cross(out), Vector3.UP, out)
		for k in cols + 1:
			var m := a.lerp(b, float(k) / float(cols))
			lm.box("Steel", m + Vector3(0, 2.4, 0) + out * 0.08, Vector3(0.12, 3.9, 0.18), basis, 0.0)
		lm.box("Steel", (a + b) * 0.5 + Vector3(0, 2.4, 0) + out * 0.08, Vector3(span, 0.1, 0.16), basis, 0.0)
		lm.box("Steel", (a + b) * 0.5 + Vector3(0, 4.4, 0) + out * 0.45, Vector3(span, 0.08, 1.0),
			basis * Basis(Vector3.RIGHT, 0.12), 0.0)

## Tapered glass roof lights on a grid, kept clear of walls and the tower.
static func _roof_lights(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var unit := LandmarkMesh.new()
	_materials(unit)
	unit.frustum("Glass", Vector3.ZERO, LIGHT_W * 0.76, LIGHT_W * 0.62, LIGHT_H, 4, PI * 0.25)
	unit.box("Steel", Vector3(0, LIGHT_H + 0.08, 0), Vector3(LIGHT_W * 0.95, 0.16, LIGHT_W * 0.95), Basis(), 0.0)
	unit.box("Lamp", Vector3(0, LIGHT_H + 0.17, 0), Vector3(LIGHT_W * 0.6, 0.03, LIGHT_W * 0.6), Basis(), 0.0)
	for k in 4:
		var d := Vector3(cos(PI * 0.5 * float(k)), 0, sin(PI * 0.5 * float(k)))
		unit.beam("Steel", d * LIGHT_W * 0.62 + Vector3(0, 0.1, 0), d * LIGHT_W * 0.5 + Vector3(0, LIGHT_H, 0),
			0.18, 0.18, Vector3.UP)
	var x := -138.0
	while x < 125.0:
		var z := -46.0
		while z < 44.0:
			var c := Vector2(x, z)
			if _clear(poly, c) and c.distance_to(TOWER) > 6.0:
				lm.merge(unit, Transform3D(Basis(), Vector3(c.x, WALL_H, c.y)))
			z += PITCH
		x += PITCH

## True when a roof light at `c` stands MARGIN from every wall.
static func _clear(poly: PackedVector2Array, c: Vector2) -> bool:
	for dx: float in [-1.0, 0.0, 1.0]:
		for dz: float in [-1.0, 0.0, 1.0]:
			if not Geometry2D.is_point_in_polygon(c + Vector2(dx, dz) * MARGIN, poly):
				return false
	return true

## The square ventilation tower with louvres.
static func _tower(lm: LandmarkMesh) -> void:
	var h := TOWER_TOP - WALL_H
	lm.box("Wall", Vector3(TOWER.x, WALL_H + h * 0.5, TOWER.y), Vector3(3.4, h, 3.4), Basis(), 0.0)
	lm.box("Steel", Vector3(TOWER.x, TOWER_TOP - 0.1, TOWER.y), Vector3(3.7, 0.2, 3.7), Basis(), 0.0)
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var y := WALL_H + 0.7 + float(k) * 1.0
			lm.box("Steel", Vector3(TOWER.x + 1.72 * s, y, TOWER.y), Vector3(0.12, 0.12, 2.6), Basis(), 0.0)
			lm.box("Steel", Vector3(TOWER.x, y, TOWER.y + 1.72 * s), Vector3(2.6, 0.12, 0.12), Basis(), 0.0)
