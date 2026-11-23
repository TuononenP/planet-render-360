class_name LandmarkMiHardRockStadium
extends RefCounted

## Hard Rock Stadium — Miami Gardens (MI-10)
## Site: 347 Don Shula Dr (25.957960, -80.238860, yaw_deg 0.0, skyline_priority 1).
## Architects: HOK / Populous (1987; canopy & spire reconstruction 2015–2016).
## Measured envelope & materials (Commons aerial/front/quarter, 275 x 235 m, spires 357 ft = 109.0 m):
##   - Rectangular open-air stadium footprint (275 x 235 m): green NFL turf pitch (110 x 49 m) with
##     Miami Dolphins aqua endzones, yard markings & yellow goalposts.
##   - Multi-tier aqua seating bowl (y = 1.2..40.5 m), suite glass ribbons & 4 corner HD video boards.
##   - Panelled modern exterior concourse screen + 4 iconic corner white cylindrical spiral ramp drums.
##   - Open-air white steel & ETFE/PTFE rectangular canopy roof (246 x 206 m at y = 44.5..51.8 m)
##     framing a 132 x 86 m rectangular sky oculus over the turf.
##   - Four soaring 109.0 m white steel corner spires with radial cable-stay fans suspending the
##     canopy + red ICAO aviation warning beacons (HALO_META at exact y = 109.0 m).

const HEIGHT_M := 109.0
const SPIRE_X := 96.0
const SPIRE_Z := 78.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhiteCanopy", LandmarkMaterials.pbr("render", "#F4F5F7", 6.0))
	lm.use("WhiteSteel", LandmarkMaterials.paint("#EAECEF", 0.36, 0.45))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C2C0BA", 4.5))
	lm.use("FacadePanel", LandmarkMaterials.pbr("sheet_metal", "#CFD5DC", 4.0, 0.46, 0.25))
	lm.use("PitchDark", LandmarkMaterials.pbr("lawn", "#2D6D27", 6.0))
	lm.use("PitchLight", LandmarkMaterials.pbr("lawn", "#3C8333", 6.0))
	lm.use("SeatAqua", LandmarkMaterials.paint("#008E97", 0.50, 0.08))
	lm.use("WhiteLine", LandmarkMaterials.paint("#F5F5F0", 0.52, 0.0))
	lm.use("Glass", LandmarkMaterials.glass("#223846"))
	lm.use("LedScreen", LandmarkMaterials.lit("#48B4FF", 0.85))
	lm.use("BeaconLamp", LandmarkMaterials.lit("#FF2618", 2.8))

	_build_plaza_and_nfl_pitch(lm)
	_build_seating_bowl_and_screens(lm)
	_build_exterior_and_spiral_ramps(lm)
	_build_canopy_with_oculus(lm)
	_build_four_spires_and_stays(lm)
	lm.commit(model)

	var halos: Array = []
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			halos.append([Vector3(sx * SPIRE_X, HEIGHT_M, sz * SPIRE_Z), 4.6, Color(1.0, 0.14, 0.08)])
	model.set_meta(LandmarkLights.HALO_META, halos)

	var stadium_white := Color(0.95, 0.97, 1.0)
	var aqua_glow := Color(0.20, 0.86, 0.92)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-60.0, 44.0, -40.0), Vector3(0.0, 1.5, 0.0), 72.0, 1.35, 95.0, stadium_white],
		[Vector3(60.0, 44.0, 40.0), Vector3(0.0, 1.5, 0.0), 72.0, 1.35, 95.0, stadium_white],
		[Vector3(-135.0, 4.0, 0.0), Vector3(-108.0, 32.0, 0.0), 62.0, 1.00, 75.0, aqua_glow],
		[Vector3(135.0, 4.0, 0.0), Vector3(108.0, 32.0, 0.0), 62.0, 1.00, 75.0, aqua_glow],
		[Vector3(0.0, 4.0, -116.0), Vector3(0.0, 32.0, -90.0), 62.0, 1.00, 75.0, aqua_glow],
		[Vector3(0.0, 4.0, 116.0), Vector3(0.0, 32.0, 90.0), 62.0, 1.00, 75.0, aqua_glow],
	])

