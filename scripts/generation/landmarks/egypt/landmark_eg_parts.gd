class_name LandmarkEgParts
extends RefCounted

## Shared pieces of the Egypt batch in true metres on LandmarkMesh:
## battered towers and pylons with torus mouldings and cavetto cornices,
## papyrus columns, obelisks, seated colossi, sphinxes, Osiride figures
## and the stripped-course square pyramid. Temples build with the
## entrance toward +Z and the sanctuary toward -Z (the registry yaw_deg
## turns the model onto the real axis); y = 0 is the courtyard floor.

const OPEN := 0  # open papyrus (campaniform) capital
const BUD := 1  # closed papyrus bud capital
const PLAIN := 2  # sixteen-sided proto-Doric shaft
const BUNDLE := 3  # bundled papyrus: eight stems, a bundle of buds on top

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

## Round rod of radius r from `a` to `b` (`seg` sides, open ends): the
## torus roll moulding that edges every pylon and temple wall.
static func rod(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r: float, seg: int = 8) -> void:
	var axis := (b - a).normalized()
	var s := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var t := axis.cross(s)
	var ln := a.distance_to(b)
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var n0 := s * cos(a0) + t * sin(a0)
		var n1 := s * cos(a1) + t * sin(a1)
		var u0 := r * a0
		var u1 := r * a1
		lm.tri(key, a + n0 * r, a + n1 * r, b + n1 * r, n0, n1, n1, Vector2(u0, 0), Vector2(u1, 0),
			Vector2(u1, -ln))
		lm.tri(key, a + n0 * r, b + n1 * r, b + n0 * r, n0, n1, n0, Vector2(u0, 0), Vector2(u1, -ln),
			Vector2(u0, -ln))

## Egyptian cornice crowning a w x d top centred on `c` (its foot): a
## torus roll, the concave cavetto gorge flaring out by `proj` over `h`,
## and the flat fillet on top.
static func cavetto(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, h: float,
		proj: float) -> void:
	var tr := maxf(h * 0.12, 0.08)
	var corners: Array[Vector3] = []
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(c + Vector3(s.x * (w * 0.5 + tr * 0.4), tr, s.y * (d * 0.5 + tr * 0.4)))
	for i in 4:
		rod(lm, key, corners[i], corners[(i + 1) % 4], tr, 6)
	var steps := 5
	var hx := w * 0.5
	var hz := d * 0.5
	var y0 := tr * 2.0
	var gh := h - y0 - h * 0.12
	for side in 4:
		var rows: Array = []
		for k in steps + 1:
			var t := float(k) / float(steps)
			var o := proj * (1.0 - cos(t * PI * 0.5))
			var y := y0 + gh * sin(t * PI * 0.5)
			var ax := hx + o
			var az := hz + o
			var p0 := Vector3(-ax, y, -az)
			var p1 := Vector3(ax, y, -az)
			match side:
				1:
					p0 = Vector3(ax, y, -az)
					p1 = Vector3(ax, y, az)
				2:
					p0 = Vector3(ax, y, az)
					p1 = Vector3(-ax, y, az)
				3:
					p0 = Vector3(-ax, y, az)
					p1 = Vector3(-ax, y, -az)
			rows.append(PackedVector3Array([c + p0, c + p1]))
		lm.grid(key, rows, c + Vector3(0, y0, 0), true)
	lm.box(key, c + Vector3(0, h - h * 0.06, 0), Vector3(w + proj * 2.0, h * 0.12, d + proj * 2.0))

## Winged sun disc carved over a gateway on a face facing +Z: the disc
## between two uraei and the spread wings, `span` wide, centred on `c`.
static func winged_disc(lm: LandmarkMesh, key: String, c: Vector3, span: float) -> void:
	var r := span * 0.09
	rod(lm, key, c, c + Vector3(0, 0, 0.35), r, 12)
	lm.disc(key, c + Vector3(0, 0, 0.35), Vector3.BACK, r, 12)
	for s in [-1.0, 1.0]:
		for k in 3:
			var y := r * (0.5 - 0.45 * float(k))
			var ln := span * (0.42 - 0.06 * float(k))
			lm.box(key, c + Vector3(s * (r + ln * 0.5), y, 0.1), Vector3(ln, r * 0.38, 0.2), Basis(), 0.0)
		lm.box(key, c + Vector3(s * r * 0.8, -r * 0.6, 0.15), Vector3(r * 0.3, r * 1.2, 0.3), Basis(), 0.0)

