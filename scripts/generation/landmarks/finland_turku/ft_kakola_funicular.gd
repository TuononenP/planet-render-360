class_name FtKakolaFunicular
extends RefCounted

## Kakolan funikulaari (2019, Leitner): Turku's inclined railway lift climbing
## Kakolanmäki from Linnankatu 55b to Graniittilinnankatu 3. Built along +X
## ascending NNW (yaw_deg = 239.4°, bearing 329.4°, y = 0 at lower station
## Linnankatu ground datum, rising 30.0 m over 128.0 m horizontal run):
##   - Plan: -64.0..+64.0 m along X (131.5 m sloped track, 13.2° incline),
##     6.8 m station width, height_m = 34.6 m (upper station roof above lower datum).
##   - Signature features:
##     1. Lower Linnankatu glass pavilion (-64 m, y = 0): dark-steel frame,
##        panoramic glazing, cantilevered flat canopy roof, concrete plinth.
##     2. Inclined steel guideway track: twin running rails on dark steel I-beams,
##        rhythmic concrete piers / granite hill footings, service catwalk & rails.
##     3. Upper Kakolanmäki station (+64 m, y = +30.0 m): dark-steel & glass
##        hilltop pavilion seated on a deep concrete/granite retaining abutment.
##     4. Angled funicular cabin mid-slope (-8 m, y = 13.1 m): level dark-metal
##        and glass passenger cabin on a 13.2° wedged bogie undercarriage, Föli
##        saffron-yellow accent band, and warm interior night glow.
## Surfaces: 7 merged PBR parts (Steel, Concrete, Granite, Glass, Accent, Deck, Lamp).

const RUN_HALF := 64.0
const RISE_M := 30.0
const CABIN_X := -8.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_lower_station(lm)
	_build_upper_station(lm)
	_build_inclined_track(lm)
	_build_funicular_cabin(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Steel", LandmarkMaterials.paint("#2E343B", 0.40, 0.56))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B4B2AA", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#867D76", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#4A6A78"))
	lm.use("Accent", LandmarkMaterials.paint("#F5A800", 0.42, 0.14))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#6E7276", 2.2))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEAC0", 2.0))

static func _track_y(x: float) -> float:
	return RISE_M * clampf((x + RUN_HALF) / (RUN_HALF * 2.0), 0.0, 1.0)

static func _build_lower_station(lm: LandmarkMesh) -> void:
	# Linnankatu 55b glass-and-steel pavilion seated with -2.5 m foundation drop.
	var cx := -RUN_HALF - 2.6
	var w := 6.2
	var d := 5.6
	var h := 4.1
	lm.box("Concrete", Vector3(cx, -1.20, 0.0), Vector3(w + 1.0, 2.50, d + 1.0))
	lm.box("Deck", Vector3(cx, 0.10, 0.0), Vector3(w + 0.6, 0.16, d + 0.6))
	# Cantilevered flat dark-steel roof canopy + warm soffit light panel.
	lm.box("Steel", Vector3(cx, h, 0.0), Vector3(w + 1.2, 0.34, d + 1.2))
	lm.box("Lamp", Vector3(cx, h - 0.22, 0.0), Vector3(w * 0.72, 0.08, d * 0.64))
	# Corner & intermediate dark-steel mullions + wraparound glazing.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(cx + sx * (w * 0.48), h * 0.5, sz * (d * 0.48)), Vector3(0.24, h, 0.24))
	for sz: float in [-1.0, 1.0]:
		lm.box("Glass", Vector3(cx, h * 0.5, sz * (d * 0.47)), Vector3(w - 0.3, h - 0.45, 0.08))
	lm.box("Glass", Vector3(cx - w * 0.47, h * 0.5, 0.0), Vector3(0.08, h - 0.45, d - 0.3))
	# Signature Föli yellow signage fascia band over entrance.
	lm.box("Accent", Vector3(cx - w * 0.52, h - 0.02, 0.0), Vector3(0.14, 0.24, d * 0.75))

static func _build_upper_station(lm: LandmarkMesh) -> void:
	# Graniittilinnankatu 3 hilltop station seated into Kakolanmäki granite crag.
	var cx := RUN_HALF + 2.8
	var y0 := RISE_M
	var w := 6.6
	var d := 5.8
	var h := 4.4
	# Deep granite/concrete retaining abutment down into hillside.
	lm.box("Granite", Vector3(cx, y0 - 3.5, 0.0), Vector3(w + 1.4, 7.1, d + 1.4))
	lm.box("Deck", Vector3(cx, y0 + 0.10, 0.0), Vector3(w + 0.8, 0.18, d + 0.8))
	# Roof canopy (top at y = 30.0 + 4.4 + 0.20 = 34.60 m).
	lm.box("Steel", Vector3(cx, y0 + h, 0.0), Vector3(w + 1.2, 0.40, d + 1.2))
	lm.box("Lamp", Vector3(cx, y0 + h - 0.24, 0.0), Vector3(w * 0.74, 0.08, d * 0.66))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(cx + sx * (w * 0.48), y0 + h * 0.5, sz * (d * 0.48)), Vector3(0.26, h, 0.26))
	for sz: float in [-1.0, 1.0]:
		lm.box("Glass", Vector3(cx, y0 + h * 0.5, sz * (d * 0.47)), Vector3(w - 0.3, h - 0.50, 0.08))
	lm.box("Glass", Vector3(cx + w * 0.47, y0 + h * 0.5, 0.0), Vector3(0.08, h - 0.50, d - 0.3))
	lm.box("Accent", Vector3(cx + w * 0.52, y0 + h - 0.02, 0.0), Vector3(0.14, 0.24, d * 0.75))