static func _build_plaza_and_nfl_pitch(lm: LandmarkMesh) -> void:
	# Stadium concourse podium filling 272 x 232 m footprint (y = -0.40..1.20 m)
	lm.poly_prism("Concrete", _oct_rect(136.0, 116.0, 18.0), -0.40, 1.20)
	lm.box("Concrete", Vector3(0.0, 1.22, 0.0), Vector3(144.0, 0.08, 86.0), Basis(), 0.0)

	# NFL playing field (109.7 x 48.8 m + aqua endzones, y = 1.26 m)
	for s: int in 10:
		var x0 := lerpf(-45.7, 45.7, float(s) / 10.0)
		var x1 := lerpf(-45.7, 45.7, float(s + 1) / 10.0)
		var pkey := "PitchDark" if (s % 2 == 0) else "PitchLight"
		lm.box(pkey, Vector3((x0 + x1) * 0.5, 1.26, 0.0), Vector3(x1 - x0, 0.08, 48.8), Basis(), 0.0)
	# Dolphins Aqua Endzones (x = -54.8..-45.7 and +45.7..+54.8)
	for sx: float in [-1.0, 1.0]:
		lm.box("SeatAqua", Vector3(sx * 50.25, 1.26, 0.0), Vector3(9.1, 0.08, 48.8), Basis(), 0.0)
		# NFL slingshot goalposts at back of endzones
		var gx := sx * 54.9
		lm.frustum("WhiteLine", Vector3(gx + sx * 1.4, 1.28, 0.0), 0.14, 0.12, 3.05, 8)
		lm.beam("WhiteLine", Vector3(gx + sx * 1.4, 3.05, 0.0), Vector3(gx, 3.05, 0.0), 0.16, 0.16)
		lm.beam("WhiteLine", Vector3(gx, 3.05, -2.82), Vector3(gx, 3.05, 2.82), 0.16, 0.16)
		for sz: float in [-1.0, 1.0]:
			lm.frustum("WhiteLine", Vector3(gx, 3.05, sz * 2.82), 0.09, 0.08, 7.6, 6)

	# Crisp white NFL sidelines, goal lines & 10-yard lines
	var ly := 1.31
	for sz: float in [-1.0, 1.0]:
		lm.box("WhiteLine", Vector3(0.0, ly, sz * 24.4), Vector3(110.2, 0.04, 0.45), Basis(), 0.0)
	for k: int in 11:
		var yx := -45.7 + float(k) * 9.14
		lm.box("WhiteLine", Vector3(yx, ly, 0.0), Vector3(0.28, 0.04, 48.8), Basis(), 0.0)
	for sx: float in [-1.0, 1.0]:
		lm.box("WhiteLine", Vector3(sx * 54.8, ly, 0.0), Vector3(0.36, 0.04, 48.8), Basis(), 0.0)

static func _build_seating_bowl_and_screens(lm: LandmarkMesh) -> void:
	# Rectangular 3-deck stadium bowl (Lower Bowl y = 1.5..16.5 m, Club Glass y = 16.5..22.5 m,
	# Upper Deck y = 22.5..40.5 m) around inner pit 136 x 78 m out to 224 x 180 m
	var steps := 10
	for i: int in steps:
		var t := float(i) / float(steps - 1)
		var y := lerpf(2.2, 16.2, t)
		var hx := lerpf(69.0, 88.0, t)
		var hz := lerpf(40.0, 59.0, t)
		_bowl_ring(lm, "SeatAqua", hx, hz, 2.2, y, 1.55)

	# Mid-level luxury suite glazing & glowing LED ribbon fascia
	_bowl_ring(lm, "Glass", 90.0, 61.0, 3.2, 19.5, 5.4)
	_bowl_ring(lm, "LedScreen", 88.2, 59.2, 0.5, 22.4, 0.9)

	for i: int in steps:
		var t := float(i) / float(steps - 1)
		var y := lerpf(23.5, 40.2, t)
		var hx := lerpf(91.0, 112.0, t)
		var hz := lerpf(62.0, 86.0, t)
		_bowl_ring(lm, "SeatAqua", hx, hz, 2.5, y, 1.85)

	# Four massive corner HD stadium scoreboards angled toward pitch centre (seen in aerial.jpg!)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var sc := Vector3(sx * 76.0, 36.5, sz * 52.0)
			var n3 := Vector3(-sx, 0.0, -sz).normalized()
			var t3 := Vector3(-n3.z, 0.0, n3.x)
			var sb := Basis(t3, Vector3.UP, n3)
			lm.box("FacadePanel", sc - n3 * 0.6, Vector3(24.0, 11.2, 1.2), sb)
			lm.box("LedScreen", sc + n3 * 0.08, Vector3(22.4, 9.6, 0.25), sb, 0.0)

