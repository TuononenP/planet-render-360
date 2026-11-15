extends SceneTree

## Headless: godot --headless --script tests/far_water_palette_test.gd
## The far rings' water takes the near water's sea colour and gloss
## (WaterSurface.sea_palette), so the sea doesn't change look at the
## edge of the detailed ground. No network.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	failures.clear()
	_place(60.17, 24.95, 0.09, "Helsinki")
	_place(40.706, -74.004, 0.23, "New York harbour")
	var mat := FarSurface.drape_material(null, null, false, null)
	var code := mat.shader.code
	_check(code.contains("uniform vec3 water_deep") and code.contains("water_far_rough"),
		"far shader declares the sea palette uniforms")
	if failures.is_empty():
		print("FAR WATER PALETTE OK: Baltic and harbour palettes reach the far rings")
		quit(0)
	else:
		for f in failures:
			printerr("FAR WATER PALETTE FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _place(lat: float, lon: float, rough: float, label: String) -> void:
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	var sea := WaterSurface.sea_palette(data)
	var mat := FarSurface.drape_material(null, null, false, data)
	_check(mat.get_shader_parameter("water_deep") == sea["deep"], "%s: far deep colour is the near sea's" % label)
	_check(mat.get_shader_parameter("water_shallow") == sea["shallow"], "%s: far shallow colour is the near sea's" % label)
	_check(is_equal_approx(float(mat.get_shader_parameter("water_far_rough")), rough), "%s: far gloss matches near far_rough" % label)
