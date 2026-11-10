class_name Underpasses
extends RefCounted

## Underpass grading for GroundTruth: a bridge over a road or railway
## sits on its banks (RoadBuilder.deck_profile arches it at most a few
## metres), but a 9 m post grid and the DEM's smoothing leave the way
## below at almost the bridge's height, so the deck read as a low hump
## laid over it. Where a bridge crosses a lower way, the ground along
## that way is cut to the deck's underside less the way's clearance,
## ramping back up at RAMP_GRADE along it; the way drapes into the cut.

## Clearance under the deck slab (metres), by what passes below.
const CLEAR_ROAD_M := 4.5
const CLEAR_PATH_M := 2.5
const CLEAR_RAIL_M := 5.5
## Grade the cut ramps back to the ground at, along the lower way.
const RAMP_GRADE := 0.08
## A railway climbs back far more gently, so a track under several
## bridges stays down between them: at the road grade it dipped and rose
## at every one, and a station yard under its viaducts was a washboard.
const RAMP_GRADE_RAIL := 0.025
## Ground left standing between two cut ways (the strip between two
## tracks) comes down with them when it stands this far above both.
const RIDGE_M := 0.5
## Height per layer a viaduct's deck stands at a joint (deck_profile).
const JOINT_UP_M := 5.0
const RIDGE_PASSES := 3
## A crossing needing more than this is a valley the data already has
## (or a layer mistake), never a cut.
const MAX_CUT_M := 8.0
const SAMPLE_M := 4.0
## A bridge joins the ground at its ends; an intersecting way there is a
## connection, not a crossing underneath it. Allow for coordinate rounding.
const END_TOLERANCE_M := 0.5
## Native GroundKernels (native/, tools/build_native.sh) when loaded.
static var _native := ClassDB.class_exists("GroundKernels")

