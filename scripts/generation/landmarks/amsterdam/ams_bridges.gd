class_name AmsBridges
extends RefCounted

## Bespoke monumental Amsterdam bridges (`AMS-4.1`), built along +X (`span_m`
## long, `base: water`, `deck_ends: true`):
##   - Magere Brug (68 m white double-leaf wooden Dutch bascule + 1,200 night bulbs)
##   - Blauwbrug (62 m Paris-inspired 3-arch stone/iron bridge + Imperial Crowns)
##   - Torensluis (42 m historic Singel 3-arch brick bridge + Multatuli terrace)
##   - Python Bridge / Hoge Brug (92 m vermilion-red undulating steel truss)

const K = preload("res://scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd")

## Magere Brug (1934 reconstruction over the Amstel, 68 m): Amsterdam's iconic
## white-painted double-leaf wooden Dutch bascule drawbridge (ophaalbrug) with
## twin overhead balance frames, timber-pile approach trestles, and warm golden
## fairy-light bulb chains illuminating the portal frames & arches at night.
static func magere_brug(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#F2EFE8", "#383D42")
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#4F463D", 2.4))
	lm.use("Pile", LandmarkMaterials.pbr("wood", "#2D2722", 2.0))
	lm.use("Fairy", LandmarkMaterials.lit("#FFD278", 3.4))
	var deck_y := 3.0
	var hw := 2.25
	# Continuous timber bridge deck (68 m long, 4.5 m wide)
	lm.box("Deck", Vector3(0.0, deck_y, 0.0), Vector3(68.0, 0.45, hw * 2.0))
	# White-painted wooden side railings + fairy-light bulb line along both rails
	for sz in [-1.0, 1.0]:
		lm.box("White", Vector3(0.0, deck_y + 0.95, sz * (hw - 0.12)), Vector3(68.0, 0.14, 0.14))
		lm.box("White", Vector3(0.0, deck_y + 0.50, sz * (hw - 0.12)), Vector3(68.0, 0.10, 0.10))
		for ix in range(-32, 33, 4):
			lm.box("White", Vector3(float(ix), deck_y + 0.55, sz * (hw - 0.12)), Vector3(0.14, 1.0, 0.14))
			# Warm fairy-light bulbs every 4 m along the railing
			lm.box("Fairy", Vector3(float(ix), deck_y + 1.12, sz * (hw - 0.12)), Vector3(0.18, 0.18, 0.18))
	# Multi-bay timber pile trestles supporting the approach spans
	for px in [-28.0, -21.0, -14.0, -7.5, 7.5, 14.0, 21.0, 28.0]:
		for sz in [-1.0, 0.0, 1.0]:
			lm.frustum("Pile", Vector3(px, -1.5, sz * (hw - 0.35)), 0.24, 0.22, deck_y + 1.4, 8)
		lm.box("White", Vector3(px, deck_y - 0.35, 0.0), Vector3(0.45, 0.4, hw * 2.1))
	# Twin iconic white Dutch bascule portal frames & overhead balance beams (10.5 m)
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 6.8
		var xb := sx * 12.5
		for sz: float in [-1.0, 1.0]:
			# Main vertical portal posts
			lm.box("White", Vector3(x0, deck_y + 3.6, sz * (hw - 0.15)), Vector3(0.42, 7.2, 0.42))
			# Overhead balance beam (balans) angled slightly back to counterweight
			lm.beam("White", Vector3(sx * 1.4, deck_y + 7.2, sz * (hw - 0.15)),
				Vector3(xb, deck_y + 6.4, sz * (hw - 0.15)), 0.36, 0.36)
			# Tension hanger rod down to bascule leaf tip
			lm.beam("White", Vector3(sx * 1.5, deck_y + 7.1, sz * (hw - 0.15)),
				Vector3(sx * 1.0, deck_y + 0.2, sz * (hw - 0.15)), 0.10, 0.10)
			# Diagonal rear strut to approach pier
			lm.beam("White", Vector3(x0, deck_y + 5.6, sz * (hw - 0.15)),
				Vector3(xb, deck_y + 0.2, sz * (hw - 0.15)), 0.26, 0.26)
			# Fairy lights tracing the portal posts & balance beams!
			lm.box("Fairy", Vector3(x0, deck_y + 6.9, sz * (hw - 0.15)), Vector3(0.28, 0.28, 0.28))
			lm.box("Fairy", Vector3(sx * 3.8, deck_y + 7.1, sz * (hw - 0.15)), Vector3(0.24, 0.24, 0.24))
		# Cross-portal transom & counterweight box
		lm.box("White", Vector3(x0, deck_y + 6.9, 0.0), Vector3(0.42, 0.45, hw * 2.0))
		lm.box("White", Vector3(xb, deck_y + 6.2, 0.0), Vector3(0.7, 0.9, hw * 2.0))
		lm.box("Fairy", Vector3(x0, deck_y + 7.25, 0.0), Vector3(0.25, 0.25, hw * 1.8))
	lm.commit(model)

## Blauwbrug (1883, 62 m over the Amstel): Paris-inspired 3-arch stone & cast-iron
## bridge with sculpted ship-prow cutwaters and royal-blue & gold Imperial Crown
## lantern columns rising to 12 m.
static func blauwbrug(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#CFC6B4", "#363D44")
	lm.use("Blue", LandmarkMaterials.paint("#1F4C8C", 0.35, 0.2))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#585552", 3.0))
	var deck_y := 3.8
	var hw := 10.0
	lm.box("Deck", Vector3(0.0, deck_y, 0.0), Vector3(62.0, 0.6, hw * 2.0))
	# Three stone & iron arch spandrels + two ornate ship-prow river piers
	for px in [-14.0, 14.0]:
		lm.box("Stone", Vector3(px, deck_y * 0.5 - 0.5, 0.0), Vector3(4.2, deck_y + 1.5, hw * 2.15))
		for sz in [-1.0, 1.0]:
			# Ship-prow stone cutwater & royal-blue Imperial Crown lantern column (12 m)
			lm.frustum("Stone", Vector3(px, -1.0, sz * (hw + 1.4)), 2.2, 1.6, deck_y + 1.8, 6)
			lm.frustum("Blue", Vector3(px, deck_y + 0.5, sz * (hw + 0.6)), 0.72, 0.52, 5.2, 10)
			K.imperial_crown(lm, "Gold", "Blue", Vector3(px, deck_y + 5.7, sz * (hw + 0.6)), 0.95, 1.8)
			lm.frustum("Lamp", Vector3(px, deck_y + 4.4, sz * (hw + 1.15)), 0.38, 0.38, 0.75, 8)
	# Ornate cast-iron parapets & arch rib facings
	for sz in [-1.0, 1.0]:
		lm.box("Dark", Vector3(0.0, deck_y + 0.8, sz * (hw - 0.18)), Vector3(62.0, 1.1, 0.32))
		lm.box("Stone", Vector3(0.0, deck_y - 0.4, sz * (hw - 0.1)), Vector3(62.0, 0.7, 0.5))
		lm.box("Lamp", Vector3(0.0, deck_y - 0.85, sz * (hw - 0.2)), Vector3(54.0, 0.18, 0.18))
	lm.commit(model)

## Torensluis (1648, 56 m from capital centre over Singel, 42 m span x 26 m wide):
## Amsterdam's widest historic brick arched bridge with three vaulted arches,
## barred dungeon pier grates, sandstone coping, and Multatuli bust terrace.
static func torensluis(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#D6CAB2", "#353B42")
	lm.use("Klinker", LandmarkMaterials.pbr("brick", "#7E4B3E", 2.5))
	var deck_y := 2.6
	var hw := 13.0
	lm.box("Klinker", Vector3(0.0, deck_y, 0.0), Vector3(42.0, 0.55, hw * 2.0))
	for px in [-14.0, -5.0, 5.0, 14.0]:
		lm.box("Brick", Vector3(px, deck_y * 0.5 - 0.5, 0.0), Vector3(3.4, deck_y + 1.2, hw * 2.02))
	for sz in [-1.0, 1.0]:
		lm.box("Brick", Vector3(0.0, deck_y - 0.35, sz * (hw - 0.2)), Vector3(42.0, 0.9, 0.55))
		lm.box("Stone", Vector3(0.0, deck_y + 0.18, sz * (hw - 0.2)), Vector3(42.4, 0.28, 0.7))
		lm.box("Dark", Vector3(0.0, deck_y + 0.9, sz * (hw - 0.18)), Vector3(42.0, 1.0, 0.16))
		# Corner historic globe lamp posts (6.5 m)
		for sx in [-19.0, 0.0, 19.0]:
			lm.frustum("Dark", Vector3(sx, deck_y + 0.2, sz * (hw - 0.35)), 0.14, 0.08, 3.2, 6)
			lm.frustum("Lamp", Vector3(sx, deck_y + 3.4, sz * (hw - 0.35)), 0.28, 0.22, 0.5, 8)
	# Multatuli statue pedestal on the broad south-east bridge square
	lm.box("Stone", Vector3(2.0, deck_y + 1.1, 6.0), Vector3(1.6, 1.6, 1.6))
	lm.frustum("Dark", Vector3(2.0, deck_y + 1.9, 6.0), 0.55, 0.42, 1.2, 8)
	lm.commit(model)

## Python Bridge / Hoge Brug (West 8, 2001, 92 m over Spoorwegbassin): bright
## vermilion-red sinusoidal undulating steel truss pedestrian bridge (13.5 m).
static func python_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#D4CEBE", "#3B4249")
	lm.use("RedSteel", LandmarkMaterials.pbr("sheet_metal", "#C62D24", 2.0, 0.38, 0.65))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#6E5A46", 2.2))
	var segs := 18
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var x0 := -46.0 + t0 * 92.0
		var x1 := -46.0 + t1 * 92.0
		var y0 := 2.4 + sin(t0 * PI) * 7.2 + sin(t0 * PI * 3.0) * 0.9
		var y1 := 2.4 + sin(t1 * PI) * 7.2 + sin(t1 * PI * 3.0) * 0.9
		var z0 := sin(t0 * PI * 2.0) * 2.6
		var z1 := sin(t1 * PI * 2.0) * 2.6
		lm.beam("Deck", Vector3(x0, y0, z0), Vector3(x1, y1, z1), 3.6, 0.35)
		for sz in [-1.8, 1.8]:
			lm.beam("RedSteel", Vector3(x0, y0 + 2.4, z0 + sz), Vector3(x1, y1 + 2.4, z1 + sz), 0.28, 0.28)
			lm.beam("RedSteel", Vector3(x0, y0, z0 + sz), Vector3(x0, y0 + 2.4, z0 + sz), 0.22, 0.22)
		if i % 3 == 0:
			lm.beam("RedSteel", Vector3(x0, y0 + 2.4, z0 - 1.8), Vector3(x0, y0 + 2.4, z0 + 1.8), 0.24, 0.24)
	# Twin red steel arch ribs beneath
	for sz in [-2.0, 2.0]:
		lm.beam("RedSteel", Vector3(-44.0, 0.0, sz), Vector3(0.0, 12.8, sz), 0.55, 0.55)
		lm.beam("RedSteel", Vector3(0.0, 12.8, sz), Vector3(44.0, 0.0, sz), 0.55, 0.55)
	lm.commit(model)
