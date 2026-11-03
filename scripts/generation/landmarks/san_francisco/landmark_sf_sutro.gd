class_name LandmarkSfSutro
extends RefCounted

## Sutro Tower in true metres on LandmarkMesh, y = 0 at the ground,
## centred on the tripod.

const TOP_M := 298.0
const LEG_FOOT_R := 34.0
const LEG_HEAD_R := 3.4
const LEG_HEAD_Y := 205.0
const LEG_HALF := 4.6
const LEG_HEAD_HALF := 1.6
const BAND_M := 17.0
const LEVELS := [0.0, 36.0, 74.0, 108.0, 142.0, 172.0, 205.0]

## Sutro Tower (1973, Sutro Broadcasting): 298 m of steel in the three
## legs of its tripod, each a ladder of two pipe columns at 120 degrees
## round a 34 m circumradius that lean in to meet under the antenna
## head at 205 m. The legs are braced by ring girders and X-bracing
## between and across them, painted in alternating international orange
## and white bands, and carry on the central mast three triangular
## antenna platforms and the broadcast panels and whip above them.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.paint("#C8402A", 0.55, 0.3))
	lm.use("White", LandmarkMaterials.paint("#EEEAE1", 0.5, 0.3))
	lm.use("Steel", LandmarkMaterials.paint("#8D9398", 0.5, 0.6))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FF5A3C", 1.2))
	for k in 3:
		_leg(lm, k)
	_bracing(lm)
	_head(lm)
	lm.commit(model)

## Foot and head points of column `side` (-1 or +1) of leg k at height
## fraction t (0 foot, 1 head).
static func _col(k: int, side: float, y: float) -> Vector3:
	var t := y / LEG_HEAD_Y
	var ang := TAU * float(k) / 3.0 + PI * 0.5
	var radial := Vector3(cos(ang), 0, sin(ang))
	var tang := Vector3(-radial.z, 0, radial.x)
	var r := lerpf(LEG_FOOT_R, LEG_HEAD_R, t)
	var half := lerpf(LEG_HALF, LEG_HEAD_HALF, t)
	return radial * r + tang * half * side + Vector3(0, y, 0)

static func _leg(lm: LandmarkMesh, k: int) -> void:
	for side in [-1.0, 1.0]:
		var foot := _col(k, side, 0.0)
		lm.box("Concrete", Vector3(foot.x, 1.2, foot.z), Vector3(7.0, 2.4, 7.0))
		lm.box("Steel", Vector3(foot.x, 2.6, foot.z), Vector3(4.2, 0.6, 4.2), Basis(), 0.0)
		var y := 2.0
		var band := 0
		while y < LEG_HEAD_Y - 0.1:
			var y1 := minf(y + BAND_M, LEG_HEAD_Y)
			var key := "Red" if band % 2 == 0 else "White"
			var a := _col(k, side, y)
			var b := _col(k, side, y1)
			var r0 := lerpf(1.05, 0.75, y / LEG_HEAD_Y)
			var r1 := lerpf(1.05, 0.75, y1 / LEG_HEAD_Y)
			LandmarkCoreBBridgeKit.tube(lm, key, PackedVector3Array([a, a.lerp(b, 0.5), b]), (r0 + r1) * 0.5, 10)
			# Flange collar at the joint.
			lm.box("Steel", b, Vector3(2.0, 0.5, 2.0), Basis(), 0.0)
			y = y1
			band += 1

static func _bracing(lm: LandmarkMesh) -> void:
	for li in LEVELS.size():
		var y: float = LEVELS[li]
		if y <= 0.0:
			continue
		for k in 3:
			var k2 := (k + 1) % 3
			# Ring girder between this leg's columns and the next leg's.
			lm.beam("Steel", _col(k, -1.0, y), _col(k, 1.0, y), 0.9, 0.9)
			lm.beam("Steel", _col(k, 1.0, y), _col(k2, -1.0, y), 0.9, 0.9)
	for li in LEVELS.size() - 1:
		var y0: float = LEVELS[li]
		var y1: float = LEVELS[li + 1]
		for k in 3:
			var k2 := (k + 1) % 3
			# X-bracing inside the leg ladder.
			lm.beam("Steel", _col(k, -1.0, y0), _col(k, 1.0, y1), 0.55, 0.55)
			lm.beam("Steel", _col(k, 1.0, y0), _col(k, -1.0, y1), 0.55, 0.55)
			# X-bracing across the gap to the next leg.
			lm.beam("Steel", _col(k, 1.0, y0), _col(k2, -1.0, y1), 0.55, 0.55)
			lm.beam("Steel", _col(k2, -1.0, y0), _col(k, 1.0, y1), 0.55, 0.55)

