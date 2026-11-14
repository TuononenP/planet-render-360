extends SceneTree

## Headless: godot --headless --script tests/far_dem_normals_test.gd
## Far terrain normals: a known slope bakes to its true normal, and a drape UV
## addresses the same place on the ring.

const MPP := 25.0

var failures: Array[String] = []

func _init() -> void:
	_slope()
	_uv_map()
	if failures.is_empty():
		print("FAR DEM NORMALS OK: analytic slope, drape to ring mapping")
		quit(0)
	else:
		for f in failures:
			printerr("FAR DEM NORMALS FAIL: ", f)
		quit(1)

## Heights rising east at 0.5 and south at 0.25: the normal leans west and north.
func _slope() -> void:
	var w := 16
	var h := 12
	var heights := PackedFloat32Array()
	heights.resize(w * h)
	for y in h:
		for x in w:
			heights[y * w + x] = float(x) * MPP * 0.5 + float(y) * MPP * 0.25
	var img := FarDemNormals.bake({"width": w, "height": h, "heights": heights}, MPP)
	if img.get_format() != Image.FORMAT_RG8 or img.get_width() != w or img.get_height() != h:
		failures.append("the map should be RG8 at ring size")
		return
	var c := img.get_pixel(8, 6)
	var k := 1.0 / sqrt(0.25 + 0.0625 + 1.0)
	if absf((c.r * 2.0 - 1.0) - (-0.5 * k)) > 0.02 or absf((c.g * 2.0 - 1.0) - (-0.25 * k)) > 0.02:
		failures.append("expected normal x %.3f z %.3f, got %.3f %.3f" % [-0.5 * k, -0.25 * k, c.r * 2.0 - 1.0, c.g * 2.0 - 1.0])

## One global point, seen through a coarser drape and a finer ring.
func _uv_map() -> void:
	var drape := {"zoom": 11, "origin_px": Vector2(1000, 2000), "size_px": Vector2i(512, 256)}
	var ring := {"zoom": 12, "origin_px": Vector2(2100, 4050), "width": 800, "height": 700}
	var m := FarDemNormals.uv_map(drape, ring)
	# Drape UV (0.25, 0.5) is global px (1128, 2128) at z11, (2256, 4256) at z12.
	var uv := Vector2(0.25 * m.x + m.z, 0.5 * m.y + m.w)
	var want := Vector2((2256.0 - 2100.0) / 800.0, (4256.0 - 4050.0) / 700.0)
	if uv.distance_to(want) > 0.0001:
		failures.append("drape uv should reach the ring at %s, got %s" % [want, uv])
