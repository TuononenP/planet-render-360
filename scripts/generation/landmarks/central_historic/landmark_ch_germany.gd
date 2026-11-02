class_name LandmarkChGermany
extends RefCounted

## Three German churches in true metres: the Munich Frauenkirche
## (red-brick hall under a steep roof, the two 98.6 m domed towers at
## the west end, -X), the Dresden Frauenkirche (square baroque body,
## four stair towers and the stone bell dome, 91.2 m, apse to +X) and
## the Berlin Cathedral (green copper dome on its drum with four corner
## cupolas, front portico to +Z, 114 m).

# --- Munich Frauenkirche ---

const MUNICH_TOP := 98.6

static func munich(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B5654A", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC3A8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9B4A30", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5E8F78", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Hall: long walls to a 32 m eave, very steep tiled roof, polygonal chevet.
	lm.box("Brick", Vector3(-10.0, 16.0, 0), Vector3(89.0, 32.0, 40.0))
	lm.gable("Roof", Vector3(-10.0, 32.0, 0), 40.0, 89.0, 22.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Brick")
	lm.lathe("Brick", Vector3(34.5, 0, 0), PackedVector2Array([Vector2(20.2, 0), Vector2(20.2, 32.0)]), 10, 1.0, 1.0,
		0.0, false)
	lm.lathe("Roof", Vector3(34.5, 32.0, 0), PackedVector2Array([Vector2(21.0, 0), Vector2(0.0, 22.0)]), 10, 1.0, 1.0,
		0.0, false)
	for sz in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		for i in 12:
			var x := -34.0 + 6.0 * i
			LandmarkChParts.pointed(lm, "Windows", Vector3(x, 3.0, sz * 20.0), 2.2, 6.0, b)
			LandmarkChParts.pointed(lm, "Windows", Vector3(x, 12.0, sz * 20.0), 2.6, 17.0, b)
			lm.box("Stone", Vector3(x + 3.0, 15.5, sz * 20.7), Vector3(1.4, 31.0, 2.2))
	for k in 10:
		var a := TAU * (float(k) + 0.5) / 10.0
		if cos(a) > 0.2:
			var b := Basis(Vector3.UP, atan2(cos(a), sin(a)))
			LandmarkChParts.pointed(lm, "Windows", Vector3(34.5, 12.0, 0) + b * Vector3(0, 0, 19.2), 2.6, 17.0, b)
	# Chevet buttresses with pinnacles round the polygonal east end.
	for k in 11:
		var a := TAU * float(k) / 10.0
		if cos(a) > -0.1:
			var q := Vector3(34.5 + cos(a) * 20.9, 0, sin(a) * 20.9)
			lm.box("Stone", q + Vector3(0, 15.5, 0), Vector3(1.6, 31.0, 1.6))
			lm.spire("Stone", q + Vector3(0, 31.0, 0), 0.8, 5.0)
	# West front: portal and tall window between the towers.
	LandmarkChParts.pointed(lm, "Windows", Vector3(-54.5, 0.0, 0), 3.8, 8.0, Basis(Vector3.UP, -PI * 0.5))
	LandmarkChParts.pointed(lm, "Windows", Vector3(-54.5, 12.0, 0), 4.6, 20.0, Basis(Vector3.UP, -PI * 0.5))
	for sz in [-1.0, 1.0]:
		_munich_tower(lm, Vector3(-47.5, 0, sz * 12.9))
	lm.commit(model)

## One tower: square brick shaft with stone courses, octagonal belfry and
## the double-curved copper cap with lantern and cross.
static func _munich_tower(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Brick", p + Vector3(0, 20.0, 0), Vector3(14.0, 40.0, 14.6))
	lm.box("Brick", p + Vector3(0, 53.0, 0), Vector3(13.0, 26.0, 13.6))
	for y in [14.0, 26.0, 40.0, 55.0]:
		LandmarkChParts.band(lm, "Stone", y, 7.0 if y < 40.0 else 6.5, 7.3 if y < 40.0 else 6.8, 0.7, 0.3, p)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", p + Vector3(sx * 7.0, 20.0, sz * 7.3), Vector3(1.3, 40.0, 1.3))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var d := 7.3 if f % 2 == 0 else 7.0
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, 8.0, d), 1, 1.0, 1.6, 6.0, b)
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, 30.0, d), 2, 3.4, 1.5, 7.0, b)
		LandmarkChParts.row(lm, "Windows", p + b * Vector3(0, 44.0, d - 0.5), 2, 3.4, 1.5, 7.0, b)
	lm.frustum("Brick", p + Vector3(0, 66.0, 0), 6.82, 6.82, 10.5, 8, PI / 8.0)
	for f in 8:
		var b := Basis(Vector3.UP, PI * 0.25 * f)
		LandmarkChParts.pointed(lm, "Windows", p + Vector3(0, 67.5, 0) + b * Vector3(0, 0, 6.3), 1.8, 7.0, b)
	LandmarkChParts.band(lm, "Stone", 76.0, 6.5, 6.5, 0.7, 0.5, p)
	var hb := p + Vector3(0, 76.5, 0)
	lm.lathe("Copper", hb, PackedVector2Array([Vector2(7.2, 0), Vector2(7.8, 1.0), Vector2(7.0, 3.0), Vector2(5.2, 6.0),
		Vector2(3.4, 9.0), Vector2(2.5, 11.0)]), 12)
	lm.frustum("Stone", hb + Vector3(0, 11.0, 0), 2.4, 2.2, 3.5, 8)
	lm.lathe("Copper", hb + Vector3(0, 14.5, 0), PackedVector2Array([Vector2(2.9, 0), Vector2(1.8, 1.2),
		Vector2(0.6, 2.4)]), 8)
	LandmarkCeParts.cross(lm, "Gilt", hb + Vector3(0, 16.9, 0), MUNICH_TOP - 93.4)

