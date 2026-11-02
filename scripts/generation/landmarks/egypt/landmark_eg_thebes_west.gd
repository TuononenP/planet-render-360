class_name LandmarkEgThebesWest
extends RefCounted

## Three monuments of the Theban west bank in true metres, entrance
## toward +Z and sanctuary toward -Z (registry yaw_deg turns them onto
## the real axis): Hatshepsut's terraced temple at Deir el-Bahari, the
## Colossi of Memnon and the Ramesseum.

# --- Mortuary Temple of Hatshepsut ---

## Three terraces rising 0 / 8.5 / 17 m (24.5 m at the top of the
## sanctuary against the cliff): the walled lower court with its ramp;
## the lower porticoes (each 25 m, two rows of 11: square pillars in
## front, sixteen-sided columns behind) under the 75 m deep middle
## terrace, flanked by 7.8 m Osiride colossi; the middle terrace with its
## second ramp, the Punt and Birth porticoes (two rows of 11 square
## pillars each side), the unfinished north colonnade of 15 columns, the
## Anubis chapel north and the Hathor chapel south; the upper portico of
## 26 pillars fronted by 5.2 m Osiride statues of the queen either side
## of the granite gate, the festival court ringed by double (west:
## triple) rows of columns, and the rock-cut sanctuary with its niches.
static func hatshepsut(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#D9C9A2", 3.2))
	lm.use("Shade", LandmarkMaterials.pbr("stone", "#8A7658", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8F5F50", 2.2))
	lm.box("Ground", Vector3(0, 0.1, 0), Vector3(116.0, 0.2, 196.0), Basis(), 0.0)
	# Lower court walls and gate.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Wall", Vector2(s * 45.0, 37.0), Vector2(s * 45.0, 94.0), 4.0, 1.4)
		LandmarkEgParts.temple_wall(lm, "Wall", Vector2(s * 45.0, 94.0), Vector2(s * 2.5, 94.0), 4.0, 1.4)
		lm.box("Wall", Vector3(s * 2.0, 3.0, 94.0), Vector3(1.4, 6.0, 2.4))
	# Middle terrace platform (porticoes cut into its front) and ends.
	lm.box("Wall", Vector3(0, 4.25, -3.5), Vector3(90.0, 8.5, 69.0))
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 37.5, 4.25, 34.0), Vector3(15.0, 8.5, 6.0))
		lm.box("Wall", Vector3(s * 4.8, 4.25, 34.0), Vector3(0.4, 8.5, 6.0))
		_portico(lm, s, 31.0, 37.0, 0.0, 4.6, 30.0, false)
		LandmarkEgParts.osiride(lm, "Wall", Vector3(s * 32.0, 0, 38.0), 7.8, s > 0.0)
	# Upper terrace platform with the middle porticoes cut into its front.
	lm.box("Wall", Vector3(0, 12.75, -66.0), Vector3(86.0, 8.5, 44.0))
	lm.box("Wall", Vector3(0, 4.25, -63.0), Vector3(90.0, 8.5, 50.0))
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 4.8, 12.75, -41.0), Vector3(0.4, 8.5, 6.0))
		lm.box("Wall", Vector3(s * 41.5, 12.75, -41.0), Vector3(3.0, 8.5, 6.0))
		_portico(lm, s, -44.0, -38.0, 8.5, 4.6, 40.0, true)
	_ramp(lm, 4.6, 80.0, 37.0, 0.0, 8.5)
	_ramp(lm, 4.6, 5.0, -38.0, 8.5, 17.0)
	_middle_chapels(lm)
	_upper_terrace(lm)
	lm.commit(model)

