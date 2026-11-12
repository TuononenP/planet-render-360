class_name TreeMeshLibrary
extends RefCounted

## Procedural species meshes for instanced trees (T5.1 / T7.2), built
## once per session in true metres (instances scale by
## WorldScale.metres_to_units()). Three LODs per species:
##   0 full  — tapered trunk with root flare, main + secondary branches
##             (bark PBR), 40-60 leaf-card clusters (3 crossed cards each)
##   1 mid   — trunk + main branches, ~40% clusters on bigger cards
##   2 far   — cross-card impostor (TreeImpostor paints its texture
##             from the LOD-0 geometry, so silhouettes match)
## Deciduous species in winter use the bare variant: full branching plus
## twig cards, no leaves. Leaf cards carry spherical crown normals (the
## crown shades as one volume, sunlit vs shaded side) and per-vertex
## AO; the leaf shader adds back-lit translucency, optional snow on
## up-facing foliage, and an F3-only ≤2° sway (PRD §5).
## Godot's front face is clockwise; tubes are wound accordingly.

const LEAF_SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform sampler2D leaf_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 tint : source_color = vec3(0.36, 0.5, 0.24);
uniform vec3 translucency : source_color = vec3(0.2, 0.26, 0.08);
uniform float alpha_cut = 0.5;
uniform float snow = 0.0;
uniform float sway = 0.0;
// Tree crowns only: thin out cards seen edge-on (hedges and other
// axis-aligned card props keep their full coverage).
uniform bool edge_fade = false;
// @SNOW
varying vec3 v_n;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (sway > 0.0) {
		vec3 wp = MODEL_MATRIX[3].xyz;
		float ph = wp.x * 0.37 + wp.z * 0.23;
		float k = max(VERTEX.y, 0.0) * sway;
		VERTEX.x += sin(TIME * 1.1 + ph) * k;
		VERTEX.z += cos(TIME * 0.9 + ph * 1.3) * k * 0.6;
	}
	v_n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec4 t = texture(leaf_tex, UV);
	vec3 c = t.rgb * tint * COLOR.rgb;
	// Shaded inner foliage (low AO in COLOR) turns slightly cooler.
	float ao = clamp(COLOR.g, 0.0, 1.0);
	c *= mix(vec3(0.86, 0.95, 1.1), vec3(1.0), smoothstep(0.3, 0.95, ao));
	vec3 n = normalize(v_n);
	if (snow > 0.0) {
		float up = (INV_VIEW_MATRIX * vec4(n, 0.0)).y;
		c = mix(c, vec3(0.86, 0.88, 0.92), smoothstep(0.0, 0.6, up) * snow * snow_line(wpos));
	}
	// Cards seen edge-on smear into streaks: thin them out by the real
	// face normal (the shading normal is bent to the crown sphere). Not
	// in the sun's shadow pass (the only orthographic projection): there
	// VIEW is the light's, and crowns must cast their full shadow.
	float edge = 1.0;
	if (edge_fade && PROJECTION_MATRIX[3][3] == 0.0) {
		vec3 face_n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		edge = smoothstep(0.22, 0.6, abs(dot(face_n, VIEW)));
	}
	ALBEDO = c;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = mix(0.95, alpha_cut, edge);
	ALPHA_ANTIALIASING_EDGE = 0.25;
	ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(leaf_tex, 0));
	NORMAL = n;
	ROUGHNESS = 0.82;
	SPECULAR = 0.22 * mix(0.4, 1.0, edge);
	BACKLIGHT = translucency * COLOR.rgb;
}
"""

const IMPOSTOR_SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform sampler2D imp_tex : filter_linear_mipmap, repeat_disable;
uniform vec3 tint : source_color = vec3(0.36, 0.5, 0.24);
uniform vec3 bark_tint : source_color = vec3(0.4, 0.35, 0.3);
// The baked image carries AO and crown-cavity shade but not the
// cast shadows the mesh crowns receive from their own outer foliage;
// this calibrates the remaining difference (set per crown type by
// impostor_material; see TreeImpostor.paint).
uniform float foliage_gain = 0.6;
uniform float snow = 0.0;
// @SNOW
varying vec3 v_n;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec4 t = texture(imp_tex, UV);
	// G packs foliage coverage (0 bark .. 0.55 foliage) and, above
	// that, the cluster warmth the mesh carries in its vertex colour.
	float fol = clamp(t.g / 0.55, 0.0, 1.0);
	float warm = (clamp((t.g - 0.55) / 0.45, 0.0, 1.0) * 2.0 - 1.0) * fol;
	vec3 leaf_c = tint * COLOR.rgb * foliage_gain * vec3(1.0 + 0.07 * warm, 1.0, 1.0 - 0.09 * warm);
	// Same cool shift on shaded foliage as the mesh leaf shader.
	leaf_c *= mix(vec3(0.86, 0.95, 1.1), vec3(1.0), smoothstep(0.3, 0.95, t.r));
	vec3 c = t.r * mix(bark_tint, leaf_c, fol);
	vec3 n = normalize(v_n);
	if (snow > 0.0) {
		c = mix(c, vec3(0.86, 0.88, 0.92), clamp(t.b * 1.6, 0.0, 1.0) * snow * snow_line(wpos));
	}
	// Two crossed vertical cards: whichever is near edge-on (in plan
	// view) smears into a pale streak, so it thins out while the other
	// faces the eye. Plan view only, so looking down keeps both cards;
	// never in the (orthographic) sun shadow pass.
	float edge = 1.0;
	if (PROJECTION_MATRIX[3][3] == 0.0) {
		vec3 fw = (INV_VIEW_MATRIX * vec4(cross(dFdx(VERTEX), dFdy(VERTEX)), 0.0)).xyz;
		vec3 vw = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;
		float lh = length(vw.xz);
		if (lh > 0.05 && length(fw.xz) > 1e-6) {
			edge = smoothstep(0.2, 0.5, abs(dot(normalize(fw.xz), vw.xz / lh)));
		}
	}
	ALBEDO = c;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = mix(0.97, 0.5, edge);
	ALPHA_ANTIALIASING_EDGE = 0.25;
	ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(imp_tex, 0));
	NORMAL = n;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2 * mix(0.4, 1.0, edge);
	BACKLIGHT = vec3(0.12, 0.15, 0.05) * fol;
}
"""

