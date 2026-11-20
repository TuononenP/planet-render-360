class_name FtUtuMainCampus
extends RefCounted

## University of Turku Main Hill (Yliopistonmäki, 1954–59, Aarne Ervi)
## — celebrated Finnish modernist acropolis around the central stone plaza
## in true metres (+X ENE along hill ridge, +Z SSE toward Hämeenkatu, turned
## by registry yaw_deg = -23.8°):
##   1. Main Building (Päärakennus, OSM way:34025118, 42.3 x 43.6 m, 4 lv,
##      H = 14.5 m) at (0, 0): crisp white/cream travertine & concrete slab
##      elevated on a tall glazed/pilotis ground floor, overhanging flat
##      cornice, rhythmic horizontal strip windows, and the iconic projecting
##      semicircular lecture auditorium drum (Luentosali I) on the flank.
##   2. Central Stone Plaza (Yliopistonmäen aukio) with stepped granite
##      terraces, dark-granite rectangular reflecting pool (Vesialtaat), and
##      Wäinö Aaltonen's bronze Genius Montis sculpture on a granite plinth.
##   3. Feeniks Library (OSM way:34025081, 61.6 x 22.4 m, 4 lv, H = 15.2 m,
##      SEAT_META child at (-54, 0, -48)): Ervi's white travertine reading
##      cube hovering over a recessed continuous glazed ground floor with
##      warm interior reading-room glow at night.
##   4. Natura (OSM way:28173749, SEAT_META child at (-12, 0, -98)): long
##      modernist brick-and-concrete natural sciences wing (116 x 24 m,
##      H = 14.8 m) framing the northern edge of Yliopistonmäki plaza.
## Surfaces: 15 merged PBR parts (8 Main+Plaza + 4 Feeniks + 3 Natura).

