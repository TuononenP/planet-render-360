class_name LandmarkDetail
extends RefCounted

## Architectural detail kits for landmark models, in true metres on
## LandmarkMesh: the parts that make a massing model read as a building
## up close. Like LandmarkKits, every kit takes material KEYS registered
## by the caller (lm.use) and builds from `base` upward.
##   column       - classical column: base mouldings, entasis, flutes,
##                  Doric / Ionic / Corinthian / Tuscan capital
##   colonnade    - a row of columns with an entablature
##   cornice      - a moulded cornice (with dentils) along an edge
##   balustrade   - plinth, vase balusters and handrail along an edge
##   window       - a framed window: architrave, sill, head, glazing
##                  bars, square or round-arched
##   pierced_face - a wall skin laid over a mass face, with real window
##                  openings: reveals in depth and glass at the back
##   arch         - a moulded round arch (archivolt) over an opening

## Classical column of height h (base to top of the abacus), lower shaft
## radius r. order: "doric", "ionic", "corinthian" or "tuscan"; flutes 0
## for a plain shaft (Doric 20, Ionic and Corinthian 24 in practice).
## `radial` is the lathe segment count of the capital and base; lower it
## (about 10) for a colonnade seen from far away.
static func column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		order: String = "doric", flutes: int = 20, radial: int = 20) -> void:
	var cap_h := r * (0.9 if order == "doric" or order == "tuscan" else (1.4 if order == "ionic" else 2.4))
	var base_h := 0.0 if order == "doric" else r * 0.9
	if base_h > 0.0:
		# Attic base: plinth, torus, scotia, torus.
		lm.box(key, base + Vector3(0, base_h * 0.15, 0), Vector3(r * 2.7, base_h * 0.3, r * 2.7))
		lm.lathe(key, base + Vector3(0, base_h * 0.3, 0), PackedVector2Array([Vector2(r * 1.3, 0),
			Vector2(r * 1.36, base_h * 0.12), Vector2(r * 1.3, base_h * 0.25), Vector2(r * 1.12, base_h * 0.35),
			Vector2(r * 1.08, base_h * 0.45), Vector2(r * 1.16, base_h * 0.55), Vector2(r * 1.18, base_h * 0.62),
			Vector2(r * 1.06, base_h * 0.7)]), radial + 4)
	var shaft_h := h - cap_h - base_h
	var sb := base + Vector3(0, base_h, 0)
	if flutes > 0:
		_fluted_shaft(lm, key, sb, r, shaft_h, flutes)
	else:
		lm.lathe(key, sb, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.99, shaft_h * 0.33),
			Vector2(r * 0.93, shaft_h * 0.7), Vector2(r * 0.83, shaft_h)]), radial)
	var cb := sb + Vector3(0, shaft_h, 0)
	var ra := r * 0.83
	match order:
		"ionic":
			lm.lathe(key, cb, PackedVector2Array([Vector2(ra, 0), Vector2(ra * 1.1, cap_h * 0.12),
				Vector2(ra * 1.15, cap_h * 0.3)]), radial)
			# Volutes: a scroll each side, front and back, spiralling in.
			for side in [-1.0, 1.0]:
				_volute(lm, key, cb + Vector3(float(side) * r * 1.05, cap_h * 0.32, 0), r * 0.42, float(side))
			lm.box(key, cb + Vector3(0, cap_h * 0.55, 0), Vector3(r * 2.6, cap_h * 0.3, r * 1.9))
			lm.box(key, cb + Vector3(0, cap_h * 0.85, 0), Vector3(r * 2.5, cap_h * 0.3, r * 2.5))
		"corinthian":
			lm.lathe(key, cb, PackedVector2Array([Vector2(ra, 0), Vector2(ra * 1.0, cap_h * 0.3),
				Vector2(ra * 1.12, cap_h * 0.6), Vector2(ra * 1.35, cap_h * 0.84)]), radial)
			# Two tiers of acanthus leaves curling out, and corner volutes.
			for tier in 2:
				for i in 8:
					var a := TAU * (float(i) + 0.5 * tier) / 8.0
					var d := Vector3(cos(a), 0, sin(a))
					var lb := cb + d * ra * 0.95 + Vector3(0, cap_h * 0.32 * tier, 0)
					var lt := lb + d * r * 0.3 + Vector3(0, cap_h * 0.4, 0)
					lm.beam(key, lb, lt, r * 0.42, r * 0.1, d.cross(Vector3.UP))
					lm.beam(key, lt, lt + d * r * 0.15 - Vector3(0, cap_h * 0.08, 0), r * 0.34, r * 0.08,
						d.cross(Vector3.UP))
			for i in 4:
				var a := TAU * (float(i) + 0.5) / 4.0
				var d := Vector3(cos(a), 0, sin(a))
				lm.beam(key, cb + d * ra + Vector3(0, cap_h * 0.6, 0),
					cb + d * r * 1.55 + Vector3(0, cap_h * 0.86, 0), r * 0.18)
			lm.box(key, cb + Vector3(0, cap_h * 0.92, 0), Vector3(r * 2.9, cap_h * 0.16, r * 2.9))
		_:
			# Doric / Tuscan: necking rings, echinus, square abacus.
			lm.frustum(key, cb, ra * 1.04, ra * 1.04, cap_h * 0.12, radial)
			lm.lathe(key, cb + Vector3(0, cap_h * 0.15, 0), PackedVector2Array([Vector2(ra, 0),
				Vector2(ra * 1.2, cap_h * 0.2), Vector2(ra * 1.45, cap_h * 0.45),
				Vector2(ra * 1.5, cap_h * 0.55)]), radial)
			lm.box(key, cb + Vector3(0, cap_h * 0.85, 0), Vector3(r * 2.5, cap_h * 0.3, r * 2.5))

