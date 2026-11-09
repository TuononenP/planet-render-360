extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	FacadeMaterials.begin_build()
	var absent := Color(0, 0, 0, 0)
	var copper := _roof({"roof_material": "copper"}, "dome", Color("#be7040"))
	_check(copper.albedo_texture == MaterialLibrary._set_tex("copper", "diff"),
		"Mapped copper must use patina, even over a red satellite sample")
	var tint := copper.albedo_color.srgb_to_linear()
	var mean: Color = MaterialLibrary.PBR_SETS["copper"]["mean"] * tint
	_check(mean.g > mean.r * 1.5 and mean.b > mean.r * 1.2, "Copper default must read verdigris, not clay")
	for tag in ["metal", "metal_sheet", "metal sheet", "steel", "zinc"]:
		var m := _roof({"roof_material": tag}, "gabled", absent)
		_check(m.albedo_texture == MaterialLibrary._set_tex("sheet_metal", "diff"), tag + " must resolve to sheet metal")
		_check(m.normal_enabled and m.normal_texture != null and m.roughness_texture != null,
			tag + " must render its folds and roughness")
	var black := _roof({"roof_material": "metal", "roof_colour": "black"}, "gabled", absent)
	var red := _roof({"roof_material": "metal", "roof_colour": "red"}, "gabled", absent)
	var grey := _roof({"roof_material": "metal", "roof_colour": "grey"}, "gabled", absent)
	_check(red.albedo_color.r > red.albedo_color.g * 1.4, "Mapped red paint must keep its hue")
	_check(grey.albedo_color.v > black.albedo_color.v * 1.5, "Black and grey sheet paint must remain distinct")
	for shape in ["flat", "hipped"]:
		var styled := _roof({}, shape, Color("#538472"), {"roof_set": "copper"})
		_check(styled.albedo_texture == copper.albedo_texture, "Otaniemi patina must survive flat roofs and green imagery")
	var painted := _roof({}, "gabled", Color("#8a3930"), {"roof_set": "sheet_metal"})
	_check(painted.albedo_texture == MaterialLibrary._set_tex("sheet_metal", "diff"),
		"Red imagery over a Nordic sheet roof must colour the paint, not change it to tiles")
	var flat := _roof({}, "flat", absent, {"roof_set": "sheet_metal"})
	_check(flat.albedo_texture == MaterialLibrary._set_tex("membrane", "diff"), "Untagged flat roofs retain membrane")
	_folds()
	_means()
	_membrane(absent)
	var fast := FacadeMaterials.roof_set_material("sheet_metal", Color.WHITE, 0) as StandardMaterial3D
	_check(not fast.normal_enabled and fast.normal_texture == null, "Distant Fast roof remains albedo-only")
	fast = FacadeMaterials.roof_for_building({"roof_material": "metal"}, "nordic", "gabled",
		absent, 1, false) as StandardMaterial3D
	_check(not fast.normal_enabled and fast.normal_texture == null and fast.roughness_texture == null,
		"Near Fast roof must also avoid full-detail seam maps")
	var mesh := MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	mesh.material_override = copper
	mesh.set_meta("lod_layer", "Buildings")
	var world := Node3D.new()
	world.add_child(mesh)
	_check(RoofSnow.apply(world, true) == 1 and mesh.material_overlay != null, "Copper must retain winter roof snow")
	RoofSnow.apply(world, false)
	_check(mesh.material_overlay == null, "Summer must detach metal roof snow")
	_round_trip(world, mesh)
	world.free()
	if failures.is_empty():
		print("ROOF METALS OK: tag priority, paint/patina, standing folds, flat roofs, Fast and snow")
		quit(0)
	else:
		for failure in failures:
			printerr("ROOF METALS FAIL: ", failure)
		quit(1)

func _roof(tags: Dictionary, shape: String, hint: Color, style: Dictionary = {}) -> StandardMaterial3D:
	return FacadeMaterials.roof_for_building(tags, "nordic", shape, hint, 3, false, 0.3, style) as StandardMaterial3D

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _folds() -> void:
	var flat := Image.create(1024, 4, false, Image.FORMAT_RGB8)
	flat.fill(Color(0.5, 0.5, 1.0))
	var folded := RoofMetalMaps.normals(flat)
	var positive := 0
	var negative := 0
	var old := 0
	for x in folded.get_width():
		var nx := folded.get_pixel(x, 0).r * 2.0 - 1.0
		var sign_x := 1 if nx > 0.6 else (-1 if nx < -0.6 else 0)
		if sign_x != 0 and sign_x != old:
			positive += int(sign_x > 0)
			negative += int(sign_x < 0)
		old = sign_x
	_check(positive == 6 and negative == 6, "A 3.6 m repeat must contain six folded pans, not tile courses")
	_check(folded.get_pixel(0, 0).is_equal_approx(folded.get_pixel(1023, 0)), "Standing folds must tile without a normal seam")
	for set_name in ["copper", "sheet_metal"]:
		for hi in [false, true]:
			for map_name in ["diff", "nor", "rough"]:
				_check(FileAccess.file_exists(PbrTextures.map_path(set_name, map_name, hi)), "Missing bundled " + set_name + " " + map_name)

