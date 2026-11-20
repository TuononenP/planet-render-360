extends SceneTree

## Offline Stockholm wall palette, glare caps and bark contracts, other cities unchanged.
## Always run with --headless:  godot --headless --script tests/stockholm_palette_test.gd
## - walls: Stockholm leans to the ochre and blush families (sage and mist plaster read olive in
##   shade), its plaster palettes are warm and light with nothing yellow-green, painted
##   boarding is calibrated to its colour, the plaster photo's grain is softened;
## - glare: dry roads, paving, ground and curtain glass carry a specular cap and a roughness floor
##   in Stockholm and none elsewhere;
## - trees: Stockholm's planes and birches take darker bark.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _place(lat: float, lon: float) -> LocationData:
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.grid_size = 32
	data.heights.resize(32 * 32)
	data.heights.fill(3.0)
	return data

func _luma(c: Color) -> float:
	return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722

## Share of 600 positions whose paint family is sage or mist (the two that green a warm wall).
func _cool_share(tone: float) -> float:
	var cool := 0
	for i in 600:
		var f := WallVariety._family(float(i) * 7.31 + 3.0, float(i) * 3.77 + 11.0, tone)
		if f == 4 or f == 5:
			cool += 1
	return float(cool) / 600.0

func _walls() -> void:
	var sto := ArchitectureStyle.tone_for(59.3293, 18.0686)
	_check(is_equal_approx(sto, ArchitectureStyle.STOCKHOLM_TONE), "Stockholm takes its own tone")
	_check(is_equal_approx(ArchitectureStyle.tone_for(59.2760, 17.9060), ArchitectureStyle.STOCKHOLM_TONE),
		"the suburbs of Stockholm's zones share the tone")
	for city: Array in [["Paris", 48.8566, 2.3522], ["London", 51.5074, -0.1278],
			["Oslo", 59.9139, 10.7522], ["Turku", 60.4518, 22.2666]]:
		var lat := float(city[1])
		var lon := float(city[2])
		var want := TerrainBuilder._hash(snappedf(lat, 0.125) * 7.31 + 1.7, snappedf(lon, 0.125) * 3.77 + 4.1)
		_check(is_equal_approx(ArchitectureStyle.tone_for(lat, lon), want), "%s keeps its hashed tone" % city[0])
	_check(_cool_share(ArchitectureStyle.STOCKHOLM_TONE) < 0.12,
		"sage and mist stay rare at Stockholm's tone (%.2f)" % _cool_share(ArchitectureStyle.STOCKHOLM_TONE))
	_check(_cool_share(0.7) > 0.3, "a place leaning to sage still draws them (the families are unchanged)")
	# The palettes: warm and light. A yellow or green leaning render turns olive in the cool shade, so
	# the apartment palettes keep red over green (linear) by a quarter at least.
	var palettes := {"STOCKHOLM_PLASTER": ArchitectureCitiesWaterfront.STOCKHOLM_PLASTER,
		"STOCKHOLM_PALE": ArchitectureCitiesWaterfront.STOCKHOLM_PALE,
		"STOCKHOLM_VILLA": ArchitectureCitiesWaterfront.STOCKHOLM_VILLA}
	for pal_name: String in palettes:
		var pal: Array = palettes[pal_name]
		var greens := 0
		for hex: String in pal:
			var c := Color(hex)
			_check(c.get_luminance() >= 0.42, "%s %s is light enough not to turn olive in shade" % [pal_name, hex])
			if c.g > c.r + 0.01:
				greens += 1
			if pal_name != "STOCKHOLM_VILLA":
				var lin := c.srgb_to_linear()
				_check(lin.r >= lin.g * 1.24, "%s %s keeps red over green in shade (%.2f)" % [pal_name, hex, lin.r / lin.g])
		_check(greens == 0, "%s has no green-leaning render: it reads olive in cool shade (%d)" % [pal_name, greens])
	var plaster: Array = ArchitectureCitiesWaterfront.STOCKHOLM_PLASTER
	var warm := 0
	for hex: String in plaster:
		if Color(hex).r > Color(hex).g * 1.03 and Color(hex).g > Color(hex).b * 1.08:
			warm += 1
	_check(warm >= 6, "Gamla stan plaster is mostly ochre, terracotta and rust (%d of %d)" % [warm, plaster.size()])
	# Wooden houses: Falu red, ochre and yellow.
	var wood: Array = (ArchitectureCitiesWaterfront.REGIONS["stockholm_wood"]["house"]["w"][0] as Array)[1]
	var reds := 0
	for hex: String in wood:
		if Color(hex).r > Color(hex).g * 1.4:
			reds += 1
	_check(reds >= 2, "the cottage districts' boarding is red and ochre")
	# Painted boarding is calibrated to its colour in Stockholm, and left to the shared cap elsewhere.
	var ochre := ArchitectureStyle._lin("#d8b878")
	var wood_mean: Color = MaterialLibrary.PBR_SETS["wood"]["mean"]
	var sto_style := {"city": "stockholm", "wall_colour": ochre}
	var hel_style := {"city": "helsinki", "wall_colour": ochre}
	var sto_tint := FacadeMaterials._wall_tint({}, sto_style, "wood", 0.3)
	var hel_tint := FacadeMaterials._wall_tint({}, hel_style, "wood", 0.3)
	_check(absf(_luma(wood_mean * sto_tint) - _luma(ochre)) < _luma(ochre) * 0.15,
		"Stockholm's painted boarding reaches its ochre")
	_check(_luma(wood_mean * hel_tint) < _luma(ochre) * 0.75, "other cities keep the shared 2.8x calibration cap")
	_check(hel_tint.is_equal_approx(FacadeMaterials._keep_chroma("wood", FacadeMaterials._calib("wood", ochre))),
		"a non-Stockholm wood tint is the shared calibration")
	# Texture identity: Stockholm's looks and glass do not share cache keys with other cities'.
	var look := {"frame": Color.WHITE, "shutter": Color.BLACK, "window": "casement", "bay_m": 3.0, "curtain": ""}
	var key_sto := FacadeMaterials._look_key(look.merged({"city": "stockholm"}))
	var key_other := FacadeMaterials._look_key(look.merged({"city": "paris"}))
	_check(key_sto != key_other and key_sto.contains("|sto"), "a Stockholm look keys its own textures")
	_check(key_other == FacadeMaterials._look_key(look), "other cities' look keys are unchanged")

