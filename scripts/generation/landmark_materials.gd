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
static var _glass_shaders: Dictionary = {}
## Landmarks build beside the buildings (WorldBuildGraph), and HeroLook
## reaches these caches from the buildings task. Recursive, so pbr() can
## call tex() while holding it.
static var _mutex := Mutex.new()

const CLEAR_GLASS_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 glass_tint : source_color = vec4(0.84, 0.93, 0.96, 1.0);
uniform float base_alpha = 0.16;
uniform float units_per_metre = 1.0;

// @CLOUD_SHADOW

varying vec3 wpos;
varying vec3 wnrm;

float cg_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 view_w = normalize(CAMERA_POSITION_WORLD - wpos);
	vec3 nw = dot(wnrm, view_w) >= 0.0 ? wnrm : -wnrm;

	// Per-rhombus pane micro-tilt & laminated glass edge bevel (UV aligned to lattice courses).
	vec2 g_uv = vec2(UV.x, UV.x + UV.y);
	vec2 cell = floor(g_uv);
	vec2 f = fract(g_uv);
	vec3 t1 = normalize(cross(abs(nw.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0), nw));
	vec3 t2 = cross(nw, t1);
	float j1 = cg_hash(cell + vec2(1.7, 3.1)) - 0.5;
	float j2 = cg_hash(cell + vec2(8.3, 5.9)) - 0.5;
	nw = normalize(nw + t1 * (j1 * 0.022) + t2 * (j2 * 0.022));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);

	float d_edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float edge_frost = 1.0 - smoothstep(0.0, 0.055, d_edge);

	// Low-iron laminated glass Schlick Fresnel: ~82% transparent straight-on, mirror-like at grazing angles.
	float ndv = clamp(dot(nw, view_w), 0.0, 1.0);
	float fresnel = clamp(0.08 + 0.80 * pow(1.0 - ndv, 3.6), 0.08, 0.88);

	vec3 sun_d = normalize(cloud_sun_dir);
	float sun_up = smoothstep(-0.04, 0.24, sun_d.y);
	float csh = cloud_shadow_at(wpos / max(units_per_metre, 0.001));
	float direct = sun_up * (1.0 - csh);

	vec3 refl_w = reflect(-view_w, nw);
	vec3 sky_zen = vec3(0.28, 0.50, 0.82);
	vec3 sky_hor = vec3(0.74, 0.83, 0.92);
	vec3 gnd_ref = vec3(0.46, 0.52, 0.54);
	vec3 env_ref = refl_w.y >= 0.0
		? mix(sky_hor, sky_zen, pow(clamp(refl_w.y, 0.0, 1.0), 0.55))
		: mix(sky_hor * 0.78, gnd_ref, clamp(-refl_w.y * 2.4, 0.0, 1.0));
	env_ref *= 0.10 + 0.90 * sun_up;

	float rds = max(dot(refl_w, sun_d), 0.0);
	float sun_spec = (pow(rds, 220.0) * 3.4 + pow(rds, 26.0) * 0.42) * direct;
	vec3 sun_col = mix(vec3(1.0, 0.80, 0.54), vec3(1.0, 0.98, 0.94), smoothstep(0.10, 0.45, sun_d.y));

	float alpha = clamp(base_alpha + fresnel * 0.56 + edge_frost * 0.12 + min(sun_spec * 0.32, 0.44), 0.14, 0.86);
	vec3 refl_energy = env_ref * (fresnel * 0.80) + sun_col * sun_spec * (0.35 + 0.65 * fresnel);

	ALBEDO = mix(glass_tint.rgb, env_ref, clamp(fresnel * 0.85, 0.0, 0.92));
	EMISSION = refl_energy / max(alpha, 0.14) * 0.48;
	ALPHA = alpha;
	ROUGHNESS = mix(0.032, 0.18, edge_frost);
	SPECULAR = 0.92;
	METALLIC = 0.08;
}
"""

## Mipmapped texture of one bundled map (shared with MaterialLibrary's
## linearised source images). The colour map is re-encoded to sRGB:
## albedo_texture is a source_color sampler the renderer decodes, so the
## linear image read dark and over-saturated (T4.7 double decode).
static func tex(set_name: String, map_name: String) -> Texture2D:
	_mutex.lock()
	var key := set_name + ":" + map_name
	if _texs.has(key):
		var ret: Texture2D = _texs[key] as Texture2D
		_mutex.unlock()
		return ret
	var img := (MaterialLibrary._set_image(set_name, map_name)).duplicate() as Image
	if map_name == "diff":
		img.linear_to_srgb()
	if not img.has_mipmaps():
		img.generate_mipmaps(map_name == "nor")
	var t := ImageTexture.create_from_image(img)
	_texs[key] = t
	var ret: Texture2D = t
	_mutex.unlock()
	return ret

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
	_mutex.lock()
	var key := "%s|%s|%.2f|%.2f|%.2f" % [set_name, hex, tile_m, roughness, metallic]
	if _cache.has(key):
		var ret: StandardMaterial3D = _cache[key] as StandardMaterial3D
		_mutex.unlock()
		return ret
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
	# LandmarkShader weathers these on desktop Ultra.
	m.set_meta(LandmarkShader.META, set_name)
	m.set_meta("landmark_hex", hex)
	_cache[key] = m
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret

## Painted wrought iron / steel: matte paint over pitted metal (the
## concrete set's micro-relief reads as weathered paint at member size).
static func paint(hex: String, roughness: float = 0.62, metallic: float = 0.25) -> StandardMaterial3D:
	return pbr("concrete", hex, 3.0, roughness, metallic)

## Gilded or brass finials and torch flames.
static func gold() -> StandardMaterial3D:
	return pbr("concrete", "#C9A04A", 2.0, 0.32, 0.85)

## Carved statuary marble (Carrara / Botticino / Pentelic): fine stone grain
## and satin polish without LandmarkShader's 1.25 x 0.55 m ashlar block joints.
static func marble(hex: String = "#EFEADF", roughness: float = 0.32) -> StandardMaterial3D:
	_mutex.lock()
	var key := "marble|%s|%.2f" % [hex, roughness]
	if _cache.has(key):
		var ret: StandardMaterial3D = _cache[key] as StandardMaterial3D
		_mutex.unlock()
		return ret
	var m := pbr("limestone", hex, 2.4, roughness, 0.0).duplicate() as StandardMaterial3D
	m.set_meta("landmark_marble", true)
	_cache[key] = m
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret

## Dark glazing: deep tinted glass with a sharp sky reflection.
static func glass(hex: String = "#2E3A40") -> StandardMaterial3D:
	_mutex.lock()
	var key := "glass|" + hex
	if _cache.has(key):
		var ret: StandardMaterial3D = _cache[key] as StandardMaterial3D
		_mutex.unlock()
		return ret
	var m := StandardMaterial3D.new()
	# Lifted toward a slate blue: the bare hex times the concrete texture
	# is near-black, and a large flat window rendered as a black hole.
	m.albedo_color = Color(hex).lerp(Color("#56697a"), 0.8)
	m.albedo_texture = tex("concrete", "diff")
	# Dark glass, not a mirror: a mostly metallic pane reflects the dark
	# environment and renders pure black on a large flat window (the church
	# archetype's front windows).
	m.roughness = 0.12
	m.metallic = 0.2
	m.uv1_scale = Vector3(0.05, 0.05, 0.05)
	_cache[key] = m
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret

## Clear architectural structural glazing (e.g. I. M. Pei's Louvre Pyramid):
## textured translucent StandardMaterial3D base + Fresnel reflective shader override.
static func clear_glass(hex: String = "#CBE4EE", opacity: float = 0.22) -> StandardMaterial3D:
	_mutex.lock()
	var key := "clear_glass|%s|%.2f" % [hex, opacity]
	if _cache.has(key):
		var ret: StandardMaterial3D = _cache[key] as StandardMaterial3D
		_mutex.unlock()
		return ret
	var m := StandardMaterial3D.new()
	var c := Color(hex)
	m.albedo_color = Color(c.r, c.g, c.b, opacity)
	m.albedo_texture = pool_water().albedo_texture
	m.roughness = 0.04
	m.metallic = 0.12
	m.metallic_specular = 0.92
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.uv1_scale = Vector3(0.2, 0.2, 0.2)
	_cache[key] = m
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret

static func clear_glass_shader(hex: String = "#D6ECF4", base_alpha: float = 0.15) -> ShaderMaterial:
	var m2u := WorldScale.metres_to_units()
	var key := "%s|%.2f|%.3f" % [hex, base_alpha, m2u]
	_mutex.lock()
	var sm: ShaderMaterial = _glass_shaders.get(key)
	if sm == null:
		sm = ShaderMaterial.new()
		sm.shader = SharedShader.of(CLEAR_GLASS_CODE.replace("// @CLOUD_SHADOW", TerrainGlsl.CLOUD_SHADOW_GLSL))
		sm.render_priority = 1
		sm.set_shader_parameter("glass_tint", Color(hex))
		sm.set_shader_parameter("base_alpha", base_alpha)
		sm.set_shader_parameter("units_per_metre", m2u)
		_glass_shaders[key] = sm
	_mutex.unlock()
	return sm

## Glossy outdoor pool water without LandmarkShader weathering or glass
## greying, keeping vivid turquoise-cyan hue on desktop Ultra.
static func pool_water(hex: String = "#386878", roughness: float = 0.08) -> StandardMaterial3D:
	_mutex.lock()
	var key := "pool_water|%s|%.2f" % [hex, roughness]
	if _cache.has(key):
		var ret: StandardMaterial3D = _cache[key] as StandardMaterial3D
		_mutex.unlock()
		return ret
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	if not _texs.has("pool_water_caustic"):
		var n := 128
		var img := Image.create(n, n, false, Image.FORMAT_RGB8)
		for y in n:
			var v := TAU * float(y) / float(n)
			for x in n:
				var u := TAU * float(x) / float(n)
				var w := 0.5 + 0.5 * (sin(u * 2.0 + sin(v * 3.0)) * cos(v * 2.0 - cos(u * 3.0)))
				var g := clampf(0.88 + 0.12 * w, 0.0, 1.0)
				img.set_pixel(x, y, Color(g, g, g))
		img.generate_mipmaps()
		_texs["pool_water_caustic"] = ImageTexture.create_from_image(img)
	m.albedo_texture = _texs["pool_water_caustic"] as Texture2D
	m.roughness = roughness
	m.metallic = 0.05
	m.metallic_specular = 0.65
	m.normal_enabled = true
	m.normal_texture = tex("sand", "nor")
	m.normal_scale = 0.14
	m.uv1_scale = Vector3(0.28, 0.28, 0.28)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.set_meta(FountainWater.BASIN_META, {"hex": hex, "roughness": roughness})
	m.set_meta("landmark_hex", hex)
	_cache[key] = m
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret

## Self-lit lamp / clock-face glow (emission so it reads at dusk).
static func lit(hex: String, energy: float = 0.6) -> StandardMaterial3D:
	_mutex.lock()
	var key := "lit|%s|%.2f" % [hex, energy]
	if _cache.has(key):
		var ret: StandardMaterial3D = _cache[key] as StandardMaterial3D
		_mutex.unlock()
		return ret
	var m := pbr("render", hex, 3.0, 0.45).duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color(hex)
	m.emission_energy_multiplier = energy
	_cache[key] = m
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret

## Night-only lamp / interior glow: dark albedo and zero emission by day,
## ramped up at dusk/night by `LandmarkLights._night_lamps` via `NIGHT_GLOW_META`.
static func night_lit(hex: String, energy: float = 1.0, day_hex: String = "#2B3238") -> StandardMaterial3D:
	_mutex.lock()
	var key := "night_lit|%s|%.2f|%s" % [hex, energy, day_hex]
	if _cache.has(key):
		var ret: StandardMaterial3D = _cache[key] as StandardMaterial3D
		_mutex.unlock()
		return ret
	var m := pbr("render", day_hex, 3.0, 0.45).duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color(hex)
	m.emission_energy_multiplier = 0.0
	m.set_meta(LandmarkLights.NIGHT_GLOW_META, energy)
	_cache[key] = m
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret

## Sydney Opera House roof: 1.06 million glossy-white and matte-cream
## Swedish tiles in a chevron pattern, 120 mm grid.
static func opera_tile() -> StandardMaterial3D:
	_mutex.lock()
	if _cache.has("opera_tile"):
		var ret: StandardMaterial3D = _cache["opera_tile"] as StandardMaterial3D
		_mutex.unlock()
		return ret
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
	var ret: StandardMaterial3D = m
	_mutex.unlock()
	return ret
