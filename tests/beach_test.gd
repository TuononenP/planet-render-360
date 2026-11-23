extends SceneTree

## Beach sand palette, dune strip, lifeguard towers, umbrellas & promenade wall (MI-7.2):
##   tools/godot_bg.sh --headless --path . --script tests/beach_test.gd

var failures: Array[String] = []

func _init() -> void:
	_check_palette()
	_check_meshes()
	_check_synthetic_beach()
	_check_bundled_miami_beach()
	if failures.is_empty():
		print("BEACH DRESSING OK: Miami sand palette, 8 lifeguard variants, dune strip, resort umbrellas & strict sand safety")
		quit(0)
	else:
		for f: String in failures:
			printerr("BEACH DRESSING FAIL: ", f)
		quit(1)

func _check_palette() -> void:
	var miami := LocationData.new()
	miami.latitude = 25.7810
	miami.longitude = -80.1300
	var ov_miami := BeachDressing.palette_overrides(miami)
	_expect(ov_miami.has("sand") and (ov_miami["sand"] as Color).is_equal_approx(BeachDressing.MIAMI_SAND),
		"Miami Beach coordinates get pale MIAMI_SAND override")

	var other := LocationData.new()
	other.latitude = 43.7310
	other.longitude = 7.4209
	var ov_other := BeachDressing.palette_overrides(other)
	_expect(ov_other.is_empty(), "Non-Miami coordinates receive empty beach palette overrides")

	var sand_x := int(GroundMaterial.ID["sand"])
	var pal_miami := GroundMaterial.palette(LocationData.Season.SUMMER, Color(0, 0, 0, 0), ov_miami)
	var pal_default := GroundMaterial.palette(LocationData.Season.SUMMER, Color(0, 0, 0, 0), ov_other)
	var c_miami := pal_miami.get_pixel(sand_x, 1)
	var c_default := pal_default.get_pixel(sand_x, 1)
	var base_sand := MaterialLibrary.ground_color("sand")
	_expect(absf(c_miami.r - BeachDressing.MIAMI_SAND.r) < 0.012
		and absf(c_miami.g - BeachDressing.MIAMI_SAND.g) < 0.012
		and absf(c_miami.b - BeachDressing.MIAMI_SAND.b) < 0.012,
		"GroundMaterial.palette uses MIAMI_SAND for Miami, got %s" % str(c_miami))
	_expect(absf(c_default.r - base_sand.r) < 0.012
		and absf(c_default.g - base_sand.g) < 0.012
		and absf(c_default.b - base_sand.b) < 0.012,
		"GroundMaterial.palette leaves non-Miami sand unchanged, got %s vs %s" % [str(c_default), str(base_sand)])
	_expect(absf(c_miami.b - c_default.b) > 0.05,
		"MIAMI_SAND is visibly paler/cooler than default sand (%s vs %s)" % [str(c_miami), str(c_default)])

