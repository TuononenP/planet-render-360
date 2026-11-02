class_name AtUtil
extends RefCounted

## Helpers shared by the Athens landmark builders (true metres on
## LandmarkMesh): the three Greek orders with real flutes and carved
## capitals, entablatures, triglyph friezes, framed doorways, stepped
## platforms, pitched temple roofs, caryatids, arched walls and curved
## seating tiers (circular cavea and the horseshoe of a stadium).

# --- Columns ----------------------------------------------------------

## Fluted shaft with entasis: `flutes` channels (0 = plain), r0 at the
## foot to r1 at the neck with the slight swell of the Greek shaft. Left
## open at both ends (the base and capital hide them).
static func fluted(lm: LandmarkMesh, key: String, base: Vector3, h: float, r0: float,
		r1: float, flutes: int = 20) -> void:
	if flutes <= 0:
		var mid := lerpf(r0, r1, 0.4) * 1.02
		lm.lathe(key, base, PackedVector2Array([Vector2(r0, 0), Vector2(mid, h * 0.4), Vector2(r1, h)]),
			16, 1.0, 1.0, 0.0, true, false)
		return
	var per := 3
	var cols := flutes * per
	var rows: Array = []
	for t in [0.0, 0.4, 0.75, 1.0]:
		var tt: float = t
		var rr := lerpf(r0, r1, tt) + sin(PI * tt) * (r0 - r1) * 0.15
		var ring := PackedVector3Array()
		for i in cols + 1:
			var a := TAU * float(i) / float(cols)
			var d := rr * (0.94 if i % per != 0 else 1.0)
			ring.append(base + Vector3(cos(a) * d, h * tt, sin(a) * d))
		rows.append(ring)
	lm.grid(key, rows, base + Vector3(0, h * 0.5, 0), true)

## Doric column with no base: `flutes` sharp-edged flutes (20 in
## Athens), three annulets at the neck, the swelling echinus and the
## square abacus. `h` is the full height, `r` the lower radius, `rot`
## turns the abacus.
static func doric(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		flutes: int = 20, rot: float = 0.0) -> void:
	var cap := r * 0.62
	var eh := cap * 0.6
	var rn := r * 0.78
	fluted(lm, key, base, h - cap, r, rn, flutes)
	var yc := base + Vector3(0, h - cap, 0)
	for k in 3:
		lm.lathe(key, yc - Vector3(0, cap * (0.06 + 0.07 * float(k)), 0), PackedVector2Array([Vector2(rn * 1.0, 0),
			Vector2(rn * 1.05, cap * 0.03), Vector2(rn * 1.0, cap * 0.06)]), 16, 1.0, 1.0, 0.0, true, false)
	lm.lathe(key, yc, PackedVector2Array([Vector2(rn, 0), Vector2(rn * 1.12, eh * 0.25),
		Vector2(rn * 1.32, eh * 0.6), Vector2(r * 1.15, eh)]), 20)
	lm.box(key, yc + Vector3(0, eh + (cap - eh) * 0.5, 0), Vector3(r * 2.3, cap - eh, r * 2.3),
		Basis(Vector3.UP, rot))

## Attic-Ionic base: torus, scotia and torus on a thin plinth ring,
## 0.7 r tall; returns its height.
static func _attic_base(lm: LandmarkMesh, key: String, base: Vector3, r: float) -> float:
	var bh := r * 0.7
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 1.42, 0), Vector2(r * 1.45, bh * 0.15),
		Vector2(r * 1.38, bh * 0.32), Vector2(r * 1.18, bh * 0.42), Vector2(r * 1.12, bh * 0.55),
		Vector2(r * 1.2, bh * 0.66), Vector2(r * 1.24, bh * 0.8), Vector2(r * 1.14, bh * 0.92),
		Vector2(r, bh)]), 16)
	return bh

