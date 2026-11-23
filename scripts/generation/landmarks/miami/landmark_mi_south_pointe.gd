class_name LandmarkMiSouthPointe
extends RefCounted

## South Pointe Pier & Park - MI-4C.
## Site: (25.763836, -80.130242, yaw_deg 32.9), 147.1 x 17.7 m, height_m = 12.0, built over
## water (base "sea"). Concrete and weathered ipe-wood fishing pier (deck top y = 3.8 m, pilings
## down to y = -3.5 m) running seaward (+X) from a grassy viewing mound, with a wide viewing
## T-head under angled white shade-canopy wings, a rock jetty along the landward side, a
## serpentine park pylon and William Lane's angled amber / cyan turtle-safe light masts
## (MastLamp, up to 12.0 m) glowing at night.

const HEIGHT_M := 12.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C4BB", 4.0))
	lm.use("Ipe", LandmarkMaterials.pbr("wood", "#6B4630", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#8A8780", 3.0))
	lm.use("Canopy", LandmarkMaterials.paint("#F4F4F1", 0.5, 0.2))
	lm.use("Steel", LandmarkMaterials.paint("#6F7A80", 0.45, 0.7))
	lm.use("Grass", LandmarkMaterials.paint("#4F8F3A", 0.9, 0.0))
	lm.use("MastLamp", LandmarkMaterials.lit("#FFB030", 0.9))
	lm.use("MastCyanLamp", LandmarkMaterials.lit("#30D8E8", 0.9))
	_deck(lm)
	_piles_and_rocks(lm)
	_mound(lm)
	_canopies(lm)
	_masts(lm)
	lm.commit(model)
	var amber := Color(1.0, 0.70, 0.30)
	var cyan := Color(0.35, 0.85, 0.95)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-20.0, 11.0, 1.1), Vector3(-20.0, 3.8, 0.0), 50.0, 0.9, 18.0, amber],
		[Vector3(10.0, 11.0, -1.1), Vector3(10.0, 3.8, 0.0), 50.0, 0.9, 18.0, cyan],
		[Vector3(40.0, 11.0, 1.1), Vector3(40.0, 3.8, 0.0), 50.0, 0.9, 18.0, amber],
		[Vector3(66.0, 11.0, 0.0), Vector3(66.0, 3.8, 0.0), 60.0, 1.0, 20.0, cyan],
	])

static func _deck(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(0.25, 3.3, 0.0), Vector3(119.5, 0.5, 6.0), Basis(), 0.0)
	lm.box("Ipe", Vector3(0.25, 3.675, 0.0), Vector3(119.5, 0.25, 5.6), Basis(), 0.0)
	lm.box("Concrete", Vector3(66.75, 3.3, 0.0), Vector3(13.5, 0.5, 17.7), Basis(), 0.0)
	lm.box("Ipe", Vector3(66.75, 3.675, 0.0), Vector3(13.5, 0.25, 17.3), Basis(), 0.0)

static func _piles_and_rocks(lm: LandmarkMesh) -> void:
	for k in 17:
		var x: float = -56.0 + 7.0 * float(k)
		for z: float in [-2.5, 2.5]:
			lm.beam("Concrete", Vector3(x, -3.5, z), Vector3(x, 3.05, z), 0.7, 0.7, Vector3.BACK, true)
	for x: float in [63.0, 70.0]:
		for z: float in [-7.5, 0.0, 7.5]:
			lm.beam("Concrete", Vector3(x, -3.5, z), Vector3(x, 3.05, z), 0.8, 0.8, Vector3.BACK, true)
	# Government Cut rock jetty along the landward stretch
	for i in 22:
		var x: float = -72.0 + 3.2 * float(i)
		var z: float = (5.5 + float(i % 3)) * (1.0 if i % 2 == 0 else -1.0)
		var s: float = 2.4 + 0.7 * float(i % 4)
		lm.box("Rock", Vector3(x, s * 0.3 - 0.3, z), Vector3(s * 1.4, s * 0.6, s), Basis(Vector3.UP, float(i) * 0.7), 0.3)

static func _mound(lm: LandmarkMesh) -> void:
	lm.lathe("Grass", Vector3(-66.5, 0.0, 0.0), PackedVector2Array([
		Vector2(7.0, -0.2), Vector2(6.2, 1.2), Vector2(4.5, 3.2), Vector2(2.5, 4.6),
		Vector2(0.8, 5.4), Vector2(0.0, 5.6)]), 20)
	# Serpentine park pylon rising from the mound crest
	for k in 8:
		var a := Vector3(-66.5, 5.0 + 0.9 * float(k), 1.6 * sin(float(k) * 0.8))
		var b := Vector3(-66.5, 5.0 + 0.9 * float(k + 1), 1.6 * sin(float(k + 1) * 0.8))
		lm.beam("Concrete", a, b, 0.5, 0.5, Vector3.BACK)

static func _canopies(lm: LandmarkMesh) -> void:
	for sz: float in [-1.0, 1.0]:
		lm.box("Canopy", Vector3(66.5, 7.2, sz * 5.0), Vector3(12.0, 0.2, 6.5),
			Basis(Vector3.RIGHT, sz * 0.12), 0.0)
		for px: float in [61.5, 71.5]:
			lm.beam("Steel", Vector3(px, 3.8, sz * 7.0), Vector3(px, 7.0, sz * 7.0), 0.2, 0.2)

static func _masts(lm: LandmarkMesh) -> void:
	for i in 12:
		var x: float = -50.0 + 10.5 * float(i)
		var sgn: float = 1.0 if i % 2 == 0 else -1.0
		var h: float = 8.5 + 3.5 * float(i % 3) / 2.0
		var base := Vector3(x, 3.8, 2.7 * sgn)
		var top := Vector3(x, h - 0.4, 2.7 * sgn - 1.6 * sgn)
		lm.beam("Steel", base, top, 0.28, 0.28, Vector3.RIGHT)
		lm.frustum("MastLamp" if i % 2 == 0 else "MastCyanLamp", top, 0.42, 0.15, 0.4, 8)
