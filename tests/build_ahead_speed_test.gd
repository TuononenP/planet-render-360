extends SceneTree

## Unit tests for the build-ahead speed optimisations:
## - VegetationMaskNative exact parity with GDScript VegetationMask
## - OsmParseCache LRU hit / eviction
## - FarCityFetcher.remap_far coordinate shift
## - LandmarkImpostor.build_cached_stripped fast path

var _fails: Array[String] = []

func _init() -> void:
	_test_vegetation_mask_parity()
	_test_osm_parse_cache()
	_test_postpass_poi_stamp()
	_test_far_city_remap()
	_test_landmark_impostor_cached_stripped()
	_test_vehicle_plans_split()
	if _fails.is_empty():
		print("BUILD AHEAD SPEED TEST OK")
		quit(0)
	else:
		for f in _fails:
			printerr("BUILD AHEAD SPEED FAIL: ", f)
		quit(1)

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

func _test_vegetation_mask_parity() -> void:
	if not ClassDB.class_exists("VegetationMaskNative"):
		print("VegetationMaskNative not loaded; skipping native parity check")
		return
	var data := LocationData.new()
	data.grid_size = 32
	data.heights = PackedFloat32Array()
	data.heights.resize(32 * 32)
	data.heights.fill(5.0)
	data.water_level = -3.0
	data.buildings = [
		{"footprint": PackedVector2Array([Vector2(10, 10), Vector2(30, 10), Vector2(30, 25), Vector2(10, 25)]),
			"x": 20.0, "z": 17.5, "size_x": 20.0, "size_z": 15.0},
		{"x": -40.0, "z": -30.0, "size_x": 16.0, "size_z": 12.0},
	]
	data.roads = [
		{"points": PackedVector2Array([Vector2(-60, 0), Vector2(60, 0)]), "width_m": 8.0, "class": "primary", "sidewalk": 3},
		{"points": PackedVector2Array([Vector2(0, -60), Vector2(0, 60)]), "width_m": 3.0, "class": "footway", "sidewalk": 0},
	]
	data.land_polygons = [
		{"class": "grass", "points": PackedVector2Array([Vector2(-80, -80), Vector2(80, -80), Vector2(80, 80), Vector2(-80, 80)]),
			"holes": [PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])]},
		{"class": "water", "points": PackedVector2Array([Vector2(40, 40), Vector2(70, 40), Vector2(70, 70), Vector2(40, 70)])},
	]
	var g := GroundTruth.new(data)
	VegetationMask.force_script = true
	var script_mask := VegetationMask.new(data, g)
	VegetationMask.force_script = false
	var native_mask := VegetationMask.new(data, g)
	_check(native_mask._native != null, "VegetationMask should instantiate VegetationMaskNative")
	var trees := [Vector3(-20, 5, -20), Vector3(15, 5, -35)]
	script_mask.mark_trees(trees)
	native_mask.mark_trees(trees)
	var masks := [VegetationMask.BUILDING, VegetationMask.ROAD, VegetationMask.ROAD_EDGE,
		VegetationMask.WATER, VegetationMask.TREE, VegetationMask.PAVED,
		VegetationMask.BUILDING | VegetationMask.ROAD_EDGE | VegetationMask.WATER | VegetationMask.PAVED]
	for z in range(-75, 76, 5):
		for x in range(-75, 76, 5):
			var fx := float(x)
			var fz := float(z)
			if script_mask.cover_at(fx, fz) != native_mask.cover_at(fx, fz):
				_fails.append("cover_at mismatch at (%d,%d)" % [x, z])
				return
			if absf(script_mask.built_fraction(fx, fz) - native_mask.built_fraction(fx, fz)) > 1e-4:
				_fails.append("built_fraction mismatch at (%d,%d)" % [x, z])
				return
			for m in masks:
				for margin in [0.0, 1.5]:
					if script_mask.blocked(fx, fz, m, margin) != native_mask.blocked(fx, fz, m, margin):
						_fails.append("blocked mismatch at (%d,%d) mask=%d margin=%.1f" % [x, z, m, margin])
						return

func _test_osm_parse_cache() -> void:
	OsmParseCache.clear()
	var k1 := OsmParseCache.make_key(60.1680, 24.9530, PackedStringArray(["100", "20"]))
	var k2 := OsmParseCache.make_key(60.1684, 24.9530, PackedStringArray(["100", "20"]))
	_check(k1 != k2, "OsmParseCache.make_key must distinguish nearby coords inside one quant cell")
	OsmParseCache.store(k1, {"buildings": [1, 2]})
	var hit := OsmParseCache.take(k1)
	_check(hit.size() == 1 and (hit["buildings"] as Array).size() == 2, "OsmParseCache should return stored entry")
	_check(OsmParseCache.take(k1).is_empty(), "OsmParseCache.take should consume entry to prevent mutation aliasing")
	OsmParseCache.store(k1, {"buildings": [1]})
	for i in range(OsmParseCache.MAX_ENTRIES + 2):
		OsmParseCache.store("k_%d" % i, {"v": i})
	_check(OsmParseCache.take(k1).is_empty(), "OsmParseCache should evict oldest entries past MAX_ENTRIES")
	OsmParseCache.clear()

