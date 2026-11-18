extends SceneTree

## HelsinkiLod2 (offline): godot --headless --script tests/helsinki_lod2_test.gd
## The bundled cells (manifest, hash, rows), the window's cells, matching
## to footprints, measured heights replacing estimates but never mapped
## heights, roof fill-only, several rows per outline, no invented
## setbacks, idempotence.

const CELL := "25496_6672"
const C_LAT := 60.1680
const C_LON := 24.9450

var failures: Array[String] = []

func _init() -> void:
	var rows := HelsinkiLod2.read_cell(CELL)
	_check(rows.size() > 100, "The bundled cell must read and pass its hash (%d rows)" % rows.size())
	_check(HelsinkiLod2.covers(60.1699, 24.9384), "Central Helsinki has bundled cells")
	_check(not HelsinkiLod2.covers(60.4518, 22.2666), "Turku has none")
	_check(HelsinkiLod2.cell_keys(60.1699, 24.9384).has(CELL), "The window round Kamppi includes the cell")
	if rows.size() > 3:
		_apply(rows)
	if failures.is_empty():
		print("HELSINKI LOD2 OK: cells, matching, heights, roofs, idempotence")
		quit(0)
	else:
		for f in failures:
			printerr("HELSINKI LOD2 FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _square(p: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([p + Vector2(-r, -r), p + Vector2(r, -r), p + Vector2(r, r), p + Vector2(-r, r)])

func _building(p: Vector2, extra: Dictionary = {}) -> Dictionary:
	var b := {"footprint": _square(p, 6.0), "holes": [], "height": 10.0, "height_source": "default",
		"levels": 0.0, "roof_shape": "", "roof_angle": 0.0, "parts": [], "kind": "yes"}
	b.merge(extra, true)
	return b

func _apply(rows: Array) -> void:
	# Real rows with a roof shape the app uses, a sloped one first.
	var pick: Array = []
	for r in rows:
		if str(r[8]) in ["gabled", "hipped"] and float(r[6]) >= 10.0 and float(r[3]) >= 50.0:
			pick.append(r)
			break
	for r in rows:
		if str(r[8]) == "flat" and float(r[3]) >= 50.0 and pick.size() < 3:
			pick.append(r)
	if pick.size() < 3:
		_check(false, "The cell must hold sloped and flat buildings")
		return
	var f := Gk25.frame(C_LAT, C_LON)
	var at := func(r: Array) -> Vector2: return Gk25.frame_xz(f, float(r[1]), float(r[2]))
	var buildings: Array = [
		_building(at.call(pick[0])),
		_building(at.call(pick[1]), {"height": 31.0, "height_source": "tag_height"}),
		_building(at.call(pick[2]), {"roof_shape": "gabled", "parts": [{"height": 9.0}]}),
	]
	var stats := HelsinkiLod2.apply(buildings, C_LAT, C_LON, rows)
	var b0: Dictionary = buildings[0]
	_check(is_equal_approx(float(b0["height"]), float(pick[0][4])) and b0["height_source"] == "tag_height" and b0.get("lod2", false),
		"A default height takes the measured one (%s vs %s)" % [b0["height"], pick[0][4]])
	_check(b0["roof_shape"] == str(pick[0][8]) and absf(float(b0["roof_angle"]) - float(pick[0][6])) <= 0.5,
		"The roof's shape and pitch fill in")
	_check(float(b0.get("roof_height_m", 0.0)) == 0.0, "The rise is left to the footprint")
	var b1: Dictionary = buildings[1]
	_check(float(b1["height"]) == 31.0 and not b1.has("lod2"), "A mapped height wins")
	_check(b1["roof_shape"] == "flat", "A missing roof shape still fills on a mapped building")
	_check(not buildings[2].has("enriched"), "A part-modelled building takes nothing")
	_check(int(stats["filled"]) == 2, "Two buildings fill (got %d)" % int(stats["filled"]))
	var before: Dictionary = b0.duplicate(true)
	HelsinkiLod2.apply(buildings, C_LAT, C_LON, rows)
	_check(buildings[0] == before, "Enrichment must be idempotent")
	# Two city buildings inside one OSM outline: the tallest height.
	var p := at.call(pick[0]) as Vector2
	var shared := [{"footprint": _square(p, 60.0), "holes": [], "height": 10.0, "height_source": "levels",
		"levels": 3.0, "roof_shape": "", "roof_angle": 0.0, "parts": [], "kind": "yes"}]
	var tall: Array = (pick[0] as Array).duplicate()
	tall[4] = 44.0
	tall[3] = 20.0
	HelsinkiLod2.apply(shared, C_LAT, C_LON, [pick[0], tall])
	_check(float(shared[0]["height"]) == 44.0, "One outline, several rows: the tallest height")
	_check(shared[0]["roof_shape"] == str(pick[0][8]), "One outline, several rows: the largest one's roof")
	# No invented setbacks on a measured building.
	var flat := _building(Vector2.ZERO, {"lod2": true, "height": 40.0, "height_source": "tag_height", "kind": "office"})
	_check(TowerMassing.stack(flat, {"kind": "commercial", "floor_h": 3.5}, {"total_m": 40.0},
		{"fidelity": 3}, "flat").is_empty(), "A LoD2 building keeps one mass")
