extends SceneTree

## Capital bridge tables: godot --headless --script tests/bridge_specs_test.gd
## Offline. Every row of BridgeSpecs is sound (schema, plausible numbers, a
## known capital country within MAX_CAPITAL_KM of a capital of its country),
## becomes a secondary registry entry whose name finds it only near its site,
## and builds a bounded model: 2..16 merged parts, at most BridgeParam.MAX_TRIS
## triangles, nothing under the water, the right length and the height the
## table implies.

## A bridge belongs to a capital when it lies this close to one of its country.
const MAX_CAPITAL_KM := 12.0
## Cities with bridge rows that are not capitals: {cc: [[lat, lon]]}.
const OTHER_CITIES := {"FI": [[60.4518, 22.2666]]}  # Turku
var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var capitals := {}
	for row in CapitalCatalog.ROWS:
		var list: Array = capitals.get(str(row[0]), [])
		list.append(Vector2(float(row[3]), float(row[4])))
		capitals[str(row[0])] = list
	for cc: String in OTHER_CITIES:
		for at: Array in OTHER_CITIES[cc]:
			(capitals[cc] as Array).append(Vector2(float(at[0]), float(at[1])))
	var seen := {}
	var built := 0
	var rows := BridgeSpecs.all()
	for row in rows:
		var id := str(row.get("id", "?"))
		for problem in BridgeSpec.validate(row, capitals):
			failures.append(problem)
		if seen.has(id):
			failures.append("duplicate bridge id %s" % id)
		seen[id] = true
		if not row.has("lat") or not row.has("cc"):
			continue
		_check_capital(row, capitals)
		if int(row["conf"]) < BridgeSpec.MIN_BUILT_CONF:
			_check(LocationData.entry_for_type(id).is_empty(), "%s is below the confidence floor but registered" % id)
			continue
		built += 1
		_check_entry(row)
		_check_model(row)
		_check_fitted(row)
	_check_span_ends()
	if failures.is_empty():
		print("BRIDGE SPECS OK: %d bridges, %d built, fitted models up to %d triangles" % [rows.size(), built, most_fitted_tris])
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE SPECS FAIL: ", f)
		quit(1)

## A parametric model's deck stops at its span's ends, so a mapped deck
## running on past them (Pont d'Arcole's branches onto its quay) is kept,
## while one on the span or beside it within clear_m is the model's.
func _check_span_ends() -> void:
	var entry := LocationData.entry_for_type("br_paris_pont_d_arcole")
	if entry.is_empty():
		failures.append("Pont d'Arcole should be registered")
		return
	var a := LandmarkSites.axis(entry)
	var across := Vector2(-a.y, a.x)
	var half := float(entry["span_m"]) * 0.5
	var spans := [[Vector2.ZERO, entry]]
	var line := PackedVector2Array()
	for k in 61:
		line.append(a * (-half + float(k) * (2.0 * half + 10.0) / 60.0))
	var runs := LandmarkSites.outside_spans(line, spans)
	_check(runs.size() == 1 and (runs[0] as PackedVector2Array)[0].dot(a) > half,
		"a deck past the span's end should be kept from the end on: %s" % [runs])
	_check(LandmarkSites.on_span(a * half * 0.5 + across * 8.0, Vector2.ZERO, entry),
		"a deck beside the span within clear_m is the model's")
	_check(not LandmarkSites.on_span(a * (half + 6.0), Vector2.ZERO, entry),
		"a deck 6 m past the span's end is not the model's")
	_check_seated(entry)

