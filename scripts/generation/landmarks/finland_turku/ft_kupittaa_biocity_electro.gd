class_name FtKupittaaBiocityElectro
extends RefCounted

## Kupittaa Science Park Core — BioCity, ElectroCity & DataCity along
## Tykistökatu / Lemminkäisenkatu, in true metres (+X ENE toward Kupittaa
## Station, +Z SSE toward Kupittaanpuisto, turned by registry yaw_deg = -34.0°):
##   1. BioCity (turku_lod2 1034544167: area 5,474 m², 7 storeys, H = 35.4 m)
##      at (0, 0): iconic red-brick & glass biotech research hub — twin
##      7-storey red-brick wings flanking a soaring full-height vaulted glass
##      atrium gallery (Tykistökatu entrance), cantilevered rooftop glass
##      conference penthouse, and illuminated interior atrium bridges.
##   2. ElectroCity (turku_lod2 103454365K / 103454370R: 6–7 storeys,
##      H = 35.4 m, SEAT_META child at (+78, 0, -44)): historic red-brick
##      industrial factory/silo masonry fused with modern glass-and-steel
##      upper laboratory levels & glazed corner turret.
##   3. DataCity (turku_lod2 103454363H / 103454368N: 6–7 storeys,
##      H = 34.4 m, SEAT_META child at (+64, 0, +16)): red-brick & glass
##      tech courtyard block with glazed street atrium and elevated skybridge
##      linking across Tykistökatu to BioCity.
## Surfaces: 14 merged PBR parts (8 BioCity + 3 ElectroCity + 3 DataCity).

const FOUND := -2.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sky := SkyKit.new(lm)
	_materials(lm, sky)
	_build_biocity(lm, sky)
	_build_skybridge(lm)
	lm.commit(model)
	_build_electrocity(model, lm)
	_build_datacity(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sky: SkyKit) -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#944836", 2.4))
	lm.use("LightMetal", LandmarkMaterials.pbr("sheet_metal", "#DCE0E3", 2.8, 0.42, 0.25))
	lm.use("DarkSteel", LandmarkMaterials.paint("#2A3038", 0.42, 0.58))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C0BEB6", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#223846"))
	sky.wall("WallLit", "brick_punched", 3.6, 3.85)
	sky.wall("GlassLit", "steel_panel", 3.6, 3.85)
	lm.use("Lamp", LandmarkMaterials.lit("#FFECC2", 1.55))

static func _build_biocity(lm: LandmarkMesh, sky: SkyKit) -> void:
	# Ground plinth & twin 7-storey red-brick biotech wings (76 x 64 m overall, H = 35.4 m).
	LandmarkFrKit.rect(lm, "Concrete", -39.0, 39.0, -33.0, 33.0, FOUND, 1.4)
	# North (-Z) and South (+Z) red-brick research wings flanking the central glass atrium.
	for sz: float in [-1.0, 1.0]:
		var z0 := 7.0 if sz > 0.0 else -31.0
		var z1 := 31.0 if sz > 0.0 else -7.0
		LandmarkFrKit.rect(lm, "Brick", -38.0, 38.0, z0, z1, 1.4, 30.8)
		sky.face("WallLit", Vector2(-38.0, z1), Vector2(38.0, z1), 1.4, 30.2, Vector3.BACK, 20)
		sky.face("WallLit", Vector2(38.0, z0), Vector2(-38.0, z0), 1.4, 30.2, Vector3.FORWARD, 20)
		sky.face("WallLit", Vector2(38.0, z1), Vector2(38.0, z0), 1.4, 30.2, Vector3.RIGHT, 6)
		sky.face("WallLit", Vector2(-38.0, z0), Vector2(-38.0, z1), 1.4, 30.2, Vector3.LEFT, 6)
		# Crisp pale-metal parapet cornice & vertical brick pilasters.
		LandmarkFrParts.band(lm, "LightMetal", -38.0, 38.0, z0, z1, 30.2, 0.72, 0.25)
		for i in 9:
			var px := lerpf(-36.0, 36.0, float(i) / 8.0)
			lm.box("Brick", Vector3(px, 16.0, z1 + 0.22 if sz > 0.0 else z0 - 0.22),
				Vector3(0.65, 29.2, 0.45))
	# Soaring central full-height vaulted glass atrium gallery between the brick wings!
	LandmarkFrKit.rect(lm, "Glass", -39.5, 39.5, -7.2, 7.2, 1.4, 31.2)
	# Vaulted steel-and-glass skylight barrel arch over atrium (y = 31.2..35.4 m).
	for i in 8:
		var t0 := float(i) / 8.0
		var t1 := float(i + 1) / 8.0
		var a0 := PI * t0
		var a1 := PI * t1
		var z0 := -cos(a0) * 7.2
		var z1 := -cos(a1) * 7.2
		var y0 := 31.2 + sin(a0) * 4.2
		var y1 := 31.2 + sin(a1) * 4.2
		LandmarkFrKit.face(lm, "Glass", [
			Vector3(-39.5, y0, z0), Vector3(39.5, y0, z0),
			Vector3(39.5, y1, z1), Vector3(-39.5, y1, z1),
		])
	# Steel portal arches & warm glowing interior skybridges inside the BioCity atrium.
	for i in 9:
		var rx := lerpf(-38.0, 38.0, float(i) / 8.0)
		lm.box("DarkSteel", Vector3(rx, 16.2, 7.3), Vector3(0.26, 29.8, 0.28))
		lm.box("DarkSteel", Vector3(rx, 16.2, -7.3), Vector3(0.26, 29.8, 0.28))
	lm.box("Lamp", Vector3(0.0, 15.0, 0.0), Vector3(70.0, 22.0, 10.0))
	# Rooftop glass-and-metal biotech penthouse on the north wing reaching 35.4 m.
	LandmarkFrKit.rect(lm, "LightMetal", -28.0, 28.0, -24.0, -11.0, 30.8, 35.2)
	LandmarkFrKit.rect(lm, "Glass", -27.2, 27.2, -24.15, -23.85, 31.4, 34.4)

