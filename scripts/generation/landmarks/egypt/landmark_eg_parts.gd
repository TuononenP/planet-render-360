class_name LandmarkEgParts
extends RefCounted

## Shared pieces of the Egypt batch in true metres on LandmarkMesh:
## battered towers and pylons, columns, obelisks, seated colossi and the
## stripped-course square pyramid. Temples build with the entrance toward
## +Z and the sanctuary toward -Z (the registry yaw_deg turns the model
## onto the real axis); y = 0 is the courtyard floor.

const OPEN := 0  # open papyrus (campaniform) capital
const BUD := 1  # closed papyrus bud capital
const PLAIN := 2  # fluted proto-Doric shaft

## Battered block: base-centre `c`, full widths (x, z) at the foot and at
## the top, `h` high; the underside stays open.
static func taper(lm: LandmarkMesh, key: String, c: Vector3, w0: float, d0: float,
		w1: float, d1: float, h: float, cap: bool = true) -> void:
	var lo: Array[Vector3] = []
	var hi: Array[Vector3] = []
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		lo.append(c + Vector3(s.x * w0, 0.0, s.y * d0) * 0.5)
		hi.append(c + Vector3(s.x * w1 * 0.5, h, s.y * d1 * 0.5))
	var mid := c + Vector3(0, h * 0.5, 0)
	for i in 4:
		var j := (i + 1) % 4
		var n := (lo[j] - lo[i]).cross(hi[i] - lo[i]).normalized()
		if n.dot((lo[i] + lo[j] + hi[i] + hi[j]) * 0.25 - mid) < 0.0:
			n = -n
		lm.quad(key, lo[i], lo[j], hi[j], hi[i], n)
	if cap:
		lm.quad(key, hi[0], hi[1], hi[2], hi[3], Vector3.UP)

## Pylon facing +Z centred on `c`: two battered towers (`w` wide in all,
## `d` thick, `h` high) round a `gate`-wide opening bridged by a lintel
## and cornice, a cavetto cornice on each tower and recessed flagstaff
## slots (`dark`) in the front face.
static func pylon(lm: LandmarkMesh, key: String, dark: String, c: Vector3, w: float,
		h: float, d: float, gate: float) -> void:
	var tw := (w - gate) * 0.5
	var body := h * 0.93
	var lean := body / 11.0
	var top_w := tw - lean
	var top_d := d * 0.93
	for s in [-1.0, 1.0]:
		var cx: float = c.x + s * (gate + tw) * 0.5
		var foot := Vector3(cx, c.y, c.z)
		taper(lm, key, foot, tw, d, top_w, top_d, body, false)
		taper(lm, key, foot + Vector3(0, body, 0), top_w, top_d, top_w + h * 0.06,
			top_d + h * 0.06, h - body)
		for k in [-0.26, 0.26]:
			lm.box(dark, Vector3(cx + k * tw, c.y + body * 0.5, c.z + d * 0.5 - (d - top_d) * 0.25),
				Vector3(maxf(tw * 0.04, 0.5), body * 0.62, 0.5))
	var gate_h := h * 0.46
	lm.box(key, c + Vector3(0, gate_h + h * 0.05, 0), Vector3(gate + 1.0, h * 0.1, d * 0.92))
	taper(lm, key, c + Vector3(0, gate_h + h * 0.1, 0), gate + 1.0, d * 0.92, gate + 2.6,
		d * 0.92 + 1.6, h * 0.04)

## Column of height h (base to capital top) and shaft radius r.
static func column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		kind: int = BUD, seg: int = 8) -> void:
	var prof: PackedVector2Array
	if kind == OPEN:
		prof = PackedVector2Array([Vector2(r * 1.2, 0), Vector2(r * 0.85, h * 0.05),
			Vector2(r, h * 0.45), Vector2(r * 0.8, h * 0.78), Vector2(r * 1.3, h * 0.88),
			Vector2(r * 1.75, h * 0.97), Vector2(r * 1.75, h)])
	elif kind == BUD:
		prof = PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r * 0.88, h * 0.06),
			Vector2(r, h * 0.5), Vector2(r * 0.82, h * 0.8), Vector2(r * 1.2, h * 0.9),
			Vector2(r * 0.85, h)])
	else:
		prof = PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r, h * 0.05),
			Vector2(r * 0.88, h * 0.94), Vector2(r * 1.1, h * 0.94), Vector2(r * 1.1, h)])
	lm.lathe(key, base, prof, seg)

## Row of `n` columns from `a` to `b` (base positions), spaced evenly.
static func colonnade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, r: float,
		h: float, kind: int = BUD, seg: int = 8) -> void:
	for i in n:
		column(lm, key, a.lerp(b, float(i) / maxf(n - 1, 1)), r, h, kind, seg)

