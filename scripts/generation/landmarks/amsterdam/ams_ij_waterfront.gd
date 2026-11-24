class_name AmsIjWaterfront
extends RefCounted

## IJ Waterfront, Oosterdok, Overhoeks, Harbour & Stadium landmarks (`AMS-3.4` & `AMS-3.5`):
##   - NEMO Science Museum (32.0 m — Renzo Piano oxidised green-copper ship prow)
##   - Het Scheepvaartmuseum & moored VOC Ship *Amsterdam* (30.0 m)
##   - EYE Filmmuseum (22.0 m — cantilevered faceted white origami shell)
##   - A'DAM Toren (100.0 m — rotated Overhoeks tower + rooftop swing crown)
##   - Muziekgebouw aan 't IJ & cantilevered black Bimhuis (24.0 m)
##   - OBA Oosterdok (42.0 m)
##   - Museum Het Schip (28.0 m — Michel de Klerk Amsterdam School spire)
##   - Pontsteiger (90.0 m — golden-bronze IJ archway gatehouse)
##   - Silodam (34.0 m — colourful MVRDV container mosaic pier)
##   - Gashouder (24.0 m — circular brick & iron-truss drum)
##   - Olympisch Stadion (46.0 m — 1928 brick bowl + Marathon Tower)
##   - Johan Cruijff ArenA (75.0 m — dual curved steel roof arch trusses)

const K = preload("res://scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd")

## NEMO Science Museum (Renzo Piano, 1997, 32 m): unmistakable oxidised
## green-copper ship prow rising out of Oosterdok with stepped rooftop piazza.
static func nemo_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#D4CEBE", "#4A8070")
	lm.use("NemoCopper", LandmarkMaterials.pbr("copper", "#4E8A78", 2.2, 0.48, 0.25))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#B5AFA4", 3.0))
	# Stepped rising green-copper ship hull from low rear (-Z) up to 32 m prow (+Z)
	var steps := 14
	for i in steps:
		var t := float(i) / float(steps - 1)
		var z := -42.0 + t * 84.0
		var h := 7.0 + t * 25.0
		var w := 38.0 * (1.0 - 0.58 * pow(t, 1.5))
		lm.box("NemoCopper", Vector3(0.0, h * 0.5, z), Vector3(w, h, 6.6))
		# Stepped public rooftop piazza descending toward the south
		lm.box("Deck", Vector3(0.0, h + 0.15, z), Vector3(w * 0.86, 0.3, 6.2))
	# Rooftop glass café pavilion & glowing porthole strip
	lm.box("Glass", Vector3(0.0, 29.0, 28.0), Vector3(14.0, 4.5, 12.0))
	lm.box("Lamp", Vector3(0.0, 31.2, 41.5), Vector3(10.0, 0.45, 0.45))
	lm.commit(model)

