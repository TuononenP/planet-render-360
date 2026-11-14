extends SceneTree

## Headless: godot --headless --script tests/omt_to_overpass_test.gd
## The vector-map tier (OmtToOverpass): z14 OpenMapTiles features become
## Overpass-shaped JSON that OsmParser reads as water (sea included),
## buildings, roads, railways and land cover; tile buffers are cut back,
## a lake split over two tiles comes back as one body, and the sea it maps
## gives the ground its sea datum. OmtOsmSource serves cached tiles and
## OsmFetcher falls back to it. No network.

const LAT := 60.168
const LON := 24.953

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()

func _run() -> void:
	failures.clear()
	var t0 := _tile_at(LAT, LON)
	var tiles: Array[Vector2i] = [t0, t0 + Vector2i(1, 0), t0 + Vector2i(0, 1)]
	var bodies := _bodies(t0)
	var text := OmtToOverpass.convert(tiles, bodies)
	_check(text != "", "a mapped tile set converts")
	_check(text.contains(OmtToOverpass.GENERATOR), "the payload names its generator")
	var c := OmtToOverpass._latlon(t0, Vector2(2048, 2048))
	var parsed := OsmParser.parse_features(text, c["lat"], c["lon"])
	_buildings(parsed)
	_roads(parsed)
	_water(parsed, text)
	_land(parsed)
	_sea_datum(parsed)
	_check(OmtToOverpass.convert(tiles, {}) == "", "no tiles at all is no payload")
	var block := OmtToOverpass.tiles_for(LAT, LON, OsmFetcher.DETAILED_RADIUS_M)
	_check(block.size() >= 9 and block.size() <= 25, "the detailed radius takes 3x3 to 5x5 tiles: %d" % block.size())
	await _source(tiles, bodies)
	await _fetcher_fallback(tiles, bodies)
	if failures.is_empty():
		print("OMT TO OVERPASS OK: buildings, roads, rails, water joins, sea, land cover, sea datum, source, fallback")
		quit(0)
	else:
		for f in failures:
			printerr("OMT TO OVERPASS FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _tile_at(lat: float, lon: float) -> Vector2i:
	var px := TileFetcher.global_pixel(lat, lon, OmtToOverpass.ZOOM)
	return Vector2i(int(px.x / 256.0), int(px.y / 256.0))

func _square(x0: float, y0: float, x1: float, y1: float) -> Array:
	# Exterior rings run with a positive MVT area (tile space, y down).
	return [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]

func _bodies(t0: Vector2i) -> Dictionary:
	var west := {
		"water": [
			# A lake running past the tile's east edge into the buffer.
			{"type": MvtReader.POLYGON, "tags": {"class": "lake"}, "geom": [[_square(3000, 1000, 4160, 2000)]]},
			{"type": MvtReader.POLYGON, "tags": {"class": "swimming_pool"}, "geom": [[_square(100, 3500, 300, 3700)]]},
		],
		"waterway": [
			{"type": MvtReader.LINE, "tags": {"class": "stream", "brunnel": "tunnel"},
				"geom": [[Vector2(100, 100), Vector2(900, 100)]]},
			{"type": MvtReader.LINE, "tags": {"class": "river"}, "geom": [[Vector2(100, 2600), Vector2(2000, 2600)]]},
		],
		"building": [
			{"type": MvtReader.POLYGON, "tags": {"render_height": 30.0, "render_min_height": 0.0},
				"geom": [[_square(500, 500, 700, 700)]]},
			{"type": MvtReader.POLYGON, "tags": {"render_height": 5.0, "render_min_height": 0.0},
				"geom": [[_square(800, 500, 1000, 700)]]},
			{"type": MvtReader.POLYGON, "tags": {"render_height": 40.0, "hide_3d": true},
				"geom": [[_square(1100, 500, 1300, 700)]]},
			# A courtyard block: one outer, one hole.
			{"type": MvtReader.POLYGON, "tags": {"render_height": 18.0},
				"geom": [[_square(1500, 500, 1900, 900), [Vector2(1600, 600), Vector2(1600, 800), Vector2(1800, 800), Vector2(1800, 600)]]]},
		],
		"transportation": [
			{"type": MvtReader.LINE, "tags": {"class": "minor", "brunnel": "bridge"},
				"geom": [[Vector2(100, 3000), Vector2(4150, 3000)]]},
			{"type": MvtReader.LINE, "tags": {"class": "primary", "ramp": 1}, "geom": [[Vector2(100, 3200), Vector2(900, 3200)]]},
			{"type": MvtReader.LINE, "tags": {"class": "transit", "subclass": "tram"}, "geom": [[Vector2(100, 3300), Vector2(900, 3300)]]},
			{"type": MvtReader.LINE, "tags": {"class": "path", "subclass": "footway"}, "geom": [[Vector2(100, 3400), Vector2(900, 3400)]]},
			{"type": MvtReader.LINE, "tags": {"class": "ferry"}, "geom": [[Vector2(100, 3450), Vector2(900, 3450)]]},
		],
		"landcover": [
			{"type": MvtReader.POLYGON, "tags": {"class": "wood", "subclass": "forest"}, "geom": [[_square(2200, 2200, 2600, 2600)]]},
		],
	}
	var east := {
		"water": [
			{"type": MvtReader.POLYGON, "tags": {"class": "lake"}, "geom": [[_square(-64, 1000, 1000, 2000)]]},
		],
		"transportation": [
			{"type": MvtReader.LINE, "tags": {"class": "minor", "brunnel": "bridge"},
				"geom": [[Vector2(-60, 3000), Vector2(800, 3000)]]},
		],
	}
	return {t0: _tile(west), t0 + Vector2i(1, 0): _tile(east), t0 + Vector2i(0, 1): PackedByteArray()}

func _buildings(parsed: Dictionary) -> void:
	var buildings: Array = parsed["buildings"]
	_check(buildings.size() == 3, "three buildings (one hidden behind its parts): %d" % buildings.size())
	var tall := 0
	for b: Dictionary in buildings:
		if absf(float(b.get("height", 0.0)) - 30.0) < 0.1:
			tall += 1
	_check(tall == 1, "render_height carries a mapped height")

func _roads(parsed: Dictionary) -> void:
	var classes := {}
	var bridge_pieces := 0
	for r: Dictionary in parsed["roads"]:
		classes[str(r.get("class", ""))] = true
		if str(r.get("class", "")) == "residential":
			bridge_pieces += 1
	for want in ["residential", "primary_link", "footway"]:
		_check(classes.has(want), "road class %s: %s" % [want, classes.keys()])
	_check(not classes.has("ferry"), "ferries are not roads")
	_check(bridge_pieces == 2, "a road over two tiles is cut at the edge, once per tile: %d" % bridge_pieces)
	var rails: Array = parsed["railways"]
	_check(rails.size() == 1 and str(rails[0].get("class", "")) == "tram", "transit/tram becomes railway=tram")

func _water(parsed: Dictionary, text: String) -> void:
	var lakes := 0
	var seas := 0
	for poly: Dictionary in parsed["land"]:
		if str(poly.get("class", "")) != "water":
			continue
		if bool(poly.get("tidal", false)):
			seas += 1
		else:
			lakes += 1
			var box := OsmGeometry._ring_aabb(poly["points"])
			# One tile is ~1220 m at 60°N; the lake spans 1096 of 4096 units each side of the edge.
			_check(box.size.x > 500.0, "the lake joins across the tile edge: %.0f m wide" % box.size.x)
	_check(lakes == 1, "one lake from two tile pieces, no pool: %d" % lakes)
	_check(seas == 1, "an open-sea tile is one tidal sea polygon: %d" % seas)
	var rivers := 0
	for w: Dictionary in parsed["waterways"]:
		if str(w.get("class", "")) == "river":
			rivers += 1
		_check(str(w.get("class", "")) != "stream", "a culverted stream is not drawn")
	_check(rivers == 1, "the river line is kept")
	_check(not text.contains("swimming_pool"), "pools are left out")

func _land(parsed: Dictionary) -> void:
	var forest := false
	for poly: Dictionary in parsed["land"]:
		forest = forest or str(poly.get("class", "")) == "forest"
	_check(forest, "landcover wood is forest")

## The coupling that matters: a surface-model sea at 17 m with the sea
## mapped drops to the sea datum; without map data it stays on the DEM.
## (water_level_m is relative to the DEM centre, here 17 m.)
func _sea_datum(parsed: Dictionary) -> void:
	var levels: Array[float] = []
	for with_map in [true, false]:
		var data := LocationData.new()
		data.grid_size = 32
		data.heights.resize(32 * 32)
		data.heights.fill(17.0)
		data.water_level = 16.0
		data.land_polygons = OsmGeometry.land_by_priority(parsed["land"]) if with_map else []
		levels.append(GroundTruth.new(data).water_level_m)
	_check(is_equal_approx(levels[0] - levels[1], WaterBuilder.SEA_LEVEL_M - 16.0),
		"mapped sea moves the datum from 16 m to the sea level: %s" % [levels])

## OmtOsmSource reads cached tiles (offline mode) and converts them.
func _source(tiles: Array[Vector2i], bodies: Dictionary) -> void:
	var dir := _fixture_dir(tiles, bodies)
	var source := OmtOsmSource.new()
	root.add_child(source)
	await process_frame
	source.set_cache_dir(dir)
	source.offline_mode = true
	var c := OmtToOverpass._latlon(tiles[0], Vector2(2048, 2048))
	source.start(c["lat"], c["lon"], 200.0)
	for i in 300:
		if source.state != OmtOsmSource.State.RUNNING:
			break
		await process_frame
	_check(source.state == OmtOsmSource.State.READY and source.text.contains(OmtToOverpass.GENERATOR),
		"the source converts cached tiles: state %d" % source.state)
	source.start(c["lat"] + 1.0, c["lon"], 200.0)
	for i in 300:
		if source.state != OmtOsmSource.State.RUNNING:
			break
		await process_frame
	_check(source.state == OmtOsmSource.State.FAILED, "no cached tiles offline is a failure")
	source.queue_free()

## A give-up with no saved copy waits for the vector map and serves it,
## reported as a simplified (partial) map.
func _fetcher_fallback(tiles: Array[Vector2i], bodies: Dictionary) -> void:
	var dir := _fixture_dir(tiles, bodies)
	CacheStore.dir_override = "user://omt_fallback_test_cache"
	DirAccess.make_dir_recursive_absolute(CacheStore.dir_override)
	var f := OsmFetcher.new()
	root.add_child(f)
	await process_frame
	f._omt.set_cache_dir(dir)
	f._omt.offline_mode = true
	var c := OmtToOverpass._latlon(tiles[0], Vector2(2048, 2048))
	var result := {"ok": false, "failed": "", "detail": "", "partial": false, "buildings": 0}
	f.succeeded.connect(func(b: Array, _r, _l, _lm) -> void:
		result["ok"] = true
		result["buildings"] = b.size())
	f.failed.connect(func(reason: String) -> void: result["failed"] = reason)
	f.fallback_used.connect(func(detail: String, partial: bool) -> void:
		result["detail"] = detail
		result["partial"] = partial)
	f._pending_lat = c["lat"]
	f._pending_lon = c["lon"]
	f._omt.start(c["lat"], c["lon"], 200.0)
	f.give_up("streamed wait over")
	var deadline := Time.get_ticks_msec() + 10000
	while not result["ok"] and result["failed"] == "" and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(result["ok"] and int(result["buildings"]) == 3, "give_up serves the vector map: %s" % [result])
	_check(str(result["detail"]) == "Simplified map" and bool(result["partial"]), "and says so: %s" % [result])
	_check(f.used_omt, "the fetcher records the vector-map tier")
	_check(DataNotes.partial_line("Simplified map").contains("simplified"), "the loading line names it")
	f.queue_free()
	CacheStore.dir_override = ""

func _fixture_dir(tiles: Array[Vector2i], bodies: Dictionary) -> String:
	var dir := "user://omt_to_overpass_test_tiles"
	DirAccess.make_dir_recursive_absolute(dir)
	for name in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute("%s/%s" % [dir, name])
	var probe := VectorTileFetcher.new()
	probe.cache_dir = dir
	for t in tiles:
		var body: PackedByteArray = bodies[t]
		var path := probe.sea_path(OmtToOverpass.ZOOM, t.x, t.y) if body.is_empty() \
			else probe.cache_path(OmtToOverpass.ZOOM, t.x, t.y)
		var fh := FileAccess.open(path, FileAccess.WRITE)
		fh.store_buffer(body)
		fh.close()
	probe.free()
	return dir

# --- A minimal MVT encoder: several layers, typed tags, lines and polygons. ---

func _tile(layers: Dictionary) -> PackedByteArray:
	var tile := PackedByteArray()
	for name: String in layers:
		var keys: Array = []
		var values: Array = []
		var body := PackedByteArray()
		_varint(body, 15 << 3)
		_varint(body, 2)
		_bytes(body, 1, name.to_utf8_buffer())
		for f: Dictionary in layers[name]:
			var feat := PackedByteArray()
			var tags := PackedByteArray()
			for k: String in f["tags"]:
				if not keys.has(k):
					keys.append(k)
				var v: Variant = f["tags"][k]
				if not values.has(v):
					values.append(v)
				_varint(tags, keys.find(k))
				_varint(tags, values.find(v))
			_bytes(feat, 2, tags)
			_varint(feat, 3 << 3)
			_varint(feat, int(f["type"]))
			_bytes(feat, 4, _geometry(int(f["type"]), f["geom"]))
			_bytes(body, 2, feat)
		for k: String in keys:
			_bytes(body, 3, k.to_utf8_buffer())
		for v: Variant in values:
			var val := PackedByteArray()
			if v is String:
				_bytes(val, 1, (v as String).to_utf8_buffer())
			elif v is bool:
				_varint(val, 7 << 3)
				_varint(val, 1 if v else 0)
			elif v is int:
				_varint(val, 4 << 3)
				_varint(val, v)
			else:
				_varint(val, (3 << 3) | 1)
				var d := PackedByteArray()
				d.resize(8)
				d.encode_double(0, float(v))
				val.append_array(d)
			_bytes(body, 4, val)
		_varint(body, 5 << 3)
		_varint(body, 4096)
		_bytes(tile, 3, body)
	return tile

## Lines: [points]; polygons: [[ring, ring...]] (first ring exterior).
func _geometry(type: int, geom: Array) -> PackedByteArray:
	var out := PackedByteArray()
	var cursor := [0, 0]
	if type == MvtReader.LINE:
		for line: Array in geom:
			_path(out, line, cursor, false)
	else:
		for poly: Array in geom:
			for ring: Array in poly:
				_path(out, ring, cursor, true)
	return out

func _path(out: PackedByteArray, pts: Array, cursor: Array, close: bool) -> void:
	for i in pts.size():
		var p: Vector2 = pts[i]
		if i == 0:
			_varint(out, 1 | (1 << 3))
		elif i == 1:
			_varint(out, 2 | ((pts.size() - 1) << 3))
		_varint(out, _zigzag(int(p.x) - int(cursor[0])))
		_varint(out, _zigzag(int(p.y) - int(cursor[1])))
		cursor[0] = int(p.x)
		cursor[1] = int(p.y)
	if close:
		_varint(out, 7 | (1 << 3))

func _varint(out: PackedByteArray, v: int) -> void:
	while v >= 0x80:
		out.append((v & 0x7f) | 0x80)
		v >>= 7
	out.append(v)

func _bytes(out: PackedByteArray, field: int, payload: PackedByteArray) -> void:
	_varint(out, (field << 3) | 2)
	_varint(out, payload.size())
	out.append_array(payload)

func _zigzag(n: int) -> int:
	return (n << 1) ^ (n >> 63)
