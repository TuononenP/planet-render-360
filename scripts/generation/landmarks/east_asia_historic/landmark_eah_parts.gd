class_name LandmarkEahParts
extends RefCounted

## Shared parts for the east-Asia historic batch, in true metres on
## LandmarkMesh: corner-to-corner slabs, perimeter colonnades, the
## hip-and-gable (irimoya) roof, ridge-end horns, stairs, arched
## openings, concave stone bases and barrel-vault extrusions. The
## concave hip roof itself is LandmarkAeParts.hip_roof.

## Axis box from corner `a` to corner `b`.
static func slab(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3) -> void:
	lm.box(key, (a + b) * 0.5, Vector3(absf(b.x - a.x), absf(b.y - a.y), absf(b.z - a.z)))

## One slightly tapering round column of radius r from `base` up h.
static func column(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		seg: int = 8) -> void:
	lm.frustum(key, base, r, r * 0.9, h, seg)

## Columns round the edge of a rectangle `size` centred at `c` (x, z): nx
## bays along X, nz along Z.
static func colonnade(lm: LandmarkMesh, key: String, c: Vector2, size: Vector2, y: float,
		h: float, nx: int, nz: int, r: float, seg: int = 8) -> void:
	for i in nx + 1:
		var x := c.x - size.x * 0.5 + size.x * float(i) / nx
		for s in [-1.0, 1.0]:
			column(lm, key, Vector3(x, y, c.y + s * size.y * 0.5), h, r, seg)
	for j in range(1, nz):
		var z := c.y - size.y * 0.5 + size.y * float(j) / nz
		for s in [-1.0, 1.0]:
			column(lm, key, Vector3(c.x + s * size.x * 0.5, y, z), h, r, seg)

## Hip-and-gable (irimoya) roof: a concave hip from the `eave` rectangle
## (X by Z, centred on c) to the `ridge` rectangle `rise_hip` up, then a
## gable (ridge along X) `rise_gable` higher with plastered ends.
static func irimoya(lm: LandmarkMesh, key: String, gable_key: String, c: Vector3, eave: Vector2,
		ridge: Vector2, rise_hip: float, rise_gable: float, lift: float = 0.8) -> void:
	LandmarkAeParts.hip_roof(lm, key, c, eave, ridge, rise_hip, lift)
	lm.gable(key, c + Vector3(0, rise_hip, 0), ridge.y, ridge.x, rise_gable,
		Basis(Vector3.UP, PI * 0.5), 0.0, gable_key)

## Curled ridge-end ornament (shibi / chiwen) rising h from `base`,
## leaning toward the ridge centre in direction `inward` (+1 / -1 along X).
static func horn(lm: LandmarkMesh, key: String, base: Vector3, h: float, inward: float,
		r: float = 0.45) -> void:
	var mid := base + Vector3(-inward * 0.2, h * 0.55, 0)
	LandmarkAeParts.tube(lm, key, base, mid, r, r * 0.75, 8)
	LandmarkAeParts.tube(lm, key, mid, base + Vector3(inward * 0.5, h, 0), r * 0.75, r * 0.15, 8)

## Straight stair rising toward -Z: `steps` treads from y0 at z_front, `w`
## wide, each tread `tread` deep and `rise` high, solid underneath.
static func stairs(lm: LandmarkMesh, key: String, x: float, z_front: float, y0: float, w: float,
		steps: int, rise: float, tread: float) -> void:
	for i in steps:
		var top := y0 + rise * (i + 1)
		var base := y0 - 0.4
		lm.box(key, Vector3(x, (base + top) * 0.5, z_front - tread * (i + 0.5)),
			Vector3(w, top - base, tread))

## Dark arched opening on a wall plane through `at` (x, z) facing the
## axis-aligned unit normal `n`: w wide, h high to the crown, bottom at y,
## drawn proud of the wall.
static func arch_open(lm: LandmarkMesh, key: String, at: Vector3, n: Vector3, y: float, w: float,
		h: float) -> void:
	var rect_h := h - w * 0.5
	var size := Vector3(w * absf(n.z) + 0.12 * absf(n.x), rect_h, w * absf(n.x) + 0.12 * absf(n.z))
	lm.box(key, Vector3(at.x, y + rect_h * 0.5, at.z) + n * 0.06, size)
	lm.disc(key, Vector3(at.x, y + rect_h, at.z) + n * 0.07, n, w * 0.5, 14)

## Concave battered stone base from below ground (y0) to `top`: plan
## `plan` at the top, flaring by `flare` (x, z) at y0, in six slices.
static func stone_base(lm: LandmarkMesh, key: String, c: Vector2, plan: Vector2, y0: float,
		top: float, flare: Vector2) -> void:
	var prev_y := y0
	var prev := plan + flare
	for i in range(1, 7):
		var t := float(i) / 6.0
		var k := pow(1.0 - t, 2.2)
		var cur := plan + flare * k
		var sy := lerpf(y0, top, t)
		LandmarkAeParts.batter(lm, key, c.x, c.y, prev.x, prev.y, cur.x, cur.y, prev_y, sy)
		prev_y = sy
		prev = cur

## Smooth skin of a (z, y) cross-section `prof` extruded along X from x0
## to x1, facing away from `centre` (z, y). Not capped.
static func extrude_x(lm: LandmarkMesh, key: String, prof: PackedVector2Array, x0: float,
		x1: float, centre: Vector2) -> void:
	var n := prof.size()
	var norms := PackedVector2Array()
	for i in n:
		var a := prof[maxi(i - 1, 0)]
		var b := prof[mini(i + 1, n - 1)]
		var e := b - a
		var nv := Vector2(e.y, -e.x).normalized()
		if nv.dot(prof[i] - centre) < 0.0:
			nv = -nv
		norms.append(nv)
	var u := 0.0
	for i in n - 1:
		var p := prof[i]
		var q := prof[i + 1]
		var span := p.distance_to(q)
		var na := Vector3(0, norms[i].y, norms[i].x)
		var nb := Vector3(0, norms[i + 1].y, norms[i + 1].x)
		var a0 := Vector3(x0, p.y, p.x)
		var b0 := Vector3(x1, p.y, p.x)
		var a1 := Vector3(x0, q.y, q.x)
		var b1 := Vector3(x1, q.y, q.x)
		var run := absf(x1 - x0)
		lm.tri(key, a0, b0, b1, na, na, nb, Vector2(0, u), Vector2(run, u), Vector2(run, u + span))
		lm.tri(key, a0, b1, a1, na, nb, nb, Vector2(0, u), Vector2(run, u + span), Vector2(0, u + span))
		u += span

## Flat polygon `poly` (x = z, y = y of a cross-section) at X = x, facing
## +X when `facing` is +1 and -X when -1.
static func cap_x(lm: LandmarkMesh, key: String, poly: PackedVector2Array, x: float,
		facing: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	var nrm := Vector3(facing, 0, 0)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(x, a.y, a.x), Vector3(x, b.y, b.x), Vector3(x, c.y, c.x), nrm, nrm, nrm,
			Vector2(a.x, a.y), Vector2(b.x, b.y), Vector2(c.x, c.y))
