class_name LandmarkMiClimateRibbon
extends RefCounted

## Brickell City Centre & Climate Ribbon — Miami MI-3B
## Architects: Arquitectonica & Hugh Dutton Associés (2016), height_m = 32.0.
## Site: OSM way 813418718, centroid 25.767126, -80.193272, yaw_deg = 88.1.
## Footprint: 187.3 x 110.0 m (+X along 3 North-South city blocks, +Z East-West across galleria).
## Envelope:
##   - 3 stepped stone, silver-metal & glass open-air luxury retail blocks (y = 0.0..21.0 m)
##     separated by 2 open cross-street canyons and bisected by an open-air shopping canyon
##     with elevated glass skybridges & diagonal escalator banks.
##   - Sweeping, undulating 180 m steel-and-glass Climate Ribbon environmental trellis
##     (y = 23.0..32.0 m): curved grid glass canopy + white steel ribs & hanging aerodynamic
##     louvre blades funneling sea breezes on graceful Y-struts, with warm coral/amber dusk lighting.

const HEIGHT_M := 32.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("SilverPanel", LandmarkMaterials.pbr("sheet_metal", "#C6CBD0", 3.0, 0.34, 0.42))
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#DCD5C7", 3.5))
	lm.use("WoodSoffit", LandmarkMaterials.pbr("wood", "#9E6E46", 2.5))
	lm.use("RibbonWhite", LandmarkMaterials.pbr("render", "#F4F5F7", 3.0, 0.32))
	lm.use("RibbonGlass", LandmarkMaterials.glass("#6294B5"))
	lm.use("StoreGlass", LandmarkMaterials.glass("#1E3140"))
	lm.use("DarkMetal", LandmarkMaterials.paint("#262B30", 0.40, 0.48))
	lm.use("Foliage", LandmarkMaterials.pbr("grass", "#3E6B35", 2.0, 0.80))
	lm.use("RibbonLamp", LandmarkMaterials.lit("#FF9E5E", 1.25))

	_retail_blocks_and_bridges(lm)
	_climate_ribbon_canopy(lm)
	lm.commit(model)

	# Warm coral/amber dusk under-lighting washing the undulating Climate Ribbon louvres
	var spots: Array = [
		[Vector3(-64.0, 21.4, -10.5), Vector3(-64.0, 30.5, 0.0), 58.0, 1.15, 26.0, Color(1.0, 0.66, 0.38)],
		[Vector3(-30.0, 15.0, 11.5), Vector3(-30.0, 29.0, 0.0), 58.0, 1.15, 26.0, Color(1.0, 0.66, 0.38)],
		[Vector3(0.0, 21.4, -10.5), Vector3(0.0, 31.8, 0.0), 60.0, 1.35, 28.0, Color(1.0, 0.64, 0.36)],
		[Vector3(0.0, 21.4, 10.5), Vector3(0.0, 31.8, 0.0), 60.0, 1.35, 28.0, Color(1.0, 0.64, 0.36)],
		[Vector3(30.0, 15.0, -11.5), Vector3(30.0, 29.0, 0.0), 58.0, 1.15, 26.0, Color(1.0, 0.66, 0.38)],
		[Vector3(64.0, 21.4, 10.5), Vector3(64.0, 30.5, 0.0), 58.0, 1.15, 26.0, Color(1.0, 0.66, 0.38)],
	]
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _retail_blocks_and_bridges(lm: LandmarkMesh) -> void:
	# Three city-block podiums along X (-93.0..+93.0 m) separated by two 13 m open cross-streets
	# at x = -37.0..-24.0 m and x = +24.0..+37.0 m; each block split by a 21 m central open canyon!
	var blocks := [
		Vector2(-93.0, -37.0),
		Vector2(-24.0, 24.0),
		Vector2(37.0, 93.0),
	]
	for blk in blocks:
		var x0: float = blk.x
		var x1: float = blk.y
		var xc := (x0 + x1) * 0.5
		var xl := x1 - x0
		# Ground canyon paving & wood plaza deck (y = 0.0..0.30 m)
		lm.box("Limestone", Vector3(xc, 0.14, 0.0), Vector3(xl, 0.28, 108.0), Basis(), 0.02)
		lm.box("WoodSoffit", Vector3(xc, 0.30, 0.0), Vector3(xl - 4.0, 0.06, 18.0), Basis(), 0.0)

		for sz in [-1.0, 1.0]:
			var s := float(sz)
			# Each wing spans from z = ±10.5 m (canyon edge) out to z = ±54.0 m (108.0..110.0 m total)
			var z_in := s * 10.5
			var z_out := s * 54.5
			var zc_1 := (z_in + z_out) * 0.5
			var wz_1 := absf(z_out - z_in)

			# Level 1 (y = 0.28..6.8 m): Limestone piers, recessed luxury glass storefronts, wood soffit
			lm.box("StoreGlass", Vector3(xc, 3.54, zc_1), Vector3(xl - 1.2, 6.52, wz_1 - 1.2), Basis(), 0.0)
			lm.box("WoodSoffit", Vector3(xc, 6.58, zc_1 - s * 0.4), Vector3(xl + 0.6, 0.36, wz_1 + 1.4), Basis(), 0.02)
			for p in 5:
				var xp := lerpf(x0 + 2.5, x1 - 2.5, float(p) / 4.0)
				lm.box("Limestone", Vector3(xp, 3.54, z_in + s * 0.6), Vector3(1.1, 6.52, 1.2), Basis(), 0.03)

			# Level 2 (y = 6.8..13.8 m): Stepped-back boutique storefronts + open-air gallery walkway & silver fascia
			var z_gal := s * 9.8
			lm.box("SilverPanel", Vector3(xc, 7.15, (z_gal + z_out) * 0.5),
				Vector3(xl + 0.8, 0.72, absf(z_out - z_gal)), Basis(), 0.03)
			lm.box("StoreGlass", Vector3(xc, 8.05, z_gal), Vector3(xl, 1.08, 0.14), Basis(), 0.0)
			var zc_2 := s * 34.0
			var wz_2 := 40.0
			lm.box("StoreGlass", Vector3(xc, 10.4, zc_2), Vector3(xl - 1.6, 6.4, wz_2 - 1.0), Basis(), 0.0)
			lm.box("SilverPanel", Vector3(xc, 12.6, s * 13.8), Vector3(xl + 0.4, 2.2, 0.65), Basis(), 0.03)
			lm.box("WoodSoffit", Vector3(xc, 13.62, zc_2 - s * 1.2), Vector3(xl + 0.4, 0.36, wz_2 + 2.8), Basis(), 0.02)

			# Level 3 (y = 13.8..21.0 m): Faceted brushed-silver & dark-louvred flagship boxes + roof planters
			lm.box("SilverPanel", Vector3(xc, 14.15, zc_2 - s * 1.0),
				Vector3(xl + 0.6, 0.70, wz_2 + 2.4), Basis(), 0.03)
			lm.box("StoreGlass", Vector3(xc, 15.05, s * 12.8), Vector3(xl - 1.0, 1.08, 0.14), Basis(), 0.0)
			var zc_3 := s * 35.8
			var wz_3 := 36.4
			lm.box("SilverPanel", Vector3(xc, 17.5, zc_3), Vector3(xl - 2.0, 6.6, wz_3), Basis(), 0.05)
			# Dark louvre & storefront vitrine insets on Level 3 canyon face (seen in quarter.jpg)
			lm.box("DarkMetal", Vector3(xc - xl * 0.20, 17.6, s * 17.45),
				Vector3(xl * 0.36, 4.8, 0.35), Basis(), 0.0)
			lm.box("StoreGlass", Vector3(xc + xl * 0.22, 17.6, s * 17.45),
				Vector3(xl * 0.36, 4.8, 0.35), Basis(), 0.0)
			lm.box("Limestone", Vector3(xc, 20.92, zc_3), Vector3(xl - 1.4, 0.32, wz_3 + 0.6), Basis(), 0.02)
			# Lush rooftop planter bed along canyon rim
			lm.box("Foliage", Vector3(xc, 21.18, s * 19.8), Vector3(xl * 0.72, 0.45, 2.6), Basis(), 0.04)

		# Diagonal twin escalator banks crisscrossing the open-air central canyon (side.jpg)
		var esc_a := Vector3(xc - 8.5, 0.3, -2.4)
		var esc_b := Vector3(xc + 4.5, 7.1, 2.4)
		var esc_c := Vector3(xc + 9.5, 7.1, 2.4)
		var esc_d := Vector3(xc - 3.5, 14.1, -2.4)
		for off_z in [-0.75, 0.75]:
			var dz := Vector3(0.0, 0.0, float(off_z))
			lm.beam("SilverPanel", esc_a + dz, esc_b + dz, 1.15, 0.85, Vector3.FORWARD)
			lm.beam("StoreGlass", esc_a + dz + Vector3(0.0, 0.85, 0.0), esc_b + dz + Vector3(0.0, 0.85, 0.0), 0.14, 0.85, Vector3.FORWARD)
			lm.beam("SilverPanel", esc_c + dz, esc_d + dz, 1.15, 0.85, Vector3.FORWARD)
			lm.beam("StoreGlass", esc_c + dz + Vector3(0.0, 0.85, 0.0), esc_d + dz + Vector3(0.0, 0.85, 0.0), 0.14, 0.85, Vector3.FORWARD)
		# Canyon cross-walkway bridge at Level 2 & Level 3
		lm.box("SilverPanel", Vector3(xc + 7.0, 6.95, 0.0), Vector3(5.2, 0.55, 20.8), Basis(), 0.02)
		lm.box("SilverPanel", Vector3(xc - 6.0, 13.95, 0.0), Vector3(4.8, 0.55, 22.8), Basis(), 0.02)

	# Elevated glazed skybridges spanning both open cross-street canyons (x = -30.5 m and x = +30.5 m)
	for x_br in [-30.5, 30.5]:
		var xb: float = float(x_br)
		for z_br in [-21.0, 21.0]:
			var zb: float = float(z_br)
			for y_br in [7.0, 14.0]:
				var yb: float = float(y_br)
				lm.box("SilverPanel", Vector3(xb, yb, zb), Vector3(13.6, 0.65, 6.4), Basis(), 0.03)
				lm.box("WoodSoffit", Vector3(xb, yb - 0.34, zb), Vector3(13.4, 0.08, 6.0), Basis(), 0.0)
				lm.box("StoreGlass", Vector3(xb, yb + 1.85, zb), Vector3(13.4, 3.1, 6.0), Basis(), 0.0)
				lm.box("SilverPanel", Vector3(xb, yb + 3.52, zb), Vector3(13.6, 0.35, 6.4), Basis(), 0.02)

