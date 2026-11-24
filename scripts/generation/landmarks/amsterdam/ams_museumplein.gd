class_name AmsMuseumplein
extends RefCounted

## Museumplein & South Canal Ring landmarks (`AMS-3.1` & `AMS-3.2`):
##   - Rijksmuseum (60.0 m — twin towers, open vaulted bicycle passage, forecourt)
##   - Van Gogh Museum (20.0 m — Rietveld block + Kurokawa ellipse + glass hall)
##   - Stedelijk Museum (22.0 m — 1895 brick + cantilevered white "Bathtub")
##   - Het Concertgebouw (26.0 m — neoclassical pediment + gilded Apollo lyre)
##   - Pathé Tuschinski (36.0 m — Art Deco green/gold twin-turret front)
##   - De Bazel (37.5 m — horizontal banded granite & dark-brick fortress)
##   - Stadsschouwburg & American Hotel (28.0 m — Leidseplein neo-Renaissance)
##   - Heineken Experience (26.0 m — 1867 brewery + copper brewhouse)
##   - Vondelkerk (50.0 m — Cuypers polychrome neo-Gothic octagonal church)

const K = preload("res://scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd")

## Pierre Cuypers' Rijksmuseum (1885, 60 m): 146 m twin-courtyard neo-Gothic /
## Dutch Renaissance red-brick & sandstone palace with the iconic open central
## vaulted bicycle passage, twin 60 m peaked slate-roofed towers, four corner
## pavilions, ceramic frieze bands, and Museumplein reflection pool.
static func rijksmuseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8A3A2B", "#E0D4BC", "#384048")
	lm.use("Pool", LandmarkMaterials.pool_water("#1E4652"))
	# West & East courtyard wings split by the open 12 m central bicycle passage
	for sx in [-1.0, 1.0]:
		# Front (+Z) & rear (-Z) long gallery ranges
		lm.box("Brick", Vector3(sx * 38.0, 11.0, 32.0), Vector3(64.0, 22.0, 16.0))
		lm.box("Brick", Vector3(sx * 38.0, 11.0, -32.0), Vector3(64.0, 22.0, 16.0))
		# Outer end wing closing each courtyard
		lm.box("Brick", Vector3(sx * 64.0, 11.0, 0.0), Vector3(14.0, 22.0, 50.0))
		# Inner courtyard glass atrium roofs
		K.pitched_roof(lm, "Glass", Vector3(sx * 36.0, 21.5, 0.0), 42.0, 48.0, 4.5, true)
		K.pitched_roof(lm, "Roof", Vector3(sx * 38.0, 22.0, 32.0), 64.4, 16.4, 7.2, true)
		K.pitched_roof(lm, "Roof", Vector3(sx * 38.0, 22.0, -32.0), 64.4, 16.4, 7.2, true)
		K.pitched_roof(lm, "Roof", Vector3(sx * 64.0, 22.0, 0.0), 14.4, 50.4, 6.8, false)
		# Corner pavilions with pyramidal slate roofs
		for sz in [-1.0, 1.0]:
			var cp := Vector3(sx * 68.0, 0.0, sz * 35.0)
			lm.box("Brick", cp + Vector3.UP * 12.5, Vector3(14.0, 25.0, 14.0))
			K.stone_band(lm, "Stone", cp.x, cp.z, 14.4, 14.4, 24.6, 0.7, 0.3)
			lm.frustum("Roof", cp + Vector3.UP * 25.0, 9.6, 0.25, 11.5, 4)
			for y0 in [4.5, 10.5, 16.5]:
				K.window_row(lm, "Glass", Vector3(sx * 12.0, 0.0, sz * 40.08), Vector3(sx * 60.0, 0.0, sz * 40.08),
					Vector3(0.0, 0.0, sz), y0, 10, 2.2, 3.6)
	# Central bridge block spanning OVER the open vaulted passage (y=11..25 m)
	lm.box("Brick", Vector3(0.0, 18.0, 0.0), Vector3(16.0, 14.0, 80.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 25.0, 0.0), 16.4, 80.4, 8.5, false)
	for sz in [-1.0, 1.0]:
		K.step_gable(lm, "Brick", "Stone", Vector3(0.0, 25.0, sz * 40.2), Vector3(0.0, 0.0, sz), 16.0, 9.0, 5, 1.0)
		lm.box("Lamp", Vector3(0.0, 10.6, sz * 38.0), Vector3(10.0, 0.45, 2.5))
	# Twin iconic 60 m central towers flanking the passage
	for sx in [-1.0, 1.0]:
		var t := Vector3(sx * 11.5, 0.0, 34.0)
		lm.box("Brick", t + Vector3.UP * 19.0, Vector3(9.4, 38.0, 9.4))
		for y in [10.0, 22.0, 37.6]:
			K.stone_band(lm, "Stone", t.x, t.z, 9.8, 9.8, y, 0.75, 0.35)
		lm.frustum("Roof", t + Vector3.UP * 38.0, 6.2, 0.14, 22.0, 4)
		# Matching slightly lower rear towers
		var rt := Vector3(sx * 11.5, 0.0, -34.0)
		lm.box("Brick", rt + Vector3.UP * 17.5, Vector3(8.8, 35.0, 8.8))
		lm.frustum("Roof", rt + Vector3.UP * 35.0, 5.8, 0.14, 17.0, 4)
	# Sandstone horizontal stringcourses & Museumplein reflecting pond (-Z side)
	K.stone_band(lm, "Stone", 0.0, 32.0, 144.0, 16.6, 10.5, 0.6, 0.25)
	K.stone_band(lm, "Stone", 0.0, -32.0, 144.0, 16.6, 10.5, 0.6, 0.25)
	lm.box("Pool", Vector3(0.0, 0.12, -56.0), Vector3(46.0, 0.24, 18.0))
	lm.commit(model)

