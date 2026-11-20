class_name FtFori
extends RefCounted

## Föri (1904, Ab Vulcan): Turku's beloved orange-and-white double-ended
## electric river ferry crossing Aurajoki between Tervatori and Läntinen
## Rantakatu in true metres (+X across Aurajoki from Läntinen Rantakatu -X
## to Tervatori +X, y = 0 at water level, yaw_deg = 54.5°, base = "water"):
##   - Moving `ForiVessel` (`ForiShuttle` Node3D): flared symmetrical double-
##     ended steel hull via HullLoft.loft (18.4 m x 6.6 m, 1.25 m freeboard,
##     0.65 m draft) in Föri bright orange, hinged steel boarding ramps at
##     both prows (±10.65 m), white bulwarks & slatted benches, 4 lifebuoys,
##     offset side operator cabin with wraparound glazing & orange canopy,
##     roof navigation mast (5.56 m) with warm lamps. Shuttles smoothly
##     between x = -26.85 m and +26.85 m (~90 s round trip, 11 s boarding
##     pauses), starting at x = 0.0 on frame 0 for deterministic captures.
##   - Stationary `ForiLandings` (`Node3D`): wooden & granite Förin laiturit
##     riverbank landing stages at x = ±37.5..±43.5 m (matching the ~75 m
##     Aurajoki crossing width so the ferry's ramps dock flush at each bank)
##     with driven timber pilings, mooring bollards, and warm quay lanterns.
## Surfaces: 10 merged PBR parts (6 on ForiVessel + 4 on ForiLandings).

const TRAVEL_HALF := 26.85
const LANDING_LIP_X := 37.5

const HULL_SPEC := {
	"length": 18.4,
	"beam": 6.6,
	"freeboard": 1.25,
	"draft": 0.65,
	"double_ended": true,
	"entry": 0.26,
	"end_width": 0.58,
	"bow_pow": 1.75,
	"flare": 0.16,
	"bow_rise": 0.20,
	"stern_rise": 0.20,
	"boot_m": 0.30,
	"lod": 0,
	"ultra": false,
}

static func build(model: Node3D) -> void:
	var vessel := ForiShuttle.new()
	vessel.name = "ForiVessel"
	vessel.travel_half_m = TRAVEL_HALF
	model.add_child(vessel)
	var vlm := LandmarkMesh.new()
	_vessel_materials(vlm)
	HullLoft.loft(vlm, HULL_SPEC, {"hull": "Orange", "boot": "Dark", "bottom": "Dark", "deck": "Deck"})
	_build_bulwarks_and_benches(vlm)
	_build_boarding_ramps(vlm)
	_build_operator_cabin_and_mast(vlm)
	vlm.commit(vessel)
	# Warm onboard deck & cabin night light moving with ForiVessel (off outside schedule).
	var deck_light := OmniLight3D.new()
	deck_light.name = "ForiDeckLight"
	deck_light.position = Vector3(0.0, 4.1, -0.4)
	deck_light.light_color = Color(1.0, 0.89, 0.68)
	deck_light.light_energy = 0.0
	deck_light.omni_range = 14.0 * WorldScale.metres_to_units()
	deck_light.shadow_enabled = false
	deck_light.visible = false
	vessel.add_child(deck_light)

	var landings := Node3D.new()
	landings.name = "ForiLandings"
	model.add_child(landings)
	var llm := LandmarkMesh.new()
	_landing_materials(llm)
	_build_landing_stages(llm)
	llm.commit(landings)

	_set_night_floods(model)