## One portico facing +Z between z_back and z_front on level y0, from
## x0 to x1 on side s: back wall, a front row of square pillars and a
## second row of sixteen-sided columns (`square2` makes both square),
## under the roof slab 8.5 m up.
static func _portico(lm: LandmarkMesh, s: float, z_back: float, z_front: float, y0: float, x0: float,
		x1: float, square2: bool) -> void:
	var w := x1 - x0
	var xc := s * (x0 + x1) * 0.5
	lm.box("Shade", Vector3(xc, y0 + 3.8, z_back + 0.15), Vector3(w, 7.6, 0.3))
	lm.box("Wall", Vector3(xc, y0 + 8.05, (z_back + z_front) * 0.5), Vector3(w, 0.9, z_front - z_back))
	for k in 11:
		var x: float = s * (x0 + 1.4 + (w - 2.8) * float(k) / 10.0)
		lm.box("Wall", Vector3(x, y0 + 3.8, z_front - 0.9), Vector3(1.1, 7.6, 1.1))
		lm.box("Wall", Vector3(x, y0 + 7.45, z_front - 0.9), Vector3(1.3, 0.3, 1.3))
		var zb := z_front - 3.6
		if square2:
			lm.box("Wall", Vector3(x, y0 + 3.8, zb), Vector3(1.1, 7.6, 1.1))
		else:
			LandmarkEgParts.column(lm, "Wall", Vector3(x, y0, zb), 0.55, 7.6, LandmarkEgParts.PLAIN)
	lm.box("Wall", Vector3(xc, y0 + 7.4, z_front - 0.9), Vector3(w, 0.4, 1.2))

## The middle terrace's north colonnade (15 sixteen-sided columns, left
## unfinished), the Anubis chapel with its twelve columns at the north
## end of the Birth portico and the Hathor chapel with its Hathor-
## headed pillars at the south end of the Punt portico.
static func _middle_chapels(lm: LandmarkMesh) -> void:
	var y := 8.5
	lm.box("Wall", Vector3(44.0, y + 4.0, -2.0), Vector3(2.0, 8.0, 50.0))
	LandmarkEgParts.colonnade(lm, "Wall", Vector3(39.5, y, 22.0), Vector3(39.5, y, -26.0), 15, 0.5, 7.4,
		LandmarkEgParts.PLAIN)
	lm.box("Wall", Vector3(41.7, y + 7.8, -2.0), Vector3(6.0, 0.8, 50.0))
	# Anubis chapel: a hall of three rows of four columns before the shrine.
	lm.box("Wall", Vector3(38.0, y + 4.0, -34.0), Vector3(14.0, 8.0, 6.0))
	for r in 3:
		for k in 4:
			LandmarkEgParts.column(lm, "Wall", Vector3(33.0 + 3.2 * float(k), y, -30.5 + 2.6 * float(r)),
				0.42, 6.8, LandmarkEgParts.PLAIN)
	lm.box("Wall", Vector3(38.0, y + 7.2, -27.0), Vector3(14.0, 0.8, 9.0))
	lm.box("Dark", Vector3(38.0, y + 2.4, -30.9), Vector3(1.8, 4.0, 0.2), Basis(), 0.0)
	# Hathor chapel: a hypostyle of Hathor-headed pillars before the shrine.
	lm.box("Wall", Vector3(-38.0, y + 4.0, -34.0), Vector3(14.0, 8.0, 6.0))
	for k in 4:
		var p := Vector3(-43.0 + 3.2 * float(k), y, -27.0)
		lm.box("Wall", p + Vector3(0, 2.6, 0), Vector3(0.9, 5.2, 0.9))
		lm.lathe("Wall", p + Vector3(0, 5.2, 0), PackedVector2Array([Vector2(0.6, 0), Vector2(0.75, 0.5),
			Vector2(0.7, 1.1), Vector2(0.4, 1.4)]), 8, 1.0, 0.8)
		lm.box("Wall", p + Vector3(0, 6.9, 0), Vector3(1.2, 0.6, 1.2))
	lm.box("Wall", Vector3(-38.0, y + 7.6, -27.0), Vector3(14.0, 0.8, 4.0))
	lm.box("Dark", Vector3(-38.0, y + 2.4, -30.9), Vector3(1.8, 4.0, 0.2), Basis(), 0.0)

