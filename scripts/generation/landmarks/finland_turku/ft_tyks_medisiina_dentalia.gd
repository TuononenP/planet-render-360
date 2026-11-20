class_name FtTyksMedisiinaDentalia
extends RefCounted

## TYKS / University of Turku Medical Teaching & Research Cluster on
## Kiinamyllynkatu 10 in true metres (+X ENE toward BioCity/Savitehtaankatu,
## +Z SSE toward Lemminkäisenkatu, turned by registry yaw_deg = -34.0°):
##   1. Medisiina D (2018, Schauman Arkkitehdit) at (0, 0): 6-storey
##      contemporary glass, light-metal & warm-timber research hub
##      (64 x 34 m, H = 24.5 m), double-height glazed campus atrium lobby
##      with warm timber soffit & vertical timber brise-soleil slats,
##      cantilevered upper laboratory volumes, rooftop mechanical screen,
##      and landscaped campus entry plaza.
##   2. Medisiina A–C (SEAT_META child at (-56, 0, -14)): mid-century
##      red-brick and concrete laboratory wings (54 x 24 m, H = 18.2 m,
##      matching LoD2 1034400283 18.1 m) with continuous horizontal lab
##      window bands and glazed connecting bridge to Medisiina D.
##   3. Dentalia (SEAT_META child at (+42, 0, +34)): pale-brick & glass
##      dental teaching clinic (42 x 22 m, H = 15.0 m) with sloped
##      clerestory skylight roof and sheltered clinical entry canopy.
## Surfaces: 14 merged PBR parts (7 Medisiina D + 4 Medisiina A-C + 3 Dentalia).

const FOUND := -2.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sky := SkyKit.new(lm)
	_materials(lm, sky)
	_build_medisiina_d(lm, sky)
	_build_campus_plaza(lm)
	lm.commit(model)
	_build_medisiina_ac(model, lm)
	_build_dentalia(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sky: SkyKit) -> void:
	lm.use("LightMetal", LandmarkMaterials.pbr("sheet_metal", "#E6E8E5", 2.8, 0.38, 0.25))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2E343B", 0.44, 0.55))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#C48E54", 2.0, 0.62))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BEBCAF", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#243948"))
	sky.wall("WallLit", "white_panel", 3.6, 3.85)
	lm.use("Lamp", LandmarkMaterials.lit("#FFECC2", 1.55))

static func _build_medisiina_d(lm: LandmarkMesh, sky: SkyKit) -> void:
	# Ground plinth & double-height glazed campus atrium lobby (y = 0..7.8 m).
	LandmarkFrKit.rect(lm, "Concrete", -33.0, 33.0, -18.0, 18.0, FOUND, 0.45)
	LandmarkFrKit.rect(lm, "Glass", -30.5, 30.5, -15.5, 15.5, 0.45, 7.8)
	# Warm timber soffit ceiling visible inside the double-height lobby.
	LandmarkFrKit.rect(lm, "Timber", -31.8, 31.8, -16.8, 16.8, 7.45, 7.95)
	lm.box("Lamp", Vector3(0.0, 4.2, 0.0), Vector3(54.0, 5.2, 24.0))
	# Perimeter dark-metal columns supporting the cantilevered upper lab block.
	for i in 11:
		var cx := lerpf(-30.0, 30.0, float(i) / 10.0)
		lm.frustum("DarkMetal", Vector3(cx, 0.45, 16.0), 0.28, 0.28, 7.2, 8)
		lm.frustum("DarkMetal", Vector3(cx, 0.45, -16.0), 0.28, 0.28, 7.2, 8)
	# Cantilevered 4-storey upper research & teaching block (64 x 34 m, y = 7.95..23.2 m).
	LandmarkFrKit.rect(lm, "LightMetal", -32.0, 32.0, -17.0, 17.0, 22.7, 23.3)
	LandmarkFrKit.rect(lm, "DarkMetal", -31.6, 31.6, -16.6, 16.6, 7.95, 22.8)
	sky.face("WallLit", Vector2(-32.0, 17.0), Vector2(32.0, 17.0), 8.0, 22.8, Vector3.BACK, 18)
	sky.face("WallLit", Vector2(32.0, -17.0), Vector2(-32.0, -17.0), 8.0, 22.8, Vector3.FORWARD, 18)
	sky.face("WallLit", Vector2(32.0, 17.0), Vector2(32.0, -17.0), 8.0, 22.8, Vector3.RIGHT, 10)
	sky.face("WallLit", Vector2(-32.0, -17.0), Vector2(-32.0, 17.0), 8.0, 22.8, Vector3.LEFT, 10)
	# Horizontal light-metal floor bands & signature vertical warm-timber brise-soleil slats.
	for fy: float in [11.7, 15.5, 19.3, 22.8]:
		LandmarkFrParts.band(lm, "LightMetal", -32.0, 32.0, -17.0, 17.0, fy, 0.45, 0.22)
	for i in 19:
		var tx := lerpf(-30.5, 30.5, float(i) / 18.0)
		if i % 2 == 0:
			lm.box("Timber", Vector3(tx, 15.4, 17.32), Vector3(0.28, 14.5, 0.48))
			lm.box("Timber", Vector3(tx, 15.4, -17.32), Vector3(0.28, 14.5, 0.48))
	# Rooftop louvered mechanical screen reaching 24.5 m.
	LandmarkFrKit.rect(lm, "LightMetal", -22.0, 22.0, -9.5, 9.5, 23.3, 24.5)
	# Elevated glazed bridge linking west (-X) toward Medisiina A-C.
	LandmarkFrKit.rect(lm, "DarkMetal", -44.0, -31.5, -5.2, -1.2, 8.2, 8.65)
	LandmarkFrKit.rect(lm, "Glass", -44.0, -31.5, -5.0, -1.4, 8.65, 11.45)
	LandmarkFrKit.rect(lm, "LightMetal", -44.0, -31.5, -5.3, -1.1, 11.45, 11.95)