static func _build_skybridge(lm: LandmarkMesh) -> void:
	# Elevated glazed skybridge linking BioCity east (+X) toward DataCity across Tykistökatu.
	LandmarkFrKit.rect(lm, "DarkSteel", 38.0, 62.0, 6.0, 10.6, 11.6, 12.1)
	LandmarkFrKit.rect(lm, "Glass", 38.0, 62.0, 6.2, 10.4, 12.1, 15.2)
	LandmarkFrKit.rect(lm, "LightMetal", 38.0, 62.0, 5.9, 10.7, 15.2, 15.7)
	lm.box("Lamp", Vector3(50.0, 13.6, 8.3), Vector3(22.0, 1.1, 2.8))

## ElectroCity — historic red-brick industrial factory/silo fused with glass-and-steel labs.
static func _build_electrocity(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["Brick", "LightMetal", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# Historic 4-storey red-brick industrial factory base (56 x 34 m, y = 0..17.5 m).
	LandmarkFrKit.rect(lm, "Brick", -28.0, 28.0, -17.0, 17.0, FOUND, 17.5)
	for lv in 4:
		var wy := 2.2 + float(lv) * 3.7
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -25.8, 25.8, sz * 17.0 - 0.14, sz * 17.0 + 0.14, wy, wy + 2.1)
	# Modern 3-storey glass-and-metal tech addition crowning the historic brick base (y = 17.5..31.8 m).
	LandmarkFrKit.rect(lm, "Glass", -26.5, 26.5, -15.5, 15.5, 17.5, 31.2)
	LandmarkFrParts.band(lm, "LightMetal", -26.5, 26.5, -15.5, 15.5, 30.8, 0.7, 0.35)
	# Historic cylindrical red-brick industrial silo tower fused with glazed crown (H = 35.4 m).
	lm.frustum("Brick", Vector3(-24.0, FOUND, 14.0), 6.4, 6.4, 24.0 - FOUND, 16)
	lm.frustum("Glass", Vector3(-24.0, 24.0, 14.0), 6.2, 6.2, 10.6, 16)
	lm.frustum("LightMetal", Vector3(-24.0, 34.6, 14.0), 6.6, 6.6, 0.8, 16)
	var child := Node3D.new()
	child.name = "ElectroCity"
	child.position = Vector3(84.0, 0.0, -44.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## DataCity — red-brick & glass tech hub across Tykistökatu.
static func _build_datacity(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["Brick", "LightMetal", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "Brick", -26.0, 26.0, -22.0, 22.0, FOUND, 31.5)
	LandmarkFrParts.band(lm, "LightMetal", -26.0, 26.0, -22.0, 22.0, 30.9, 0.72, 0.25)
	# Tall vertical glass atrium bay on west (-X) Tykistökatu front.
	LandmarkFrKit.rect(lm, "Glass", -27.2, -16.0, -9.0, 9.0, 0.0, 34.0)
	LandmarkFrKit.rect(lm, "LightMetal", -27.4, -15.8, -9.2, 9.2, 33.8, 34.4)
	for lv in 7:
		var wy := 1.8 + float(lv) * 4.1
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -24.0, 24.0, sz * 22.0 - 0.14, sz * 22.0 + 0.14, wy, wy + 2.0)
	var child := Node3D.new()
	child.name = "DataCity"
	child.position = Vector3(68.0, 0.0, 16.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-52.0, 3.0, 0.0), Vector3(-38.0, 18.0, 0.0), 62.0, 0.90, 50.0, Color(1.0, 0.90, 0.72)],
		[Vector3(52.0, 3.0, 0.0), Vector3(38.0, 18.0, 0.0), 62.0, 0.85, 50.0, Color(1.0, 0.90, 0.72)],
		[Vector3(0.0, 3.0, 44.0), Vector3(0.0, 18.0, 30.0), 64.0, 0.65, 48.0, Color(1.0, 0.86, 0.66)],
	])
