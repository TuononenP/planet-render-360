extends SceneTree

## Headless: godot --headless --script tests/far_aspect_test.gd
## FarSurface.aspect_params: the sun's side by hemisphere, and the
## treeline's height above the place, which the weather does not move.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	failures.clear()
	var north := LocationData.new()
	north.latitude = 46.69
	var a := FarSurface.aspect_params(north)
	_check(is_equal_approx(float(a["sun_side"]), 1.0), "the sun stands south of the northern hemisphere")
	north.centre_elevation_m = 600.0
	var want := (ClimateModel.treeline_m(north) - 600.0) * WorldScale.metres_to_units()
	_check(is_equal_approx(float(FarSurface.aspect_params(north)["treeline_y"]), want),
		"the treeline is measured from the place's centre")
	var south := LocationData.new()
	south.latitude = -33.87
	_check(is_equal_approx(float(FarSurface.aspect_params(south)["sun_side"]), -1.0), "the sun stands north of the southern hemisphere")
	# The material carries them, and a material with no place keeps its defaults.
	var mat := FarSurface.drape_material(null, null, false, north)
	_check(is_equal_approx(float(mat.get_shader_parameter("sun_side")), 1.0), "the material gets the sun's side")
	_check(FarSurface.drape_material(null, null).get_shader_parameter("sun_side") == null, "no place sets no aspect")
	if failures.is_empty():
		print("FAR ASPECT OK")
		quit(0)
	else:
		for f in failures:
			printerr("FAR ASPECT FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