static func _bowl_ring(lm: LandmarkMesh, key: String, hx: float, hz: float, thick: float,
		yc: float, h: float) -> void:
	for sz: float in [-1.0, 1.0]:
		lm.box(key, Vector3(0.0, yc, sz * hz), Vector3((hx - 8.0) * 2.0, h, thick), Basis(), 0.0)
	for sx: float in [-1.0, 1.0]:
		lm.box(key, Vector3(sx * hx, yc, 0.0), Vector3(thick, h, (hz - 8.0) * 2.0), Basis(), 0.0)
	# Chamfered corner seating wedges
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := Vector3(sx * (hx - 4.5), yc, sz * (hz - 4.5))
			var b := Basis(Vector3.UP, sx * sz * PI * 0.25)
			lm.box(key, c, Vector3(13.5, h, thick), b, 0.0)

static func _build_exterior_and_spiral_ramps(lm: LandmarkMesh) -> void:
	# Panelled concourse screen & diagrid steel struts along the 4 stadium sides (y = 1.2..38.0 m)
	for sz: float in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(0.0, 9.5, sz * 94.0), Vector3(172.0, 16.5, 4.0))
		lm.box("FacadePanel", Vector3(0.0, 26.5, sz * 95.5), Vector3(176.0, 18.0, 2.2))
		lm.box("SeatAqua", Vector3(0.0, 18.2, sz * 96.8), Vector3(64.0, 2.6, 0.8))
	for sx: float in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(sx * 116.0, 9.5, 0.0), Vector3(4.0, 16.5, 132.0))
		lm.box("FacadePanel", Vector3(sx * 117.5, 26.5, 0.0), Vector3(2.2, 18.0, 136.0))
		lm.box("SeatAqua", Vector3(sx * 118.8, 18.2, 0.0), Vector3(0.8, 2.6, 52.0))

	# Four signature white corner cylindrical pedestrian spiral ramp helices (r = 16.0 m, y = 1.2..36.5 m)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var rc := Vector3(sx * 114.0, 1.2, sz * 94.0)
			lm.frustum("Concrete", rc, 9.5, 9.5, 35.0, 16)
			for col: int in 8:
				var ca := TAU * float(col) / 8.0
				lm.frustum("WhiteSteel", rc + Vector3(cos(ca) * 14.8, 0.0, sin(ca) * 14.8), 0.45, 0.42, 35.8, 8)
			# 3-turn white helical concrete ramp ribbon wrapping the drum
			var turns := 36
			for s: int in turns:
				var t0 := float(s) / float(turns)
				var t1 := float(s + 1) / float(turns)
				var a0 := t0 * TAU * 3.0
				var a1 := t1 * TAU * 3.0
				var p0 := rc + Vector3(cos(a0) * 13.8, t0 * 33.8, sin(a0) * 13.8)
				var p1 := rc + Vector3(cos(a1) * 13.8, t1 * 33.8, sin(a1) * 13.8)
				var rad_out := Vector3(cos((a0 + a1) * 0.5), 0.0, sin((a0 + a1) * 0.5))
				lm.beam("WhiteCanopy", p0, p1, 4.2, 0.95, rad_out)

static func _build_canopy_with_oculus(lm: LandmarkMesh) -> void:
	# Open-air white rectangular canopy (248 x 208 m outer, 132 x 86 m inner sky oculus, y = 44.5..49.8 m)
	# North & South long-side canopy wings (z = +-43.0..+-104.0 m)
	for sz: float in [-1.0, 1.0]:
		var rows: Array = []
		var row_in := PackedVector3Array([
			Vector3(-66.0, 44.6, sz * 43.0), Vector3(0.0, 44.6, sz * 43.0), Vector3(66.0, 44.6, sz * 43.0)])
		var row_mid := PackedVector3Array([
			Vector3(-95.0, 48.8, sz * 74.0), Vector3(0.0, 49.4, sz * 74.0), Vector3(95.0, 48.8, sz * 74.0)])
		var row_out := PackedVector3Array([
			Vector3(-124.0, 46.8, sz * 104.0), Vector3(0.0, 47.2, sz * 104.0), Vector3(124.0, 46.8, sz * 104.0)])
		if sz > 0.0:
			rows = [row_in, row_mid, row_out]
		else:
			rows = [row_out, row_mid, row_in]
		lm.grid("WhiteCanopy", rows, Vector3.UP)
		lm.box("WhiteSteel", Vector3(0.0, 46.8, sz * 104.0), Vector3(248.0, 1.35, 1.8))
		lm.box("WhiteSteel", Vector3(0.0, 44.8, sz * 43.0), Vector3(132.0, 1.25, 1.6))

	# East & West end-zone canopy wings (x = +-66.0..+-124.0 m)
	for sx: float in [-1.0, 1.0]:
		var rows: Array = []
		var col_in := PackedVector3Array([
			Vector3(sx * 66.0, 44.6, -43.0), Vector3(sx * 66.0, 44.6, 0.0), Vector3(sx * 66.0, 44.6, 43.0)])
		var col_mid := PackedVector3Array([
			Vector3(sx * 95.0, 48.8, -74.0), Vector3(sx * 95.0, 49.2, 0.0), Vector3(sx * 95.0, 48.8, 74.0)])
		var col_out := PackedVector3Array([
			Vector3(sx * 124.0, 46.8, -104.0), Vector3(sx * 124.0, 47.2, 0.0), Vector3(sx * 124.0, 46.8, 104.0)])
		if sx > 0.0:
			rows = [col_in, col_mid, col_out]
		else:
			rows = [col_out, col_mid, col_in]
		lm.grid("WhiteCanopy", rows, Vector3.UP)
		lm.box("WhiteSteel", Vector3(sx * 124.0, 46.8, 0.0), Vector3(1.8, 1.35, 208.0))
		lm.box("WhiteSteel", Vector3(sx * 66.0, 44.8, 0.0), Vector3(1.6, 1.25, 86.0))

	# Primary rooftop white steel box-truss girders spanning between spires & oculus corners (y = 49.0..52.0 m)
	for sz: float in [-1.0, 1.0]:
		lm.beam("WhiteSteel", Vector3(-SPIRE_X, 50.8, sz * SPIRE_Z), Vector3(SPIRE_X, 50.8, sz * SPIRE_Z), 2.2, 2.6)
	for sx: float in [-1.0, 1.0]:
		lm.beam("WhiteSteel", Vector3(sx * SPIRE_X, 50.8, -SPIRE_Z), Vector3(sx * SPIRE_X, 50.8, SPIRE_Z), 2.2, 2.6)