## Head: the hub where the legs meet, the mast in orange and white
## bands, three antenna platforms with their panels, the whip.
static func _head(lm: LandmarkMesh) -> void:
	lm.lathe("Steel", Vector3(0, LEG_HEAD_Y - 6.0, 0), PackedVector2Array([Vector2(3.6, 0.0), Vector2(3.6, 12.0),
		Vector2(2.4, 14.0)]), 16)
	var mast: Array = [[LEG_HEAD_Y + 8.0, 2.3], [232.0, 1.9], [252.0, 1.4], [272.0, 0.95], [286.0, 0.6], [TOP_M - 6.0, 0.3]]
	var prev_y := LEG_HEAD_Y + 6.0
	var prev_r := 2.4
	var band := 0
	for m in mast:
		var y: float = m[0]
		var r: float = m[1]
		var key := "Red" if band % 2 == 0 else "White"
		lm.lathe(key, Vector3(0, prev_y, 0), PackedVector2Array([Vector2(prev_r, 0.0), Vector2(r, y - prev_y)]), 10)
		prev_y = y
		prev_r = r
		band += 1
	lm.lathe("Steel", Vector3(0, TOP_M - 6.0, 0), PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.14, 5.9),
		Vector2(0.02, 6.0)]), 6)
	# Antenna platforms: triangular frames carrying vertical panels.
	var plat := [[214.0, 8.2, 9.0], [232.0, 6.6, 8.0], [250.0, 5.2, 7.0]]
	for p in plat:
		var py: float = p[0]
		var pr: float = p[1]
		var ph: float = p[2]
		for k in 3:
			var a := TAU * float(k) / 3.0 + PI * 0.5
			var a2 := TAU * float(k + 1) / 3.0 + PI * 0.5
			var c0 := Vector3(cos(a) * pr, py, sin(a) * pr)
			var c1 := Vector3(cos(a2) * pr, py, sin(a2) * pr)
			lm.beam("Steel", c0, c1, 0.7, 0.9)
			lm.beam("Steel", Vector3(0, py, 0), c0, 0.6, 0.6)
			lm.beam("Steel", c0 + Vector3(0, 0.0, 0), c0 + Vector3(0, ph + 0.5, 0), 0.4, 0.4)
			lm.beam("Steel", c0 + Vector3(0, ph * 0.5, 0), (c1 + c0) * 0.5 + Vector3(0, ph * 0.5 + 2.0, 0), 0.3, 0.3)
			# Panel antennas on each platform corner, two per side.
			var out := Vector3(cos(a), 0, sin(a))
			var basis := Basis.looking_at(-out)
			for s in [-1.0, 1.0]:
				var tang := Vector3(-out.z, 0, out.x)
				lm.box("White", c0 + out * 0.9 + tang * float(s) * 1.1 + Vector3(0, ph * 0.5 + 0.5, 0),
					Vector3(1.4, ph, 0.35), basis, 0.0)
	# Candelabra of slender antenna rods above the top platform.
	for k in 6:
		var a := TAU * float(k) / 6.0
		var base := Vector3(cos(a) * 2.6, 262.0, sin(a) * 2.6)
		lm.beam("White", base, base + Vector3(0, 22.0 + 2.0 * float(k % 2), 0), 0.3, 0.3)
	lm.box("Lamp", Vector3(0, TOP_M - 0.3, 0), Vector3(0.5, 0.5, 0.5), Basis(), 0.0)
	lm.box("Lamp", Vector3(0, 214.0 + 12.0, 8.0), Vector3(0.5, 0.5, 0.5), Basis(), 0.0)
