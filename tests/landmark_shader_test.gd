extends SceneTree

## Headless: godot --headless --script tests/landmark_shader_test.gd
## Landmark weathering (LandmarkShader, desktop Ultra): every calibrated
## landmark material is swapped for the shared shader as a surface
## override (the meshes and the standard materials stay as built), with
## the right kind per set; glass, glow and LandmarkLights' overrides keep
## theirs; only Ultra on Forward+ turns it on.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var hero := LandmarkBuilder.build("arch_of_constantine")
	var swapped := LandmarkShader.upgrade(hero)
	if swapped < 2:
		failures.append("the arch should swap its stone parts, got %d" % swapped)
	var ashlar := false
	for mi in LandmarkBuilder.parts(hero):
		var base := mi.mesh.surface_get_material(0)
		if not (base is StandardMaterial3D):
			failures.append("the mesh's own material should stay standard: %s" % mi.name)
			break
		var o := mi.get_surface_override_material(0) as ShaderMaterial
		if base.has_meta(LandmarkShader.META) and (o == null or o.shader != LandmarkShader.shader()):
			failures.append("a calibrated part should carry the shader: %s" % mi.name)
		if o != null and int(o.get_shader_parameter("kind")) == LandmarkShader.Kind.ASHLAR:
			ashlar = true
	if not ashlar:
		failures.append("limestone should be coursed as ashlar")
	if LandmarkShader.upgrade(hero) != 0:
		failures.append("a second upgrade should swap nothing")
	hero.free()
	# Shared standard materials share one shader material.
	var a := LandmarkShader.swap(LandmarkMaterials.pbr("stone", "#A89878", 3.0))
	if a != LandmarkShader.swap(LandmarkMaterials.pbr("stone", "#A89878", 3.0)):
		failures.append("one shader material per standard material")
	if LandmarkShader.kind_for("concrete", 0.3) != LandmarkShader.Kind.METAL \
			or LandmarkShader.kind_for("lawn", 0.0) != LandmarkShader.Kind.GROUND \
			or LandmarkShader.kind_for("brick", 0.0) != LandmarkShader.Kind.BUILT:
		failures.append("kinds: painted metal, ground cover and walls")
	if LandmarkMaterials.glass().has_meta(LandmarkShader.META) \
			or LandmarkMaterials.opera_tile().has_meta(LandmarkShader.META):
		failures.append("glass and the opera tile keep their standard materials")
	# The Eiffel Tower's night glow overrides survive the upgrade.
	var eiffel := LandmarkBuilder.build("eiffel")
	LandmarkLights.dress(eiffel, "eiffel")
	LandmarkShader.upgrade(eiffel)
	for mi in LandmarkBuilder.parts(eiffel):
		var o := mi.get_surface_override_material(0)
		if o is StandardMaterial3D and not (o as StandardMaterial3D).has_meta(CityLights.META):
			failures.append("only glow overrides should stay standard on the Eiffel Tower")
			break
	eiffel.free()
	if LandmarkShader.enabled(RenderSettings.Preset.HIGH, true) \
			or LandmarkShader.enabled(RenderSettings.Preset.ULTRA, false) \
			or not LandmarkShader.enabled(RenderSettings.Preset.ULTRA, true):
		failures.append("only desktop Ultra should weather landmarks")
	failures.erase(failures[0])
	if failures.is_empty():
		print("LANDMARK SHADER OK: calibrated parts weathered by override, glow and glass kept, Ultra only")
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK SHADER FAIL: ", f)
		quit(1)