## One Ionic volute: a scroll band spiralling inward from the top of
## the cushion at `c`, in the plane of `right` x up, unrolling toward
## `side` (+1 / -1), radius vr.
static func _volute(lm: LandmarkMesh, key: String, c: Vector3, right: Vector3, out: Vector3,
		vr: float, side: float) -> void:
	var prev := c + Vector3(0, vr, 0)
	for i in 8:
		var t := float(i + 1) / 8.0
		var a := PI * 0.5 - side * t * TAU * 1.05
		var rr := vr * (1.0 - t * 0.72)
		var p := c + right * cos(a) * rr + Vector3(0, sin(a) * rr, 0)
		lm.beam(key, prev, p, vr * 0.16, vr * 0.3 * (1.0 - t * 0.5), out)
		prev = p

## Ionic column on an attic base: fluted shaft (24 flutes with fillets),
## egg-and-dart echinus, the cushion with a spiral volute on both faces
## of each side, and a thin moulded abacus. The volute faces look along
## the local Z axis, turned by `rot` (PI/2 for a facade running
## north-south).
static func ionic(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		flutes: int = 24, rot: float = 0.0) -> void:
	var bh := _attic_base(lm, key, base, r)
	var ch := r * 0.95
	var rn := r * 0.84
	fluted(lm, key, base + Vector3(0, bh, 0), h - bh - ch, r, rn, flutes)
	var b := Basis(Vector3.UP, rot)
	var yc := Vector3(base.x, base.y + h - ch, base.z)
	lm.lathe(key, yc, PackedVector2Array([Vector2(rn, 0), Vector2(rn * 1.05, r * 0.05),
		Vector2(rn * 1.0, r * 0.1), Vector2(r * 1.08, r * 0.3)]), 20)
	lm.box(key, yc + Vector3(0, r * 0.45, 0), Vector3(r * 2.4, r * 0.3, r * 1.5), b)
	for s in [-1.0, 1.0]:
		var sd: float = s
		var c: Vector3 = yc + Vector3(0, r * 0.32, 0) + b.x * sd * r * 1.2
		cyl(lm, key, c - b.z * r * 0.72, c + b.z * r * 0.72, r * 0.32, 10)
		for f in [-1.0, 1.0]:
			_volute(lm, key, c + b.z * r * 0.76 * float(f), b.x, b.z, r * 0.42, sd)
	lm.box(key, Vector3(base.x, base.y + h - r * 0.07, base.z), Vector3(r * 2.8, r * 0.14, r * 2.0), b, 0.0)

