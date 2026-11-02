extends RefCounted

## The Amber (Amer) Fort of Jaipur in true metres: the hill palace in
## four terraced courts climbing -Z from the Jaleb Chowk. Built in its
## own frame; the registry yaw turns it onto the real bearing.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")
const ID = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_detail.gd")

## Amber Fort (36 m above the lowest court; 1592 on): the palace laid out
## on four levels, each with a courtyard. The Jaleb Chowk (y 0) behind
## the Suraj Pol, lined with two storeys of arcaded stables and guard
## rooms, the Sila Devi temple by the stair; the Singh Pol into the
## second court and its Diwan-i-Am, a raised hall of 27 columns with
## elephant bracket capitals; the painted three-storey Ganesh Pol with the
## latticed Suhag Mandir above; the third court's Mughal garden with its
## star-shaped pool between the mirrored Jai Mandir (Sheesh Mahal) and
## the Sukh Niwas; and the zenana court of the Man Singh I palace (1599)
## round its pillared baradari, kiosks on the roofline. Terrace walls
## with arched cells, merloned ridge walls and round bastions.
static func amber_fort(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#C8A27C", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("stone", "#B5583C", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE6D4", 3.0))
	lm.use("Fresco", LandmarkMaterials.pbr("render", "#C79058", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4A3A30", 2.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#7A8C52", 4.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#BFAE90", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Terraces: z0, z1, floor height. Each stands on the ground as a solid
	# block whose front face carries a row of arched cells.
	var floors := [[10.0, 70.0, 0.0], [-25.0, 10.0, 6.5], [-55.0, -25.0, 13.0], [-88.0, -55.0, 20.0]]
	for t in floors:
		var z0: float = t[0]
		var z1: float = t[1]
		var fy: float = t[2]
		if fy > 0.0:
			lm.box("Sand", Vector3(0, fy * 0.5, (z0 + z1) * 0.5), Vector3(70.0, fy, z1 - z0))
		lm.box("Pave", Vector3(0, fy + 0.03, (z0 + z1) * 0.5), Vector3(66.0, 0.06, z1 - z0 - 4.0))
		for sx in [-1.0, 1.0]:
			IU.wall_run(lm, "Sand", Vector2(sx * 34.0, z0), Vector2(sx * 34.0, z1), 0.0, fy + 6.0, 3.0)
			IU.merlons(lm, "Sand", Vector2(sx * 35.0, z0), Vector2(sx * 35.0, z1), fy + 6.0, 3.2, 1.6, 1.3, 1.0)
	for t in [[10.0, 6.5], [-25.0, 6.5], [-55.0, 7.0]]:
		var z: float = t[0]
		var dh: float = t[1]
		var base_y := 0.0 if z > 0.0 else (6.5 if z > -30.0 else 13.0)
		for sx in [-1.0, 1.0]:
			ID.arcade_wall(lm, "Sand", "Recess", Vector3(sx * 21.0, base_y, z), Basis(), 26.0, dh - 0.3, 0.6, 5, 2.6,
				dh - 2.0)
	# Front wall with the Suraj Pol gate, and bastions up the ridge walls.
	IU.gate(lm, "Sand", "Marble", Vector3(0, 0, 70.0), Basis(), 26.0, 12.0, 9.0, 7.0, 9.0, 3.0, 13.0, 3, "Recess")
	for sx in [-1.0, 1.0]:
		IU.wall_run(lm, "Sand", Vector2(sx * 13.0, 70.0), Vector2(sx * 34.0, 70.0), 0.0, 7.0, 3.0)
		IU.merlons(lm, "Sand", Vector2(sx * 13.0, 71.0), Vector2(sx * 34.0, 71.0), 7.0, 3.2, 1.6, 1.3, 1.0)
		for z in [60.0, 25.0, -10.0, -40.0, -70.0]:
			var fy := 0.0 if z > 10.0 else (6.5 if z > -25.0 else (13.0 if z > -55.0 else 20.0))
			IU.bastion(lm, "Sand", "Marble", Vector3(sx * 35.0, 0.0, z), 3.6, fy + 5.5)
	_jaleb_chowk(lm)
	# Singh Pol: the lion gate into the Diwan-i-Am court, with the stair of the ascent.
	IU.gate(lm, "Sand", "Marble", Vector3(0, 6.5, 4.0), Basis(), 30.0, 11.0, 8.0, 6.0, 8.0, 2.6, 12.0, 3, "Recess")
	IU.stairs(lm, "Sand", Vector3(0, 0, 10.0), Basis(), 12.0, 7, 0.93, 1.0)
	_diwan_i_am(lm, Vector3(-18.0, 6.5, -10.0))
	_ganesh_pol(lm, Vector3(0, 6.5, -28.5))
	_garden_court(lm)
	_zenana(lm)
	lm.commit(model)

## Jaleb Chowk: two storeys of arched stables and guard rooms down both
## sides of the great court, a chhajja and parapet, and the small marble
## Sila Devi temple beside the stair.
static func _jaleb_chowk(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		var x: float = sx * 27.0
		var fb := Basis(Vector3.UP, -sx * PI * 0.5)
		lm.box("Sand", Vector3(x + sx * 1.0, 4.5, 40.0), Vector3(10.0, 9.0, 56.0))
		ID.arcade_wall(lm, "Sand", "Recess", Vector3(x - sx * 4.0, 0.0, 40.0), fb, 56.0, 4.6, 0.5, 11, 2.8, 3.8)
		ID.arcade_wall(lm, "Sand", "Recess", Vector3(x - sx * 4.0, 4.6, 40.0), fb, 56.0, 4.4, 0.5, 11, 2.2, 3.2,
			"cusped", 0.4)
		ID.chhajja(lm, "Sand", Vector3(x - sx * 4.5, 8.9, 12.0), Vector3(x - sx * 4.5, 8.9, 68.0), Vector3(-sx, 0, 0),
			1.0, 0.45, 2.6)
		lm.box("Sand", Vector3(x - sx * 3.7, 9.6, 40.0), Vector3(0.6, 1.2, 56.0))
	# Sila Devi temple: marble front with three arches and a small dome.
	var t := Vector3(18.0, 0, 15.0)
	lm.box("Marble", t + Vector3(0, 0.6, 0), Vector3(10.0, 1.2, 8.0))
	lm.box("Marble", t + Vector3(0, 3.7, -0.5), Vector3(9.0, 5.0, 7.0))
	ID.arcade_wall(lm, "Marble", "Recess", t + Vector3(0, 1.2, 3.0), Basis(), 9.0, 5.0, 0.5, 3, 2.0, 3.8, "cusped")
	ID.chhajja_ring(lm, "Marble", t + Vector3(0, 6.2, -0.25), 9.0, 7.5, 0.8, 0.35, 1.8)
	ID.chhatri_fit(lm, "Marble", "Marble", t + Vector3(0, 6.2, -0.5), 4.0, 4.4)

## Diwan-i-Am on its platform at `c` (west side of the second court): 27
## columns (9 x 3), double-bracketed elephant capitals, the beamed flat
## roof with its chhajja and parapet, and three kiosks on top.
static func _diwan_i_am(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Red", c + Vector3(0, 0.6, 0), Vector3(30.0, 1.2, 12.0))
	IU.stairs(lm, "Red", c + Vector3(0, 0, 6.0), Basis(), 6.0, 2, 0.6, 0.6)
	for i in 9:
		for j in 3:
			var p := c + Vector3(-13.0 + 3.25 * float(i), 1.2, -4.5 + 4.5 * float(j))
			var key := "Marble" if j == 1 else "Red"
			lm.box(key, p + Vector3(0, 0.35, 0), Vector3(0.9, 0.7, 0.9))
			lm.frustum(key, p + Vector3(0, 0.7, 0), 0.32, 0.3, 3.3, 16)
			for a in [0.0, PI * 0.5]:
				var d := Vector3(cos(a), 0, sin(a))
				lm.beam(key, p + Vector3(0, 3.6, 0) - d * 0.75, p + Vector3(0, 3.6, 0) + d * 0.75, 0.35, 0.5)
				lm.beam(key, p + Vector3(0, 3.4, 0) - d * 0.45, p + Vector3(0, 3.4, 0) + d * 0.45, 0.3, 0.4)
	lm.box("Red", c + Vector3(0, 5.2, 0), Vector3(28.0, 0.8, 11.0))
	ID.chhajja_ring(lm, "Red", c + Vector3(0, 4.9, 0), 28.0, 11.0, 1.1, 0.5, 2.6)
	lm.box("Marble", c + Vector3(0, 5.9, 0), Vector3(28.4, 0.6, 11.4))
	for k in 3:
		ID.chhatri_fit(lm, "Marble", "Marble", c + Vector3((float(k) - 1.0) * 9.0, 6.2, 0), 4.0, 4.4)

## Ganesh Pol at `c` (foot on the second court's floor, front face +Z):
## a three-storey painted gate with tiers of arched niches either side
## of the great arch, the Suhag Mandir above with latticed windows under
## a chhajja, and the kiosks on its crest.
static func _ganesh_pol(lm: LandmarkMesh, c: Vector3) -> void:
	U.arch_wall(lm, "Fresco", c, Basis(), 26.0, 15.0, 7.0, 5.6, 8.0)
	ID.arcade_wall(lm, "Fresco", "", c + Vector3(0, 0, 3.5), Basis(), 8.6, 13.0, 0.6, 1, 6.8, 11.0, "cusped")
	for sx in [-1.0, 1.0]:
		for y in [0.4, 5.2, 10.0]:
			ID.arcade_wall(lm, "Fresco", "Recess", c + Vector3(sx * 8.6, y, 3.5), Basis(), 8.6, 4.6, 0.35, 2, 2.0, 3.6,
				"cusped")
	# Suhag Mandir: latticed upper storey, its chhajja and kiosks.
	lm.box("Fresco", c + Vector3(0, 17.0, -0.5), Vector3(24.0, 4.0, 6.0))
	ID.arcade_wall(lm, "Marble", "Recess", c + Vector3(0, 15.0, 2.5), Basis(), 24.0, 4.0, 0.3, 9, 1.4, 3.0, "cusped",
		0.4)
	ID.chhajja(lm, "Marble", c + Vector3(-13.0, 19.0, 2.6), c + Vector3(13.0, 19.0, 2.6), Vector3(0, 0, 1), 1.0, 0.45,
		2.0)
	lm.box("Marble", c + Vector3(0, 19.4, 0), Vector3(26.0, 0.8, 7.5))
	for k in 3:
		ID.chhatri_fit(lm, "Marble", "Marble", c + Vector3((float(k) - 1.0) * 8.0, 19.8, 0), 3.8, 5.6, 8, false)

## Third court: the Mughal garden with the star-shaped pool and the
## raised beds between the Jai Mandir (west, two storeys of cusped marble
## arcades with the Jas Mandir above) and the Sukh Niwas (east).
static func _garden_court(lm: LandmarkMesh) -> void:
	lm.box("Lawn", Vector3(0, 13.1, -40.0), Vector3(32.0, 0.12, 24.0))
	var star := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		var r := 5.0 if i % 2 == 0 else 3.2
		star.append(Vector2(cos(a) * r, -40.0 + sin(a) * r))
	lm.poly_prism("Marble", star, 13.0, 13.4)
	var water := PackedVector2Array()
	for p in star:
		water.append(Vector2(p.x * 0.85, -40.0 + (p.y + 40.0) * 0.85))
	lm.poly_prism("Water", water, 13.0, 13.42)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Marble", Vector3(sx * 9.0, 13.25, -40.0 + sz * 7.0), Vector3(10.0, 0.3, 6.0))
	for sx in [-1.0, 1.0]:
		var p := Vector3(sx * 25.0, 13.0, -40.0)
		var fb := Basis(Vector3.UP, -sx * PI * 0.5)
		var marble: bool = sx < 0.0
		var wk := "Marble" if marble else "Sand"
		lm.box(wk, p + Vector3(sx * 2.0, 5.0, 0), Vector3(10.0, 10.0, 24.0))
		ID.arcade_wall(lm, wk, "", p + Vector3(-sx * 3.0, 0.0, 0), fb, 24.0, 5.8, 1.2, 5, 3.4, 4.6, "cusped", 0.0, true)
		ID.chhajja(lm, wk, p + Vector3(-sx * 4.2, 5.8, -12.0), p + Vector3(-sx * 4.2, 5.8, 12.0), Vector3(-sx, 0, 0), 1.0,
			0.45, 2.0)
		if marble:
			ID.arcade_wall(lm, "Marble", "Recess", p + Vector3(-sx * 3.0, 6.0, 0), fb, 24.0, 4.0, 0.4, 7, 1.8, 3.2,
				"cusped")
			lm.box("Marble", p + Vector3(sx * 2.0, 10.3, 0), Vector3(10.6, 0.6, 24.6))
			ID.chhatri_fit(lm, "Marble", "Gilt", p + Vector3(sx * 2.0, 10.6, -8.0), 3.4, 4.8, 8, false)
			ID.chhatri_fit(lm, "Marble", "Gilt", p + Vector3(sx * 2.0, 10.6, 8.0), 3.4, 4.8, 8, false)
		else:
			lm.box("Marble", p + Vector3(sx * 2.0, 10.3, 0), Vector3(10.6, 0.6, 24.6))

## Zenana court of the Man Singh I palace: two-storey ranges with arched
## rooms on three sides, the pillared baradari pavilion at the centre of
## the court and the roofline kiosks that set the 36 m top.
static func _zenana(lm: LandmarkMesh) -> void:
	lm.box("Sand", Vector3(0, 25.25, -80.0), Vector3(62.0, 10.5, 14.0))
	lm.box("Marble", Vector3(0, 30.9, -80.0), Vector3(63.0, 0.8, 15.0))
	ID.arcade_wall(lm, "Sand", "Recess", Vector3(0, 20.0, -73.0), Basis(), 56.0, 5.4, 0.5, 8, 3.6, 4.6)
	ID.arcade_wall(lm, "Sand", "Recess", Vector3(0, 25.4, -73.0), Basis(), 56.0, 5.1, 0.5, 8, 3.0, 3.8, "cusped", 0.4)
	ID.chhajja(lm, "Sand", Vector3(-28.0, 25.3, -72.5), Vector3(28.0, 25.3, -72.5), Vector3(0, 0, 1), 1.0, 0.45, 2.6)
	for sx in [-1.0, 1.0]:
		lm.box("Sand", Vector3(sx * 28.0, 24.0, -64.0), Vector3(8.0, 8.0, 18.0))
		ID.arcade_wall(lm, "Sand", "Recess", Vector3(sx * 24.0, 20.0, -64.0), Basis(Vector3.UP, -sx * PI * 0.5), 18.0,
			7.6, 0.4, 4, 2.6, 5.0, "cusped")
		ID.chhatri_fit(lm, "Marble", "Marble", Vector3(sx * 28.0, 28.0, -58.0), 3.6, 4.4)
	for k in 5:
		ID.chhatri_fit(lm, "Marble", "Marble", Vector3((float(k) - 2.0) * 13.0, 31.3, -80.0), 5.0, 4.7)
	# Baradari: twelve pillars on a plinth, a flat roof with its chhajja.
	var b := Vector3(0, 20.0, -63.0)
	lm.box("Marble", b + Vector3(0, 0.5, 0), Vector3(13.0, 1.0, 13.0))
	for i in 4:
		for j in 4:
			if (i == 1 or i == 2) and (j == 1 or j == 2):
				continue
			var p := b + Vector3(-5.1 + 3.4 * float(i), 1.0, -5.1 + 3.4 * float(j))
			lm.frustum("Marble", p, 0.3, 0.26, 3.6, 8)
			lm.box("Marble", p + Vector3(0, 3.7, 0), Vector3(0.8, 0.3, 0.8), Basis(), 0.0)
	lm.box("Marble", b + Vector3(0, 5.2, 0), Vector3(12.0, 0.6, 12.0))
	ID.chhajja_ring(lm, "Marble", b + Vector3(0, 4.9, 0), 12.0, 12.0, 1.0, 0.45, 2.0)
	ID.chhatri_fit(lm, "Marble", "Marble", b + Vector3(0, 5.5, 0), 6.0, 5.4)
