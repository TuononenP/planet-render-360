class_name LandmarkBkGrandPalaceWall
extends RefCounted

## Grand Palace outer crenellated wall (`way:23482754`, ~1.9 km), perimeter forts,
## spired palace gates, Middle Court halls (Amarin Winitchai `way:205631558`,
## Borom Phiman `way:82543520`), Wat Phra Kaew belfry (`way:229771450`), and
## 12 guardian Yaksha giants (`BK-4.1`). Coordinates in metres relative to
## registry origin (13.75101, 100.49188), -Z north, +X east.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const WALL_RING := [
	Vector2(-257.8, -134.1),
	Vector2(-55.3, -140.7),
	Vector2(162.3, -140.7),
	Vector2(185.0, 5.3),
	Vector2(204.2, 106.4),
	Vector2(234.0, 322.3),
	Vector2(231.0, 367.6),
	Vector2(65.0, 422.0),
	Vector2(-109.9, 475.1),
	Vector2(-173.6, 359.7),
	Vector2(-222.4, 156.6),
	Vector2(-249.7, -40.0),
]

const FORTS := [
	[161.7, -148.0, 7.5],   # Phadet Datsakon Fort (NE corner facing Sanam Luang)
	[-48.7, -144.1, 7.0],   # Khan Kuenphet Fort (N wall facing Sanam Luang)
	[-257.8, -134.1, 6.8],  # Inthara Rangsri bastion (NW corner)
	[185.8, -4.0, 6.5],     # Sanchorn Chaiwing Fort (E wall)
	[204.2, 106.4, 6.8],    # Singkhornkhan Fort (E wall)
	[234.0, 322.3, 6.8],    # Anantakhiri Fort (SE wall)
	[229.3, 361.0, 7.5],    # Mani Prakan Fort (SE corner)
]

const GATES := [
	[-62.0, -140.6, PI],         # Wisetchaisri Gate (main N visitor entrance facing Sanam Luang)
	[22.0, -142.2, PI],          # Phiman Chaisri / Manopimok Gate (N wall)
	[-158.0, -137.4, PI],        # Phiman Devesr Gate (NW wall)
	[173.5, -72.0, PI * 0.5],    # Sawatdi Sophon Gate (E wall opposite City Pillar Shrine)
	[212.0, 165.0, PI * 0.5],    # Thewaphithak Gate (E wall)
	[-236.0, 55.0, -PI * 0.5],   # Tha Chang river-side palace gate (W wall)
]

static func build_extensions(lm: LandmarkMesh, hall_keys: Dictionary) -> void:
	_outer_wall_and_forts(lm)
	_palace_gates(lm)
	_middle_and_outer_courts(lm, hall_keys)
	_wat_phra_kaew_yaksha_and_belfry(lm)

