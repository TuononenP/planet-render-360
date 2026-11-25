class_name LandmarkSgHeritageCivic
extends RefCounted

## Colonial & neoclassical Civic heritage gems:
## - `raffles_hotel` (24 m, SG-3.8): 1887 white 3-storey neo-Renaissance hotel, cast-iron
##   porte-cochère, arched verandas, green timber shutters, red terracotta hipped roofs, palm forecourt.
## - `old_hill_street_police` (30 m, SG-3.9): 1934 six-storey white arcaded neoclassical block
##   famous for its 927 timber louvred window shutters painted in rainbow bands.

static func raffles_hotel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F7F5EE", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#AA4630", 2.0))
	lm.use("Shutter", LandmarkMaterials.pbr("wood", "#2D5A3E", 2.0))
	lm.use("Iron", LandmarkMaterials.pbr("sheet_metal", "#283034", 2.0, 0.35, 0.72))
	lm.use("Trunk", LandmarkMaterials.pbr("wood", "#6E5A46", 2.0))
	lm.use("Palm", LandmarkMaterials.pbr("forest", "#2F6630", 3.0))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE0A0", 1.8))

	# Main 3-storey neo-Renaissance central block + two flanking courtyard wings with pitched hipped roofs.
	lm.box("White", Vector3(0.0, 8.0, -8.0), Vector3(114.0, 16.0, 30.0))
	LandmarkSgKit.hipped_roof(lm, "Roof", Vector3(0.0, 16.2, -8.0), 116.8, 32.8, 4.6, 11.0)
	for sx: float in [-48.0, 48.0]:
		lm.box("White", Vector3(sx, 8.0, 18.0), Vector3(24.0, 16.0, 34.0))
		LandmarkSgKit.hipped_roof(lm, "Roof", Vector3(sx, 16.2, 18.0), 26.8, 36.8, 4.6, 9.0)
		# Corner cupola turret pavilions (reaches 24.0 m).
		lm.box("White", Vector3(sx, 19.5, 32.0), Vector3(11.0, 3.6, 11.0))
		lm.spire("Roof", Vector3(sx, 21.3, 32.0), 5.8, 2.7, 0.6, 4)

	# Grand arched colonnaded verandas & green louvred timber shutters on all 3 storeys.
	LandmarkSgKit.colonnade(lm, "White", Vector3(-50.0, 0.0, 8.5), Vector3(50.0, 0.0, 8.5), 14.5, 0.45, 18)
	for fl: float in [4.5, 9.5, 13.8]:
		for i in 14:
			var wx := -46.0 + float(i) * 7.1
			lm.box("Shutter", Vector3(wx, fl, 7.2), Vector3(2.2, 2.8, 0.45))
	# Iconic cast-iron entrance porte-cochère on Beach Road front (+Z).
	lm.box("Iron", Vector3(0.0, 6.2, 14.5), Vector3(18.0, 1.2, 12.0))
	for px: float in [-8.0, 8.0]:
		lm.beam("Iron", Vector3(px, 0.0, 19.5), Vector3(px, 6.2, 19.5), 0.35, 0.35)
	lm.box("WarmLamp", Vector3(0.0, 5.4, 14.5), Vector3(14.0, 0.35, 8.0))
	# Formal Traveller's & Royal Palm forecourt garden.
	for px: float in [-26.0, -14.0, 14.0, 26.0]:
		LandmarkSgKit.palm(lm, "Trunk", "Palm", Vector3(px, 0.0, 24.0), 9.0, Vector2(0.2, 0.15), 8)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 32.0), Vector3(0.0, 12.0, 6.0), 66.0, 1.4],
		[Vector3(-48.0, 2.5, 42.0), Vector3(-48.0, 14.0, 26.0), 58.0, 1.1],
		[Vector3(48.0, 2.5, 42.0), Vector3(48.0, 14.0, 26.0), 58.0, 1.1],
	])

static func old_hill_street_police(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F2EFE8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4832", 2.0))
	# Six iconic rainbow shutter bands (green, yellow, orange, red, purple, blue).
	lm.use("ShGreen", LandmarkMaterials.paint("#2E8E52", 0.55, 0.0))
	lm.use("ShYellow", LandmarkMaterials.paint("#E6B828", 0.55, 0.0))
	lm.use("ShOrange", LandmarkMaterials.paint("#E66E24", 0.55, 0.0))
	lm.use("ShRed", LandmarkMaterials.paint("#C83034", 0.55, 0.0))
	lm.use("ShPurple", LandmarkMaterials.paint("#6E44A2", 0.55, 0.0))
	lm.use("ShBlue", LandmarkMaterials.paint("#2C6CB2", 0.55, 0.0))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE0A4", 1.7))

	var bands := ["ShGreen", "ShYellow", "ShOrange", "ShRed", "ShPurple", "ShBlue"]

	# Six-storey monumental white neoclassical courtyard block (128 x 86 m, y=0..27 m).
	lm.box("White", Vector3(0.0, 13.5, 0.0), Vector3(126.0, 27.0, 84.0))
	lm.box("White", Vector3(0.0, 27.6, 0.0), Vector3(128.0, 1.4, 86.0))
	lm.box("Roof", Vector3(0.0, 29.1, 0.0), Vector3(122.0, 1.8, 80.0))
	# Central projecting portico bays on both long facades.
	for side: float in [-1.0, 1.0]:
		lm.box("White", Vector3(0.0, 14.0, side * 43.2), Vector3(24.0, 28.0, 3.0))
		lm.box("WarmLamp", Vector3(0.0, 26.8, side * 43.0), Vector3(118.0, 0.35, 0.35))

	# 927 signature rainbow-banded timber louvred shutters across all 4 facades & 6 storeys.
	for fl in 6:
		var wy := 3.0 + float(fl) * 4.1
		for i in 22:
			var wx := -57.0 + float(i) * 5.4
			var key: String = bands[(i / 4 + fl) % bands.size()]
			lm.box(key, Vector3(wx, wy, 42.3), Vector3(2.8, 2.8, 0.5))
			lm.box(key, Vector3(wx, wy, -42.3), Vector3(2.8, 2.8, 0.5))
		for j in 14:
			var wz := -36.0 + float(j) * 5.5
			var key_s: String = bands[(j / 3 + fl) % bands.size()]
			lm.box(key_s, Vector3(63.3, wy, wz), Vector3(0.5, 2.8, 2.8))
			lm.box(key_s, Vector3(-63.3, wy, wz), Vector3(0.5, 2.8, 2.8))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 54.0), Vector3(0.0, 16.0, 40.0), 68.0, 1.3],
		[Vector3(0.0, 2.5, -54.0), Vector3(0.0, 16.0, -40.0), 68.0, 1.2],
	])