func _grain(texs: Dictionary) -> float:
	var img := (texs["albedo"] as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var sum := 0.0
	var sq := 0.0
	var n := 0
	for y in range(8, img.get_height() - 8, 3):
		for x in range(8, img.get_width() - 8, 3):
			var l := img.get_pixel(x, y).get_luminance()
			sum += l
			sq += l * l
			n += 1
	var mean := sum / float(n)
	return sqrt(maxf(sq / float(n) - mean * mean, 0.0))

func _grain_check() -> void:
	var loader := Callable(MaterialLibrary, "_set_image")
	var base := {"frame": Color(0.9, 0.9, 0.9), "shutter": Color.BLACK, "shutter_p": 0.0, "window": "casement",
		"rails": 0.0, "variant": 0, "bay_m": 3.0, "floor_h": 3.2, "wall_colour": Color(0.6, 0.5, 0.3)}
	var sto := FacadeComposer.compose_tile("render", "punched", 1, base.merged({"city": "stockholm"}), loader)
	var other := FacadeComposer.compose_tile("render", "punched", 1, base.merged({"city": "paris"}), loader)
	var gs := _grain(sto)
	var go := _grain(other)
	_check(go > 0.002 and gs < go * 0.85, "Stockholm's plaster photo is smoother (%.4f vs %.4f)" % [gs, go])

func _glare() -> void:
	FacadeMaterials.begin_build()
	var sto := _place(59.3293, 18.0686)
	var paris := _place(48.8566, 2.3522)
	var off := Vector2(1.0, 0.0)
	RoadSurface.set_place(paris)
	_check(RoadSurface._glare == off, "no glare cap outside Stockholm")
	var asphalt_paris := RoadSurface.material(Color(0.2, 0.2, 0.2))
	_check(asphalt_paris.get_shader_parameter("glare") == off, "Paris asphalt keeps the shader as it was")
	var paved_paris := RoadSurface.paved_material("pavement", Color(0.4, 0.4, 0.4))
	_check(paved_paris.get_shader_parameter("glare") == off, "Paris paving keeps the shader as it was")
	RoadSurface.set_place(sto)
	_check(RoadSurface._glare == RoadSurface.STOCKHOLM_GLARE, "Stockholm caps dry specular")
	_check(RoadSurface.STOCKHOLM_GLARE.x <= 0.2 and RoadSurface.STOCKHOLM_GLARE.y >= 0.7,
		"the cap is a real one: specular at most 0.2, roughness at least 0.7")
	_check(asphalt_paris.get_shader_parameter("glare") == RoadSurface.STOCKHOLM_GLARE,
		"the shared asphalt follows the place")
	var paved_sto := RoadSurface.paved_material("pavement", Color(0.4, 0.4, 0.4))
	_check(paved_sto.get_shader_parameter("glare") == RoadSurface.STOCKHOLM_GLARE, "Stockholm paving is capped")
	RoadSurface.set_place(paris)
	_check(asphalt_paris.get_shader_parameter("glare") == off, "the cap does not leak back to the next place")
	for code: String in [RoadSurface.CODE, RoadSurface.PAVED_CODE, GroundShader.CODE, FacadeShader.SHADER]:
		_check(code.contains("glare") or code.contains("glass_cap"), "every shader declares its cap")
	# Curtain glass: Stockholm's is capped and keyed apart.
	var sto_look := {"city": "stockholm", "bay_m": 3.0, "floor_h": 3.8, "curtain": ""}
	var glass_sto := FacadeTextures._facade_material_for("glass", 0, 1, Color.WHITE, "curtain", sto_look)
	var glass_hel := FacadeTextures._facade_material_for("glass", 0, 1, Color.WHITE, "curtain",
		{"city": "helsinki", "bay_m": 3.0, "floor_h": 3.8, "curtain": ""})
	_check(glass_hel.metallic > 0.55 and not glass_hel.has_meta("glass_cap"), "other cities' glass is unchanged")
	_check(glass_sto.metallic <= 0.11 and glass_sto.metallic_specular <= 0.13 and glass_sto.has_meta("glass_cap"),
		"Stockholm's glass is a duller mirror")
	# The shared distant glass (far blocks, towers): Stockholm's own, keyed apart.
	var far_sto := FacadeTextures.curtain_distant(1, {"city": "stockholm"})
	var far_other := FacadeTextures.curtain_distant(1)
	_check(far_sto != far_other and far_sto.metallic <= 0.11 and far_other.metallic > 0.55,
		"the distant curtain glass is capped in Stockholm only")
	_check(far_sto.roughness_texture == null and far_sto.roughness >= 0.45 and far_other.roughness_texture != null,
		"Stockholm's far glass has one dull roughness, not the mirror-smooth pane map")
	_check(FacadeTextures.curtain_distant(1, {"city": "stockholm"}) == far_sto
		and FacadeTextures.curtain_distant(1, {"city": "paris"}) == far_other, "and each is shared")
	var shader_mat := FacadeShader.from_standard(glass_sto)
	_check((shader_mat.get_shader_parameter("glass_cap") as Vector3).z >= 0.5, "the Ultra glass floors its roughness")
	_check(FacadeShader.from_standard(glass_hel).get_shader_parameter("glass_cap") == null, "other cities' shader glass has no cap")

## One MeshInstance3D per material, under a root.
func _glare_world(mats: Array) -> Node3D:
	var root := Node3D.new()
	for m: Material in mats:
		var mi := MeshInstance3D.new()
		mi.mesh = BoxMesh.new()
		mi.mesh.surface_set_material(0, m)
		root.add_child(mi)
	return root

func _shown(mi: Node) -> Material:
	var m := (mi as MeshInstance3D).get_surface_override_material(0)
	return m if m != null else (mi as MeshInstance3D).mesh.surface_get_material(0)

func _world_glare() -> void:
	var tex := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGB8))
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = tex
	stone.roughness = 0.9
	var wet := StandardMaterial3D.new()
	wet.albedo_texture = tex
	wet.roughness = 0.38
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.35
	glass.roughness = 0.04
	glass.albedo_color = Color(0.8, 0.9, 1.0, 0.8)
	var wall := StandardMaterial3D.new()
	wall.albedo_texture = tex
	wall.set_meta("wall", true)
	var paint := StandardMaterial3D.new()
	paint.roughness = 0.3
	var rock_std := LandmarkMaterials.pbr("rock", "#7B746E", 3.0)
	var rock := LandmarkShader.swap(rock_std)
	var mats := [stone, wet, glass, wall, paint, rock]
	var sto := _place(59.3293, 18.0686)
	var paris := _place(48.8566, 2.3522)
	var w_paris := _glare_world(mats)
	_check(StockholmGlare.apply(w_paris, paris) == 0, "no glare pass outside Stockholm")
	for i in mats.size():
		_check(_shown(w_paris.get_child(i)) == mats[i], "Paris keeps material %d" % i)
	var w := _glare_world(mats)
	var n := StockholmGlare.apply(w, sto)
	_check(n == 4, "Stockholm caps the stone, wet stone, glass and landmark rock (%d)" % n)
	var cs := _shown(w.get_child(0)) as StandardMaterial3D
	_check(cs != stone and cs.metallic_specular <= 0.16 and cs.roughness >= 0.55, "dry stone loses its sheen")
	_check(stone.metallic_specular >= 0.45 and is_equal_approx(stone.roughness, 0.9), "the shared stone material is not changed")
	var cw := _shown(w.get_child(1)) as StandardMaterial3D
	_check(cw.roughness >= 0.55 and cw.roughness < 0.6, "wet stone is floored, not flattened to dry")
	var cg := _shown(w.get_child(2)) as StandardMaterial3D
	_check(cg != glass and cg.metallic <= 0.11 and cg.roughness >= 0.5 and cg.albedo_color.r < 0.6 and is_equal_approx(cg.albedo_color.a, 0.8),
		"alpha glass is dimmer and duller, still clear")
	_check(glass.roughness < 0.05, "the shared glass is not changed")
	_check(_shown(w.get_child(3)) == wall and _shown(w.get_child(4)) == paint, "facade-marked and untextured paint materials stay")
	var cr := _shown(w.get_child(5)) as ShaderMaterial
	_check(cr != rock and cr.get_shader_parameter("glare") == StockholmGlare.STONE and rock.get_shader_parameter("glare") == null,
		"landmark rock takes the cap on a copy")
	_check(StockholmGlare.apply(w, sto) == 0, "a second pass changes nothing")
	_check(LandmarkShader.shader().code.contains("uniform vec2 glare"), "the landmark shader declares the cap")
	w.free()
	w_paris.free()

