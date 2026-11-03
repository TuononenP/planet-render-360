extends SceneTree

## Headless: godot --headless --script tests/marine_layer_test.gd
## Coastal fog (MarineLayer via AtmosphereRig): fog weather at a place with
## a coastline shows the layer, bounded from the sea to TOP_M, and thins the
## air's own fog (the layer carries it); clear weather or an inland place
## keeps the plain weather fog and no layer.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var rig := AtmosphereRig.new(RenderSettings.Preset.ULTRA)
	root.add_child(rig)
	rig.set_coast(-60.0, true)
	rig.set_weather(45, 100.0)
	var coastal_fog := rig.environment.fog_density
	if rig.marine.visible != MarineLayer.supported():
		failures.append("fog at a coastal place should show the marine layer")
	var mat := rig.marine.material_override as ShaderMaterial
	var top := float(mat.get_shader_parameter("top_y"))
	if absf(top - (-60.0 + MarineLayer.TOP_M * rig.units_per_metre)) > 0.01:
		failures.append("the layer top should stand TOP_M over the sea, got %s" % top)
	if MarineLayer.supported() and float(mat.get_shader_parameter("amount")) < 1.0:
		failures.append("the layer should be fully on in fog")
	rig.set_coast(-60.0, false)
	var inland_fog := rig.environment.fog_density
	if rig.marine.visible:
		failures.append("an inland place keeps the plain weather fog, no layer")
	if MarineLayer.supported() and coastal_fog >= inland_fog * 0.5:
		failures.append("the layer carries the fog: the air's fog should thin (%s vs %s)" % [coastal_fog, inland_fog])
	if not MarineLayer.supported() and absf(coastal_fog - inland_fog) > 0.00001:
		failures.append("Compatibility must keep ordinary weather fog at the coast")
	rig.set_coast(-60.0, true)
	rig.set_weather(0, 10.0)
	if rig.marine.visible:
		failures.append("clear weather shows no marine layer")
	rig.queue_free()
	failures.remove_at(0)
	if failures.is_empty():
		print("MARINE LAYER OK: coastal fog lies on the sea to its top, thins the air fog; none inland or clear")
		quit(0)
	else:
		for f in failures:
			printerr("MARINE LAYER FAIL: ", f)
		quit(1)
