class_name LandmarkMaParts
extends RefCounted

## Small shared shapes for the Middle East / Africa landmark batch, in
## true metres on LandmarkMesh.

## Dome profile (radius, y), bottom to top, ending on the axis. `tip`
## > 0 pulls the crown into an onion point (radius * cos^(1 + tip)).
static func dome_profile(r: float, h: float, steps: int = 8, tip: float = 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * pow(cos(a), 1.0 + tip), h * sin(a)))
	return p

## Dome of radius r and height h standing on `base`.
static func dome(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 16, tip: float = 0.0) -> void:
	lm.lathe(key, base, dome_profile(r, h, 6, tip), seg)

## Ellipsoid (sphere stretched by sy) centred on `c`.
static func sphere(lm: LandmarkMesh, key: String, c: Vector3, r: float, seg: int = 20,
		rings: int = 10, sy: float = 1.0) -> void:
	var p := PackedVector2Array()
	for i in rings + 1:
		var a := -PI * 0.5 + PI * float(i) / rings
		p.append(Vector2(r * cos(a), r * sy * (1.0 + sin(a))))
	lm.lathe(key, c - Vector3(0, r * sy, 0), p, seg)

## Needle / mast: radius tapers through `prof` (height m, radius m) pairs.
static func needle(lm: LandmarkMesh, key: String, base: Vector3, prof: PackedVector2Array,
		seg: int = 12) -> void:
	var p := PackedVector2Array()
	for v in prof:
		p.append(Vector2(v.y, v.x))
	lm.lathe(key, base, p, seg)

## Crescent in the XY plane: an arc of `r` round `c`, open upward.
static func crescent(lm: LandmarkMesh, key: String, c: Vector3, r: float, w: float) -> void:
	var prev := c + Vector3(sin(deg_to_rad(-130.0)), -cos(deg_to_rad(-130.0)), 0) * r
	for k in range(1, 15):
		var t := deg_to_rad(-130.0 + 260.0 * float(k) / 14.0)
		var p := c + Vector3(sin(t), -cos(t), 0) * r
		lm.beam(key, prev, p, w, w * 1.6, Vector3(0, 0, 1))
		prev = p

## Arch curve offsets (x from the opening's centre, y above the
## springing) from the left springing to the right: round when `rise`
## equals `half` (half the opening), two-centred pointed when higher.
static func arch_curve(half: float, rise: float, steps: int = 6) -> PackedVector2Array:
	var rr := maxf(rise, half)
	var rho := (rr * rr + half * half) / (2.0 * half)
	var off := rho - half
	var crown := acos(clampf(-off / rho, -1.0, 1.0))
	var left := PackedVector2Array()
	for i in steps + 1:
		var a := lerpf(PI, crown, float(i) / float(steps))
		left.append(Vector2(off + rho * cos(a), rho * sin(a)))
	var p := left.duplicate()
	for i in range(steps - 1, -1, -1):
		p.append(Vector2(-left[i].x, left[i].y))
	return p

## A wall skin `depth` thick over a mass face (or free-standing as an
## arcade front) w x h, cut by `bays` arched openings `open_w` wide that
## spring at `spring` and rise `rise` more: piers, spandrels, jambs and
## the arch soffits are real geometry. `back` (if set) closes each
## opening just in front of the mass face (glass, a door or shadow);
## `frame` (if set) runs a moulded archivolt round each arch. `origin` is
## the bottom-left of the face, `right` and `normal` unit vectors.
static func arched_bays(lm: LandmarkMesh, wall: String, back: String, origin: Vector3, right: Vector3,
		normal: Vector3, w: float, h: float, bays: int, open_w: float, spring: float, rise: float,
		depth: float = 0.6, frame: String = "", steps: int = 6) -> void:
	var r := right.normalized()
	var n := normal.normalized()
	var u := Vector3.UP
	var pitch := w / float(bays)
	var half := open_w * 0.5
	var curve := arch_curve(half, rise, steps)
	var P := func(x: float, y: float, d: float) -> Vector3:
		return origin + r * x + u * y + n * d
	for i in bays:
		var x0 := pitch * float(i)
		var cx := x0 + pitch * 0.5
		_rect(lm, wall, P, x0, 0.0, cx - half - x0, h, depth, n)
		_rect(lm, wall, P, cx + half, 0.0, x0 + pitch - cx - half, h, depth, n)
		for k in curve.size() - 1:
			var a := curve[k]
			var b := curve[k + 1]
			lm.quad(wall, P.call(cx + a.x, spring + a.y, depth), P.call(cx + b.x, spring + b.y, depth),
				P.call(cx + b.x, h, depth), P.call(cx + a.x, h, depth), n, Vector2(cx + a.x, -spring - a.y))
			var e := b - a
			var inward := Vector2(e.y, -e.x).normalized()
			lm.quad(wall, P.call(cx + a.x, spring + a.y, 0.0), P.call(cx + b.x, spring + b.y, 0.0),
				P.call(cx + b.x, spring + b.y, depth), P.call(cx + a.x, spring + a.y, depth),
				r * inward.x + u * inward.y)
			if frame != "":
				var fw := clampf(open_w * 0.08, 0.12, 0.9)
				var oa := a + (a - Vector2(0, half * 0.3)).normalized() * fw * 0.5
				var ob := b + (b - Vector2(0, half * 0.3)).normalized() * fw * 0.5
				lm.beam(frame, P.call(cx + oa.x, spring + oa.y, depth + 0.08),
					P.call(cx + ob.x, spring + ob.y, depth + 0.08), 0.16, fw, n)
		if spring > 0.01:
			lm.quad(wall, P.call(cx - half, 0.0, 0.0), P.call(cx - half, 0.0, depth),
				P.call(cx - half, spring, depth), P.call(cx - half, spring, 0.0), r)
			lm.quad(wall, P.call(cx + half, 0.0, depth), P.call(cx + half, 0.0, 0.0),
				P.call(cx + half, spring, 0.0), P.call(cx + half, spring, depth), -r)
		if back != "":
			lm.quad(back, P.call(cx - half, 0.0, 0.02), P.call(cx + half, 0.0, 0.02),
				P.call(cx + half, spring, 0.02), P.call(cx - half, spring, 0.02), n)
			var c0: Vector3 = P.call(cx, spring, 0.02)
			for k in curve.size() - 1:
				var a := curve[k]
				var b := curve[k + 1]
				lm.tri(back, c0, P.call(cx + a.x, spring + a.y, 0.02), P.call(cx + b.x, spring + b.y, 0.02),
					n, n, n, Vector2.ZERO, a, b)
	lm.quad(wall, P.call(0.0, 0.0, 0.0), P.call(0.0, 0.0, depth), P.call(0.0, h, depth), P.call(0.0, h, 0.0), -r)
	lm.quad(wall, P.call(w, 0.0, depth), P.call(w, 0.0, 0.0), P.call(w, h, 0.0), P.call(w, h, depth), r)
	lm.quad(wall, P.call(0.0, h, depth), P.call(w, h, depth), P.call(w, h, 0.0), P.call(0.0, h, 0.0), u)