## Geometry buffer for one surface.
class Buf:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()
	func arrays() -> Array:
		var a: Array = []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = verts
		a[Mesh.ARRAY_NORMAL] = normals
		a[Mesh.ARRAY_TEX_UV] = uvs
		a[Mesh.ARRAY_COLOR] = colors
		a[Mesh.ARRAY_INDEX] = idx
		return a
	func tris() -> int:
		return idx.size() / 3

static var _bufs: Dictionary = {}
static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}
static var _shader_leaf: Shader
static var _shader_imp: Shader

static func species_names() -> Array:
	return TreeSpecies.names()

static func is_evergreen(sp: String) -> bool:
	return TreeSpecies.is_evergreen(sp)

## [bark Buf, foliage Buf] for a species/LOD/bare variant (cached).
static func bufs(sp: String, lod: int, bare: bool) -> Array:
	var key := "%s|%d|%s" % [sp, lod, bare]
	if _bufs.has(key):
		return _bufs[key]
	var s := TreeSpecies.spec(sp)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sp) & 0x7fffffff
	var out: Array
	match str(s["gen"]):
		"conifer":
			out = TreeGenerators._gen_conifer(s, lod, rng)
		"palm":
			out = TreeGenerators._gen_palm(s, lod, rng)
		_:
			out = TreeGenerators._gen_broad(s, lod, bare, rng)
	_bufs[key] = out
	return out

## Instanced mesh (bark + foliage surfaces, materials attached).
static func mesh(sp: String, lod: int, season: int, snow: float, sway: float = 0.0) -> ArrayMesh:
	var bare := season == LocationData.Season.WINTER and not is_evergreen(sp)
	if lod >= 2:
		return _impostor_mesh(sp, bare, season, snow)
	var key := "%s|%d|%s|%d|%.2f|%.3f" % [sp, lod, bare, season, snow, sway]
	if _meshes.has(key):
		return _meshes[key]
	var s := TreeSpecies.spec(sp)
	var b: Array = bufs(sp, lod, bare)
	var m := ArrayMesh.new()
	var bark: Buf = b[0]
	var leaf: Buf = b[1]
	if bark.idx.size() > 0:
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bark.arrays())
		m.surface_set_material(m.get_surface_count() - 1, bark_material(str(s["bark"])))
	if leaf.idx.size() > 0:
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, leaf.arrays())
		var lm: Material
		if bare:
			lm = leaf_material("twigs", Color(0.46, 0.40, 0.34), 0.0, sway, false, true)
		else:
			# Snow settles on conifer whorls; broad-crowned evergreens
			# (pines, olives) hold only a dusting.
			var sn := snow if str(s["gen"]) == "conifer" else snow * 0.35
			lm = leaf_material(str(s["leaf"]), TreeSpecies.tint(sp, season), sn, sway, true, true)
		m.surface_set_material(m.get_surface_count() - 1, lm)
	_meshes[key] = m
	return m

