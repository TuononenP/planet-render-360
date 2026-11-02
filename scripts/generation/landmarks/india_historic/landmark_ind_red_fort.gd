extends RefCounted

## The Red Fort (Lal Qila) of Delhi in true metres, built in its own
## frame: the Lahori-Diwan axis is the model X axis, the Lahori Gate
## faces -X (west), the river front is +X and the Delhi Gate is on +Z
## (south). The registry yaw turns it onto the real bearing.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")
const ID = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_detail.gd")

## Red Fort (33 m to the Lahori Gate kiosks; 1639-48): the 2.41 km
## octagon of red sandstone walls, 18 m on the river side rising to
## 22 m on the city side above the filled moat, with kangura merlons and
## round bastions under pillared kiosks; the Lahori Gate (two banded
## octagonal turrets, the iwan, the parapet row of seven marble kiosks)
## behind Aurangzeb's barbican; the vaulted Chhatta Chowk bazaar; the
## Naubat Khana; the Diwan-i-Am (nine engrailed arches by three bays,
## 55 x 18 m, with the marble throne canopy under its Bengal roof); the
## white marble river pavilions (Diwan-i-Khas, Khas Mahal, Rang Mahal,
## Mumtaz Mahal, the Hammam) with the gilt-domed Muthamman Burj; the
## three-domed Moti Masjid; the Hayat Bakhsh garden with the Sawan and
## Bhadon pavilions and the Zafar Mahal; the British barracks; and the
## Delhi Gate with its two stone elephants.
static func red_fort_delhi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("stone", "#A5442C", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EEE9DC", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4A3A32", 2.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B8A58C", 4.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4C", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	var poly := [Vector2(-245, -230), Vector2(-120, -385), Vector2(200, -385), Vector2(272, -300),
		Vector2(265, 280), Vector2(170, 428), Vector2(-150, 428), Vector2(-245, 260)]
	var heights := [21.0, 20.0, 19.0, 18.0, 19.0, 21.0, 22.0, 22.0]
	var lawn := PackedVector2Array()
	for p in poly:
		lawn.append((p as Vector2) * 0.97 + Vector2(10, 20) * 0.03)
	lm.poly_prism("Lawn", lawn, 0.0, 0.04)
	_walls(lm, poly, heights)
	_lahori_gate(lm)
	_chhatta_chowk(lm)
	# The Naubat Khana (drum house) across the outer court: a two-storey
	# gatehouse with an arched passage and arched windows on every face.
	lm.box("Paving", Vector3(-80, 0.05, 0), Vector3(160.0, 0.1, 110.0))
	IU.gate(lm, "Red", "Marble", Vector3(0, 0, 0), Basis(Vector3.UP, -PI * 0.5), 34.0, 15.0, 14.0, 9.0, 12.0,
		3.0, 17.0, 0, "Recess")
	lm.box("Red", Vector3(0, 17.5, 0), Vector3(26.0, 5.0, 10.0))
	for s in [-1.0, 1.0]:
		var fb := Basis(Vector3.UP, -PI * 0.5 if s < 0.0 else PI * 0.5)
		ID.arcade_wall(lm, "Red", "Recess", Vector3(s * 5.0, 15.6, 0), fb, 24.0, 4.6, 0.3, 7, 1.6, 3.4)
	for k in 3:
		ID.chhatri_fit(lm, "Marble", "Marble", Vector3((float(k) - 1.0) * 8.0, 20.1, 0), 4.0, 4.4)
	_diwan_i_am(lm)
	# The river wall's marble pavilions: x, z, width (Z), depth (X), height, arches.
	for e in [[249.0, -4.0, 32.0, 14.0, 7.5, 7], [249.0, -50.0, 28.0, 14.0, 7.0, 5],
			[249.0, -88.0, 30.0, 20.0, 8.5, 5], [242.0, -127.0, 28.0, 16.0, 6.0, 5],
			[256.0, -180.0, 14.0, 10.0, 7.0, 3], [252.0, 60.0, 26.0, 16.0, 7.0, 5]]:
		_pavilion(lm, float(e[0]), float(e[1]), float(e[2]), float(e[3]), float(e[4]), int(e[5]))
	# Muthamman Burj: the octagonal tower on the river wall with its gilt dome.
	lm.frustum("Marble", Vector3(262, 0.0, -51), 4.7, 4.5, 10.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		ID.arcade_wall(lm, "Marble", "Recess", Vector3(262, 4.5, -51) + d * 4.15, Basis(Vector3.UP, PI * 0.5 - a),
			3.4, 4.4, 0.25, 1, 2.0, 3.6, "cusped")
	ID.chhatri_fit(lm, "Marble", "Gilt", Vector3(262, 10.0, -51), 7.0, 8.2)
	_moti_masjid(lm)
	_hayat_bakhsh(lm)
	# British barracks (now museums): two storeys of arched verandas.
	for e in [[-70.0, 215.0, 70.0], [-70.0, 250.0, 70.0], [60.0, 230.0, 60.0]]:
		var bx: float = e[0]
		var bz: float = e[1]
		var bl: float = e[2]
		lm.box("Red", Vector3(bx, 4.5, bz), Vector3(bl, 9.0, 14.0))
		lm.box("Marble", Vector3(bx, 9.2, bz), Vector3(bl + 1.0, 0.5, 17.0))
		for s in [-1.0, 1.0]:
			var fb := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
			var bays := int(bl / 3.6)
			ID.arcade_wall(lm, "Red", "Recess", Vector3(bx, 0, bz + s * 7.0), fb, bl, 4.4, 1.2, bays, 2.2, 3.6, "round")
			ID.arcade_wall(lm, "Red", "Recess", Vector3(bx, 4.5, bz + s * 7.0), fb, bl, 4.2, 1.2, bays, 2.0, 3.2,
				"round", 0.6)
	# Delhi Gate in the south wall, with its two stone elephants.
	IU.gate(lm, "Red", "Marble", Vector3(-62, 0, 428), Basis(), 30.0, 21.0, 16.0, 8.0, 13.0, 4.5,
		24.0, 3, "Recess")
	for sx in [-1.0, 1.0]:
		_elephant(lm, Vector3(-62 + sx * 9.0, 0, 440.0))
	lm.commit(model)

## The curtain walls: battered red sandstone runs with a string course,
## kangura merlons on the outer edge and round bastions every ~110 m.
static func _walls(lm: LandmarkMesh, poly: Array, heights: Array) -> void:
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var h: float = heights[i]
		IU.wall_run(lm, "Red", a, b, 0.0, h, 6.0)
		var out := Vector2((b - a).y, -(b - a).x).normalized()
		if out.dot((a + b) * 0.5 - Vector2(10, 20)) < 0.0:
			out = -out
		# Batter at the foot and a moulded string course under the parapet.
		IU.wall_run(lm, "Red", a + out * 3.6, b + out * 3.6, 0.0, 3.0, 1.4)
		IU.wall_run(lm, "Red", a + out * 3.2, b + out * 3.2, h - 2.6, h - 2.0, 0.6)
		IU.merlons(lm, "Red", a + out * 2.2, b + out * 2.2, h, 4.5, 2.6, 1.8, 1.1)
		var n := maxi(int(a.distance_to(b) / 110.0), 1)
		for k in n:
			var p := a.lerp(b, float(k) / float(n))
			IU.bastion(lm, "Red", "Marble", Vector3(p.x, 0.0, p.y), 5.5, h + 1.5)

## Lahori Gate with the turrets that set the 33 m top, and Aurangzeb's
## barbican with its own arched gate in front.
static func _lahori_gate(lm: LandmarkMesh) -> void:
	var west := Basis(Vector3.UP, -PI * 0.5)
	IU.gate(lm, "Red", "Marble", Vector3(-245, 0, -1), west, 34.0, 25.0, 22.0, 9.0, 14.0, 5.2,
		28.0, 7, "Recess")
	for sz in [-1.0, 1.0]:
		IU.wall_run(lm, "Red", Vector2(-257, sz * 17.0), Vector2(-287, sz * 17.0), 0.0, 14.0, 4.0)
		IU.merlons(lm, "Red", Vector2(-257, sz * 18.5), Vector2(-287, sz * 18.5), 14.0, 3.0, 1.6, 1.4, 0.8)
	U.arch_wall(lm, "Red", Vector3(-287, 0, -1), west, 38.0, 14.0, 4.0, 7.0, 10.0)
	IU.merlons(lm, "Red", Vector2(-289, -18.0), Vector2(-289, 16.0), 14.0, 3.0, 1.6, 1.4, 0.8)
	for sz in [-1.0, 1.0]:
		ID.arcade_wall(lm, "Red", "Recess", Vector3(-289, 1.0, -1 + sz * 11.5), west, 12.0, 10.0, 0.3, 3, 2.2, 7.0)

## Chhatta Chowk: the vaulted two-storey bazaar from the Lahori Gate, its
## shop arches on both faces of the arcade, the roof with an open
## octagonal light well at the centre.
static func _chhatta_chowk(lm: LandmarkMesh) -> void:
	lm.box("Red", Vector3(-197, 4.25, -1), Vector3(74.0, 8.5, 12.0))
	for s in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
		ID.arcade_wall(lm, "Red", "Recess", Vector3(-197, 0, -1 + s * 6.0), b, 74.0, 4.4, 0.8, 16, 2.8, 3.6)
		ID.arcade_wall(lm, "Red", "Recess", Vector3(-197, 4.4, -1 + s * 6.0), b, 74.0, 4.1, 0.8, 16, 2.2, 3.0,
			"pointed", 0.5)
		ID.chhajja(lm, "Red", Vector3(-234, 8.4, -1 + s * 6.8), Vector3(-160, 8.4, -1 + s * 6.8), Vector3(0, 0, s),
			0.9, 0.4, 3.0)
	# Barrel vault over the street and the octagonal well.
	var rows: Array = []
	for i in 9:
		var a := PI * float(i) / 8.0
		rows.append(PackedVector3Array([Vector3(-234, 8.5 + sin(a) * 2.2, -1 + cos(a) * 5.5),
			Vector3(-160, 8.5 + sin(a) * 2.2, -1 + cos(a) * 5.5)]))
	lm.grid("Red", rows, Vector3(-197, 0, -1), true)
	lm.frustum("Red", Vector3(-197, 8.5, -1), 7.0, 6.6, 3.0, 8, PI / 8.0)

## Diwan-i-Am: the hall of public audience, nine engrailed arches by three
## bays deep (55 x 18 m) on its plinth, open on three sides, the flat
## roof with corner kiosks and the marble throne canopy (Bengal roof) on
## the back wall.
static func _diwan_i_am(lm: LandmarkMesh) -> void:
	lm.box("Paving", Vector3(60, 0.05, 0), Vector3(104.0, 0.1, 120.0))
	var x0 := 110.0
	var depth := 18.3
	var front := 55.0
	lm.box("Red", Vector3(x0 + depth * 0.5, 0.6, 0), Vector3(depth + 4.0, 1.2, front + 4.0))
	var west := Basis(Vector3.UP, -PI * 0.5)
	var sh := 10.0
	# Three arcade screens parallel to the front, then the two side screens.
	for k in 3:
		ID.arcade_wall(lm, "Red", "", Vector3(x0 + 0.6 + 6.1 * float(k), 1.2, 0), west, front, sh, 1.2, 9, 4.4,
			8.0, "cusped", 0.0, true)
	for s in [-1.0, 1.0]:
		var sb := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
		ID.arcade_wall(lm, "Red", "", Vector3(x0 + depth * 0.5 - 1.5, 1.2, s * (front * 0.5 - 0.6)), sb, depth - 3.0,
			sh, 1.2, 3, 4.4, 8.0, "cusped", 0.0, true)
	# Back wall, roof slab, chhajja and parapet.
	lm.box("Red", Vector3(x0 + depth, 1.2 + sh * 0.5, 0), Vector3(1.4, sh, front))
	lm.box("Red", Vector3(x0 + depth * 0.5, 1.2 + sh + 0.4, 0), Vector3(depth + 1.4, 0.8, front + 1.4))
	ID.chhajja_ring(lm, "Red", Vector3(x0 + depth * 0.5, 1.2 + sh, 0), depth + 1.4, front + 1.4, 1.3, 0.6, 3.0)
	lm.box("Red", Vector3(x0 + 0.2, 1.2 + sh + 1.3, 0), Vector3(0.5, 1.0, front + 1.4))
	for sz in [-1.0, 1.0]:
		for sx in [0.0, 1.0]:
			ID.chhatri_fit(lm, "Marble", "Marble", Vector3(x0 + 1.5 + sx * (depth - 3.0), 1.2 + sh + 0.8,
				sz * (front * 0.5 - 1.5)), 3.4, 4.8)
	# Throne canopy: marble baldachin with a curved Bengal roof.
	var t := Vector3(x0 + depth - 3.0, 1.2, 0)
	lm.box("Marble", t + Vector3(0, 1.4, 0), Vector3(4.6, 2.8, 7.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Marble", t + Vector3(sx * 1.8, 2.8, sz * 2.8), 0.25, 0.2, 3.2, 8)
	var rows: Array = []
	for i in 7:
		var u := float(i) / 6.0
		var x := lerpf(-2.6, 2.6, u)
		var y := 6.0 + 1.3 * (1.0 - pow(absf(u * 2.0 - 1.0), 1.6))
		rows.append(PackedVector3Array([t + Vector3(x, y, -3.8), t + Vector3(x, y, 3.8)]))
	lm.grid("Marble", rows, Vector3.UP)
	U.finial(lm, "Gilt", t + Vector3(0, 7.3, 0), 1.6, 0.18)

## One white marble pavilion on the river wall: plinth, hall block with a
## through-arcade of `arches` engrailed arches on the courtyard face,
## a chhajja and a kiosk at each roof corner.
static func _pavilion(lm: LandmarkMesh, x: float, z: float, w: float, d: float, h: float,
		arches: int) -> void:
	lm.box("Marble", Vector3(x, 0.5, z), Vector3(d + 2.0, 1.0, w + 2.0))
	lm.box("Marble", Vector3(x + 1.5, 0.5 + h * 0.5, z), Vector3(d - 3.0, h, w))
	ID.arcade_wall(lm, "Marble", "", Vector3(x - d * 0.5 + 1.2, 1.0, z), Basis(Vector3.UP, -PI * 0.5), w, h - 0.5,
		1.2, arches, w / float(arches) * 0.66, h * 0.72, "cusped", 0.0, true)
	lm.box("Marble", Vector3(x, h + 0.75, z), Vector3(d + 0.6, 0.5, w + 0.6))
	ID.chhajja_ring(lm, "Marble", Vector3(x, h + 0.5, z), d, w, 1.1, 0.5, 2.4)
	for sz in [-1.0, 1.0]:
		for sx in [-1.0, 1.0]:
			ID.chhatri_fit(lm, "Marble", "Gilt", Vector3(x + sx * (d * 0.5 - 1.6), h + 1.0,
				z + sz * (w * 0.5 - 1.6)), 2.8, 3.6)

## Moti Masjid: Aurangzeb's small marble mosque (1659) behind its red
## outer wall, a three-arched prayer hall under three bulbous domes.
static func _moti_masjid(lm: LandmarkMesh) -> void:
	var c := Vector3(203, 0, -128)
	for e in [[0.0, 15.0, 30.0, 1.4], [0.0, -15.0, 30.0, 1.4], [-15.0, 0.0, 1.4, 30.0]]:
		lm.box("Red", c + Vector3(float(e[0]), 3.5, float(e[1])), Vector3(float(e[2]), 7.0, float(e[3])))
	lm.box("Marble", c + Vector3(8, 3.2, 0), Vector3(10.0, 6.4, 24.0))
	ID.arcade_wall(lm, "Marble", "Recess", c + Vector3(3, 0.3, 0), Basis(Vector3.UP, -PI * 0.5), 24.0, 6.0, 0.4, 3,
		4.6, 5.0, "cusped")
	lm.box("Marble", c + Vector3(-4, 0.15, 0), Vector3(14.0, 0.3, 24.0))
	ID.chhajja(lm, "Marble", c + Vector3(3, 6.0, -12), c + Vector3(3, 6.0, 12), Vector3(-1, 0, 0), 0.9, 0.4, 2.0)
	for k in 3:
		var p := c + Vector3(8, 6.4, (float(k) - 1.0) * 8.0)
		var r := 3.2 if k == 1 else 2.8
		lm.frustum("Marble", p, r * 0.85, r * 0.85, 0.8, 24)
		U.onion(lm, "Marble", p + Vector3(0, 0.8, 0), r, r * 1.35, 24)
		U.finial(lm, "Gilt", p + Vector3(0, 0.7 + r * 1.35, 0), 1.6, 0.16)

## Hayat Bakhsh Bagh: the garden with its central tank and the red
## sandstone Zafar Mahal, the marble Sawan and Bhadon pavilions at the
## ends of the north-south channel and the paved cross walks.
static func _hayat_bakhsh(lm: LandmarkMesh) -> void:
	var c := Vector3(150, 0, -235)
	lm.box("Lawn", c + Vector3(0, 0.05, 0), Vector3(100.0, 0.1, 90.0))
	lm.box("Paving", c + Vector3(0, 0.12, 0), Vector3(100.0, 0.1, 6.0))
	lm.box("Paving", c + Vector3(0, 0.12, 0), Vector3(6.0, 0.1, 90.0))
	lm.box("Water", c + Vector3(0, 0.15, 0), Vector3(30.0, 0.1, 30.0))
	lm.box("Water", c + Vector3(0, 0.16, 0), Vector3(2.0, 0.1, 86.0))
	lm.box("Red", c + Vector3(0, 0.6, 0), Vector3(12.0, 1.2, 12.0))
	ID.arcade_wall(lm, "Red", "", c + Vector3(-4.5, 1.2, 0), Basis(Vector3.UP, -PI * 0.5), 9.0, 4.6, 0.6, 3, 2.0,
		3.4, "cusped", 0.0, true)
	ID.arcade_wall(lm, "Red", "", c + Vector3(4.5, 1.2, 0), Basis(Vector3.UP, PI * 0.5), 9.0, 4.6, 0.6, 3, 2.0,
		3.4, "cusped", 0.0, true)
	lm.box("Red", c + Vector3(0, 6.0, 0), Vector3(10.0, 0.4, 10.0))
	ID.chhajja_ring(lm, "Red", c + Vector3(0, 5.8, 0), 9.6, 9.6, 1.0, 0.4, 2.2)
	ID.chhatri_fit(lm, "Red", "Marble", c + Vector3(0, 6.2, 0), 5.0, 4.6)
	for sz in [-1.0, 1.0]:
		var p := c + Vector3(0, 0, sz * 44.0)
		lm.box("Marble", p + Vector3(0, 0.5, 0), Vector3(14.0, 1.0, 8.0))
		var fb := Basis(Vector3.UP, 0.0 if sz < 0.0 else PI)
		ID.arcade_wall(lm, "Marble", "", p + Vector3(0, 1.0, -sz * 2.8), fb, 12.0, 5.0, 0.6, 3, 2.6, 4.0,
			"cusped", 0.0, true)
		lm.box("Marble", p + Vector3(0, 3.5, sz * 1.0), Vector3(12.0, 5.0, 4.0))
		lm.box("Marble", p + Vector3(0, 6.2, 0), Vector3(13.0, 0.4, 7.0))
		ID.chhajja_ring(lm, "Marble", p + Vector3(0, 6.0, 0), 12.0, 6.4, 0.9, 0.4, 2.0)
		for sx in [-1.0, 1.0]:
			ID.chhatri_fit(lm, "Marble", "Marble", p + Vector3(sx * 4.6, 6.4, 0), 2.2, 2.8)

## One life-size stone elephant on a plinth, facing out of the gate (+Z).
static func _elephant(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Red", p + Vector3(0, 0.6, 0), Vector3(3.2, 1.2, 5.0))
	var b := p + Vector3(0, 1.2, 0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Marble", b + Vector3(sx * 0.6, 0, sz * 1.0), 0.38, 0.34, 1.6, 8)
	lm.box("Marble", b + Vector3(0, 2.6, -0.1), Vector3(2.3, 2.2, 3.8))
	lm.box("Marble", b + Vector3(0, 3.8, -0.3), Vector3(1.6, 0.5, 2.8))
	var head := b + Vector3(0, 2.4, 1.7)
	lm.lathe("Marble", head - Vector3(0, 0.6, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.65, 0.2),
		Vector2(0.75, 0.7), Vector2(0.5, 1.2), Vector2(0.0, 1.35)]), 10)
	for sx in [-1.0, 1.0]:
		lm.box("Marble", head + Vector3(sx * 0.8, 0.1, -0.2), Vector3(0.15, 1.1, 0.9), Basis(Vector3.UP, sx * 0.3), 0.0)
	lm.beam("Marble", head + Vector3(0, -0.2, 0.5), head + Vector3(0, -1.2, 0.9), 0.32, 0.32)
	lm.beam("Marble", head + Vector3(0, -1.2, 0.9), head + Vector3(0, -2.3, 0.75), 0.22, 0.22)