## Van Gogh Museum (Rietveld 1973 geometric white/grey block + Kurokawa 1999
## elliptical titanium & stone wing + curved glass entrance hall, 20 m).
static func van_gogh_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#E5E2DA", "#5C636B")
	lm.use("Titanium", LandmarkMaterials.pbr("sheet_metal", "#7C8288", 2.0, 0.35, 0.75))
	lm.use("Pool", LandmarkMaterials.pool_water("#224954"))
	# Rietveld modernist stacked white/pale-grey cubic volumes
	lm.box("White", Vector3(-16.0, 9.0, 0.0), Vector3(38.0, 18.0, 36.0))
	lm.box("White", Vector3(-16.0, 19.0, -4.0), Vector3(24.0, 2.0, 22.0))
	K.window_row(lm, "Glass", Vector3(-32.0, 0.0, 18.08), Vector3(0.0, 0.0, 18.08), Vector3.BACK, 2.0, 7, 3.6, 13.0)
	# Kurokawa elliptical exhibition wing in dark stone & titanium
	lm.frustum("Titanium", Vector3(20.0, 0.0, -2.0), 16.0, 16.0, 14.5, 24)
	lm.frustum("Roof", Vector3(20.0, 14.5, -2.0), 16.2, 14.8, 1.5, 24)
	# Curved structural glass entrance foyer & sunken pond
	lm.box("Glass", Vector3(4.0, 4.5, 16.0), Vector3(22.0, 9.0, 12.0))
	lm.box("Pool", Vector3(16.0, 0.12, 14.0), Vector3(16.0, 0.24, 10.0))
	lm.box("Lamp", Vector3(4.0, 8.6, 22.05), Vector3(20.0, 0.3, 0.2))
	lm.commit(model)

## Stedelijk Museum (Weissman 1895 brick-and-sandstone Dutch Renaissance hall
## fused with Benthem Crouwel's cantilevered pure-white "Bathtub" wing, 22 m).
static func stedelijk_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8B3E2E", "#DFD3BC", "#3C444C")
	lm.use("Bathtub", LandmarkMaterials.pbr("render", "#F4F3EF", 1.8, 0.22, 0.08))
	# Historic 1895 brick & sandstone museum block (-Z)
	lm.box("Brick", Vector3(0.0, 8.5, -14.0), Vector3(74.0, 17.0, 28.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 17.0, -14.0), 74.4, 28.4, 5.0, true)
	K.step_gable(lm, "Brick", "Stone", Vector3(0.0, 17.0, -28.1), Vector3.FORWARD, 14.0, 5.2, 4, 0.8)
	K.stone_band(lm, "Stone", 0.0, -14.0, 74.4, 28.4, 9.0, 0.55, 0.25)
	# Iconic cantilevered pure-white "Bathtub" (De Badkuip) facing Museumplein (+Z)
	lm.box("Glass", Vector3(0.0, 3.0, 12.0), Vector3(68.0, 6.0, 18.0))
	lm.box("Bathtub", Vector3(0.0, 11.2, 16.5), Vector3(84.0, 10.6, 26.0))
	# Tapered underside lip of the cantilever
	lm.box("Bathtub", Vector3(0.0, 6.0, 22.0), Vector3(78.0, 1.4, 12.0))
	lm.box("Lamp", Vector3(0.0, 5.5, 21.1), Vector3(64.0, 0.35, 0.35))
	lm.commit(model)

