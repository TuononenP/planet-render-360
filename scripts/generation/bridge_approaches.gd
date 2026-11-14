class_name BridgeApproaches
extends RefCounted

## Approach slabs for bridge structures (BridgeStructures). The ground is a
## grid of posts 9 m apart: where a way passes under a bridge 10 m from its
## end, the post inside the span is cut down for it and the ground between
## that post and the next one outside the span slopes down into the cut.
## The approach road, draped on that ground, dived several metres in the
## last few metres before the deck, and the deck, held to it, tipped down to
## meet it. A real bridge stands on an abutment with wing walls and an
## approach slab. Here each member's deck runs on along its approach road
## until the ground comes back up to the deck, and that stretch is part of
## the structure: the same slab, parapets along its sides, and walls down to
## the ground under its sides and under the span's old end.

## Longest approach slab, metres.
const TAIL_MAX_M := 16.0
## The slab ends where the ground is within this of the deck, metres.
const TAIL_TOL_M := 0.15
## Member ends this close share one slab length, metres.
const CLUSTER_M := 12.0
## Most water a slab crosses at the bank, metres.
const TAIL_WET_M := 4.0
## A slab is only laid where the ground dips this far under the deck, metres.
const TAIL_MIN_DIVE_M := 0.3
## An approach whose ground one post out stands this far over the ground at
## the bridge end has dived into a cut: its road level is the ground there.
const DIVE_M := 0.5

## The level of the road leaving a bridge end at `p` along `road` (its
## approach, ordered away from the end): the ground at the end, or where the
## ground there has been pulled down into a cut under the span (more than
## DIVE_M under the ground one post out), the ground one post out.
static func road_level(road: PackedVector2Array, surf: RoadBuilder._Surface, m2u: float) -> float:
	var at := surf.height(road[0].x, road[0].y)
	var out := _along(road, surf.step)
	if surf.ground.water_at(out.x, out.y) > 0.0:
		return at
	var further := surf.height(out.x, out.y)
	return further if further - at > DIVE_M * m2u else at

## Point `dist` along polyline `pts` (its end when shorter).
static func _along(pts: PackedVector2Array, dist: float) -> Vector2:
	var run := 0.0
	for i in range(1, pts.size()):
		var seg := pts[i].distance_to(pts[i - 1])
		if run + seg >= dist:
			return pts[i - 1].lerp(pts[i], (dist - run) / maxf(seg, 1e-6))
		run += seg
	return pts[pts.size() - 1]

