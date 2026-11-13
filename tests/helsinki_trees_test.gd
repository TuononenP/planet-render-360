extends SceneTree

## HelsinkiTrees (offline): godot --headless --script tests/helsinki_trees_test.gd
## Decoding a trimmed real WFS answer, size classes, the 3 m dedupe
## against OSM trees (mapped tags win), the High / Ultra gate on
## register-only trees, and the boreal genus models.

const FIXTURE := "res://tests/fixtures/helsinki_trees_sample.json"
const C_LAT := 60.172
const C_LON := 24.950

var failures: Array[String] = []

func _init() -> void:
	var rows: Variant = HelsinkiTrees.decode(FileAccess.get_file_as_string(FIXTURE))
	_check(rows is Array and (rows as Array).size() == 15, "The fixture must decode to 15 trees")
	if rows is Array:
		_rows(rows)
	_heights()
	_species()
	if failures.is_empty():
		print("HELSINKI TREES OK: decode, sizes, dedupe, gate, species")
		quit(0)
	else:
		for f in failures:
			printerr("HELSINKI TREES FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _rows(rows: Array) -> void:
	var r0: Dictionary = rows[0]
	_check(r0["genus"] == "tilia" and r0["species"].begins_with("tilia") and r0["height_m"] == 14.0,
		"Row 0 must be a 30–50 cm lime, 14 m")
	_check(r0["street"] == true, "Katu trees are street trees")
	var p0 := Gk25.to_xz(float(r0["e"]), float(r0["n"]), C_LAT, C_LON)
	var p1 := Gk25.to_xz(float(rows[1]["e"]), float(rows[1]["n"]), C_LAT, C_LON)
	# OSM tree 1 m from register tree 0, with its own genus; another
	# untagged 2 m from tree 1.
	var osm: Array = [
		{"x": p0.x + 1.0, "z": p0.y, "genus": "betula"},
		{"x": p1.x, "z": p1.y + 2.0},
	]
	var original := osm.duplicate(true)
	var stats := {}
	var merged := HelsinkiTrees.merge(osm, C_LAT, C_LON, rows, false, stats)
	_check(osm.size() == original.size(), "merge must not grow the input array (parse cache)")
	_check(merged.size() == 2 and int(stats["added"]) == 0, "Without add_new nothing is planted")
	_check(merged[0]["genus"] == "betula" and merged[0]["height_m"] == 14.0,
		"A mapped genus wins; the register adds the missing height")
	_check(str(merged[1]["genus"]) == str(rows[1]["genus"]), "An untagged OSM tree takes the register genus")
	var inside := 0
	var half := WorldScale.DETAILED_EXTENT_M * 0.5
	for r in rows:
		var p := Gk25.to_xz(float(r["e"]), float(r["n"]), C_LAT, C_LON)
		if absf(p.x) <= half and absf(p.y) <= half:
			inside += 1
	var grown := HelsinkiTrees.merge(original, C_LAT, C_LON, rows, true, stats)
	_check(inside > 2 and inside < rows.size(), "The fixture must straddle the extent edge (%d inside)" % inside)
	_check(grown.size() == inside and int(stats["added"]) == inside - 2,
		"With add_new the unmatched register trees inside the extent are planted (got %d of %d)" % [int(stats["added"]), inside - 2])
	_check(str((grown[grown.size() - 1] as Dictionary).get("source", "")) == HelsinkiTrees.SOURCE,
		"Planted register trees carry their source")

func _heights() -> void:
	_check(HelsinkiTrees.height_for("0 - 10 cm", 0) == 4.5, "0–10 cm is 4.5 m")
	_check(HelsinkiTrees.height_for("70 cm -", 0) == 22.0, "70+ cm is 22 m")
	_check(HelsinkiTrees.height_for("50 - 70 cm", 2024) == HelsinkiTrees.YOUNG_MAX_M, "Young plantings cap")
	_check(HelsinkiTrees.height_for("", 0) == 0.0, "An unknown class gives no height")

func _species() -> void:
	_check(TreeSpecies.species_from_tags({"genus": "acer"}, "boreal") == "maple", "Boreal Acer is a maple")
	_check(TreeSpecies.species_from_tags({"genus": "sorbus"}, "boreal") == "rowan", "Boreal Sorbus is a rowan")
	_check(TreeSpecies.species_from_tags({"genus": "acer"}, "temperate") == "lime",
		"Other biomes keep their mapping")
	_check(TreeSpecies.species_from_tags({"genus": "tilia"}, "boreal") == "lime", "Tilia stays a lime")
