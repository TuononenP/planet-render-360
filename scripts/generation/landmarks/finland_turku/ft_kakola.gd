class_name FtKakola
extends RefCounted

## Kakola Hilltop Prison Complex (Kakolanmäki, Turku) in true metres (+X ENE,
## +Z SSE, turned by registry yaw_deg = -32.0°; detached wings seated across
## the granite ridge via LandmarkTerrain.SEAT_META):
##   1. Main Granite Prison (1853, Ernst Lohrmann) at (0, 0): 68 x 18 m
##      4-storey rusticated grey/pink granite main wing (eaves 16.0 m, hipped
##      slate roof 21.6 m), central chapel/admin projection (20 x 22 m, eaves
##      18.0 m, hipped roof 23.0 m, ridge lantern 24.1 m), twin rear cross-
##      wings (+Z), Hotel Kakola forecourt entrance (-Z), and surviving
##      granite perimeter prison walls (H 4.6 m) with 4 corner watchtowers.
##   2. West Cellblock (Länsiselli, 1911) as SEAT_META child at (-58, -6):
##      20 x 44 m red-brick Jugendstil wing on granite plinth, shaped brick
##      gables, twin cylindrical corner stair turrets (22.0 m), cell windows.
##   3. Kakola Mental Hospital (Kakolan mielisairaala) as SEAT_META child at
##      (-42, +52) on the SW crag: castle-like polygonal grey-granite block
##      (32 x 24 m) with octagonal SW bastion tower (20.4 m) & hipped roofs.
## Surfaces: 14 merged PBR parts (6 main + 4 WestCellblock + 4 MentalHospital).

