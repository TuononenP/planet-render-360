class_name RockOutcrops
extends RefCounted

## Mapped bare rock that stands up out of the ground: Central Park's
## glaciated schist (Umpire Rock, Rat Rock, Vista Rock's shoulders) is
## natural=bare_rock, which the ground otherwise only paints. Each rock
## land polygon of park size (MIN_M2 to MAX_M2; mountain scree and cliffs
## stay paint, the DEM carries their relief) becomes a low faceted mound:
## its outline sunk into the ground, rings shrunk toward its centre rising
## to a rounded, uneven top, one merged mesh in the rock texture. Every
## point lifts from the ground under it, so a patch running down a slope
## to the water stays a low skin on the slope, never a cone over it.

const MIN_M2 := 15.0
const MAX_M2 := 6000.0
## Ring shrink and the share of the mound's height each ring reaches.
const RINGS := [[0.78, 0.55], [0.5, 0.86], [0.22, 1.0]]
## Mound height from the patch's size: K_H x sqrt(area), clamped.
const K_H := 0.06
const H_RANGE := Vector2(0.7, 3.2)
## Rock colour (sRGB hex) by city; elsewhere the neutral ROCK_HEX. Helsinki's
## bedrock is pink-grey rapakivi granite and gneiss, warmer than schist;
## Stockholm's skerries and shore rock are red-grey gneiss granite.
const ROCK_HEX := "#77736c"
const CITY_ROCK_HEX := {"helsinki": "#8c7e78", "espoo": "#8c7e78", "stockholm": "#6b625d"}

static func rock_hex(data: LocationData) -> String:
	var city := CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude))
	return str(CITY_ROCK_HEX.get(city, ROCK_HEX))

static func build(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask = null) -> int:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("rock", rock_hex(data), 3.0))
	var count := 0
	for poly in data.land_polygons:
		if not (poly is Dictionary) or str((poly as Dictionary).get("class", "")) != "rock":
			continue
		var pts: Variant = (poly as Dictionary).get("points", null)
		if not (pts is PackedVector2Array) or (pts as PackedVector2Array).size() < 3:
			continue
		var ring := pts as PackedVector2Array
		var area := absf(SkyKit.winding(ring)) * 0.5
		if area < MIN_M2 or area > MAX_M2:
			continue
		var c := Vector2.ZERO
		for p in ring:
			c += p
		c /= float(ring.size())
		if not ground.is_inside(c.x, c.y):
			continue
		var h := clampf(K_H * sqrt(area), H_RANGE.x, H_RANGE.y)
		var holes: Array = (poly as Dictionary).get("holes", [])
		if holes.is_empty() and _star_shaped(ring, c):
			mound(lm, ring, c, h, ground)
		else:
			field(lm, ring, holes, h, ground)
		count += 1
	if ShoreApron.stockholm(data):
		count += scatter(lm, data, ground, mask)
	if count > 0:
		var node := Node3D.new()
		node.name = "RockOutcrops"
		lm.commit(node)
		root.add_child(node)
	if ShoreApron.stockholm(data):
		count += StockholmCliff.build(root, data, ground, mask)
	return count

## Stockholm's granite breaks through where the map has no rock polygon: faceted
## mounds on the steep faces of its cliffs (Mariaberget, Fjällgatan, the Slussen
## rise), jittered on a SCATTER_CELL_M grid within SCATTER_RADIUS_M of the eye, and
## a sparse few along its natural shores. Never on a footprint, a carriageway or
## water. Deterministic (hash of the cell), so a rebuild gives the same rocks.
const SCATTER_CELL_M := 11.0
const SCATTER_RADIUS_M := 420.0
const SCATTER_SLOPE := 0.55
const SCATTER_CHANCE := 0.5
const SCATTER_SHORE_CHANCE := 0.03
const SCATTER_R_M := Vector2(2.5, 6.0)
## A mound stands at least this far from a building and from a quay wall, metres.
const SCATTER_CLEAR_M := 9.0

