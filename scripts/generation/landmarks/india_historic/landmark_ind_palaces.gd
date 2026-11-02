class_name LandmarkIndPalaces
extends RefCounted

## Two Indian palaces in true metres: the Mysore Palace and the Victoria
## Memorial of Kolkata (the Amber Fort is in landmark_ind_amber.gd).
## Fronts face +Z unless noted; the registry yaw turns each onto its
## bearing.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")
const ID = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_detail.gd")

## Mysore Palace (44 m; 1897-1912): the Indo-Saracenic palace of grey
## granite and cream plaster, 75 x 48 m (245 x 156 ft) round its inner
## court. The east facade (built here on +Z, origin at its centre) has
## the great central arch with four smaller arches either side on granite
## piers, the open public durbar hall (47 x 13 m) as a colonnade of
## cusped arches on the first floor, a second floor of windows with
## balconies and a balustraded roof with pink-domed kiosks; the
## five-storey central tower under its gilt onion dome crowned by a
## kiosk instead of a finial; five-storey square towers with pink domes
## at the ends; and the octagonal Kalyana Mantapa with its stained-glass
## dome in the court.
static func mysore_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E3D3B0", 3.0))
	lm.use("Pink", LandmarkMaterials.pbr("render", "#D58C7A", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8E80", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4A3F38", 2.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#3E5A6A"))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#B5A58C", 4.0))
	lm.box("Pave", Vector3(0, 0.05, 25), Vector3(150.0, 0.1, 50.0))
	lm.box("Granite", Vector3(0, 0.75, -22), Vector3(78.0, 1.5, 54.0))
	IU.stairs(lm, "Granite", Vector3(0, 0, 5.0), Basis(), 16.0, 3, 0.5, 0.6)
	# Ranges round the court: front (16 m deep), sides and rear, 21 m.
	lm.box("Cream", Vector3(0, 11.25, -8.0), Vector3(75.0, 19.5, 16.0))
	lm.box("Cream", Vector3(0, 9.75, -42.0), Vector3(75.0, 16.5, 12.0))
	for sx in [-1.0, 1.0]:
		lm.box("Cream", Vector3(sx * 31.5, 9.75, -26.0), Vector3(12.0, 16.5, 20.0))
		for fl in 2:
			ID.arcade_wall(lm, "Cream", "Recess", Vector3(sx * 37.5, 1.5 + 8.0 * float(fl), -30.0),
				Basis(Vector3.UP, sx * PI * 0.5), 32.0, 8.0, 0.4, 6, 2.6, 5.0 + 0.4 * float(fl), "cusped")
	lm.box("Granite", Vector3(0, 21.2, -8.0), Vector3(76.0, 0.6, 17.0))
	lm.box("Granite", Vector3(0, 18.2, -42.0), Vector3(76.0, 0.6, 13.0))
	_mysore_facade(lm)
	_mysore_tower(lm)
	# End towers: five storeys, arched windows, pink onion domes.
	for sx in [-1.0, 1.0]:
		var p := Vector3(sx * 33.0, 21.5, -6.0)
		lm.box("Cream", p + Vector3(0, 5.0, 0), Vector3(10.0, 10.0, 10.0))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			ID.arcade_wall(lm, "Cream", "Recess", p + b * Vector3(0, 0.6, 5.0), b, 10.0, 4.4, 0.3, 3, 1.6, 3.4, "cusped")
			ID.arcade_wall(lm, "Cream", "Recess", p + b * Vector3(0, 5.2, 5.0), b, 10.0, 4.4, 0.3, 3, 1.6, 3.4, "cusped")
		lm.box("Granite", p + Vector3(0, 10.3, 0), Vector3(11.0, 0.6, 11.0))
		ID.chhajja_ring(lm, "Granite", p + Vector3(0, 10.0, 0), 10.0, 10.0, 0.9, 0.4, 2.0)
		lm.frustum("Cream", p + Vector3(0, 10.6, 0), 4.4, 4.4, 0.8, 16)
		U.onion(lm, "Pink", p + Vector3(0, 11.4, 0), 4.8, 5.0, 24)
		U.finial(lm, "Gilt", p + Vector3(0, 15.7, 0), 2.4, 0.3)
		for k in 4:
			var a := PI * 0.25 + PI * 0.5 * float(k)
			ID.chhatri_fit(lm, "Cream", "Pink", p + Vector3(cos(a) * 4.6, 10.6, sin(a) * 4.6), 1.6, 3.0, 6)
	# Kalyana Mantapa in the court: octagon of cast-iron columns under the
	# stained-glass dome.
	var kc := Vector3(0, 1.5, -26.0)
	lm.frustum("Cream", kc, 8.0, 7.8, 9.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		ID.arcade_wall(lm, "Cream", "Recess", kc + d * 7.3, Basis(Vector3.UP, PI * 0.5 - a), 6.0, 8.6, 0.35, 1, 3.2,
			6.4, "cusped")
	lm.frustum("Pink", kc + Vector3(0, 9.0, 0), 8.6, 8.6, 0.6, 8, PI / 8.0)
	lm.lathe("Glass", kc + Vector3(0, 9.6, 0), PackedVector2Array([Vector2(7.4, 0), Vector2(7.0, 1.8),
		Vector2(5.6, 3.6), Vector2(3.2, 4.8), Vector2(0.4, 5.3)]), 16)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := kc + Vector3(0, 9.6, 0) + d * 7.45
		for q in [[7.05, 1.8], [5.65, 3.6], [3.25, 4.8], [0.45, 5.3]]:
			var nxt: Vector3 = kc + Vector3(0, 9.6 + float(q[1]), 0) + d * float(q[0])
			lm.beam("Pink", prev, nxt, 0.18, 0.15, d.cross(Vector3.UP))
			prev = nxt
	lm.commit(model)

## The east facade on z = 0: the porch of nine arches on granite piers
## (the great central arch), the first-floor durbar hall colonnade of
## cusped arches, the second-floor windows on their balconies, chhajja
## eaves, the balustraded parapet and the pink-domed roof kiosks.
static func _mysore_facade(lm: LandmarkMesh) -> void:
	var front := Basis()
	# Ground floor: the porch projecting 3 m, nine arches, the central one 12 m.
	lm.box("Cream", Vector3(0, 8.5, 1.5), Vector3(44.0, 14.0, 3.0))
	ID.arcade_wall(lm, "Cream", "", Vector3(0, 1.5, 3.0), front, 16.0, 14.0, 1.0, 1, 11.4, 12.8, "cusped", 0.0, false, 9)
	for sx in [-1.0, 1.0]:
		ID.arcade_wall(lm, "Cream", "Recess", Vector3(sx * 15.0, 1.5, 3.0), front, 14.0, 7.0, 0.6, 4, 2.4, 5.6,
			"cusped")
		for k in 5:
			lm.box("Granite", Vector3(sx * (8.0 + 3.5 * float(k)), 4.6, 3.8), Vector3(0.8, 6.2, 0.8))
		for wing in [[15.0, 14.0, 4], [29.8, 15.4, 4]]:
			var wx: float = sx * float(wing[0])
			var ww: float = wing[1]
			var nb: int = wing[2]
			if absf(wx) > 20.0:
				ID.arcade_wall(lm, "Cream", "Recess", Vector3(wx, 1.5, 0.0), front, ww, 7.0, 0.5, nb, 2.4, 5.4, "pointed")
			# First floor: the open durbar hall colonnade (paired columns).
			ID.arcade_wall(lm, "Cream", "", Vector3(wx, 8.5, 0.0 if absf(wx) > 20.0 else 3.0), front, ww, 7.0, 0.9,
				nb + 1, 2.3, 5.4, "cusped", 0.0, true)
			for k in nb + 2:
				var cx := wx - ww * 0.5 + ww * float(k) / float(nb + 1)
				for dz in [-0.3, 0.3]:
					lm.frustum("Granite", Vector3(cx + dz, 8.5, (0.0 if absf(wx) > 20.0 else 3.0) + 1.3), 0.17, 0.15,
						5.0, 8)
			# Second floor windows and their balconies.
			ID.arcade_wall(lm, "Cream", "Recess", Vector3(wx, 15.5, 0.0), front, ww, 5.6, 0.4, nb + 1, 1.6, 3.8,
				"round", 0.8)
			for k in nb + 1:
				var bx := wx - ww * 0.5 + ww * (float(k) + 0.5) / float(nb + 1)
				lm.box("Pink", Vector3(bx, 16.1, 0.9), Vector3(2.4, 0.3, 1.2), front, 0.0)
				lm.box("Pink", Vector3(bx, 16.6, 1.45), Vector3(2.4, 0.8, 0.12), front, 0.0)
	for y in [8.4, 15.4]:
		ID.chhajja(lm, "Granite", Vector3(-37.5, y, 0.0), Vector3(37.5, y, 0.0), Vector3(0, 0, 1), 1.0, 0.4, 2.5)
	ID.chhajja(lm, "Pink", Vector3(-37.5, 20.9, 0.0), Vector3(37.5, 20.9, 0.0), Vector3(0, 0, 1), 1.2, 0.5, 2.5)
	# Balustraded parapet along the front.
	lm.box("Granite", Vector3(0, 21.65, 0.2), Vector3(75.0, 0.3, 0.6))
	for k in 60:
		lm.frustum("Cream", Vector3(-36.9 + 1.25 * float(k), 21.8, 0.2), 0.16, 0.12, 0.8, 6)
	lm.box("Granite", Vector3(0, 22.7, 0.2), Vector3(75.0, 0.25, 0.7))
	# Pink-domed kiosks on the roof between the towers.
	for sx in [-1.0, 1.0]:
		ID.chhatri_fit(lm, "Cream", "Pink", Vector3(sx * 15.0, 21.5, -3.0), 5.4, 6.8)
		ID.chhatri_fit(lm, "Cream", "Pink", Vector3(sx * 22.5, 21.5, -3.0), 3.6, 5.2)
		ID.chhatri_fit(lm, "Cream", "Pink", Vector3(sx * 22.5, 21.5, -14.0), 3.6, 5.2)

## Central tower behind the porch: two arcaded storeys above the roof
## (the third to fifth storeys with the floors below), corner turrets,
## the drum, the gilt onion dome and the gilt kiosk crowning it at 44 m.
static func _mysore_tower(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, -8.5)
	lm.box("Cream", c + Vector3(0, 28.0, 0), Vector3(16.0, 14.0, 16.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for y in [21.6, 28.4]:
			ID.arcade_wall(lm, "Cream", "Recess", c + b * Vector3(0, y, 8.0), b, 16.0, 6.6, 0.4, 3, 3.0, 5.2, "cusped")
		ID.chhajja(lm, "Granite", c + b * Vector3(-8.0, 28.2, 8.4), c + b * Vector3(8.0, 28.2, 8.4), b * Vector3(0, 0, 1),
			0.9, 0.4, 2.0)
	lm.box("Granite", c + Vector3(0, 35.4, 0), Vector3(18.0, 0.8, 18.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			ID.chhatri_fit(lm, "Cream", "Pink", c + Vector3(sx * 7.6, 35.8, sz * 7.6), 2.2, 3.4, 6)
	lm.frustum("Cream", c + Vector3(0, 35.8, 0), 6.0, 6.0, 1.7, 16)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Cream", c + Vector3(cos(a) * 6.05, 36.65, sin(a) * 6.05), Vector3(0.4, 1.5, 0.3),
			Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	U.onion(lm, "Gilt", c + Vector3(0, 37.5, 0), 6.0, 4.2, 32)
	ID.chhatri_fit(lm, "Gilt", "Gilt", c + Vector3(0, 41.6, 0), 2.4, 2.4, 6)

## Victoria Memorial (56 m to the Angel of Victory; 1906-21): the 103 x
## 69 m white Makrana marble hall on its terrace, two floors of
## round-arched bays between paired pilasters under a cornice and
## balustrade, domed octagonal towers at the four corners, the north
## porch (to -Z) with its great arch between paired columns under the
## figures of Motherhood, Prudence and Learning, smaller arched porches on
## the other sides, the great central dome on its drum ringed by Art,
## Architecture, Justice and Charity and by four corner kiosks, and the
## 4.9 m bronze Angel of Victory on top. The north (front) side is built
## on -Z.
static func victoria_memorial_kolkata(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F2EFE7", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#5A5048", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4B3F2F", 2.0, 0.4, 0.6))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6F8F4D", 4.0))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#BDB19A", 4.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.box("Lawn", Vector3(0, 0.02, 0), Vector3(170.0, 0.04, 150.0))
	lm.box("Pave", Vector3(0, 0.05, -52), Vector3(14.0, 0.06, 40.0))
	lm.box("Marble", Vector3(0, 0.15, 70), Vector3(62.0, 0.3, 20.0))
	lm.box("Water", Vector3(0, 0.32, 70), Vector3(60.0, 0.06, 18.0))
	lm.box("Marble", Vector3(0, 0.9, 0), Vector3(106.0, 1.8, 70.0))
	lm.box("Marble", Vector3(0, 0.4, 0), Vector3(110.0, 0.8, 74.0))
	# Main body: 92 x 58 m, two floors of arched bays, cornice, balustrade.
	lm.box("Marble", Vector3(0, 11.0, 0), Vector3(92.0, 18.4, 58.0))
	lm.box("Marble", Vector3(0, 20.5, 0), Vector3(94.0, 1.4, 60.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var long := side % 2 == 0
		var run := 92.0 if long else 58.0
		var hl := 29.0 if long else 46.0
		var n := 9 if long else 5
		ID.arcade_wall(lm, "Marble", "Recess", b * Vector3(0, 1.8, hl), b, run - 14.0, 8.2, 0.6, n, 3.6, 6.6, "round")
		ID.arcade_wall(lm, "Marble", "Recess", b * Vector3(0, 10.0, hl), b, run - 14.0, 9.2, 0.6, n, 3.4, 6.2, "round",
			0.8)
		ID.pilasters(lm, "Marble", b * Vector3(-(run - 14.0) * 0.5, 1.8, hl + 0.6), b * Vector3((run - 14.0) * 0.5, 1.8,
			hl + 0.6), b * Vector3(0, 0, 1), n * 2, 17.0, 0.5, 0.3)
		lm.box("Marble", b * Vector3(0, 10.0, hl + 0.75), Vector3(run - 14.0, 0.5, 0.5), b, 0.0)
		_balustrade(lm, b * Vector3(-(run * 0.5 + 0.5), 21.2, hl + 0.6), b * Vector3(run * 0.5 + 0.5, 21.2, hl + 0.6))
	# Corner towers: octagons with arched windows, cornices and domes.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 46.0, 1.8, sz * 29.0)
			lm.frustum("Marble", p, 7.2, 7.0, 22.0, 8, PI / 8.0)
			lm.frustum("Marble", p + Vector3(0, 21.0, 0), 8.0, 8.0, 1.2, 8, PI / 8.0)
			lm.frustum("Marble", p + Vector3(0, 9.6, 0), 7.5, 7.5, 0.6, 8, PI / 8.0)
			for k in 8:
				var a := TAU * (float(k) + 0.5) / 8.0
				var d := Vector3(cos(a), 0, sin(a))
				var fb := Basis(Vector3.UP, PI * 0.5 - a)
				ID.arcade_wall(lm, "Marble", "Recess", p + d * 6.55, fb, 5.0, 8.6, 0.35, 1, 2.4, 6.6, "round", 0.8)
				ID.arcade_wall(lm, "Marble", "Recess", p + d * 6.47 + Vector3(0, 10.2, 0), fb, 5.0, 8.6, 0.35, 1, 2.2, 6.0,
					"round", 0.8)
			lm.frustum("Marble", p + Vector3(0, 22.2, 0), 6.2, 6.0, 1.4, 16)
			U.dome(lm, "Marble", p + Vector3(0, 23.6, 0), 6.2, 5.1, 24, 6)
			U.finial(lm, "Marble", p + Vector3(0, 28.4, 0), 2.6, 0.3)
	# North porch (to -Z): the great arch between paired Ionic columns,
	# entablature, balustrade and the sculpture group, and the steps.
	lm.box("Marble", Vector3(0, 2.4, -34.0), Vector3(30.0, 1.2, 12.0))
	IU.stairs(lm, "Marble", Vector3(0, 0, -40.0), Basis(Vector3.UP, PI), 24.0, 4, 0.7, 1.0)
	U.arch_wall(lm, "Marble", Vector3(0, 3.0, -35.0), Basis(), 22.0, 15.5, 10.0, 9.0, 12.5)
	ID.arcade_wall(lm, "Marble", "", Vector3(0, 3.0, -40.0), Basis(Vector3.UP, PI), 22.0, 15.5, 0.5, 1, 10.4, 13.2,
		"round")
	lm.box("Recess", Vector3(0, 9.0, -29.05), Vector3(9.0, 12.0, 0.3))
	for sx in [-1.0, 1.0]:
		for k in 2:
			LandmarkDetail.column(lm, "Marble", Vector3(sx * (8.0 + 2.2 * float(k)), 3.0, -40.8), 0.7, 13.0, "ionic", 24)
	lm.box("Marble", Vector3(0, 17.2, -35.0), Vector3(24.0, 1.4, 12.0))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-12.0, 17.9, -41.0), Vector3(12.0, 17.9, -41.0), Vector3(0, 0, -1),
		0.9, true)
	_balustrade(lm, Vector3(-12.0, 18.8, -40.6), Vector3(12.0, 18.8, -40.6))
	lm.box("Marble", Vector3(0, 19.6, -37.0), Vector3(9.0, 1.6, 5.0))
	for k in 3:
		LandmarkKits.statue_figure(lm, "Marble", Vector3((float(k) - 1.0) * 2.8, 20.4, -37.5), 3.2 + 0.4 *
			float(1 - absi(k - 1)), k == 1)
	# South and lateral porches: arched bays with an attic.
	for e in [[0.0, 31.0, 0.0, 24.0], [48.0, 0.0, PI * 0.5, 20.0], [-48.0, 0.0, -PI * 0.5, 20.0]]:
		var b := Basis(Vector3.UP, float(e[2]))
		var pc := Vector3(float(e[0]), 1.8, float(e[1]))
		var pw: float = e[3]
		var bsz := Vector3(pw, 13.2, 3.0) if absf(float(e[2])) < 0.1 else Vector3(3.0, 13.2, pw)
		lm.box("Marble", pc + Vector3(0, 6.6, 0) - b * Vector3(0, 0, 0.5), bsz)
		ID.arcade_wall(lm, "Marble", "Recess", pc + b * Vector3(0, 0, 1.0), b, pw, 13.2, 0.6, 3, 4.0, 10.0, "round")
		lm.box("Marble", pc + Vector3(0, 13.7, 0), Vector3(pw + 2.0, 1.0, 5.0) if absf(float(e[2])) < 0.1 else
			Vector3(5.0, 1.0, pw + 2.0))
	# Central hall, drum, great dome, corner kiosks, allegories, Angel.
	lm.box("Marble", Vector3(0, 26.0, 0), Vector3(40.0, 12.0, 40.0))
	lm.box("Marble", Vector3(0, 32.4, 0), Vector3(42.0, 1.2, 42.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		ID.arcade_wall(lm, "Marble", "Recess", b * Vector3(0, 21.5, 20.0), b, 36.0, 10.4, 0.5, 5, 4.0, 8.0, "round")
		_balustrade(lm, b * Vector3(-21.0, 33.0, 21.0), b * Vector3(21.0, 33.0, 21.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			ID.chhatri_fit(lm, "Marble", "Marble", Vector3(sx * 17.5, 33.0, sz * 17.5), 6.0, 8.3)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		LandmarkKits.statue_figure(lm, "Marble", Vector3(cos(a) * 12.6, 33.0, sin(a) * 12.6), 3.4, k % 2 == 0)
	LandmarkKits.dome_on_drum(lm, "Marble", "Marble", Vector3(0, 33.0, 0), 11.5, 7.0, 11.1, 0.0, 40, 16)
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 51.1, 0), 4.9, true)
	lm.commit(model)

## Light balustrade along a-b: plinth, square balusters, handrail
## (lighter than LandmarkDetail.balustrade for the long roof runs).
static func _balustrade(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var dir := (b - a).normalized()
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5
	lm.box("Marble", mid + Vector3(0, 0.1, 0), Vector3(dl, 0.2, 0.5), bas, 0.0)
	lm.box("Marble", mid + Vector3(0, 1.0, 0), Vector3(dl, 0.18, 0.55), bas, 0.0)
	var n := int(dl / 0.45)
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.lathe("Marble", p + Vector3(0, 0.2, 0), PackedVector2Array([Vector2(0.1, 0), Vector2(0.15, 0.3),
			Vector2(0.08, 0.6), Vector2(0.11, 0.7)]), 4, 1.0, 1.0, 0.0, false, false)
	var piers := maxi(int(dl / 6.0), 1)
	for i in piers + 1:
		lm.box("Marble", a.lerp(b, float(i) / float(piers)) + Vector3(0, 0.55, 0), Vector3(0.45, 1.1, 0.45), bas, 0.0)
