extends RefCounted

## Facade parts for the Empire-style Helsinki fronts (Senate Square,
## Market Square, Aleksanterinkatu), in true metres on LandmarkMesh with
## front +Z: a framed window with sill, lintel, optional jambs, glazing
## bars and a pediment or round hood, evenly spaced window runs along a
## wall, and a hexastyle portico. Materials come from the caller's
## `lm.use`: a frame key and a glass key.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

## Window w x h standing on the wall face at `p` (bottom centre) facing
## `out`. kind: "plain" (sill and lintel), "rect" (plus jambs and glazing
## bars), "hood" (rect under a triangular pediment), "round" (rect under a
## round-arched lunette) or "arch" (round-headed, framed).
static func win(lm: LandmarkMesh, frame: String, glass: String, p: Vector3, out: Vector3, w: float, h: float,
		kind: String = "rect") -> void:
	var n := out.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var b := Basis(r, Vector3.UP, n)
	if kind == "arch":
		LandmarkDetail.window(lm, frame, glass, p + Vector3(0, h * 0.5, 0), n, w, h, true, 0.2)
		return
	var up := Vector3(0, h, 0)
	var g := p + n * 0.03
	lm.quad(glass, g - r * w * 0.5, g + r * w * 0.5, g + r * w * 0.5 + up, g - r * w * 0.5 + up, n)
	lm.box(frame, p + Vector3(0, h + 0.12, 0) + n * 0.1, Vector3(w + 0.5, 0.24, 0.2), b, 0.0)
	lm.box(frame, p + Vector3(0, -0.06, 0) + n * 0.12, Vector3(w + 0.36, 0.14, 0.26), b, 0.0)
	if kind == "plain":
		return
	for s in [-1.0, 1.0]:
		lm.box(frame, p + r * (s * (w * 0.5 + 0.09)) + Vector3(0, h * 0.5, 0) + n * 0.08,
			Vector3(0.18, h, 0.12), b, 0.0)
	lm.box(frame, p + Vector3(0, h * 0.5, 0) + n * 0.05, Vector3(0.05, h, 0.05), b, 0.0)
	lm.box(frame, p + Vector3(0, h * 0.64, 0) + n * 0.05, Vector3(w, 0.05, 0.05), b, 0.0)
	if kind == "hood":
		lm.gable(frame, p + Vector3(0, h + 0.24, 0) + n * 0.1, w + 0.9, 0.2, 0.5, b, 0.0, frame)
	elif kind == "round":
		LandmarkDetail.arch(lm, frame, p + Vector3(0, h + 0.24, 0), n, w + 0.1, 0.16, 0.2, 9)

## `n` windows along the wall run a..b (ground points) facing `out`, the
## first sill `y` up; `skip` holds the bay indices left blank.
static func row(lm: LandmarkMesh, frame: String, glass: String, a: Vector3, b: Vector3, out: Vector3,
		y: float, n: int, w: float, h: float, kind: String = "rect", skip: Array = []) -> void:
	for i in n:
		if skip.has(i):
			continue
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		win(lm, frame, glass, Vector3(p.x, y, p.z), out, w, h, kind)

## Window rows [y, w, h, kind] along the wall a..b (XZ points), one bay
## every `pitch` metres between `margin` metres of blank wall at each end.
static func run(lm: LandmarkMesh, frame: String, glass: String, a: Vector2, b: Vector2, out: Vector2,
		pitch: float, rows: Array, margin: float = 1.2) -> void:
	var d := (b - a).normalized()
	var a3 := Vector3(a.x + d.x * margin, 0, a.y + d.y * margin)
	var b3 := Vector3(b.x - d.x * margin, 0, b.y - d.y * margin)
	var n := maxi(int(round(a3.distance_to(b3) / pitch)), 1)
	for r in rows:
		var rr: Array = r
		row(lm, frame, glass, a3, b3, Vector3(out.x, 0, out.y), float(rr[0]), n, float(rr[1]), float(rr[2]),
			str(rr[3]))

