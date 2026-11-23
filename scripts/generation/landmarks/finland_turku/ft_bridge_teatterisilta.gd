class_name FtBridgeTeatterisilta
extends RefCounted

## Teatterisilta (1997): Turku's broad wood-decked pedestrian plaza-bridge over
## Aurajoki in front of Turku City Theatre. Built along +X (yaw_deg = 60.7°,
## bearing 150.7°, base = "water", y = 0 at Aurajoki water level):
##   - Plan: 66.2 m total span (-33.1..+33.1 m), 6.4 m wide pedestrian deck
##     (-3.2..+3.2 m), gentle camber from y = 4.25 m at abutments to y = 4.95 m
##     at mid-span, height_m = 13.8 m (top of signature white lighting masts).
##   - Structure: slender white-painted steel box girder with subtle haunches
##     at concrete/granite riverfront abutments (footing y = -2.5 m).
##   - Signature features:
##     1. Broad warm timber plank deck with integrated wooden plaza benches.
##     2. Crisp white tubular steel pedestrian railings along both sides.
##     3. Six tall white architectural lighting masts (3 pairs at x = -18, 0, +18 m)
##        rising to y = 13.8 m with tension stay rods and glowing warm luminaire heads.
## Surfaces: 6 merged PBR parts (Steel, Timber, Concrete, Dark, Bench, Lamp).

const SPAN_HALF := 33.1
const HALF_W := 3.2
const DECK_Y := 4.5
const MAST_H := 9.3
const FOOT_Y := 0.0

static func build(model: Node3D, row: Dictionary = {}) -> void:
	if row.is_empty():
		row = BridgeSpecs.row_for("br_turku_teatterisilta")
	var h := BridgeParam.half_length(row)
	var half_w := float(row.get("width", HALF_W * 2.0)) * 0.5
	var c := float(row.get("clear", DECK_Y))
	var orn := float(row.get("orn", MAST_H))
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_abutments(lm, h, c, half_w)
	_build_girder_and_wood_deck(lm, h, c, half_w)
	_build_railings_and_benches(lm, h, c, half_w)
	_build_lighting_masts(lm, c, half_w, orn)
	BridgeCamber.apply(lm, h, c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)
	_set_night_floods(model, c)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Steel", LandmarkMaterials.paint("#F1F1EC", 0.38, 0.24))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#967452", 2.6, 0.78))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A8A69E", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#2D3236", 0.44, 0.55))
	lm.use("Bench", LandmarkMaterials.pbr("wood", "#7C5A3B", 1.8, 0.74))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEBC2", 2.2))

