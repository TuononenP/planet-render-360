class_name LandmarkMiCulturalCenter
extends RefCounted

## Miami-Dade Cultural Center — Miami MI-2B
## Architect: Philip Johnson & John Burgee (1983), Mediterranean Revival complex, height_m = 24.0.
## Site: OSM way 648249520, centroid 25.774631, -80.196478, yaw_deg = -1.8.
## Footprint: 87.8 x 83.6 m (+X East toward NW 1st Ave, -Z North, +Z South).
## Envelope:
##   - Raised Florida coral-travertine ashlar plinth (y = 0.0..4.8 m) with grand East & West
##     entry staircases, recessed dark louvre grilles, patterned terracotta plaza tile & balustrade.
##   - 3 distinct warm cream-ochre stucco pavilions around the sunny central courtyard:
##       1) Main Library (South-East, with square Mediterranean belvedere tower reaching 24.0 m)
##       2) HistoryMiami Museum (North wing) + West mural loggia gallery
##       3) Art Museum / Exhibition Pavilion (South-West wing)
##   - Shaded courtyard arcades on round coral-stone columns, clay barrel-tile hipped roofs
##     (LandmarkMiKit.barrel_tile_strip), multi-globe plaza streetlamps & Royal Palms.

const HEIGHT_M := 24.0
const PLAZA_Y := 4.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Keystone", LandmarkMaterials.pbr("stone", "#BFB7A6", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#E7D6B2", 4.0))
	lm.use("PlazaTile", LandmarkMaterials.pbr("brick", "#C57C56", 2.5))
	lm.use("Terracotta", LandmarkMaterials.pbr("terracotta", "#B85436", 2.5))
	lm.use("DarkMetal", LandmarkMaterials.paint("#252728", 0.48, 0.54))
	lm.use("Glass", LandmarkMaterials.glass("#223442"))
	lm.use("PalmTrunk", LandmarkMaterials.pbr("limestone", "#9C968B", 2.0))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#436B34", 2.0, 0.78))
	lm.use("PlazaLamp", LandmarkMaterials.lit("#FFE8B3", 1.05))

	_raised_plaza_and_stairs(lm)
	_main_library_and_tower(lm)
	_history_miami_and_loggia(lm)
	_art_pavilion(lm)
	_courtyard_palms_and_lamps(lm)
	lm.commit(model)

	var spots: Array = [
		[Vector3(4.0, PLAZA_Y + 0.8, 0.0), Vector3(26.0, 17.5, 20.0), 52.0, 1.25, 42.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-6.0, PLAZA_Y + 0.8, 4.0), Vector3(4.0, 14.0, -24.0), 54.0, 1.10, 40.0, Color(1.0, 0.90, 0.72)],
		[Vector3(4.0, PLAZA_Y + 0.8, -4.0), Vector3(-25.0, 13.5, 22.0), 52.0, 1.05, 38.0, Color(1.0, 0.90, 0.72)],
		[Vector3(47.0, 1.2, 0.0), Vector3(36.0, 10.0, 0.0), 56.0, 1.15, 34.0, Color(1.0, 0.92, 0.78)],
	]
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _raised_plaza_and_stairs(lm: LandmarkMesh) -> void:
	# Main coral-travertine plinth (77.0 x 79.0 m, plus East/West grand stairs out to 87.6 x 81.6 m)
	lm.box("Keystone", Vector3(0.0, PLAZA_Y * 0.5, 0.0), Vector3(77.0, PLAZA_Y, 79.0), Basis(), 0.06)
	lm.box("Keystone", Vector3(0.0, PLAZA_Y - 0.18, 0.0), Vector3(78.0, 0.42, 80.0), Basis(), 0.04)
	# Diagonal-patterned red/ochre quarry-tile courtyard surface + travertine border bands
	lm.box("PlazaTile", Vector3(0.0, PLAZA_Y + 0.04, 0.0), Vector3(75.4, 0.08, 77.4), Basis(), 0.0)
	for ang in [0.0, PI * 0.5]:
		var b_inlay := Basis(Vector3.UP, float(ang) + PI * 0.25)
		lm.box("Keystone", Vector3(-1.5, PLAZA_Y + 0.06, -0.5), Vector3(32.0, 0.06, 0.55), b_inlay, 0.0)

	# Street-level recessed dark louvre grilles set into the coral-stone plinth (seen in quarter.jpg)
	for side_z in [-1.0, 1.0]:
		for k in 6:
			var xk := -28.0 + float(k) * 11.2
			lm.box("DarkMetal", Vector3(xk, 2.25, float(side_z) * 39.45),
				Vector3(3.4, 3.1, 0.22), Basis(), 0.0)
	for side_x in [-1.0, 1.0]:
		for k in [-22.0, 22.0]:
			lm.box("DarkMetal", Vector3(float(side_x) * 38.45, 2.25, float(k)),
				Vector3(0.22, 3.1, 4.2), Basis(), 0.0)

	# Grand East (+X, NW 1st Ave) & West (-X) entry staircases climbing y = 0.0..4.8 m
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		var sw := 19.0 if sx > 0.0 else 14.0
		var run := 5.3
		var steps := 10
		for i in steps:
			var t := float(i) / float(steps)
			var h := PLAZA_Y * (1.0 - t)
			var xc := s * (38.5 + run * (t + 0.5 / float(steps)))
			lm.box("Keystone", Vector3(xc, h * 0.5, 0.0),
				Vector3(run / float(steps) + 0.08, h, sw), Basis(), 0.02)
		# Heavy coral-stone cheek walls & dark iron handrails
		for sz in [-1.0, 1.0]:
			var z_cheek := float(sz) * (sw * 0.5 + 0.65)
			lm.box("Keystone", Vector3(s * (38.5 + run * 0.5), PLAZA_Y * 0.5 + 0.35, z_cheek),
				Vector3(run + 0.4, PLAZA_Y + 0.70, 1.3), Basis(), 0.04)
		for rail_z in [-sw * 0.32, 0.0, sw * 0.32]:
			lm.beam("DarkMetal", Vector3(s * (38.5 + run), 0.95, float(rail_z)),
				Vector3(s * 38.5, PLAZA_Y + 0.95, float(rail_z)), 0.08, 0.10, Vector3.UP)

	# Perimeter stone parapet & ornamental iron balustrade along open East & South/North edges
	for seg_z: Vector2 in [Vector2(-38.5, -10.5), Vector2(10.5, 38.5)]:
		var zc := (seg_z.x + seg_z.y) * 0.5
		var zl := seg_z.y - seg_z.x
		lm.box("Keystone", Vector3(38.1, PLAZA_Y + 0.35, zc), Vector3(0.75, 0.70, zl), Basis(), 0.03)
		lm.box("DarkMetal", Vector3(38.1, PLAZA_Y + 0.92, zc), Vector3(0.16, 0.45, zl - 0.8), Basis(), 0.0)

