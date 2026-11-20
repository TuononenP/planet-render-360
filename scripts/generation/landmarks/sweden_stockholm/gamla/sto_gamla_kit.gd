extends RefCounted

## Shared parts for the Gamla stan models (Stortorget, Skeppsbron,
## Stadsmuseet), in true metres on LandmarkMesh. A townhouse is built once
## in its own frame (front wall on z = 0 facing +Z, width along X centred on
## the origin, the body running back to z = -d, y = 0 at the pavement) and
## merged onto the site with `place`. Every part takes material KEYS the
## caller registered with lm.use: "Glass", "Trim", "Slate" and "Stone" are
## required; the wall key and the optional "Copper", "Gold" come from the spec.

const Pal = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")
const Baro = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")

## Depth of the wall skin that carries the window reveals (LandmarkDetail.pierced_face).
const SKIN := 0.3

## A fresh mesh with every material of `mats` registered.
static func fresh(mats: Dictionary) -> LandmarkMesh:
	return Baro.fresh(mats)

## Merges a house part built in its own frame onto the site: the front on
## `pos`, turned `rot` radians about Y (PI/2 turns +Z onto +X).
static func place(lm: LandmarkMesh, part: LandmarkMesh, pos: Vector3, rot: float = 0.0) -> void:
	lm.merge(part, Transform3D(Basis(Vector3.UP, rot), pos))

## A window surround (jambs, lintel, projecting sill, glazing bars) for an
## opening `w` x `h` whose sill centre is the origin, standing on a wall that
## faces +Z. The glass is cut into the wall by the skin, not here.
static func surround(mats: Dictionary, frame: String, w: float, h: float, round_head: bool = false) -> LandmarkMesh:
	var p := fresh(mats)
	var f := clampf(w * 0.12, 0.1, 0.22)
	for s in [-1.0, 1.0]:
		p.box(frame, Vector3(float(s) * (w * 0.5 + f * 0.5), h * 0.5, 0.06), Vector3(f, h, 0.16), Basis(), 0.0)
	p.box(frame, Vector3(0, h + f * 0.5, 0.07), Vector3(w + f * 2.0 + 0.1, f, 0.2), Basis(), 0.0)
	p.box(frame, Vector3(0, -f * 0.5, 0.1), Vector3(w + f * 2.0 + 0.14, f, 0.24), Basis(), 0.0)
	if round_head:
		p.box(frame, Vector3(0, h + f * 1.2, 0.1), Vector3(f * 1.4, f * 1.4, 0.24), Basis(), 0.0)
	p.box(frame, Vector3(0, h * 0.5, 0.02), Vector3(0.05, h, 0.05), Basis(), 0.0)
	p.box(frame, Vector3(0, h * 0.66, 0.02), Vector3(w, 0.05, 0.05), Basis(), 0.0)
	return p

## A flat window for a wall with no cut-out: dark glass in a thin frame on a
## plane facing +Z (sill centre at the origin).
static func flat_window(mats: Dictionary, frame: String, w: float, h: float) -> LandmarkMesh:
	var p := fresh(mats)
	p.quad("Glass", Vector3(-w * 0.5, 0, 0.03), Vector3(w * 0.5, 0, 0.03), Vector3(w * 0.5, h, 0.03),
		Vector3(-w * 0.5, h, 0.03), Vector3(0, 0, 1))
	var f := clampf(w * 0.11, 0.09, 0.2)
	for s in [-1.0, 1.0]:
		p.box(frame, Vector3(float(s) * (w * 0.5 + f * 0.5), h * 0.5, 0.06), Vector3(f, h + f, 0.14), Basis(), 0.0)
	p.box(frame, Vector3(0, h + f * 0.5, 0.07), Vector3(w + f * 2.0 + 0.1, f, 0.18), Basis(), 0.0)
	p.box(frame, Vector3(0, -f * 0.5, 0.09), Vector3(w + f * 2.0 + 0.12, f, 0.22), Basis(), 0.0)
	p.box(frame, Vector3(0, h * 0.5, 0.05), Vector3(0.05, h, 0.04), Basis(), 0.0)
	p.box(frame, Vector3(0, h * 0.62, 0.05), Vector3(w, 0.05, 0.04), Basis(), 0.0)
	return p

