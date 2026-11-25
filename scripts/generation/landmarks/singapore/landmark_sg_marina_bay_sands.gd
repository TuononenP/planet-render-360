class_name LandmarkSgMarinaBaySands
extends RefCounted

## Marina Bay Sands (207 m, SG-2.1):
## - Anchor: Tower 2 centroid (1.28368, 103.86071), yaw -67.5° (+X runs NNE along T1->T3 chord,
##   -Z faces west toward Marina Bay & CBD, +Z faces east toward Gardens by the Bay).
## - Three 55-storey hotel towers at true measured bent centroids (~7° curve, 118 m T1-T2, 106 m T2-T3):
##   each is a straight glazed west curtain-wall slab (`SkyKit` night-lit glass + vertical fins)
##   paired with a curved splayed east balcony slab lofted via `LandmarkMesh.grid` meeting near L23
##   with an open lower atrium gap and pale cladding on the narrow shear end walls.
## - 340 m curved Sands SkyPark hull following the 7° bend with a 66.5 m north cantilever past Tower 3,
##   ribbed soffit, 150 m turquoise `pool_water` infinity pool on the west edge, glass balustrade,
##   palms & sky-garden trees, and north observation prow (207 m top).
## - Waterfront podium: The Shoppes curved-roof blocks west of the towers, faceted glass Crystal
##   Pavilion North, and the 30 m floating geodesic glass dome sphere of Apple Marina Bay Sands.
## - Night: SkyPark white edge ribbon (`SkyLamp`), warm interior glow in Apple sphere & pavilions,
##   tower flood spots (`FLOOD_META`), and red aviation beacons (`HALO_META`).

const TOWER_DATA := [
	# [cx, cz, rot_rad, width_x, east_base_z]
	[-116.0, 2.0, -0.055, 52.0, 32.0],   # Tower 1 (south, widest splay)
	[0.0, -3.5, 0.0, 50.0, 29.0],        # Tower 2 (centre)
	[106.0, 1.5, 0.062, 46.0, 25.0],     # Tower 3 (north, tighter splay)
]

static func build(model: Node3D) -> void:
	var kit := SkyKit.tower("intl_bronze", 3.0, 3.4, [], "#243038")
	var lm := kit.lm
	lm.use("Clad", LandmarkMaterials.pbr("concrete", "#F0EDE5", 3.0))
	lm.use("Hull", LandmarkMaterials.pbr("concrete", "#C8C4BC", 3.0))
	lm.use("DarkHull", LandmarkMaterials.pbr("sheet_metal", "#383F47", 2.0, 0.36, 0.65))
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#4C5560", 2.0, 0.30, 0.74))
	lm.use("SilverRoof", LandmarkMaterials.pbr("sheet_metal", "#E6E9EC", 2.0, 0.25, 0.72))
	lm.use("Balcony", LandmarkMaterials.pbr("concrete", "#CFCBC2", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#223846"))
	lm.use("CanopyGlass", LandmarkMaterials.glass("#7EA4B8"))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#8E6F4E", 2.0))
	lm.use("Pool", LandmarkMaterials.pool_water())
	lm.use("Trees", LandmarkMaterials.pbr("forest", "#275E2B", 3.0))
	lm.use("Trunk", LandmarkMaterials.pbr("wood", "#6E5A46", 2.0))
	lm.use("SkyLamp", LandmarkMaterials.lit("#FFF6E4", 2.6))
	lm.use("AppleLamp", LandmarkMaterials.lit("#FFE4B2", 2.2))

	_build_podium_and_pavilions(lm)
	_build_towers(kit, lm)
	_build_skypark(lm)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-116.0, 12.0, -48.0), Vector3(-116.0, 140.0, -8.0), 58.0, 1.3],
		[Vector3(0.0, 12.0, -52.0), Vector3(0.0, 140.0, -10.0), 58.0, 1.4],
		[Vector3(106.0, 12.0, -48.0), Vector3(106.0, 140.0, -8.0), 58.0, 1.3],
		[Vector3(165.0, 170.0, -35.0), Vector3(172.0, 198.0, 0.0), 65.0, 1.1],
	])
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(186.0, 207.0, 7.0), 2.5, Color(1.0, 0.14, 0.06)],
		[Vector3(-152.0, 204.0, 6.0), 2.2, Color(1.0, 0.14, 0.06)],
	])

