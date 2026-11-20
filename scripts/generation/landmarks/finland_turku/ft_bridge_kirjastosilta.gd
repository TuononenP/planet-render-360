class_name FtBridgeKirjastosilta
extends RefCounted

## Kirjastosilta (2013, Teemu Kurkela / JKMM & Pontek): sleek white steel
## pedestrian and cycle arch bridge over Aurajoki linking Turku Main Library
## and Rettig Palace. Built along +X (yaw_deg = 33.2°, bearing 123.2°,
## base = "water", y = 0 at Aurajoki water level):
##   - Plan: 59.8 m total span (-29.9..+29.9 m), 5.0 m deck width (-2.5..+2.5 m),
##     cambered deck from y = 3.85 m at abutments to y = 4.65 m at mid-span,
##     height_m = 7.8 m (crown of sculptural white steel twin side arches).
##   - Structure: slender tapered white steel box girder + graceful white steel
##     twin tubular side arches springing from riverfront concrete abutments
##     (y = -2.5 m) and rising above the mid-span deck with slim vertical hangers.
##   - Signature features:
##     1. Continuous transparent glass balustrades along both edges with
##        brushed stainless handrails and slim posts.
##     2. Night architectural LED under-deck & arch-rib glow reflecting in
##        Aurajoki (LedGlow emissive strip + FLOOD_META).
## Surfaces: 6 merged PBR parts (Steel, Deck, Concrete, Glass, Stainless, LedGlow).

const SPAN_HALF := 29.9
const HALF_W := 2.5
const END_Y := 3.85
const CAMBER := 0.80
const ARCH_TOP_Y := 7.8
const FOOT_Y := -2.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_abutments(lm)
	_build_deck_and_girder(lm)
	_build_white_steel_arches(lm)
	_build_glass_balustrades(lm)
	_build_night_led_glow(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Steel", LandmarkMaterials.paint("#F0F2F0", 0.36, 0.25))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#4A4D50", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B6B0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#8FB5C4"))
	lm.use("Stainless", LandmarkMaterials.paint("#CFD4D8", 0.24, 0.82))
	lm.use("LedGlow", LandmarkMaterials.lit("#7CE6FF", 2.0))

static func _deck_y(x: float) -> float:
	var u := clampf(x / SPAN_HALF, -1.0, 1.0)
	return END_Y + CAMBER * (1.0 - u * u)

static func _arch_y(x: float) -> float:
	var u := clampf(x / (SPAN_HALF - 1.5), -1.0, 1.0)
	return 1.35 + (ARCH_TOP_Y - 1.35) * (1.0 - u * u)

static func _build_abutments(lm: LandmarkMesh) -> void:
	for sx: float in [-1.0, 1.0]:
		var ax := sx * (SPAN_HALF - 1.4)
		lm.box("Concrete", Vector3(ax, (FOOT_Y + END_Y - 0.15) * 0.5, 0.0),
			Vector3(3.2, END_Y - 0.15 - FOOT_Y, HALF_W * 2.0 + 1.4))
		# Sculpted white steel abutment bearing seat.
		lm.box("Steel", Vector3(ax - sx * 0.8, END_Y - 0.55, 0.0),
			Vector3(1.8, 0.85, HALF_W * 2.0 + 0.8))

static func _build_deck_and_girder(lm: LandmarkMesh) -> void:
	# Cambered pedestrian deck slab and tapered white steel box girder beneath.
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
		# Non-slip deck wearing surface + white steel fascia edge beams.
		lm.box("Deck", Vector3(xm, ym - 0.06, 0.0), Vector3(l, 0.14, HALF_W * 2.0 - 0.36), rot)
		var depth := lerpf(0.62, 1.05, pow(absf(xm) / SPAN_HALF, 1.5))
		lm.box("Steel", Vector3(xm, ym - 0.14 - depth * 0.5, 0.0), Vector3(l, depth, HALF_W * 2.0 - 0.55), rot)
		for sz: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(xm, ym - 0.16, sz * (HALF_W - 0.10)), Vector3(l, 0.36, 0.22), rot)