## Windows of `part` on the wall run a -> b (ground points) facing `out`:
## `n` evenly spaced, sills `y` up, `rows` rows `storey` apart.
static func window_rows(lm: LandmarkMesh, part: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3,
		y: float, n: int, rows: int, storey: float) -> void:
	var rot := Basis(Vector3.UP.cross(out).normalized(), Vector3.UP, out)
	for r in rows:
		for i in n:
			var p := a.lerp(b, (float(i) + 0.5) / float(n))
			lm.merge(part, Transform3D(rot, Vector3(p.x, y + storey * float(r), p.z)))

## A tall arched or flat door: frame, dark leaves with a fanlight, centred
## on x = `x`, standing on the pavement of a wall facing +Z at z = `z`.
static func door(lm: LandmarkMesh, x: float, z: float, w: float, h: float, arched: bool = true) -> void:
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, h * 0.5 + 0.01, z + SKIN), Vector3(0, 0, 1), w, h, arched, 0.3)
	lm.box("Stone", Vector3(x, 0.12, z + SKIN + 0.45), Vector3(w + 0.9, 0.24, 0.9), Basis(), 0.0)

## One storey-and-window house, the front facing +Z at z = 0.
## spec: w, d, eave, base_h, wall, cols, win (Vector2), sill, storey, rows,
## roof ("mansard", "hip", "gable"), rise, roof_key, dormers, chimneys,
## door (column index, a list of them, or -1), sides (windows on the flanks), back (windows on
## the back wall), base ("Stone" rusticated ground floor).
static func house(mats: Dictionary, s: Dictionary) -> LandmarkMesh:
	var lm := fresh(mats)
	var w: float = s["w"]
	var d: float = s["d"]
	var eave: float = s["eave"]
	var bh: float = s.get("base_h", 4.4)
	var wall: String = s["wall"]
	var hw := w * 0.5
	var cols: int = s["cols"]
	var win: Vector2 = s.get("win", Vector2(1.25, 1.9))
	var storey: float = s.get("storey", 3.6)
	var rows: int = s["rows"]
	var sill: float = s.get("sill", 1.0)
	Pal.rb(lm, wall, -hw, hw, 0.0, eave, -d, 0.0, 0.0)
	var a := Vector3(-hw, 0, 0)
	var b := Vector3(hw, 0, 0)
	# Rusticated ground floor and the upper wall, each with real openings.
	if bh > 0.1:
		LandmarkFhParts.pierce(lm, str(s.get("base", "Stone")), "Glass", a, b, Vector3(0, 0, 1), 0.0, bh, cols, 1,
			Vector2(win.x * 0.9, bh * 0.5), bh * 0.28, storey, SKIN)
	LandmarkFhParts.pierce(lm, wall, "Glass", a, b, Vector3(0, 0, 1), bh, eave - bh, cols, rows, win, sill, storey, SKIN)
	var sur := surround(mats, "Trim", win.x, win.y)
	window_rows(lm, sur, Vector3(-hw, 0, SKIN), Vector3(hw, 0, SKIN), Vector3(0, 0, 1), bh + sill, cols, rows, storey)
	if bh > 0.1:
		var sur_b := surround(mats, "Trim", win.x * 0.9, bh * 0.5)
		window_rows(lm, sur_b, Vector3(-hw, 0, SKIN), Vector3(hw, 0, SKIN), Vector3(0, 0, 1), bh * 0.28, cols, 1, storey)
		Pal.rb(lm, "Trim", -hw - 0.1, hw + 0.1, bh - 0.12, bh + 0.16, -d - 0.1, SKIN + 0.12, 0.0)
	var doors: Variant = s.get("door", -1)
	var pitch := w / float(cols)
	for dc: int in (doors if doors is Array else [doors]):
		if dc >= 0:
			door(lm, -hw + pitch * (float(dc) + 0.5), 0.0, 1.7, minf(bh * 0.8, 3.3))
	# Eave cornice on all sides.
	Pal.rb(lm, "Trim", -hw - 0.3, hw + 0.3, eave - 0.5, eave + 0.15, -d - 0.3, SKIN + 0.3, 0.0)
	if bool(s.get("back", true)):
		LandmarkFhParts.pierce(lm, wall, "Glass", Vector3(hw, 0, -d), Vector3(-hw, 0, -d), Vector3(0, 0, -1), 0.0,
			eave, cols, rows + 1, win, 1.0, storey, 0.0)
	if bool(s.get("sides", false)):
		var nside := maxi(int(d / 3.4), 2)
		LandmarkFhParts.pierce(lm, wall, "Glass", Vector3(hw, 0, 0), Vector3(hw, 0, -d), Vector3(1, 0, 0), 0.0,
			eave, nside, rows + 1, win, 1.0, storey, 0.0)
		LandmarkFhParts.pierce(lm, wall, "Glass", Vector3(-hw, 0, -d), Vector3(-hw, 0, 0), Vector3(-1, 0, 0), 0.0,
			eave, nside, rows + 1, win, 1.0, storey, 0.0)
	_roof(lm, s, hw, d, eave)
	return lm

