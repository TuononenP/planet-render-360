class_name LandmarkIndMughal
extends RefCounted

## Two Mughal monuments of Delhi in true metres: Humayun's Tomb and the
## Jama Masjid (the Red Fort is in landmark_ind_red_fort.gd). Built in
## the monument's own frame (the registry yaw turns it onto the real
## bearing).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")
const ID = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_detail.gd")

## Humayun's Tomb (47 m to the brass finial; 1565-72): the first Mughal
## garden-tomb. The 7 m arcaded terrace (about 95 m square, 14 arched
## cells a side either side of the stair set into each face) carries
## the red sandstone tomb, a square with chamfered corners: on each
## face a white-marble-framed iwan rising past the parapet over a
## two-storey screen, two storeys of deep arched niches either side and
## on each chamfer, then the pillared kiosks of the roof, the 32-sided
## drum and the white marble double dome (42.5 m). Round it the walled
## char bagh with its sunken channels and pools, the two-storey west and
## south gateways (16 m), the baradari of the east wall and the Nai ka
## Gumbad.
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
	_humayun_terrace(lm)
	var h := 22.5
	var c := 6.0
	lm.box("Marble", Vector3(0, 7.15, 0), Vector3(54.0, 0.3, 54.0))
	lm.box("Red", Vector3(0, 7.9, 0), Vector3(52.0, 1.2, 52.0))
	var plan := PackedVector2Array([Vector2(-h + c, -h), Vector2(h - c, -h), Vector2(h, -h + c),
		Vector2(h, h - c), Vector2(h - c, h), Vector2(-h + c, h), Vector2(-h, h - c), Vector2(-h, -h + c)])
	lm.poly_prism("Red", plan, 8.5, 26.5)
	lm.poly_prism("Marble", PackedVector2Array([Vector2(-h + c - 0.5, -h - 0.8), Vector2(h - c + 0.5, -h - 0.8),
		Vector2(h + 0.8, -h + c - 0.5), Vector2(h + 0.8, h - c + 0.5), Vector2(h - c + 0.5, h + 0.8),
		Vector2(-h + c - 0.5, h + 0.8), Vector2(-h - 0.8, h - c + 0.5), Vector2(-h - 0.8, -h + c - 0.5)]),
		26.5, 27.6)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Iwan: a marble pishtaq rising past the parapet round a deep pointed
		# recess, the two-storey screen of doors and windows at its back.
		ID.arcade_wall(lm, "Marble", "", b * Vector3(0, 8.5, h), b, 17.0, 21.0, 2.6, 1, 10.0, 16.0)
		lm.box("Marble", b * Vector3(0, 29.8, h + 1.3), Vector3(17.6, 0.6, 2.8), b)
		ID.arcade_wall(lm, "Red", "Recess", b * Vector3(0, 8.5, h), b, 10.0, 14.0, 0.3, 3, 2.0, 4.6, "pointed", 0.4)
		ID.arcade_wall(lm, "Marble", "Recess", b * Vector3(0, 15.6, h + 0.3), b, 10.0, 7.0, 0.2, 3, 2.0, 4.8,
			"pointed", 0.6)
		# Two storeys of deep arched niches either side of the iwan.
		for sx in [-1.0, 1.0]:
			for t in [[8.5, 9.0, 7.6], [17.9, 8.6, 7.2]]:
				ID.arcade_wall(lm, "Red", "Recess", b * Vector3(sx * 12.5, float(t[0]), h), b, 7.8, float(t[1]), 1.0, 1,
					4.6, float(t[2]))
				ID.arcade_wall(lm, "Marble", "Recess", b * Vector3(sx * 12.5, float(t[0]) + 1.0, h), b, 3.4,
					float(t[2]) * 0.62, 0.4, 1, 1.6, float(t[2]) * 0.5)
		var nb := Basis(Vector3.UP, PI * 0.25 + PI * 0.5 * float(side))
		var cd := (h - c * 0.5) * sqrt(2.0)
		for t in [[8.5, 9.0, 7.6], [17.9, 8.6, 7.2]]:
			ID.arcade_wall(lm, "Red", "Recess", nb * Vector3(0, float(t[0]), cd), nb, 8.2, float(t[1]), 1.0, 1,
				4.8, float(t[2]))
		# Roof kiosks: the large octagonal corner chhatris and a pair on each
		# iwan's shoulders.
		ID.chhatri(lm, "Marble", "Marble", b * Vector3(14.0, 27.6, 14.0), 5.6, 3.6, 2.6)
		for sx in [-1.0, 1.0]:
			ID.chhatri(lm, "Marble", "Marble", b * Vector3(sx * 7.6, 30.1, h + 0.6), 1.6, 1.0, 1.1, 6)
	# Double dome: 32-sided drum with ribs and bands, marble bulb, finial.
	lm.frustum("Marble", Vector3(0, 27.6, 0), 7.8, 7.6, 6.9, 32)
	for k in 32:
		var a := TAU * float(k) / 32.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Marble", Vector3(0, 30.6, 0) + d * 7.75, Vector3(0.45, 5.4, 0.3), Basis.looking_at(d), 0.0)
	for y in [27.8, 33.6]:
		lm.frustum("Marble", Vector3(0, y, 0), 8.0, 8.0, 0.45, 32)
	lm.frustum("Marble", Vector3(0, 34.2, 0), 8.3, 8.3, 0.4, 32)
	lm.lathe("Marble", Vector3(0, 34.5, 0), PackedVector2Array([Vector2(7.6, 0), Vector2(7.95, 0.6),
		Vector2(8.2, 1.3), Vector2(8.32, 2.0), Vector2(8.3, 2.8), Vector2(8.0, 3.8), Vector2(7.5, 4.6),
		Vector2(6.6, 5.4), Vector2(5.6, 6.2), Vector2(4.3, 6.8), Vector2(3.0, 7.3), Vector2(1.8, 7.65),
		Vector2(0.7, 7.9), Vector2(0.0, 8.0)]), 40)
	lm.lathe("Marble", Vector3(0, 42.1, 0), PackedVector2Array([Vector2(1.1, 0), Vector2(1.4, 0.3),
		Vector2(0.9, 0.6), Vector2(0.0, 0.7)]), 16)
	U.finial(lm, "Gilt", Vector3(0, 42.3, 0), 4.7, 0.5)
	_humayun_garden(lm)
	lm.commit(model)

