class_name FtTyksKantasairaalaPavilions
extends RefCounted

## Historic TYKS Kantasairaala Pavilions (Kiinamyllynkatu / Kunnallissairaalantie)
## — surviving red-brick, ochre-render & modernist hospital pavilions seated
## across the sloped medical hill via LandmarkTerrain.SEAT_META, in true metres
## (+X ENE, +Z SSE, turned by registry yaw_deg = -34.0°):
##   1. Hallintorakennus (Admin Pavilion, central at (0, 0), turku_lod2
##      103436144T area 1,247 m², 3 storeys, H = 20.6 m): classicist ochre-
##      rendered 3-storey pavilion (46 x 18 m) on rough grey granite plinth,
##      central pedimented entrance risalit, steep gabled terracotta roof with
##      dormers, copper ridge ventilator & brick chimneys.
##   2. Vanha lastenklinikka (Old Children's Clinic, SEAT_META child at
##      (+34, 0, -34), turku_lod2 103828158D 19.2 m): historic red-brick
##      3-storey pavilion (38 x 16 m, H = 19.2 m) with cream render quoins &
##      window frames, arched granite portal, and hipped slate roof.
##   3. Mikro (Microbiology Institute, SEAT_META child at (-36, 0, -24)):
##      mid-century red-brick & pale-concrete laboratory pavilion (36 x 16 m,
##      H = 15.8 m) with rhythmic lab window bays & rooftop penthouses.
##   4. Rakennus 14 (SEAT_META child at (-32, 0, +34)): historic ochre-plaster
##      2-storey ward pavilion (32 x 15 m, H = 14.2 m) with gabled roof,
##      courtyard granite wall, service lane bollards & emergency wayfinding.
## Surfaces: 16 merged PBR parts (6 Hallinto + 4 Lastenklinikka + 3 Mikro + 3 R14).

