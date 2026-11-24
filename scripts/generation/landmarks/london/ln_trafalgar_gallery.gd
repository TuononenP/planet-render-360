class_name LandmarkLnTrafalgarGallery
extends RefCounted

## William Wilkins' National Gallery (1838) and the raised North Terrace
## overlooking Trafalgar Square (z = -56..-100 m, width = 134 m).
##
## Features:
## - North Terrace rusticated granite retaining wall, stone balustrade, and
##   wide central ceremonial staircase flanked by bronze globe lamps.
## - Double-row octastyle Corinthian central portico on wide entrance steps
##   with coffered soffit, entablature, and sculpted triangular pediment.
## - Rusticated ground storey with recessed arched doorways and blind arcades.
## - Piano nobile with recessed multi-pane sash windows alternating with
##   pedimented blind statue niches framed by paired Corinthian pilasters.
## - Continuous rooftop Portland-stone balustrade along the full 134 m parapet.
## - Ribbed central cylindrical drum, lead cupola dome, glazed lantern & finial,
##   flanked by Victorian open-arched columned pepper-pot turrets and end
##   tetrastyle pavilions.

const GZ := -86.0
const GW := 134.0
const GD := 28.0
const TERRACE_Y := 3.6
const EAVE_Y := 20.4

static func build(lm: LandmarkMesh) -> void:
	_north_terrace(lm)
	_main_facade(lm)
	_central_portico(lm)
	_end_pavilions(lm)
	_central_dome_and_turrets(lm)

static func _north_terrace(lm: LandmarkMesh) -> void:
	var wall_z := -58.0
	# Raised North Terrace platform connecting retaining wall to Gallery facade
	lm.box("Granite", Vector3(0.0, TERRACE_Y * 0.5, -67.0), Vector3(GW + 8.0, TERRACE_Y, 18.0))
	# Moulded granite cornice coping along the retaining wall top
	lm.box("Stone", Vector3(0.0, TERRACE_Y + 0.14, wall_z + 0.15), Vector3(GW + 8.6, 0.28, 0.9))
	# Rusticated masonry piers along the retaining wall face
	for sx in [-1.0, 1.0]:
		var sf := float(sx)
		for px in [12.5, 28.0, 46.0, 66.0]:
			lm.box("Granite", Vector3(sf * px, TERRACE_Y * 0.5, wall_z + 0.35), Vector3(2.0, TERRACE_Y + 0.4, 0.9))
			lm.box("Stone", Vector3(sf * px, TERRACE_Y + 0.72, wall_z + 0.35), Vector3(1.7, 1.05, 1.1))
		# Stone balustrade along North Terrace overlooking the square (left & right of grand stairs)
		SEuParts.rail(lm, "Stone", Vector3(sf * 13.5, TERRACE_Y + 0.28, wall_z + 0.15),
			Vector3(sf * 65.5, TERRACE_Y + 0.28, wall_z + 0.15), 1.05, 6.5)
	# Wide central ceremonial staircase descending from North Terrace to Trafalgar Square
	var steps := 12
	var step_h := TERRACE_Y / float(steps)
	var step_d := 0.46
	for k in steps:
		var y_top := TERRACE_Y - float(k) * step_h
		var z_step := wall_z + 0.5 + float(k) * step_d
		lm.box("Granite", Vector3(0.0, y_top * 0.5, z_step), Vector3(22.0, y_top, step_d + 0.04), Basis(), 0.0)
	# Flanking stepped stone cheek walls framing the central staircase
	for sx in [-1.0, 1.0]:
		var sf := float(sx)
		lm.box("Granite", Vector3(sf * 11.7, TERRACE_Y * 0.48, wall_z + 3.2), Vector3(1.5, TERRACE_Y * 0.96, 6.2))
		lm.box("Stone", Vector3(sf * 11.7, TERRACE_Y + 0.15, wall_z + 3.2), Vector3(1.75, 0.30, 6.45))