## Shaft with entasis and `n` concave flutes, as a grid of rings.
static func _fluted_shaft(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, n: int) -> void:
	var per := 4
	var cols := n * per
	var rows: Array = []
	var levels := [0.0, 0.08, 0.33, 0.6, 0.85, 1.0]
	for t in levels:
		var y := float(t) * h
		# Entasis: full to a third, then a gentle swell-and-taper to 0.83 r.
		var rr := r if t <= 0.33 else lerpf(r, r * 0.83, pow((float(t) - 0.33) / 0.67, 1.3))
		var ring := PackedVector3Array()
		for i in cols + 1:
			var a := TAU * float(i) / float(cols)
			var f := float(i % per) / float(per)
			var depth := sin(PI * f) * rr * 0.045
			ring.append(base + Vector3(cos(a) * (rr - depth), y, sin(a) * (rr - depth)))
		rows.append(ring)
	lm.grid(key, rows, base + Vector3(0, h * 0.5, 0), true)
	lm.disc(key, base + Vector3(0, h, 0), Vector3.UP, r * 0.83, 16)

## One Ionic scroll pair (front and back) at `c`, radius vr, unrolling
## outward on `side`.
static func _volute(lm: LandmarkMesh, key: String, c: Vector3, vr: float, side: float) -> void:
	for face in [-1.0, 1.0]:
		var z := float(face) * vr * 1.6
		var prev := c + Vector3(-side * vr, vr, z)
		for i in 14:
			var t := float(i + 1) / 14.0
			var a := PI * 0.5 + t * TAU * 1.25 * side
			var rr := vr * (1.0 - t * 0.75)
			var p := c + Vector3(cos(a) * rr * side * -1.0, sin(a) * rr, z)
			lm.beam(key, prev, p, vr * 0.22 * (1.0 - t * 0.5), vr * 0.3)
			prev = p
		lm.frustum(key, c + Vector3(0, -vr * 0.15, -vr * 1.6), vr * 0.5, vr * 0.5, 0.01, 10)
	# The scroll's cushion, front to back.
	lm.beam(key, c + Vector3(0, vr * 0.3, -vr * 1.6), c + Vector3(0, vr * 0.3, vr * 1.6), vr * 1.3, vr * 1.1)

## Columns from `a` to `b` (both column centres, at the base level),
## `count` of them, with an architrave, frieze and cornice on top.
static func colonnade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, count: int,
		r: float, h: float, order: String = "doric", flutes: int = 20, entab_key: String = "") -> void:
	var ek := key if entab_key == "" else entab_key
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		column(lm, key, a.lerp(b, t), r, h, order, flutes)
	var dir := (b - a).normalized()
	var out := dir.cross(Vector3.UP).normalized()
	var top := Vector3(0, h, 0)
	var ext := dir * r * 1.4
	var arch_h := r * 1.3
	var mid := (a + b) * 0.5 + top
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var run := a.distance_to(b) + r * 2.8
	lm.box(ek, mid + Vector3(0, arch_h * 0.5, 0), Vector3(run, arch_h, r * 2.3), basis)
	lm.box(ek, mid + Vector3(0, arch_h * 1.5, 0), Vector3(run, arch_h, r * 2.1), basis)
	for s in [-1.0, 1.0]:
		cornice(lm, ek, a - ext + top + Vector3(0, arch_h * 2.0, 0) + out * r * 1.05 * float(s),
			b + ext + top + Vector3(0, arch_h * 2.0, 0) + out * r * 1.05 * float(s),
			out * float(s), r * 0.9, true)

