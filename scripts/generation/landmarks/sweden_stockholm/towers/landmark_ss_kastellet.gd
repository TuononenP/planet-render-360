extends RefCounted

## Kastellet on Kastellholmen (the citadel of 1848), front +Z (south, the
## gun terrace towards the harbour), no yaw (OSM way 49744847 is axis-aligned,
## 30.7 x 30.5 m with its rounded bastion). Origin on the building's axis
## about the middle of the wings; model top 20 m is the flagpole tip.
##
## From the Commons photos (visual-plan/refs/landmarks/kastellet_stockholm/):
## - two storeys of red-orange brick in two wings, 30.4 x 9 m, 6.9 m to a
##   white corbel-arch frieze, a white cornice course (to 7.8 m), a white
##   parapet wall and shaped white merlons (to 9.1 m) all round,
## - in each wing a single row of small tall windows with stone sills (six
##   a side on the long faces), basement lights and two arched doors on the
##   front, gable-end windows,
## - at the middle a round bay projecting 2 m (radius 5) to the cornice, and
##   the round tower rising out of it: brick drum of radius 4.3 to 11.4 m
##   with four arched windows and two round windows (white surrounds), a
##   white corbel frieze, a dished cornice ring, a white parapet with
##   merlons at 14.3 m,
## - on the tower roof a small white square stair turret with a crenellated
##   top (15.8 m) and the flagpole with the Swedish flag to 20 m,
## - a granite plinth round the building, and the semicircular gun terrace
##   in front (radius 13.5 m) with its low granite wall, pale coping and a
##   row of tarpaulin-covered guns,
## - granite boulders on the rock at the back (the knoll the citadel stands
##   on).
## The 20 m top and the flag are from SFV/Wikipedia and the photos; the
## wings' depth and terrace radius are scaled off the aerial photo.

const HALF := 15.2
const Z_FRONT := -0.5
const Z_BACK := -9.5
const WING_TOP := 6.9
const FRIEZE_TOP := 7.8
const PARAPET_TOP := 8.4
const MERLON_TOP := 9.1
const TOWER := Vector3(0.0, 0.0, -4.0)
const BOW_R := 5.0
const DRUM_R := 4.3
const DRUM_TOP := 11.4
const TERRACE_R := 13.5
const TERRACE_AT := Vector3(0.0, 0.0, -0.5)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B04A32", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E6E3DB", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("rock", "#85817A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#6F6E6A", 3.0))
	lm.use("Court", LandmarkMaterials.pbr("stone", "#B2A58C", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#25292B"))
	lm.use("Gun", LandmarkMaterials.paint("#4D5640", 0.7, 0.1))
	lm.use("Mast", LandmarkMaterials.paint("#EDEDED", 0.5, 0.2))
	lm.use("FlagBlue", LandmarkMaterials.paint("#1D5FA6", 0.8, 0.0))
	lm.use("FlagYellow", LandmarkMaterials.paint("#F2C500", 0.8, 0.0))
	_wings(lm)
	_windows(lm)
	_cornice(lm)
	_tower(lm)
	_terrace(lm)
	_rocks(lm)
	lm.commit(model)

static func _wings(lm: LandmarkMesh) -> void:
	var d := Z_FRONT - Z_BACK
	var cz := (Z_FRONT + Z_BACK) * 0.5
	lm.box("Brick", Vector3(0, WING_TOP * 0.5, cz), Vector3(HALF * 2.0, WING_TOP, d), Basis(), 0.0)
	# Granite plinth course round the foot.
	lm.box("Stone", Vector3(0, 0.5, cz), Vector3(HALF * 2.0 + 0.3, 1.0, d + 0.3), Basis(), 0.0)
	lm.frustum("Brick", TOWER, BOW_R, BOW_R, WING_TOP, 32)
	lm.frustum("Stone", TOWER, BOW_R + 0.15, BOW_R + 0.15, 1.0, 32)

static func _windows(lm: LandmarkMesh) -> void:
	var cz := (Z_FRONT + Z_BACK) * 0.5
	for side in [-1.0, 1.0]:
		for k in 6:
			var x := float(side) * (6.4 + 1.65 * float(k))
			# Long faces: tall windows, basement lights on the front.
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 4.0, Z_FRONT), Vector3(0, 0, 1), 0.85, 2.0, false, 0.15)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 4.0, Z_BACK), Vector3(0, 0, -1), 0.85, 2.0, false, 0.15)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 1.0, Z_FRONT), Vector3(0, 0, 1), 0.5, 0.8, false, 0.1)
		# Arched doors on the front, gable-end windows.
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(side) * 9.6, 1.35, Z_FRONT), Vector3(0, 0, 1), 1.3, 2.7, true, 0.2)
		for zz in [-3.0, -7.0]:
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(side) * HALF, 4.0, zz), Vector3(float(side), 0, 0), 0.85, 2.0, false, 0.15)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(side) * HALF, 1.0, zz), Vector3(float(side), 0, 0), 0.5, 0.8, false, 0.1)
	# Windows on the bow.
	for a in [-0.4, 0.4]:
		var n := Vector3(sin(a), 0, cos(a))
		LandmarkDetail.window(lm, "Trim", "Glass", TOWER + n * BOW_R + Vector3(0, 4.0, 0), n, 0.85, 2.0, false, 0.15)