## Pylon facing +Z centred on `c`: two battered towers (`w` wide in all,
## `d` thick, `h` high) edged with torus rolls under a cavetto cornice,
## `slots` recessed flagstaff grooves (`dark`) per tower in the front
## face, and the taller-than-wide gateway between them with its own
## cornice and winged disc over the open passage. `finished` false
## leaves the towers as the builders did at Karnak: rough, uncorniced.
static func pylon(lm: LandmarkMesh, key: String, dark: String, c: Vector3, w: float,
		h: float, d: float, gate: float, slots: int = 2, finished: bool = true) -> void:
	var tw := (w - gate) * 0.5
	var corn := h * 0.07 if finished else 0.0
	var body := h - corn
	var lean := body / 11.0
	var top_w := tw - lean
	var top_d := d - lean * 0.8
	var tr := clampf(h * 0.012, 0.15, 0.55)
	for s in [-1.0, 1.0]:
		var cx: float = c.x + s * (gate + tw) * 0.5
		var foot := Vector3(cx, c.y, c.z)
		taper(lm, key, foot, tw, d, top_w, top_d, body, true)
		if not finished:
			# Unfinished: the masons' rough bosses left on the face courses.
			for k in 9:
				var y := body * (0.08 + 0.1 * float(k))
				var wy := lerpf(tw, top_w, y / body)
				var zy := c.z + d * 0.5 - (d - top_d) * 0.5 * y / body
				lm.box(key, Vector3(cx, c.y + y, zy), Vector3(wy * 0.94, 0.5, 0.5), Basis(), 0.0)
			continue
		cavetto(lm, key, foot + Vector3(0, body, 0), top_w, top_d, corn, corn * 0.75)
		# Torus rolls up the four battered arrises.
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				rod(lm, key, foot + Vector3(sx * tw * 0.5, tr, sz * d * 0.5),
					foot + Vector3(sx * top_w * 0.5, body, sz * top_d * 0.5), tr, 6)
		# Flagstaff grooves with their clamp windows above, cut into the face.
		var zf := func(y: float) -> float:
			return c.z + d * 0.5 - (d - top_d) * 0.5 * y / body + 0.06
		for k in slots:
			var f := (float(k) + 0.5) / float(slots) - 0.5
			var gx := cx + f * tw * 0.7
			var gw := maxf(tw * 0.045, 0.5)
			var gh := body * 0.78
			lm.beam(dark, Vector3(gx, c.y, zf.call(0.0)), Vector3(gx, c.y + gh, zf.call(gh)), gw, 0.12,
				Vector3.RIGHT)
			var wy := gh + body * 0.06
			lm.box(dark, Vector3(gx, c.y + wy, zf.call(wy)), Vector3(gw * 0.9, gw * 1.2, 0.12), Basis(), 0.0)
		# Small windows lighting the stairs inside the tower.
		for k in 2:
			var wy := body * (0.62 + 0.14 * float(k))
			lm.box(dark, Vector3(cx - s * tw * 0.12, c.y + wy, zf.call(wy)), Vector3(0.6, 0.9, 0.12),
				Basis(), 0.0)
	# Gateway: jamb faces proud of the towers, lintel, cornice, winged disc.
	var gate_h := h * 0.58
	var gd := d + 1.2
	for s in [-1.0, 1.0]:
		lm.box(key, c + Vector3(s * (gate * 0.5 + 0.8), gate_h * 0.5, 0), Vector3(1.6, gate_h, gd))
	lm.box(key, c + Vector3(0, gate_h - h * 0.08, 0), Vector3(gate + 3.2, h * 0.16, gd))
	cavetto(lm, key, c + Vector3(0, gate_h, 0), gate + 3.2, gd, h * 0.06, h * 0.04)
	winged_disc(lm, key, c + Vector3(0, gate_h - h * 0.08, gd * 0.5), gate * 0.9)