static func _main_facade(lm: LandmarkMesh) -> void:
	var fz := GZ + GD * 0.5  # -72.0 m front wall plane
	var nz := Vector3(0.0, 0.0, 1.0)
	# Rusticated ground storey (3.6..8.4 m) + piano nobile body (8.4..19.6 m)
	lm.box("DarkStone", Vector3(0.0, TERRACE_Y + 2.4, GZ), Vector3(GW + 0.6, 4.8, GD + 0.4))
	lm.box("Stone", Vector3(0.0, 14.0, GZ), Vector3(GW, 11.2, GD))
	# Strong horizontal belt course between rusticated ground & piano nobile
	lm.box("Stone", Vector3(0.0, 8.55, fz + 0.28), Vector3(GW + 1.2, 0.55, 0.65))
	# Deep classical entablature & dentil cornice along full 134 m frontage
	lm.box("Stone", Vector3(0.0, 19.75, GZ + 0.2), Vector3(GW + 1.8, 1.35, GD + 1.4))
	LandmarkDetail.cornice(lm, "Stone", Vector3(-GW * 0.5 - 0.9, EAVE_Y, fz + 0.85),
		Vector3(GW * 0.5 + 0.9, EAVE_Y, fz + 0.85), nz, 0.95, true)
	# Continuous rooftop Portland-stone balustrade along the entire parapet
	SEuParts.rail(lm, "Stone", Vector3(-65.0, EAVE_Y + 0.15, fz + 0.2), Vector3(-16.0, EAVE_Y + 0.15, fz + 0.2), 1.35, 5.5)
	SEuParts.rail(lm, "Stone", Vector3(16.0, EAVE_Y + 0.15, fz + 0.2), Vector3(65.0, EAVE_Y + 0.15, fz + 0.2), 1.35, 5.5)

	# Articulated wing bays: paired Corinthian pilasters, recessed multi-pane windows & pedimented blind niches
	for sx in [-1.0, 1.0]:
		var sf := float(sx)
		# Inner recessed links (x = ±17..±30 m) and outer gallery wings (x = ±36..±47 m)
		for bay_x in [18.5, 23.0, 27.5, 39.0, 43.5]:
			var wx := sf * float(bay_x)
			# Rusticated ground-floor recessed arched window/opening
			SEuParts.niche(lm, "Stone", "Glass", Vector3(wx, TERRACE_Y + 0.9, fz + 0.22), nz, 1.75, 2.95, SEuParts.ROUND, 0.34)
			# Piano nobile: alternate recessed pedimented sash windows & arched blind statue niches
			var is_niche := absf(float(bay_x) - 23.0) < 1.0 or absf(float(bay_x) - 43.5) < 1.0
			if is_niche:
				SEuParts.niche(lm, "Stone", "DarkStone", Vector3(wx, 10.1, fz + 0.08), nz, 1.85, 4.4, SEuParts.ROUND, 0.42)
				lm.box("Stone", Vector3(wx, 9.85, fz + 0.32), Vector3(2.25, 0.36, 0.52))
				# Classical stone urn/figure seated inside blind niche
				lm.lathe("Statue", Vector3(wx, 10.25, fz + 0.26), PackedVector2Array([
					Vector2(0.35, 0.0), Vector2(0.24, 0.45), Vector2(0.48, 1.15),
					Vector2(0.32, 1.65), Vector2(0.18, 2.05), Vector2(0.0, 2.25),
				]), 10)
			else:
				LandmarkDetail.window(lm, "Stone", "Glass", Vector3(wx, 12.6, fz + 0.05), nz, 1.95, 4.3, false, 0.34)
				lm.box("Stone", Vector3(wx, 10.15, fz + 0.28), Vector3(2.35, 0.32, 0.46))
				lm.gable("Stone", Vector3(wx, 15.05, fz + 0.32), 2.55, 0.55, 0.72, Basis(), 0.0, "Stone")
			# Upper mezzanine attic square window
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(wx, 17.4, fz + 0.05), nz, 1.55, 1.55, false, 0.24)
		# Giant Corinthian pilasters framing each bay
		for px in [16.2, 20.8, 25.2, 29.8, 36.8, 41.2, 45.8]:
			var x := sf * float(px)
			lm.box("Stone", Vector3(x, 14.0, fz + 0.24), Vector3(0.88, 10.8, 0.45))
			lm.box("Stone", Vector3(x, 19.1, fz + 0.34), Vector3(1.22, 0.65, 0.62))
		# Intermediate projecting vestibule bays under the pepper-pot turrets (x = ±33.2 m)
		var vx := sf * 33.2
		lm.box("Stone", Vector3(vx, 12.0, fz + 1.0), Vector3(6.8, 16.8, 2.2))
		SEuParts.niche(lm, "Stone", "Glass", Vector3(vx, TERRACE_Y + 0.4, fz + 2.12), nz, 2.6, 4.2, SEuParts.ROUND, 0.45)
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(vx, 12.8, fz + 2.12), nz, 2.2, 4.4, true, 0.38)
		lm.box("Stone", Vector3(vx, 20.6, fz + 1.0), Vector3(7.4, 0.75, 2.8))

