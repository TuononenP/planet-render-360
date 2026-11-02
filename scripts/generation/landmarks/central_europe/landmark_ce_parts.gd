class_name LandmarkCeParts
extends RefCounted

## Small shared parts for the central Europe landmark batch, in true
## metres on LandmarkMesh: onion domes, window rows, colonnades and
## battlement teeth. Each takes the material KEY to draw with.

## Onion dome of base radius r and total height h (closed at the tip).
static func onion(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 16, smooth: bool = true) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 0.55, 0), Vector2(r * 0.85, h * 0.07),
		Vector2(r, h * 0.24), Vector2(r * 0.92, h * 0.42), Vector2(r * 0.58, h * 0.62),
		Vector2(r * 0.22, h * 0.82), Vector2(0.0, h)]), seg, 1.0, 1.0, 0.0, smooth)

## Thin upright cross of total height h standing on `base`.
static func cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.beam(key, base, base + Vector3(0, h, 0), h * 0.07, h * 0.07)
	lm.beam(key, base + Vector3(-h * 0.22, h * 0.68, 0), base + Vector3(h * 0.22, h * 0.68, 0),
		h * 0.06, h * 0.06)

## `count` flat window boxes in a row along `along` (unit), centred on
## `origin`; `basis` turns each box to face outwards.
static func windows(lm: LandmarkMesh, key: String, origin: Vector3, along: Vector3, count: int,
		step: float, size: Vector3, basis: Basis = Basis()) -> void:
	for i in count:
		lm.box(key, origin + along * step * (float(i) - float(count - 1) * 0.5), size, basis)

## `count` round columns in a row along `along` from `origin`, r0 at the
## foot to r1 at the top, h tall.
static func colonnade(lm: LandmarkMesh, key: String, origin: Vector3, along: Vector3, count: int,
		step: float, r0: float, r1: float, h: float, seg: int = 12) -> void:
	for i in count:
		lm.frustum(key, origin + along * step * (float(i) - float(count - 1) * 0.5), r0, r1, h, seg)

## Battlement teeth along a straight wall top from `a` to `b` (both at
## the wall-top height): one tooth every `step`, w wide, h tall, d deep.
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, step: float,
		w: float, h: float, d: float) -> void:
	var n := maxi(int(a.distance_to(b) / step), 1)
	var dir := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	for i in n + 1:
		lm.box(key, a.lerp(b, float(i) / n) + Vector3(0, h * 0.5, 0), Vector3(w, h, d), basis)

## Eight-sided (or n-sided) pointed tent / spire of base radius r.
static func tent(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		sides: int = 8, top_r: float = 0.0) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r, 0), Vector2(top_r, h)]), sides,
		1.0, 1.0, PI / float(sides), false)

## Hipped roof over a w (X) by l (Z) rectangle centred at `c` (eave
## level), `rise` high with all four faces sloped; ridge along the
## longer side.
static func hip(lm: LandmarkMesh, key: String, c: Vector3, w: float, l: float, rise: float) -> void:
	var swap := w > l
	var u := (l if swap else w) * 0.5
	var v := (w if swap else l) * 0.5
	var r := v - u
	var up := Vector3(0, rise, 0)
	var a := _uv(c, -u, -v, swap)
	var b := _uv(c, u, -v, swap)
	var cc := _uv(c, u, v, swap)
	var d := _uv(c, -u, v, swap)
	var r0 := _uv(c, 0.0, -r, swap) + up
	var r1 := _uv(c, 0.0, r, swap) + up
	var nu := _uv(Vector3.ZERO, rise, 0.0, swap) + Vector3(0, u, 0)
	var nv := _uv(Vector3.ZERO, 0.0, rise, swap) + Vector3(0, u, 0)
	var mu := _uv(Vector3.ZERO, -rise, 0.0, swap) + Vector3(0, u, 0)
	var mv := _uv(Vector3.ZERO, 0.0, -rise, swap) + Vector3(0, u, 0)
	lm.quad(key, b, cc, r1, r0, nu.normalized())
	lm.quad(key, d, a, r0, r1, mu.normalized())
	lm.tri(key, a, b, r0, mv.normalized(), mv.normalized(), mv.normalized(), Vector2(0, 0), Vector2(u * 2.0, 0), Vector2(u, -rise))
	lm.tri(key, cc, d, r1, nv.normalized(), nv.normalized(), nv.normalized(), Vector2(0, 0), Vector2(u * 2.0, 0), Vector2(u, -rise))

## (across, along) offsets to a world point; `swap` runs `along` on X.
static func _uv(c: Vector3, u: float, v: float, swap: bool) -> Vector3:
	return c + (Vector3(v, 0, u) if swap else Vector3(u, 0, v))

## Round dome of base radius r rising h (quarter-ellipse profile), closed.
static func dome(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 20) -> void:
	var p := PackedVector2Array()
	for i in 9:
		var a := PI * 0.5 * float(i) / 8.0
		p.append(Vector2(r * cos(a), h * sin(a)))
	lm.lathe(key, base, p, seg)