## Over a river with banks lower than the row's clearance, the model is
## built with its deck at the banks past its ends (still standing on the
## water, never sunk), a bridge far over its banks keeps its own height,
## and a mapped deck going on from the model's end is its landing.
func _check_seated(arcole: Dictionary) -> void:
	var entry := arcole.duplicate()
	entry["yaw_deg"] = 0.0
	var half := float(entry["span_m"]) * 0.5
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.latitude = 48.8555
	d.longitude = 2.3506
	d.land_polygons = [{"class": "water", "holes": [], "points": PackedVector2Array([
		Vector2(-half + 4.0, -300), Vector2(half - 4.0, -300), Vector2(half - 4.0, 300), Vector2(-half + 4.0, 300)])}]
	var ground := GroundTruth.new(d)
	var water := ground.water_level_at(0.0, 0.0)
	var y := TerrainBuilder._hero_y(d, ground, 0.0, 0.0, entry, 10.0)
	_check(absf(y - water) < 0.01, "a spec bridge stands on the water, %.2f off it" % (y - water))
	var bank := maxf(ground.height_at_world(half + 6.0, 0.0), ground.height_at_world(-half - 6.0, 0.0))
	var fit := TerrainBuilder.landing_clear_m(ground, Vector2.ZERO, entry, y)
	_check(not is_nan(fit) and absf(fit - maxf(bank - water, TerrainBuilder.DECK_MIN_AIR_M)) < 0.6,
		"a spec bridge's deck should meet its banks: deck %.2f, banks %.2f over the water" % [fit, bank - water])
	var high := entry.duplicate()
	high["deck_m"] = 40.0
	_check(is_nan(TerrainBuilder.landing_clear_m(ground, Vector2.ZERO, high, y)),
		"a high-level bridge keeps its own height")
	var hand := entry.duplicate()
	hand.erase("deck_ends")
	_check(is_nan(TerrainBuilder.landing_clear_m(ground, Vector2.ZERO, hand, y)),
		"a hand-built bridge keeps its own height")
	if not is_nan(fit):
		var root := LandmarkBuilder.build_bridge("br_paris_pont_d_arcole", fit)
		var top := -INF
		var low := INF
		for mi in LandmarkBuilder.parts(root):
			var box := mi.get_aabb()
			top = maxf(top, box.end.y)
			low = minf(low, box.position.y)
		var camber := float(BridgeSpec.fitted(BridgeSpecs.row_for("br_paris_pont_d_arcole"), fit)["camber"])
		_check(camber > 0.5 and camber * BridgeCamber.LIFT_STEEPEST <= BridgeSpec.DECK_GRADE * half + 0.01,
			"a bridge fitted to low banks humps within its grade, got %.2f m" % camber)
		_check(absf(top - (fit + camber + BridgeSpec.PARAPET_M)) < 0.3 and low > -0.01,
			"the fitted model's railing tops out at %.2f m (deck %.2f + hump %.2f), lowest %.2f" % [top, fit, camber, low])
		root.free()
		# Banks of unequal height: the +X end stands `tilt` higher, the -X end lower.
		var tilted := LandmarkBuilder.build_bridge("br_paris_pont_d_arcole", 4.0, 1.5)
		var hi := -INF
		var lo_end := -INF
		for mi in LandmarkBuilder.parts(tilted):
			if mi.name != "Deck":
				continue
			var vs: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for v in vs:
				if v.x > half - 0.5:
					hi = maxf(hi, v.y)
				if v.x < -half + 0.5:
					lo_end = maxf(lo_end, v.y)
		_check(absf(hi - 5.5) < 0.2 and absf(lo_end - 2.5) < 0.2,
			"a tilted deck should stand 5.5 m and 2.5 m at its ends, got %.2f and %.2f" % [hi, lo_end])
		tilted.free()
		# The hump leaves the ends at the banks' height and the feet on the water.
		_check(BridgeCamber.lift(half, half, camber) < 0.001 and absf(BridgeCamber.lift(0.0, half, camber) - camber) < 0.001,
			"the hump is none at the ends and whole at mid-span")
		var end_grade := (BridgeCamber.lift(half * 0.98, half, camber) - BridgeCamber.lift(half, half, camber)) / (half * 0.02)
		_check(end_grade < 0.005, "the hump meets the road level, got a %.3f grade at its end" % end_grade)
		var ramp_end := (BridgeCamber.ramp(half, half, 1.5) - BridgeCamber.ramp(half * 0.98, half, 1.5)) / (half * 0.02)
		_check(absf(BridgeCamber.ramp(half, half, 1.5) - 1.5) < 0.001 and ramp_end < 0.005,
			"the tilt meets each road level, got a %.3f grade at its end" % ramp_end)
		# Hump and tilt together stay under the deck's steepest grade.
		var both := LandmarkBuilder.build_bridge("br_paris_pont_d_arcole", 3.0, 0.8, 0.5)
		var tops := {}
		for mi in LandmarkBuilder.parts(both):
			if mi.name != "Deck":
				continue
			var vs: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for v in vs:
				if absf(v.x) <= half:
					var bin := int(floorf(v.x / 2.0))
					tops[bin] = maxf(float(tops.get(bin, -INF)), v.y)
		var steepest := 0.0
		for bin: int in tops:
			if tops.has(bin + 1):
				steepest = maxf(steepest, absf(float(tops[bin + 1]) - float(tops[bin])) / 2.0)
		_check(tops.size() > 4 and steepest <= BridgeSpec.DECK_GRADE + 0.01,
			"a humped, tilted deck should stay under a %.2f grade, got %.3f" % [BridgeSpec.DECK_GRADE, steepest])
		both.free()
	var a := LandmarkSites.axis(entry)
	var spans := [[Vector2.ZERO, entry]]
	_check(LandmarkSites.lands_at_span(PackedVector2Array([a * (half + 1.5), a * (half + 1.5) + Vector2(6, 8)]), spans),
		"a deck going on from the model's end is its landing")
	_check(not LandmarkSites.lands_at_span(PackedVector2Array([a * (half + 60.0), a * (half + 80.0)]), spans),
		"a deck 60 m past the model's end is not its landing")

func _check_capital(row: Dictionary, capitals: Dictionary) -> void:
	var best := INF
	for c in capitals.get(str(row["cc"]), []):
		best = minf(best, LocationData.distance_m(float(row["lat"]), float(row["lon"]), c.x, c.y))
	_check(best <= MAX_CAPITAL_KM * 1000.0, "%s is %.1f km from the nearest %s capital (max %.0f)" % [
		row["id"], best / 1000.0, row["cc"], MAX_CAPITAL_KM])