const FOUND := -3.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_main_building(lm)
	_build_plaza_and_pool(lm)
	lm.commit(model)
	_build_feeniks_library(model, lm)
	_build_natura(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Travertine", LandmarkMaterials.pbr("stone", "#E6E1D5", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7C7974", 2.6))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2A2F34", 0.45, 0.55))
	lm.use("Bronze", LandmarkMaterials.paint("#4B4439", 0.36, 0.72))
	lm.use("Water", LandmarkMaterials.pool_water("#244454"))
	lm.use("Glass", LandmarkMaterials.glass("#22323E"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFECC2", 1.5))

static func _build_main_building(lm: LandmarkMesh) -> void:
	# Stepped granite hill podium & open pilotis colonnade (y = 0..4.4 m).
	LandmarkFrKit.rect(lm, "Granite", -24.0, 24.0, -24.0, 24.0, FOUND, 0.6)
	# Recessed glazed foyer core behind Ervi's pilotis columns.
	LandmarkFrKit.rect(lm, "Glass", -18.5, 18.5, -16.5, 16.5, 0.6, 4.5)
	lm.box("Lamp", Vector3(0.0, 2.6, 0.0), Vector3(32.0, 2.8, 28.0))
	for ix in 7:
		var px := lerpf(-20.0, 20.0, float(ix) / 6.0)
		for pz: float in [-20.0, 20.0]:
			lm.frustum("Travertine", Vector3(px, 0.6, pz), 0.34, 0.34, 4.0, 10)
	for iz in 5:
		var pz := lerpf(-13.5, 13.5, float(iz) / 4.0)
		for px: float in [-20.0, 20.0]:
			lm.frustum("Travertine", Vector3(px, 0.6, pz), 0.34, 0.34, 4.0, 10)
	# Hovering 3-storey white travertine upper main block (42 x 42 m, y = 4.5..14.5 m).
	LandmarkFrKit.rect(lm, "Travertine", -21.0, 21.0, -21.0, 21.0, 4.5, 14.5)
	# Crisp thin cantilevered roof overhang fascia (Ervi signature).
	LandmarkFrParts.band(lm, "Travertine", -21.0, 21.0, -21.0, 21.0, 14.1, 0.45, 0.65)
	# Continuous horizontal strip windows on upper 3 storeys (all 4 sides).
	for lv in 3:
		var wy := 5.4 + float(lv) * 2.95
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -19.6, 19.6, sz * 21.0 - 0.14, sz * 21.0 + 0.14, wy, wy + 1.55)
			for k in 15:
				var mx := lerpf(-19.2, 19.2, float(k) / 14.0)
				lm.box("DarkMetal", Vector3(mx, wy + 0.78, sz * 21.12), Vector3(0.14, 1.6, 0.12))
		for sx: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", sx * 21.0 - 0.14, sx * 21.0 + 0.14, -19.6, 19.6, wy, wy + 1.55)
	# Iconic projecting semicircular lecture auditorium drum (Luentosali I) on +X/-Z corner.
	lm.frustum("Travertine", Vector3(21.0, 4.2, -5.0), 10.5, 10.5, 9.6, 18)
	lm.frustum("Travertine", Vector3(21.0, 13.7, -5.0), 11.1, 11.1, 0.45, 18)
	# Vertical travertine ribs around the semicircular auditorium drum.
	for i in 10:
		var a := -PI * 0.45 + PI * 0.9 * float(i) / 9.0
		lm.box("Travertine", Vector3(21.0 + cos(a) * 10.65, 9.0, -5.0 + sin(a) * 10.65),
			Vector3(0.35, 9.5, 0.35), Basis(Vector3.UP, -a))
	# Pilotis columns supporting the cantilevered semicircular auditorium.
	for i in 5:
		var a := -PI * 0.38 + PI * 0.76 * float(i) / 4.0
		lm.frustum("Travertine", Vector3(21.0 + cos(a) * 9.2, FOUND, -5.0 + sin(a) * 9.2),
			0.35, 0.35, 4.3 - FOUND, 10)

static func _build_plaza_and_pool(lm: LandmarkMesh) -> void:
	# Central granite-paved Yliopistonmäki plaza extending -Z toward Feeniks & Natura.
	LandmarkFrKit.rect(lm, "Granite", -36.0, 26.0, -64.0, -24.0, FOUND, 0.32)
	# Rectangular granite-rimmed reflecting pool (Vesialtaat).
	LandmarkFrKit.rect(lm, "Granite", -20.0, 6.0, -52.0, -34.0, 0.25, 0.62)
	LandmarkFrKit.rect(lm, "Water", -19.2, 5.2, -51.2, -34.8, 0.32, 0.56)
	# Wäinö Aaltonen's bronze Genius Montis sculpture on granite plinth beside the pool.
	LandmarkFrKit.rect(lm, "Granite", 10.0, 13.2, -46.0, -42.8, 0.32, 2.2)
	lm.frustum("Bronze", Vector3(11.6, 2.2, -44.4), 0.75, 0.45, 2.8, 10)
	lm.lathe("Bronze", Vector3(11.6, 5.2, -44.4), PackedVector2Array([Vector2(0.42, 0.0), Vector2(0.42 * 0.85, 0.42 * 0.52), Vector2(0.42 * 0.48, 0.42 * 0.86), Vector2(0.05, 0.42)]), 8)
	# Low modernist plaza lantern bollards.
	for lx: float in [-26.0, -10.0, 8.0, 20.0]:
		lm.frustum("DarkMetal", Vector3(lx, 0.32, -30.0), 0.12, 0.12, 2.6, 8)
		lm.box("Lamp", Vector3(lx, 3.0, -30.0), Vector3(0.45, 0.22, 0.45))

## Feeniks Library (1954, Aarne Ervi) — white travertine reading cube on glazed ground floor.
static func _build_feeniks_library(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["Travertine", "DarkMetal", "Glass", "Lamp"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# 60 x 22 m reading block: recessed glazed ground floor + hovering travertine cube.
	LandmarkFrKit.rect(lm, "Glass", -28.0, 28.0, -9.5, 9.5, FOUND, 4.4)
	lm.box("Lamp", Vector3(0.0, 2.4, 0.0), Vector3(50.0, 2.8, 15.0))
	for i in 11:
		var px := lerpf(-29.0, 29.0, float(i) / 10.0)
		lm.frustum("DarkMetal", Vector3(px, 0.0, 10.4), 0.24, 0.24, 4.4, 8)
		lm.frustum("DarkMetal", Vector3(px, 0.0, -10.4), 0.24, 0.24, 4.4, 8)
	LandmarkFrKit.rect(lm, "Travertine", -30.5, 30.5, -11.2, 11.2, 4.4, 14.8)
	LandmarkFrParts.band(lm, "Travertine", -30.5, 30.5, -11.2, 11.2, 14.4, 0.42, 0.55)
	# Tall vertical reading-hall window bays on upper library floors.
	for lv in 2:
		var wy := 5.6 + float(lv) * 4.2
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -28.8, 28.8, sz * 11.2 - 0.14, sz * 11.2 + 0.14, wy, wy + 2.4)
	var child := Node3D.new()
	child.name = "FeeniksLibrary"
	child.position = Vector3(-52.0, 0.0, -48.0)
	child.rotation.y = deg_to_rad(90.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## Natura (OSM way:28173749) — long modernist natural sciences wing framing north plaza edge.
static func _build_natura(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B9A589", 2.6))
	lm.use("Travertine", (base_lm._surfs["Travertine"] as LandmarkMesh.Surf).mat)
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "Brick", -58.0, 58.0, -12.0, 12.0, FOUND, 14.6)
	LandmarkFrParts.band(lm, "Travertine", -58.0, 58.0, -12.0, 12.0, 14.1, 0.5, 0.45)
	for lv in 4:
		var wy := 1.6 + float(lv) * 3.1
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -55.5, 55.5, sz * 12.0 - 0.14, sz * 12.0 + 0.14, wy, wy + 1.6)
	var child := Node3D.new()
	child.name = "Natura"
	child.position = Vector3(-16.0, 0.0, -96.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, -34.0), Vector3(0.0, 9.0, -20.0), 62.0, 0.90, 44.0, Color(1.0, 0.90, 0.72)],
		[Vector3(34.0, 2.0, -14.0), Vector3(24.0, 9.0, -5.0), 54.0, 0.75, 36.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-36.0, 2.0, -48.0), Vector3(-50.0, 9.0, -48.0), 58.0, 0.70, 40.0, Color(1.0, 0.90, 0.72)],
	])
