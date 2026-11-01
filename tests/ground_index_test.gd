extends SceneTree

## GroundIndex (offline): godot --headless --script tests/ground_index_test.gd
## GroundTruth's land-class and building grids must answer exactly like
## the full scans they replace (first matching polygon in data order,
## any building circle), inside the grid, on cell edges and well past the
## extent where the scan fallback applies.

func _init() -> void:
	_run()

func _ring(c: Vector2, r: float, n: int, seed_v: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var k := 0.7 + 0.3 * sin(a * 5.0 + seed_v) * cos(a * 2.0 - seed_v)
		out.append(c + Vector2(cos(a), sin(a)) * r * k)
	return out

func _fixture(rng: RandomNumberGenerator) -> LocationData:
	var d := LocationData.new()
	d.grid_size = 64
	d.heights.resize(64 * 64)
	d.heights.fill(10.0)
	d.water_level = 0.0
	var classes := ["water", "forest", "grass", "urban", "park", "field"]
	for k in 80:
		var c := Vector2(rng.randf_range(-1600, 1600), rng.randf_range(-1600, 1600))
		var holes: Array = []
		if k % 5 == 0:
			holes.append(_ring(c, rng.randf_range(10, 40), 12, float(k) + 0.5))
		d.land_polygons.append({"class": classes[k % classes.size()],
			"points": _ring(c, rng.randf_range(20, 700), 40, float(k)), "holes": holes})
	for k in 3000:
		d.buildings.append({"x": rng.randf_range(-1300, 1300), "z": rng.randf_range(-1300, 1300),
			"size_x": rng.randf_range(4, 60), "size_z": rng.randf_range(4, 60)})
	return d

func _scan_class(g: GroundTruth, p: Vector2) -> String:
	for k in g._land.size():
		if (g._land_index[k] as PolygonIndex).contains(p):
			return str(g._land[k].get("class", ""))
	return ""

func _scan_built(g: GroundTruth, x: float, z: float) -> bool:
	for b in g._buildings:
		var dx := x - float(b.get("x", 0.0))
		var dz := z - float(b.get("z", 0.0))
		var reach := maxf(float(b.get("size_x", 0.0)), float(b.get("size_z", 0.0))) * 0.5 + 1.6
		if dx * dx + dz * dz < reach * reach:
			return true
	return false

func _run() -> void:
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var g := GroundTruth.new(_fixture(rng))
	var probes: Array[Vector2] = []
	for i in 40000:
		probes.append(Vector2(rng.randf_range(-2600, 2600), rng.randf_range(-2600, 2600)))
	# Cell edges and corners of the 64 m grid, where an off-by-one bites.
	for i in range(-40, 41):
		for j in range(-40, 41, 8):
			probes.append(Vector2(float(i) * GroundIndex.GRID_M, float(j) * GroundIndex.GRID_M))
	# Polygon vertices themselves.
	for poly in g._land:
		var pts: PackedVector2Array = poly["points"]
		for i in range(0, pts.size(), 4):
			probes.append(pts[i])
	var bad_class := 0
	var bad_built := 0
	for p in probes:
		if g.land_class_at(p.x, p.y) != _scan_class(g, p):
			bad_class += 1
		if g.is_built_at(p.x, p.y) != _scan_built(g, p.x, p.y):
			bad_built += 1
	if bad_class > 0:
		failures.append("land_class_at disagreed with the scan at %d/%d points" % [bad_class, probes.size()])
	if bad_built > 0:
		failures.append("is_built_at disagreed with the scan at %d/%d points" % [bad_built, probes.size()])
	if failures.is_empty():
		print("GROUND INDEX OK: %d probes agree with the full scans" % probes.size())
		quit(0)
	else:
		for f in failures:
			printerr("GROUND INDEX FAIL: ", f)
		quit(1)
