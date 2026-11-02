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
## A crossing needing more than this is a valley the data already has
## (or a layer mistake), never a cut.
const MAX_CUT_M := 8.0
const SAMPLE_M := 4.0

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
	# Per lower way: [arc position, floor height] of each crossing.
	var cuts := {}
	# Posts carrying a bridge end stay put: the deck sits on its banks.
	var keep := {}
	var hs := float(size) * 0.5
	for b in bridges:
		var ends: PackedVector2Array = b["points"]
		for e in [ends[0], ends[ends.size() - 1]]:
			keep[Vector2i(roundi(e.x / step + hs), roundi(e.y / step + hs))] = true
	for b in bridges:
		var bp: PackedVector2Array = b["points"]
		var b_len := _length(bp)
		if b_len <= 0.0:
			continue
		var h_a := RoadGrading._sample(src, size, step, bp[0])
		var h_b := RoadGrading._sample(src, size, step, bp[bp.size() - 1])
		var b_layer := _layer(b)
		for k in lower.size():
			var w: Dictionary = lower[k]
			if _layer(w) >= b_layer:
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
						var deck := lerpf(h_a, h_b, (b_arc + bp[i].distance_to(p)) / b_len)
						var floor_y := deck - RoadBuilder.DECK_DEPTH_M - clear
						var cut := RoadGrading._sample(src, size, step, p) - floor_y
						if cut > 0.0 and cut <= MAX_CUT_M:
							if not cuts.has(k):
								cuts[k] = []
							(cuts[k] as Array).append([w_arc + wp[j].distance_to(p), floor_y])
					w_arc += wp[j].distance_to(wp[j + 1])
				b_arc += bp[i].distance_to(bp[i + 1])
	for k in cuts:
		_cut_way(surface, level, size, step, lower[k], cuts[k], keep, m2u)

## Lowers the posts along one way to its ramped floor profile: weight 1
## across the way, easing out by one post (narrow, so a short bridge's
## ends stay clear of the cut).
static func _cut_way(surface: PackedFloat32Array, level: PackedFloat32Array,
		size: int, step: float, way: Dictionary, crossings: Array, keep: Dictionary,
		m2u: float) -> void:
	var half := maxf(float(way.get("width_m", 0.0)), 3.0) * 0.5 * m2u
	var inner := half
	var reach := half + step
	var hs := float(size) * 0.5
	var line := GroundTruth._densify(way["points"], SAMPLE_M * m2u)
	var s := 0.0
	for i in line.size():
		if i > 0:
			s += line[i].distance_to(line[i - 1])
		var cap := INF
		for c in crossings:
			cap = minf(cap, float(c[1]) + RAMP_GRADE * absf(s - float(c[0])) / m2u)
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

static func _length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	return total
