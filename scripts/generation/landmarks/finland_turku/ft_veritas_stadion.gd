class_name FtVeritasStadion
extends RefCounted

## Veritas Stadion (Kupittaan jalkapallostadion, Kupittaanpuisto, Turku)
## in true metres (origin at pitch centre 60.442760, 22.291880; +X ENE along
## touchline, +Z SSE toward Olympic Tribune, -Z NNW toward 2003 Main Stand;
## turned onto the map by registry yaw_deg = 26.4°):
##   - Striped FIFA grass football pitch (105 x 68 m + run-off apron), crisp
##     white pitch lines, penalty boxes, centre circle, corner flags & goals.
##   - 2003 Main Stand (Pääkatsomo, turku_lod2 103454419A: area 4,204 m²,
##     H = 18.4 m, skillion 7°) along -Z: 2-tier tiered seating bowl, glazed
##     hospitality & VIP concourse back facade, cantilevered white steel truss
##     roof with tension mast pylons & under-roof LED light rail.
##   - 1952 Olympic Tribune (Olympiakatsomo, Erik Bryggman, turku_lod2
##     1034544189: area 2,622 m², H = 11.8 m, gabled 17°) along +Z: protected
##     white functionalist grandstand with tiered wooden/blue seating, slender
##     columns, and low-pitched gabled roof overhanging the terrace.
##   - 2009 West End Stand (turku_lod2 103454420B: H = 9.9 m) & 2023 East End
##     Stand (turku_lod2 104013826P: H = 10.1 m) enclosing both goal ends with
##     covered seating tiers & digital stadium scoreboard.
##   - Four 32 m corner steel lattice floodlight masts with angled lamp banks
##     (`FLOOD_META` + `HALO_META`) illuminating the pitch at night.
## Surfaces: 12 merged PBR parts (Pitch, PitchStripe, WhiteLine, Concrete,
## WhiteWall, SteelDark, SeatBlue, RoofMetal, Glass, Screen, Lamp).

