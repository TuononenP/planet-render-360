class_name LandmarkParisDomes
extends RefCounted

## The Panthéon and Les Invalides in true metres, y = 0 at street level.

## Panthéon (83 m): Greek-cross plan 110 x 84 m, the 22-column Corinthian
## portico with pediment on the north (-Z) front, the peristyle drum of
## 32 columns, the grey dome, lantern, cupola and cross over the crossing.
static func pantheon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC8B6", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#8B9296", 2.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#B9B3A6", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var c := Vector3(0, 28, 10.0)
	# Cross-plan walls (28 m), cornice band and flat lead roofs.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 10.0, 30.0, 26.0, 90.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 10.0, 84.0, 26.0, 30.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 26.0, 10.0, 31.4, 2.0, 91.4)
	LandmarkWestKit.blk(lm, "Stone", 0, 26.0, 10.0, 85.4, 2.0, 31.4)
	LandmarkWestKit.blk(lm, "Dome", 0, 28.0, 10.0, 28.0, 0.5, 88.0)
	LandmarkWestKit.blk(lm, "Dome", 0, 28.0, 10.0, 82.0, 0.5, 28.0)
	# Portico: 6 x 3 columns on a five-step stylobate, entablature, pediment.
	for k in 5:
		LandmarkWestKit.blk(lm, "Steps", 0, 0, -63.0 + 1.6 * float(k), 44.0 - 2.0 * float(k), 1.0 * float(k + 1),
			1.6)
	LandmarkWestKit.blk(lm, "Steps", 0, 0, -45.0, 40.0, 5.0, 20.0)
	for row in 3:
		LandmarkWestKit.col_row(lm, "Stone", Vector3(-15.0, 5.0, -54.0 + 6.0 * float(row)),
			Vector3(15.0, 5.0, -54.0 + 6.0 * float(row)), 6, 1.0, 0.85, 19.0, 12)
	LandmarkWestKit.blk(lm, "Stone", 0, 24.0, -45.0, 38.0, 3.0, 20.0)
	lm.gable("Stone", Vector3(0, 27.0, -45.0), 38.0, 20.0, 6.5, Basis(), 0.0, "Stone")
	# Peristyle drum, attic, dome, lantern, cupola and cross.
	lm.frustum("Stone", c, 10.2, 10.2, 11.5, 28)
	LandmarkWestKit.col_ring(lm, "Stone", c, 11.4, 32, 0.55, 0.5, 11.0)
	lm.frustum("Stone", c + Vector3(0, 11.5, 0), 12.3, 12.3, 1.8, 32)
	lm.frustum("Stone", c + Vector3(0, 13.3, 0), 10.6, 10.6, 4.7, 28)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Glass", c + Vector3(cos(a) * 10.65, 15.6, sin(a) * 10.65), Vector3(1.2, 2.6, 0.2),
			Basis(Vector3.UP, -a + PI * 0.5))
	lm.lathe("Dome", c + Vector3(0, 18.0, 0), LandmarkWestKit.dome_prof(10.6, 21.0, 12, 1.1), 28)
	lm.frustum("Stone", c + Vector3(0, 39.0, 0), 2.8, 2.6, 6.5, 12)
	LandmarkWestKit.col_ring(lm, "Stone", c + Vector3(0, 39.0, 0), 3.0, 8, 0.3, 0.28, 6.5)
	lm.lathe("Dome", c + Vector3(0, 45.5, 0), LandmarkWestKit.dome_prof(2.9, 3.0, 6), 12)
	LandmarkWestKit.cross(lm, "Gilt", c + Vector3(0, 48.0, 0), 7.0)
	lm.commit(model)