# --- Dresden Frauenkirche ---

const DRESDEN_TOP := 91.2

static func dresden(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B2A88F", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5F584E", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6A7075", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E907F", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Square body with a semicircular altar apse and a roof round the drum.
	lm.box("Stone", Vector3(0, 12.0, 0), Vector3(40.0, 24.0, 40.0))
	lm.frustum("Stone", Vector3(20.0, 0, 0), 9.0, 9.0, 24.0, 16)
	lm.lathe("Lead", Vector3(20.0, 24.0, 0), PackedVector2Array([Vector2(9.8, 0), Vector2(0.0, 8.0)]), 16)
	LandmarkChParts.band(lm, "Dark", 12.0, 20.0, 20.0, 0.6, 0.3)
	LandmarkChParts.band(lm, "Dark", 24.0, 20.0, 20.0, 1.0, 0.7)
	LandmarkCeParts.hip(lm, "Lead", Vector3(0, 25.0, 0), 41.0, 41.0, 10.0)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		for y in [3.0, 13.0]:
			LandmarkChParts.row(lm, "Windows", b * Vector3(0, y, 20.0), 4, 8.0, 2.6, 7.5, b, false)
		LandmarkChParts.round_arch(lm, "Windows", b * Vector3(0, 0.0, 20.0), 5.0, 9.0, b)
	# Four octagonal stair towers at the corners with copper caps.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 18.0, 0, sz * 18.0)
			lm.frustum("Stone", p, 5.84, 5.84, 32.0, 8, PI / 8.0)
			LandmarkChParts.band(lm, "Dark", 24.0, 5.4, 5.4, 0.8, 0.3, p)
			LandmarkChParts.band(lm, "Dark", 32.0, 5.4, 5.4, 1.0, 0.6, p)
			for f in 8:
				var b := Basis(Vector3.UP, PI * 0.25 * f)
				LandmarkChParts.row(lm, "Windows", p + Vector3(0, 8.0, 0) + b * Vector3(0, 0, 5.4), 1, 1.0, 1.4, 5.0, b, false)
				LandmarkChParts.row(lm, "Windows", p + Vector3(0, 26.0, 0) + b * Vector3(0, 0, 5.4), 1, 1.0, 1.4, 4.4, b, false)
			lm.lathe("Copper", p + Vector3(0, 33.0, 0), PackedVector2Array([Vector2(5.8, 0), Vector2(6.3, 0.8),
				Vector2(5.4, 2.4), Vector2(3.6, 5.0), Vector2(2.4, 7.0)]), 12)
			lm.frustum("Stone", p + Vector3(0, 40.0, 0), 1.9, 1.7, 3.0, 8)
			lm.lathe("Copper", p + Vector3(0, 43.0, 0), PackedVector2Array([Vector2(2.2, 0), Vector2(1.2, 1.0),
				Vector2(0.4, 1.8)]), 8)
			LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, 44.8, 0), 2.0, 0.35)
	# Drum, the 28 m stone bell with its eight ribs, lantern, orb and cross.
	var db := Vector3(0, 24.0, 0)
	lm.frustum("Stone", db, 13.5, 13.5, 17.0, 16)
	for k in 8:
		var b := Basis(Vector3.UP, PI * 0.25 * k)
		LandmarkChParts.round_arch(lm, "Windows", db + Vector3(0, 5.0, 0) + b * Vector3(0, 0, 13.45), 2.4, 8.0, b)
	LandmarkChParts.band(lm, "Dark", 40.0, 13.5, 13.5, 1.0, 0.6)
	var prof := PackedVector2Array([Vector2(13.5, 0), Vector2(14.2, 1.5), Vector2(14.0, 4.0), Vector2(12.5, 9.0),
		Vector2(10.0, 15.0), Vector2(7.6, 21.0), Vector2(5.8, 26.0), Vector2(5.2, 28.0)])
	lm.lathe("Stone", Vector3(0, 41.0, 0), prof, 16)
	for k in 8:
		var a := PI * 0.25 * k
		for j in prof.size() - 1:
			var p0 := Vector3(cos(a) * (prof[j].x + 0.2), 41.0 + prof[j].y, sin(a) * (prof[j].x + 0.2))
			var p1 := Vector3(cos(a) * (prof[j + 1].x + 0.2), 41.0 + prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.2))
			lm.beam("Dark", p0, p1, 0.7, 0.4)
	lm.frustum("Stone", Vector3(0, 69.0, 0), 5.0, 4.4, 8.0, 12)
	lm.lathe("Stone", Vector3(0, 77.0, 0), PackedVector2Array([Vector2(4.8, 0), Vector2(3.0, 2.0), Vector2(1.6, 3.8),
		Vector2(0.9, 5.0)]), 12)
	LandmarkChParts.finial(lm, "Gilt", Vector3(0, 82.0, 0), 3.0, 1.2)
	LandmarkCeParts.cross(lm, "Gilt", Vector3(0, 85.0, 0), DRESDEN_TOP - 85.0)
	lm.commit(model)

