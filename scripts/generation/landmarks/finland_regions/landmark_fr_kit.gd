class_name LandmarkFrKit
extends RefCounted

## Shared parts of the finland_regions batch, in true metres on
## LandmarkMesh: boxes by bounds, gabled and hipped roofs over a
## rectangle, square towers with pyramid caps, window rows, crosses and
## the Nordic palette (grey granite, whitewash, red brick, tarred and
## ochre timber, copper, shingle). Models are built in the frame of the
## real plan: +X east, +Z south, turned onto the map by the entry's yaw_deg.

## Opens the standard keys (Stone, Wall, Roof, Glass, Trim) with the
## given hex colours; callers add their own extras with lm.use.
static func palette(lm: LandmarkMesh, stone: String, wall: String, roof: String,
		trim: String = "#E7E2D5") -> void:
	lm.use("Stone", LandmarkMaterials.pbr("stone", stone, 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", wall, 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", roof, 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", trim, 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))

static func copper(hex: String = "#6F9A86") -> StandardMaterial3D:
	return LandmarkMaterials.pbr("concrete", hex, 2.0, 0.55, 0.3)

static func shingle(hex: String = "#4C4137") -> StandardMaterial3D:
	return LandmarkMaterials.pbr("wood", hex, 1.5)

## Box from bounds (x0..x1, y0..y1, z0..z1).
static func rect(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float,
		y0: float, y1: float) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)))

## Gabled roof over the rectangle, eaves at y, ridge along the longer
## side (or along X when ridge_x is 1, along Z when 0); the gable ends
## are closed with `gable_key` when set.
static func gable(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float,
		y: float, rise: float, over: float = 0.5, gable_key: String = "", ridge_x: int = -1) -> void:
	var w := x1 - x0
	var d := z1 - z0
	var along_x := (ridge_x == 1) if ridge_x >= 0 else (w >= d)
	var c := Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5)
	if along_x:
		lm.gable(key, c, d, w, rise, Basis(Vector3.UP, PI * 0.5), over, gable_key)
	else:
		lm.gable(key, c, w, d, rise, Basis(), over, gable_key)

## Box walls from y0 to the eaves with a gabled roof on top.
static func house(lm: LandmarkMesh, wall: String, roof: String, x0: float, x1: float, z0: float,
		z1: float, y0: float, eave: float, rise: float, over: float = 0.5, ridge_x: int = -1) -> void:
	rect(lm, wall, x0, x1, z0, z1, y0, eave)
	gable(lm, roof, x0, x1, z0, z1, eave, rise, over, wall, ridge_x)

## Hipped roof over the rectangle (square = pyramid); ridge along the
## longer side.
static func hip(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float,
		y: float, rise: float, over: float = 0.4) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var hw := (x1 - x0) * 0.5 + over
	var hd := (z1 - z0) * 0.5 + over
	var r := absf(hw - hd)
	var up := Vector3(0, rise, 0)
	var a := Vector3(cx - hw, y, cz - hd)
	var b := Vector3(cx + hw, y, cz - hd)
	var c := Vector3(cx + hw, y, cz + hd)
	var d := Vector3(cx - hw, y, cz + hd)
	var r0 := Vector3(cx, y, cz) + up
	var r1 := r0
	if hw >= hd:
		r0 += Vector3(-r, 0, 0)
		r1 += Vector3(r, 0, 0)
		face(lm, key, [a, b, r1, r0])
		face(lm, key, [b, c, r1])
		face(lm, key, [c, d, r0, r1])
		face(lm, key, [d, a, r0])
	else:
		r0 += Vector3(0, 0, -r)
		r1 += Vector3(0, 0, r)
		face(lm, key, [a, b, r0])
		face(lm, key, [b, c, r1, r0])
		face(lm, key, [c, d, r1])
		face(lm, key, [d, a, r0, r1])

