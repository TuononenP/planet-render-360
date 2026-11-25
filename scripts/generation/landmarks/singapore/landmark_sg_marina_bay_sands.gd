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
	var kit := SkyKit.tower("lowe_blue", 3.0, 3.4, [], "#E2E0DA")
	var lm := kit.lm
	lm.use("Clad", LandmarkMaterials.pbr("concrete", "#E6E3DC", 3.0))
	lm.use("Hull", LandmarkMaterials.pbr("concrete", "#CFCBC3", 3.0))
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#58606A", 2.0, 0.32, 0.72))
	lm.use("Balcony", LandmarkMaterials.pbr("concrete", "#DCD8CE", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#5A8296"))
	lm.use("Pool", LandmarkMaterials.pool_water())
	lm.use("Trees", LandmarkMaterials.pbr("forest", "#2F6630", 3.0))
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
	# Hotel base podium linking the three towers.
	lm.box("Hull", Vector3(-4.0, 4.5, 8.0), Vector3(316.0, 9.0, 86.0))
	lm.box("Clad", Vector3(-4.0, 9.2, 8.0), Vector3(318.0, 0.6, 88.0))
	# The Shoppes at Marina Bay Sands: sweeping curved-roof waterfront mall west of the towers (-Z).
	for i in 3:
		var sx := -96.0 + float(i) * 96.0
		lm.box("Hull", Vector3(sx, 7.5, -108.0), Vector3(84.0, 15.0, 62.0))
		lm.box("Glass", Vector3(sx, 7.5, -139.2), Vector3(78.0, 13.0, 0.8))
		# Sculptural sweeping timber/concrete wave roof over Shoppes.
		lm.box("Clad", Vector3(sx, 16.0, -108.0), Vector3(88.0, 2.2, 68.0), Basis(Vector3.RIGHT, 0.08))
		lm.box("SkyLamp", Vector3(sx, 15.2, -141.0), Vector3(84.0, 0.35, 0.35))
	# Waterfront event promenade apron.
	lm.box("Hull", Vector3(0.0, 1.2, -158.0), Vector3(310.0, 2.4, 34.0))
	# Crystal Pavilion North (Louis Vuitton faceted glass island pavilion, way 172013197).
	var lv_c := Vector3(58.0, 0.0, -196.0)
	lm.box("Hull", lv_c + Vector3(0.0, 1.5, 0.0), Vector3(44.0, 3.0, 34.0))
	lm.box("Glass", lv_c + Vector3(0.0, 9.0, 0.0), Vector3(38.0, 12.0, 28.0))
	lm.box("Clad", lv_c + Vector3(0.0, 16.0, 0.0), Vector3(42.0, 2.0, 32.0), Basis(Vector3.FORWARD, -0.07))
	lm.box("AppleLamp", lv_c + Vector3(0.0, 8.0, 0.0), Vector3(30.0, 8.0, 20.0))
	# Apple Marina Bay Sands (30 m floating geodesic glass dome sphere on the bay, way 821764692).
	var ap_c := Vector3(-68.0, 0.0, -198.0)
	lm.frustum("Hull", ap_c, 16.5, 16.0, 2.5, 24)
	LandmarkSgKit.loft_shell(lm, "Glass", ap_c + Vector3(0.0, 2.5, 0.0), 15.0, 15.0, 16.5, 10, 24, 0.82)
	LandmarkSgKit.shell_arch_ribs(lm, "Steel", ap_c + Vector3(0.0, 2.5, 0.0), 15.0, 15.0, 16.5, 10, 0.25, 0.28, 12, 0.82)
	LandmarkAsiaSouthUtil.dome(lm, "AppleLamp", ap_c + Vector3(0.0, 3.0, 0.0), 12.0, 12.5, 14, 6)
	# Underwater/waterfront boardwalk bridge to Apple dome.
	lm.box("Hull", Vector3(-68.0, 1.6, -178.0), Vector3(8.0, 1.2, 22.0))

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

		# Straight West Slab (facing Marina Bay, -Z) with SkyKit curtain wall + vertical fins.
		var w_pts := PackedVector2Array([
			Vector2(-hw, -13.0), Vector2(hw, -13.0), Vector2(hw, -2.0), Vector2(-hw, -2.0)])
		var w_rot := PackedVector2Array()
		for p in w_pts:
			var v := b * Vector3(p.x, 0.0, p.y)
			w_rot.append(Vector2(cx + v.x, cz + v.z))
		kit.prism("Facade", w_rot, 9.0, 189.0)
		# Shear end-walls & vertical architectural fins on west facade.
		for s: float in [-1.0, 1.0]:
			lm.box("Clad", o + b * Vector3(s * (hw + 0.6), 99.0, -7.5), Vector3(1.8, 180.0, 11.6), b)
		for f in range(-4, 5):
			var fx := float(f) * (wx / 9.0)
			lm.box("Clad", o + b * Vector3(fx, 99.0, -13.3), Vector3(0.55, 180.0, 0.8), b)

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
				var x := lerpf(-hw, hw, float(k) * 0.5)
				row_f.append(o + b * Vector3(x, y, ez + 5.5))
				row_b.append(o + b * Vector3(x, y, ez - 5.5))
			front_grid.append(row_f)
			back_grid.append(row_b)
		lm.grid("Glass", front_grid)
		lm.grid("Glass", back_grid)
		# Curved shear end-walls along east leg.
		for s: float in [-1.0, 1.0]:
			var prev := o + b * Vector3(s * (hw + 0.5), 9.0, _east_leg_z(0.0, east_z0))
			for i in range(1, segs + 1):
				var t := float(i) / float(segs)
				var cur := o + b * Vector3(s * (hw + 0.5), 9.0 + 180.0 * t, _east_leg_z(t, east_z0))
				lm.beam("Clad", prev, cur, 1.8, 11.6)
				prev = cur
		# Stepped balcony trays along east leg (every 2 storeys for crisp shadow bands).
		for fl in range(1, 27):
			var t := float(fl) / 26.0
			var y := 9.0 + 180.0 * t
			var ez := _east_leg_z(t, east_z0)
			lm.box("Balcony", o + b * Vector3(0.0, y, ez + 5.8), Vector3(wx + 1.0, 0.55, 2.2), b, 0.0)
			# Sky-atrium cross-struts tying east and west legs above L23.
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
	# Multi-tier hull lofted along the bend: soffit -> belly -> deck rim.
	var tiers := [
		[187.0, 190.5, 0.58, "Hull"],
		[190.5, 195.0, 0.82, "Hull"],
		[195.0, 200.0, 1.00, "Clad"],
		[200.0, 200.8, 0.96, "Hull"],
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
		west_lamp.append(Vector3(x, 199.4, cz - hw * 1.02))
		east_lamp.append(Vector3(x, 199.4, cz + hw * 1.02))
	LandmarkSgKit.led_ribbon(lm, "SkyLamp", west_lamp, 0.65)
	LandmarkSgKit.led_ribbon(lm, "SkyLamp", east_lamp, 0.55)
	for i in 32:
		var x := -144.0 + float(i) * 10.4
		var cz := _skypark_center_z(x)
		var hw := _hull_hw(stations, x)
		lm.box("Steel", Vector3(x, 191.5, cz), Vector3(0.9, 5.2, hw * 1.68), Basis(), 0.0)

	# 150 m Infinity Pool along the city-facing west side (-Z) of the SkyPark deck.
	for seg in 6:
		var x0 := -45.0 + float(seg) * 25.0
		var x1 := x0 + 25.0
		var xm := 0.5 * (x0 + x1)
		var cz := _skypark_center_z(xm)
		var slope := (_skypark_center_z(x1) - _skypark_center_z(x0)) / 25.0
		var pb := Basis(Vector3.UP, -atan(slope))
		lm.box("Pool", Vector3(xm, 201.0, cz - 10.5), Vector3(25.4, 0.6, 8.8), pb)
		lm.box("Clad", Vector3(xm, 200.9, cz - 15.2), Vector3(25.4, 0.9, 0.9), pb, 0.0)
	# Glass windbreak balustrade around the deck perimeter.
	for i in stations.size() - 1:
		var a: Array = stations[i]
		var b_st: Array = stations[i + 1]
		var xa := float(a[0]); var xb := float(b_st[0])
		for side: float in [-1.0, 1.0]:
			var pa := Vector3(xa, 201.8, _skypark_center_z(xa) + side * float(a[1]) * 0.94)
			var pb_v := Vector3(xb, 201.8, _skypark_center_z(xb) + side * float(b_st[1]) * 0.94)
			lm.beam("Glass", pa, pb_v, 0.14, 1.8)

	# Lush SkyPark tropical garden, palms, and north observation prow pavilion (top 207 m).
	for i in 18:
		var x := -132.0 + float(i) * 16.0
		var cz := _skypark_center_z(x)
		var z_off := 8.5 + 2.0 * sin(float(i) * 1.7)
		LandmarkSgKit.palm(lm, "Trunk", "Trees", Vector3(x, 200.8, cz + z_off), 5.8 + fmod(float(i) * 0.7, 1.4), Vector2(0.3, 0.2), 7)
		if i % 2 == 0:
			LandmarkAsiaSouthUtil.dome(lm, "Trees", Vector3(x + 6.0, 200.8, cz + z_off - 3.5), 3.6, 4.2, 8, 4)
	# North observation deck & bar canopy on the 66.5 m cantilever.
	var prow_z := _skypark_center_z(164.0)
	lm.box("Clad", Vector3(164.0, 202.2, prow_z), Vector3(24.0, 2.8, 12.0))
	lm.box("Glass", Vector3(164.0, 204.6, prow_z), Vector3(18.0, 2.2, 9.0))
	lm.box("Clad", Vector3(164.0, 206.4, prow_z), Vector3(22.0, 1.2, 11.0))

static func _hull_hw(stations: Array, x: float) -> float:
	for i in stations.size() - 1:
		var a: Array = stations[i]
		var b: Array = stations[i + 1]
		if x >= float(a[0]) and x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / (float(b[0]) - float(a[0])))
	return 3.0