static func _build_abutments(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	var ab_h := maxf(c - 0.15 - FOOT_Y, 0.2)
	var seat_h := minf(1.20, maxf(c - 0.35, 0.2))
	for sx: float in [-1.0, 1.0]:
		var ax := sx * (h - 1.5)
		lm.box("Concrete", Vector3(ax, FOOT_Y + ab_h * 0.5, 0.0),
			Vector3(3.4, ab_h, half_w * 2.0 + 1.6), Basis(), 0.0)
		lm.box("Steel", Vector3(ax - sx * 0.9, c - 0.15 - seat_h * 0.5, 0.0),
			Vector3(2.2, seat_h, half_w * 2.0 - 0.8), Basis(), 0.0)

static func _build_girder_and_wood_deck(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	var segs := 16
	var max_haunch := minf(1.55, maxf(c * 0.65, 0.5))
	var min_haunch := minf(0.75, max_haunch * 0.5)
	for i in segs:
		var x0 := lerpf(-h, h, float(i) / float(segs))
		var x1 := lerpf(-h, h, float(i + 1) / float(segs))
		var xm := (x0 + x1) * 0.5
		var l := (x1 - x0) + 0.04
		# Warm wood-plank pedestrian plaza deck.
		lm.box("Timber", Vector3(xm, c - 0.06, 0.0), Vector3(l, 0.14, half_w * 2.0 - 0.30), Basis(), 0.0)
		# Haunched white steel box girder below deck.
		var haunch := lerpf(min_haunch, max_haunch, pow(absf(xm) / h, 2.0))
		lm.box("Steel", Vector3(xm, c - 0.14 - haunch * 0.5, 0.0), Vector3(l, haunch, half_w * 2.0 - 1.1), Basis(), 0.0)
		# White steel fascia edges.
		for sz: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(xm, c - 0.18, sz * (half_w - 0.12)), Vector3(l, 0.40, 0.24), Basis(), 0.0)

static func _build_railings_and_benches(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	var segs := 16
	for sz: float in [-1.0, 1.0]:
		var zr := sz * (half_w - 0.12)
		for i in segs:
			var x0 := lerpf(-h + 0.4, h - 0.4, float(i) / float(segs))
			var x1 := lerpf(-h + 0.4, h - 0.4, float(i + 1) / float(segs))
			lm.beam("Steel", Vector3(x0, c + 1.12, zr), Vector3(x1, c + 1.12, zr), 0.08, 0.08)
			lm.beam("Steel", Vector3(x0, c + 0.58, zr), Vector3(x1, c + 0.58, zr), 0.05, 0.05)
			lm.beam("Steel", Vector3(x0, c + 0.26, zr), Vector3(x1, c + 0.26, zr), 0.05, 0.05)
			lm.beam("Steel", Vector3(x0, c, zr), Vector3(x0, c + 1.12, zr), 0.065, 0.065)
		# Wooden pedestrian benches along the mid-span plaza section.
		for bx: float in [-10.0, 0.0, 10.0]:
			var bz := sz * (half_w - 0.68)
			lm.box("Bench", Vector3(bx, c + 0.46, bz), Vector3(3.2, 0.08, 0.52), Basis(), 0.0)
			lm.box("Bench", Vector3(bx, c + 0.78, bz + sz * 0.22), Vector3(3.2, 0.34, 0.08), Basis(), 0.0)
			for lx: float in [-1.2, 0.0, 1.2]:
				lm.box("Dark", Vector3(bx + lx, c + 0.23, bz), Vector3(0.08, 0.46, 0.44), Basis(), 0.0)

static func _build_lighting_masts(lm: LandmarkMesh, c: float, half_w: float, orn: float) -> void:
	# Three pairs of tall tapered white architectural lighting masts with stays
	# and twin warm luminaire heads (top y = c + orn at mid-span).
	var mast_prof := PackedVector2Array([
		Vector2(0.18, -0.25), Vector2(0.14, 2.75), Vector2(0.09, orn - 0.3), Vector2(0.05, orn)
	])
	for mx: float in [-18.0, 0.0, 18.0]:
		var top_y := c + orn
		for sz: float in [-1.0, 1.0]:
			var zm := sz * (half_w + 0.08)
			lm.lathe("Steel", Vector3(mx, c, zm), mast_prof, 8)
			# Subtle outrigger luminaire arm pointing inward over the wood deck.
			var arm_end := Vector3(mx, top_y - 0.45, zm - sz * 1.15)
			lm.beam("Steel", Vector3(mx, top_y - 0.75, zm), arm_end, 0.06, 0.06)
			lm.box("Dark", arm_end + Vector3(0.0, 0.06, 0.0), Vector3(0.55, 0.12, 0.32), Basis(), 0.0)
			lm.box("Lamp", arm_end + Vector3(0.0, -0.02, 0.0), Vector3(0.46, 0.08, 0.24), Basis(), 0.0)
			# Tension stay rods bracing each mast longitudinally along the bridge.
			for dx: float in [-5.5, 5.5]:
				var ax := mx + dx
				lm.beam("Dark", Vector3(mx, top_y - 1.4, zm),
					Vector3(ax, c + 0.15, zm), 0.035, 0.035)
		# Slim overhead tie cable linking each mast pair across the deck.
		lm.beam("Dark", Vector3(mx, top_y - 0.9, -half_w - 0.08),
			Vector3(mx, top_y - 0.9, half_w + 0.08), 0.03, 0.03)

static func _set_night_floods(model: Node3D, c: float) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, c + 8.5, 4.0), Vector3(-18.0, c, 0.0), 65.0, 0.8, 26.0, Color("#FFE8BE")],
		[Vector3(0.0, c + 9.0, -4.0), Vector3(0.0, c, 0.0), 70.0, 0.9, 28.0, Color("#FFE8BE")],
		[Vector3(18.0, c + 8.5, 4.0), Vector3(18.0, c, 0.0), 65.0, 0.8, 26.0, Color("#FFE8BE")],
	])
