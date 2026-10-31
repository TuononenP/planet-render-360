extends SceneTree

## Arid and dry-summer ground (offline): godot --headless --script tests/arid_ground_test.gd
## Unmapped ground that the photo scores as "green" took the lawn colour
## whatever the climate, so Dubai's sandy lots read as grass. Arid places
## now raise the vegetation threshold and take the dry-grass colour.

func _init() -> void:
	_run()

func _data(precip: float, warm_precip: float, t_warm: float, t_cold: float) -> LocationData:
	var d := LocationData.new()
	d.climate = {"precip_mm": precip, "precip_warm_mm": warm_precip,
		"t_warm_c": t_warm, "t_cold_c": t_cold}
	return d

func _mat(d: LocationData) -> ShaderMaterial:
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	img.fill(Color(0.5, 0.45, 0.35))
	return GroundMaterial.build(d, ImageTexture.create_from_image(img),
		Rect2(0, 0, 1, 1), true)

func _run() -> void:
	await process_frame  # texture read-backs need the main loop running
	var failures: Array[String] = []
	var dubai := _data(107.0, 3.0, 34.3, 20.5)
	var paris := _data(659.0, 165.0, 18.6, 4.4)
	var big_sur := _data(800.0, 40.0, 17.0, 10.0)
	if not ClimateModel.arid(dubai) or ClimateModel.arid(paris):
		failures.append("fixture climates: Dubai arid, Paris not")
	var md := _mat(dubai)
	var mp := _mat(paris)
	var mb := _mat(big_sur)
	if float(md.get_shader_parameter("veg_lo")) <= float(mp.get_shader_parameter("veg_lo")) \
			or float(md.get_shader_parameter("veg_hi")) <= float(mp.get_shader_parameter("veg_hi")):
		failures.append("arid ground should need a stronger green signal than temperate")
	# A tan sand pixel's excess-green index must sit below the arid window
	# (it read ~0.06, i.e. half-green, under the default 0.03..0.12).
	var sand := Color(0.50, 0.46, 0.34)
	var exg := (2.0 * sand.g - sand.r - sand.b) / (sand.r + sand.g + sand.b)
	if exg >= float(md.get_shader_parameter("veg_lo")):
		failures.append("sand (exg %.3f) must not count as vegetation in an arid climate" % exg)
	var green: Color = md.get_shader_parameter("unknown_veg")
	var temperate: Color = mp.get_shader_parameter("unknown_veg")
	if green.g > green.r + 0.02 or green.is_equal_approx(temperate):
		failures.append("arid unmapped vegetation should be the dry colour, not green %s" % green)
	if not mp.get_shader_parameter("unknown_veg") == Color(0.35, 0.48, 0.24):
		failures.append("temperate unmapped vegetation must keep the lawn green")
	# Dry-summer climates (Big Sur) take the golden grass; thresholds stay default.
	var gold: Color = mb.get_shader_parameter("unknown_veg")
	if ClimateModel.summer_dry(big_sur) and gold.g > gold.r + 0.05:
		failures.append("dry-summer unmapped vegetation should be golden, got %s" % gold)
	if failures.is_empty():
		print("ARID GROUND OK: arid thresholds raised, dry colour for unmapped vegetation, temperate unchanged")
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)
