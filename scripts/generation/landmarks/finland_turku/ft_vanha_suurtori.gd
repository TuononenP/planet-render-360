class_name FtVanhaSuurtori
extends RefCounted

## Vanha Suurtori (Old Great Square, Turku) — complete 4-mansion Empire
## ensemble in true metres (+X NNE along square, +Z ESE into Vanha Suurtori
## square, -Z WNW toward Aurajoki/Katedralskolan, turned by yaw_deg = -59.0°):
##   1. Brinkkala Mansion (Brinkkalan talo, 1829, P.J. Gylich) at (0, 0):
##      34 x 13 m pale-yellow Empire street wing (eaves 10.6 m, hipped roof
##      14.8 m), rusticated base, arched carriage passage, wrought-iron
##      Christmas Peace balcony (+Z), and twin rear courtyard wings (-Z).
##   2. Old Town Hall (Vanha Raatihuone, 1736/1829) as SEAT_META child at
##      (+17.2, +30.5): 22 x 16 m warm red-ochre 3-storey Empire facade with
##      white pilasters, triangular pediment with illuminated clock dial,
##      hipped slate roof, and octagonal cupola/turret rising to 16.3 m.
##   3. Hjelt House (Hjeltin talo, 1830) at (-26.5, +22.0): 14 x 26 m pale
##      Empire palace facing +X into the square with pilastered piano nobile
##      and central pediment (eaves 10.4 m, ridge 14.0 m).
##   4. Juselius House (Juseliuksen talo) at (-3.0, +47.0): 24 x 14 m warm
##      ochre Empire corner house closing the south edge of Vanha Suurtori
##      (eaves 9.8 m, ridge 13.4 m), plus cobble square & Empire lamps.
## Surfaces: 12 merged PBR parts (8 main + 4 on OldTownHall SEAT_META child).

