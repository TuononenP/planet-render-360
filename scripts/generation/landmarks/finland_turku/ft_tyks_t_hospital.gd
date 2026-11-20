class_name FtTyksTHospital
extends RefCounted

## TYKS T-sairaala (2003–2013, Arkkitehtiryhmä Reino Koivula) & Emergency
## Precinct along Hämeentie / Savitehtaankatu, in true metres (+X ENE toward
## Majakkasairaala, +Z SSE toward BioCity, turned by registry yaw_deg = -34.0°):
##   - NE Tall Clinical Tower (T-sairaala B/C/D wing, turku_lod2 103520210L:
##     area 3,702 m², 9 storeys, H = 44.5 m): pale-metal & glass block with
##     vertical sun-shading louvers and rooftop helipad-clear mechanical crown.
##   - Main Curved Glass-and-Louver Clinical Wing (turku_lod2 1034400250:
##     area 3,287 m², 7 storeys, H = 29.9 m): gentle 5-segment curved south
##     facade facing Hämeentie/Savitehtaankatu with rhythmic aluminum louvers,
##     turquoise/terracotta accent panels, and low pitched mechanical roof.
##   - Soaring Main Entrance Glass Atrium (y = 0..22 m) with cantilevered
##     steel-and-glass drop-off canopy and warm illuminated lobby interior.
##   - Dedicated Ambulance / Emergency Bay (Päivystys) on the SW flank with
##     sheltered drive-through canopy, red emergency fascia band, and bay lights.
##   - T-sairaalan pysäköintitalo (multi-storey parking garage, SEAT_META child
##     at (-56, 0, -18), 6 open concrete levels, slatted screen, helical ramp).
##   - Enclosed glazed skybridges linking east (+X) toward Majakkasairaala and
##     southwest (+Z/-X) toward Medisiina D.
## Surfaces: 12 merged PBR parts (8 main + 4 ParkingGarage).

