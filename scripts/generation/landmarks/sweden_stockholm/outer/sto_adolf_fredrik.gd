class_name StoOuterAdolf
extends RefCounted

## Adolf Fredriks kyrka (Carl Fredrik Adelcrantz, 1768-74), Sveavagen. Origin
## at the OSM footprint centre (way 42038493, 51.5 x 43 m), arms along local X
## (long, 25.7 m each way) and Z (21.4 m each way), 16 m wide, front +Z. The
## registry yaw (-26.6) turns local +X onto bearing 63.4 and +Z onto 153.4.
##
## From the photos (front, quarter, night in visual-plan/refs/landmarks/
## adolf_fredriks_kyrka/):
## - A Greek cross in cream-white plaster on a low grey granite plinth, the
##   walls 12.5 m to a moulded cornice. The arms carry tall round-headed
##   windows (a pilaster between each pair), a small square window above, and
##   flat ends with a round-headed door, two flanking arched windows and a
##   square window over the door.
## - Each arm has a pale verdigris copper roof hipped at its end, ridge 5.5 m
##   above the eaves (18 m), running in to the crossing.
## - The crossing rises as a 16 m square block to 21 m with two round windows
##   on each face, a cornice and a stone balustrade round its top.
## - On it stands the 12 x 11 m clock stage (to 31 m): quoined corner
##   pilasters, a clock on every face over a tall louvred window, a cornice
##   and four gilt balls at the corners.
## - The dark brown copper dome (to 38.5 m), then a small octagonal lantern
##   with a balcony, its cupola, gilt ball and weather vane (43.5 m, OSM).
## - A low black iron fence round the churchyard (the front photo).
## Night: the front and the tower stage are floodlit (night photo).
## Height 43.5 m is the OSM lantern part. Arm eaves (12.5 m) and the clock
## stage (21-31 m) are scaled from the photos against the OSM part heights
## (dome part 38.5 m from 21 m, arms 18 m with 5-5.5 m roofs).

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const HW := 8.0
const ZC := 8.0
const EAVE := 12.5
const RISE := 5.5
const BLOCK_Y := 21.0
const STAGE_X := 6.0
const STAGE_Z := 5.5
const STAGE_Y := 31.0
const TOP := 43.5
const ARM_X := 17.7
const ARM_Z := 13.4

static func _mats() -> Dictionary:
	return {
		"Plaster": LandmarkMaterials.pbr("render", "#E4DCC8", 3.0),
		"Trim": LandmarkMaterials.pbr("render", "#EEE8D8", 3.0),
		"Base": LandmarkMaterials.pbr("stone", "#8F8B85", 2.4),
		"Glass": LandmarkMaterials.glass("#2A3138"),
		"Frame": LandmarkMaterials.paint("#3A3733", 0.5, 0.3),
		"Roof": LandmarkMaterials.pbr("copper", "#8EA898", 2.0, 0.55, 0.3),
		"Dome": LandmarkMaterials.pbr("sheet_metal", "#3E3731", 2.5, 0.5, 0.45),
		"Gilt": LandmarkMaterials.gold(),
		"Door": LandmarkMaterials.pbr("wood", "#5B3B26", 2.0),
		"Fence": LandmarkMaterials.paint("#1E1E20", 0.6, 0.3),
	}

static func build(model: Node3D) -> void:
	var mats := _mats()
	var lm := LandmarkMesh.new()
	for k in mats:
		lm.use(str(k), mats[k])
	_crossing(lm)
	_arms(lm, mats)
	_stage(lm)
	_dome(lm)
	_fence(lm)
	lm.commit(model)
	# Night: the front and the clock stage are washed from the churchyard.
	var warm := Color(1.0, 0.86, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-9.0, 1.5, 36.0), Vector3(-3.0, 9.0, 21.0), 38.0, 0.9, 55.0, warm],
		[Vector3(9.0, 1.5, 36.0), Vector3(3.0, 9.0, 21.0), 38.0, 0.9, 55.0, warm],
		[Vector3(0.0, 1.5, 26.0), Vector3(0.0, 27.0, 5.0), 32.0, 1.0, 62.0, warm]])