func _plinth() -> void:
	var off := Vector2(1.0, 0.0)
	var plain := FinlandRelief._base_stone("#958c86") as ShaderMaterial
	var calm := FinlandRelief._base_stone("#958c86", true) as ShaderMaterial
	_check(plain.get_shader_parameter("glare") == off, "the shared granite base keeps the shader as it was")
	_check(calm != plain and calm.get_shader_parameter("glare") == RoadSurface.STOCKHOLM_GLARE,
		"Stockholm's granite base takes the glare cap, cached apart")
	var ns: Variant = plain.get_shader_parameter("normal_scale")
	_check(ns == null or float(calm.get_shader_parameter("normal_scale")) <= float(ns) * 0.51, "and half the relief")
	_check(FinlandRelief._base_stone("#958c86", true) == calm and FinlandRelief._base_stone("#958c86") == plain,
		"each is shared")
	var body := PlinthStyle.body_material() as ShaderMaterial
	var body_calm := PlinthStyle.body_material(true) as ShaderMaterial
	var cop_calm := PlinthStyle.coping_material(true) as ShaderMaterial
	_check(body.get_shader_parameter("glare") == off and (PlinthStyle.coping_material() as ShaderMaterial).get_shader_parameter("glare") == off,
		"the shared building plinth is unchanged")
	_check(body_calm != body and body_calm.get_shader_parameter("glare") == RoadSurface.STOCKHOLM_GLARE
		and cop_calm.get_shader_parameter("glare") == RoadSurface.STOCKHOLM_GLARE, "Stockholm's building plinth and coping take the cap")
	_check(PlinthStyle.body_material(true) == body_calm and PlinthStyle.body_material() == body, "each is shared")
	_check(StreetSnow.material(StandardMaterial3D.new()).get_shader_parameter("glare") == off, "other StreetSnow stone is unchanged")
	_check(StreetSnow._shader.code.contains("min(0.5, glare.x)") and StreetSnow._shader.code.contains("max(roughness, glare.y)"),
		"the snow-stone shader applies the cap to dry stone")

