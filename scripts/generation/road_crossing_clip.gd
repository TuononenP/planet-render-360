class_name RoadCrossingClip
extends RefCounted

## Where a crossing's paint may lie. A mapped crossing way runs on across
## the pavement, bends at the kerbs and meets its neighbours at the
## corners; its paint stops at the kerb line, lies in straight bands, and
## no two bands paint the same ground.

## Sampling along a way to find its runs, and the shortest run kept.
const STEP_M := 1.0
const MIN_RUN_M := 1.0
## Halvings that place a run's end between two samples (1 m / 64).
const EDGE_STEPS := 6
## A band with less than this share of itself clear of longer bands is
## another mapping of the same crossing.
const MIN_CLEAR := 0.5
## What a cut against another band leaves, shorter than this, is a scrap;
## so is a piece this short beside a longer one where a way bends.
const FRAGMENT_M := 2.5
const BEND_SCRAP_M := 4.0
## Bands at least this wide (m, RoadMarkings.SCRAMBLE_WIDTH_M) trim to their edges.
const WIDE_M := 8.0

## The stretches of `pts` over a road of `grid` ([a, b, half width,
## service?] segments) or an apron, ending exactly at the kerb. With
## `keep_on` false, the stretches clear of them instead. `skip_service`
## leaves service roads out of the test.
static func on_road_runs(pts: PackedVector2Array, grid: Dictionary, aprons: Dictionary, m: float,
		keep_on: bool = true, skip_service: bool = false) -> Array:
	return _runs(pts, m, func(p: Vector2) -> bool:
		return _on_road(p, grid, aprons, m, skip_service) == keep_on)

## Fast path for clipping a footway against junction aprons only (no road grid):
## skips resampling entirely when no apron cell overlaps `pts`'s AABB.
static func off_apron_runs(pts: PackedVector2Array, aprons: Dictionary, m: float) -> Array:
	if aprons.is_empty() or pts.size() < 2:
		return [pts]
	var cell := RoadMarkings.CELL_M * m
	var min_x := pts[0].x
	var max_x := min_x
	var min_y := pts[0].y
	var max_y := min_y
	for i in range(1, pts.size()):
		var p := pts[i]
		if p.x < min_x: min_x = p.x
		elif p.x > max_x: max_x = p.x
		if p.y < min_y: min_y = p.y
		elif p.y > max_y: max_y = p.y
	var hit := false
	for cx in range(floori(min_x / cell), floori(max_x / cell) + 1):
		for cy in range(floori(min_y / cell), floori(max_y / cell) + 1):
			if aprons.has(Vector2i(cx, cy)):
				hit = true
				break
		if hit:
			break
	if not hit:
		return [pts]
	return _runs(pts, m, func(p: Vector2) -> bool:
		for ring: PackedVector2Array in aprons.get(RoadMarkings._cell(p, cell), []):
			if Geometry2D.is_point_in_polygon(p, ring):
				return false
		return true)

