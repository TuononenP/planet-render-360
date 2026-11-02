class_name LandmarkAmhParts
extends RefCounted

## Small pieces shared by the Americas historic landmark builders, in
## true metres on LandmarkMesh: sloped rectangular tiers, stepped
## stairways with their side balustrades, and rings of columns.

## Rectangular tier from half-extents (hx0, hz0) at the base to
## (hx1, hz1) at height `h`, its base centre at `c`. The top is closed
## when `cap` is set; the underside never is.
static func slab(lm: LandmarkMesh, key: String, c: Vector3, h: float, hx0: float, hz0: float,
		hx1: float, hz1: float, cap: bool = true) -> void:
	var b: Array[Vector3] = []
	var t: Array[Vector3] = []
	for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var v: Vector2 = q
		b.append(c + Vector3(v.x * hx0, 0, v.y * hz0))
		t.append(c + Vector3(v.x * hx1, h, v.y * hz1))
	for i in 4:
		var j := (i + 1) % 4
		var out := (b[i] + b[j]) * 0.5 - c
		var n := (b[j] - b[i]).cross(t[i] - b[i]).normalized()
		if n.dot(Vector3(out.x, 0.0, out.z)) < 0.0:
			n = -n
		lm.quad(key, b[i], b[j], t[j], t[i], n)
	if cap:
		lm.quad(key, t[0], t[1], t[2], t[3], Vector3.UP)

## Flight of `n` treads, `w` wide, centred on local x = 0 and rising
## toward local -Z from (z0, y0) at the foot to (z1, y1) at the head;
## the blocks run back to `z_back`. `o` and `r` place the local frame
## (r turns local +Z onto the outward direction of the face).
static func stair(lm: LandmarkMesh, key: String, o: Vector3, r: Basis, w: float, z0: float,
		y0: float, z1: float, y1: float, z_back: float, n: int) -> void:
	var rise := (y1 - y0) / float(n)
	for i in n:
		var top := y0 + rise * float(i + 1)
		var zf := lerpf(z0, z1, float(i) / float(n))
		lm.box(key, o + r * Vector3(0, top - rise * 0.5, (zf + z_back) * 0.5),
			Vector3(w, rise, zf - z_back), r)

## Flight of `n` treads that follows a stepped outer profile (radius,
## y) rising from y0 to y1, each tread `off` proud of the surface, so
## the stair lands on every ledge; `rail_w` > 0 adds a parapet along
## both sides in `rail_key`. Local frame as for stair().
static func stair_hug(lm: LandmarkMesh, key: String, o: Vector3, r: Basis, w: float,
		outer: PackedVector2Array, y0: float, y1: float, n: int, z_back: float,
		off: float = 0.4, rail_w: float = 0.0, rail_key: String = "") -> void:
	var rise := (y1 - y0) / float(n)
	for i in n:
		var ym := y0 + rise * (float(i) + 0.5)
		var zf := _outer_at(outer, ym) + off
		var depth := zf - z_back
		lm.box(key, o + r * Vector3(0, ym, (zf + z_back) * 0.5), Vector3(w, rise, depth), r)
		if rail_w > 0.0:
			for s in [-1.0, 1.0]:
				lm.box(rail_key, o + r * Vector3(s * (w + rail_w) * 0.5, ym + 0.35,
					(zf + z_back) * 0.5), Vector3(rail_w, rise + 0.7, depth), r)

## Radius of a stepped profile at height y (flat ledges are skipped).
static func _outer_at(outer: PackedVector2Array, y: float) -> float:
	for j in outer.size() - 1:
		var a := outer[j]
		var b := outer[j + 1]
		if b.y > a.y + 0.01 and y >= a.y and y <= b.y:
			return lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
	return outer[outer.size() - 1].x

## The two sloping side walls of a stair (alfardas): beams `bw` wide
## and `bd` deep along the flight, at x = +-(w / 2 + bw / 2).
static func rails(lm: LandmarkMesh, key: String, o: Vector3, r: Basis, w: float, z0: float,
		y0: float, z1: float, y1: float, bw: float, bd: float) -> void:
	for s in [-1.0, 1.0]:
		var x: float = s * (w * 0.5 + bw * 0.5)
		lm.beam(key, o + r * Vector3(x, y0 + bd * 0.5, z0), o + r * Vector3(x, y1 - bd * 0.5, z1),
			bw, bd, r * Vector3.RIGHT)

## Ring of `n` tapered columns of radius r0 -> r1 and height `h`
## around `c` at ring radius `ring_r`, starting at angle `a0`.
static func column_ring(lm: LandmarkMesh, key: String, c: Vector3, ring_r: float, n: int,
		r0: float, r1: float, h: float, a0: float = 0.0, seg: int = 12) -> void:
	for k in n:
		var a := a0 + TAU * float(k) / float(n)
		lm.frustum(key, c + Vector3(cos(a) * ring_r, 0, sin(a) * ring_r), r0, r1, h, seg)

## Dark rectangular opening (door or window) on a wall: centre `c`,
## local +Z turned onto the wall normal by `r`.
static func opening(lm: LandmarkMesh, key: String, c: Vector3, r: Basis, w: float, h: float,
		depth: float = 0.3) -> void:
	lm.box(key, c, Vector3(w, h, depth), r)