func _means() -> void:
	for set_name in ["copper", "sheet_metal"]:
		var img := MaterialLibrary._set_image(set_name, "diff", false).duplicate() as Image
		img.resize(64, 64, Image.INTERPOLATE_LANCZOS)
		var measured := Vector3.ZERO
		for y in 64:
			for x in 64:
				var p := img.get_pixel(x, y)
				measured += Vector3(p.r, p.g, p.b) / 4096.0
		var expected: Color = MaterialLibrary.PBR_SETS[set_name]["mean"]
		_check(measured.distance_to(Vector3(expected.r, expected.g, expected.b)) < 0.01,
			set_name + " calibration mean must match the loaded PBR map")
		if set_name == "sheet_metal":
			_check(absf(measured.x - measured.z) < 0.003, "Sheet paint must cover the source metal's blue oxidation")

## Flat roofs: no roll bands in the albedo or normal map, the calibrated mean
## kept. A style's flat concrete stays concrete: the bitumen photo is so dark
## that its capped tint could not reach a pale or painted finish.
func _membrane(absent: Color) -> void:
	var img := MaterialLibrary._set_image("membrane", "diff", false)
	var bands := _row_spread(img, 0)
	var expected: Color = MaterialLibrary.PBR_SETS["membrane"]["mean"]
	_check(bands.y / bands.x < 0.03, "Membrane albedo must lose its roll bands, row spread %s" % bands.y)
	_check(absf(bands.x - expected.r) < 0.004, "Destriping must keep the membrane mean, got %s" % bands.x)
	_check(_row_spread(MaterialLibrary._set_image("membrane", "nor", false), 1).y < 0.003,
		"Membrane normals must lose the roll bands too")
	for set_name in ["slate", "terracotta", "membrane"]:
		var near := FacadeMaterials.roof_set_material(set_name, Color.WHITE, 1) as StandardMaterial3D
		_check(near.normal_enabled and near.normal_scale < 1.0, set_name + " roofs must render their normal map")
		var far := FacadeMaterials.roof_set_material(set_name, Color.WHITE, 0) as StandardMaterial3D
		_check(not far.normal_enabled, set_name + " on Fast stays albedo-only")
	var green := Color("#5f8f72").srgb_to_linear()
	var painted := _roof({}, "flat", absent, {"roof_set": "concrete", "roof_colour": green})
	_check(painted.albedo_texture == MaterialLibrary._set_tex("concrete", "diff"), "Flat concrete must stay concrete")
	var mean: Color = MaterialLibrary.PBR_SETS["concrete"]["mean"] * painted.albedo_color.srgb_to_linear()
	_check(mean.g > mean.r * 1.2, "A painted flat concrete roof must keep its paint")

## Mean of channel `ch` and the standard deviation of its row means.
func _row_spread(img: Image, ch: int) -> Vector2:
	var rows: Array[float] = []
	var mean := 0.0
	for y in img.get_height():
		var sum := 0.0
		for x in img.get_width():
			sum += img.get_pixel(x, y)[ch]
		rows.append(sum / img.get_width())
		mean += rows[y] / img.get_height()
	var deviation := 0.0
	for row in rows:
		deviation += (row - mean) * (row - mean) / rows.size()
	return Vector2(mean, sqrt(deviation))

func _round_trip(world: Node3D, roof: MeshInstance3D) -> void:
	roof.owner = world
	var packed := PackedScene.new()
	var path := "user://roof-metals-roundtrip.scn"
	_check(packed.pack(world) == OK and ResourceSaver.save(packed, path) == OK,
		"Generated metal maps must pack for the world cache")
	var restored := load(path) as PackedScene
	if restored == null:
		failures.append("Metal roof cache round trip must load")
		return
	var copy := restored.instantiate() as Node3D
	var material := (copy.get_child(0) as MeshInstance3D).material_override as StandardMaterial3D
	_check(material != null and RoofVariety.is_roof(material) and material.normal_enabled
		and material.normal_texture != null and material.roughness_texture != null,
		"Cached copper must retain standing folds, roughness and snow eligibility")
	copy.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
