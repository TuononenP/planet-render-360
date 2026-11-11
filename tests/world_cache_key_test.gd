extends SceneTree

## World cache key and save pump: godot --headless --script tests/world_cache_key_test.gd
## A world built after a far DEM / far-field fetch fell back (procedural
## backdrop, no rings, no drapes) must not share a key with the world
## built from the real far data, or a revisit on a good connection would
## load the degraded one.

func _init() -> void:
	_run()

func _data() -> LocationData:
	var d := LocationData.new()
	d.latitude = 37.775
	d.longitude = -122.419
	d.climate = {"t_warm_c": 15.0}
	return d

func _run() -> void:
	var failures: Array[String] = []
	var good := _data()
	good.far_heights = PackedFloat32Array([1.0, 2.0, 3.0])
	good.dem_rings = [{"zoom": 10}]
	good.far_drapes = [{"zoom": 10}]
	var bare := _data()
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("world without far heights, rings and drapes shares the key of one with them")
	for layer in ["far_heights", "dem_rings", "far_drapes"]:
		var d := _data()
		d.far_heights = good.far_heights
		d.dem_rings = good.dem_rings
		d.far_drapes = good.far_drapes
		d.set(layer, PackedFloat32Array() if layer == "far_heights" else [])
		if WorldCache.key(d) == WorldCache.key(good):
			failures.append("dropping only %s leaves the key unchanged" % layer)
	if WorldCache.key(good) != WorldCache.key(good):
		failures.append("key is not stable for the same data")
	good.far_towers = [{"height": 50.0}]
	bare.far_towers = [{"height": 51.0}]
	bare.far_heights = good.far_heights
	bare.dem_rings = good.dem_rings
	bare.far_drapes = good.far_drapes
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different far-city payloads of the same size must not share a world")
	bare.far_towers = good.far_towers
	good.pois = [{"name": "First"}]
	bare.pois = [{"name": "Second"}]
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different POIs of the same size must not share a world")
	bare.pois = good.pois
	for layer in ["trees", "barriers", "railways", "street_furniture", "piers", "landmark_candidates"]:
		good.set(layer, [{"x": 1.0}])
		bare.set(layer, [{"x": 2.0}])
		if WorldCache.key(good) == WorldCache.key(bare):
			failures.append("different %s payloads of the same size must not share a world" % layer)
		bare.set(layer, good.get(layer))
	good.seed_value = 10
	bare.seed_value = 11
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different generation seeds must not share a world")
	bare.seed_value = good.seed_value
	good.view = {"eye_lat": 48.85, "eye_lon": 2.35, "bearing": 0.0}
	bare.view = {"eye_lat": 48.86, "eye_lon": 2.35, "bearing": 0.0}
	if WorldCache.key(good) != WorldCache.key(bare):
		failures.append("the opening eye must not change the world key (the entry records it)")
	bare.view = good.view.duplicate()
	bare.view["bearing"] = 90.0
	if WorldCache.key(good) != WorldCache.key(bare):
		failures.append("a camera bearing alone must not change the world key")
	bare.focus = {"name": "landmark"}
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("focus presence can change the prop placement centre")
	bare.focus = {}
	good.landcover_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([50]))
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("a world missing land cover must not share the populated key")
	bare.landcover_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([10]))
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different raster contents must not share a world key")
	good.landcover_image = Image.create_from_data(1, 2, false, Image.FORMAT_L8, PackedByteArray([10, 50]))
	bare.landcover_image = Image.create_from_data(2, 1, false, Image.FORMAT_L8, PackedByteArray([10, 50]))
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("raster dimensions must participate in the world key")
	WorldCache.dir_override = "user://isolated-world-cache"
	var paths := WorldCache._paths(good)
	if not str(paths["scene"]).begins_with(WorldCache.dir_override + "/") \
			or not str(paths["ground"]).begins_with(WorldCache.dir_override + "/"):
		failures.append("test cache override must contain both files")
	WorldCache.dir_override = ""
	# A second save for the same key must not share a temporary file.
	var gate := Semaphore.new()
	var writer := Thread.new()
	writer.start(func() -> void: gate.wait())
	WorldCache._save_threads[paths["scene"]] = writer
	if not WorldCache._save_in_progress(paths["scene"]):
		failures.append("an active save must block another save for the same scene")
	if WorldCache._save_in_progress(str(paths["scene"]) + ".other"):
		failures.append("a save for another scene must remain independent")
	gate.post()
	writer.wait_to_finish()
	if WorldCache._save_in_progress(paths["scene"]):
		failures.append("a completed save must not block a later save")
	# A cached world is reused while the eye stays near the one it was built around.
	var eye := _data()
	eye.latitude = 60.168
	eye.longitude = 24.953
	eye.quality_preset = RenderSettings.Preset.ULTRA
	eye.view = {"lat": 60.168, "lon": 24.953, "eye_lat": 60.1657, "eye_lon": 24.9558}
	var built := View360.spawn_xz(eye)
	if not WorldCache.eye_fits(built, eye):
		failures.append("the eye a world was built around must reuse it")
	eye.view = {"lat": 60.168, "lon": 24.953, "eye_lat": 60.167408, "eye_lon": 24.953232}
	var moved := built.distance_to(View360.spawn_xz(eye))
	if absf(moved - 237.0) > 10.0:
		failures.append("Helsinki reopen eye should stand ~237 m from the preset eye, got %.0f" % moved)
	if not WorldCache.eye_fits(built, eye):
		failures.append("a reopen ~237 m from the built eye must reuse the world")
	# A reopen reaches as far as a walk inside the open world, on every
	# preset and platform: ~400 m reuses, ~650 m rebuilds.
	for p in range(4):
		eye.quality_preset = p
		if not WorldCache.eye_fits(built, eye):
			failures.append("preset %d should reuse a world ~237 m away" % p)
	eye.quality_preset = RenderSettings.Preset.ULTRA
	eye.view = {"lat": 60.168, "lon": 24.953, "eye_lat": 60.1657 + 650.0 / 111320.0, "eye_lon": 24.9558}
	if WorldCache.eye_fits(built, eye):
		failures.append("a reopen ~650 m from the built eye must rebuild")
	eye.view = {"lat": 60.168, "lon": 24.953, "eye_lat": 60.1657 + 400.0 / 111320.0, "eye_lon": 24.9558}
	if not WorldCache.eye_fits(built, eye):
		failures.append("a reopen ~400 m from the built eye must reuse the world")
	# Measured from the scene centre too: past the walk circle (and past
	# where the world's own eye stood) the detailed extent runs out.
	eye.view = {"lat": 60.168, "lon": 24.953, "eye_lat": 60.168 - 900.0 / 111320.0, "eye_lon": 24.953}
	var out := View360.spawn_xz(eye).normalized()
	if WorldCache.eye_fits(out * 400.0, eye):
		failures.append("a reopen 900 m from the centre must rebuild a world built 400 m out")
	if not WorldCache.eye_fits(out * 950.0, eye):
		failures.append("an off-centre preset eye may reopen as far out as it was built")
	# Debug fingerprint: fetch-only data sources are skipped, and nothing a
	# build runs may use one (else editing it could leave a stale world on
	# screen): not the builders, not the data helpers they call.
	_check_skipped_sources(failures)
	if WorldCache._state_fits({}, eye):
		failures.append("an entry without a recorded eye (old format) must rebuild")
	# Save pump: a slow frame gets a bigger slice, a quit takes the most.
	if WorldCache.pump_budget_us(7000) != WorldCache.PUMP_US:
		failures.append("a fast frame should keep the base pump slice")
	if WorldCache.pump_budget_us(28000) <= WorldCache.PUMP_US:
		failures.append("a 28 ms frame should pump longer than the base slice")
	if WorldCache.pump_budget_us(10000000) != WorldCache.PUMP_MAX_US:
		failures.append("the pump slice should be capped")
	WorldCache.hurry = true
	if WorldCache.pump_budget_us(7000) != WorldCache.HURRY_US:
		failures.append("quitting should take the hurry slice")
	WorldCache.hurry = false
	if failures.is_empty():
		print("WORLD CACHE KEY PASS")
		quit(0)
	else:
		for f in failures:
			printerr("WORLD CACHE KEY FAIL: ", f)
		quit(1)