## Frieze, cornice course, parapet and merlons on the wings.
static func _cornice(lm: LandmarkMesh) -> void:
	var cz := (Z_FRONT + Z_BACK) * 0.5
	var d := Z_FRONT - Z_BACK
	lm.box("Trim", Vector3(0, (WING_TOP + FRIEZE_TOP) * 0.5, cz), Vector3(HALF * 2.0 + 0.5, FRIEZE_TOP - WING_TOP, d + 0.5), Basis(), 0.0)
	lm.box("Roof", Vector3(0, FRIEZE_TOP + 0.03, cz), Vector3(HALF * 2.0 - 0.4, 0.06, d - 0.4), Basis(), 0.0)
	# Corbel-arch frieze under it, on the faces the bow leaves free.
	var zf := Z_FRONT + 0.25
	var zb := Z_BACK - 0.25
	LandmarkFhParts.arch_frieze(lm, "Trim", Vector3(-HALF - 0.25, 0, zf), Vector3(-BOW_R, 0, zf), Vector3(0, 0, 1), WING_TOP, 0.9, 0.2)
	LandmarkFhParts.arch_frieze(lm, "Trim", Vector3(BOW_R, 0, zf), Vector3(HALF + 0.25, 0, zf), Vector3(0, 0, 1), WING_TOP, 0.9, 0.2)
	LandmarkFhParts.arch_frieze(lm, "Trim", Vector3(-HALF - 0.25, 0, zb), Vector3(HALF + 0.25, 0, zb), Vector3(0, 0, -1), WING_TOP, 0.9, 0.2)
	# Parapet wall all round, merlons on it.
	var h := PARAPET_TOP - FRIEZE_TOP
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(0, FRIEZE_TOP + h * 0.5, cz + float(s) * (d * 0.5 + 0.05)), Vector3(HALF * 2.0 + 0.4, h, 0.45), Basis(), 0.0)
		lm.box("Trim", Vector3(float(s) * (HALF + 0.05), FRIEZE_TOP + h * 0.5, cz), Vector3(0.45, h, d + 0.4), Basis(), 0.0)
	var mh := MERLON_TOP - PARAPET_TOP
	for i in 21:
		var x := -HALF + 0.5 + (HALF * 2.0 - 1.0) * float(i) / 20.0
		for z in [Z_FRONT + 0.05, Z_BACK - 0.05]:
			if z == Z_FRONT + 0.05 and absf(x) < BOW_R - 0.5:
				continue
			lm.box("Trim", Vector3(x, PARAPET_TOP + mh * 0.5, z), Vector3(0.8, mh, 0.45), Basis(), 0.0)
	for i in 6:
		var z := Z_BACK + 0.9 + (d - 1.8) * float(i) / 5.0
		for s in [-1.0, 1.0]:
			lm.box("Trim", Vector3(float(s) * (HALF + 0.05), PARAPET_TOP + mh * 0.5, z), Vector3(0.45, mh, 0.8), Basis(), 0.0)

