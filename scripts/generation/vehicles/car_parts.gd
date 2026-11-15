class_name CarParts
extends RefCounted

## Modelled parts of the procedural cars (CarModel), on LandmarkMesh in
## the car's frame (metres; +X forward, wheels on y = 0):
## * wheel(): a tyre with rounded shoulders on a dished alloy: tapered
##   spokes (single or paired) falling from the rim lip to a recessed hub,
##   a brake disc and caliper behind them.
## * lamps(): head and tail lamp clusters laid a few millimetres over the
##   paint and carried round the corner onto the flank (VehicleKit
##   face_point): a dark bezel, the lens, a light guide along its top (head)
##   or across it (tail), projectors, the indicator and the reversing lamp.
##   A head lamp narrows toward its inner end by the spec's lamp_taper.
## * mirror(): a door mirror, its housing sunk into the door's top edge,
##   its glass facing back and a repeater on its nose.

## Lift of the lamp layers off the paint (metres): bezel, lens, inserts.
const BEZEL_LIFT := 0.004
const LENS_LIFT := 0.007
const INSERT_LIFT := 0.012

## A road wheel on its axle at `centre`, outer face toward `side`. Keys:
## Rubber (tyre, the dark behind the spokes), Rim, Trim (caliper, cap badge).
static func wheel(lm: LandmarkMesh, centre: Vector3, r: float, width: float, side: float,
		far: bool, spokes: int = 5, twin: bool = false) -> void:
	var hw := width * 0.5
	var rr := r * 0.7
	if far:
		VehicleKit.revolve(lm, "Rubber", centre, PackedVector2Array([Vector2(rr, -hw), Vector2(r, -hw),
			Vector2(r, hw), Vector2(rr, hw)]), 12, side, false)
		lm.disc("Rim", centre + Vector3(0, 0, side * hw * 0.98), Vector3(0, 0, side), rr, 12)
		return
	VehicleKit.revolve(lm, "Rubber", centre, PackedVector2Array([Vector2(rr * 1.02, -hw * 0.86),
		Vector2(r * 0.84, -hw * 0.98), Vector2(r * 0.95, -hw * 0.9), Vector2(r * 0.995, -hw * 0.68),
		Vector2(r, -hw * 0.3), Vector2(r, hw * 0.3), Vector2(r * 0.995, hw * 0.68), Vector2(r * 0.95, hw * 0.9),
		Vector2(r * 0.84, hw * 0.98), Vector2(rr * 1.02, hw * 0.86)]), 32, side)
	# Rim: a lip proud of the tyre's bead, the barrel inside it, then the
	# dark back the spokes stand against.
	VehicleKit.revolve(lm, "Rim", centre, PackedVector2Array([Vector2(rr * 1.02, hw * 0.86),
		Vector2(rr * 1.0, hw * 0.93), Vector2(rr * 0.95, hw * 0.95), Vector2(rr * 0.92, hw * 0.88),
		Vector2(rr * 0.9, hw * 0.2)]), 32, side, false)
	lm.disc("Rubber", centre + Vector3(0, 0, side * hw * 0.2), Vector3(0, 0, side), rr * 0.9, 24)
	# Brake disc, and its caliper at the back of it.
	lm.disc("Rim", centre + Vector3(0, 0, side * hw * 0.32), Vector3(0, 0, side), rr * 0.7, 24)
	var cal := Vector3(-0.55, 0.62, 0.0).normalized()
	lm.box("Trim", centre + cal * rr * 0.6 + Vector3(0, 0, side * hw * 0.42),
		Vector3(rr * 0.28, rr * 0.34, hw * 0.3), Basis(Vector3(0, 0, 1), atan2(cal.y, cal.x)), 0.01)
	var hub := hw * 0.6
	for k in spokes:
		var a := TAU * float(k) / float(spokes) + PI * 0.5
		if twin:
			for d: float in [-0.13, 0.13]:
				_spoke(lm, centre, side, a + d * TAU / float(spokes), rr, hw, hub, 0.5)
		else:
			_spoke(lm, centre, side, a, rr, hw, hub, 1.0)
	# The hub: a domed cap with a dark badge.
	VehicleKit.revolve(lm, "Rim", centre, PackedVector2Array([Vector2(rr * 0.24, hub - 0.004),
		Vector2(rr * 0.23, hub + 0.02), Vector2(rr * 0.15, hub + 0.03), Vector2(0.0, hub + 0.032)]), 20, side, true)
	lm.disc("Trim", centre + Vector3(0, 0, side * (hub + 0.0325)), Vector3(0, 0, side), rr * 0.09, 14)