const FOUND := -2.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sky := SkyKit.new(lm)
	_materials(lm, sky)
	_build_ne_tower(lm, sky)
	_build_curved_clinical_wing(lm, sky)
	_build_main_atrium_and_emergency(lm)
	_build_skybridges(lm)
	lm.commit(model)
	_build_parking_garage(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sky: SkyKit) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C6BE", 3.2))
	lm.use("MetalLight", LandmarkMaterials.pbr("sheet_metal", "#DDE1E4", 2.8, 0.42, 0.25))
	lm.use("MetalDark", LandmarkMaterials.paint("#363D44", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#243947"))
	sky.wall("WallLit", "steel_panel", 3.5, 3.8)
	lm.use("AccentTeal", LandmarkMaterials.paint("#357D84", 0.35, 0.15))
	lm.use("EmergencyRed", LandmarkMaterials.paint("#C62828", 0.32, 0.05))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF0CE", 1.6))

static func _build_ne_tower(lm: LandmarkMesh, sky: SkyKit) -> void:
	# 9-storey NE clinical tower (54 x 42 m, H = 44.5 m matching LoD2 103520210L).
	var x0 := 10.0
	var x1 := 64.0
	var z0 := -46.0
	var z1 := -4.0
	LandmarkFrKit.rect(lm, "Concrete", x0 - 0.5, x1 + 0.5, z0 - 0.5, z1 + 0.5, FOUND, 3.6)
	_sky_box(lm, sky, x0, x1, z0, z1, 3.6, 41.2, 14, 11)
	LandmarkFrParts.band(lm, "MetalLight", x0, x1, z0, z1, 40.4, 0.9, 0.28)
	# Horizontal floor bands & rhythmic vertical aluminum sun-shading louvers.
	for lv in range(1, 10):
		var fy := 3.6 + float(lv) * 3.85
		if fy < 40.2:
			LandmarkFrParts.band(lm, "MetalLight", x0, x1, z0, z1, fy, 0.38, 0.22)
	for i in 12:
		var lx := lerpf(x0 + 2.5, x1 - 2.5, float(i) / 11.0)
		var mat := "AccentTeal" if i % 4 == 0 else "MetalLight"
		lm.box(mat, Vector3(lx, 22.4, z1 + 0.32), Vector3(0.32, 36.2, 0.45))
		lm.box(mat, Vector3(lx, 22.4, z0 - 0.32), Vector3(0.32, 36.2, 0.45))
	# Rooftop mechanical penthouse reaching 44.5 m.
	LandmarkFrKit.rect(lm, "MetalLight", x0 + 8.0, x1 - 8.0, z0 + 7.0, z1 - 7.0, 41.2, 44.5)
	LandmarkFrKit.rect(lm, "MetalDark", x0 + 8.4, x1 - 8.4, z0 + 7.4, z1 - 7.4, 44.3, 44.65)

static func _build_curved_clinical_wing(lm: LandmarkMesh, sky: SkyKit) -> void:
	# Main 7-storey clinical wing (2003-2013, H = 29.9 m) with curved south facade.
	LandmarkFrKit.rect(lm, "Concrete", -44.0, 42.0, -8.0, 26.0, FOUND, 3.6)
	_sky_box(lm, sky, -42.0, 40.0, -6.0, 22.0, 3.6, 26.8, 22, 8)
	# Gently curved 5-segment projecting clinical bow along +Z (Savitehtaankatu front).
	var segs := 5
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var x0 := lerpf(-38.0, 36.0, t0)
		var x1 := lerpf(-38.0, 36.0, t1)
		var mid := (t0 + t1) * 0.5
		var bulge := sin(mid * PI) * 7.5
		var z_front := 22.0 + bulge
		_sky_box(lm, sky, x0, x1, 20.0, z_front, 3.6, 26.8, 4, 2)
		# Vertical sun-shading louver fins on the curved clinical bow.
		for k in 4:
			var lx := lerpf(x0 + 1.4, x1 - 1.4, float(k) / 3.0)
			lm.box("MetalLight", Vector3(lx, 15.2, z_front + 0.35), Vector3(0.28, 22.8, 0.55))
	# Low sloped metal roof over main clinical wing (26.8 -> 29.9 m).
	LandmarkFrKit.gable(lm, "MetalLight", -42.0, 40.0, -6.0, 24.0, 26.8, 3.1, 0.45, "MetalLight", 1)
	# Coloured teal accent stair cores on east & west ends.
	LandmarkFrKit.rect(lm, "AccentTeal", -44.5, -41.5, 4.0, 14.0, 3.6, 28.2)
	LandmarkFrKit.rect(lm, "AccentTeal", 39.5, 42.5, 4.0, 14.0, 3.6, 28.2)

static func _build_main_atrium_and_emergency(lm: LandmarkMesh) -> void:
	# Soaring Main Entrance Glass Atrium (y = 0..22 m) on south forecourt (+Z).
	LandmarkFrKit.rect(lm, "Concrete", -16.0, 16.0, 26.0, 38.0, FOUND, 0.4)
	LandmarkFrKit.rect(lm, "Glass", -12.5, 12.5, 25.5, 34.5, 0.4, 21.5)
	LandmarkFrKit.rect(lm, "MetalLight", -13.0, 13.0, 25.0, 35.0, 21.3, 22.4)
	# Warm illuminated atrium interior glow at night.
	lm.box("Lamp", Vector3(0.0, 9.5, 29.8), Vector3(22.0, 16.0, 6.2))
	# Structural steel atrium mullions.
	for i in 7:
		var mx := lerpf(-12.0, 12.0, float(i) / 6.0)
		lm.box("MetalDark", Vector3(mx, 11.0, 34.6), Vector3(0.26, 21.2, 0.32))
	# Cantilevered steel-and-glass main entrance drop-off canopy.
	LandmarkFrKit.rect(lm, "MetalLight", -15.5, 15.5, 34.5, 42.5, 4.6, 5.15)
	LandmarkFrKit.rect(lm, "Glass", -14.5, 14.5, 35.0, 42.0, 4.55, 5.2)
	for cx: float in [-13.0, -4.5, 4.5, 13.0]:
		lm.frustum("MetalDark", Vector3(cx, 0.0, 41.2), 0.24, 0.24, 4.7, 8)
	lm.box("Lamp", Vector3(0.0, 4.52, 38.5), Vector3(26.0, 0.10, 0.55))
	# Dedicated Emergency / Ambulance Bay (Päivystys) on the SW flank (-X / +Z).
	LandmarkFrKit.rect(lm, "Concrete", -56.0, -41.0, 12.0, 30.0, FOUND, 0.35)
	LandmarkFrKit.rect(lm, "MetalLight", -55.0, -41.5, 13.5, 29.0, 4.8, 5.6)
	LandmarkFrKit.rect(lm, "EmergencyRed", -55.4, -41.2, 28.6, 29.3, 4.85, 5.65)
	LandmarkFrKit.rect(lm, "EmergencyRed", -55.4, -54.7, 13.5, 29.3, 4.85, 5.65)
	for ez: float in [15.0, 21.5, 28.0]:
		lm.frustum("MetalDark", Vector3(-54.0, 0.0, ez), 0.26, 0.26, 4.9, 8)
	lm.box("Lamp", Vector3(-48.5, 4.72, 21.2), Vector3(11.0, 0.12, 12.0))

static func _build_skybridges(lm: LandmarkMesh) -> void:
	# East glazed skybridge stub linking toward Majakkasairaala (+X).
	LandmarkFrKit.rect(lm, "MetalDark", 40.0, 72.0, 4.0, 9.6, 13.8, 14.3)
	LandmarkFrKit.rect(lm, "MetalLight", 40.0, 72.0, 3.9, 9.7, 17.3, 17.9)
	LandmarkFrKit.rect(lm, "Glass", 40.0, 71.5, 4.15, 9.45, 14.3, 17.3)
	lm.box("Lamp", Vector3(56.0, 15.8, 6.8), Vector3(30.0, 1.1, 3.2))
	# SW enclosed skybridge linking toward Medisiina D (-X / +Z).
	LandmarkFrKit.rect(lm, "MetalDark", -42.0, -36.8, 24.0, 56.0, 11.2, 11.7)
	LandmarkFrKit.rect(lm, "MetalLight", -42.1, -36.7, 24.0, 56.0, 14.5, 15.0)
	LandmarkFrKit.rect(lm, "Glass", -41.8, -37.0, 24.2, 55.8, 11.7, 14.5)
	lm.box("Lamp", Vector3(-39.4, 13.1, 40.0), Vector3(3.0, 1.0, 30.0))
	lm.frustum("Concrete", Vector3(-39.4, FOUND, 44.0), 0.65, 0.65, 11.5 - FOUND, 10)

static func _build_parking_garage(model: Node3D, base_lm: LandmarkMesh) -> void:
	# T-sairaalan pysäköintitalo (6-storey open-deck concrete parking garage).
	var lm := LandmarkMesh.new()
	for k: String in ["Concrete", "MetalLight", "MetalDark", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# 6 stacked parking decks (48 x 32 m, H = 18.8 m) with open ventilation gaps.
	LandmarkFrKit.rect(lm, "Concrete", -24.0, 24.0, -16.0, 16.0, FOUND, 0.5)
	for lv in 6:
		var y := 0.5 + float(lv) * 3.05
		LandmarkFrKit.rect(lm, "Concrete", -24.0, 24.0, -16.0, 16.0, y, y + 1.15)
	# Exterior perimeter columns & vertical metal screening slats.
	for i in 11:
		var cx := lerpf(-23.5, 23.5, float(i) / 10.0)
		lm.box("MetalLight", Vector3(cx, 9.6, 16.15), Vector3(0.42, 18.6, 0.35))
		lm.box("MetalLight", Vector3(cx, 9.6, -16.15), Vector3(0.42, 18.6, 0.35))
	for i in 7:
		var cz := lerpf(-15.5, 15.5, float(i) / 6.0)
		lm.box("MetalLight", Vector3(-24.15, 9.6, cz), Vector3(0.35, 18.6, 0.42))
		lm.box("MetalLight", Vector3(24.15, 9.6, cz), Vector3(0.35, 18.6, 0.42))
	# Helical cylindrical ramp drum on SW corner & glazed stair/lift core.
	lm.frustum("Concrete", Vector3(-24.0, FOUND, 14.0), 6.2, 6.2, 19.2 - FOUND, 16)
	LandmarkFrKit.rect(lm, "Glass", 20.0, 25.0, 10.0, 16.8, 0.4, 21.4)
	LandmarkFrKit.rect(lm, "MetalDark", 19.8, 25.2, 9.8, 17.0, 21.2, 21.8)
	var child := Node3D.new()
	child.name = "ParkingGarage"
	child.position = Vector3(-66.0, 0.0, -22.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _sky_box(lm: LandmarkMesh, sky: SkyKit, x0: float, x1: float,
		z0: float, z1: float, y0: float, y1: float, bx: int, bz: int) -> void:
	LandmarkFrKit.rect(lm, "MetalLight", x0 + 0.15, x1 - 0.15, z0 + 0.15, z1 - 0.15, y1 - 0.5, y1)
	LandmarkFrKit.rect(lm, "MetalDark", x0 + 0.4, x1 - 0.4, z0 + 0.4, z1 - 0.4, y0, y1 - 0.4)
	sky.face("WallLit", Vector2(x0, z1), Vector2(x1, z1), y0, y1 - 0.35, Vector3.BACK, bx)
	sky.face("WallLit", Vector2(x1, z0), Vector2(x0, z0), y0, y1 - 0.35, Vector3.FORWARD, bx)
	sky.face("WallLit", Vector2(x1, z1), Vector2(x1, z0), y0, y1 - 0.35, Vector3.RIGHT, bz)
	sky.face("WallLit", Vector2(x0, z0), Vector2(x0, z1), y0, y1 - 0.35, Vector3.LEFT, bz)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 48.0), Vector3(0.0, 16.0, 32.0), 62.0, 0.95, 50.0, Color(1.0, 0.92, 0.78)],
		[Vector3(-56.0, 3.0, 36.0), Vector3(-48.0, 8.0, 22.0), 56.0, 0.85, 36.0, Color(1.0, 0.88, 0.76)],
		[Vector3(44.0, 3.0, 10.0), Vector3(38.0, 28.0, -16.0), 58.0, 0.70, 52.0, Color(0.92, 0.96, 1.0)],
	])