## Runs each member's deck on along its approach where the ground dips under
## it (`s.tails`), adds those stretches to the outline, and keeps the span's
## old abutment ends (`s.span_ends`) for their walls down to the ground.
static func extend(s: BridgeStructures.Structure, index: RoadBridgeDecks.Index, surf: RoadBuilder._Surface,
		m2u: float) -> void:
	s.span = s.ring.duplicate()
	var opens := BridgeStructures._openings(s, index, surf, m2u)
	for e in s.ring.size():
		var a := s.ring[e]
		var b := s.ring[(e + 1) % s.ring.size()]
		for run: Array in BridgeStructures._runs(opens[e] as Array):
			if int(run[2]) == 2:
				s.span_ends.append([a.lerp(b, float(run[0])), a.lerp(b, float(run[1]))])
	var step := 1.0 * m2u
	# Each member end's approach and the slab it needs (0: none).
	var ends: Array = []  # [li, side, end point, approach (dense), needed length]
	for li in s.members:
		var line: Dictionary = index.lines[li]
		var pts: PackedVector2Array = line["points"]
		for side_i in 2:
			var end := pts[0] if side_i == 0 else pts[pts.size() - 1]
			var back := pts[1] if side_i == 0 else pts[pts.size() - 2]
			if surf.ground.water_at(end.x, end.y) > 0.0:
				continue
			var road := BridgeLandings.approach_from(surf, end, (end - back).normalized())
			if road.size() < 2:
				continue
			var dense := RoadBuilder._resample(road, step)
			ends.append([li, side_i, end, dense, _needed(s.level_at(end), dense, surf, m2u)])
	# Members ending side by side end their slabs together: a carriageway's
	# slab running on past its link's left the outline stepped, and a
	# parapet stood along the step beside the link's road.
	var grown := false
	var tails := {}
	for e: Array in ends:
		var want := 0.0
		for o: Array in ends:
			if (o[2] as Vector2).distance_to(e[2]) <= CLUSTER_M * m2u:
				want = maxf(want, float(o[4]))
		if want <= 0.0:
			continue
		var level := s.level_at(e[2])
		var dense: PackedVector2Array = e[3]
		var tail := PackedVector2Array()
		var run := 0.0
		var reach := 0.0
		for k in range(1, dense.size()):
			run += dense[k].distance_to(dense[k - 1])
			# Never under the ground (a rise the slab would cut through).
			if run > want + 0.01 * m2u or surf.height(dense[k].x, dense[k].y) > level + TAIL_TOL_M * m2u:
				break
			tail.append(dense[k])
			reach = run
		if tail.is_empty():
			continue
		var line: Dictionary = index.lines[int(e[0])]
		var half := float(line["half"]) + BridgeStructures.EDGE_BEAM_M * m2u
		var slab := PackedVector2Array([e[2]])
		slab.append_array(tail)
		var polys: Array = Geometry2D.offset_polyline(slab, half, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT)
		# The outline's end edge runs on with it: an outline wider than
		# the roads (shoulders, a carriageway and its link) stepped in to
		# the slab, and a parapet stood across the step over the dip.
		var end_edge := _end_edge(s.span, e[2], (dense[1] - dense[0]).normalized(), m2u)
		if not end_edge.is_empty():
			var dir := (dense[1] - dense[0]).normalized() * reach
			polys.append(PackedVector2Array([end_edge[0], end_edge[1], end_edge[1] + dir, end_edge[0] + dir]))
		for poly: PackedVector2Array in polys:
			s.ring = _merged(s.ring, poly)
			grown = true
		if int(e[1]) == 0:
			tail.reverse()
		if not tails.has(e[0]):
			tails[e[0]] = [PackedVector2Array(), PackedVector2Array()]
		(tails[e[0]] as Array)[int(e[1])] = tail
	s.tails = tails
	if grown:
		s.ring = _closed(s.ring, SLIT_M * 0.5 * m2u)
		s.bounds = RingGeometry.aabb(s.ring)

## Slits narrower than this between two slabs side by side close, metres.
const SLIT_M := 2.0

## `ring` with its slits narrower than 2 `r` closed (grown by `r` and
## shrunk back): a carriageway's and its link's slabs left a gap between
## them, and parapets stood along both its sides on the deck.
static func _closed(ring: PackedVector2Array, r: float) -> PackedVector2Array:
	for grown_ring: PackedVector2Array in Geometry2D.offset_polygon(ring, r, Geometry2D.JOIN_MITER):
		# The clipper's outer rings run counter-clockwise, its holes clockwise.
		if Geometry2D.is_polygon_clockwise(grown_ring):
			continue
		var best := PackedVector2Array()
		for back: PackedVector2Array in Geometry2D.offset_polygon(grown_ring, -r, Geometry2D.JOIN_MITER):
			if not Geometry2D.is_polygon_clockwise(back) \
					and absf(BridgeStructures.Plan._area(back)) > absf(BridgeStructures.Plan._area(best)):
				best = back
		if best.size() >= 3 and absf(BridgeStructures.Plan._area(best)) >= absf(BridgeStructures.Plan._area(ring)) * 0.99:
			return best
	return ring

