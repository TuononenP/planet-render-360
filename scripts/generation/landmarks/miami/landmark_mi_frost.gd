class_name LandmarkMiFrost
extends RefCounted

## Phillip and Patricia Frost Museum of Science — Maurice A. Ferré Park MI-2A.4
## Site: 1101 Biscayne Blvd, OSM way 319426548 + way 484587349 (25.785151, -80.187850, yaw_deg -24.1).
## Architect: Grimshaw Architects (2017).
## Measured envelope & four-building open-air campus (height_m = 32.0, footprint 140 x 92 m):
##   - Frost Planetarium (-X/-Z Biscayne Blvd corner): 26.2 m diameter (r = 13.1 m) full spherical
##     white precast-concrete dome cradled in a sculpted circular plaza basin.
##   - Gulf Stream Aquarium (central courtyard): iconic 3-level inverted conical white concrete
##     vessel flaring to r = 16.5 m at y = 24.0 m, crowned with a glowing turquoise pool_water
##     open-water deck & shade canopy, and pierced below by the recessed 9.5 m glass oculus lens.
##   - North Wing & West/Innovation Wing (y = 0..30.6 m): textured white geometric ceramic-tile
##     and board-formed concrete museum blocks linked by multi-level open-air breezeway bridges,
##     topped by white steel solar photovoltaic canopies reaching exact y = 32.0 m.

const HEIGHT_M := 32.0
const DOME_POS := Vector3(-42.0, 14.3, -16.0)
const DOME_R := 13.1
const AQUA_POS := Vector3(-6.0, 0.0, -14.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Precast", LandmarkMaterials.pbr("render", "#F4F3EE", 4.0))
	lm.use("TileRelief", LandmarkMaterials.pbr("limestone", "#E6E4DC", 2.8))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C9C5BC", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#224C5A"))
	lm.use("AquaWater", LandmarkMaterials.pool_water("#18B8CC", 0.07))
	lm.use("OculusLamp", LandmarkMaterials.lit("#26D0E8", 0.70))
	lm.use("Steel", LandmarkMaterials.paint("#DCE1E6", 0.40, 0.55))
	lm.use("Solar", LandmarkMaterials.pbr("slate", "#233246", 2.0, 0.22, 0.35))

	_build_plaza_base(lm)
	_build_planetarium_sphere(lm)
	_build_gulf_stream_aquarium(lm)
	_build_north_and_west_wings(lm)
	_build_breezeways_and_solar_roof(lm)
	lm.commit(model)

	var cool := Color(0.74, 0.90, 1.0)
	var aqua := Color(0.25, 0.85, 0.96)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-62.0, 2.0, -16.0), DOME_POS + Vector3(0.0, 2.0, 0.0), 54.0, 1.25, 48.0, cool],
		[Vector3(-42.0, 2.0, -38.0), DOME_POS + Vector3(0.0, 2.0, 0.0), 54.0, 1.15, 48.0, cool],
		[Vector3(-6.0, 1.2, -2.0), Vector3(-6.0, 14.0, -14.0), 58.0, 1.20, 38.0, aqua],
		[Vector3(36.0, 2.0, 0.0), Vector3(36.0, 18.0, -22.0), 52.0, 1.0, 50.0, cool],
		[Vector3(0.0, 2.0, 42.0), Vector3(0.0, 18.0, 22.0), 54.0, 1.0, 50.0, cool],
	])

static func _build_plaza_base(lm: LandmarkMesh) -> void:
	# Campus plinth terrace (136 x 88 m, y = -0.35..1.2 m) with stepped arrival court
	var poly := TowerSpec.plan("round", 136.0, 88.0, 10.0, -2.0, -2.0)
	lm.poly_prism("Concrete", poly, -0.35, 1.2)
	# Raised lower promenade deck connecting the four buildings (y = 1.2..5.2 m on East/South)
	lm.box("Concrete", Vector3(14.0, 3.2, 4.0), Vector3(96.0, 4.0, 68.0))