func _test_postpass_poi_stamp() -> void:
	var raw := '{"elements":[]}'
	var stamped := PostpassFallback.stamp_pois(raw)
	_check(stamped.begins_with(PostpassFallback.POI_STAMP), "stamp_pois must prefix POI_STAMP")
	_check(PostpassFallback.stamp_pois(stamped) == stamped, "stamp_pois should be idempotent")
	var js: Variant = JSON.parse_string(stamped)
	_check(js is Dictionary and bool((js as Dictionary).get("postpass_pois", false)),
		"stamped payload must parse as valid JSON with postpass_pois marker")
	var parsed := OsmParser.parse_features(stamped, 60.168, 24.953)
	_check(parsed is Dictionary and parsed.has("buildings"), "OsmParser must accept stamped payload")

func _test_far_city_remap() -> void:
	var lu := [{"class": "residential", "points": PackedVector2Array([Vector2(10, 20), Vector2(30, 40)]), "holes": []}]
	var tw := [{"x": 100.0, "z": 200.0, "footprint": PackedVector2Array([Vector2(95, 195), Vector2(105, 205)])}]
	var out := FarCityFetcher.remap_far(lu, tw, Vector2(-50.0, 25.0))
	var lu0: Dictionary = out["landuse"][0]
	var tw0: Dictionary = out["towers"][0]
	_check((lu0["points"] as PackedVector2Array)[0].is_equal_approx(Vector2(-40.0, 45.0)),
		"remap_far should shift landuse points by offset")
	_check(is_equal_approx(float(tw0["x"]), 50.0) and is_equal_approx(float(tw0["z"]), 225.0),
		"remap_far should shift tower x/z by offset")
	# Original arrays must not be mutated.
	_check(is_equal_approx(float(tw[0]["x"]), 100.0), "remap_far must not mutate input tower dict")

func _test_landmark_impostor_cached_stripped() -> void:
	LandmarkImpostor.clear_view_cache()
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(20.0, 50.0, 20.0)
	box.mesh = bm
	var model := Node3D.new()
	model.name = "Model"
	model.add_child(box)
	var root := Node3D.new()
	root.name = "TestTower"
	root.add_child(model)
	var mode := LandmarkImpostor.apply_if_far(root, LandmarkImpostor.STRIP_REAL_M + 500.0, "test_tower_cache", true)
	_check(mode == "stripped", "far landmark past STRIP_REAL_M should strip real parts")
	var stripped_count := root.get_child_count()
	root.free()
	var fast := LandmarkImpostor.build_cached_stripped("test_tower_cache", LandmarkImpostor.STRIP_REAL_M + 800.0)
	_check(fast != null, "build_cached_stripped should return cached impostor node")
	if fast != null:
		_check(fast.get_child_count() == stripped_count and stripped_count == 1 and fast.get_child(0) is MeshInstance3D,
			"cached stripped node should match stripped child tree (1 Impostor child)")
		_check(bool(fast.get_meta("impostor_only", false)), "cached stripped node should be marked impostor_only")
		fast.free()
	_check(LandmarkImpostor.build_cached_stripped("test_tower_cache", LandmarkImpostor.STRIP_REAL_M - 100.0) == null,
		"build_cached_stripped must return null within STRIP_REAL_M")
	LandmarkImpostor.clear_view_cache()

func _test_vehicle_plans_split() -> void:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	data.grid_size = 16
	data.heights = PackedFloat32Array()
	data.heights.resize(16 * 16)
	data.heights.fill(5.0)
	data.water_level = -3.0
	data.railways = [{"class": "tram", "points": PackedVector2Array([Vector2(-100, 0), Vector2(100, 0)])}]
	var ground := GroundTruth.new(data)
	var plans := VehicleMover.compute_plans(data, ground)
	_check(plans.has("Tram") and plans.has("Train"), "compute_plans should return Tram and Train plans")
	_check(not data.has_meta(VehicleMover.PLANS_META), "compute_plans must not mutate LocationData meta")
	VehicleMover.store_plans(data, ground, plans)
	_check(data.has_meta(VehicleMover.PLANS_META) and data.get_meta(VehicleMover.PLANS_GROUND) == ground,
		"store_plans should record PLANS_META and PLANS_GROUND on LocationData")