## Moulded cornice along a-b (the wall's top edge, face line), projecting
## along `out`, `h` tall: bed moulding, dentils, corona, cyma.
static func cornice(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, h: float,
		dentils: bool = true) -> void:
	var o := out.normalized()
	var prof := [[0.0, 0.0], [0.12, 0.08], [0.18, 0.22], [0.2, 0.3], [0.55, 0.32], [0.62, 0.55],
		[0.6, 0.62], [0.72, 0.7], [0.9, 0.86], [1.0, 1.0], [0.0, 1.0]]
	var rows: Array = []
	for q in prof:
		var off := o * float(q[0]) * h + Vector3(0, float(q[1]) * h, 0)
		rows.append(PackedVector3Array([a + off, b + off]))
	lm.grid(key, rows, o + Vector3.UP * 0.2)
	if dentils:
		var dl := a.distance_to(b)
		var step := h * 0.32
		var dir := (b - a).normalized()
		var n := int(dl / step)
		var basis := Basis(dir, Vector3.UP, o)
		for i in n:
			var p := a + dir * (step * (float(i) + 0.5)) + o * h * 0.28 + Vector3(0, h * 0.42, 0)
			lm.box(key, p, Vector3(step * 0.55, h * 0.16, h * 0.2), basis, 0.0)

## Balustrade along a-b on the level of a and b: plinth, lathed vase
## balusters (`radial` segments each), handrail, with a square pedestal
## every `bay` metres.
static func balustrade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.0,
		bay: float = 4.0, radial: int = 8) -> void:
	var dir := (b - a).normalized()
	var dl := a.distance_to(b)
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	var w := h * 0.22
	lm.box(key, mid + Vector3(0, h * 0.06, 0), Vector3(dl, h * 0.12, w * 1.2), basis)
	lm.box(key, mid + Vector3(0, h * 0.93, 0), Vector3(dl, h * 0.14, w * 1.35), basis)
	var vase := PackedVector2Array([Vector2(w * 0.32, 0), Vector2(w * 0.22, h * 0.08),
		Vector2(w * 0.45, h * 0.3), Vector2(w * 0.25, h * 0.55), Vector2(w * 0.16, h * 0.64),
		Vector2(w * 0.32, h * 0.74)])
	var pitch := h * 0.32
	var n := int(dl / pitch)
	var piers := maxi(int(dl / bay), 1)
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		var slot := fmod(t * piers, 1.0)
		if slot < 0.06 or slot > 0.94:
			continue
		lm.lathe(key, a.lerp(b, t) + Vector3(0, h * 0.12, 0), vase, radial)
	for i in piers + 1:
		lm.box(key, a.lerp(b, float(i) / float(piers)) + Vector3(0, h * 0.5, 0),
			Vector3(w * 1.6, h, w * 1.6), basis)

