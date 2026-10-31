class_name RingGeometry
extends RefCounted

## Dependency-free 2D ring helpers (footprints and roof outlines in XZ)
## shared by BuildingBuilder and BuildingDetail. A leaf class on purpose:
## it names no other project class, so neither builder can end up in a
## class-load cycle through it (the load-order-dependent failure noted in
## the plan's 2026-10-28 render-check row).

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
static func bridge_holes(outer: PackedVector2Array, holes: Array) -> PackedVector2Array:
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
		var seam := PackedVector2Array()
		for k in hole.size() + 1:
			seam.append(hole[(hi + k) % hole.size()])
		seam.append(out[oi])
		var joined := out.slice(0, oi + 1)
		joined.append_array(seam)
		joined.append_array(out.slice(oi + 1))
		out = joined
	return out

## Nearest vertex of `out` whose seam to p crosses no edge of `out` or of
## any hole (the nearest vertex outright when none is clear).
static func _visible_vertex(out: PackedVector2Array, p: Vector2, holes: Array) -> int:
	var order: Array = range(out.size())
	order.sort_custom(func(i: int, j: int) -> bool:
		return out[i].distance_squared_to(p) < out[j].distance_squared_to(p))
	for i in order:
		if _seam_clear(out[i], p, out, holes):
			return i
	return order[0] if not order.is_empty() else 0

static func _seam_clear(a: Vector2, b: Vector2, out: PackedVector2Array, holes: Array) -> bool:
	var rings: Array = [out]
	rings.append_array(holes)
	for r in rings:
		var ring := r as PackedVector2Array
		for j in ring.size():
			var c := ring[j]
			var d := ring[(j + 1) % ring.size()]
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
