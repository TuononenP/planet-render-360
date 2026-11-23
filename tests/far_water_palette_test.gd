extends SceneTree

## Headless: godot --headless --script tests/far_water_palette_test.gd
## The far rings' water takes the near water's sea colour and gloss
## (WaterSurface.sea_palette), so the sea doesn't change look at the
## edge of the detailed ground. No network.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	failures.clear()
	_place(60.17, 24.95, "Helsinki")
	_place(40.706, -74.004, "New York harbour")
	_place(13.75398, 100.50144, "Bangkok Chao Phraya")
	_check_bangkok_silty()
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

func _place(lat: float, lon: float, label: String) -> void:
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	var sea := WaterSurface.sea_palette(data)
	var mat := FarSurface.drape_material(null, null, false, data)
	_check(mat.get_shader_parameter("water_deep") == sea["deep"], "%s: far deep colour is the near sea's" % label)
	_check(mat.get_shader_parameter("water_shallow") == sea["shallow"], "%s: far shallow colour is the near sea's" % label)
	_check(is_equal_approx(float(mat.get_shader_parameter("water_far_rough")), float(sea["far_rough"])), "%s: far gloss matches near far_rough" % label)
	_check(float(sea["far_rough"]) == (0.23 if bool(sea["harbour"]) else 0.09), "%s: harbour seas end rougher" % label)

func _check_bangkok_silty() -> void:
	var bkk := LocationData.new()
	bkk.latitude = 13.75398
	bkk.longitude = 100.50144
	var sea := WaterSurface.sea_palette(bkk)
	var sh: Vector3 = sea["shallow"]
	var dp: Vector3 = sea["deep"]
	_check(sh.x > sh.z and sh.y > sh.z and dp.x > dp.z and dp.y > dp.z,
		"Bangkok Chao Phraya far water must be silty brown-green, never turquoise: shallow=%s deep=%s" % [sh, dp])
	var inland := WaterSurface.inland_palette(bkk)
	_check(not inland.is_empty(), "Bangkok must provide an inland Chao Phraya & khlong palette")
	if not inland.is_empty():
		var c_deep: Color = inland["deep"]
		var c_khlong: Color = inland["khlong"]
		_check(c_deep.r > c_deep.b and c_deep.g > c_deep.b, "Chao Phraya river colour must have zero turquoise bias")
		_check(c_khlong.g < c_deep.g and c_khlong.g > c_khlong.b, "Bangkok khlong palette must be darker olive-brown than river")