# --- Arms --------------------------------------------------------------

## The four arms: one part per length built facing +Z, merged turned onto
## +Z, -Z, +X and -X.
static func _arms(lm: LandmarkMesh, mats: Dictionary) -> void:
	var long_arm := _arm(mats, ARM_X)
	var short_arm := _arm(mats, ARM_Z)
	lm.merge(short_arm, Transform3D(Basis(), Vector3.ZERO))
	lm.merge(short_arm, Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO))
	lm.merge(long_arm, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO))
	lm.merge(long_arm, Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3.ZERO))

## One arm from the crossing edge (z = 8) out `length` m along +Z.
static func _arm(mats: Dictionary, length: float) -> LandmarkMesh:
	var p := LandmarkMesh.new()
	for k in mats:
		p.use(str(k), mats[k])
	var z1 := ZC + length
	K.rb(p, "Plaster", -HW, HW, 1.0, EAVE, ZC, z1, 0.0)
	K.rb(p, "Base", -HW - 0.2, HW + 0.2, 0.0, 1.3, ZC, z1 + 0.2, 0.0)
	var cy := EAVE - 0.9
	LandmarkDetail.cornice(p, "Trim", Vector3(-HW - 0.2, cy, z1), Vector3(HW + 0.2, cy, z1), Vector3(0, 0, 1), 0.9, false)
	for s in [-1.0, 1.0]:
		var sg: float = s
		LandmarkDetail.cornice(p, "Trim", Vector3(sg * HW, cy, ZC), Vector3(sg * HW, cy, z1 + 0.2),
			Vector3(sg, 0, 0), 0.9, false)
	_arm_sides(p, length)
	_arm_end(p, z1)
	_arm_roof(p, z1)
	return p

static func _arm_sides(p: LandmarkMesh, length: float) -> void:
	var bays := maxi(int(roundf(length / 5.5)), 2)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var out := Vector3(sg, 0, 0)
		for i in bays:
			var z := ZC + length * (float(i) + 0.5) / float(bays)
			LandmarkDetail.window(p, "Trim", "Glass", Vector3(sg * HW, 1.7 + 3.1, z), out, 2.3, 6.2, true, 0.3)
			LandmarkDetail.window(p, "Trim", "Glass", Vector3(sg * HW, 9.9, z), out, 1.3, 1.9, false, 0.2)
		for i in bays + 1:
			var zp := ZC + length * float(i) / float(bays)
			K.rb(p, "Trim", sg * HW - 0.05, sg * HW + sg * 0.3, 1.3, EAVE - 0.9, zp - 0.4, zp + 0.4, 0.0)

static func _arm_end(p: LandmarkMesh, z1: float) -> void:
	var out := Vector3(0, 0, 1)
	LandmarkDetail.window(p, "Trim", "Door", Vector3(0, 0.2 + 2.5, z1), out, 2.6, 5.0, true, 0.35)
	for x in [-5.1, 5.1]:
		LandmarkDetail.window(p, "Trim", "Glass", Vector3(float(x), 1.8 + 2.7, z1), out, 2.2, 5.4, true, 0.3)
	LandmarkDetail.window(p, "Trim", "Glass", Vector3(0, 9.3, z1), out, 1.6, 2.4, false, 0.25)
	for x in [-7.6, -2.7, 2.7, 7.6]:
		K.rb(p, "Trim", float(x) - 0.4, float(x) + 0.4, 1.3, EAVE - 0.9, z1 - 0.05, z1 + 0.3, 0.0)
	# Steps to the door.
	for k in 3:
		K.rb(p, "Base", -2.4 - 0.3 * float(2 - k), 2.4 + 0.3 * float(2 - k), 0.0, 0.2 * float(3 - k),
			z1, z1 + 0.35 * float(k + 1), 0.0)