static func add_floodlights(model: Node3D) -> void:
	# Warm white wash along the northern & eastern palace walls (E7 Sanam Luang view!)
	# plus rich golden floodlights on Phra Si Rattana Chedi, Chakri Maha Prasat, and Pantheon.
	var spots: Array = [
		[Vector3(44.0, 3.0, -44.0), Vector3(44.0, 26.0, -68.0), 48.0, 1.5, 42.0, Color(1.0, 0.85, 0.44)],
		[Vector3(44.0, 3.0, -92.0), Vector3(44.0, 26.0, -68.0), 48.0, 1.5, 42.0, Color(1.0, 0.85, 0.44)],
		[Vector3(94.0, 3.0, -44.0), Vector3(94.0, 22.0, -68.0), 48.0, 1.2, 38.0, Color(1.0, 0.88, 0.58)],
		[Vector3(-65.0, 2.5, 62.0), Vector3(-65.0, 24.0, 109.0), 55.0, 1.35, 65.0, Color(1.0, 0.90, 0.68)],
		[Vector3(-148.0, 2.5, 62.0), Vector3(-148.0, 18.0, 94.0), 48.0, 1.1, 48.0, Color(1.0, 0.90, 0.68)],
	]
	for nx in [-200.0, -110.0, -20.0, 70.0, 150.0]:
		spots.append([Vector3(nx, 1.8, -158.0), Vector3(nx, 6.0, -141.0), 55.0, 0.95, 32.0, Color(1.0, 0.94, 0.82)])
	for ez in [-100.0, 0.0, 100.0]:
		spots.append([Vector3(205.0, 1.8, ez), Vector3(186.0, 6.0, ez), 55.0, 0.90, 32.0, Color(1.0, 0.94, 0.82)])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _outer_wall_and_forts(lm: LandmarkMesh) -> void:
	# Low-triangle instanced pointed lotus merlon (6 tris each) for the 1.9 km white crenellated outer wall
	var merlon := LandmarkMesh.new()
	merlon.use("Wall", LandmarkMaterials.gold())
	merlon.spire("Wall", Vector3.ZERO, 0.65, 1.05, 0.0, 4)

	var n := WALL_RING.size()
	for i in n:
		var a2: Vector2 = WALL_RING[i]
		var b2: Vector2 = WALL_RING[(i + 1) % n]
		var a := Vector3(a2.x, 0.0, a2.y)
		var b := Vector3(b2.x, 0.0, b2.y)
		var dir := (b - a).normalized()
		var length := a.distance_to(b)
		var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		var mid := (a + b) * 0.5
		# Solid 4.6 m whitewashed brick palace wall + moulded coping (0.0 bevel to stay well within 150k budget)
		lm.box("Wall", mid + Vector3(0, 2.3, 0), Vector3(length + 1.2, 4.6, 1.35), basis, 0.0)
		lm.box("Stone", mid + Vector3(0, 4.68, 0), Vector3(length + 1.4, 0.24, 1.65), basis, 0.0)
		var count := int(length / 3.8)
		for k in count:
			var p := a.lerp(b, (float(k) + 0.5) / float(count))
			lm.merge(merlon, Transform3D(basis, p + Vector3(0, 4.80, 0)))

	# Named octagonal perimeter forts & corner bastions
	var fort_sub := LandmarkMesh.new()
	for k in ["Wall", "Stone", "Orange", "Gold", "Dark"]:
		fort_sub.use(k, LandmarkMaterials.gold())
	K2.fort_tier(fort_sub, "Wall", "Dark", Vector3.ZERO, 1.0, 0.94, 6.2, 8, false, true)
	K2.fort_tier(fort_sub, "Wall", "Dark", Vector3(0, 6.2, 0), 0.64, 0.60, 3.0, 8, false, false)
	fort_sub.spire("Orange", Vector3(0, 9.2, 0), 0.68, 2.2, 0.0, 8)
	fort_sub.frustum("Gold", Vector3(0, 11.3, 0), 0.08, 0.0, 1.2, 6)
	for ft in FORTS:
		var r: float = ft[2]
		lm.merge(fort_sub, Transform3D(Basis().scaled(Vector3(r, 1.0, r)), Vector3(float(ft[0]), 0.0, float(ft[1]))))

static func _palace_gates(lm: LandmarkMesh) -> void:
	# Reusable ceremonial gate pavilion crowned by a gilded Thai prasat spire
	var gate := LandmarkMesh.new()
	for k in ["Wall", "Stone", "Orange", "Green", "Gold", "Dark"]:
		gate.use(k, LandmarkMaterials.gold())
	gate.box("Wall", Vector3(0, 3.6, 0), Vector3(11.6, 7.2, 4.6), Basis(), 0.0)
	gate.box("Dark", Vector3(0, 2.5, 0), Vector3(3.8, 5.0, 4.8), Basis(), 0.0)
	gate.box("Stone", Vector3(0, 7.4, 0), Vector3(12.6, 0.5, 5.4), Basis(), 0.0)
	gate.gable("Orange", Vector3(0, 7.65, 0), 5.6, 13.0, 2.6, Basis(Vector3.UP, PI * 0.5), 0.6, "Gold")
	U.prasat_spire(gate, "Wall", "Orange", "Gold", Vector3(0, 10.2, 0), 2.2, 8.8, 4)
	for g in GATES:
		lm.merge(gate, Transform3D(Basis(Vector3.UP, float(g[2])), Vector3(float(g[0]), 0.0, float(g[1]))))

