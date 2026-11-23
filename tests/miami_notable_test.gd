extends SceneTree

## MiamiNotable (offline):
## tools/godot_bg.sh --headless --path . --script tests/miami_notable_test.gd
## The rows are well formed and sourced, every key exists in the bundled
## Miami snapshots, a row fills only what the map leaves out (a mapped tag
## wins), records its provenance, and its finish wins over the district roll.

var failures: Array[String] = []

func _init() -> void:
	_rows()
	_apply()
	_matches_bundled_osm()
	_reaches_the_facade()
	if failures.is_empty():
		print("MIAMI NOTABLE OK: %d rows, bundled OSM, fill-only, provenance, wall set" % MiamiNotable.ROWS.size())
		quit(0)
	else:
		for f in failures:
			printerr("MIAMI NOTABLE FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _rows() -> void:
	_check(MiamiNotable.ROWS.size() >= 115, "the table must hold >= 115 curated rows (got %d)" % MiamiNotable.ROWS.size())
	for id in MiamiNotable.ROWS:
		var row: Dictionary = MiamiNotable.ROWS[id]
		_check(str(id).begins_with("way:") or str(id).begins_with("relation:"), "%s is not an OSM identity" % id)
		_check(str(row.get("name", "")) != "", "%s needs a name" % id)
		_check(str(row.get("address", "")) != "", "%s needs an address" % id)
		_check(str(row.get("source", "")).begins_with("https://"), "%s needs an https source URL" % id)
		_check(not HostPolicy.is_blocked(str(row.get("source", ""))), "%s: source host is blocked" % id)
		var values: Dictionary = row.get("values", {})
		_check(not values.is_empty(), "%s has no values" % id)
		var mat := str(values.get("material", ""))
		_check(mat == "" or MaterialLibrary.MATERIAL_TAGS.has(mat), "%s: unknown material %s" % [id, mat])
		var colour := str(values.get("colour", ""))
		_check(colour == "" or MaterialLibrary.parse_colour_tag(colour).a > 0.0, "%s: unreadable colour %s" % [id, colour])
		_check(int(values.get("start_year", 0)) > 1800, "%s needs a start_year" % id)

func _apply() -> void:
	var id := str(MiamiNotable.ROWS.keys()[0])
	var values: Dictionary = MiamiNotable.ROWS[id]["values"]
	var bare := {"osm_id": id, "material": "", "colour": "", "start_year": 0}
	var other := {"osm_id": "way:1", "material": "", "colour": ""}
	var mapped := {"osm_id": id, "material": "brick", "colour": "#112233", "start_year": 1999}
	var n := MiamiNotable.apply([bare, other, mapped, "not a building"])
	_check(n == 1 or n == 2, "only matching buildings with a gap count (got %d)" % n)
	_check(str(bare["colour"]) == str(values["colour"]), "the row fills the empty colour")
	_check(str(bare["material"]) == str(values["material"]), "the row fills the empty material")
	_check(int(bare["start_year"]) == int(values["start_year"]), "the row fills the missing start_year")
	_check(str(other["colour"]) == "" and not other.has("enriched"), "an unmatched building stays untouched")
	_check(str(mapped["material"]) == "brick" and str(mapped["colour"]) == "#112233" and int(mapped["start_year"]) == 1999, "a mapped tag always wins")
	_check((bare.get("enriched", {}) as Dictionary).has(MiamiNotable.PROVENANCE), "the filled fields are recorded as provenance")
	var alias := {"osm_id": "way:2", "alias_ids": [id], "material": ""}
	MiamiNotable.apply([alias])
	_check(alias.has("enriched"), "a row also matches through an alias id")

func _matches_bundled_osm() -> void:
	var found := {}
	for key: String in ["miami_detailed", "miami_beach_detailed"]:
		var lat := 25.7743 if key == "miami_detailed" else 25.7810
		var lon := -80.1855 if key == "miami_detailed" else -80.1300
		var feats := OsmParser.parse_features(BundledOsm.read(key), lat, lon)
		for b in feats["buildings"]:
			for oid in OsmParser.ids_of(b as Dictionary):
				found[oid] = true
	var missing: Array[String] = []
	for id in MiamiNotable.ROWS:
		if not found.has(id):
			missing.append(str(id))
	_check(missing.is_empty(), "%d MiamiNotable IDs missing from bundled OSM: %s" % [missing.size(), ", ".join(missing.slice(0, 10))])

func _reaches_the_facade() -> void:
	for id in MiamiNotable.ROWS:
		var values: Dictionary = MiamiNotable.ROWS[id]["values"]
		var mat := str(values.get("material", ""))
		if mat == "":
			continue
		var mapped := str(MaterialLibrary.MATERIAL_TAGS[mat])
		var misses := 0
		for k: int in 6:
			var b := {"osm_id": id, "material": mat, "colour": str(values.get("colour", "")),
				"use": "commercial", "levels": 6.0, "x": 0.0, "z": 0.0, "start_year": int(values.get("start_year", 1935))}
			var look := ArchitectureStyle.resolve(b, "miami", "dense", (float(k) + 0.5) / 6.0, 900.0,
				{"cores": [Vector2.ZERO], "districts": [["miami_commercial", Vector2.ZERO, 500.0, 8.0]]})
			if str(look["wall_set"]) != mapped:
				misses += 1
		_check(misses == 0, "%s: the wall set must be %s for every seed (%d misses)" % [id, mapped, misses])
