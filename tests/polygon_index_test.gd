extends SceneTree

## PolygonIndex (offline): godot --headless --script tests/polygon_index_test.gd
## The banded index must answer exactly like WorldScale.point_in_polygon
## (outer ring, minus holes), and a Venice-sized lagoon (tens of thousands
## of vertices, a thousand island holes) must carve a 256 grid in seconds:
## the per-post vertex walk it replaces never finished.

func _init() -> void:
	_run()

## Wobbly closed ring around c (irregular radius, so edges are concave).
func _ring(c: Vector2, r: float, n: int, seed_v: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var k := 0.75 + 0.25 * sin(a * 7.0 + seed_v) * cos(a * 3.0 - seed_v * 2.0)
		out.append(c + Vector2(cos(a), sin(a)) * r * k)
	return out

func _slow(p: Vector2, outer: PackedVector2Array, holes: Array) -> bool:
	if not WorldScale.point_in_polygon(p, outer):
		return false
	for h in holes:
		if WorldScale.point_in_polygon(p, h):
			return false
	return true

func _run() -> void:
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Agreement: irregular outer ring, holes, random probes + grid posts.
	var outer := _ring(Vector2(10, -20), 900.0, 700, 0.4)
	var holes: Array = []
	for k in 40:
		var c := Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500))
		holes.append(_ring(c, rng.randf_range(15, 60), 24, float(k)))
	var idx := PolygonIndex.new(outer, holes)
	var bad := 0
	for i in 4000:
		var p := Vector2(rng.randf_range(-1100, 1100), rng.randf_range(-1100, 1100))
		if idx.contains(p) != _slow(p, outer, holes):
			bad += 1
	if bad > 0:
		failures.append("contains() disagreed with point_in_polygon on %d of 4000 points" % bad)
	var size := 96
	var step := 2400.0 / float(size - 1)
	var half := float(size) / 2.0
	var fast := {}
	for i in idx.posts_inside(size, step, half):
		fast[i] = true
	var mism := 0
	for z in size:
		for x in size:
			var p := Vector2((float(x) - half) * step, (float(z) - half) * step)
			if fast.has(z * size + x) != _slow(p, outer, holes):
				mism += 1
	if mism > 0:
		failures.append("posts_inside() disagreed with point_in_polygon on %d of %d posts" % [mism, size * size])
	# Scale: a lagoon covering the whole grid, ~15k outer vertices and
	# 1100 island holes (~70k vertices), like Venice.
	var lagoon := _ring(Vector2.ZERO, 6000.0, 15000, 1.3)
	var isles: Array = []
	for k in 1100:
		var c := Vector2(rng.randf_range(-1200, 1200), rng.randf_range(-1200, 1200))
		isles.append(_ring(c, rng.randf_range(3, 25), 64, float(k)))
	var t := Time.get_ticks_msec()
	var big := PolygonIndex.new(lagoon, isles)
	var posts := big.posts_inside(256, 2400.0 / 255.0, 128.0)
	for i in 3000:
		big.contains(Vector2(rng.randf_range(-1200, 1200), rng.randf_range(-1200, 1200)))
	var ms := Time.get_ticks_msec() - t
	if posts.size() < 256 * 256 / 2:
		failures.append("lagoon should cover most posts, got %d" % posts.size())
	if ms > 20000:
		failures.append("lagoon index + 256 grid + 3000 probes took %d ms (should be seconds)" % ms)
	if failures.is_empty():
		print("POLYGON INDEX OK: identical to point_in_polygon (points + grid posts), lagoon-scale carve in %d ms" % ms)
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)
