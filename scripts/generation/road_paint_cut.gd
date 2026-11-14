class_name RoadPaintCut
extends RefCounted

## Where lane paint stops. Lines are laid along whole streets, then cut
## where a painter would lift the machine: across a junction, a crossing
## and a stop line. The cut is made in the geometry, at the edge itself,
## so a line never runs on under a zebra or into the junction box.

## Zone kinds: [RING, polygon], [DISC, centre, radius], [BAND, a, b, half].
const RING := 0
const DISC := 1
const BAND := 2
## Paint keeps this clear of a crossing's band or a stop line.
const BAND_PAD_M := 0.3
const SAMPLE_M := 1.0
const EDGE_STEPS := 6
## A shorter stretch than this between two cuts is not painted: the stub
## between a stop line and its crossing, or between two crossings.
const MIN_PIECE_M := 4.0

## The zones of `plan`, bucketed by RoadMarkings cells. `junctions_only`
## leaves the crossings and stop lines out.
static func zones(plan: RoadMarkings.Plan, m: float, junctions_only: bool = false) -> Dictionary:
	var grid := {}
	if plan == null:
		return grid
	for ring: PackedVector2Array in plan.clear:
		var lo := ring[0]
		var hi := ring[0]
		for p in ring:
			lo = lo.min(p)
			hi = hi.max(p)
		_add(grid, lo, hi, 0.0, [RING, ring], m)
	for disc: Array in plan.discs:
		_add(grid, disc[0], disc[0], float(disc[1]), [DISC, disc[0], float(disc[1])], m)
	if junctions_only:
		return grid
	var pad := BAND_PAD_M * m
	for i: int in plan.by_road:
		var entry: Dictionary = plan.by_road[i]
		if not str(entry["finish"]).begins_with("crossing"):
			continue
		for run: PackedVector2Array in entry.get("runs", []):
			_band(grid, run, float(entry["width_m"]) * m * 0.5 + pad, m)
	for c: PackedVector2Array in plan.inferred:
		_band(grid, c, RoadMarkings.INFERRED_DEPTH_M * m * 0.5 + pad, m)
	for s: PackedVector2Array in plan.stops:
		_band(grid, s, RoadMarkings.STOP_DEPTH_M * m * 0.5 + pad, m)
	return grid

static func _band(grid: Dictionary, run: PackedVector2Array, half: float, m: float) -> void:
	var a := run[0]
	var b := run[run.size() - 1]
	_add(grid, a.min(b), a.max(b), half, [BAND, a, b, half], m)

static func _add(grid: Dictionary, lo: Vector2, hi: Vector2, pad: float, zone: Array, m: float) -> void:
	for k in RoadMarkings._cells(lo, hi, pad, m):
		if not grid.has(k):
			grid[k] = []
		(grid[k] as Array).append(zone)

## True when `p` lies in a zone of `grid`.
static func inside(grid: Dictionary, p: Vector2, m: float) -> bool:
	for zone: Array in grid.get(RoadMarkings._cell(p, RoadMarkings.CELL_M * m), []):
		match int(zone[0]):
			RING:
				if Geometry2D.is_point_in_polygon(p, zone[1]):
					return true
			DISC:
				if p.distance_to(zone[1]) <= float(zone[2]):
					return true
			BAND:
				if Geometry2D.get_closest_point_to_segment(p, zone[1], zone[2]).distance_to(p) <= float(zone[3]):
					return true
	return false

## The stretches of polyline `pts` outside every zone, cut at the zone
## edges; they keep the polyline's own vertices in between.
static func keep(pts: PackedVector2Array, grid: Dictionary, m: float) -> Array:
	if grid.is_empty() or pts.size() < 2:
		return [pts]
	var out: Array = []
	var size := RoadMarkings.CELL_M * m
	var cur := PackedVector2Array()
	var was_in := inside(grid, pts[0], m)
	if not was_in:
		cur.append(pts[0])
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		# No zone reaches either end's cell: the segment is clear.
		if not was_in and not grid.has(RoadMarkings._cell(a, size)) and not grid.has(RoadMarkings._cell(b, size)):
			cur.append(b)
			continue
		var n := maxi(1, ceili(a.distance_to(b) / (SAMPLE_M * m)))
		var prev := a
		for k in range(1, n + 1):
			var q := a.lerp(b, float(k) / float(n))
			var q_in := inside(grid, q, m)
			if q_in != was_in:
				var edge := _edge(prev, q, was_in, grid, m)
				if was_in:
					cur = PackedVector2Array([edge])
				else:
					cur.append(edge)
					_end(out, cur, m)
					cur = PackedVector2Array()
				was_in = q_in
			prev = q
		if not was_in:
			cur.append(b)
	_end(out, cur, m)
	return out

static func _edge(a: Vector2, b: Vector2, a_in: bool, grid: Dictionary, m: float) -> Vector2:
	var lo := a
	var hi := b
	for _i in EDGE_STEPS:
		var mid := (lo + hi) * 0.5
		if inside(grid, mid, m) == a_in:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5

static func _end(out: Array, run: PackedVector2Array, m: float) -> void:
	if run.size() < 2:
		return
	var length := 0.0
	for i in run.size() - 1:
		length += run[i].distance_to(run[i + 1])
	if length >= MIN_PIECE_M * m:
		out.append(run)