## Hipped copper roof running in to the crossing wall at z = 8.
static func _arm_roof(p: LandmarkMesh, z1: float) -> void:
	var ey := EAVE - 0.1
	var hw := HW + 0.5
	var ze := z1 + 0.5
	var zr := ze - hw
	var ny := hw
	var nr := Vector3(RISE, ny, 0.0).normalized()
	var nl := Vector3(-RISE, ny, 0.0).normalized()
	var ne := Vector3(0.0, ny, RISE).normalized()
	p.quad("Roof", Vector3(hw, ey, ZC), Vector3(hw, ey, ze), Vector3(0, ey + RISE, zr), Vector3(0, ey + RISE, ZC), nr)
	p.quad("Roof", Vector3(-hw, ey, ze), Vector3(-hw, ey, ZC), Vector3(0, ey + RISE, ZC), Vector3(0, ey + RISE, zr), nl)
	p.tri("Roof", Vector3(hw, ey, ze), Vector3(-hw, ey, ze), Vector3(0, ey + RISE, zr), ne, ne, ne,
		Vector2(hw, 0), Vector2(-hw, 0), Vector2(0, RISE))

# --- Crossing, tower stage, dome ------------------------------------------

## The square block over the crossing: oculi, cornice, balustrade.
static func _crossing(lm: LandmarkMesh) -> void:
	K.rb(lm, "Plaster", -HW, HW, 11.0, BLOCK_Y - 0.9, -HW, HW, 0.0)
	for s in [-1.0, 1.0]:
		var sg: float = s
		for out in [Vector3(0, 0, sg), Vector3(sg, 0, 0)]:
			var along := K.right(out)
			var o: Vector3 = out
			for t in [-2.4, 2.4]:
				var c: Vector3 = o * (HW + 0.03) + along * float(t) + Vector3(0, 19.0, 0)
				lm.disc("Trim", c + o * 0.03, o, 0.85, 14)
				lm.disc("Glass", c + o * 0.06, o, 0.62, 14)
			var a: Vector3 = o * (HW + 0.2) - along * (HW + 0.2) + Vector3(0, BLOCK_Y - 0.9, 0)
			var b: Vector3 = o * (HW + 0.2) + along * (HW + 0.2) + Vector3(0, BLOCK_Y - 0.9, 0)
			LandmarkDetail.cornice(lm, "Trim", a, b, o, 0.9, false)
			var ya := BLOCK_Y
			var a2: Vector3 = o * (HW + 0.1) - along * (HW + 0.1) + Vector3(0, ya, 0)
			var b2: Vector3 = o * (HW + 0.1) + along * (HW + 0.1) + Vector3(0, ya, 0)
			LandmarkDetail.balustrade(lm, "Trim", a2, b2, 1.1, 4.0, 6)
	K.rb(lm, "Plaster", -HW, HW, BLOCK_Y - 0.9, BLOCK_Y, -HW, HW, 0.0)

