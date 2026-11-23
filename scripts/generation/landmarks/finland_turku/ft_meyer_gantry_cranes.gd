class_name FtMeyerGantryCranes
extends RefCounted

## Meyer Turku Shipyard Twin Goliath Portal Gantry Cranes at Perno, Turku
## (60.457800, 22.124800, skyline: true, +X = 154 m span across the 365 m
## Rakennusallas building dock turned by yaw_deg = 38.1°, +Z toward sea mouth):
##   - Measured from OSM way:366690301 (366 x 80 m dry dock) and way:673162242
##     (155.5 m rail span, 739 m track length).
##   - South-west 600 t Goliath gantry crane (z = +58.0 m, bridge top 93.0 m,
##     trolley top 97.5 m) and north-east 1200 t Goliath gantry crane (z = -52.0 m,
##     bridge top 100.5 m, machinery/service jib top 105.0 m).
##   - Both cranes feature Konecranes/Meyer deep-blue splayed A-frame portal
##     legs on articulated multi-wheel rail bogies, stair/service access towers,
##     crisp white main trapezoidal box-girder bridges with blue "MEYER TURKU"
##     girder band & lettering panels, upper/lower hoist trolleys, wire-rope
##     cables with heavy spreader beams/hook blocks, glazed operator cabins,
##     and red ICAO aviation warning beacons (HALO_META) + dock floodlights.
## Surfaces: 8 merged PBR parts (Blue, White, DarkSteel, Concrete, Glass,
## Cable, Lamp, Beacon); y >= 0.0 throughout.

const TOP_M := 105.0
const SPAN_HALF := 77.0  # 154.0 m rail gauge

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_crane_rails(lm)
	_build_goliath_crane(lm, -52.0, 91.5, 100.5, 105.0, 4.6, 54.0, true)   # 1200 t crane
	_build_goliath_crane(lm, 58.0, 85.0, 93.0, 97.5, 3.8, 42.0, false)     # 600 t crane
	lm.commit(model)
	_set_night_lights(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Blue", LandmarkMaterials.paint("#16569A", 0.44, 0.45))
	lm.use("White", LandmarkMaterials.paint("#F0F2F5", 0.42, 0.22))
	lm.use("DarkSteel", LandmarkMaterials.paint("#2A323A", 0.48, 0.65))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9A9790", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#22384A"))
	lm.use("Cable", LandmarkMaterials.paint("#1C2024", 0.42, 0.72))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.8))
	lm.use("Beacon", LandmarkMaterials.lit("#FF180C", 2.4))

static func _build_crane_rails(lm: LandmarkMesh) -> void:
	# Concrete crane rail foundations & steel running rails along x = +-77.0 m (y >= 0.0).
	for sx: float in [-1.0, 1.0]:
		var rx := SPAN_HALF * sx
		LandmarkFrKit.rect(lm, "Concrete", rx - 2.2, rx + 2.2, -110.0, 110.0, 0.0, 0.55)
		lm.box("DarkSteel", Vector3(rx - 0.55, 0.70, 0.0), Vector3(0.28, 0.30, 218.0))
		lm.box("DarkSteel", Vector3(rx + 0.55, 0.70, 0.0), Vector3(0.28, 0.30, 218.0))