## Squared distance from point `p` to segment `a`..`b`.
static func _seg_dist_sq(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 <= 1e-12:
		return p.distance_squared_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_squared_to(a + ab * t)

## True when `p` is over a road of `grid` or inside an apron.
static func _on_road(p: Vector2, grid: Dictionary, aprons: Dictionary, m: float, skip_service: bool = false) -> bool:
	var cell := RoadMarkings.CELL_M * m
	var reach := RoadMarkings.ON_ROAD_REACH_M * m
	var cx0 := floori((p.x - reach) / cell)
	var cx1 := floori((p.x + reach) / cell)
	var cy0 := floori((p.y - reach) / cell)
	var cy1 := floori((p.y + reach) / cell)
	for x in range(cx0, cx1 + 1):
		for z in range(cy0, cy1 + 1):
			var bucket: Variant = grid.get(Vector2i(x, z))
			if bucket == null:
				continue
			for seg: Array in (bucket as Array):
				if skip_service and seg.size() > 3 and bool(seg[3]):
					continue
				var hw := float(seg[2])
				if _seg_dist_sq(p, seg[0], seg[1]) <= hw * hw:
					return true
	if not aprons.is_empty():
		var ab: Variant = aprons.get(RoadMarkings._cell(p, cell))
		if ab != null:
			for ring: PackedVector2Array in (ab as Array):
				if Geometry2D.is_point_in_polygon(p, ring):
					return true
	return false

## The runs of `pts` where `keep` holds, each end placed on the boundary.
static func _runs(pts: PackedVector2Array, m: float, keep: Callable) -> Array:
	var out: Array = []
	var cur := PackedVector2Array()
	var prev := Vector2.INF
	var prev_kept := false
	for j in pts.size() - 1:
		var n := maxi(1, ceili(pts[j].distance_to(pts[j + 1]) / (STEP_M * m)))
		for k in n + (1 if j == pts.size() - 2 else 0):
			var p := pts[j].lerp(pts[j + 1], float(k) / float(n))
			var kept: bool = keep.call(p)
			if prev.is_finite() and kept != prev_kept:
				cur.append(_edge(prev, p, prev_kept, keep))
				if not kept:
					_end_run(out, cur, m)
					cur = PackedVector2Array()
			if kept:
				cur.append(p)
			prev = p
			prev_kept = kept
	_end_run(out, cur, m)
	return out

## The point between `a` and `b` where `keep` changes; `a_kept` is its value at a.
static func _edge(a: Vector2, b: Vector2, a_kept: bool, keep: Callable) -> Vector2:
	var lo := a
	var hi := b
	for _i in EDGE_STEPS:
		var mid := (lo + hi) * 0.5
		if bool(keep.call(mid)) == a_kept:
			lo = mid
		else:
			hi = mid
	return lo if a_kept else hi

static func _end_run(out: Array, run: PackedVector2Array, m: float) -> void:
	if run.size() >= 2 and run[0].distance_to(run[run.size() - 1]) >= MIN_RUN_M * m:
		out.append(run)

## `run` cut at its bends into straight two-point pieces: a crossing's
## bands fan out and fold if its ribbon has to turn a corner.
static func straight_pieces(run: PackedVector2Array, tolerance: float) -> Array:
	var a := run[0]
	var b := run[run.size() - 1]
	var worst := -1
	var far := tolerance
	for i in range(1, run.size() - 1):
		var d := Geometry2D.get_closest_point_to_segment(run[i], a, b).distance_to(run[i])
		if d > far:
			far = d
			worst = i
	if worst < 0:
		return [PackedVector2Array([a, b])]
	return straight_pieces(run.slice(0, worst + 1), tolerance) + straight_pieces(run.slice(worst), tolerance)

## The straight painted pieces of a crossing way: over the carriageways
## it crosses, or over a service road when it crosses nothing else.
## A band `width_m` of at least WIDE_M keeps only the stretch where both
## its edges are over the road too: one straight band laid wide across a
## kerb that runs at a slant hangs its corner over the pavement.
static func pieces(pts: PackedVector2Array, grid: Dictionary, aprons: Dictionary, m: float,
		width_m: float = 0.0) -> Array:
	var runs := on_road_runs(pts, grid, aprons, m, true, true)
	if runs.is_empty():
		runs = on_road_runs(pts, grid, aprons, m)
	var out: Array = []
	for run: PackedVector2Array in runs:
		var straight := straight_pieces(run, RoadMarkings.BEND_TOL_M * m)
		var longest := 0.0
		for piece: PackedVector2Array in straight:
			longest = maxf(longest, piece[0].distance_to(piece[1]))
		# The turn a mapped way makes at the kerb leaves a scrap of band
		# beside the crossing proper: shorter than a band is wide.
		for piece: PackedVector2Array in straight:
			var length := piece[0].distance_to(piece[1])
			if length >= BEND_SCRAP_M * m or is_equal_approx(length, longest):
				out.append(piece)
	if width_m < WIDE_M:
		return out
	var trimmed: Array = []
	for piece: PackedVector2Array in out:
		var side := (piece[1] - piece[0]).normalized().orthogonal() * width_m * 0.5 * m
		# Only the ends move: a gap in the road grid inside the crossing
		# (between carriageways) must not cut the band in two.
		var wide_runs := _runs(piece, m, func(p: Vector2) -> bool:
			return _on_road(p + side, grid, aprons, m) and _on_road(p - side, grid, aprons, m))
		if not wide_runs.is_empty():
			var last: PackedVector2Array = wide_runs[wide_runs.size() - 1]
			trimmed.append(PackedVector2Array([(wide_runs[0] as PackedVector2Array)[0], last[last.size() - 1]]))
	return trimmed

## Cuts every painted crossing piece of `by_road` ({road: {finish,
## width_m, runs}}) back to the ground no longer piece already paints,
## and drops one that is mostly painted already: two ways mapped over one
## crossing, the pieces either side of a bend, bands meeting at a corner.
static func dedupe(by_road: Dictionary, m: float) -> void:
	var all: Array = []
	var roads: Array = by_road.keys()
	roads.sort()
	for i: int in roads:
		var entry: Dictionary = by_road[i]
		if not entry.has("runs") or not str(entry["finish"]).begins_with("crossing"):
			continue
		for run: PackedVector2Array in entry["runs"]:
			all.append([run[0].distance_to(run[run.size() - 1]), i, run, float(entry["width_m"]) * m * 0.5])
		entry["runs"] = []
	# Longest first; the road index breaks ties so a build repeats itself.
	all.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[0]) > float(b[0]) if not is_equal_approx(float(a[0]), float(b[0])) else int(a[1]) < int(b[1]))
	var kept := {}
	var reach := RoadMarkings.ON_ROAD_REACH_M * m
	for item: Array in all:
		var run: PackedVector2Array = item[2]
		# A band overlaps where its middle or either edge enters another:
		# the edges catch two bands meeting side by side at a corner.
		var side := (run[run.size() - 1] - run[0]).normalized().orthogonal() * float(item[3])
		var clear := _runs(run, m, func(p: Vector2) -> bool:
			for band: Array in RoadMarkings._grid_near(kept, p, reach, m):
				for q: Vector2 in [p, p + side, p - side]:
					if in_band(q, band[0], band[1], float(band[2])):
						return false
			return true)
		# What a cut leaves at a corner is a scrap, not a crossing.
		if clear.size() != 1 or not is_equal_approx((clear[0] as PackedVector2Array)[0].distance_to(
				(clear[0] as PackedVector2Array)[(clear[0] as PackedVector2Array).size() - 1]), float(item[0])):
			clear = clear.filter(func(piece: PackedVector2Array) -> bool:
				return piece[0].distance_to(piece[piece.size() - 1]) >= FRAGMENT_M * m)
		var left := 0.0
		for piece: PackedVector2Array in clear:
			left += piece[0].distance_to(piece[piece.size() - 1])
		if left < float(item[0]) * MIN_CLEAR:
			continue
		for piece: PackedVector2Array in clear:
			var straight := PackedVector2Array([piece[0], piece[piece.size() - 1]])
			((by_road[int(item[1])] as Dictionary)["runs"] as Array).append(straight)
			RoadMarkings._grid_add(kept, straight[0], straight[1], [straight[0], straight[1], float(item[3])], m)

## True when `p` lies in the rectangle `half` either side of a-b (square ends).
static func in_band(p: Vector2, a: Vector2, b: Vector2, half: float) -> bool:
	var d := b - a
	var length := d.length()
	if length < 0.00001:
		return p.distance_to(a) <= half
	var t := d / length
	var along := (p - a).dot(t)
	return along >= 0.0 and along <= length and absf((p - a).cross(t)) <= half
