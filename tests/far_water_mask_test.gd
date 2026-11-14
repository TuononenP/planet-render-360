extends SceneTree

## Headless: godot --headless --script tests/far_water_mask_test.gd
## The far water mask: OpenMapTiles water polygons (holes, lakes, open-sea
## tiles) rasterise to the right bytes, the far rings take water from it
## over a raised surface-model sea, open sea lies at sea level, and the
## coast bias is measured on it when no coastline is in reach. No network.

const Z := 10
const FIRST := Vector2i(580, 290)

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	failures.clear()
	_raster()
	_wet_rule()
	_native_colors()
	_sea_level()
	_coast_bias()
	if failures.is_empty():
		print("FAR WATER MASK OK: raster, holes, lakes, open sea, wet rule, native colours, sea level, coast bias")
		quit(0)
	else:
		for f in failures:
			printerr("FAR WATER MASK FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

## Byte at fractional tile position (fx, fy) from FIRST.
func _at(mask: Dictionary, fx: float, fy: float) -> int:
	var world := float(1 << Z)
	return FarWaterMask.sample_uv(mask, (FIRST.x + fx) / world, (FIRST.y + fy) / world)

func _raster() -> void:
	var tiles: Array[Vector2i] = [FIRST, FIRST + Vector2i(1, 0), FIRST + Vector2i(0, 1), FIRST + Vector2i(1, 1)]
	var ocean_rings := [
		[Vector2(0, 0), Vector2(2048, 0), Vector2(2048, 4096), Vector2(0, 4096)],
		[Vector2(512, 512), Vector2(512, 1536), Vector2(1536, 1536), Vector2(1536, 512)],  # island
	]
	var lake := [[Vector2(2560, 1024), Vector2(3584, 1024), Vector2(3584, 2048), Vector2(2560, 2048)]]
	var bodies := {
		tiles[0]: _tile("water", [[0, ocean_rings], [1, lake]], ["ocean", "lake"]),
		tiles[1]: PackedByteArray(),  # open sea: the server sends no tile
		tiles[2]: _tile("park", [], []),
		tiles[3]: _tile("water", [[0, lake]], ["swimming_pool"]),
	}
	for native in [true, false]:
		if native and not ClassDB.class_exists("GroundKernels"):
			continue
		FarWaterMask._native = native
		var label := "native" if native else "script"
		var mask := FarWaterMask.build(Z, tiles, bodies)
		_check(not mask.is_empty(), "%s: a complete tile set builds a mask" % label)
		if mask.is_empty():
			continue
		_check(_at(mask, 0.25, 0.75) == FarWaterMask.OCEAN, "%s: ocean polygon is OCEAN" % label)
		_check(_at(mask, 0.25, 0.25) == FarWaterMask.LAND, "%s: the island hole stays land" % label)
		_check(_at(mask, 0.75, 0.375) == FarWaterMask.INLAND, "%s: a lake is INLAND" % label)
		_check(_at(mask, 0.9, 0.9) == FarWaterMask.LAND, "%s: outside every polygon is land" % label)
		_check(_at(mask, 1.5, 0.5) == FarWaterMask.OCEAN, "%s: an empty (open-sea) tile is all OCEAN" % label)
		_check(_at(mask, 0.5, 1.5) == FarWaterMask.LAND, "%s: a tile without water is land" % label)
		_check(_at(mask, 1.75, 1.375) == FarWaterMask.LAND, "%s: swimming pools are not water" % label)
		_check(_at(mask, 2.5, 0.5) == FarWaterMask.NONE, "%s: outside the window is NONE" % label)
	FarWaterMask._native = ClassDB.class_exists("GroundKernels")
	var partial := bodies.duplicate()
	partial.erase(tiles[3])
	_check(FarWaterMask.build(Z, tiles, partial).is_empty(), "a missing tile drops the whole mask")
	var block := FarWaterMask.tiles_for(60.168, 24.953, FarWaterMask.zoom_for(60.168))
	var side := int(round(sqrt(float(block.size()))))
	_check(side * side == block.size() and side >= 3, "the fetch block is square and spans the reach: %d" % block.size())

func _wet_rule() -> void:
	_check(FarSampler._far_water(17.0, 0.5, false, FarWaterMask.OCEAN), "mask sea is water at 17 m")
	_check(FarSampler._far_water(40.0, 0.5, false, FarWaterMask.INLAND), "mask lake is water")
	_check(not FarSampler._far_water(0.1, 0.5, false, FarWaterMask.LAND), "mask land is not water, however low")
	_check(FarSampler._far_water(0.1, 0.5, false), "without a mask the sea-level rule stands")
	_check(not FarSampler._far_water(17.0, 0.5, false), "without a mask a 17 m sea stays land (the old bug)")
	_check(FarSampler._far_water(17.0, 0.5, true, FarWaterMask.LAND), "OSM water still wins")

## A uniform mask over +-40 km of (lat, lon).
func _uniform(lat: float, lon: float, value: int) -> Dictionary:
	var rect := FarFieldFetcher.window_px(lat, lon, Z, 40000.0)
	var n := 64
	var bytes := PackedByteArray()
	bytes.resize(n * n)
	bytes.fill(value)
	return {"zoom": Z, "origin_px": Vector2(rect.position), "size_px": rect.size, "n": n, "bytes": bytes,
		"image": Image.create_from_data(n, n, false, Image.FORMAT_L8, bytes)}

func _native_colors() -> void:
	if not ClassDB.class_exists("FarKernels"):
		print("FAR WATER MASK: FarKernels not loaded, native colours skipped")
		return
	var per := 4
	var loops := 3
	var pos := PackedVector3Array()
	for k in loops:
		for j in per:
			var a := TAU * float(j) / float(per)
			pos.append(Vector3(cos(a) * (2000.0 + k * 500.0), 17.0, sin(a) * (2000.0 + k * 500.0)))
	for case in [[FarWaterMask.OCEAN, true], [FarWaterMask.LAND, false], [-1, false]]:
		var params := {"tl": 1000.0, "sl": 3000.0, "forest": Color(0.2, 0.3, 0.1), "meadow": Color(0.3, 0.4, 0.2),
			"water_level_m": 0.5, "datum_m": 0.0, "y_scale": 1.0, "wbounds": Rect2(),
			"lat": 60.168, "lon": 24.953, "m2u": WorldScale.metres_to_units(),
			"water_mask": {} if case[0] < 0 else FarWaterMask.native_params(_uniform(60.168, 24.953, case[0]))}
		var out: Array = ClassDB.class_call_static("FarKernels", "ring_colors", pos, loops, per, params, [])
		var cols: PackedColorArray = out[1]
		var wet := 0
		for c in cols:
			if c.a < 0.5:
				wet += 1
		_check(wet == (cols.size() if case[1] else 0),
			"native ring colours with mask %d: %d/%d wet" % [case[0], wet, cols.size()])

func _place() -> LocationData:
	var data := LocationData.new()
	data.latitude = 60.168
	data.longitude = 24.953
	data.grid_size = 16
	data.heights.resize(16 * 16)
	data.heights.fill(2.0)
	data.far_grid_size = 4
	data.far_heights.resize(16)
	data.far_heights.fill(17.0)
	return data

func _sea_level() -> void:
	var data := _place()
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var x := 5000.0 * m2u
	var uv := FarSurface.merc_uv(data, 5000.0, 0.0)
	var raised := FarSampler._mid_dem_height_uv(data, ground, 100000.0 * m2u, x, 0.0, uv.x, uv.y)
	_check(absf(ground.asl_y(raised) - 17.0) < 0.01, "without a mask the raised sea keeps its DEM height")
	data.far_water_mask = _uniform(data.latitude, data.longitude, FarWaterMask.OCEAN)
	var flat := FarSampler._mid_dem_height_uv(data, ground, 100000.0 * m2u, x, 0.0, uv.x, uv.y)
	_check(absf(ground.asl_y(flat)) < 0.01, "open sea on the mask lies at sea level: %.2f m" % ground.asl_y(flat))
	_check(absf(FarSampler._mid_dem_height(data, ground, 100000.0 * m2u, x, 0.0) - flat) < 0.01,
		"the metre path flattens the same sea")
	data.far_water_mask = _uniform(data.latitude, data.longitude, FarWaterMask.INLAND)
	var lake := FarSampler._mid_dem_height_uv(data, ground, 100000.0 * m2u, x, 0.0, uv.x, uv.y)
	_check(absf(ground.asl_y(lake) - 17.0) < 0.01, "a lake keeps its own level")

func _coast_bias() -> void:
	var data := _place()
	var zoom := 13
	var rect := FarFieldFetcher.window_px(data.latitude, data.longitude, zoom, 4000.0)
	var heights := PackedFloat32Array()
	heights.resize(rect.size.x * rect.size.y)
	for i in heights.size():
		heights[i] = 17.0 + 0.3 * float(i % 3)
	data.dem_rings = [{"zoom": zoom, "origin_px": Vector2(rect.position), "width": rect.size.x,
		"height": rect.size.y, "heights": heights, "reach_m": 4000.0}]
	_check(CoastalDem.estimate_from_mask(data) == 0.0, "no mask, no mask estimate")
	data.far_water_mask = _uniform(data.latitude, data.longitude, FarWaterMask.LAND)
	_check(CoastalDem.estimate_from_mask(data) == 0.0, "an inland mask measures nothing")
	data.far_water_mask = _uniform(data.latitude, data.longitude, FarWaterMask.OCEAN)
	var bias := CoastalDem.estimate_from_mask(data)
	_check(absf(bias - 17.3) < 0.31, "a raised open sea measures its bias: %.2f" % bias)
	for i in heights.size():
		heights[i] = 0.2
	data.dem_rings[0]["heights"] = heights
	_check(CoastalDem.estimate_from_mask(data) == 0.0, "a sea already at sea level is left alone")

# --- A minimal MVT encoder (one layer, polygon features). ---

## `features`: [[value index, rings]], rings of tile-unit Vector2 points.
func _tile(layer: String, features: Array, values: Array) -> PackedByteArray:
	var body := PackedByteArray()
	_varint(body, 15 << 3)
	_varint(body, 2)
	_bytes(body, 1, layer.to_utf8_buffer())
	for f: Array in features:
		var feat := PackedByteArray()
		var tags := PackedByteArray()
		_varint(tags, 0)
		_varint(tags, int(f[0]))
		_bytes(feat, 2, tags)
		_varint(feat, 3 << 3)
		_varint(feat, MvtReader.POLYGON)
		var geom := PackedByteArray()
		var cx := 0
		var cy := 0
		for ring: Array in f[1]:
			for i in ring.size():
				var p: Vector2 = ring[i]
				if i == 0:
					_varint(geom, 1 | (1 << 3))
				elif i == 1:
					_varint(geom, 2 | ((ring.size() - 1) << 3))
				_varint(geom, _zigzag(int(p.x) - cx))
				_varint(geom, _zigzag(int(p.y) - cy))
				cx = int(p.x)
				cy = int(p.y)
			_varint(geom, 7 | (1 << 3))
		_bytes(feat, 4, geom)
		_bytes(body, 2, feat)
	if not values.is_empty():
		_bytes(body, 3, "class".to_utf8_buffer())
	for v: String in values:
		var val := PackedByteArray()
		_bytes(val, 1, v.to_utf8_buffer())
		_bytes(body, 4, val)
	_varint(body, 5 << 3)
	_varint(body, 4096)
	var tile := PackedByteArray()
	_bytes(tile, 3, body)
	return tile

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