## Obelisk of height h (plinth, battered shaft and pyramidion) on `base`.
static func obelisk(lm: LandmarkMesh, key: String, tip: String, base: Vector3, w: float,
		h: float) -> void:
	var tip_h := w * 0.95
	var plinth := w * 0.35
	lm.box(key, base + Vector3(0, plinth * 0.5, 0), Vector3(w * 1.8, plinth, w * 1.8))
	taper(lm, key, base + Vector3(0, plinth, 0), w, w, w * 0.62, w * 0.62, h - tip_h - plinth, false)
	lm.spire(tip, base + Vector3(0, h - tip_h, 0), w * 0.31, tip_h, 0.0, 4)

## Seated king facing +Z: throne block, two thighs and shins, torso,
## nemes head and (when `crown`) the tall crown, `h` tall in all.
static func colossus(lm: LandmarkMesh, key: String, c: Vector3, h: float,
		crown: bool = true) -> void:
	var w := h * 0.42
	lm.box(key, c + Vector3(0, h * 0.2, -h * 0.07), Vector3(w, h * 0.4, h * 0.62))
	lm.box(key, c + Vector3(0, h * 0.5, -h * 0.28), Vector3(w * 0.92, h * 0.6, h * 0.14))
	for s in [-1.0, 1.0]:
		lm.box(key, c + Vector3(s * w * 0.25, h * 0.2, h * 0.27), Vector3(w * 0.36, h * 0.4, h * 0.14))
		lm.box(key, c + Vector3(s * w * 0.25, h * 0.43, h * 0.16), Vector3(w * 0.36, h * 0.1, h * 0.34))
		lm.box(key, c + Vector3(s * w * 0.46, h * 0.56, -h * 0.04), Vector3(w * 0.14, h * 0.3, h * 0.12))
		lm.box(key, c + Vector3(s * w * 0.21, h * 0.78, -h * 0.02), Vector3(w * 0.1, h * 0.18, h * 0.07))
	taper(lm, key, c + Vector3(0, h * 0.4, -h * 0.08), w * 0.84, h * 0.2, w * 0.72, h * 0.16, h * 0.34)
	taper(lm, key, c + Vector3(0, h * 0.74, -h * 0.08), w * 0.3, h * 0.17, w * 0.28, h * 0.15, h * 0.1)
	taper(lm, key, c + Vector3(0, h * 0.82, -h * 0.08), w * 0.46, h * 0.2, w * 0.36, h * 0.17, h * 0.1)
	if crown:
		taper(lm, key, c + Vector3(0, h * 0.92, -h * 0.08), w * 0.3, h * 0.12, w * 0.2, h * 0.09, h * 0.08)

## Dome of radius r and height h (quarter ellipse) standing on `base`.
static func dome(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 12) -> void:
	var prof := PackedVector2Array()
	for i in 6:
		var a := PI * 0.5 * float(i) / 5.0
		prof.append(Vector2(r * cos(a), h * sin(a)))
	lm.lathe(key, base, prof, seg)

## Stripped courses of a square pyramid (half-base `hb`, true apex
## height `apex`) between y0 and y1, one ledge every `step` m, centred
## on `c`; `cap` closes a flat top.
static func courses(lm: LandmarkMesh, key: String, c: Vector3, hb: float, apex: float,
		y0: float, y1: float, step: float, cap: bool = false) -> void:
	var k := sqrt(2.0)
	var n := maxi(1, int(round((y1 - y0) / step)))
	var prof := PackedVector2Array()
	for s in n:
		var ya := lerpf(y0, y1, float(s) / n)
		var yb := lerpf(y0, y1, float(s + 1) / n)
		var ra := hb * (1.0 - ya / apex) * k
		var rb := hb * (1.0 - yb / apex) * k
		prof.append(Vector2(ra, ya))
		prof.append(Vector2(ra - minf(0.3 * k, (ra - rb) * 0.6), yb))
	prof.append(Vector2(hb * (1.0 - y1 / apex) * k, y1))
	lm.lathe(key, c, prof, 4, 1.0, 1.0, PI * 0.25, false, cap)

## Smooth-faced stretch of the same pyramid between y0 and y1.
static func smooth(lm: LandmarkMesh, key: String, c: Vector3, hb: float, apex: float,
		y0: float, y1: float, cap: bool = false) -> void:
	var k := sqrt(2.0)
	lm.lathe(key, c + Vector3(0, y0, 0), PackedVector2Array([
		Vector2(hb * (1.0 - y0 / apex) * k, 0), Vector2(hb * (1.0 - y1 / apex) * k, y1 - y0)]),
		4, 1.0, 1.0, PI * 0.25, false, cap)

## Straight wall of height h and thickness t between two XZ points.
static func wall(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, h: float, t: float,
		y0: float = 0.0) -> void:
	lm.beam(key, Vector3(a.x, y0 + h * 0.5, a.y), Vector3(b.x, y0 + h * 0.5, b.y), h, t,
		Vector3.UP, true)