## Data scripts the builders name that run before a build (fetching what
## LocationData carries), not inside it: they may use skipped sources.
const FETCH_TIME := ["cache_store.gd", "far_city_fetcher.gd", "ground_model_fetcher.gd",
	"osm_fetcher.gd", "satellite_fetcher.gd", "tile_fetcher.gd"]

## Source text with comments dropped, so a doc mention is not a use.
func _code(path: String) -> String:
	var out := PackedStringArray()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var hash_at := line.find("#")
		out.append(line if hash_at < 0 else line.substr(0, hash_at))
	return "\n".join(out)

func _class_of(path: String) -> String:
	var m := RegEx.create_from_string("(?m)^class_name\\s+(\\w+)").search(
		FileAccess.get_file_as_string(path))
	return "" if m == null else m.get_string(1)

func _check_skipped_sources(failures: Array[String]) -> void:
	var build_files: Array[String] = []
	for d in ["res://scripts/generation", "res://scripts/render"]:
		build_files.append_array(WorldCache._source_files(d))
	var build_src := ""
	for f in build_files:
		build_src += _code(f) + "\n"
	# Data helpers a build runs: the fingerprinted data files the builders name.
	for f in WorldCache._source_files("res://scripts/data"):
		var c := _class_of(f)
		if f.get_file() in FETCH_TIME or c == "":
			continue
		if RegEx.create_from_string("\\b%s\\b" % c).search(build_src) != null:
			build_files.append(f)
	for f in WorldCache.SOURCE_SKIP:
		if not FileAccess.file_exists(f):
			failures.append("skipped source %s no longer exists" % f)
			continue
		var c := _class_of(f)
		var uses := RegEx.create_from_string("\\b%s\\b" % c) if c != "" else null
		for b in build_files:
			if b == "res://scripts/render/world_cache.gd":
				continue  # lists the skipped files; runs none of them
			var code := _code(b)
			if code.contains(f.get_file()) or (uses != null and uses.search(code) != null):
				failures.append("%s uses skipped source %s: keep it in the fingerprint" % [b, f])