## One spoke from the hub out to the rim lip at angle `a`: its face falls
## from the lip into the dish, tapering in toward the hub; `wk` scales its
## width (paired spokes are thin).
static func _spoke(lm: LandmarkMesh, centre: Vector3, side: float, a: float, rr: float, hw: float,
		hub: float, wk: float) -> void:
	var dir := Vector3(cos(a), sin(a), 0.0)
	var across := Vector3(-dir.y, dir.x, 0.0)
	var z := Vector3(0, 0, side)
	var depth := 0.022
	var rows: Array = []
	for i in 5:
		var f := float(i) / 4.0
		var rho := lerpf(rr * 0.2, rr * 0.93, f)
		var face := lerpf(hub + 0.012, hw * 0.9, pow(f, 1.6))
		var w := lerpf(rr * 0.17, rr * 0.25, f) * wk
		var c := centre + dir * rho
		rows.append(PackedVector3Array([c + across * w * 0.5 + z * (face - depth),
			c + across * w * 0.42 + z * face, c - across * w * 0.42 + z * face,
			c - across * w * 0.5 + z * (face - depth)]))
	var p0: PackedVector3Array = rows[0]
	var p1: PackedVector3Array = rows[1]
	var n := (p1[2] - p0[1]).cross(p0[2] - p1[1])
	VehicleKit.skin(lm, rows, func(_r: int, _c: int) -> String: return "Rim", [], false, n.dot(z) < 0.0)

## Head (`end` +1) or tail (-1) lamp clusters on both sides, inner edge at
## `u_in` (share of the half width across the end face).
static func lamps(lm: LandmarkMesh, s: Dictionary, end: float, u_in: float) -> void:
	var front := end > 0.0
	var lamp: Vector2 = s["lamp_f"] if front else s["lamp_r"]
	var u_out := 1.0 + float(s["wrap_f"] if front else s["wrap_r"])
	var taper := float(s["lamp_taper_f"] if front else s["lamp_taper_r"])
	var face_h := VehicleKit.end_at(s, end, 0.0, 1.0).y - VehicleKit.end_at(s, end, 0.0, 0.0).y
	var m := 0.008 / maxf(face_h, 0.1)
	var span := lamp.y - lamp.x
	# The lens's outline at share `a` from its inner end to its outer:
	# (bottom, top), narrowing inward by the taper and rounded at both ends.
	var band := func(a: float) -> Vector2:
		var hs := lerpf(taper, 1.0, smoothstep(0.0, 0.7, a))
		var top := lamp.y
		var foot := lamp.y - span * hs
		var pinch := 1.0 - 0.45 * pow(absf(a * 2.0 - 1.0), 6.0)
		var mid := (top + foot) * 0.5
		return Vector2(mid + (foot - mid) * pinch, mid + (top - mid) * pinch)
	# An insert inside the lens: shares a0..a1 along it, f0..f1 up it, so it
	# follows the outline and never crosses it.
	var inset := func(a0: float, a1: float, f0: float, f1: float) -> Callable:
		return func(a: float) -> Vector2:
			var b: Vector2 = band.call(lerpf(a0, a1, a))
			return Vector2(lerpf(b.x, b.y, f0), lerpf(b.x, b.y, f1))
	var at := func(a: float) -> float: return lerpf(u_in, u_out, a)
	for side: float in [1.0, -1.0]:
		var outer := func(a: float) -> Vector2:
			var b: Vector2 = band.call(a)
			return Vector2(b.x - m, b.y + m)
		# The bezel: the lens's own outline grown by a thin rim top and foot,
		# ending with it so no dark ends stand proud of the lens.
		patch(lm, s, end, side, "Trim", u_in, u_out, outer, BEZEL_LIFT, false, false)
		patch(lm, s, end, side, "HeadLamp" if front else "TailLamp", u_in, u_out, band, LENS_LIFT, false, false)
		if front:
			# A light guide along the top, then two projectors and the indicator.
			patch(lm, s, end, side, "Drl", at.call(0.08), at.call(0.94), inset.call(0.08, 0.94, 0.76, 0.9),
				INSERT_LIFT, false, false)
			var ls := clampf(span * face_h / 0.14, 1.0, 2.2)
			for a: float in [0.42, 0.68]:
				var b: Vector2 = band.call(a)
				var u: float = at.call(a)
				var t := lerpf(b.x, b.y, 0.38)
				var n := VehicleKit.face_normal(s, end, side, u, t)
				var p := VehicleKit.face_point(s, end, side, u, t)
				lm.disc("Trim", p + n * INSERT_LIFT, n, 0.036 * ls, 16)
				lm.disc("Chrome", p + n * (INSERT_LIFT + 0.002), n, 0.026 * ls, 14)
				lm.disc("HeadLamp", p + n * (INSERT_LIFT + 0.004), n, 0.014 * ls, 12)
			patch(lm, s, end, side, "Amber", at.call(0.82), at.call(0.95), inset.call(0.82, 0.95, 0.12, 0.4),
				INSERT_LIFT, false, false)
		else:
			# A glowing bar across the cluster, the reversing lamp at its inner
			# end and the indicator below the bar toward the outer.
			patch(lm, s, end, side, "TailGlow", at.call(0.2), at.call(0.93), inset.call(0.2, 0.93, 0.58, 0.76),
				INSERT_LIFT, false, false)
			patch(lm, s, end, side, "HeadLamp", at.call(0.06), at.call(0.16), inset.call(0.06, 0.16, 0.22, 0.78),
				INSERT_LIFT, false, false)
			patch(lm, s, end, side, "Amber", at.call(0.55), at.call(0.9), inset.call(0.55, 0.9, 0.2, 0.42),
				INSERT_LIFT, false, false)

