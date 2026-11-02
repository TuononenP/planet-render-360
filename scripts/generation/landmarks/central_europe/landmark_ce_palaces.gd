class_name LandmarkCePalaces
extends RefCounted

## Two imperial-era palaces in true metres: the Hungarian Parliament
## (neo-Gothic block along the Danube with its 96 m ribbed dome, the
## river front facing west along Z) and Schönbrunn Palace (the long
## Theresian-yellow baroque front with its forecourt wings, facing
## north, 27 m).

const PARL_TOP := 96.0

static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E1DBCB", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6B7886", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#8794A2", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#A39E94", 4.0))
	lm.box("Steps", Vector3(-62.0, 0.6, 0), Vector3(8.0, 1.2, 270.0))
	# Wings [centre x, centre z, size x, size z, eave]: river and rear
	# fronts, the two chamber blocks, the dome hall and both end wings.
	var wings := [[-47.0, 0.0, 24.0, 268.0, 22.0], [47.0, 0.0, 24.0, 268.0, 22.0],
		[0.0, -65.0, 70.0, 40.0, 22.0], [0.0, 65.0, 70.0, 40.0, 22.0],
		[0.0, 0.0, 70.0, 60.0, 27.0], [0.0, -122.0, 70.0, 24.0, 22.0], [0.0, 122.0, 70.0, 24.0, 22.0]]
	for w in wings:
		var c := Vector3(float(w[0]), 0, float(w[1]))
		var size := Vector3(float(w[2]), float(w[4]), float(w[3]))
		lm.box("Stone", c + Vector3(0, size.y * 0.5, 0), size)
		LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, size.y, 0), size.x - 2.0, size.z - 2.0, 9.0)
	for sx in [-1.0, 1.0]:
		for row in 3:
			LandmarkCeParts.windows(lm, "Windows", Vector3(sx * 59.1, 5.0 + 6.0 * row, 0), Vector3(0, 0, 1), 52,
				5.0, Vector3(0.2, 3.4, 1.8))
	# River-front pinnacles and the corner and gable towers.
	for sx in [-1.0, 1.0]:
		for i in 22:
			var z := -126.0 + 12.0 * i
			lm.box("Stone", Vector3(sx * 58.0, 24.0, z), Vector3(1.4, 4.0, 1.4))
			lm.spire("Stone", Vector3(sx * 58.0, 26.0, z), 0.8, 8.0)
		for z in [-134.0, -100.0, 0.0, 100.0, 134.0]:
			var c := Vector3(sx * 56.0, 0, float(z))
			lm.box("Stone", c + Vector3(0, 20.0, 0), Vector3(12.0, 40.0, 12.0))
			lm.spire("Roof", c + Vector3(0, 40.0, 0), 6.4, 16.0, 0.0, 8)
	# Central dome: sixteen-sided drum, ribbed pointed dome, gilded lantern.
	var db := Vector3(0, 27.0, 0)
	lm.frustum("Stone", db, 14.5, 14.5, 20.0, 16)
	LandmarkCeParts.windows(lm, "Windows", db + Vector3(0, 11.0, 14.8), Vector3(1, 0, 0), 1, 1.0, Vector3(2.2, 12.0, 0.2))
	for k in 16:
		var a := TAU * k / 16.0
		var q := db + Vector3(cos(a) * 15.2, 20.0, sin(a) * 15.2)
		lm.box("Stone", q + Vector3(0, 3.0, 0), Vector3(1.6, 6.0, 1.6))
		lm.spire("Stone", q + Vector3(0, 6.0, 0), 0.9, 7.0)
	var top := db + Vector3(0, 20.0, 0)
	lm.lathe("Dome", top, PackedVector2Array([Vector2(14.5, 0), Vector2(14.2, 4.0), Vector2(12.8, 10.0),
		Vector2(10.4, 17.0), Vector2(7.6, 24.0), Vector2(5.0, 30.0), Vector2(3.0, 35.0),
		Vector2(1.8, 38.0)]), 16, 1.0, 1.0, 0.0, false)
	lm.lathe("Gilt", top + Vector3(0, 38.0, 0), PackedVector2Array([Vector2(1.8, 0), Vector2(1.5, 4.0),
		Vector2(0.9, 8.0), Vector2(0.2, PARL_TOP - 85.0)]), 12)
	lm.commit(model)

# --- Schönbrunn Palace ---

const SCHOEN_TOP := 27.0
const SCHOEN_EAVE := 17.5

static func schoenbrunn(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6C455", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EFEAD8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5A5E57", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#C9B99A", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Gravel", Vector3(0, -0.2, -42.0), Vector3(150.0, 0.4, 70.0))
	# Main block, central pavilion and the two forecourt wings.
	lm.box("Wall", Vector3(0, SCHOEN_EAVE * 0.5, 0), Vector3(176.0, SCHOEN_EAVE, 40.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(0, SCHOEN_EAVE, 0), 170.0, 38.0, 6.0)
	lm.box("Wall", Vector3(0, 10.0, 0), Vector3(48.0, 20.0, 46.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(0, 20.0, 0), 46.0, 44.0, SCHOEN_TOP - 20.0)
	lm.box("White", Vector3(0, 20.2, 0), Vector3(48.4, 0.5, 46.4))
	for sx in [-1.0, 1.0]:
		var wc := Vector3(sx * 76.0, 0, -42.0)
		lm.box("Wall", wc + Vector3(0, 7.5, 0), Vector3(24.0, 15.0, 50.0))
		LandmarkCeParts.hip(lm, "Roof", wc + Vector3(0, 15.0, 0), 22.0, 48.0, 5.5)
		for row in 3:
			LandmarkCeParts.windows(lm, "Windows", wc + Vector3(-sx * 12.1, 3.5 + 4.2 * row, 0), Vector3(0, 0, 1), 9,
				5.0, Vector3(0.2, 2.4, 1.6))
		lm.box("Wall", Vector3(sx * 96.0, 6.0, -20.0), Vector3(16.0, 12.0, 14.0))
		LandmarkCeParts.hip(lm, "Roof", Vector3(sx * 96.0, 12.0, -20.0), 14.0, 12.0, 4.0)
		# Gate obelisks at the entrance to the court.
		lm.spire("White", Vector3(sx * 20.0, 0, -78.0), 1.6, 12.0, 0.5)
		lm.box("Gilt", Vector3(sx * 20.0, 12.4, -78.0), Vector3(1.0, 0.8, 1.0))
	# Pilasters and three window rows on the court front and garden front.
	for sz in [-1.0, 1.0]:
		var zf: float = sz * 20.15
		for i in 30:
			var x := -87.0 + 6.0 * i
			lm.box("White", Vector3(x, 8.5, zf), Vector3(1.2, 15.0, 0.4))
		for row in 3:
			LandmarkCeParts.windows(lm, "Windows", Vector3(0, 3.5 + 4.6 * row, zf + sz * 0.1), Vector3(1, 0, 0), 29,
				6.0, Vector3(1.8, 2.8, 0.2))
	lm.box("White", Vector3(0, 0.5, -20.0), Vector3(48.0, 1.0, 4.0))
	lm.commit(model)