## Column of height h (base to abacus top) and lower shaft radius r: a
## round base, the shaft with its five binding bands under the capital
## (`kind` OPEN bell, BUD, BUNDLE of eight stems or a PLAIN sixteen-sided
## proto-Doric shaft) and the square abacus block.
static func column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		kind: int = BUD, seg: int = 12) -> void:
	var bh := r * 0.32
	lm.frustum(key, base, r * 1.4, r * 1.32, bh, seg)
	var b := base + Vector3(0, bh, 0)
	var ab := r * (0.42 if kind == OPEN else 0.5)
	var body := h - bh - ab
	var cap_y := body * (0.7 if kind == OPEN else 0.8)
	if kind == PLAIN:
		cap_y = body
		lm.lathe(key, b, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.88, body)]), 16, 1.0, 1.0,
			0.0, false, false)
		lm.box(key, b + Vector3(0, body + ab * 0.5, 0), Vector3(r * 2.0, ab, r * 2.0))
		return
	var neck := r * 0.84
	if kind == BUNDLE:
		for i in 8:
			var a := TAU * float(i) / 8.0
			var off := Vector3(cos(a), 0, sin(a)) * r * 0.62
			lm.lathe(key, b + off, PackedVector2Array([Vector2(r * 0.3, 0), Vector2(r * 0.42, cap_y * 0.08),
				Vector2(r * 0.4, cap_y * 0.5), Vector2(r * 0.33, cap_y)]), 6, 1.0, 1.0, a, true, false)
	else:
		lm.lathe(key, b, PackedVector2Array([Vector2(r * 0.86, 0), Vector2(r, cap_y * 0.07),
			Vector2(r, cap_y * 0.4), Vector2(neck, cap_y)]), seg, 1.0, 1.0, 0.0, true, false)
		# Sheathing leaves at the foot of the stem.
		for i in 6:
			var a := TAU * float(i) / 6.0
			var dd := Vector3(cos(a), 0, sin(a))
			lm.beam(key, b + dd * r * 0.9, b + dd * r * 0.97 + Vector3(0, cap_y * 0.08, 0), r * 0.5,
				r * 0.08, dd.cross(Vector3.UP))
	# Five binding bands.
	var band := r * 0.12
	for k in 5:
		lm.lathe(key, b + Vector3(0, cap_y - band * float(5 - k), 0),
			PackedVector2Array([Vector2(neck * 1.06, 0), Vector2(neck * 1.06, band * 0.8)]), seg, 1.0, 1.0,
			0.0, true, false)
	var cb := b + Vector3(0, cap_y, 0)
	var ch := body - cap_y
	match kind:
		OPEN:
			lm.lathe(key, cb, PackedVector2Array([Vector2(neck, 0), Vector2(neck * 1.05, ch * 0.2),
				Vector2(r * 1.25, ch * 0.5), Vector2(r * 1.62, ch * 0.82), Vector2(r * 1.75, ch * 0.96),
				Vector2(r * 1.7, ch)]), seg + 4)
			for i in 8:
				var a := TAU * (float(i) + 0.5) / 8.0
				var dd := Vector3(cos(a), 0, sin(a))
				lm.beam(key, cb + dd * neck * 1.02 + Vector3(0, ch * 0.08, 0),
					cb + dd * r * 1.72 + Vector3(0, ch * 0.9, 0), r * 0.16, r * 0.06, dd.cross(Vector3.UP))
			lm.box(key, cb + Vector3(0, ch + ab * 0.5, 0), Vector3(r * 1.45, ab, r * 1.45))
		BUNDLE:
			for i in 8:
				var a := TAU * float(i) / 8.0
				var off := Vector3(cos(a), 0, sin(a)) * r * 0.55
				lm.lathe(key, cb + off, PackedVector2Array([Vector2(r * 0.3, 0), Vector2(r * 0.45, ch * 0.45),
					Vector2(r * 0.36, ch * 0.8), Vector2(r * 0.26, ch)]), 6, 1.0, 1.0, a, true, false)
			lm.box(key, cb + Vector3(0, ch + ab * 0.5, 0), Vector3(r * 1.5, ab, r * 1.5))
		_:
			lm.lathe(key, cb, PackedVector2Array([Vector2(neck, 0), Vector2(r * 1.12, ch * 0.3),
				Vector2(r * 1.15, ch * 0.5), Vector2(r * 1.0, ch * 0.78), Vector2(r * 0.85, ch)]), seg)
			for i in 6:
				var a := TAU * float(i) / 6.0
				var dd := Vector3(cos(a), 0, sin(a))
				lm.beam(key, cb + dd * neck + Vector3(0, ch * 0.05, 0), cb + dd * r * 1.12 + Vector3(0, ch * 0.4, 0),
					r * 0.18, r * 0.06, dd.cross(Vector3.UP))
			lm.box(key, cb + Vector3(0, ch + ab * 0.5, 0), Vector3(r * 1.8, ab, r * 1.8))

