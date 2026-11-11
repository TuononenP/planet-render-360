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
## needed. A partial response leaves open chains (the Eiffel flood:
## the Seine arrived as its two banks, the cross-river closers
## missing); those rejoin pairwise below, and a chain still open
## afterwards drops unless its closing gap is dust or a short chord
## next to its length (_self_closes) — emitting a bank would close a
## kilometre chord across the city.
## Widest cross-water rejoin (m): boundary-clipped riverbanks rejoin
## across the water (the Seine gap is ~150 m); beyond this the chord
## would cross unmapped land, so the chain drops instead.
const PAIR_MAX_M := 500.0
## Widest implicit closing chord (m) a still-open chain may carry out.
const DUST_M := 1.0
## A chain may close on itself only across a chord this short next to
## its own length: a lake missing a stretch of shore closes, a curved
## single bank (a meander, its chord across the bend) does not.
const SELF_CLOSE_FRAC := 0.3
## A self-close may only complete a loop, never fold one bank back on
## itself: rings averaging under 2 × this width (area < perimeter ×
## this) are out-and-back slivers and drop.
const SLIVER_MIN_HALF_WIDTH := 0.5
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
	return _pair_open_chains(rings)

## Rejoin the open chains a partial response leaves: repeatedly join
## the closest endpoint pair (across chains, or a chain's own ends to
## close it) within PAIR_MAX_M, flipping as needed. Closed rings pass
## through; a chain still open with a gap past DUST_M drops.
static func _pair_open_chains(chains: Array) -> Array:
	var out: Array = []
	var pool: Array = []
	for c in chains:
		var ring: PackedVector2Array = c
		if _is_closed(ring):
			out.append(ring)
		elif ring.size() >= 3:
			pool.append(ring)
	while not pool.is_empty():
		var best := {"d": INF, "i": -1, "j": -1, "a_end": 1, "b_end": 0}
		for i in pool.size():
			var a: PackedVector2Array = pool[i]
			if _self_closes(a):
				_consider_pair(best, a[0], a[a.size() - 1], i, i, 0, 1)
			for j in range(i + 1, pool.size()):
				var b: PackedVector2Array = pool[j]
				_consider_pair(best, a[a.size() - 1], b[0], i, j, 1, 0)
				_consider_pair(best, a[a.size() - 1], b[b.size() - 1], i, j, 1, 1)
				_consider_pair(best, a[0], b[b.size() - 1], i, j, 0, 1)
				_consider_pair(best, a[0], b[0], i, j, 0, 0)
		if float(best["d"]) > PAIR_MAX_M:
			break
		_join_best(pool, best)
		# A join that closed its chain leaves the pool: closed rings
		# never rejoin. Every pass now shrinks the pool, so the loop
		# terminates. A self-close that folded one bank back on itself
		# is a sliver, not a loop, and drops instead of emitting.
		var i := int(best["i"])
		if int(best["i"]) == int(best["j"]):
			if _is_sliver(pool[i]):
				pool.remove_at(i)
			else:
				out.append(pool[i])
				pool.remove_at(i)
		elif _is_closed(pool[i]):
			out.append(pool[i])
			pool.remove_at(i)
	# Left open: kept when its gap is dust, or when it closes on itself
	# across a short chord (most of a large lake's shore, its far ways
	# outside the query) into a real loop, not a sliver.
	for c in pool:
		var ring: PackedVector2Array = c
		if _is_closed(ring) or ring[0].distance_to(ring[ring.size() - 1]) <= DUST_M:
			out.append(ring)
		elif _self_closes(ring):
			var closed := ring.duplicate()
			closed.append(ring[0])
			if not _is_sliver(closed):
				out.append(closed)
	return out

## Whether open chain `chain` may close on itself: its closing chord is
## at most SELF_CLOSE_FRAC of its length.
static func _self_closes(chain: PackedVector2Array) -> bool:
	var length := 0.0
	for i in range(1, chain.size()):
		length += chain[i].distance_to(chain[i - 1])
	return chain[0].distance_to(chain[chain.size() - 1]) <= SELF_CLOSE_FRAC * length

## Ends are 0 (head) or 1 (tail); same-chain candidates are always a
## head-to-tail self-close.
static func _consider_pair(best: Dictionary, p: Vector2, q: Vector2,
		i: int, j: int, a_end: int, b_end: int) -> void:
	var d := p.distance_to(q)
	if d >= float(best["d"]):
		return
	best["d"] = d
	best["i"] = i
	best["j"] = j
	best["a_end"] = a_end
	best["b_end"] = b_end

static func _join_best(pool: Array, best: Dictionary) -> void:
	var i := int(best["i"])
	var j := int(best["j"])
	var d := float(best["d"])
	if i == j:
		var ring: PackedVector2Array = pool[i]
		ring.append(ring[0])
		pool[i] = ring
		return
	var a: PackedVector2Array = pool[i]
	var b: PackedVector2Array = pool[j]
	pool[i] = _concat_chains(a, int(best["a_end"]) == 0, b, int(best["b_end"]) == 1, d)
	pool.remove_at(j)

