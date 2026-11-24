class_name FtFori
extends RefCounted

## Föri (1904, Ab Vulcan): Turku's iconic orange-and-blue double-ended
## electric river ferry crossing Aurajoki between Tervatori and Läntinen
## Rantakatu in true metres (+X across Aurajoki from Läntinen Rantakatu -X
## to Tervatori +X, y = 0 at water level, yaw_deg = 54.5°, base = "water"):
##   - Moving `ForiVessel` (`ForiShuttle` Node3D): authentic low-freeboard
##     bright orange steel hull (1.12 m freeboard, 0.65 m draft, dark waterline
##     boot), cantilevered flat grey deck (DECK_Y = 1.38 m) with diagonal orange
##     side gusset ribs and sloped bow/stern boarding ramp aprons (±10.65 m),
##     orange open railings, 4 orange rectangular side machinery/locker boxes,
##     orange benches, orange ramp-lifting A-frame derricks with counterweights,
##     striped end barrier gates, 4 red-and-white lifebuoys, bright royal blue
##     offset side operator wheelhouse with dark wraparound windows, white-
##     framed end door, white "FÖRI" roof sign, blue Turku flag, and black mast
##     with two black circular daymarks (~5.7 m). Shuttles smoothly between
##     x = -26.85 m and +26.85 m (~90 s round trip, 11 s boarding pauses).
##   - Stationary `ForiLandings` (`Node3D`): low grey concrete & granite Förin
##     laiturit boarding piers at x = ±37.5..±42.8 m flush with Föri's deck
##     (PIER_Y = 1.44 m), plus sloped quay-side ramps added by `conform()` that
##     climb along the granite embankment face from the low pier right up onto
##     each bank's road level.

const TRAVEL_HALF := 26.85
const LANDING_LIP_X := 37.5
const DECK_Y := 1.38
const PIER_Y := 1.44