# --- Berlin Cathedral ---

const BERLIN_TOP := 114.0

static func berlin(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9AE96", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#8C8574", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6A9482", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Central block, portico wing to the south, choir and apse to the north.
	lm.box("Stone", Vector3(0, 19.0, 0), Vector3(62.0, 38.0, 62.0))
	lm.box("Stone", Vector3(0, 15.0, 43.0), Vector3(74.0, 30.0, 24.0))
	lm.box("Stone", Vector3(0, 13.0, -43.0), Vector3(40.0, 26.0, 24.0))
	lm.gable("Copper", Vector3(0, 26.0, -43.0), 40.0, 24.0, 9.0, Basis(), 0.6, "Stone")
	lm.frustum("Stone", Vector3(0, 0, -55.0), 12.0, 12.0, 26.0, 12)
	lm.lathe("Copper", Vector3(0, 26.0, -55.0), PackedVector2Array([Vector2(13.0, 0), Vector2(0.0, 9.0)]), 12)
	LandmarkCeParts.hip(lm, "Copper", Vector3(0, 38.0, 0), 62.0, 62.0, 8.0)
	LandmarkCeParts.hip(lm, "Copper", Vector3(0, 30.0, 43.0), 74.0, 24.0, 6.0)
	for y in [10.0, 20.0]:
		LandmarkChParts.band(lm, "Dark", y, 31.0, 31.0, 0.7, 0.4)
	LandmarkChParts.band(lm, "Dark", 37.0, 31.0, 31.0, 1.0, 0.8)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		if f != 0:
			for y in [3.5, 13.0, 23.0]:
				LandmarkChParts.row(lm, "Windows", b * Vector3(0, y, 31.0), 5, 10.0, 3.0,
					6.0 if y < 20.0 else 8.0, b, false)
	for sx in [-1.0, 1.0]:
		for y in [3.5, 12.0, 21.0]:
			LandmarkChParts.row(lm, "Windows", Vector3(sx * 37.0, y, 43.0), 3, 7.0, 2.4, 5.5,
				Basis(Vector3.UP, PI * 0.5 * sx), false)
	# Portico: four columns in front of the deep arched niche, pediment above.
	LandmarkChParts.round_arch(lm, "Windows", Vector3(0, 0.0, 55.0), 13.0, 22.0)
	for sx in [-1.0, 1.0]:
		for dx in [5.5, 11.0]:
			lm.frustum("Stone", Vector3(sx * dx, 0.0, 57.5), 1.1, 1.0, 22.0, 14)
	lm.box("Stone", Vector3(0, 23.5, 56.5), Vector3(28.0, 3.0, 5.0))
	lm.gable("Stone", Vector3(0, 25.0, 57.0), 28.0, 4.0, 4.5, Basis(), 0.0, "Stone")
	LandmarkChParts.row(lm, "Windows", Vector3(-25.0, 4.0, 55.0), 2, 8.0, 2.6, 9.0, Basis(), false)
	LandmarkChParts.row(lm, "Windows", Vector3(25.0, 4.0, 55.0), 2, 8.0, 2.6, 9.0, Basis(), false)
	# Drum with sixteen columns, ribbed copper dome, lantern, orb and cross.
	var db := Vector3(0, 38.0, 0)
	lm.frustum("Stone", db, 17.5, 17.5, 20.0, 24)
	for k in 16:
		var a := TAU * k / 16.0
		lm.frustum("Stone", db + Vector3(cos(a) * 18.2, 0.0, sin(a) * 18.2), 0.8, 0.7, 20.0, 8)
		var b := Basis(Vector3.UP, atan2(cos(a + TAU / 32.0), sin(a + TAU / 32.0)))
		LandmarkChParts.round_arch(lm, "Windows", db + Vector3(0, 5.0, 0) + b * Vector3(0, 0, 17.45), 2.0, 9.0, b)
	LandmarkChParts.band(lm, "Dark", 58.0, 17.5, 17.5, 1.2, 0.9)
	var prof := PackedVector2Array([Vector2(17.5, 0), Vector2(17.2, 3.0), Vector2(16.2, 8.0), Vector2(14.0, 14.0),
		Vector2(11.0, 19.5), Vector2(8.0, 24.0), Vector2(5.6, 27.5), Vector2(4.4, 29.2), Vector2(4.4, 30.0)])
	lm.lathe("Copper", Vector3(0, 59.2, 0), prof, 24)
	for k in 16:
		var a := TAU * k / 16.0
		for j in prof.size() - 2:
			var p0 := Vector3(cos(a) * (prof[j].x + 0.15), 59.2 + prof[j].y, sin(a) * (prof[j].x + 0.15))
			var p1 := Vector3(cos(a) * (prof[j + 1].x + 0.15), 59.2 + prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.15))
			lm.beam("Stone", p0, p1, 0.45, 0.3)
	lm.frustum("Stone", Vector3(0, 89.2, 0), 4.4, 4.0, 10.0, 12)
	for k in 8:
		var a := TAU * k / 8.0
		lm.frustum("Gilt", Vector3(cos(a) * 4.5, 89.2, sin(a) * 4.5), 0.35, 0.3, 10.0, 8)
	lm.lathe("Copper", Vector3(0, 99.2, 0), PackedVector2Array([Vector2(4.8, 0), Vector2(4.4, 0.6), Vector2(3.2, 3.0),
		Vector2(1.6, 5.0), Vector2(0.6, 6.4)]), 16)
	LandmarkChParts.finial(lm, "Gilt", Vector3(0, 105.6, 0), 2.4, 1.0)
	LandmarkCeParts.cross(lm, "Gilt", Vector3(0, 108.0, 0), BERLIN_TOP - 108.0)
	# Four corner cupolas on square towers.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 25.0, 0, sz * 25.0)
			lm.box("Stone", p + Vector3(0, 45.0, 0), Vector3(11.0, 14.0, 11.0))
			LandmarkChParts.band(lm, "Dark", 52.0, 5.5, 5.5, 0.8, 0.4, p)
			lm.frustum("Stone", p + Vector3(0, 52.8, 0), 4.7, 4.4, 5.0, 8, PI / 8.0)
			lm.lathe("Copper", p + Vector3(0, 57.8, 0), LandmarkChParts.swell(5.0, 8.0), 12)
			lm.frustum("Stone", p + Vector3(0, 65.0, 0), 1.7, 1.5, 3.0, 8)
			lm.lathe("Copper", p + Vector3(0, 68.0, 0), PackedVector2Array([Vector2(2.1, 0), Vector2(1.2, 1.0),
				Vector2(0.4, 1.8)]), 8)
			LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, 69.8, 0), 2.4, 0.35)
	lm.commit(model)
