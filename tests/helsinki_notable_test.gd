extends SceneTree

## HelsinkiNotable (offline):
## godot --headless --script tests/helsinki_notable_test.gd
## The rows are well formed and sourced, fill only what the map leaves out
## (a mapped tag wins), record their provenance, run inside the OSM parse,
## and a notable building's finish reaches the wall set the facade is drawn
## with (the district roll does not override it).

var failures: Array[String] = []

func _init() -> void:
	_rows()
	_apply()
	_parse_runs_it()
	_reaches_the_facade()
	if failures.is_empty():
		print("HELSINKI NOTABLE OK: %d rows, fill-only, provenance, parse hook, wall set" % HelsinkiNotable.ROWS.size())
		quit(0)
	else:
		for f in failures:
			printerr("HELSINKI NOTABLE FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _rows() -> void:
	_check(HelsinkiNotable.ROWS.size() >= 3, "the table must hold the curated rows")
	for id in HelsinkiNotable.ROWS:
		var row: Dictionary = HelsinkiNotable.ROWS[id]
		_check(str(id).begins_with("way:") or str(id).begins_with("relation:"), "%s is not an OSM identity" % id)
		_check(str(row.get("name", "")) != "", "%s needs a name" % id)
		_check(str(row.get("source", "")).begins_with("http"), "%s needs a source URL" % id)
		var values: Dictionary = row.get("values", {})
		_check(not values.is_empty(), "%s has no values" % id)
		var mat := str(values.get("material", ""))
		_check(mat == "" or MaterialLibrary.MATERIAL_TAGS.has(mat), "%s: unknown material %s" % [id, mat])
		var colour := str(values.get("colour", ""))
		_check(colour == "" or MaterialLibrary.parse_colour_tag(colour).a > 0.0, "%s: unreadable colour %s" % [id, colour])
		_check(not HostPolicy.is_blocked(str(row.get("source", ""))), "%s: source host is blocked" % id)

func _first_id() -> String:
	return str(HelsinkiNotable.ROWS.keys()[0])

func _apply() -> void:
	var id := _first_id()
	var values: Dictionary = HelsinkiNotable.ROWS[id]["values"]
	var bare := {"osm_id": id, "material": "", "colour": ""}
	var other := {"osm_id": "way:1", "material": "", "colour": ""}
	var mapped := {"osm_id": id, "material": "brick", "colour": "#112233"}
	var n := HelsinkiNotable.apply([bare, other, mapped, "not a building"])
	_check(n == 1 or n == 2, "only matching buildings with a gap count (got %d)" % n)
	_check(str(bare["colour"]) == str(values.get("colour", bare["colour"])), "the row fills the empty colour")
	_check(str(other["colour"]) == "" and not other.has("enriched"), "an unmatched building stays untouched")
	_check(str(mapped["material"]) == "brick" and str(mapped["colour"]) == "#112233", "a mapped tag always wins")
	var enriched: Dictionary = bare.get("enriched", {})
	_check(enriched.has(HelsinkiNotable.PROVENANCE), "the filled fields are recorded as provenance")
	var alias := {"osm_id": "way:2", "alias_ids": [id], "material": ""}
	HelsinkiNotable.apply([alias])
	_check(alias.has("enriched"), "a row also matches through an alias id")

func _parse_runs_it() -> void:
	# The hook sits in the OSM parse: a way carrying a row's id, with no
	# material or colour of its own, leaves it filled.
	var id := _first_id()
	var way := int(id.substr(4)) if id.begins_with("way:") else 0
	if way == 0:
		return
	var ring := [[60.1700, 24.9400], [60.1700, 24.9404], [60.1703, 24.9404], [60.1703, 24.9400], [60.1700, 24.9400]]
	var geometry: Array = []
	for p in ring:
		geometry.append({"lat": p[0], "lon": p[1]})
	var osm := JSON.stringify({"elements": [{"type": "way", "id": way, "nodes": [1, 2, 3, 4, 1],
		"tags": {"building": "yes"}, "geometry": geometry}]})
	var feats := OsmParser.parse_features(osm, 60.17, 24.94)
	var hit := false
	for b in feats["buildings"]:
		if (b as Dictionary).get("osm_id", "") == id:
			hit = true
			_check(str((b as Dictionary).get("colour", "")) != "" or str((b as Dictionary).get("material", "")) != "",
				"the OSM parse applies the notable row")
	_check(hit, "the synthetic way parsed into a building")

func _reaches_the_facade() -> void:
	# The wall set a notable building is drawn with is the row's finish,
	# whatever finish its district rolled, and its own colour is the paint.
	var region := "helsinki"
	for id in HelsinkiNotable.ROWS:
		var values: Dictionary = HelsinkiNotable.ROWS[id]["values"]
		var mat := str(values.get("material", ""))
		if mat == "":
			continue
		var mapped := str(MaterialLibrary.MATERIAL_TAGS[mat])
		var misses := 0
		for k in 12:
			var b := {"osm_id": id, "material": mat, "colour": str(values.get("colour", "")),
				"use": "commercial", "levels": 6.0, "x": 0.0, "z": 0.0, "start_year": int(values.get("start_year", 1905))}
			var seed_v := (float(k) + 0.5) / 12.0
			var look := ArchitectureStyle.resolve(b, region, "dense", seed_v, 900.0,
				{"cores": [Vector2.ZERO], "districts": [["helsinki_commercial", Vector2.ZERO, 500.0, 8.0]]})
			if str(look["wall_set"]) != mapped:
				misses += 1
		_check(misses == 0, "%s: the wall set must be %s for every seed (%d misses)" % [id, mapped, misses])
