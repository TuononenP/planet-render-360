class_name PbrTextures
extends RefCounted

## CC0 PBR texture loading and material construction for
## MaterialLibrary: set images, weather tiling, calibration tints
## and cached PBR materials. Set tables and caches stay in
## MaterialLibrary (single source); this class is the loader.
static func _set_image(set_name: String, map_name: String) -> Image:
	var key := set_name + ":" + map_name
	if MaterialLibrary._set_images.has(key):
		return MaterialLibrary._set_images[key] as Image
	var img: Image = null
	var path := MaterialLibrary.TEXTURE_DIR + set_name + "_" + map_name + ".jpg"
	if FileAccess.file_exists(path):
		var loaded := Image.load_from_file(path)
		if loaded != null and not loaded.is_empty() and loaded.get_width() >= 64:
			img = loaded
			if map_name == "diff":
				img.srgb_to_linear()
				if set_name == "terracotta":
					_weather_tiles(img)
	if img == null:
		if not MaterialLibrary._set_images.has("warned:" + set_name):
			MaterialLibrary._set_images["warned:" + set_name] = true
			push_warning("MaterialLibrary: bundled PBR set '%s' unreadable; procedural fallback." % set_name)
		img = Image.create(64, 64, false, Image.FORMAT_RGB8)
		if map_name == "nor":
			img.fill(Color(0.5, 0.5, 1.0))
		else:
			MaterialLibrary.speckle(img, Color(0.5, 0.5, 0.5), 700, 3.1, 0.08)
	MaterialLibrary._set_images[key] = img
	return img

## Remap a linear clay-tile image to weathered terracotta (see
## MaterialLibrary.TERRACOTTA_CONTRAST): per channel, out = target·(1 + k·(in/mean − 1)).
static func _weather_tiles(img: Image) -> void:
	var to: Color = (MaterialLibrary.PBR_SETS["terracotta"] as Dictionary)["mean"]
	var fr := MaterialLibrary.TERRACOTTA_PHOTO_MEAN
	var k := MaterialLibrary.TERRACOTTA_CONTRAST
	if img.is_compressed():
		img.decompress()
	# 512² keeps ~4.5 cm texels at the 11 m roof repeat and a quarter
	# of the per-pixel remap cost.
	if img.get_width() > 512:
		img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(
				clampf(to.r * (1.0 + k * (c.r / fr.r - 1.0)), 0.0, 1.0),
				clampf(to.g * (1.0 + k * (c.g / fr.g - 1.0)), 0.0, 1.0),
				clampf(to.b * (1.0 + k * (c.b / fr.b - 1.0)), 0.0, 1.0)))

## Runtime texture of one set map for StandardMaterial3D (pbr_material),
## mipmapped (T4.7: without mips the tiled roofs and road ribbons alias
## to speckle at distance). albedo_texture is a source_color sampler the
## renderer sRGB-decodes (runtime ImageTextures included — measured on
## Metal), so the colour map is re-encoded to sRGB here; handing it the
## linearised image decoded it twice (dark, over-contrasted roofs and
## near-black asphalt). The cached Image stays linear and mip-free for
## the CPU composers and the GroundMaterial shader (raw samplers).
static func _set_tex(set_name: String, map_name: String) -> Texture2D:
	var key := "t:" + set_name + ":" + map_name
	if MaterialLibrary._set_texs.has(key):
		return MaterialLibrary._set_texs[key] as Texture2D
	var img := (_set_image(set_name, map_name) as Image).duplicate() as Image
	if map_name == "diff":
		img.linear_to_srgb()
	if not img.has_mipmaps():
		img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	MaterialLibrary._set_texs[key] = t
	return t

## Per-channel tint taking a set mean to a target, clamped so texture
## contrast survives (no channel pushed past 0.3×–2.8×).
static func _calib_tint(mean: Color, target: Color) -> Color:
	return Color(
		clampf(target.r / maxf(mean.r, 0.004), 0.3, 2.8),
		clampf(target.g / maxf(mean.g, 0.004), 0.3, 2.8),
		clampf(target.b / maxf(mean.b, 0.004), 0.3, 2.8))

