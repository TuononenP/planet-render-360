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

## The stretches of `pts` over a road of `grid` ([a, b, half width,
## service?] segments) or an apron, ending exactly at the kerb. With
## `keep_on` false, the stretches clear of them instead. `skip_service`
## leaves service roads out of the test.
static func on_road_runs(pts: PackedVector2Array, grid: Dictionary, aprons: Dictionary, m: float,
		keep_on: bool = true, skip_service: bool = false) -> Array:
	var size := RoadMarkings.CELL_M * m
	var reach := RoadMarkings.ON_ROAD_REACH_M * m
	return _runs(pts, m, func(p: Vector2) -> bool:
		for seg: Array in RoadMarkings._grid_near(grid, p, reach, m):
			if skip_service and seg.size() > 3 and bool(seg[3]):
				continue
			if Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p) <= float(seg[2]):
				return keep_on
		for ring: PackedVector2Array in aprons.get(RoadMarkings._cell(p, size), []):
			if Geometry2D.is_point_in_polygon(p, ring):
				return keep_on
		return not keep_on)

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
static func pieces(pts: PackedVector2Array, grid: Dictionary, aprons: Dictionary, m: float) -> Array:
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
	return out

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
