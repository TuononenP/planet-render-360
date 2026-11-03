extends SceneTree

## Native earcut: godot --headless --path . --script tests/earcut_native_test.gd
## EarcutKernels (native/, tools/build_native.sh) must cover a polygon with
## holes exactly, and on the map's own polygons agree with the script's
## keyhole triangulation wherever that one succeeds, while also coming out
## with triangles where it gives up (islands touching a coast). Skips,
## passing, when the library is not built.

const AREA_TOLERANCE := 1e-4

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _run() -> void:
	if not ClassDB.class_exists("EarcutKernels"):
		print("EARCUT_NATIVE SKIP: EarcutKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	_synthetic()
	var checked := 0
	var agreed := 0
	var rescued := 0
	var pack := MapPack.shared(MapPack.OMT)
	for z in 7:
		for x in 1 << z:
			for y in 1 << z:
				if z == 6 and (x % 4 != 0 or y % 2 != 0):
					continue
				var body := VectorTileFetcher.inflate(pack.get_tile(z, x, y))
				if body.is_empty():
					continue
				var decoded := MvtReader.read(body, MapStyle.wanted(float(z)))
				for layer_name in decoded:
					var layer: Dictionary = decoded[layer_name]
					var xf := Transform2D().scaled(Vector2(512.0 / float(layer["extent"]), 512.0 / float(layer["extent"])))
					for f in layer["features"]:
						if int(f["type"]) != MvtReader.POLYGON:
							continue
						for rings in f["geom"]:
							if rings.size() < 2:
								continue
							var outer: PackedVector2Array = xf * (rings[0] as PackedVector2Array)
							var holes: Array = []
							for i in range(1, rings.size()):
								var h: PackedVector2Array = xf * (rings[i] as PackedVector2Array)
								if VectorTileBuilder._box_area(RingGeometry.aabb(h)) >= VectorTileBuilder.MIN_HOLE_AREA:
									holes.append(h)
							if holes.is_empty():
								continue
							checked += 1
							var verdict := _compare("%d/%d/%d %s" % [z, x, y, layer_name], outer, holes)
							agreed += 1 if verdict == 1 else 0
							rescued += 1 if verdict == 2 else 0
	if _failures.is_empty():
		print("EARCUT_NATIVE OK: covers a holed square exactly; %d map polygons: %d match the script's triangulation, %d the script gave up on triangulate" % [checked, agreed, rescued])
		quit(0)
	else:
		for f in _failures.slice(0, 20):
			printerr("EARCUT_NATIVE FAIL: ", f)
		quit(1)

static func _tri_area(points: PackedVector2Array, idx: PackedInt32Array) -> float:
	var sum := 0.0
	for t in idx.size() / 3:
		var a := points[idx[t * 3]]
		var b := points[idx[t * 3 + 1]]
		var c := points[idx[t * 3 + 2]]
		sum += absf((b - a).cross(c - a)) / 2.0
	return sum

func _synthetic() -> void:
	var outer := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	var a := PackedVector2Array([Vector2(10, 10), Vector2(30, 10), Vector2(30, 30), Vector2(10, 30)])
	var b := PackedVector2Array([Vector2(60, 60), Vector2(80, 60), Vector2(80, 90), Vector2(60, 90)])
	var idx: PackedInt32Array = ClassDB.class_call_static("EarcutKernels", "triangulate", outer, [a, b])
	var points := outer.duplicate()
	points.append_array(a)
	points.append_array(b)
	var want := 100.0 * 100.0 - 20.0 * 20.0 - 20.0 * 30.0
	if idx.size() % 3 != 0 or absf(_tri_area(points, idx) - want) > 1e-6:
		_failures.append("a square with two holes should be covered exactly: area %f, want %f" % [_tri_area(points, idx), want])
	for i in idx:
		if i < 0 or i >= points.size():
			_failures.append("an index is out of range")
			break
	if not (ClassDB.class_call_static("EarcutKernels", "triangulate", PackedVector2Array([Vector2(0, 0), Vector2(1, 1)]), []) as PackedInt32Array).is_empty():
		_failures.append("an outline of two points has no triangles")

## 1: agrees with the script; 2: the script gave up and earcut did not; 0: neither or a failure.
func _compare(label: String, outer: PackedVector2Array, holes: Array) -> int:
	var points := outer.duplicate()
	var hole_area := 0.0
	for h in holes:
		points.append_array(h)
		hole_area += absf(RingGeometry.signed_area(h))
	var idx: PackedInt32Array = ClassDB.class_call_static("EarcutKernels", "triangulate", outer, holes)
	if idx.size() % 3 != 0 or idx.is_empty():
		_failures.append("%s: earcut returned %d indices" % [label, idx.size()])
		return 0
	for i in idx:
		if i < 0 or i >= points.size():
			_failures.append("%s: index %d out of range" % [label, i])
			return 0
	var earcut_area := _tri_area(points, idx)
	var ring := RingGeometry.bridge_holes(outer, holes)
	var script_idx := VectorTileBuilder._keyhole_triangles(ring, holes)
	if script_idx.is_empty():
		# Tangled holes: earcut must at least stay inside the outline and cover most of it.
		var outer_area := absf(RingGeometry.signed_area(outer))
		if earcut_area > outer_area * (1.0 + AREA_TOLERANCE) or earcut_area < (outer_area - hole_area) * 0.9:
			_failures.append("%s: earcut area %.1f outside [%.1f, %.1f]" % [label, earcut_area, (outer_area - hole_area) * 0.9, outer_area])
			return 0
		return 2
	var script_area := _tri_area(ring, script_idx)
	if absf(earcut_area - script_area) > maxf(script_area, 1.0) * AREA_TOLERANCE:
		_failures.append("%s: earcut covers %.2f px2, the script %.2f" % [label, earcut_area, script_area])
		return 0
	return 1