## The upper terrace: the portico of pillars fronted by Osiride statues
## (white crown south, double crown north) either side of the granite
## gate, the festival court and the rock-cut sanctuary.
static func _upper_terrace(lm: LandmarkMesh) -> void:
	var y := 17.0
	for s in [-1.0, 1.0]:
		for k in 13:
			var x: float = s * (6.0 + 2.85 * float(k))
			lm.box("Wall", Vector3(x, y + 3.3, -39.6), Vector3(1.3, 6.6, 1.3))
			LandmarkEgParts.osiride(lm, "Wall", Vector3(x, y, -38.6), 5.2, s > 0.0)
			LandmarkEgParts.column(lm, "Wall", Vector3(x, y, -42.6), 0.5, 6.6, LandmarkEgParts.PLAIN)
		lm.box("Wall", Vector3(s * 23.5, y + 6.9, -41.0), Vector3(37.0, 0.6, 5.0))
		LandmarkEgParts.temple_wall(lm, "Wall", Vector2(s * 4.0, -44.5), Vector2(s * 42.0, -44.5), 7.2, 1.2, y)
		LandmarkEgParts.temple_wall(lm, "Wall", Vector2(s * 21.0, -45.0), Vector2(s * 21.0, -80.0), 7.2, 1.4, y)
		# Double colonnades down the sides of the festival court.
		for xr in [16.5, 19.0]:
			LandmarkEgParts.colonnade(lm, "Wall", Vector3(s * xr, y, -48.0), Vector3(s * xr, y, -68.0), 7, 0.42,
				6.0, LandmarkEgParts.PLAIN)
		lm.box("Wall", Vector3(s * 18.0, y + 6.3, -58.0), Vector3(5.0, 0.6, 22.0))
	# Granite gate.
	lm.box("Granite", Vector3(0, y + 3.6, -44.5), Vector3(8.0, 7.2, 1.6))
	lm.box("Dark", Vector3(0, y + 2.6, -43.6), Vector3(2.4, 5.2, 0.2), Basis(), 0.0)
	LandmarkEgParts.cavetto(lm, "Granite", Vector3(0, y + 7.2, -44.5), 8.0, 1.6, 0.8, 0.4)
	# Triple colonnade across the west (rear) side and the sanctuary.
	for zr in [-71.0, -73.5, -76.0]:
		LandmarkEgParts.colonnade(lm, "Wall", Vector3(-18.0, y, zr), Vector3(18.0, y, zr), 10, 0.42, 6.0,
			LandmarkEgParts.PLAIN)
	lm.box("Wall", Vector3(0, y + 6.3, -73.5), Vector3(40.0, 0.6, 7.0))
	lm.box("Wall", Vector3(0, y + 3.25, -84.0), Vector3(60.0, 6.5, 8.0))
	LandmarkEgParts.cavetto(lm, "Wall", Vector3(0, y + 6.5, -84.0), 60.0, 8.0, 1.0, 0.0)
	lm.box("Granite", Vector3(0, y + 2.8, -79.9), Vector3(4.4, 5.6, 0.4))
	lm.box("Dark", Vector3(0, y + 2.4, -79.6), Vector3(2.0, 4.4, 0.2), Basis(), 0.0)
	for k in 9:
		if k == 4:
			continue
		var x := -16.0 + 4.0 * float(k)
		var big := k % 2 == 0
		lm.box("Dark", Vector3(x, y + (2.4 if big else 3.0), -79.95), Vector3(1.4 if big else 0.9,
			3.2 if big else 1.8, 0.1), Basis(), 0.0)

