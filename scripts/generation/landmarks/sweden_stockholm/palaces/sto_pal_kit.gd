extends RefCounted

## Small shared parts for the Stockholm palace models of plan S-1 (Opera,
## Grand Hôtel, Nationalmuseum), in true metres on LandmarkMesh: ranged
## boxes, evenly spaced window rows, stone courses, vase urns, statues,
## sloping awnings and flagpoles. Every part takes material KEYS the
## caller registered with lm.use.

## Axis box from corner ranges (x0..x1, y0..y1, z0..z1).
static func rb(lm: LandmarkMesh, key: String, x0: float, x1: float, y0: float, y1: float, z0: float,
		z1: float, bevel: float = -1.0) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(x1 - x0, y1 - y0, z1 - z0), Basis(), bevel)

## `n` offsets `pitch` apart, centred on zero.
static func evenly(n: int, pitch: float) -> Array:
	var out: Array = []
	for i in n:
		out.append((float(i) - float(n - 1) * 0.5) * pitch)
	return out

## Along-wall direction of a wall facing `out`, running to the viewer's
## right as seen from outside.
static func right(out: Vector3) -> Vector3:
	return Vector3.UP.cross(out).normalized()

## Framed windows (LandmarkDetail.window) at offsets `offs` along the wall
## from wall point `p`, their sills `y` up, on a wall facing `out`.
static func wins(lm: LandmarkMesh, frame: String, glass: String, p: Vector3, out: Vector3,
		offs: Array, y: float, w: float, h: float, arched: bool = false, depth: float = 0.25) -> void:
	var along := right(out)
	for t in offs:
		var c: Vector3 = p + along * float(t) + Vector3(0, y + h * 0.5, 0) + out * 0.02
		LandmarkDetail.window(lm, frame, glass, c, out, w, h, arched, depth)

## Flat dark openings (cheap: two triangles each) at offsets along a wall.
static func holes(lm: LandmarkMesh, key: String, p: Vector3, out: Vector3, offs: Array,
		y: float, w: float, h: float, round_top: bool = false) -> void:
	var along := right(out)
	for t in offs:
		LandmarkFhUtil.opening(lm, key, p + along * float(t) + Vector3(0, y, 0) + out * 0.06, out, w, h, round_top)

## Stone courses: thin projecting bands every `pitch` from y0 to y1 across a
## wall `len` long centred on `p`, facing `out`.
static func courses(lm: LandmarkMesh, key: String, p: Vector3, out: Vector3, len: float,
		y0: float, y1: float, pitch: float, band: float = 0.16, proj: float = 0.1) -> void:
	var along := right(out)
	var basis := Basis(along, Vector3.UP, out)
	var y := y0 + pitch
	while y < y1 - 0.05:
		lm.box(key, p + Vector3(0, y, 0) + out * proj * 0.5, Vector3(len, band, proj), basis, 0.0)
		y += pitch

## Vase urn of height h standing on `base`.
static func urn(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	var k := h / 1.5
	var prof := PackedVector2Array([Vector2(0.34, 0.0), Vector2(0.34, 0.18), Vector2(0.16, 0.34),
		Vector2(0.38, 0.68), Vector2(0.44, 0.98), Vector2(0.3, 1.2), Vector2(0.12, 1.32), Vector2(0.0, 1.4)])
	for i in prof.size():
		prof[i] *= k
	lm.lathe(key, base, prof, 8)

## Standing statue of height h on a small plinth.
static func figure(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.08, 0), Vector3(h * 0.34, h * 0.16, h * 0.34))
	lm.frustum(key, base + Vector3(0, h * 0.16, 0), h * 0.15, h * 0.1, h * 0.58, 8)
	lm.lathe(key, base + Vector3(0, h * 0.8, 0), LandmarkFhUtil.ball(h * 0.09), 8)

## Sloping awning: top edge at `top` (on the wall), `w` wide along `along`,
## reaching `reach` out and dropping `drop`; both faces and a front valance.
static func awning(lm: LandmarkMesh, key: String, top: Vector3, out: Vector3, w: float,
		reach: float, drop: float) -> void:
	var along := right(out)
	var a := top - along * w * 0.5
	var b := top + along * w * 0.5
	var da := out * reach - Vector3(0, drop, 0)
	var up_n := (out * drop + Vector3.UP * reach).normalized()
	lm.quad(key, a, b, b + da, a + da, up_n)
	lm.quad(key, a + da, b + da, b, a, -up_n)
	lm.quad(key, a + da, b + da, b + da - Vector3(0, 0.35, 0), a + da - Vector3(0, 0.35, 0), out)

## Flagpole from `base` up `h`, with a flag `fw` x `fh` flying toward `along`.
static func flag(lm: LandmarkMesh, pole: String, cloth: String, base: Vector3, h: float, along: Vector3,
		fw: float, fh: float) -> void:
	lm.beam(pole, base, base + Vector3(0, h, 0), 0.14, 0.14)
	var top := base + Vector3(0, h - 0.2, 0)
	var n := Vector3.UP.cross(along).normalized()
	lm.quad(cloth, top, top + along * fw, top + along * fw - Vector3(0, fh, 0), top - Vector3(0, fh, 0), n)
	lm.quad(cloth, top - Vector3(0, fh, 0), top + along * fw - Vector3(0, fh, 0), top + along * fw, top, -n)
