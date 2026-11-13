extends SceneTree

## OrthoSource / OrthoFetcher / InnerImagery (offline):
## godot --headless --script tests/ortho_source_test.gd
## WMS bbox maths on the slippy pixel grid, coverage, part split, blank
## detection, colour matching, cache paths, the host policy, and the
## inner-mosaic UV map at the orthophoto's z19 / span 15.

var failures: Array[String] = []

func _init() -> void:
	_bbox()
	_coverage()
	_images()
	_inner_map()
	if failures.is_empty():
		print("ORTHO SOURCE OK: bbox, coverage, parts, blank, colour match, inner map")
		quit(0)
	else:
		for f in failures:
			printerr("ORTHO SOURCE FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

## Global slippy pixel (x, y) at `zoom` in float64 (a Vector2 is float32,
## several pixels coarse at z19's 1e8 px world).
func _gpx(lat: float, lon: float, zoom: int) -> PackedFloat64Array:
	var n := 256.0 * pow(2.0, float(zoom))
	return PackedFloat64Array([(lon + 180.0) / 360.0 * n,
		(1.0 - asinh(tan(deg_to_rad(lat))) / PI) / 2.0 * n])

func _bbox() -> void:
	var lat := 60.1680
	var lon := 24.9530
	var r := 6378137.0
	var mx := deg_to_rad(lon) * r
	var my := r * log(tan(PI / 4.0 + deg_to_rad(lat) / 2.0))
	for z in [18, 19]:
		var origin := OrthoFetcher.origin_px(lat, lon, z, 15)
		var bb := OrthoSource.bbox_3857(origin, Vector2(3840, 3840), z)
		_check(mx > bb[0] and mx < bb[2] and my > bb[1] and my < bb[3], "z%d bbox must contain the viewpoint" % z)
		var gp := _gpx(lat, lon, z)
		var fx := (mx - bb[0]) / (bb[2] - bb[0]) * 3840.0
		var fy := (bb[3] - my) / (bb[3] - bb[1]) * 3840.0
		var ex := gp[0] - float(origin.x)
		var ey := gp[1] - float(origin.y)
		_check(absf(fx - ex) < 0.05 and absf(fy - ey) < 0.05,
			"z%d bbox must agree with the slippy pixel grid (off %.3f, %.3f px)" % [z, fx - ex, fy - ey])
	var url := OrthoSource.part_url("hsy_2023", Vector2(0, 0), 1920, 19)
	_check(not HostPolicy.is_blocked(url) and url.contains("crs=EPSG:3857") and url.contains("width=1920"),
		"Part URLs must be WMS 1.3.0 EPSG:3857 at the part size, on an allowed host")
	_check(OrthoSource.parts_for(3840) == 2 and OrthoSource.parts_for(1792) == 1 and OrthoSource.parts_for(2816) == 2,
		"Mosaics split into parts of at most MAX_PART_PX")
	_check(OrthoFetcher.cache_path("hsy_2023", 19, 15, 60.168, 24.953, 3).ends_with("_p3.jpg"),
		"Parts cache per place, zoom, span and part")

func _coverage() -> void:
	_check(OrthoSource.source_for(60.1680, 24.9530, 19, 15) == "hsy_2023", "Central Helsinki is covered")
	_check(OrthoSource.source_for(60.1760, 24.8050, 18, 11) == "hsy_2023", "Tapiola is covered")
	_check(OrthoSource.source_for(59.4370, 24.7536, 18, 7) == "", "Tallinn is not")
	_check(OrthoSource.source_for(60.6040, 24.9, 18, 11) == "", "A mosaic crossing the layer edge is not")

func _images() -> void:
	var flat := Image.create(64, 64, false, Image.FORMAT_RGB8)
	flat.fill(Color(1, 1, 1))
	_check(OrthoSource.is_blank(flat), "A flat white part is blank fill")
	var busy := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			busy.set_pixel(x, y, Color(float(x) / 63.0, float(y) / 63.0, 0.5))
	_check(not OrthoSource.is_blank(busy), "A textured part is imagery")
	# Matching an image to itself is the identity; a darker copy is lifted.
	var same := OrthoSource.colour_match(busy, busy)
	_check((same["gain"] as Vector3).is_equal_approx(Vector3.ONE) and (same["bias"] as Vector3).length() < 1e-4,
		"Self match must be the identity")
	var dark := busy.duplicate() as Image
	for y in 64:
		for x in 64:
			dark.set_pixel(x, y, busy.get_pixel(x, y) * 0.8)
	var lift := OrthoSource.colour_match(dark, busy)
	var gain: Vector3 = lift["gain"]
	_check(gain.x > 1.0 and gain.x <= 1.4, "A darker photo gains toward the reference")

## GroundMaterial.inner_map with an orthophoto source (z19, span 15):
## within half a z19 pixel of the exact path over the inner area.
func _inner_map() -> void:
	var m := WorldScale.metres_to_units()
	var z := 19
	var span := 15
	var size := float(span * SatelliteFetcher.TILE_PX)
	var d := LocationData.new()
	d.latitude = 60.1680
	d.longitude = 24.9530
	d.satellite_inner_origin_px = OrthoFetcher.origin_px(d.latitude, d.longitude, z, span)
	d.satellite_inner_source = {"src": "hsy_2023", "zoom": z, "span": span}
	d.satellite_source = {"source_zoom": 17, "source_span": 13}
	var c17 := TileFetcher.global_pixel(d.latitude, d.longitude, 17)
	d.satellite_origin_px = ((c17 / 256.0).floor() - Vector2(6, 6)) * 256.0
	var map := GroundMaterial.inner_map(d)
	for p in [Vector2(0, 0), Vector2(200, -180), Vector2(-210, 190)]:
		var w: Vector2 = p * m
		# WorldScale.latlon_from_xz in float64 (its Vector2 is ~0.4 m coarse).
		var la := d.latitude - float(w.y) / 110540.0
		var lo := d.longitude + float(w.x) / (111320.0 * cos(deg_to_rad(d.latitude)))
		var g := _gpx(la, lo, z)
		var exact := Vector2((g[0] - float(d.satellite_inner_origin_px.x)) / size,
			(g[1] - float(d.satellite_inner_origin_px.y)) / size)
		var uv := TerrainBuilder.satellite_uv(d, w.x, w.y)
		var fit := Vector2(uv.x * map.x + map.z, uv.y * map.y + map.w)
		_check((exact - fit).length() * size < 0.5,
			"z19 inner map at %s m off by %.2f px" % [p, (exact - fit).length() * size])
