class_name GodrayShader
extends RefCounted

## Screen-space god-ray and additive overlay GLSL for HazeRig (Ultra on
## desktop Forward+). Kept as string constants (SkyShader / WaterShader
## pattern) so HazeRig stays about viewport lifecycle and sun projection.
##
## Two lightweight shaders, zero copy of the world viewport:
##  1. RAYS_CODE (half-res `SubViewport`): decodes the world RT from sRGB
##     to linear, marches TAPS jittered steps toward `sun_uv`, and gates
##     emission to bright sun-aureole sky texels so silhouetted roofs,
##     spires, bridges and tree crowns cast crisp dark shadow lanes.
##  2. OVERLAY_CODE (`TextureRect` with `blend_add` directly over the
##     world container and under the HUD): bilinearly upsamples the
##     half-res shaft buffer and adds it onto the untouched ACES world.

## Radial taps per half-res pixel (fixed from tools/haze_spike.gd on
## Apple M5 Ultra, Forward+, 1280x720: 48 taps at 0.5x scale < 0.02 ms).
const TAPS := 48
const FADE := 0.95
## Linear-luminance window separating bright sun-side sky from buildings,
## bridges, terrain and mid-tone sunlit stone.
const LUMA_FLOOR := 0.50
const LUMA_CEIL := 0.92
const OVERLAY_GAIN := 0.18

const RAYS_CODE := """
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled;

uniform sampler2D world : filter_linear, repeat_disable;
uniform float taps = 48.0;
uniform float fade = 0.95;
uniform vec2 sun_uv = vec2(0.5, 0.35);
uniform float aspect = 1.7778;
uniform float ray_amount = 0.0;
uniform vec3 sun_color = vec3(1.0, 0.85, 0.64);
uniform float luma_floor = 0.50;
uniform float luma_ceil = 0.92;

vec3 srgb_to_linear(vec3 s) {
	return mix(s / 12.92, pow((s + vec3(0.055)) / 1.055, vec3(2.4)), lessThanEqual(vec3(0.04045), s));
}

void fragment() {
	vec3 out_rays = vec3(0.0);
	if (ray_amount > 0.001 && taps > 0.5) {
		vec2 to_sun = sun_uv - UV;
		vec2 metric = vec2(to_sun.x * aspect, to_sun.y);
		float dist = length(metric);
		float cone = 1.0 - smoothstep(0.05, 0.92, dist);
		if (cone > 0.001 && dist > 1e-4) {
			vec3 base_s = srgb_to_linear(texture(world, UV).rgb);
			float base_luma = dot(base_s, vec3(0.2126, 0.7152, 0.0722));
			// Protect bright sky, sunward haze and roofs (`base_luma >= 0.56` -> 0),
			// while allowing warm shafts across dark foliage and shaded streets.
			float sky_protect = 1.0 - smoothstep(0.28, 0.56, base_luma);
			if (sky_protect > 0.005) {
				float reach = min(1.0, 0.38 / max(dist, 0.001));
				vec2 step_uv = (to_sun * reach) / max(taps, 1.0);
				float ign = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
				vec2 uv = UV + step_uv * ign;
				float w = 1.0;
				float w_sum = 0.0;
				float blocked = 0.0;
				vec3 acc = vec3(0.0);
				for (int i = 0; i < 64; i++) {
					if (float(i) >= taps) {
						break;
					}
					vec2 clamped = clamp(uv, vec2(0.001), vec2(0.999));
					float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
					vec3 s = srgb_to_linear(texture(world, clamped).rgb);
					float luma = dot(s, vec3(0.2126, 0.7152, 0.0722));
					float tap_dist = length(vec2((clamped.x - sun_uv.x) * aspect, clamped.y - sun_uv.y));
					float sun_source = exp(-tap_dist * 3.4);
					float emitter = smoothstep(luma_floor, luma_ceil, luma) * sun_source * in_bounds;
					blocked += (1.0 - smoothstep(0.18, 0.48, luma)) * w * in_bounds;
					acc += s * (emitter * w);
					w_sum += w;
					w *= fade;
					uv += step_uv;
				}
				float inv_w = 1.0 / max(w_sum, 1.0);
				vec3 streak = acc * inv_w;
				float occ_frac = blocked * inv_w;
				float shaft_gate = clamp(0.35 + occ_frac * 1.8, 0.0, 1.0) * sky_protect;
				float mag = dot(streak, vec3(0.2126, 0.7152, 0.0722));
				streak = mix(streak, sun_color * mag * 1.15, 0.65);
				streak = streak / (vec3(1.0) + streak * 1.2);
				float disc_guard = smoothstep(0.012, 0.055, dist);
				out_rays = streak * (cone * disc_guard * shaft_gate);
			}
		}
	}
	ALBEDO = out_rays;
}
"""

const OVERLAY_CODE := """
shader_type canvas_item;
render_mode blend_add;

uniform float ray_amount = 0.0;
uniform float gain = 0.18;

void fragment() {
	vec3 r = texture(TEXTURE, UV).rgb * (ray_amount * gain);
	COLOR = vec4(r, 1.0);
}
"""

static var _rays_shader: Shader
static var _overlay_shader: Shader

static func rays_material(world: Texture2D) -> ShaderMaterial:
	if _rays_shader == null:
		_rays_shader = Shader.new()
		_rays_shader.code = RAYS_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _rays_shader
	mat.set_shader_parameter("taps", float(TAPS))
	mat.set_shader_parameter("fade", FADE)
	mat.set_shader_parameter("luma_floor", LUMA_FLOOR)
	mat.set_shader_parameter("luma_ceil", LUMA_CEIL)
	mat.set_shader_parameter("ray_amount", 0.0)
	if world != null:
		mat.set_shader_parameter("world", world)
	return mat

static func overlay_material() -> ShaderMaterial:
	if _overlay_shader == null:
		_overlay_shader = Shader.new()
		_overlay_shader.code = OVERLAY_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _overlay_shader
	mat.set_shader_parameter("ray_amount", 0.0)
	mat.set_shader_parameter("gain", OVERLAY_GAIN)
	return mat