## Row of `n` columns from `a` to `b` (base positions), spaced evenly.
static func colonnade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, r: float,
		h: float, kind: int = BUD, seg: int = 12) -> void:
	for i in n:
		column(lm, key, a.lerp(b, float(i) / maxf(n - 1, 1)), r, h, kind, seg)

## Obelisk of height h on `base`: a two-step plinth, the battered shaft
## with its three sunk columns of hieroglyphs on each face (`dark`
## strips when set) and the pyramidion (`tip`).
static func obelisk(lm: LandmarkMesh, key: String, tip: String, base: Vector3, w: float,
		h: float, dark: String = "") -> void:
	var tip_h := w * 0.95
	var plinth := w * 0.45
	lm.box(key, base + Vector3(0, plinth * 0.3, 0), Vector3(w * 2.2, plinth * 0.6, w * 2.2))
	lm.box(key, base + Vector3(0, plinth * 0.8, 0), Vector3(w * 1.7, plinth * 0.4, w * 1.7))
	var sh := h - tip_h - plinth
	taper(lm, key, base + Vector3(0, plinth, 0), w, w, w * 0.64, w * 0.64, sh, false)
	lm.spire(tip, base + Vector3(0, h - tip_h, 0), w * 0.32, tip_h, 0.0, 4)
	if dark == "":
		return
	for f in 4:
		var n := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(n)
		for k in [-1.0, 0.0, 1.0]:
			var p0: Vector3 = base + Vector3(0, plinth + sh * 0.04, 0) + n * (w * 0.5 + 0.01) + rt * k * w * 0.22
			var p1: Vector3 = base + Vector3(0, plinth + sh * 0.94, 0) + n * (w * 0.32 * 1.0 + 0.01) + rt * k * w * 0.15
			lm.beam(dark, p0, p1, w * 0.06, 0.02, rt)

