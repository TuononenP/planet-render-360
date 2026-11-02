class_name LandmarkParisChurches
extends RefCounted

## Notre-Dame de Paris and Sacré-Cœur in true metres, y = 0 at the
## parvis / basilica platform.

## Notre-Dame (96 m to the tip of the flèche): west facade with two
## 69 m towers, three portals, Gallery of Kings, rose window and Great
## Gallery; the 128 m long nave with double aisles, flying buttresses
## and a 43 m lead roof; the transept; the rounded apse; and the oak
## spire over the crossing. Nave along X, facade at the west (-X) end.
static func notre_dame(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C4B493", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6F767A", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Aisles and clerestory with the steep lead roof, apse closing the east.
	LandmarkWestKit.blk(lm, "Stone", -5.0, 0.0, 0.0, 90.0, 20.0, 40.0)
	LandmarkWestKit.blk(lm, "Lead", -5.0, 20.0, 0.0, 88.0, 0.8, 38.0)
	LandmarkWestKit.blk(lm, "Stone", -5.0, 20.0, 0.0, 90.0, 10.0, 17.0)
	lm.gable("Lead", Vector3(-5.0, 30.0, 0), 17.0, 90.0, 13.0, rot, 0.8, "Stone")
	lm.lathe("Stone", Vector3(40, 0, 0), PackedVector2Array([Vector2(20, 0), Vector2(20, 20)]), 16,
		1.0, 1.0, 0.0, false)
	lm.lathe("Lead", Vector3(40, 20, 0), PackedVector2Array([Vector2(19.5, 0), Vector2(19.5, 0.8)]), 16)
	lm.lathe("Stone", Vector3(40, 20, 0), PackedVector2Array([Vector2(8.5, 0), Vector2(8.5, 10)]), 10,
		1.0, 1.0, 0.0, false)
	lm.lathe("Lead", Vector3(40, 30, 0), PackedVector2Array([Vector2(9.4, 0), Vector2(0.4, 13)]), 10,
		1.0, 1.0, 0.0, false)
	# Transept with its rose-window gable ends.
	LandmarkWestKit.blk(lm, "Stone", 4.0, 0.0, 0.0, 17.0, 30.0, 48.0)
	lm.gable("Lead", Vector3(4.0, 30.0, 0), 17.0, 48.0, 13.0, Basis(), 0.8, "Stone")
	for sz in [-1.0, 1.0]:
		lm.disc("Glass", Vector3(4.0, 24.0, sz * 24.1), Vector3(0, 0, sz), 4.2)
		lm.box("Glass", Vector3(4.0, 11.0, sz * 24.1), Vector3(5.0, 14.0, 0.3))
	# Flying buttresses: pier + pinnacle + arched flyer to the clerestory.
	for k in 11:
		var x := -46.0 + 8.4 * float(k)
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(x, 12.0, sz * 20.6), Vector3(1.8, 24.0, 1.8))
			lm.spire("Stone", Vector3(x, 24.0, sz * 20.6), 1.0, 4.5)
			lm.beam("Stone", Vector3(x, 25.0, sz * 19.8), Vector3(x, 29.0, sz * 8.6), 1.3, 1.0)
			lm.box("Glass", Vector3(x, 25.0, sz * 8.55), Vector3(2.4, 8.0, 0.2))
	# West facade: towers, centre section, portals, galleries, rose.
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", -57.0, 0.0, sz * 13.4, 14.0, 67.5, 14.0)
		LandmarkWestKit.blk(lm, "Stone", -57.0, 67.5, sz * 13.4, 14.8, 1.5, 14.8)
		for wz in [-3.2, 3.2]:
			lm.box("Glass", Vector3(-64.1, 52.0, sz * 13.4 + wz), Vector3(0.3, 13.0, 2.0))
		lm.box("Glass", Vector3(-57.0, 52.0, sz * 20.1), Vector3(2.0, 13.0, 0.3))
	LandmarkWestKit.blk(lm, "Stone", -57.0, 0.0, 0.0, 14.0, 44.0, 13.0)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-64.6, 19.0, -19.0), Vector3(-64.6, 19.0, 19.0),
		28, 0.35, 0.3, 3.0)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-64.6, 38.0, -19.5), Vector3(-64.6, 38.0, 19.5),
		30, 0.28, 0.25, 4.6)
	for pz in [-20.2, -6.4, 6.4, 20.2]:
		LandmarkWestKit.blk(lm, "Stone", -64.5, 0.0, pz, 2.0, 62.0, 1.8)
	for pc in [[-12.5, 4.6, 9.5], [0.0, 6.4, 11.5], [12.5, 4.6, 9.5]]:
		lm.box("Glass", Vector3(-64.2, pc[2] * 0.5, pc[0]), Vector3(0.4, pc[2], pc[1]))
		lm.spire("Stone", Vector3(-64.6, pc[2], pc[0]), pc[1] * 0.55, 5.0, 0.3)
	lm.disc("Glass", Vector3(-64.2, 28.0, 0), Vector3(-1, 0, 0), 4.8)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.beam("Stone", Vector3(-64.35, 28.0, 0), Vector3(-64.35, 28.0 + sin(a) * 4.8, cos(a) * 4.8), 0.22)
	# Oak flèche over the crossing, lead-clad (96 m to the tip).
	lm.lathe("Lead", Vector3(4.0, 36.0, 0), PackedVector2Array([Vector2(5.2, 0), Vector2(5.2, 10)]), 8,
		1.0, 1.0, PI / 8.0, false)
	lm.lathe("Lead", Vector3(4.0, 46.0, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(3.4, 8),
		Vector2(2.2, 20), Vector2(1.0, 34), Vector2(0.35, 44), Vector2(0.0, 50)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.lathe("Gilt", Vector3(4.0, 92.0, 0), LandmarkWestKit.ball(0.5), 8)
	lm.commit(model)

## Sacré-Cœur (83 m): the white travertine Romano-Byzantine basilica
## on the Montmartre summit — elongated central dome on a windowed drum
## with lantern, four small corner domes, the three-arch porch with its
## stair down the hill (south, +Z) and the 78 m Savoyarde campanile
## behind the apse (north, -Z).
static func sacre_coeur(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#E6E1D3", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#B5AE9F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Cross-plan body and apse.
	LandmarkWestKit.blk(lm, "White", 0, -4.0, 0, 28.0, 32.0, 62.0)
	LandmarkWestKit.blk(lm, "White", 0, -4.0, 3.0, 52.0, 32.0, 22.0)
	lm.lathe("White", Vector3(0, -4, -31.0), PackedVector2Array([Vector2(14, 0), Vector2(14, 28)]), 14,
		1.0, 1.0, 0.0, false)
	lm.lathe("White", Vector3(0, 24, -31.0), LandmarkWestKit.dome_prof(14.0, 9.0, 6, 1.5), 14)
	# Central drum and elongated dome, lantern, cap and cross (83 m).
	var c := Vector3(0, 28, 3.0)
	lm.frustum("White", c, 9.5, 9.5, 14.0, 20)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Glass", c + Vector3(cos(a) * 9.55, 7.0, sin(a) * 9.55), Vector3(1.3, 5.5, 0.2),
			Basis(Vector3.UP, -a + PI * 0.5))
		lm.beam("White", c + Vector3(cos(a) * 9.8, 14.0, sin(a) * 9.8),
			c + Vector3(cos(a) * 0.6, 38.0, sin(a) * 0.6), 0.5, 0.4)
	lm.lathe("White", c + Vector3(0, 14, 0), LandmarkWestKit.dome_prof(9.7, 26.0, 12, 1.5), 20)
	lm.frustum("White", c + Vector3(0, 40, 0), 2.6, 2.3, 9.0, 12)
	lm.lathe("White", c + Vector3(0, 49, 0), LandmarkWestKit.dome_prof(2.5, 3.5, 5), 12)
	LandmarkWestKit.cross(lm, "Gilt", c + Vector3(0, 52.0, 0), 3.0)
	# Four corner domes and two facade turrets.
	for p in [Vector2(-15, -9), Vector2(15, -9), Vector2(-15, 15), Vector2(15, 15),
			Vector2(-12, 27), Vector2(12, 27)]:
		var b := Vector3(p.x, 28, p.y)
		var r := 4.3 if absf(p.y) < 20.0 else 3.0
		LandmarkKits.dome_on_drum(lm, "White", "White", b, r, 6.0, 9.0, 0.0, 12)
		LandmarkWestKit.cross(lm, "Gilt", b + Vector3(0, 14.6, 0), 2.4)
	# South porch: three arches, niches with the two equestrian statues.
	LandmarkWestKit.blk(lm, "White", 0, -4.0, 32.0, 30.0, 18.0, 4.0)
	for x in [-8.0, 0.0, 8.0]:
		lm.box("Glass", Vector3(x, 5.0, 34.05), Vector3(5.0, 10.0, 0.2))
		lm.spire("White", Vector3(x, 10.0, 34.1), 2.6, 3.2, 0.2)
	for x in [-12.0, 12.0]:
		LandmarkWestKit.blk(lm, "Gilt", x, 14.0, 34.1, 2.4, 4.0, 1.2)
	LandmarkWestKit.col_row(lm, "White", Vector3(-12.0, 14.0, 34.2), Vector3(12.0, 14.0, 34.2),
		9, 0.35, 0.3, 6.0)
	for k in 9:
		LandmarkWestKit.blk(lm, "Steps", 0, -12.0, 36.0 + 2.0 * float(k), 36.0 + 2.0 * float(k),
			12.0 - 1.3 * float(k + 1), 2.0)
	# Savoyarde campanile behind the apse.
	LandmarkWestKit.blk(lm, "White", 0, -4.0, -54.0, 12.5, 66.0, 12.5)
	LandmarkWestKit.blk(lm, "White", 0, 62.0, -54.0, 10.5, 11.0, 10.5)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Glass", Vector3(0, 67.5, -54.0) + r * Vector3(0, 0, 5.3), Vector3(3.2, 7.0, 0.2), r)
	lm.lathe("White", Vector3(0, 73, -54.0), LandmarkWestKit.dome_prof(5.4, 5.4, 6, 1.4), 12)
	lm.commit(model)