const FOUND := -2.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_brinkkala(lm)
	_build_hjelt_house(lm)
	_build_juselius_house(lm)
	_build_square_and_lamps(lm)
	lm.commit(model)
	_build_old_town_hall(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E7CE82", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("render", "#D5BF7A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F0E6", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3B4044", 2.2))
	lm.use("Iron", LandmarkMaterials.paint("#23262A", 0.45, 0.65))
	lm.use("Cobble", LandmarkMaterials.pbr("pavement", "#76726B", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#222B30"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BA", 1.5))

static func _build_brinkkala(lm: LandmarkMesh) -> void:
	# Main Empire street wing (34 x 13 m, eaves 10.6 m, hipped roof 14.8 m).
	LandmarkFrKit.rect(lm, "Base", -17.2, 17.2, -6.7, 6.7, FOUND, 4.3)
	LandmarkFrKit.rect(lm, "Wall", -17.0, 17.0, -6.5, 6.5, 4.3, 10.6)
	# Rusticated horizontal stone courses along the ground storey front (+Z).
	for k in 5:
		var ry := 0.85 + float(k) * 0.72
		lm.box("Trim", Vector3(0.0, ry, 6.74), Vector3(34.3, 0.10, 0.08))
	LandmarkFrParts.band(lm, "Trim", -17.0, 17.0, -6.5, 6.5, 4.2, 0.42, 0.16)
	LandmarkFrParts.cornice_ring(lm, "Trim", -17.0, 17.0, -6.5, 6.5, 10.05, 0.58)
	LandmarkFrKit.hip(lm, "Roof", -17.0, 17.0, -6.5, 6.5, 10.6, 4.2, 0.45)
	# Twin brick/rendered chimneys on the Brinkkala ridge.
	for cx: float in [-8.5, 8.5]:
		LandmarkFrKit.rect(lm, "Trim", cx - 0.65, cx + 0.65, -0.65, 0.65, 13.0, 15.1)
	# Central slightly projecting 3-bay avant-corps facing Vanha Suurtori (+Z).
	LandmarkFrKit.rect(lm, "Wall", -4.8, 4.8, 6.4, 7.05, 4.3, 10.75)
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(0.0, 10.75, 7.05), Vector3.RIGHT, Vector3.BACK, 9.8, 1.9, 0.55)
	# Central arched carriage portal into Brinkkala courtyard & flanking ground windows.
	LandmarkFrParts.opening(lm, "Trim", "Iron", Vector3(0.0, 0.0, 6.75), Vector3.BACK, 3.2, 3.8,
		LandmarkFrParts.HEAD_ROUND, 0.28, 0.18)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 4.5, 1.35, 6.72),
			Vector3(sx * 15.2, 1.35, 6.72), Vector3.BACK, 3, 1.35, 2.2, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
	# Piano nobile windows (9 bays across front, tall balcony doors in centre).
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 5.8, 5.2, 6.52),
			Vector3(sx * 15.4, 5.2, 6.52), Vector3.BACK, 3, 1.38, 2.75, LandmarkFrParts.HEAD_FLAT, 0.18, 0.14, 1)
	for bx: float in [-2.4, 0.0, 2.4]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(bx, 4.75, 7.05), Vector3.BACK, 1.45, 3.25,
			LandmarkFrParts.HEAD_FLAT, 0.20, 0.14, 1)
		lm.box("Trim", Vector3(bx, 8.32, 7.22), Vector3(1.9, 0.22, 0.28))
	# Iconic wrought-iron Christmas Peace balcony (Joulurauhan parveke, +Z).
	lm.box("Trim", Vector3(0.0, 4.58, 7.95), Vector3(6.8, 0.32, 1.9))
	for cx: float in [-2.8, -1.0, 1.0, 2.8]:
		lm.beam("Trim", Vector3(cx, 3.85, 7.05), Vector3(cx, 4.48, 8.65), 0.24, 0.22, Vector3.RIGHT)
	# Wrought-iron top/bottom rails & rhythmic balusters.
	lm.box("Iron", Vector3(0.0, 5.62, 8.84), Vector3(6.8, 0.09, 0.09))
	lm.box("Iron", Vector3(0.0, 4.82, 8.84), Vector3(6.8, 0.07, 0.07))
	for k in 15:
		var px := lerpf(-3.3, 3.3, float(k) / 14.0)
		lm.box("Iron", Vector3(px, 5.18, 8.84), Vector3(0.05, 0.92, 0.05))
	for sx: float in [-3.35, 3.35]:
		lm.box("Iron", Vector3(sx, 5.62, 7.95), Vector3(0.09, 0.09, 1.85))
		lm.box("Iron", Vector3(sx, 4.82, 7.95), Vector3(0.07, 0.07, 1.85))
		for j in 5:
			var pz := lerpf(7.15, 8.75, float(j) / 4.0)
			lm.box("Iron", Vector3(sx, 5.18, pz), Vector3(0.05, 0.92, 0.05))
	# Rear courtyard wings enclosing Brinkkala inner yard (-Z).
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 12.5 - 4.5
		var x1 := sx * 12.5 + 4.5
		LandmarkFrKit.rect(lm, "Base", x0 - 0.15, x1 + 0.15, -21.2, -6.5, FOUND, 3.2)
		LandmarkFrKit.rect(lm, "Wall", x0, x1, -21.0, -6.5, 3.2, 8.8)
		LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, -21.0, -6.5, 8.35, 0.45)
		LandmarkFrKit.hip(lm, "Roof", x0, x1, -21.0, -6.5, 8.8, 3.3, 0.35)
		var inner_x := x1 if sx < 0.0 else x0
		var inner_n := Vector3(-sx, 0, 0)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(inner_x, 4.4, -19.2),
			Vector3(inner_x, 4.4, -8.5), inner_n, 4, 1.25, 2.2, LandmarkFrParts.HEAD_FLAT, 0.15, 0.10, 1)

