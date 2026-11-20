extends SceneTree

## Turku open-data unit tests (offline):
## tools/godot_bg.sh --headless --path . --script tests/turku_open_data_test.gd

var failures: Array[String] = []

const SAMPLE_TREES := """<?xml version="1.0" encoding="utf-8"?>
<wfs:FeatureCollection xmlns:wfs="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:GIS="http://www.tekla.com/schemas/GIS">
 <gml:featureMember>
  <GIS:Puut gml:id="Puut.1">
    <GIS:Kasviryhma>Lehtipuu</GIS:Kasviryhma>
    <GIS:Kasvilaji>Tilia x vulgaris (puistolehmus)</GIS:Kasvilaji>
    <GIS:Istutusvuosi>1985</GIS:Istutusvuosi>
    <GIS:Geometry><gml:Point><gml:pos>23459660.0 6704670.0</gml:pos></gml:Point></GIS:Geometry>
  </GIS:Puut>
 </gml:featureMember>
 <gml:featureMember>
  <GIS:Puut gml:id="Puut.2">
    <GIS:Kasviryhma>Havupuu</GIS:Kasviryhma>
    <GIS:Kasvilaji>Pinus sylvestris (mänty)</GIS:Kasvilaji>
    <GIS:Istutusvuosi>2024</GIS:Istutusvuosi>
    <GIS:Geometry><gml:Point><gml:pos>23459710.0 6704690.0</gml:pos></gml:Point></GIS:Geometry>
  </GIS:Puut>
 </gml:featureMember>
</wfs:FeatureCollection>"""

const SAMPLE_STREETS := """<?xml version="1.0" encoding="utf-8"?>
<wfs:FeatureCollection xmlns:wfs="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:GIS="http://www.tekla.com/schemas/GIS">
 <gml:featureMember>
  <GIS:Katualueet gml:id="Katualueet.1">
    <GIS:Katuosalaji>Jalkakäytävä</GIS:Katuosalaji>
    <GIS:Pintamateriaali>Noppakivi</GIS:Pintamateriaali>
    <GIS:Geometry><gml:Polygon><gml:exterior><gml:LinearRing>
      <gml:posList>23459650.0 6704660.0 23459670.0 6704660.0 23459670.0 6704670.0 23459650.0 6704670.0 23459650.0 6704660.0</gml:posList>
    </gml:LinearRing></gml:exterior></gml:Polygon></GIS:Geometry>
  </GIS:Katualueet>
 </gml:featureMember>
 <gml:featureMember>
  <GIS:Katualueet gml:id="Katualueet.2">
    <GIS:Katuosalaji>Ajorata</GIS:Katuosalaji>
    <GIS:Pintamateriaali>Asfalttibetoni</GIS:Pintamateriaali>
    <GIS:Geometry><gml:Polygon><gml:exterior><gml:LinearRing>
      <gml:posList>23459650.0 6704670.0 23459670.0 6704670.0 23459670.0 6704680.0 23459650.0 6704680.0 23459650.0 6704670.0</gml:posList>
    </gml:LinearRing></gml:exterior></gml:Polygon></GIS:Geometry>
  </GIS:Katualueet>
 </gml:featureMember>
</wfs:FeatureCollection>"""