static func _build_podium_and_pavilions(lm: LandmarkMesh) -> void:
	# Hotel base podium & angled sloping atrium connectors between Towers 1-2 and 2-3.
	lm.box("Hull", Vector3(-4.0, 4.5, 8.0), Vector3(318.0, 9.0, 82.0))
	lm.box("Clad", Vector3(-4.0, 9.2, 8.0), Vector3(320.0, 0.6, 84.0))
	for ax: float in [-58.0, 53.0]:
		lm.box("Glass", Vector3(ax, 14.0, 2.0), Vector3(64.0, 14.0, 32.0))
		lm.box("Clad", Vector3(ax, 21.8, 2.0), Vector3(66.0, 1.6, 34.0), Basis(Vector3.RIGHT, 0.14))
	# Elevated glazed pedestrian skybridge crossing Bayfront Ave from hotel atrium to The Shoppes.
	lm.box("Glass", Vector3(-4.0, 14.5, -56.0), Vector3(18.0, 5.2, 46.0))
	lm.box("SilverRoof", Vector3(-4.0, 17.4, -56.0), Vector3(20.0, 0.9, 48.0))
	lm.box("Hull", Vector3(-4.0, 11.4, -56.0), Vector3(18.0, 1.1, 46.0))

	# The Shoppes & Sands Expo at Marina Bay Sands: 4 sweeping sculptural curved-shell white ribbed roof volumes
	# separated by vaulted glass-and-steel barrel-vault atrium canyons running the full waterfront length.
	var shop_blocks := [
		[-228.0, 118.0, 17.5, 13.0], # Sands Expo & Convention Centre south hall (largest sweeping wave shell)
		[-106.0, 94.0, 17.0, 11.5],  # South Shoppes sweeping shell
		[4.0, 86.0, 16.0, 10.5],     # Central Shoppes / Casino wave shell
		[104.0, 74.0, 15.2, 9.5],    # North Theatre / Shoppes curved shell
	]
	for sb in shop_blocks:
		var sx := float(sb[0])
		var sw := float(sb[1])
		var wall_h := float(sb[2])
		var arch_h := float(sb[3])
		# Glazed waterfront mall volume.
		lm.box("Glass", Vector3(sx, wall_h * 0.5, -106.0), Vector3(sw - 4.0, wall_h, 58.0))
		lm.box("Hull", Vector3(sx, 1.5, -106.0), Vector3(sw, 3.0, 62.0))
		# Sweeping curved stepped-wave white shell roof (sloping gracefully down toward bay -Z).
		_build_wave_shell_roof(lm, sx, -106.0, wall_h, sw, 64.0, arch_h)
		lm.box("SkyLamp", Vector3(sx, wall_h - 0.8, -136.0), Vector3(sw - 2.0, 0.4, 0.4))

	# Soaring glazed barrel-vault atrium canyons between the Shoppes wave shells.
	for vx: float in [-161.0, -50.0, 56.0]:
		lm.box("Glass", Vector3(vx, 10.0, -106.0), Vector3(16.0, 20.0, 64.0))
		_build_barrel_vault(lm, vx, -106.0, 19.5, 17.0, 66.0, 5.5)

	# Long curved Waterfront Glass Canopy / Promenade Arcade along bayfront (-Z = -144)
	# with iconic white angled Y-masts / cable-stayed steel spires.
	lm.box("Timber", Vector3(-68.0, 1.3, -158.0), Vector3(446.0, 2.6, 38.0))
	lm.box("Hull", Vector3(-68.0, 0.9, -177.0), Vector3(448.0, 1.8, 3.0))
	_build_promenade_canopy(lm, -284.0, 148.0, -144.0)

	# Event Plaza stepped amphitheatre & circular Rain Oculus vortex in front of central atrium.
	var ep_x := -18.0
	for step in 4:
		var st_z := -166.0 - float(step) * 3.8
		var st_y := 2.4 - float(step) * 0.45
		lm.box("Timber", Vector3(ep_x, st_y * 0.5, st_z), Vector3(58.0 - float(step) * 4.0, st_y, 3.6))
	lm.frustum("Hull", Vector3(ep_x, 2.5, -152.0), 11.5, 12.0, 1.8, 20)
	lm.frustum("CanopyGlass", Vector3(ep_x, 3.4, -152.0), 10.8, 9.0, 1.2, 20)

	# Crystal Pavilion North (Louis Vuitton Island Maison) at exact real-life GPS spot in Marina Bay water.
	var lv_c := Vector3(14.0, 0.0, -254.0)
	lm.box("DarkHull", lv_c + Vector3(0.0, 1.2, 0.0), Vector3(46.0, 2.4, 36.0))
	lm.box("Timber", Vector3(14.0, 1.4, -208.0), Vector3(10.0, 1.1, 64.0))
	# Two angled faceted glass crystal volumes with tilted silver-ribbed origami roofs.
	var lv_b1 := Basis(Vector3.UP, 0.24)
	var lv_b2 := Basis(Vector3.UP, -0.32)
	lm.box("Glass", lv_c + Vector3(-8.0, 7.6, -2.0), Vector3(26.0, 10.6, 22.0), lv_b1)
	lm.box("SilverRoof", lv_c + Vector3(-8.0, 13.8, -2.0), Vector3(29.0, 1.4, 25.0), lv_b1 * Basis(Vector3.FORWARD, -0.18))
	lm.box("Glass", lv_c + Vector3(10.0, 6.8, 4.0), Vector3(22.0, 9.0, 18.0), lv_b2)
	lm.box("SilverRoof", lv_c + Vector3(10.0, 12.2, 4.0), Vector3(25.0, 1.3, 21.0), lv_b2 * Basis(Vector3.FORWARD, 0.16))
	lm.box("AppleLamp", lv_c + Vector3(0.0, 6.5, 0.0), Vector3(28.0, 6.8, 18.0))

	# Apple Marina Bay Sands (30 m floating geodesic glass dome sphere at exact real-life GPS spot in Marina Bay).
	var ap_c := Vector3(-195.0, 0.0, -214.0)
	lm.frustum("DarkHull", ap_c, 16.8, 16.2, 2.4, 28)
	LandmarkSgKit.loft_shell(lm, "Glass", ap_c + Vector3(0.0, 2.3, 0.0), 15.2, 15.2, 16.8, 12, 28, 0.84)
	LandmarkSgKit.shell_arch_ribs(lm, "Steel", ap_c + Vector3(0.0, 2.3, 0.0), 15.2, 15.2, 16.8, 10, 0.22, 0.24, 14, 0.84)
	# Concentric horizontal white sunshade baffle rings (signature Apple dome banding).
	for ri in range(1, 8):
		var v := float(ri) / 8.5
		var ry := 2.3 + 16.8 * pow(sin(v * PI * 0.5), 0.84)
		var rrad := 15.35 * cos(v * PI * 0.5)
		lm.frustum("SilverRoof", Vector3(ap_c.x, ry, ap_c.z), rrad, rrad * 0.985, 0.42, 28)
	LandmarkAsiaSouthUtil.dome(lm, "AppleLamp", ap_c + Vector3(0.0, 2.8, 0.0), 12.2, 12.8, 14, 6)
	lm.box("Timber", Vector3(-195.0, 1.5, -189.0), Vector3(7.5, 1.1, 30.0))

	# Waterfront palm promenade lining Marina Bay.
	for pi in 19:
		var px := -272.0 + float(pi) * 22.5
		if absf(px - ep_x) < 18.0:
			continue
		LandmarkSgKit.palm(lm, "Trunk", "Trees", Vector3(px, 2.5, -172.0), 7.5 + fmod(float(pi) * 0.9, 1.6), Vector2(0.25, -0.15), 7)