static func scatter(lm: LandmarkMesh, data: LocationData, ground: GroundTruth, mask: VegetationMask) -> int:
	var m := WorldScale.metres_to_units()
	var centre := View360.spawn_xz(data)
	var cell := SCATTER_CELL_M * m
	var n := int(SCATTER_RADIUS_M / SCATTER_CELL_M)
	var count := 0
	for iz in range(-n, n + 1):
		for ix in range(-n, n + 1):
			if _hash(float(ix) * 1.7 + 3.1, float(iz) * 2.3 - 5.9) > SCATTER_CHANCE:
				continue
			var p := centre + Vector2(
				float(ix) + 0.5 + (_hash(float(ix) * 3.3, float(iz) * 1.1) - 0.5) * 0.8,
				float(iz) + 0.5 + (_hash(float(iz) * 4.7, float(ix) * 0.9) - 0.5) * 0.8) * cell
			if ground.slope_at(p.x, p.y) < SCATTER_SLOPE:
				continue
			if _scatter_one(lm, p, ground, mask, m, _hash(p.x, p.y)):
				count += 1
	if ground.shoreline != null and ground.shoreline.ready:
		for seg in ground.shoreline.segments:
			if str(seg.get("kind", "")) == "hard":
				continue
			var mid: Vector2 = ((seg["a"] as Vector2) + (seg["b"] as Vector2)) * 0.5
			if mid.distance_squared_to(centre) > pow(SCATTER_RADIUS_M * m, 2.0) \
					or _hash(mid.x * 0.7, mid.y * 1.3) > SCATTER_SHORE_CHANCE:
				continue
			if _scatter_one(lm, mid + (seg["land"] as Vector2) * 2.0 * m, ground, mask, m, _hash(mid.y, mid.x)):
				count += 1
	return count

static func _scatter_one(lm: LandmarkMesh, p: Vector2, ground: GroundTruth, mask: VegetationMask,
		m: float, rnd: float) -> bool:
	if not ground.is_inside(p.x, p.y) or ground.water_at(p.x, p.y) > 0.0:
		return false
	if mask != null and mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD, 2.0):
		return false
	# No mound against a house wall or a quay: there the DEM's steepness is a
	# terrace or a retaining wall, and a lump of rock at a plinth reads as a
	# pale heap. Rock breaks through on open cliff, not at a building's foot.
	if mask != null and mask.blocked(p.x, p.y, VegetationMask.BUILDING, SCATTER_CLEAR_M):
		return false
	if ground.shoreline != null and ground.shoreline.ready:
		var bank: Dictionary = ground.shoreline.nearest(p, 1)
		if not bank.is_empty() and float(bank["distance"]) < SCATTER_CLEAR_M * m:
			return false
	if ground.land_class_at(p.x, p.y) in ["water", "building", "road"]:
		return false
	var r := lerpf(SCATTER_R_M.x, SCATTER_R_M.y, rnd) * m
	var ring := PackedVector2Array()
	for i in 9:
		var a := TAU * float(i) / 9.0
		ring.append(p + Vector2(cos(a), sin(a)) * r * (0.75 + 0.5 * _hash(p.x + float(i), p.y - float(i))))
	var area := absf(SkyKit.winding(ring)) * 0.5
	mound(lm, ring, p, clampf(K_H * sqrt(area / (m * m)) * m, H_RANGE.x * m, H_RANGE.y * m), ground)
	return true

## One mound over `ring' (centre `c`, top `h` metres over its ground).
static func mound(lm: LandmarkMesh, ring: PackedVector2Array, c: Vector2, h: float, ground: GroundTruth) -> void:
	var rings: Array = []
	var edge := PackedVector3Array()
	for p in ring:
		edge.append(Vector3(p.x, ground.height_at_world(p.x, p.y) - 0.3, p.y))
	rings.append(edge)
	for r in RINGS:
		var k := float(r[0])
		var row := PackedVector3Array()
		for p in ring:
			var q := c + (p - c) * k
			var lift := h * float(r[1]) * (0.75 + 0.5 * _hash(q.x, q.y))
			row.append(Vector3(q.x, ground.height_at_world(q.x, q.y) + lift, q.y))
		rings.append(row)
	var apex := Vector3(c.x, ground.height_at_world(c.x, c.y) + h, c.y)
	for j in rings.size() - 1:
		var a: PackedVector3Array = rings[j]
		var b: PackedVector3Array = rings[j + 1]
		for i in a.size():
			var i2 := (i + 1) % a.size()
			_face(lm, a[i], a[i2], b[i2])
			_face(lm, a[i], b[i2], b[i])
	var top: PackedVector3Array = rings.back()
	for i in top.size():
		_face(lm, top[i], top[(i + 1) % top.size()], apex)

## True when `ring` winds once around `c` (every edge turns the same way seen
## from it). Only then does shrinking it toward `c` give a mound: on a horseshoe
## or banana of rock, or one with a hole, the shrunk rings fold over each other
## and the mound becomes loose ribs.
static func _star_shaped(ring: PackedVector2Array, c: Vector2) -> bool:
	var turn := 0.0
	for i in ring.size():
		var cr := (ring[i] - c).cross(ring[(i + 1) % ring.size()] - c)
		if absf(cr) < 1e-9:
			continue
		if turn == 0.0:
			turn = signf(cr)
		elif signf(cr) != turn:
			return false
	return turn != 0.0