## Het Scheepvaartmuseum (1656 's Lands Zeemagazijn, 30 m) + moored 1749 VOC
## three-masted East Indiaman replica *Amsterdam* alongside the quay.
static func scheepvaartmuseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#843A2C", "#DED3BC", "#384048")
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#4A3222", 2.0))
	lm.use("Sail", LandmarkMaterials.pbr("render", "#E4DEC8", 2.0))
	# Monumental 62 x 62 m square classical waterfront arsenal around courtyard
	lm.box("Brick", Vector3(0.0, 9.5, 24.0), Vector3(62.0, 19.0, 14.0))
	lm.box("Brick", Vector3(0.0, 9.5, -24.0), Vector3(62.0, 19.0, 14.0))
	lm.box("Brick", Vector3(-24.0, 9.5, 0.0), Vector3(14.0, 19.0, 36.0))
	lm.box("Brick", Vector3(24.0, 9.5, 0.0), Vector3(14.0, 19.0, 36.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 19.0, 24.0), 62.4, 14.4, 6.0, true)
	K.pitched_roof(lm, "Roof", Vector3(0.0, 19.0, -24.0), 62.4, 14.4, 6.0, true)
	K.pitched_roof(lm, "Roof", Vector3(-24.0, 19.0, 0.0), 14.4, 36.4, 6.0, false)
	K.pitched_roof(lm, "Roof", Vector3(24.0, 19.0, 0.0), 14.4, 36.4, 6.0, false)
	K.pediment(lm, "Stone", "Brick", Vector3(0.0, 19.0, 31.1), Vector3.BACK, 16.0, 4.8, 1.2)
	# Modern diamond-grid geodesic glass courtyard roof
	lm.lathe("Glass", Vector3(0.0, 19.0, 0.0), PackedVector2Array([
		Vector2(18.0, 0.0), Vector2(14.0, 2.2), Vector2(6.0, 3.6), Vector2(0.0, 4.0),
	]), 12)
	# Moored full-scale VOC East Indiaman *Amsterdam* along the west quay (-X)
	var sx := -42.0
	lm.box("Timber", Vector3(sx, 2.4, 0.0), Vector3(9.5, 4.8, 38.0))
	lm.box("Timber", Vector3(sx, 5.8, -14.0), Vector3(8.5, 3.2, 11.0))
	lm.box("Gold", Vector3(sx, 6.2, -19.6), Vector3(7.4, 2.2, 0.5))
	for mz in [-10.0, 1.0, 12.0]:
		var mh := 30.0 if absf(mz) < 3.0 else 25.0
		lm.frustum("Timber", Vector3(sx, 4.5, mz), 0.38, 0.16, mh - 4.5, 8)
		for yy in [11.0, 17.5, 22.5]:
			if yy < mh - 2.0:
				lm.beam("Timber", Vector3(sx - 6.5, yy, mz), Vector3(sx + 6.5, yy, mz), 0.22, 0.22)
				lm.box("Sail", Vector3(sx, yy - 0.5, mz + 0.25), Vector3(11.0, 0.85, 0.45))
	lm.commit(model)

## EYE Filmmuseum (Delugan Meissl, 2012, 22 m): stark cantilevered faceted
## white aluminium origami volume hovering above the north bank of the IJ.
static func eye_filmmuseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#F0EFEA", "#384048")
	lm.use("Alu", LandmarkMaterials.pbr("render", "#F2F2EE", 1.6, 0.24, 0.18))
	# Cantilevered faceted white origami main volume
	lm.box("Alu", Vector3(0.0, 11.5, 0.0), Vector3(76.0, 12.0, 32.0))
	lm.box("Alu", Vector3(18.0, 14.5, 6.0), Vector3(52.0, 9.0, 22.0), Basis(Vector3.UP, 0.16))
	lm.box("Alu", Vector3(-16.0, 16.2, -4.0), Vector3(42.0, 10.5, 20.0), Basis(Vector3.UP, -0.14))
	# Stepped waterfront panoramic glass foyer facing the IJ (+Z)
	lm.box("Glass", Vector3(4.0, 4.5, 13.0), Vector3(48.0, 7.5, 12.0))
	lm.box("Lamp", Vector3(4.0, 8.4, 19.1), Vector3(44.0, 0.35, 0.3))
	lm.commit(model)