## The terrace: a 7 m plinth with a stair set into the middle of each
## face and seven arched cells either side of it (each a deep pointed
## recess with its door), a moulded band and the paved top.
static func _humayun_terrace(lm: LandmarkMesh) -> void:
	var f := 46.8
	var slot := 4.6
	lm.box("Red", Vector3(0, 3.5, 0), Vector3(79.6, 7.0, 79.6))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for sx in [-1.0, 1.0]:
			var cx: float = sx * (slot + (f - slot) * 0.5)
			lm.box("Red", b * Vector3(cx, 3.5, f - 3.5), Vector3(f - slot, 7.0, 7.0), b)
			ID.arcade_wall(lm, "Red", "Recess", b * Vector3(cx, 0.0, f), b, f - slot, 6.8, 0.9, 7, 3.6, 5.4)
		IU.stairs(lm, "Red", b * Vector3(0, 0, f), b, slot * 2.0, 7, 1.0, 1.0)
		lm.box("Marble", b * Vector3(0, 6.85, f + 0.5), Vector3(f * 2.0 + 1.0, 0.3, 1.0), b)
	lm.box("Paving", Vector3(0, 7.02, 0), Vector3(93.0, 0.06, 93.0))

## Char bagh inside the rubble walls: lawns, raised walks with their
## sunken water channels and pools, blind arcades on the walls' inner
## faces, the west and south gateways, the east wall's baradari and the
## Nai ka Gumbad in the south-east quarter.
static func _humayun_garden(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Lawn", Vector3(sx * 94.0, 0.04, sz * 94.0), Vector3(172.0, 0.08, 172.0))
	lm.box("Paving", Vector3(0, 0.07, 0), Vector3(360.0, 0.1, 9.0))
	lm.box("Paving", Vector3(0, 0.07, 0), Vector3(9.0, 0.1, 360.0))
	for k in [-90.0, 90.0]:
		lm.box("Paving", Vector3(0, 0.06, k), Vector3(360.0, 0.1, 5.0))
		lm.box("Paving", Vector3(k, 0.06, 0), Vector3(5.0, 0.1, 360.0))
		for e in [[k, 0.0], [0.0, k]]:
			lm.box("Red", Vector3(float(e[0]), 0.25, float(e[1])), Vector3(11.0, 0.5, 11.0))
			lm.box("Water", Vector3(float(e[0]), 0.52, float(e[1])), Vector3(9.6, 0.06, 9.6))
	for s in [-1.0, 1.0]:
		for e in [[s * 114.0, 0.0, 132.0, 2.2], [0.0, s * 114.0, 2.2, 132.0]]:
			lm.box("Red", Vector3(float(e[0]), 0.15, float(e[1])), Vector3(float(e[2]) + 1.0, 0.3, float(e[3]) + 1.0))
			lm.box("Water", Vector3(float(e[0]), 0.32, float(e[1])), Vector3(float(e[2]), 0.06, float(e[3])))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# South and west walls carry the gateways (16 m, two storeys).
		var gated := side == 0 or side == 3
		var runs: Array = [[-180.0, -12.0], [12.0, 180.0]] if gated else [[-180.0, 180.0]]
		for r in runs:
			var x0: float = r[0]
			var x1: float = r[1]
			IU.wall_run(lm, "Rubble", IU.xz(b * Vector3(x0, 0, 180.0)), IU.xz(b * Vector3(x1, 0, 180.0)), 0.0, 6.0, 3.0)
			var ib := b * Basis(Vector3.UP, PI)
			var bays := int((x1 - x0) / 6.0)
			ID.arcade_wall(lm, "Rubble", "Recess", b * Vector3((x0 + x1) * 0.5, 0.4, 178.5), ib, x1 - x0, 5.0, 0.4,
				bays, 3.2, 3.8)
		if gated:
			IU.gate(lm, "Rubble", "Marble", b * Vector3(0, 0, 180.0), b, 24.0, 14.0, 12.0, 8.0, 11.0,
				2.4, 11.0, 3, "Recess")
	# Baradari: the twelve-doored pavilion at the middle of the east wall.
	var bp := Vector3(178.0, 0, 0)
	lm.box("Red", bp + Vector3(-5.0, 0.6, 0), Vector3(12.0, 1.2, 26.0))
	ID.arcade_wall(lm, "Red", "", bp + Vector3(-9.0, 1.2, 0), Basis(Vector3.UP, -PI * 0.5), 22.0, 6.0, 0.8, 5, 2.8,
		4.6, "cusped", 0.0, true)
	lm.box("Red", bp + Vector3(-3.5, 4.2, 0), Vector3(9.0, 6.0, 22.0))
	ID.chhajja_ring(lm, "Red", bp + Vector3(-5.0, 7.2, 0), 9.0, 22.0, 1.0, 0.4, 2.4)
	lm.box("Red", bp + Vector3(-5.0, 7.5, 0), Vector3(9.4, 0.6, 22.4))
	# Nai ka Gumbad (the Barber's Tomb) in the south-east quarter.
	lm.box("Red", Vector3(110, 0.9, 62), Vector3(16.0, 1.8, 16.0))
	lm.box("Red", Vector3(110, 5.2, 62), Vector3(10.0, 7.0, 10.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		ID.arcade_wall(lm, "Red", "Recess", Vector3(110, 1.8, 62) + b * Vector3(0, 0, 5.0), b, 10.0, 6.8, 0.4, 3,
			2.0, 4.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			ID.chhatri(lm, "Red", "Marble", Vector3(110 + sx * 4.3, 8.7, 62 + sz * 4.3), 1.6, 0.9, 1.0, 6)
	lm.frustum("Marble", Vector3(110, 8.7, 62), 4.0, 4.0, 1.0, 16)
	U.dome(lm, "Marble", Vector3(110, 9.7, 62), 4.2, 4.0, 24, 6)
	U.finial(lm, "Gilt", Vector3(110, 13.6, 62), 1.6, 0.2)

## Jama Masjid (51 m to the minaret kiosks; 1650-56): the red sandstone
## mosque on its 10 m plinth (arched cells round its outer faces), the
## 99 m sahn with its cloister arcades, corner kiosks and the 17 x 15 m
## marble tank, the three-storey east gate and two-storey north and south
## gates up their stairs (35, 39 and 33 steps), the 61 x 27 m prayer hall
## (west) with its pishtaq, ten cusped arches, marble bands with black
## calligraphy panels and three black-striped marble onion domes, and the
## two 41 m minarets with three galleries and marble stripes. The prayer
## hall is on -X (Mecca), the royal gate on +X.
static func jama_masjid_delhi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("stone", "#A04A31", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 3.0))
	lm.use("Black", LandmarkMaterials.pbr("stone", "#2C2825", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#41362E", 2.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A9553B", 4.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Red", Vector3(0, 5.0, 0), Vector3(126.4, 10.0, 126.4))
	# Arched cells round the plinth's outer faces, split by the stairs.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var gap := 0.0 if side == 3 else 15.0
		var runs: Array = [[-63.2, 63.2]] if gap == 0.0 else [[-63.2, -gap], [gap, 63.2]]
		for r in runs:
			var x0: float = r[0]
			var x1: float = r[1]
			var bays := int((x1 - x0) / 5.2)
			ID.arcade_wall(lm, "Red", "Recess", b * Vector3((x0 + x1) * 0.5, 0, 63.2), b, x1 - x0, 9.4, 0.8, bays, 3.2, 6.0)
			ID.chhajja(lm, "Red", b * Vector3(x0, 9.4, 64.0), b * Vector3(x1, 9.4, 64.0), b * Vector3(0, 0, 1), 0.8, 0.4,
				3.0)
	lm.box("Paving", Vector3(7.5, 10.05, 0), Vector3(87.0, 0.1, 109.0))
	lm.box("Marble", Vector3(7.5, 10.4, 0), Vector3(17.0, 0.8, 15.0))
	lm.box("Water", Vector3(7.5, 10.82, 0), Vector3(15.0, 0.1, 13.0))
	lm.box("Marble", Vector3(7.5, 11.1, 0), Vector3(0.8, 0.6, 0.8))
	_jama_cloisters(lm)
	# Gateways: the three-storey royal gate east, two-storey gates north and south.
	var east := Basis(Vector3.UP, PI * 0.5)
	IU.gate(lm, "Red", "Marble", Vector3(57, 10, 0), east, 30.0, 19.0, 12.0, 10.0, 14.0, 2.6, 22.0, 5, "Recess")
	IU.gate(lm, "Red", "Marble", Vector3(7.5, 10, -58.5), Basis(Vector3.UP, PI), 22.0, 14.0, 12.0, 8.0,
		10.0, 2.2, 16.0, 3, "Recess")
	IU.gate(lm, "Red", "Marble", Vector3(7.5, 10, 58.5), Basis(), 22.0, 14.0, 12.0, 8.0, 10.0, 2.2,
		16.0, 3, "Recess")
	IU.stairs(lm, "Red", Vector3(63.2, 0, 0), east, 28.0, 35, 10.0 / 35.0, 0.4)
	IU.stairs(lm, "Red", Vector3(7.5, 0, -63.2), Basis(Vector3.UP, PI), 20.0, 39, 10.0 / 39.0, 0.38)
	IU.stairs(lm, "Red", Vector3(7.5, 0, 63.2), Basis(), 20.0, 33, 10.0 / 33.0, 0.42)
	_jama_prayer_hall(lm)
	for s in [-1.0, 1.0]:
		_jama_minaret(lm, Vector3(-38.0, 10.0, s * 34.5))
	lm.commit(model)

## Cloisters round the sahn: north, south and east ranges with an open
## arcade on the court side, a blind arcade outside, a chhajja and a
## parapet, and the pillared kiosks at the corners.
static func _jama_cloisters(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var inner := Basis(Vector3.UP, 0.0 if s < 0.0 else PI)
		lm.box("Red", Vector3(7.5, 13.25, s * 61.5), Vector3(87.0, 6.5, 4.0))
		lm.box("Red", Vector3(7.5, 16.6, s * 58.5), Vector3(87.0, 0.6, 10.0))
		ID.arcade_wall(lm, "Red", "", Vector3(7.5, 10.1, s * 54.6), inner, 87.0, 6.2, 1.2, 17, 3.6, 4.8, "cusped", 0.0,
			true)
		ID.arcade_wall(lm, "Red", "", Vector3(7.5, 10.1, s * 58.5), inner, 87.0, 6.2, 0.9, 17, 3.6, 4.8, "pointed", 0.0,
			true)
		lm.box("Marble", Vector3(7.5, 17.05, s * 58.5), Vector3(87.0, 0.3, 10.4))
		ID.chhajja(lm, "Red", Vector3(-36, 16.2, s * 53.4), Vector3(51, 16.2, s * 53.4), Vector3(0, 0, -s), 1.0, 0.45,
			2.6)
		lm.box("Red", Vector3(7.5, 17.6, s * 53.8), Vector3(87.0, 0.9, 0.4))
		for x in [51.0, -36.0]:
			ID.chhatri_fit(lm, "Marble", "Marble", Vector3(x, 17.2, s * 54.5), 5.0, 5.0)
	lm.box("Red", Vector3(61.0, 13.25, 0), Vector3(4.0, 6.5, 109.0))
	lm.box("Red", Vector3(57.0, 16.6, 0), Vector3(12.0, 0.6, 109.0))
	lm.box("Marble", Vector3(57.0, 17.05, 0), Vector3(12.4, 0.3, 109.0))
	ID.arcade_wall(lm, "Red", "", Vector3(52.2, 10.1, 0), Basis(Vector3.UP, -PI * 0.5), 99.0, 6.2, 1.2, 19, 3.6, 4.8,
		"cusped", 0.0, true)
	ID.chhajja(lm, "Red", Vector3(51.0, 16.2, -53), Vector3(51.0, 16.2, 53), Vector3(-1, 0, 0), 1.0, 0.45, 2.6)

## Prayer hall: 61 x 27 m under a marble-capped parapet, the pishtaq with
## its cusped arch, five cusped arches either side opening into the
## hall, marble bands with black calligraphy panels, slim corner turrets,
## kiosks flanking the pishtaq and the three striped onion domes on
## their drums.
static func _jama_prayer_hall(lm: LandmarkMesh) -> void:
	var east := Basis(Vector3.UP, PI * 0.5)
	lm.box("Red", Vector3(-50.4, 17.5, 0), Vector3(25.2, 15.0, 61.0))
	lm.box("Marble", Vector3(-49.5, 25.4, 0), Vector3(28.0, 0.8, 62.0))
	for s in [-1.0, 1.0]:
		ID.arcade_wall(lm, "Red", "Recess", Vector3(-37.8, 10.0, s * 19.5), east, 22.0, 14.2, 1.0, 5, 3.4, 8.6, "cusped")
		for k in 5:
			var z: float = s * (10.6 + 4.4 * float(k))
			lm.box("Marble", Vector3(-36.7, 21.2, z), Vector3(0.2, 2.2, 3.6))
			lm.box("Black", Vector3(-36.6, 21.2, z), Vector3(0.12, 1.4, 2.8))
		ID.chhatri_fit(lm, "Marble", "Marble", Vector3(-35.6, 31.0, s * 6.6), 2.6, 4.6)
		# Slim octagonal turrets at the hall's four corners.
		for x in [-36.4, -63.0]:
			var p := Vector3(x, 10.0, s * 30.6)
			lm.frustum("Red", p, 1.3, 1.1, 17.0, 8, PI / 8.0)
			for y in [5.0, 10.0, 15.0]:
				lm.frustum("Marble", p + Vector3(0, y, 0), 1.3, 1.3, 0.3, 8, PI / 8.0)
			ID.chhatri_fit(lm, "Marble", "Marble", p + Vector3(0, 17.0, 0), 2.4, 3.6)
	ID.chhajja(lm, "Red", Vector3(-36.8, 25.0, -30.5), Vector3(-36.8, 25.0, 30.5), Vector3(1, 0, 0), 1.1, 0.5, 2.6)
	lm.box("Red", Vector3(-37.3, 26.3, 0), Vector3(0.5, 1.2, 61.0))
	for y in [19.6, 22.4]:
		lm.box("Marble", Vector3(-37.75, y, 0), Vector3(0.2, 0.6, 61.0))
	# Pishtaq: marble frame rising to 30 m round the great cusped arch.
	ID.arcade_wall(lm, "Marble", "Recess", Vector3(-37.8, 10.0, 0), east, 15.0, 21.0, 2.0, 1, 9.0, 15.0, "cusped", 0.0,
		false, 9)
	for k in 3:
		lm.box("Black", Vector3(-35.75, 27.0, (float(k) - 1.0) * 4.2), Vector3(0.12, 2.0, 3.6))
	for s in [-1.0, 1.0]:
		lm.frustum("Marble", Vector3(-35.9, 10.0, s * 7.5), 0.8, 0.7, 21.6, 8, PI / 8.0)
		ID.chhatri_fit(lm, "Marble", "Marble", Vector3(-35.9, 31.6, s * 7.5), 1.8, 3.0)
	for k in 3:
		var z := (float(k) - 1.0) * 20.0
		var r := 8.2 if k == 1 else 7.6
		var dh := 12.5 if k == 1 else 11.5
		lm.frustum("Marble", Vector3(-49.5, 25.8, z), r * 0.62, r * 0.6, 1.8, 32)
		lm.frustum("Marble", Vector3(-49.5, 27.2, z), r * 0.7, r * 0.7, 0.4, 32)
		IU.striped_onion(lm, "Marble", "Black", Vector3(-49.5, 27.6, z), r, dh)
		U.finial(lm, "Gilt", Vector3(-49.5, 27.6 + dh - 0.4, z), 4.0, 0.4)

## One minaret on its square base: a tapering 16-sided red shaft with
## eight marble stripes, three corbelled galleries with railings and the
## marble kiosk whose finial is the 51 m top.
static func _jama_minaret(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Red", p + Vector3(0, 2.25, 0), Vector3(8.4, 4.5, 8.4))
	lm.box("Marble", p + Vector3(0, 4.6, 0), Vector3(8.8, 0.3, 8.8))
	lm.frustum("Red", p + Vector3(0, 4.5, 0), 3.2, 2.6, 31.0, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var tang := Vector3(-sin(a), 0, cos(a))
		lm.beam("Marble", p + Vector3(cos(a) * 3.3, 4.5, sin(a) * 3.3),
			p + Vector3(cos(a) * 2.7, 35.5, sin(a) * 2.7), 0.7, 0.2, tang)
	for y in [14.0, 23.5, 32.0]:
		var rr := lerpf(3.2, 2.6, (y - 4.5) / 31.0)
		# Corbels under the gallery, the floor, posts and a rail.
		lm.lathe("Marble", p + Vector3(0, y - 1.2, 0), PackedVector2Array([Vector2(rr * 1.02, 0),
			Vector2(rr * 1.15, 0.5), Vector2(4.0, 1.0), Vector2(4.4, 1.2)]), 16)
		for i in 16:
			var a := TAU * (float(i) + 0.5) / 16.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Red", p + d * rr + Vector3(0, y - 1.6, 0), p + d * 4.1 + Vector3(0, y - 0.05, 0), 0.3, 0.3)
		lm.frustum("Marble", p + Vector3(0, y, 0), 4.4, 4.4, 0.3, 16)
		for i in 16:
			var a := TAU * float(i) / 16.0
			lm.box("Marble", p + Vector3(cos(a) * 4.25, y + 0.85, sin(a) * 4.25), Vector3(0.2, 1.1, 0.2),
				Basis(Vector3.UP, -a), 0.0)
		lm.frustum("Marble", p + Vector3(0, y + 1.4, 0), 4.35, 4.35, 0.15, 16)
	ID.chhatri_fit(lm, "Marble", "Marble", p + Vector3(0, 35.5, 0), 5.4, 5.5, 8, true, "Gilt")