static func _build_hjelt_house(lm: LandmarkMesh) -> void:
	# Hjelt House (Hjeltin talo, 1830): pale Empire palace along SW edge of square (-26.5, +22.0).
	var x0 := -33.5
	var x1 := -19.5
	var z0 := 9.0
	var z1 := 35.0
	LandmarkFrKit.rect(lm, "Base", x0 - 0.2, x1 + 0.2, z0 - 0.2, z1 + 0.2, FOUND, 3.8)
	LandmarkFrKit.rect(lm, "Trim", x0, x1, z0, z1, 3.8, 10.4)
	LandmarkFrParts.band(lm, "Base", x0, x1, z0, z1, 3.7, 0.38, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, z0, z1, 9.85, 0.55)
	LandmarkFrKit.hip(lm, "Roof", x0, x1, z0, z1, 10.4, 3.6, 0.42)
	# Pilastered piano nobile & central pediment facing Vanha Suurtori (+X).
	for k in 6:
		var pz := lerpf(11.5, 32.5, float(k) / 5.0)
		lm.box("Base", Vector3(x1 + 0.12, 7.0, pz), Vector3(0.24, 5.8, 0.55))
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(x1 + 0.1, 10.4, 22.0), Vector3.BACK, Vector3.RIGHT, 10.5, 2.0, 0.5)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(x1, 1.1, 11.2), Vector3(x1, 1.1, 32.8),
		Vector3.RIGHT, 7, 1.35, 2.2, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
	LandmarkFrParts.openings(lm, "Base", "Glass", Vector3(x1, 5.0, 11.2), Vector3(x1, 5.0, 32.8),
		Vector3.RIGHT, 7, 1.4, 2.8, LandmarkFrParts.HEAD_FLAT, 0.18, 0.14, 1)

static func _build_juselius_house(lm: LandmarkMesh) -> void:
	# Juselius House (Juseliuksen talo): Empire corner mansion closing south edge (-3.0, +47.0).
	var x0 := -15.0
	var x1 := 9.0
	var z0 := 40.0
	var z1 := 54.0
	LandmarkFrKit.rect(lm, "Base", x0 - 0.2, x1 + 0.2, z0 - 0.2, z1 + 0.2, FOUND, 3.6)
	LandmarkFrKit.rect(lm, "Wall", x0, x1, z0, z1, 3.6, 9.8)
	LandmarkFrParts.band(lm, "Trim", x0, x1, z0, z1, 3.55, 0.35, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, z0, z1, 9.3, 0.50)
	LandmarkFrKit.hip(lm, "Roof", x0, x1, z0, z1, 9.8, 3.6, 0.40)
	# Square-facing (-Z) Empire windows & entrance portal.
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-13.2, 1.0, z0), Vector3(7.2, 1.0, z0),
		Vector3.FORWARD, 7, 1.3, 2.1, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-13.2, 4.7, z0), Vector3(7.2, 4.7, z0),
		Vector3.FORWARD, 7, 1.35, 2.55, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)

static func _build_square_and_lamps(lm: LandmarkMesh) -> void:
	# Historic cobblestone Vanha Suurtori apron & 4 black-iron Empire street lanterns.
	LandmarkFrKit.rect(lm, "Cobble", -19.4, 9.2, 6.7, 40.0, -1.2, 0.08)
	for pos: Array in [[-14.5, 11.5], [7.0, 11.5], [-14.5, 35.5], [5.5, 35.5]]:
		var lx: float = pos[0]
		var lz: float = pos[1]
		lm.frustum("Iron", Vector3(lx, 0.08, lz), 0.18, 0.08, 4.1, 8)
		lm.frustum("Lamp", Vector3(lx, 4.18, lz), 0.18, 0.24, 0.45, 6)
		lm.spire("Iron", Vector3(lx, 4.63, lz), 0.28, 0.26, 0.0, 6)

