extends SceneTree

## HelsinkiRegister / RegisterCodes / Gk25 (offline):
## godot --headless --script tests/helsinki_register_test.gd
## Projection round trip, decoding a trimmed real WFS answer, footprint
## matching (inside, holes, snap, several rows per outline), fill-only
## priority, the code tables and the DEM miss marker.

const FIXTURE := "res://tests/fixtures/helsinki_register_sample.json"
const C_LAT := 60.168
const C_LON := 24.945

var failures: Array[String] = []

func _init() -> void:
	_gk25()
	_decode_and_apply()
	_codes()
	_urls()
	_dem_miss()
	if failures.is_empty():
		print("HELSINKI REGISTER OK: GK25 inverse, decode, matching, fill-only, codes, DEM miss")
		quit(0)
	else:
		for f in failures:
			printerr("HELSINKI REGISTER FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _gk25() -> void:
	# Finlandia Hall reference point (HelsinkiDem test): forward is the
	# same code as before, so check the delegate and the inverse.
	_check(HelsinkiDem.gk25(60.1757, 24.9338) == Gk25.from_latlon(60.1757, 24.9338),
		"HelsinkiDem.gk25 must delegate to Gk25")
	var worst := 0.0
	for dlat in [-0.03, 0.0, 0.03]:
		for dlon in [-0.06, 0.0, 0.06]:
			var lat: float = 60.17 + dlat
			var lon: float = 24.94 + dlon
			var p := Gk25.forward(lat, lon)
			var back := Gk25.to_latlon(p[0], p[1])
			var q := Gk25.forward(back[0], back[1])
			worst = maxf(worst, Vector2(p[0] - q[0], p[1] - q[1]).length())
	_check(worst < 0.01, "GK25 round trip must hold to 1 cm (worst %.4f m)" % worst)
	var c := Gk25.forward(C_LAT, C_LON)
	var xz := Gk25.to_xz(c[0] + 100.0, c[1] + 50.0, C_LAT, C_LON)
	_check(absf(xz.x - 100.0) < 1.5 and absf(xz.y + 50.0) < 1.5,
		"GK25 offsets must map to local east / -north metres (got %s)" % str(xz))
	# The per-place affine frame stays within 2 cm of the exact path over
	# a 3 km window.
	var fr := Gk25.frame(C_LAT, C_LON)
	var off := 0.0
	for de in [-1450.0, 0.0, 1450.0]:
		for dn in [-1450.0, 0.0, 1450.0]:
			var a := Gk25.to_xz(c[0] + de, c[1] + dn, C_LAT, C_LON)
			var b := Gk25.frame_xz(fr, c[0] + de, c[1] + dn)
			off = maxf(off, a.distance_to(b))
	_check(off < 0.02, "The affine frame must stay within 2 cm of to_xz (worst %.4f m)" % off)

## A square footprint of half-size `r` round local (x, z).
func _square(x: float, z: float, r: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x - r, z - r), Vector2(x + r, z - r),
		Vector2(x + r, z + r), Vector2(x - r, z + r)])

func _building(fp: PackedVector2Array, extra: Dictionary = {}) -> Dictionary:
	var b := {"footprint": fp, "holes": [], "height": 10.0, "height_source": "default",
		"levels": 0.0, "material": "", "kind": "yes", "start_year": 0, "parts": []}
	b.merge(extra, true)
	return b

