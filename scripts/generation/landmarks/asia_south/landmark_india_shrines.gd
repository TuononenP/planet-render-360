class_name LandmarkIndiaShrines
extends RefCounted

## Two holy sites in true metres: the Golden Temple (Harmandir Sahib)
## in its pool and the Boudhanath Stupa.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Harmandir Sahib (20 m): marble ground floor, gilded upper floor with
## corner kiosks and the fluted gilt dome, on a platform in the 150 m
## pool (water 0.5 m below the walks), joined to the Darshani Deori
## gate by a causeway running west.
static func golden_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#6A5B48", 2.0))
	lm.box("Water", Vector3(0, -1.5, 0), Vector3(150.0, 2.0, 150.0))
	# Marble walkway (parikrama) all round the pool.
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, -0.75, s * 82.5), Vector3(180.0, 1.5, 15.0))
		lm.box("Marble", Vector3(s * 82.5, -0.75, 0), Vector3(15.0, 1.5, 150.0))
	lm.box("Marble", Vector3(-42.0, -0.1, 0), Vector3(64.0, 1.2, 6.0))
	lm.box("Marble", Vector3(0, 0.25, 0), Vector3(24.0, 1.9, 24.0))
	# Gate pavilion at the head of the causeway.
	U.arch_wall(lm, "Marble", Vector3(-76.0, 0, 0), Basis(Vector3.UP, PI * 0.5), 14.0, 9.0, 6.0,
		4.5, 6.5)
	U.dome(lm, "Gold", Vector3(-76.0, 9.0, 0), 3.0, 3.0, 16)
	# Ground floor: 12.2 m square, an arched doorway on each side.
	lm.box("Marble", Vector3(0, 4.35, 0), Vector3(12.2, 6.3, 12.2))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for x in [-3.6, 0.0, 3.6]:
			lm.box("Recess", b * Vector3(x, 3.6, 6.2), Vector3(2.2, 4.4, 0.2), b)
		U.chhatri(lm, "Gold", "Gold", b * Vector3(4.7, 12.5, 4.7), 2.4, 1.6, 1.6)
	# Gilded upper floor, eave, drum and the lotus dome.
	lm.box("Gold", Vector3(0, 7.7, 0), Vector3(13.4, 0.5, 13.4))
	lm.box("Gold", Vector3(0, 10.0, 0), Vector3(11.0, 4.0, 11.0))
	lm.box("Gold", Vector3(0, 12.25, 0), Vector3(12.4, 0.5, 12.4))
	lm.frustum("Gold", Vector3(0, 12.5, 0), 4.0, 4.0, 1.5, 16)
	U.onion(lm, "Gold", Vector3(0, 14.0, 0), 4.4, 4.0, 24)
	U.finial(lm, "Gold", Vector3(0, 17.8, 0), 2.2, 0.35)
	lm.commit(model)

## Boudhanath Stupa (36 m): three stepped terraces, the white hemispherical
## dome, the gilded harmika with the all-seeing eyes on four sides, 13
## stepped tiers, the umbrella and a spire; a prayer-wheel wall round it.
static func boudhanath(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EEE6", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C9772B", 3.0))
	lm.use("Eyes", LandmarkMaterials.pbr("concrete", "#1F2A44", 2.0))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#9A8A78", 3.0))
	lm.lathe("Wall", Vector3(0, -1.0, 0), PackedVector2Array([Vector2(49.0, 0), Vector2(49.0, 4.0),
		Vector2(44.0, 4.0), Vector2(44.0, 0)]), 32)
	for k in 3:
		lm.frustum("White", Vector3(0, -1.0 + 2.4 * float(k), 0), 41.0 - 3.0 * float(k),
			40.0 - 3.0 * float(k), 2.4, 32)
	lm.frustum("Ochre", Vector3(0, 6.2, 0), 21.0, 20.8, 1.0, 32)
	U.dome(lm, "White", Vector3(0, 6.2, 0), 20.5, 14.3, 40, 14)
	# Harmika: gilded cube with a pair of eyes and the curled nose per face.
	lm.box("Gold", Vector3(0, 23.85, 0), Vector3(9.0, 6.7, 9.0))
	lm.box("Ochre", Vector3(0, 20.7, 0), Vector3(9.6, 0.8, 9.6))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for sx in [-1.0, 1.0]:
			lm.box("Eyes", b * Vector3(sx * 1.7, 24.4, 4.55), Vector3(2.2, 0.8, 0.15), b)
		lm.box("Eyes", b * Vector3(0, 23.2, 4.55), Vector3(0.45, 1.6, 0.15), b)
		lm.box("Eyes", b * Vector3(0, 25.8, 4.55), Vector3(0.7, 0.7, 0.15), b)
	# 13 tiers (stepped cone), umbrella and spire.
	var prof := PackedVector2Array()
	for k in 13:
		var r := lerpf(3.4, 1.0, float(k) / 12.0)
		prof.append(Vector2(r, 27.2 + 0.43 * float(k)))
		prof.append(Vector2(r, 27.2 + 0.43 * float(k) + 0.33))
	lm.lathe("Gold", Vector3.ZERO, prof, 16)
	lm.lathe("Gold", Vector3(0, 32.8, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(2.0, 0.5),
		Vector2(0.4, 0.8)]), 16)
	U.finial(lm, "Gold", Vector3(0, 33.5, 0), 2.5, 0.45)
	lm.commit(model)