func _check_entry(row: Dictionary) -> void:
	var id := str(row["id"])
	var entry := LocationData.entry_for_type(id)
	if entry.is_empty():
		failures.append("%s is not in the registry" % id)
		return
	_check(bool(entry.get("secondary", false)) and str(entry.get("kind", "")) == "Bridge",
		"%s should be a secondary Bridge entry" % id)
	_check(absf(float(entry["span_m"]) - BridgeSpec.length_m(row)) < 0.2, "%s span_m should be the spans' sum" % id)
	var lat := float(row["lat"])
	var lon := float(row["lon"])
	# Never a city centre's primary icon, but found by name beside it.
	_check(LocationData.landmark_for(lat, lon, "") != id, "%s must not be the primary landmark of its own site" % id)
	_check(LocationData.landmark_for(lat, lon, str(row["name"])) == id, "searching '%s' should find it" % row["name"])
	# The same name elsewhere on Earth is not this bridge.
	_check(LocationData.landmark_for(lat + 5.0, lon, str(row["name"])) != id,
		"%s answers its name 500 km away" % id)

## Every bank-to-bank row, built down to low banks (TerrainBuilder.
## landing_clear_m, 2 m and 3.5 m over the water): the humped model keeps
## its length and width, stands wholly over the water, tops out where its
## fitted row and hump say, and stays within FITTED_TRIS (the hump cuts
## long triangles along the bridge).
const FITTED_TRIS := 3 * BridgeParam.MAX_TRIS
var most_fitted_tris := 0

func _check_fitted(row: Dictionary) -> void:
	if float(row["clear"]) > TerrainBuilder.LANDING_FIT_CLEAR_M:
		return
	var id := str(row["id"])
	for deck: float in [2.0, 3.5]:
		var fit := BridgeSpec.fitted(row, deck)
		var camber := float(fit.get("camber", 0.0))
		_check(camber >= 0.0 and camber * BridgeCamber.LIFT_STEEPEST <= BridgeSpec.DECK_GRADE * BridgeSpec.length_m(row) * 0.5 + 0.001,
			"%s humps %.2f m at a %.1f m deck, over its grade" % [id, camber, deck])
		var root := LandmarkBuilder.build_bridge(id, deck)
		var tris := 0
		var box := AABB()
		var first := true
		for m in LandmarkBuilder.parts(root):
			tris += m.mesh.surface_get_array_len(0) / 3
			var b := m.transform * m.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		most_fitted_tris = maxi(most_fitted_tris, tris)
		_check(tris <= FITTED_TRIS, "%s fitted to %.1f m has %d triangles (max %d)" % [id, deck, tris, FITTED_TRIS])
		_check(box.position.y > -0.05, "%s fitted to %.1f m reaches %.2f m below the water" % [id, deck, box.position.y])
		var top := BridgeSpec.model_top(fit)
		_check(box.end.y >= float(fit["clear"]) + camber - 0.05 and box.end.y <= top + camber + maxf(1.0, top * 0.03),
			"%s fitted to %.1f m (hump %.2f) should stand about %.1f m, got %.1f m" % [id, deck, camber, top + camber, box.end.y])
		var length := BridgeSpec.length_m(row)
		_check(box.size.x >= length * 0.98 and box.size.x <= length * 1.04 + 2.0,
			"%s fitted to %.1f m should be %.0f m long, got %.0f m" % [id, deck, length, box.size.x])
		_check(box.size.z >= float(row["width"]) * 0.9,
			"%s fitted to %.1f m should be %.0f m wide, got %.0f m" % [id, deck, row["width"], box.size.z])
		root.free()

func _check_model(row: Dictionary) -> void:
	var id := str(row["id"])
	if not LandmarkBuilder.is_bespoke(id):
		failures.append("%s has no builder" % id)
		return
	var root := LandmarkBuilder.build(id)
	var parts := LandmarkBuilder.parts(root)
	_check(parts.size() >= 2 and parts.size() <= 16, "%s should be 2..16 parts, got %d" % [id, parts.size()])
	var tris := 0
	var box := AABB()
	var first := true
	for m in parts:
		tris += m.mesh.surface_get_array_len(0) / 3
		var b := m.transform * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	_check(tris <= BridgeParam.MAX_TRIS, "%s has %d triangles (max %d)" % [id, tris, BridgeParam.MAX_TRIS])
	_check(box.position.y > -0.05, "%s reaches %.2f m below the water" % [id, box.position.y])
	var top := BridgeSpec.model_top(row)
	_check(absf(box.end.y - top) <= maxf(1.0, top * 0.03), "%s should stand %.1f m, got %.1f m" % [id, top, box.end.y])
	var length := BridgeSpec.length_m(row)
	_check(box.size.x >= length * 0.98 and box.size.x <= length * 1.04 + 2.0,
		"%s should be %.0f m long, got %.0f m" % [id, length, box.size.x])
	_check(box.size.z >= float(row["width"]) * 0.9, "%s should be %.0f m wide, got %.0f m" % [id, row["width"], box.size.z])
	root.free()