## Les Invalides (107 m): the gilded Dôme church on its square base with
## the two-storey south portico, its drum, ribbed golden dome, lantern
## and needle; the Soldiers' Church behind it and the Hôtel's court of
## honour opening north (-Z) with the 196 m mansard front.
static func invalides(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D3C7A8", 3.5))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#59616A", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Rib", LandmarkMaterials.paint("#E6BE63", 0.3, 0.85))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Court", LandmarkMaterials.pbr("gravel", "#BDB3A0", 5.0))
	# Dôme church: cube body, two-tier south portico with pediment.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 60.0, 30.0, 60.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 30.0, 0, 62.0, 3.0, 62.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 32.0, 34.0, 24.0, 4.0)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-14.0, 0, 35.0), Vector3(14.0, 0, 35.0), 6,
		0.8, 0.7, 11.0, 12)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-9.0, 13.0, 34.5), Vector3(9.0, 13.0, 34.5), 4,
		0.65, 0.55, 8.5, 12)
	lm.gable("Stone", Vector3(0, 24.0, 32.0), 22.0, 4.0, 4.5, Basis(), 0.5, "Stone")
	for sx in [-1.0, 1.0]:
		lm.box("Glass", Vector3(sx * 16.0, 14.0, 30.05), Vector3(4.0, 9.0, 0.2))
		lm.box("Glass", Vector3(sx * 22.0, 14.0, 30.05), Vector3(4.0, 9.0, 0.2))
	# Drum, golden dome with ribs, lantern, cap, needle (107 m).
	lm.frustum("Stone", Vector3(0, 33, 0), 13.6, 13.6, 14.0, 24)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Glass", Vector3(cos(a) * 13.65, 40.0, sin(a) * 13.65), Vector3(1.6, 6.0, 0.2),
			Basis(Vector3.UP, -a + PI * 0.5))
	var prof := LandmarkWestKit.dome_prof(13.6, 28.0, 12, 1.1)
	lm.lathe("Gold", Vector3(0, 47, 0), prof, 24)
	for k in 12:
		var dir := Vector3(cos(TAU * float(k) / 12.0), 0, sin(TAU * float(k) / 12.0))
		for j in prof.size() - 2:
			lm.beam("Rib", Vector3(0, 47, 0) + dir * (prof[j].x + 0.2) + Vector3(0, prof[j].y, 0),
				Vector3(0, 47, 0) + dir * (prof[j + 1].x + 0.2) + Vector3(0, prof[j + 1].y, 0), 0.5, 0.35)
	lm.frustum("Stone", Vector3(0, 75, 0), 3.7, 3.4, 12.0, 12)
	LandmarkWestKit.col_ring(lm, "Gold", Vector3(0, 75, 0), 3.8, 12, 0.22, 0.2, 12.0)
	lm.lathe("Gold", Vector3(0, 87, 0), LandmarkWestKit.dome_prof(3.9, 6.0, 8, 1.8), 12)
	lm.lathe("Gold", Vector3(0, 93, 0), PackedVector2Array([Vector2(0.7, 0), Vector2(0.35, 5.0),
		Vector2(0.08, 14.0)]), 8)
	lm.lathe("Gold", Vector3(0, 98, 0), LandmarkWestKit.ball(0.9), 8)
	# Soldiers' Church (nave + roof) behind the Dôme.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -51.0, 30.0, 22.0, 42.0)
	lm.gable("Slate", Vector3(0, 22.0, -51.0), 30.0, 42.0, 9.0, Basis(), 0.8, "Stone")
	# Hôtel: south range, two wings round the court, mansard north front.
	LandmarkWestKit.blk(lm, "Court", 0, 0, -145.0, 102.0, 0.3, 102.0)
	for r in [[0.0, -83.0, 134.0, 22.0], [-59.0, -145.0, 16.0, 102.0], [59.0, -145.0, 16.0, 102.0],
			[0.0, -204.0, 196.0, 16.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], 21.0, r[3])
		LandmarkWestKit.hip(lm, "Slate", Vector3(r[0], 21.0, r[1]), r[2] + 1.0, r[3] + 1.0, 6.5, 0.9)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -213.0, 26.0, 30.0, 6.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(0, 30.0, -213.0), 27.0, 7.0, 5.0, 0.8)
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-96, 0, -212.2), Vector3(96, 0, -212.2),
		Vector3(0, 0, -1), 6.0, 1.6, 3.4, [5.0, 12.5])
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.win_line(lm, "Glass", Vector3(sx * 51.2, 0, -96.0), Vector3(sx * 51.2, 0, -194.0),
			Vector3(-sx, 0, 0), 6.0, 1.6, 3.4, [5.0, 12.5])
	lm.commit(model)