## Corinthian column on an attic base: fluted shaft, a bell wrapped in
## two tiers of eight curling acanthus leaves, the corner helices and
## the concave-sided abacus. The capital is 1.2 diameters tall.
static func corinthian(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		flutes: int = 24, rot: float = 0.0) -> void:
	var bh := _attic_base(lm, key, base, r)
	var ch := r * 2.4
	var rn := r * 0.84
	fluted(lm, key, base + Vector3(0, bh, 0), h - bh - ch, r, rn, flutes)
	var yc := Vector3(base.x, base.y + h - ch, base.z)
	lm.lathe(key, yc, PackedVector2Array([Vector2(rn * 1.04, 0), Vector2(rn * 1.04, ch * 0.05),
		Vector2(rn, ch * 0.08), Vector2(rn * 1.02, ch * 0.5), Vector2(r * 1.05, ch * 0.8),
		Vector2(r * 1.2, ch * 0.9)]), 16, 1.0, 1.0, 0.0, true, false)
	for tier in 2:
		for i in 8:
			var a := rot + TAU * (float(i) + 0.5 * float(tier)) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			var lb := yc + d * rn * 0.98 + Vector3(0, ch * (0.04 + 0.28 * float(tier)), 0)
			var lt := lb + d * r * 0.18 + Vector3(0, ch * 0.3, 0)
			lm.beam(key, lb, lt, r * 0.5, r * 0.1, d.cross(Vector3.UP))
			lm.beam(key, lt, lt + d * r * 0.2 - Vector3(0, ch * 0.08, 0), r * 0.4, r * 0.08, d.cross(Vector3.UP))
	for i in 4:
		var a := rot + TAU * (float(i) + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam(key, yc + d * rn + Vector3(0, ch * 0.55, 0), yc + d * r * 1.5 + Vector3(0, ch * 0.86, 0),
			r * 0.2, r * 0.16)
	lm.box(key, yc + Vector3(0, ch * 0.95, 0), Vector3(r * 2.9, ch * 0.1, r * 2.9), Basis(Vector3.UP, rot))
	lm.box(key, yc + Vector3(0, ch * 0.95, 0), Vector3(r * 3.3, ch * 0.08, r * 0.9),
		Basis(Vector3.UP, rot + PI * 0.25), 0.0)
	lm.box(key, yc + Vector3(0, ch * 0.95, 0), Vector3(r * 0.9, ch * 0.08, r * 3.3),
		Basis(Vector3.UP, rot + PI * 0.25), 0.0)

## Round-section member from `a` to `b` (volute rolls, fallen drums).
static func cyl(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r: float,
		seg: int = 10) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := axis.cross(u)
	for i in seg:
		var t0 := TAU * float(i) / float(seg)
		var t1 := TAU * float(i + 1) / float(seg)
		var d0 := u * cos(t0) + v * sin(t0)
		var d1 := u * cos(t1) + v * sin(t1)
		lm.quad(key, a + d0 * r, a + d1 * r, b + d1 * r, b + d0 * r, ((d0 + d1) * 0.5).normalized())
	lm.disc(key, a, -axis, r, seg)
	lm.disc(key, b, axis, r, seg)

## Draped maiden of the Erechtheion porch (2.3 m with her capital):
## `h` tall in all, `r` the half-width of the robe, facing +Z turned by
## `rot`. Peplos with vertical folds falling from the belt, the bent
## knee, overfold, shoulders, plaited hair falling behind, head and the
## basket capital (echinus and abacus) on her head.
static func caryatid(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		rot: float = 0.0) -> void:
	var b := Basis(Vector3.UP, rot)
	lm.box(key, base + Vector3(0, h * 0.02, 0), Vector3(r * 2.3, h * 0.04, r * 2.0), b)
	var foot := base + Vector3(0, h * 0.04, 0)
	lm.lathe(key, foot, PackedVector2Array([Vector2(r * 1.0, 0), Vector2(r * 0.98, h * 0.2),
		Vector2(r * 0.88, h * 0.37), Vector2(r * 0.8, h * 0.42), Vector2(r * 0.95, h * 0.48),
		Vector2(r * 0.85, h * 0.55)]), 16, 1.0, 0.75, rot)
	for i in 9:
		var a := rot + TAU * float(i) / 9.0
		var d := Vector3(cos(a), 0, sin(a) * 0.75)
		lm.frustum(key, foot + d * r * 0.92, r * 0.1, r * 0.06, h * 0.4, 6)
	# The relaxed knee pressing through the drapery.
	lm.lathe(key, foot + b.z * r * 0.35 + b.x * r * 0.35, PackedVector2Array([Vector2(r * 0.3, 0),
		Vector2(r * 0.34, h * 0.2), Vector2(r * 0.22, h * 0.38)]), 8)
	var tb := foot + Vector3(0, h * 0.55, 0)
	lm.lathe(key, tb, PackedVector2Array([Vector2(r * 0.85, 0), Vector2(r * 0.9, h * 0.06),
		Vector2(r * 0.95, h * 0.1), Vector2(r * 0.7, h * 0.14), Vector2(r * 0.4, h * 0.16)]), 14, 1.0, 0.7, rot)
	lm.frustum(key, tb + Vector3(0, h * 0.15, 0), r * 0.22, r * 0.2, h * 0.04, 10)
	var hd := tb + Vector3(0, h * 0.18, 0)
	lm.lathe(key, hd, PackedVector2Array([Vector2(r * 0.1, 0), Vector2(r * 0.3, h * 0.02),
		Vector2(r * 0.34, h * 0.06), Vector2(r * 0.28, h * 0.1), Vector2(0.0, h * 0.11)]), 10, 0.9, 1.0, rot)
	lm.beam(key, hd - b.z * r * 0.25 + Vector3(0, h * 0.08, 0), tb - b.z * r * 0.55 + Vector3(0, h * 0.04, 0),
		r * 0.35, r * 0.15, b.x)
	var cb := hd + Vector3(0, h * 0.11, 0)
	lm.frustum(key, cb, r * 0.4, r * 0.48, h * 0.03, 12)
	lm.lathe(key, cb + Vector3(0, h * 0.03, 0), PackedVector2Array([Vector2(r * 0.48, 0),
		Vector2(r * 0.8, h * 0.03), Vector2(r * 1.0, h * 0.05)]), 16)
	var top := base.y + h
	lm.box(key, Vector3(base.x, (cb.y + h * 0.08 + top) * 0.5, base.z),
		Vector3(r * 2.2, maxf(top - cb.y - h * 0.08, 0.05), r * 2.2), b)

# --- Entablatures, doors ----------------------------------------------

## Entablature `len` long and `dep` deep centred at c (bottom of the
## architrave), running along basis X: architrave of three stepped
## fasciae (a plain beam when `fasciae` is false), frieze (frieze_key),
## and a moulded cornice with dentils on both long faces. Returns the top.
static func entab(lm: LandmarkMesh, key: String, frieze_key: String, c: Vector3, len_m: float,
		dep: float, ha: float, hf: float, hc: float, basis: Basis = Basis(),
		fasciae: bool = true, dentils: bool = true) -> float:
	if fasciae:
		for k in 3:
			lm.box(key, c + basis.y * ha * (float(k) + 0.5) / 3.0,
				Vector3(len_m, ha / 3.0, dep + 0.04 * float(k)), basis)
	else:
		lm.box(key, c + basis.y * ha * 0.5, Vector3(len_m, ha, dep), basis)
	lm.box(key, c + basis.y * (ha + 0.04), Vector3(len_m + 0.1, 0.08, dep + 0.2), basis, 0.0)
	lm.box(frieze_key, c + basis.y * (ha + hf * 0.5), Vector3(len_m, hf, dep - 0.04), basis)
	var yc := c + basis.y * (ha + hf)
	lm.box(key, yc + basis.y * hc * 0.5, Vector3(len_m + 0.2, hc, dep + 0.1), basis)
	for s in [-1.0, 1.0]:
		var o: Vector3 = basis.z * float(s)
		var e := yc + o * (dep * 0.5 + 0.05)
		LandmarkDetail.cornice(lm, key, e - basis.x * (len_m * 0.5 + 0.1), e + basis.x * (len_m * 0.5 + 0.1),
			o, hc, dentils)
	return yc.y + hc

## Doric triglyph frieze along a-b (frieze centre line on the face):
## `n` triglyphs, each with its two vertical glyphs, and a mutule with
## guttae drops in the cornice soffit above; `out` is the face normal.
static func triglyphs(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, out: Vector3,
		h: float, w: float) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, out.normalized())
	for i in n:
		var p := a.lerp(b, float(i) / float(maxi(n - 1, 1)))
		lm.box(key, p, Vector3(w, h, 0.12), basis, 0.0)
		for g in [-1.0, 1.0]:
			lm.box(key, p + dir * w * 0.17 * float(g) + out * 0.07, Vector3(w * 0.12, h * 0.85, 0.04), basis, 0.0)
		lm.box(key, p + out * 0.18 + Vector3(0, h * 0.55, 0), Vector3(w, 0.06, 0.3), basis, 0.0)