## Concatenates first + second (each optionally flipped) into one
## chain. A dust-distance joint shares its vertex; a real gap keeps
## both ends, so the closing chord is an explicit edge.
static func _concat_chains(first: PackedVector2Array, flip_first: bool,
		second: PackedVector2Array, flip_second: bool, gap: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if flip_first:
		for k in range(first.size() - 1, -1, -1):
			out.append(first[k])
	else:
		out.append_array(first)
	var start := 1 if gap < 0.001 else 0
	if flip_second:
		for k in range(second.size() - 1 - start, -1, -1):
			out.append(second[k])
	else:
		out.append_array(second.slice(start))
	return out

## Contract-§2.6 land entries for one multipolygon relation: one entry
## per outer ring, each with its `holes` (inner rings attached to
## their containing outer; all inners when there is a single outer).
## waterway=riverbank relations land as water; anything without a
## mapped class (incl. coastline/boundary/route relations, which are
## not areas) yields no entry.
static func _relation_land(tags: Dictionary, members: Array,
		c_lat: float, c_lon: float) -> Array:
	var cls := ""
	if str(tags.get("waterway", "")) == "riverbank":
		cls = "water"
	elif str(tags.get("natural", "")) == "coastline":
		return []
	else:
		cls = OsmTags.land_class(tags)
		if cls == "":
			return []
	var entries: Array = []
	for r in _relation_rings(members, c_lat, c_lon):
		var entry := {"class": cls, "points": r["outer"], "holes": r["holes"]}
		if cls == "grass":
			entry["sward"] = OsmTags.sward(tags)
		entries.append(entry)
	return entries

## Stitched rings of one multipolygon relation as [{outer, holes}]:
## each inner ring attaches to the outer containing its first vertex
## (all inners when there is a single outer). Rings keep the closing
## duplicate vertex _join_rings produces, like way footprints do.
static func _relation_rings(members: Array, c_lat: float, c_lon: float) -> Array:
	var outers := _join_rings(_member_segments(members, true, c_lat, c_lon))
	if outers.is_empty():
		return []
	var inners := _join_rings(_member_segments(members, false, c_lat, c_lon))
	var out: Array = []
	for o in outers:
		var holes: Array = []
		for h in inners:
			if outers.size() == 1 or _point_in_ring((h as PackedVector2Array)[0], o):
				holes.append(h)
		out.append({"outer": o, "holes": holes})
	return out
## Points every `step` metres along a polyline (first vertex included).
static func along(line: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if line.is_empty():
		return out
	out.append(line[0])
	var carry := 0.0
	for i in line.size() - 1:
		var a := line[i]
		var seg := line[i + 1] - a
		var d := seg.length()
		var t := step - carry
		while t <= d:
			out.append(a + seg * (t / d))
			t += step
		carry = d - (t - step)
	return out

## A ring is closed when its ends meet (4 cm in internal units).
static func _is_closed(poly: PackedVector2Array) -> bool:
	return poly.size() >= 3 and poly[0].distance_to(poly[poly.size() - 1]) < 0.01

## A self-closed ring whose area is ~zero for its perimeter folded one
## bank back on itself instead of completing a loop.
static func _is_sliver(poly: PackedVector2Array) -> bool:
	return _ring_area_abs(poly) < _ring_perimeter(poly) * SLIVER_MIN_HALF_WIDTH

static func _ring_area_abs(poly: PackedVector2Array) -> float:
	var area2 := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		area2 += a.x * b.y - b.x * a.y
	return absf(area2) * 0.5

static func _ring_perimeter(poly: PackedVector2Array) -> float:
	var total := 0.0
	for i in poly.size():
		total += poly[i].distance_to(poly[(i + 1) % poly.size()])
	return total
static func _ring_aabb(ring: PackedVector2Array) -> Rect2:
	var min_p := ring[0]
	var max_p := ring[0]
	for p in ring:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)

## Land polygons in priority order: water first, then the smallest first.
## Ground paint and GroundTruth.land_class_at both let the earliest entry
## win where polygons overlap, so a park inside a city-wide residential
## landuse reads as park (it painted paving under the park's trees), and a
## pond in a park stays water. Stable within equal keys.
static func land_by_priority(polys: Array) -> Array:
	var keyed: Array = []
	for i in polys.size():
		var poly: Variant = polys[i]
		var area := INF
		var water := false
		if poly is Dictionary:
			var pts: Variant = (poly as Dictionary).get("points", null)
			if pts is PackedVector2Array and (pts as PackedVector2Array).size() >= 3:
				area = absf(RingGeometry.signed_area(pts))
			water = str((poly as Dictionary).get("class", "")) == "water"
		keyed.append([0 if water else 1, area, i, poly])
	keyed.sort_custom(func(a: Array, b: Array) -> bool:
		if a[0] != b[0]:
			return a[0] < b[0]
		if a[1] != b[1]:
			return a[1] < b[1]
		return a[2] < b[2])
	var out: Array = []
	for k in keyed:
		out.append(k[3])
	return out
