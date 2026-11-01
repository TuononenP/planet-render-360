extends SceneTree

## Observation wheel parsing + restored ground (offline):
## godot --headless --script tests/wheel_ground_test.gd
## A big_wheel gets its true bearing and footprint on every mapping path,
## and a footprint-derived height when OSM gives no height. A GroundTruth
## restored the way WorldCache does it answers land_class_at like a built one.

const LAT := 51.5033
const LON := -0.1196

func _init() -> void:
	_run()

## Thin slab `len_m` x `wide_m` centred on the origin, long side at
## `bearing` radians clockwise from north, as OSM lat/lon geometry.
func _slab(len_m: float, wide_m: float, bearing: float) -> Array:
	var u := Vector2(sin(bearing), cos(bearing))  # east, north
	var v := Vector2(u.y, -u.x)
	var out: Array = []
	for c in [[-1, -1], [1, -1], [1, 1], [-1, 1], [-1, -1]]:
		var m: Vector2 = u * float(c[0]) * len_m * 0.5 + v * float(c[1]) * wide_m * 0.5
		out.append({"lat": LAT + m.y / 111320.0,
			"lon": LON + m.x / (111320.0 * cos(deg_to_rad(LAT)))})
	return out

func _wheel(landmarks: Array) -> Dictionary:
	for l in landmarks:
		if str(l.get("archetype", "")) == "big_wheel":
			return l
	return {}

func _check_wheel(failures: Array[String], label: String, lm: Dictionary,
		geom: Array, min_h: float) -> void:
	if lm.is_empty():
		failures.append("%s: no big_wheel landmark" % label)
		return
	if not lm.has("yaw"):
		failures.append("%s: wheel has no yaw" % label)
		return
	var a := OsmFetcher.local_xz(float(geom[0]["lat"]), float(geom[0]["lon"]), LAT, LON)
	var b := OsmFetcher.local_xz(float(geom[1]["lat"]), float(geom[1]["lon"]), LAT, LON)
	var along := (b - a).normalized()
	var yaw := float(lm["yaw"])
	var dir := Vector2(sin(yaw), cos(yaw))
	if absf(dir.dot(along)) < 0.99:
		failures.append("%s: yaw %.2f does not follow the long side" % [label, yaw])
	if float(lm["size_z"]) < float(lm["size_x"]) * 4.0:
		failures.append("%s: size_z should run along the wheel, got %s x %s" % [label, lm["size_x"], lm["size_z"]])
	if float(lm["height"]) < min_h:
		failures.append("%s: height %.1f should come from the footprint (>= %.1f)" % [label, lm["height"], min_h])

func _run() -> void:
	var failures: Array[String] = []
	var geom := _slab(120.0, 10.0, deg_to_rad(30.0))
	var min_h := OsmFetcher.local_xz(float(geom[0]["lat"]), float(geom[0]["lon"]), LAT, LON) \
		.distance_to(OsmFetcher.local_xz(float(geom[1]["lat"]), float(geom[1]["lon"]), LAT, LON)) \
		/ LandmarkWheel.DIAMETER_PER_HEIGHT * 0.95
	# Building way without height / levels: the 10 m default must not win.
	var as_building := JSON.stringify({"elements": [{"type": "way", "id": 1,
		"tags": {"building": "yes", "attraction": "big_wheel"}, "geometry": geom}]})
	_check_wheel(failures, "building way",
		_wheel(OsmFetcher.parse_features(as_building, LAT, LON)["landmarks"]), geom, min_h)
	# Plain tourism way (no building tag): same bearing and size.
	var as_way := JSON.stringify({"elements": [{"type": "way", "id": 2,
		"tags": {"tourism": "attraction", "attraction": "big_wheel"}, "geometry": geom}]})
	_check_wheel(failures, "plain way",
		_wheel(OsmFetcher.parse_features(as_way, LAT, LON)["landmarks"]), geom, min_h)
	# A tagged height is kept.
	var tall := JSON.stringify({"elements": [{"type": "way", "id": 3,
		"tags": {"building": "yes", "attraction": "big_wheel", "height": "135"}, "geometry": geom}]})
	var tl := _wheel(OsmFetcher.parse_features(tall, LAT, LON)["landmarks"])
	if tl.is_empty() or not is_equal_approx(float(tl["height"]), 135.0):
		failures.append("tagged wheel height should stay 135 m, got %s" % [tl.get("height")])

	# Restored ground (WorldCache._load_ground): land lookups still work.
	var square := PackedVector2Array([Vector2(-50, -50), Vector2(50, -50),
		Vector2(50, 50), Vector2(-50, 50)])
	var g := GroundTruth.new(null)
	g.set_land([{"class": "park", "points": square, "holes": []}])
	if g.land_class_at(0.0, 0.0) != "park":
		failures.append("restored ground: land_class_at inside should be park, got '%s'" % g.land_class_at(0.0, 0.0))
	if g.land_class_at(200.0, 0.0) != "":
		failures.append("restored ground: land_class_at outside should be empty")

	if failures.is_empty():
		print("WHEEL + GROUND OK: wheel bearing/size/height on building and plain ways, restored land lookups")
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)