## Framed doorway on a wall face: a dark recess `w` x `h` standing on
## `c` (bottom centre on the face), an architrave surround, and a lintel
## cornice on two consoles when `consoles`.
static func doorway(lm: LandmarkMesh, frame: String, dark: String, c: Vector3, normal: Vector3,
		w: float, h: float, consoles: bool = false) -> void:
	var n := normal.normalized()
	var rt := Vector3.UP.cross(n).normalized()
	var basis := Basis(rt, Vector3.UP, n)
	var fw := clampf(w * 0.14, 0.15, 0.6)
	lm.box(dark, c + Vector3(0, h * 0.5, 0) + n * 0.02, Vector3(w, h, 0.04), basis, 0.0)
	for s in [-1.0, 1.0]:
		lm.box(frame, c + rt * (w * 0.5 + fw * 0.5) * float(s) + Vector3(0, h * 0.5, 0) + n * 0.1,
			Vector3(fw, h, 0.2), basis)
		if consoles:
			lm.box(frame, c + rt * (w * 0.5 + fw * 1.1) * float(s) + Vector3(0, h + fw * 0.6, 0) + n * 0.2,
				Vector3(fw * 0.4, fw * 1.6, 0.4), basis)
	lm.box(frame, c + Vector3(0, h + fw * 0.5, 0) + n * 0.1, Vector3(w + fw * 2.0, fw, 0.2), basis)
	lm.box(frame, c + Vector3(0, h + fw * 1.25, 0) + n * 0.12, Vector3(w + fw * 1.6, fw * 0.5, 0.24), basis)
	LandmarkDetail.cornice(lm, frame, c + Vector3(0, h + fw * 1.5, 0) - rt * (w * 0.5 + fw * 1.6) + n * 0.25,
		c + Vector3(0, h + fw * 1.5, 0) + rt * (w * 0.5 + fw * 1.6) + n * 0.25, n, fw * 0.9, false)