## Seated king facing +Z, `h` tall to the top of the crown (`crown`
## false: the nemes is the top): throne with back pillar, feet, shins,
## thighs and kilt, hands flat on the knees, torso, shoulders, the nemes
## headdress with its lappets, false beard and the double crown.
static func colossus(lm: LandmarkMesh, key: String, c: Vector3, h: float,
		crown: bool = true) -> void:
	var u := h / (1.06 if crown else 0.89)
	var w := u * 0.36
	# Throne and the back pillar.
	lm.box(key, c + Vector3(0, u * 0.17, -u * 0.06), Vector3(w * 1.05, u * 0.34, u * 0.4))
	lm.box(key, c + Vector3(0, u * 0.42, -u * 0.24), Vector3(w * 0.6, u * 0.52 if crown else u * 0.44, u * 0.08))
	for s in [-1.0, 1.0]:
		var x: float = s * w * 0.24
		lm.box(key, c + Vector3(x, u * 0.03, u * 0.22), Vector3(w * 0.3, u * 0.06, u * 0.16))
		lm.box(key, c + Vector3(x, u * 0.19, u * 0.18), Vector3(w * 0.27, u * 0.28, u * 0.12))
		lm.lathe(key, c + Vector3(x, u * 0.33, u * 0.2), PackedVector2Array([Vector2(w * 0.14, 0),
			Vector2(w * 0.16, u * 0.02), Vector2(w * 0.1, u * 0.04)]), 8)
		lm.box(key, c + Vector3(x, u * 0.38, u * 0.06), Vector3(w * 0.3, u * 0.09, u * 0.32))
		lm.box(key, c + Vector3(x, u * 0.44, u * 0.15), Vector3(w * 0.2, u * 0.03, u * 0.11))
		lm.beam(key, c + Vector3(s * w * 0.42, u * 0.44, -u * 0.04), c + Vector3(x * 1.2, u * 0.45, u * 0.12),
			u * 0.06, u * 0.06)
		lm.beam(key, c + Vector3(s * w * 0.4, u * 0.68, -u * 0.07), c + Vector3(s * w * 0.42, u * 0.45, -u * 0.04),
			u * 0.07, u * 0.07)
	lm.box(key, c + Vector3(0, u * 0.43, -u * 0.03), Vector3(w * 0.66, u * 0.05, u * 0.16))
	lm.lathe(key, c + Vector3(0, u * 0.42, -u * 0.07), PackedVector2Array([Vector2(w * 0.3, 0),
		Vector2(w * 0.32, u * 0.1), Vector2(w * 0.4, u * 0.22), Vector2(w * 0.44, u * 0.27),
		Vector2(w * 0.2, u * 0.31)]), 12, 1.0, 0.55)
	var hb := c + Vector3(0, u * 0.71, -u * 0.06)
	lm.frustum(key, hb, w * 0.1, w * 0.1, u * 0.04, 8)
	# Nemes headdress, face and beard.
	lm.lathe(key, hb + Vector3(0, u * 0.03, 0), PackedVector2Array([Vector2(w * 0.32, 0),
		Vector2(w * 0.28, u * 0.06), Vector2(w * 0.22, u * 0.11), Vector2(w * 0.15, u * 0.14),
		Vector2(0.0, u * 0.15)]), 10, 1.0, 0.9)
	lm.lathe(key, hb + Vector3(0, u * 0.04, u * 0.02), PackedVector2Array([Vector2(w * 0.12, 0),
		Vector2(w * 0.14, u * 0.04), Vector2(w * 0.12, u * 0.08), Vector2(0.0, u * 0.1)]), 10, 0.9, 1.0)
	for s in [-1.0, 1.0]:
		lm.box(key, hb + Vector3(s * w * 0.2, -u * 0.04, u * 0.03), Vector3(w * 0.14, u * 0.12, u * 0.03))
	lm.beam(key, hb + Vector3(0, u * 0.04, u * 0.06), hb + Vector3(0, -u * 0.02, u * 0.08), u * 0.025, u * 0.02)
	if crown:
		var cr := hb + Vector3(0, u * 0.17, 0)
		lm.lathe(key, cr, PackedVector2Array([Vector2(w * 0.17, 0), Vector2(w * 0.16, u * 0.05),
			Vector2(w * 0.11, u * 0.12), Vector2(w * 0.07, u * 0.16), Vector2(w * 0.04, u * 0.17),
			Vector2(0.0, u * 0.12 + u * 0.06)]), 10)

## Couchant sphinx on a plinth facing +Z, `ln` long: lion body and
## paws, the haunch, and a human head in nemes or (`ram`) a ram's head
## with curled horns, a small king figure between the paws.
static func sphinx(lm: LandmarkMesh, key: String, c: Vector3, ln: float, ram: bool = false,
		basis: Basis = Basis()) -> void:
	var P := func(v: Vector3) -> Vector3:
		return c + basis * v
	var s := ln
	lm.box(key, P.call(Vector3(0, s * 0.06, 0)), Vector3(s * 0.4, s * 0.12, s * 1.04), basis)
	lm.lathe(key, P.call(Vector3(0, s * 0.12, -s * 0.12)), PackedVector2Array([Vector2(s * 0.12, 0),
		Vector2(s * 0.14, s * 0.1), Vector2(s * 0.1, s * 0.2), Vector2(0.0, s * 0.22)]), 8, 1.0, 2.2)
	for x in [-1.0, 1.0]:
		lm.box(key, P.call(Vector3(x * s * 0.09, s * 0.15, s * 0.3)), Vector3(s * 0.08, s * 0.06, s * 0.3), basis)
	var hp: Vector3 = P.call(Vector3(0, s * 0.26, s * 0.13))
	if ram:
		lm.lathe(key, hp, PackedVector2Array([Vector2(s * 0.05, 0), Vector2(s * 0.07, s * 0.05),
			Vector2(s * 0.05, s * 0.1), Vector2(0.0, s * 0.11)]), 8, 1.0, 1.6)
		for x in [-1.0, 1.0]:
			rod(lm, key, hp + basis * Vector3(x * s * 0.04, s * 0.09, -s * 0.03),
				hp + basis * Vector3(x * s * 0.1, s * 0.05, s * 0.03), s * 0.025, 6)
	else:
		lm.lathe(key, hp, PackedVector2Array([Vector2(s * 0.09, 0), Vector2(s * 0.08, s * 0.06),
			Vector2(s * 0.05, s * 0.11), Vector2(0.0, s * 0.12)]), 8)
	lm.box(key, P.call(Vector3(0, s * 0.18, s * 0.42)), Vector3(s * 0.08, s * 0.12, s * 0.06), basis)