static func _build_inclined_track(lm: LandmarkMesh) -> void:
	# Sloped steel guideway, twin running rails, haulage cable, and service catwalk.
	var p0 := Vector3(-RUN_HALF, 0.35, 0.0)
	var p1 := Vector3(RUN_HALF, RISE_M + 0.35, 0.0)
	var slope_len := p0.distance_to(p1)
	var rot := Basis(Vector3.BACK, atan2(RISE_M, RUN_HALF * 2.0))
	var mid := (p0 + p1) * 0.5
	# Twin main steel track girders + running rails (gauge ~1.6 m).
	for sz: float in [-0.82, 0.82]:
		lm.beam("Steel", p0 + Vector3(0.0, 0.0, sz), p1 + Vector3(0.0, 0.0, sz), 0.38, 0.26)
		lm.beam("Deck", p0 + Vector3(0.0, 0.24, sz), p1 + Vector3(0.0, 0.24, sz), 0.12, 0.10)
	# Central haulage cable & guideway spine.
	lm.beam("Steel", p0 + Vector3(0.0, 0.16, 0.0), p1 + Vector3(0.0, 0.16, 0.0), 0.07, 0.07)
	# Side service catwalk deck + handrail along +Z side.
	lm.box("Deck", mid + Vector3(0.0, -0.02, 1.55), Vector3(slope_len, 0.12, 0.95), rot)
	lm.beam("Steel", p0 + Vector3(0.0, 1.05, 1.98), p1 + Vector3(0.0, 1.05, 1.98), 0.06, 0.06)
	# Rhythmic concrete support piers + cross-ties seated deep into the granite slope.
	var piers := 14
	for i in piers + 1:
		var x := lerpf(-RUN_HALF + 2.0, RUN_HALF - 2.0, float(i) / float(piers))
		var ty := _track_y(x) + 0.20
		lm.box("Steel", Vector3(x, ty - 0.10, 0.35), Vector3(0.28, 0.26, 3.2))
		# Vertical concrete pier extending 5.5 m down into Kakolanmäki rock slope.
		lm.box("Concrete", Vector3(x, ty - 2.95, 0.0), Vector3(0.75, 5.5, 2.2))
		lm.box("Granite", Vector3(x, ty - 5.2, 0.0), Vector3(1.15, 1.4, 2.6))
		# Catwalk railing stanchion.
		lm.beam("Steel", Vector3(x, ty + 0.12, 1.98), Vector3(x, ty + 1.20, 1.98), 0.05, 0.05)

static func _build_funicular_cabin(lm: LandmarkMesh) -> void:
	# Angled funicular bogie undercarriage + level panoramic passenger cabin.
	var cy := _track_y(CABIN_X) + 0.55
	var slope := atan2(RISE_M, RUN_HALF * 2.0)
	var bogie_rot := Basis(Vector3.BACK, slope)
	# Bogie chassis aligned to track gradient + wedge leveling truss.
	lm.box("Steel", Vector3(CABIN_X, cy + 0.22, 0.0), Vector3(5.6, 0.34, 2.1), bogie_rot)
	var wedge := PackedVector2Array([
		Vector2(CABIN_X - 2.6, cy + 0.35 - 2.6 * tan(slope)),
		Vector2(CABIN_X + 2.6, cy + 0.35 + 2.6 * tan(slope)),
		Vector2(CABIN_X + 2.6, cy + 1.05),
		Vector2(CABIN_X - 2.6, cy + 1.05),
	])
	LandmarkBrKit.extrude_xy(lm, "Steel", wedge, -1.15, 1.15)
	# Horizontal dark-metal & panoramic glass cabin body (5.2 m x 2.75 m x 2.65 m).
	var floor_y := cy + 1.05
	var cab_h := 2.65
	lm.box("Steel", Vector3(CABIN_X, floor_y + 0.12, 0.0), Vector3(5.2, 0.24, 2.75))
	lm.box("Steel", Vector3(CABIN_X, floor_y + cab_h, 0.0), Vector3(5.3, 0.22, 2.82))
	# Wraparound dark-tinted cabin glass + warm interior light core.
	lm.box("Glass", Vector3(CABIN_X, floor_y + cab_h * 0.52, 0.0), Vector3(5.05, cab_h - 0.38, 2.62))
	lm.box("Lamp", Vector3(CABIN_X, floor_y + cab_h * 0.56, 0.0), Vector3(4.3, 1.35, 1.95))
	# Corner window mullions + signature Föli saffron-yellow lower accent stripe.
	for sx: float in [-2.52, -0.85, 0.85, 2.52]:
		for sz: float in [-1.32, 1.32]:
			lm.box("Steel", Vector3(CABIN_X + sx, floor_y + cab_h * 0.5, sz), Vector3(0.14, cab_h, 0.14))
	for sz: float in [-1.38, 1.38]:
		lm.box("Accent", Vector3(CABIN_X, floor_y + 0.32, sz), Vector3(5.15, 0.22, 0.06))

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		{"at": Vector3(-RUN_HALF - 2.6, 3.2, 0.0), "range": 18.0, "energy": 2.2, "colour": Color("#FFE8BE")},
		{"at": Vector3(CABIN_X, _track_y(CABIN_X) + 3.0, 0.0), "range": 16.0, "energy": 2.0, "colour": Color("#FFE8BE")},
		{"at": Vector3(RUN_HALF + 2.8, RISE_M + 3.5, 0.0), "range": 18.0, "energy": 2.2, "colour": Color("#FFE8BE")},
	])