static func _rect(lm: LandmarkMesh, key: String, P: Callable, x: float, y: float, w: float,
		h: float, d: float, n: Vector3) -> void:
	if w <= 0.001 or h <= 0.001:
		return
	lm.quad(key, P.call(x, y, d), P.call(x + w, y, d), P.call(x + w, y + h, d), P.call(x, y + h, d), n,
		Vector2(x, -y))

## Polygonal ring of arched faces (`sides` faces, circumradius `cr`,
## first corner at angle `rot`, matching lm.frustum's corners): one
## arched opening per face, as in a drum or an octagon's walls.
static func arched_ring(lm: LandmarkMesh, wall: String, back: String, base: Vector3, cr: float,
		sides: int, h: float, open_w: float, spring: float, rise: float, depth: float = 0.5,
		rot: float = 0.0, frame: String = "", bays: int = 1) -> void:
	for i in sides:
		var a0 := rot + TAU * float(i) / float(sides)
		var a1 := rot + TAU * float(i + 1) / float(sides)
		var p0 := base + Vector3(cos(a0), 0, sin(a0)) * cr
		var p1 := base + Vector3(cos(a1), 0, sin(a1)) * cr
		var am := (a0 + a1) * 0.5
		arched_bays(lm, wall, back, p0, p1 - p0, Vector3(cos(am), 0, sin(am)), p0.distance_to(p1), h,
			bays, open_w, spring, rise, depth, frame, 4)

## Merlons along a-b (a parapet's top edge): `count` blocks w wide, h
## high, t thick; `stepped` gives each a stepped (Islamic) top.
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, count: int, w: float,
		h: float, t: float, stepped: bool = false) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		if stepped:
			lm.box(key, p + Vector3(0, h * 0.3, 0), Vector3(w, h * 0.6, t), basis, 0.0)
			lm.box(key, p + Vector3(0, h * 0.75, 0), Vector3(w * 0.55, h * 0.3, t), basis, 0.0)
			lm.box(key, p + Vector3(0, h * 0.95, 0), Vector3(w * 0.2, h * 0.1, t), basis, 0.0)
		else:
			lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(w, h, t), basis, 0.0)

## Hipped roof over a w x l rectangle centred on `c` (eave level),
## rising h to a w1 x l1 top (0 x 0 for a pyramid), the top capped.
static func hip_roof(lm: LandmarkMesh, key: String, c: Vector3, w: float, l: float, h: float,
		w1: float = 0.0, l1: float = 0.0) -> void:
	var b: Array[Vector3] = [Vector3(-w, 0, -l) * 0.5, Vector3(w, 0, -l) * 0.5, Vector3(w, 0, l) * 0.5,
		Vector3(-w, 0, l) * 0.5]
	var t: Array[Vector3] = [Vector3(-w1 * 0.5, h, -l1 * 0.5), Vector3(w1 * 0.5, h, -l1 * 0.5),
		Vector3(w1 * 0.5, h, l1 * 0.5), Vector3(-w1 * 0.5, h, l1 * 0.5)]
	for i in 4:
		var j := (i + 1) % 4
		var o := ((b[i] + b[j]) * 0.5).normalized()
		var n := (b[j] - b[i]).cross((t[i] + t[j]) * 0.5 - (b[i] + b[j]) * 0.5).normalized()
		if n.dot(o) < 0.0:
			n = -n
		lm.quad(key, c + b[i], c + b[j], c + t[j], c + t[i], n)
	if w1 > 0.0 and l1 > 0.0:
		lm.quad(key, c + t[0], c + t[1], c + t[2], c + t[3], Vector3.UP)