## A'DAM Toren (1971 / 2016, 100 m): former Shell tower rotated 45° to the IJ,
## vertical precast white ribs, cantilevered crown & Over The Edge swing.
static func adam_toren(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#E6E3DC", "#2F353C")
	lm.use("RedLamp", LandmarkMaterials.lit("#E82E2E", 3.2))
	lm.box("White", Vector3(0.0, 5.0, 0.0), Vector3(38.0, 10.0, 38.0))
	# Main 22-storey ribbed vertical tower shaft (10..86 m)
	lm.box("Glass", Vector3(0.0, 48.0, 0.0), Vector3(26.0, 76.0, 26.0))
	for i in 7:
		var o := -12.0 + 4.0 * float(i)
		for s in [-1.0, 1.0]:
			lm.box("White", Vector3(o, 48.0, s * 13.2), Vector3(0.85, 76.0, 0.85))
			lm.box("White", Vector3(s * 13.2, 48.0, o), Vector3(0.85, 76.0, 0.85))
	# Iconic cantilevered crown & A'DAM Lookout deck (86..100 m)
	lm.box("Dark", Vector3(0.0, 90.0, 0.0), Vector3(31.0, 8.0, 31.0))
	lm.box("Lamp", Vector3(0.0, 94.2, 0.0), Vector3(31.4, 0.55, 31.4))
	# Over The Edge rooftop swing gantry & aviation beacon
	lm.beam("RedLamp", Vector3(0.0, 94.0, 14.0), Vector3(0.0, 99.5, 18.0), 0.55, 0.55)
	lm.frustum("RedLamp", Vector3(0.0, 94.5, 0.0), 0.7, 0.12, 5.5, 8)
	lm.commit(model)

## Muziekgebouw aan 't IJ & cantilevered black-box Bimhuis (24 m):
static func muziekgebouw_bimhuis(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#DDD8CE", "#262A2F")
	lm.box("Glass", Vector3(-10.0, 10.0, 0.0), Vector3(78.0, 20.0, 42.0))
	lm.box("Roof", Vector3(-10.0, 21.5, 0.0), Vector3(88.0, 3.0, 48.0))
	# Iconic cantilevered corrugated-black Bimhuis jazz box (+X)
	lm.box("Dark", Vector3(40.0, 14.5, 4.0), Vector3(28.0, 15.0, 26.0))
	lm.box("Glass", Vector3(54.1, 14.5, 4.0), Vector3(0.3, 12.0, 22.0))
	lm.box("Lamp", Vector3(40.0, 6.8, 4.0), Vector3(26.0, 0.35, 24.0))
	lm.commit(model)

## OBA Oosterdok (Jo Coenen, 2007, 42 m): pale sandstone & glass central library.
static func oba_oosterdok(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#E2D9C6", "#3E454C")
	lm.box("Stone", Vector3(0.0, 18.0, 0.0), Vector3(56.0, 36.0, 64.0))
	lm.box("Glass", Vector3(0.0, 20.0, 32.1), Vector3(44.0, 28.0, 0.4))
	lm.box("Roof", Vector3(0.0, 39.0, -4.0), Vector3(50.0, 6.0, 52.0))
	lm.commit(model)

## Museum Het Schip (Michel de Klerk, 1919, 28 m): Amsterdam School brick prow.
static func het_schip(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8A432F", "#E0D6C0", "#7D3E2B")
	lm.box("Brick", Vector3(0.0, 7.5, 0.0), Vector3(74.0, 15.0, 36.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 15.0, 0.0), 74.4, 36.4, 5.2, true)
	# Sharp Amsterdam-School sculptural spire at the prow
	lm.frustum("Brick", Vector3(30.0, 14.0, 0.0), 3.4, 2.2, 6.5, 6)
	lm.frustum("Roof", Vector3(30.0, 20.5, 0.0), 2.4, 0.08, 7.5, 6)
	lm.commit(model)

## Pontsteiger (2018, 90 m): dramatic golden-bronze twin-legged archway tower on the IJ.
static func pontsteiger(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#C9A56B", "#3B4046")
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#B9945B", 2.0, 0.35, 0.65))
	# Twin water-edge legs (0..56 m) leaving a monumental open central arch
	for sx in [-1.0, 1.0]:
		lm.box("Bronze", Vector3(sx * 32.0, 28.0, 0.0), Vector3(24.0, 56.0, 38.0))
		lm.box("Glass", Vector3(sx * 32.0, 28.0, 19.1), Vector3(18.0, 48.0, 0.3))
	# Massive 8-storey cantilevered golden sky-bridge spanning across both legs (56..90 m)
	lm.box("Bronze", Vector3(0.0, 73.0, 0.0), Vector3(88.0, 34.0, 38.0))
	lm.box("Glass", Vector3(0.0, 73.0, 19.1), Vector3(80.0, 26.0, 0.35))
	lm.box("Lamp", Vector3(0.0, 56.2, 0.0), Vector3(40.0, 0.45, 36.0))
	lm.commit(model)

## Silodam (MVRDV, 2002, 34 m): colourful stacked container-mosaic pier block.
static func silodam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8E3D2E", "#E2DAC8", "#3B4249")
	lm.use("Blue", LandmarkMaterials.paint("#2A5E8A", 0.45, 0.15))
	lm.use("Ochre", LandmarkMaterials.paint("#C99234", 0.5, 0.1))
	lm.box("Dark", Vector3(0.0, 2.5, 0.0), Vector3(114.0, 5.0, 18.0))
	lm.box("Brick", Vector3(-34.0, 19.5, 0.0), Vector3(36.0, 29.0, 20.0))
	lm.box("Blue", Vector3(2.0, 19.5, 0.0), Vector3(36.0, 29.0, 20.0))
	lm.box("Ochre", Vector3(38.0, 19.5, 0.0), Vector3(36.0, 29.0, 20.0))
	lm.commit(model)

## Gashouder (1902, Westergas, 24 m): circular brick & iron-truss drum.
static func gashouder_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#843A2C", "#D4C9B4", "#383F47")
	lm.frustum("Brick", Vector3.ZERO, 28.0, 27.6, 17.0, 28)
	lm.frustum("Roof", Vector3(0.0, 17.0, 0.0), 28.2, 2.0, 7.0, 28)
	lm.commit(model)

## Olympic Stadium Amsterdam (Jan Wils, 1928, 46 m): brick bowl + Marathon Tower.
static func olympisch_stadion_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8A402E", "#DED6C4", "#3B4249")
	lm.frustum("Brick", Vector3.ZERO, 88.0, 86.0, 19.0, 32)
	lm.frustum("Roof", Vector3(0.0, 19.0, 0.0), 86.0, 72.0, 3.0, 32)
	# Iconic 46 m Marathon Tower with Olympic cauldron bowl
	var mt := Vector3(0.0, 0.0, 94.0)
	lm.box("Brick", mt + Vector3.UP * 20.0, Vector3(6.2, 40.0, 6.2))
	lm.frustum("Stone", mt + Vector3.UP * 40.0, 4.4, 5.2, 3.5, 12)
	lm.frustum("Lamp", mt + Vector3.UP * 43.5, 3.6, 1.0, 2.5, 12)
	lm.commit(model)

## Johan Cruijff ArenA (1996, 75 m): oval bowl + dual curved steel roof trusses.
static func johan_cruijff_arena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#D6D8DC", "#5E666E")
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#B8C0C8", 2.0, 0.35, 0.78))
	lm.frustum("Stone", Vector3.ZERO, 108.0, 104.0, 46.0, 32)
	lm.lathe("Roof", Vector3(0.0, 46.0, 0.0), PackedVector2Array([
		Vector2(105.0, 0.0), Vector2(88.0, 14.0), Vector2(46.0, 22.0), Vector2(28.0, 23.0),
	]), 32)
	# Dual signature steel arch roof trusses rising to 75 m
	for sx in [-34.0, 34.0]:
		lm.beam("Steel", Vector3(sx, 46.0, -96.0), Vector3(sx, 75.0, 0.0), 2.4, 2.8)
		lm.beam("Steel", Vector3(sx, 75.0, 0.0), Vector3(sx, 46.0, 96.0), 2.4, 2.8)
	lm.box("Lamp", Vector3(0.0, 45.5, 104.5), Vector3(68.0, 1.2, 0.8))
	lm.commit(model)
