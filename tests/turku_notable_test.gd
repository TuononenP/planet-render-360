extends SceneTree

## TurkuNotable & Turku district styles (offline):
## tools/godot_bg.sh --headless --path . --script tests/turku_notable_test.gd
## Verifies every TurkuNotable row is well-formed, matches a real building in
## bundled turku_detailed / turku_ring1600, fills only missing tags, records
## provenance, runs in OsmParser, and beats district randomisation.

var failures: Array[String] = []

func _init() -> void:
	_rows()
	_apply()
	_matches_bundled_osm()
	_reaches_the_facade()
	_turku_districts()
	if failures.is_empty():
		print("TURKU NOTABLE OK: %d rows verified against bundled OSM, fill-only, wall set, districts" % TurkuNotable.ROWS.size())
		quit(0)
	else:
		for f in failures:
			printerr("TURKU NOTABLE FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _rows() -> void:
	_check(TurkuNotable.ROWS.size() >= 150, "TurkuNotable should hold >= 150 rows (got %d)" % TurkuNotable.ROWS.size())
	for id in TurkuNotable.ROWS:
		var row: Dictionary = TurkuNotable.ROWS[id]
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

func _apply() -> void:
	var id := str(TurkuNotable.ROWS.keys()[0])
	var values: Dictionary = TurkuNotable.ROWS[id]["values"]
	var bare := {"osm_id": id, "material": "", "colour": ""}
	var other := {"osm_id": "way:1", "material": "", "colour": ""}
	var mapped := {"osm_id": id, "material": "wood", "colour": "#112233"}
	var n := TurkuNotable.apply([bare, other, mapped, "not a building"])
	_check(n >= 1, "matching building with a gap counts (got %d)" % n)
	_check(str(bare["colour"]) == str(values.get("colour", bare["colour"])), "row fills empty colour")
	_check(str(other["colour"]) == "" and not other.has("enriched"), "unmatched building stays untouched")
	_check(str(mapped["material"]) == "wood" and str(mapped["colour"]) == "#112233", "mapped tags always win")
	var enriched: Dictionary = bare.get("enriched", {})
	_check(enriched.has(TurkuNotable.PROVENANCE), "filled fields recorded as provenance")

func _matches_bundled_osm() -> void:
	var found := {}
	var enriched_in_parse := 0
	for key in ["turku_detailed", "turku_ring1600"]:
		var text := BundledOsm.read(key)
		var feats := OsmParser.parse_features(text, 60.4518, 22.2666)
		for b in feats["buildings"]:
			var bd := b as Dictionary
			for oid in OsmParser.ids_of(bd):
				if TurkuNotable.ROWS.has(oid):
					if not found.has(oid):
						found[oid] = true
						if (bd.get("enriched", {}) as Dictionary).has(TurkuNotable.PROVENANCE):
							enriched_in_parse += 1
	var missing: Array[String] = []
	for id in TurkuNotable.ROWS:
		if not found.has(id):
			missing.append(str(id))
	_check(missing.is_empty(), "%d TurkuNotable IDs missing from bundled OSM: %s" % [missing.size(), ", ".join(missing.slice(0, 10))])
	_check(enriched_in_parse >= 140, "OsmParser applies TurkuNotable to bundled Turku buildings (got %d)" % enriched_in_parse)

func _reaches_the_facade() -> void:
	var checked := 0
	for id in TurkuNotable.ROWS:
		if checked >= 20:
			break
		var values: Dictionary = TurkuNotable.ROWS[id]["values"]
		var mat := str(values.get("material", ""))
		if mat == "":
			continue
		checked += 1
		var mapped := str(MaterialLibrary.MATERIAL_TAGS[mat])
		var misses := 0
		for k in 8:
			var b := {"osm_id": id, "material": mat, "colour": str(values.get("colour", "")),
				"use": "commercial", "levels": 5.0, "x": 0.0, "z": 0.0, "start_year": int(values.get("start_year", 1910))}
			var look := ArchitectureStyle.resolve(b, "turku", "dense", (float(k) + 0.5) / 8.0, 600.0,
				{"cores": [Vector2.ZERO], "districts": [["turku_commercial", Vector2.ZERO, 450.0, 9.0]]})
			if str(look["wall_set"]) != mapped:
				misses += 1
		_check(misses == 0, "%s: wall set must be %s for every seed (%d misses)" % [id, mapped, misses])

func _turku_districts() -> void:
	var f_comm := CityStyles.local_frame("turku", 60.4515, 22.2666)
	var comm := BuildingEra.refine("turku", "commercial", {"x": 0.0, "z": 0.0, "levels": 5, "start_year": 1965}, f_comm, 0.5, 500.0)
	_check(comm == "turku_commercial", "Kauppatori 1965 commercial resolves to turku_commercial (got %s)" % comm)
	var jugend_in_comm := BuildingEra.refine("turku", "apartments", {"x": 0.0, "z": 0.0, "levels": 5, "start_year": 1908}, f_comm, 0.5, 500.0)
	_check(jugend_in_comm == "turku_jugend", "Kauppatori 1908 block resolves to turku_jugend (got %s)" % jugend_in_comm)
	var f_tyks := CityStyles.local_frame("turku", 60.4525, 22.2935)
	var tyks := BuildingEra.refine("turku", "civic", {"x": 0.0, "z": 0.0, "levels": 6, "start_year": 2022}, f_tyks, 0.5, 1200.0)
	_check(tyks == "turku_campus", "TYKS Hospital resolves to turku_campus (got %s)" % tyks)
	var f_jug := CityStyles.local_frame("turku", 60.4538, 22.2610)
	var jug := BuildingEra.refine("turku", "apartments", {"x": 0.0, "z": 0.0, "levels": 5, "start_year": 1910}, f_jug, 0.5, 400.0)
	_check(jug == "turku_jugend", "Puolalanmäki 1910 block resolves to turku_jugend (got %s)" % jug)
