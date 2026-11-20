extends RefCounted

## Parts shared by the Riddarhuset, Wrangel and Bonde builders (true metres
## on LandmarkMesh). Repeated parts (a window, a festoon, a pilaster, a
## roundel) are built once in their own frame, facing +Z with the wall
## point at the origin, and merged onto each wall with `put`. Roofs are
## hips whose profile is a list of [inset_m, rise_m] rows, so a straight
## pitch is two rows and the curved säteri roof of the Riddarhuset is
## eight.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

## A mesh with every material of `mats` (key -> Material) registered.
static func fresh(mats: Dictionary) -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	for k in mats:
		lm.use(str(k), mats[k])
	return lm

## Basis that turns +Z onto the horizontal outward normal `out`.
static func face(out: Vector3) -> Basis:
	return Basis(Vector3.UP.cross(out).normalized(), Vector3.UP, out)

## Merges a part (built facing +Z at the origin) onto a wall at `pos`.
static func put(lm: LandmarkMesh, part: LandmarkMesh, pos: Vector3, out: Vector3) -> void:
	lm.merge(part, Transform3D(face(out), pos))

## `n` copies of `part` evenly along the wall run a..b (ground points, the
## y of `a` ignored), `y` up, facing `out`; `skip` lists indices left bare.
static func row(lm: LandmarkMesh, part: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, y: float,
		n: int, skip: Array = []) -> void:
	for i in n:
		if skip.has(i):
			continue
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		put(lm, part, Vector3(p.x, y, p.z), out)

## Framed window `w` x `h` whose sill stands at the origin (frame key
## `frame`, glass key "Glass"); `arched` gives a round head.
static func window(mats: Dictionary, frame: String, w: float, h: float, arched: bool = false,
		depth: float = 0.22) -> LandmarkMesh:
	var p := fresh(mats)
	LandmarkDetail.window(p, frame, "Glass", Vector3(0, h * 0.5 + 0.5, 0), Vector3(0, 0, 1), w, h, arched, depth)
	var q := fresh(mats)
	q.merge(p, Transform3D(Basis(), Vector3(0, -0.5, 0)))
	return q

## A swag of cloth hung between two bows, `w` across and sagging `drop`,
## the bows at the origin height.
static func festoon(mats: Dictionary, key: String, w: float, drop: float) -> LandmarkMesh:
	var p := fresh(mats)
	var n := 8
	var prev := Vector3(-w * 0.5, 0, 0.06)
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		var cur := Vector3(-w * 0.5 + w * t, -drop * 4.0 * t * (1.0 - t), 0.06)
		p.beam(key, prev, cur, 0.14, 0.3)
		prev = cur
	for s in [-1.0, 1.0]:
		p.box(key, Vector3(float(s) * w * 0.5, 0.05, 0.08), Vector3(0.42, 0.34, 0.16), Basis(), 0.0)
		p.box(key, Vector3(float(s) * (w * 0.5 - 0.1), -drop * 0.55, 0.06), Vector3(0.2, drop * 0.9, 0.12),
			Basis(), 0.0)
	return p