## Sloping ramp `w` half-wide climbing from (z_lo, y_lo) to (z_hi, y_hi)
## with solid flanks and a balustrade each side: a sloping parapet with
## a rounded coping ending at the foot in a couchant lion.
static func _ramp(lm: LandmarkMesh, w: float, z_lo: float, z_hi: float, y_lo: float,
		y_hi: float) -> void:
	var n := Vector3(0, z_lo - z_hi, y_hi - y_lo).normalized()
	lm.quad("Wall", Vector3(-w, y_lo, z_lo), Vector3(w, y_lo, z_lo), Vector3(w, y_hi, z_hi),
		Vector3(-w, y_hi, z_hi), n)
	for s in [-1.0, 1.0]:
		var sn := Vector3(s, 0, 0)
		lm.tri("Wall", Vector3(s * w, y_lo, z_lo), Vector3(s * w, y_hi, z_hi),
			Vector3(s * w, y_lo, z_hi), sn, sn, sn, Vector2(z_lo, y_lo), Vector2(z_hi, y_hi),
			Vector2(z_hi, y_lo))
		var a := Vector3(s * (w - 0.3), y_lo + 0.5, z_lo)
		var b := Vector3(s * (w - 0.3), y_hi + 0.5, z_hi)
		lm.beam("Wall", a, b, 1.0, 0.6, Vector3.UP, true)
		LandmarkEgParts.rod(lm, "Wall", a + Vector3(0, 0.5, 0), b + Vector3(0, 0.5, 0), 0.32, 8)
		lm.box("Wall", Vector3(s * (w - 0.3), y_lo + 0.6, z_lo + 1.2), Vector3(0.9, 1.2, 2.4))
		lm.lathe("Wall", Vector3(s * (w - 0.3), y_lo + 1.2, z_lo + 0.4), PackedVector2Array([Vector2(0.4, 0),
			Vector2(0.45, 0.4), Vector2(0.3, 0.8), Vector2(0.0, 0.9)]), 8, 1.0, 1.6)

# --- Colossi of Memnon ---

