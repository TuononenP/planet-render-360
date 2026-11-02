class_name LandmarkCeIstanbul
extends RefCounted

## Istanbul in true metres: Hagia Sophia (central dome on its drum
## between two semi-domes, buttresses and four minarets, 60 m), the
## Sultan Ahmed or Blue Mosque (cascade of domes and semi-domes, domed
## forecourt arcade, six minarets, 64 m) and the Galata Tower (stone
## cylinder, gallery and conical lead cap, 66.9 m on its hilltop).

const SOPHIA_TOP := 60.0

static func hagia_sophia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#C99A7A", 4.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#D8C4A4", 4.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#7A7E80", 2.5, 0.5, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave block, the semi-dome exedrae east and west, narthex and apse.
	lm.box("Wall", Vector3(0, 14.0, 0), Vector3(64.0, 28.0, 56.0))
	for sx in [-1.0, 1.0]:
		lm.box("Wall", Vector3(sx * 38.0, 12.0, 0), Vector3(14.0, 24.0, 30.0))
		LandmarkCeParts.dome(lm, "Dome", Vector3(sx * 27.0, 26.0, 0), 15.0, 12.0, 24)
		lm.lathe("Wall", Vector3(sx * 45.0, 0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(8.0, 16.0)]), 12, 1.0, 1.0, 0.0, false)
		LandmarkCeParts.dome(lm, "Dome", Vector3(sx * 45.0, 16.0, 0), 8.4, 5.0, 12)
		for sz in [-1.0, 1.0]:
			# Great buttresses and the semi-domed bays between them.
			for bx in [-20.0, -6.0, 8.0, 22.0]:
				lm.box("Wall", Vector3(bx, 13.0, sz * 32.5), Vector3(7.0, 26.0, 9.0))
				lm.box("Pale", Vector3(bx, 26.4, sz * 32.5), Vector3(7.6, 0.8, 9.6))
	lm.box("Pale", Vector3(-52.0, 8.0, 0), Vector3(8.0, 16.0, 52.0))
	LandmarkCeParts.windows(lm, "Windows", Vector3(-56.05, 8.0, 0), Vector3(0, 0, 1), 9, 5.0, Vector3(0.2, 5.0, 2.0))
	LandmarkKits.dome_on_drum(lm, "Pale", "Dome", Vector3(0, 28.0, 0), 16.0, 11.0, 14.0, 2.6, 40)
	for k in 40:
		var a := TAU * k / 40.0
		lm.box("Windows", Vector3(cos(a) * 16.05, 36.0, sin(a) * 16.05), Vector3(1.0, 5.0, 1.0), Basis(Vector3.UP, PI * 0.5 - a))
	# Four Ottoman minarets at the corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkKits.minaret(lm, "Pale", "Dome", Vector3(sx * 46.0, 0, sz * 34.0), 2.1, SOPHIA_TOP, 2)
	lm.commit(model)

# --- Blue Mosque ---

const BLUE_TOP := 64.0