static func _build_goliath_crane(lm: LandmarkMesh, zc: float, y_bot: float, y_top: float,
		y_peak: float, girder_w: float, hook_y: float, is_main: bool) -> void:
	var leg_spread_z := 23.0 if is_main else 19.5
	var knee_y := y_bot * 0.52
	var leg_r := 1.45 if is_main else 1.20
	# Rail bogie trucks, sill beams, and splayed A-frame legs on both rail tracks (x = +-77 m).
	for sx: float in [-1.0, 1.0]:
		var rx := SPAN_HALF * sx
		var top_x := (SPAN_HALF - 4.5) * sx
		# Articulated twin bogie clusters and sill equalizer box girder.
		for sz: float in [-1.0, 1.0]:
			var bz := zc + leg_spread_z * sz
			lm.box("DarkSteel", Vector3(rx, 1.65, bz), Vector3(3.4, 1.7, 11.0))
			lm.box("Blue", Vector3(rx, 3.05, bz), Vector3(2.9, 1.2, 8.8))
			for wx_off: float in [-0.55, 0.55]:
				for wz_off: float in [-3.6, -1.2, 1.2, 3.6]:
					lm.box("DarkSteel", Vector3(rx + wx_off, 1.05, bz + wz_off),
						Vector3(0.35, 1.1, 1.1))
		lm.box("Blue", Vector3(rx, 3.4, zc), Vector3(2.4, 1.5, leg_spread_z * 2.0 - 4.0))
		# Splayed A-frame legs rising from bogies to the main girder saddle.
		var f_fore := Vector3(rx, 3.6, zc + leg_spread_z)
		var f_aft := Vector3(rx, 3.6, zc - leg_spread_z)
		var m_fore := Vector3(lerpf(rx, top_x, 0.52), knee_y, zc + leg_spread_z * 0.50)
		var m_aft := Vector3(lerpf(rx, top_x, 0.52), knee_y, zc - leg_spread_z * 0.50)
		var t_fore := Vector3(top_x, y_bot - 0.8, zc + girder_w * 0.45)
		var t_aft := Vector3(top_x, y_bot - 0.8, zc - girder_w * 0.45)
		for seg in [[f_fore, m_fore], [m_fore, t_fore], [f_aft, m_aft], [m_aft, t_aft]]:
			lm.beam("Blue", seg[0], seg[1], leg_r, leg_r)
		# Horizontal tie-struts and K-bracing across the A-frame bay.
		lm.beam("Blue", m_fore, m_aft, 0.85, 0.85)
		var low_y := y_bot * 0.24
		var l_fore := f_fore.lerp(m_fore, 0.46)
		var l_aft := f_aft.lerp(m_aft, 0.46)
		lm.beam("Blue", Vector3(l_fore.x, low_y, l_fore.z), Vector3(l_aft.x, low_y, l_aft.z), 0.72, 0.72)
		lm.beam("DarkSteel", l_fore, m_aft, 0.38, 0.38)
		lm.beam("DarkSteel", l_aft, m_fore, 0.38, 0.38)
		lm.beam("DarkSteel", m_fore, t_aft, 0.36, 0.36)
		lm.beam("DarkSteel", m_aft, t_fore, 0.36, 0.36)
		# Machinery/elevator stair tower inside the fixed pier leg (-X).
		if sx < 0.0:
			for st in 10:
				var sy := 6.0 + float(st) * ((y_bot - 10.0) / 10.0)
				lm.box("DarkSteel", Vector3(rx + 1.8, sy, zc - leg_spread_z * 0.35 + float(st % 2) * 1.4),
					Vector3(1.8, 0.28, 3.2))
			lm.beam("White", Vector3(rx + 1.8, 4.0, zc), Vector3(top_x + 1.4, y_bot - 1.5, zc), 0.55, 0.55)

	# Upper portal saddle collars and cantilevered outreach tips beyond the rails.
	var bridge_half := SPAN_HALF + (9.5 if is_main else 7.5)
	for sx: float in [-1.0, 1.0]:
		lm.box("Blue", Vector3((SPAN_HALF - 4.5) * sx, y_bot + 1.2, zc),
			Vector3(8.0, 4.2, girder_w + 3.2))

	# Main horizontal box-girder bridge (white body + Meyer Turku contrasting girder band).
	var gh := y_top - y_bot
	lm.box("White", Vector3(0.0, y_bot + gh * 0.5, zc), Vector3(bridge_half * 2.0, gh, girder_w))
	# Deep-blue lower chord rail flange and upper "Meyer Turku" band framing along both faces.
	lm.box("Blue", Vector3(0.0, y_bot + 0.55, zc), Vector3(bridge_half * 2.0 + 0.4, 1.1, girder_w + 0.35))
	lm.box("Blue", Vector3(0.0, y_top - 0.55, zc), Vector3(bridge_half * 2.0 + 0.4, 1.1, girder_w + 0.35))
	# Crisp white "MEYER TURKU" signage band panels + bold dark-blue letter-bar relief on both girder sides.
	var band_w := 56.0 if is_main else 42.0
	var band_h := gh * 0.42
	for sz: float in [-1.0, 1.0]:
		var bz := zc + (girder_w * 0.5 + 0.12) * sz
		lm.box("White", Vector3(0.0, y_bot + gh * 0.52, bz), Vector3(band_w, band_h, 0.24))
		lm.box("Blue", Vector3(0.0, y_bot + gh * 0.52 + band_h * 0.45, bz + 0.08 * sz),
			Vector3(band_w, 0.32, 0.14))
		lm.box("Blue", Vector3(0.0, y_bot + gh * 0.52 - band_h * 0.45, bz + 0.08 * sz),
			Vector3(band_w, 0.32, 0.14))
		# Stylized geometric glyph blocks reading as "MEYER TURKU" at skyline distance.
		var letters := 10
		for k in letters:
			var lx := lerpf(-band_w * 0.38, band_w * 0.38, float(k) / float(letters - 1))
			lm.box("Blue", Vector3(lx, y_bot + gh * 0.52, bz + 0.10 * sz),
				Vector3(2.1 if is_main else 1.6, band_h * 0.56, 0.16))

	# Top maintenance walkway, safety railings, and overhead crane machinery/service house.
	for sz: float in [-1.0, 1.0]:
		var rz := zc + (girder_w * 0.46) * sz
		lm.box("DarkSteel", Vector3(0.0, y_top + 1.05, rz), Vector3(bridge_half * 1.95, 0.14, 0.14))
		for k in 15:
			var px := lerpf(-bridge_half * 0.94, bridge_half * 0.94, float(k) / 14.0)
			lm.box("DarkSteel", Vector3(px, y_top + 0.55, rz), Vector3(0.14, 1.1, 0.14))

	# Upper and lower travelling hoist trolleys + machinery house + maintenance jib reaching y_peak.
	var t_x := -14.0 if is_main else 18.0
	var house_h := y_peak - y_top
	lm.box("White", Vector3(t_x, y_top + house_h * 0.42, zc), Vector3(11.5, house_h * 0.84, girder_w + 1.8))
	lm.box("Blue", Vector3(t_x, y_top + house_h * 0.86, zc), Vector3(12.2, 0.65, girder_w + 2.2))
	# Slewing maintenance jib mast on trolley roof up to exact y_peak (105.0 m on 1200 t crane).
	lm.frustum("DarkSteel", Vector3(t_x + 3.8, y_top + house_h * 0.84, zc), 0.45, 0.35,
		maxf(0.4, y_peak - (y_top + house_h * 0.84)), 10)
	lm.box("Beacon", Vector3(t_x + 3.8, y_peak - 0.25, zc), Vector3(0.65, 0.50, 0.65))
	# Tip aviation beacons on both cantilevered bridge ends.
	for sx: float in [-1.0, 1.0]:
		lm.box("Beacon", Vector3((bridge_half - 1.2) * sx, y_top + 1.35, zc), Vector3(0.55, 0.55, 0.55))

	# Lower underslung trolley, glazed operator's cab with night light, wire ropes, and spreader beam.
	var low_t_x := 16.0 if is_main else -12.0
	lm.box("Blue", Vector3(low_t_x, y_bot - 1.6, zc), Vector3(12.0, 2.4, girder_w + 2.6))
	var cab_x := low_t_x + 7.2
	lm.box("White", Vector3(cab_x, y_bot - 2.2, zc + 2.4), Vector3(3.2, 2.2, 2.4))
	lm.box("Glass", Vector3(cab_x, y_bot - 2.3, zc + 3.55), Vector3(2.8, 1.6, 0.25))
	lm.box("Lamp", Vector3(cab_x, y_bot - 2.3, zc + 3.1), Vector3(2.2, 1.2, 0.5))
	# Under-girder floodlight housings along the bridge soffit.
	for fx: float in [-42.0, 0.0, 42.0]:
		lm.box("Lamp", Vector3(fx, y_bot - 0.15, zc), Vector3(2.8, 0.24, 1.2))
	# Wire-rope hoist cables and suspended heavy shipyard spreader beam / hook block.
	for cx_off: float in [-4.5, 4.5]:
		for cz_off: float in [-1.6, 1.6]:
			lm.beam("Cable", Vector3(low_t_x + cx_off, y_bot - 2.4, zc + cz_off),
				Vector3(low_t_x + cx_off, hook_y + 1.8, zc + cz_off), 0.10, 0.10)
	lm.box("Blue", Vector3(low_t_x, hook_y + 1.0, zc), Vector3(11.5, 1.6, 4.2))
	lm.box("DarkSteel", Vector3(low_t_x, hook_y - 0.4, zc), Vector3(3.0, 1.4, 2.2))

