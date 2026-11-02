class_name RmAUtil
extends RefCounted

## Helpers shared by the ancient Rome landmark builders (true metres on
## LandmarkMesh): arched walls with real soffits, Roman columns, coffered
## barrel vaults, pediments, and ruined wall tops.

## Wall face along `right` from local x0 to x1 (origin `o` at the foot of
## x = 0), facing `out`, between y0 and y1 and `depth` thick inward, pierced
## by round-headed passages `opens` = [centre_x, width, spring_y, rise]
## (rise 0 = semicircle). Jambs and soffits use `dark`.
static func arch_wall(lm: LandmarkMesh, key: String, dark: String, o: Vector3, right: Vector3,
		out: Vector3, x0: float, x1: float, y0: float, y1: float, opens: Array, depth: float,
		segs: int = 8, cap: bool = true) -> void:
	var inward := -out * depth
	var cursor := x0
	for op in opens:
		var cx: float = float(op[0])
		var w: float = float(op[1])
		var spring: float = float(op[2])
		var rise: float = float(op[3]) if float(op[3]) > 0.0 else w * 0.5
		_solid(lm, key, o, right, out, inward, cursor, cx - w * 0.5, y0, y1)
		var cen := o + right * cx + Vector3(0, spring, 0)
		var prev := o + right * (cx - w * 0.5) + Vector3(0, spring, 0)
		for k in range(1, segs + 1):
			var t := PI - PI * float(k) / float(segs)
			var pt := cen + right * (cos(t) * w * 0.5) + Vector3(0, sin(t) * rise, 0)
			var pt_top := Vector3(pt.x, o.y + y1, pt.z)
			var prev_top := Vector3(prev.x, o.y + y1, prev.z)
			lm.quad(key, prev, pt, pt_top, prev_top, out)
			lm.quad(key, prev + inward, pt + inward, pt_top + inward, prev_top + inward, -out)
			var mid := (prev + pt) * 0.5
			var toward := (right * (cx - (mid - o).dot(right)) + Vector3(0, spring - mid.y, 0)).normalized()
			lm.quad(dark, prev, pt, pt + inward, prev + inward, toward)
			prev = pt
		var jl := o + right * (cx - w * 0.5)
		var jr := o + right * (cx + w * 0.5)
		lm.quad(dark, jl + Vector3(0, y0, 0), jl + Vector3(0, spring, 0),
			jl + Vector3(0, spring, 0) + inward, jl + Vector3(0, y0, 0) + inward, right)
		lm.quad(dark, jr + Vector3(0, y0, 0), jr + Vector3(0, spring, 0),
			jr + Vector3(0, spring, 0) + inward, jr + Vector3(0, y0, 0) + inward, -right)
		cursor = cx + w * 0.5
	_solid(lm, key, o, right, out, inward, cursor, x1, y0, y1)
	var e0 := o + right * x0
	var e1 := o + right * x1
	lm.quad(key, e0 + Vector3(0, y0, 0), e0 + Vector3(0, y1, 0), e0 + Vector3(0, y1, 0) + inward,
		e0 + Vector3(0, y0, 0) + inward, -right)
	lm.quad(key, e1 + Vector3(0, y0, 0), e1 + Vector3(0, y1, 0), e1 + Vector3(0, y1, 0) + inward,
		e1 + Vector3(0, y0, 0) + inward, right)
	if cap:
		lm.quad(key, e0 + Vector3(0, y1, 0), e1 + Vector3(0, y1, 0), e1 + Vector3(0, y1, 0) + inward,
			e0 + Vector3(0, y1, 0) + inward, Vector3.UP)

static func _solid(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		inward: Vector3, xa: float, xb: float, y0: float, y1: float) -> void:
	if xb - xa < 0.01:
		return
	var a := o + right * xa
	var b := o + right * xb
	lm.quad(key, a + Vector3(0, y0, 0), b + Vector3(0, y0, 0), b + Vector3(0, y1, 0),
		a + Vector3(0, y1, 0), out)
	lm.quad(key, a + Vector3(0, y0, 0) + inward, b + Vector3(0, y0, 0) + inward,
		b + Vector3(0, y1, 0) + inward, a + Vector3(0, y1, 0) + inward, -out)

## `n` arched bays round the circle (centre c, radius r) between angles
## a0..a1 (radians in the x/z plane, 0 = +X, turning toward +Z), one passage
## per bay occupying `open_frac` of the bay. `face_in` turns the face toward
## the centre (a hemicycle seen from its floor), else it looks outward.
static func arc_arcade(lm: LandmarkMesh, key: String, dark: String, c: Vector3, r: float,
		a0: float, a1: float, n: int, y0: float, y1: float, open_frac: float,
		spring_frac: float, depth: float, face_in: bool = false, cap: bool = false) -> void:
	for i in n:
		var t0 := a0 + (a1 - a0) * float(i) / float(n)
		var t1 := a0 + (a1 - a0) * float(i + 1) / float(n)
		var p0 := c + Vector3(cos(t0) * r, 0, sin(t0) * r)
		var p1 := c + Vector3(cos(t1) * r, 0, sin(t1) * r)
		var d := p1 - p0
		var w := d.length()
		var out := Vector3(cos((t0 + t1) * 0.5), 0, sin((t0 + t1) * 0.5))
		var ow := w * open_frac
		var spring := y0 + (y1 - y0) * spring_frac
		var op := [[w * 0.5, ow, spring, minf(ow * 0.5, (y1 - spring) * 0.85)]]
		if face_in:
			arch_wall(lm, key, dark, p1, -d / w, -out, 0.0, w, y0, y1, op, depth, 6, cap)
		else:
			arch_wall(lm, key, dark, p0, d / w, out, 0.0, w, y0, y1, op, depth, 6, cap)

