class_name LandmarkIndMughal
extends RefCounted

## Three Mughal monuments of Delhi in true metres: the Red Fort, Humayun's
## Tomb and the Jama Masjid. Built in the monument's own frame (the
## registry yaw turns it onto the real bearing).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")

## Red Fort (33 m to the Lahori Gate turrets): the 2.4 km octagon of red
## sandstone walls with merlons and kiosk bastions (22 m on the city
## side, 18 m on the river side), the Lahori Gate and its barbican, the
## vaulted Chhatta Chowk, the Naubat Khana, the Diwan-i-Am, the white
## marble pavilions along the river wall and the Delhi Gate. The
## Lahori-Diwan axis is the model X axis; the gate faces -X (west).
static func red_fort_delhi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("stone", "#A5442C", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EEE9DC", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4A3A32", 2.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B8A58C", 4.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4C", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	var poly := [Vector2(-245, -230), Vector2(-120, -385), Vector2(200, -385), Vector2(272, -300),
		Vector2(265, 280), Vector2(170, 428), Vector2(-150, 428), Vector2(-245, 260)]
	var heights := [21.0, 20.0, 19.0, 18.0, 19.0, 21.0, 22.0, 22.0]
	var lawn := PackedVector2Array()
	for p in poly:
		lawn.append((p as Vector2) * 0.97 + Vector2(10, 20) * 0.03)
	lm.poly_prism("Lawn", lawn, -0.4, 0.04)
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var h: float = heights[i]
		IU.wall_run(lm, "Red", a, b, -1.0, h, 6.0)
		var out := Vector2((b - a).y, -(b - a).x).normalized()
		if out.dot((a + b) * 0.5 - Vector2(10, 20)) < 0.0:
			out = -out
		IU.merlons(lm, "Red", a + out * 2.2, b + out * 2.2, h, 6.0, 3.2, 1.6, 1.1)
		var n := maxi(int(a.distance_to(b) / 110.0), 1)
		for k in n:
			var p := a.lerp(b, float(k) / float(n))
			IU.bastion(lm, "Red", "Marble", Vector3(p.x, -1.0, p.y), 4.5, h + 1.5)
	# Lahori Gate with the turrets that set the 33 m top, and Aurangzeb's barbican.
	var west := Basis(Vector3.UP, -PI * 0.5)
	IU.gate(lm, "Red", "Marble", Vector3(-245, 0, -1), west, 34.0, 25.0, 22.0, 9.0, 14.0, 5.2,
		28.0, 5)
	for sz in [-1.0, 1.0]:
		IU.wall_run(lm, "Red", Vector2(-257, sz * 17.0), Vector2(-287, sz * 17.0), -1.0, 14.0, 4.0)
	U.arch_wall(lm, "Red", Vector3(-287, 0, -1), west, 38.0, 14.0, 4.0, 7.0, 10.0)
	# Chhatta Chowk (vaulted bazaar) and the Naubat Khana across the outer court.
	lm.box("Red", Vector3(-197, 4.25, -1), Vector3(74.0, 8.5, 15.0))
	for s in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
		IU.arcade(lm, "Recess", Vector3(-197, 0, s * 7.55), b, 16, 4.5, 2.8, 4.8)
	lm.box("Paving", Vector3(-80, 0.05, 0), Vector3(160.0, 0.1, 110.0))
	IU.gate(lm, "Red", "Marble", Vector3(0, 0, 0), west, 34.0, 15.0, 14.0, 9.0, 12.0, 3.0, 17.0, 0)
	lm.box("Red", Vector3(0, 17.5, 0), Vector3(26.0, 5.0, 10.0))
	for k in 3:
		U.chhatri(lm, "Marble", "Marble", Vector3((float(k) - 1.0) * 8.0, 20.1, 0), 4.0, 1.8, 2.2)
	# Diwan-i-Am: nine-arch hall on its plinth, the throne alcove on the back.
	lm.box("Paving", Vector3(60, 0.05, 0), Vector3(104.0, 0.1, 120.0))
	lm.box("Red", Vector3(125, 0.6, 0), Vector3(36.0, 1.2, 64.0))
	lm.box("Red", Vector3(125, 6.7, 0), Vector3(30.0, 11.0, 60.0))
	lm.box("Marble", Vector3(125, 12.5, 0), Vector3(31.2, 0.9, 61.2))
	var wb := Basis(Vector3.UP, -PI * 0.5)
	for k in 9:
		var pz := (float(k) - 4.0) * 6.1
		IU.arch_panel(lm, "Marble", Vector3(109.95, 1.2, pz), wb, 5.0, 8.8)
		IU.arch_panel(lm, "Recess", Vector3(109.9, 1.2, pz), wb, 4.0, 8.0)
	for sz in [-1.0, 1.0]:
		for sx in [-1.0, 1.0]:
			U.chhatri(lm, "Marble", "Marble", Vector3(125 + sx * 12.0, 13.0, sz * 26.0), 4.0, 2.0, 2.4)
	lm.box("Marble", Vector3(142.5, 5.0, 0), Vector3(5.0, 8.0, 11.0))
	U.chhatri(lm, "Marble", "Gilt", Vector3(142.5, 9.0, 0), 6.0, 1.6, 2.6)
	# The river wall's marble pavilions: x, z, width (Z), depth (X), height.
	for e in [[249.0, -4.0, 32.0, 14.0, 7.5], [249.0, -50.0, 28.0, 14.0, 7.0],
			[249.0, -88.0, 30.0, 20.0, 8.5], [242.0, -127.0, 28.0, 16.0, 6.0],
			[256.0, -180.0, 14.0, 10.0, 7.0]]:
		_pavilion(lm, float(e[0]), float(e[1]), float(e[2]), float(e[3]), float(e[4]))
	lm.frustum("Marble", Vector3(262, -1.0, -51), 4.7, 4.5, 11.0, 8)
	U.chhatri(lm, "Marble", "Gilt", Vector3(262, 10.0, -51), 6.0, 2.2, 3.0)
	# Moti Masjid, Mumtaz Mahal, Shahi Burj and the Hayat Bakhsh garden pool.
	lm.box("Marble", Vector3(203, 2.8, -128), Vector3(12.0, 5.6, 24.0))
	for k in 3:
		U.dome(lm, "Marble", Vector3(203, 5.6, -128 + (float(k) - 1.0) * 8.0), 2.9, 3.4, 14, 5)
	lm.box("Red", Vector3(247, 3.5, 126), Vector3(14.0, 7.0, 40.0))
	lm.box("Marble", Vector3(258, 4.5, -326), Vector3(10.0, 9.0, 10.0))
	U.chhatri(lm, "Marble", "Gilt", Vector3(258, 9.0, -326), 7.0, 2.0, 3.0)
	lm.box("Lawn", Vector3(150, 0.05, -235), Vector3(100.0, 0.1, 90.0))
	lm.box("Paving", Vector3(150, 0.12, -235), Vector3(30.0, 0.1, 30.0))
	lm.box("Red", Vector3(150, 3.0, -235), Vector3(8.0, 6.0, 8.0))
	U.chhatri(lm, "Red", "Marble", Vector3(150, 6.0, -235), 6.0, 1.5, 2.4)
	# British barracks (now museums) south of the palace court.
	for e in [[-70.0, 215.0, 70.0], [-70.0, 250.0, 70.0], [60.0, 230.0, 60.0]]:
		lm.box("Red", Vector3(float(e[0]), 4.5, float(e[1])), Vector3(float(e[2]), 9.0, 16.0))
		lm.box("Marble", Vector3(float(e[0]), 9.2, float(e[1])), Vector3(float(e[2]) + 1.0, 0.5, 17.0))
	# Delhi Gate in the south wall.
	IU.gate(lm, "Red", "Marble", Vector3(-62, 0, 428), Basis(), 30.0, 21.0, 16.0, 8.0, 13.0, 4.5,
		24.0, 3)
	lm.commit(model)

## One white marble pavilion on the river wall: hall block, a cornice, five
## arches on the courtyard face and kiosks at the roof corners.
static func _pavilion(lm: LandmarkMesh, x: float, z: float, w: float, d: float, h: float) -> void:
	lm.box("Marble", Vector3(x, h * 0.5, z), Vector3(d, h, w))
	lm.box("Marble", Vector3(x, h + 0.3, z), Vector3(d + 1.0, 0.6, w + 1.0))
	var wb := Basis(Vector3.UP, -PI * 0.5)
	IU.arcade(lm, "Recess", Vector3(x - d * 0.5 - 0.05, 0.4, z), wb, 5, w / 5.4, w / 7.0, h * 0.7)
	for sz in [-1.0, 1.0]:
		U.chhatri(lm, "Marble", "Marble", Vector3(x, h + 0.6, z + sz * (w * 0.5 - 2.2)), 3.4, 1.4, 1.8)

## Humayun's Tomb (47 m): the first Mughal garden-tomb. A red sandstone
## body with white marble iwans and niche panels, chamfered corners,
## kiosks and a marble double dome on its drum, all on the 7 m arcaded
## terrace in the walled char bagh, with the west and south gateways.
static func humayuns_tomb(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("stone", "#9E4A33", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE5D6", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#3F342C", 2.0))
	lm.use("Rubble", LandmarkMaterials.pbr("stone", "#8A7C68", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C2B093", 4.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6C8C4C", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Red", Vector3(0, 3.5, 0), Vector3(98.0, 7.0, 98.0))
	lm.box("Marble", Vector3(0, 7.15, 0), Vector3(54.0, 0.3, 54.0))
	lm.box("Red", Vector3(0, 7.9, 0), Vector3(52.0, 1.2, 52.0))
	var h := 22.5
	var c := 6.0
	var plan := PackedVector2Array([Vector2(-h + c, -h), Vector2(h - c, -h), Vector2(h, -h + c),
		Vector2(h, h - c), Vector2(h - c, h), Vector2(-h + c, h), Vector2(-h, h - c), Vector2(-h, -h + c)])
	lm.poly_prism("Red", plan, 8.5, 26.5)
	lm.poly_prism("Marble", PackedVector2Array([Vector2(-h + c - 0.5, -h - 0.8), Vector2(h - c + 0.5, -h - 0.8),
		Vector2(h + 0.8, -h + c - 0.5), Vector2(h + 0.8, h - c + 0.5), Vector2(h - c + 0.5, h + 0.8),
		Vector2(-h + c - 0.5, h + 0.8), Vector2(-h - 0.8, h - c + 0.5), Vector2(-h - 0.8, -h + c - 0.5)]),
		26.5, 27.6)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Terrace: 14 arched cells either side of a central stair.
		for k in 15:
			if k != 7:
				IU.arch_panel(lm, "Recess", b * Vector3((float(k) - 7.0) * 6.2, 0.4, 49.05), b, 3.4, 5.4)
		IU.stairs(lm, "Red", b * Vector3(0, 0, 49.0), b, 12.0, 7, 1.0, 1.0)
		# Iwan: marble frame round a deep pointed recess, niche panels beside it.
		U.arch_wall(lm, "Marble", b * Vector3(0, 8.5, h + 0.7), b, 17.0, 19.0, 1.4, 9.0, 14.0)
		IU.arch_panel(lm, "Recess", b * Vector3(0, 8.5, h + 0.04), b, 9.0, 14.0)
		for sx in [-1.0, 1.0]:
			for y in [11.0, 18.5]:
				IU.arch_panel(lm, "Marble", b * Vector3(sx * 12.8, y, h + 0.04), b, 5.0, 6.6)
				IU.arch_panel(lm, "Recess", b * Vector3(sx * 12.8, y, h + 0.08), b, 3.8, 5.8)
		var nb := Basis(Vector3.UP, PI * 0.25 + PI * 0.5 * float(side))
		for y in [11.0, 18.5]:
			IU.arch_panel(lm, "Marble", nb * Vector3(0, y, 27.62), nb, 5.0, 6.6)
			IU.arch_panel(lm, "Recess", nb * Vector3(0, y, 27.66), nb, 3.8, 5.8)
		U.chhatri(lm, "Marble", "Marble", b * Vector3(14.0, 27.6, 14.0), 5.4, 3.2, 3.0)
		U.chhatri(lm, "Marble", "Marble", b * Vector3(0, 27.6, 15.5), 3.4, 2.4, 2.2)
	# Double dome: 16-sided drum, bulb dome and the brass finial.
	lm.frustum("Marble", Vector3(0, 27.6, 0), 7.8, 7.6, 6.9, 16)
	lm.frustum("Marble", Vector3(0, 34.2, 0), 8.3, 8.3, 0.4, 16)
	lm.lathe("Marble", Vector3(0, 34.5, 0), PackedVector2Array([Vector2(7.6, 0), Vector2(8.2, 1.3),
		Vector2(8.3, 2.8), Vector2(7.5, 4.6), Vector2(5.6, 6.2), Vector2(3.0, 7.3), Vector2(0.7, 7.9),
		Vector2(0.0, 8.0)]), 32)
	U.finial(lm, "Gilt", Vector3(0, 42.3, 0), 4.7, 0.5)
	# Char bagh: lawns, paved walks and water channels inside the rubble wall.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Lawn", Vector3(sx * 94.0, 0.04, sz * 94.0), Vector3(172.0, 0.08, 172.0))
	lm.box("Paving", Vector3(0, 0.07, 0), Vector3(360.0, 0.1, 9.0))
	lm.box("Paving", Vector3(0, 0.07, 0), Vector3(9.0, 0.1, 360.0))
	for k in [-90.0, 90.0]:
		lm.box("Paving", Vector3(0, 0.06, k), Vector3(360.0, 0.1, 5.0))
		lm.box("Paving", Vector3(k, 0.06, 0), Vector3(5.0, 0.1, 360.0))
		lm.box("Water", Vector3(k, 0.12, 0), Vector3(10.0, 0.1, 10.0))
		lm.box("Water", Vector3(0, 0.12, k), Vector3(10.0, 0.1, 10.0))
	for s in [-1.0, 1.0]:
		lm.box("Water", Vector3(s * 114.0, 0.13, 0), Vector3(132.0, 0.1, 2.2))
		lm.box("Water", Vector3(0, 0.13, s * 114.0), Vector3(2.2, 0.1, 132.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# South and west walls carry the gateways (16 m, two storeys).
		var gated := side == 0 or side == 3
		var runs: Array = [[-180.0, -12.0], [12.0, 180.0]] if gated else [[-180.0, 180.0]]
		for r in runs:
			IU.wall_run(lm, "Rubble", IU.xz(b * Vector3(float(r[0]), 0, 180.0)),
				IU.xz(b * Vector3(float(r[1]), 0, 180.0)), -1.0, 6.0, 3.0)
		if gated:
			IU.gate(lm, "Rubble", "Marble", b * Vector3(0, 0, 180.0), b, 24.0, 14.0, 12.0, 8.0, 11.0,
				2.4, 15.0, 3)
	# Nai ka Gumbad (the Barber's Tomb) in the south-east quarter.
	lm.box("Red", Vector3(110, 0.9, 62), Vector3(16.0, 1.8, 16.0))
	lm.box("Red", Vector3(110, 5.2, 62), Vector3(10.0, 7.0, 10.0))
	U.dome(lm, "Marble", Vector3(110, 8.7, 62), 4.2, 4.0, 20, 6)
	lm.commit(model)

## Jama Masjid (51 m to the minaret kiosks): the red sandstone mosque on
## its 10 m plinth, the 99 m sahn with arcades and the marble tank, the
## three gateways with their stairs, the prayer hall (west) with its
## pishtaq, ten cusped arches and three black-striped marble domes, and
## the two 41 m minarets. The prayer hall is on -X (Mecca), the royal
## gate on +X.
static func jama_masjid_delhi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("stone", "#A04A31", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 3.0))
	lm.use("Black", LandmarkMaterials.pbr("stone", "#2C2825", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#41362E", 2.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A9553B", 4.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Red", Vector3(0, 4.5, 0), Vector3(128.0, 11.0, 128.0))
	lm.box("Paving", Vector3(7.5, 10.05, 0), Vector3(87.0, 0.1, 109.0))
	lm.box("Marble", Vector3(7.5, 10.4, 0), Vector3(17.0, 0.8, 15.0))
	lm.box("Water", Vector3(7.5, 10.82, 0), Vector3(15.0, 0.1, 13.0))
	# Arcades round the sahn: north, south and east, arched bays on the inner face.
	var east := Basis(Vector3.UP, PI * 0.5)
	lm.box("Red", Vector3(7.5, 13.25, -58.5), Vector3(87.0, 6.5, 10.0))
	lm.box("Red", Vector3(7.5, 13.25, 58.5), Vector3(87.0, 6.5, 10.0))
	lm.box("Red", Vector3(57.0, 13.25, 0), Vector3(12.0, 6.5, 109.0))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(7.5, 16.75, s * 58.5), Vector3(87.0, 0.5, 10.4))
		IU.arcade(lm, "Recess", Vector3(7.5, 10.1, s * 53.45), Basis(Vector3.UP, 0.0 if s < 0.0 else PI),
			17, 5.1, 3.6, 4.8)
		U.chhatri(lm, "Marble", "Marble", Vector3(51, 17.0, s * 54.5), 5.0, 2.4, 2.6)
		U.chhatri(lm, "Marble", "Marble", Vector3(-36, 17.0, s * 54.5), 5.0, 2.4, 2.6)
	lm.box("Marble", Vector3(57.0, 16.75, 0), Vector3(12.4, 0.5, 109.0))
	IU.arcade(lm, "Recess", Vector3(50.95, 10.1, 0), Basis(Vector3.UP, -PI * 0.5), 19, 5.5, 3.6, 4.8)
	# Gateways: the three-storey royal gate east, two-storey gates north and south.
	IU.gate(lm, "Red", "Marble", Vector3(57, 10, 0), east, 30.0, 19.0, 12.0, 10.0, 14.0, 2.6, 22.0, 5)
	IU.gate(lm, "Red", "Marble", Vector3(7.5, 10, -58.5), Basis(Vector3.UP, PI), 22.0, 14.0, 12.0, 8.0,
		10.0, 2.2, 16.0, 3)
	IU.gate(lm, "Red", "Marble", Vector3(7.5, 10, 58.5), Basis(), 22.0, 14.0, 12.0, 8.0, 10.0, 2.2,
		16.0, 3)
	IU.stairs(lm, "Red", Vector3(64, 0, 0), east, 28.0, 20, 0.5, 0.7)
	IU.stairs(lm, "Red", Vector3(7.5, 0, -64), Basis(Vector3.UP, PI), 20.0, 20, 0.5, 0.7)
	IU.stairs(lm, "Red", Vector3(7.5, 0, 64), Basis(), 20.0, 20, 0.5, 0.7)
	# Prayer hall: 61 x 27 m, pishtaq, five cusped arches either side, bands.
	lm.box("Red", Vector3(-49.5, 17.5, 0), Vector3(27.0, 15.0, 61.0))
	lm.box("Marble", Vector3(-49.5, 25.4, 0), Vector3(28.0, 0.8, 62.0))
	for y in [19.6, 22.4]:
		lm.box("Marble", Vector3(-35.9, y, 0), Vector3(0.2, 0.6, 61.0))
	lm.box("Black", Vector3(-35.9, 21.0, 0), Vector3(0.2, 0.5, 61.0))
	for s in [-1.0, 1.0]:
		for k in 5:
			var z: float = s * (10.1 + 4.2 * float(k))
			IU.arch_panel(lm, "Marble", Vector3(-35.95, 10.1, z), east, 3.9, 8.8)
			IU.arch_panel(lm, "Recess", Vector3(-35.9, 10.1, z), east, 3.2, 8.1)
		U.chhatri(lm, "Marble", "Marble", Vector3(-35.6, 31.0, s * 6.6), 2.6, 2.0, 2.2)
	U.arch_wall(lm, "Marble", Vector3(-35.2, 10, 0), east, 15.0, 21.0, 1.6, 9.0, 15.0)
	IU.arch_panel(lm, "Recess", Vector3(-35.95, 10.1, 0), east, 9.0, 15.0)
	for k in 3:
		var z := (float(k) - 1.0) * 20.0
		var r := 8.2 if k == 1 else 7.6
		var dh := 12.5 if k == 1 else 11.5
		lm.frustum("Marble", Vector3(-49.5, 25.8, z), r * 0.62, r * 0.6, 1.8, 16)
		IU.striped_onion(lm, "Marble", "Black", Vector3(-49.5, 27.6, z), r, dh)
		U.finial(lm, "Gilt", Vector3(-49.5, 27.6 + dh - 0.4, z), 4.0, 0.4)
	# Minarets: striped red and marble shafts, three balconies, a kiosk at 51 m.
	for s in [-1.0, 1.0]:
		var p := Vector3(-38.0, 10.0, s * 34.5)
		lm.box("Red", p + Vector3(0, 2.25, 0), Vector3(8.4, 4.5, 8.4))
		lm.frustum("Red", p + Vector3(0, 4.5, 0), 3.2, 2.6, 31.0, 16)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var tang := Vector3(-sin(a), 0, cos(a))
			lm.beam("Marble", p + Vector3(cos(a) * 3.3, 4.5, sin(a) * 3.3),
				p + Vector3(cos(a) * 2.7, 35.5, sin(a) * 2.7), 0.7, 0.2, tang)
		for y in [14.0, 23.5, 32.0]:
			lm.lathe("Marble", p + Vector3(0, y, 0), PackedVector2Array([Vector2(3.0, 0), Vector2(4.4, 0.7),
				Vector2(4.4, 1.6), Vector2(4.0, 1.6)]), 16)
		U.chhatri(lm, "Marble", "Marble", p + Vector3(0, 35.5, 0), 5.4, 2.6, 2.4)
	lm.commit(model)