func _decode_and_apply() -> void:
	var rows: Variant = HelsinkiRegister.decode(FileAccess.get_file_as_string(FIXTURE))
	_check(rows is Array and (rows as Array).size() == 20, "The fixture must decode to 20 in-service rows")
	if not (rows is Array):
		return
	_check(HelsinkiRegister.decode("<ExceptionReport/>") == null, "A WFS exception must decode to null")
	var r0: Dictionary = rows[0]
	_check(r0["floors"] == 8 and r0["year"] == 1957 and r0["facade"] == "1" and r0["rl"] == "0121",
		"Row fields must decode (floors, year, facade, class)")
	# One footprint round each of the first rows' positions.
	var buildings: Array = []
	for i in 6:
		var r: Dictionary = rows[i]
		var p := Gk25.to_xz(float(r["e"]), float(r["n"]), C_LAT, C_LON)
		buildings.append(_building(_square(p.x, p.y, 8.0)))
	# 1: mapped storeys and material win.
	buildings[1]["levels"] = 3.0
	buildings[1]["height_source"] = "levels"
	buildings[1]["height"] = 9.6
	buildings[1]["material"] = "plaster"
	# 2: a part-modelled landmark takes nothing.
	buildings[2]["parts"] = [{"height": 20.0}]
	# 3: the point sits in a courtyard hole: no match.
	var p3 := Gk25.to_xz(float(rows[3]["e"]), float(rows[3]["n"]), C_LAT, C_LON)
	buildings[3]["holes"] = [_square(p3.x, p3.y, 3.0)]
	# 4: the footprint stops 2 m short of the point: snapped.
	var p4 := Gk25.to_xz(float(rows[4]["e"]), float(rows[4]["n"]), C_LAT, C_LON)
	buildings[4]["footprint"] = _square(p4.x + 10.0, p4.y, 8.0)
	# 5: drawn 6 m away: too far to snap.
	var p5 := Gk25.to_xz(float(rows[5]["e"]), float(rows[5]["n"]), C_LAT, C_LON)
	buildings[5]["footprint"] = _square(p5.x + 14.0, p5.y, 8.0)
	var stats := HelsinkiRegister.apply(buildings, C_LAT, C_LON, rows)
	var b0: Dictionary = buildings[0]
	_check(b0["levels"] == 8.0 and b0["height_source"] == "levels" and is_equal_approx(float(b0["height"]), 25.6),
		"Register floors must give a missing height (8 floors, 25.6 m)")
	_check(b0["start_year"] == 1957 and b0["material"] == "concrete" and b0["kind"] == "apartments",
		"Year, facade and use class must fill (1957, concrete, apartments via RL2018)")
	_check((b0.get("enriched", {}) as Dictionary).has(HelsinkiRegister.PROVENANCE),
		"Filled fields must record their provenance")
	var b1: Dictionary = buildings[1]
	_check(b1["levels"] == 3.0 and is_equal_approx(float(b1["height"]), 9.6) and b1["material"] == "plaster",
		"Mapped storeys, height and material must win over the register")
	_check(b1["start_year"] == 1924 and b1["kind"] == "apartments",
		"Missing year / kind still fill on a mapped building")
	_check(not buildings[2].has("enriched") and buildings[2]["levels"] == 0.0,
		"A part-modelled building must take nothing")
	_check(not buildings[3].has("enriched"), "A point in a courtyard hole must not match")
	_check(buildings[4].has("enriched"), "A point 2 m outside must snap to the footprint")
	_check(not buildings[5].has("enriched"), "A point 6 m away must not snap")
	_check(int(stats["filled"]) == 3, "Three buildings must fill (got %d)" % int(stats["filled"]))
	# Idempotent.
	var before: Dictionary = buildings[0].duplicate(true)
	HelsinkiRegister.apply(buildings, C_LAT, C_LON, rows)
	_check(buildings[0] == before, "Enrichment must be idempotent")
	# Several register rows in one outline: most floors, largest entry's facts.
	var pa := Gk25.to_xz(float(rows[0]["e"]), float(rows[0]["n"]), C_LAT, C_LON)
	var shared := [_building(_square(pa.x, pa.y, 30.0))]
	var small: Dictionary = (rows[0] as Dictionary).duplicate()
	small["floors"] = 11
	small["area"] = 100.0
	small["year"] = 2001
	HelsinkiRegister.apply(shared, C_LAT, C_LON, [rows[0], small])
	_check(shared[0]["levels"] == 11.0 and shared[0]["start_year"] == 1957,
		"Shared outline: most floors, the largest entry's year")

func _codes() -> void:
	for code in RegisterCodes.USE_1994:
		_check(ArchitectureData.KIND_TAGS.has(RegisterCodes.USE_1994[code]),
			"Use class %s must map to a KIND_TAGS kind" % code)
	for code in RegisterCodes.RL2018:
		_check(ArchitectureData.KIND_TAGS.has(RegisterCodes.RL2018[code]),
			"RL2018 %s must map to a KIND_TAGS kind" % code)
	for code in RegisterCodes.RL2018_MAIN:
		_check(ArchitectureData.KIND_TAGS.has(RegisterCodes.RL2018_MAIN[code]),
			"RL2018 class %s must map to a KIND_TAGS kind" % code)
	for code in RegisterCodes.FACADE:
		_check(MaterialLibrary.MATERIAL_TAGS.has(RegisterCodes.FACADE[code]),
			"Facade %s must map to a MATERIAL_TAGS value" % code)
	_check(RegisterCodes.kind_for("151", "") == "office", "151 is an office")
	_check(RegisterCodes.kind_for("", "0610") == "hospital", "RL2018 061x is a hospital")
	_check(RegisterCodes.kind_for("", "0790") == "civic", "RL2018 07 falls back to civic")
	_check(RegisterCodes.kind_for("163", "0510") == "", "A use code without a kind says nothing")
	_check(RegisterCodes.facade_for("2", "2", 1924, 7) == "", "Pre-1940 brick blocks stay rendered (era)")
	_check(RegisterCodes.facade_for("2", "2", 1814, 2) == "brick", "Low early brick stays brick")
	_check(RegisterCodes.facade_for("7", "2", 1950, 5) == "", "'Other' facades stay with the era")
	_check(RegisterCodes.facade_for("", "4", 1920, 2) == "wood", "A low timber frame is clad in wood")

func _urls() -> void:
	for url in [HelsinkiRegister.request_url(C_LAT, C_LON), HelsinkiTrees.request_url(C_LAT, C_LON)]:
		_check(not HostPolicy.is_blocked(url), "City endpoints must pass HostPolicy")
		_check(url.contains("EPSG:3879") and url.contains("bbox="), "Requests must be GK25 bbox windows")
	_check(HelsinkiRegister.covers(60.1699, 24.9384), "The register covers central Helsinki")
	_check(HelsinkiRegister.covers(60.1755, 24.8310), "Keilaniemi's window reaches Helsinki")
	_check(not HelsinkiRegister.covers(59.3293, 18.0686), "Stockholm is not covered")

func _dem_miss() -> void:
	var dir := "user://cache-register-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	CacheStore.dir_override = dir
	_check(not HelsinkiDemFetcher.known_miss(60.1755, 24.8310), "No miss before an answer")
	var f := FileAccess.open(HelsinkiDemFetcher.miss_path(60.1755, 24.8310), FileAccess.WRITE)
	f.close()
	_check(HelsinkiDemFetcher.known_miss(60.1755, 24.8310), "A miss marker must be seen")
	_check(not HelsinkiDemFetcher.known_miss(60.1699, 24.9384), "A miss is per place")
	DirAccess.remove_absolute(HelsinkiDemFetcher.miss_path(60.1755, 24.8310))
	DirAccess.remove_absolute(dir)
	CacheStore.dir_override = ""