## Cuts `surface` (size × size posts, `step` units apart, source metres
## in Y) under every bridge crossing in `ways` (road or railway dicts:
## points, bridge, tunnel, layer, class, width_m). `level` marks carved
## water posts (-INF = dry), which are left alone.
static func carve(surface: PackedFloat32Array, level: PackedFloat32Array,
		size: int, step: float, ways: Array, m2u: float) -> void:
	if size < 2:
		return
	var bridges: Array = []
	var lower: Array = []
	for w in ways:
		if not (w is Dictionary) or bool((w as Dictionary).get("tunnel", false)) \
				or bool((w as Dictionary).get("area", false)):
			continue
		var pts: PackedVector2Array = (w as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		if bool((w as Dictionary).get("bridge", false)):
			bridges.append(w)
		else:
			lower.append(w)
	if bridges.is_empty() or lower.is_empty():
		return
	var src := surface.duplicate()
	# Bounding boxes skip the pairs that cannot cross: Venice tested every
	# bridge segment against every segment of thousands of ways. The 1 m
	# margin covers segment_intersects_segment's tolerance, so the hits
	# (and their order) are the same.
	var boxes: Array[Rect2] = []
	if not _native:
		for w in lower:
			boxes.append(_box((w as Dictionary)["points"]))
	# Per lower way: [arc position, floor height] of each crossing.
	var cuts := {}
	# Posts carrying a bridge end stay put: the deck sits on its banks.
	# A viaduct is mapped as many bridge ways end to end, and a joint
	# between two of them is in mid-air, not a bank: kept, each one left
	# a pillar of uncut ground standing among the tracks below.
	var keep := {}
	var hs := float(size) * 0.5
	var joints := {}
	for b in bridges:
		var ends: PackedVector2Array = b["points"]
		for e in [ends[0], ends[ends.size() - 1]]:
			joints[_node(e, m2u)] = int(joints.get(_node(e, m2u), 0)) + 1
	for b in bridges:
		var ends: PackedVector2Array = b["points"]
		for e in [ends[0], ends[ends.size() - 1]]:
			if int(joints[_node(e, m2u)]) == 1:
				keep[Vector2i(roundi(e.x / step + hs), roundi(e.y / step + hs))] = true
	# Every crossing at once on every core, then evaluated bridge by bridge.
	var hits: Array = []
	if _native:
		var b_pts: Array = []
		var b_lay := PackedInt32Array()
		for b in bridges:
			b_pts.append(b["points"])
			b_lay.append(_layer(b))
		var w_pts: Array = []
		var w_lay := PackedInt32Array()
		for w in lower:
			w_pts.append((w as Dictionary)["points"])
			w_lay.append(_layer(w))
		hits = ClassDB.class_call_static("GroundKernels", "underpass_hits", b_pts, w_pts, b_lay, w_lay)
	for bi in bridges.size():
		var b: Dictionary = bridges[bi]
		var bp: PackedVector2Array = b["points"]
		var b_len := _length(bp)
		if b_len <= 0.0:
			continue
		# The deck as RoadBuilder.deck_profile draws it: on its bank at a true
		# end, and held a storey up per layer at a joint with the next bridge
		# way. Taken at ground level there, the cut dug every way under a
		# viaduct down by the height the deck already stands above it.
		var up := float(int(b.get("layer", 0))) * JOINT_UP_M
		var h_a := RoadGrading._sample(src, size, step, bp[0]) \
			+ (up if int(joints[_node(bp[0], m2u)]) >= 2 else 0.0)
		var h_b := RoadGrading._sample(src, size, step, bp[bp.size() - 1]) \
			+ (up if int(joints[_node(bp[bp.size() - 1], m2u)]) >= 2 else 0.0)
		var b_layer := _layer(b)
		if _native:
			_cross_native(cuts, hits[bi], lower, src, size, step, h_a, h_b, b_len, m2u)
			continue
		var b_box := _box(bp)
		for k in lower.size():
			var w: Dictionary = lower[k]
			if _layer(w) >= b_layer or not b_box.intersects(boxes[k], true):
				continue
			var wp: PackedVector2Array = w["points"]
			var clear := _clearance(str(w.get("class", "")))
			var b_arc := 0.0
			for i in bp.size() - 1:
				var w_arc := 0.0
				for j in wp.size() - 1:
					var hit: Variant = Geometry2D.segment_intersects_segment(
						bp[i], bp[i + 1], wp[j], wp[j + 1])
					if hit is Vector2:
						var p: Vector2 = hit
						var hit_arc := b_arc + bp[i].distance_to(p)
						if _at_bridge_end(hit_arc, b_len, m2u):
							w_arc += wp[j].distance_to(wp[j + 1])
							continue
						var deck := lerpf(h_a, h_b, hit_arc / b_len)
						var floor_y := deck - RoadBuilder.DECK_DEPTH_M - clear
						var cut := RoadGrading._sample(src, size, step, p) - floor_y
						if cut > 0.0 and cut <= MAX_CUT_M:
							if not cuts.has(k):
								cuts[k] = []
							(cuts[k] as Array).append([w_arc + wp[j].distance_to(p), floor_y])
					w_arc += wp[j].distance_to(wp[j + 1])
				b_arc += bp[i].distance_to(bp[i + 1])
	var touched := {}
	for k in cuts:
		_cut_way(surface, level, size, step, lower[k], cuts[k], keep, m2u, touched)
	_level_ridges(surface, level, size, keep, touched)

## Lowers a post left standing between cut posts on opposite sides of it
## to the higher of the two: parallel ways each cut their own trench and
## left a ridge between them.
static func _level_ridges(surface: PackedFloat32Array, level: PackedFloat32Array, size: int,
		keep: Dictionary, touched: Dictionary) -> void:
	var pairs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]
	for _pass in RIDGE_PASSES:
		var lowered := {}
		var seen := {}
		for t: Vector2i in touched:
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var c := t + Vector2i(dx, dz)
					if seen.has(c) or touched.has(c) or keep.has(c) \
							or c.x < 1 or c.y < 1 or c.x >= size - 1 or c.y >= size - 1:
						continue
					seen[c] = true
					var idx := c.y * size + c.x
					if not is_inf(level[idx]):
						continue
					var cap := INF
					for d: Vector2i in pairs:
						if touched.has(c + d) and touched.has(c - d):
							cap = minf(cap, maxf(surface[(c.y + d.y) * size + c.x + d.x],
								surface[(c.y - d.y) * size + c.x - d.x]))
					if surface[idx] > cap + RIDGE_M:
						lowered[c] = cap
		if lowered.is_empty():
			return
		for c: Vector2i in lowered:
			surface[c.y * size + c.x] = lowered[c]
			touched[c] = true

