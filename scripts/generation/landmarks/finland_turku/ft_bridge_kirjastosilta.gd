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
const DECK_Y := 4.0
const ARCH_ORN := 3.8
const FOOT_Y := 0.0

static func build(model: Node3D, row: Dictionary = {}) -> void:
	if row.is_empty():
		row = BridgeSpecs.row_for("br_turku_kirjastosilta")
	var h := BridgeParam.half_length(row)
	var half_w := float(row.get("width", HALF_W * 2.0)) * 0.5
	var c := float(row.get("clear", DECK_Y))
	var orn := float(row.get("orn", ARCH_ORN))
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_abutments(lm, h, c, half_w)
	_build_deck_and_girder(lm, h, c, half_w)
	_build_white_steel_arches(lm, h, c, half_w, orn)
	_build_glass_balustrades(lm, h, c, half_w)
	_build_night_led_glow(lm, h, c, half_w)
	BridgeCamber.apply(lm, h, c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)
	_set_night_floods(model, c)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Steel", LandmarkMaterials.paint("#F0F2F0", 0.36, 0.25))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#4A4D50", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B6B0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#8FB5C4"))
	lm.use("Stainless", LandmarkMaterials.paint("#CFD4D8", 0.24, 0.82))
	lm.use("LedGlow", LandmarkMaterials.lit("#7CE6FF", 2.0))

static func _arch_y(x: float, span: float, spring: float, crown: float) -> float:
	var u := clampf(x / span, -1.0, 1.0)
	return spring + (crown - spring) * (1.0 - u * u)

static func _build_abutments(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	var ab_h := maxf(c - 0.15 - FOOT_Y, 0.2)
	var seat_h := minf(0.85, maxf(c - 0.35, 0.2))
	for sx: float in [-1.0, 1.0]:
		var ax := sx * (h - 1.4)
		lm.box("Concrete", Vector3(ax, FOOT_Y + ab_h * 0.5, 0.0),
			Vector3(3.2, ab_h, half_w * 2.0 + 1.4), Basis(), 0.0)
		# Sculpted white steel abutment bearing seat.
		lm.box("Steel", Vector3(ax - sx * 0.8, c - 0.15 - seat_h * 0.5, 0.0),
			Vector3(1.8, seat_h, half_w * 2.0 + 0.8), Basis(), 0.0)

static func _build_deck_and_girder(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	# Flat pedestrian deck slab and tapered white steel box girder beneath (cambered by BridgeCamber).
	var segs := 16
	var max_d := minf(1.05, maxf(c * 0.45, 0.45))
	var min_d := minf(0.62, max_d * 0.6)
	for i in segs:
		var x0 := lerpf(-h, h, float(i) / float(segs))
		var x1 := lerpf(-h, h, float(i + 1) / float(segs))
		var xm := (x0 + x1) * 0.5
		var l := (x1 - x0) + 0.04
		# Non-slip deck wearing surface + white steel fascia edge beams.
		lm.box("Deck", Vector3(xm, c - 0.06, 0.0), Vector3(l, 0.14, half_w * 2.0 - 0.36), Basis(), 0.0)
		var depth := lerpf(min_d, max_d, pow(absf(xm) / h, 1.5))
		lm.box("Steel", Vector3(xm, c - 0.14 - depth * 0.5, 0.0), Vector3(l, depth, half_w * 2.0 - 0.55), Basis(), 0.0)
		for sz: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(xm, c - 0.16, sz * (half_w - 0.10)), Vector3(l, 0.36, 0.22), Basis(), 0.0)

static func _build_white_steel_arches(lm: LandmarkMesh, h: float, c: float, half_w: float, orn: float) -> void:
	# Twin white steel arch ribs springing from abutments and rising above the
	# deck at mid-span to c + orn, with slim vertical hangers.
	var segs := 16
	var span := h - 1.5
	var spring := clampf(c * 0.34, 0.35, 1.35)
	var crown := c + orn - 0.17
	for sz: float in [-1.0, 1.0]:
		var z_rib := sz * (half_w + 0.24)
		for i in segs:
			var x0 := lerpf(-span, span, float(i) / float(segs))
			var x1 := lerpf(-span, span, float(i + 1) / float(segs))
			var p0 := Vector3(x0, _arch_y(x0, span, spring, crown), z_rib)
			var p1 := Vector3(x1, _arch_y(x1, span, spring, crown), z_rib)
			lm.beam("Steel", p0, p1, 0.42, 0.34)
		# Vertical hanger rods / spandrel posts tying the arch to the deck edge.
		for k in range(-7, 8):
			var hx := float(k) * ((span - 1.0) / 7.5)
			var ay := _arch_y(hx, span, spring, crown)
			if absf(ay - c) > 0.35:
				lm.beam("Stainless", Vector3(hx, minf(ay, c), z_rib),
					Vector3(hx, maxf(ay, c), z_rib), 0.07, 0.07)

static func _build_glass_balustrades(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	# Continuous transparent glass balustrades with brushed stainless top rail.
	var segs := 14
	for sz: float in [-1.0, 1.0]:
		var zb := sz * (half_w - 0.08)
		for i in segs:
			var x0 := lerpf(-h + 0.3, h - 0.3, float(i) / float(segs))
			var x1 := lerpf(-h + 0.3, h - 0.3, float(i + 1) / float(segs))
			lm.quad("Glass",
				Vector3(x0, c + 0.08, zb), Vector3(x1, c + 0.08, zb),
				Vector3(x1, c + 1.12, zb), Vector3(x0, c + 1.12, zb), Vector3(0, 0, sz))
			lm.quad("Glass",
				Vector3(x1, c + 0.08, zb), Vector3(x0, c + 0.08, zb),
				Vector3(x0, c + 1.12, zb), Vector3(x1, c + 1.12, zb), Vector3(0, 0, -sz))
			lm.beam("Stainless", Vector3(x0, c + 1.14, zb), Vector3(x1, c + 1.14, zb), 0.07, 0.08)
			lm.beam("Stainless", Vector3(x0, c, zb), Vector3(x0, c + 1.14, zb), 0.055, 0.055)

static func _build_night_led_glow(lm: LandmarkMesh, h: float, c: float, half_w: float) -> void:
	# Continuous under-deck LED accent strip along both girder flanks.
	var segs := 14
	var led_y := maxf(c - 0.42, 0.15)
	for sz: float in [-1.0, 1.0]:
		var zl := sz * (half_w - 0.24)
		for i in segs:
			var x0 := lerpf(-h + 2.5, h - 2.5, float(i) / float(segs))
			var x1 := lerpf(-h + 2.5, h - 2.5, float(i + 1) / float(segs))
			lm.beam("LedGlow", Vector3(x0, led_y, zl), Vector3(x1, led_y, zl), 0.12, 0.10)

static func _set_night_floods(model: Node3D, c: float) -> void:
	var ly := maxf(c * 0.75, 0.9)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, ly, 4.0), Vector3(-12.0, c, 0.0), 65.0, 0.85, 24.0, Color("#6CE0FF")],
		[Vector3(0.0, ly, -4.0), Vector3(0.0, c, 0.0), 70.0, 1.0, 28.0, Color("#7CE6FF")],
		[Vector3(12.0, ly, 4.0), Vector3(12.0, c, 0.0), 65.0, 0.85, 24.0, Color("#6CE0FF")],
	])
