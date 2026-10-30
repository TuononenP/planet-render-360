class_name FarSurface
extends RefCounted

## Pure far-field samplers for FarTerrainBuilder (T3.7): DEM ring
## heights, imagery drape UVs, the no-imagery mountain colour ramp, and
## the two-drape ring material. All positions are true metres relative
## to the viewpoint (+X east, +Z south, contract §1.1); callers convert
## from internal units. Mercator mapping is exact and shared with
## TerrainBuilder.satellite_uv (WorldScale.latlon_from_xz ->
## TileFetcher.global_pixel), so near and far imagery line up.

## Edge fade of a DEM ring window, in source pixels: a finer ring hands
## over to the next coarser one over this band instead of stepping.
const RING_FADE_PX := 24.0
## Far imagery gain + albedo ceiling (shader and CPU albedo_at agree).
const IMAGERY_GAIN := 1.6
const ALBEDO_CAP := 0.85

## Global pixel of a viewpoint-relative metre position at a zoom.
static func global_px(data: LocationData, xm: float, zm: float, zoom: int) -> Vector2:
	var ll := WorldScale.latlon_from_xz(xm, zm, data.latitude, data.longitude)
	return TileFetcher.global_pixel(ll.x, ll.y, zoom)

## Ring height at metre XZ as Vector2(height_m, weight): weight 1 deep
## inside the window, fading to 0 over RING_FADE_PX at its edge, 0
## outside. Bilinear over pixel centres.
static func ring_sample(data: LocationData, ring: Dictionary, xm: float, zm: float) -> Vector2:
	var w: int = ring["width"]
	var h: int = ring["height"]
	var p := global_px(data, xm, zm, int(ring["zoom"])) \
		- (ring["origin_px"] as Vector2) - Vector2(0.5, 0.5)
	var edge := minf(minf(p.x, p.y), minf(float(w - 1) - p.x, float(h - 1) - p.y))
	if edge <= 0.0:
		return Vector2.ZERO
	var heights: PackedFloat32Array = ring["heights"]
	var x0 := mini(int(p.x), w - 2)
	var y0 := mini(int(p.y), h - 2)
	var tx := p.x - float(x0)
	var ty := p.y - float(y0)
	var i := y0 * w + x0
	var a := lerpf(heights[i], heights[i + 1], tx)
	var b := lerpf(heights[i + w], heights[i + w + 1], tx)
	return Vector2(lerpf(a, b, ty), clampf(edge / RING_FADE_PX, 0.0, 1.0))

## Ring-composited height (m ASL) at metre XZ over a fallback value:
## coarsest ring first, finer rings blended on top by their edge fades.
## outer_fade scales the coarsest ring's weight (the mesh uses it to
## hand the outermost loops back to the z8 far grid).
static func height_m(data: LocationData, xm: float, zm: float,
		fallback_m: float, outer_fade: float = 1.0) -> float:
	var h := fallback_m
	var n := data.dem_rings.size()
	for k in range(n - 1, -1, -1):
		var s := ring_sample(data, data.dem_rings[k], xm, zm)
		var w := s.y * (outer_fade if k == n - 1 else 1.0)
		if w > 0.0:
			h = lerpf(h, s.x, w)
	return h

## Drape UV (0..1 inside the window, outside = not covered).
static func drape_uv(data: LocationData, drape: Dictionary, xm: float, zm: float) -> Vector2:
	var p := global_px(data, xm, zm, int(drape["zoom"]))
	var size: Vector2i = drape["size_px"]
	return (p - (drape["origin_px"] as Vector2)) / Vector2(size)

## Latitude-only treeline / snowline (ClimateModel owns both; these
## delegators keep existing callers). Place colours use the CHELSA
## isotherms through ClimateModel when climate data exists.
static func treeline_m(lat: float) -> float:
	return ClimateModel.latitude_treeline_m(lat)

static func snowline_m(lat: float, season: int) -> float:
	return ClimateModel.latitude_snowline_m(lat, season)