static func _build_wave_shell_roof(lm: LandmarkMesh, cx: float, cz: float, y_base: float,
		span_x: float, depth_z: float, arch_h: float) -> void:
	# Lofted curved roof arching high on the east (land) side and sweeping smoothly down toward the bay (-Z),
	# topped with stepped white scalloped wave ribs.
	var nx := 12
	var nz := 10
	var grid: Array = []
	for iz in nz + 1:
		var vz := float(iz) / float(nz)  # 0 = bayfront (-Z), 1 = Bayfront Ave (+Z)
		var z := cz - depth_z * 0.5 + vz * depth_z
		var arch_z := sin(vz * PI) * arch_h + vz * 2.2
		var row: Array = []
		for ix in nx + 1:
			var ux := float(ix) / float(nx)
			var x := cx - span_x * 0.5 + ux * span_x
			var crown_x := 0.72 + 0.28 * sin(ux * PI)
			row.append(Vector3(x, y_base + arch_z * crown_x, z))
		grid.append(row)
	lm.grid("SilverRoof", grid)
	# Stepped sculptural white arch ribs standing proud along the shell.
	var rib_count := 9
	for r in rib_count:
		var ux := (float(r) + 0.5) / float(rib_count)
		var x := cx - span_x * 0.5 + ux * span_x
		var crown_x := 0.72 + 0.28 * sin(ux * PI)
		var prev := Vector3.ZERO
		for iz in nz + 1:
			var vz := float(iz) / float(nz)
			var z := cz - depth_z * 0.5 + vz * depth_z
			var y := y_base + (sin(vz * PI) * arch_h + vz * 2.2) * crown_x + 0.55
			var cur := Vector3(x, y, z)
			if iz > 0:
				lm.beam("Clad", prev, cur, 1.35, 1.1)
			prev = cur