static func _build_four_spires_and_stays(lm: LandmarkMesh) -> void:
	# Four soaring 109.0 m tapered white steel corner masts + radial stay-cable fans & corner backstays
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var sx_p := sx * SPIRE_X
			var sz_p := sz * SPIRE_Z
			# Massive corner concrete pier base (y = 0..46 m) + tapered white steel spire to y = 109.0 m
			lm.frustum("Concrete", Vector3(sx_p, 0.0, sz_p), 3.8, 3.0, 46.0, 12)
			lm.lathe("WhiteSteel", Vector3(sx_p, 45.5, sz_p), PackedVector2Array([
				Vector2(2.85, 0.0),
				Vector2(2.25, 18.0),
				Vector2(1.55, 38.0),
				Vector2(0.92, 54.0),
				Vector2(0.45, 62.6),
				Vector2(0.18, 63.1),
			]), 12)
			# Red aviation warning beacon finial at exact HEIGHT_M = 109.0 m (45.5 + 63.5 = 109.0)
			lm.frustum("BeaconLamp", Vector3(sx_p, 108.55, sz_p), 0.24, 0.10, 0.45, 8)

			# Radial cable-stay fan from spire anchor collars (y = 94 m & 102 m) to canopy trusses + backstays
			var top_a := Vector3(sx_p, 102.0, sz_p)
			var mid_a := Vector3(sx_p, 93.5, sz_p)
			var deck_targets: Array[Vector3] = [
				Vector3(sx * 66.0, 45.4, sz * 43.0),
				Vector3(sx * 24.0, 50.8, sz * SPIRE_Z),
				Vector3(sx * 58.0, 50.8, sz * SPIRE_Z),
				Vector3(sx * SPIRE_X, 50.8, sz * 18.0),
				Vector3(sx * SPIRE_X, 50.8, sz * 48.0),
				Vector3(sx * 66.0, 45.4, sz * 14.0),
			]
			for idx: int in deck_targets.size():
				var anchor := top_a if (idx % 2 == 0) else mid_a
				lm.beam("WhiteSteel", anchor, deck_targets[idx], 0.16, 0.16)
			# Twin exterior corner tie-down backstays anchored to outer corner buttress piers (seen in front.jpg!)
			var buttress := Vector3(sx * 128.0, 0.0, sz * 107.0)
			lm.box("Concrete", buttress + Vector3(0.0, 6.0, 0.0), Vector3(4.5, 12.0, 4.5))
			lm.beam("WhiteSteel", top_a, buttress + Vector3(0.0, 11.8, 0.0), 0.20, 0.20)
			lm.beam("WhiteSteel", mid_a, buttress + Vector3(-sx * 3.0, 11.8, -sz * 3.0), 0.18, 0.18)

static func _oct_rect(hx: float, hz: float, ch: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-hx + ch, -hz), Vector2(hx - ch, -hz),
		Vector2(hx, -hz + ch), Vector2(hx, hz - ch),
		Vector2(hx - ch, hz), Vector2(-hx + ch, hz),
		Vector2(-hx, hz - ch), Vector2(-hx, -hz + ch),
	])
