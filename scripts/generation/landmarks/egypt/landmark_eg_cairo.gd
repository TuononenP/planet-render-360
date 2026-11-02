class_name LandmarkEgCairo
extends RefCounted

## Two great mosques of Islamic Cairo in true metres, built with the
## courtyard / entrance toward +Z and the qibla wall toward -Z (registry
## yaw_deg 136 turns the qibla onto its real bearing, south-east).

# --- Mosque of Muhammad Ali ---

## The Alabaster Mosque (1848, Citadel of Cairo): a 41 m square Ottoman
## prayer hall under a 21 m central dome at 52 m on four semidomes and
## four corner domes, the 54 m arcaded forecourt (+Z) with its domed
## ablution fountain and clock tower, and the two 82 m pencil minarets
## at the front corners of the hall.
static func muhammad_ali(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#DACDAA", 4.0))
	lm.use("Lead", LandmarkMaterials.paint("#8E949A", 0.5, 0.3))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("limestone", "#C9BD9F", 6.0))
	lm.box("Ground", Vector3(0, -0.4, 34.0), Vector3(58.0, 1.0, 100.0))
	# Prayer hall: body, cornice, central block, the four semidomes and the corner domes.
	lm.box("Wall", Vector3(0, 12.0, 0), Vector3(41.0, 24.0, 41.0))
	LandmarkEgParts.taper(lm, "Wall", Vector3(0, 24.0, 0), 41.0, 41.0, 43.0, 43.0, 0.8)
	lm.box("Wall", Vector3(0, 29.4, 0), Vector3(31.0, 10.0, 31.0))
	for p in [Vector2(11.5, 0), Vector2(-11.5, 0), Vector2(0, 11.5), Vector2(0, -11.5)]:
		LandmarkEgParts.dome(lm, "Lead", Vector3(p.x, 24.8, p.y), 9.5, 8.5, 20)
	for p in [Vector2(-17.0, -17.0), Vector2(17.0, -17.0)]:
		LandmarkEgParts.dome(lm, "Lead", Vector3(p.x, 24.8, p.y), 3.8, 4.0, 12)
	LandmarkKits.dome_on_drum(lm, "Wall", "Lead", Vector3(0, 34.4, 0), 10.5, 2.6, 13.0, 2.0, 32)
	lm.box("Dark", Vector3(0, 12.0, 20.6), Vector3(7.0, 12.0, 0.3))
	for s in [-1.0, 1.0]:
		LandmarkKits.minaret(lm, "Wall", "Lead", Vector3(s * 17.5, 24.8, 17.5), 1.7, 57.2, 2)
		lm.box("Wall", Vector3(s * 17.5, 28.0, 17.5), Vector3(5.4, 8.0, 5.4))
	# Forecourt: arcaded ring of small domes, fountain pavilion, clock tower.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Wall", Vector2(s * 27.0, 20.5), Vector2(s * 27.0, 74.5), 9.0, 1.4)
		LandmarkEgParts.colonnade(lm, "Wall", Vector3(s * 22.5, 0, 24.0), Vector3(s * 22.5, 0, 71.0),
			13, 0.45, 6.0, LandmarkEgParts.PLAIN)
		lm.box("Wall", Vector3(s * 24.8, 6.6, 47.5), Vector3(5.2, 1.2, 54.0))
		for k in 12:
			LandmarkEgParts.dome(lm, "Lead", Vector3(s * 24.8, 7.2, 26.0 + 4.0 * k), 1.9, 1.5, 8)
	LandmarkEgParts.wall(lm, "Wall", Vector2(-27.0, 74.5), Vector2(27.0, 74.5), 9.0, 1.4)
	lm.box("Wall", Vector3(0, 6.6, 72.0), Vector3(44.0, 1.2, 5.0))
	for k in 11:
		LandmarkEgParts.dome(lm, "Lead", Vector3(-20.0 + 4.0 * k, 7.2, 72.0), 1.9, 1.5, 8)
	lm.box("Wall", Vector3(0, 7.0, 66.0), Vector3(4.6, 14.0, 4.6))
	lm.lathe("Lead", Vector3(0, 14.0, 66.0), PackedVector2Array([Vector2(3.8, 0), Vector2(3.2, 1.2),
		Vector2(0.0, 5.5)]), 8)
	lm.lathe("Wall", Vector3(0, 0, 47.5), PackedVector2Array([Vector2(4.4, 0), Vector2(4.2, 3.6)]), 8)
	lm.lathe("Lead", Vector3(0, 3.6, 47.5), PackedVector2Array([Vector2(5.4, 0), Vector2(4.4, 1.0),
		Vector2(0.0, 3.2)]), 8)
	lm.commit(model)

