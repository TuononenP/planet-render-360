class_name FtIntelligateIctKupittaa
extends RefCounted

## Kupittaa Station Business & Tech Precinct — Intelligate I–III Office Towers,
## ICT-City & Original Sokos Hotel Kupittaa along Joukahaisenkatu, in true
## metres (+X ENE toward railway/Itäharju, +Z SSE toward Kupittaanpuisto,
## turned by registry yaw_deg = -34.0°; `skyline: true`):
##   1. Intelligate I–III (turku_lod2 102217649H H = 45.2 m, 103650280D
##      H = 39.9 m, 103585115A H = 31.6 m): three sleek glass-and-steel
##      contemporary office towers flanking Kupittaa Station (9–11 storeys,
##      SkyKit reflective curtain walls with crisp silver/dark-steel floor
##      fins, glazed sky-lobbies, and glowing rooftop crown bands).
##   2. ICT-City (turku_lod2 1034543846: area 9,879 m², 6 storeys, H = 30.8 m,
##      SEAT_META child at (-36, 0, +18)): expansive red-brick & glass
##      university/tech courtyard block with central glazed atrium & horizontal
##      sunscreen louvers.
##   3. Original Sokos Hotel Kupittaa (turku_lod2 103454371S: 7–8 storeys,
##      H = 31.6 m, SEAT_META child at (-88, 0, +68)): crisp light-stone &
##      glass modern hotel block with illuminated rooftop lounge crown &
##      cantilevered Joukahaisenkatu entrance canopy.
## Surfaces: 14 merged PBR parts (7 Intelligate + 4 ICT-City + 3 Sokos Hotel).

const FOUND := -2.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sky := SkyKit.new(lm)
	_materials(lm, sky)
	_build_intelligate_towers(lm, sky)
	lm.commit(model)
	_build_ict_city(model, lm)
	_build_sokos_hotel(model, lm)
	_set_night_lights(model)

static func _materials(lm: LandmarkMesh, sky: SkyKit) -> void:
	lm.use("LightMetal", LandmarkMaterials.pbr("sheet_metal", "#DCE2E6", 2.8, 0.36, 0.35))
	lm.use("DarkSteel", LandmarkMaterials.paint("#282F37", 0.40, 0.62))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C2C0B8", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#223A4B"))
	sky.wall("CurtainBlue", "steel_panel", 3.2, 3.8)
	sky.wall("CurtainLight", "white_panel", 3.2, 3.8)
	lm.use("Lamp", LandmarkMaterials.lit("#FFF0CE", 1.65))

static func _build_intelligate_towers(lm: LandmarkMesh, sky: SkyKit) -> void:
	# Shared 2-storey podium plaza & retail concourse along Joukahaisenkatu.
	LandmarkFrKit.rect(lm, "Concrete", -46.0, 48.0, -54.0, 56.0, FOUND, 0.45)
	# Intelligate II (tallest north tower, 38 x 28 m, H = 45.2 m matching LoD2 102217649H).
	_tower(lm, sky, -18.0, 20.0, -48.0, -20.0, 45.2, "CurtainBlue")
	# Intelligate I (central-south tower, 34 x 26 m, H = 39.9 m matching LoD2 103650280D).
	_tower(lm, sky, -14.0, 20.0, 12.0, 38.0, 39.9, "CurtainLight")
	# Intelligate III (east station-side tower, 28 x 24 m, H = 33.4 m).
	_tower(lm, sky, 16.0, 44.0, -16.0, 8.0, 33.4, "CurtainBlue")
	# Glazed 2-storey linking concourse & elevated skybridges between Intelligate I, II & III.
	LandmarkFrKit.rect(lm, "Glass", -10.0, 16.0, -20.0, 12.0, 0.45, 7.6)
	LandmarkFrKit.rect(lm, "LightMetal", -10.4, 16.4, -20.4, 12.4, 7.4, 8.1)
	lm.box("Lamp", Vector3(3.0, 4.0, -4.0), Vector3(22.0, 5.2, 26.0))
	# Elevated skybridge at level 4 linking Intelligate II and Intelligate III.
	LandmarkFrKit.rect(lm, "DarkSteel", 14.0, 24.0, -20.0, -14.0, 15.2, 15.7)
	LandmarkFrKit.rect(lm, "Glass", 14.2, 23.8, -19.8, -14.2, 15.7, 18.8)
	LandmarkFrKit.rect(lm, "LightMetal", 13.9, 24.1, -20.1, -13.9, 18.8, 19.3)

