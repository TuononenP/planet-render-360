class_name VehicleKit
extends RefCounted

## Shared modelling parts for procedural road vehicles, on LandmarkMesh
## (metres; +X forward, +Y up, wheels on y = 0).
## * skin(): a grid of points becomes a surface whose every quad picks
##   its own material key, so glass, lamps and trim are regions of one
##   flowing body, not boxes stuck on it. Normals smooth across quads
##   that meet within SMOOTH_COS and crease elsewhere. Paint UV.x carries
##   baked occlusion for CarPaint.
## * body(): a car body lofted from a spec (CarSpecs): cross sections at
##   stations along the length, each running floor, wheel well, side,
##   shoulder, glasshouse side and roof to the centreline, mirrored. The
##   wheel arches are cut by lifting the side's lower edge over the wheel
##   circle; nose and tail close by shrinking the end section to the
##   centreline along a bowed plan.
## * rake(), side_w(), face_point(): where the lofted surface lies, for
##   the parts laid on it (CarParts, CarModel). Wheels are CarParts'.

const SMOOTH_COS := 0.74
## Height share over which the shoulder's character line steps in.
const SHOULDER_T := 0.03
## How far out from its arch a flare runs back into the flank (metres).
const FLARE_M := 0.3

const ROLE_UNDER := 0
const ROLE_SIDE := 1
const ROLE_PAINT := 2
const ROLE_MOULD := 3
const ROLE_SIDE_GLASS := 4
const ROLE_ROOF := 5
const ROLE_RAIL := 6

## Piecewise-linear lookup in a (key, value) table sorted by key.
static func lin(table: PackedVector2Array, k: float) -> float:
	var last := table.size() - 1
	if k <= table[0].x:
		return table[0].y
	if k >= table[last].x:
		return table[last].y
	var i := 0
	while table[i + 1].x < k:
		i += 1
	var a := table[i]
	var b := table[i + 1]
	return lerpf(a.y, b.y, (k - a.x) / maxf(b.x - a.x, 0.0001))

## lin() with its corners rounded over about `r`.
static func soft(table: PackedVector2Array, k: float, r: float) -> float:
	return (lin(table, k - r) + 2.0 * lin(table, k) + lin(table, k + r)) * 0.25

## Surface through `rows` (PackedVector3Array each, equal length). Quad
## (r, c) lies between rows r, r+1 and columns c, c+1 and takes the key
## `keys.call(r, c)` ("" leaves a hole). Faces point along
## (row step) x (column step), or the reverse with `flip`. `ao` holds a
## PackedFloat32Array per row (omitted: 1). `mirror` adds the z-mirrored
## half.
static func skin(lm: LandmarkMesh, rows: Array, keys: Callable, ao: Array = [],
		mirror: bool = false, flip: bool = false) -> void:
	var nr := rows.size()
	var nc := (rows[0] as PackedVector3Array).size()
	var raw: Array = []
	var unit: Array = []
	for r in nr - 1:
		var p0: PackedVector3Array = rows[r]
		var p1: PackedVector3Array = rows[r + 1]
		var fr := PackedVector3Array()
		var fu := PackedVector3Array()
		fr.resize(nc - 1)
		fu.resize(nc - 1)
		for c in nc - 1:
			var n := (p1[c + 1] - p0[c]).cross(p0[c + 1] - p1[c])
			if flip:
				n = -n
			fr[c] = n
			fu[c] = n.normalized() if n.length_squared() > 1e-14 else Vector3.ZERO
		raw.append(fr)
		unit.append(fu)
	for r in nr - 1:
		var p0: PackedVector3Array = rows[r]
		var p1: PackedVector3Array = rows[r + 1]
		var a0: PackedFloat32Array = ao[r] if not ao.is_empty() else PackedFloat32Array()
		var a1: PackedFloat32Array = ao[r + 1] if not ao.is_empty() else PackedFloat32Array()
		var fu: PackedVector3Array = unit[r]
		for c in nc - 1:
			var own := fu[c]
			if own == Vector3.ZERO:
				continue
			var key: String = keys.call(r, c)
			if key == "":
				continue
			var na := _corner(raw, unit, own, r, c, nr, nc)
			var nb := _corner(raw, unit, own, r, c + 1, nr, nc)
			var nd := _corner(raw, unit, own, r + 1, c + 1, nr, nc)
			var ne := _corner(raw, unit, own, r + 1, c, nr, nc)
			var ua := Vector2(a0[c] if not a0.is_empty() else 1.0, 0.0)
			var ub := Vector2(a0[c + 1] if not a0.is_empty() else 1.0, 0.0)
			var ud := Vector2(a1[c + 1] if not a1.is_empty() else 1.0, 0.0)
			var ue := Vector2(a1[c] if not a1.is_empty() else 1.0, 0.0)
			_tri(lm, key, p0[c], p0[c + 1], p1[c + 1], na, nb, nd, ua, ub, ud, mirror)
			_tri(lm, key, p0[c], p1[c + 1], p1[c], na, nd, ne, ua, ud, ue, mirror)