static func _set_night_lights(model: Node3D) -> void:
	model.set_meta(LandmarkLights.HALO_META, [
		# 1200 t crane (z = -52) top & bridge-end ICAO red aviation beacons
		[Vector3(-10.2, TOP_M, -52.0), 1.8, Color(1.0, 0.08, 0.04)],
		[Vector3(-85.3, 101.85, -52.0), 1.8, Color(1.0, 0.08, 0.04)],
		[Vector3(85.3, 101.85, -52.0), 1.8, Color(1.0, 0.08, 0.04)],
		# 600 t crane (z = +58) top & bridge-end ICAO red aviation beacons
		[Vector3(21.8, 97.5, 58.0), 1.8, Color(1.0, 0.08, 0.04)],
		[Vector3(-83.3, 94.35, 58.0), 1.8, Color(1.0, 0.08, 0.04)],
		[Vector3(83.3, 94.35, 58.0), 1.8, Color(1.0, 0.08, 0.04)],
	])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 91.0, -52.0), Vector3(0.0, 20.0, -50.0), 68.0, 0.85, 110.0, Color(1.0, 0.90, 0.72)],
		[Vector3(0.0, 84.5, 58.0), Vector3(0.0, 20.0, 56.0), 68.0, 0.85, 105.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-42.0, 4.0, -10.0), Vector3(-55.0, 86.0, -52.0), 58.0, 0.75, 115.0, Color(0.92, 0.95, 1.0)],
		[Vector3(42.0, 4.0, 15.0), Vector3(55.0, 80.0, 58.0), 58.0, 0.75, 115.0, Color(0.92, 0.95, 1.0)],
	])
