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
varying vec3 wpos;
varying float wny;
varying vec3 wnrm;
void vertex() {
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wny = wnrm.y;
	// A few centimetres proud of the roof so the pass never z-fights,
	// and lying snow a hand deep on the flatter planes it settles on.
	VERTEX += NORMAL * (0.03 + 0.08 * smoothstep(0.45, 0.85, wny));
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float px = max(fwidth(wpos.x), fwidth(wpos.z));
	float n = mix(snow_noise(wpos.xz / 2.3) * 0.7 + snow_noise(wpos.xz / 0.7) * 0.3, 0.5, smoothstep(0.4, 2.5, px));
	// Roofs are never one clean sheet: it thins where the roof's own
	// warmth and the wind get at it, without opening holes.
	float a = snow_line(wpos) * smoothstep(0.30, 0.60, wny) * mix(0.86, 1.0, smoothstep(0.15, 0.4, n));
	// Where it thins, the edge is a rounded lip (derivatives first).
	vec3 lip = snow_edge(a, wpos, 0.08);
	if (a < 0.01) {
		discard;
	}
	ALBEDO = snow_albedo(wpos.xz, px, 0.0) * (0.95 + 0.08 * n);
	ALPHA = a * 0.97;
	float near_px = 1.0 - smoothstep(0.4, 2.5, px);
	vec2 dr = near_px > 0.0 ? snow_drift(wpos.xz) * near_px : vec2(0.0);
	// Drift bends the roof's own normal, so a gable keeps its lit side.
	vec3 nw = normalize(normalize(wnrm) - vec3(dr.x + lip.x * near_px, 0.0, dr.y + lip.y * near_px) * 0.2);
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	ROUGHNESS = SNOW_ROUGH;
	SPECULAR = SNOW_SPEC;
	RIM = SNOW_RIM;
	RIM_TINT = SNOW_RIM_TINT;
}
"""

static var _overlay: ShaderMaterial

static func overlay() -> ShaderMaterial:
	if _overlay == null:
		var sh := Shader.new()
		sh.code = SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
		_overlay = ShaderMaterial.new()
		_overlay.shader = sh
	return _overlay

## Attaches (on) or detaches (off) the overlay on every building mesh
## of `world` that carries a roof material. Returns the meshes touched.
static func apply(world: Node, on: bool) -> int:
	var touched := 0
	for c in world.get_children():
		if not (c is MeshInstance3D):
			continue
		var layer := str(c.get_meta("lod_layer", ""))
		if layer != "Buildings" and layer != "FarCity":
			continue
		var mi := c as MeshInstance3D
		var mats: Array = [mi.material_override]
		for s in (mi.mesh.get_surface_count() if mi.mesh != null else 0):
			mats.append(mi.mesh.surface_get_material(s))
		if mats.any(func(m: Variant) -> bool: return m is Material and (m as Material).has_meta("roof")):
			mi.material_overlay = overlay() if on else null
			touched += 1
	return touched