static func _build_white_steel_arches(lm: LandmarkMesh) -> void:
	# Twin outward-leaning white steel arch ribs springing from abutments and
	# rising gracefully above the deck at mid-span, with slim vertical hangers.
	var segs := 28
	var span := SPAN_HALF - 1.5
	for sz: float in [-1.0, 1.0]:
		var z_rib := sz * (HALF_W + 0.24)
		for i in segs:
			var x0 := lerpf(-span, span, float(i) / float(segs))
			var x1 := lerpf(-span, span, float(i + 1) / float(segs))
			var p0 := Vector3(x0, _arch_y(x0), z_rib)
			var p1 := Vector3(x1, _arch_y(x1), z_rib)
			lm.beam("Steel", p0, p1, 0.42, 0.34)
		# Vertical hanger rods / spandrel posts tying the arch to the deck edge.
		for k in range(-9, 10):
			var hx := float(k) * 2.75
			var ay := _arch_y(hx)
			var dy := _deck_y(hx)
			if absf(ay - dy) > 0.35:
				lm.beam("Stainless", Vector3(hx, minf(ay, dy), z_rib),
					Vector3(hx, maxf(ay, dy), z_rib), 0.07, 0.07)

static func _build_glass_balustrades(lm: LandmarkMesh) -> void:
	# Continuous transparent glass balustrades with brushed stainless top rail.
	var segs := 20
	for sz: float in [-1.0, 1.0]:
		var zb := sz * (HALF_W - 0.08)
		for i in segs:
			var x0 := lerpf(-SPAN_HALF + 0.3, SPAN_HALF - 0.3, float(i) / float(segs))
			var x1 := lerpf(-SPAN_HALF + 0.3, SPAN_HALF - 0.3, float(i + 1) / float(segs))
			var y0 := _deck_y(x0)
			var y1 := _deck_y(x1)
			lm.quad("Glass",
				Vector3(x0, y0 + 0.08, zb), Vector3(x1, y1 + 0.08, zb),
				Vector3(x1, y1 + 1.12, zb), Vector3(x0, y0 + 1.12, zb), Vector3(0, 0, sz))
			lm.quad("Glass",
				Vector3(x1, y1 + 0.08, zb), Vector3(x0, y0 + 0.08, zb),
				Vector3(x0, y0 + 1.12, zb), Vector3(x1, y1 + 1.12, zb), Vector3(0, 0, -sz))
			lm.beam("Stainless", Vector3(x0, y0 + 1.14, zb), Vector3(x1, y1 + 1.14, zb), 0.07, 0.08)
			lm.beam("Stainless", Vector3(x0, y0, zb), Vector3(x0, y0 + 1.14, zb), 0.055, 0.055)

static func _build_night_led_glow(lm: LandmarkMesh) -> void:
	# Continuous under-deck LED accent strip along both girder flanks.
	var segs := 20
	for sz: float in [-1.0, 1.0]:
		var zl := sz * (HALF_W - 0.24)
		for i in segs:
			var x0 := lerpf(-SPAN_HALF + 2.5, SPAN_HALF - 2.5, float(i) / float(segs))
			var x1 := lerpf(-SPAN_HALF + 2.5, SPAN_HALF - 2.5, float(i + 1) / float(segs))
			lm.beam("LedGlow", Vector3(x0, _deck_y(x0) - 0.42, zl),
				Vector3(x1, _deck_y(x1) - 0.42, zl), 0.12, 0.10)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		{"at": Vector3(-12.0, 3.2, 0.0), "range": 24.0, "energy": 2.6, "colour": Color("#6CE0FF")},
		{"at": Vector3(0.0, 3.4, 0.0), "range": 28.0, "energy": 3.0, "colour": Color("#7CE6FF")},
		{"at": Vector3(12.0, 3.2, 0.0), "range": 24.0, "energy": 2.6, "colour": Color("#6CE0FF")},
	])
