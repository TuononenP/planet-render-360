class_name OsmGeometry
extends RefCounted

## Ring geometry for OsmFetcher: centroids, point-in-ring, and
## stitching multipolygon member segments into closed rings.
## Area-weighted polygon centroid; the AABB centre for degenerate rings.
static func _polygon_centroid(pts: PackedVector2Array, fallback: Vector2) -> Vector2:
	var area2 := 0.0
	var cx := 0.0
	var cz := 0.0
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var cross := a.x * b.y - b.x * a.y
		area2 += cross
		cx += (a.x + b.x) * cross
		cz += (a.y + b.y) * cross
	if absf(area2) < 0.000001:
		return fallback
	return Vector2(cx / (3.0 * area2), cz / (3.0 * area2))

## Ray-cast point-in-ring for nesting building:parts in parents.
static func _point_in_ring(p: Vector2, ring: PackedVector2Array) -> bool:
	var inside := false
	var j := ring.size() - 1
	for i in ring.size():
		var a := ring[i]
		var b := ring[j]
		if (a.y > p.y) != (b.y > p.y) \
				and p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x:
			inside = not inside
		j = i
	return inside
## Member segments of a multipolygon relation for one role side:
## role "outer" (or "" — single-outer members often leave it blank)
## vs. role "inner". Members without geometry (outside the response
## bbox) are skipped; the ring join below tolerates the gap.
static func _member_segments(members: Array, want_outer: bool,
		c_lat: float, c_lon: float) -> Array:
	var segs: Array = []
	for m in members:
		if not (m is Dictionary):
			continue
		var role := str((m as Dictionary).get("role", ""))
		var is_outer := role == "outer" or role == ""
		if is_outer != want_outer:
			continue
		var geom: Array = (m as Dictionary).get("geometry", [])
		if geom.size() < 2:
			continue
		var pts := PackedVector2Array()
		for node in geom:
			if not (node is Dictionary):
				continue
			pts.append(WorldScale.xz_from_latlon(float((node as Dictionary).get("lat", c_lat)),
				float((node as Dictionary).get("lon", c_lon)), c_lat, c_lon))
		if pts.size() >= 2:
			segs.append(pts)
	return segs

## Stitch member segments into rings by greedy endpoint matching
## (shared end nodes decode to identical XZ, so the epsilon only
## absorbs float dust). Grows at both ends, flipping segments as
## needed. Open chains with ≥3 posts still emit — consumers close
## rings implicitly — so a partial response degrades, never drops.
static func _join_rings(segs: Array) -> Array:
	var rings: Array = []
	var pool: Array = segs.duplicate()
	while not pool.is_empty():
		var ring: PackedVector2Array = pool.pop_back()
		var grown := true
		while grown and not pool.is_empty():
			grown = false
			if ring.size() >= 3 \
					and ring[0].distance_to(ring[ring.size() - 1]) < 0.001:
				break
			var tail := ring[ring.size() - 1]
			var head := ring[0]
			for i in pool.size():
				var s: PackedVector2Array = pool[i]
				if tail.distance_to(s[0]) < 0.001:
					ring.append_array(s.slice(1))
					pool.remove_at(i)
					grown = true
					break
				if tail.distance_to(s[s.size() - 1]) < 0.001:
					for k in range(s.size() - 2, -1, -1):
						ring.append(s[k])
					pool.remove_at(i)
					grown = true
					break
				if head.distance_to(s[s.size() - 1]) < 0.001:
					var nr := PackedVector2Array(s.slice(0, s.size() - 1))
					nr.append_array(ring)
					ring = nr
					pool.remove_at(i)
					grown = true
					break
				if head.distance_to(s[0]) < 0.001:
					var nr2 := PackedVector2Array()
					for k in range(s.size() - 1, 0, -1):
						nr2.append(s[k])
					nr2.append_array(ring)
					ring = nr2
					pool.remove_at(i)
					grown = true
					break
		if ring.size() >= 3:
			rings.append(ring)
	return rings

## Contract-§2.6 land entries for one multipolygon relation: one entry
## per outer ring, each with its `holes` (inner rings attached to
## their containing outer; all inners when there is a single outer).
## waterway=riverbank relations land as water; anything without a
## mapped class (incl. coastline/boundary/route relations, which are
## not areas) yields no entry.
static func _relation_land(tags: Dictionary, members: Array,
		c_lat: float, c_lon: float) -> Array:
	var outers := _join_rings(_member_segments(members, true, c_lat, c_lon))
	if outers.is_empty():
		return []
	var cls := ""
	if str(tags.get("waterway", "")) == "riverbank":
		cls = "water"
	elif str(tags.get("natural", "")) == "coastline":
		return []
	else:
		cls = OsmTags.land_class(tags)
		if cls == "":
			return []
	var inners := _join_rings(_member_segments(members, false, c_lat, c_lon))
	var entries: Array = []
	for o in outers:
		var holes: Array = []
		for h in inners:
			if outers.size() == 1 or _point_in_ring((h as PackedVector2Array)[0], o):
				holes.append(h)
		entries.append({"class": cls, "points": o, "holes": holes})
	return entries
## A ring is closed when its ends meet (4 cm in internal units).
static func _is_closed(poly: PackedVector2Array) -> bool:
	return poly.size() >= 3 and poly[0].distance_to(poly[poly.size() - 1]) < 0.01
static func _ring_aabb(ring: PackedVector2Array) -> Rect2:
	var min_p := ring[0]
	var max_p := ring[0]
	for p in ring:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)
