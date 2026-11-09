class_name LandmarkLondonEye
extends RefCounted

## London Eye (Marks Barfield, 1999/2000) in true metres: a 120 m
## cantilevered observation wheel on the South Bank, 135 m to the top of
## the highest capsule (OSM: height 136.5, min_height 1.5, so the lowest
## capsule floats 1.5 m above the boarding pier). Local frame: the wheel
## turns in the YZ plane, axle along +X, and the model is yawed -10 deg
## about Y at the end so the axle runs along OSM's bearing 99-101 deg
## (the wheel plane is rotated 11 deg from north-south; +X is then the
## landward east side). Dimensions used:
## - Rim: a 120 m ring (outer chords on the 119.6 m circle) as a
##   triangular-section truss, two 0.84 m outer chords 2.7 m apart and a
##   single 0.64 m inner chord 2.8 m below them, laced in a Warren
##   pattern over 64 bays; the 64 spoke cables (70 mm) alternate from the
##   two hub flanges to the 64 inner-chord nodes, 16 rotation cables
##   (two sets of eight, opposite hands on each face) run tangent to
##   the hub.
## - Spindle 23 m long with the cast hub drum, two cable flanges and a
##   tail housing carrying the A-frame yoke on the east side.
## - A-frame: two tubular legs (2 m diameter) 20 m apart at the base,
##   about 58 m long, leaning 65 degrees over the river from trunnions
##   on tall concrete pillars (44 piles) in Jubilee Gardens; six
##   backstays (four to the A-frame head, two to the spindle tail) run
##   to the 1,200 t tension foundation to the east.
## - 32 ovoid capsules (10 t, 25 passengers): glass ovoids 8 m long and
##   4.2 m high on a horizontal X axis, each held between two mounting
##   rings that turn on arms from the outside of the rim so the floor
##   stays level; the lowest sits at the boarding pier.
## - The boarding pier at the foot of the wheel.

