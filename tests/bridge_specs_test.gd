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
	if failures.is_empty():
		print("BRIDGE SPECS OK: %d bridges, %d built" % [rows.size(), built])
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE SPECS FAIL: ", f)
		quit(1)

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