# --- Mosque-Madrasa of Sultan Hassan ---

## The Mamluk mosque and four-school madrasa (1356-63): a 150 x 68 m
## ashlar block with 36 m walls under a stalactite cornice, the 38 m
## entrance portal at the front corner, the open court between four
## iwans, the qibla iwan and, behind it, the square mausoleum with its
## 55 m dome and the surviving 81 m minaret.
static func sultan_hassan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#C2AB84", 3.4))
	lm.use("Lead", LandmarkMaterials.paint("#8E949A", 0.5, 0.3))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("limestone", "#C9BD9F", 6.0))
	lm.box("Ground", Vector3(0, -0.4, 0), Vector3(80.0, 1.0, 160.0))
	lm.box("Wall", Vector3(0, 18.0, 61.0), Vector3(68.0, 36.0, 28.0))
	lm.box("Wall", Vector3(0, 18.0, -31.0), Vector3(32.0, 36.0, 32.0))
	lm.box("Wall", Vector3(0, 18.0, -61.0), Vector3(28.0, 36.0, 28.0))
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 25.0, 17.0, 0), Vector3(18.0, 34.0, 94.0))
		lm.box("Dark", Vector3(s * 15.8, 9.0, 16.0), Vector3(0.4, 18.0, 10.0))
		# Cornice band round the outer walls.
		lm.box("Wall", Vector3(s * 34.4, 36.8, 14.0), Vector3(1.6, 1.8, 122.0))
		lm.box("Wall", Vector3(s * 14.4, 36.8, -61.0), Vector3(1.6, 1.8, 28.0))
	lm.box("Wall", Vector3(0, 36.8, 75.4), Vector3(69.6, 1.8, 1.6))
	lm.box("Wall", Vector3(0, 36.8, -75.4), Vector3(29.6, 1.8, 1.6))
	lm.box("Dark", Vector3(0, 12.0, -14.8), Vector3(14.0, 24.0, 0.4))
	# Entrance portal at the north (left) corner: recessed arch under a stalactite hood.
	lm.box("Wall", Vector3(-20.0, 19.0, 77.5), Vector3(14.0, 38.0, 5.0))
	lm.box("Dark", Vector3(-20.0, 9.0, 80.1), Vector3(5.0, 18.0, 0.5))
	LandmarkEgParts.taper(lm, "Wall", Vector3(-20.0, 18.0, 77.5), 9.0, 5.2, 12.0, 5.6, 8.0)
	LandmarkEgParts.taper(lm, "Wall", Vector3(-20.0, 38.0, 77.5), 14.0, 5.0, 15.6, 6.4, 1.0)
	# Court fountain, mausoleum dome and minaret.
	lm.lathe("Wall", Vector3(0, 0, 16.0), PackedVector2Array([Vector2(3.4, 0), Vector2(3.2, 3.2)]), 8)
	lm.lathe("Lead", Vector3(0, 3.2, 16.0), PackedVector2Array([Vector2(4.2, 0), Vector2(3.6, 1.0),
		Vector2(0.0, 3.0)]), 8)
	LandmarkKits.dome_on_drum(lm, "Wall", "Lead", Vector3(0, 36.0, -61.0), 9.5, 4.5, 13.0, 2.0, 24)
	lm.box("Wall", Vector3(21.0, 37.0, -45.0), Vector3(5.6, 6.0, 5.6))
	LandmarkKits.minaret(lm, "Wall", "Lead", Vector3(21.0, 40.0, -45.0), 2.2, 41.0, 2)
	lm.commit(model)