func _init() -> void:
	# 1. Gk23 round trip around Turku centre
	var en := Gk23.forward(60.4518, 22.2666)
	var ll := Gk23.to_latlon(en[0], en[1])
	_check(absf(ll[0] - 60.4518) < 1e-6 and absf(ll[1] - 22.2666) < 1e-6,
		"Gk23 round trip accurate: %s" % str(ll))
	var f := Gk23.frame(60.4518, 22.2666)
	var xz := Gk23.frame_xz(f, en[0], en[1])
	_check(xz.length() < 0.01, "Gk23 frame origin is (0, 0), got %s" % str(xz))
	# 2. Coverage & URLs
	_check(TurkuTrees.covers(60.4518, 22.2666), "Turku centre covered")
	_check(not TurkuTrees.covers(60.1699, 24.9384), "Helsinki not covered by TurkuTrees")
	_check(CityOpenData.covers("turku_trees", 60.4518, 22.2666), "CityOpenData covers turku_trees")
	_check(CityOpenData.covers("turku_streets", 60.4518, 22.2666), "CityOpenData covers turku_streets")
	# 3. Tree GML decode + merge
	var rows: Variant = TurkuTrees.decode(SAMPLE_TREES)
	_check(rows is Array and (rows as Array).size() == 2, "Decoded 2 Turku trees")
	if rows is Array and (rows as Array).size() == 2:
		var r0: Dictionary = rows[0]
		var r1: Dictionary = rows[1]
		_check(r0["genus"] == "tilia" and r0["leaf_type"] == "broadleaved" and float(r0["height_m"]) >= 13.0,
			"Mature linden parsed: %s" % str(r0))
		_check(r1["genus"] == "pinus" and r1["leaf_type"] == "needleleaved" and float(r1["height_m"]) <= 5.0,
			"Young pine parsed: %s" % str(r1))
		var st := {}
		var merged := TurkuTrees.merge([], 60.4518, 22.2666, rows, true, st)
		_check(merged.size() == 2 and int(st["added"]) == 2, "Merged 2 register trees")
	_check(TurkuTrees.decode("<ExceptionReport/>") == null, "Non-FeatureCollection returns null")
	# 4. Street GML decode + apply
	var srows: Variant = TurkuStreets.decode(SAMPLE_STREETS)
	_check(srows is Array and (srows as Array).size() == 2, "Decoded 2 Turku street polygons")
	if srows is Array and (srows as Array).size() == 2:
		var d := LocationData.new()
		d.latitude = 60.4518
		d.longitude = 22.2666
		var st2 := TurkuStreets.apply(d, srows)
		_check(int(st2["drive"]) == 1 and int(st2["paved"]) == 1, "Applied 1 drive + 1 paved: %s" % str(st2))
		_check(d.paved_areas.size() == 1 and str(d.paved_areas[0]["class"]) == "sett",
			"Noppakivi walkway classified as sett")
	# 5. Enriched turku_lod2 start_year & use_code -> kind
	var lod2_rows := HelsinkiLod2.rows_for(60.4518, 22.2666)
	var with_year := 0
	var with_use := 0
	var sample_row: Array = []
	for r in lod2_rows:
		if r is Array and (r as Array).size() >= 12:
			if int(r[10]) >= 1700:
				with_year += 1
			if str(r[11]) != "":
				with_use += 1
			if sample_row.is_empty() and int(r[10]) >= 1700 and RegisterCodes.kind_for(str(r[11]), "") != "" and float(r[3]) >= 20.0 and float(r[4]) >= 4.0:
				sample_row = r
	_check(with_year > 500, "Turku LoD2 centre carries start_year (got %d)" % with_year)
	_check(with_use > 500, "Turku LoD2 centre carries use_code (got %d)" % with_use)
	if not sample_row.is_empty():
		var ll_s := Gk23.to_latlon(float(sample_row[1]), float(sample_row[2]))
		var b_open := {"footprint": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]),
			"x": 0.0, "z": 0.0, "size_x": 16.0, "size_z": 16.0, "height": 9.0, "height_source": "default", "kind": "yes"}
		var b_mapped := {"footprint": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]),
			"x": 0.0, "z": 0.0, "size_x": 16.0, "size_z": 16.0, "height": 9.0, "height_source": "default",
			"kind": "museum", "start_year": 1899}
		HelsinkiLod2.apply([b_open], ll_s[0], ll_s[1], [sample_row])
		HelsinkiLod2.apply([b_mapped], ll_s[0], ll_s[1], [sample_row])
		_check(int(b_open.get("start_year", 0)) == int(sample_row[10]),
			"Turku LoD2 fills missing start_year: %s" % str(b_open.get("start_year", 0)))
		_check(str(b_open.get("kind", "")) == RegisterCodes.kind_for(str(sample_row[11]), ""),
			"Turku LoD2 fills generic kind from use_code: %s" % str(b_open.get("kind", "")))
		_check(int(b_mapped.get("start_year", 0)) == 1899 and str(b_mapped.get("kind", "")) == "museum",
			"Turku LoD2 preserves mapped start_year and kind")
	if failures.is_empty():
		print("TURKU OPEN DATA OK: Gk23, TurkuTrees, TurkuStreets, turku_lod2 enrichment")
		quit(0)
	else:
		for msg in failures:
			printerr("TURKU OPEN DATA FAIL: ", msg)
		quit(1)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