static func triangle_count(sp: String, lod: int, bare: bool = false) -> int:
	if lod >= 2:
		return 4
	var b: Array = bufs(sp, lod, bare)
	return (b[0] as Buf).tris() + (b[1] as Buf).tris()

## LOD-0 bounds in metres (impostor framing).
static func bounds(sp: String, bare: bool = false) -> AABB:
	var b: Array = bufs(sp, 0, bare)
	var box := AABB()
	var first := true
	for buf in b:
		for v in (buf as Buf).verts:
			if first:
				box = AABB(v, Vector3.ZERO)
				first = false
			else:
				box = box.expand(v)
	return box

# --- Materials -----------------------------------------------------------

static func bark_material(kind: String) -> StandardMaterial3D:
	var key := "bark|" + kind
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = FoliageTextures.bark_albedo(kind)
	m.normal_enabled = true
	m.normal_texture = FoliageTextures.bark_normal(kind)
	m.normal_scale = 1.2
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.92
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m

## `edge_fade` thins cards seen edge-on: tree crowns only (crossed
## cards at random angles), not axis-aligned props such as hedges.
static func leaf_material(kind: String, tint: Color, snow: float, sway: float,
		translucent: bool, edge_fade: bool = false) -> ShaderMaterial:
	var key := "leaf|%s|%s|%.2f|%.3f|%s|%s" % [kind, tint.to_html(), snow, sway, translucent, edge_fade]
	if _mats.has(key):
		return _mats[key]
	if _shader_leaf == null:
		_shader_leaf = Shader.new()
		_shader_leaf.code = LEAF_SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var m := ShaderMaterial.new()
	m.shader = _shader_leaf
	m.set_shader_parameter("leaf_tex", FoliageTextures.leaf(kind))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("snow", snow)
	m.set_shader_parameter("sway", sway)
	m.set_shader_parameter("edge_fade", edge_fade)
	m.set_shader_parameter("translucency",
		Color(tint.r * 0.45, tint.g * 0.5, tint.b * 0.2) if translucent else Color.BLACK)
	_mats[key] = m
	return m

static func impostor_material(sp: String, bare: bool, season: int, snow: float) -> ShaderMaterial:
	var key := "imp|%s|%s|%d|%.2f" % [sp, bare, season, snow]
	if _mats.has(key):
		return _mats[key]
	if _shader_imp == null:
		_shader_imp = Shader.new()
		_shader_imp.code = IMPOSTOR_SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var s := TreeSpecies.spec(sp)
	var m := ShaderMaterial.new()
	m.shader = _shader_imp
	m.set_shader_parameter("imp_tex", TreeImpostor.texture(sp, bare))
	m.set_shader_parameter("tint", TreeSpecies.tint(sp, season))
	m.set_shader_parameter("bark_tint", TreeSpecies.BARK_TINT.get(str(s["bark"]), Color(0.4, 0.35, 0.3)))
	# Calibrated against LOD-0 renders (mean crown colour, sun + sky):
	# conifer whorls self-shadow less than lobed broadleaf crowns.
	m.set_shader_parameter("foliage_gain", 0.7 if str(s["gen"]) == "conifer" else 0.6)
	m.set_shader_parameter("snow", snow)
	_mats[key] = m
	return m

## Number of distinct cached vegetation materials (T7.2 leak assert).
static func material_count() -> int:
	return _mats.size()

# --- Primitive helpers ---------------------------------------------------

