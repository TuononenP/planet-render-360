class_name FacadeShader
extends RefCounted

## Desktop-Ultra facades (Phase 3 of the Ultra pass). The composed facade
## textures stay as they are; on Forward+ Ultra every facade material the
## build made (StandardMaterial3D, meta "facade_set") is swapped for a
## shader material reading the same textures and adding what a texture
## cannot hold:
##   - a room behind every pane (interior mapping: back wall, floor,
##     ceiling and side walls traced per bay and storey, with furniture,
##     curtains and blinds from a per-pane hash), dim by day;
##   - night windows decided per pane from that hash, the building's own
##     occupancy and the clock (CityLights.hour): flats fill in the
##     evening and thin out after 23:00, offices go dark after 20:00, so
##     lit panes no longer line up in the columns a one-storey tile makes;
##     each lit room has its own colour temperature, now and then a TV;
##   - glass that is glass: smooth enough (0.12–0.18; smoother renders the
##     indirect reflections as noise) for probes and SSR to mirror the
##     street, a fraction of a degree of tilt per pane so reflections
##     break up as float glass does; near panes reflect like double
##     glazing and trade the room for the mirror by Fresnel, so head-on
##     you look in and at a shallow angle you see the street (the shells
##     are hollow, so the see-through is the traced room, never alpha);
##   - world-space weathering: building-scale hue and grime noise and
##     faint rain streaks, so a 40 m wall does not repeat its tile;
##   - the wall photo's full grain: the composers shrink each 1K photo to
##     64–128 px a tile, so on tiled facades the shader multiplies the
##     composed wall by the full-size photo over its own mip at the
##     composer's scale (and adds the matching normal detail), giving back
##     millimetre detail up close while the composer's boards, grout and
##     streaks stay.
## The pane mask is the composers' glass class (roughness <= 0.2, see
## FacadeComposer.depth_from_rough). Lower tiers and Mobile keep the
## standard materials (enabled()).

## Full-size wall photo grain on tiled facades (see the class doc).
const PHOTO_DETAIL := true
## Room depth behind a pane, metres.
const ROOM_DEPTH_M := 4.5

const SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D paint_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_paint = false;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_normal = false;
uniform sampler2D depth_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool has_depth = false;
uniform float depth_scale = 0.0;
uniform float metallic_wall = 0.0;
uniform bool curtain_wall = false;
// Pane cells per UV unit (bays across, storeys down) and one cell's size
// in world units; room depth in world units.
uniform vec2 cells = vec2(4.0, 1.0);
uniform vec2 cell_size = vec2(3.2, 3.3);
uniform float room_depth = 4.5;
uniform float night_energy = 0.0;
uniform float city_hour = 20.0;
uniform float units_per_m = 1.0;
// The wall's own photo set at full size (tiled facades only): photo_reps
// copies per bay and storey, photo_lod the mip the composer's tile matches.
uniform sampler2D photo_diff : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D photo_nor : filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_photo = false;
uniform float photo_reps = 1.0;
uniform float photo_lod = 3.0;
uniform float photo_keep = 1.0;
uniform bool photo_turn = false;

varying vec3 wpos;
varying flat float bld;

// Near panes. Head-on reflectance of double glazing (four surfaces); the
// high metallic over a dark albedo gives it with almost no diffuse.
const float GLASS_F0 = 0.13;
const float GLASS_METALLIC = 0.8;
const float GLASS_ALBEDO = 0.14;
// Daytime room brightness behind a near pane (emission, so it ignores the
// shade the wall is in: brighter reads as a lit room, not as glass), and
// the glass's own tint.
const float DAY_ROOM_NEAR = 0.035;
const vec3 GLASS_TINT = vec3(0.90, 0.97, 0.94);