## Mummiform Osiride figure `h` tall facing +Z on `c`: wrapped body,
## crossed arms holding crook and flail, beard, and the white crown (or
## the double crown when `pschent`).
static func osiride(lm: LandmarkMesh, key: String, c: Vector3, h: float, pschent: bool = false) -> void:
	lm.lathe(key, c, PackedVector2Array([Vector2(h * 0.08, 0), Vector2(h * 0.09, h * 0.08),
		Vector2(h * 0.095, h * 0.35), Vector2(h * 0.12, h * 0.55), Vector2(h * 0.13, h * 0.66),
		Vector2(h * 0.06, h * 0.7)]), 10, 1.0, 0.7)
	for s in [-1.0, 1.0]:
		lm.beam(key, c + Vector3(s * h * 0.1, h * 0.62, h * 0.06), c + Vector3(-s * h * 0.06, h * 0.55, h * 0.1),
			h * 0.04, h * 0.035)
	lm.lathe(key, c + Vector3(0, h * 0.7, 0), PackedVector2Array([Vector2(h * 0.05, 0),
		Vector2(h * 0.06, h * 0.05), Vector2(h * 0.045, h * 0.1), Vector2(0.0, h * 0.11)]), 8)
	lm.beam(key, c + Vector3(0, h * 0.72, h * 0.04), c + Vector3(0, h * 0.66, h * 0.06), h * 0.02, h * 0.02)
	var cr := c + Vector3(0, h * 0.79, 0)
	if pschent:
		lm.frustum(key, cr, h * 0.06, h * 0.065, h * 0.06, 8)
	lm.lathe(key, cr, PackedVector2Array([Vector2(h * 0.05, 0), Vector2(h * 0.045, h * 0.12),
		Vector2(h * 0.025, h * 0.19), Vector2(0.0, h * 0.21)]), 8)

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

## Temple wall a-b crowned the Egyptian way: the plain wall, a torus
## roll along its top edges and a small cavetto coping.
static func temple_wall(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, h: float, t: float,
		y0: float = 0.0) -> void:
	var ch := clampf(h * 0.08, 0.5, 1.6)
	wall(lm, key, a, b, h - ch, t, y0)
	var dir := Vector3(b.x - a.x, 0, b.y - a.y)
	var ln := dir.length()
	dir /= ln
	var mid := Vector3((a.x + b.x) * 0.5, y0 + h - ch, (a.y + b.y) * 0.5)
	var basis := Basis(dir.cross(Vector3.UP), Vector3.UP, -dir)
	# A cavetto band on each long side, built along the wall axis.
	var tr := ch * 0.12
	var side := dir.cross(Vector3.UP).normalized()
	for s in [-1.0, 1.0]:
		var off: Vector3 = side * (t * 0.5 + tr * 0.3) * s
		rod(lm, key, mid - dir * ln * 0.5 + off + Vector3(0, tr, 0), mid + dir * ln * 0.5 + off + Vector3(0, tr, 0),
			tr, 6)
		var rows: Array = []
		for k in 5:
			var f := float(k) / 4.0
			var o: Vector3 = side * s * (t * 0.5 + ch * 0.55 * (1.0 - cos(f * PI * 0.5)))
			var y := Vector3(0, tr * 2.0 + (ch * 0.8 - tr * 2.0) * sin(f * PI * 0.5), 0)
			rows.append(PackedVector3Array([mid - dir * ln * 0.5 + o + y, mid + dir * ln * 0.5 + o + y]))
		lm.grid(key, rows, side * s + Vector3.UP * 0.3)
	lm.box(key, mid + Vector3(0, ch * 0.9, 0), Vector3(t + ch * 1.1, ch * 0.2, ln), basis)