static func _build_planetarium_sphere(lm: LandmarkMesh) -> void:
	# Sculpted circular plaza cradle & amphitheatre ring surrounding the base of the sphere
	var cradle_c := Vector3(DOME_POS.x, 1.2, DOME_POS.z)
	lm.lathe("Concrete", cradle_c, PackedVector2Array([
		Vector2(16.8, 0.0), Vector2(16.2, 3.6), Vector2(14.0, 3.6),
		Vector2(11.5, 1.2), Vector2(0.0, 1.2)]), 28)

	# 26.2 m diameter (r = 13.1 m) precast white spherical Frost Planetarium dome (y = 1.2..27.4 m)
	var prof := PackedVector2Array()
	var rings := 16
	for j in rings + 1:
		var theta := -PI * 0.47 + (PI * 0.97) * (float(j) / float(rings))
		var r := maxf(cos(theta) * DOME_R, 0.0)
		var y := DOME_R + sin(theta) * DOME_R
		prof.append(Vector2(r, y))
	lm.lathe("Precast", Vector3(DOME_POS.x, DOME_POS.y - DOME_R, DOME_POS.z), prof, 28)

	# Equatorial & meridian subtle structural reveal bands + bridge link into the Aquarium/West Wing
	lm.lathe("TileRelief", Vector3(DOME_POS.x, DOME_POS.y - 0.18, DOME_POS.z), PackedVector2Array([
		Vector2(DOME_R + 0.05, 0.0), Vector2(DOME_R + 0.05, 0.36)]), 28, 1.0, 1.0, 0.0, true, false)
	lm.box("Concrete", Vector3(-25.0, 7.6, -15.0), Vector3(12.0, 3.6, 5.8))

static func _build_gulf_stream_aquarium(lm: LandmarkMesh) -> void:
	# 3-storey inverted conical white concrete Gulf Stream Aquarium vessel (y = 4.8..24.0 m)
	# Supported on 4 inclined sculptural V-piers over the open-air oculus plaza (see front.jpg!)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3
		var foot := AQUA_POS + Vector3(cos(a) * 14.2, 1.2, sin(a) * 14.2)
		var haunch := AQUA_POS + Vector3(cos(a) * 10.6, 9.8, sin(a) * 10.6)
		lm.beam("Concrete", foot, haunch, 1.35, 1.85)

	# Recessed glowing 9.5 m circular oculus lens at the bottom of the cone (y = 5.4 m)
	lm.frustum("Concrete", AQUA_POS + Vector3(0.0, 5.2, 0.0), 9.2, 10.2, 2.2, 24)
	lm.disc("OculusLamp", AQUA_POS + Vector3(0.0, 5.18, 0.0), Vector3.DOWN, 4.6, 24)

	# Flaring conical precast vessel wall from r = 9.8 m at y = 7.2 m up to r = 16.6 m at y = 24.0 m
	lm.lathe("Precast", AQUA_POS + Vector3(0.0, 7.2, 0.0), PackedVector2Array([
		Vector2(9.8, 0.0), Vector2(11.6, 4.8), Vector2(13.8, 10.5),
		Vector2(16.6, 16.8), Vector2(15.6, 16.8), Vector2(15.2, 15.8)]), 28)

	# Vivid turquoise Gulf Stream open-water top tank surface at y = 23.2 m + glass viewing parapet
	lm.disc("AquaWater", AQUA_POS + Vector3(0.0, 23.25, 0.0), Vector3.UP, 15.3, 28)
	lm.lathe("Glass", AQUA_POS + Vector3(0.0, 24.0, 0.0), PackedVector2Array([
		Vector2(16.4, 0.0), Vector2(16.4, 1.15)]), 28, 1.0, 1.0, 0.0, true, false)

	# Crisp white tensile shade sail canopy suspended above the open aquarium deck (y = 26.8..28.6 m)
	var rows: Array = []
	for j in 7:
		var v := -1.0 + 2.0 * (float(j) / 6.0)
		var row := PackedVector3Array()
		for i in 7:
			var u := -1.0 + 2.0 * (float(i) / 6.0)
			var sag := 27.6 + 0.85 * (u * u - v * v)
			row.append(AQUA_POS + Vector3(u * 13.5, sag, v * 13.5))
		rows.append(row)
	lm.grid("Precast", rows, Vector3.UP)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var mast_x: float = AQUA_POS.x + sx * 15.5
			var mast_z: float = AQUA_POS.z + sz * 15.5
			lm.beam("Steel", Vector3(mast_x, 23.8, mast_z), Vector3(mast_x * 0.96, 29.0, mast_z * 0.96), 0.30, 0.30)

