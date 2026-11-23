class_name LandmarkMiMiamicentral
extends RefCounted

## MiamiCentral (Brightline Station) — Miami MI-2B
## Architect: Skidmore, Owings & Merrill (SOM, 2018), height_m = 45.0.
## Site: OSM way 1105389938, centroid 25.778577, -80.195789, yaw_deg = -2.0.
## Footprint: 48.1 x 165.0 m (+X East-West width 48.1 m, +Z North-South length 165.0 m).
## Envelope:
##   - 3 glazed ground-concourse halls leaving 2 East-West cross-street portals open beneath.
##   - 2 rows of giant angled white V-truss columns (y = 0.0..14.5 m) carrying continuous
##     elevated white Warren V-truss side girders & coffered soffits (y = 14.5..24.0 m).
##   - Elevated concourse, 3-track rail deck, platforms, berthed Brightline train & warm Lit strips.
##   - Sweeping louvred silver-white station canopy & clerestory glazing rising to 32.0 m,
##     plus north/south glazed concourse overbuild frames reaching 45.0 m.

const HEIGHT_M := 45.0
const HALF_X := 24.0
const HALF_Z := 82.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhiteSteel", LandmarkMaterials.pbr("render", "#F2EFE8", 3.5, 0.38))
	lm.use("SilverCanopy", LandmarkMaterials.pbr("sheet_metal", "#DCE0E4", 3.0, 0.36, 0.36))
	lm.use("WarmSoffit", LandmarkMaterials.pbr("limestone", "#CBBBA2", 3.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#96999B", 4.0))
	lm.use("DarkMetal", LandmarkMaterials.paint("#282E34", 0.42, 0.46))
	lm.use("Glass", LandmarkMaterials.glass("#1D3342"))
	lm.use("YellowAccent", LandmarkMaterials.paint("#F5C400", 0.34, 0.15))
	lm.use("PlatLamp", LandmarkMaterials.lit("#FFEBC2", 1.18))

	_ground_halls_and_v_columns(lm)
	_elevated_v_truss_and_platforms(lm)
	_station_canopy(lm)
	_overbuild_frames(lm)
	lm.commit(model)

	var spots: Array = [
		[Vector3(31.0, 1.5, -52.0), Vector3(18.0, 26.0, -52.0), 54.0, 1.15, 65.0, Color(0.98, 0.95, 0.90)],
		[Vector3(31.0, 1.5, 0.0), Vector3(18.0, 22.0, 0.0), 54.0, 1.15, 60.0, Color(0.98, 0.95, 0.90)],
		[Vector3(31.0, 1.5, 52.0), Vector3(18.0, 24.0, 52.0), 54.0, 1.15, 65.0, Color(0.98, 0.95, 0.90)],
		[Vector3(-31.0, 1.5, -52.0), Vector3(-18.0, 26.0, -52.0), 54.0, 1.15, 65.0, Color(0.98, 0.95, 0.90)],
		[Vector3(-31.0, 1.5, 0.0), Vector3(-18.0, 22.0, 0.0), 54.0, 1.15, 60.0, Color(0.98, 0.95, 0.90)],
		[Vector3(-31.0, 1.5, 52.0), Vector3(-18.0, 24.0, 52.0), 54.0, 1.15, 65.0, Color(0.98, 0.95, 0.90)],
	]
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _ground_halls_and_v_columns(lm: LandmarkMesh) -> void:
	# Three glazed ground-concourse halls separated by two open cross-street portals:
	# Portal 1: z = -35.5..-17.5 m (18 m clear street); Portal 2: z = +17.5..+35.5 m (18 m clear street).
	var halls := [
		Vector2(-78.5, -36.5),
		Vector2(-16.5, 16.5),
		Vector2(36.5, 78.5),
	]
	for h in halls:
		var z0: float = h.x
		var z1: float = h.y
		var zc := (z0 + z1) * 0.5
		var zl := z1 - z0
		lm.box("Concrete", Vector3(0.0, 0.18, zc), Vector3(36.4, 0.36, zl + 1.2), Basis(), 0.03)
		lm.box("Glass", Vector3(0.0, 7.25, zc), Vector3(34.6, 13.8, zl), Basis(), 0.0)
		# Vertical curtain-wall mullions along East/West concourse glass walls
		var m_count := int(zl / 4.2)
		for m in m_count + 1:
			var zm := lerpf(z0 + 0.4, z1 - 0.4, float(m) / float(maxi(m_count, 1)))
			for sx in [-1.0, 1.0]:
				lm.box("DarkMetal", Vector3(float(sx) * 17.38, 7.25, zm),
					Vector3(0.18, 13.8, 0.22), Basis(), 0.0)
		# Brightline signature yellow entrance portal frame on central & north concourses
		for sx in [-1.0, 1.0]:
			var px := float(sx) * 17.55
			lm.box("YellowAccent", Vector3(px, 3.8, zc), Vector3(0.55, 0.42, 7.2), Basis(), 0.02)
			for sz in [-1.0, 1.0]:
				lm.box("YellowAccent", Vector3(px, 1.9, zc + float(sz) * 3.4),
					Vector3(0.55, 3.8, 0.42), Basis(), 0.02)

	# Two rows of SOM's monumental angled white V-truss columns straddling the streets (y = 0..14.5 m)
	# Positioned safely outside the two cross-street roadways so portals remain 100% unobstructed.
	var col_zs := [-72.0, -45.0, -9.5, 9.5, 45.0, 72.0]
	for z_base in col_zs:
		var zb: float = float(z_base)
		for sx in [-1.0, 1.0]:
			var s := float(sx)
			var base_pt := Vector3(s * 20.2, 0.35, zb)
			lm.box("Concrete", Vector3(s * 20.2, 0.20, zb), Vector3(2.8, 0.40, 3.0), Basis(), 0.04)
			# Twin outward-raking white steel/concrete V-legs rising to truss bottom chord at y = 14.5 m
			var top_a := Vector3(s * 23.1, 14.5, zb - 5.2)
			var top_b := Vector3(s * 23.1, 14.5, zb + 5.2)
			lm.beam("WhiteSteel", base_pt, top_a, 1.55, 1.35, Vector3(s, 0.0, 0.0), true)
			lm.beam("WhiteSteel", base_pt, top_b, 1.55, 1.35, Vector3(s, 0.0, 0.0), true)
			# Inner raking tripod strut bracing the concourse soffit (visible in street-level photos)
			lm.beam("Concrete", base_pt + Vector3(-s * 0.6, 0.0, 0.0),
				Vector3(s * 14.8, 14.2, zb), 1.25, 1.15, Vector3(0.0, 0.0, 1.0), true)

static func _elevated_v_truss_and_platforms(lm: LandmarkMesh) -> void:
	# Elevated concourse deck & coffered warm-beige underside soffit (y = 14.1..19.6 m)
	lm.box("WarmSoffit", Vector3(0.0, 14.35, 0.0), Vector3(46.2, 0.50, 164.0), Basis(), 0.03)
	for k in 17:
		var zk := -80.0 + float(k) * 10.0
		lm.box("WhiteSteel", Vector3(0.0, 14.08, zk), Vector3(45.8, 0.28, 0.55), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		lm.box("WhiteSteel", Vector3(float(sx) * 11.5, 14.08, 0.0), Vector3(0.55, 0.28, 163.6), Basis(), 0.0)

	# Recessed concourse lounge glass & warm spandrel backing behind the outer V-trusses (y = 14.6..19.8 m)
	lm.box("Glass", Vector3(0.0, 17.2, 0.0), Vector3(42.4, 5.2, 160.0), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		lm.box("WarmSoffit", Vector3(float(sx) * 21.8, 15.6, 0.0), Vector3(0.9, 1.9, 162.4), Basis(), 0.02)

	# Continuous monumental white Warren V-truss fascia girders along East & West sides (y = 14.5..23.4 m)
	var bays := 16
	var z_min := -81.6
	var z_max := 81.6
	var bay_l := (z_max - z_min) / float(bays)
	for sx in [-1.0, 1.0]:
		var x_truss := float(sx) * 23.25
		var side_n := Vector3(float(sx), 0.0, 0.0)
		lm.box("WhiteSteel", Vector3(x_truss, 14.65, 0.0), Vector3(1.45, 0.85, 164.4), Basis(), 0.04)
		lm.box("WhiteSteel", Vector3(x_truss, 23.15, 0.0), Vector3(1.55, 0.95, 164.6), Basis(), 0.04)
		for i in bays:
			var za := z_min + float(i) * bay_l
			var zm := za + bay_l * 0.5
			var zb := za + bay_l
			lm.beam("WhiteSteel", Vector3(x_truss, 23.0, za), Vector3(x_truss, 14.7, zm), 1.15, 1.10, side_n)
			lm.beam("WhiteSteel", Vector3(x_truss, 14.7, zm), Vector3(x_truss, 23.0, zb), 1.15, 1.10, side_n)

	# Trackbed slab & 3 railway tracks + 2 passenger platforms (y = 19.8..21.2 m)
	lm.box("Concrete", Vector3(0.0, 20.05, 0.0), Vector3(45.4, 0.65, 164.2), Basis(), 0.03)
	var track_xs := [-8.6, 0.0, 8.6]
	for tx in track_xs:
		var x_tr: float = float(tx)
		lm.box("DarkMetal", Vector3(x_tr, 20.42, 0.0), Vector3(2.4, 0.10, 163.6), Basis(), 0.0)
		for r_off in [-0.72, 0.72]:
			lm.box("SilverCanopy", Vector3(x_tr + float(r_off), 20.52, 0.0),
				Vector3(0.14, 0.14, 163.8), Basis(), 0.0)

	# Two wide passenger platforms with Brightline yellow safety tactile strips & warm Lit strips above
	var plat_specs := [Vector2(-15.6, 9.2), Vector2(15.6, 9.2), Vector2(-4.3, 4.8)]
	for ps in plat_specs:
		var px: float = ps.x
		var pw: float = ps.y
		lm.box("Concrete", Vector3(px, 20.82, 0.0), Vector3(pw, 0.90, 156.0), Basis(), 0.03)
		lm.box("YellowAccent", Vector3(px + (-pw * 0.46 if px > 0.0 else pw * 0.46), 21.28, 0.0),
			Vector3(0.32, 0.05, 155.0), Basis(), 0.0)
		lm.box("PlatLamp", Vector3(px, 23.75, 0.0), Vector3(0.55, 0.18, 148.0), Basis(), 0.0)

	# Berthed streamlined Brightline trainset on Track 2 (x = 0.0, z = -42..+36 m)
	lm.box("WhiteSteel", Vector3(0.0, 22.15, -3.0), Vector3(3.05, 3.15, 74.0), Basis(), 0.14)
	lm.box("DarkMetal", Vector3(0.0, 22.35, -3.0), Vector3(3.12, 1.05, 68.0), Basis(), 0.0)
	lm.box("YellowAccent", Vector3(0.0, 21.35, -3.0), Vector3(3.10, 0.45, 74.2), Basis(), 0.02)
	for sz in [-1.0, 1.0]:
		lm.spire("YellowAccent", Vector3(0.0, 21.5, -3.0 + float(sz) * 37.0), 1.45, 1.9, 0.55, 4)

static func _station_canopy(lm: LandmarkMesh) -> void:
	# Sweeping louvred silver-white station canopy & clerestory glazing rising to y = 32.0 m
	var z_len := 156.0
	# Central arched skylight monitor peaking at y = 32.0 m + side gull-wing louvred canopy decks
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		# Outer canopy wing sloping from y = 25.2 m at x = ±24.0 m up to y = 29.4 m at x = ±8.5 m
		var tilt := Basis(Vector3.FORWARD, -s * atan2(4.2, 15.5))
		lm.box("SilverCanopy", Vector3(s * 16.25, 27.3, 0.0), Vector3(16.1, 0.48, z_len), tilt, 0.03)
		lm.box("WarmSoffit", Vector3(s * 16.25, 27.0, 0.0), Vector3(15.6, 0.18, z_len - 1.0), tilt, 0.0)
		# Clerestory glazing band rising from y = 29.1 to 31.4 m
		lm.box("Glass", Vector3(s * 8.1, 30.25, 0.0), Vector3(0.32, 2.35, z_len - 4.0), Basis(), 0.0)
		# Horizontal sun-louvre blades along canopy eaves
		for lv in 4:
			var t_lv := float(lv) / 3.0
			lm.box("WhiteSteel", Vector3(s * (23.7 - t_lv * 2.4), 24.85 + t_lv * 0.65, 0.0),
				Vector3(0.36, 0.12, z_len), Basis(), 0.0)

	# Upper vaulted skylight cap peaking at y = 32.0 m
	lm.gable("SilverCanopy", Vector3(0.0, 31.15, 0.0), 16.6, z_len - 2.0, 0.85, Basis(), 0.5, "WhiteSteel")

	# Transverse white steel portal ribs supporting the canopy every 13 m
	for r in 13:
		var zr := -78.0 + float(r) * 13.0
		for sx in [-1.0, 1.0]:
			var s := float(sx)
			lm.beam("WhiteSteel", Vector3(s * 23.2, 23.3, zr), Vector3(s * 8.2, 29.5, zr), 0.75, 0.65, Vector3.BACK)
			lm.beam("WhiteSteel", Vector3(s * 8.2, 29.5, zr), Vector3(0.0, 31.95, zr), 0.70, 0.55, Vector3.BACK)

static func _overbuild_frames(lm: LandmarkMesh) -> void:
	# North & South glazed concourse overbuild frames rising out of the station deck to HEIGHT_M = 45.0 m
	# (visible in reference front.jpg directly atop the V-truss concourse).
	_overbuild_block(lm, Vector3(-1.5, 0.0, -55.0), 33.0, 38.0, 25.5, HEIGHT_M)
	_overbuild_block(lm, Vector3(-1.5, 0.0, 54.0), 31.0, 34.0, 25.5, 38.8)

static func _overbuild_block(lm: LandmarkMesh, base_c: Vector3, wx: float, wz: float,
		y0: float, y_top: float) -> void:
	var body_top := y_top - 1.35
	var h := body_top - y0
	lm.box("Glass", Vector3(base_c.x, y0 + h * 0.5, base_c.z), Vector3(wx - 0.5, h, wz - 0.5), Basis(), 0.0)
	# Crisp white SOM structural exo-grid: floor slab bands & perimeter column mullions
	var floors := maxi(2, roundi(h / 3.9))
	for f in floors + 1:
		var yf := lerpf(y0, body_top, float(f) / float(floors))
		lm.box("WhiteSteel", Vector3(base_c.x, yf, base_c.z), Vector3(wx + 0.25, 0.44, wz + 0.25), Basis(), 0.02)
	var cols_x := roundi(wx / 5.5)
	for ix in cols_x + 1:
		var xk := base_c.x - wx * 0.5 + wx * float(ix) / float(cols_x)
		for sz in [-1.0, 1.0]:
			lm.box("WhiteSteel", Vector3(xk, y0 + h * 0.5, base_c.z + float(sz) * wz * 0.5),
				Vector3(0.48, h, 0.48), Basis(), 0.02)
	var cols_z := roundi(wz / 5.5)
	for iz in cols_z + 1:
		var zk := base_c.z - wz * 0.5 + wz * float(iz) / float(cols_z)
		for sx in [-1.0, 1.0]:
			lm.box("WhiteSteel", Vector3(base_c.x + float(sx) * wx * 0.5, y0 + h * 0.5, zk),
				Vector3(0.48, h, 0.48), Basis(), 0.02)
	# Recessed louvred mechanical crown & white parapet coping landing cleanly at y_top (45.0 m on North)
	lm.box("DarkMetal", Vector3(base_c.x, body_top + 0.60, base_c.z),
		Vector3(wx * 0.78, 1.20, wz * 0.78), Basis(), 0.0)
	lm.box("WhiteSteel", Vector3(base_c.x, y_top - 0.18, base_c.z),
		Vector3(wx * 0.82, 0.36, wz * 0.82), Basis(), 0.02)