float h12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float h13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h12(i), h12(i + vec2(1.0, 0.0)), u.x),
		mix(h12(i + vec2(0.0, 1.0)), h12(i + vec2(1.0, 1.0)), u.x), u.y);
}
// Circular distance in hours.
float hdist(float a, float b) {
	return abs(mod(a - b + 12.0, 24.0) - 12.0);
}
// Share of a building's rooms lit at `h`: homes peak near 21:00 and thin
// out after 23:00 with a small breakfast bump; offices mostly empty after
// 20:00, but cleaners and lights left on keep a sixth of the floors lit.
float occupancy(float h, bool office) {
	if (office) {
		return 0.16 + 0.56 * (1.0 - smoothstep(18.5, 21.0, h)) * smoothstep(6.0, 8.0, h);
	}
	float d = hdist(h, 20.5);
	float m = hdist(h, 6.7);
	return 0.07 + 0.38 * exp(-d * d / 24.5) + 0.14 * exp(-m * m / 1.2);
}
vec3 room_palette(float k) {
	if (k < 0.30) return vec3(0.80, 0.76, 0.68);   // warm white
	if (k < 0.50) return vec3(0.72, 0.64, 0.52);   // beige
	if (k < 0.65) return vec3(0.62, 0.64, 0.66);   // grey
	if (k < 0.78) return vec3(0.58, 0.64, 0.70);   // pale blue
	if (k < 0.90) return vec3(0.62, 0.68, 0.56);   // sage
	return vec3(0.74, 0.56, 0.48);                 // terracotta
}
vec3 lamp_colour(float k, float t) {
	if (k > 0.96) {
		// A television: cool and flickering.
		float f = 0.75 + 0.25 * sin(t * 7.0 + k * 40.0) * sin(t * 3.1 + k * 17.0);
		return vec3(0.55, 0.68, 1.0) * f;
	}
	vec3 warm = vec3(1.0, 0.70, 0.40);    // 2700 K
	vec3 neutral = vec3(1.0, 0.82, 0.60); // 3500 K
	vec3 cool = vec3(0.96, 0.92, 0.84);   // 4500 K
	return k < 0.55 ? mix(warm, neutral, k / 0.55) : mix(neutral, cool, (k - 0.55) / 0.41);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// The per-building wall tint (vertex colour) and the wall's facing
	// tell buildings and their sides apart. Chromaticity only, coarsely
	// quantized and flat: the foot shade darkens a wall's lower vertices
	// and 8-bit vertex colours round them, and a seed that differs between
	// vertices interpolates into a new hash on every pixel.
	vec3 chroma = COLOR.rgb / max(COLOR.r + COLOR.g + COLOR.b, 1e-3);
	bld = floor(chroma.r * 24.0) * 3.0 + floor(chroma.b * 24.0) * 89.0 + floor(wn.x * 4.0 + 4.5) * 31.0
		+ floor(wn.z * 4.0 + 4.5) * 57.0;
}

