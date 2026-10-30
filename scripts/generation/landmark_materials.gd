class_name LandmarkMaterials
extends RefCounted

## Calibrated photographic PBR materials for landmark models (T5.3).
## Same CC0 sets and linear-space calibration as MaterialLibrary /
## FacadeMaterials (tint = target / set mean, so the texture keeps its
## grain while the mean lands on the reference colour), but mipmapped
## so lattice members and distant towers do not shimmer. Never a flat
## untextured colour; the one generated map is the Sydney Opera House
## chevron tile, which no bundled set provides.

static var _cache: Dictionary = {}
static var _texs: Dictionary = {}

## Mipmapped texture of one bundled map (shared with MaterialLibrary's
## linearised source images). The colour map is re-encoded to sRGB:
## albedo_texture is a source_color sampler the renderer decodes, so the
## linear image read dark and over-saturated (T4.7 double decode).
static func tex(set_name: String, map_name: String) -> Texture2D:
	var key := set_name + ":" + map_name
	if _texs.has(key):
		return _texs[key] as Texture2D
	var img := (MaterialLibrary._set_image(set_name, map_name)).duplicate() as Image
	if map_name == "diff":
		img.linear_to_srgb()
	if not img.has_mipmaps():
		img.generate_mipmaps(map_name == "nor")
	var t := ImageTexture.create_from_image(img)
	_texs[key] = t
	return t

## Tint (sRGB, for albedo_color) that takes the set's linear mean to
## the sRGB `hex` reference colour; wider clamp than buildings so
## landmark hues (verdigris, international orange) land on target.
static func tint(set_name: String, hex: String) -> Color:
	var mean: Color = (MaterialLibrary.PBR_SETS[set_name] as Dictionary)["mean"]
	var target := Color(hex).srgb_to_linear()
	return Color(clampf(target.r / maxf(mean.r, 0.004), 0.15, 6.0),
		clampf(target.g / maxf(mean.g, 0.004), 0.15, 6.0),
		clampf(target.b / maxf(mean.b, 0.004), 0.15, 6.0)).linear_to_srgb()

## PBR material from a bundled set calibrated to `hex`, tiled every
## `tile_m` metres (LandmarkMesh UVs are metres). roughness < 0 keeps
## the set's roughness map.
static func pbr(set_name: String, hex: String, tile_m: float = 4.0,
		roughness: float = -1.0, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%.2f|%.2f|%.2f" % [set_name, hex, tile_m, roughness, metallic]
	if _cache.has(key):
		return _cache[key] as StandardMaterial3D
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(set_name, "diff")
	m.albedo_color = tint(set_name, hex)
	m.normal_enabled = true
	m.normal_texture = tex(set_name, "nor")
	if roughness < 0.0:
		m.roughness_texture = tex(set_name, "rough")
		m.roughness = 1.0
	else:
		m.roughness = roughness
	m.metallic = metallic
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var s := 1.0 / maxf(tile_m, 0.05)
	m.uv1_scale = Vector3(s, s, s)
	_cache[key] = m
	return m

## Painted wrought iron / steel: matte paint over pitted metal (the
## concrete set's micro-relief reads as weathered paint at member size).
static func paint(hex: String, roughness: float = 0.62, metallic: float = 0.25) -> StandardMaterial3D:
	return pbr("concrete", hex, 3.0, roughness, metallic)

## Gilded or brass finials and torch flames.
static func gold() -> StandardMaterial3D:
	return pbr("concrete", "#C9A04A", 2.0, 0.32, 0.85)

## Dark glazing: deep tinted glass with a sharp sky reflection.
static func glass(hex: String = "#2E3A40") -> StandardMaterial3D:
	var key := "glass|" + hex
	if _cache.has(key):
		return _cache[key] as StandardMaterial3D
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.albedo_texture = tex("concrete", "diff")
	m.roughness = 0.08
	m.metallic = 0.65
	m.uv1_scale = Vector3(0.05, 0.05, 0.05)
	_cache[key] = m
	return m

## Self-lit lamp / clock-face glow (emission so it reads at dusk).
static func lit(hex: String, energy: float = 0.6) -> StandardMaterial3D:
	var key := "lit|%s|%.2f" % [hex, energy]
	if _cache.has(key):
		return _cache[key] as StandardMaterial3D
	var m := pbr("render", hex, 3.0, 0.45).duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color(hex)
	m.emission_energy_multiplier = energy
	_cache[key] = m
	return m

## Sydney Opera House roof: 1.06 million glossy-white and matte-cream
## Swedish tiles in a chevron pattern, 120 mm grid.
static func opera_tile() -> StandardMaterial3D:
	if _cache.has("opera_tile"):
		return _cache["opera_tile"] as StandardMaterial3D
	var n := 256
	var alb := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rough := Image.create(n, n, false, Image.FORMAT_RGB8)
	var cell := 16
	var gloss := Color("#F3F1EA")
	var matte := Color("#E2DCCB")
	var grout := Color("#B9B3A6")
	for y in n:
		for x in n:
			var cx := x / cell
			var cy := y / cell
			var lx := x % cell
			var ly := y % cell
			var g := lx == 0 or ly == 0
			# Chevron: glossy tiles along diagonal bands, matte between.
			var band := (cx + absi((cy % 8) - 4)) % 4 == 0
			var c := grout if g else (gloss if band else matte)
			var jitter := float(((cx * 73 + cy * 151) % 17)) / 17.0 * 0.03
			alb.set_pixel(x, y, c.lightened(jitter))
			var r := 0.6 if g else (0.12 if band else 0.38)
			rough.set_pixel(x, y, Color(r, r, r))
	# Tile colours are sRGB already; the sampler decodes them.
	alb.generate_mipmaps()
	rough.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(alb)
	m.roughness_texture = ImageTexture.create_from_image(rough)
	m.roughness = 1.0
	m.normal_enabled = true
	m.normal_texture = tex("slate", "nor")
	m.normal_scale = 0.25
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.uv1_scale = Vector3(0.52, 0.52, 0.52)  # 16 tiles per ~1.9 m
	_cache["opera_tile"] = m
	return m
