extends SceneTree

## Headless: godot --headless --script tests/street_lights_test.gd
## Street-lamp light (StreetLights, desktop Ultra): the nearest lamps get
## a shadowless, distance-faded light at the lamp head, off by day; at
## night CityLights turns them on with the lamp glass. Lamp glass glows
## only at night on every tier.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var placed := {"lantern": [], "modern": []}
	for i in StreetLights.MAX_LIGHTS + 40:
		var at := Vector3(float(i) * 7.0, 2.0, 30.0)
		(placed["lantern" if i % 2 == 0 else "modern"] as Array).append(Transform3D(Basis(), at))
	var root := Node3D.new()
	var n := StreetLights.add(root, placed, "haussmann", 1.0)
	if n != StreetLights.MAX_LIGHTS:
		failures.append("the nearest MAX_LIGHTS lamps get a light, got %d" % n)
	var lights := root.get_node("StreetLights").get_children()
	var far := 0.0
	var spots := 0
	for l in lights:
		var light := l as Light3D
		far = maxf(far, Vector2(light.position.x, light.position.z).length())
		if light.shadow_enabled or not light.distance_fade_enabled or light.visible or light.light_energy != 0.0:
			failures.append("street lights are shadowless, distance-faded and off until night")
			break
		if light is SpotLight3D:
			spots += 1
			var down := -(light as SpotLight3D).transform.basis.z
			if down.dot(Vector3.DOWN) < 0.99:
				failures.append("cobra-head spots should shine straight down, got %s" % down)
				break
			if absf(light.position.y - (2.0 + StreetLights.COBRA_HEAD.y)) > 0.01:
				failures.append("a spot should hang at the lamp head")
				break
	if spots == 0 or spots == lights.size():
		failures.append("lanterns get omnis and cobra heads get spots")
	if far > float(StreetLights.MAX_LIGHTS + 40) * 7.0 * 0.95:
		failures.append("the farthest lamps should be the ones left unlit")
	CityLights.apply(root, 1.0)
	var l0 := lights[0] as Light3D
	if not l0.visible or absf(l0.light_energy - StreetLights.ENERGY) > 0.001:
		failures.append("full night should switch the lights on at ENERGY")
	CityLights.apply(root, 0.0)
	if l0.visible:
		failures.append("day should switch the lights off")
	if StreetLights.colour_for("modern", "eastern_europe").g > 0.7 \
			or StreetLights.colour_for("modern", "north_america").b < 0.7:
		failures.append("sodium orange in sodium regions, neutral LED elsewhere")
	var glass := StreetProps._lamp_mesh("modern").surface_get_material(1) as StandardMaterial3D
	if glass == null or not glass.has_meta(CityLights.META) or glass.emission_energy_multiplier != 0.0:
		failures.append("lamp glass should be dark by day and lit with the windows at night")
	root.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("STREET LIGHTS OK: nearest lamps lit, shadowless and faded, spots down at the head, night-driven, regional colour, lamp glass night-only")
		quit(0)
	else:
		for f in failures:
			printerr("STREET LIGHTS FAIL: ", f)
		quit(1)