static func _build_barrel_vault(lm: LandmarkMesh, cx: float, cz: float, y_base: float,
		span_x: float, depth_z: float, vault_h: float) -> void:
	var segs := 8
	var grid: Array = []
	for iz in 3:
		var z := cz - depth_z * 0.5 + float(iz) * depth_z * 0.5
		var row: Array = []
		for ix in segs + 1:
			var u := float(ix) / float(segs)
			var ang := u * PI
			var x := cx - cos(ang) * span_x * 0.5
			var y := y_base + sin(ang) * vault_h
			row.append(Vector3(x, y, z))
		grid.append(row)
	lm.grid("CanopyGlass", grid)
	for rib in 6:
		var rz := cz - depth_z * 0.45 + float(rib) * (depth_z * 0.18)
		var prev := Vector3.ZERO
		for ix in segs + 1:
			var ang := float(ix) / float(segs) * PI
			var cur := Vector3(cx - cos(ang) * span_x * 0.5, y_base + sin(ang) * vault_h + 0.25, rz)
			if ix > 0:
				lm.beam("Steel", prev, cur, 0.45, 0.45)
			prev = cur

static func _build_promenade_canopy(lm: LandmarkMesh, x0: float, x1: float, cz: float) -> void:
	# Sweeping translucent ribbed glass waterfront canopy + tall white angled cable-stay masts.
	var bays := 15
	var dx := (x1 - x0) / float(bays)
	var grid: Array = []
	for iz in 5:
		var vz := float(iz) / 4.0
		var z := cz - 14.0 + vz * 22.0
		var y := 9.2 + sin(vz * PI) * 2.8 + vz * 1.4
		var row: Array = []
		for ix in bays + 1:
			var x := x0 + float(ix) * dx
			row.append(Vector3(x, y, z))
		grid.append(row)
	lm.grid("CanopyGlass", grid)
	for i in bays + 1:
		var x := x0 + float(i) * dx
		# Tall white mast spire + angled cable stays supporting the waterfront canopy.
		lm.frustum("Clad", Vector3(x, 2.5, cz - 11.0), 0.38, 0.18, 21.5, 6)
		lm.beam("Steel", Vector3(x, 23.0, cz - 11.0), Vector3(x, 10.6, cz - 14.0), 0.16, 0.16)
		lm.beam("Steel", Vector3(x, 23.0, cz - 11.0), Vector3(x, 12.2, cz + 4.0), 0.16, 0.16)
		lm.beam("Clad", Vector3(x, 9.2, cz - 14.0), Vector3(x, 10.6, cz + 8.0), 0.45, 0.45)