static func _middle_and_outer_courts(lm: LandmarkMesh, hall_keys: Dictionary) -> void:
	# Clipped green lawns of the Outer Court (facing Wisetchaisri Gate) & Chakri forecourt
	lm.box("Grass", Vector3(-95.0, 0.05, -72.0), Vector3(145.0, 0.10, 95.0), Basis(), 0.0)
	lm.box("Grass", Vector3(-65.0, 0.05, 42.0), Vector3(82.0, 0.10, 56.0), Basis(), 0.0)
	lm.box("Stone", Vector3(-62.0, 0.08, -22.0), Vector3(16.0, 0.16, 210.0), Basis(), 0.0)

	# Amarin Winitchai Throne Hall (`way:205631558`, c = 13.1, 62.8) + Paisal Taksin behind it
	# (compact massing + K.thai_roof keeps total Grand Palace compound under the 150k triangle ceiling)
	for hspec in [[Vector3(13.0, 0.0, 63.0), PI, 18.0, 34.0, 8.8, 4.8],
			[Vector3(13.0, 0.0, 98.0), PI * 0.5, 13.0, 36.0, 7.6, 4.2]]:
		var hc: Vector3 = hspec[0]
		var hb := Basis(Vector3.UP, float(hspec[1]))
		var hw := float(hspec[2])
		var hl := float(hspec[3])
		var hh := float(hspec[4])
		lm.box("Stone", hc + Vector3(0, 0.6, 0), Vector3(hw + 2.4, 1.2, hl + 2.4), hb, 0.0)
		lm.box("Wall", hc + Vector3(0, 1.2 + hh * 0.5, 0), Vector3(hw, hh, hl), hb, 0.0)
		K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", hc + Vector3(0, 1.2 + hh, 0),
			hb, hw + 1.6, hl + 1.6, float(hspec[5]), 1.1, 2, 0, 1.3)

	# Borom Phiman Mansion (`way:82543520`, c = 115.9, 61.6): 2-storey cream Neo-Renaissance
	# royal residence with slate mansard roof and central dome
	var bc := Vector3(116.0, 0.0, 62.0)
	lm.box("Stone", bc + Vector3(0, 0.7, 0), Vector3(70.0, 1.4, 26.0))
	lm.box("Wall", bc + Vector3(0, 6.9, 0), Vector3(68.0, 11.0, 24.0))
	lm.box("Stone", bc + Vector3(0, 12.6, 0), Vector3(69.6, 0.6, 25.6))
	lm.spire("Slate", bc + Vector3(0, 12.9, 0), 34.5, 3.8, 28.0, 4)
	lm.lathe("Slate", bc + Vector3(0, 12.9, 0), PackedVector2Array([
		Vector2(6.5, 0.0), Vector2(6.2, 3.2), Vector2(4.2, 5.6), Vector2(1.4, 6.8), Vector2(0.0, 7.4)]), 12)
	for i in 11:
		var wx := -27.5 + 5.5 * float(i)
		for z_s in [-1.0, 1.0]:
			for wy in [4.2, 9.2]:
				lm.box("Glass", bc + Vector3(wx, wy, float(z_s) * 12.06), Vector3(1.5, 2.6, 0.08), Basis(), 0.0)

static func _wat_phra_kaew_yaksha_and_belfry(lm: LandmarkMesh) -> void:
	# Ho Rakhang (Wat Phra Kaew Belfry, `way:229771450`, c = 80.4, 5.9): 22 m mosaic prasat belfry
	var bf := Vector3(80.4, 0.0, 5.9)
	K.redent_lathe(lm, "Stone", bf, PackedVector2Array([
		Vector2(4.6, 0.0), Vector2(4.6, 1.4), Vector2(3.8, 1.6), Vector2(3.8, 3.2)]), 0.12)
	K2.mondop(lm, {"wall": "Blue", "stone": "Stone", "tile": "Orange", "border": "Green", "gold": "Gold", "dark": "Dark"},
		bf + Vector3(0, 3.2, 0), Basis(), 5.4, 5.2, 13.6, 5)

	# 12 Guardian Yaksha Giants (`K2.yaksha`, 5.8 m tall) built in 2 colour pairs and merged at the 6 gallery gates
	var yak_g := LandmarkMesh.new()
	var yak_p := LandmarkMesh.new()
	for sub in [yak_g, yak_p]:
		for k in ["Green", "Pink", "Gold", "Stone"]:
			sub.use(k, LandmarkMaterials.gold())
	K2.yaksha(yak_g, "Green", "Stone", "Gold", Vector3.ZERO, Basis(), 5.8)
	K2.yaksha(yak_p, "Pink", "Stone", "Gold", Vector3.ZERO, Basis(), 5.8)

	var wk := Vector3(84.0, 0.0, -54.0)
	var gate_pairs := [
		[Vector3(-32, 0, 71), 0.0], [Vector3(24, 0, 71), 0.0],
		[Vector3(-32, 0, -71), PI], [Vector3(24, 0, -71), PI],
		[Vector3(-73, 0, -14), PI * 0.5], [Vector3(73, 0, -28), -PI * 0.5],
	]
	for gp in gate_pairs:
		var c: Vector3 = wk + (gp[0] as Vector3)
		var yaw: float = gp[1]
		var b := Basis(Vector3.UP, yaw)
		lm.merge(yak_g, Transform3D(b, c + b * Vector3(-2.8, 0, 0)))
		lm.merge(yak_p, Transform3D(b, c + b * Vector3(2.8, 0, 0)))
