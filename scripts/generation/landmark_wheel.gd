class_name LandmarkWheel
extends RefCounted

## Observation wheel (OSM attraction=big_wheel: London Eye, Wiener
## Riesenrad, Singapore Flyer...) in true metres: a twin-rim truss, cable
## spokes to a horizontal hub, glazed capsules outside the rim, and
## A-frame legs on both sides. The wheel stands in the local YZ plane
## (axle along X), so the footprint's long side, which OSM maps along
## the wheel, runs along local Z like every other archetype. Detail
## after the London Eye and Singapore Flyer: the capsule rail outside
## the rim truss, a flanged hub, ovoid capsules with end rings, braced
## A-frames on footings and a canopied boarding platform.

## `h` = overall height (top of the highest capsule), `l` = footprint
## length along the wheel. Mapped footprints that cover only the base
## (shorter than ~0.6 h) fall back to a diameter from the height.
## Largest wheel diameter per unit of overall height (the rest is the
## capsules above the rim and the clearance under it).
const DIAMETER_PER_HEIGHT := 0.88

static func build(lm: LandmarkMesh, h: float, l: float) -> void:
	lm.use("Steel", LandmarkMaterials.paint("#E6E9EC", 0.45, 0.55))
	lm.use("Cable", LandmarkMaterials.paint("#B9C0C7", 0.5, 0.7))
	lm.use("Capsule", LandmarkMaterials.glass("#7F97A6"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB9B0", 4.0))
	var d := l if l >= h * 0.6 else h * DIAMETER_PER_HEIGHT
	d = minf(d, h * DIAMETER_PER_HEIGHT)
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
	# Capsule rail: a third ring outside the truss that the capsules'
	# bearing rings run on, braced back to the rim.
	for k in seg:
		lm.beam("Steel", hub + pts[k] * (1.0 + cs * 0.2 / r), hub + pts[(k + 1) % seg] * (1.0 + cs * 0.2 / r),
			rim_w * 0.6, rim_w * 0.6, Vector3.RIGHT)
	# Cable spokes fan from both hub ends to the opposite rims, so the
	# wheel reads as a bicycle wheel rather than a solid disc.
	var hub_len := clampf(d * 0.12, 2.0, 16.0)
	var cable := clampf(d * 0.003, 0.12, 0.4)
	for k in seg:
		for sx in [-1.0, 1.0]:
			if (k % 2 == 0) == (sx > 0.0):
				lm.beam("Cable", hub + Vector3(sx * hub_len * 0.5, 0, 0),
					hub + pts[k] + Vector3(-sx * rim_off, 0, 0), cable)
	# Hub: spindle, the two spoke flanges and bearing housings.
	var hr := clampf(d * 0.035, 1.0, 5.0)
	lm.beam("Steel", hub + Vector3(-hub_len * 0.5 - hr * 0.4, 0, 0), hub + Vector3(hub_len * 0.5 + hr * 0.4, 0, 0),
		hr * 0.8, hr * 0.8, Vector3.UP, true)
	for sx in [-1.0, 1.0]:
		lm.disc("Steel", hub + Vector3(sx * hub_len * 0.5, 0, 0), Vector3(sx, 0, 0), hr * 1.3, 24)
		lm.disc("Steel", hub + Vector3(sx * hub_len * 0.5 - sx * 0.05, 0, 0), Vector3(-sx, 0, 0), hr * 1.3, 24)
		lm.beam("Steel", hub + Vector3(sx * (hub_len * 0.5 + hr * 0.3), 0, 0),
			hub + Vector3(sx * (hub_len * 0.5 + hr * 0.9), 0, 0), hr * 1.1, hr * 1.1, Vector3.UP, true)
	# Capsules ride outside the rim, long axis parallel to the axle, and
	# hang upright like real gondolas (they never tilt with the rim):
	# glazed ovoid shells with steel end rings, floor pan and mounting.
	var n := clampi(int(round(d * 0.26)), 12, 40)
	var cap_prof := PackedVector2Array([Vector2(0.0, -cs * 0.75), Vector2(cs * 0.28, -cs * 0.68),
		Vector2(cs * 0.4, -cs * 0.4), Vector2(cs * 0.42, 0.0), Vector2(cs * 0.4, cs * 0.4),
		Vector2(cs * 0.28, cs * 0.68), Vector2(0.0, cs * 0.75)])
	for k in n:
		var a := TAU * float(k) / float(n)
		var dir := Vector3(0, cos(a), sin(a))
		var c := hub + dir * (r + cs * 0.65)
		_capsule(lm, c, cap_prof, cs)
		lm.beam("Steel", hub + dir * (r + cs * 0.2), c - dir * cs * 0.35, rim_w * 0.5)
		lm.beam("Steel", c - dir * cs * 0.35 - Vector3(cs * 0.5, 0, 0), c - dir * cs * 0.35 + Vector3(cs * 0.5, 0, 0),
			rim_w * 0.4)
	# A-frame legs from footings to each end of the hub, braced by
	# horizontal struts and diagonal lattice between the pair.
	var spread := clampf(d * 0.2, 3.0, 26.0)
	var leg_w := clampf(d * 0.022, 0.6, 3.0)
	var fh := leg_w + 0.4
	for sx in [-1.0, 1.0]:
		var top := hub + Vector3(sx * (hub_len * 0.5 + hr * 0.9), 0, 0)
		var feet: Array[Vector3] = []
		for sz in [-1.0, 1.0]:
			var foot := Vector3(sx * spread, fh, sz * r * 0.42)
			feet.append(foot)
			lm.beam("Steel", foot, top, leg_w)
			lm.box("Concrete", Vector3(foot.x, fh * 0.5, foot.z), Vector3(leg_w * 3.0, fh, leg_w * 3.0))
		var rungs := 4
		var prev_a: Vector3 = feet[0]
		for i in range(1, rungs + 1):
			var t := float(i) / float(rungs + 1)
			var pa: Vector3 = feet[0].lerp(top, t)
			var pb: Vector3 = feet[1].lerp(top, t)
			lm.beam("Steel", pa, pb, leg_w * 0.45)
			lm.beam("Steel", prev_a, pb, leg_w * 0.3)
			prev_a = pa
	# Boarding platform under the wheel: deck, steps and a canopy.
	var pl := Vector3(spread * 1.2, 1.2, r * 0.7)
	lm.box("Concrete", Vector3(0, pl.y * 0.5, 0), pl)
	for i in 3:
		lm.box("Concrete", Vector3(0, pl.y * (float(i) + 0.5) / 3.0, -pl.z * 0.5 - 0.4 * (3.0 - float(i))),
			Vector3(pl.x * 0.3, pl.y / 3.0, 0.4 * (3.0 - float(i)) * 2.0))
	var ch := pl.y + 3.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(sx * pl.x * 0.45, pl.y, sz * pl.z * 0.45), Vector3(sx * pl.x * 0.45, ch, sz * pl.z * 0.45),
				0.25)
	lm.box("Capsule", Vector3(0, ch + 0.1, 0), Vector3(pl.x * 0.95, 0.15, pl.z * 0.95), Basis(), 0.0)
	lm.box("Steel", Vector3(0, ch - 0.1, 0), Vector3(pl.x * 0.96, 0.25, pl.z * 0.96), Basis(), 0.0)

## One capsule at `c`: an ovoid glass shell (long axis along X), steel
## end rings and a floor pan.
static func _capsule(lm: LandmarkMesh, c: Vector3, prof: PackedVector2Array, cs: float) -> void:
	var b := Basis(Vector3.BACK, PI * 0.5)
	var pts: Array = []
	for k in prof.size():
		var ring := PackedVector3Array()
		for i in 11:
			var t := TAU * float(i) / 10.0
			ring.append(c + b * Vector3(cos(t) * prof[k].x, prof[k].y, sin(t) * prof[k].x * 1.1))
		pts.append(ring)
	lm.grid("Capsule", pts, c, true)
	for sx in [-1.0, 1.0]:
		var rr := cs * 0.36
		var prev := c + Vector3(sx * cs * 0.55, rr, 0)
		for i in range(1, 9):
			var t := TAU * float(i) / 8.0
			var p := c + Vector3(sx * cs * 0.55, cos(t) * rr, sin(t) * rr * 1.1)
			lm.beam("Steel", prev, p, cs * 0.06, cs * 0.06, Vector3.RIGHT)
			prev = p
	lm.box("Steel", c - Vector3(0, cs * 0.3, 0), Vector3(cs * 1.2, cs * 0.06, cs * 0.6), Basis(), 0.0)