void fragment() {
	// Tangent frame: the mesh's where it has one, else one built from the
	// wall normal and the world's up (batched impostor walls).
	vec3 up_v = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec3 T = TANGENT;
	vec3 Bv = -BINORMAL;
	bool framed = length(T) > 0.5 && abs(dot(T, NORMAL)) < 0.2;
	if (!framed) {
		T = normalize(cross(up_v, NORMAL));
		Bv = -up_v;
	}
	vec3 vts = normalize(vec3(dot(VIEW, T), dot(VIEW, Bv), dot(VIEW, NORMAL)));
	vec2 uv = UV;
	// Parallax shifts uv by a different amount on each pixel, so its own
	// derivatives are noise: every lookup uses the surface's (textureGrad),
	// or mip selection sparkles across the glass threshold.
	vec2 gx = dFdx(UV);
	vec2 gy = dFdy(UV);
	// Panes per pixel: a pane a few pixels wide shows its room's average
	// colour, not a sparkle of walls, floor and furniture.
	// Full room detail from ~80 px a pane, flat colour below ~30 px.
	float far_room = smoothstep(0.012, 0.033, max(length(gx * cells), length(gy * cells)));
	// Glass treatment from ~50 px a pane, none under ~17 px: distant panes
	// keep the plain look and cannot shimmer.
	float near_glass = 1.0 - smoothstep(0.02, 0.06, max(length(gx * cells), length(gy * cells)));
	// Window reveals: steep parallax over the depth map (white = wall face).
	if (has_depth && framed) {
		float layers = mix(32.0, 8.0, abs(vts.z));
		float step_d = 1.0 / layers;
		vec2 delta = vts.xy * depth_scale / layers;
		float cur = 0.0;
		float d = 1.0 - textureGrad(depth_tex, uv, gx, gy).r;
		for (int i = 0; i < 32; i++) {
			if (cur >= d) {
				break;
			}
			uv -= delta;
			d = 1.0 - textureGrad(depth_tex, uv, gx, gy).r;
			cur += step_d;
		}
		vec2 prev = uv + delta;
		float after = d - cur;
		float before = (1.0 - textureGrad(depth_tex, prev, gx, gy).r) - cur + step_d;
		uv = mix(uv, prev, after / (after - before));
	}
	vec3 base = textureGrad(albedo_tex, uv, gx, gy).rgb * tint.rgb;
	vec2 photo_n = vec2(0.0);
	if (has_photo) {
		vec2 puv = uv * cells * photo_reps;
		if (photo_turn) {
			puv = vec2(puv.y, -puv.x);
		}
		vec2 pgx = gx * cells * photo_reps;
		vec2 pgy = gy * cells * photo_reps;
		if (photo_turn) {
			pgx = vec2(pgx.y, -pgx.x);
			pgy = vec2(pgy.y, -pgy.x);
		}
		vec3 hi = textureGrad(photo_diff, puv, pgx, pgy).rgb;
		vec3 lo = textureLod(photo_diff, puv, photo_lod).rgb;
		base *= mix(vec3(1.0), clamp(hi / max(lo, vec3(0.02)), vec3(0.4), vec3(2.2)), photo_keep);
		photo_n = textureGrad(photo_nor, puv, pgx, pgy).rg - textureLod(photo_nor, puv, photo_lod).rg;
		if (photo_turn) {
			photo_n = vec2(photo_n.y, -photo_n.x);
		}
	}
	if (has_paint) {
		vec4 p = textureGrad(paint_tex, uv, gx, gy);
		base = mix(base, p.rgb, p.a);
	}
	float rough = has_normal ? textureGrad(rough_tex, uv, gx, gy).r : 0.9;
	float pane = has_normal ? smoothstep(0.32, 0.22, rough) : 0.0;
	// Weathering in world space (metres): building-scale hue and grime,
	// faint vertical rain streaks.
	vec3 wm = wpos / units_per_m;
	float g = vnoise(wm.xz * 0.045 + wm.y * 0.02);
	float streak = vnoise(vec2((wm.x + wm.z) * 0.9, wm.y * 0.06));
	vec3 wall = base * COLOR.rgb * mix(0.90, 1.06, g) * (1.0 - 0.07 * smoothstep(0.55, 0.95, streak));

	vec2 cg = uv * cells;
	vec2 cell = floor(cg);
	vec2 cuv = fract(cg);
	float seed = h13(vec3(cell, bld));
	float night = clamp(night_energy / 2.6, 0.0, 1.0);
	float occ = occupancy(city_hour, curtain_wall) * mix(0.5, 1.4, h12(vec2(bld, 7.0)));
	// Offices light a floor in stretches of five bays, homes room by room.
	vec2 lc = curtain_wall ? vec2(floor(cell.x / 5.0), cell.y) : cell;
	float lit = step(h13(vec3(lc + 0.37, bld + 11.0)), occ) * night;
	vec3 lamp = lamp_colour(h13(vec3(lc, bld + 3.7)), TIME);
	// Panes under ~2 px glow at the building's lit share in an average warm
	// white: picked one by one they alias to white speckle on the skyline.
	float sub = smoothstep(0.25, 0.7, max(length(gx * cells), length(gy * cells)));
	lit = mix(lit, occ * night, sub);
	lamp = mix(lamp, vec3(1.0, 0.80, 0.58), sub);

	// The room: trace the eye ray from the pane into a box one bay wide,
	// one storey tall and room_depth deep (x along u, y down, z into it).
	vec3 r = -vts;
	vec3 dr = vec3(r.x / cell_size.x, r.y / cell_size.y, r.z / room_depth);
	vec3 p0 = vec3(cuv, 0.0);
	float tx = ((dr.x > 0.0 ? 1.0 : 0.0) - p0.x) / (abs(dr.x) > 1e-5 ? dr.x : 1e-5);
	float ty = ((dr.y > 0.0 ? 1.0 : 0.0) - p0.y) / (abs(dr.y) > 1e-5 ? dr.y : 1e-5);
	float tz = -1.0 / min(dr.z, -1e-4);
	float t = min(min(tx, ty), tz);
	vec3 hit = p0 + dr * t;
	float back = -hit.z;
	vec3 wallc = room_palette(seed);
	vec3 room;
	float lamp_k;
	if (t == tz) {
		room = wallc;
		lamp_k = 0.55;
		// A sofa, desk or bed against the back wall; a picture above it.
		float fx = mix(0.25, 0.75, h12(vec2(seed, 2.0)));
		if (hit.y > 0.66 && abs(hit.x - fx) < 0.24 && h12(vec2(seed, 5.0)) > 0.3) {
			room = mix(vec3(0.20, 0.17, 0.15), vec3(0.42, 0.30, 0.22), h12(vec2(seed, 9.0)));
		} else if (hit.y > 0.30 && hit.y < 0.50 && abs(hit.x - fx) < 0.12 && h12(vec2(seed, 6.0)) > 0.5) {
			room = vec3(0.30, 0.34, 0.40) * (0.6 + 0.6 * h12(vec2(seed, 8.0)));
		}
	} else if (t == ty) {
		bool floor_hit = dr.y > 0.0;
		room = floor_hit ? mix(vec3(0.34, 0.24, 0.16), vec3(0.40, 0.40, 0.38), step(0.6, seed)) : vec3(0.86, 0.85, 0.82);
		lamp_k = floor_hit ? 0.45 : 0.95;
	} else {
		room = wallc * 0.92;
		lamp_k = 0.6;
	}
	// Curtains drawn in from the sides and a blind from the top, just
	// inside the glass.
	float open_half = mix(0.06, 0.45, h12(vec2(seed, 13.0)));
	float blind = h12(vec2(seed, 17.0)) > 0.6 ? mix(0.25, 0.65, h12(vec2(seed, 19.0))) : 0.0;
	vec3 fabric = mix(vec3(0.86, 0.82, 0.74), vec3(0.55, 0.50, 0.46), step(0.7, h12(vec2(seed, 23.0))));
	float drape = max(step(open_half, abs(cuv.x - 0.5)), step(cuv.y, blind));
	room = mix(room, wallc * 0.75, far_room);
	back = mix(back, 0.5, far_room);
	lamp_k = mix(lamp_k, 0.65, far_room);
	drape = mix(drape, clamp(1.0 - 2.0 * open_half + blind * 0.5, 0.0, 1.0) * 0.6, far_room);
	// From ~33 px a pane to ~8 px, curtains settle to the building's average:
	// a tenfold albedo range picked per window reads as a checkerboard.
	float pane_mean = smoothstep(0.03, 0.12, max(length(gx * cells), length(gy * cells))) * 0.85;
	drape = mix(drape, 0.3, pane_mean);
	fabric = mix(fabric, vec3(0.76, 0.71, 0.64), pane_mean);
	room = mix(room, vec3(0.525, 0.505, 0.46), pane_mean);
	float day_k = mix(0.07, DAY_ROOM_NEAR, curtain_wall ? 0.0 : near_glass);
	float day_room = day_k * mix(1.0, 0.35, back) * (1.0 - night);
	vec3 inside = room * mix(day_room, lamp_k * mix(1.0, 0.55, back) * lit, night);
	vec3 drape_e = fabric * mix(day_k * (1.0 - night), 0.55 * lit, night);
	inside = mix(inside, drape_e, drape);
	// Tinted curtain walls show less of the room by day; at night the lit
	// floors behind them read strongly.
	float transmit = curtain_wall ? mix(0.35, 0.8, night) : 0.85;
	vec3 glass_e = inside * transmit * mix(vec3(1.0), lamp * night_energy * 1.4, step(0.001, lit));
	// What the glass reflects it does not let through: the room gives way
	// to the mirror as the view gets shallow.
	float fresnel = GLASS_F0 + (1.0 - GLASS_F0) * pow(1.0 - clamp(vts.z, 0.0, 1.0), 5.0);
	glass_e *= mix(vec3(1.0), GLASS_TINT * (1.0 - fresnel), near_glass);

	// A curtain wall's floors differ a little: no two batches of glass match.
	vec3 glass_alb = curtain_wall ? base * 0.8 * (0.97 + 0.06 * h12(vec2(cell.y, bld)))
		: mix(mix(vec3(0.015), fabric * 0.18, drape), vec3(GLASS_ALBEDO), near_glass);
	ALBEDO = mix(wall, glass_alb, pane);
	// Below ~0.12 the indirect reflections render as salt-and-pepper noise.
	// Sub-pixel panes share one value: picked per pane they alias to speckle.
	ROUGHNESS = mix(rough, mix(0.12, 0.18, mix(h12(vec2(seed, 29.0)), 0.5, pane_mean)), pane);
	METALLIC = mix(metallic_wall, curtain_wall ? 0.6 : GLASS_METALLIC * near_glass, pane);
	SPECULAR = mix(0.5, 0.65, pane);
	EMISSION = glass_e * pane;
	vec3 nm = has_normal ? textureGrad(normal_tex, uv, gx, gy).rgb : vec3(0.5, 0.5, 1.0);
	// Godot rebuilds z from xy: keep the sum inside the unit disc (outside
	// it z is NaN and the pixel renders black).
	vec2 nxy = nm.xy * 2.0 - 1.0 + photo_n;
	nxy *= min(1.0, 0.92 / max(length(nxy), 1e-4));
	nm.xy = nxy * 0.5 + 0.5;
	// About 0.3 degrees of tilt per pane.
	vec2 tilt = (vec2(h12(vec2(seed, 31.0)), h12(vec2(seed, 37.0))) - 0.5) * 0.012 * (1.0 - pane_mean);
	NORMAL_MAP = mix(nm, vec3(0.5 + tilt, 1.0), pane);
}
"""

static var _shader: Shader
static var _photos := {}
static var _photo_mutex := Mutex.new()

static func shader() -> Shader:
	if _shader == null:
		var sh := Shader.new()
		sh.code = SHADER
		_shader = sh
	return _shader

## Full-size mipmapped texture of one bundled photo map (linear, as the
## composers read it), shared by every facade of the set.
static func photo_texture(set_name: String, map_name: String) -> Texture2D:
	var key := set_name + ":" + map_name + (":2k" if MaterialLibrary.hi_res else "")
	_photo_mutex.lock()
	var cached: Texture2D = _photos.get(key)
	_photo_mutex.unlock()
	if cached != null:
		return cached
	var img := (MaterialLibrary._set_image(set_name, map_name) as Image).duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_photo_mutex.lock()
	_photos[key] = tex
	_photo_mutex.unlock()
	return tex

## Ultra on Forward+ only: Mobile and lower tiers keep the standard facades.
static func enabled(preset: int, forward_plus: bool = RenderQuality.is_forward_plus()) -> bool:
	return RenderQuality.ultra_desktop(preset, forward_plus)

## Swaps every facade material under `root` for its shader counterpart
## (one per standard material, so shared materials stay shared). Returns
## the number of distinct materials swapped.
static func upgrade(root: Node) -> int:
	var done := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if mi.material_override is StandardMaterial3D and mi.material_override.has_meta("facade_set"):
			mi.material_override = _swap(mi.material_override as StandardMaterial3D, done)
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			if m is StandardMaterial3D and m.has_meta("facade_set"):
				mi.mesh.surface_set_material(s, _swap(m as StandardMaterial3D, done))
	return done.size()

static func _swap(m: StandardMaterial3D, done: Dictionary) -> ShaderMaterial:
	if done.has(m):
		return done[m] as ShaderMaterial
	var s := from_standard(m)
	done[m] = s
	return s

## The shader material for one facade material (same textures, tint,
## UV cells and lit-window marking).
static func from_standard(m: StandardMaterial3D) -> ShaderMaterial:
	var s := ShaderMaterial.new()
	s.shader = shader()
	var m2u := WorldScale.metres_to_units()
	s.set_shader_parameter("albedo_tex", m.albedo_texture)
	s.set_shader_parameter("tint", m.albedo_color)
	s.set_shader_parameter("has_paint", m.detail_enabled and m.detail_albedo != null)
	if m.detail_enabled and m.detail_albedo != null:
		s.set_shader_parameter("paint_tex", m.detail_albedo)
	var has_normal := m.normal_texture != null and m.roughness_texture != null
	s.set_shader_parameter("has_normal", has_normal)
	if has_normal:
		s.set_shader_parameter("normal_tex", m.normal_texture)
		s.set_shader_parameter("rough_tex", m.roughness_texture)
	var has_depth := m.heightmap_enabled and m.heightmap_texture != null
	s.set_shader_parameter("has_depth", has_depth)
	if has_depth:
		s.set_shader_parameter("depth_tex", m.heightmap_texture)
		s.set_shader_parameter("depth_scale", m.heightmap_scale * 0.01)
	var set_name := str(m.get_meta("facade_set"))
	s.set_shader_parameter("curtain_wall", set_name == "glass")
	s.set_shader_parameter("metallic_wall", 0.0 if set_name == "glass" else m.metallic)
	var uvp := FacadeTextures.facade_uv(m)
	var bay_m := uvp.x if uvp.x > 0.0 else 3.2
	var bays := uvp.y if uvp.y > 0.0 else float(FacadeComposer.BAYS)
	var rows := 1.0 if uvp.z > 0.0 else float(m.get_meta("facade_rows", 6))
	var floor_m := float(m.get_meta("facade_floor_m", 3.3))
	s.set_shader_parameter("cells", Vector2(bays, rows))
	s.set_shader_parameter("cell_size", Vector2(bay_m, floor_m) * m2u)
	s.set_shader_parameter("room_depth", ROOM_DEPTH_M * m2u)
	s.set_shader_parameter("units_per_m", m2u)
	s.set_shader_parameter("city_hour", CityLights.hour)
	if PHOTO_DETAIL and uvp.z > 0.0 and MaterialLibrary.PBR_SETS.has(set_name):
		var diff := photo_texture(set_name, "diff")
		var reps := float(FacadeComposer.PHOTO_REPS.get(set_name, 1))
		s.set_shader_parameter("has_photo", true)
		s.set_shader_parameter("photo_diff", diff)
		s.set_shader_parameter("photo_nor", photo_texture(set_name, "nor"))
		s.set_shader_parameter("photo_reps", reps)
		s.set_shader_parameter("photo_lod", maxf(log(float(diff.get_width()) * reps
			/ float(FacadeComposer.CELL)) / log(2.0), 0.0))
		s.set_shader_parameter("photo_keep", float(FacadeComposer.KEEP_CONTRAST.get(set_name, 1.0)))
		s.set_shader_parameter("photo_turn", set_name == "wood" and str(m.get_meta("facade_pattern", "")) == "clapboard")
	for k in m.get_meta_list():
		if k != "facade_set":
			s.set_meta(k, m.get_meta(k))
	s.set_meta("facade_shader", set_name)
	return s
