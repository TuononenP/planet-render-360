class_name LandmarkSgNationalGallery
extends RefCounted

## National Gallery Singapore (60 m dome, SG-3.1):
## - Joins two monumental Padang landmarks along St Andrew's Road:
##   1. Former Supreme Court (south-west, way 170960936): rusticated limestone palazzo,
##      Corinthian portico with triangular pediment relief, drum rotunda, and iconic
##      patina-green copper central dome reaching 60 m.
##   2. Former City Hall (north-east, way 46595597): grand 18-column Corinthian colonnade
##      and ceremonial stone steps facing the Padang.
## - United by Studio Milou's shimmering gold-aluminium filigree veil roof canopy & glass sky-bridges.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#E4DFD4", 3.0))
	lm.use("Rustic", LandmarkMaterials.pbr("stone", "#CCC6B8", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#4E8272", 2.0, 0.35, 0.65))
	lm.use("GoldVeil", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#4E7286"))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4A34", 2.0))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD890", 1.8))

	# --- 1. Former Supreme Court (south-west wing, x = -64 m) ---
	var sc := Vector3(-64.0, 0.0, 0.0)
	lm.box("Rustic", sc + Vector3(0.0, 4.0, 0.0), Vector3(88.0, 8.0, 72.0))
	lm.box("Limestone", sc + Vector3(0.0, 16.0, 0.0), Vector3(82.0, 16.0, 64.0))
	lm.box("Glass", sc + Vector3(0.0, 16.0, 32.3), Vector3(72.0, 10.0, 0.5))
	lm.box("Glass", sc + Vector3(0.0, 16.0, -32.3), Vector3(72.0, 10.0, 0.5))
	# Corinthian portico & pediment facing the Padang (+Z).
	LandmarkSgKit.colonnade(lm, "Limestone", sc + Vector3(-24.0, 8.0, 35.0), sc + Vector3(24.0, 8.0, 35.0), 14.5, 0.85, 8)
	lm.box("Limestone", sc + Vector3(0.0, 23.5, 34.5), Vector3(54.0, 2.4, 6.0))
	# Triangular classical tympanum pediment.
	var ped_p := sc + Vector3(0.0, 24.7, 36.8)
	LandmarkSgKit.flat_tri(lm, "Limestone", ped_p + Vector3(-25.0, 0.0, 0.0), ped_p + Vector3(25.0, 0.0, 0.0), ped_p + Vector3(0.0, 6.2, 0.0))
	LandmarkSgKit.flat_tri(lm, "Limestone", ped_p + Vector3(25.0, 0.0, -3.5), ped_p + Vector3(-25.0, 0.0, -3.5), ped_p + Vector3(0.0, 6.2, -3.5))
	# Iconic Former Supreme Court drum & green patina copper dome (reaches 60.0 m).
	lm.frustum("Limestone", sc + Vector3(0.0, 24.0, 0.0), 17.5, 16.5, 11.5, 20)
	lm.frustum("Glass", sc + Vector3(0.0, 25.5, 0.0), 17.0, 16.8, 6.0, 20)
	LandmarkAsiaSouthUtil.dome(lm, "Copper", sc + Vector3(0.0, 35.5, 0.0), 16.2, 16.5, 20, 10)
	lm.frustum("Limestone", sc + Vector3(0.0, 51.5, 0.0), 3.6, 3.2, 5.0, 12)
	LandmarkAsiaSouthUtil.dome(lm, "Copper", sc + Vector3(0.0, 56.5, 0.0), 3.3, 3.5, 12, 6)

	# --- 2. Former City Hall (north-east wing, x = +60 m) ---
	var ch := Vector3(60.0, 0.0, 0.0)
	# Monumental ceremonial Padang steps (+Z front).
	for s in 5:
		lm.box("Rustic", ch + Vector3(0.0, 0.5 + float(s) * 0.9, 38.0 - float(s) * 1.1), Vector3(88.0, 1.0, 4.0))
	lm.box("Rustic", ch + Vector3(0.0, 4.0, 0.0), Vector3(114.0, 8.0, 64.0))
	lm.box("Limestone", ch + Vector3(0.0, 15.5, -2.0), Vector3(106.0, 15.0, 54.0))
	lm.box("Glass", ch + Vector3(0.0, 15.5, 25.3), Vector3(96.0, 9.5, 0.5))
	# Grand 18-column Corinthian colonnade facing the Padang (+Z).
	LandmarkSgKit.colonnade(lm, "Limestone", ch + Vector3(-48.0, 8.0, 30.5), ch + Vector3(48.0, 8.0, 30.5), 14.5, 0.82, 18)
	lm.box("Limestone", ch + Vector3(0.0, 23.2, 0.0), Vector3(114.0, 2.4, 66.0))
	lm.box("Roof", ch + Vector3(0.0, 25.4, -2.0), Vector3(106.0, 2.2, 54.0))

	# --- 3. Gold-Aluminium Filigree Veil Roof Canopy & Glass Link (x = -18..+10 m) ---
	lm.box("Glass", Vector3(-6.0, 14.0, 0.0), Vector3(26.0, 24.0, 52.0))
	lm.box("GoldVeil", Vector3(-4.0, 27.2, 0.0), Vector3(118.0, 1.4, 58.0))
	lm.box("WarmLamp", Vector3(-6.0, 25.8, 28.0), Vector3(110.0, 0.45, 0.45))
	lm.box("WarmLamp", sc + Vector3(0.0, 34.8, 0.0), Vector3(34.0, 0.5, 34.0))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-64.0, 2.5, 48.0), Vector3(-64.0, 32.0, 20.0), 62.0, 1.4],
		[Vector3(60.0, 2.5, 48.0), Vector3(60.0, 18.0, 26.0), 66.0, 1.4],
		[Vector3(-64.0, 28.0, 26.0), Vector3(-64.0, 48.0, 0.0), 58.0, 1.3],
	])