func _trees() -> void:
	for sp in ["plane", "birch", "lime", "oak", "maple", "rowan"]:
		_check(TreeSpecies.stockholm_species(sp) == sp + "_grey", "Stockholm's %s takes the grey bark" % sp)
	for sp in ["spruce", "scots_pine", "palm", "plane_grey"]:
		_check(TreeSpecies.stockholm_species(sp) == sp, "%s keeps its name" % sp)
	for orig in ["plane", "birch", "lime", "oak"]:
		var sp: String = orig + "_grey"
		var kind := str(TreeSpecies.spec(sp)["bark"])
		_check(kind.ends_with("_grey"), "%s has a grey bark kind (%s)" % [sp, kind])
		_check(TreeSpecies.spec(sp)["h"] == TreeSpecies.spec(orig)["h"] and TreeSpecies.spec(sp)["gen"] == TreeSpecies.spec(orig)["gen"],
			"%s is the same tree as %s" % [sp, orig])
		var a: Color = TreeSpecies.BARK_TINT[kind]
		var b: Color = TreeSpecies.BARK_TINT[str(TreeSpecies.spec(orig)["bark"])]
		_check(a.get_luminance() < b.get_luminance() * 0.85, "%s impostor bark is darker than %s" % [sp, orig])
		var tex_a := FoliageTextures.paint_bark(kind, 0.12)[0] as Image
		var tex_b := FoliageTextures.paint_bark(str(TreeSpecies.spec(orig)["bark"]), 0.12)[0] as Image
		_check(_mean_luma(tex_a) < _mean_luma(tex_b) * 0.85,
			"%s bark texture is darker (%.2f vs %.2f)" % [sp, _mean_luma(tex_a), _mean_luma(tex_b)])
		_check(_mean_luma(tex_a) < 0.5, "%s bark is a grey-brown, not cream (%.2f)" % [sp, _mean_luma(tex_a)])
	var grey_bark := TreeMeshLibrary.bark_material("furrowed_grey")
	var shared_bark := TreeMeshLibrary.bark_material("furrowed")
	_check(grey_bark.metallic_specular <= 0.15 and shared_bark.metallic_specular >= 0.45,
		"Stockholm's trunks lose the grazing sheen, the shared bark keeps it")
	_check(TreeSpecies.spec("plane")["bark"] == "plane" and TreeSpecies.spec("birch")["bark"] == "birch"
		and TreeSpecies.spec("lime")["bark"] == "furrowed", "the shared species keep their bark")
	_check(not TreeSpecies.SPECIES.has("lime_grey") and TreeSpecies.spec("nonsense_grey") == TreeSpecies.spec("lime"),
		"unknown names still fall back to the lime")

func _mean_luma(img: Image) -> float:
	var sum := 0.0
	var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			sum += img.get_pixel(x, y).get_luminance()
			n += 1
	return sum / float(n)

func _run() -> void:
	_walls()
	_grain_check()
	_glare()
	_world_glare()
	_plinth()
	_trees()
	if failures.is_empty():
		print("STOCKHOLM PALETTE OK: ochre and blush walls, smooth plaster, glare caps, grey bark, other cities unchanged")
		quit(0)
	else:
		for f in failures:
			printerr("STOCKHOLM PALETTE FAIL: ", f)
		quit(1)