## Normal at grid vertex (vr, vc) for a quad facing `own`: the touching
## faces within the smoothing angle, weighted by area.
static func _corner(raw: Array, unit: Array, own: Vector3, vr: int, vc: int, nr: int, nc: int) -> Vector3:
	var sum := Vector3.ZERO
	for qr in [vr - 1, vr]:
		if qr < 0 or qr >= nr - 1:
			continue
		var fu: PackedVector3Array = unit[qr]
		var fr: PackedVector3Array = raw[qr]
		for qc in [vc - 1, vc]:
			if qc < 0 or qc >= nc - 1:
				continue
			if fu[qc].dot(own) >= SMOOTH_COS:
				sum += fr[qc]
	return sum.normalized() if sum.length_squared() > 1e-16 else own

static func _tri(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3,
		nb: Vector3, nc: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, mirror: bool) -> void:
	if (b - a).cross(c - a).length_squared() < 1e-13:
		return
	if mirror:
		# A sliver lying in the centre plane is edge on from every side.
		if absf(a.z) < 1e-5 and absf(b.z) < 1e-5 and absf(c.z) < 1e-5:
			return
		# On the centreline the two halves share a normal, or the crown
		# reads as a ridge.
		na = _on_centre(a, na)
		nb = _on_centre(b, nb)
		nc = _on_centre(c, nc)
	lm.tri(key, a, b, c, na, nb, nc, ua, ub, uc)
	if mirror:
		var m := Vector3(1, 1, -1)
		lm.tri(key, a * m, b * m, c * m, na * m, nb * m, nc * m, ua, ub, uc)

static func _on_centre(p: Vector3, n: Vector3) -> Vector3:
	if absf(p.z) > 1e-5 or absf(n.z) > 0.9:
		return n
	return Vector3(n.x, n.y, 0.0).normalized()

## Rounded lump (mirror housings, aerials): a superellipsoid of half
## sizes `half` at `centre`.
static func blob(lm: LandmarkMesh, key: String, centre: Vector3, half: Vector3,
		lat: int = 5, lon: int = 10, ao: float = 1.0) -> void:
	var rows: Array = []
	var shade: Array = []
	for j in lat + 1:
		var phi := -PI * 0.5 + PI * float(j) / float(lat)
		var row := PackedVector3Array()
		var a := PackedFloat32Array()
		for i in lon + 1:
			var th := TAU * float(i) / float(lon)
			var d := Vector3(cos(phi) * cos(th), sin(phi), cos(phi) * sin(th))
			d = Vector3(signf(d.x) * pow(absf(d.x), 0.7), signf(d.y) * pow(absf(d.y), 0.7),
				signf(d.z) * pow(absf(d.z), 0.7))
			row.append(centre + d * half)
			a.append(ao)
		rows.append(row)
		shade.append(a)
	skin(lm, rows, func(_r: int, _c: int) -> String: return key, shade)

