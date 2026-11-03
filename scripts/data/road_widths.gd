class_name RoadWidths
extends RefCounted

## Carriageway width from the sidewalks mapped beside it. OSM `lanes`
## counts traffic lanes only, so a street with parking along both kerbs
## (San Francisco's Hyde St: 2 lanes, ~12 m kerb to kerb) parsed as 6 m,
## left a strip of unpaved ground between the road and its separately
## mapped sidewalks, and had no room for parked cars. Where a road says
## its sidewalks are mapped (`sidewalk` bits) and footway=sidewalk lines
## run parallel to it on both sides, the kerbs stand SIDEWALK_HALF_M
## inside those lines: the road takes that width (never narrower than its
## tagged lanes, never past MAX_M, never when `width` is tagged) and
## records the room beyond its lanes as `parking_m` (ParkedCars).

## Half the width of a mapped sidewalk: its line is the footway's centre.
const SIDEWALK_HALF_M := 1.5
## A sidewalk line this near (or nearer) is the road's own; farther is
## the next street's (m from the centreline).
const MIN_OFFSET_M := 3.0
const MAX_OFFSET_M := 16.0
## Parallel within this angle (cos) to count as the road's sidewalk.
const PARALLEL_COS := 0.94
const MAX_M := 24.0
const CELL_M := 20.0
## Probes per road: one every PROBE_M along it, at least one.
const PROBE_M := 12.0

## Widens `roads` (attributed road dicts, metres) in place.
static func from_sidewalks(roads: Array, trees: Array = []) -> void:
	var grid := {}
	var barriers := {}
	for r in roads:
		if not (r is Dictionary):
			continue
		var road: Dictionary = r
		var sidewalk := bool(road.get("kerb_line", false))
		if not sidewalk and not str(road.get("class", "")) in ["cycleway", "path", "footway"]:
			continue
		var target: Dictionary = grid if sidewalk else barriers
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		for i in pts.size() - 1:
			var seg := [pts[i], pts[i + 1], float(road.get("width_m", 2.0)) * 0.5]
			for cell in _cells(pts[i], pts[i + 1]):
				if not target.has(cell):
					target[cell] = []
				(target[cell] as Array).append(seg)
	for tree in trees:
		var p := Vector2(float(tree.get("x", 0.0)), float(tree.get("z", 0.0)))
		for cell in _cells(p, p):
			if not barriers.has(cell):
				barriers[cell] = []
			(barriers[cell] as Array).append([p, p, 1.0])
	if grid.is_empty():
		return
	for r in roads:
		if not (r is Dictionary):
			continue
		var road: Dictionary = r
		if int(road.get("sidewalk_separate", 0)) == 0 or bool(road.get("width_tagged", false)) \
				or bool(road.get("area", false)) or bool(road.get("kerb_line", false)):
			continue
		var base := float(road.get("width_m", 0.0))
		if base >= MAX_M:
			continue
		var w := measure(road.get("points", PackedVector2Array()), grid, barriers,
			int(road.get("sidewalk_separate", 0)), base)
		if w > base + 0.5:
			road["width_m"] = minf(w, MAX_M)
			road["parking_m"] = minf(w, MAX_M) - base

## Kerb-to-kerb width (m) from the sidewalk lines either side of the
## polyline, the median over its probes; 0 when either side has none.
static func measure(pts: PackedVector2Array, grid: Dictionary, barriers: Dictionary = {},
		sides: int = 3, base: float = 0.0) -> float:
	var left: Array[float] = []
	var right: Array[float] = []
	var caps: Array[float] = []
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var len := a.distance_to(b)
		if len < 4.0:
			continue
		var dir := (b - a) / len
		var n := Vector2(dir.y, -dir.x)
		var probes := maxi(1, int(len / PROBE_M))
		for k in probes:
			var p := a + dir * len * (float(k) + 0.5) / float(probes)
			var best_l := INF if sides & 1 else base * 0.5 + SIDEWALK_HALF_M
			var best_r := INF if sides & 2 else base * 0.5 + SIDEWALK_HALF_M
			for seg in grid.get(_cell(p), []):
				var s0: Vector2 = seg[0]
				var s1: Vector2 = seg[1]
				var sd := s1 - s0
				if sd.length() < 0.5 or absf(sd.normalized().dot(dir)) < PARALLEL_COS:
					continue
				var q := Geometry2D.get_closest_point_to_segment(p, s0, s1)
				var off := (q - p).dot(n)
				var along := absf((q - p).dot(dir))
				if along > 2.0 or absf(off) < MIN_OFFSET_M or absf(off) > MAX_OFFSET_M:
					continue
				if off > 0.0:
					best_l = minf(best_l, off)
				else:
					best_r = minf(best_r, -off)
			var width_cap := INF
			# Verges and separate cycle tracks keep their ground: never turn
			# the space between them and the footway into parking asphalt.
			for seg in barriers.get(_cell(p), []):
				var a0: Vector2 = seg[0]
				var a1: Vector2 = seg[1]
				var tangent := a1 - a0
				if tangent.length() > 0.5 and absf(tangent.normalized().dot(dir)) < PARALLEL_COS:
					continue
				var q := Geometry2D.get_closest_point_to_segment(p, a0, a1) if a0 != a1 else a0
				if absf((q - p).dot(dir)) > (PROBE_M if a0 == a1 else 3.0):
					continue
				var off := (q - p).dot(n)
				var cap := maxf(base * 0.5, absf(off) - float(seg[2])) + SIDEWALK_HALF_M
				if (off > 0.0 and off < best_l) or (off < 0.0 and -off < best_r):
					width_cap = minf(width_cap, 2.0 * (cap - SIDEWALK_HALF_M))
				if off > 0.0 and best_l < INF:
					best_l = minf(best_l, cap)
				elif off < 0.0 and best_r < INF:
					best_r = minf(best_r, cap)
			if best_l < INF and best_r < INF:
				left.append(best_l)
				right.append(best_r)
				caps.append(width_cap)
	if left.is_empty():
		return 0.0
	left.sort()
	right.sort()
	caps.sort()
	# Ribbons are centred on the mapped way: an obstacle on just one side
	# caps both half-widths so asymmetric verges cannot be paved over.
	return minf(left[left.size() / 2] + right[right.size() / 2] - 2.0 * SIDEWALK_HALF_M, caps[caps.size() / 2])

static func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL_M), floori(p.y / CELL_M))

## Every cell within MAX_OFFSET_M of the segment's bounding box.
static func _cells(a: Vector2, b: Vector2) -> Array[Vector2i]:
	var lo := _cell(Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * MAX_OFFSET_M)
	var hi := _cell(Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * MAX_OFFSET_M)
	var out: Array[Vector2i] = []
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			out.append(Vector2i(x, y))
	return out
