extends SceneTree

## Headless: port quays berth cargo ships, ferry terminals keep ferries
## (even on port land), plain quays keep liners; the warehouse-share
## fallback works without port tags; plans are deterministic and every
## large ship carries the berth data ShipMooring needs.
var failures: Array[String] = []

func _init() -> void:
	var d := LocationData.new()
	d.grid_size = 49
	d.heights.resize(49 * 49)
	d.heights.fill(3.0)
	d.water_level = 0.5
	d.country = "FI"
	d.quality_preset = RenderSettings.Preset.ULTRA
	var sea := {"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-1200, 0), Vector2(1200, 0), Vector2(1200, 1200), Vector2(-1200, 1200)])}
	var port := {"class": "urban", "harbour_use": "port",
		"points": PackedVector2Array([Vector2(-600, -5), Vector2(200, -5), Vector2(200, -400), Vector2(-600, -400)])}
	d.land_polygons = [sea]
	d.shore_structures = [{"kind": "quay", "points": PackedVector2Array([Vector2(-450, 0), Vector2(50, 0)])}]
	var g := GroundTruth.new(d)
	var plain: Array = MarinaBuilder.plan(d, g, 1.0)["liners"]
	_check(plain.size() == 1 and plain[0][6] == "liner", "A plain sea quay keeps its liner")
	d.land_polygons = [sea, port]
	g = GroundTruth.new(d)
	var a := Vector2(-450, 0)
	var b := Vector2(50, 0)
	_check(CargoBerths.port_run(d, a, b, 1.0), "Port land behind a quay makes it a port run")
	var ships: Array = MarinaBuilder.plan(d, g, 1.0)["liners"]
	_check(ships.size() == 1 and str(ships[0][6]).begins_with("cargo:"), "A port quay berths a cargo ship, not a liner")
	_check(ships == MarinaBuilder.plan(d, g, 1.0)["liners"], "Cargo berths must be deterministic")
	for s in ships:
		var p: Vector3 = s[0]
		_check(p.z > 0.0 and absf(sin(float(s[1]))) < 0.001, "Cargo ships lie alongside on the wet side")
		_check(str(s[6]).trim_prefix("cargo:") in CargoShipModel.VARIANTS, "Cargo variant must be a model variant")
		var info: Dictionary = s[7]
		_check(float(info["quay_z"]) < 0.0 and float(info["quay_top"]) > 0.5, "Berth data puts the quay on the land side")
	d.pois = [{"kind": "ferry_terminal", "x": -200.0, "z": -20.0}]
	var ferry: Array = MarinaBuilder.plan(d, g, 1.0)["liners"]
	_check(ferry.size() == 1 and ferry[0][6] == "ferry", "A terminal on port land keeps its ferry")
	d.pois = []
	# Warehouses alone (no port tags) also mark a cargo quay.
	d.land_polygons = [sea]
	var sheds: Array = []
	for i in 5:
		sheds.append({"kind": "warehouse", "x": -400.0 + float(i) * 90.0, "z": -80.0, "size_x": 70.0, "size_z": 40.0})
	sheds.append({"kind": "house", "x": -100.0, "z": -150.0, "size_x": 12.0, "size_z": 10.0})
	d.buildings = sheds
	g = GroundTruth.new(d)
	_check(CargoBerths.port_run(d, a, b, 1.0), "A quay lined with warehouses is a port run")
	d.buildings = [sheds[0], sheds[1], sheds[5]]
	_check(not CargoBerths.port_run(d, a, b, 1.0), "Two sheds do not make a port")
	d.buildings = []
	var industrial := port.duplicate()
	industrial["harbour_use"] = "industrial"
	d.land_polygons = [sea, industrial]
	_check(not CargoBerths.port_run(d, a, b, 1.0), "Bare industrial land without sheds is not a port")
	for v in [[400.0, 0.1], [400.0, 0.9], [200.0, 0.2], [150.0, 0.5]]:
		var size := CargoBerths.pick(float(v[0]), float(v[1]))
		_check(float(size[1]) <= float(v[0]) - 30.0 + 0.001 and float(size[1]) >= CargoBerths.MIN_M,
			"A cargo ship must fit its run: %s" % [size])
	if failures.is_empty():
		print("CARGO BERTHS OK: port tags, warehouse fallback, ferry and liner precedence, deterministic, berth data")
		quit(0)
	else:
		for f in failures:
			printerr("CARGO BERTHS FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
