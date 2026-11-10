extends SceneTree

## Headless: godot --headless --script tests/facade_lite_shader_test.gd
## FacadeLiteShader: Forward+ Balanced and High only, swaps lit facades once
## per material, keeps their day parameters and metas, and picks window
## cells per bay and storey (Paris rows, legacy 8 x 8).

var failures: Array[String] = []

func _init() -> void:
	_gate()
	_swap()
	_grids()
	if failures.is_empty():
		print("FACADE LITE OK: Forward+ Balanced/High gate, one swap per material, day parameters kept, bay x storey cells")
		quit(0)
	else:
		for f in failures:
			printerr("FACADE LITE FAIL: ", f)
		quit(1)

func _gate() -> void:
	var P := RenderSettings.Preset
	if not (FacadeLiteShader.enabled(P.BALANCED, true) and FacadeLiteShader.enabled(P.HIGH, true)):
		failures.append("Balanced and High on Forward+ should get the lite shader")
	if FacadeLiteShader.enabled(P.ULTRA, true) or FacadeLiteShader.enabled(P.FAST, true):
		failures.append("Ultra has its own shader and Fast stays Standard")
	if FacadeLiteShader.enabled(P.HIGH, false):
		failures.append("Mobile / Compatibility must keep StandardMaterial3D")

func _facade(set_name: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.8, 0.7, 0.6)
	m.roughness = 0.85
	m.metallic_specular = 0.4
	m.set_meta("facade_set", set_name)
	m.set_meta(CityLights.META, true)
	m.set_meta("fc_uv", Vector3(1.0, 4.0, 3.2))
	m.set_meta("keep_me", 7)
	return m

func _swap() -> void:
	var lit := _facade("glass")
	var plain := StandardMaterial3D.new()
	var root := Node3D.new()
	for mat in [lit, lit, plain]:
		var mi := MeshInstance3D.new()
		mi.mesh = BoxMesh.new()
		mi.material_override = mat
		root.add_child(mi)
	var n := FacadeLiteShader.upgrade(root)
	if n != 1:
		failures.append("one lit material should swap once, swapped %d" % n)
	var a := (root.get_child(0) as MeshInstance3D).material_override
	var b := (root.get_child(1) as MeshInstance3D).material_override
	if not (a is ShaderMaterial) or a != b:
		failures.append("buildings sharing a material should share its lite swap")
	if (root.get_child(2) as MeshInstance3D).material_override != plain:
		failures.append("a material without night lights must stay Standard")
	if a is ShaderMaterial:
		var s := a as ShaderMaterial
		if s.get_shader_parameter("has_depth") != false:
			failures.append("has_depth must read false (relief tests read it)")
		if s.get_shader_parameter("tint") != lit.albedo_color \
				or not is_equal_approx(float(s.get_shader_parameter("roughness_value")), 0.85) \
				or not is_equal_approx(float(s.get_shader_parameter("specular_value")), 0.4):
			failures.append("day parameters must carry over from the Standard material")
		if s.get_shader_parameter("curtain_wall") != true:
			failures.append("glass sets light offices in stretches")
		if int(s.get_meta("keep_me", 0)) != 7 or not s.has_meta(CityLights.META) \
				or s.has_meta("facade_set") or str(s.get_meta("facade_lite", "")) != "glass":
			failures.append("metas: keep others and the night flag, move facade_set to facade_lite")
		if FacadeLiteShader.eligible(s):
			failures.append("a swapped material must not swap again")
	root.free()
	# Night: the Standard emit map, switched per cell by a mask that averages 1.
	var L := FacadeLiteShader
	var mean := L.LIT_SHARE * L.mask(true) + (1.0 - L.LIT_SHARE) * L.mask(false)
	if absf(mean - 1.0) > 1e-5 or L.mask(false) >= 0.5 or L.mask(true) <= 1.0:
		failures.append("night mask must average 1 with dark and lit cells apart, mean %.4f" % mean)
	for want in ["0.55", "mix(0.12, 1.0, on) / mix(0.12, 1.0, 0.55)"]:
		if not L.CODE.contains(want) or not L.CODE.contains("texture(emit_tex, UV).rgb * night_energy * k"):
			failures.append("shader mask drifted from LIT_SHARE / DARK_GLOW")
	var lit_map := _facade("render")
	lit_map.emission_enabled = true
	lit_map.emission_texture = ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	var sm := L.from_standard(lit_map)
	if sm.get_shader_parameter("has_emit") != true or sm.get_shader_parameter("emit_tex") != lit_map.emission_texture:
		failures.append("the Standard emit map must carry over")
	if L.from_standard(_facade("render")).get_shader_parameter("has_emit") != false:
		failures.append("no emit map, no night glow")

func _grids() -> void:
	if FacadeLiteShader.grid_for(_facade("render")) != Vector2(4.0, 1.0):
		failures.append("a tiled look holds its bays by one storey")
	var paris := StandardMaterial3D.new()
	paris.set_meta("facade_rows", 6)
	if FacadeLiteShader.grid_for(paris) != Vector2(float(StoreyComposer.PARIS_BAYS), 6.0):
		failures.append("the Paris facade holds PARIS_BAYS by its rows")
	if FacadeLiteShader.grid_for(StandardMaterial3D.new()) != Vector2(8.0, 8.0):
		failures.append("a legacy facade is an 8 x 8 grid")