## Two seated 18 m statues of Amenhotep III (14.8 m of quartzite
## sandstone on 3.2 m plinths, crowns and faces lost), 15 m apart,
## facing +Z: each with Queen Tiye and his mother Mutemwiya standing
## against the throne front beside his legs and a daughter between
## them, the Nile gods binding the Two Lands carved on the throne sides,
## and the northern colossus rebuilt above the waist in five courses of
## sandstone blocks after the earthquake of 27 BC.
static func memnon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Quartzite", LandmarkMaterials.pbr("stone", "#B08A5E", 7.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9C7952", 4.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D2BA8A", 8.0))
	lm.box("Ground", Vector3(0, 0.1, 0), Vector3(40.0, 0.2, 30.0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 7.5, 0, 0)
		lm.box("Plinth", c + Vector3(0, 1.5, 0), Vector3(8.6, 3.0, 12.4))
		lm.box("Plinth", c + Vector3(0, 3.1, 0), Vector3(8.0, 0.2, 11.8))
		lm.box("Plinth", c + Vector3(0, 0.2, 0), Vector3(9.4, 0.4, 13.2))
		LandmarkEgParts.colossus(lm, "Quartzite", c + Vector3(0, 3.2, 1.2), 14.8, false)
		# Tiye and Mutemwiya beside the shins, a daughter between them.
		for k in [-1.0, 1.0]:
			_standing_queen(lm, c + Vector3(k * 2.1, 3.2, 4.7), 4.6)
		_standing_queen(lm, c + Vector3(0, 3.2, 5.0), 2.6)
		# Sema-tawy relief on each side of the throne.
		for k in [-1.0, 1.0]:
			var fx: float = c.x + k * 3.2
			lm.box("Quartzite", Vector3(fx, 7.8, 0.6), Vector3(0.12, 4.8, 4.4), Basis(), 0.0)
			lm.lathe("Quartzite", Vector3(fx + k * 0.1, 6.0, 0.6), PackedVector2Array([Vector2(0.5, 0),
				Vector2(0.6, 1.0), Vector2(0.3, 1.8), Vector2(0.0, 2.0)]), 6, 0.3, 1.0)
			for j in [-1.0, 1.0]:
				lm.beam("Quartzite", Vector3(fx + k * 0.12, 5.7, 0.6 + j * 1.6),
					Vector3(fx + k * 0.12, 9.6, 0.6 + j * 1.2), 0.4, 0.15)
	# Roman repair courses on the northern (+X) colossus.
	for k in 5:
		lm.box("Plinth", Vector3(7.5, 10.0 + 1.0 * float(k), 0.1), Vector3(4.6 - 0.25 * float(k), 0.1, 3.0),
			Basis(), 0.0)
	lm.commit(model)

## Small standing queen against the throne, `h` tall: long sheath dress,
## arms at the sides, tripartite wig and a modius crown.
static func _standing_queen(lm: LandmarkMesh, c: Vector3, h: float) -> void:
	lm.lathe("Quartzite", c, PackedVector2Array([Vector2(h * 0.09, 0), Vector2(h * 0.08, h * 0.3),
		Vector2(h * 0.1, h * 0.55), Vector2(h * 0.12, h * 0.72), Vector2(h * 0.07, h * 0.8)]), 10, 1.0, 0.7)
	for s in [-1.0, 1.0]:
		lm.beam("Quartzite", c + Vector3(s * h * 0.12, h * 0.75, 0), c + Vector3(s * h * 0.11, h * 0.45, h * 0.02),
			h * 0.04, h * 0.04)
	lm.lathe("Quartzite", c + Vector3(0, h * 0.8, 0), PackedVector2Array([Vector2(h * 0.08, 0),
		Vector2(h * 0.075, h * 0.1), Vector2(h * 0.06, h * 0.16), Vector2(0.0, h * 0.18)]), 10)
	lm.frustum("Quartzite", c + Vector3(0, h * 0.96, 0), h * 0.06, h * 0.07, h * 0.04, 10)

# --- Ramesseum ---

## Mortuary temple of Ramesses II: ruined first pylon (22 m), first court
## with the fallen granite colossus (once 19 m seated, the "Ozymandias"),
## second pylon, the Osiride court with the statues of the king against
## its east and west pillars and a second fallen granite head, the
## 48-column hypostyle hall (12 open-papyrus nave columns of 12.5 m), the
## rear halls and the brick storerooms either side.
static func ramesseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CDAE7E", 3.2))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8F5F50", 2.2))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Mud", LandmarkMaterials.pbr("brick", "#9C7B55", 3.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, 0.1, -4.0), Vector3(100.0, 0.2, 180.0), Basis(), 0.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 82.0), 68.0, 22.0, 8.0, 8.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 43.0), 62.0, 19.0, 7.0, 7.0)
	# First court: bud-column side colonnades and the fallen colossus.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 29.5, 78.0), Vector2(s * 29.5, 46.0), 8.0, 1.6)
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 24.0, 0, 72.0), Vector3(s * 24.0, 0, 50.0),
			6, 0.8, 7.2)
		lm.box("Sand", Vector3(s * 26.0, 7.6, 61.0), Vector3(9.0, 0.8, 30.0))
	_fallen_colossus(lm, Vector3(-6.0, 0, 60.0))
	# Second (Osiride) court: pillars with Osiride statues of the king on
	# the east and west porticoes, plain pillars down the sides.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 28.0, 39.0), Vector2(s * 28.0, 12.0), 9.0, 1.8)
		for i in 6:
			lm.box("Sand", Vector3(s * 22.0, 3.7, 35.0 - 4.8 * i), Vector3(2.2, 7.4, 2.2))
		lm.box("Sand", Vector3(s * 24.0, 7.8, 23.0), Vector3(6.0, 0.8, 26.0))
	for z in [36.5, 14.5]:
		var into := -1.0 if z > 25.0 else 1.0
		for i in 8:
			var x := -15.75 + 4.5 * float(i)
			lm.box("Sand", Vector3(x, 0.6, z), Vector3(3.6, 1.2, 3.6))
			lm.box("Sand", Vector3(x, 4.8, z - into * 0.6), Vector3(2.0, 7.2, 2.0))
			if i % 3 != 1:
				LandmarkEgParts.osiride(lm, "Sand", Vector3(x, 1.2, z + into * 0.9), 7.2)
		lm.box("Sand", Vector3(0, 8.8, z - into * 0.6), Vector3(34.0, 0.8, 2.4))
	# Head and shoulders of a second fallen colossus in the Osiride court.
	lm.lathe("Granite", Vector3(-12.0, 0, 28.0), PackedVector2Array([Vector2(1.6, 0), Vector2(1.5, 1.2),
		Vector2(1.0, 2.2), Vector2(0.0, 2.6)]), 10, 1.0, 0.8)
	lm.box("Granite", Vector3(-12.0, 0.8, 25.6), Vector3(4.6, 1.6, 2.2))
	# Hypostyle hall: 12 nave columns, 36 bud columns in 6 rows under aisle roofs.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 27.0, 12.0), Vector2(s * 27.0, -24.0), 14.0, 2.0)
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 5.2, 0, 7.0), Vector3(s * 5.2, 0, -19.0),
			6, 1.15, 12.5, LandmarkEgParts.OPEN, 10)
		lm.beam("Sand", Vector3(s * 5.2, 13.1, 10.0), Vector3(s * 5.2, 13.1, -22.0), 1.4, 2.6,
			Vector3.UP, true)
		lm.box("Sand", Vector3(s * 8.6, 11.0, -6.0), Vector3(0.9, 4.2, 34.0))
		for xr in [12.0, 17.0, 22.0]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, 7.0), Vector3(s * xr, 0, -19.0),
				6, 0.8, 8.6)
		lm.box("Sand", Vector3(s * 17.6, 9.4, -6.0), Vector3(18.0, 0.9, 34.0))
	lm.box("Sand", Vector3(0, 13.9, -6.0), Vector3(12.0, 0.9, 34.0))
	# Rear halls and sanctuary, stepping down; brick magazines either side.
	lm.box("Sand", Vector3(0, 4.0, -31.0), Vector3(44.0, 8.0, 14.0))
	lm.box("Sand", Vector3(0, 3.2, -44.0), Vector3(30.0, 6.4, 12.0))
	lm.box("Sand", Vector3(0, 2.7, -55.0), Vector3(20.0, 5.4, 10.0))
	lm.box("Dark", Vector3(0, 2.4, -23.9), Vector3(4.0, 4.8, 0.5))
	for s in [-1.0, 1.0]:
		lm.box("Mud", Vector3(s * 40.5, 2.4, -22.0), Vector3(8.0, 4.8, 78.0))
	lm.commit(model)