static func _tower(lm: LandmarkMesh, sky: SkyKit, x0: float, x1: float,
		z0: float, z1: float, h: float, wall_key: String) -> void:
	# Recessed double-height glazed lobby (y = 0.45..7.2 m).
	LandmarkFrKit.rect(lm, "Glass", x0 + 1.4, x1 - 1.4, z0 + 1.4, z1 - 1.4, 0.45, 7.2)
	lm.box("Lamp", Vector3((x0 + x1) * 0.5, 3.8, (z0 + z1) * 0.5),
		Vector3((x1 - x0) - 5.0, 4.8, (z1 - z0) - 5.0))
	# Perimeter steel lobby columns.
	for sx: float in [x0 + 0.8, (x0 + x1) * 0.5, x1 - 0.8]:
		for sz: float in [z0 + 0.8, z1 - 0.8]:
			lm.frustum("DarkSteel", Vector3(sx, 0.45, sz), 0.32, 0.32, 6.8, 8)
	# Sleek glass-and-steel office shaft (y = 7.2..h - 1.8 m).
	var shaft_top := h - 1.8
	LandmarkFrKit.rect(lm, "DarkSteel", x0 + 0.35, x1 - 0.35, z0 + 0.35, z1 - 0.35, 7.2, shaft_top)
	var bx := maxi(4, int((x1 - x0) / 3.2))
	var bz := maxi(4, int((z1 - z0) / 3.2))
	sky.face(wall_key, Vector2(x0, z1), Vector2(x1, z1), 7.2, shaft_top, Vector3.BACK, bx)
	sky.face(wall_key, Vector2(x1, z0), Vector2(x0, z0), 7.2, shaft_top, Vector3.FORWARD, bx)
	sky.face(wall_key, Vector2(x1, z1), Vector2(x1, z0), 7.2, shaft_top, Vector3.RIGHT, bz)
	sky.face(wall_key, Vector2(x0, z0), Vector2(x0, z1), 7.2, shaft_top, Vector3.LEFT, bz)
	# Crisp horizontal aluminum spandrel fins & glowing crown band.
	var fy := 11.0
	while fy < shaft_top - 1.0:
		LandmarkFrParts.band(lm, "LightMetal", x0, x1, z0, z1, fy, 0.35, 0.22)
		fy += 3.8
	LandmarkFrParts.band(lm, "LightMetal", x0, x1, z0, z1, shaft_top - 0.5, 0.75, 0.30)
	# Rooftop illuminated crown glass fascia & mechanical penthouse reaching exact h.
	LandmarkFrKit.rect(lm, "DarkSteel", x0 + 2.2, x1 - 2.2, z0 + 2.2, z1 - 2.2, shaft_top, h)
	LandmarkFrParts.band(lm, "Lamp", x0 + 2.2, x1 - 2.2, z0 + 2.2, z1 - 2.2, h - 0.65, 0.32, 0.12)

## ICT-City (turku_lod2 1034543846, 6 storeys, H = 30.8 m) — brick/glass courtyard tech block.
static func _build_ict_city(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A25842", 2.4))
	lm.use("LightMetal", (base_lm._surfs["LightMetal"] as LandmarkMesh.Surf).mat)
	lm.use("DarkSteel", (base_lm._surfs["DarkSteel"] as LandmarkMesh.Surf).mat)
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	# U-shaped 6-storey brick & glass block (78 x 54 m, H = 30.8 m) around glazed central courtyard.
	LandmarkFrKit.rect(lm, "Brick", -39.0, 39.0, -27.0, -9.0, FOUND, 28.8)
	LandmarkFrKit.rect(lm, "Brick", -39.0, 39.0, 9.0, 27.0, FOUND, 28.8)
	LandmarkFrKit.rect(lm, "Brick", -39.0, -19.0, -9.0, 9.0, FOUND, 28.8)
	LandmarkFrKit.rect(lm, "Glass", -19.0, 37.0, -9.2, 9.2, 0.0, 26.8)
	LandmarkFrKit.rect(lm, "LightMetal", -19.4, 37.4, -9.6, 9.6, 26.6, 27.2)
	# Rooftop mechanical penthouse reaching 30.8 m.
	LandmarkFrKit.rect(lm, "LightMetal", -28.0, 28.0, -22.0, -13.0, 28.8, 30.8)
	# Horizontal ribbon windows along north & south brick facades.
	for lv in 6:
		var wy := 1.6 + float(lv) * 4.25
		LandmarkFrKit.rect(lm, "Glass", -37.0, 37.0, -27.14, -26.86, wy, wy + 2.1)
		LandmarkFrKit.rect(lm, "Glass", -37.0, 37.0, 26.86, 27.14, wy, wy + 2.1)
	var child := Node3D.new()
	child.name = "IctCity"
	child.position = Vector3(-48.0, 0.0, 14.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## Original Sokos Hotel Kupittaa (7-8 storeys, H = 31.6 m) — light-stone & glass hotel.
static func _build_sokos_hotel(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("LightStone", LandmarkMaterials.pbr("stone", "#E2DDD2", 3.0))
	lm.use("DarkSteel", (base_lm._surfs["DarkSteel"] as LandmarkMesh.Surf).mat)
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "LightStone", -32.0, 32.0, -15.0, 15.0, FOUND, 28.6)
	# Recessed rooftop Bistro Elli / sky-lounge pavilion reaching 31.6 m.
	LandmarkFrKit.rect(lm, "Glass", -20.0, 20.0, -10.0, 10.0, 28.6, 31.2)
	LandmarkFrKit.rect(lm, "DarkSteel", -20.5, 20.5, -10.5, 10.5, 31.1, 31.6)
	for lv in 7:
		var wy := 1.8 + float(lv) * 3.65
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -30.0, 30.0, sz * 15.0 - 0.14, sz * 15.0 + 0.14, wy, wy + 1.9)
	LandmarkFrKit.rect(lm, "DarkSteel", -10.0, 10.0, -19.5, -15.0, 4.2, 4.7)
	var child := Node3D.new()
	child.name = "SokosHotelKupittaa"
	child.position = Vector3(-86.0, 0.0, 66.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_lights(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 3.0, -60.0), Vector3(1.0, 30.0, -34.0), 58.0, 0.85, 56.0, Color(0.92, 0.96, 1.0)],
		[Vector3(0.0, 3.0, 52.0), Vector3(3.0, 26.0, 25.0), 58.0, 0.80, 52.0, Color(0.92, 0.96, 1.0)],
	])
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(1.0, 45.4, -34.0), 3.6, Color(1.0, 0.92, 0.72)],
		[Vector3(3.0, 40.1, 25.0), 3.0, Color(1.0, 0.92, 0.72)],
	])