# --- Platforms and roofs ---------------------------------------------

## Stepped platform: `n` steps `rise` high, each `tread` wider than the one
## above; the top step is w x d centred on c with its top at c.y. The
## lowest step runs down to the ground (y = 0) as the foundation course.
static func steps(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, n: int,
		rise: float, tread: float) -> void:
	for k in n:
		var g := tread * float(k)
		var top := c.y - rise * float(k)
		var bot := maxf(top - rise, 0.0) if k < n - 1 else 0.0
		if top - bot > 0.01:
			lm.box(key, Vector3(c.x, (top + bot) * 0.5, c.z), Vector3(w + 2.0 * g, top - bot, d + 2.0 * g))

## Pitched roof with tympanum triangles and raking cornices at both
## ends: eaves at c.y, `w` across the basis X, `l` along its Z (ridge).
static func roof(lm: LandmarkMesh, roof_key: String, stone_key: String, tymp_key: String,
		c: Vector3, w: float, l: float, rise: float, over: float = 0.3,
		basis: Basis = Basis()) -> void:
	lm.gable(roof_key, c, w, l, rise, basis, over, tymp_key)
	for s in [-1.0, 1.0]:
		var e: Vector3 = c + basis.z * (l * 0.5 + 0.1) * s
		var apex: Vector3 = e + basis.y * rise
		for t in [-1.0, 1.0]:
			lm.beam(stone_key, e + basis.x * (w * 0.5 + over * 0.5) * t, apex, 0.7, 0.45, basis.z)