const FOUND := -1.8
const GROUND_Y := 0.18
const PITCH_HL := 52.5
const PITCH_HW := 34.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_pitch(lm)
	_build_main_stand_2003(lm)
	_build_olympic_tribune_1952(lm)
	_build_end_stands(lm)
	_build_floodlight_masts(lm)
	lm.commit(model)
	_set_night_lights(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Pitch", LandmarkMaterials.pbr("lawn", "#3E7A2C", 6.0))
	lm.use("PitchStripe", LandmarkMaterials.pbr("lawn", "#4E8E36", 6.0))
	lm.use("WhiteLine", LandmarkMaterials.paint("#F4F4EE", 0.55, 0.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8BCC0", 3.0))
	lm.use("WhiteWall", LandmarkMaterials.pbr("render", "#ECEAE2", 3.0))
	lm.use("SteelDark", LandmarkMaterials.paint("#323840", 0.42, 0.62))
	lm.use("SeatBlue", LandmarkMaterials.paint("#1E5CA8", 0.48, 0.08))
	lm.use("RoofMetal", LandmarkMaterials.pbr("sheet_metal", "#D6DBE0", 2.8, 0.40, 0.25))
	lm.use("Glass", LandmarkMaterials.glass("#223848"))
	lm.use("Screen", LandmarkMaterials.paint("#141920", 0.25, 0.15))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF8E8", 2.4))

static func _build_pitch(lm: LandmarkMesh) -> void:
	# Stadium ground apron & run-off surround.
	LandmarkFrKit.rect(lm, "Concrete", -76.0, 76.0, -54.0, 54.0, FOUND, GROUND_Y - 0.02)
	# Alternating mown natural grass stripes (105 x 68 m pitch + 3.5 m grass apron).
	for i in 14:
		var x0 := lerpf(-(PITCH_HL + 3.5), PITCH_HL + 3.5, float(i) / 14.0)
		var x1 := lerpf(-(PITCH_HL + 3.5), PITCH_HL + 3.5, float(i + 1) / 14.0)
		var mat := "Pitch" if i % 2 == 0 else "PitchStripe"
		LandmarkFrKit.rect(lm, mat, x0, x1, -(PITCH_HW + 3.0), PITCH_HW + 3.0, 0.0, GROUND_Y)
	# Crisp white FIFA pitch markings (touchlines, goal lines, halfway, penalty boxes, centre circle).
	var ly0 := GROUND_Y
	var ly1 := GROUND_Y + 0.025
	LandmarkFrKit.rect(lm, "WhiteLine", -PITCH_HL, PITCH_HL, -PITCH_HW - 0.08, -PITCH_HW + 0.08, ly0, ly1)
	LandmarkFrKit.rect(lm, "WhiteLine", -PITCH_HL, PITCH_HL, PITCH_HW - 0.08, PITCH_HW + 0.08, ly0, ly1)
	LandmarkFrKit.rect(lm, "WhiteLine", -PITCH_HL - 0.08, -PITCH_HL + 0.08, -PITCH_HW, PITCH_HW, ly0, ly1)
	LandmarkFrKit.rect(lm, "WhiteLine", PITCH_HL - 0.08, PITCH_HL + 0.08, -PITCH_HW, PITCH_HW, ly0, ly1)
	LandmarkFrKit.rect(lm, "WhiteLine", -0.08, 0.08, -PITCH_HW, PITCH_HW, ly0, ly1)
	for i in 32:
		var a0 := TAU * float(i) / 32.0
		var a1 := TAU * float(i + 1) / 32.0
		lm.beam("WhiteLine", Vector3(cos(a0) * 9.15, ly1, sin(a0) * 9.15),
			Vector3(cos(a1) * 9.15, ly1, sin(a1) * 9.15), 0.02, 0.16, Vector3.UP)
	# Penalty areas, 6-yard boxes & white football goal frames at both ends.
	for sx: float in [-1.0, 1.0]:
		var gx := sx * PITCH_HL
		var px := sx * (PITCH_HL - 16.5)
		var bx := sx * (PITCH_HL - 5.5)
		LandmarkFrKit.rect(lm, "WhiteLine", minf(gx, px), maxf(gx, px), -20.24, -20.08, ly0, ly1)
		LandmarkFrKit.rect(lm, "WhiteLine", minf(gx, px), maxf(gx, px), 20.08, 20.24, ly0, ly1)
		LandmarkFrKit.rect(lm, "WhiteLine", px - 0.08, px + 0.08, -20.16, 20.16, ly0, ly1)
		LandmarkFrKit.rect(lm, "WhiteLine", minf(gx, bx), maxf(gx, bx), -9.24, -9.08, ly0, ly1)
		LandmarkFrKit.rect(lm, "WhiteLine", minf(gx, bx), maxf(gx, bx), 9.08, 9.24, ly0, ly1)
		LandmarkFrKit.rect(lm, "WhiteLine", bx - 0.08, bx + 0.08, -9.16, 9.16, ly0, ly1)
		# Goalposts & crossbar (7.32 m wide x 2.44 m high).
		lm.frustum("WhiteLine", Vector3(gx, GROUND_Y, -3.66), 0.07, 0.07, 2.44, 6)
		lm.frustum("WhiteLine", Vector3(gx, GROUND_Y, 3.66), 0.07, 0.07, 2.44, 6)
		lm.beam("WhiteLine", Vector3(gx, GROUND_Y + 2.44, -3.66), Vector3(gx, GROUND_Y + 2.44, 3.66), 0.14, 0.14)
		# Rear net stanchions.
		lm.beam("SteelDark", Vector3(gx, GROUND_Y + 2.44, -3.66), Vector3(gx + sx * 2.0, GROUND_Y, -3.66), 0.06, 0.06)
		lm.beam("SteelDark", Vector3(gx, GROUND_Y + 2.44, 3.66), Vector3(gx + sx * 2.0, GROUND_Y, 3.66), 0.06, 0.06)

static func _build_main_stand_2003(lm: LandmarkMesh) -> void:
	# 2003 2-tier Glass-Backed Main Stand (Pääkatsomo) along -Z (x = -54..+54, z = -39..-58, H = 18.4 m).
	LandmarkFrKit.rect(lm, "Concrete", -54.0, 54.0, -58.5, -39.5, FOUND, 1.4)
	# Rear 3-storey glazed VIP/hospitality & concourse back facade (z = -58..-51, y = 1.4..14.6 m).
	LandmarkFrKit.rect(lm, "Glass", -53.0, 53.0, -58.0, -51.5, 1.4, 14.6)
	lm.box("Lamp", Vector3(0.0, 8.0, -54.8), Vector3(96.0, 10.0, 3.2))
	for i in 15:
		var mx := lerpf(-52.5, 52.5, float(i) / 14.0)
		lm.box("SteelDark", Vector3(mx, 8.0, -58.15), Vector3(0.28, 13.2, 0.28))
	# Two-tier concrete & blue-seat terraced seating bowl stepping up toward -Z.
	for step in 12:
		var t := float(step) / 11.0
		var z0 := lerpf(-40.0, -52.0, t)
		var y_top := 1.4 + float(step) * 0.85
		LandmarkFrKit.rect(lm, "Concrete", -53.0, 53.0, z0 - 1.05, z0, 1.2, y_top)
		LandmarkFrKit.rect(lm, "SeatBlue", -52.2, 52.2, z0 - 0.85, z0 - 0.15, y_top, y_top + 0.35)
	# Glass VIP commentary box band mid-stand.
	LandmarkFrKit.rect(lm, "Glass", -38.0, 38.0, -53.0, -50.8, 11.6, 14.4)
	# Cantilevered sloped steel-truss roof (skillion 7°: rear 15.6 m -> front overhang 18.4 m).
	LandmarkFrKit.face(lm, "RoofMetal", [
		Vector3(-55.0, 15.6, -59.0), Vector3(55.0, 15.6, -59.0),
		Vector3(55.0, 18.4, -37.5), Vector3(-55.0, 18.4, -37.5),
	])
	LandmarkFrKit.face(lm, "SteelDark", [
		Vector3(-55.0, 15.1, -59.0), Vector3(-55.0, 17.9, -37.5),
		Vector3(55.0, 17.9, -37.5), Vector3(55.0, 15.1, -59.0),
	])
	# Exposed white steel cantilevered roof trusses & rear support pylons.
	for i in 11:
		var tx := lerpf(-52.0, 52.0, float(i) / 10.0)
		lm.beam("SteelDark", Vector3(tx, 15.4, -58.5), Vector3(tx, 18.2, -37.8), 0.32, 0.55)
		lm.frustum("SteelDark", Vector3(tx, 1.4, -57.6), 0.28, 0.28, 14.4, 8)
	# Under-roof LED floodlight bar along Main Stand front edge.
	lm.box("Lamp", Vector3(0.0, 17.7, -38.4), Vector3(92.0, 0.25, 0.35))

static func _build_olympic_tribune_1952(lm: LandmarkMesh) -> void:
	# 1952 Functionalist Olympic Tribune (Olympiakatsomo, Erik Bryggman) along +Z (H = 11.8 m).
	LandmarkFrKit.rect(lm, "WhiteWall", -48.0, 48.0, 39.5, 53.5, FOUND, 2.2)
	# Rear white functionalist facade & ribbon clerestory along +Z.
	LandmarkFrKit.rect(lm, "WhiteWall", -48.0, 48.0, 51.5, 53.5, 2.2, 9.2)
	LandmarkFrKit.rect(lm, "Glass", -45.0, 45.0, 53.4, 53.65, 5.2, 7.6)
	# Tiered Olympic seating deck stepping up toward +Z.
	for step in 8:
		var t := float(step) / 7.0
		var z0 := lerpf(40.2, 50.8, t)
		var y_top := 1.4 + float(step) * 0.72
		LandmarkFrKit.rect(lm, "Concrete", -47.0, 47.0, z0, z0 + 1.35, 1.2, y_top)
		LandmarkFrKit.rect(lm, "SeatBlue", -46.2, 46.2, z0 + 0.15, z0 + 1.0, y_top, y_top + 0.32)
	# Slender white functionalist roof columns & low-pitched gabled roof (9.0 -> 11.8 m).
	for i in 11:
		var cx := lerpf(-46.0, 46.0, float(i) / 10.0)
		lm.frustum("WhiteWall", Vector3(cx, 2.2, 42.5), 0.22, 0.22, 6.8, 8)
	LandmarkFrKit.gable(lm, "RoofMetal", -49.0, 49.0, 38.5, 54.0, 9.0, 2.8, 0.5, "WhiteWall", 1)

static func _build_end_stands(lm: LandmarkMesh) -> void:
	# 2009 West End Stand (-X) & 2023 East End Stand (+X) enclosing both goals (H = 10.1 m).
	for sx: float in [-1.0, 1.0]:
		var x_in := sx * 59.0
		var x_out := sx * 71.5
		LandmarkFrKit.rect(lm, "Concrete", minf(x_in, x_out), maxf(x_in, x_out), -32.0, 32.0, FOUND, 1.4)
		for step in 7:
			var t := float(step) / 6.0
			var xs := lerpf(x_in + sx * 0.6, x_out - sx * 1.4, t)
			var y_top := 1.4 + float(step) * 0.72
			LandmarkFrKit.rect(lm, "Concrete", minf(xs, xs + sx * 1.3), maxf(xs, xs + sx * 1.3),
				-31.0, 31.0, 1.2, y_top)
			LandmarkFrKit.rect(lm, "SeatBlue", minf(xs + sx * 0.2, xs + sx * 1.0),
				maxf(xs + sx * 0.2, xs + sx * 1.0), -30.2, 30.2, y_top, y_top + 0.32)
		# Back wind wall & skillion steel canopy roof (y = 8.4..10.1 m).
		LandmarkFrKit.rect(lm, "WhiteWall", x_out - sx * 0.6, x_out, -32.0, 32.0, 1.4, 8.6)
		LandmarkFrKit.face(lm, "RoofMetal", [
			Vector3(x_out, 8.6, -32.5), Vector3(x_out, 8.6, 32.5),
			Vector3(x_in - sx * 1.2, 10.1, 32.5), Vector3(x_in - sx * 1.2, 10.1, -32.5),
		])
		for i in 7:
			var cz := lerpf(-30.0, 30.0, float(i) / 6.0)
			lm.frustum("SteelDark", Vector3(x_out - sx * 0.8, 1.4, cz), 0.22, 0.22, 7.2, 8)
	# Digital stadium LED scoreboard in the NE corner.
	LandmarkFrKit.rect(lm, "SteelDark", 56.0, 58.0, -37.0, -35.0, FOUND, 10.5)
	LandmarkFrKit.rect(lm, "Screen", 54.0, 59.0, -38.5, -33.5, 6.2, 10.2)

static func _build_floodlight_masts(lm: LandmarkMesh) -> void:
	# Four 32 m corner steel floodlight masts with angled luminaire headframes.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var mx := sx * 64.0
			var mz := sz * 46.0
			lm.frustum("SteelDark", Vector3(mx, FOUND, mz), 0.72, 0.34, 30.2 - FOUND, 8)
			# Angled floodlight luminaire headframe facing pitch centre.
			var ang := atan2(-mz, -mx)
			var rot := Basis(Vector3.UP, -ang)
			lm.box("SteelDark", Vector3(mx, 31.0, mz), Vector3(0.65, 3.2, 5.4), rot)
			lm.box("Lamp", Vector3(mx - sx * 0.35, 31.0, mz - sz * 0.25), Vector3(0.28, 2.8, 4.8), rot)

static func _set_night_lights(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-64.0, 31.0, -46.0), Vector3(-18.0, 0.2, -10.0), 68.0, 0.95, 110.0, Color(0.95, 0.98, 1.0)],
		[Vector3(64.0, 31.0, -46.0), Vector3(18.0, 0.2, -10.0), 68.0, 0.95, 110.0, Color(0.95, 0.98, 1.0)],
		[Vector3(-64.0, 31.0, 46.0), Vector3(-18.0, 0.2, 10.0), 68.0, 0.95, 110.0, Color(0.95, 0.98, 1.0)],
		[Vector3(64.0, 31.0, 46.0), Vector3(18.0, 0.2, 10.0), 68.0, 0.95, 110.0, Color(0.95, 0.98, 1.0)],
	])
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(-64.0, 31.0, -46.0), 4.2, Color(0.96, 0.98, 1.0)],
		[Vector3(64.0, 31.0, -46.0), 4.2, Color(0.96, 0.98, 1.0)],
		[Vector3(-64.0, 31.0, 46.0), 4.2, Color(0.96, 0.98, 1.0)],
		[Vector3(64.0, 31.0, 46.0), 4.2, Color(0.96, 0.98, 1.0)],
	])