static func _central_portico(lm: LandmarkMesh) -> void:
	var fz := GZ + GD * 0.5
	var pz := fz + 5.2  # -66.8 m front row of octastyle portico
	# Ceremonial portico podium & wide entrance steps
	lm.box("Granite", Vector3(0.0, TERRACE_Y + 0.85, fz + 2.8), Vector3(31.0, 1.7, 6.2))
	for k in 6:
		var t := float(k) / 6.0
		lm.box("Granite", Vector3(0.0, TERRACE_Y + 0.14 + (1.0 - t) * 0.72, pz + 1.1 + float(k) * 0.48),
			Vector3(26.0, 0.28 + (1.0 - t) * 1.42, 0.52), Basis(), 0.0)
	# Deep shaded portico recess behind columns + grand central bronze entrance portals
	lm.box("DarkStone", Vector3(0.0, 11.8, fz + 0.08), Vector3(24.0, 13.0, 0.25))
	for dx in [-4.8, 0.0, 4.8]:
		SEuParts.niche(lm, "Stone", "Glass", Vector3(float(dx), TERRACE_Y + 1.7, fz + 0.22),
			Vector3(0, 0, 1), 2.8, 5.4, SEuParts.ROUND, 0.45)
	# Double-row octastyle Corinthian columns (8 front + 4 inner return columns)
	for i in 8:
		var cx := lerpf(-13.3, 13.3, float(i) / 7.0)
		SEuParts.col(lm, "Stone", Vector3(cx, TERRACE_Y + 1.7, pz), 0.62, 13.6, "corinthian", 14)
	for cx in [-13.3, -9.5, 9.5, 13.3]:
		SEuParts.col(lm, "Stone", Vector3(float(cx), TERRACE_Y + 1.7, pz - 3.2), 0.62, 13.6, "corinthian", 14)
	# Portico entablature, coffered soffit ceiling & grand triangular pediment
	lm.box("Stone", Vector3(0.0, 19.65, fz + 2.7), Vector3(29.8, 1.55, 6.2))
	LandmarkLnKit.pediment_z(lm, "Stone", 0.0, 20.42, pz - 0.1, 29.6, 4.9, 1.8)
	# Recessed dark tympanum shadow & sculpted classical pediment relief figures
	lm.box("DarkStone", Vector3(0.0, 21.8, pz + 0.72), Vector3(16.0, 1.8, 0.18))
	for k in 5:
		var fx := lerpf(-5.6, 5.6, float(k) / 4.0)
		var fh := 2.35 - absf(fx) * 0.18
		SEuParts.figure(lm, "Statue", Vector3(fx, 20.6, pz + 0.88), fh, k == 2, 0.0)
	# Apex acroterion statue atop pediment peak
	lm.box("Stone", Vector3(0.0, 25.5, pz), Vector3(1.5, 0.55, 1.4))
	SEuParts.figure(lm, "Statue", Vector3(0.0, 25.78, pz), 1.85, false, 0.0)

static func _end_pavilions(lm: LandmarkMesh) -> void:
	var fz := GZ + GD * 0.5
	var nz := Vector3(0.0, 0.0, 1.0)
	for sx in [-1.0, 1.0]:
		var ex := float(sx) * 56.5
		lm.box("Stone", Vector3(ex, 12.2, GZ + 1.5), Vector3(21.0, 17.2, GD + 3.0))
		lm.box("DarkStone", Vector3(ex, TERRACE_Y + 2.2, GZ + 1.5), Vector3(21.4, 4.4, GD + 3.4))
		# Tetrastyle Corinthian portico on each projecting end pavilion
		for i in 4:
			var cx := lerpf(ex - 6.8, ex + 6.8, float(i) / 3.0)
			SEuParts.col(lm, "Stone", Vector3(cx, TERRACE_Y + 4.4, fz + 3.7), 0.52, 11.4, "corinthian", 12)
		lm.box("Stone", Vector3(ex, 20.1, fz + 2.4), Vector3(16.8, 1.35, 3.6))
		LandmarkLnKit.pediment_z(lm, "Stone", ex, 20.78, fz + 3.7, 16.6, 2.9, 1.4)
		for wx in [ex - 4.4, ex, ex + 4.4]:
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(float(wx), 13.0, fz + 3.05), nz, 1.75, 4.0, false, 0.30)

