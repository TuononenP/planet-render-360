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