static func _build_north_and_west_wings(lm: LandmarkMesh) -> void:
	# North Wing (x = 16..64 m, z = -39..-13 m, y = 1.2..30.2 m): pixel-textured ceramic tile facade
	var nw_c := Vector3(40.0, 15.7, -26.0)
	lm.box("Precast", nw_c, Vector3(48.0, 29.0, 25.0))
	_add_textured_wing_detail(lm, nw_c, 48.0, 25.0, 29.0)

	# West / Baptist Health Innovation Wing (x = -48..+54 m, z = 10..36 m, y = 1.2..30.2 m):
	# Long sculpted white museum bar along the south side of the canyon breezeway
	var sw_c := Vector3(4.0, 15.7, 23.0)
	lm.box("Precast", sw_c, Vector3(102.0, 29.0, 24.0))
	_add_textured_wing_detail(lm, sw_c, 102.0, 24.0, 29.0)
	# Stepped west cantilevered terrace prow facing Biscayne Blvd (-X, +Z)
	lm.box("TileRelief", Vector3(-51.0, 18.0, 22.0), Vector3(14.0, 18.5, 20.0))
	lm.box("Glass", Vector3(-58.05, 17.5, 22.0), Vector3(0.30, 13.5, 16.0), Basis(), 0.0)

static func _add_textured_wing_detail(lm: LandmarkMesh, c: Vector3, w: float, d: float, h: float) -> void:
	var y_bot := c.y - h * 0.5
	var bays := maxi(int(w / 8.5), 4)
	for sz in [-1.0, 1.0]:
		var fz: float = c.z + sz * (d * 0.5 + 0.08)
		# Horizontal ribbon window bands + geometric relief ceramic panels
		for fl in 4:
			var wy := y_bot + 6.2 + float(fl) * 5.8
			lm.box("Glass", Vector3(c.x, wy, fz), Vector3(w - 6.0, 2.1, 0.24), Basis(), 0.0)
			for b in bays:
				if (b + fl) % 2 == 0:
					var bx := c.x - w * 0.5 + (float(b) + 0.5) * (w / float(bays))
					lm.box("TileRelief", Vector3(bx, wy + 2.8, fz + sz * 0.08),
						Vector3((w / float(bays)) * 0.82, 3.1, 0.28))

static func _build_breezeways_and_solar_roof(lm: LandmarkMesh) -> void:
	# Multi-level open-air concrete canyon walkways & bridges linking North Wing, Aquarium & West Wing
	for by in [10.8, 16.6, 22.4]:
		# East breezeway bridge (between North Wing z = -13.5 and West Wing z = +11.0)
		lm.box("Concrete", Vector3(26.0, by, -1.2), Vector3(8.5, 0.65, 25.0))
		lm.box("Glass", Vector3(21.8, by + 0.85, -1.2), Vector3(0.18, 1.15, 24.5), Basis(), 0.0)
		lm.box("Glass", Vector3(30.2, by + 0.85, -1.2), Vector3(0.18, 1.15, 24.5), Basis(), 0.0)
		# West breezeway bridge linking Aquarium terrace to West Wing
		lm.box("Concrete", Vector3(-22.0, by, -1.5), Vector3(6.5, 0.65, 24.0))
		lm.box("Glass", Vector3(-25.2, by + 0.85, -1.5), Vector3(0.18, 1.15, 23.5), Basis(), 0.0)

	# Rooftop Solar Farm steel pergolas & angled photovoltaic arrays topping at exact HEIGHT_M = 32.0 m
	_solar_canopy(lm, Vector3(40.0, 30.2, -26.0), 42.0, 18.0)
	_solar_canopy(lm, Vector3(6.0, 30.2, 23.0), 86.0, 18.0)

static func _solar_canopy(lm: LandmarkMesh, base: Vector3, w: float, d: float) -> void:
	var cols := maxi(int(w / 10.5), 3)
	for i in cols + 1:
		var px := base.x - w * 0.5 + w * (float(i) / float(cols))
		for sz in [-1.0, 1.0]:
			var pz: float = base.z + sz * (d * 0.42)
			lm.beam("Steel", Vector3(px, base.y, pz), Vector3(px, 31.72, pz), 0.24, 0.24)
		lm.beam("Steel", Vector3(px, 31.72, base.z - d * 0.48), Vector3(px, 31.72, base.z + d * 0.48), 0.22, 0.26)
	# Solar PV deck plates & perimeter frame reaching exact y = 32.0 m
	for r in 3:
		var rz := base.z - d * 0.32 + float(r) * (d * 0.32)
		lm.box("Solar", Vector3(base.x, 31.88, rz), Vector3(w, 0.16, d * 0.26), Basis(), 0.0)
	lm.box("Steel", Vector3(base.x, 31.92, base.z - d * 0.48), Vector3(w + 0.4, 0.16, 0.24), Basis(), 0.0)
	lm.box("Steel", Vector3(base.x, 31.92, base.z + d * 0.48), Vector3(w + 0.4, 0.16, 0.24), Basis(), 0.0)