## Het Concertgebouw (van Gendt, 1888, 26 m): cream sandstone & red-brick
## neoclassical concert hall with Corinthian pediment & gilded Apollo lyre.
static func concertgebouw(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8C4130", "#E3D9C4", "#3E454D")
	lm.box("Brick", Vector3(0.0, 9.5, 0.0), Vector3(62.0, 19.0, 58.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 19.0, 0.0), 62.4, 58.4, 5.5, false)
	# Grand sandstone front portico facing Museumplein (+Z)
	lm.box("Stone", Vector3(0.0, 10.0, 29.5), Vector3(44.0, 20.0, 3.0))
	for i in 8:
		var px := -17.5 + 5.0 * float(i)
		lm.frustum("Stone", Vector3(px, 2.0, 31.2), 0.55, 0.48, 16.5, 10)
	K.pediment(lm, "Stone", "White", Vector3(0.0, 20.0, 30.2), Vector3.BACK, 36.0, 5.0, 1.8)
	# Gilded Apollo lyre finial on pediment apex (26 m)
	lm.frustum("Gold", Vector3(0.0, 24.8, 30.6), 0.9, 0.45, 1.2, 8)
	# Modern glazed side foyer wing (-X)
	lm.box("Glass", Vector3(-34.0, 5.5, 4.0), Vector3(6.5, 11.0, 44.0))
	lm.box("Lamp", Vector3(0.0, 19.2, 31.4), Vector3(34.0, 0.35, 0.3))
	lm.commit(model)

## Pathé Tuschinski (1921 Art Deco / Amsterdam School cinema, 36 m):
static func pathe_tuschinski(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8C4C38", "#D6DEC8", "#3B4A45")
	lm.use("Ceram", LandmarkMaterials.pbr("render", "#BFD2BE", 2.0, 0.35, 0.1))
	lm.box("Brick", Vector3(0.0, 12.0, -4.0), Vector3(30.0, 24.0, 46.0))
	lm.box("Ceram", Vector3(0.0, 13.0, 19.2), Vector3(30.6, 26.0, 2.0))
	lm.box("Lamp", Vector3(0.0, 4.2, 21.0), Vector3(18.0, 1.2, 2.8))
	for sx in [-1.0, 1.0]:
		var tp := Vector3(sx * 13.5, 0.0, 19.2)
		lm.box("Ceram", tp + Vector3.UP * 14.5, Vector3(4.8, 29.0, 4.8))
		lm.lathe("Gold", tp + Vector3.UP * 29.0, PackedVector2Array([
			Vector2(2.4, 0.0), Vector2(2.6, 2.8), Vector2(1.2, 5.4), Vector2(0.08, 7.0),
		]), 10)
	lm.commit(model)

## De Bazel (1926, 37.5 m): monumental horizontal granite & dark-brick block.
static func de_bazel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#6B382C", "#9E9588", "#3A4046")
	lm.box("Brick", Vector3(0.0, 14.5, 0.0), Vector3(32.0, 29.0, 98.0))
	lm.box("Brick", Vector3(0.0, 33.25, 0.0), Vector3(26.0, 8.5, 88.0))
	for y in range(4, 30, 4):
		K.stone_band(lm, "Stone", 0.0, 0.0, 32.4, 98.4, float(y), 0.65, 0.25)
	for sx in [-1.0, 1.0]:
		for y0 in [5.0, 13.0, 21.0]:
			K.window_row(lm, "Glass", Vector3(sx * 16.08, 0.0, -44.0), Vector3(sx * 16.08, 0.0, 44.0),
				Vector3(sx, 0.0, 0.0), y0, 20, 2.0, 2.6)
	lm.commit(model)

## Stadsschouwburg & American Hotel on Leidseplein (28 m):
static func stadsschouwburg_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8D3D2E", "#DFD2B8", "#3A4148")
	lm.box("Brick", Vector3(0.0, 10.5, 0.0), Vector3(48.0, 21.0, 74.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 21.0, 0.0), 48.4, 74.4, 7.0, false)
	lm.box("Stone", Vector3(0.0, 4.5, 37.8), Vector3(36.0, 9.0, 3.0))
	K.stone_band(lm, "Stone", 0.0, 0.0, 48.4, 74.4, 10.0, 0.65, 0.28)
	K.window_row(lm, "Lamp", Vector3(-16.0, 0.0, 39.35), Vector3(16.0, 0.0, 39.35), Vector3.BACK, 1.0, 7, 2.8, 6.2)
	lm.commit(model)

## Heineken Experience (1867 brewery, 26 m):
static func heineken_experience(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8B3B2B", "#DED2BA", "#3B4249")
	lm.box("Brick", Vector3(0.0, 9.5, 0.0), Vector3(72.0, 19.0, 48.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 19.0, 0.0), 72.4, 48.4, 5.2, true)
	K.step_gable(lm, "Brick", "Stone", Vector3(0.0, 19.0, 24.1), Vector3.BACK, 14.0, 6.8, 4, 0.9)
	lm.box("Copper", Vector3(16.0, 21.5, 0.0), Vector3(18.0, 5.0, 18.0))
	K.stone_band(lm, "Stone", 0.0, 0.0, 72.4, 48.4, 9.6, 0.55, 0.24)
	lm.commit(model)

## Vondelkerk (Pierre Cuypers, 1880, 50 m): octagonal polychrome neo-Gothic church.
static func vondelkerk(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#87382A", "#D8CCB4", "#363D45")
	lm.frustum("Brick", Vector3.ZERO, 16.0, 15.6, 18.0, 8)
	lm.frustum("Roof", Vector3(0.0, 18.0, 0.0), 16.2, 6.5, 9.0, 8)
	lm.frustum("Brick", Vector3(0.0, 27.0, 0.0), 5.6, 5.2, 7.5, 8)
	lm.frustum("Lamp", Vector3(0.0, 28.0, 0.0), 5.3, 5.0, 4.0, 8)
	lm.frustum("Roof", Vector3(0.0, 34.5, 0.0), 5.4, 0.1, 15.5, 8)
	lm.commit(model)