func _check_meshes() -> void:
	for v: int in range(8):
		var m := BeachDressing.mesh("lifeguard_%d" % v)
		var sc := m.get_surface_count()
		_expect(sc >= 2 and sc <= 14, "lifeguard_%d surface count in 2..14, got %d" % [v, sc])
		var min_y := INF
		var max_y := -INF
		var tris := 0
		for s: int in range(sc):
			var arr := m.surface_get_arrays(s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			tris += (idx as PackedInt32Array).size() / 3 if idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty() else verts.size() / 3
			for vt: Vector3 in verts:
				min_y = minf(min_y, vt.y)
				max_y = maxf(max_y, vt.y)
		_expect(tris > 40 and tris <= 120000, "lifeguard_%d triangle count valid, got %d" % [v, tris])
		_expect(min_y >= -0.5, "lifeguard_%d nothing below y=-0.5, got %.2f" % [v, min_y])
		_expect(max_y >= 4.4 and max_y <= 6.0, "lifeguard_%d true-metre height ~4.6-5.4 m, got %.2f" % [v, max_y])
	for key: String in ["umbrella_0", "umbrella_4", "dune_post", "dune_oats", "volleyball_court", "promenade_wall"]:
		var m2 := BeachDressing.mesh(key)
		_expect(m2.get_surface_count() >= 2, "%s builds multi-surface mesh" % key)

func _synthetic_coastal_data(preset: int, seed_val: int = 1337) -> LocationData:
	var m := WorldScale.metres_to_units()
	var d := LocationData.new()
	d.latitude = 25.7810
	d.longitude = -80.1300
	d.country = "US"
	d.quality_preset = preset
	d.seed_value = seed_val
	d.grid_size = 64
	d.heights.resize(64 * 64)
	d.heights.fill(2.2)
	d.water_level = 0.0
	d.land_polygons = [
		{"class": "sand", "points": PackedVector2Array([
			Vector2(0.0, -220.0) * m, Vector2(62.0, -220.0) * m,
			Vector2(62.0, 220.0) * m, Vector2(0.0, 220.0) * m]), "holes": []},
		{"class": "water", "tidal": true, "points": PackedVector2Array([
			Vector2(62.0, -220.0) * m, Vector2(260.0, -220.0) * m,
			Vector2(260.0, 220.0) * m, Vector2(62.0, 220.0) * m]), "holes": []},
		{"class": "grass", "sward": "mown", "points": PackedVector2Array([
			Vector2(-45.0, -220.0) * m, Vector2(0.0, -220.0) * m,
			Vector2(0.0, 220.0) * m, Vector2(-45.0, 220.0) * m]), "holes": []},
	]
	# Building encroaching onto the sand edge + one valid lifeguard POI and one inside the building
	var bfp := PackedVector2Array([
		Vector2(-8.0, -20.0) * m, Vector2(16.0, -20.0) * m,
		Vector2(16.0, 20.0) * m, Vector2(-8.0, 20.0) * m])
	d.buildings = [{
		"x": 4.0 * m, "z": 0.0, "size_x": 24.0 * m, "size_z": 40.0 * m,
		"height": 18.0, "levels": 5, "height_source": "levels", "footprint": bfp, "parts": []
	}]
	d.roads = [{
		"class": "footway", "width_m": 3.0, "surface": "concrete",
		"points": PackedVector2Array([Vector2(-2.5, -220.0) * m, Vector2(-2.5, 220.0) * m])
	}]
	d.pois = [
		{"x": 38.0 * m, "z": -70.0 * m, "category": "emergency", "kind": "lifeguard", "name": "Tower 7"},
		{"x": 8.0 * m, "z": 0.0, "category": "emergency", "kind": "lifeguard", "name": "Blocked Inside Building"},
	]
	return d

func _check_synthetic_beach() -> void:
	var m := WorldScale.metres_to_units()
	var d0 := _synthetic_coastal_data(RenderSettings.Preset.FAST)
	var g0 := GroundTruth.new(d0)
	var m0 := VegetationMask.new(d0, g0)
	var p0 := BeachDressing.plan(d0, g0, m0, m)
	_expect(int(p0["total"]) == 0 and (p0["items"] as Array).is_empty(),
		"Synthetic preset 0 (Fast) places 0 beach props")

	var d1 := _synthetic_coastal_data(RenderSettings.Preset.BALANCED)
	var g1 := GroundTruth.new(d1)
	var m1 := VegetationMask.new(d1, g1)
	var p1 := BeachDressing.plan(d1, g1, m1, m)
	var c1: Dictionary = p1["counts"]
	_expect(int(c1["lifeguard"]) >= 2 and int(p1["total"]) == int(c1["lifeguard"])
		and int(p1["total"]) <= BeachDressing.PRESET_CAP[1],
		"Synthetic preset 1 (Balanced) places lifeguard towers only within cap, got %s" % str(c1))
	_verify_all_safe("synthetic_p1", p1["items"] as Array, d1, g1, m1)

	var d3 := _synthetic_coastal_data(RenderSettings.Preset.ULTRA, 9001)
	var g3 := GroundTruth.new(d3)
	var m3 := VegetationMask.new(d3, g3)
	var p3 := BeachDressing.plan(d3, g3, m3, m)
	var c3: Dictionary = p3["counts"]
	_expect(int(c3["lifeguard"]) >= 2, "Synthetic Ultra places lifeguard towers, got %s" % str(c3))
	_expect(int(c3["umbrella"]) >= 4, "Synthetic Ultra places resort umbrellas, got %s" % str(c3))
	_expect(int(c3["dune_post"]) >= 4 and int(c3["dune_oats"]) >= 4,
		"Synthetic Ultra places dune fence posts and sea oats, got %s" % str(c3))
	_expect(int(c3["volleyball"]) >= 1 and int(c3["promenade_wall"]) >= 4,
		"Synthetic Ultra places volleyball court and promenade border wall, got %s" % str(c3))
	_expect(int(p3["total"]) <= BeachDressing.PRESET_CAP[3],
		"Synthetic Ultra respects PRESET_CAP[3]=%d, got %d" % [BeachDressing.PRESET_CAP[3], int(p3["total"])])
	_verify_all_safe("synthetic_p3", p3["items"] as Array, d3, g3, m3)

	# Determinism: same seed_value -> identical positions and variants
	var p3_again := BeachDressing.plan(_synthetic_coastal_data(RenderSettings.Preset.ULTRA, 9001), g3, m3, m)
	_verify_identical("synthetic_determinism", p3["items"] as Array, p3_again["items"] as Array)

	# Build scene node check
	var root := Node3D.new()
	var built_n := BeachDressing.build(root, d3, g3, m3)
	_expect(built_n == int(p3["total"]) and root.has_node("BeachDressing"),
		"BeachDressing.build emits BeachDressing holder with %d instances" % built_n)
	root.free()

func _check_bundled_miami_beach() -> void:
	var raw := BundledOsm.read("miami_beach_detailed")
	_expect(raw != "", "Bundled miami_beach_detailed snapshot loads")
	if raw == "":
		return
	var lat := 25.7810
	var lon := -80.1300
	var parsed := OsmParser.parse_features(raw, lat, lon)
	var lg_pois := 0
	for p_v: Variant in parsed.get("pois", []):
		if p_v is Dictionary and str((p_v as Dictionary).get("kind", "")) == "lifeguard":
			lg_pois += 1
	_expect(lg_pois >= 8, "miami_beach_detailed parses >= 8 emergency=lifeguard POIs, got %d" % lg_pois)

	var m := WorldScale.metres_to_units()
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.country = "US"
	data.seed_value = 2026
	data.grid_size = 64
	data.heights.resize(64 * 64)
	data.heights.fill(2.2)
	data.water_level = 0.0
	data.buildings = parsed.get("buildings", [])
	data.roads = parsed.get("roads", [])
	data.land_polygons = parsed.get("land", [])
	data.waterways = parsed.get("waterways", [])
	data.barriers = parsed.get("barriers", [])
	data.trees = parsed.get("trees", [])
	data.street_furniture = parsed.get("furniture", [])
	data.pois = parsed.get("pois", [])
	data.piers = parsed.get("piers", [])
	data.shore_structures = parsed.get("shore_structures", [])

	var ground := GroundTruth.new(data)
	var mask := VegetationMask.new(data, ground)

	data.quality_preset = RenderSettings.Preset.FAST
	var pf := BeachDressing.plan(data, ground, mask, m)
	_expect(int(pf["total"]) == 0, "Miami Beach preset 0 places 0 props")

	data.quality_preset = RenderSettings.Preset.BALANCED
	var pb := BeachDressing.plan(data, ground, mask, m)
	_expect(int((pb["counts"] as Dictionary)["lifeguard"]) >= 5
		and int(pb["total"]) <= BeachDressing.PRESET_CAP[1],
		"Miami Beach preset 1 places mapped lifeguard towers <= cap, got %s" % str(pb["counts"]))
	_verify_all_safe("miami_beach_p1", pb["items"] as Array, data, ground, mask)

	data.quality_preset = RenderSettings.Preset.ULTRA
	var pu := BeachDressing.plan(data, ground, mask, m)
	var cu: Dictionary = pu["counts"]
	_expect(int(cu["lifeguard"]) >= 5 and int(cu["umbrella"]) >= 10
		and int(pu["total"]) <= BeachDressing.PRESET_CAP[3],
		"Miami Beach preset 3 places lifeguards + beach props <= PRESET_CAP[3], got %s" % str(cu))
	_verify_all_safe("miami_beach_p3", pu["items"] as Array, data, ground, mask)

	var pu2 := BeachDressing.plan(data, ground, mask, m)
	_verify_identical("miami_beach_determinism", pu["items"] as Array, pu2["items"] as Array)

func _verify_all_safe(tag: String, items: Array, data: LocationData, ground: GroundTruth,
		mask: VegetationMask) -> void:
	var bad_inside := 0
	var bad_sand := 0
	var bad_water := 0
	var bad_bldg := 0
	var bad_mask := 0
	for it_v: Variant in items:
		var it: Dictionary = it_v
		var x := float(it["x"])
		var z := float(it["z"])
		if not ground.is_inside(x, z):
			bad_inside += 1
		if ground.land_class_at(x, z) != "sand":
			bad_sand += 1
		if ground.water_at(x, z) > 0.0:
			bad_water += 1
		if mask != null and mask.blocked(x, z,
				VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER, 1.2):
			bad_mask += 1
		var pt := Vector2(x, z)
		for b_v: Variant in data.buildings:
			var fp: Variant = (b_v as Dictionary).get("footprint", null)
			if fp is PackedVector2Array and Geometry2D.is_point_in_polygon(pt, fp as PackedVector2Array):
				bad_bldg += 1
				break
	_expect(bad_inside == 0 and bad_sand == 0 and bad_water == 0 and bad_bldg == 0 and bad_mask == 0,
		"%s safety: inside=%d non_sand=%d wet=%d in_bldg=%d mask_blocked=%d (checked %d items)"
		% [tag, bad_inside, bad_sand, bad_water, bad_bldg, bad_mask, items.size()])

func _verify_identical(tag: String, a: Array, b: Array) -> void:
	if a.size() != b.size():
		failures.append("%s: item count mismatch %d vs %d" % [tag, a.size(), b.size()])
		return
	for i: int in range(a.size()):
		var ia: Dictionary = a[i]
		var ib: Dictionary = b[i]
		if not is_equal_approx(float(ia["x"]), float(ib["x"])) \
				or not is_equal_approx(float(ia["z"]), float(ib["z"])) \
				or not is_equal_approx(float(ia["yaw"]), float(ib["yaw"])) \
				or str(ia["mesh"]) != str(ib["mesh"]) \
				or int(ia["variant"]) != int(ib["variant"]):
			failures.append("%s: mismatch at %d: %s vs %s" % [tag, i, str(ia), str(ib)])
			return

func _expect(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
