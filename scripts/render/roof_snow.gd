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
render_mode blend_mix, depth_draw_never, cull_back;
// @SNOW
varying vec3 wpos;
varying float wny;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wny = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
	// A few centimetres proud of the roof so the pass never z-fights.
	VERTEX += NORMAL * 0.03;
}
void fragment() {
	float a = snow_line(wpos) * smoothstep(0.30, 0.60, wny);
	if (a < 0.01) {
		discard;
	}
	ALBEDO = snow_col;
	ALPHA = a * 0.95;
	ROUGHNESS = 0.8;
	SPECULAR = 0.3;
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
