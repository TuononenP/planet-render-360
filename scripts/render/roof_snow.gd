class_name RoofSnow
extends RefCounted

## Snow lying on roofs. Roof materials are standard PBR materials (no
## shader of their own to read the climate globals), so while climate
## snow is on, every building mesh carrying a roof-tagged material (meta
## "roof", set where roof materials are made) gets a shared overlay pass
## (material_overlay): up-facing planes above the snow line turn white,
## walls and steep mansard faces shed it. The pass is detached again when
## snow is off, so summer pays nothing. It sits on the instance, not the
## shared material (next_pass): a world is packed for WorldCache before
## this runs and saved on a thread meanwhile, and changing a shared
## material's resources under that save broke it ("not pre cached").

const SHADER := """
shader_type spatial;
// Wrap lighting: a snow-only pass, so a soft terminator on gables stands
// in for the light snow scatters under its surface.
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert_wrap;
// @SNOW
// Where this world's origin lies on the streamer's continuous map (m,
// WorldStreamer): the snow's grain and drifts hold through a swap.
global uniform vec2 world_origin_m;
global uniform vec3 cloud_sun_dir;
varying vec3 wpos;
varying float wny;
varying vec3 wnrm;
void vertex() {
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wny = wnrm.y;
	// Depth-scaled pillowing: flatter roofs hold thicker cushions (up to ~22 cm),
	// steep mansards/gables stay tight so snow never detaches from ridges.
	float d = clamp(climate_snow_depth, 0.0, 1.0);
	float flat_k = smoothstep(0.45, 0.90, wny);
	VERTEX += NORMAL * (0.02 + (0.04 + 0.16 * d) * flat_k);
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float px = max(fwidth(wpos.x), fwidth(wpos.z));
	float d = clamp(climate_snow_depth, 0.0, 1.0);
	vec2 hp = wpos.xz + world_origin_m;
	// Wind-sculpted cover aligned with WaterShader.WIND (0.86, 0.51).
	vec2 wind_p = vec2(dot(hp, vec2(0.86, 0.51)), dot(hp, vec2(-0.51, 0.86)));
	float drift_n = mix(snow_noise(wind_p / vec2(4.5, 2.1)) * 0.65 + snow_noise(hp / 0.85) * 0.35, 0.5, smoothstep(0.4, 2.5, px));
	// Steeper roofs shed light dustings; deep snowpack grips steeper pitches.
	float pitch_lo = mix(0.52, 0.28, d);
	float pitch_hi = mix(0.82, 0.56, d);
	float slope_hold = smoothstep(pitch_lo, pitch_hi, wny);
	// Sun-facing slopes and warm-roof spots thin first during light cover or thaw.
	vec3 n_w = normalize(wnrm);
	float sun_melt = smoothstep(0.25, 0.75, dot(n_w, cloud_sun_dir)) * smoothstep(0.10, 0.35, cloud_sun_dir.y);
	float warm_spot = snow_noise(hp / 3.4 + 4.7);
	float melt_cut = (0.18 * sun_melt + 0.22 * climate_snow_thaw) * (1.0 - 0.5 * d);
	float cover_k = smoothstep(0.03 + melt_cut, 0.35 + melt_cut * 0.5, d * (0.65 + 0.70 * drift_n) - warm_spot * 0.14 * (1.0 - d * 0.6));
	float a = snow_line(wpos) * slope_hold * cover_k * mix(0.86, 1.0, smoothstep(0.15, 0.4, drift_n));
	// Where it thins, the edge is a rounded lip (derivatives first).
	vec3 lip = snow_edge(a, wpos, mix(0.04, 0.14, d));
	if (a < 0.01) {
		discard;
	}
	float age = climate_snow_thaw * 0.55;
	ALBEDO = snow_albedo(hp, px, age) * (0.95 + 0.08 * drift_n);
	ALPHA = a * mix(0.92, 0.98, d);
	float near_px = 1.0 - smoothstep(0.4, 2.5, px);
	vec2 dr = near_px > 0.0 ? snow_drift(hp) * near_px * mix(0.6, 1.2, d) : vec2(0.0);
	// Drift bends the roof's own normal, so a gable keeps its lit side.
	vec3 nw = normalize(n_w - vec3(dr.x + lip.x * near_px, 0.0, dr.y + lip.y * near_px) * 0.22);
	float glint = 0.0;
	if (climate_snow_thaw < 0.4 && near_px > 0.1) {
		vec4 facet = snow_facet(hp, px);
		glint = facet.w * (1.0 - climate_snow_thaw * 2.5) * a;
		nw = normalize(mix(nw, facet.xyz, glint));
	}
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	ROUGHNESS = mix(mix(SNOW_ROUGH, 0.42, climate_snow_thaw), 0.04, glint);
	SPECULAR = mix(mix(SNOW_SPEC, 0.55, climate_snow_thaw), 1.0, glint);
	RIM = SNOW_RIM * (1.0 - 0.5 * climate_snow_thaw);
	RIM_TINT = SNOW_RIM_TINT;
}
"""