static func _ribbon_y(x: float, z: float) -> float:
	# Smooth undulating crest-and-valley wave peaking cleanly at y = 31.72 m at (0, 0)
	# (plus 0.28 m top steel arch rib = exact HEIGHT_M = 32.0 m!).
	var u := x / 90.0
	var env := 1.0 - 0.18 * u * u
	var wave := 0.5 + 0.5 * cos(x * TAU / 60.0)
	var spine := lerpf(25.1, 31.72, wave * env)
	var arch_drop := (z * z) / (19.5 * 19.5) * (1.85 + 0.75 * sin(x * 0.07))
	return spine - arch_drop

static func _ribbon_half_w(x: float) -> float:
	# Billows wide over the central plaza & two cross-street portals, sleeks along the blocks
	var street_flare := exp(-pow((absf(x) - 30.5) / 11.0, 2.0)) * 5.6
	var center_flare := exp(-pow(x / 20.0, 2.0)) * 3.8
	return 14.8 + street_flare + center_flare

static func _climate_ribbon_canopy(lm: LandmarkMesh) -> void:
	var nx := 37
	var nz := 9
	var top_rows: Array = []
	var bot_rows: Array = []
	for ix in nx:
		var x := lerpf(-90.0, 90.0, float(ix) / float(nx - 1))
		var hw := _ribbon_half_w(x)
		var r_top := PackedVector3Array()
		var r_bot := PackedVector3Array()
		for iz in nz:
			var s := lerpf(-1.0, 1.0, float(iz) / float(nz - 1))
			var z := s * hw
			var y := _ribbon_y(x, z)
			r_top.append(Vector3(x, y, z))
			r_bot.append(Vector3(x, y - 0.08, z))
		top_rows.append(r_top)
		bot_rows.append(r_bot)

	# Double-sided undulating laminated glass canopy shell
	lm.grid("RibbonGlass", top_rows, Vector3.UP)
	lm.grid("RibbonGlass", bot_rows, Vector3.DOWN)

	# Longitudinal steel spine & edge tube beams + warm coral/amber glowing dusk spine cove
	for iz_idx in [0, 2, 4, 6, 8]:
		for ix in nx - 1:
			var p0: Vector3 = (top_rows[ix] as PackedVector3Array)[iz_idx] + Vector3(0.0, 0.12, 0.0)
			var p1: Vector3 = (top_rows[ix + 1] as PackedVector3Array)[iz_idx] + Vector3(0.0, 0.12, 0.0)
			var w_long := 0.52 if iz_idx == 4 else 0.34
			lm.beam("RibbonWhite", p0, p1, w_long, 0.32, Vector3.BACK)
			if iz_idx == 4:
				lm.beam("RibbonLamp", p0 - Vector3(0.0, 0.34, 0.0), p1 - Vector3(0.0, 0.34, 0.0), 0.32, 0.16, Vector3.BACK)

	# Transverse arched white steel ribs (crown rib at ix = 18, x = 0 hits y = 31.72 + 0.28 = 32.0 m!)
	# + signature hanging undulating white aerodynamic breeze-scoop louvre blades underneath!
	for ix in nx:
		var row: PackedVector3Array = top_rows[ix]
		var x_cur := row[4].x
		for iz in nz - 1:
			var a := row[iz] + Vector3(0.0, 0.14, 0.0)
			var b := row[iz + 1] + Vector3(0.0, 0.14, 0.0)
			lm.beam("RibbonWhite", a, b, 0.30, 0.28, Vector3.RIGHT)
			# Hanging curved aerodynamic louvre blade scooping sea breeze beneath every rib
			var wave_d := 1.05 + 0.55 * sin(x_cur * 0.11 + float(iz) * 0.65)
			var la := row[iz] - Vector3(0.18, wave_d, 0.0)
			var lb := row[iz + 1] - Vector3(0.18, wave_d * 0.92, 0.0)
			lm.beam("RibbonWhite", (row[iz] + la) * 0.5, (row[iz + 1] + lb) * 0.5,
				0.10, wave_d, Vector3.RIGHT)

	# Lateral cross-street wing canopies funneling breezes across SE 7th & SE 8th St (x = ±30.5 m)
	for x_wing in [-30.5, 30.5]:
		var xw: float = float(x_wing)
		for sz in [-1.0, 1.0]:
			var s := float(sz)
			var w_rows: Array = []
			for iu in 5:
				var x_loc := xw + lerpf(-7.5, 7.5, float(iu) / 4.0)
				var wr := PackedVector3Array()
				for iv in 5:
					var z_loc := s * lerpf(18.5, 46.0, float(iv) / 4.0)
					var y_loc := lerpf(26.4, 24.2, float(iv) / 4.0) + cos(float(iu - 2) * 0.6) * 0.55
					wr.append(Vector3(x_loc, y_loc, z_loc))
				w_rows.append(wr)
			lm.grid("RibbonGlass", w_rows, Vector3.UP)
			for iu in [0, 2, 4]:
				var r_pts: PackedVector3Array = w_rows[iu]
				for iv in 4:
					lm.beam("RibbonWhite", r_pts[iv], r_pts[iv + 1], 0.28, 0.26, Vector3.RIGHT)

	# Graceful branching white steel Y-struts springing from the Level 3 retail roofs (y = 21.0 m)
	var strut_xs := [-80.0, -56.0, -40.0, -18.0, 0.0, 18.0, 40.0, 56.0, 80.0]
	for sx_val in strut_xs:
		var xs: float = float(sx_val)
		var hw := _ribbon_half_w(xs)
		for sz in [-1.0, 1.0]:
			var s := float(sz)
			var foot := Vector3(xs, 20.9, s * 13.2)
			var fork := Vector3(xs, 23.4, s * (hw * 0.62))
			var tip_in := Vector3(xs - 2.2, _ribbon_y(xs - 2.2, s * hw * 0.42), s * hw * 0.42)
			var tip_out := Vector3(xs + 2.2, _ribbon_y(xs + 2.2, s * hw * 0.82), s * hw * 0.82)
			lm.beam("RibbonWhite", foot, fork, 0.52, 0.52, Vector3.RIGHT, true)
			lm.beam("RibbonWhite", fork, tip_in, 0.34, 0.34, Vector3.RIGHT)
			lm.beam("RibbonWhite", fork, tip_out, 0.34, 0.34, Vector3.RIGHT)