static func _build_towers(kit: SkyKit, lm: LandmarkMesh) -> void:
	for td in TOWER_DATA:
		var cx := float(td[0])
		var cz := float(td[1])
		var rot := float(td[2])
		var wx := float(td[3])
		var east_z0 := float(td[4])
		var hw := wx * 0.5
		var b := Basis(Vector3.UP, rot)
		var o := Vector3(cx, 0.0, cz)

		# Straight West Slab (facing Marina Bay, -Z) with dark reflective glass & dark gunmetal mullions.
		var w_pts := PackedVector2Array([
			Vector2(-hw + 1.2, -13.0), Vector2(hw - 1.2, -13.0),
			Vector2(hw - 1.2, -2.0), Vector2(-hw + 1.2, -2.0)])
		var w_rot := PackedVector2Array()
		for p in w_pts:
			var v := b * Vector3(p.x, 0.0, p.y)
			w_rot.append(Vector2(cx + v.x, cz + v.z))
		kit.prism("Facade", w_rot, 9.0, 189.0)
		# Subtle dark vertical fins & horizontal spandrel shadow bands on west facade.
		for f in range(-4, 5):
			var fx := float(f) * ((wx - 4.0) / 9.0)
			lm.box("Steel", o + b * Vector3(fx, 99.0, -13.25), Vector3(0.45, 180.0, 0.65), b)
		for sp in range(1, 18):
			var sy := 9.0 + float(sp) * 10.0
			lm.box("DarkHull", o + b * Vector3(0.0, sy, -13.2), Vector3(wx - 2.6, 0.55, 0.55), b, 0.0)

		# Curved East Slab (splayed at podium, leans to meet west slab near L23 / y=95 m, rises to 189 m).
		var segs := 18
		var front_grid: Array = []
		var back_grid: Array = []
		for i in segs + 1:
			var t := float(i) / float(segs)
			var y := 9.0 + 180.0 * t
			var ez := _east_leg_z(t, east_z0)
			var row_f: Array = []
			var row_b: Array = []
			for k in 3:
				var x := lerpf(-hw + 1.2, hw - 1.2, float(k) * 0.5)
				row_f.append(o + b * Vector3(x, y, ez + 5.2))
				row_b.append(o + b * Vector3(x, y, ez - 5.2))
			front_grid.append(row_f)
			back_grid.append(row_b)
		lm.grid("Glass", front_grid)
		lm.grid("Glass", back_grid)

		# Iconic sculptural bright-white A-frame concrete shear end-walls on both ±hw flanks:
		# west blade flares gently at base, east blade sweeps gracefully from east_z0 to merge above L23,
		# leaving the dramatic open triangular lower atrium void between the two legs.
		for s: float in [-1.0, 1.0]:
			var sx := s * (hw + 0.4)
			var prev_w := o + b * Vector3(sx, 9.0, -13.5)
			var prev_e := o + b * Vector3(sx, 9.0, _east_leg_z(0.0, east_z0))
			for i in range(1, segs + 1):
				var t := float(i) / float(segs)
				var y := 9.0 + 180.0 * t
				var wz := -13.5 + 6.0 * pow(t, 0.85)
				var ez := _east_leg_z(t, east_z0)
				var cur_w := o + b * Vector3(sx, y, wz)
				var cur_e := o + b * Vector3(sx, y, ez)
				var leg_thick := lerpf(11.8, 13.4, pow(t, 1.4))
				lm.beam("Clad", prev_w, cur_w, 3.0, leg_thick)
				lm.beam("Clad", prev_e, cur_e, 3.0, leg_thick)
				# Above L23 (t >= 0.44), solid sculpted concrete web joins the two legs into a single white flank.
				if t >= 0.44:
					var mid_z := 0.5 * (wz + ez)
					var span_z := absf(ez - wz) + leg_thick * 0.9
					lm.box("Clad", o + b * Vector3(sx, y - 5.0, mid_z), Vector3(3.0, 10.6, span_z), b)
				prev_w = cur_w
				prev_e = cur_e
			# Dramatic glazed arch infill inside lower atrium void + white ground buttress shoe.
			lm.box("Clad", o + b * Vector3(sx, 11.5, -16.5), Vector3(3.6, 5.0, 10.0), b)
			lm.box("Clad", o + b * Vector3(sx, 11.5, east_z0 + 4.0), Vector3(3.6, 5.0, 10.0), b)

		# Stepped balcony trays along east leg (every 2 storeys for crisp shadow bands).
		for fl in range(1, 27):
			var t := float(fl) / 26.0
			var y := 9.0 + 180.0 * t
			var ez := _east_leg_z(t, east_z0)
			lm.box("Balcony", o + b * Vector3(0.0, y, ez + 5.6), Vector3(wx - 1.2, 0.55, 2.2), b, 0.0)
			if t >= 0.48:
				lm.box("Steel", o + b * Vector3(0.0, y, -1.0), Vector3(wx - 4.0, 0.5, 4.0), b, 0.0)