## A pilaster `w` wide, `h` tall from its foot at the origin, standing
## `proj` proud: base, shaft, capital. `order` is "corinthian" (acanthus
## bell, corner volutes, abacus) or "ionic" (cushion with two volutes).
static func pilaster(mats: Dictionary, key: String, h: float, w: float, proj: float,
		order: String = "corinthian") -> LandmarkMesh:
	var p := fresh(mats)
	var ch := w * 0.95
	var bh := w * 0.45
	p.box(key, Vector3(0, bh * 0.5, proj * 0.55), Vector3(w * 1.25, bh, proj * 1.1), Basis(), 0.0)
	p.box(key, Vector3(0, bh + (h - bh - ch) * 0.5, proj * 0.5), Vector3(w, h - bh - ch, proj))
	var y0 := h - ch
	if order == "corinthian":
		p.box(key, Vector3(0, y0 + ch * 0.2, proj * 0.5), Vector3(w * 1.02, ch * 0.4, proj * 1.0), Basis(), 0.0)
		p.box(key, Vector3(0, y0 + ch * 0.58, proj * 0.6), Vector3(w * 1.28, ch * 0.34, proj * 1.2), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			p.box(key, Vector3(float(s) * w * 0.6, y0 + ch * 0.74, proj * 0.62), Vector3(w * 0.3, ch * 0.34, proj * 1.24),
				Basis(), 0.0)
		p.box(key, Vector3(0, y0 + ch * 0.93, proj * 0.6), Vector3(w * 1.5, ch * 0.14, proj * 1.3), Basis(), 0.0)
	else:
		p.box(key, Vector3(0, y0 + ch * 0.55, proj * 0.62), Vector3(w * 1.3, ch * 0.4, proj * 1.24), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			p.disc(key, Vector3(float(s) * w * 0.55, y0 + ch * 0.5, proj * 1.25), Vector3(0, 0, 1), ch * 0.3, 10)
		p.box(key, Vector3(0, y0 + ch * 0.9, proj * 0.62), Vector3(w * 1.45, ch * 0.2, proj * 1.3), Basis(), 0.0)
	return p

## A round window: moulded ring and dark glass, centred on the origin.
static func roundel(mats: Dictionary, key: String, r: float) -> LandmarkMesh:
	var p := fresh(mats)
	FhP.ring(p, key, Vector3.ZERO, Vector3(0, 0, 1), r * 0.78, r * 1.25, 0.12, 12)
	p.disc("Glass", Vector3(0, 0, 0.03), Vector3(0, 0, 1), r * 0.78, 12)
	p.box(key, Vector3(0, 0, 0.06), Vector3(r * 1.56, 0.06, 0.05), Basis(), 0.0)
	p.box(key, Vector3(0, 0, 0.06), Vector3(0.06, r * 1.56, 0.05), Basis(), 0.0)
	return p

## Hip roof over the rectangle `hx` x `hz` (half extents) about `c` (eave
## level), rising by the rows of `prof` ([inset_m, rise_m], eave first),
## closed by a flat top. Each side is its own smooth strip, so the long
## planes shade flat across and curve along the profile.
static func hip(lm: LandmarkMesh, key: String, c: Vector3, hx: float, hz: float, prof: Array) -> void:
	for side in 4:
		var rows: Array = []
		for r in prof:
			var ax := maxf(hx - float(r[0]), 0.05)
			var az := maxf(hz - float(r[0]), 0.05)
			var y := c.y + float(r[1])
			var pa: Vector3
			var pb: Vector3
			match side:
				0:
					pa = Vector3(c.x - ax, y, c.z - az)
					pb = Vector3(c.x + ax, y, c.z - az)
				1:
					pa = Vector3(c.x + ax, y, c.z - az)
					pb = Vector3(c.x + ax, y, c.z + az)
				2:
					pa = Vector3(c.x + ax, y, c.z + az)
					pb = Vector3(c.x - ax, y, c.z + az)
				_:
					pa = Vector3(c.x - ax, y, c.z + az)
					pb = Vector3(c.x - ax, y, c.z - az)
			rows.append(PackedVector3Array([pa, pb]))
		var hint := Vector3(0, 0.6, -1)
		match side:
			1: hint = Vector3(1, 0.6, 0)
			2: hint = Vector3(0, 0.6, 1)
			3: hint = Vector3(-1, 0.6, 0)
		lm.grid(key, rows, hint)
	var top: Array = prof[prof.size() - 1]
	var tx := maxf(hx - float(top[0]), 0.05)
	var tz := maxf(hz - float(top[0]), 0.05)
	var ty := c.y + float(top[1])
	lm.quad(key, Vector3(c.x - tx, ty, c.z - tz), Vector3(c.x + tx, ty, c.z - tz),
		Vector3(c.x + tx, ty, c.z + tz), Vector3(c.x - tx, ty, c.z + tz), Vector3.UP)

## Dome of `prof` rows (radius, y from the base), stretched to the ellipse
## `sx` x `sz` (1.0 for a round one), with a lantern: ring of posts round
## dark openings, a small cap, a ball and a spire. Returns the finial top.
static func domed_lantern(lm: LandmarkMesh, mats: Dictionary, base: Vector3, prof: PackedVector2Array,
		lantern_h: float, cap_h: float, spire_h: float, sx: float = 1.0, sz: float = 1.0) -> float:
	lm.lathe("Copper", base, prof, 24, sx, sz)
	var top := prof[prof.size() - 1]
	var lb := base + Vector3(0, top.y, 0)
	var lr := top.x
	lm.frustum("Copper", lb, lr * 1.18, lr * 1.1, 0.25, 12)
	var hb := lb + Vector3(0, 0.25, 0)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Copper", hb + d * lr * 0.96 + Vector3(0, lantern_h * 0.5, 0),
			Vector3(lr * 0.24, lantern_h, lr * 0.24), Basis(Vector3.UP, -a), 0.0)
		var wa := a + PI / 8.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		lm.box("Glass", hb + wd * lr * 0.95 + Vector3(0, lantern_h * 0.5, 0),
			Vector3(lr * 0.3, lantern_h * 0.72, lr * 0.12), Basis(Vector3.UP, -wa), 0.0)
	var cb := hb + Vector3(0, lantern_h, 0)
	lm.frustum("Copper", cb, lr * 1.2, lr * 1.0, 0.22, 12)
	lm.lathe("Copper", cb + Vector3(0, 0.22, 0), PackedVector2Array([Vector2(lr * 1.0, 0), Vector2(lr * 0.9, cap_h * 0.3),
		Vector2(lr * 0.6, cap_h * 0.7), Vector2(lr * 0.2, cap_h)]), 16)
	var sb := cb + Vector3(0, 0.22 + cap_h, 0)
	lm.lathe("Gold", sb, PackedVector2Array([Vector2(0.0, 0), Vector2(0.28, 0.2), Vector2(0.32, 0.45),
		Vector2(0.2, 0.75), Vector2(0.0, 0.8)]), 10)
	lm.frustum("Gold", sb + Vector3(0, 0.75, 0), 0.07, 0.015, spire_h, 6)
	return sb.y + 0.75 + spire_h

## Straight run of iron railing a..b: top and bottom rail and bars `step` apart.
static func railing(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, step: float = 0.7) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5
	lm.box(key, mid + Vector3(0, h, 0), Vector3(dl, 0.07, 0.1), basis, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.12, 0), Vector3(dl, 0.07, 0.1), basis, 0.0)
	var n := maxi(int(dl / step), 1)
	var bars := PackedVector3Array()
	var sizes := PackedVector3Array()
	for i in n + 1:
		bars.append(a.lerp(b, float(i) / float(n)) + Vector3(0, h * 0.5, 0))
		sizes.append(Vector3(0.05, h, 0.05))
	lm.boxes(key, bars, sizes, basis, 0.0)