## Surface of revolution about the Z axis through `centre`. `prof` is
## (radius, offset along the axle), the offset counted toward `side`
## (+1 / -1); faces point to the right of the profile's direction.
static func revolve(lm: LandmarkMesh, key: String, centre: Vector3, prof: PackedVector2Array,
		seg: int, side: float, smooth: bool = true) -> void:
	var n := prof.size()
	var seg_n := PackedVector2Array()
	for j in n - 1:
		var d := prof[j + 1] - prof[j]
		seg_n.append(Vector2(d.y, -d.x).normalized())
	for j in n - 1:
		var n0 := seg_n[j]
		var n1 := seg_n[j]
		if smooth:
			n0 = (seg_n[maxi(j - 1, 0)] + seg_n[j]).normalized()
			n1 = (seg_n[j] + seg_n[mini(j + 1, n - 2)]).normalized()
		for i in seg:
			var t0 := TAU * float(i) / float(seg)
			var t1 := TAU * float(i + 1) / float(seg)
			var d0 := Vector3(cos(t0), sin(t0), 0)
			var d1 := Vector3(cos(t1), sin(t1), 0)
			var z0 := Vector3(0, 0, side * prof[j].y)
			var z1 := Vector3(0, 0, side * prof[j + 1].y)
			var a := centre + d0 * prof[j].x + z0
			var b := centre + d1 * prof[j].x + z0
			var c := centre + d1 * prof[j + 1].x + z1
			var e := centre + d0 * prof[j + 1].x + z1
			var na := d0 * n0.x + Vector3(0, 0, side * n0.y)
			var nb := d1 * n0.x + Vector3(0, 0, side * n0.y)
			var nc := d1 * n1.x + Vector3(0, 0, side * n1.y)
			var ne := d0 * n1.x + Vector3(0, 0, side * n1.y)
			if (b - a).length_squared() > 1e-12:
				lm.tri(key, a, b, c, na, nb, nc, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
			if (c - e).length_squared() > 1e-12:
				lm.tri(key, a, c, e, na, nc, ne, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)

## Half width of the body in plan at `x`: a slight barrel, and
## superellipse corners into the nose and tail.
static func half_width(s: Dictionary, x: float) -> float:
	var half_l := float(s["len"]) * 0.5
	var w := float(s["wid"]) * 0.5 * (1.0 - float(s["taper"]) * pow(x / half_l, 2.0))
	var pw := float(s["corner_pow"])
	var x_f := half_l - float(s["bulge_f"])
	var x_r := -half_l + float(s["bulge_r"])
	var cf := float(s["corner_f"])
	var cr := float(s["corner_r"])
	if x > x_f - cf:
		var k := clampf((x - (x_f - cf)) / cf, 0.0, 1.0)
		var e := float(s["end_w_f"])
		w *= e + (1.0 - e) * pow(1.0 - pow(k, pw), 1.0 / pw)
	elif x < x_r + cr:
		var k := clampf(((x_r + cr) - x) / cr, 0.0, 1.0)
		var e := float(s["end_w_r"])
		w *= e + (1.0 - e) * pow(1.0 - pow(k, pw), 1.0 / pw)
	return w

## Half width of the flank at station `x`, height share `hf` (height `y`
## under a belt at `belt`): the plan width `w` bowed by the bulge table,
## stepped in above the shoulder line and pushed out over the arches.
static func side_w(s: Dictionary, x: float, w: float, hf: float, y: float, belt: float) -> float:
	var ws := w * lin(s["bulge"], hf)
	var sh: Vector2 = s["shoulder"]
	ws -= sh.y * smoothstep(sh.x, sh.x + SHOULDER_T, hf)
	# Below the sill line the flank tucks under: a crisp lower crease.
	var sl: Vector2 = s["sill"]
	ws -= sl.y * (1.0 - smoothstep(sl.x - SHOULDER_T, sl.x, hf))
	return ws + flare_at(s, x, y, belt)

## How far the arch flares stand out at (`x`, `y`): a smooth ring round
## each arch, full at its edge and gone FLARE_M out from it, kept off the
## shoulder below the belt.
static func flare_at(s: Dictionary, x: float, y: float, belt: float) -> float:
	var f := float(s["flare"])
	if f <= 0.0:
		return 0.0
	var ra := float(s["arch_r"])
	var r := float(s["wheel_r"])
	var ring := 0.0
	for ax: float in [float(s["axle_f"]), float(s["axle_r"])]:
		var d := maxf(Vector2(x - ax, y - r).length() - ra, 0.0)
		var k := clampf(1.0 - d / FLARE_M, 0.0, 1.0)
		ring = maxf(ring, k * k * (3.0 - 2.0 * k))
	return f * ring * (1.0 - smoothstep(belt - 0.16, belt - 0.03, y))

## The end faces lean back above the bumper: `p` moved toward the middle
## near the nose and tail, by rake_f / rake_r at the belt, nothing at the
## bumper. Every body point and every point placed on it goes through
## here; the ramp stops short of the glasshouse so the roof is untouched.
static func rake(s: Dictionary, p: Vector3) -> Vector3:
	var half := float(s["len"]) * 0.5
	var gh: PackedFloat32Array = s["gh"]
	var x_f := half - float(s["bulge_f"])
	var x_r := -half + float(s["bulge_r"])
	var rf := float(s["rake_f"])
	var lf := minf(0.55, x_f - gh[3] - 0.03)
	if rf > 0.0 and lf > 0.05 and p.x > x_f - lf:
		p.x -= rf * smoothstep(x_f - lf, x_f, p.x) * _rake_h(s, x_f, p.y)
	var rr := float(s["rake_r"])
	var lr := minf(0.5, gh[0] - x_r - 0.03)
	if rr > 0.0 and lr > 0.05 and p.x < x_r + lr:
		p.x += rr * smoothstep(x_r + lr, x_r, p.x) * _rake_h(s, x_r, p.y)
	return p

static func _rake_h(s: Dictionary, xe: float, y: float) -> float:
	var fl := soft(s["floor"], xe, 0.06)
	var belt := soft(s["belt"], xe, 0.1)
	var yb := lerpf(fl, belt, float(s["bumper_t"]))
	return pow(clampf((y - yb) / maxf(belt - yb, 0.01), 0.0, 1.0), 1.2)

## Stations along the body: the ends, corner and arch curves, the
## glasshouse and trim boundaries, filled in evenly between.
static func _stations(s: Dictionary, far: bool) -> PackedFloat32Array:
	var half_l := float(s["len"]) * 0.5
	var x_f := half_l - float(s["bulge_f"])
	var x_r := -half_l + float(s["bulge_r"])
	var pw := float(s["corner_pow"])
	var must: Array[float] = [x_r, x_f]
	for deg in ([45.0, 75.0] if far else [18.0, 36.0, 54.0, 68.0, 80.0]):
		var f := pow(sin(deg_to_rad(deg)), 2.0 / pw)
		must.append(x_f - float(s["corner_f"]) * (1.0 - f))
		must.append(x_r + float(s["corner_r"]) * (1.0 - f))
	var ra := float(s["arch_r"])
	var na := 2 if far else 12
	for ax: float in [float(s["axle_f"]), float(s["axle_r"])]:
		for k in na + 1:
			must.append(ax - ra * cos(PI * float(k) / float(na)))
		if not far:
			must.append(ax - ra - 0.004)
			must.append(ax + ra + 0.004)
	var gh: PackedFloat32Array = s["gh"]
	for x in gh:
		must.append(x)
	must.append(lerpf(gh[1], gh[2], 0.45))  # the roof's peak
	if float(s["board_x"]) > gh[2]:
		must.append(float(s["board_x"]))
	for x: float in (s["cuts_far"] if far else s["cuts"]):
		must.append(x)
	must.sort()
	var out: Array[float] = []
	for x in must:
		if x < x_r - 0.0001 or x > x_f + 0.0001:
			continue
		if out.is_empty() or x - out[out.size() - 1] > 0.0035:
			out.append(x)
	# A bus's long flat flanks need few stations.
	var step := (0.55 if far else 0.16) * (2.0 if half_l > 3.5 else 1.0)
	var keyed := out.duplicate()
	var fill := x_r + step
	while fill < x_f:
		var clear := true
		for k in keyed:
			if absf(k - fill) < step * 0.45:
				clear = false
				break
		if clear:
			out.append(fill)
		fill += step
	out.sort()
	return PackedFloat32Array(out)

## Height fractions up the body side: the trim boundaries, filled in.
static func _side_ts(s: Dictionary, far: bool) -> PackedFloat32Array:
	var out: Array[float] = [0.0, 1.0]
	var lamp_f: Vector2 = s["lamp_f"]
	var lamp_r: Vector2 = s["lamp_r"]
	var grille: Vector2 = s["grille"]
	var need: Array[float] = [lamp_f.x, lamp_f.y, lamp_r.x, lamp_r.y, 0.94]
	if not far:
		var sh: Vector2 = s["shoulder"]
		need.append_array([grille.x, grille.y, float(s["valance"]), float(s["clad"]), float(s["bumper_t"])])
		if sh.y > 0.0:
			need.append_array([sh.x, sh.x + SHOULDER_T])
		need.append(float(s["valance_r"]))
	for t in need:
		var clear := t > 0.0
		for k in out:
			if absf(k - t) < 0.02:
				clear = false
		if clear:
			out.append(t)
	# The shoulder's two rows sit closer than the rest may.
	var sh2: Vector2 = s["shoulder"]
	if not far and sh2.y > 0.0:
		for t in [sh2.x, sh2.x + SHOULDER_T]:
			if not out.has(t):
				out.append(t)
	var sl2: Vector2 = s["sill"]
	if not far and sl2.y > 0.0:
		for t in [sl2.x - SHOULDER_T, sl2.x]:
			var clear := true
			for k in out:
				if absf(k - t) < 0.012:
					clear = false
			if clear:
				out.append(t)
	if not far:
		for t: float in [0.05, 0.12, 0.22, 0.34, 0.46, 0.58, 0.70, 0.80, 0.88]:
			var clear := true
			for k in out:
				if absf(k - t) < 0.045:
					clear = false
			if clear:
				out.append(t)
	out.sort()
	return PackedFloat32Array(out)

## One half cross section at station `x`; returns [points, occlusion].
static func _section(s: Dictionary, x: float, ts: PackedFloat32Array, vs: PackedFloat32Array,
		wr: PackedFloat32Array, far: bool) -> Array:
	var pts := PackedVector3Array()
	var ao := PackedFloat32Array()
	var fl := soft(s["floor"], x, 0.06)
	var belt := soft(s["belt"], x, 0.1)
	var w := half_width(s, x)
	var low := fl
	var ra := float(s["arch_r"])
	for ax: float in [float(s["axle_f"]), float(s["axle_r"])]:
		var dx := absf(x - ax)
		if dx < ra:
			low = maxf(low, float(s["wheel_r"]) + sqrt(ra * ra - dx * dx))
	low = minf(low, belt - float(s["arch_margin"]))
	var arch := low > fl + 0.01
	pts.append(Vector3(x, fl, 0.0))
	ao.append(0.3)
	if not far:
		var zi := maxf(w - float(s["well"]), 0.1)
		pts.append(Vector3(x, fl, zi))
		pts.append(Vector3(x, low, zi))
		ao.append_array([0.3, 0.3])
	var ws := w
	for t in ts:
		# Rows keep their height along the car and gather on the arch's edge
		# where it rises through them, so the shoulder line and the flares
		# run straight over the wheels.
		var y := maxf(lerpf(fl, belt, t), low)
		var hf := (y - fl) / maxf(belt - fl, 0.01)
		ws = side_w(s, x, w, hf, y, belt)
		pts.append(Vector3(x, y, ws))
		var shade := 0.55 + 0.45 * smoothstep(0.0, 0.2, hf)
		if arch:
			shade *= 0.75 + 0.25 * smoothstep(0.0, 0.12, t)
		ao.append(shade)
	# Shoulder chamfer, then the deck (bonnet, boot or the shelf under
	# the side glass), crowned to the centreline.
	var wd := ws - 0.03
	var lift := 0.012
	var crown := lin(s["crown"], x)
	pts.append(Vector3(x, belt + lift, wd))
	var gb := minf(wd - float(s["shelf"]), w * lin(s["gh_w"], x))
	var y0 := belt + lift + crown * (1.0 - pow(gb / wd, 2.0))
	var top := belt + lift + crown
	var gh: PackedFloat32Array = s["gh"]
	if x > gh[0] - 0.07 and x < gh[3] + 0.07:
		top = maxf(top, soft(s["roof"], x, 0.07))
	# Across the car the roof is nearly flat; the bowed windscreen and
	# rear window, cut square to the body, stand taller in the middle.
	var glassy := maxf(smoothstep(gh[2], gh[2] + 0.3, x), 1.0 - smoothstep(gh[1] - 0.3, gh[1], x))
	var rc := lerpf(float(s["roof_crown"]), float(s["glass_crown"]), glassy)
	var hside := maxf(y0, top - rc)
	var frac := clampf((hside - y0) / float(s["gh_full"]), 0.0, 1.0)
	var zt := gb
	for v in vs:
		zt = gb - float(s["tumble"]) * frac * pow(v, 1.15) - (0.02 * frac if v >= 1.0 else 0.0)
		pts.append(Vector3(x, lerpf(y0, hside, v), zt))
	for q in wr:
		pts.append(Vector3(x, hside + (top - hside) * (1.0 - pow(1.0 - q, 2.0)), zt * (1.0 - q)))
	while ao.size() < pts.size():
		ao.append(1.0)
	return [pts, ao]

## Lofts the body of spec `s` into `lm`: keys Paint, Glass, Trim, Rubber,
## HeadLamp, TailLamp and (a bus's destination sign) Board.
static func body(lm: LandmarkMesh, s: Dictionary, far: bool) -> void:
	if far and float(s["flare"]) > 0.0:
		# Too few stations far off to round a flare: it would read as a dent.
		s = s.duplicate()
		s["flare"] = 0.0
	var xs := _stations(s, far)
	var ts := _side_ts(s, far)
	var vs := PackedFloat32Array([0.0, 1.0]) if far else PackedFloat32Array([0.0, 0.07, 0.36, 0.65, 0.93, 1.0])
	var wr := PackedFloat32Array([0.5, 1.0]) if far else PackedFloat32Array([0.1, 0.4, 0.7, 1.0])
	var ends := PackedFloat32Array([0.72, 0.4, 0.0]) if far else PackedFloat32Array([0.86, 0.68, 0.45, 0.2, 0.0])
	# Column roles, by the quad between points c and c + 1.
	var role := PackedInt32Array()
	var tmid := PackedFloat32Array()
	var under := 1 if far else 3
	for c in under:
		role.append(ROLE_UNDER)
		tmid.append(0.0)
	for i in ts.size() - 1:
		role.append(ROLE_SIDE)
		tmid.append((ts[i] + ts[i + 1]) * 0.5)
	role.append_array([ROLE_PAINT, ROLE_PAINT])  # shoulder, shelf
	for i in vs.size() - 1:
		var mould := not far and i == 0
		var rail := not far and i == vs.size() - 2
		role.append(ROLE_MOULD if mould else (ROLE_RAIL if rail else ROLE_SIDE_GLASS))
	if far:
		for i in wr.size():
			role.append(ROLE_ROOF)
	else:
		role.append(ROLE_RAIL)  # roof rail and screen pillar
		for i in wr.size() - 1:
			role.append(ROLE_ROOF)
	while tmid.size() < role.size():
		tmid.append(0.0)
	var rows: Array = []
	var ao: Array = []
	var rx := PackedFloat32Array()
	var re := PackedFloat32Array()
	var x_r := xs[0]
	var x_f := xs[xs.size() - 1]
	var tail: Array = _section(s, x_r, ts, vs, wr, far)
	for i in range(ends.size() - 1, -1, -1):
		rows.append(_shrunk(tail[0], ends[i], x_r, -float(s["bulge_r"]), under, ts.size()))
		ao.append(tail[1])
		rx.append(x_r)
		re.append(-(1.0 - ends[i]))
	for x in xs:
		var sec: Array = _section(s, x, ts, vs, wr, far)
		rows.append(sec[0])
		ao.append(sec[1])
		rx.append(x)
		re.append(0.0)
	var nose: Array = _section(s, x_f, ts, vs, wr, far)
	for e in ends:
		rows.append(_shrunk(nose[0], e, x_f, float(s["bulge_f"]), under, ts.size()))
		ao.append(nose[1])
		rx.append(x_f)
		re.append(1.0 - e)
	for r in rows.size():
		var row: PackedVector3Array = rows[r]
		for i in row.size():
			row[i] = rake(s, row[i])
		rows[r] = row
	var bed := not far and bool(s["bed"])
	var bx: Vector2 = s["bed_x"]
	var keys := func(r: int, c: int) -> String:
		var xm := (rx[r] + rx[r + 1]) * 0.5
		var em := (re[r] + re[r + 1]) * 0.5
		if bed and em == 0.0 and role[c] == ROLE_ROOF and xm > bx.x and xm < bx.y:
			return ""
		return _key(s, role[c], tmid[c], xm, em, x_r, x_f, far)
	skin(lm, rows, keys, ao, true)
	if far or not bool(s["cabin"]):
		return
	# The cabin's lining: the body's own quads around the cabin, facing in
	# and dark, so what is seen through the glass is the inside of the car.
	var gh: PackedFloat32Array = s["gh"]
	var c0 := gh[0] - (0.02 if bed else 0.4)
	var c1 := gh[3] + 0.05
	var lining := func(r: int, c: int) -> String:
		var xm := (rx[r] + rx[r + 1]) * 0.5
		if xm < c0 or xm > c1:
			return ""
		var key: String = keys.call(r, c)
		return "" if key == "" or key == "Glass" else "Cabin"
	skin(lm, rows, lining, [], true, true)
	if bed:
		var c_roof := role.find(ROLE_ROOF)
		CarDetails.bed(lm, s, rows, rx, re, c_roof)

## The end section drawn in to `k` of its width and bowed out by
## `bulge` (signed along x), less toward the top so the face leans back.
## A low deck (bonnet, boot) keeps its crown: each point drawn in takes
## the deck's height where it lands, so the face rises to the crowned edge
## instead of the crown folding into a ridge at the centreline.
static func _shrunk(pts: PackedVector3Array, k: float, x: float, bulge: float, under: int,
		side_n: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var y_lo := pts[under].y
	var y_hi := pts[under + side_n - 1].y
	var d0 := under + side_n
	var deck := pts[pts.size() - 1].y - pts[d0].y < 0.2
	for i in pts.size():
		var p := pts[i]
		var hf := clampf((p.y - y_lo) / maxf(y_hi - y_lo, 0.01), 0.0, 1.0)
		var y := _deck_y(pts, d0, p.z * k) if deck and i >= d0 else p.y
		out.append(Vector3(x + bulge * (1.0 - k * k) * (1.0 - 0.35 * hf * hf), y, p.z * k))
	return out

## Height of the section's deck (points from `d0` on, running in to the
## centreline) at `z` across.
static func _deck_y(pts: PackedVector3Array, d0: int, z: float) -> float:
	if z >= pts[d0].z:
		return pts[d0].y
	for j in range(d0, pts.size() - 1):
		var a := pts[j]
		var b := pts[j + 1]
		if z >= b.z and a.z - b.z > 1e-5:
			return lerpf(b.y, a.y, (z - b.z) / (a.z - b.z))
	return pts[pts.size() - 1].y

## A point on an end face of the body: `end` is +1 at the nose and -1 at
## the tail, `k` the share of the half width across (signed; 0 on the
## centreline, 1 at the flank) and `t` the share of the face height (0 the
## floor, 1 the belt). It follows the rings body() lofts.
static func end_at(s: Dictionary, end: float, k: float, t: float) -> Vector3:
	var bulge := float(s["bulge_f"]) if end > 0.0 else float(s["bulge_r"])
	var xs := end * (float(s["len"]) * 0.5 - bulge)
	var fl := soft(s["floor"], xs, 0.06)
	var belt := soft(s["belt"], xs, 0.1)
	var y := lerpf(fl, belt, t)
	var w := side_w(s, xs, half_width(s, xs), t, y, belt)
	var x := xs + end * bulge * (1.0 - k * k) * (1.0 - 0.35 * t * t)
	return rake(s, Vector3(x, y, k * w))

## end_at() carried round the corner: `u` up to 1 crosses the end face
## (0 the centreline), beyond it runs back along the flank, u - 1 metres
## from the corner, on side `side` (+1 / -1).
static func face_point(s: Dictionary, end: float, side: float, u: float, t: float) -> Vector3:
	if u <= 1.0:
		return end_at(s, end, side * u, t)
	var bulge := float(s["bulge_f"]) if end > 0.0 else float(s["bulge_r"])
	var x := end * (float(s["len"]) * 0.5 - bulge - (u - 1.0))
	var fl := soft(s["floor"], x, 0.06)
	var belt := soft(s["belt"], x, 0.1)
	var y := lerpf(fl, belt, t)
	return rake(s, Vector3(x, y, side * side_w(s, x, half_width(s, x), t, y, belt)))

## The outward normal of the body at face_point().
static func face_normal(s: Dictionary, end: float, side: float, u: float, t: float) -> Vector3:
	var e := 0.02
	var du := face_point(s, end, side, u + e, t) - face_point(s, end, side, maxf(u - e, 0.0), t)
	var dt := face_point(s, end, side, u, t + e) - face_point(s, end, side, u, t - e)
	var n := du.cross(dt).normalized()
	var out := face_point(s, end, side, u, t) - Vector3(0.0, face_point(s, end, side, u, t).y, 0.0)
	if n.dot(out) < 0.0:
		n = -n
	return n

## The face at end_at(): x out of it, y up, z across.
static func end_frame(s: Dictionary, end: float, k: float, t: float) -> Basis:
	var dz := end_at(s, end, k + 0.03, t) - end_at(s, end, k - 0.03, t)
	var dy := end_at(s, end, k, t + 0.03) - end_at(s, end, k, t - 0.03)
	var n := dz.cross(dy).normalized()
	if n.x * end < 0.0:
		n = -n
	var up := (Vector3.UP - n * n.dot(Vector3.UP)).normalized()
	return Basis(n, up, n.cross(up))

## Height of the glasshouse top at (`x`, `z`): the roof, or the crowned
## deck under a windscreen, as _section() lofts it (centre span only).
static func roof_at(s: Dictionary, x: float, z: float) -> float:
	var gh: PackedFloat32Array = s["gh"]
	var belt := soft(s["belt"], x, 0.1)
	var w := half_width(s, x)
	var wd := w * lin(s["bulge"], 1.0) - 0.03
	var gb := minf(wd - float(s["shelf"]), w * lin(s["gh_w"], x))
	var crown := lin(s["crown"], x)
	var y0 := belt + 0.012 + crown * (1.0 - pow(gb / wd, 2.0))
	var top := maxf(belt + 0.012 + crown, soft(s["roof"], x, 0.07))
	var glassy := maxf(smoothstep(gh[2], gh[2] + 0.3, x), 1.0 - smoothstep(gh[1] - 0.3, gh[1], x))
	var rc := lerpf(float(s["roof_crown"]), float(s["glass_crown"]), glassy)
	var hside := maxf(y0, top - rc)
	var frac := clampf((hside - y0) / float(s["gh_full"]), 0.0, 1.0)
	var zt := gb - (float(s["tumble"]) + 0.02) * frac
	return hside + (top - hside) * (1.0 - pow(minf(absf(z) / zt, 1.0), 2.0))

## Half width of the roof (the glasshouse's top edge) at `x`.
static func roof_half(s: Dictionary, x: float) -> float:
	var belt := soft(s["belt"], x, 0.1)
	var w := half_width(s, x)
	var wd := w * lin(s["bulge"], 1.0) - 0.03
	var gb := minf(wd - float(s["shelf"]), w * lin(s["gh_w"], x))
	var crown := lin(s["crown"], x)
	var y0 := belt + 0.012 + crown * (1.0 - pow(gb / wd, 2.0))
	var top := maxf(belt + 0.012 + crown, soft(s["roof"], x, 0.07))
	var frac := clampf((maxf(y0, top - float(s["roof_crown"])) - y0) / float(s["gh_full"]), 0.0, 1.0)
	return gb - (float(s["tumble"]) + 0.02) * frac

## roof_at() as the near loft draws it: straight between its stations, so
## what lies on the glass touches it.
static func roof_on_mesh(s: Dictionary, x: float, z: float) -> float:
	var xs := _stations(s, false)
	var i := clampi(xs.bsearch(x), 1, xs.size() - 1)
	var t := clampf((x - xs[i - 1]) / maxf(xs[i] - xs[i - 1], 0.0001), 0.0, 1.0)
	return lerpf(roof_at(s, xs[i - 1], z), roof_at(s, xs[i], z), t)

## Material key of a body quad: `t` up the side, `xm` its station, `em`
## its depth into the front (+) or rear (-) face (0 on the flanks).
static func _key(s: Dictionary, role: int, t: float, xm: float, em: float, x_r: float, x_f: float,
		far: bool) -> String:
	match role:
		ROLE_UNDER:
			return "Rubber"
		ROLE_PAINT:
			return "Paint"
		ROLE_RAIL:
			# Gloss-black pillars and rails float the roof over the glass.
			var ghr: PackedFloat32Array = s["gh"]
			if bool(s["black_pillars"]) and em == 0.0 and xm > ghr[0] and xm < ghr[3]:
				return "Trim"
			return "Paint"
		ROLE_MOULD:
			return "Chrome" if bool(s["chrome"]) and not far else "Trim"
		ROLE_SIDE_GLASS:
			# An upright tail carries its window in the rear face.
			if em < -0.1 and bool(s["tail_glass"]):
				return "Glass"
			var sg: Vector2 = s["side_glass"]
			if em != 0.0 or xm < sg.x or xm > sg.y:
				var ghs: PackedFloat32Array = s["gh"]
				return "Trim" if bool(s["black_pillars"]) and em == 0.0 and xm > ghs[0] and xm < ghs[3] else "Paint"
			# Far off the pillars are too thin to read: they would only flash.
			# A bus's posts take the body colour: dark glass between black
			# posts reads as one black slab.
			var post := "Paint" if float(s["len"]) > 8.0 else "Trim"
			for p: Vector2 in (s["pillars"] if not far else []):
				if xm > p.x and xm < p.y:
					return post
			return "Glass"
		ROLE_ROOF:
			var gh: PackedFloat32Array = s["gh"]
			if em == 0.0 and xm > gh[2] and xm < float(s["board_x"]):
				return "Board"
			if em == 0.0 and ((xm > gh[2] and xm < gh[3]) or (xm > gh[0] and xm < gh[1])):
				return "Glass"
			# A glass roof panel between the screens' headers.
			if bool(s["roof_glass"]) and em == 0.0 and xm > gh[1] + 0.14 and xm < gh[2] - 0.14:
				return "Glass"
			return "Paint"
	# Near to, the lamps are clusters laid on the paint (CarParts.lamps).
	var front := far and (em > 0.0 or xm > x_f - float(s["lamp_wrap_f"]))
	var rear := far and (em < 0.0 or xm < x_r + float(s["lamp_wrap"]))
	if front:
		# Between the lamps the paint carries the drawn grille (CarPaint).
		var lamp: Vector2 = s["lamp_f"]
		if t > lamp.x and t < lamp.y and em < float(s["lamp_in"]):
			return "HeadLamp"
	if rear:
		var lamp: Vector2 = s["lamp_r"]
		if t > lamp.x and t < lamp.y and -em < float(s["lamp_in_r"]):
			return "TailLamp"
	# The black bumper skirt runs back along the flank to the arch's edge,
	# so no body-coloured skirt hangs below it ahead of the wheel.
	var arch_f := float(s["axle_f"]) + float(s["arch_r"]) + 0.03
	var arch_r := float(s["axle_r"]) - float(s["arch_r"]) - 0.03
	if (em > 0.0 or xm > minf(x_f - 0.3, arch_f)) and t < float(s["valance"]):
		return "Trim"
	if (em < 0.0 or xm < maxf(x_r + 0.3, arch_r)) and t < float(s["valance_r"]):
		return "Trim"
	if t < float(s["clad"]):
		return "Trim"
	return "Paint"
