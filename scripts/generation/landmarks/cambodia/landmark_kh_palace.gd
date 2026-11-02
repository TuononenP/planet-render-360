class_name LandmarkKhPalace
extends RefCounted

## Phnom Penh royal and national buildings in true metres: the Royal Palace
## (Throne Hall and its pavilions), the Silver Pagoda compound and the
## National Museum. All are built facing +X (east) and turned onto the
## street grid by the registry yaw.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Royal Palace (59 m): the cross-plan Throne Hall (1917) under three
## spires, the central one a stepped tower carrying the white four-faced
## head of Brahma and a gilded needle; Khemarin Palace with its single
## prang to the north-west and the open Moonlight Pavilion by the east wall.
static func royal_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F0E6C8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D79A2B", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#9A3A2E", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F5F2EA", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("pavement", "#B9AE98", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2E2824", 2.0))
	# Throne Hall: platform, nave along X, transept along Z, porches.
	lm.box("Base", Vector3(0, 1.2, 0), Vector3(66.0, 2.4, 34.0))
	lm.box("Base", Vector3(0, 1.2, 0), Vector3(30.0, 2.4, 62.0))
	for s in [-1.0, 1.0]:
		U.stair(lm, "Base", Vector3(33.0 * s, 0, 0), Basis(Vector3.UP, PI * 0.5 * s), 9.0, 7, 0.55, 0.34)
	U.hall(lm, "Wall", "White", "Roof", "Red", Vector3(0, 2.4, 0), Basis(Vector3.UP, PI * 0.5),
		18.0, 56.0, 0.0, 8.0, 5.2, 3, 12)
	U.hall(lm, "Wall", "White", "Roof", "Red", Vector3(0, 2.4, 0), Basis(), 18.0, 54.0, 0.0, 8.0,
		5.2, 3, 12)
	# Central spire on the crossing: stepped square tiers, Brahma head, needle.
	var y := 2.4 + 8.4 + 5.2 * 1.4
	lm.box("Wall", Vector3(0, y + 2.0, 0), Vector3(11.0, 4.0, 11.0))
	y += 4.0
	for k in 3:
		var w := 8.4 - 1.4 * float(k)
		lm.box("White", Vector3(0, y + 0.25, 0), Vector3(w + 1.2, 0.5, w + 1.2))
		lm.box("Wall", Vector3(0, y + 2.7, 0), Vector3(w, 4.4, w))
		lm.spire("Roof", Vector3(0, y + 4.9, 0), w * 0.72, 2.0, w * 0.34)
		y += 7.0
	lm.box("White", Vector3(0, y + 2.8, 0), Vector3(3.6, 5.6, 3.6))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("White", b * Vector3(0, y + 3.0, 1.9), Vector3(2.0, 2.6, 0.5), b)
		lm.box("Dark", b * Vector3(0, y + 3.4, 2.18), Vector3(1.4, 0.3, 0.1), b)
		lm.box("Gold", b * Vector3(0, y + 4.8, 1.0), Vector3(2.4, 0.5, 2.4), b)
	U.lotus_bud(lm, "Gold", Vector3(0, y + 5.6, 0), 1.9, 5.0)
	var top := y + 10.6
	lm.lathe("Gold", Vector3(0, top, 0), PackedVector2Array([Vector2(0.45, 0), Vector2(0.22, 2.0),
		Vector2(0.4, 2.4), Vector2(0.0, 59.0 - top)]), 8)
	# Lesser spires over the east and west porches.
	for s in [-1.0, 1.0]:
		var base := Vector3(s * 24.0, 2.4 + 8.4 + 5.2 * 1.8, 0)
		lm.box("Wall", base + Vector3(0, 2.0, 0), Vector3(6.0, 4.0, 6.0))
		lm.spire("Roof", base + Vector3(0, 4.0, 0), 4.2, 5.0, 1.2)
		lm.lathe("Gold", base + Vector3(0, 9.0, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(0.2, 3.5),
			Vector2(0.0, 7.5)]), 8)
	# Khemarin Palace (north-west) with its single prang.
	var k := Vector3(-81.0, 0, -76.0)
	U.hall(lm, "Wall", "White", "Roof", "Red", k, Basis(), 18.0, 46.0, 1.4, 7.0, 4.4, 2, 10)
	U.prasat(lm, "Wall", "Roof", "Dark", k + Vector3(0, 11.0, 0), 4.0, 22.0, 3, 0.3)
	# Moonlight Pavilion (north-east): open pillared hall under a tiered roof.
	var m := Vector3(126.0, 0, -83.0)
	var mb := Basis(Vector3.UP, PI * 0.5)
	U.hall(lm, "Wall", "White", "Roof", "Red", m, mb, 14.0, 34.0, 1.6, 5.5, 4.2, 2, 8)
	lm.commit(model)