## One planar roof face (3 or 4 corners) with an upward normal.
static func face(lm: LandmarkMesh, key: String, p: Array) -> void:
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var c: Vector3 = p[2]
	var n := (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		n = -n
	if p.size() == 4:
		lm.quad(key, a, b, c, p[3] as Vector3, n)
	else:
		lm.tri(key, a, b, c, n, n, n, Vector2(0, 0), Vector2(a.distance_to(b), 0),
			Vector2(a.distance_to(b) * 0.5, -a.distance_to(c)))

## Square tower: walls from y0 to y1 and a pyramid cap rising `cap`.
static func tower(lm: LandmarkMesh, wall: String, roof: String, cx: float, cz: float, hw: float,
		y0: float, y1: float, cap: float, over: float = 0.4) -> void:
	lm.box(wall, Vector3(cx, (y0 + y1) * 0.5, cz), Vector3(hw * 2.0, y1 - y0, hw * 2.0))
	if cap > 0.0:
		lm.spire(roof, Vector3(cx, y1, cz), hw + over, cap)

## Thin upright cross of total height h standing on `base`.
static func cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.beam(key, base, base + Vector3(0, h, 0), h * 0.08, h * 0.08)
	lm.beam(key, base + Vector3(-h * 0.22, h * 0.68, 0), base + Vector3(h * 0.22, h * 0.68, 0),
		h * 0.07, h * 0.07)

## Window panes in a row along `along` (unit), centred on `origin`.
static func windows(lm: LandmarkMesh, key: String, origin: Vector3, along: Vector3, count: int,
		step: float, size: Vector3, basis: Basis = Basis()) -> void:
	for i in count:
		lm.box(key, origin + along * step * (float(i) - float(count - 1) * 0.5), size, basis)

## Windows on the four faces of an upright box centred at (cx, y, cz),
## `half` its half-width, one row of `count` panes per face.
static func ring_windows(lm: LandmarkMesh, key: String, cx: float, cz: float, half: float,
		y: float, count: int, step: float, size: Vector3) -> void:
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		windows(lm, key, Vector3(cx, y, cz) + r * Vector3(0, 0, half + 0.05), r * Vector3.RIGHT, count,
			step, size, r)

## Clock faces on the four sides of a tower stage at height y.
static func clocks(lm: LandmarkMesh, face: String, hands: String, cx: float, cz: float,
		half: float, y: float, r: float) -> void:
	for f in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = rot * Vector3(0, 0, 1)
		var c := Vector3(cx, y, cz) + out * (half + 0.06)
		lm.disc(face, c, out, r, 20)
		lm.disc(hands, c + out * 0.05, out, r * 0.78, 20)

## Battlement teeth along a wall top from a to b (both at the top).
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, step: float,
		w: float, h: float, d: float) -> void:
	var n := maxi(int(a.distance_to(b) / step), 1)
	var dir := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	for i in n + 1:
		lm.box(key, a.lerp(b, float(i) / n) + Vector3(0, h * 0.5, 0), Vector3(w, h, d), basis)

## Closed ring of wall segments over an XZ polygon with a crenellated top.
static func curtain(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float, h: float,
		t: float, tooth: String = "") -> void:
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var a := Vector3(p.x, y + h * 0.5, p.y)
		var b := Vector3(q.x, y + h * 0.5, q.y)
		lm.beam(key, a, b, h, t, Vector3.UP)
		if tooth != "":
			merlons(lm, tooth, Vector3(p.x, y + h, p.y), Vector3(q.x, y + h, q.y), 3.0, 1.3, 1.1, t * 0.5)

## Round tower: shaft from y0 to y1 and a conical cap rising `cap`.
static func round_tower(lm: LandmarkMesh, wall: String, roof: String, cx: float, cz: float, r: float,
		y0: float, y1: float, cap: float, seg: int = 16) -> void:
	lm.frustum(wall, Vector3(cx, y0, cz), r, r * 0.96, y1 - y0, seg)
	if cap > 0.0:
		lm.lathe(roof, Vector3(cx, y1, cz), PackedVector2Array([Vector2(r * 1.12, 0), Vector2(0.0, cap)]), seg)

## Slim octagonal lantern with a pointed cap (steeple top).
static func lantern(lm: LandmarkMesh, wall: String, roof: String, cx: float, cz: float, r: float,
		y: float, h: float, cap: float) -> void:
	lm.frustum(wall, Vector3(cx, y, cz), r, r * 0.92, h, 8, PI / 8.0)
	lm.lathe(roof, Vector3(cx, y + h, cz), PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r * 0.7, cap * 0.18),
		Vector2(r * 0.3, cap * 0.6), Vector2(0.12, cap)]), 8, 1.0, 1.0, PI / 8.0, false)

static func ball(r: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 7:
		var t := PI * float(k) / 6.0
		pr.append(Vector2(sin(t) * r, r - cos(t) * r))
	return pr

static func dome(r: float, h: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 9:
		var t := PI * 0.5 * float(k) / 8.0
		pr.append(Vector2(cos(t) * r, sin(t) * h))
	pr[pr.size() - 1] = Vector2(0.0, h)
	return pr