## Tapered tube along a polyline; u wraps `reps` times, v runs 1 per
## 1.6 m of length. AO ramps ao0 → ao1 from first to last ring.
static func _tube(b: Buf, pts: Array, radii: Array, sides: int, ao0: float, ao1: float) -> void:
	var n := pts.size()
	if n < 2:
		return
	var base := b.verts.size()
	var reps := maxf(1.0, round(float(radii[0]) * TAU / 0.9))
	var prev_n := Vector3.ZERO
	var vacc := 0.0
	for i in n:
		var p: Vector3 = pts[i]
		var t: Vector3
		if i == 0:
			t = (pts[1] - pts[0]).normalized()
		elif i == n - 1:
			t = (pts[i] - pts[i - 1]).normalized()
		else:
			t = (pts[i + 1] - pts[i - 1]).normalized()
		var nrm: Vector3
		if i == 0:
			var ref := Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.BACK
			nrm = t.cross(ref).normalized()
		else:
			nrm = (prev_n - t * prev_n.dot(t)).normalized()
			vacc += (pts[i] - pts[i - 1]).length()
		prev_n = nrm
		var bin := t.cross(nrm)
		var ao := lerpf(ao0, ao1, float(i) / float(n - 1))
		for k in sides + 1:
			var a := TAU * float(k) / float(sides)
			var dir := nrm * cos(a) + bin * sin(a)
			b.verts.append(p + dir * float(radii[i]))
			b.normals.append(dir)
			b.uvs.append(Vector2(float(k) / float(sides) * reps, vacc / 1.6))
			b.colors.append(Color(ao, ao, ao))
	for i in n - 1:
		for k in sides:
			var a0 := base + i * (sides + 1) + k
			var a1 := a0 + sides + 1
			b.idx.append_array([a0, a0 + 1, a1, a0 + 1, a1 + 1, a1])

## One card (4 corners in order, UVs (0,0)(1,0)(1,1)(0,1) unless given).
## Vertex colour = AO x `tint` (keep tint.g at 1: shaders and the
## impostor read the green channel as AO).
static func _card(b: Buf, c: Array, nrm: Array, ao: Array, uv: Array = [],
		tint: Color = Color.WHITE) -> void:
	var base := b.verts.size()
	var uvd: Array = uv if not uv.is_empty() else \
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in 4:
		b.verts.append(c[i])
		b.normals.append(nrm[i])
		b.uvs.append(uvd[i])
		var a: float = ao[i]
		b.colors.append(Color(a * tint.r, a * tint.g, a * tint.b))
	b.idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

static func _bezier(a: Vector3, c: Vector3, e: Vector3, n: int) -> Array:
	var out: Array = []
	for i in n + 1:
		var t := float(i) / float(n)
		out.append(a.lerp(c, t).lerp(c.lerp(e, t), t))
	return out

static func _frame(n: Vector3) -> Array:
	var ref := Vector3.UP if absf(n.y) < 0.92 else Vector3.RIGHT
	var t1 := n.cross(ref).normalized()
	var t2 := n.cross(t1).normalized()
	return [t1, t2]

# --- Broadleaf (and pine-crowned) generator ------------------------------

static func _impostor_mesh(sp: String, bare: bool, season: int, snow: float) -> ArrayMesh:
	var key := "imp|%s|%s|%d|%.2f" % [sp, bare, season, snow]
	if _meshes.has(key):
		return _meshes[key]
	var box := bounds(sp, bare)
	var half := maxf(maxf(absf(box.position.x), absf(box.end.x)),
		maxf(absf(box.position.z), absf(box.end.z)))
	var y0 := box.position.y
	var y1 := box.end.y
	var cc := Vector3(0, lerpf(y0, y1, 0.62), 0)
	var b := Buf.new()
	for k in 2:
		var d := Vector3(1, 0, 0).rotated(Vector3.UP, float(k) * PI * 0.5)
		var c := [Vector3(0, y1, 0) - d * half, Vector3(0, y1, 0) + d * half,
			Vector3(0, y0, 0) + d * half, Vector3(0, y0, 0) - d * half]
		var nrm: Array = []
		for p in c:
			nrm.append((((p as Vector3) - cc).normalized() + Vector3(0, 0.35, 0)).normalized())
		var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		if k == 1:
			uv = [Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)]
		_card(b, c, nrm, [1.0, 1.0, 1.0, 1.0], uv)
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, b.arrays())
	m.surface_set_material(0, impostor_material(sp, bare, season, snow))
	_meshes[key] = m
	return m