## A sheet `lift` off the body over u in [u0, u1] (face_point), each column
## spanning the (bottom, top) shares band.call(a) gives at its share `a`
## along the patch. Its ends are rounded off unless `round_in` / `round_out`
## say not (a patch meeting its mirror at the centreline keeps that edge).
static func patch(lm: LandmarkMesh, s: Dictionary, end: float, side: float, key: String, u0: float, u1: float,
		band: Callable, lift: float, round_in: bool = true, round_out: bool = true, nt: int = 3) -> void:
	var nu := 18
	# Shares along the patch, one of them moved onto the body's corner
	# (u = 1) where the patch wraps it: a sheet spanning the corner between
	# two samples would cut through it.
	var shares := PackedFloat32Array()
	for i in nu + 1:
		shares.append(float(i) / float(nu))
	if u0 < 1.0 and u1 > 1.0:
		var ac := (1.0 - u0) / (u1 - u0)
		var near := clampi(roundi(ac * float(nu)), 1, nu - 1)
		shares[near] = ac
	var on: Array = []
	for j in nt + 1:
		var row := PackedVector3Array()
		var ft := float(j) / float(nt)
		for i in nu + 1:
			var a := shares[i]
			var b: Vector2 = band.call(a)
			# Round the ends: the outer columns pinch toward the band's middle.
			var pinch := 1.0
			if (a < 0.5 and round_in) or (a >= 0.5 and round_out):
				pinch = 1.0 - 0.45 * pow(absf(a * 2.0 - 1.0), 6.0)
			var mid := (b.x + b.y) * 0.5
			row.append(VehicleKit.face_point(s, end, side, lerpf(u0, u1, a), mid + (lerpf(b.x, b.y, ft) - mid) * pinch))
		on.append(row)
	# Lift each point along the sheet's own normal, oriented out of the body.
	var c := nu / 2
	var out := VehicleKit.face_normal(s, end, side, lerpf(u0, u1, 0.5), (band.call(0.5) as Vector2).x)
	var rows: Array = []
	for j in nt + 1:
		var row := PackedVector3Array()
		var here: PackedVector3Array = on[j]
		var below: PackedVector3Array = on[maxi(j - 1, 0)]
		var above: PackedVector3Array = on[mini(j + 1, nt)]
		for i in nu + 1:
			var n := (here[mini(i + 1, nu)] - here[maxi(i - 1, 0)]).cross(above[i] - below[i]).normalized()
			if n.dot(out) < 0.0:
				n = -n
			row.append(here[i] + n * lift)
		rows.append(row)
	# skin() faces each quad along (row step) x (column step); turn it out.
	var p0: PackedVector3Array = rows[1]
	var p1: PackedVector3Array = rows[2]
	var n := (p1[c + 1] - p0[c]).cross(p0[c + 1] - p1[c])
	VehicleKit.skin(lm, rows, func(_r: int, _c: int) -> String: return key, [], false, n.dot(out) < 0.0)

## A door mirror on side `side` at the window's front corner.
static func mirror(lm: LandmarkMesh, s: Dictionary, side: float) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var f := clampf(float(s["wid"]) / 1.8, 1.0, 1.35)
	var x := gh[3] - float(s["a_gap"]) * 0.5 - 0.04
	var belt := VehicleKit.soft(s["belt"], x, 0.1)
	var wb := VehicleKit.side_w(s, x, VehicleKit.half_width(s, x), 1.0, belt, belt)
	# One housing, its inner end sunk into the door's top edge so it
	# springs from the body: no gap, no separate arm.
	var half := Vector3(0.07 * f, 0.06 * f, 0.11)
	var c := Vector3(x - 0.02 * f, belt + 0.012 + half.y * 0.8, side * (wb + half.z - 0.045))
	VehicleKit.blob(lm, "Paint", c, half, 6, 12)
	# The mirror itself, set in the housing's back.
	lm.box("Chrome", c - Vector3(half.x * 0.62, 0.0, -side * 0.025), Vector3(0.02, half.y * 1.45, half.z * 1.25), Basis(), 0.006)
	# A repeater on the leading edge, toward the tip.
	lm.box("Amber", c + Vector3(half.x * 0.62, -half.y * 0.3, side * half.z * 0.45),
		Vector3(0.02, 0.014 * f, half.z * 0.7), Basis(), 0.0)