## Mountain colour ramp for terrain with no imagery (returned LINEAR,
## from sRGB picks — the v1 ramp fed sRGB values as linear and washed
## to cream). Forest/meadow below the treeline, alpine grass then rock
## above it, rock on steep slopes everywhere, snow by altitude +
## latitude + season (not height above the viewpoint), water flat blue.
static func ramp_color(data: LocationData, nrm: Vector3, h_asl: float,
		water: bool, noise: float) -> Color:
	if water:
		return Color(0.149, 0.263, 0.247).srgb_to_linear()  # #26433F (T3.8)
	var tl := ClimateModel.treeline_m(data)
	var sl := ClimateModel.snowline_m(data, data.season)
	var forest := Color(0.17, 0.25, 0.13)
	var meadow := Color(0.33, 0.42, 0.20)
	# Climate (CHELSA): dry summers turn the meadows golden, arid ground
	# reads sparse; forests stay dark (evergreen oak, chaparral, pine).
	var dry := ClimateModel.grass_tint(data, data.season)
	if dry.a > 0.0:
		meadow = Color(dry.r, dry.g, dry.b).linear_to_srgb()
		forest = forest.lerp(meadow, 0.35 if ClimateModel.arid(data) else 0.15)
	var alpine := Color(0.42, 0.43, 0.32)
	var rock := Color(0.40, 0.38, 0.36)
	var snow := Color(0.90, 0.92, 0.95)
	var flat := clampf((nrm.y - 0.80) / 0.15, 0.0, 1.0)
	# Valley floors read as meadow, slopes as forest (mottled).
	var c := forest.lerp(meadow, clampf(flat * 0.8 + (noise - 0.5) * 0.5, 0.0, 1.0))
	c = c.lerp(alpine, smoothstep(tl - 150.0, tl + 150.0, h_asl))
	var steep := 1.0 - smoothstep(0.55, 0.80, nrm.y)
	var high := smoothstep(tl, tl + 500.0, h_asl)
	c = c.lerp(rock, clampf(maxf(steep, high * 0.85), 0.0, 1.0))
	# Snow settles on what is not too steep to hold it.
	var hold := smoothstep(0.45, 0.70, nrm.y)
	var snow_w := smoothstep(sl - 200.0, sl + 200.0, h_asl + (noise - 0.5) * 160.0) * hold
	c = c.lerp(snow, snow_w)
	var shade := 0.92 + noise * 0.16
	return Color(c.r * shade, c.g * shade, c.b * shade).srgb_to_linear()

const _SHADER_CODE := """
shader_type spatial;
render_mode cull_back;
uniform sampler2D fine_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D coarse_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float has_fine = 0.0;
uniform float has_coarse = 0.0;
uniform float albedo_cap = 0.85;
// Esri imagery is exposed dark (forest ~0.03 linear, baked shadows);
// real canopy albedo is ~0.08-0.15, so far imagery gets a gain, with
// the PRD 0.85 cap applied as a ceiling, not a multiplier.
uniform float imagery_gain = 1.6;  // FarSurface.IMAGERY_GAIN
// @SNOW
varying vec3 wpos;
varying float wny;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wny = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
}
float edge_w(vec2 uv) {
	vec2 d = min(uv, vec2(1.0) - uv);
	return smoothstep(0.0, 0.015, min(d.x, d.y));
}
void fragment() {
	vec3 c = COLOR.rgb;
	float wc = has_coarse * edge_w(UV2);
	if (wc > 0.0) { c = mix(c, texture(coarse_tex, UV2).rgb * imagery_gain, wc); }
	float wf = has_fine * edge_w(UV);
	if (wf > 0.0) { c = mix(c, texture(fine_tex, UV).rgb * imagery_gain, wf); }
	c = mix(c, snow_col, snow_cover(wpos, wny));
	ALBEDO = min(c, vec3(albedo_cap));
	ROUGHNESS = 0.96;
	SPECULAR = 0.2;
}
"""
static var _shader: Shader

## Ring material: imagery (UV = fine drape, UV2 = coarse drape) over
## the vertex-colour ramp, each drape faded out at its window edge.
## The 0.85 albedo ceiling matches the near drape cap (PRD §4.4).
static func drape_material(fine: Texture2D, coarse: Texture2D,
		double_sided: bool = false, data: LocationData = null) -> ShaderMaterial:
	var code := _SHADER_CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	if _shader == null:
		_shader = Shader.new()
		_shader.code = code
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	if double_sided:
		var sh := Shader.new()
		sh.code = code.replace("cull_back", "cull_disabled")
		mat.shader = sh
	if data != null:
		ClimateModel.apply_snow(mat, data)
	mat.set_shader_parameter("has_fine", 1.0 if fine != null else 0.0)
	mat.set_shader_parameter("has_coarse", 1.0 if coarse != null else 0.0)
	if fine != null:
		mat.set_shader_parameter("fine_tex", fine)
	if coarse != null:
		mat.set_shader_parameter("coarse_tex", coarse)
	return mat

## Linear albedo of the finest drape covering metre XZ, gained and
## capped exactly as the ring shader does; alpha 0 = no drape covers it.
## Reads the drape's CPU image (FarFieldFetcher keeps it as "image").
static func drape_albedo(data: LocationData, xm: float, zm: float) -> Color:
	for d in data.far_drapes:
		var img: Image = d.get("image", null)
		if img == null:
			continue
		var uv := drape_uv(data, d, xm, zm)
		if uv.x <= 0.0 or uv.y <= 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
			continue
		var c := img.get_pixel(int(uv.x * float(img.get_width())),
			int(uv.y * float(img.get_height()))).srgb_to_linear()
		return Color(minf(c.r * IMAGERY_GAIN, ALBEDO_CAP),
			minf(c.g * IMAGERY_GAIN, ALBEDO_CAP),
			minf(c.b * IMAGERY_GAIN, ALBEDO_CAP), 1.0)
	return Color(0, 0, 0, 0)

## Mesh with UV + UV2 + vertex colours under drape_material.
static func drape_mesh(verts: PackedVector3Array, normals: PackedVector3Array,
		colors: PackedColorArray, uvs: PackedVector2Array, uv2s: PackedVector2Array,
		indices: PackedInt32Array, fine: Texture2D, coarse: Texture2D,
		double_sided: bool = false, data: LocationData = null) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = drape_material(fine, coarse, double_sided, data)
	return mi