## Silver Pagoda (Wat Preah Keo Morakot): the vihear on a raised marble
## base under its three-tier roof and naga-horn ridge, the two stupas, the
## library, Phnom Mondap and the Ramayana cloister enclosing the compound.
static func silver_pagoda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E2DACB", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFE3C0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D6962A", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#8E3328", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Hill", LandmarkMaterials.pbr("grass", "#5F7A45", 4.0))
	lm.use("Gravel", LandmarkMaterials.pbr("pavement", "#B7AC98", 3.0))
	var eb := Basis(Vector3.UP, PI * 0.5)
	lm.box("Gravel", Vector3(0, 0.1, 0), Vector3(150.0, 0.2, 140.0))
	# Vihear: long axis along X, steps up the east end.
	U.hall(lm, "Wall", "Marble", "Roof", "Red", Vector3.ZERO, eb, 20.0, 40.0, 3.0, 7.0, 4.2, 3, 12)
	U.stair(lm, "Marble", Vector3(21.5, 0, 0), eb, 9.0, 9, 0.45, 0.34)
	U.naga_rail(lm, "Marble", Vector3(21.5, 0, -4.8), eb, 4.0, 3.0, 0.2, 0.6, 5)
	U.naga_rail(lm, "Marble", Vector3(21.5, 0, 4.8), eb, 4.0, 3.0, 0.2, 0.6, 5)
	# Stupas of King Suramarit and Princess Kantha Bopha, north-west.
	U.stupa(lm, "Marble", "Gold", Vector3(-26.0, 0, -30.0), 3.4, 17.0)
	U.stupa(lm, "Marble", "Gold", Vector3(-12.0, 0, -34.0), 2.6, 12.0)
	# Library (Hor Samut) and Hor Tray pavilion in the east court.
	U.hall(lm, "Wall", "Marble", "Roof", "Red", Vector3(30.0, 0, -32.0), Basis(), 9.0, 14.0, 1.6,
		5.0, 3.4, 2, 5)
	U.hall(lm, "Wall", "Marble", "Roof", "Red", Vector3(30.0, 0, 32.0), Basis(), 9.0, 14.0, 1.6,
		5.0, 3.4, 2, 5)
	# Phnom Mondap, the artificial hill with a small shrine, south-west.
	lm.lathe("Hill", Vector3(-24.0, 0, 28.0), PackedVector2Array([Vector2(9.0, 0), Vector2(7.0, 3.0),
		Vector2(4.5, 5.4), Vector2(0.0, 6.4)]), 16)
	U.prasat(lm, "Marble", "Wall", "Red", Vector3(-24.0, 6.2, 28.0), 1.5, 6.0, 2, 0.4)
	# Cloister: gabled gallery ranges round the compound.
	var hx := 75.0
	var hz := 70.0
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(0, 2.4, s * hz), Vector3(hx * 2.0, 4.8, 5.0))
		lm.gable("Roof", Vector3(0, 4.8, s * hz), 5.0, hx * 2.0, 2.6, eb, 0.7, "Wall")
		lm.box("Wall", Vector3(s * hx, 2.4, 0), Vector3(5.0, 4.8, hz * 2.0 - 5.0))
		lm.gable("Roof", Vector3(s * hx, 4.8, 0), 5.0, hz * 2.0 - 5.0, 2.6, Basis(), 0.7, "Wall")
	lm.commit(model)

## National Museum of Cambodia (George Groslier, 1920): a red, Khmer-roofed
## U of galleries round a garden court, a three-tier pavilion over the
## entrance hall and two-tier pavilions at the wing ends.
static func national_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#B4523A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8A3222", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E3D3AE", 3.0))
	lm.use("Post", LandmarkMaterials.pbr("wood", "#6A3426", 3.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4C", 4.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Lawn", Vector3(-36.0, 0.05, 0), Vector3(54.0, 0.1, 62.0))
	# Entrance range (east) along Z, side wings along X, the west range
	# closing the court, two end pavilions on the front range.
	var rb := Basis(Vector3.UP, PI * 0.5)
	U.hall(lm, "Wall", "Trim", "Roof", "Post", Vector3.ZERO, Basis(), 17.0, 96.0, 1.4, 5.6, 4.0, 1, 24)
	U.hall(lm, "Wall", "Trim", "Roof", "Post", Vector3(-71.0, 0, 0), Basis(), 14.0, 95.0, 1.4, 5.6, 3.6, 1, 22)
	for s in [-1.0, 1.0]:
		U.hall(lm, "Wall", "Trim", "Roof", "Post", Vector3(-36.0, 0, s * 40.0), rb, 15.0, 56.0, 1.4,
			5.6, 3.6, 1, 14)
		U.hall(lm, "Wall", "Trim", "Roof", "Post", Vector3(2.0, 0, s * 46.0), rb, 14.0, 18.0, 1.4,
			6.4, 5.0, 2, 4)
	# Entrance hall pavilion.
	var top := U.hall(lm, "Wall", "Trim", "Roof", "Post", Vector3(8.0, 0, 0), Basis(Vector3.UP, PI * 0.5),
		16.0, 24.0, 1.4, 7.6, 5.0, 3, 6)
	U.stair(lm, "Trim", Vector3(18.0, 0, 0), Basis(Vector3.UP, PI * 0.5), 10.0, 6, 0.5, 0.25)
	lm.box("Gold", Vector3(8.0, top + 0.4, 0), Vector3(1.0, 0.8, 1.0))
	lm.commit(model)