## The fallen granite colossus of Ramesses II (the Ozymandias of
## Shelley), once 19 m seated: the throne and legs still on their base,
## the torso broken away and lying on its back with the head, a foot and
## shattered pieces strewn about.
static func _fallen_colossus(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Granite", c + Vector3(0, 0.8, -4.0), Vector3(9.0, 1.6, 10.0))
	lm.box("Granite", c + Vector3(0, 3.2, -6.0), Vector3(7.6, 3.2, 5.0))
	for s in [-1.0, 1.0]:
		lm.box("Granite", c + Vector3(s * 1.9, 3.6, -2.0), Vector3(2.8, 4.0, 3.0))
		lm.box("Granite", c + Vector3(s * 1.9, 2.0, 0.4), Vector3(2.4, 0.8, 2.6))
	# Torso on its back, chest up, with the nemes head beyond the shoulders.
	var rb := Basis(Vector3.UP, 0.5)
	var tc := c + Vector3(4.0, 0, 7.0)
	lm.box("Granite", tc + Vector3(0, 1.2, 0), Vector3(7.0, 2.4, 4.6), rb)
	LandmarkEgParts.rod(lm, "Granite", tc + rb * Vector3(-3.2, 2.0, 0), tc + rb * Vector3(3.2, 2.0, 0), 1.6, 12)
	for k in [-1.0, 1.0]:
		LandmarkEgParts.rod(lm, "Granite", tc + rb * Vector3(-2.6, 1.0, k * 2.6), tc + rb * Vector3(2.4, 1.0, k * 2.5),
			0.9, 8)
	var hc := tc + rb * Vector3(5.4, 0, 0)
	lm.lathe("Granite", hc, PackedVector2Array([Vector2(1.9, 0), Vector2(1.8, 0.8), Vector2(1.5, 1.6),
		Vector2(0.9, 2.2), Vector2(0.0, 2.4)]), 12, 1.0, 0.9)
	for k in 5:
		var a := float(k) * 1.3
		lm.box("Granite", c + Vector3(6.0 + 3.0 * cos(a), 0.6, 2.0 + 4.0 * sin(a)),
			Vector3(1.6 + 0.3 * float(k), 1.2, 1.4), Basis(Vector3.UP, a))