static func _stage(lm: LandmarkMesh) -> void:
	var y0 := BLOCK_Y
	K.rb(lm, "Trim", -STAGE_X, STAGE_X, y0, STAGE_Y, -STAGE_Z, STAGE_Z, 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx: float = float(sx) * (STAGE_X - 0.2)
			var cz: float = float(sz) * (STAGE_Z - 0.2)
			K.rb(lm, "Plaster", cx - 0.75, cx + 0.75, y0, STAGE_Y - 0.4, cz - 0.75, cz + 0.75, 0.0)
			K.rb(lm, "Trim", cx - 0.95, cx + 0.95, STAGE_Y - 0.4, STAGE_Y, cz - 0.95, cz + 0.95, 0.0)
			lm.lathe("Gilt", Vector3(cx, STAGE_Y + 0.9, cz), LandmarkFhUtil.ball(0.34), 8)
	var faces := [[Vector3(0, 0, 1), STAGE_Z], [Vector3(0, 0, -1), STAGE_Z],
		[Vector3(1, 0, 0), STAGE_X], [Vector3(-1, 0, 0), STAGE_X]]
	for f in faces:
		var out: Vector3 = f[0]
		var half: float = f[1]
		var along := K.right(out)
		var c: Vector3 = out * (half + 0.04)
		lm.disc("Gilt", c + Vector3(0, 28.0, 0) + out * 0.12, out, 1.55, 20)
		lm.disc("Trim", c + Vector3(0, 28.0, 0) + out * 0.16, out, 1.4, 20)
		lm.disc("Frame", c + Vector3(0, 28.0, 0) + out * 0.2, out, 0.1, 8)
		K.holes(lm, "Frame", c, out, [0.0], y0 + 1.2, 1.5, 4.2, false)
		K.holes(lm, "Frame", c, out, [-3.0, 3.0] if half > 5.8 else [-2.7, 2.7], y0 + 2.4, 0.9, 2.2, true)
		var a: Vector3 = c - along * (half + 0.4) + Vector3(0, STAGE_Y - 0.9, 0)
		var b: Vector3 = c + along * (half + 0.4) + Vector3(0, STAGE_Y - 0.9, 0)
		LandmarkDetail.cornice(lm, "Trim", a + out * 0.0, b + out * 0.0, out, 0.9, true)

static func _dome(lm: LandmarkMesh) -> void:
	var y0 := STAGE_Y + 0.9
	K.rb(lm, "Trim", -STAGE_X + 0.1, STAGE_X - 0.1, STAGE_Y, y0, -STAGE_Z + 0.1, STAGE_Z - 0.1, 0.0)
	var prof := PackedVector2Array([Vector2(5.4, 0.0), Vector2(5.4, 0.6), Vector2(5.2, 1.6), Vector2(4.6, 2.7),
		Vector2(3.7, 3.8), Vector2(2.6, 4.8), Vector2(1.8, 5.6), Vector2(1.5, 6.6)])
	lm.lathe("Dome", Vector3(0, y0, 0), prof, 20, STAGE_X / 5.7, STAGE_Z / 5.7)
	var yl := y0 + 6.6
	# Lantern: balcony, octagonal body, cupola, ball and vane.
	lm.frustum("Dome", Vector3(0, yl, 0), 2.7, 2.7, 0.3, 8)
	lm.frustum("Dome", Vector3(0, yl + 0.3, 0), 2.0, 2.0, 2.3, 8)
	for k in 4:
		var a := TAU * (float(k) + 0.5) / 4.0
		var o := Vector3(sin(a), 0, cos(a))
		K.holes(lm, "Gilt", o * 2.03 + Vector3(0, yl + 0.8, 0), o, [0.0], 0.0, 0.8, 1.3, true)
	var cap := PackedVector2Array([Vector2(2.3, 0.0), Vector2(2.0, 0.4), Vector2(1.2, 1.0), Vector2(0.5, 1.5), Vector2(0.2, 1.7)])
	lm.lathe("Dome", Vector3(0, yl + 2.6, 0), cap, 8)
	lm.lathe("Gilt", Vector3(0, yl + 4.2, 0), LandmarkFhUtil.ball(0.42), 8)
	lm.beam("Gilt", Vector3(0, yl + 4.3, 0), Vector3(0, TOP, 0), 0.08, 0.08)

## Low iron fence round the churchyard.
static func _fence(lm: LandmarkMesh) -> void:
	var x0 := -33.0
	var x1 := 33.0
	var z0 := -29.0
	var z1 := 29.0
	var runs := [[Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x1, z0)],
		[Vector2(x1, z0), Vector2(x0, z0)], [Vector2(x0, z0), Vector2(x0, z1)]]
	for r in runs:
		var a: Vector2 = r[0]
		var b: Vector2 = r[1]
		var n := int(a.distance_to(b) / 2.4)
		var basis := Basis(Vector3.UP, atan2(b.x - a.x, b.y - a.y))
		var mid := (a + b) * 0.5
		lm.box("Fence", Vector3(mid.x, 0.95, mid.y), Vector3(0.06, 0.07, a.distance_to(b)), basis, 0.0)
		lm.box("Fence", Vector3(mid.x, 0.25, mid.y), Vector3(0.06, 0.07, a.distance_to(b)), basis, 0.0)
		for i in n + 1:
			var q := a.lerp(b, float(i) / float(n))
			lm.box("Fence", Vector3(q.x, 0.6, q.y), Vector3(0.1, 1.2, 0.1), basis, 0.0)