static func _build_campus_plaza(lm: LandmarkMesh) -> void:
	# Paved forecourt & low granite/timber campus benches on +Z entrance side.
	LandmarkFrKit.rect(lm, "Concrete", -36.0, 36.0, 18.0, 28.0, FOUND, 0.28)
	for bx: float in [-18.0, -6.0, 6.0, 18.0]:
		lm.box("Concrete", Vector3(bx, 0.46, 23.0), Vector3(4.2, 0.36, 1.1))
		lm.box("Timber", Vector3(bx, 0.68, 23.0), Vector3(4.3, 0.12, 1.15))

## Mid-century red-brick & concrete Medisiina A–C lab wings.
static func _build_medisiina_ac(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9C523E", 2.4))
	lm.use("Concrete", (base_lm._surfs["Concrete"] as LandmarkMesh.Surf).mat)
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	lm.use("DarkMetal", (base_lm._surfs["DarkMetal"] as LandmarkMesh.Surf).mat)
	# L-shaped 4-storey red-brick lab wings (54 x 24 m, H = 18.2 m).
	LandmarkFrKit.rect(lm, "Concrete", -27.4, 27.4, -12.4, 12.4, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Brick", -27.0, 27.0, -12.0, 12.0, 1.8, 17.4)
	LandmarkFrParts.band(lm, "Concrete", -27.0, 27.0, -12.0, 12.0, 16.9, 0.55, 0.18)
	LandmarkFrKit.rect(lm, "Concrete", -16.0, 16.0, -5.5, 5.5, 17.4, 18.2)
	# Continuous horizontal laboratory ribbon windows on all 4 storeys.
	for lv in 4:
		var wy := 2.8 + float(lv) * 3.55
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -25.0, 25.0, sz * 12.0 - 0.14, sz * 12.0 + 0.14, wy, wy + 1.8)
			LandmarkFrKit.rect(lm, "Concrete", -25.2, 25.2, sz * 12.0 - 0.22, sz * 12.0 + 0.22, wy - 0.2, wy)
	# Secondary north lab wing projecting -Z.
	LandmarkFrKit.rect(lm, "Brick", -27.0, -8.0, -28.0, -12.0, FOUND, 15.6)
	for lv in 3:
		var wy := 2.8 + float(lv) * 3.6
		LandmarkFrKit.rect(lm, "Glass", -27.15, -26.85, -26.0, -13.5, wy, wy + 1.8)
	var child := Node3D.new()
	child.name = "MedisiinaAC"
	child.position = Vector3(-58.0, 0.0, -12.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## Dentalia — pale-brick & glass dental teaching clinic.
static func _build_dentalia(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("PaleBrick", LandmarkMaterials.pbr("brick", "#CFC6B4", 2.4))
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	lm.use("DarkMetal", (base_lm._surfs["DarkMetal"] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "PaleBrick", -21.0, 21.0, -11.0, 11.0, FOUND, 13.2)
	# Raised sloped clerestory skylight roof (13.2 -> 15.0 m).
	LandmarkFrKit.gable(lm, "DarkMetal", -18.0, 18.0, -6.5, 6.5, 13.2, 1.8, 0.25, "Glass", 1)
	for lv in 3:
		var wy := 2.2 + float(lv) * 3.55
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -19.2, 19.2, sz * 11.0 - 0.14, sz * 11.0 + 0.14, wy, wy + 1.85)
	# Entry canopy on -Z side facing Medisiina D plaza.
	LandmarkFrKit.rect(lm, "DarkMetal", -6.5, 6.5, -14.8, -11.0, 3.8, 4.2)
	var child := Node3D.new()
	child.name = "Dentalia"
	child.position = Vector3(42.0, 0.0, 36.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 32.0), Vector3(0.0, 12.0, 17.0), 62.0, 0.90, 46.0, Color(1.0, 0.88, 0.68)],
		[Vector3(-24.0, 2.0, 28.0), Vector3(-20.0, 12.0, 17.0), 54.0, 0.65, 38.0, Color(1.0, 0.88, 0.68)],
		[Vector3(24.0, 2.0, 28.0), Vector3(20.0, 12.0, 17.0), 54.0, 0.65, 38.0, Color(1.0, 0.88, 0.68)],
	])