## Cover-tile ridges on a gable roof laid by `roof` / LandmarkMesh.gable
## (same c, w, l, rise, basis, over): a rounded cover tile down each
## joint every `pitch` metres on both slopes, the ridge cap, and an
## antefix at each eave end; `akroteria` adds the apex and corner
## ornaments at both gables.
static func roof_tiles(lm: LandmarkMesh, key: String, c: Vector3, w: float, l: float, rise: float,
		basis: Basis = Basis(), over: float = 0.3, pitch: float = 0.7, akroteria: bool = false) -> void:
	var n := maxi(int(l / pitch), 2)
	var hx := basis.x * (w * 0.5 + over)
	var up := basis.y * rise
	var tw := clampf(pitch * 0.25, 0.08, 0.3)
	for i in n:
		var z := basis.z * (-l * 0.5 + l * (float(i) + 0.5) / float(n))
		for s in [-1.0, 1.0]:
			var eave: Vector3 = c + hx * float(s) + z
			lm.beam(key, eave + basis.y * 0.04, c + up + z + basis.y * 0.04, tw, tw * 0.7)
			lm.box(key, eave + basis.y * tw * 0.8, Vector3(tw * 1.6, tw * 2.2, tw * 0.5),
				basis * Basis(Vector3.UP, PI * 0.5), 0.0)
	lm.beam(key, c + up - basis.z * l * 0.5 + basis.y * 0.06, c + up + basis.z * l * 0.5 + basis.y * 0.06,
		tw * 1.6, tw * 1.2)
	if akroteria:
		for s in [-1.0, 1.0]:
			var e: Vector3 = c + basis.z * (l * 0.5 + 0.1) * float(s)
			lm.box(key, e + up + basis.y * rise * 0.18, Vector3(rise * 0.3, rise * 0.36, 0.15), basis, 0.0)
			for t in [-1.0, 1.0]:
				lm.box(key, e + basis.x * (w * 0.5 + over * 0.5) * float(t) + basis.y * rise * 0.12,
					Vector3(rise * 0.2, rise * 0.24, 0.15), basis, 0.0)

## `n` small boxes (triglyphs and the like) evenly from a to b.
static func row_boxes(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int,
		size: Vector3, basis: Basis = Basis()) -> void:
	for i in n:
		lm.box(key, a.lerp(b, float(i) / float(maxi(n - 1, 1))), size, basis)

## Wall with a semicircular opening of radius r centred on cx: spandrel
## faces up to top_y on both planes (z0 front, z1 back) and the soffit.
static func arch_wall(lm: LandmarkMesh, key: String, cx: float, spring_y: float, r: float,
		top_y: float, z0: float, z1: float) -> void:
	var prev := Vector3.ZERO
	for k in 11:
		var a := PI * (1.0 - float(k) / 10.0)
		var p := Vector3(cx + r * cos(a), spring_y + r * sin(a), 0)
		if k > 0:
			for z in [z0, z1]:
				var zz: float = z
				lm.quad(key, Vector3(prev.x, prev.y, zz), Vector3(p.x, p.y, zz),
					Vector3(p.x, top_y, zz), Vector3(prev.x, top_y, zz),
					Vector3(0, 0, signf(zz - (z0 + z1) * 0.5)))
			var inward := Vector3(cx - p.x, spring_y - p.y, 0).normalized()
			lm.quad(key, Vector3(prev.x, prev.y, z0), Vector3(p.x, p.y, z0),
				Vector3(p.x, p.y, z1), Vector3(prev.x, prev.y, z1), inward)
		prev = p

# --- Seating ----------------------------------------------------------

## Tiers on a circular arc about c (angles in radians, direction
## (cos a, sin a) in XZ): `rows` tiers from radius r0, each `depth` deep
## and `rise` higher than the one before, the first topping out at
## y0 + rise. Each tier is a prism running down to base_y.
static func cavea(lm: LandmarkMesh, key: String, c: Vector3, r0: float, rows: int,
		depth: float, rise: float, a0: float, a1: float, y0: float, base_y: float) -> void:
	var r_end := r0 + depth * float(rows)
	var segs := maxi(int(ceil(absf(a1 - a0) * r_end / 2.5)), 3)
	for k in rows:
		var ri := r0 + depth * float(k)
		var ro := ri + depth
		var poly := PackedVector2Array()
		for i in segs + 1:
			var a := lerpf(a0, a1, float(i) / float(segs))
			poly.append(Vector2(c.x + cos(a) * ro, c.z + sin(a) * ro))
		for i in range(segs, -1, -1):
			var a := lerpf(a0, a1, float(i) / float(segs))
			poly.append(Vector2(c.x + cos(a) * ri, c.z + sin(a) * ri))
		lm.poly_prism(key, poly, base_y, y0 + rise * float(k + 1))