## Straight arcade of `n` bays from a to b facing `out`.
static func arcade(lm: LandmarkMesh, key: String, dark: String, a: Vector3, b: Vector3,
		out: Vector3, n: int, y0: float, y1: float, open_frac: float, spring_frac: float,
		depth: float) -> void:
	var d := b - a
	var len := d.length()
	var w := len / float(n)
	var ow := w * open_frac
	var spring := y0 + (y1 - y0) * spring_frac
	for i in n:
		arch_wall(lm, key, dark, a + d / len * (w * float(i)), d / len, out, 0.0, w, y0, y1,
			[[w * 0.5, ow, spring, minf(ow * 0.5, (y1 - spring) * 0.85)]], depth, 6, false)

## Axis-aligned-by-yaw wall prism from a to b (ground points), thick, y0..y1.
static func seg_box(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, thick: float,
		y0: float, y1: float) -> void:
	var d := b - a
	d.y = 0.0
	var l := d.length()
	if l < 0.01 or y1 - y0 < 0.01:
		return
	lm.box(key, (a + b) * 0.5 + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(thick, y1 - y0, l),
		Basis(Vector3.UP, atan2(d.x, d.z)))

## Wall from a to b whose top is ragged: segments `step` long rising from
## y0 to between hmin and hmax (a ruin's broken crown).
static func ruin_wall(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, thick: float,
		y0: float, hmin: float, hmax: float, step: float, seed_v: float = 1.0) -> void:
	var n := maxi(int(a.distance_to(b) / step), 1)
	for i in n:
		var p := a.lerp(b, float(i) / float(n))
		var q := a.lerp(b, float(i + 1) / float(n))
		var f := absf(sin(float(i) * 12.9898 + seed_v * 78.233))
		seg_box(lm, key, p, q, thick, y0, y0 + hmin + (hmax - hmin) * f)

## Roman column of total height h standing at `base`: moulded foot, shaft
## with entasis, capital of the given order ("corinthian", "ionic",
## "doric") and abacus. The ionic volutes face local +/-Z.
static func column(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		order: String = "corinthian", seg: int = 12) -> void:
	var cap_h := r * (2.1 if order == "corinthian" else 1.1)
	var aba := r * 0.3
	var foot := r * 0.6
	var sh := h - aba - cap_h - foot
	var ys := foot + sh
	var p := PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r * 1.3, r * 0.2),
		Vector2(r * 1.1, r * 0.3), Vector2(r * 1.2, r * 0.42), Vector2(r * 1.0, foot),
		Vector2(r * 1.025, foot + sh * 0.3), Vector2(r * 0.95, foot + sh * 0.7),
		Vector2(r * 0.86, ys)])
	if order == "corinthian":
		p.append_array(PackedVector2Array([Vector2(r * 0.92, ys), Vector2(r * 1.0, ys + cap_h * 0.15),
			Vector2(r * 1.22, ys + cap_h * 0.55), Vector2(r * 1.38, ys + cap_h * 0.85),
			Vector2(r * 1.4, ys + cap_h)]))
	elif order == "doric":
		p.append_array(PackedVector2Array([Vector2(r * 0.9, ys), Vector2(r * 1.08, ys + cap_h * 0.3),
			Vector2(r * 1.28, ys + cap_h * 0.75), Vector2(r * 1.3, ys + cap_h)]))
	else:
		p.append_array(PackedVector2Array([Vector2(r * 0.9, ys), Vector2(r * 1.1, ys + cap_h * 0.4),
			Vector2(r * 1.12, ys + cap_h * 0.55)]))
		lm.box(key, base + Vector3(0, ys + cap_h * 0.75, 0), Vector3(r * 3.3, cap_h * 0.4, r * 2.0))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.disc(key, base + Vector3(sx * r * 1.45, ys + cap_h * 0.72, sz * r * 1.01),
					Vector3(0, 0, sz), r * 0.5, 10)
	lm.lathe(key, base, p, seg)
	var w := r * (2.9 if order == "corinthian" else 3.3 if order == "ionic" else 2.8)
	lm.box(key, base + Vector3(0, h - aba * 0.5, 0), Vector3(w, aba, w if order != "ionic" else r * 2.2))

