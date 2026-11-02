extends SceneTree

## Headless: godot --headless --script tests/facade_shader_test.gd
## Ultra facade shader (FacadeShader): only Forward+ Ultra gets it; every
## facade material swaps for one shared shader material that keeps the
## textures, the UV cells and the lit-window and wall marks; other
## materials are left alone; CityLights drives its night energy and clock.

func _init() -> void:
	_run()

func _facade(set_name: String, pattern: String) -> StandardMaterial3D:
	var look := ArchitectureStyle.resolve({"kind": "apartments", "levels": 5, "x": 0.0, "z": 0.0},
		"haussmann" if pattern == "haussmann" else "nordic", "dense", 0.3, 400.0)
	look["pattern"] = pattern
	look["wall_set"] = set_name
	return FacadeMaterials.facade_for_building({}, "haussmann", 5, 3, false, 0.3, look) as StandardMaterial3D

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var ultra := RenderSettings.Preset.ULTRA
	if not FacadeShader.enabled(ultra, true) or FacadeShader.enabled(RenderSettings.Preset.HIGH, true) \
			or FacadeShader.enabled(ultra, false):
		failures.append("the facade shader is for Forward+ Ultra only")
	# Desktop Ultra builds relief, trim and roof detail out to its detail
	# ring; the other tiers keep the shared radii (AC-12).
	if RenderQuality.ultra_desktop(ultra):
		if FacadeRelief.radius_m(ultra) <= FacadeRelief.RADIUS_M or BuildingTrim.radius_m(ultra) <= BuildingTrim.RADIUS_M \
				or BuildingDetail.near_radius(ultra) <= BuildingDetail.NEAR_RADIUS \
				or BuildingTrim.radius_m(ultra) > LodRing.detail_m(ultra):
			failures.append("desktop Ultra should widen the detail rings up to LodRing's detail reach")
	var high := RenderSettings.Preset.HIGH
	if FacadeRelief.radius_m(high) != FacadeRelief.RADIUS_M or BuildingTrim.radius_m(high) != BuildingTrim.RADIUS_M \
			or BuildingDetail.near_radius(high) != BuildingDetail.NEAR_RADIUS:
		failures.append("High keeps the shared detail radii")
	FacadeMaterials.begin_build()
	var wall := _facade("render", "punched")
	var glass := _facade("glass", "curtain")
	if wall == null or not wall.has_meta("facade_set") or glass == null or str(glass.get_meta("facade_set")) != "glass":
		failures.append("facade materials should carry their set (meta facade_set)")
	var other := StandardMaterial3D.new()
	var root := Node3D.new()
	var shared: Array[MeshInstance3D] = []
	for i in 3:
		var mi := MeshInstance3D.new()
		var mesh := ArrayMesh.new()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, wall)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(1, other)
		mi.mesh = mesh
		root.add_child(mi)
		shared.append(mi)
	var over := MeshInstance3D.new()
	over.mesh = BoxMesh.new()
	over.material_override = glass
	root.add_child(over)
	var n := FacadeShader.upgrade(root)
	if n != 2:
		failures.append("two distinct facade materials should swap, got %d" % n)
	var s0 := shared[0].mesh.surface_get_material(0)
	if not (s0 is ShaderMaterial):
		failures.append("facade surfaces should carry the shader material")
	else:
		var sm := s0 as ShaderMaterial
		for mi in shared:
			if mi.mesh.surface_get_material(0) != sm:
				failures.append("one facade material should map to one shared shader material")
				break
		if sm.get_shader_parameter("albedo_tex") != wall.albedo_texture \
				or sm.get_shader_parameter("normal_tex") != wall.normal_texture:
			failures.append("the shader material should read the facade's own textures")
		if not bool(sm.get_shader_parameter("has_depth")) or float(sm.get_shader_parameter("depth_scale")) <= 0.0:
			failures.append("Ultra facades keep their window reveals in the shader")
		# Tiled walls get their photo's full grain back over the composer's
		# mip of it (1K photo, one copy per 128 px bay: mip 3).
		if sm.get_shader_parameter("has_photo") != true \
				or absf(float(sm.get_shader_parameter("photo_lod")) - 3.0) > 0.01 \
				or (sm.get_shader_parameter("photo_diff") as Texture2D).get_width() < 512:
			failures.append("tiled facades should read the full-size wall photo at the composer's mip")
		var cells: Vector2 = sm.get_shader_parameter("cells")
		if absf(cells.x - float(FacadeComposer.BAYS)) > 0.01 or absf(cells.y - 1.0) > 0.01:
			failures.append("a tiled facade spans BAYS bays x one storey, got %s" % cells)
		if not WallVariety.is_wall(sm) or not sm.has_meta(CityLights.META) or not sm.has_meta("fc_uv"):
			failures.append("the shader material keeps the wall, lit-window and UV marks")
		CityLights.hour = 22.5
		CityLights.apply(root, 1.0)
		if absf(float(sm.get_shader_parameter("night_energy")) - CityLights.NIGHT_ENERGY) > 0.001 \
				or absf(float(sm.get_shader_parameter("city_hour")) - 22.5) > 0.001:
			failures.append("CityLights should drive the shader's night energy and clock")
	if shared[0].mesh.surface_get_material(1) != other:
		failures.append("non-facade materials are left alone")
	if not (over.material_override is ShaderMaterial) \
			or not bool((over.material_override as ShaderMaterial).get_shader_parameter("curtain_wall")) \
			or (over.material_override as ShaderMaterial).get_shader_parameter("has_photo") == true:
		failures.append("a glass override should become a curtain-wall shader material")
	if FacadeShader.upgrade(root) != 0:
		failures.append("a second pass has nothing left to swap")
	root.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("FACADE SHADER OK: Forward+ Ultra only, wider Ultra detail rings, shared swap, own textures and reveals, BAYS x storey cells, marks kept, CityLights-driven")
		quit(0)
	else:
		for f in failures:
			printerr("FACADE SHADER FAIL: ", f)
		quit(1)
