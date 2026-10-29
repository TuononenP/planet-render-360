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
varying vec3 v_n;
void vertex() {
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
	vec3 n = normalize(v_n);
	if (snow > 0.0) {
		float up = (INV_VIEW_MATRIX * vec4(n, 0.0)).y;
		c = mix(c, vec3(0.86, 0.88, 0.92), smoothstep(0.25, 0.75, up) * snow);
	}
	ALBEDO = c;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	NORMAL = n;
	ROUGHNESS = 0.82;
	SPECULAR = 0.22;
	BACKLIGHT = translucency * COLOR.rgb;
}
"""

const IMPOSTOR_SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform sampler2D imp_tex : filter_linear_mipmap, repeat_disable;
uniform vec3 tint : source_color = vec3(0.36, 0.5, 0.24);
uniform vec3 bark_tint : source_color = vec3(0.4, 0.35, 0.3);
uniform float snow = 0.0;
varying vec3 v_n;
void vertex() {
	v_n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec4 t = texture(imp_tex, UV);
	vec3 c = t.r * mix(bark_tint, tint * COLOR.rgb, t.g);
	vec3 n = normalize(v_n);
	if (snow > 0.0) {
		c = mix(c, vec3(0.86, 0.88, 0.92), t.b * snow);
	}
	ALBEDO = c;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	NORMAL = n;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	BACKLIGHT = vec3(0.12, 0.15, 0.05) * t.g;
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
			out = _gen_conifer(s, lod, rng)
		"palm":
			out = _gen_palm(s, lod, rng)
		_:
			out = _gen_broad(s, lod, bare, rng)
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
			lm = leaf_material("twigs", Color(0.46, 0.40, 0.34), 0.0, sway, false)
		else:
			# Snow settles on conifer whorls; broad-crowned evergreens
			# (pines, olives) hold only a dusting.
			var sn := snow if str(s["gen"]) == "conifer" else snow * 0.35
			lm = leaf_material(str(s["leaf"]), TreeSpecies.tint(sp, season), sn, sway, true)
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

static func leaf_material(kind: String, tint: Color, snow: float, sway: float,
		translucent: bool) -> ShaderMaterial:
	var key := "leaf|%s|%s|%.2f|%.3f|%s" % [kind, tint.to_html(), snow, sway, translucent]
	if _mats.has(key):
		return _mats[key]
	if _shader_leaf == null:
		_shader_leaf = Shader.new()
		_shader_leaf.code = LEAF_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader_leaf
	m.set_shader_parameter("leaf_tex", FoliageTextures.leaf(kind))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("snow", snow)
	m.set_shader_parameter("sway", sway)
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
		_shader_imp.code = IMPOSTOR_SHADER
	var s := TreeSpecies.spec(sp)
	var m := ShaderMaterial.new()
	m.shader = _shader_imp
	m.set_shader_parameter("imp_tex", TreeImpostor.texture(sp, bare))
	m.set_shader_parameter("tint", TreeSpecies.tint(sp, season))
	m.set_shader_parameter("bark_tint", TreeSpecies.BARK_TINT.get(str(s["bark"]), Color(0.4, 0.35, 0.3)))
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
static func _card(b: Buf, c: Array, nrm: Array, ao: Array, uv: Array = []) -> void:
	var base := b.verts.size()
	var uvd: Array = uv if not uv.is_empty() else \
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in 4:
		b.verts.append(c[i])
		b.normals.append(nrm[i])
		b.uvs.append(uvd[i])
		var a: float = ao[i]
		b.colors.append(Color(a, a, a))
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

static func _gen_broad(s: Dictionary, lod: int, bare: bool, rng: RandomNumberGenerator) -> Array:
	var bark := Buf.new()
	var leaf := Buf.new()
	var h: float = s["h"]
	var base_y := float(s["bole"]) * h
	var crown_h := h - base_y
	var cc := Vector3(0, base_y + crown_h * 0.5, 0)
	var rx := float(s["crown_r"]) * h
	var ry := crown_h * 0.5
	var tr: float = s["trunk_r"]
	var sides := 9 if lod == 0 else 6
	var leader: float = s["leader"]
	var top_y := base_y + crown_h * maxf(leader, 0.12)
	# Trunk with a gentle sway and root flare below/at grade.
	var trunk: Array = []
	var radii: Array = []
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * h * 0.012
	var segs := 7 if lod == 0 else 4
	for i in segs + 1:
		var t := float(i) / float(segs)
		var y := lerpf(-0.4, top_y, t)
		trunk.append(Vector3(0, y, 0) + lean * t * t + Vector3(sin(t * 5.0), 0, cos(t * 4.0)) * h * 0.006 * t)
		var r := lerpf(tr, tr * (0.32 if leader > 0.5 else 0.6), t)
		if y < 0.6:
			r *= 1.0 + 0.45 * (1.0 - clampf((y + 0.4) / 1.0, 0.0, 1.0))
		radii.append(r)
	_tube(bark, trunk, radii, sides, 0.62, 1.0)
	# Main scaffold branches (golden-angle spiral).
	var nb: int = s["branches"]
	var tips: Array = []
	var mains: Array = []
	var attach_hi := top_y - crown_h * 0.05 if leader < 0.5 else base_y + crown_h * minf(leader, 0.85) * 0.9
	for i in nb:
		var f := (float(i) + rng.randf_range(0.0, 0.6)) / float(nb)
		var ay := lerpf(base_y * 0.97, attach_hi, f)
		var tf := clampf((ay + 0.4) / (top_y + 0.4), 0.0, 1.0)
		var start := Vector3(0, ay, 0) + lean * tf * tf
		var az := float(i) * 2.39996 + rng.randf_range(-0.35, 0.35)
		var dh := Vector3(cos(az), 0, sin(az))
		var ey := clampf(lerpf(ay + ry * 0.2, cc.y + ry * 0.85, float(s["up"])) + rng.randf_range(-0.12, 0.12) * ry,
			cc.y - ry * 0.55, cc.y + ry * 0.9)
		var q := (ey - cc.y) / ry
		var hr := rx * sqrt(maxf(0.06, 1.0 - q * q)) * rng.randf_range(0.72, 0.92)
		var end := Vector3(dh.x * hr, ey - float(s["droop"]) * ry * 0.35, dh.z * hr)
		var ctrl := start.lerp(end, 0.45) + Vector3(0, (end.y - start.y) * 0.35 + ry * 0.12, 0) \
			- dh * hr * 0.12
		var path := _bezier(start, ctrl, end, 4 if lod == 0 else 2)
		var r0 := tr * (0.55 if leader < 0.5 else 0.38) * (1.0 - 0.4 * f)
		var br: Array = []
		for k in path.size():
			br.append(lerpf(r0, 0.035, float(k) / float(path.size() - 1)))
		_tube(bark, path, br, 6 if lod == 0 else 4, 0.7, 1.0)
		mains.append(path)
		tips.append(end)
		# Secondaries (always on bare winter trees: the structure shows).
		if lod == 0 or bare:
			var kids := rng.randi_range(2, 3) + (1 if bare else 0)
			for k in kids:
				var u := rng.randf_range(0.35, 0.8)
				var sp0: Vector3 = _bezier(start, ctrl, end, 8)[int(u * 8.0)]
				var d := (end - start).normalized().rotated(Vector3.UP, rng.randf_range(-0.9, 0.9) * (1.0 if k % 2 == 0 else -1.0))
				d = (d + Vector3(0, rng.randf_range(0.1, 0.6), 0)).normalized()
				var ln := (end - start).length() * rng.randf_range(0.35, 0.5)
				var se := _clamp_ellipsoid(sp0 + d * ln, cc, rx, ry)
				var smid := sp0.lerp(se, 0.5) + Vector3(0, ln * 0.08 - float(s["droop"]) * ln * 0.2, 0)
				_tube(bark, _bezier(sp0, smid, se, 2), [r0 * 0.45, r0 * 0.3, 0.02], 4 if lod == 0 else 3, 0.75, 1.0)
				tips.append(se)
	# Foliage clusters (or winter twig cards).
	var count := int(float(s["clusters"]) * (1.0 if lod == 0 else 0.4))
	var card := float(s["card"]) * (1.0 if lod == 0 else 1.5)
	if bare:
		count = int(float(s["clusters"]) * (0.55 if lod == 0 else 0.3))
		card *= 0.85
	var anchors: Array = tips.duplicate()
	for path in mains:
		anchors.append(path[path.size() / 2])
	var tries := 0
	while anchors.size() < count and tries < count * 6:
		tries += 1
		var dir := Vector3(rng.randfn(), rng.randfn() * 0.8, rng.randfn()).normalized()
		var r := rng.randf_range(0.5, 0.97)
		var p := cc + Vector3(dir.x * rx * r, dir.y * ry * r, dir.z * rx * r)
		if p.y < base_y + 0.3:
			continue
		if s.get("flat_top", false) and dir.y < -0.2:
			continue
		anchors.append(p)
	anchors = anchors.slice(0, count)
	var quads := 3 if lod == 0 else 2
	for p in anchors:
		var sz: float = card * rng.randf_range(0.8, 1.2)
		var rel: Vector3 = (p - cc)
		var nn := Vector3(rel.x / maxf(rx, 0.1), rel.y / maxf(ry, 0.1), rel.z / maxf(rx, 0.1))
		var radial := clampf(nn.length(), 0.0, 1.0)
		var out_n := (nn.normalized() + Vector3(0, 0.25, 0)).normalized()
		var jitter := Vector3(rng.randfn(), rng.randfn(), rng.randfn()) * 0.35
		var cn := (out_n + jitter).normalized()
		var fr := _frame(cn)
		var t1: Vector3 = fr[0]
		var t2: Vector3 = fr[1]
		var ang := rng.randf_range(0.0, TAU)
		var a1 := t1 * cos(ang) + t2 * sin(ang)
		var a2 := cn.cross(a1).normalized()
		var planes: Array = [[a1, a2], [a1, cn], [a2, cn]]
		for qi in quads:
			var u_ax: Vector3 = planes[qi][0]
			var v_ax: Vector3 = planes[qi][1]
			var hs := sz * 0.5
			# Card "up" (texture top, v=0) points out of the crown.
			var corners := [p - u_ax * hs + v_ax * hs, p + u_ax * hs + v_ax * hs,
				p + u_ax * hs - v_ax * hs, p - u_ax * hs - v_ax * hs]
			var nrm: Array = []
			var ao: Array = []
			for c in corners:
				var cr: Vector3 = (c as Vector3) - cc
				var sn := Vector3(cr.x / maxf(rx, 0.1), cr.y / maxf(ry, 0.1), cr.z / maxf(rx, 0.1))
				nrm.append((sn.normalized() * 0.8 + cn * 0.2 + Vector3(0, 0.15, 0)).normalized())
				var hgt := clampf(((c as Vector3).y - base_y) / maxf(crown_h, 0.1), 0.0, 1.0)
				ao.append(clampf(lerpf(0.6, 1.0, radial) * lerpf(0.85, 1.05, hgt), 0.45, 1.0))
			_card(leaf, corners, nrm, ao)
	return [bark, leaf]

static func _clamp_ellipsoid(p: Vector3, cc: Vector3, rx: float, ry: float) -> Vector3:
	var r := p - cc
	var q := Vector3(r.x / rx, r.y / ry, r.z / rx)
	var l := q.length()
	if l <= 0.95:
		return p
	return cc + r * (0.95 / l)

# --- Conifer generator ----------------------------------------------------

static func _gen_conifer(s: Dictionary, lod: int, rng: RandomNumberGenerator) -> Array:
	var bark := Buf.new()
	var leaf := Buf.new()
	var h: float = s["h"]
	var tr: float = s["trunk_r"]
	var cb := float(s["crown_base"]) * h
	var r0 := float(s["base_r"]) * h
	var column: bool = s.get("column", false)
	var trunk: Array = []
	var radii: Array = []
	for i in 7:
		var t := float(i) / 6.0
		trunk.append(Vector3(0, lerpf(-0.4, h, t), 0))
		radii.append(lerpf(tr, 0.03, t) * (1.35 if i == 0 else 1.0))
	_tube(bark, trunk, radii, 8 if lod == 0 else 5, 0.55, 1.0)
	var whorl := float(s["whorl"]) * (1.0 if lod == 0 else 1.9)
	var per := int(s["per_whorl"]) - (0 if lod == 0 else 2)
	var pitch: float = s["pitch"]
	var droop: float = s["droop"]
	var y := cb
	var off := 0.0
	while y < h - 0.7:
		var t := (y - cb) / maxf(h - cb, 0.1)
		var env: float
		if column:
			env = r0 * pow(sin(PI * clampf(t * 0.9 + 0.12, 0.0, 1.0)), 0.55)
		else:
			env = r0 * pow(1.0 - t, 0.95) + 0.25
		var n := maxi(3, per - (1 if t > 0.6 else 0))
		off += 0.7
		for k in n:
			var az := off + TAU * float(k) / float(n) + rng.randf_range(-0.25, 0.25)
			var d := Vector3(cos(az), 0, sin(az))
			var ln := env * rng.randf_range(0.85, 1.12) * (1.0 if lod == 0 else 1.12)
			var start := Vector3(0, y, 0)
			var rise := tan(clampf(pitch, -1.2, 1.2))
			var mid := start + d * ln * 0.5 + Vector3(0, rise * ln * 0.5, 0)
			var tip := start + d * ln + Vector3(0, rise * ln - droop * ln * 0.35, 0)
			# Plumes roll alternately about the branch so the crown has
			# volume from every side (a flat whorl vanishes edge-on).
			var roll := (0.5 if k % 2 == 0 else -0.5) + rng.randf_range(-0.15, 0.15)
			var side := d.cross(Vector3.UP).normalized().rotated(d, roll)
			var w := ln * (1.1 if not column else 1.5) * (1.0 if lod == 0 else 1.2)
			var aos := [0.45, 0.78, 1.0]
			if t < 0.2:
				aos = [0.38, 0.62, 0.85]
			var pts := [start, mid, tip]
			# Horizontal plume, two segments (droops along its length).
			for sgi in 2:
				var a: Vector3 = pts[sgi]
				var b: Vector3 = pts[sgi + 1]
				var wa := w * (0.35 if sgi == 0 else 0.5)
				var wb := w * (0.5 if sgi == 0 else 0.3)
				var ua := float(sgi) * 0.5
				var ub := ua + 0.5
				var na := (d + Vector3(0, 0.55, 0)).normalized()
				_card(leaf, [a + side * wa, b + side * wb, b - side * wb, a - side * wa],
					[na, na, na, na], [aos[sgi], aos[sgi + 1], aos[sgi + 1], aos[sgi]],
					[Vector2(ua, 0), Vector2(ub, 0), Vector2(ub, 1), Vector2(ua, 1)])
			if lod == 0:
				# Vertical fin through the branch: volume from the side.
				var up := d.cross(side).normalized() * w * 0.42
				var nb := (d + Vector3(0, 0.35, 0)).normalized()
				_card(leaf, [start + up, tip + up * 0.6, tip - up * 0.6, start - up],
					[nb, nb, nb, nb], [aos[0], aos[2], aos[2], aos[0]],
					[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		y += whorl * rng.randf_range(0.85, 1.15)
	# Leader: crossed vertical plumes at the tip.
	for k in 2:
		var d := Vector3(1, 0, 0).rotated(Vector3.UP, float(k) * PI * 0.5)
		var a := Vector3(0, h - 1.5, 0)
		var b := Vector3(0, h + 0.2, 0)
		var nn := (d + Vector3(0, 0.6, 0)).normalized()
		_card(leaf, [a + d * 0.45, b + d * 0.12, b - d * 0.12, a - d * 0.45], [nn, nn, nn, nn],
			[0.9, 1.0, 1.0, 0.9], [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	return [bark, leaf]

# --- Palm generator -------------------------------------------------------

static func _gen_palm(s: Dictionary, lod: int, rng: RandomNumberGenerator) -> Array:
	var bark := Buf.new()
	var leaf := Buf.new()
	var h: float = s["h"]
	var tr: float = s["trunk_r"]
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * h * 0.08
	var top := Vector3(0, h, 0) + lean
	var trunk := _bezier(Vector3(0, -0.4, 0), Vector3(0, h * 0.55, 0) + lean * 0.15, top, 8 if lod == 0 else 4)
	var radii: Array = []
	for i in trunk.size():
		var t := float(i) / float(trunk.size() - 1)
		radii.append(tr * lerpf(1.45, 0.82, pow(t, 0.4)))
	_tube(bark, trunk, radii, 9 if lod == 0 else 6, 0.7, 0.9)
	var fronds := int(s["fronds"]) - (0 if lod == 0 else 5)
	var segs := 6 if lod == 0 else 3
	var flen: float = s["frond_len"]
	for f in fronds + (4 if lod == 0 else 0):
		var dead := f >= fronds
		var az := float(f) * 2.39996 + rng.randf_range(-0.2, 0.2)
		var el := rng.randf_range(-0.35, 0.85) if not dead else -1.25
		var ln := flen * rng.randf_range(0.85, 1.1) * (0.7 if dead else 1.0)
		var dh := Vector3(cos(az), 0, sin(az))
		var pts: Array = []
		for k in segs + 1:
			var u := float(k) / float(segs)
			var p := top + dh * cos(el) * ln * u + Vector3(0, sin(el) * ln * u - 0.5 * ln * u * u, 0)
			pts.append(p)
		var col := 1.0 if not dead else 0.62
		var w := 2.3
		for k in segs:
			var a: Vector3 = pts[k]
			var b: Vector3 = pts[k + 1]
			var tng := (b - a).normalized()
			var side := tng.cross(Vector3.UP).normalized()
			var droop_v := Vector3(0, -w * 0.22, 0)
			var ua := float(k) / float(segs)
			var ub := float(k + 1) / float(segs)
			var nup := (Vector3.UP * 0.8 + tng * 0.1).normalized()
			for sd in [-1.0, 1.0]:
				var sv: Vector3 = side * float(sd) * w * 0.5 + droop_v
				var v_edge: float = 0.0 if sd < 0.0 else 1.0
				_card(leaf, [a, b, b + sv, a + sv], [nup, nup, nup, nup],
					[col * 0.8, col * 0.8, col, col],
					[Vector2(ua, 0.5), Vector2(ub, 0.5), Vector2(ub, v_edge), Vector2(ua, v_edge)])
	return [bark, leaf]

# --- Impostor ------------------------------------------------------------

## Two crossed vertical cards spanning the LOD-0 bounds, crown-spherical
## normals so the far crown keeps its sunlit/shaded sides.
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