static func _vessel_materials(lm: LandmarkMesh) -> void:
	lm.use("Orange", LandmarkMaterials.paint("#E46414", 0.42, 0.14))
	lm.use("White", LandmarkMaterials.paint("#F3F0EA", 0.46, 0.08))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#6B7075", 2.0, 0.75))
	lm.use("Dark", LandmarkMaterials.paint("#262A2E", 0.48, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#24333C"))
	lm.use("ForiLamp", LandmarkMaterials.lit("#FFEAC0", 0.0))

static func _landing_materials(lm: LandmarkMesh) -> void:
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#7C5E42", 2.2, 0.76))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#827E78", 2.4))
	lm.use("Dark", LandmarkMaterials.paint("#262A2E", 0.48, 0.45))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEAC0", 1.6))

static func _build_bulwarks_and_benches(lm: LandmarkMesh) -> void:
	# White side bulwarks, stanchions, and top handrails along both flared sides.
	var n := 18
	for s: float in [-1.0, 1.0]:
		var prev_top := Vector3.ZERO
		for i in n + 1:
			var x := lerpf(-7.8, 7.8, float(i) / float(n))
			var hz := HullLoft.half(HULL_SPEC, x) - 0.12
			var sy := HullLoft.sheer(HULL_SPEC, x)
			var p_bot := Vector3(x, sy, hz * s)
			var p_top := Vector3(x, sy + 1.02, hz * s)
			if i % 2 == 0:
				lm.beam("White", p_bot, p_top, 0.07, 0.07)
			if i > 0:
				var px := lerpf(-7.8, 7.8, float(i - 1) / float(n))
				var p_prev_bot := Vector3(px, HullLoft.sheer(HULL_SPEC, px),
					(HullLoft.half(HULL_SPEC, px) - 0.12) * s)
				lm.quad("White", p_prev_bot, p_bot,
					Vector3(p_bot.x, p_bot.y + 0.56, p_bot.z),
					Vector3(p_prev_bot.x, p_prev_bot.y + 0.56, p_prev_bot.z), Vector3(0, 0, s))
				lm.quad("White", p_bot, p_prev_bot,
					Vector3(p_prev_bot.x, p_prev_bot.y + 0.56, p_prev_bot.z),
					Vector3(p_bot.x, p_bot.y + 0.56, p_bot.z), Vector3(0, 0, -s))
				lm.beam("White", prev_top, p_top, 0.075, 0.075)
			prev_top = p_top
		# White slatted passenger benches facing inward along port (+Z) and starboard (-Z) sides.
		var spans := [[-6.4, 6.4]] if s > 0.0 else [[-6.4, -2.6], [2.6, 6.4]]
		for sp: Array in spans:
			var x0: float = sp[0]
			var x1: float = sp[1]
			var bz := 2.62 if s > 0.0 else -2.62
			LandmarkFrKit.rect(lm, "White", x0, x1, bz - 0.24, bz + 0.24, 1.66, 1.74)
			LandmarkFrKit.rect(lm, "White", x0, x1, bz + s * 0.20 - 0.04, bz + s * 0.20 + 0.04, 1.74, 2.15)
			for lx: float in [x0 + 0.35, (x0 + x1) * 0.5, x1 - 0.35]:
				lm.box("Dark", Vector3(lx, 1.46, bz), Vector3(0.10, 0.42, 0.42))
		# Four bright orange-and-white lifebuoys mounted on the outer bulwarks.
		for bx: float in [-4.8, 4.8]:
			var hz := HullLoft.half(HULL_SPEC, bx) + 0.04
			var by := HullLoft.sheer(HULL_SPEC, bx) + 0.55
			lm.disc("Orange", Vector3(bx, by, hz * s), Vector3(0, 0, s), 0.34, 10)
			lm.disc("White", Vector3(bx, by, (hz + 0.02) * s), Vector3(0, 0, s), 0.18, 8)

static func _build_boarding_ramps(lm: LandmarkMesh) -> void:
	# Hinged steel boarding ramps & lifting chain stanchions at both symmetrical prows.
	for sx: float in [-1.0, 1.0]:
		var rx0 := sx * 9.05
		var rx1 := sx * 10.65
		var hinge := Vector3(rx0, 1.42, 0.0)
		var lip := Vector3(rx1, 1.56, 0.0)
		lm.beam("Deck", hinge, lip, 0.14, 3.35, Vector3.UP)
		lm.beam("Orange", hinge + Vector3(sx * 0.1, 0.08, -1.68), lip + Vector3(0, 0.08, -1.68), 0.12, 0.14)
		lm.beam("Orange", hinge + Vector3(sx * 0.1, 0.08, 1.68), lip + Vector3(0, 0.08, 1.68), 0.12, 0.14)
		for sz: float in [-1.72, 1.72]:
			var post_b := Vector3(sx * 8.55, 1.40, sz)
			var post_t := Vector3(sx * 8.55, 2.75, sz)
			lm.beam("White", post_b, post_t, 0.09, 0.09)
			lm.beam("Dark", post_t, Vector3(rx1 - sx * 0.15, 1.62, sz), 0.035, 0.035)

static func _build_operator_cabin_and_mast(lm: LandmarkMesh) -> void:
	# Offset side operator wheelhouse (-Z side) with wraparound glazing & orange canopy roof.
	LandmarkFrKit.rect(lm, "White", -2.2, 2.2, -2.95, -1.35, 1.25, 2.45)
	LandmarkFrKit.rect(lm, "Glass", -2.05, 2.05, -2.88, -1.42, 2.45, 3.65)
	for cx: float in [-2.12, 0.0, 2.12]:
		for cz: float in [-2.88, -1.42]:
			lm.box("White", Vector3(cx, 3.05, cz), Vector3(0.14, 1.25, 0.14))
	LandmarkFrKit.rect(lm, "Dark", -0.8, 0.8, -2.4, -1.7, 1.30, 2.25)
	LandmarkFrKit.rect(lm, "ForiLamp", -1.4, 1.4, -2.3, -1.9, 3.42, 3.62)
	LandmarkFrKit.rect(lm, "Orange", -2.65, 2.65, -3.15, -1.10, 3.65, 3.92)
	LandmarkFrKit.rect(lm, "White", -2.55, 2.55, -3.05, -1.20, 3.56, 3.65)
	# Roof navigation mast rising to 5.56 m (matches registry height_m = 5.5 m) with lamps.
	lm.frustum("White", Vector3(0.0, 3.92, -2.15), 0.09, 0.055, 1.42, 8)
	lm.beam("White", Vector3(0.0, 4.95, -2.75), Vector3(0.0, 4.95, -1.55), 0.05, 0.05)
	lm.lathe("ForiLamp", Vector3(0.0, 5.34, -2.15), LandmarkFrKit.ball(0.11), 6)
	for lz: float in [-2.70, -1.60]:
		lm.lathe("ForiLamp", Vector3(0.0, 4.95, lz), LandmarkFrKit.ball(0.09), 6)
	# Bow & stern deck work/navigation lamps mounted on the ramp stanchions.
	for sx: float in [-1.0, 1.0]:
		lm.lathe("ForiLamp", Vector3(sx * 8.55, 2.75, -1.72), LandmarkFrKit.ball(0.09), 6)
		lm.lathe("ForiLamp", Vector3(sx * 8.55, 2.75, 1.72), LandmarkFrKit.ball(0.09), 6)

static func _build_landing_stages(lm: LandmarkMesh) -> void:
	# Stationary Förin laiturit on Läntinen Rantakatu (-X) and Tervatori (+X) banks.
	for sx: float in [-1.0, 1.0]:
		var x_near := sx * LANDING_LIP_X
		var x_far := sx * (LANDING_LIP_X + 5.5)
		var x0 := minf(x_near, x_far)
		var x1 := maxf(x_near, x_far)
		LandmarkFrKit.rect(lm, "Timber", x0, x1, -3.6, 3.6, 1.15, 1.48)
		var gx0 := x_far - (2.2 if sx > 0.0 else 0.0)
		var gx1 := x_far + (0.0 if sx > 0.0 else 2.2)
		LandmarkFrKit.rect(lm, "Granite", gx0, gx1, -4.2, 4.2, -1.6, 1.54)
		for pz: float in [-3.3, -1.6, 1.6, 3.3]:
			lm.frustum("Timber", Vector3(x_near + sx * 0.45, -1.6, pz), 0.22, 0.20, 2.95, 8)
		for bz: float in [-3.0, 3.0]:
			lm.frustum("Dark", Vector3(x_near + sx * 0.85, 1.48, bz), 0.16, 0.14, 0.44, 8)
		var lx := x_far - sx * 0.8
		lm.frustum("Dark", Vector3(lx, 1.54, -3.5), 0.08, 0.05, 3.1, 8)
		lm.lathe("Lamp", Vector3(lx, 4.64, -3.5), LandmarkFrKit.ball(0.18), 8)

static func _set_night_floods(model: Node3D) -> void:
	# Stationary landing-stage quay floodlights (vessel night lights are schedule-gated in ForiShuttle).
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-LANDING_LIP_X - 3.5, 4.8, -3.5), Vector3(-LANDING_LIP_X, 1.4, 0.0), 66.0, 0.70, 20.0, Color(1.0, 0.88, 0.66)],
		[Vector3(LANDING_LIP_X + 3.5, 4.8, -3.5), Vector3(LANDING_LIP_X, 1.4, 0.0), 66.0, 0.70, 20.0, Color(1.0, 0.88, 0.66)],
	])