const FOUND := -3.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_hallintorakennus(lm)
	_build_courtyard_lane(lm)
	lm.commit(model)
	_build_vanha_lastenklinikka(model, lm)
	_build_mikro(model, lm)
	_build_rakennus_14(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7F7A72", 2.4))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#DEC288", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F0EAE0", 3.0))
	lm.use("RoofRed", LandmarkMaterials.pbr("terracotta", "#864636", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#202B32"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8B8", 1.45))

static func _build_hallintorakennus(lm: LandmarkMesh) -> void:
	# 3-storey classicist ochre-render pavilion (46 x 18 m, eaves 13.8 m, ridge 20.6 m).
	LandmarkFrKit.rect(lm, "Granite", -23.5, 23.5, -9.5, 9.5, FOUND, 2.1)
	LandmarkFrKit.rect(lm, "Ochre", -23.0, 23.0, -9.0, 9.0, 2.1, 13.8)
	LandmarkFrParts.band(lm, "Trim", -23.0, 23.0, -9.0, 9.0, 2.05, 0.34, 0.16)
	LandmarkFrParts.band(lm, "Trim", -23.0, 23.0, -9.0, 9.0, 6.2, 0.26, 0.12)
	LandmarkFrParts.cornice_ring(lm, "Trim", -23.0, 23.0, -9.0, 9.0, 13.25, 0.58)
	# Steep gabled terracotta roof (13.8 -> 19.6 m) + ridge lantern reaching 20.6 m.
	LandmarkFrKit.gable(lm, "RoofRed", -23.0, 23.0, -9.0, 9.0, 13.8, 5.8, 0.55, "Ochre", 1)
	lm.frustum("Trim", Vector3(0.0, 19.1, 0.0), 1.1, 1.0, 0.9, 8, PI / 8.0)
	lm.lathe("RoofRed", Vector3(0.0, 20.0, 0.0), PackedVector2Array([
		Vector2(1.25, 0.0), Vector2(0.06, 0.65)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Brick/ochre chimneys along ridge.
	for cx: float in [-13.5, 13.5]:
		LandmarkFrKit.rect(lm, "Ochre", cx - 0.65, cx + 0.65, -0.65, 0.65, 17.0, 20.4)
		LandmarkFrKit.rect(lm, "Trim", cx - 0.8, cx + 0.8, -0.8, 0.8, 20.25, 20.55)
	# Central projecting pedimented entrance risalit on +Z front.
	LandmarkFrKit.rect(lm, "Granite", -6.4, 6.4, 8.8, 11.4, FOUND, 2.1)
	LandmarkFrKit.rect(lm, "Ochre", -6.2, 6.2, 8.8, 11.2, 2.1, 14.0)
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(0.0, 14.0, 11.25), Vector3.RIGHT, Vector3.BACK, 12.6, 3.2, 0.45)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(0.0, 2.1, 11.2), Vector3.BACK, 2.8, 3.8,
		LandmarkFrParts.HEAD_ROUND, 0.34, 0.22, 1)
	# Granite entrance steps & lantern pair.
	LandmarkFrKit.rect(lm, "Granite", -4.4, 4.4, 11.2, 13.2, FOUND, 1.1)
	LandmarkFrKit.rect(lm, "Granite", -4.8, 4.8, 13.2, 14.4, FOUND, 0.55)
	for lx: float in [-2.4, 2.4]:
		lm.box("Lamp", Vector3(lx, 3.8, 11.55), Vector3(0.24, 0.38, 0.24))
	# Rhythmic 3-storey classicist windows on +Z and -Z facades.
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var spans := [[-20.8, -7.8], [7.8, 20.8]] if sz > 0.0 else [[-20.8, 20.8]]
		for sp: Array in spans:
			var bays := 4 if sz > 0.0 else 11
			LandmarkFrParts.facade(lm, "Trim", "Glass", Vector3(float(sp[0]), 2.6, sz * 9.0),
				Vector3(float(sp[1]), 2.6, sz * 9.0), n, 10.2, bays, 3, Vector2(1.2, 1.9), 0.75, 3.45, 0.20)

static func _build_courtyard_lane(lm: LandmarkMesh) -> void:
	# Low granite hospital courtyard retaining wall & illuminated wayfinding bollards.
	LandmarkFrKit.rect(lm, "Granite", -28.0, 28.0, 19.0, 19.8, FOUND, 0.95)
	for bx: float in [-22.0, -8.0, 8.0, 22.0]:
		lm.frustum("Granite", Vector3(bx, 0.0, 18.2), 0.14, 0.14, 1.05, 8)
		lm.box("Lamp", Vector3(bx, 1.12, 18.2), Vector3(0.22, 0.24, 0.22))

## Vanha lastenklinikka (Old Children's Clinic) — historic red-brick 3-storey pavilion.
static func _build_vanha_lastenklinikka(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#984735", 2.4))
	lm.use("Trim", (base_lm._surfs["Trim"] as LandmarkMesh.Surf).mat)
	lm.use("RoofSlate", LandmarkMaterials.pbr("slate", "#3A3F44", 2.2))
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "Brick", -19.0, 19.0, -8.0, 8.0, FOUND, 13.8)
	LandmarkFrParts.band(lm, "Trim", -19.0, 19.0, -8.0, 8.0, 2.2, 0.34, 0.15)
	LandmarkFrParts.cornice_ring(lm, "Trim", -19.0, 19.0, -8.0, 8.0, 13.25, 0.55)
	LandmarkFrKit.hip(lm, "RoofSlate", -19.0, 19.0, -8.0, 8.0, 13.8, 5.4, 0.55)
	# Central arched entrance porch & 3-storey rhythmic windows.
	LandmarkFrKit.rect(lm, "Brick", -4.8, 4.8, 8.0, 10.6, FOUND, 6.2)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(0.0, 1.4, 10.6), Vector3.BACK, 2.6, 3.8,
		LandmarkFrParts.HEAD_ROUND, 0.32, 0.20, 1)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.facade(lm, "Trim", "Glass", Vector3(-16.8, 2.8, sz * 8.0),
			Vector3(16.8, 2.8, sz * 8.0), Vector3(0, 0, sz), 10.0, 9, 3, Vector2(1.15, 1.85), 0.7, 3.4, 0.20)
	var child := Node3D.new()
	child.name = "VanhaLastenklinikka"
	child.position = Vector3(36.0, 0.0, -34.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## Mikro — mid-century red-brick & concrete microbiology pavilion.
static func _build_mikro(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9D543D", 2.4))
	lm.use("Concrete", (base_lm._surfs["Trim"] as LandmarkMesh.Surf).mat)
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "Brick", -18.0, 18.0, -8.0, 8.0, FOUND, 14.4)
	LandmarkFrParts.band(lm, "Concrete", -18.0, 18.0, -8.0, 8.0, 13.9, 0.52, 0.16)
	LandmarkFrKit.rect(lm, "Concrete", -11.0, 11.0, -4.5, 4.5, 14.4, 15.8)
	for lv in 3:
		var wy := 2.4 + float(lv) * 3.6
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -16.2, 16.2, sz * 8.0 - 0.14, sz * 8.0 + 0.14, wy, wy + 1.8)
	var child := Node3D.new()
	child.name = "Mikro"
	child.position = Vector3(-38.0, 0.0, -24.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## Rakennus 14 — historic 2-storey ochre-render ward pavilion with gabled roof.
static func _build_rakennus_14(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["Ochre", "RoofRed", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "Ochre", -16.0, 16.0, -7.5, 7.5, FOUND, 9.6)
	LandmarkFrKit.gable(lm, "RoofRed", -16.0, 16.0, -7.5, 7.5, 9.6, 4.6, 0.45, "Ochre", 1)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.facade(lm, "Ochre", "Glass", Vector3(-13.8, 2.0, sz * 7.5),
			Vector3(13.8, 2.0, sz * 7.5), Vector3(0, 0, sz), 7.0, 8, 2, Vector2(1.15, 1.85), 0.7, 3.4, 0.18)
	var child := Node3D.new()
	child.name = "Rakennus14"
	child.position = Vector3(-32.0, 0.0, 36.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 22.0), Vector3(0.0, 10.0, 11.0), 58.0, 0.85, 42.0, Color(1.0, 0.86, 0.64)],
		[Vector3(36.0, 2.0, -16.0), Vector3(36.0, 10.0, -34.0), 54.0, 0.65, 38.0, Color(1.0, 0.86, 0.64)],
	])