## Entablature along a..b (points at the underside, i.e. on the column
## tops): architrave, frieze and projecting cornice of total height h.
static func entablature(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float,
		depth: float, over: float = 0.3) -> void:
	var up := Vector3.UP
	lm.beam(key, a + up * h * 0.14, b + up * h * 0.14, h * 0.28, depth * 0.9, up, true)
	lm.beam(key, a + up * h * 0.49, b + up * h * 0.49, h * 0.42, depth * 0.84, up, true)
	lm.beam(key, a + up * h * 0.85, b + up * h * 0.85, h * 0.3, depth + over * 2.0, up, true)

## Triangular pediment prism: base centre `c`, width w along `along`
## (horizontal unit), facing `out`, `rise` high and `depth` thick.
static func pediment(lm: LandmarkMesh, key: String, c: Vector3, along: Vector3, out: Vector3,
		w: float, rise: float, depth: float) -> void:
	var up := Vector3.UP
	var l := c - along * (w * 0.5)
	var r := c + along * (w * 0.5)
	var ap := c + up * rise
	var f := out * depth * 0.5
	lm.tri(key, l + f, r + f, ap + f, out, out, out, Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, -rise))
	lm.tri(key, l - f, r - f, ap - f, -out, -out, -out, Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, -rise))
	var nl := (-along * rise + up * (w * 0.5)).normalized()
	var nr := (along * rise + up * (w * 0.5)).normalized()
	lm.quad(key, l + f, ap + f, ap - f, l - f, nl)
	lm.quad(key, ap + f, r + f, r - f, ap - f, nr)
	lm.quad(key, l + f, l - f, r - f, r + f, -up)

## Barrel vault: intrados strips from `c` (centre of the span at the
## springing, at the near end) along `axis` for `length`, spanning `span`
## across `across`, rising `rise`; extrados `thick` above; a grid of
## dark coffers (`cof_across` x `cof_along`) sunk into the soffit.
static func barrel_vault(lm: LandmarkMesh, key: String, dark: String, c: Vector3, axis: Vector3,
		across: Vector3, length: float, span: float, rise: float, thick: float,
		cof_across: int = 0, cof_along: int = 0, steps: int = 12) -> void:
	var hs := span * 0.5
	var ext := axis * length
	for k in steps:
		var t0 := PI * float(k) / float(steps)
		var t1 := PI * float(k + 1) / float(steps)
		var i0 := c + across * (cos(t0) * hs) + Vector3(0, sin(t0) * rise, 0)
		var i1 := c + across * (cos(t1) * hs) + Vector3(0, sin(t1) * rise, 0)
		var o0 := c + across * (cos(t0) * (hs + thick)) + Vector3(0, sin(t0) * (rise + thick), 0)
		var o1 := c + across * (cos(t1) * (hs + thick)) + Vector3(0, sin(t1) * (rise + thick), 0)
		var mid := (i0 + i1) * 0.5
		lm.quad(key, i0, i1, i1 + ext, i0 + ext, (c + Vector3(0, 0.0, 0) - mid).normalized())
		lm.quad(key, o0, o1, o1 + ext, o0 + ext, ((o0 + o1) * 0.5 - c).normalized())
		lm.quad(key, i0, o0, o1, i1, -axis)
		lm.quad(key, i0 + ext, o0 + ext, o1 + ext, i1 + ext, axis)
	for ia in cof_across:
		for ib in cof_along:
			var u0 := PI * (float(ia) + 0.2) / float(cof_across)
			var u1 := PI * (float(ia) + 0.8) / float(cof_across)
			var s0 := length * (float(ib) + 0.2) / float(cof_along)
			var s1 := length * (float(ib) + 0.8) / float(cof_along)
			var um := (u0 + u1) * 0.5
			var q0 := c + across * (cos(u0) * (hs - 0.12)) + Vector3(0, sin(u0) * (rise - 0.12), 0)
			var q1 := c + across * (cos(um) * (hs - 0.2)) + Vector3(0, sin(um) * (rise - 0.2), 0)
			var q2 := c + across * (cos(u1) * (hs - 0.12)) + Vector3(0, sin(u1) * (rise - 0.12), 0)
			var n := (c - q1).normalized()
			var da := axis * s0
			var db := axis * s1
			lm.quad(dark, q0 + da, q1 + da, q1 + db, q0 + db, n)
			lm.quad(dark, q1 + da, q2 + da, q2 + db, q1 + db, n)

## Merlons round a drum: `n` blocks w wide at radius r on height y.
static func merlons_ring(lm: LandmarkMesh, key: String, c: Vector3, r: float, y: float, n: int,
		w: float, h: float, thick: float) -> void:
	for i in n:
		var a := TAU * (float(i) + 0.5) / float(n)
		lm.box(key, c + Vector3(cos(a) * r, y + h * 0.5, sin(a) * r), Vector3(thick, h, w),
			Basis(Vector3.UP, -a))

## Flat-topped block of steps rising toward -local Z (or `dir`).
static func stairs(lm: LandmarkMesh, key: String, front: Vector3, dir: Vector3, width: float,
		tread: float, riser: float, n: int) -> void:
	SEuUtil.steps_up(lm, key, front, dir, width, tread, riser, n)
