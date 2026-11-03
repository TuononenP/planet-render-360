class_name RingGeometry
extends RefCounted

## Dependency-free 2D ring helpers (footprints and roof outlines in XZ)
## shared by BuildingBuilder and BuildingDetail. A leaf class on purpose:
## it names no other project class, so neither builder can end up in a
## class-load cycle through it (the load-order-dependent failure noted in
## the plan's 2026-10-28 render-check row).

## Rings up to this many vertices (every building) sort all vertices by
## distance to pick a keyhole seam; bigger ones (map coastlines) pick lazily.
const SORT_MAX_VERTICES := 512
## Candidates the lazy pick tries before taking the nearest vertex.
const LAZY_TRIES := 128

static func signed_area(ring: PackedVector2Array) -> float:
	var a := 0.0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5

static func aabb(ring: PackedVector2Array) -> Rect2:
	var mn := ring[0]
	var mx := ring[0]
	for p in ring:
		mn.x = minf(mn.x, p.x)
		mn.y = minf(mn.y, p.y)
		mx.x = maxf(mx.x, p.x)
		mx.y = maxf(mx.y, p.y)
	return Rect2(mn, mx - mn)

static func centroid(ring: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in ring:
		c += p
	return c / float(maxi(ring.size(), 1))

## Ray-cast point-in-ring.
static func point_in_ring(p: Vector2, ring: PackedVector2Array) -> bool:
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

## Roof reference point: the centroid, or a centimetre nudge when the
## centroid lands exactly on the boundary (symmetric L inner corner).
## Still outside for true donuts/C-notches — the caller keeps the flat
## seal cap then.
static func interior_point(ring: PackedVector2Array) -> Vector2:
	var c := centroid(ring)
	if point_in_ring(c, ring):
		return c
	for n in [Vector2(0.03, 0.02), Vector2(-0.02, 0.03),
			Vector2(0.02, -0.03)]:
		if point_in_ring(c + n, ring):
			return c + n
	return c

## Unit direction of the ring's longest edge, folded to point +X (or +Y
## for a vertical edge): the roof ridge and detail axis. A block rotated
## to its street keeps its roof aligned with it; axis-aligned footprints
## reduce to the old AABB axis.
static func dominant_axis(ring: PackedVector2Array) -> Vector2:
	var best := 0.0
	var axis := Vector2.RIGHT
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length_squared() > best + 0.000001:
			best = e.length_squared()
			axis = e
	axis = axis.normalized()
	if axis.x < -0.000001 or (absf(axis.x) <= 0.000001 and axis.y < 0.0):
		axis = -axis
	return axis

## Largest distance from c to the ring along one axis.
static func half_extent(ring: PackedVector2Array, c: Vector2, axis: Vector2) -> float:
	var e := 0.0
	for p in ring:
		e = maxf(e, absf((p - c).dot(axis)))
	return e

## One weakly simple ring for `outer` with `holes` cut in (keyhole
## bridges: each hole, rightmost first, joins the nearest outer vertex by
## a doubled seam), so Geometry2D.triangulate_polygon — which knows no
## holes — can triangulate a courtyard block. Holes run against the
## outer's winding. The seam goes to the nearest outer vertex it can
## reach without crossing an edge; drop_hole_triangles filters the rest.
## `sliver` > 0 moves the second visit of each seam end that far aside, so
## the seam is a thin sliver and no two ring points coincide: Geometry2D's
## ear clipping treats a coincident point as inside every ear it touches
## and can run out of ears beside a coast. 0 keeps the exact doubled seam.
static func bridge_holes(outer: PackedVector2Array, holes: Array, sliver: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array(outer)
	var ccw := signed_area(outer) > 0.0
	var sorted := holes.duplicate()
	sorted.sort_custom(func(a: PackedVector2Array, b: PackedVector2Array) -> bool:
		return aabb(a).end.x > aabb(b).end.x)
	for h in sorted:
		var hole := PackedVector2Array(h as PackedVector2Array)
		if hole.size() < 3:
			continue
		if (signed_area(hole) > 0.0) == ccw:
			hole.reverse()
		var hi := 0
		for i in hole.size():
			if hole[i].x > hole[hi].x:
				hi = i
		var oi := _visible_vertex(out, hole[hi], sorted)
		var aside := Vector2.ZERO
		if sliver > 0.0:
			var along := (out[oi] - hole[hi]).normalized()
			aside = Vector2(-along.y, along.x) * sliver
		var seam := PackedVector2Array()
		for k in hole.size() + 1:
			seam.append(hole[(hi + k) % hole.size()])
		seam[hole.size()] += aside
		seam.append(out[oi] + aside)
		var joined := out.slice(0, oi + 1)
		joined.append_array(seam)
		joined.append_array(out.slice(oi + 1))
		out = joined
	return out

## The holes of `holes` that cross or touch neither an edge of `outer` nor
## a larger kept hole. Such a hole (an island generalised into the coast
## or into its neighbour) cannot be part of any simple ring, and one is
## enough to stop a triangulation; of two crossing holes the smaller goes.
static func holes_clear_of(outer: PackedVector2Array, holes: Array) -> Array:
	var order: Array = holes.duplicate()
	order.sort_custom(func(a: PackedVector2Array, b: PackedVector2Array) -> bool:
		return absf(signed_area(a)) > absf(signed_area(b)))
	var clear: Array = []
	var boxes: Array[Rect2] = []
	for h in order:
		var hole := h as PackedVector2Array
		var box := aabb(hole).grow(0.5)
		var tangled := _ring_crosses(hole, box, outer)
		for i in clear.size():
			if tangled:
				break
			tangled = box.intersects(boxes[i]) and _ring_crosses(hole, box, clear[i])
		if not tangled:
			clear.append(hole)
			boxes.append(box)
	return clear

## `holes` made fit for one simple ring with `outer`, without losing the
## islands that tangle: holes that cross each other are merged, and one
## that reaches the outline is cut to the part inside `outer` (an island
## generalised into the coast) and pulled `inset` in from it, so none
## touches the outline or another. The rest come back unchanged, in no
## particular order.
static func untangled_holes(outer: PackedVector2Array, holes: Array, inset: float) -> Array:
	var pieces: Array = holes.duplicate()
	var i := 0
	while i < pieces.size():
		var merged := false
		var box := aabb(pieces[i]).grow(0.5)
		for j in range(i + 1, pieces.size()):
			var other := pieces[j] as PackedVector2Array
			var other_box := aabb(other).grow(0.5)
			if box.intersects(other_box) and _ring_crosses(other, other_box, pieces[i]):
				var union := _solid_parts(Geometry2D.merge_polygons(pieces[i], other))
				if union.size() == 1:
					pieces[i] = union[0]
					pieces.remove_at(j)
					merged = true
					break
		if not merged:
			i += 1
	var out: Array = []
	for piece in pieces:
		# Clipping against a coastline of thousands of vertices is costly:
		# only the pieces that reach it are cut and pulled in.
		if not _ring_crosses(piece, aabb(piece).grow(0.5), outer):
			out.append(piece)
			continue
		for inside in _solid_parts(Geometry2D.intersect_polygons(piece, outer)):
			out.append_array(_solid_parts(Geometry2D.offset_polygon(inside, -inset)))
	return out

## The solid polygons of a clipping result, which lists outer boundaries and
## the holes cut in them alike: those wound as the largest one is.
static func _solid_parts(polygons: Array) -> Array:
	var largest := 0.0
	var clockwise := false
	for p in polygons:
		var area := absf(signed_area(p))
		if area > largest:
			largest = area
			clockwise = Geometry2D.is_polygon_clockwise(p)
	var solid: Array = []
	for p in polygons:
		if Geometry2D.is_polygon_clockwise(p) == clockwise:
			solid.append(p)
	return solid

## Whether any edge of `hole` (within `box`, its grown bounds) crosses or
## touches an edge of `ring`.
static func _ring_crosses(hole: PackedVector2Array, box: Rect2, ring: PackedVector2Array) -> bool:
	for i in ring.size():
		var r := ring[i]
		var t := ring[(i + 1) % ring.size()]
		if maxf(r.x, t.x) < box.position.x or minf(r.x, t.x) > box.end.x \
				or maxf(r.y, t.y) < box.position.y or minf(r.y, t.y) > box.end.y:
			continue
		for j in hole.size():
			if Geometry2D.segment_intersects_segment(hole[j], hole[(j + 1) % hole.size()], r, t) != null:
				return true
	return false

## Nearest vertex of `out` whose seam to p crosses no edge of `out` or of
## any hole (the nearest vertex outright when none is clear).
static func _visible_vertex(out: PackedVector2Array, p: Vector2, holes: Array) -> int:
	if out.size() > SORT_MAX_VERTICES:
		return _visible_vertex_lazy(out, p, holes)
	var order: Array = range(out.size())
	order.sort_custom(func(i: int, j: int) -> bool:
		return out[i].distance_squared_to(p) < out[j].distance_squared_to(p))
	for i in order:
		if _seam_clear(out[i], p, out, holes):
			return i
	return order[0] if not order.is_empty() else 0

## _visible_vertex for a big ring (a coastline of thousands of vertices):
## the nearest clear vertex is nearly always among the first few, so pick
## candidates one at a time instead of sorting them all with a callback.
## Gives up after LAZY_TRIES and takes the nearest vertex outright.
static func _visible_vertex_lazy(out: PackedVector2Array, p: Vector2, holes: Array) -> int:
	var dist := PackedFloat64Array()
	dist.resize(out.size())
	for i in out.size():
		dist[i] = out[i].distance_squared_to(p)
	var nearest := -1
	for _try in LAZY_TRIES:
		var best := -1
		var best_d := INF
		for i in dist.size():
			if dist[i] < best_d:
				best_d = dist[i]
				best = i
		if best < 0:
			break
		if nearest < 0:
			nearest = best
		if _seam_clear(out[best], p, out, holes):
			return best
		dist[best] = INF
	return maxi(nearest, 0)

static func _seam_clear(a: Vector2, b: Vector2, out: PackedVector2Array, holes: Array) -> bool:
	var rings: Array = [out]
	rings.append_array(holes)
	# An edge wholly outside the seam's box cannot cross it: most of a
	# coastline's thousands of edges are skipped on four comparisons.
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(0.001, 0.001)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(0.001, 0.001)
	for r in rings:
		var ring := r as PackedVector2Array
		for j in ring.size():
			var c := ring[j]
			var d := ring[(j + 1) % ring.size()]
			if (c.x < lo.x and d.x < lo.x) or (c.x > hi.x and d.x > hi.x) \
					or (c.y < lo.y and d.y < lo.y) or (c.y > hi.y and d.y > hi.y):
				continue
			# Edges sharing a seam end touch it there by construction.
			if c.is_equal_approx(a) or d.is_equal_approx(a) \
					or c.is_equal_approx(b) or d.is_equal_approx(b):
				continue
			if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
				return false
	return true

## Triangles of `idx` (indexing `ring`) whose centroid is outside every
## hole: a keyhole triangulation can still span a courtyard when a seam
## had no clear vertex.
static func drop_hole_triangles(ring: PackedVector2Array, idx: PackedInt32Array,
		holes: Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	for t in idx.size() / 3:
		var c := (ring[idx[t * 3]] + ring[idx[t * 3 + 1]] + ring[idx[t * 3 + 2]]) / 3.0
		var in_hole := false
		for h in holes:
			if (h as PackedVector2Array).size() >= 3 and point_in_ring(c, h):
				in_hole = true
				break
		if not in_hole:
			out.append_array([idx[t * 3], idx[t * 3 + 1], idx[t * 3 + 2]])
	return out