## Rock outline too bent for `mound` (centroid outside it, a hole in it): a
## height field over its own area. Boundary points are sunk into the ground,
## interior points sit on a jittered grid and rise with their distance from the
## outline up to the top height `h` at the deepest point, and a Delaunay
## triangulation of them, kept where a triangle lies on the rock, is the skin.
const FIELD_STEP_M := Vector2(2.0, 5.0)
const FIELD_MAX_POINTS := 2500

static func field(lm: LandmarkMesh, ring: PackedVector2Array, holes: Array, h: float,
		ground: GroundTruth) -> void:
	var loops: Array = [ring]
	for hole in holes:
		if hole is PackedVector2Array and (hole as PackedVector2Array).size() >= 3:
			loops.append(hole)
	var bb := Rect2(ring[0], Vector2.ZERO)
	for p in ring:
		bb = bb.expand(p)
	var step := clampf(sqrt(bb.size.x * bb.size.y) / 8.0, FIELD_STEP_M.x, FIELD_STEP_M.y)
	step = maxf(step, sqrt(bb.size.x * bb.size.y / float(FIELD_MAX_POINTS)))
	var pts := PackedVector2Array()
	var depth := PackedFloat32Array()
	for loop: PackedVector2Array in loops:
		for i in loop.size():
			var a := loop[i]
			var b := loop[(i + 1) % loop.size()]
			var n := maxi(1, ceili(a.distance_to(b) / (step * 1.5)))
			for k in n:
				var q := a.lerp(b, float(k) / float(n))
				if pts.is_empty() or q.distance_squared_to(pts[pts.size() - 1]) > 1e-6:
					pts.append(q)
					depth.append(0.0)
	var edge_count := pts.size()
	var dmax := 0.0
	var gx := bb.position.x + step * 0.5
	while gx < bb.end.x:
		var gz := bb.position.y + step * 0.5
		while gz < bb.end.y:
			var q := Vector2(gx + (_hash(gx, gz) - 0.5) * step * 0.6, gz + (_hash(gz, gx) - 0.5) * step * 0.6)
			if _on_rock(q, ring, holes):
				var d := _edge_distance(q, loops)
				if d >= step * 0.45:
					pts.append(q)
					depth.append(d)
					dmax = maxf(dmax, d)
			gz += step
		gx += step
	if pts.size() < 3:
		return
	var tris := Geometry2D.triangulate_delaunay(pts)
	var verts := PackedVector3Array()
	for i in pts.size():
		var f := 0.0
		if i >= edge_count:
			var u := 1.0 - minf(depth[i] / dmax, 1.0)
			f = (1.0 - u * u) * (0.85 + 0.3 * _hash(pts[i].x, pts[i].y))
		verts.append(Vector3(pts[i].x, ground.height_at_world(pts[i].x, pts[i].y) - 0.3 + (h + 0.3) * f, pts[i].y))
	for t in range(0, tris.size() - 2, 3):
		var a := pts[tris[t]]
		var b := pts[tris[t + 1]]
		var c := pts[tris[t + 2]]
		if _on_rock((a + b + c) / 3.0, ring, holes):
			_face(lm, verts[tris[t]], verts[tris[t + 1]], verts[tris[t + 2]])

static func _on_rock(p: Vector2, ring: PackedVector2Array, holes: Array) -> bool:
	if not Geometry2D.is_point_in_polygon(p, ring):
		return false
	for hole in holes:
		if hole is PackedVector2Array and Geometry2D.is_point_in_polygon(p, hole):
			return false
	return true

static func _edge_distance(p: Vector2, loops: Array) -> float:
	var best := INF
	for loop: PackedVector2Array in loops:
		for i in loop.size():
			var q := Geometry2D.get_closest_point_to_segment(p, loop[i], loop[(i + 1) % loop.size()])
			best = minf(best, p.distance_squared_to(q))
	return sqrt(best)

## A faceted triangle of the mound's surface, its normal turned upward
## (a mound is a height field over its outline).
static func _face(lm: LandmarkMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-8:
		return
	n = n.normalized()
	if n.y < 0.0:
		n = -n
	lm.tri("Rock", a, b, c, n, n, n, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z))

static func _hash(x: float, z: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