## String course along a..b (XZ points) at y, h tall, proud by `proj`.
static func course(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, out: Vector2, y: float, h: float,
		proj: float) -> void:
	var d := (b - a).normalized()
	var basis := Basis(Vector3(d.x, 0, d.y), Vector3.UP, Vector3(out.x, 0, out.y))
	var m := (a + b) * 0.5
	lm.box(key, Vector3(m.x, y + h * 0.5, m.y) + Vector3(out.x, 0, out.y) * proj * 0.5,
		Vector3(a.distance_to(b), h, proj), basis, 0.0)

## A pilaster (or pair) on the wall face: base point `p`, facing `out`,
## from y0 up `h`, `w` wide, proud by `proj`, with a capital block.
static func pilaster(lm: LandmarkMesh, key: String, p: Vector3, out: Vector3, y0: float, h: float, w: float = 0.8,
		proj: float = 0.3) -> void:
	var n := out.normalized()
	var b := Basis(Vector3.UP.cross(n).normalized(), Vector3.UP, n)
	lm.box(key, Vector3(p.x, y0 + h * 0.5, p.z) + n * proj * 0.5, Vector3(w, h, proj), b, 0.0)
	lm.box(key, Vector3(p.x, y0 + h - 0.2, p.z) + n * proj * 0.6, Vector3(w + 0.25, 0.4, proj * 1.2), b, 0.0)
	lm.box(key, Vector3(p.x, y0 + 0.15, p.z) + n * proj * 0.6, Vector3(w + 0.2, 0.3, proj * 1.2), b, 0.0)

## Portico on the front (+Z) wall at z = `zw`: `n` columns across
## `width` centred on x = `cx`, standing on a platform of `plat` m, `h` tall
## (capital included), an entablature, a pediment `rise` high and a
## tympanum in the "Tympanum" key when the caller defined it.
static func portico(lm: LandmarkMesh, trim: String, cx: float, zw: float, width: float, n: int, base_y: float,
		h: float, depth: float, rise: float, order: String = "corinthian", r: float = 0.5) -> void:
	var zc := zw + depth - 0.65
	for i in n:
		var t := float(i) / float(maxi(n - 1, 1))
		LandmarkDetail.column(lm, trim, Vector3(cx - width * 0.5 + width * t, base_y, zc), r, h, order, 20, 14)
	var ty := base_y + h
	U.blk(lm, trim, cx, ty, zw + depth * 0.5, width + 2.6, 1.3, depth + 0.3)
	lm.gable(trim, Vector3(cx, ty + 1.3, zw + depth * 0.5), width + 2.8, depth + 0.5, rise, Basis(), 0.2, trim)
	LandmarkDetail.cornice(lm, trim, Vector3(cx - width * 0.5 - 1.5, ty + 1.3, zw + depth + 0.15),
		Vector3(cx + width * 0.5 + 1.5, ty + 1.3, zw + depth + 0.15), Vector3(0, 0, 1), 0.5, true)

## Window rows along every edge of the XZ polygon `poly` at least
## `min_len` long, except edges whose outward normal points within
## `skip_dot` of `skip_out` (a front the caller dresses itself).
static func poly_walls(lm: LandmarkMesh, frame: String, glass: String, poly: PackedVector2Array,
		pitch: float, rows: Array, margin: float = 1.2, min_len: float = 4.0, skip_out: Vector2 = Vector2.ZERO,
		skip_dot: float = 2.0) -> void:
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < min_len:
			continue
		var o3 := LandmarkFhParts.edge_out(poly, i)
		var o := Vector2(o3.x, o3.z)
		if skip_out != Vector2.ZERO and o.dot(skip_out) > skip_dot:
			continue
		run(lm, frame, glass, a, b, o, pitch, rows, margin)