## Sloped stair strip between two radii on a cavea aisle (centre angle
## `am`, half-width `da` radians), rising from y_in to y_out.
static func aisle(lm: LandmarkMesh, key: String, c: Vector3, am: float, da: float,
		r_in: float, r_out: float, y_in: float, y_out: float) -> void:
	lm.quad(key, c + Vector3(cos(am - da) * r_in, y_in, sin(am - da) * r_in),
		c + Vector3(cos(am + da) * r_in, y_in, sin(am + da) * r_in),
		c + Vector3(cos(am + da) * r_out, y_out, sin(am + da) * r_out),
		c + Vector3(cos(am - da) * r_out, y_out, sin(am - da) * r_out), Vector3.UP)

## Stair up a radial aisle (centre angle `am`, `gap` radians wide): two
## steps per seat row (a half-height step on the front half of every
## row) as in Greek theatres, each as wide as the aisle at its radius
## (or a fixed `width` for a straight stair).
static func aisle_steps(lm: LandmarkMesh, key: String, c: Vector3, am: float, gap: float, r0: float,
		rows: int, depth: float, rise: float, y0: float, width: float = 0.0) -> void:
	var d := Vector3(cos(am), 0, sin(am))
	var b := Basis(d, Vector3.UP, d.cross(Vector3.UP))
	for k in rows:
		var y := y0 + rise * float(k)
		for half in 2:
			var r := r0 + depth * (float(k) + 0.25 + 0.5 * float(half))
			var hh := rise * (0.5 + 0.5 * float(half))
			lm.box(key, c + d * r + Vector3(0, y + hh * 0.5 - rise * 0.25, 0),
				Vector3(depth * 0.5, hh + rise * 0.5, width if width > 0.0 else gap * r + 0.02), b, 0.0)

## A cavea cut into `n` wedges by radial stair aisles `gap` radians wide,
## each aisle a stair in `stair_key`.
static func cavea_wedges(lm: LandmarkMesh, key: String, stair_key: String, c: Vector3,
		r0: float, rows: int, depth: float, rise: float, a0: float, a1: float, y0: float,
		base_y: float, n: int, gap: float) -> void:
	var span := (a1 - a0 - gap * float(n - 1)) / float(n)
	for i in n:
		var w0 := a0 + (span + gap) * float(i)
		cavea(lm, key, c, r0, rows, depth, rise, w0, w0 + span, y0, base_y)
		if i < n - 1:
			var am := w0 + span + gap * 0.5
			aisle_steps(lm, stair_key, c, am, gap, r0, rows, depth, rise, y0)

## Annular band of a horseshoe (two parallel straights from z_open back
## to z_c, then a semicircle round the centre (0, z_c) toward -Z), between
## half-widths r_in and r_out, as a prism from y0 to y1.
static func u_band(lm: LandmarkMesh, key: String, z_open: float, z_c: float, r_in: float,
		r_out: float, y0: float, y1: float, arc_segs: int = 24) -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(-r_out, z_open))
	for i in range(0, arc_segs + 1):
		var t := PI + PI * float(i) / float(arc_segs)
		poly.append(Vector2(r_out * cos(t), z_c + r_out * sin(t)))
	poly.append(Vector2(r_out, z_open))
	poly.append(Vector2(r_in, z_open))
	for i in range(arc_segs, -1, -1):
		var t := PI + PI * float(i) / float(arc_segs)
		poly.append(Vector2(r_in * cos(t), z_c + r_in * sin(t)))
	poly.append(Vector2(-r_in, z_open))
	lm.poly_prism(key, poly, y0, y1)

## Stadium tiers: `rows` horseshoe bands of width `depth` from half-width
## r0, each `rise` higher than the one before (first top at y0 + rise).
static func u_rows(lm: LandmarkMesh, key: String, z_open: float, z_c: float, r0: float,
		rows: int, depth: float, rise: float, y0: float, base_y: float, arc_segs: int = 24) -> void:
	for k in rows:
		var ri := r0 + depth * float(k)
		u_band(lm, key, z_open, z_c, ri, ri + depth, base_y, y0 + rise * float(k + 1), arc_segs)
