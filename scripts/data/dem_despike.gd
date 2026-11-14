class_name DemDespike
extends RefCounted

## Removes corrupt height spikes from the far DEM rings. High-latitude
## Terrarium tiles (ArcticDEM) carry compact towers hundreds of metres above
## the ground around them, which the far terrain raised into rock needles on
## Reykjavik's horizon. Each ring is cleaned on its own: a coarser ring cannot
## be the reference, because it disagrees with the fine one over whole
## districts. A spike starts at a wall-like step and its high side closes up
## within a few hundred metres, standing far taller than it is wide. The high
## side of a real cliff runs on into the land, and a real peak climbs too
## gradually to have the step.

## Spikes are confined to the ArcticDEM source, so real cliffs elsewhere are
## never at risk.
const MIN_LAT_DEG := 58.0
## A step between two neighbours must beat this height, and this slope.
const STEP_M := 100.0
const STEP_SLOPE := 3.0
## Widest blob (m across) that can be a spike.
const MAX_WIDE_M := 1000.0
## A spike's height over its half-width.
const MIN_ASPECT := 2.0
## Resampled rims ramp down over a few pixels: the refill grows this far
## into pixels still this far above the ground.
const GROW_PX := 4
const GROW_ABOVE_M := 30.0

## Cleans `rings` (FarFieldFetcher) in place. Returns the pixels replaced.
static func clean_rings(rings: Array, lat: float) -> int:
	if lat < MIN_LAT_DEG:
		return 0
	var replaced := 0
	for ring: Dictionary in rings:
		replaced += clean(ring, DemFetcher.metres_per_px(lat, int(ring["zoom"])))
	return replaced

## Flattens the spikes of `ring`, `mpp` metres per pixel, to the ground
## around each. The tallest steps go first.
static func clean(ring: Dictionary, mpp: float) -> int:
	var w := int(ring["width"])
	var h := int(ring["height"])
	var heights: PackedFloat32Array = ring["heights"]
	var seeds := _steps(heights, w, h, maxf(STEP_M, STEP_SLOPE * mpp))
	var seen := PackedByteArray()
	seen.resize(w * h)
	var limit := int(pow(MAX_WIDE_M / mpp, 2.0))
	var replaced := 0
	for seed_v: Vector3i in seeds:
		if seen[seed_v.y] == 0:
			replaced += _resolve(heights, w, h, seen, seed_v, limit, mpp)
	ring["heights"] = heights
	return replaced

## Every wall-like step as (height, high pixel, low pixel), tallest first.
static func _steps(heights: PackedFloat32Array, w: int, h: int, need: float) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for y in h:
		for x in w:
			var p := y * w + x
			if x + 1 < w and absf(heights[p] - heights[p + 1]) > need:
				out.append(_step(heights, p, p + 1))
			if y + 1 < h and absf(heights[p] - heights[p + w]) > need:
				out.append(_step(heights, p, p + w))
	out.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.x > b.x)
	return out

static func _step(heights: PackedFloat32Array, a: int, b: int) -> Vector3i:
	var high := a if heights[a] > heights[b] else b
	var low := b if high == a else a
	return Vector3i(int(heights[high] - heights[low]), high, low)

## Floods the high side of one step and flattens it if it is a spike. Pixels
## are left marked 1 either way, so a step of the same blob is not retried.
static func _resolve(heights: PackedFloat32Array, w: int, h: int, seen: PackedByteArray,
		seed_v: Vector3i, limit: int, mpp: float) -> int:
	var level := heights[seed_v.z] + 0.5 * (heights[seed_v.y] - heights[seed_v.z])
	var blob := PackedInt32Array([seed_v.y])
	seen[seed_v.y] = 2
	var i := 0
	var over := false
	while i < blob.size() and not over:
		for n in _around(blob[i], w, h):
			if seen[n] != 2 and heights[n] > level:
				seen[n] = 2
				blob.append(n)
		i += 1
		over = blob.size() > limit
	var replaced := 0
	if not over:
		replaced = _flatten(heights, w, h, seen, blob, mpp)
	for p in blob:
		seen[p] = 1
	return replaced

## Flattens `blob` (marked 2 in `seen`) to the median of its rim if it stands
## tall enough for its width.
static func _flatten(heights: PackedFloat32Array, w: int, h: int, seen: PackedByteArray,
		blob: PackedInt32Array, mpp: float) -> int:
	var rim := PackedFloat32Array()
	var peak := -INF
	for p in blob:
		peak = maxf(peak, heights[p])
		for n in _around(p, w, h):
			if seen[n] != 2:
				rim.append(heights[n])
	if rim.is_empty():
		return 0
	rim.sort()
	var ground := rim[rim.size() / 2]
	if peak - ground < STEP_M or (peak - ground) / (0.5 * sqrt(float(blob.size())) * mpp) < MIN_ASPECT:
		return 0
	var filled := blob.duplicate()
	var start := 0
	for _pass in GROW_PX:
		var end := filled.size()
		for k in range(start, end):
			for n in _around(filled[k], w, h):
				if seen[n] != 2 and heights[n] > ground + GROW_ABOVE_M:
					seen[n] = 2
					filled.append(n)
		start = end
	for p in filled:
		heights[p] = ground
		seen[p] = 1
	return filled.size()

## The four neighbours of pixel `p` inside the ring.
static func _around(p: int, w: int, h: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var x := p % w
	if x > 0:
		out.append(p - 1)
	if x + 1 < w:
		out.append(p + 1)
	if p >= w:
		out.append(p - w)
	if p + w < w * h:
		out.append(p + w)
	return out