static func _tower(lm: LandmarkMesh) -> void:
	# The bow's cornice course with corbels under it.
	lm.frustum("Trim", Vector3(TOWER.x, WING_TOP, TOWER.z), BOW_R + 0.35, BOW_R + 0.35, FRIEZE_TOP - WING_TOP, 32)
	_corbels(lm, BOW_R + 0.1, WING_TOP - 0.5, 28)
	# Upper brick drum with its arched windows and round windows.
	lm.frustum("Brick", Vector3(TOWER.x, FRIEZE_TOP, TOWER.z), DRUM_R, DRUM_R, DRUM_TOP - FRIEZE_TOP, 32)
	for a in [-0.55, -0.2, 0.2, 0.55]:
		var n := Vector3(sin(a * 1.6), 0, cos(a * 1.6))
		LandmarkDetail.window(lm, "Trim", "Glass", TOWER + n * DRUM_R + Vector3(0, 9.4, 0), n, 1.1, 2.2, true, 0.2)
	for a in [-0.2, 0.2]:
		var n := Vector3(sin(a), 0, cos(a))
		var p := TOWER + n * (DRUM_R + 0.02) + Vector3(0, 10.9, 0)
		lm.disc("Trim", p + n * 0.05, n, 0.5, 12)
		lm.disc("Glass", p + n * 0.07, n, 0.34, 12)
	# White corbel frieze, the dished cornice ring and the parapet.
	_corbels(lm, DRUM_R + 0.1, DRUM_TOP - 0.5, 26)
	lm.frustum("Trim", Vector3(TOWER.x, DRUM_TOP, TOWER.z), DRUM_R + 0.35, DRUM_R + 0.35, 0.8, 32)
	lm.lathe("Trim", Vector3(TOWER.x, DRUM_TOP + 0.8, TOWER.z), PackedVector2Array([Vector2(DRUM_R + 0.35, 0),
		Vector2(DRUM_R + 0.95, 0.1), Vector2(DRUM_R + 1.0, 0.4), Vector2(DRUM_R + 0.75, 0.55),
		Vector2(DRUM_R + 0.35, 0.6)]), 32)
	var roof := DRUM_TOP + 1.4
	lm.frustum("Trim", Vector3(TOWER.x, roof, TOWER.z), DRUM_R + 0.55, DRUM_R + 0.55, 0.7, 32)
	for i in 16:
		var a := TAU * (float(i) + 0.5) / 16.0
		lm.box("Trim", TOWER + Vector3(cos(a), 0, sin(a)) * (DRUM_R + 0.35) + Vector3(0, roof + 0.7 + 0.4, 0),
			Vector3(0.8, 0.8, 0.5), Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	# Stair turret with its crenellated top, the flagpole and the flag.
	var tp := Vector3(0.6, roof + 0.7, -4.8)
	lm.box("Trim", tp + Vector3(0, 1.0, 0), Vector3(3.4, 2.0, 3.4), Basis(), 0.0)
	for i in 5:
		var t := -1.5 + 3.0 * float(i) / 4.0
		for s in [-1.0, 1.0]:
			lm.box("Trim", tp + Vector3(t, 2.35, float(s) * 1.6), Vector3(0.6, 0.7, 0.4), Basis(), 0.0)
			if i > 0 and i < 4:
				lm.box("Trim", tp + Vector3(float(s) * 1.6, 2.35, t), Vector3(0.4, 0.7, 0.6), Basis(), 0.0)
	var top := tp + Vector3(0, 2.0, 0)
	lm.beam("Mast", top, Vector3(top.x, 20.0, top.z), 0.14, 0.14)
	var fy := 18.2
	for k in 2:
		var s := 1.0 if k == 0 else -1.0
		var z := top.z + s * 0.03
		lm.quad("FlagBlue", Vector3(top.x, fy, z), Vector3(top.x + 2.4, fy, z), Vector3(top.x + 2.4, fy + 1.5, z),
			Vector3(top.x, fy + 1.5, z), Vector3(0, 0, s))
		var zy := top.z + s * 0.045
		lm.quad("FlagYellow", Vector3(top.x, fy + 0.6, zy), Vector3(top.x + 2.4, fy + 0.6, zy),
			Vector3(top.x + 2.4, fy + 0.9, zy), Vector3(top.x, fy + 0.9, zy), Vector3(0, 0, s))
		lm.quad("FlagYellow", Vector3(top.x + 0.7, fy, zy), Vector3(top.x + 1.0, fy, zy), Vector3(top.x + 1.0, fy + 1.5, zy),
			Vector3(top.x + 0.7, fy + 1.5, zy), Vector3(0, 0, s))

## A ring of `count` small corbel blocks under a course, hung from y.
static func _corbels(lm: LandmarkMesh, r: float, y: float, count: int) -> void:
	for i in count:
		var a := TAU * float(i) / float(count)
		var n := Vector3(cos(a), 0, sin(a))
		lm.box("Trim", TOWER + n * (r + 0.1) + Vector3(0, y + 0.25, 0), Vector3(0.32, 0.5, 0.3),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)

## The gun terrace: a paved half disc in front, its granite wall with a pale
## coping, the covered guns.
static func _terrace(lm: LandmarkMesh) -> void:
	var poly := PackedVector2Array()
	for k in 25:
		var a := PI * float(k) / 24.0
		poly.append(Vector2(TERRACE_AT.x + cos(a) * TERRACE_R, TERRACE_AT.z + sin(a) * TERRACE_R))
	lm.poly_prism("Court", poly, 0.0, 0.08, true)
	var seg := 24
	for k in seg:
		var a0 := PI * float(k) / float(seg)
		var a1 := PI * float(k + 1) / float(seg)
		var p0 := Vector3(cos(a0), 0, sin(a0)) * (TERRACE_R + 0.45) + TERRACE_AT
		var p1 := Vector3(cos(a1), 0, sin(a1)) * (TERRACE_R + 0.45) + TERRACE_AT
		var dir := (p1 - p0).normalized()
		var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		var m := (p0 + p1) * 0.5
		lm.box("Stone", m + Vector3(0, 0.55, 0), Vector3(p0.distance_to(p1) + 0.05, 1.1, 0.9), basis, 0.0)
		lm.box("Trim", m + Vector3(0, 1.2, 0), Vector3(p0.distance_to(p1) + 0.05, 0.2, 1.1), basis, 0.0)
	for a in [0.22, 0.5, 0.78, 1.0, 1.22]:
		var ang: float = PI * float(a) / 1.44 + PI * 0.14
		var p := Vector3(cos(ang), 0, sin(ang)) * (TERRACE_R - 1.4) + TERRACE_AT
		lm.box("Gun", p + Vector3(0, 0.45, 0), Vector3(2.0, 0.9, 1.2), Basis(Vector3.UP, -ang + PI * 0.5), 0.0)

## Granite boulders on the rock behind the citadel.
static func _rocks(lm: LandmarkMesh) -> void:
	var rocks := [[-13.0, -11.5, 3.4, 1.6, 2.4, 0.4], [-8.0, -12.4, 2.6, 1.2, 2.0, -0.3], [-2.5, -11.8, 3.8, 1.8, 2.6, 0.2],
		[3.0, -12.6, 3.0, 1.4, 2.2, -0.5], [8.5, -11.7, 3.6, 1.7, 2.4, 0.3], [13.2, -12.0, 3.2, 1.5, 2.6, -0.2],
		[17.5, -5.0, 2.8, 1.4, 3.0, 0.6], [-17.8, -4.0, 3.0, 1.6, 3.4, -0.4]]
	for r in rocks:
		lm.box("Stone", Vector3(float(r[0]), float(r[4]) * 0.3 + 0.1, float(r[1])), Vector3(float(r[2]), float(r[4]) * 0.6, float(r[3]) * 1.6),
			Basis(Vector3.UP, float(r[5])), 0.12)
