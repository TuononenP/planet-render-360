class_name LandmarkAngOuter
extends RefCounted

## The outer Siem Reap temples in true metres: the ruined Angkor Wat-style
## Beng Mealea, the hilltop Phnom Krom and the island of West Mebon.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const K = preload("res://scripts/generation/landmarks/angkor/landmark_ang_outer_kit.gd")

## Beng Mealea (14 m): the largely unrestored early-12th-century sandstone
## temple, an Angkor Wat plan lying in the forest. Three nested galleries
## (181 x 152 m outside, then 116 x 96 m and 64 x 50 m, each on a higher
## terrace) joined by cross cloisters, with cruciform gopuras on all four
## sides, corner towers, four libraries on the east avenue and the
## sanctuary collapsed into a mound of blocks. Roofs and bays have fallen
## in places, fig trees and roots grip the stone. East: the 100 m causeway
## with seven-headed naga balustrades and its cruciform terrace. The
## 1,025 x 875 m moat is terrain. Built facing +X (east).
static func beng_mealea(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7D7966", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#23201C", 2.0))
	lm.use("Root", LandmarkMaterials.pbr("rock", "#4D4438", 3.0))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4E5C34", 4.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1112
	# Terraces of the middle and inner galleries.
	lm.box("Laterite", Vector3(0, 0.75, 0), Vector3(124.0, 1.5, 104.0))
	lm.box("Stone", Vector3(0, 2.25, 0), Vector3(70.0, 1.5, 57.0))
	# The three gallery rings (outer half-sizes, thickness, height) with a
	# 12 m opening in the middle of every side for the gopuras.
	_gallery_ring(lm, rng, 90.5, 76.0, 0.0, 5.5, 5.0)
	_gallery_ring(lm, rng, 58.0, 48.0, 1.5, 5.0, 5.5)
	_gallery_ring(lm, rng, 32.0, 25.0, 3.0, 4.5, 6.0)
	# Gopuras: outer, middle and inner (the inner east one is the tallest
	# standing piece), on the centre lines of the rings.
	# [x of the east/west gates, z of the north/south gates, terrace y,
	# width along the wall, depth, block height, tower height].
	var gops: Array = [[87.75, 73.25, 0.0, 16.0, 9.0, 5.6, 5.0], [55.5, 45.5, 1.5, 14.0, 8.0, 5.8, 5.5],
		[29.75, 22.75, 3.0, 12.0, 7.0, 6.0, 5.0]]
	for g in gops:
		for s in [-1.0, 1.0]:
			var sg: float = s
			K.gopura_tower(lm, "Stone", "Dark", Vector3(sg * float(g[0]), float(g[2]), 0),
				Basis(Vector3.UP, PI * 0.5), float(g[3]), float(g[4]), float(g[5]),
				float(g[6]) - (1.2 if sg < 0.0 else 0.0))
			K.gopura_tower(lm, "Stone", "Dark", Vector3(0, float(g[2]), sg * float(g[1])), Basis(),
				float(g[3]), float(g[4]), float(g[5]), float(g[6]) - (0.8 if sg > 0.0 else 1.6))
	# Corner towers of the rings; some have fallen.
	for ring in [[90.5 - 2.75, 76.0 - 2.75, 5.4, 5.0, 2.0], [58.0 - 2.5, 48.0 - 2.5, 7.4, 4.5, 1.7],
			[32.0 - 2.25, 25.0 - 2.25, 9.4, 4.0, 1.6]]:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var base := Vector3(sx * float(ring[0]), float(ring[2]), sz * float(ring[1]))
				if rng.randf() < 0.7:
					K.light_tower(lm, "Stone", "Dark", base, float(ring[4]), float(ring[3]), 2)
				else:
					K.rubble(lm, "Stone", base, float(ring[4]) * 1.8, 7, rng, 1.2)
	# Cross cloisters: inner to middle gallery (all four ways), middle to
	# outer on the west, north and south.
	for s in [-1.0, 1.0]:
		K.gallery_run(lm, "Stone", "Dark", Vector3(s * 35.0, 1.5, 0), Vector3(s * 53.0, 1.5, 0), 4.5, 4.5, rng, 9.0)
		K.gallery_run(lm, "Stone", "Dark", Vector3(0, 1.5, s * 28.5), Vector3(0, 1.5, s * 43.0), 4.5, 4.5, rng, 9.0)
	K.gallery_run(lm, "Stone", "Dark", Vector3(-62.0, 0, 0), Vector3(-85.0, 0, 0), 4.5, 4.5, rng, 11.5)
	for s in [-1.0, 1.0]:
		K.gallery_run(lm, "Stone", "Dark", Vector3(0, 0, s * 52.0), Vector3(0, 0, s * 70.5), 4.5, 4.5, rng, 9.0)
	# Four libraries flanking the east avenue (door toward the avenue).
	for s in [-1.0, 1.0]:
		var face := Basis(Vector3.UP, PI if s > 0.0 else 0.0)
		K.library(lm, "Stone", "Stone", "Dark", Vector3(73.0, 0, s * 13.0), face, 5.5, 8.5, 3.6)
		K.library(lm, "Stone", "Stone", "Dark", Vector3(46.0, 1.5, s * 12.0), face, 5.0, 7.5, 3.4)
	# East avenue and the causeway with seven-headed nagas, the cruciform
	# terrace with five-headed nagas halfway.
	var east := Basis(Vector3.UP, PI * 0.5)
	lm.box("Laterite", Vector3(74.0, 0.3, 0), Vector3(26.0, 0.6, 8.0))
	lm.box("Stone", Vector3(142.5, 0.45, 0), Vector3(100.0, 0.9, 12.0))
	lm.box("Stone", Vector3(142.5, 0.45, 0), Vector3(9.0, 0.9, 22.0))
	for s in [-1.0, 1.0]:
		U.naga_rail(lm, "Stone", Vector3(93.0, 0.8, s * 5.2), east, 98.0, 0.3, 0.3, 0.6, 7)
		var sb := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
		U.naga_fan(lm, "Stone", Vector3(142.5, 0.9, s * 11.2), sb, 5, 2.4)
	# The collapsed sanctuary: stumps of the cruciform core in a mound of
	# fallen blocks, a fig tree growing from it.
	lm.box("Stone", Vector3(0, 3.0 + 2.2, 0), Vector3(11.0, 4.4, 11.0))
	lm.box("Stone", Vector3(-3.0, 3.0 + 3.6, 2.0), Vector3(5.0, 7.2, 5.0))
	lm.box("Stone", Vector3(3.5, 3.0 + 3.0, -2.5), Vector3(4.0, 6.0, 4.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Stone", b * Vector3(0, 3.0 + 1.6, 7.0), Vector3(5.0, 3.2, 4.0), b)
		K.rubble(lm, "Stone", b * Vector3(7.5, 3.0, 7.5), 6.0, 14, rng, 1.6)
	K.rubble(lm, "Stone", Vector3(0, 3.0, 0), 9.0, 30, rng, 2.4)
	K.tree(lm, "Root", "Moss", Vector3(2.0, 7.4, 0.5), 1.6, 5.0)
	# Fig trees clasping the galleries and the outer court.
	K.tree(lm, "Root", "Moss", Vector3(-60.0, 0, 18.0), 2.4, 11.0)
	K.tree(lm, "Root", "Moss", Vector3(30.0, 1.5, -40.0), 2.0, 9.0)
	K.tree(lm, "Root", "Moss", Vector3(-74.0, 0, -55.0), 2.2, 10.0)
	K.tree(lm, "Root", "Moss", Vector3(66.0, 0, 60.0), 1.9, 8.5)
	K.tree(lm, "Root", "Moss", Vector3(-20.0, 3.0, -17.0), 1.5, 6.5)
	K.rubble(lm, "Stone", Vector3(-45.0, 0, -35.0), 8.0, 16, rng, 1.2)
	K.rubble(lm, "Stone", Vector3(50.0, 0, 38.0), 7.0, 12, rng, 1.0)
	lm.commit(model)

## One gallery ring, outer half-sizes hx, hz, on a terrace at y0: bays cut
## by the 12 m openings at the middle of every side.
static func _gallery_ring(lm: LandmarkMesh, rng: RandomNumberGenerator, hx: float, hz: float,
		y0: float, t: float, h: float) -> void:
	var cx := hx - t * 0.5
	var cz := hz - t * 0.5
	for s in [-1.0, 1.0]:
		var sg: float = s
		# North and south sides along X, east and west sides along Z.
		for e in [-1.0, 1.0]:
			var eg: float = e
			K.gallery_run(lm, "Stone", "Dark", Vector3(eg * 6.0, y0, sg * cz), Vector3(eg * (cx + t * 0.5), y0, sg * cz),
				t, h, rng)
			K.gallery_run(lm, "Stone", "Dark", Vector3(sg * cx, y0, eg * 6.0), Vector3(sg * cx, y0, eg * (cz + t * 0.5)),
				t, h, rng)

## Phnom Krom (11.2 m): Yasovarman I's late-9th-century hilltop temple, three
## sandstone towers in a north-south row on one platform (the central one
## higher; their tops have fallen), facing east up a seven-step stair, in a
## 50 x 50 m laterite wall with a gate on each side, four small buildings
## inside the east gate and three collapsed halls along the north and
## south walls. The 140 m hill is terrain. Built facing +X (east).
static func phnom_krom(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A7D68", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 889
	# Platform (offset a little west of the wall's centre) and its east stair.
	lm.box("Stone", Vector3(-3.0, 0.6, 0), Vector3(12.0, 1.2, 32.0))
	lm.box("Stone", Vector3(-3.0, 1.1, 0), Vector3(12.6, 0.2, 32.6), Basis(), 0.0)
	U.stair(lm, "Stone", Vector3(3.0, 0, 0), Basis(Vector3.UP, PI * 0.5), 4.0, 7, 0.4, 1.2 / 7.0)
	# Three towers; the broken tops are heaps of blocks.
	var heights: Array[float] = [8.0, 10.0, 8.0]
	for k in 3:
		var hw := 2.2 if k != 1 else 2.6
		var base := Vector3(-3.0, 1.2, (float(k) - 1.0) * 11.0)
		U.prasat(lm, "Stone", "Stone", "Dark", base, hw, heights[k], 3, 0.1, 0.8)
		K.rubble(lm, "Stone", base + Vector3(4.2, 0, 0), 2.2, 5, rng, 0.6)
	# Laterite wall with a gate on each side.
	K.ring(lm, "Laterite", "Laterite", 25.0, 25.0, 2.6, 1.1, 1.8, 1.8)
	for s in [-1.0, 1.0]:
		K.gopura_roofed(lm, "Laterite", "Stone", "Dark", Vector3(s * 25.0, 0, 0), Basis(Vector3.UP, PI * 0.5),
			3.6, 5.0, 3.2, 1.4)
		K.gopura_roofed(lm, "Laterite", "Stone", "Dark", Vector3(0, 0, s * 25.0), Basis(), 3.6, 5.0, 3.2, 1.4)
	# Four small buildings in a row just inside the east gate.
	for k in 4:
		var z := (float(k) - 1.5) * 6.0
		lm.box("Laterite", Vector3(15.0, 0.7, z), Vector3(3.4, 1.4, 3.4))
		lm.gable("Laterite", Vector3(15.0, 1.4, z), 3.6, 3.6, 1.0, Basis(), 0.1, "Laterite")
		lm.box("Dark", Vector3(16.73, 0.7, z), Vector3(0.06, 0.9, 1.0), Basis(), 0.0)
	# Three collapsed halls inside the north and south walls.
	var halls := [[-12.0, -19.5], [10.0, -19.5], [-4.0, 19.5]]
	for hl in halls:
		var c := Vector3(float(hl[0]), 0, float(hl[1]))
		lm.box("Laterite", c + Vector3(0, 0.6, 0), Vector3(12.0, 1.2, 3.6))
		lm.box("Laterite", c + Vector3(-3.5, 1.2, 0), Vector3(3.0, 2.4, 3.6))
		K.rubble(lm, "Laterite", c + Vector3(3.0, 1.2, 0), 3.0, 8, rng, 0.8)
	lm.commit(model)

## West Mebon (7.8 m): the 11th-century island temple in the middle of the
## West Baray: a roughly 100 m square laterite wall with three
## lotus-crowned tower-passages on each side, 28 m apart, on a revetted
## island, and in the middle a 24 m stone platform joined to the east wall
## by a laterite and sandstone causeway (where the bronze reclining Vishnu
## was found). The baray water is terrain. Built facing +X (east).
static func west_mebon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A8C72", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	# Island revetment, 1 m high, and its stepped sandstone edge.
	lm.box("Laterite", Vector3(0, 0.5, 0), Vector3(112.0, 1.0, 112.0))
	lm.box("Stone", Vector3(0, 0.9, 0), Vector3(113.0, 0.2, 113.0), Basis(), 0.0)
	# Wall and the twelve tower-passages (three a side).
	K.ring(lm, "Laterite", "Stone", 50.0, 50.0, 3.0, 1.4, 0.0, 0.0, 1.0)
	for s in [-1.0, 1.0]:
		for k in [-1.0, 0.0, 1.0]:
			var off: float = k * 28.0
			var sg: float = s
			K.lotus_gate(lm, "Laterite", "Stone", "Dark", Vector3(sg * 50.0, 1.0, off),
				Basis(Vector3.UP, PI * 0.5), 6.0, 5.0, 4.2, 2.6)
			K.lotus_gate(lm, "Laterite", "Stone", "Dark", Vector3(off, 1.0, sg * 50.0), Basis(), 6.0, 5.0,
				4.2, 2.6)
	# Central platform with its stair, and the causeway to the east gate.
	lm.box("Stone", Vector3(0, 1.0 + 0.8, 0), Vector3(24.0, 1.6, 24.0))
	lm.box("Stone", Vector3(0, 1.0 + 1.6, 0), Vector3(24.8, 0.3, 24.8), Basis(), 0.0)
	lm.box("Laterite", Vector3(0, 1.0 + 1.9, 0), Vector3(21.0, 0.3, 21.0))
	U.stair(lm, "Stone", Vector3(12.0, 1.0, 0), Basis(Vector3.UP, PI * 0.5), 5.0, 4, 0.45, 0.45)
	lm.box("Laterite", Vector3(31.0, 1.0 + 0.4, 0), Vector3(36.0, 0.8, 4.4))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(31.0, 1.0 + 0.85, s * 2.3), Vector3(36.0, 0.3, 0.5), Basis(), 0.0)
	lm.commit(model)
