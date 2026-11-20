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
const END_Y := 4.25
const CAMBER := 0.70
const MAST_H := 8.85
const FOOT_Y := -2.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_abutments(lm)
	_build_girder_and_wood_deck(lm)
	_build_railings_and_benches(lm)
	_build_lighting_masts(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Steel", LandmarkMaterials.paint("#F1F1EC", 0.38, 0.24))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#967452", 2.6, 0.78))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A8A69E", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#2D3236", 0.44, 0.55))
	lm.use("Bench", LandmarkMaterials.pbr("wood", "#7C5A3B", 1.8, 0.74))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEBC2", 2.2))

static func _deck_y(x: float) -> float:
	var u := clampf(x / SPAN_HALF, -1.0, 1.0)
	return END_Y + CAMBER * (1.0 - u * u)

static func _build_abutments(lm: LandmarkMesh) -> void:
	for sx: float in [-1.0, 1.0]:
		var ax := sx * (SPAN_HALF - 1.5)
		lm.box("Concrete", Vector3(ax, (FOOT_Y + END_Y - 0.15) * 0.5, 0.0),
			Vector3(3.4, END_Y - 0.15 - FOOT_Y, HALF_W * 2.0 + 1.6))
		lm.box("Steel", Vector3(ax - sx * 0.9, END_Y - 0.75, 0.0),
			Vector3(2.2, 1.20, HALF_W * 2.0 - 0.8))

static func _build_girder_and_wood_deck(lm: LandmarkMesh) -> void:
	var segs := 28
	for i in segs:
		var x0 := lerpf(-SPAN_HALF, SPAN_HALF, float(i) / float(segs))
		var x1 := lerpf(-SPAN_HALF, SPAN_HALF, float(i + 1) / float(segs))
		var xm := (x0 + x1) * 0.5
		var y0 := _deck_y(x0)
		var y1 := _deck_y(x1)
		var ym := (y0 + y1) * 0.5
		var l := Vector2(x1 - x0, y1 - y0).length() + 0.06
		var rot := Basis(Vector3.BACK, atan2(y1 - y0, x1 - x0))
		# Warm wood-plank pedestrian plaza deck.
		lm.box("Timber", Vector3(xm, ym - 0.06, 0.0), Vector3(l, 0.14, HALF_W * 2.0 - 0.30), rot)
		# Haunched white steel box girder below deck.
		var haunch := lerpf(0.75, 1.55, pow(absf(xm) / SPAN_HALF, 2.0))
		lm.box("Steel", Vector3(xm, ym - 0.14 - haunch * 0.5, 0.0), Vector3(l, haunch, HALF_W * 2.0 - 1.1), rot)
		# White steel fascia edges.
		for sz: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(xm, ym - 0.18, sz * (HALF_W - 0.12)), Vector3(l, 0.40, 0.24), rot)

static func _build_railings_and_benches(lm: LandmarkMesh) -> void:
	var segs := 24
	for sz: float in [-1.0, 1.0]:
		var zr := sz * (HALF_W - 0.12)
		for i in segs:
			var x0 := lerpf(-SPAN_HALF + 0.4, SPAN_HALF - 0.4, float(i) / float(segs))
			var x1 := lerpf(-SPAN_HALF + 0.4, SPAN_HALF - 0.4, float(i + 1) / float(segs))
			var y0 := _deck_y(x0)
			var y1 := _deck_y(x1)
			lm.beam("Steel", Vector3(x0, y0 + 1.12, zr), Vector3(x1, y1 + 1.12, zr), 0.08, 0.08)
			lm.beam("Steel", Vector3(x0, y0 + 0.58, zr), Vector3(x1, y1 + 0.58, zr), 0.05, 0.05)
			lm.beam("Steel", Vector3(x0, y0 + 0.26, zr), Vector3(x1, y1 + 0.26, zr), 0.05, 0.05)
			lm.beam("Steel", Vector3(x0, y0, zr), Vector3(x0, y0 + 1.12, zr), 0.065, 0.065)
		# Wooden pedestrian benches along the mid-span plaza section.
		for bx: float in [-10.0, 0.0, 10.0]:
			var by := _deck_y(bx)
			var bz := sz * (HALF_W - 0.68)
			lm.box("Bench", Vector3(bx, by + 0.46, bz), Vector3(3.2, 0.08, 0.52))
			lm.box("Bench", Vector3(bx, by + 0.78, bz + sz * 0.22), Vector3(3.2, 0.34, 0.08))
			for lx: float in [-1.2, 0.0, 1.2]:
				lm.box("Dark", Vector3(bx + lx, by + 0.23, bz), Vector3(0.08, 0.46, 0.44))

static func _build_lighting_masts(lm: LandmarkMesh) -> void:
	# Three pairs of tall tapered white architectural lighting masts with stays
	# and twin warm luminaire heads (top y = 4.95 + 8.85 = 13.80 m at mid-span).
	var mast_prof := PackedVector2Array([
		Vector2(0.18, 0.0), Vector2(0.14, 3.0), Vector2(0.09, MAST_H - 0.3), Vector2(0.05, MAST_H)
	])
	for mx: float in [-18.0, 0.0, 18.0]:
		var dy := _deck_y(mx)
		var top_y := dy + MAST_H
		for sz: float in [-1.0, 1.0]:
			var zm := sz * (HALF_W + 0.08)
			lm.lathe("Steel", Vector3(mx, dy - 0.25, zm), mast_prof, 8)
			# Subtle outrigger luminaire arm pointing inward over the wood deck.
			var arm_end := Vector3(mx, top_y - 0.45, zm - sz * 1.15)
			lm.beam("Steel", Vector3(mx, top_y - 0.75, zm), arm_end, 0.06, 0.06)
			lm.box("Dark", arm_end + Vector3(0.0, 0.06, 0.0), Vector3(0.55, 0.12, 0.32))
			lm.box("Lamp", arm_end + Vector3(0.0, -0.02, 0.0), Vector3(0.46, 0.08, 0.24))
			# Tension stay rods bracing each mast longitudinally along the bridge.
			for dx: float in [-5.5, 5.5]:
				var ax := mx + dx
				lm.beam("Dark", Vector3(mx, top_y - 1.4, zm),
					Vector3(ax, _deck_y(ax) + 0.15, zm), 0.035, 0.035)
		# Slim overhead tie cable linking each mast pair across the deck.
		lm.beam("Dark", Vector3(mx, top_y - 0.9, -HALF_W - 0.08),
			Vector3(mx, top_y - 0.9, HALF_W + 0.08), 0.03, 0.03)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		{"at": Vector3(-18.0, 12.2, 0.0), "range": 26.0, "energy": 2.4, "colour": Color("#FFE8BE")},
		{"at": Vector3(0.0, 12.8, 0.0), "range": 28.0, "energy": 2.6, "colour": Color("#FFE8BE")},
		{"at": Vector3(18.0, 12.2, 0.0), "range": 26.0, "energy": 2.4, "colour": Color("#FFE8BE")},
	])
