class_name RoadTapers
extends RefCounted

## Merge tapers where a road narrows. OSM ends a lane by starting a new way
## with fewer lanes at a node (Gräsanlaakso, Espoo: two lanes, the right
## one `merge_to_left`, then one). Each way is a ribbon of one width, so
## the carriageway stepped in at the node. Here the narrower way's first
## stretch is underlaid with paving that eases from the wider way's width
## to its own, as a lane drop is painted out on the road.

## Taper length per metre of width lost, metres.
const TAPER_PER_M := 12.0
## Longest taper, metres, and the most of the narrower way it takes.
const TAPER_MAX_M := 60.0
const TAPER_SHARE := 0.6
## Widths closer than this need no taper, metres.
const MIN_STEP_M := 1.0
## The ways must run on within this (cos of the angle between them).
const STRAIGHT_COS := 0.94

## Lays the tapers of `data`'s roads into `batches`.
static func lay(batches: Dictionary, data: LocationData, surf: RoadBuilder._Surface, m2u: float) -> void:
	for t: Array in tapers(data, m2u):
		var line: Dictionary = t[0]
		var ring := wedge(t[1] as PackedVector2Array, float(t[2]), float(t[3]), m2u)
		if ring.size() >= 3:
			RoadBuilder._area(RoadBuilder._batch(batches, RoadBuilder.finish_of(line, surf, m2u)), ring, [], surf,
				RoadBuilder.AREA_LIFT_M * m2u, m2u)

## [narrower road, its points from the shared node, its half width, the
## wider road's half width] for every node where exactly two surface roads
## meet end to end, running straight on, at different widths.
static func tapers(data: LocationData, m2u: float) -> Array:
	var ends := {}  # node key -> [[road, points from the node]]
	for w: Variant in data.roads:
		if not (w is Dictionary):
			continue
		var d: Dictionary = w
		var r := RoadBuilder._parse(d, m2u)
		if r.is_empty() or bool(r["bridge"]) or bool(d.get("area", false)) or bool(d.get("crossing", false)) \
				or int(r["rank"]) == 0:
			continue
		var pts: PackedVector2Array = r["points"]
		if pts.size() < 2:
			continue
		var back := pts.duplicate()
		back.reverse()
		for from: PackedVector2Array in [pts, back]:
			var key := Vector2i(roundi(from[0].x * 20.0 / m2u), roundi(from[0].y * 20.0 / m2u))
			if not ends.has(key):
				ends[key] = []
			(ends[key] as Array).append([d, from, float(r["width_u"]) * 0.5])
	var out: Array = []
	for key: Vector2i in ends:
		var at: Array = ends[key]
		if at.size() != 2:
			continue
		var a: Array = at[0]
		var b: Array = at[1]
		var da := ((a[1] as PackedVector2Array)[1] - (a[1] as PackedVector2Array)[0]).normalized()
		var db := ((b[1] as PackedVector2Array)[1] - (b[1] as PackedVector2Array)[0]).normalized()
		# Both leave the node: running straight on, they leave opposite ways.
		if da.dot(db) > -STRAIGHT_COS or absf(float(a[2]) - float(b[2])) < MIN_STEP_M * 0.5 * m2u:
			continue
		var narrow: Array = a if float(a[2]) < float(b[2]) else b
		var wide: Array = b if narrow == a else a
		out.append([narrow[0], narrow[1], narrow[2], wide[2]])
	return out

## The paving under the start of `pts` (from the node): `wide` half width
## at the node, easing to `half` over the taper length.
static func wedge(pts: PackedVector2Array, half: float, wide: float, m2u: float) -> PackedVector2Array:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	var length := minf(minf((wide - half) * 2.0 / m2u * TAPER_PER_M, TAPER_MAX_M) * m2u, total * TAPER_SHARE)
	if length <= 0.0:
		return PackedVector2Array()
	var dense := RoadBuilder._resample(pts, 2.0 * m2u)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var run := 0.0
	for i in dense.size():
		if i > 0:
			run += dense[i].distance_to(dense[i - 1])
		var p := dense[i]
		var f := minf(run / length, 1.0)
		# Smooth at both ends: no kink where it leaves the wide road or
		# where it meets the narrow one's edge.
		var h := lerpf(wide, half, f * f * (3.0 - 2.0 * f))
		var sd := RoadBuilder._side(dense, i)
		if f >= 1.0:
			var q := dense[i - 1].lerp(p, 1.0 - (run - length) / maxf(dense[i].distance_to(dense[i - 1]), 1e-6))
			left.append(q + sd * half)
			right.append(q - sd * half)
			break
		left.append(p + sd * h)
		right.append(p - sd * h)
	right.reverse()
	left.append_array(right)
	return left
