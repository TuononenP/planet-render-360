class_name RoadPits
extends RefCounted

## Keeps road and footway ribbons out of ground pits (GroundPits shape:
## {c, f, hw, hl}): a ribbon draped over a subway stairwell would cover
## the hole the ground shader cuts. Ribbons near a pit are resampled
## finely, then any ribbon quad touching the pit rectangle is dropped, so
## the footway simply stops at the opening and resumes past it.

const FINE_STEP_M := 0.25
## Pit rectangle inflation: a hair past the coping so no sliver remains.
const MARGIN_M := 0.1

static func _local(p: Vector2, pit: Dictionary) -> Vector2:
	var f: Vector2 = pit["f"]
	var d := p - (pit["c"] as Vector2)
	return Vector2(d.dot(Vector2(-f.y, f.x)), d.dot(f))

## True when the segment a-b passes within `reach` of any pit.
static func _near(a: Vector2, b: Vector2, pits: Array, reach: float) -> bool:
	for pit in pits:
		var r := float(pit["hw"]) + float(pit["hl"]) + reach
		var c: Vector2 = pit["c"]
		var q := Geometry2D.get_closest_point_to_segment(c, a, b)
		if q.distance_to(c) <= r:
			return true
	return false

## `pts` with segments near a pit split to FINE_STEP_M (others untouched).
static func densify(pts: PackedVector2Array, pits: Array, half_width: float) -> PackedVector2Array:
	if pits.is_empty() or pts.size() < 2:
		return pts
	var out := PackedVector2Array([pts[0]])
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		if _near(a, b, pits, half_width + 1.0):
			var n := maxi(1, ceili(a.distance_to(b) / FINE_STEP_M))
			for k in range(1, n + 1):
				out.append(a.lerp(b, float(k) / float(n)))
		else:
			out.append(b)
	return out

## True when the ribbon quad (la, ra at one point; lb, rb at the next)
## overlaps any pit rectangle (conservative: the quad's box in the pit's
## frame against the inflated rectangle).
static func blocked(la: Vector2, ra: Vector2, lb: Vector2, rb: Vector2, pits: Array) -> bool:
	for pit in pits:
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for p in [la, ra, lb, rb]:
			var q := _local(p, pit)
			lo = lo.min(q)
			hi = hi.max(q)
		var hw := float(pit["hw"]) + MARGIN_M
		var hl := float(pit["hl"]) + MARGIN_M
		if hi.x >= -hw and lo.x <= hw and hi.y >= -hl and lo.y <= hl:
			return true
	return false