## Old Town Hall (Vanha Raatihuone) seated via SEAT_META on the uphill SE edge.
static func _build_old_town_hall(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	lm.use("TownHall", LandmarkMaterials.pbr("render", "#C66B4C", 3.0))
	lm.use("Trim", (base_lm._surfs["Trim"] as LandmarkMesh.Surf).mat)
	lm.use("Roof", (base_lm._surfs["Roof"] as LandmarkMesh.Surf).mat)
	lm.use("Glass", (base_lm._surfs["Glass"] as LandmarkMesh.Surf).mat)
	# 3-storey warm red-ochre Empire facade (22 x 16 m, eaves 11.4 m, hipped roof 13.8 m).
	LandmarkFrKit.rect(lm, "Trim", -11.3, 11.3, -8.3, 8.3, FOUND, 3.6)
	LandmarkFrKit.rect(lm, "TownHall", -11.0, 11.0, -8.0, 8.0, 3.6, 11.4)
	LandmarkFrParts.band(lm, "Trim", -11.0, 11.0, -8.0, 8.0, 3.55, 0.42, 0.16)
	LandmarkFrParts.cornice_ring(lm, "Trim", -11.0, 11.0, -8.0, 8.0, 10.85, 0.58)
	LandmarkFrKit.hip(lm, "Roof", -11.0, 11.0, -8.0, 8.0, 11.4, 2.5, 0.45)
	# White Corinthian pilasters & central triangular pediment with clock dial facing -Z / square.
	for k in 6:
		var px := lerpf(-9.2, 9.2, float(k) / 5.0)
		lm.box("Trim", Vector3(px, 7.3, -8.12), Vector3(0.52, 6.9, 0.26))
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(0.0, 11.4, -8.15), Vector3.RIGHT, Vector3.FORWARD, 10.4, 2.35, 0.55)
	lm.disc("Trim", Vector3(0.0, 12.25, -8.25), Vector3.FORWARD, 0.72, 16)
	lm.disc("Roof", Vector3(0.0, 12.25, -8.29), Vector3.FORWARD, 0.56, 16)
	# Windows on square-facing (-Z and -X) fronts.
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-9.0, 1.0, -8.3), Vector3(9.0, 1.0, -8.3),
		Vector3.FORWARD, 7, 1.25, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-9.0, 4.4, -8.0), Vector3(9.0, 4.4, -8.0),
		Vector3.FORWARD, 7, 1.35, 2.5, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-9.0, 7.8, -8.0), Vector3(9.0, 7.8, -8.0),
		Vector3.FORWARD, 7, 1.3, 2.2, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-11.0, 4.4, -6.0), Vector3(-11.0, 4.4, 6.0),
		Vector3.LEFT, 4, 1.35, 2.5, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
	# Signature central octagonal ridge bell/clock turret (top 16.3 m, within 15.0 +/- 2.0 m).
	lm.box("Trim", Vector3(0.0, 13.75, 0.0), Vector3(3.4, 1.1, 3.4))
	lm.frustum("Trim", Vector3(0.0, 14.3, 0.0), 1.35, 1.28, 1.15, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(0.0, 15.45, 0.0), PackedVector2Array([
		Vector2(1.52, 0.0), Vector2(0.85, 0.42), Vector2(0.08, 0.85)]), 8, 1.0, 1.0, PI / 8.0, false)
	var child := Node3D.new()
	child.name = "OldTownHall"
	child.position = Vector3(17.2, 0.0, 30.5)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, 16.0), Vector3(0.0, 6.5, 7.0), 56.0, 0.90, 38.0, Color(1.0, 0.88, 0.66)],
		[Vector3(8.0, 1.5, 19.0), Vector3(17.2, 9.0, 23.0), 54.0, 0.85, 40.0, Color(1.0, 0.84, 0.60)],
		[Vector3(-12.0, 1.5, 22.0), Vector3(-20.0, 6.5, 22.0), 56.0, 0.70, 34.0, Color(1.0, 0.88, 0.68)],
		[Vector3(-3.0, 1.5, 32.0), Vector3(-3.0, 6.0, 40.0), 56.0, 0.65, 34.0, Color(1.0, 0.88, 0.68)],
	])
