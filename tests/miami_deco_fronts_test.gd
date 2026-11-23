extends SceneTree

## Offline verification for MiamiDecoFronts & DecoFront (MI-4A):
## tools/godot_bg.sh --headless --path . --script tests/miami_deco_fronts_test.gd

var failures: Array[String] = []

const MB_LAT := 25.7810
const MB_LON := -80.1300

func _init() -> void:
	_check(MiamiDecoFronts.ROWS.size() >= 24,
		"MiamiDecoFronts.ROWS has >= 24 rows (got %d)" % MiamiDecoFronts.ROWS.size())

	var text := BundledOsm.read("miami_beach_detailed")
	_check(text != "", "BundledOsm.read('miami_beach_detailed') loaded non-empty snapshot")

	var snapshot_ids := {}
	var matched_buildings := 0
	if text != "":
		var parsed := OsmFetcher.parse_features(text, MB_LAT, MB_LON)
		for raw_b in parsed.buildings:
			var b := raw_b as Dictionary
			for raw_id in OsmParser.ids_of(b):
				snapshot_ids[str(raw_id)] = true
			if not MiamiDecoFronts.row_for(b).is_empty():
				matched_buildings += 1

	for raw_key in MiamiDecoFronts.ROWS.keys():
		var key := str(raw_key)
		var row: Dictionary = MiamiDecoFronts.ROWS[key]
		_check(key.begins_with("way:"), "%s uses way:<id> format" % key)
		var num_id := key.trim_prefix("way:")
		_check(snapshot_ids.has(key) and text.contains('"id":' + num_id),
			"%s (%s) exists in miami_beach_detailed.osmb" % [key, str(row.get("name", ""))])

		var pal: Variant = row.get("palette", [])
		_check(pal is Array and (pal as Array).size() == 3,
			"%s has a 3-colour palette" % key)
		if pal is Array:
			for hex_v in (pal as Array):
				var hx := str(hex_v)
				_check(hx.begins_with("#") and hx.length() == 7 and hx.substr(1).is_valid_hex_number(false),
					"%s palette colour '%s' is #RRGGBB" % [key, hx])

		var parapet := str(row.get("parapet", ""))
		_check(parapet in MiamiDecoFronts.PARAPET_TYPES,
			"%s parapet '%s' in PARAPET_TYPES" % [key, parapet])

		var fin_pos := str(row.get("fin_pos", ""))
		_check(fin_pos in ["center", "left", "right", "none"],
			"%s fin_pos '%s' is valid" % [key, fin_pos])
		_check(str(row.get("corner", "")) in ["square", "round"],
			"%s corner '%s' is valid" % [key, str(row.get("corner", ""))])

		var sign_s := str(row.get("sign", ""))
		_check(sign_s.length() > 0 and sign_s.length() <= 16,
			"%s sign '%s' length %d in 1..16" % [key, sign_s, sign_s.length()])

		for col_key: String in ["sign_hex", "neon_hex"]:
			var chx := str(row.get(col_key, ""))
			_check(chx.begins_with("#") and chx.length() == 7 and chx.substr(1).is_valid_hex_number(false),
				"%s %s '%s' is #RRGGBB" % [key, col_key, chx])

		var terr: Variant = row.get("terrace", [])
		_check(terr is Array and (terr as Array).size() == 2,
			"%s terrace has [awning_hex, umbrella_hex]" % key)

	_check(matched_buildings == MiamiDecoFronts.ROWS.size(),
		"row_for() matched all %d Deco rows in parsed buildings (got %d)" % [
			MiamiDecoFronts.ROWS.size(), matched_buildings])

	_smoke_test_deco_front()

	if failures.is_empty():
		print("MIAMI DECO FRONTS OK: %d rows verified against miami_beach_detailed" % MiamiDecoFronts.ROWS.size())
		quit(0)
	else:
		for msg: String in failures:
			printerr("MIAMI DECO FRONTS FAIL: ", msg)
		quit(1)

func _smoke_test_deco_front() -> void:
	var m := WorldScale.metres_to_units()
	var spans := [{
		"a": Vector2(0.0, 0.0),
		"b": Vector2(12.0 * m, 0.0),
		"dir": Vector2(1.0, 0.0),
		"n": Vector2(0.0, 1.0),
		"len_m": 12.0,
		"bays": 3,
		"street": true,
		"first": true,
		"last": true,
		"a_inside": false,
		"b_inside": false,
	}]
	var rows := [
		{"y0": 0.0, "y1": 3.8 * m, "storey": 0, "ground": true, "win0": 0.4 * m, "win1": 3.2 * m},
		{"y0": 3.8 * m, "y1": 7.2 * m, "storey": 1, "ground": false, "win0": 4.6 * m, "win1": 6.6 * m},
		{"y0": 7.2 * m, "y1": 10.6 * m, "storey": 2, "ground": false, "win0": 8.0 * m, "win1": 10.0 * m},
	]
	var non_deco_kit := ReliefKit.new()
	DecoFront.add(non_deco_kit, spans, rows, {
		"b": {"osm_id": "way:1"},
		"look": {"relief": {}},
		"seed": 42.0,
		"top": 10.6 * m,
		"ground_y": 0.0,
	})
	_check(non_deco_kit.is_empty(), "DecoFront.add is zero-cost for non-Deco buildings")

	var colony_kit := ReliefKit.new()
	colony_kit.ultra = true
	DecoFront.add(colony_kit, spans, rows, {
		"b": {"osm_id": "way:435587753"},
		"look": {"relief": {}},
		"seed": 736.0,
		"top": 10.6 * m,
		"ground_y": 0.0,
	})
	_check(not colony_kit.is_empty(), "DecoFront.add emits 3D relief for Colony Hotel (way:435587753)")

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