## How far along `dense` (an approach, from the bridge end) the ground comes
## back up to within TAIL_TOL_M of the deck `level`, where it dipped more
## than TAIL_MIN_DIVE_M on the way; 0 where it never dips (no slab needed)
## or does not come back within TAIL_MAX_M, or the approach runs into water.
static func _needed(level: float, dense: PackedVector2Array, surf: RoadBuilder._Surface, m2u: float) -> float:
	var run := 0.0
	var wet := 0.0
	var dive := 0.0
	for k in range(1, dense.size()):
		var q := dense[k]
		var seg := q.distance_to(dense[k - 1])
		run += seg
		# A sliver of the stream's edge at the bank is crossed; more water
		# than that is the bridge's business, not a slab's.
		if surf.ground.water_at(q.x, q.y) > 0.0:
			wet += seg
			if wet > TAIL_WET_M * m2u:
				return 0.0
			continue
		if run > TAIL_MAX_M * m2u:
			return 0.0
		var h := surf.height(q.x, q.y)
		dive = maxf(dive, level - h)
		if h >= level - TAIL_TOL_M * m2u:
			return run if dive >= TAIL_MIN_DIVE_M * m2u else 0.0
	return 0.0

## Longest outline end edge an approach slab carries on, metres.
const END_EDGE_MAX_M := 40.0

## The edge of outline `span` nearest the member end `p` that its approach
## (heading `dir`) leaves through, roughly square to it; [] when none.
static func _end_edge(span: PackedVector2Array, p: Vector2, dir: Vector2, m2u: float) -> Array:
	var best := INF
	var found: Array = []
	for i in span.size():
		var a := span[i]
		var b := span[(i + 1) % span.size()]
		var len := a.distance_to(b)
		if len < 0.5 * m2u or len > END_EDGE_MAX_M * m2u or absf((b - a).normalized().dot(dir)) > 0.5:
			continue
		var d := Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)
		if d < best:
			best = d
			found = [a, b]
	return found if best <= 3.0 * m2u else []

## The larger outer ring of `ring` merged with `poly` (`ring` itself when
## they do not join).
static func _merged(ring: PackedVector2Array, poly: PackedVector2Array) -> PackedVector2Array:
	var best := ring
	for piece: PackedVector2Array in Geometry2D.merge_polygons(ring, poly):
		if not Geometry2D.is_polygon_clockwise(piece) \
				and absf(BridgeStructures.Plan._area(piece)) > absf(BridgeStructures.Plan._area(best)):
			best = piece
	return best

## True where `p` lies on an approach slab (outside the span's outline).
static func on_tail(s: BridgeStructures.Structure, p: Vector2, m2u: float) -> bool:
	if s.tails.is_empty() or s.span.size() < 3 or Geometry2D.is_point_in_polygon(p, s.span):
		return false
	for i in s.span.size():
		var q := Geometry2D.get_closest_point_to_segment(p, s.span[i], s.span[(i + 1) % s.span.size()])
		if q.distance_to(p) <= 0.3 * m2u:
			return false
	return true

## Walls down to the ground under the span's old abutment ends now inside
## the slab: the deck's end over the cut, seen from the way passing under.
static func span_end_walls(side: RoadBuilder._Batch, s: BridgeStructures.Structure, surf: RoadBuilder._Surface,
		m2u: float) -> void:
	if s.tails.is_empty():
		return
	var inner := Geometry2D.offset_polygon(s.ring, -0.2 * m2u)
	for seg: Array in s.span_ends:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var mid := (a + b) * 0.5
		var inside := false
		for ring: PackedVector2Array in inner:
			inside = inside or Geometry2D.is_point_in_polygon(mid, ring)
		if not inside:
			continue
		var n := maxi(1, ceili(a.distance_to(b) / (BridgeStructures.SLICE_M * m2u)))
		var out := Vector2(-(b - a).y, (b - a).x).normalized()
		for k in n:
			var pa := a.lerp(b, float(k) / float(n))
			var pb := a.lerp(b, float(k + 1) / float(n))
			if surf.ground.water_at(pa.x, pa.y) > 0.0 or surf.ground.water_at(pb.x, pb.y) > 0.0:
				continue
			var ya := s.surface_at(pa) - s.depth
			var yb := s.surface_at(pb) - s.depth
			var ga := surf.height(pa.x, pa.y) - 0.3 * m2u
			var gb := surf.height(pb.x, pb.y) - 0.3 * m2u
			if ga < ya or gb < yb:
				RoadBuilder._wall(side, pa, pb, ga, gb, ya, yb, out, true)
				RoadBuilder._wall(side, pa, pb, ga, gb, ya, yb, -out, true)
