extends RefCounted

## Small shared helpers for the Suomenlinna and island landmarks
## (Valkosaari, Klippan, Lonna, Uunisaari, Kustaanmiekka): a hipped roof
## with a flat ridge, round turrets with a cap and spire, framed window
## rows with a pale surround, and a rock ledge for an islet.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

## Hipped roof over a w (X) by d (Z) rectangle centred (cx, cz), eaves at
## y0, `rise` high, ridge `rl` long along X (w - d gives a true hip), with
## `over` overhang.
static func hip(lm: LandmarkMesh, key: String, cx: float, cz: float, y0: float, w: float, d: float,
		rise: float, rl: float, over: float = 0.5) -> void:
	var hx := w * 0.5 + over
	var hz := d * 0.5 + over
	var r := rl * 0.5
	var y1 := y0 + rise
	var a := Vector3(cx - hx, y0, cz + hz)
	var b := Vector3(cx + hx, y0, cz + hz)
	var c := Vector3(cx + hx, y0, cz - hz)
	var e := Vector3(cx - hx, y0, cz - hz)
	var rn := Vector3(cx - r, y1, cz)
	var rp := Vector3(cx + r, y1, cz)
	lm.quad(key, a, b, rp, rn, Vector3(0, hz, rise).normalized())
	lm.quad(key, c, e, rn, rp, Vector3(0, hz, -rise).normalized())
	lm.quad(key, b, c, rp, rp, Vector3(rise, hx - r, 0).normalized())
	lm.quad(key, e, a, rn, rn, Vector3(-rise, hx - r, 0).normalized())

## Round turret: drum from y0, h tall, radius r, a flared cap `cap_h`
## tall and a spire `spire_h` on it.
static func turret(lm: LandmarkMesh, wall: String, roof: String, cx: float, cz: float, y0: float,
		r: float, h: float, cap_h: float, spire_h: float, seg: int = 12) -> void:
	lm.frustum(wall, Vector3(cx, y0, cz), r, r, h, seg)
	lm.frustum("Trim", Vector3(cx, y0 + h, cz), r + 0.25, r + 0.25, 0.25, seg)
	var prof := PackedVector2Array([Vector2(r + 0.45, 0), Vector2(r * 0.95, cap_h * 0.18), Vector2(r * 0.6, cap_h * 0.55),
		Vector2(r * 0.3, cap_h * 0.82), Vector2(r * 0.12, cap_h)])
	lm.lathe(roof, Vector3(cx, y0 + h + 0.25, cz), prof, seg)
	lm.frustum(roof, Vector3(cx, y0 + h + 0.25 + cap_h, cz), r * 0.12, 0.02, spire_h, 6)

## A row of `n` framed windows (arched when `arched`) along the face at
## `out` (a unit horizontal vector) between ground points a and b.
static func row(lm: LandmarkMesh, glass: String, a: Vector3, b: Vector3, out: Vector3, y: float, n: int,
		w: float, h: float, arched: bool = false, frame: String = "Trim") -> void:
	FhP.win_row(lm, frame, glass, a, b, out, y + a.y, n, w, h, arched, 0.14)

## Rock ledge for an islet building: a low mound plus a shore ring of
## boulders (boxes turned about the vertical).
static func ledge(lm: LandmarkMesh, key: String, rx: float, rz: float, h: float, boulders: int = 18) -> void:
	var prof := PackedVector2Array([Vector2(1.0, -1.0), Vector2(0.98, 0.0), Vector2(0.86, h * 0.5),
		Vector2(0.55, h * 0.9), Vector2(0.3, h)])
	lm.lathe(key, Vector3.ZERO, prof, 24, rx, rz)
	lm.lathe(key, Vector3(0, h - 0.02, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.0, 0.02)]), 24, rx, rz)
	for i in boulders:
		var a := TAU * float(i) / float(boulders) + float(i % 3) * 0.1
		var s := 0.9 + float(i % 4) * 0.35
		lm.box(key, Vector3(cos(a) * rx * 0.98, 0.25, sin(a) * rz * 0.98), Vector3(s * 1.4, 0.7, s), Basis(Vector3.UP, a * 2.0))

## Gabled house w (X) by d (Z) centred (cx, cz) on ground y0: plinth, walls
## `h` tall, ridge along X rising `rise`, `cols` x `rows` windows on both
## long faces (framed, sized ww x wh) and 1 on each gable end.
static func house(lm: LandmarkMesh, wall: String, roof: String, cx: float, cz: float, y0: float, w: float,
		d: float, h: float, rise: float, cols: int, rows: int, ww: float = 1.2, wh: float = 1.9,
		sill: float = 1.0, over: float = 0.45) -> void:
	U.blk(lm, "Granite", cx, y0, cz, w + 0.3, 0.5, d + 0.3)
	U.blk(lm, wall, cx, y0 + 0.5, cz, w, h - 0.5, d)
	U.ridge_x(lm, roof, wall, Vector3(cx, y0 + h, cz), w + 0.4, d + 2.0 * over, rise, 0.0)
	var pitch := (h - sill - 0.6) / maxf(float(rows), 1.0)
	for s in [-1.0, 1.0]:
		for r in rows:
			row(lm, "Window", Vector3(cx - w * 0.5 + 1.4, y0, cz + s * d * 0.5), Vector3(cx + w * 0.5 - 1.4, y0, cz + s * d * 0.5),
				Vector3(0, 0, s), sill + float(r) * pitch, cols, ww, wh)
		row(lm, "Window", Vector3(cx + s * w * 0.5, y0, cz), Vector3(cx + s * w * 0.5, y0, cz), Vector3(s, 0, 0),
			sill, 1, ww, wh)
