class_name FootprintMatcher
extends RefCounted

## Joins city building records given as GK25 points (the building
## register's coordinates, the LoD2 model's roof centroids) to the OSM
## footprints they stand in: the footprint containing the point (outside
## its courtyards), else the nearest within SNAP_M. Shared by
## HelsinkiRegister and HelsinkiLod2.

## A point a little outside every footprint (a corner-placed register
## point, an outline drawn slightly small) still joins the nearest one.
const SNAP_M := 3.5
const CELL_M := 50.0

## {building index: [rows]} for `rows` ({e, n} or [_, e, n, ...]) over
## `buildings` (local metre footprints round c_lat, c_lon).
static func match(buildings: Array, c_lat: float, c_lon: float, rows: Array) -> Dictionary:
	var hits := {}
	if rows.is_empty() or buildings.is_empty():
		return hits
	var grid := _grid(buildings)
	var f := Gk25.frame(c_lat, c_lon)
	for r in rows:
		var e: float = float(r["e"]) if r is Dictionary else float(r[1])
		var n: float = float(r["n"]) if r is Dictionary else float(r[2])
		var i := _owner(buildings, grid, Gk25.frame_xz(f, e, n))
		if i < 0:
			continue
		if not hits.has(i):
			hits[i] = []
		(hits[i] as Array).append(r)
	return hits

## Whether a building takes city facts: not a part-modelled or mapped
## landmark, a vessel or a fortification (their own builders).
static func eligible(b: Dictionary) -> bool:
	return (b.get("parts", []) as Array).is_empty() \
		and not str(b.get("kind", "")) in ["ship", "boat", "houseboat"] \
		and not b.has("defensive_works") and not b.get("suomenlinna", false) \
		and not b.get("mapped_landmark", false)

## Building index buckets per CELL_M cell of each footprint's AABB.
static func _grid(buildings: Array) -> Dictionary:
	var grid := {}
	for i in buildings.size():
		var b: Variant = buildings[i]
		if not (b is Dictionary) or not eligible(b):
			continue
		var fp: PackedVector2Array = (b as Dictionary).get("footprint", PackedVector2Array())
		if fp.size() < 3:
			continue
		var lo := fp[0]
		var hi := fp[0]
		for q in fp:
			lo = lo.min(q)
			hi = hi.max(q)
		lo -= Vector2(SNAP_M, SNAP_M)
		hi += Vector2(SNAP_M, SNAP_M)
		for cx in range(floori(lo.x / CELL_M), floori(hi.x / CELL_M) + 1):
			for cz in range(floori(lo.y / CELL_M), floori(hi.y / CELL_M) + 1):
				var key := Vector2i(cx, cz)
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append(i)
	return grid

## The building containing `p`, else the nearest within SNAP_M; -1 none.
static func _owner(buildings: Array, grid: Dictionary, p: Vector2) -> int:
	var key := Vector2i(floori(p.x / CELL_M), floori(p.y / CELL_M))
	var near := -1
	var near_d := SNAP_M
	for i in grid.get(key, []):
		var b: Dictionary = buildings[i]
		var fp: PackedVector2Array = b["footprint"]
		if WorldScale.point_in_polygon(p, fp):
			var in_hole := false
			for h in b.get("holes", []):
				if WorldScale.point_in_polygon(p, h):
					in_hole = true
					break
			if not in_hole:
				return i
		var d := _edge_distance(p, fp)
		if d < near_d:
			near_d = d
			near = i
	return near

static func _edge_distance(p: Vector2, fp: PackedVector2Array) -> float:
	var best := INF
	for k in fp.size():
		var a := fp[k]
		var b := fp[(k + 1) % fp.size()]
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best