static func blue_mosque(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#D2CABA", 4.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#6F7479", 2.5, 0.5, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#B5AE9F", 4.0))
	lm.box("Court", Vector3(0, 0.1, -50.0), Vector3(62.0, 0.2, 72.0))
	lm.box("Wall", Vector3(0, 9.0, 14.0), Vector3(62.0, 18.0, 56.0))
	LandmarkCeParts.windows(lm, "Windows", Vector3(0, 8.0, 42.1), Vector3(1, 0, 0), 9, 6.0, Vector3(2.4, 7.0, 0.2))
	# Cascade: main dome on its drum, four semi-domes, four corner domes.
	var mc := Vector3(0, 18.0, 14.0)
	LandmarkKits.dome_on_drum(lm, "Wall", "Dome", mc, 11.75, 10.0, 15.0, 0.0, 32)
	for k in 28:
		var a := TAU * k / 28.0
		lm.box("Windows", mc + Vector3(cos(a) * 11.8, 5.0, sin(a) * 11.8), Vector3(0.9, 4.0, 0.9), Basis(Vector3.UP, PI * 0.5 - a))
	lm.beam("Gilt", mc + Vector3(0, 24.8, 0), mc + Vector3(0, 27.0, 0), 0.3, 0.3)
	for d in [[1.0, 0.0], [-1.0, 0.0], [0.0, 1.0], [0.0, -1.0]]:
		LandmarkCeParts.dome(lm, "Dome", mc + Vector3(float(d[0]) * 16.0, 0, float(d[1]) * 16.0), 9.5, 11.0, 24)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkCeParts.dome(lm, "Dome", mc + Vector3(sx * 20.0, 0, sz * 20.0), 5.4, 5.0, 16)
	# Domed forecourt arcade round three sides, with the ablution fountain.
	for p in [[0.0, -85.0, 62.0, 3.0], [-31.0, -50.0, 3.0, 72.0], [31.0, -50.0, 3.0, 72.0]]:
		lm.box("Wall", Vector3(float(p[0]), 4.5, float(p[1])), Vector3(float(p[2]) + 3.0, 9.0, float(p[3]) + 3.0))
	for i in 9:
		var t := -26.0 + 52.0 * i / 8.0
		LandmarkCeParts.dome(lm, "Dome", Vector3(t, 9.0, -85.0), 3.3, 2.8, 14)
	for i in 9:
		var t := -80.0 + 66.0 * i / 8.0
		for sx in [-1.0, 1.0]:
			LandmarkCeParts.dome(lm, "Dome", Vector3(sx * 31.0, 9.0, t), 3.3, 2.8, 14)
	lm.frustum("Wall", Vector3(0, 0, -50.0), 4.0, 4.0, 3.2, 8)
	LandmarkCeParts.dome(lm, "Dome", Vector3(0, 3.2, -50.0), 4.4, 3.4, 12)
	# Six minarets: four on the prayer hall, two at the forecourt corners.
	for sx in [-1.0, 1.0]:
		for z in [-12.0, 40.0]:
			LandmarkKits.minaret(lm, "Wall", "Dome", Vector3(sx * 34.0, 0, z), 2.0, BLUE_TOP, 3)
		LandmarkKits.minaret(lm, "Wall", "Dome", Vector3(sx * 34.0, 0, -86.0), 2.0, 58.0, 2)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0, -14.0)
	model.add_child(pivot)
	lm.commit(pivot)

# --- Galata Tower ---

const GALATA_TOP := 66.9

static func galata(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B0A184", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#7C705C", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6B7176", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#202A30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Foundations and terrace sunk into the hillside.
	lm.frustum("Dark", Vector3(0, -14.0, 0), 11.5, 10.0, 14.0, 24)
	lm.frustum("Stone", Vector3(0, 0, 0), 9.0, 8.2, 3.0, 28)
	lm.lathe("Stone", Vector3(0, 3.0, 0), PackedVector2Array([Vector2(8.2, 0), Vector2(7.9, 20.0),
		Vector2(7.6, 44.0), Vector2(7.5, 47.0)]), 32)
	for lvl in 6:
		var y := 12.0 + 6.5 * lvl
		for k in 8:
			var a := TAU * k / 8.0 + (0.4 if lvl % 2 == 1 else 0.0)
			var rr := 7.9 - (y - 3.0) * 0.0066
			lm.box("Windows", Vector3(cos(a) * rr, y, sin(a) * rr), Vector3(0.9, 2.4, 0.9), Basis(Vector3.UP, PI * 0.5 - a))
	# Machicolated flare, the viewing gallery and the cylindrical lantern.
	lm.lathe("Stone", Vector3(0, 50.0, 0), PackedVector2Array([Vector2(7.5, 0), Vector2(8.6, 1.0),
		Vector2(9.2, 2.2), Vector2(9.2, 4.4), Vector2(8.8, 4.8)]), 32)
	for k in 24:
		var a := TAU * k / 24.0
		lm.box("Dark", Vector3(cos(a) * 9.2, 52.4, sin(a) * 9.2), Vector3(0.9, 1.6, 0.6), Basis(Vector3.UP, PI * 0.5 - a))
		lm.box("Dark", Vector3(cos(a) * 9.2, 55.6, sin(a) * 9.2), Vector3(0.7, 0.9, 0.4), Basis(Vector3.UP, PI * 0.5 - a))
	lm.frustum("Stone", Vector3(0, 54.8, 0), 7.6, 7.2, 4.6, 24)
	for k in 12:
		var a := TAU * k / 12.0
		lm.box("Windows", Vector3(cos(a) * 7.3, 57.0, sin(a) * 7.3), Vector3(1.2, 2.2, 0.6), Basis(Vector3.UP, PI * 0.5 - a))
	lm.lathe("Lead", Vector3(0, 59.4, 0), PackedVector2Array([Vector2(8.4, 0), Vector2(7.8, 0.6),
		Vector2(0.9, 6.6), Vector2(0.4, 7.0)]), 32)
	lm.frustum("Gilt", Vector3(0, 66.0, 0), 0.4, 0.15, GALATA_TOP - 66.0, 8)
	lm.commit(model)