## A framed window of opening w x h (centre `c` on the wall face facing
## `normal`): architrave surround, projecting sill, a cornice head (or a
## round arch when `arched`), glass set back in the frame, glazing bars.
static func window(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, normal: Vector3,
		w: float, h: float, arched: bool = false, depth: float = 0.25) -> void:
	var n := normal.normalized()
	var right := Vector3.UP.cross(n).normalized()
	var basis := Basis(right, Vector3.UP, n)
	var fw := clampf(w * 0.14, 0.12, 0.6)
	var oh := h - (w * 0.5 if arched else 0.0)
	var mid := c + n * depth * 0.5
	# Jambs.
	for s in [-1.0, 1.0]:
		lm.box(frame, mid + right * (w * 0.5 + fw * 0.5) * float(s) - Vector3(0, (h - oh) * 0.5, 0),
			Vector3(fw, oh, depth), basis)
	var base_y := c.y - h * 0.5
	# Sill and its apron; on a ground-floor window neither reaches below
	# the model's base (y = 0).
	var floor_y := 0.0 if base_y >= 0.0 else -INF
	var sill_lo := maxf(base_y - fw * 0.6, floor_y)
	if base_y - sill_lo > 0.02:
		lm.box(frame, Vector3(c.x, (sill_lo + base_y) * 0.5, c.z) + n * depth * 0.75,
			Vector3(w + fw * 3.0, base_y - sill_lo, depth * 1.5), basis)
	var apron_lo := maxf(base_y - fw * 1.8, floor_y)
	var apron_hi := maxf(base_y - fw * 0.6, apron_lo)
	if apron_hi - apron_lo > 0.02:
		lm.box(frame, Vector3(c.x, (apron_lo + apron_hi) * 0.5, c.z) + n * depth * 0.35,
			Vector3(w * 0.7, apron_hi - apron_lo, depth * 0.7), basis)
	var top_y := base_y + oh
	if arched:
		var ctr := Vector3(c.x, top_y, c.z) + n * depth * 0.5
		var prev := ctr + right * (w * 0.5 + fw * 0.5)
		for i in 12:
			var t := PI * float(i + 1) / 12.0
			var p := ctr + right * cos(t) * (w * 0.5 + fw * 0.5) + Vector3(0, sin(t) * (w * 0.5 + fw * 0.5), 0)
			lm.beam(frame, prev, p, fw * 1.05, depth, n)
			prev = p
		# Keystone.
		lm.box(frame, ctr + Vector3(0, w * 0.5 + fw * 0.5, 0) + n * depth * 0.2,
			Vector3(fw * 1.2, fw * 1.8, depth * 1.2), basis)
	else:
		lm.box(frame, Vector3(c.x, top_y + fw * 0.5, c.z) + n * depth * 0.5,
			Vector3(w + fw * 2.0, fw, depth), basis)
		cornice(lm, frame, Vector3(c.x, top_y + fw, c.z) - right * (w * 0.5 + fw * 1.4) + n * depth,
			Vector3(c.x, top_y + fw, c.z) + right * (w * 0.5 + fw * 1.4) + n * depth, n, fw * 1.2, false)
	# Glass set back in the frame, then glazing bars.
	var gc := Vector3(c.x, base_y + oh * 0.5, c.z) + n * 0.02
	lm.quad(glass, gc - right * w * 0.5 - Vector3(0, oh * 0.5, 0), gc + right * w * 0.5 - Vector3(0, oh * 0.5, 0),
		gc + right * w * 0.5 + Vector3(0, oh * 0.5, 0), gc - right * w * 0.5 + Vector3(0, oh * 0.5, 0), n)
	if arched:
		var ac := Vector3(c.x, top_y, c.z) + n * 0.02
		for i in 10:
			var t0 := PI * float(i) / 10.0
			var t1 := PI * float(i + 1) / 10.0
			lm.tri(glass, ac, ac + (right * cos(t0) + Vector3.UP * sin(t0)) * w * 0.5,
				ac + (right * cos(t1) + Vector3.UP * sin(t1)) * w * 0.5, n, n, n,
				Vector2.ZERO, Vector2(cos(t0), sin(t0)) * w * 0.5, Vector2(cos(t1), sin(t1)) * w * 0.5)
	var bar := clampf(w * 0.04, 0.04, 0.12)
	var bc := Vector3(c.x, base_y, c.z) + n * 0.06
	lm.box(frame, bc + Vector3(0, h * 0.5, 0), Vector3(bar, h, bar), basis, 0.0)
	for k in 2:
		lm.box(frame, bc + Vector3(0, oh * (float(k) + 1.0) / 3.0, 0), Vector3(w, bar, bar), basis, 0.0)

