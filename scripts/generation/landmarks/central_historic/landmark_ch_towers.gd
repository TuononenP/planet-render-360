class_name LandmarkChTowers
extends RefCounted

## Three Gothic towers of the Danube lands in true metres: the Old Town
## Hall tower of Prague with its Astronomical Clock (the dial on the
## south face, +Z, 69.5 m), the Powder Tower (sooty gate tower with
## corner turrets and a copper spire, passage along Z, 65 m) and
## Budapest's Fisherman's Bastion with Matthias Church (seven white
## cones on a curved loggia, church with the 80 m Bela tower to its west).

# --- Old Town Hall tower and Astronomical Clock ---

const ORLOJ_TOP := 69.5

static func orloj(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B3A88F", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#CDC4AB", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4F5A55", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Blue", LandmarkMaterials.paint("#2D4F86", 0.45, 0.2))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Wing", LandmarkMaterials.pbr("render", "#D8C697", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4A30", 2.5))
	# Shaft in two stages with string courses, belvedere gallery above.
	lm.box("Pale", Vector3(0, 0.5, 0), Vector3(11.2, 1.0, 11.2))
	lm.box("Stone", Vector3(0, 18.5, 0), Vector3(10.4, 35.0, 10.4))
	LandmarkChParts.band(lm, "Pale", 36.0, 5.2, 5.2, 0.9, 0.35)
	lm.box("Stone", Vector3(0, 45.5, 0), Vector3(9.4, 17.1, 9.4))
	LandmarkChParts.band(lm, "Pale", 20.0, 5.2, 5.2, 0.5, 0.2)
	LandmarkChParts.band(lm, "Pale", 54.0, 4.7, 4.7, 1.4, 0.7)
	lm.box("Stone", Vector3(0, 58.5, 0), Vector3(6.6, 7.0, 6.6))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.row(lm, "Windows", b * Vector3(0, 11.0, 5.2), 1, 1.0, 0.9, 5.0, b)
		LandmarkChParts.row(lm, "Windows", b * Vector3(0, 27.0, 5.2), 2, 3.0, 0.9, 4.6, b)
		LandmarkChParts.row(lm, "Windows", b * Vector3(0, 40.0, 4.7), 2, 3.0, 1.0, 5.2, b)
		LandmarkChParts.row(lm, "Windows", b * Vector3(0, 55.5, 3.3), 2, 3.4, 1.9, 5.2, b)
		for k in [-1.0, 1.0]:
			lm.box("Stone", b * Vector3(k * 3.9, 58.5, 3.9), Vector3(1.6, 7.0, 1.6))
	LandmarkChParts.band(lm, "Pale", 62.0, 4.7, 4.7, 0.8, 0.45)
	# Four corner pinnacles round a slim octagonal spire with a gilt finial.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkChParts.turret(lm, "Stone", "Roof", Vector3(sx * 4.1, 62.8, sz * 4.1), 0.95, 3.0, 3.0)
	lm.lathe("Roof", Vector3(0, 62.8, 0), PackedVector2Array([Vector2(3.6, 0), Vector2(1.6, 3.2),
		Vector2(0.3, 5.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkChParts.finial(lm, "Gilt", Vector3(0, 67.8, 0), ORLOJ_TOP - 67.8, 0.35)
	# The Astronomical Clock and calendar dial on the south face.
	var b0 := Basis()
	LandmarkChParts.pointed(lm, "Pale", Vector3(0, 1.0, 5.2), 4.6, 10.5, b0, 0.05)
	lm.disc("Gilt", Vector3(0, 7.6, 5.4), Vector3.BACK, 1.75, 28)
	lm.disc("Blue", Vector3(0, 7.6, 5.48), Vector3.BACK, 1.42, 28)
	lm.disc("Gilt", Vector3(0, 3.7, 5.4), Vector3.BACK, 1.55, 28)
	lm.disc("Blue", Vector3(0, 3.7, 5.48), Vector3.BACK, 1.25, 28)
	# Oriel chapel on the east face with its pointed cap.
	var poly := PackedVector2Array()
	for i in 5:
		var a := -PI * 0.5 + PI * float(i) / 4.0
		poly.append(Vector2(5.2 + cos(a) * 2.6, sin(a) * 2.6))
	lm.poly_prism("Pale", poly, 11.0, 19.0)
	lm.lathe("Roof", Vector3(5.2, 19.0, 0), PackedVector2Array([Vector2(3.0, 0), Vector2(0.2, 5.5)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for k in 4:
		var a := -PI * 0.5 + PI * (float(k) + 0.5) / 4.0
		var b := Basis(Vector3.UP, PI * 0.5 - a)
		LandmarkChParts.pointed(lm, "Windows", Vector3(5.2, 12.5, 0) + b * Vector3(0, 0, 2.4), 0.9, 4.6, b)
	# Town hall wing running north from the tower.
	lm.box("Wing", Vector3(0, 8.0, -21.0), Vector3(14.0, 16.0, 30.0))
	lm.gable("Tile", Vector3(0, 16.0, -21.0), 14.0, 30.0, 7.0, Basis(), 0.6, "Wing")
	for sx in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, PI * 0.5 * sx)
		for r in 2:
			LandmarkChParts.row(lm, "Windows", b * Vector3(0, 3.0 + 6.0 * r, 7.0) + Vector3(0, 0, -21.0), 6, 4.6,
				1.4, 2.8, b, false)
	lm.commit(model)

# --- Powder Tower ---

const POWDER_TOP := 65.0
const POWDER_HALF := 8.0

static func powder(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7B7568", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("stone", "#9A9382", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#5E8A76", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var h := POWDER_HALF
	# Body: two piers and a lintel course leave the 4.6 m gate passage.
	for sx in [-1.0, 1.0]:
		lm.box("Pale", Vector3(sx * 5.45, 0.6, 0), Vector3(6.3, 1.2, h * 2.0 + 1.2))
		lm.box("Stone", Vector3(sx * 5.15, 20.6, 0), Vector3(5.7, 38.8, h * 2.0))
	lm.box("Stone", Vector3(0, 23.7, 0), Vector3(4.6, 33.0, h * 2.0))
	LandmarkChParts.band(lm, "Pale", 13.0, h, h, 0.6, 0.35)
	LandmarkChParts.band(lm, "Pale", 22.0, h, h, 0.6, 0.3)
	LandmarkChParts.band(lm, "Pale", 36.0, h, h, 2.2, 0.8)
	lm.box("Pale", Vector3(0, 40.3, 0), Vector3(h * 2.0 + 2.0, 1.2, h * 2.0 + 2.0))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.row(lm, "Windows", b * Vector3(0, 15.0, h), 3, 3.6, 1.3, 4.0, b)
		LandmarkChParts.row(lm, "Windows", b * Vector3(0, 25.0, h), 3, 3.6, 1.7, 7.5, b)
		LandmarkChParts.row(lm, "Windows", b * Vector3(0, 42.0, 5.5), 2, 4.0, 1.4, 4.4, b)
	# Corner turrets climb out of the corbel table beside the upper stage.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkChParts.turret(lm, "Stone", "Roof", Vector3(sx * 7.3, 36.0, sz * 7.3), 1.5, 11.0, 8.0)
	# Upper stage, copper pyramid roof and the finial.
	lm.box("Stone", Vector3(0, 44.6, 0), Vector3(11.0, 7.4, 11.0))
	LandmarkChParts.band(lm, "Pale", 48.0, 5.5, 5.5, 0.9, 0.6)
	lm.spire("Roof", Vector3(0, 48.9, 0), 6.4, 11.5, 0.9)
	LandmarkChParts.finial(lm, "Gilt", Vector3(0, 60.4, 0), POWDER_TOP - 60.4, 0.9)
	lm.commit(model)

# --- Fisherman's Bastion and Matthias Church ---

const BASTION_TOP := 80.0
const BASTION_CENTRE := Vector3(-14.0, 0.0, -2.0)
const BASTION_R := 46.0

static func bastion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#D2C9AE", 3.0))
	lm.use("White", LandmarkMaterials.pbr("limestone", "#E9E4D4", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8672", 3.0))
	lm.use("Cone", LandmarkMaterials.pbr("limestone", "#B8B4A6", 1.8))
	lm.use("Spire", LandmarkMaterials.pbr("stone", "#9C978A", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B9582F", 2.0))
	lm.use("RoofG", LandmarkMaterials.pbr("terracotta", "#4F7F5A", 2.0))
	lm.use("RoofY", LandmarkMaterials.pbr("terracotta", "#D9A93C", 2.0))
	lm.use("RoofB", LandmarkMaterials.pbr("terracotta", "#3C5C8C", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_matthias(lm)
	_loggia(lm)
	lm.commit(model)

## Church of Our Lady: nave and transept under the patterned Zsolnay
## roof, polygonal chancel and the Bela tower at the south-west corner.
static func _matthias(lm: LandmarkMesh) -> void:
	var c := Vector3(-42.0, 0, 6.0)
	lm.box("Wall", c + Vector3(-5.0, 8.5, 0), Vector3(30.0, 17.0, 18.0))
	lm.gable("Roof", c + Vector3(-5.0, 17.0, 0), 18.0, 30.0, 12.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	lm.box("Wall", c + Vector3(-2.0, 8.5, 0), Vector3(14.0, 17.0, 34.0))
	lm.gable("Roof", c + Vector3(-2.0, 17.0, 0), 14.0, 34.0, 9.5, Basis(), 0.5, "Wall")
	lm.box("Wall", c + Vector3(16.0, 7.5, 0), Vector3(12.0, 15.0, 15.0))
	lm.gable("Roof", c + Vector3(16.0, 15.0, 0), 15.0, 12.0, 10.5, Basis(Vector3.UP, PI * 0.5), 0.4, "Wall")
	lm.frustum("Wall", c + Vector3(22.0, 0, 0), 8.1, 8.1, 15.0, 8, PI / 8.0)
	lm.lathe("Roof", c + Vector3(22.0, 15.0, 0), PackedVector2Array([Vector2(8.6, 0), Vector2(0.0, 13.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	# Chevron bands in green, ochre and blue over both nave slopes.
	var bands := {0.2: "RoofG", 0.45: "RoofY", 0.7: "RoofB"}
	for sz in [-1.0, 1.0]:
		var up := Vector3(0, 12.0, -sz * 9.5).normalized()
		var out := Vector3(0, 9.5, sz * 12.0).normalized() * 0.12
		for t in bands:
			var mid := c + Vector3(-5.0, 17.0 + 12.0 * t, sz * 9.5 * (1.0 - t))
			var prev := Vector3(mid.x - 14.0, mid.y, mid.z) + out - up * 1.3
			for i in range(1, 13):
				var p := Vector3(mid.x - 14.0 + 2.4 * i, mid.y, mid.z) + out + up * (1.3 if i % 2 == 0 else -1.3)
				lm.beam(bands[t], prev, p, 0.7, 0.15, out)
				prev = p
	# Buttresses with pinnacles, tall windows and the west rose.
	for sz in [-1.0, 1.0]:
		for i in 6:
			var x := -18.0 + 5.6 * i
			if absf(x + 2.0) < 7.5:
				continue
			lm.box("White", c + Vector3(x, 8.0, sz * 9.4), Vector3(1.2, 16.0, 1.8))
			lm.spire("White", c + Vector3(x, 16.0, sz * 9.4), 0.6, 4.0)
		var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		for x in [-15.2, 7.8]:
			LandmarkChParts.pointed(lm, "Windows", c + Vector3(x, 4.0, sz * 9.0), 2.2, 8.5, b)
		LandmarkChParts.pointed(lm, "Windows", c + Vector3(-2.0, 6.0, sz * 17.0), 3.6, 9.0, b)
	LandmarkChParts.pointed(lm, "Windows", c + Vector3(-20.0, 6.0, 0), 5.0, 14.0, Basis(Vector3.UP, -PI * 0.5))
	# Bela tower: square shaft, octagonal belfry, corner turrets, stone spire.
	var tw := c + Vector3(-15.0, 0, 12.5)
	lm.box("Wall", tw + Vector3(0, 20.0, 0), Vector3(10.0, 40.0, 10.0))
	LandmarkChParts.band(lm, "White", 28.0, 5.0, 5.0, 0.6, 0.25, tw)
	LandmarkChParts.band(lm, "White", 39.0, 5.0, 5.0, 1.0, 0.5, tw)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.row(lm, "Windows", tw + b * Vector3(0, 12.0, 5.0), 2, 3.4, 1.3, 6.0, b)
		LandmarkChParts.row(lm, "Windows", tw + b * Vector3(0, 31.0, 5.0), 1, 1.0, 1.8, 6.0, b)
	lm.frustum("Wall", tw + Vector3(0, 40.0, 0), 5.41, 5.41, 12.0, 8, PI / 8.0)
	for f in 8:
		var b := Basis(Vector3.UP, PI * 0.25 * f)
		LandmarkChParts.pointed(lm, "Windows", tw + Vector3(0, 42.0, 0) + b * Vector3(0, 0, 5.0), 1.6, 8.0, b)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkChParts.turret(lm, "White", "Spire", tw + Vector3(sx * 4.4, 40.0, sz * 4.4), 1.0, 14.0, 7.0)
	lm.lathe("Spire", tw + Vector3(0, 52.0, 0), PackedVector2Array([Vector2(5.6, 0), Vector2(4.6, 4.0),
		Vector2(3.2, 10.0), Vector2(1.6, 17.0), Vector2(0.6, 22.0), Vector2(0.15, 25.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	LandmarkChParts.finial(lm, "Gilt", tw + Vector3(0, 77.0, 0), BASTION_TOP - 77.0, 0.5)

## The curved loggia on the cliff edge: arcaded gallery, seven conical
## towers (the central one tallest) and the deep retaining wall below.
static func _loggia(lm: LandmarkMesh) -> void:
	var c := BASTION_CENTRE
	var last := 6
	for k in last + 1:
		var a := deg_to_rad(-54.0 + 18.0 * k)
		var dir := Vector3(cos(a), 0, sin(a))
		var p := c + dir * BASTION_R
		var body := 12.0 if k == 3 else 10.5
		var cone := 10.0 if k == 3 else 8.0
		lm.frustum("White", p, 2.8, 2.6, body, 12)
		lm.frustum("White", p + Vector3(0, body, 0), 3.3, 3.0, 0.9, 12)
		lm.lathe("Cone", p + Vector3(0, body + 0.9, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(3.0, 1.2),
			Vector2(2.1, 4.0), Vector2(1.0, cone * 0.75), Vector2(0.12, cone)]), 12)
		LandmarkChParts.finial(lm, "Cone", p + Vector3(0, body + 0.9 + cone, 0), 1.4, 0.3)
		var b := Basis(Vector3.UP, atan2(dir.x, dir.z))
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, 3.2, 2.8), 2, 1.9, 0.9, 3.6, b, false)
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, 7.2, 2.7), 1, 1.0, 0.9, 2.6, b, false)
		if k == last:
			break
		# Gallery to the next tower: roofed arcade inside, windowed wall out.
		var a1 := deg_to_rad(-54.0 + 18.0 * (k + 1))
		var q := c + Vector3(cos(a1), 0, sin(a1)) * BASTION_R
		var pi_ := c + dir * (BASTION_R - 2.2)
		var qi := c + Vector3(cos(a1), 0, sin(a1)) * (BASTION_R - 2.2)
		LandmarkChParts.wall(lm, "White", p, q, 4.8, 5.5, 5.4)
		LandmarkChParts.wall(lm, "White", c + dir * (BASTION_R + 2.0), c + Vector3(cos(a1), 0, sin(a1)) * (BASTION_R + 2.0),
			0.0, 4.8, 0.7)
		LandmarkChParts.wall(lm, "White", pi_, qi, 4.2, 4.8, 0.8)
		LandmarkChParts.wall(lm, "Stone", c + dir * (BASTION_R + 3.4), c + Vector3(cos(a1), 0, sin(a1)) * (BASTION_R + 3.4),
			-14.0, 0.2, 3.4)
		var out_p := c + dir * (BASTION_R + 2.0)
		var out_q := c + Vector3(cos(a1), 0, sin(a1)) * (BASTION_R + 2.0)
		var mid_dir := (dir + Vector3(cos(a1), 0, sin(a1))).normalized()
		var wb := Basis(Vector3.UP, atan2(mid_dir.x, mid_dir.z))
		for i in range(1, 6):
			var f := float(i) / 6.0
			var col := pi_.lerp(qi, f)
			lm.frustum("White", Vector3(col.x, 0.0, col.z), 0.3, 0.26, 4.4, 8)
			var wm := out_p.lerp(out_q, f) + mid_dir * 0.35
			LandmarkChParts.round_arch(lm, "Windows", Vector3(wm.x, 0.8, wm.z), 1.0, 3.2, wb)