static func _roof(lm: LandmarkMesh, s: Dictionary, hw: float, d: float, eave: float) -> void:
	var rk: String = s.get("roof_key", "Slate")
	var rise: float = s.get("rise", 5.4)
	var y0 := eave + 0.15
	var c := Vector3(0, y0, -d * 0.5 + 0.15)
	var hz := d * 0.5
	match str(s.get("roof", "mansard")):
		"gable":
			lm.gable(rk, Vector3(0, y0, -d * 0.5), hw * 2.0 + 0.3, d + 0.2, rise, Basis(), 0.3, str(s["wall"]))
		"hip":
			var inset := minf(hw, d * 0.5) - 0.05
			Baro.hip(lm, rk, c, hw + 0.25, hz, [[-0.3, 0.0], [inset, rise]])
		_:
			var top_in := clampf(hw * 0.62, 1.9, maxf(hw - 0.1, 1.95))
			Baro.hip(lm, rk, c, hw + 0.25, hz,
				[[-0.3, 0.0], [1.5, rise * 0.78], [1.8, rise * 0.84], [top_in, rise]])
	var n: int = s.get("dormers", 0)
	if n > 0:
		_dormers(lm, s, hw, y0, n, rk)
	var chim: int = s.get("chimneys", 0)
	for i in chim:
		var t := (float(i) + 0.5) / float(chim)
		var cx := lerpf(-hw * 0.7, hw * 0.7, t)
		var cz := -d * (0.45 if i % 2 == 0 else 0.7)
		Pal.rb(lm, "Slate", cx - 0.6, cx + 0.6, y0, y0 + rise + 1.7, cz - 0.6, cz + 0.6, 0.0)
		Pal.rb(lm, "Trim", cx - 0.7, cx + 0.7, y0 + rise + 1.7, y0 + rise + 1.95, cz - 0.7, cz + 0.7, 0.0)

