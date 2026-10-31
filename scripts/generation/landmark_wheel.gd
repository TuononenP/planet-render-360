class_name LandmarkWheel
extends RefCounted

## Observation wheel (OSM attraction=big_wheel: London Eye, Wiener
## Riesenrad, Singapore Flyer...) in true metres: a twin-rim truss, cable
## spokes to a horizontal hub, glazed capsules outside the rim, and
## A-frame legs on both sides. The wheel stands in the local YZ plane
## (axle along X), so the footprint's long side, which OSM maps along
## the wheel, runs along local Z like every other archetype.

## `h` = overall height (top of the highest capsule), `l` = footprint
## length along the wheel. Mapped footprints that cover only the base
## (shorter than ~0.6 h) fall back to a diameter from the height.
static func build(lm: LandmarkMesh, h: float, l: float) -> void:
	lm.use("Steel", LandmarkMaterials.paint("#E6E9EC", 0.45, 0.55))
	lm.use("Cable", LandmarkMaterials.paint("#B9C0C7", 0.5, 0.7))
	lm.use("Capsule", LandmarkMaterials.glass("#7F97A6"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB9B0", 4.0))
	var d := l if l >= h * 0.6 else h * 0.88
	d = minf(d, h * 0.88)
	var r := d * 0.5
	var cs := clampf(d * 0.035, 1.2, 5.0)  # capsule size
	var hub_y := maxf(h - r - cs * 1.1, r + cs * 1.5)
	var hub := Vector3(0, hub_y, 0)
	var rim_off := clampf(d * 0.04, 0.8, 4.0)
	var rim_w := clampf(d * 0.012, 0.35, 1.6)
	var seg := 48
	var pts: Array[Vector3] = []
	for k in seg:
		var a := TAU * float(k) / float(seg)
		pts.append(Vector3(0, cos(a) * r, sin(a) * r))
	# Twin rims tied into a truss by rungs and zigzag diagonals.
	for k in seg:
		var p0: Vector3 = pts[k]
		var p1: Vector3 = pts[(k + 1) % seg]
		for sx in [-1.0, 1.0]:
			var o := Vector3(sx * rim_off, 0, 0)
			lm.beam("Steel", hub + p0 + o, hub + p1 + o, rim_w, rim_w, Vector3.RIGHT)
		lm.beam("Steel", hub + p0 + Vector3(-rim_off, 0, 0), hub + p0 + Vector3(rim_off, 0, 0),
			rim_w * 0.6)
		lm.beam("Steel", hub + p0 + Vector3(-rim_off, 0, 0), hub + p1 + Vector3(rim_off, 0, 0),
			rim_w * 0.4)
	# Cable spokes fan from both hub ends to the opposite rims, so the
	# wheel reads as a bicycle wheel rather than a solid disc.
	var hub_len := clampf(d * 0.12, 2.0, 16.0)
	var cable := clampf(d * 0.003, 0.12, 0.4)
	for k in range(0, seg, 2):
		for sx in [-1.0, 1.0]:
			lm.beam("Cable", hub + Vector3(sx * hub_len * 0.5, 0, 0),
				hub + pts[k] + Vector3(-sx * rim_off, 0, 0), cable)
	lm.beam("Steel", hub + Vector3(-hub_len * 0.5, 0, 0), hub + Vector3(hub_len * 0.5, 0, 0),
		clampf(d * 0.035, 1.0, 5.0))
	# Capsules ride outside the rim, long axis parallel to the axle.
	var n := clampi(int(round(d * 0.26)), 12, 40)
	for k in n:
		var a := TAU * float(k) / float(n)
		var dir := Vector3(0, cos(a), sin(a))
		var c := hub + dir * (r + cs * 0.65)
		var basis := Basis(Vector3.RIGHT, -a)
		lm.box("Capsule", c, Vector3(cs * 1.5, cs * 0.8, cs * 0.8), basis)
		for sx in [-1.0, 1.0]:
			lm.box("Steel", c + Vector3(sx * cs * 0.75, 0, 0), Vector3(cs * 0.08, cs * 0.85, cs * 0.85), basis)
		lm.beam("Steel", hub + dir * r, c - dir * cs * 0.4, rim_w * 0.5)
	# A-frame legs from a splayed footing to each end of the hub.
	var spread := clampf(d * 0.2, 3.0, 26.0)
	var leg_w := clampf(d * 0.022, 0.6, 3.0)
	for sx in [-1.0, 1.0]:
		var top := hub + Vector3(sx * hub_len * 0.5, 0, 0)
		for sz in [-1.0, 1.0]:
			var foot := Vector3(sx * spread, 0, sz * r * 0.42)
			lm.beam("Steel", foot, top, leg_w)
			lm.box("Concrete", foot + Vector3(0, 0.5, 0), Vector3(leg_w * 3.0, 1.0, leg_w * 3.0))
		lm.beam("Steel", Vector3(sx * spread * 0.55, hub_y * 0.45, -r * 0.23),
			Vector3(sx * spread * 0.55, hub_y * 0.45, r * 0.23), leg_w * 0.6)
	# Boarding platform under the wheel.
	lm.box("Concrete", Vector3(0, 0.6, 0), Vector3(spread * 1.2, 1.2, r * 0.7))
