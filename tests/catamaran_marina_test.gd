extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	data.grid_size = 33
	data.heights.resize(33 * 33)
	data.heights.fill(-6.0)
	data.water_level = 0.0
	data.latitude = 43.73
	data.longitude = 7.42
	data.country = "MC"
	data.land_polygons = [{"class": "water", "tidal": true, "points": PackedVector2Array([
		Vector2(-1100, -1100), Vector2(1100, -1100), Vector2(1100, 1100), Vector2(-1100, 1100)])}]
	for z in [-120.0, -40.0, 40.0, 120.0]:
		data.piers.append({"points": PackedVector2Array([Vector2(-250, z), Vector2(250, z)]), "floating": true})
	var ground := GroundTruth.new(data)
	_check(MarinaBuilder.mediterranean(data), "Monaco coastal marina qualifies")
	var plan := MarinaBuilder.plan(data, ground, 1.0)
	var boats: Array = plan["boats"]
	var cats := 0
	for boat in boats:
		if VesselPrototypes.base_kind(boat[3]) == "catamaran":
			cats += 1
	_check(cats > 0, "the Mediterranean fleet includes catamarans")
	_check(var_to_bytes(boats) == var_to_bytes(MarinaBuilder.plan(data, ground, 1.0)["boats"]), "catamaran berths are deterministic")
	for i in boats.size():
		if VesselPrototypes.base_kind(boats[i][3]) != "catamaran":
			continue
		var cat := _bounds(boats[i])
		for j in boats.size():
			if i != j:
				_check(not cat.intersects(_bounds(boats[j])), "full catamaran beam must not overlap another berth")
	# A narrow obstruction intersects only the outer hull, not the centreline.
	data.buildings = [{"x": 3.9, "z": 5.0, "size_x": 1.4, "size_z": 5.0, "height": 2.0,
		"footprint": PackedVector2Array([Vector2(3.2, 2.5), Vector2(4.6, 2.5), Vector2(4.6, 7.5), Vector2(3.2, 7.5)])}]
	var mask := VegetationMask.new(data, ground)
	_check(not mask.blocked(0, 5, VegetationMask.BUILDING, 0.5), "fixture centreline remains clear")
	_check(not MarinaBuilder._wide_wet(ground, Vector2.ZERO, Vector2.DOWN, 10.0, 5.8, 1.0, 0.0, mask),
		"an obstruction at an outer hull must reject a wide berth")
	for region in [[39.56, 2.65, "ES"], [43.27, 6.64, "FR"], [43.51, 16.44, "HR"]]:
		data.latitude = region[0]
		data.longitude = region[1]
		data.country = region[2]
		_check(MarinaBuilder.mediterranean(data), "other Mediterranean coastal marina qualifies: %s" % region[2])
	for region in [[48.85, 2.35, "FR"], [60.17, 24.95, "FI"], [44.84, -0.58, "FR"], [43.2, 27.9, "BG"]]:
		data.latitude = region[0]
		data.longitude = region[1]
		data.country = region[2]
		_check(not MarinaBuilder.mediterranean(data), "non-Mediterranean marina must keep its existing fleet: %s" % region[2])
	data.latitude = 45.8
	data.longitude = 8.6
	data.country = "IT"
	data.land_polygons[0]["tidal"] = false
	_check(not MarinaBuilder.mediterranean(data), "an inland Italian lake is not a Mediterranean harbour")
	if failures.is_empty():
		print("CATAMARAN MARINA OK: %d cats, deterministic, full beam, outer-hull obstruction, coastal region gating" % cats)
		quit(0)
	else:
		for failure in failures:
			printerr("CATAMARAN MARINA FAIL: ", failure)
		quit(1)

func _bounds(boat: Array) -> Rect2:
	var p: Vector3 = boat[0]
	var length := float(boat[2]) * 10.0
	var width := length * (CatamaranModel.BERTH_BEAM_SHARE if VesselPrototypes.base_kind(boat[3]) == "catamaran" else 0.3)
	# Fixture piers run east/west; boats point north/south.
	var far_z := p.z - sin(float(boat[1])) * length
	return Rect2(p.x - width * 0.5, minf(p.z, far_z), width, length)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
