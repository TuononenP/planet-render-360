extends SceneTree

## HsyRegister (offline):
## godot --headless --script tests/hsy_register_test.gd
## Decoding a trimmed real WFS answer (Tapiola), withheld values, the
## footprint centroid, Helsinki's buildings left to the city register,
## the window gate, and filling an OSM building through
## HelsinkiRegister.apply.

const FIXTURE := "res://tests/fixtures/hsy_register_sample.json"
var failures: Array[String] = []

func _init() -> void:
	_decode()
	_centroid()
	_covers()
	_fill()
	if failures.is_empty():
		print("HSY REGISTER OK: decode, withheld, centroid, gate, fill")
		quit(0)
	else:
		for f in failures:
			printerr("HSY REGISTER FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _rows() -> Array:
	var rows: Variant = HsyRegister.decode(FileAccess.get_file_as_string(FIXTURE))
	return rows if rows is Array else []

func _decode() -> void:
	var rows := _rows()
	_check(rows.size() == 20, "The fixture decodes to 20 buildings (%d)" % rows.size())
	_check(HsyRegister.decode("<ExceptionReport/>") == null, "An exception decodes to null")
	if rows.size() != 20:
		return
	var r0: Dictionary = rows[0]
	_check(int(r0["floors"]) == 2 and str(r0["facade"]) == "1" and int(r0["year"]) == 2011,
		"The first building reads 2 floors, concrete, 2011 (%s)" % str(r0))
	_check(float(r0["e"]) > 25480000.0 and float(r0["n"]) > 6660000.0, "Centroids stay in GK25")
	_check(str(rows[1]["facade"]) == "", "A withheld facade reads empty")
	var withheld := 0
	for r in rows.slice(16):
		withheld += 1 if int(r["floors"]) == 0 else 0
	_check(withheld == 4, "Withheld floor counts (999999999) read 0 (%d of 4)" % withheld)
	var helsinki := '{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[25496000,6672000],[25496010,6672000],[25496010,6672010],[25496000,6672010],[25496000,6672000]]]},"properties":{"kunta":"091","kavu":1930,"kerrosten_lkm":5,"julkisivu":2,"rakennusaine":2,"kerala":900}}]}'
	_check((HsyRegister.decode(helsinki) as Array).is_empty(), "Helsinki's buildings are left to the city register")

func _centroid() -> void:
	var square := {"type": "Polygon", "coordinates": [[[25486000.0, 6672000.0], [25486020.0, 6672000.0],
		[25486020.0, 6672010.0], [25486000.0, 6672010.0], [25486000.0, 6672000.0]]]}
	var c := HsyRegister._centroid(square)
	_check(c.size() == 2 and absf(c[0] - 25486010.0) < 0.01 and absf(c[1] - 6672005.0) < 0.01,
		"A rectangle's centroid is its middle to the centimetre (%s)" % str(c))

func _covers() -> void:
	_check(HsyRegister.covers(60.1755, 24.8050), "Tapiola asks HSY")
	_check(not HsyRegister.covers(60.1699, 24.9384), "Central Helsinki asks nothing more")
	_check(not HsyRegister.covers(60.4518, 22.2666), "Turku is outside HSY")
	_check(CityOpenData.covers("hsy_register", 60.1755, 24.8050) and not CityOpenData.covers("hsy_register", 60.1699, 24.9384),
		"CityOpenData gates the HSY layer by place")
	_check(CityOpenData.covers("hsy_register", 60.2050, 24.6550) and not CityOpenData.covers("register", 60.2050, 24.6550),
		"Espoo centre (Espoonkeskus) takes HSY's register alone")

func _fill() -> void:
	var rows := _rows()
	if rows.is_empty():
		return
	var r0: Dictionary = rows[0]
	var ll := Gk25.to_latlon(float(r0["e"]), float(r0["n"]))
	var c_lat: float = ll[0] + 0.001
	var c_lon: float = ll[1]
	var p := Gk25.frame_xz(Gk25.frame(c_lat, c_lon), float(r0["e"]), float(r0["n"]))
	var ring := PackedVector2Array([p + Vector2(-6, -6), p + Vector2(6, -6), p + Vector2(6, 6), p + Vector2(-6, 6)])
	var b := {"footprint": ring, "holes": [], "height": 8.0, "height_source": "default", "levels": 0.0,
		"kind": "yes", "parts": []}
	var st := HelsinkiRegister.apply([b], c_lat, c_lon, rows)
	_check(int(st["filled"]) == 1, "The building under the first row fills (%s)" % str(st))
	_check(float(b.get("levels", 0.0)) == 2.0 and int(b.get("start_year", 0)) == 2011
		and str(b.get("material", "")) == "concrete", "Floors, year and facade fill in (%s)" % str(b))
