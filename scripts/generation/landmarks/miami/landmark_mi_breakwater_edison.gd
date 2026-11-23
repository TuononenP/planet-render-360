class_name LandmarkMiBreakwaterEdison
extends RefCounted

## Hotel Breakwater & Edison Hotel — Ocean Drive 9th–10th St (MI-4A).
## Site: OSM ways 380875541 (940 Breakwater), 380875540 (960 Edison),
## 25.780103, -80.131007, yaw_deg 11.7. Local +X = east (Ocean Drive), +Z = north.
## Measured envelope (Anthony Zink 1939 Streamline Moderne; Commons front views):
##   - Footprint 38.0 m (X) x 46.0 m (Z), front at x = +9.5, sidewalk terrace to x = +16.
##   - Breakwater (z -23..5, 5 storeys to 17.5 m): symmetrical white & ocean-blue
##     ship-prow front (central bay projects 2.4 m), porthole rows, pool-terrace
##     parapet, crowned by the central vertical sign pylon whose tip is the model
##     top, exactly 24.0 m, glowing cyan with magenta neon bars.
##   - Edison (z 5..23, 4 storeys to 13.0 m): pastel mint, cream & coral ziggurat
##     corner front at 10th St.

const HEIGHT_M := 24.0
const FRONT_X := 9.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F7F6F1", 3.0))
	lm.use("Blue", LandmarkMaterials.paint("#1D6FB8", 0.5, 0.05))
	lm.use("Mint", LandmarkMaterials.pbr("render", "#BFE6CF", 3.0))
	lm.use("Coral", LandmarkMaterials.paint("#EE8467", 0.55, 0.05))
	lm.use("Glass", LandmarkMaterials.glass("#24343E"))
	lm.use("Cyan", LandmarkMaterials.lit("#36D8FF", 1.5))
	lm.use("Magenta", LandmarkMaterials.lit("#FF3FA8", 1.4))
	lm.use("Trunk", LandmarkMaterials.pbr("concrete", "#9A9588", 2.0))
	lm.use("Frond", LandmarkMaterials.paint("#2F6B35", 0.8, 0.0))
	lm.use("Walk", LandmarkMaterials.pbr("concrete", "#CDC7B9", 3.0))

	lm.box("Walk", Vector3(3.0, -0.15, 0.0), Vector3(32.0, 0.3, 46.0))
	_wing(lm, "White", "Blue", -23.0, 5.0, 17.5, 5)
	_wing(lm, "Mint", "Coral", 5.0, 23.0, 13.0, 4)
	_prow(lm)
	_pylon(lm)
	_edison_ziggurat(lm)
	_terrace(lm)
	lm.commit(model)

	var cyan := Color(0.55, 0.88, 1.0)
	var pink := Color(1.0, 0.62, 0.84)
	var warm := Color(1.0, 0.9, 0.7)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(17.0, 1.5, -13.0), Vector3(FRONT_X + 1.0, 13.0, -9.0), 44.0, 1.3, 40.0, cyan],
		[Vector3(17.0, 1.5, -3.0), Vector3(FRONT_X + 1.0, 18.0, -9.0), 44.0, 1.3, 44.0, pink],
		[Vector3(17.0, 1.5, 14.0), Vector3(FRONT_X, 8.0, 14.0), 40.0, 1.1, 34.0, warm],
	])

static func _wing(lm: LandmarkMesh, wall: String, trim: String, z0: float, z1: float,
		h: float, floors: int) -> void:
	var zc := (z0 + z1) * 0.5
	lm.box(wall, Vector3(-0.5, (h - 0.3) * 0.5, zc), Vector3(20.0, h + 0.3, z1 - z0 - 0.3))
	lm.box(trim, Vector3(FRONT_X - 0.1, h - 0.3, zc), Vector3(0.5, 0.7, z1 - z0 - 0.3))
	lm.box(trim, Vector3(FRONT_X - 0.3, h + 0.5, zc), Vector3(0.3, 0.9, z1 - z0 - 0.3))
	var fh := h / float(floors)
	var bays := maxi(2, int((z1 - z0) / 3.0))
	for f in floors:
		var yc := float(f) * fh + fh * 0.5 + 0.2
		for i in bays:
			var z := lerpf(z0 + 1.0, z1 - 1.0, (float(i) + 0.5) / float(bays))
			lm.box("Glass", Vector3(FRONT_X + 0.03, yc, z), Vector3(0.1, 1.7 if f > 0 else 2.0, 1.3))
		if f > 0:
			LandmarkMiKit.deco_eyebrow(lm, trim, Vector2(FRONT_X, z0 + 0.2),
				Vector2(FRONT_X, z1 - 0.2), float(f) * fh + fh * 0.5 + 1.2, 0.42, 0.10, Vector2(1, 0))