## Wet-roof sheen overlay when raining and not snow-covered: darkens and
## glosses up-facing roof planes via material_overlay without touching
## shared roof materials (WorldCache-safe).
const WET_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_schlick_ggx;
// @SNOW
global uniform vec2 world_origin_m;
varying vec3 wpos;
varying float wny;
void vertex() {
	vec3 wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wny = wn.y;
	VERTEX += NORMAL * 0.015;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float up = smoothstep(0.22, 0.55, wny);
	float wet = climate_wetness * (1.0 - snow_line(wpos)) * up;
	if (wet < 0.01) {
		discard;
	}
	vec2 hp = wpos.xz + world_origin_m;
	float patch_n = snow_noise(hp / 4.2) * 0.65 + snow_noise(hp / 1.3) * 0.35;
	float film = wet * mix(0.65, 1.0, patch_n);
	ALBEDO = vec3(0.025, 0.028, 0.032);
	ALPHA = film * 0.32;
	ROUGHNESS = mix(0.28, 0.11, film);
	SPECULAR = 0.72;
	METALLIC = 0.0;
}
"""

static var _overlay: ShaderMaterial
static var _wet_overlay: ShaderMaterial

static func overlay() -> ShaderMaterial:
	if _overlay == null:
		var sh := Shader.new()
		sh.code = SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
		_overlay = ShaderMaterial.new()
		_overlay.shader = sh
	return _overlay

static func wet_overlay() -> ShaderMaterial:
	if _wet_overlay == null:
		var sh := Shader.new()
		sh.code = WET_SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
		_wet_overlay = ShaderMaterial.new()
		_wet_overlay.shader = sh
	return _wet_overlay

## Attaches (on) or detaches (off) the snow or wet overlay on every
## building and roof-tagged landmark mesh of `world`. Snow wins when both
## are active; `wet` attaches the wet-sheen overlay when snow is off.
static func apply(world: Node, on: bool, wet: bool = false) -> int:
	var touched := 0
	var mat: Material = overlay() if on else (wet_overlay() if wet else null)
	for c in world.get_children():
		if c is MeshInstance3D:
			var layer := str(c.get_meta("lod_layer", ""))
			if layer != "Buildings" and layer != "FarCity":
				continue
			if _apply_mi(c as MeshInstance3D, mat):
				touched += 1
		elif c.name == "Landmarks" or str(c.get_meta("lod_layer", "")) == "Landmarks":
			touched += _apply_landmarks(c, mat)
	return touched

static func _apply_landmarks(root: Node, mat: Material) -> int:
	var touched := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and _apply_mi(n as MeshInstance3D, mat, true):
			touched += 1
	return touched

static func _apply_mi(mi: MeshInstance3D, mat: Material, skip_shader := false) -> bool:
	var mats: Array = [mi.material_override]
	var sc := mi.mesh.get_surface_count() if mi.mesh != null else 0
	for s in sc:
		var over := mi.get_surface_override_material(s)
		if skip_shader and over is ShaderMaterial:
			return false
		mats.append(over if over != null else mi.mesh.surface_get_material(s))
	if mats.any(func(m: Variant) -> bool: return m is Material and (m as Material).has_meta("roof")):
		mi.material_overlay = mat
		return true
	return false