static func _central_dome_and_turrets(lm: LandmarkMesh) -> void:
	var dz := GZ + 2.5
	# Square attic podium beneath central dome
	lm.box("Stone", Vector3(0.0, 22.0, dz), Vector3(18.5, 3.6, 18.5))
	# Octagonal / cylindrical colonnaded drum with arched clerestory windows
	lm.frustum("Stone", Vector3(0.0, 23.8, dz), 8.2, 8.0, 5.4, 24)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0.0, sin(a))
		SEuParts.col(lm, "Stone", Vector3(0.0, 23.8, dz) + d * 8.15, 0.34, 5.2, "corinthian", 8)
		if k % 2 == 0:
			lm.box("Glass", Vector3(0.0, 26.4, dz) + d * 8.02, Vector3(1.5, 3.0, 0.22), Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	lm.frustum("Stone", Vector3(0.0, 29.2, dz), 8.6, 8.6, 0.65, 24)
	# Ribbed lead-grey central cupola dome
	var dome_prof := PackedVector2Array()
	for i in 10:
		var a := float(i) / 9.0 * PI * 0.5
		dome_prof.append(Vector2(cos(a) * 8.1, sin(a) * 6.8))
	lm.lathe("Lead", Vector3(0.0, 29.85, dz), dome_prof, 24)
	# 12 raised standing-seam lead ribs curving up the dome
	for k in 12:
		var a := TAU * float(k) / 12.0
		for j in 6:
			var a0 := float(j) / 6.0 * PI * 0.46
			var a1 := float(j + 1) / 6.0 * PI * 0.46
			var p0 := Vector3(cos(a) * cos(a0) * 8.18, 29.85 + sin(a0) * 6.86, dz + sin(a) * cos(a0) * 8.18)
			var p1 := Vector3(cos(a) * cos(a1) * 8.18, 29.85 + sin(a1) * 6.86, dz + sin(a) * cos(a1) * 8.18)
			lm.beam("Stone", p0, p1, 0.22, 0.22)
	# Glazed cupola lantern & finial crown (reaches ~40.5 m)
	lm.frustum("Stone", Vector3(0.0, 36.4, dz), 2.1, 2.0, 2.8, 12)
	lm.frustum("Glass", Vector3(0.0, 36.8, dz), 1.9, 1.9, 1.9, 12)
	lm.lathe("Lead", Vector3(0.0, 39.2, dz), PackedVector2Array([
		Vector2(2.15, 0.0), Vector2(1.75, 0.9), Vector2(0.85, 1.55), Vector2(0.15, 2.1), Vector2(0.0, 2.4),
	]), 14)

	# Twin flanking Victorian pepper-pot turrets with open columned drums & ogee cupolas
	for sx in [-1.0, 1.0]:
		var px := float(sx) * 33.2
		var pz := GZ + 7.2
		lm.box("Stone", Vector3(px, 21.8, pz), Vector3(6.4, 2.8, 6.4))
		SEuParts.arcade_ring(lm, "Stone", "Stone", Vector3(px, 23.2, pz), 2.55, 8, 3.6, 0.22, 0.0, "corinthian", 8)
		lm.frustum("DarkStone", Vector3(px, 23.2, pz), 1.75, 1.75, 3.6, 12)
		lm.frustum("Stone", Vector3(px, 26.9, pz), 2.85, 2.85, 0.45, 16)
		lm.lathe("Lead", Vector3(px, 27.35, pz), PackedVector2Array([
			Vector2(2.70, 0.0), Vector2(2.45, 1.25), Vector2(1.65, 2.45),
			Vector2(0.75, 3.35), Vector2(0.22, 4.15), Vector2(0.0, 4.55),
		]), 16)