## One bridge's crossings from GroundKernels.underpass_hits (way index,
## arc along the bridge and the way, hit x and z), as the script's own
## search records them.
static func _cross_native(cuts: Dictionary, hits: PackedFloat64Array, lower: Array,
		src: PackedFloat32Array, size: int, step: float, h_a: float, h_b: float,
		b_len: float, m2u: float) -> void:
	for n in range(0, hits.size(), 5):
		if _at_bridge_end(hits[n + 1], b_len, m2u):
			continue
		var k := int(hits[n])
		var clear := _clearance(str((lower[k] as Dictionary).get("class", "")))
		var deck := lerpf(h_a, h_b, hits[n + 1] / b_len)
		var floor_y := deck - RoadBuilder.DECK_DEPTH_M - clear
		var cut := RoadGrading._sample(src, size, step, Vector2(hits[n + 3], hits[n + 4])) - floor_y
		if cut > 0.0 and cut <= MAX_CUT_M:
			if not cuts.has(k):
				cuts[k] = []
			(cuts[k] as Array).append([hits[n + 2], floor_y])

static func _at_bridge_end(arc: float, length: float, m2u: float) -> bool:
	var tolerance := END_TOLERANCE_M * m2u
	return arc <= tolerance or arc >= length - tolerance

## Lowers the posts along one way to its ramped floor profile: weight 1
## across the way, easing out by one post (narrow, so a short bridge's
## ends stay clear of the cut).
static func _cut_way(surface: PackedFloat32Array, level: PackedFloat32Array,
		size: int, step: float, way: Dictionary, crossings: Array, keep: Dictionary,
		m2u: float, touched: Dictionary = {}) -> void:
	var grade := RAMP_GRADE_RAIL if _clearance(str(way.get("class", ""))) == CLEAR_RAIL_M else RAMP_GRADE
	var half := maxf(float(way.get("width_m", 0.0)), 3.0) * 0.5 * m2u
	var inner := half
	var reach := half + step
	if grade == RAMP_GRADE_RAIL:
		# A track is narrower than the posts are apart: cut only across its
		# own width, the posts along it came down by different amounts as
		# it passed nearer or farther, and it rode metre-high bumps. Cut
		# fully to half a post out, as RoadGrading stamps its profile.
		inner = half + step * 0.5
		reach = half + step * 1.5
	var hs := float(size) * 0.5
	var line := GroundTruth._densify(way["points"], SAMPLE_M * m2u)
	var s := 0.0
	for i in line.size():
		if i > 0:
			s += line[i].distance_to(line[i - 1])
		var cap := INF
		for c in crossings:
			cap = minf(cap, float(c[1]) + grade * absf(s - float(c[0])) / m2u)
		if is_inf(cap):
			continue
		var p := line[i]
		var x0 := clampi(int(floor((p.x - reach) / step + hs)), 0, size - 1)
		var x1 := clampi(int(ceil((p.x + reach) / step + hs)), 0, size - 1)
		var z0 := clampi(int(floor((p.y - reach) / step + hs)), 0, size - 1)
		var z1 := clampi(int(ceil((p.y + reach) / step + hs)), 0, size - 1)
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var idx := z * size + x
				if not is_inf(level[idx]) or surface[idx] <= cap \
						or keep.has(Vector2i(x, z)):
					continue
				var d := Vector2((float(x) - hs) * step, (float(z) - hs) * step).distance_to(p)
				if d >= reach:
					continue
				var wgt := 1.0 - smoothstep(inner, reach, d)
				surface[idx] = minf(surface[idx], lerpf(surface[idx], cap, wgt))
				if wgt >= 0.5:
					touched[Vector2i(x, z)] = true

## A way's end as a centimetre grid node, to match ends that meet.
static func _node(p: Vector2, m2u: float) -> Vector2i:
	return Vector2i(roundi(p.x * 100.0 / m2u), roundi(p.y * 100.0 / m2u))

## OSM layer, a bridge without one counting as 1 (above the ground ways).
static func _layer(w: Dictionary) -> int:
	var l := int(w.get("layer", 0))
	if l == 0 and bool(w.get("bridge", false)):
		return 1
	return l

static func _clearance(cls: String) -> float:
	match cls:
		"rail", "light_rail", "subway", "narrow_gauge", "monorail", "funicular":
			return CLEAR_RAIL_M
		"footway", "path", "steps", "cycleway", "bridleway", "pedestrian", "track", "corridor":
			return CLEAR_PATH_M
	return CLEAR_ROAD_M

## Bounds of a way's points, grown by a metre.
static func _box(pts: PackedVector2Array) -> Rect2:
	return RingGeometry.aabb(pts).grow(1.0)

static func _length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	return total