static func _east_leg_z(t: float, z0: float) -> float:
	# Curves smoothly from z0 at base to z=4.5 at y=189 m (meeting west slab at z=-2..4.5).
	return 4.5 + (z0 - 4.5) * pow(1.0 - t, 2.15)

static func _skypark_center_z(x: float) -> float:
	# Smooth ~7° bend matching the three tower centroids (-116 -> +2, 0 -> -3.5, +106 -> +1.5, +185 -> +8.5).
	return -3.5 + 0.00038 * x * x

static func _build_skypark(lm: LandmarkMesh) -> void:
	# 340 m hull from x=-154 (south stern) to x=+186 (north cantilever prow past Tower 3 at +106).
	var stations := [
		[-154.0, 4.0], [-144.0, 14.0], [-116.0, 19.5], [-60.0, 20.5],
		[0.0, 21.0], [60.0, 20.5], [106.0, 19.5], [146.0, 16.0],
		[172.0, 10.5], [186.0, 3.0],
	]
	# Multi-tier hull lofted along the bend: dark fluted soffit -> belly -> bright metallic rim -> deck.
	var tiers := [
		[187.0, 190.8, 0.56, "DarkHull"],
		[190.8, 194.8, 0.84, "Hull"],
		[194.8, 199.6, 1.00, "Clad"],
		[199.6, 200.6, 0.96, "DarkHull"],
	]
	for tr in tiers:
		var y0 := float(tr[0])
		var y1 := float(tr[1])
		var wk := float(tr[2])
		var key := str(tr[3])
		var poly := PackedVector2Array()
		for st in stations:
			var x := float(st[0])
			poly.append(Vector2(x, _skypark_center_z(x) + float(st[1]) * wk))
		for i in range(stations.size() - 1, -1, -1):
			var st: Array = stations[i]
			var x := float(st[0])
			poly.append(Vector2(x, _skypark_center_z(x) - float(st[1]) * wk))
		lm.poly_prism(key, poly, y0, y1)

	# Structural soffit ribs & glowing white SkyPark night edge ribbon on west & east sides.
	var west_lamp: Array = []
	var east_lamp: Array = []
	for st in stations:
		var x := float(st[0])
		var cz := _skypark_center_z(x)
		var hw := float(st[1])
		west_lamp.append(Vector3(x, 199.2, cz - hw * 1.02))
		east_lamp.append(Vector3(x, 199.2, cz + hw * 1.02))
	LandmarkSgKit.led_ribbon(lm, "SkyLamp", west_lamp, 0.65)
	LandmarkSgKit.led_ribbon(lm, "SkyLamp", east_lamp, 0.55)
	for i in 32:
		var x := -144.0 + float(i) * 10.4
		var cz := _skypark_center_z(x)
		var hw := _hull_hw(stations, x)
		lm.box("DarkHull", Vector3(x, 191.5, cz), Vector3(0.95, 5.2, hw * 1.68), Basis(), 0.0)

	# 150 m Infinity Pool along the city-facing west side (-Z) of the SkyPark deck.
	for seg in 6:
		var x0 := -45.0 + float(seg) * 25.0
		var x1 := x0 + 25.0
		var xm := 0.5 * (x0 + x1)
		var cz := _skypark_center_z(xm)
		var slope := (_skypark_center_z(x1) - _skypark_center_z(x0)) / 25.0
		var pb := Basis(Vector3.UP, -atan(slope))
		lm.box("Pool", Vector3(xm, 200.9, cz - 10.5), Vector3(25.4, 0.6, 8.8), pb)
		lm.box("Clad", Vector3(xm, 200.8, cz - 15.2), Vector3(25.4, 0.9, 0.9), pb, 0.0)
	# Glass windbreak balustrade around the deck perimeter.
	for i in stations.size() - 1:
		var a: Array = stations[i]
		var b_st: Array = stations[i + 1]
		var xa := float(a[0]); var xb := float(b_st[0])
		for side: float in [-1.0, 1.0]:
			var pa := Vector3(xa, 201.6, _skypark_center_z(xa) + side * float(a[1]) * 0.94)
			var pb_v := Vector3(xb, 201.6, _skypark_center_z(xb) + side * float(b_st[1]) * 0.94)
			lm.beam("CanopyGlass", pa, pb_v, 0.16, 1.8)

	# Two iconic white rectangular rooftop lift-core / restaurant pavilions over Tower 1 & Tower 3 (209.5 m top).
	for px: float in [-114.0, 104.0]:
		var pz := _skypark_center_z(px)
		lm.box("Glass", Vector3(px, 203.2, pz), Vector3(22.0, 5.2, 16.0))
		lm.box("Clad", Vector3(px, 207.2, pz), Vector3(25.0, 4.4, 18.5))
		lm.box("SkyLamp", Vector3(px, 204.8, pz - 8.6), Vector3(21.0, 0.35, 0.35))

	# Lush SkyPark tropical garden canopy & palms rising visibly along the skyline between the pavilions.
	for i in 22:
		var x := -132.0 + float(i) * 13.5
		var cz := _skypark_center_z(x)
		var z_off := 6.8 + 2.5 * sin(float(i) * 1.7)
		LandmarkSgKit.palm(lm, "Trunk", "Trees", Vector3(x, 200.6, cz + z_off), 7.4 + fmod(float(i) * 0.7, 1.8), Vector2(0.3, 0.2), 7)
		LandmarkAsiaSouthUtil.dome(lm, "Trees", Vector3(x + 4.0, 200.6, cz + z_off - 3.0), 4.8, 6.2, 8, 4)
	# North observation deck canopy on the 66.5 m cantilever prow.
	var prow_z := _skypark_center_z(164.0)
	lm.box("Glass", Vector3(164.0, 202.4, prow_z), Vector3(20.0, 3.2, 10.5))
	lm.box("Clad", Vector3(164.0, 204.5, prow_z), Vector3(24.0, 1.3, 12.5))

static func _hull_hw(stations: Array, x: float) -> float:
	for i in stations.size() - 1:
		var a: Array = stations[i]
		var b: Array = stations[i + 1]
		if x >= float(a[0]) and x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / (float(b[0]) - float(a[0])))
	return 3.0