static func _prow(lm: LandmarkMesh) -> void:
	# Ship-prow central bay of the Breakwater, symmetrical about z = -9.
	var zc := -9.0
	var poly := PackedVector2Array([Vector2(FRONT_X - 0.5, zc - 6.0), Vector2(FRONT_X + 2.4, zc - 2.2),
		Vector2(FRONT_X + 2.4, zc + 2.2), Vector2(FRONT_X - 0.5, zc + 6.0)])
	lm.poly_prism("White", poly, -0.3, 17.5)
	for f in 5:
		var y := 1.2 + float(f) * 3.5
		lm.box("Blue", Vector3(FRONT_X + 2.45, y + 0.9, zc), Vector3(0.1, 0.25, 3.6))
		lm.box("Glass", Vector3(FRONT_X + 2.46, y, zc), Vector3(0.1, 1.5, 3.0))
		if f > 0:
			LandmarkMiKit.deco_eyebrow(lm, "Blue", Vector2(FRONT_X + 2.4, zc - 2.4),
				Vector2(FRONT_X + 2.4, zc + 2.4), y + 1.1, 0.5, 0.12, Vector2(1, 0))
	LandmarkMiKit.porthole_row(lm, "Blue", "Glass", Vector2(FRONT_X, -21.5),
		Vector2(FRONT_X, zc - 6.5), 2.6, 3, 0.32, Vector2(1, 0))
	LandmarkMiKit.porthole_row(lm, "Blue", "Glass", Vector2(FRONT_X, zc + 6.5),
		Vector2(FRONT_X, 3.5), 2.6, 3, 0.32, Vector2(1, 0))

static func _pylon(lm: LandmarkMesh) -> void:
	var zc := -9.0
	var px := FRONT_X + 1.1
	# Pool-terrace parapet and the three-tier vertical sign pylon to exactly 24.0 m.
	lm.box("Blue", Vector3(FRONT_X - 0.2, 18.1, -9.0), Vector3(0.4, 1.2, 12.0))
	lm.box("White", Vector3(px, 18.9, zc), Vector3(1.4, 2.4, 3.0))
	lm.box("White", Vector3(px, 21.1, zc), Vector3(1.1, 2.4, 2.2))
	lm.box("Blue", Vector3(px, 22.9, zc), Vector3(0.9, 1.4, 1.5))
	lm.spire("Blue", Vector3(px, 23.6, zc), 0.35, 0.4, 0.03, 4)
	for sz: float in [-1.0, 1.0]:
		lm.beam("Cyan", Vector3(px + 0.8, 17.6, zc + sz * 1.45), Vector3(px + 0.8, 23.5, zc + sz * 0.75), 0.12, 0.12)
	for k in 4:
		lm.box("Magenta", Vector3(px + 0.78, 19.3 + float(k) * 1.2, zc), Vector3(0.1, 0.4, 1.3))
	lm.beam("Cyan", Vector3(px + 0.6, 23.5, zc), Vector3(px + 0.6, HEIGHT_M, zc), 0.1, 0.1)

static func _edison_ziggurat(lm: LandmarkMesh) -> void:
	LandmarkMiKit.ziggurat_parapet(lm, "Mint", "Coral", Vector2(FRONT_X - 0.4, 20.0),
		Vector2(0, 1), Vector2(1, 0), 13.0, 6.0, 0.5, 3, 0.5)
	lm.box("Coral", Vector3(FRONT_X + 0.15, 6.5, 22.6), Vector3(0.5, 12.0, 0.5))
	var tube := PackedVector3Array([Vector3(FRONT_X + 0.5, 12.7, 5.3), Vector3(FRONT_X + 0.5, 12.7, 22.7)])
	LandmarkMiKit.neon_tube_line(lm, "Magenta", tube, 0.09)

static func _terrace(lm: LandmarkMesh) -> void:
	for z: float in [-20.0, -14.0, -4.0, 0.0, 10.0, 17.0]:
		var u := Vector3(FRONT_X + 7.0, 0.0, z)
		lm.beam("Trunk", u, u + Vector3(0, 2.3, 0), 0.08, 0.08)
		lm.frustum("Blue" if z < 5.0 else "Coral", u + Vector3(0, 2.1, 0), 1.3, 0.06, 0.55, 8)
	for z: float in [-18.0, 2.0, 20.0]:
		LandmarkMiKit.royal_palm(lm, "Trunk", "Frond", Vector3(FRONT_X + 10.5, 0.0, z), 9.5, z)