## A wall skin `depth` thick laid over a mass face, with a grid of real
## window openings: front face with the holes cut, reveals (jambs, head,
## sill) running back to the mass face, glass just in front of it, and
## returns at the skin's edges. `origin` is the bottom-left of the area
## on the mass face, `right` and `normal` unit vectors, the area w x h;
## openings `win` (w, h) in `cols` x `rows` bays, the first sill at
## `sill` above origin and storeys `storey` apart.
static func pierced_face(lm: LandmarkMesh, wall: String, glass: String, origin: Vector3, right: Vector3,
		normal: Vector3, w: float, h: float, cols: int, rows: int, win: Vector2, sill: float,
		storey: float, depth: float = 0.35) -> void:
	var r := right.normalized()
	var n := normal.normalized()
	var u := Vector3.UP
	var pitch := w / float(cols)
	var x0s: Array[float] = []
	for i in cols:
		x0s.append(pitch * (float(i) + 0.5) - win.x * 0.5)
	var ys: Array[float] = []
	for j in rows:
		var y := sill + storey * float(j)
		if y + win.y <= h - 0.05:
			ys.append(y)
	var P := func(x: float, y: float, d: float) -> Vector3:
		return origin + r * x + u * y + n * d
	# Front face: bands between rows, piers between windows in each row.
	var band_y := 0.0
	for y in ys:
		_wall_rect(lm, wall, P, 0.0, band_y, w, y - band_y, depth, n)
		var px := 0.0
		for x in x0s:
			_wall_rect(lm, wall, P, px, y, x - px, win.y, depth, n)
			px = x + win.x
		_wall_rect(lm, wall, P, px, y, w - px, win.y, depth, n)
		band_y = y + win.y
	_wall_rect(lm, wall, P, 0.0, band_y, w, h - band_y, depth, n)
	# Reveals and glass.
	for y in ys:
		for x in x0s:
			var x1 := x + win.x
			var y1 := y + win.y
			lm.quad(wall, P.call(x, y, depth), P.call(x, y, 0.0), P.call(x, y1, 0.0), P.call(x, y1, depth), r)
			lm.quad(wall, P.call(x1, y, 0.0), P.call(x1, y, depth), P.call(x1, y1, depth), P.call(x1, y1, 0.0), -r)
			lm.quad(wall, P.call(x, y1, depth), P.call(x, y1, 0.0), P.call(x1, y1, 0.0), P.call(x1, y1, depth), -u)
			lm.quad(wall, P.call(x, y, 0.0), P.call(x, y, depth), P.call(x1, y, depth), P.call(x1, y, 0.0), u)
			lm.quad(glass, P.call(x, y, 0.03), P.call(x1, y, 0.03), P.call(x1, y1, 0.03), P.call(x, y1, 0.03), n)
	# Returns at the skin's edges.
	lm.quad(wall, P.call(0.0, 0.0, 0.0), P.call(0.0, 0.0, depth), P.call(0.0, h, depth), P.call(0.0, h, 0.0), -r)
	lm.quad(wall, P.call(w, 0.0, depth), P.call(w, 0.0, 0.0), P.call(w, h, 0.0), P.call(w, h, depth), r)
	lm.quad(wall, P.call(0.0, h, depth), P.call(w, h, depth), P.call(w, h, 0.0), P.call(0.0, h, 0.0), u)

static func _wall_rect(lm: LandmarkMesh, wall: String, P: Callable, x: float, y: float, w: float,
		h: float, depth: float, n: Vector3) -> void:
	if w <= 0.001 or h <= 0.001:
		return
	lm.quad(wall, P.call(x, y, depth), P.call(x + w, y, depth), P.call(x + w, y + h, depth),
		P.call(x, y + h, depth), n, Vector2(x, -y))

## Moulded round arch over an opening `span` wide whose springing line
## is at `c` (centre), on a wall facing `normal`: an archivolt of
## voussoirs (at most `max_segs`) with a projecting keystone.
static func arch(lm: LandmarkMesh, key: String, c: Vector3, normal: Vector3, span: float,
		band: float = -1.0, depth: float = 0.3, max_segs: int = 25) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var bw := band if band > 0.0 else clampf(span * 0.12, 0.2, 1.5)
	var rad := span * 0.5 + bw * 0.5
	var segs := clampi(int(PI * rad / maxf(bw * 0.8, 0.3)), mini(9, max_segs), max_segs)
	var basis := Basis(r, Vector3.UP, n)
	for i in segs:
		var t0 := PI * float(i) / float(segs)
		var t1 := PI * float(i + 1) / float(segs)
		var p0 := c + (r * cos(t0) + Vector3.UP * sin(t0)) * rad + n * depth * 0.5
		var p1 := c + (r * cos(t1) + Vector3.UP * sin(t1)) * rad + n * depth * 0.5
		var pm := (p0 + p1) * 0.5
		lm.box(key, pm, Vector3(p0.distance_to(p1) * 0.96, bw, depth),
			Basis((p1 - p0).normalized(), ((p1 + p0) * 0.5 - c - n * depth * 0.5).normalized(), n))
	lm.box(key, c + Vector3.UP * rad + n * depth * 0.6, Vector3(bw * 0.9, bw * 1.5, depth * 1.2), basis)