const FOUND := -3.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_main_prison(lm)
	_build_perimeter_walls(lm)
	lm.commit(model)
	_build_west_cellblock(model, lm)
	_build_mental_hospital(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#867F77", 2.4))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E4DEC9", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#373B40", 2.2))
	lm.use("Iron", LandmarkMaterials.paint("#24282C", 0.48, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#1E252A"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B8", 1.35))

static func _build_main_prison(lm: LandmarkMesh) -> void:
	# Long 4-storey Lohrmann granite cellblock (68 x 18 m, eaves 16.0 m, hipped roof 21.6 m).
	LandmarkFrKit.rect(lm, "Granite", -34.4, 34.4, -9.4, 9.4, FOUND, 2.4)
	LandmarkFrKit.rect(lm, "Granite", -34.0, 34.0, -9.0, 9.0, 2.4, 16.0)
	LandmarkFrParts.band(lm, "Trim", -34.0, 34.0, -9.0, 9.0, 2.35, 0.38, 0.16)
	LandmarkFrParts.cornice_ring(lm, "Trim", -34.0, 34.0, -9.0, 9.0, 15.35, 0.65)
	LandmarkFrKit.hip(lm, "Roof", -34.0, 34.0, -9.0, 9.0, 16.0, 5.6, 0.55)
	# Granite chimneys along the main wing ridge.
	for cx: float in [-24.0, -14.0, 14.0, 24.0]:
		LandmarkFrKit.rect(lm, "Granite", cx - 0.75, cx + 0.75, -0.75, 0.75, 19.5, 22.3)
		LandmarkFrKit.rect(lm, "Trim", cx - 0.9, cx + 0.9, -0.9, 0.9, 22.15, 22.45)
	# Central projecting chapel/admin pavilion (20 x 22 m, eaves 18.0 m, roof 23.0 m, cupola 24.1 m).
	LandmarkFrKit.rect(lm, "Granite", -10.2, 10.2, -11.2, 11.2, FOUND, 18.0)
	LandmarkFrParts.band(lm, "Trim", -10.2, 10.2, -11.2, 11.2, 2.35, 0.42, 0.16)
	LandmarkFrParts.band(lm, "Trim", -10.2, 10.2, -11.2, 11.2, 11.4, 0.35, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", -10.2, 10.2, -11.2, 11.2, 17.35, 0.65)
	LandmarkFrKit.hip(lm, "Roof", -10.2, 10.2, -11.2, 11.2, 18.0, 5.0, 0.55)
	# Central ridge cupola/ventilator reaching 24.1 m (matches registry height_m = 24.0).
	lm.frustum("Trim", Vector3(0.0, 22.6, 0.0), 1.4, 1.32, 0.95, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(0.0, 23.55, 0.0), PackedVector2Array([
		Vector2(1.55, 0.0), Vector2(0.08, 0.55)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Hotel Kakola arched granite entry portal (-Z forecourt) & tall arched chapel windows above.
	LandmarkFrKit.rect(lm, "Granite", -5.2, 5.2, -12.8, -11.2, FOUND, 1.0)
	LandmarkFrParts.opening(lm, "Trim", "Iron", Vector3(0.0, 1.0, -11.2), Vector3.FORWARD, 3.2, 4.2,
		LandmarkFrParts.HEAD_ROUND, 0.36, 0.22)
	for wx: float in [-5.6, -2.8, 0.0, 2.8, 5.6]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 12.2, -11.2), Vector3.FORWARD, 1.45, 3.8,
			LandmarkFrParts.HEAD_ROUND, 0.20, 0.14, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 12.2, 11.2), Vector3.BACK, 1.45, 3.8,
			LandmarkFrParts.HEAD_ROUND, 0.20, 0.14, 1)
	# Twin projecting rear cross-wings (+Z).
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 26.5 - 7.5
		var x1 := sx * 26.5 + 7.5
		LandmarkFrKit.rect(lm, "Granite", x0, x1, 9.0, 23.5, FOUND, 14.8)
		LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, 9.0, 23.5, 14.25, 0.55)
		LandmarkFrKit.hip(lm, "Roof", x0, x1, 9.0, 23.5, 14.8, 4.6, 0.50)
		LandmarkFrParts.facade(lm, "Granite", "Glass", Vector3(x0 + 1.2, 2.4, 23.5), Vector3(x1 - 1.2, 2.4, 23.5),
			Vector3.BACK, 11.4, 4, 3, Vector2(1.15, 1.8), 0.9, 3.6, 0.24)
	# Rhythmic barred cell-window grid along north (-Z) and south (+Z) flanks of main wing.
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for sp: Array in [[-32.5, -11.2], [11.2, 32.5]]:
			LandmarkFrParts.facade(lm, "Granite", "Glass", Vector3(float(sp[0]), 2.6, sz * 9.0),
				Vector3(float(sp[1]), 2.6, sz * 9.0), n, 12.2, 7, 3, Vector2(1.15, 1.85), 0.9, 3.85, 0.24)

static func _build_perimeter_walls(lm: LandmarkMesh) -> void:
	# Surviving high granite perimeter prison walls enclosing Hotel Kakola courtyard.
	var h := 4.6
	var t := 0.85
	# North wall (-Z = -29) split by arched prison gatehouse at x = 0.
	LandmarkFrKit.rect(lm, "Granite", -44.0, -5.5, -29.0 - t, -29.0, FOUND, h)
	LandmarkFrKit.rect(lm, "Granite", 5.5, 44.0, -29.0 - t, -29.0, FOUND, h)
	# Arched granite entrance gatehouse & courtyard lanterns.
	LandmarkFrKit.rect(lm, "Granite", -5.5, 5.5, -30.5, -28.0, FOUND, 6.4)
	LandmarkFrKit.hip(lm, "Roof", -5.5, 5.5, -30.5, -28.0, 6.4, 1.6, 0.35)
	LandmarkFrParts.opening(lm, "Trim", "Iron", Vector3(0.0, 0.0, -30.5), Vector3.FORWARD, 4.2, 4.4,
		LandmarkFrParts.HEAD_ROUND, 0.32, 0.20)
	for lx: float in [-4.0, 4.0]:
		lm.box("Iron", Vector3(lx, 3.2, -30.8), Vector3(0.24, 0.36, 0.42))
		lm.box("Lamp", Vector3(lx, 3.05, -30.92), Vector3(0.18, 0.28, 0.18))
	# East (+X = +44) and South (+Z = +32) surviving perimeter granite walls.
	LandmarkFrKit.rect(lm, "Granite", 44.0 - t, 44.0, -29.0, 32.0, FOUND, h)
	LandmarkFrKit.rect(lm, "Granite", -36.0, 44.0, 32.0 - t, 32.0, FOUND, h)
	LandmarkFrKit.rect(lm, "Granite", -44.0, -44.0 + t, -29.0, 12.0, FOUND, h)
	# Four cylindrical granite corner watchtowers with conical slate roofs.
	for pos: Array in [[-44.0, -29.0], [44.0, -29.0], [44.0, 32.0], [-36.0, 32.0]]:
		var tx: float = pos[0]
		var tz: float = pos[1]
		lm.frustum("Granite", Vector3(tx, FOUND, tz), 2.35, 2.25, 7.2 - FOUND, 10)
		lm.frustum("Trim", Vector3(tx, 6.95, tz), 2.45, 2.45, 0.35, 10)
		lm.lathe("Roof", Vector3(tx, 7.3, tz), PackedVector2Array([
			Vector2(2.65, 0.0), Vector2(0.08, 2.2)]), 10)

## 1911 Red-Brick West Cellblock (Länsiselli) with Jugend gables & corner turrets.
static func _build_west_cellblock(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#944533", 2.4))
	lm.use("Granite", (base_lm._surfs["Granite"] as LandmarkMesh.Surf).mat)
	lm.use("Roof", (base_lm._surfs["Roof"] as LandmarkMesh.Surf).mat)
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	# 20 x 44 m red-brick Jugend wing on rough granite plinth.
	LandmarkFrKit.rect(lm, "Granite", -10.4, 10.4, -22.4, 22.4, FOUND, 2.4)
	LandmarkFrKit.rect(lm, "Brick", -10.0, 10.0, -22.0, 22.0, 2.4, 15.2)
	LandmarkFrKit.gable(lm, "Roof", -10.0, 10.0, -22.0, 22.0, 15.2, 5.8, 0.55, "Brick", 0)
	# Shaped Jugend end gables on -Z and +Z fronts.
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Brick", -6.2, 6.2, sz * 22.0 - 0.5, sz * 22.0 + 0.5, 15.2, 18.8)
		LandmarkFrKit.rect(lm, "Brick", -3.4, 3.4, sz * 22.0 - 0.5, sz * 22.0 + 0.5, 18.8, 21.4)
		LandmarkFrParts.openings(lm, "Granite", "Glass", Vector3(-6.5, 3.6, sz * 22.0),
			Vector3(6.5, 3.6, sz * 22.0), Vector3(0, 0, sz), 4, 1.25, 2.0, LandmarkFrParts.HEAD_ROUND, 0.16, 0.12)
		LandmarkFrParts.openings(lm, "Granite", "Glass", Vector3(-6.5, 8.6, sz * 22.0),
			Vector3(6.5, 8.6, sz * 22.0), Vector3(0, 0, sz), 4, 1.25, 2.0, LandmarkFrParts.HEAD_ROUND, 0.16, 0.12)
	# Twin cylindrical red-brick Jugend corner stair turrets (22.0 m) on the +X courtyard corners.
	for sz: float in [-1.0, 1.0]:
		lm.frustum("Granite", Vector3(9.6, FOUND, sz * 21.2), 2.5, 2.4, 2.4 - FOUND, 12)
		lm.frustum("Brick", Vector3(9.6, 2.4, sz * 21.2), 2.35, 2.25, 14.8, 12)
		lm.lathe("Roof", Vector3(9.6, 17.2, sz * 21.2), PackedVector2Array([
			Vector2(2.6, 0.0), Vector2(1.4, 2.2), Vector2(0.08, 4.8)]), 12)
	# Rhythmic cell-window grid along both 44 m flanks.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.facade(lm, "Brick", "Glass", Vector3(sx * 10.0, 2.8, -19.5),
			Vector3(sx * 10.0, 2.8, 19.5), Vector3(sx, 0, 0), 11.8, 11, 3, Vector2(1.1, 1.75), 0.9, 3.7, 0.24)
	var child := Node3D.new()
	child.name = "WestCellblock"
	child.position = Vector3(-58.0, 0.0, -6.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## Polygonal Granite Mental Hospital (Kakolan mielisairaala) on the SW crag.
static func _build_mental_hospital(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["Granite", "Trim", "Roof", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# Castle-like U/polygonal granite crag block (32 x 22 m) with deep hill skirt.
	LandmarkFrKit.rect(lm, "Granite", -16.4, 16.4, -11.4, 11.4, -3.8, 13.6)
	LandmarkFrParts.cornice_ring(lm, "Trim", -16.4, 16.4, -11.4, 11.4, 13.0, 0.60)
	LandmarkFrKit.hip(lm, "Roof", -16.4, 16.4, -11.4, 11.4, 13.6, 4.8, 0.55)
	# Angled octagonal granite bastion tower on the SW crag corner (20.4 m).
	lm.frustum("Granite", Vector3(-16.0, -3.8, 10.5), 4.6, 4.4, 15.8 + 3.8, 8, PI / 8.0)
	lm.frustum("Trim", Vector3(-16.0, 15.4, 10.5), 4.7, 4.7, 0.45, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(-16.0, 15.85, 10.5), PackedVector2Array([
		Vector2(4.95, 0.0), Vector2(0.12, 4.55)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Flanking NE granite annex wing.
	LandmarkFrKit.rect(lm, "Granite", 11.0, 23.0, -18.0, -4.0, -3.8, 11.4)
	LandmarkFrKit.hip(lm, "Roof", 11.0, 23.0, -18.0, -4.0, 11.4, 3.8, 0.45)
	# Institutional arched windows on main facades.
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.facade(lm, "Granite", "Glass", Vector3(-13.5, 2.2, sz * 11.4),
			Vector3(13.5, 2.2, sz * 11.4), Vector3(0, 0, sz), 10.4, 8, 3, Vector2(1.15, 1.8), 0.85, 3.4, 0.24)
	var child := Node3D.new()
	child.name = "MentalHospital"
	child.position = Vector3(-42.0, 0.0, 52.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, -24.0), Vector3(0.0, 12.0, -11.0), 58.0, 0.90, 46.0, Color(1.0, 0.86, 0.64)],
		[Vector3(-24.0, 2.0, -22.0), Vector3(-22.0, 10.0, -9.0), 54.0, 0.70, 40.0, Color(1.0, 0.86, 0.64)],
		[Vector3(24.0, 2.0, -22.0), Vector3(22.0, 10.0, -9.0), 54.0, 0.70, 40.0, Color(1.0, 0.86, 0.64)],
		[Vector3(0.0, 2.0, 24.0), Vector3(0.0, 12.0, 11.0), 58.0, 0.65, 42.0, Color(1.0, 0.86, 0.64)],
	])