## Shared single-set PBR material, cached by set + tint + repeat.
## detail 0 is the F1 distant path: albedo only, scalar roughness.
## `tint` is LINEAR (every calibration here is target/mean in linear);
## albedo_color is a source_color uniform the renderer sRGB-decodes, so
## it is stored encoded (T4.7 — passing the linear tint raw squared it:
## near-black navy asphalt and slate, blown-out bright tints).
static func pbr_material(set_name: String, tint: Color = Color.WHITE,
		uv_scale: float = 1.0, detail: int = 1) -> StandardMaterial3D:
	var key := "%s|%s|%.2f|%d" % [set_name, tint.to_html(), uv_scale, detail]
	if MaterialLibrary._pbr_mats.has(key):
		return MaterialLibrary._pbr_mats[key] as StandardMaterial3D
	if MaterialLibrary._pbr_mats.size() >= 64:
		return MaterialLibrary._pbr_mats.values()[0] as StandardMaterial3D
	var row: Dictionary = MaterialLibrary.PBR_SETS.get(set_name, MaterialLibrary.PBR_SETS["limestone"])
	var m := StandardMaterial3D.new()
	m.albedo_texture = _set_tex(set_name, "diff")
	m.albedo_color = tint.linear_to_srgb()
	if detail >= 1:
		m.normal_texture = _set_tex(set_name, "nor")
		m.roughness_texture = _set_tex(set_name, "rough")
		m.roughness = 1.0
	else:
		m.roughness = float(row["rough"])
	m.metallic = float(row["metal"])
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	MaterialLibrary._pbr_mats[key] = m
	return m

## OSM `building:colour` / `roof:colour`: #rgb/#rrggbb hex (with or
## without #) plus the common named colours, returned linear with
## alpha 1; unparseable/empty reads alpha 0 (caller keeps its tint).
static func parse_colour_tag(s: String) -> Color:
	var t := s.strip_edges().to_lower()
	if t == "":
		return Color(0, 0, 0, 0)
	if t.begins_with("#"):
		t = t.substr(1)
	var hex_ok := t.length() == 6 or t.length() == 3
	if hex_ok:
		for i in t.length():
			if "0123456789abcdef".find(t.substr(i, 1)) < 0:
				hex_ok = false
	if hex_ok:
		if t.length() == 3:
			t = t.substr(0, 1) + t.substr(0, 1) + t.substr(1, 1) \
				+ t.substr(1, 1) + t.substr(2, 1) + t.substr(2, 1)
		var c := Color.html(t)
		c.a = 1.0
		return c.srgb_to_linear()
	var named := {
		"white": "FFFFFF", "black": "232323", "grey": "8A8A8A",
		"gray": "8A8A8A", "darkgrey": "4A4A4A", "darkgray": "4A4A4A",
		"lightgrey": "C8C8C8", "lightgray": "C8C8C8", "red": "9E3B2E",
		"brown": "6B4A2F", "beige": "F0E6CE", "yellow": "D9B23C",
		"cream": "F2EAD8", "green": "5A6B3C", "blue": "3C5A78",
		"orange": "B25A2A", "pink": "D8A0A0", "terracotta": "A9522F",
	}
	if named.has(t):
		var c := Color.html(named[t])
		c.a = 1.0
		return c.srgb_to_linear()
	return Color(0, 0, 0, 0)

## Photographic PBR ground per land class (T4.3): the T2.4 §2.6 class
## maps to a bundled set (GROUND_SETS) calibrated toward the class
## palette colour, so the no-satellite path reads photographic instead
## of flat. (Contract names this parameter `class`; renamed: `class`
## is reserved.) One shared material per class (PRD §6 budget
## direction); water surfaces use water_material(), and unknown or
## unmapped ("") classes share the settled-ground fallback, never a
## wrong class colour.