static func _hipped_tile_roof(lm: LandmarkMesh, cx: float, cz: float, wx: float, wz: float,
		eaves_y: float, ridge_y: float) -> void:
	# Cornice molding + hipped terracotta roof core + barrel_tile_strip ribs along all 4 eaves
	lm.box("Keystone", Vector3(cx, eaves_y - 0.24, cz), Vector3(wx + 0.9, 0.52, wz + 0.9), Basis(), 0.03)
	var half_short := minf(wx, wz) * 0.5
	var inset := half_short * 0.76
	var low := SkyKit.rect(wx + 1.1, wz + 1.1, cx, cz)
	var high := SkyKit.rect(maxf(wx + 1.1 - inset * 2.0, 1.4), maxf(wz + 1.1 - inset * 2.0, 1.4), cx, cz)
	for i in 4:
		var j := (i + 1) % 4
		var p0 := Vector3(low[i].x, eaves_y, low[i].y)
		var p1 := Vector3(low[j].x, eaves_y, low[j].y)
		var p2 := Vector3(high[j].x, ridge_y, high[j].y)
		var p3 := Vector3(high[i].x, ridge_y, high[i].y)
		lm.quad("Terracotta", p0, p1, p2, p3)
	lm.poly_prism("Terracotta", high, ridge_y - 0.18, ridge_y + 0.04, true)

	# 3D clay barrel-tile ribs along both long eaves via LandmarkMiKit.barrel_tile_strip
	var strip_d := minf(inset, 4.2)
	var strip_top := lerpf(eaves_y, ridge_y, strip_d / maxf(inset, 0.5))
	LandmarkMiKit.barrel_tile_strip(lm, "Terracotta",
		Vector2(cx - wx * 0.46, cz - wz * 0.5), Vector2(cx + wx * 0.46, cz - wz * 0.5),
		eaves_y + 0.04, strip_top, strip_d, Vector2(0.0, -1.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Terracotta",
		Vector2(cx + wx * 0.46, cz + wz * 0.5), Vector2(cx - wx * 0.46, cz + wz * 0.5),
		eaves_y + 0.04, strip_top, strip_d, Vector2(0.0, 1.0))

static func _arcade_run(lm: LandmarkMesh, a: Vector2, b: Vector2, outward: Vector2,
		bays: int, arch_top_y: float) -> void:
	# Shaded ground-plaza Mediterranean Revival colonnade with round coral-stone columns & arches
	var n2 := outward.normalized()
	var n3 := Vector3(n2.x, 0.0, n2.y)
	var dir2 := (b - a).normalized()
	var basis := Basis(Vector3(dir2.x, 0.0, dir2.y), Vector3.UP, n3)
	var span := a.distance_to(b)
	var bay_w := span / float(bays)
	var col_h := arch_top_y - PLAZA_Y - 1.35
	# Recessed dark arcade shadow back-wall & arched doors
	var mid_back := (a + b) * 0.5 - n2 * 2.6
	lm.box("Glass", Vector3(mid_back.x, PLAZA_Y + (arch_top_y - PLAZA_Y) * 0.48, mid_back.y),
		Vector3(span - 0.8, (arch_top_y - PLAZA_Y) * 0.90, 0.35), basis, 0.0)
	lm.box("Stucco", Vector3((a.x + b.x) * 0.5 - n2.x * 1.3, arch_top_y - 0.15, (a.y + b.y) * 0.5 - n2.y * 1.3),
		Vector3(span, 0.35, 2.7), basis, 0.0)
	for i in bays + 1:
		var p2 := a.lerp(b, float(i) / float(bays))
		var base := Vector3(p2.x, PLAZA_Y, p2.y)
		lm.box("Keystone", base + Vector3(0.0, 0.16, 0.0), Vector3(0.92, 0.32, 0.92), basis, 0.02)
		lm.frustum("Keystone", base + Vector3(0.0, 0.32, 0.0), 0.34, 0.31, col_h - 0.32, 12)
		lm.box("Keystone", base + Vector3(0.0, col_h + 0.18, 0.0), Vector3(0.96, 0.36, 0.96), basis, 0.03)
	for i in bays:
		var p0 := a.lerp(b, float(i) / float(bays))
		var p1 := a.lerp(b, float(i + 1) / float(bays))
		var pm := (p0 + p1) * 0.5
		# Arch spandrel lintel & keystone
		var c_sp := Vector3(pm.x, PLAZA_Y + col_h + 0.88, pm.y)
		lm.box("Stucco", c_sp, Vector3(bay_w, 1.05, 0.68), basis, 0.0)
		lm.beam("Keystone", Vector3(p0.x, PLAZA_Y + col_h + 0.36, p0.y),
			Vector3(pm.x, arch_top_y - 0.25, pm.y), 0.36, 0.74, n3)
		lm.beam("Keystone", Vector3(pm.x, arch_top_y - 0.25, pm.y),
			Vector3(p1.x, PLAZA_Y + col_h + 0.36, p1.y), 0.36, 0.74, n3)
		if i % 2 == 1:
			var l_pos := Vector3(pm.x - n2.x * 1.25, arch_top_y - 0.75, pm.y - n2.y * 1.25)
			lm.box("PlazaLamp", l_pos, Vector3(0.32, 0.46, 0.32), Basis(), 0.0)

static func _main_library_and_tower(lm: LandmarkMesh) -> void:
	# 1) Miami-Dade Main Library (South-East wing, x = -11.0..+36.5, z = +14.0..+38.0, eaves y = 18.2 m)
	var cx := 12.75
	var cz := 26.0
	var wx := 47.5
	var wz := 24.0
	var eaves := 18.2
	# Upper stucco mass above ground arcade (front sits at z = 14.0 m)
	lm.box("Stucco", Vector3(cx, PLAZA_Y + (eaves - PLAZA_Y) * 0.5, cz + 1.4),
		Vector3(wx, eaves - PLAZA_Y, wz - 2.8), Basis(), 0.05)
	lm.box("Stucco", Vector3(cx, 9.6 + (eaves - 9.6) * 0.5, 15.4),
		Vector3(wx, eaves - 9.6, 2.8), Basis(), 0.05)
	_arcade_run(lm, Vector2(-10.2, 14.1), Vector2(21.2, 14.1), Vector2(0.0, -1.0), 7, 9.6)
	# Clerestory frieze windows & tall recessed reading-room windows (seen in front.jpg)
	for k in 8:
		var xw := -8.5 + float(k) * 5.6
		lm.box("Glass", Vector3(xw, 16.5, 13.92), Vector3(1.05, 1.35, 0.20), Basis(), 0.0)
		if k % 2 == 0:
			lm.box("Glass", Vector3(xw, 12.8, 13.92), Vector3(1.45, 3.6, 0.22), Basis(), 0.0)
	_hipped_tile_roof(lm, cx, cz, wx, wz, eaves, 21.6)

	# Tallest Library Belvedere / Campanile Tower at inner NE corner reaching exact HEIGHT_M = 24.0 m
	var tx := 29.5
	var tz := 19.5
	var tw := 11.6
	var t_eaves := 21.35
	lm.box("Stucco", Vector3(tx, PLAZA_Y + (t_eaves - PLAZA_Y) * 0.5, tz),
		Vector3(tw, t_eaves - PLAZA_Y, tw), Basis(), 0.05)
	lm.box("Keystone", Vector3(tx, 17.6, tz), Vector3(tw + 0.5, 0.42, tw + 0.5), Basis(), 0.02)
	# Arched belfry loggia openings on all 4 faces of the upper belvedere stage
	for side in 4:
		var ang := float(side) * PI * 0.5
		var b := Basis(Vector3.UP, ang)
		for off in [-2.1, 2.1]:
			lm.box("DarkMetal", Vector3(tx, 19.45, tz) + b.z * (tw * 0.5 + 0.02) + b.x * float(off),
				Vector3(1.55, 2.45, 0.22), b, 0.0)
	_hipped_tile_roof(lm, tx, tz, tw, tw, t_eaves, 23.65)
	# Bronze Mediterranean roof finial capping cleanly at y = 24.0 m
	lm.frustum("DarkMetal", Vector3(tx, 23.60, tz), 0.36, 0.08, 0.40, 8)

static func _history_miami_and_loggia(lm: LandmarkMesh) -> void:
	# 2) HistoryMiami Museum Pavilion (North wing, x = -22.5..+34.5, z = -38.0..-16.0, eaves y = 15.6 m)
	var cx := 6.0
	var cz := -27.0
	var wx := 57.0
	var wz := 22.0
	var eaves := 15.6
	lm.box("Stucco", Vector3(cx, PLAZA_Y + (eaves - PLAZA_Y) * 0.5, cz - 1.3),
		Vector3(wx, eaves - PLAZA_Y, wz - 2.6), Basis(), 0.05)
	lm.box("Stucco", Vector3(cx, 9.3 + (eaves - 9.3) * 0.5, -17.3),
		Vector3(wx, eaves - 9.3, 2.6), Basis(), 0.05)
	_arcade_run(lm, Vector2(33.5, -16.1), Vector2(-21.5, -16.1), Vector2(0.0, 1.0), 11, 9.3)
	for k in 9:
		var xw := -18.0 + float(k) * 6.2
		lm.box("Glass", Vector3(xw, 13.8, -15.92), Vector3(1.0, 1.25, 0.20), Basis(), 0.0)
	_hipped_tile_roof(lm, cx, cz, wx, wz, eaves, 19.0)

	# West Mural Gallery Bridge / Covered Loggia (seen straight ahead in front.jpg, y = 4.8..11.2 m)
	lm.box("Stucco", Vector3(-30.5, PLAZA_Y + 4.8, -3.0), Vector3(12.0, 3.2, 27.0), Basis(), 0.04)
	lm.box("Terracotta", Vector3(-30.5, PLAZA_Y + 6.52, -3.0), Vector3(12.5, 0.26, 27.5), Basis(), 0.02)
	for k in 5:
		var zp := -14.0 + float(k) * 5.5
		lm.box("Stucco", Vector3(-25.2, PLAZA_Y + 1.6, zp), Vector3(0.95, 3.2, 1.15), Basis(), 0.02)
		lm.box("Keystone", Vector3(-35.8, PLAZA_Y + 1.6, zp), Vector3(0.95, 3.2, 1.15), Basis(), 0.02)

static func _art_pavilion(lm: LandmarkMesh) -> void:
	# 3) Art Museum / Gallery Pavilion (South-West wing, x = -37.0..-16.5, z = +10.5..+37.5, eaves y = 14.8 m)
	var cx := -26.75
	var cz := 24.0
	var wx := 20.5
	var wz := 27.0
	var eaves := 14.8
	lm.box("Stucco", Vector3(cx - 1.2, PLAZA_Y + (eaves - PLAZA_Y) * 0.5, cz),
		Vector3(wx - 2.4, eaves - PLAZA_Y, wz), Basis(), 0.05)
	lm.box("Stucco", Vector3(-17.7, 9.1 + (eaves - 9.1) * 0.5, cz),
		Vector3(2.4, eaves - 9.1, wz), Basis(), 0.05)
	_arcade_run(lm, Vector2(-16.6, 11.5), Vector2(-16.6, 36.5), Vector2(1.0, 0.0), 5, 9.1)
	_hipped_tile_roof(lm, cx, cz, wx, wz, eaves, 18.0)

static func _courtyard_palms_and_lamps(lm: LandmarkMesh) -> void:
	# Courtyard Royal Palms in raised coral-stone planters (staying well under 24.0 m tower crest)
	var palms := [
		[Vector3(-11.0, PLAZA_Y, -9.5), 14.2, 0.4],
		[Vector3(24.0, PLAZA_Y, -9.5), 14.8, 1.7],
		[Vector3(-10.5, PLAZA_Y, 7.5), 13.6, 2.5],
		[Vector3(31.5, PLAZA_Y, 4.5), 15.0, 0.9],
		[Vector3(41.5, 0.0, -18.5), 16.5, 1.2],
		[Vector3(41.5, 0.0, 18.5), 16.0, 2.8],
	]
	for p in palms:
		var pos: Vector3 = p[0]
		var h: float = float(p[1])
		var ang: float = float(p[2])
		lm.box("Keystone", pos + Vector3(0.0, 0.32, 0.0), Vector3(3.2, 0.64, 3.2), Basis(), 0.03)
		lm.box("PalmFrond", pos + Vector3(0.0, 0.66, 0.0), Vector3(2.6, 0.12, 2.6), Basis(), 0.0)
		LandmarkMiKit.royal_palm(lm, "PalmTrunk", "PalmFrond", pos + Vector3(0.0, 0.65, 0.0), h, ang)

	# Traditional cast-iron 5-globe plaza streetlamps & central bronze courtyard sculpture (front.jpg)
	var lamp_pts := [
		Vector3(14.5, PLAZA_Y, -5.5),
		Vector3(14.5, PLAZA_Y, 5.5),
		Vector3(-2.5, PLAZA_Y, -5.5),
		Vector3(-2.5, PLAZA_Y, 5.5),
	]
	for lp in lamp_pts:
		var p_lamp: Vector3 = lp
		lm.frustum("DarkMetal", p_lamp, 0.32, 0.14, 3.5, 8)
		lm.box("PlazaLamp", p_lamp + Vector3(0.0, 3.78, 0.0), Vector3(0.36, 0.48, 0.36), Basis(), 0.04)
		for a in 4:
			var dir := Vector3(cos(TAU * float(a) / 4.0), 0.0, sin(TAU * float(a) / 4.0))
			lm.beam("DarkMetal", p_lamp + Vector3(0.0, 3.25, 0.0), p_lamp + dir * 0.55 + Vector3(0.0, 3.45, 0.0), 0.07, 0.07)
			lm.box("PlazaLamp", p_lamp + dir * 0.55 + Vector3(0.0, 3.68, 0.0), Vector3(0.28, 0.38, 0.28), Basis(), 0.03)

	# Abstract bronze sculpture on coral-stone pedestal in west court (front.jpg)
	lm.box("Keystone", Vector3(-18.5, PLAZA_Y + 0.55, -2.5), Vector3(1.9, 1.10, 1.9), Basis(), 0.03)
	lm.beam("DarkMetal", Vector3(-18.8, PLAZA_Y + 1.1, -2.5), Vector3(-18.1, PLAZA_Y + 2.35, -2.2), 0.65, 0.52)