const HULL_SPEC := {
	"length": 15.6,
	"beam": 5.8,
	"freeboard": 1.12,
	"draft": 0.65,
	"double_ended": true,
	"entry": 0.22,
	"end_width": 0.72,
	"bow_pow": 1.6,
	"flare": 0.08,
	"bow_rise": 0.05,
	"stern_rise": 0.05,
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
	_build_cantilever_deck_and_ramps(vlm)
	_build_railings_boxes_and_benches(vlm)
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

## Connects each low water-level boarding pier (PIER_Y, flush with Föri's deck)
## up to the actual Aurajoki quay/road elevation via a sloped granite-and-concrete
## access ramp running along the front of the embankment wall (in open space,
## never buried by the quay terrain).
static func conform(root: Node3D, ground: GroundTruth) -> void:
	var model := root.get_node_or_null("Model") as Node3D
	var landings := model.get_node_or_null("ForiLandings") as Node3D if model != null else null
	if model == null or landings == null or ground == null:
		return
	var to_world := root.transform * model.transform
	var m2u := WorldScale.metres_to_units()
	var rlm := LandmarkMesh.new()
	_landing_materials(rlm)
	var built_any := false
	for sx: float in [-1.0, 1.0]:
		var z_dir := 1.0 if sx > 0.0 else -1.0
		var road_y := -INF
		for rx: float in [42.0, 45.0, 48.0]:
			for rz: float in [18.0, 21.0, 24.0]:
				var wp := to_world * Vector3(sx * rx, 0.0, z_dir * rz)
				if ground.is_inside(wp.x, wp.z) and ground.water_at(wp.x, wp.z) <= 0.0:
					road_y = maxf(road_y, (ground.height_at_world(wp.x, wp.z) - root.position.y) / m2u)
		if road_y <= PIER_Y + 0.15:
			continue
		road_y = clampf(road_y, PIER_Y + 0.3, 6.5)
		built_any = true
		var x_in := sx * (LANDING_LIP_X + 5.2) if sx > 0.0 else -(LANDING_LIP_X + 2.3)
		var x_out := sx * (LANDING_LIP_X + 1.6) if sx > 0.0 else -(LANDING_LIP_X - 1.1)
		var x_mid := (x_in + x_out) * 0.5
		var rw := absf(x_in - x_out)
		var z_bot := z_dir * 3.4
		var z_top := z_dir * 20.0
		var p_bot := Vector3(x_mid, PIER_Y - 0.12, z_bot)
		var p_top := Vector3(x_mid, road_y - 0.12, z_top)
		# Sloped concrete walkway climbing from the low boarding pier to the quay road.
		rlm.beam("Concrete", p_bot, p_top, 0.28, rw, Vector3.UP)
		# Stepped granite retaining wall beneath the ramp down below waterline.
		var x0 := minf(x_in, x_out)
		var x1 := maxf(x_in, x_out)
		for seg in 6:
			var f0 := float(seg) / 6.0
			var f1 := float(seg + 1) / 6.0
			var za := lerpf(z_bot, z_top, f0)
			var zb := lerpf(z_bot, z_top, f1)
			var yt := lerpf(PIER_Y, road_y, (f0 + f1) * 0.5) - 0.20
			LandmarkFrKit.rect(rlm, "Granite", x0, x1, minf(za, zb), maxf(za, zb), -1.6, yt)
		# Level top landing apron bridging from the ramp top flush onto the quay sidewalk/road.
		var tx0 := minf(x_out, sx * (LANDING_LIP_X + 9.5))
		var tx1 := maxf(x_out, sx * (LANDING_LIP_X + 9.5))
		var tz0 := minf(z_top - z_dir * 0.2, z_top + z_dir * 4.2)
		var tz1 := maxf(z_top - z_dir * 0.2, z_top + z_dir * 4.2)
		LandmarkFrKit.rect(rlm, "Concrete", tx0, tx1, tz0, tz1, road_y - 0.28, road_y + 0.04)
		LandmarkFrKit.rect(rlm, "Granite", tx0, tx1, tz0, tz1, -1.6, road_y - 0.28)
		# Continuous dark steel safety handrail along the river-facing edge of the ramp.
		var rail_x := x_out + sx * 0.14
		var rb := Vector3(rail_x, PIER_Y, z_bot)
		var rt := Vector3(rail_x, road_y, z_top)
		rlm.beam("Dark", rb + Vector3(0, 0.96, 0), rt + Vector3(0, 0.96, 0), 0.06, 0.06)
		rlm.beam("Dark", rb + Vector3(0, 0.50, 0), rt + Vector3(0, 0.50, 0), 0.045, 0.045)
		for k in 6:
			var f := float(k) / 5.0
			var base := rb.lerp(rt, f)
			rlm.beam("Dark", base, base + Vector3(0, 0.96, 0), 0.06, 0.06)
		rlm.beam("Dark", rt + Vector3(0, 0.96, 0), rt + Vector3(0, 0.96, z_dir * 4.0), 0.06, 0.06)
		rlm.beam("Dark", rt + Vector3(0, 0.50, 0), rt + Vector3(0, 0.50, z_dir * 4.0), 0.045, 0.045)
		rlm.beam("Dark", rt + Vector3(0, 0.0, z_dir * 4.0), rt + Vector3(0, 0.96, z_dir * 4.0), 0.06, 0.06)
	if built_any:
		rlm.commit(landings)

static func _vessel_materials(lm: LandmarkMesh) -> void:
	lm.use("Orange", LandmarkMaterials.paint("#E86A14", 0.40, 0.14))
	lm.use("Blue", LandmarkMaterials.paint("#1452B0", 0.38, 0.12))
	lm.use("White", LandmarkMaterials.paint("#F2EFE9", 0.46, 0.08))
	lm.use("BuoyRed", LandmarkMaterials.paint("#D23622", 0.44, 0.08))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#9A9D9F", 2.0, 0.78))
	lm.use("Dark", LandmarkMaterials.paint("#22262A", 0.48, 0.42))
	lm.use("Glass", LandmarkMaterials.glass("#1A2832"))
	lm.use("ForiLamp", LandmarkMaterials.lit("#FFEAC0", 0.0))

static func _landing_materials(lm: LandmarkMesh) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#7E8285", 2.2, 0.80))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#827E78", 2.4))
	lm.use("Dark", LandmarkMaterials.paint("#262A2E", 0.48, 0.45))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEAC0", 1.6))

static func _build_cantilever_deck_and_ramps(lm: LandmarkMesh) -> void:
	# Wide rectangular overhanging deck (18.6 m x 6.6 m) sitting low above the orange hull.
	LandmarkFrKit.rect(lm, "Deck", -9.2, 9.2, -3.28, 3.28, 1.24, DECK_Y)
	# Bright orange deck edge skirt / rub-rail along both long sides.
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Orange", -9.2, 9.2, sz * 3.16 - 0.14, sz * 3.16 + 0.14, 1.16, DECK_Y + 0.02)
		# Diagonal orange triangular gusset brackets supporting the deck overhang along the hull.
		for i in 11:
			var gx := lerpf(-7.0, 7.0, float(i) / 10.0)
			var hull_z := (HullLoft.half(HULL_SPEC, gx) - 0.08) * sz
			lm.beam("Orange", Vector3(gx, 0.56, hull_z), Vector3(gx, 1.20, 3.20 * sz), 0.08, 0.07)
	# Cantilevered sloped steel bow & stern boarding ramp aprons (±9.2..±10.65 m).
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 9.15
		var x1 := sx * 10.65
		lm.beam("Deck", Vector3(x0, 1.32, 0.0), Vector3(x1, 1.42, 0.0), 0.12, 6.2, Vector3.UP)
		# Angled weathered/dark-orange underside prow plate.
		lm.beam("Orange", Vector3(sx * 7.6, 0.78, 0.0), Vector3(x1, 1.30, 0.0), 0.14, 5.9, Vector3.UP)
		lm.beam("Dark", Vector3(x1 - sx * 0.08, 1.34, -3.1), Vector3(x1 - sx * 0.08, 1.34, 3.1), 0.22, 0.10)
		# Striped boarding safety gate bar across each open prow.
		for seg in 6:
			var z0 := lerpf(-2.7, 2.7, float(seg) / 6.0)
			var z1 := lerpf(-2.7, 2.7, float(seg + 1) / 6.0)
			var mat := "Dark" if seg % 2 == 0 else "Orange"
			lm.beam(mat, Vector3(sx * 8.45, 2.34, z0), Vector3(sx * 8.45, 2.34, z1), 0.08, 0.08)
		# Orange ramp-lifting A-frame derricks with round orange counterweights on both sides.
		for sz: float in [-2.85, 2.85]:
			var top := Vector3(sx * 7.45, 3.20, sz)
			lm.beam("Orange", Vector3(sx * 6.55, DECK_Y, sz), top, 0.08, 0.08)
			lm.beam("Orange", Vector3(sx * 8.35, DECK_Y, sz), top, 0.08, 0.08)
			lm.lathe("Orange", top, LandmarkFrKit.ball(0.16), 8)
			lm.beam("Dark", top, Vector3(sx * 10.2, 1.46, sz), 0.03, 0.03)

static func _build_railings_boxes_and_benches(lm: LandmarkMesh) -> void:
	# Open orange side railings (stanchions + 3 horizontal rails) along both sides.
	for sz: float in [-1.0, 1.0]:
		var rz := sz * 3.16
		for i in 11:
			var x := lerpf(-8.6, 8.6, float(i) / 10.0)
			lm.beam("Orange", Vector3(x, DECK_Y, rz), Vector3(x, 2.48, rz), 0.06, 0.06)
		for ry: float in [1.74, 2.10, 2.46]:
			lm.beam("Orange", Vector3(-8.6, ry, rz), Vector3(8.6, ry, rz), 0.055, 0.055)
		# Iconic solid orange rectangular side machinery/lifejacket locker boxes flanking the cabin.
		for bx: float in [-4.5, 4.5]:
			LandmarkFrKit.rect(lm, "Orange", bx - 1.05, bx + 1.05, rz - 0.24, rz + 0.24, DECK_Y, 2.62)
		# Orange slatted passenger benches along the open port (+Z) side.
		if sz > 0.0:
			LandmarkFrKit.rect(lm, "Orange", -5.5, 5.5, 2.46, 2.94, 1.82, 1.90)
			LandmarkFrKit.rect(lm, "Orange", -5.5, 5.5, 2.90, 2.98, 1.90, 2.32)
			for lx: float in [-4.8, -1.6, 1.6, 4.8]:
				lm.box("Dark", Vector3(lx, 1.60, 2.70), Vector3(0.08, 0.44, 0.44))
		# Four bright red-and-white lifebuoys hanging on the outer railings.
		for bx: float in [-6.8, 6.8]:
			var bz := 3.24 * sz
			lm.disc("BuoyRed", Vector3(bx, 1.98, bz), Vector3(0, 0, sz), 0.34, 10)
			lm.disc("White", Vector3(bx, 1.98, bz + 0.02 * sz), Vector3(0, 0, sz), 0.18, 8)

static func _build_operator_cabin_and_mast(lm: LandmarkMesh) -> void:
	# Iconic royal blue offset side operator wheelhouse (-Z side) with blue roof overhang.
	LandmarkFrKit.rect(lm, "Blue", -2.15, 2.15, -3.02, -1.38, DECK_Y, 2.54)
	LandmarkFrKit.rect(lm, "Glass", -2.06, 2.06, -2.96, -1.44, 2.52, 3.74)
	for cx: float in [-2.10, -0.70, 0.70, 2.10]:
		for cz: float in [-2.96, -1.44]:
			lm.box("Blue", Vector3(cx, 3.14, cz), Vector3(0.16, 1.28, 0.16))
	# White-framed glass door on the +X end of the blue cabin.
	LandmarkFrKit.rect(lm, "White", 2.12, 2.19, -2.55, -1.80, 1.46, 3.42)
	LandmarkFrKit.rect(lm, "Glass", 2.16, 2.21, -2.46, -1.89, 2.36, 3.28)
	# Blue fascia & flat overhanging blue wheelhouse roof.
	LandmarkFrKit.rect(lm, "Blue", -2.35, 2.35, -3.18, -1.22, 3.74, 4.08)
	# Interior dark console & warm cabin ceiling lamp.
	LandmarkFrKit.rect(lm, "Dark", -0.8, 0.8, -2.4, -1.75, 1.42, 2.30)
	LandmarkFrKit.rect(lm, "ForiLamp", -1.4, 1.4, -2.35, -1.90, 3.52, 3.70)
	# White "FÖRI" roof signboard and small blue Turku coat-of-arms flag on cabin roof.
	LandmarkFrKit.rect(lm, "White", 0.35, 1.05, -2.32, -2.24, 4.08, 4.52)
	lm.frustum("White", Vector3(1.55, 4.08, -2.20), 0.035, 0.025, 1.05, 6)
	LandmarkFrKit.rect(lm, "Blue", 1.55, 2.15, -2.23, -2.17, 4.74, 5.11)
	# Tall black navigation mast with two iconic black circular daymark balls/discs.
	lm.frustum("Dark", Vector3(-1.35, 4.08, -2.20), 0.055, 0.035, 1.65, 8)
	lm.beam("Dark", Vector3(-1.35, 5.20, -2.65), Vector3(-1.35, 5.20, -1.75), 0.035, 0.035)
	lm.lathe("Dark", Vector3(-1.35, 4.78, -2.20), LandmarkFrKit.ball(0.24), 10)
	lm.lathe("Dark", Vector3(-1.35, 5.48, -2.20), LandmarkFrKit.ball(0.24), 10)
	lm.lathe("ForiLamp", Vector3(-1.35, 5.76, -2.20), LandmarkFrKit.ball(0.09), 6)
	for lz: float in [-2.62, -1.78]:
		lm.lathe("ForiLamp", Vector3(-1.35, 5.20, lz), LandmarkFrKit.ball(0.08), 6)
	# Bow & stern deck work lamps on the ramp A-frames.
	for sx: float in [-1.0, 1.0]:
		lm.lathe("ForiLamp", Vector3(sx * 7.45, 3.36, -2.85), LandmarkFrKit.ball(0.08), 6)
		lm.lathe("ForiLamp", Vector3(sx * 7.45, 3.36, 2.85), LandmarkFrKit.ball(0.08), 6)

static func _build_landing_stages(lm: LandmarkMesh) -> void:
	# Stationary Förin laiturit on Läntinen Rantakatu (-X) and Tervatori (+X) banks,
	# sitting low and level with Föri's boarding deck (PIER_Y = 1.44 m).
	for sx: float in [-1.0, 1.0]:
		var x_near := sx * LANDING_LIP_X
		var x_far := sx * (LANDING_LIP_X + 5.8)
		var x0 := minf(x_near, x_far)
		var x1 := maxf(x_near, x_far)
		LandmarkFrKit.rect(lm, "Concrete", x0, x1, -3.5, 3.5, PIER_Y - 0.32, PIER_Y)
		LandmarkFrKit.rect(lm, "Granite", x0, x1, -3.6, 3.6, -1.6, PIER_Y - 0.32)
		var gx0 := x_far - (2.4 if sx > 0.0 else 0.0)
		var gx1 := x_far + (0.0 if sx > 0.0 else 2.4)
		LandmarkFrKit.rect(lm, "Granite", gx0, gx1, -4.4, 4.4, -1.6, PIER_Y + 0.06)
		# Dark steel side railing on the closed side (open toward the sloped quay ramp).
		var rz_closed := -3.4 if sx > 0.0 else 3.4
		lm.beam("Dark", Vector3(x0, PIER_Y + 0.94, rz_closed), Vector3(x1, PIER_Y + 0.94, rz_closed), 0.06, 0.06)
		lm.beam("Dark", Vector3(x0, PIER_Y + 0.48, rz_closed), Vector3(x1, PIER_Y + 0.48, rz_closed), 0.045, 0.045)
		for px: float in [x0 + 0.3, (x0 + x1) * 0.5, x1 - 0.3]:
			lm.beam("Dark", Vector3(px, PIER_Y, rz_closed), Vector3(px, PIER_Y + 0.94, rz_closed), 0.06, 0.06)
		var bz_seat := rz_closed - signf(rz_closed) * 0.35
		LandmarkFrKit.rect(lm, "Dark", x0 + 0.4, x1 - 0.4, bz_seat - 0.22, bz_seat + 0.22, PIER_Y + 0.40, PIER_Y + 0.48)
		for bz: float in [-3.1, 3.1]:
			lm.frustum("Dark", Vector3(x_near + sx * 0.65, PIER_Y, bz), 0.15, 0.13, 0.42, 8)
		var lx := x_far - sx * 0.8
		lm.frustum("Dark", Vector3(lx, PIER_Y + 0.06, -3.8), 0.08, 0.05, 3.1, 8)
		lm.lathe("Lamp", Vector3(lx, PIER_Y + 3.16, -3.8), LandmarkFrKit.ball(0.18), 8)

static func _set_night_floods(model: Node3D) -> void:
	# Stationary landing-stage quay floodlights (vessel night lights are schedule-gated in ForiShuttle).
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-LANDING_LIP_X - 3.5, PIER_Y + 3.4, -3.8), Vector3(-LANDING_LIP_X, PIER_Y, 0.0), 66.0, 0.70, 20.0, Color(1.0, 0.88, 0.66)],
		[Vector3(LANDING_LIP_X + 3.5, PIER_Y + 3.4, -3.8), Vector3(LANDING_LIP_X, PIER_Y, 0.0), 66.0, 0.70, 20.0, Color(1.0, 0.88, 0.66)],
	])