## Dormers on the steep lower slope of a mansard roof: dark cheeks, a
## pedimented front with a window, a small slate gable on top.
static func _dormers(lm: LandmarkMesh, s: Dictionary, hw: float, y0: float, n: int, rk: String) -> void:
	var rise: float = s.get("rise", 5.4)
	var lower := rise * 0.78
	var yc := y0 + lower * 0.42
	var zs := 0.45 - (yc - y0) / lower * 1.8
	var dw := 1.4
	for i in n:
		var x := lerpf(-hw * 0.72, hw * 0.72, (float(i) + 0.5) / float(n)) if n > 1 else 0.0
		Pal.rb(lm, rk, x - dw * 0.5, x + dw * 0.5, yc - 0.7, yc + 0.95, zs - 1.2, zs + 0.32, 0.0)
		lm.quad("Glass", Vector3(x - 0.45, yc - 0.45, zs + 0.34), Vector3(x + 0.45, yc - 0.45, zs + 0.34),
			Vector3(x + 0.45, yc + 0.6, zs + 0.34), Vector3(x - 0.45, yc + 0.6, zs + 0.34), Vector3(0, 0, 1))
		Pal.rb(lm, "Trim", x - 0.6, x + 0.6, yc - 0.55, yc - 0.45, zs + 0.3, zs + 0.45, 0.0)
		Pal.rb(lm, "Trim", x - 0.6, x + 0.6, yc + 0.6, yc + 0.72, zs + 0.3, zs + 0.45, 0.0)
		lm.gable(rk, Vector3(x, yc + 0.95, zs - 0.45), dw + 0.2, 1.7, 0.7, Basis(), 0.1, rk)

# --- Gables -------------------------------------------------------------

## Stepped (trappgavel) profile: half widths as shares of `hw` at heights as
## shares of `h`, mirrored.
const STEPPED := [[1.0, 0.0], [1.0, 0.2], [0.8, 0.2], [0.8, 0.4], [0.6, 0.4], [0.6, 0.58], [0.4, 0.58],
	[0.4, 0.74], [0.2, 0.74], [0.2, 0.88], [0.07, 0.88], [0.0, 1.0]]

## Shaped baroque gable: full width at the eave, an ogee in to a narrow neck,
## a round crown on top.
static func baroque_profile(hw: float, h: float) -> PackedVector2Array:
	var right := PackedVector2Array()
	right.append(Vector2(hw, 0.0))
	right.append(Vector2(hw, 0.1 * h))
	for i in range(1, 7):
		var t := float(i) / 6.0
		var sm := t * t * (3.0 - 2.0 * t)
		right.append(Vector2(hw - (hw - 0.52 * hw) * sm, 0.1 * h + 0.36 * h * t))
	var cr := 0.52 * hw
	var cy := 0.46 * h
	for i in range(0, 9):
		var a := PI * float(i) / 8.0
		right.append(Vector2(cr * cos(a), cy + (h - cy) * sin(a)))
	var poly := PackedVector2Array()
	for p in right:
		poly.append(p)
	for i in range(right.size() - 1, -1, -1):
		var q := right[i]
		if q.x > 0.001:
			poly.append(Vector2(-q.x, q.y))
	return poly

static func stepped_profile(hw: float, h: float) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for r in STEPPED:
		poly.append(Vector2(hw * float(r[0]), h * float(r[1])))
	for i in range(STEPPED.size() - 1, -1, -1):
		var r: Array = STEPPED[i]
		if float(r[0]) > 0.001:
			poly.append(Vector2(-hw * float(r[0]), h * float(r[1])))
	return poly

## A gable plate of outline `prof` (x along the wall, y up from the eave line),
## `thick` deep, its front on z = `zf`, merged into `lm`.
static func gable_plate(lm: LandmarkMesh, mats: Dictionary, key: String, prof: PackedVector2Array,
		eave_y: float, zf: float, thick: float = 0.6) -> void:
	var p := fresh(mats)
	p.poly_prism(key, prof, 0.0, thick)
	lm.merge(p, Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3(0, eave_y, zf)))

## A round window (moulded ring, dark glass) facing +Z.
static func oculus(lm: LandmarkMesh, ring: String, c: Vector3, r: float) -> void:
	lm.disc(ring, c + Vector3(0, 0, 0.02), Vector3(0, 0, 1), r * 1.3, 14)
	lm.disc("Glass", c + Vector3(0, 0, 0.05), Vector3(0, 0, 1), r, 14)