const HUB_Y := 68.2
const RIM_R := 59.8
const INNER_R := 57.0
const CAP_R := 64.9
const BAYS := 64
const CAPSULES := 32
const SPINDLE_HALF := 11.5
const FLANGE_X := 8.0
const AXLE_YAW_DEG := -10.0
## Half length and radius of the capsule ovoid, bearing rings at +-2.75.
const CAP_HALF := 4.0
const CAP_RAD := 2.1
const A_TOP_X := 9.5
const A_FOOT_X := 34.0
const A_FOOT_Y := 13.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#EEF0F2", 0.45, 0.55))
	lm.use("Cable", LandmarkMaterials.paint("#B9C0C7", 0.5, 0.7))
	lm.use("Capsule", LandmarkMaterials.glass("#7F97A6"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB9B0", 4.0))
	_rim(lm)
	_hub(lm)
	for k in CAPSULES:
		_capsule(lm, TAU * float(k) / float(CAPSULES))
	_a_frame(lm)
	_pier(lm)
	var yaw := deg_to_rad(AXLE_YAW_DEG)
	for mi in lm.commit(model):
		mi.rotation.y = yaw

## Point on the wheel at angle a (0 = top, turning toward +Z), radius r
## from the axle and x along it.
static func _pt(a: float, r: float, x: float) -> Vector3:
	return Vector3(x, HUB_Y + cos(a) * r, sin(a) * r)

## Tapered round member a-b: radius r0 at a, r1 at b.
static func _taper(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r0: float,
		r1: float, seg: int) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := axis.cross(u)
	for i in seg:
		var d0 := u * cos(TAU * float(i) / float(seg)) + v * sin(TAU * float(i) / float(seg))
		var d1 := u * cos(TAU * float(i + 1) / float(seg)) + v * sin(TAU * float(i + 1) / float(seg))
		lm.quad(key, a + d0 * r0, a + d1 * r0, b + d1 * r1, b + d0 * r1, (d0 + d1).normalized())

## The rim truss and the spoke network.
static func _rim(lm: LandmarkMesh) -> void:
	var step := TAU / float(BAYS)
	for k in BAYS:
		var a0 := step * float(k)
		var a1 := step * float(k + 1)
		var am := (a0 + a1) * 0.5
		for sx in [-1.35, 1.35]:
			var x: float = sx
			LandmarkWestKit.tube(lm, "Steel", _pt(a0, RIM_R, x), _pt(a1, RIM_R, x), 0.42, 6)
			# Warren lacing: outer node, down to the inner chord, back out.
			lm.beam("Steel", _pt(a0, RIM_R, x), _pt(am, INNER_R, 0.0), 0.2)
			lm.beam("Steel", _pt(am, INNER_R, 0.0), _pt(a1, RIM_R, x), 0.2)
		LandmarkWestKit.tube(lm, "Steel", _pt(a0, INNER_R, 0.0), _pt(a1, INNER_R, 0.0), 0.32, 6)
		# Transverse frame at the node and the diagonal across the outer chords.
		lm.beam("Steel", _pt(a0, RIM_R, -1.35), _pt(a0, RIM_R, 1.35), 0.22)
		lm.beam("Steel", _pt(a0, RIM_R, -1.35), _pt(a1, RIM_R, 1.35), 0.16)
		# One spoke cable per node, alternating between the two flanges.
		var fx := -FLANGE_X if k % 2 == 0 else FLANGE_X
		lm.beam("Cable", _pt(a0, 4.1, fx), _pt(a0, INNER_R, 0.0), 0.2)
	# Rotation cables: eight a face, tangent to the hub drum, opposite hands.
	var lead := acos(3.4 / INNER_R)
	for face in [-1.0, 1.0]:
		var f: float = face
		for i in 8:
			var b := TAU * float(i) / 8.0 + (0.0 if f < 0.0 else TAU / 16.0)
			var rim_a := roundf((b - f * lead) / step) * step
			lm.beam("Cable", _pt(b, 3.5, f * FLANGE_X), _pt(rim_a, INNER_R, 0.0), 0.16)

## Spindle, cast hub drum, cable flanges and the tail housing.
static func _hub(lm: LandmarkMesh) -> void:
	var hub := Vector3(0, HUB_Y, 0)
	LandmarkWestKit.tube(lm, "Steel", hub + Vector3(-SPINDLE_HALF, 0, 0), hub + Vector3(SPINDLE_HALF, 0, 0), 1.5, 16)
	LandmarkWestKit.tube(lm, "Steel", hub + Vector3(-4.5, 0, 0), hub + Vector3(4.5, 0, 0), 3.4, 16)
	for sx in [-FLANGE_X, FLANGE_X]:
		var x: float = sx
		LandmarkWestKit.tube(lm, "Steel", hub + Vector3(x - 0.45, 0, 0), hub + Vector3(x + 0.45, 0, 0), 4.3, 20)
		LandmarkWestKit.tube(lm, "Steel", hub + Vector3(x - 0.9, 0, 0), hub + Vector3(x + 0.9, 0, 0), 2.4, 14)
	# Domed bearing cover on the river end, tail housing on the land end.
	_taper(lm, "Steel", hub + Vector3(-SPINDLE_HALF, 0, 0), hub + Vector3(-SPINDLE_HALF - 1.4, 0, 0), 1.9, 1.0, 14)
	LandmarkWestKit.tube(lm, "Steel", hub + Vector3(5.0, 0, 0), hub + Vector3(13.8, 0, 0), 2.4, 14)
	LandmarkWestKit.tube(lm, "Steel", hub + Vector3(13.8, 0, 0), hub + Vector3(14.6, 0, 0), 2.9, 14)
	lm.box("Steel", Vector3(A_TOP_X, HUB_Y - 2.2, 0), Vector3(4.2, 2.6, 6.4))

## One capsule at wheel angle a: an ovoid on its X axis held between two
## mounting rings, kept upright whatever the angle.
static func _capsule(lm: LandmarkMesh, a: float) -> void:
	var dir := Vector3(0, cos(a), sin(a))
	var c := Vector3(0, HUB_Y, 0) + dir * CAP_R
	var xs := [-3.4, -2.55, -1.7, -0.85, 0.0, 0.85, 1.7, 2.55, 3.4]
	# Glass above, a steel belt (the floor and its skirt) in the lowest 72 degrees.
	var belt := 0.63
	var glass_rows: Array = []
	var belt_rows: Array = []
	for xv in xs:
		var x: float = xv
		var rho := CAP_RAD * sqrt(1.0 - pow(x / CAP_HALF, 2.0))
		var g := PackedVector3Array()
		var b := PackedVector3Array()
		for i in 17:
			var p := -(PI - belt) + 2.0 * (PI - belt) * float(i) / 16.0
			g.append(c + Vector3(x, cos(p) * rho, sin(p) * rho))
		for i in 5:
			var p := PI - belt + 2.0 * belt * float(i) / 4.0
			b.append(c + Vector3(x, cos(p) * rho, sin(p) * rho))
		glass_rows.append(g)
		belt_rows.append(b)
	lm.grid("Capsule", glass_rows, c, true)
	lm.grid("Steel", belt_rows, c, true)
	# Meridian ribs of the glass cage.
	for pd in [-108.0, -54.0, 0.0, 54.0, 108.0]:
		var p := deg_to_rad(float(pd))
		for j in xs.size() - 1:
			var x0: float = xs[j]
			var x1: float = xs[j + 1]
			var r0 := CAP_RAD * sqrt(1.0 - pow(x0 / CAP_HALF, 2.0)) + 0.04
			var r1 := CAP_RAD * sqrt(1.0 - pow(x1 / CAP_HALF, 2.0)) + 0.04
			lm.beam("Steel", c + Vector3(x0, cos(p) * r0, sin(p) * r0),
				c + Vector3(x1, cos(p) * r1, sin(p) * r1), 0.1, 0.1)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		# End plate and bearing boss.
		lm.disc("Steel", c + Vector3(s * 3.45, 0, 0), Vector3(s, 0, 0), 1.12, 12)
		LandmarkWestKit.tube(lm, "Steel", c + Vector3(s * 3.4, 0, 0), c + Vector3(s * 4.1, 0, 0), 0.5, 8)
		# Mounting ring round the ovoid and its arm back to the rim.
		var ring_c := c + Vector3(s * 2.75, 0, 0)
		var rr := CAP_RAD * sqrt(1.0 - pow(2.75 / CAP_HALF, 2.0)) + 0.14
		for j in 12:
			var t0 := TAU * float(j) / 12.0
			var t1 := TAU * float(j + 1) / 12.0
			lm.beam("Steel", ring_c + Vector3(0, cos(t0), sin(t0)) * rr,
				ring_c + Vector3(0, cos(t1), sin(t1)) * rr, 0.26, 0.2, Vector3.RIGHT)
		lm.beam("Steel", _pt(a, RIM_R - 0.2, s * 1.35), ring_c - dir * (rr - 0.1), 0.34, 0.3)

## The A-frame, its backstays, the anchor and the pier.
static func _a_frame(lm: LandmarkMesh) -> void:
	for sz in [-1.0, 1.0]:
		var s: float = sz
		var foot := Vector3(A_FOOT_X, A_FOOT_Y, s * 10.0)
		var top := Vector3(A_TOP_X, HUB_Y - 1.5, s * 1.6)
		_taper(lm, "Steel", foot, top, 1.15, 0.95, 14)
		# Trunnion on a tall concrete pillar over a pile cap.
		LandmarkWestKit.tube(lm, "Steel", foot + Vector3(0, 0.3, -1.9), foot + Vector3(0, 0.3, 1.9), 1.5, 12)
		lm.box("Concrete", Vector3(A_FOOT_X + 0.5, 1.2 + (A_FOOT_Y - 1.8) * 0.5, s * 10.0),
			Vector3(7.0, A_FOOT_Y - 1.8, 5.0), Basis(), 0.0)
		lm.box("Concrete", Vector3(A_FOOT_X + 0.5, 0.6, s * 10.0), Vector3(12.0, 1.2, 9.0))
		# Backstay anchor on the tension foundation.
		lm.box("Concrete", Vector3(82.0, 0.3, s * 5.0), Vector3(8.0, 0.6, 7.0))
		for dz in [3.0, 6.5]:
			var anchor_z: float = dz
			var head_z := 0.9 + (anchor_z - 3.0) * 0.45
			lm.beam("Cable", Vector3(A_TOP_X + 1.0, HUB_Y - 0.6, s * head_z),
				Vector3(82.0, 0.7, s * anchor_z), 0.3)
		lm.beam("Cable", Vector3(14.6, HUB_Y + 0.4, s * 0.8), Vector3(82.0, 0.7, s * 1.6), 0.3)

## Boarding pier under the foot of the wheel, with the slot rails.
static func _pier(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(-6.0, 0.25, 0), Vector3(40.0, 0.5, 62.0))
	for sx in [-4.9, 4.9]:
		var x: float = sx
		lm.beam("Steel", Vector3(x, 1.0, -15.0), Vector3(x, 1.0, 15.0), 0.12, 0.12)
		for z in [-15.0, -7.5, 0.0, 7.5, 15.0]:
			lm.box("Steel", Vector3(x, 0.8, float(z)), Vector3(0.1, 0.6, 0.1), Basis(), 0.0)
	for z in [-31.0, 31.0]:
		lm.beam("Steel", Vector3(-26.0, 1.1, z), Vector3(14.0, 1.1, z), 0.1, 0.1)
	lm.beam("Steel", Vector3(-26.0, 1.1, -31.0), Vector3(-26.0, 1.1, 31.0), 0.1, 0.1)
