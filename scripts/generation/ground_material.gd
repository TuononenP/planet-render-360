class_name GroundMaterial
extends RefCounted

## Near-ground look v2 (T3.6): the detailed terrain's ShaderMaterial.
##
## Why: the satellite mosaic is an aerial photograph — rooftops,
## building shadows, cars and treetops. Draped flat beneath the 3D
## buildings and seen at grazing angles it reads as dark teal noise,
## and it has no near-field detail. Here the photo is demoted:
##
## - A land-cover CLASS MAP (R8 ids, baked at build time over the
##   detailed extent) is rasterised from the same OSM land polygons
##   GroundTruth.land_class_at reads (first polygon wins, holes
##   honoured), then roads and building footprints on top.
## - Each class picks tiled PBR detail (pavement / grass / rock /
##   asphalt; world-space UVs at two scales against visible tiling),
##   a class base colour, and how much of the LOW-FREQUENCY photo
##   (a ~5 m mip) tints it. Inside footprints and on road ribbons the
##   photo is never the albedo; urban open ground is pavement; parks
##   are grass tinted by the photo; unmapped ground decides
##   vegetated-vs-bare from the photo's own greenness.
## - The full-resolution photo returns only with view distance (where
##   its 0.6–2.4 m/px is adequate), capped per class.
## - Value: the photo is lifted by one achromatic gain measured on the
##   extent (mean luminance → GAIN_TARGET), every albedo is floored at
##   LUM_FLOOR and capped at the PRD §4.4 0.85 — never bleached, never
##   near-black. Achromatic and metre-based, so quality presets (which
##   stitch different zooms) keep hue and geometry (PRD §3.4 AC-12).
## - Seam: the last band of the extent fades to the far terrain's own
##   albedo (FarTerrainBuilder.far_albedo_at — far drape, else ramp —
##   carried in COLOR.rgb by TerrainBuilder), so the
##   near/far hand-off matches where FarTerrainBuilder's mid ring
##   overlaps the detailed edge.
##
## Heights stay GroundTruth's; this class only colours.

const CLASS_TEXELS := 1024
const TILE_M := 3.0
## Metres at which the full photo starts / finishes taking over.
const NEAR_M := 140.0
const FAR_M := 900.0
## Low-frequency photo blur target in metres (mip picked per zoom).
const LF_M := 5.0
const GAIN_TARGET := 0.20
const LUM_FLOOR := 0.055

## Class ids in the map (0 = unmapped ground, photo decides).
const ID := {
	"": 0, "building": 1, "road": 2, "urban": 3, "grass": 4,
	"forest": 5, "field": 6, "orchard": 7, "cemetery": 8, "pitch": 9,
	"wetland": 10, "sand": 11, "rock": 12, "quarry": 13, "glacier": 14,
	"water": 15, "path": 16,
}

## Footpath-like road classes paint pavement / dirt, not asphalt.
const PAVED_PATHS := ["footway", "pedestrian", "steps", "cycleway",
	"living_street", "corridor", "platform"]
const DIRT_PATHS := ["path", "track", "bridleway"]

## Procedural paving weight per class (palette row 2 A): open urban
## ground is laid paving; paved paths a little; everything else none.
const PAVED := {"urban": 1.0, "building": 1.0, "path": 0.3}

static var _detail_texs: Dictionary = {}

## The shared ground material for one built place. `photo` is the
## satellite mosaic (vertex UV = TerrainBuilder.satellite_uv) or, with
## no imagery, the procedural colour image TerrainBuilder bakes over
## the extent (vertex UV = extent UV). `photo_rect` is the photo-UV
## box of the detailed extent (gain statistics only).
static func build(data: LocationData, photo: Texture2D, photo_rect: Rect2,
		has_sat: bool) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	var m2u := WorldScale.metres_to_units()
	m.set_shader_parameter("photo", photo)
	m.set_shader_parameter("class_map", ImageTexture.create_from_image(class_map(data)))
	m.set_shader_parameter("palette", ImageTexture.create_from_image(palette(data.season)))
	m.set_shader_parameter("class_n", float(CLASS_TEXELS))
	m.set_shader_parameter("extent_u", WorldScale.detailed_extent_units())
	m.set_shader_parameter("u2m", 1.0 / m2u)
	m.set_shader_parameter("tile_m", TILE_M)
	m.set_shader_parameter("near_m", NEAR_M)
	m.set_shader_parameter("far_m", FAR_M)
	m.set_shader_parameter("lum_floor", LUM_FLOOR)
	m.set_shader_parameter("photo_gain", photo_gain(photo, photo_rect) if has_sat else 1.0)
	m.set_shader_parameter("lf_lod", lf_lod(data) if has_sat else 0.0)
	# Unmapped non-green ground: settled places read as pavement,
	# wild high-relief places as bare earth/rock (v1 settled rule).
	var settled := not data.buildings.is_empty() or data.relief_metres < 120.0
	m.set_shader_parameter("urban_unknown", 1.0 if settled else 0.15)
	# Unmapped ground takes a class-like base (pavement or earth, or
	# grass where the photo is green) and only a share of the photo's
	# colour — a full 5 m photo there is the blurry smear v1 showed.
	var bare := Color(0.54, 0.51, 0.45) if settled else Color(0.55, 0.50, 0.40)
	m.set_shader_parameter("unknown_bare", bare)
	m.set_shader_parameter("unknown_veg", Color(0.35, 0.48, 0.24))
	m.set_shader_parameter("unknown_trust", 0.2 if settled else 0.5)
	var sets := ["pavement", "grass", "rock", "asphalt"]
	for i in sets.size():
		var s: String = sets[i]
		m.set_shader_parameter("d%d" % i, _detail_tex(s, "diff"))
		m.set_shader_parameter("n%d" % i, _detail_tex(s, "nor"))
		var mean: Color = MaterialLibrary.PBR_SETS[s]["mean"]
		m.set_shader_parameter("m%d" % i, Vector3(mean.r, mean.g, mean.b))
	return m

## Mip level whose texel is ~LF_M metres: the same ground blur at
## every satellite zoom (tier invariance).
static func lf_lod(data: LocationData) -> float:
	var mpp := data.satellite_metres_per_px
	if mpp <= 0.0:
		var zoom := int(data.satellite_source.get("source_zoom", data.satellite_zoom))
		mpp = 156543.03 * cos(deg_to_rad(data.latitude)) / pow(2.0, float(zoom))
	return clampf(log(LF_M / maxf(mpp, 0.01)) / log(2.0), 0.0, 8.0)

## One achromatic gain taking the photo's mean linear luminance over
## the detailed extent to GAIN_TARGET (clamped 1.0–1.9: lift only).
static func photo_gain(photo: Texture2D, rect: Rect2) -> float:
	if photo == null:
		return 1.0
	var img := photo.get_image()
	if img == null or img.is_empty():
		return 1.0
	if img.is_compressed():
		return 1.0
	var w := img.get_width()
	var h := img.get_height()
	var sum := 0.0
	var n := 0
	for j in 32:
		for i in 32:
			var u := rect.position.x + rect.size.x * (float(i) + 0.5) / 32.0
			var v := rect.position.y + rect.size.y * (float(j) + 0.5) / 32.0
			var c := img.get_pixel(clampi(int(u * w), 0, w - 1),
				clampi(int(v * h), 0, h - 1)).srgb_to_linear()
			sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
	var mean := sum / float(maxi(n, 1))
	return clampf(GAIN_TARGET / maxf(mean, 0.01), 1.0, 1.9)

## Per-class lookup, 32 x 3 RGBA8 (nearest):
## row 0 detail weights (pavement, grass, rock, asphalt);
## row 1 base colour (sRGB) + photo tint trust in A;
## row 2 R = full-photo cap with distance, G = roughness, B = how
## much of the photo's own fine luminance structure (markings, paving,
## mown stripes, ±45% at most) modulates the near ground, A = how much
## procedural paving (PAVING in the shader, T4.7) the class carries.
static func palette(season: int = LocationData.Season.SUMMER) -> Image:
	var img := Image.create(32, 3, false, Image.FORMAT_RGBA8)
	# Unused ids must never read as colour: v1 filled (1,0,0,0), which
	# row 1 decodes as pure red albedo (the Big Sur all-red ground).
	img.fill(Color(0, 0, 0, 0))
	var grass := Color(0.35, 0.48, 0.24)  # PRD grass #5A7A3C
	if season == LocationData.Season.AUTUMN:
		grass = Color(0.55, 0.52, 0.30)
	elif season == LocationData.Season.WINTER:
		grass = Color(0.60, 0.62, 0.55)
	elif season == LocationData.Season.SPRING:
		grass = Color(0.48, 0.62, 0.36)
	var pave := MaterialLibrary.ground_color("urban")
	var rows := {
		"building": [Color(1, 0, 0, 0), pave, 0.0, 0.0, 0.95, 0.0],
		"road": [Color(0, 0, 0, 1), Color(0.40, 0.39, 0.37), 0.0, 0.25, 0.95, 0.45],
		"urban": [Color(1, 0, 0, 0), Color(0.54, 0.51, 0.45), 0.12, 0.45, 0.95, 0.55],
		"grass": [Color(0, 1, 0, 0), grass, 0.5, 1.0, 0.97, 0.55],
		"forest": [Color(0, 0.55, 0.45, 0), MaterialLibrary.ground_color("forest"), 0.45, 1.0, 0.97, 0.6],
		"field": [Color(0, 0.6, 0.4, 0), MaterialLibrary.ground_color("field"), 0.6, 1.0, 0.97, 0.6],
		"orchard": [Color(0, 1, 0, 0), MaterialLibrary.ground_color("orchard"), 0.5, 1.0, 0.97, 0.55],
		"cemetery": [Color(0.3, 0.7, 0, 0), MaterialLibrary.ground_color("cemetery"), 0.4, 0.8, 0.97, 0.5],
		"pitch": [Color(0, 1, 0, 0), MaterialLibrary.ground_color("pitch"), 0.3, 0.8, 0.97, 0.4],
		"wetland": [Color(0, 0.8, 0.2, 0), MaterialLibrary.ground_color("wetland"), 0.5, 1.0, 0.9, 0.55],
		"sand": [Color(0.7, 0, 0.3, 0), MaterialLibrary.ground_color("sand"), 0.4, 1.0, 0.97, 0.45],
		"rock": [Color(0, 0, 1, 0), MaterialLibrary.ground_color("rock"), 0.5, 1.0, 0.97, 0.6],
		"quarry": [Color(0, 0, 1, 0), MaterialLibrary.ground_color("quarry"), 0.5, 1.0, 0.97, 0.55],
		"glacier": [Color(1, 0, 0, 0), MaterialLibrary.ground_color("glacier"), 0.4, 1.0, 0.6, 0.4],
		"water": [Color(0, 0.2, 0.8, 0), MaterialLibrary.ground_color("wetland"), 0.3, 1.0, 0.9, 0.4],
		"path": [Color(0.2, 0.2, 0.6, 0), Color(0.58, 0.52, 0.42), 0.15, 0.6, 0.97, 0.5],
	}
	for cls in rows:
		var r: Array = rows[cls]
		var x: int = ID[cls]
		img.set_pixel(x, 0, r[0])
		var c: Color = r[1]
		img.set_pixel(x, 1, Color(c.r, c.g, c.b, float(r[2])))
		img.set_pixel(x, 2, Color(float(r[3]), float(r[4]), float(r[5]),
			float(PAVED.get(cls, 0.0))))
	return img

## Land-cover id map over the detailed extent (texel centres at
## (i + 0.5) * E / N - E / 2). Polygons paint last-to-first so the
## FIRST containing polygon wins (land_class_at order) with holes left
## to what lies beneath (even-odd over outer + hole rings); roads then
## footprints paint on top. Scanline spans → Image.fill_rect.
static func class_map(data: LocationData, n: int = CLASS_TEXELS) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_R8)
	img.fill(Color(0, 0, 0))
	var polys: Array = data.land_polygons
	for k in range(polys.size() - 1, -1, -1):
		var poly = polys[k]
		if not (poly is Dictionary):
			continue
		var cls := str((poly as Dictionary).get("class", ""))
		if not ID.has(cls):
			continue
		var rings: Array = [(poly as Dictionary).get("points", PackedVector2Array())]
		for hole in (poly as Dictionary).get("holes", []):
			if hole is PackedVector2Array:
				rings.append(hole)
		_fill_rings(img, rings, int(ID[cls]), n)
	var m2u := WorldScale.metres_to_units()
	for line in data.roads:
		var pts := PackedVector2Array()
		var width := 1.7
		var id: int = ID["road"]
		if line is Dictionary:
			var road: Dictionary = line
			if bool(road.get("tunnel", false)) or bool(road.get("bridge", false)):
				continue
			pts = road.get("points", PackedVector2Array())
			width = maxf(float(road.get("width_m", 0.0)) * m2u, 0.4)
			var rc := str(road.get("class", ""))
			if rc in PAVED_PATHS:
				id = ID["urban"]
			elif rc in DIRT_PATHS:
				id = ID["path"]
		elif line is PackedVector2Array:
			pts = line
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var d := b - a
			if d.length() < 0.001:
				continue
			var dir := d.normalized()
			var nrm := Vector2(-dir.y, dir.x) * width * 0.5
			var cap := dir * width * 0.5
			_fill_rings(img, [PackedVector2Array([a - cap + nrm, b + cap + nrm,
				b + cap - nrm, a - cap - nrm])], id, n)
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var fp: Variant = (b as Dictionary).get("footprint", null)
		if fp is PackedVector2Array and (fp as PackedVector2Array).size() >= 3:
			_fill_rings(img, [fp], ID["building"], n)
		else:
			var bx := float(b.get("x", 0.0))
			var bz := float(b.get("z", 0.0))
			var hx := float(b.get("size_x", 0.0)) * 0.5
			var hz := float(b.get("size_z", 0.0)) * 0.5
			if hx > 0.0 and hz > 0.0:
				_fill_rings(img, [PackedVector2Array([Vector2(bx - hx, bz - hz),
					Vector2(bx + hx, bz - hz), Vector2(bx + hx, bz + hz),
					Vector2(bx - hx, bz + hz)])], ID["building"], n)
	return img

## Even-odd scanline fill of the rings (outer + holes) with `id`.
static func _fill_rings(img: Image, rings: Array, id: int, n: int) -> void:
	var e := WorldScale.detailed_extent_units()
	var half := e * 0.5
	var ts := e / float(n)
	var zmin := INF
	var zmax := -INF
	for r in rings:
		for p in (r as PackedVector2Array):
			zmin = minf(zmin, p.y)
			zmax = maxf(zmax, p.y)
	if zmin == INF:
		return
	var j0 := maxi(int(ceil((zmin + half) / ts - 0.5)), 0)
	var j1 := mini(int(floor((zmax + half) / ts - 0.5)), n - 1)
	var col := Color(float(id) / 255.0, 0, 0)
	var xs: Array[float] = []
	for j in range(j0, j1 + 1):
		var wz := (float(j) + 0.5) * ts - half
		xs.clear()
		for r in rings:
			var ring: PackedVector2Array = r
			var cnt := ring.size()
			for q in cnt:
				var a := ring[q]
				var b := ring[(q + 1) % cnt]
				if (a.y <= wz and b.y > wz) or (b.y <= wz and a.y > wz):
					xs.append(a.x + (wz - a.y) / (b.y - a.y) * (b.x - a.x))
		if xs.size() < 2:
			continue
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var i0 := maxi(int(ceil((xs[k] + half) / ts - 0.5)), 0)
			var i1 := mini(int(floor((xs[k + 1] + half) / ts - 0.5)), n - 1)
			if i1 >= i0:
				img.fill_rect(Rect2i(i0, j, i1 - i0 + 1, 1), col)
			k += 2

## Mipmapped copy of a bundled PBR map (MaterialLibrary's runtime
## textures carry no mipmaps; tiled ground without them shimmers).
static func _detail_tex(set_name: String, map_name: String) -> Texture2D:
	var key := set_name + ":" + map_name
	if _detail_texs.has(key):
		return _detail_texs[key] as Texture2D
	var img := (MaterialLibrary._set_image(set_name, map_name) as Image).duplicate() as Image
	if not img.has_mipmaps():
		img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_detail_texs[key] = t
	return t

const SHADER := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D photo : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D class_map : filter_nearest, repeat_disable;
uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D d0 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D d1 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D d2 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D d3 : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n0 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n1 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n2 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n3 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 m0 = vec3(0.2);
uniform vec3 m1 = vec3(0.2);
uniform vec3 m2 = vec3(0.2);
uniform vec3 m3 = vec3(0.2);
uniform float class_n = 1024.0;
uniform int max_id = 16;
uniform float extent_u = 220.0;
uniform float u2m = 1.0;
uniform float tile_m = 3.0;
uniform float near_m = 140.0;
uniform float far_m = 900.0;
uniform float photo_gain = 1.0;
uniform float lf_lod = 0.0;
uniform float lum_floor = 0.055;
uniform float urban_unknown = 1.0;
uniform float unknown_trust = 0.3;
uniform vec3 unknown_bare : source_color = vec3(0.54, 0.51, 0.45);
uniform vec3 unknown_veg : source_color = vec3(0.35, 0.48, 0.24);

varying vec3 wpos;
varying float wny;

void vertex() {
	wpos = VERTEX;
	wny = NORMAL.y;
	TANGENT = normalize(vec3(1.0, 0.0, 0.0) - NORMAL * NORMAL.x);
	BINORMAL = normalize(cross(TANGENT, NORMAL));
}

float lum(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Luminance into [lum_floor, 0.85] without changing chromaticity.
vec3 value_clamp(vec3 c) {
	float l = max(lum(c), 1e-4);
	float t = clamp(l, lum_floor, 0.85);
	return min(c * (t / l), vec3(1.0));
}

vec3 srgb_lin(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

vec3 tile(sampler2D t, vec2 a, vec2 b) {
	return 0.5 * (texture(t, a).rgb + texture(t, b).rgb);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

// PAVING (T4.7): achromatic value gain for laid urban ground at metre
// coords g. ±8% patches over 6–25 m (wear, cleaning, repairs) plus
// 2 x 1.4 m running-bond flagstones with ±4% per-slab value and 3 cm
// darker joints; the slab layer fades with its screen footprint so it
// never aliases. Multiplies value only, so hue is preset-stable.
float paving(vec2 g) {
	float big = (vnoise(g / 23.0) - 0.5) * 0.11 + (vnoise(g / 6.5 + 17.0) - 0.5) * 0.06;
	vec2 slab = vec2(2.0, 1.4);
	vec2 su = g / slab;
	su.x += 0.5 * mod(floor(su.y), 2.0);
	vec2 fw = fwidth(g) / slab;
	float vis = 1.0 - smoothstep(0.08, 0.35, max(fw.x, fw.y));
	float jit = (hash2(floor(su) + 3.1) - 0.5) * 0.08;
	vec2 e = min(fract(su), 1.0 - fract(su)) * slab;
	vec2 fm = max(fwidth(g), vec2(1e-4));
	vec2 jl = smoothstep(vec2(0.015), vec2(0.015) + fm, e);
	float joint = -0.10 * (1.0 - min(jl.x, jl.y));
	return 1.0 + big + vis * (jit + joint);
}

void fragment() {
	float dist_m = length(VERTEX) * u2m;
	vec3 lf = textureLod(photo, UV, lf_lod).rgb * photo_gain;
	vec3 hf = texture(photo, UV).rgb * photo_gain;
	float exg = (2.0 * lf.g - lf.r - lf.b) / max(lf.r + lf.g + lf.b, 1e-3);
	float veg = smoothstep(0.03, 0.12, exg);
	// Manual bilinear over class ids (ids never filter).
	vec2 cuv = (wpos.xz / extent_u + 0.5) * class_n - 0.5;
	vec2 f = fract(cuv);
	ivec2 c0 = ivec2(floor(cuv));
	ivec2 cmax = ivec2(int(class_n) - 1);
	vec4 W = vec4(0.0);
	vec3 col = vec3(0.0);
	float trust = 0.0;
	float farc = 0.0;
	float rough = 0.0;
	float hfk = 0.0;
	float pave = 0.0;
	for (int k = 0; k < 4; k++) {
		ivec2 o = ivec2(k & 1, k >> 1);
		float bw = (o.x == 1 ? f.x : 1.0 - f.x) * (o.y == 1 ? f.y : 1.0 - f.y);
		int id = int(texelFetch(class_map, clamp(c0 + o, ivec2(0), cmax), 0).r * 255.0 + 0.5);
		// Ids past the palette (an unbound/white class map reads 255)
		// fall back to unmapped ground; texelFetch past the 32-texel
		// palette is undefined (Metal returned the red fill).
		if (id == 0 || id > max_id) {
			W += bw * vec4((1.0 - veg) * urban_unknown, veg,
				(1.0 - veg) * (1.0 - urban_unknown), 0.0);
			col += bw * mix(unknown_bare, unknown_veg, veg);
			trust += bw * unknown_trust;
			farc += bw;
			rough += bw * 0.96;
			hfk += bw * 0.35;
			pave += bw * (1.0 - veg) * urban_unknown * 0.7;
		} else {
			W += bw * texelFetch(palette, ivec2(id, 0), 0);
			vec4 p1 = texelFetch(palette, ivec2(id, 1), 0);
			vec4 p2 = texelFetch(palette, ivec2(id, 2), 0);
			col += bw * srgb_lin(p1.rgb);
			trust += bw * p1.a;
			farc += bw * p2.r;
			rough += bw * p2.g;
			hfk += bw * p2.b;
			pave += bw * p2.a;
		}
	}
	// Steep ground is bare rock/earth whatever the cover says.
	float steep = smoothstep(0.82, 0.62, wny);
	W = mix(W, vec4(0.0, 0.0, 1.0, 0.0), steep * 0.8);
	W /= max(W.x + W.y + W.z + W.w, 1e-3);
	// Macro variation (~40 m patches) from the photo's own value, so
	// wide pavement and lawns are never a flat slab.
	float big = lum(textureLod(photo, UV, lf_lod + 3.0).rgb * photo_gain);
	float macro = clamp(lum(lf) / max(big, 1e-3), 0.72, 1.3);
	vec3 base = value_clamp(mix(col, lf, trust) * mix(1.0, macro, 0.8));
	// Tiled PBR detail, normalised by each set's mean so the class
	// colour sets the value and the texture only adds structure.
	vec2 g = wpos.xz * u2m;
	vec2 ua = g / tile_m;
	vec2 ub = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * g / (tile_m * 3.7) + 0.37;
	vec3 det = W.x * tile(d0, ua, ub) / m0
		+ W.y * tile(d1, ua, ub) / m1
		+ W.z * tile(d2, ua, ub) / m2
		+ W.w * tile(d3, ua, ub) / m3;
	det = clamp(det, vec3(0.3), vec3(2.0));
	float ratio = clamp(lum(hf) / max(lum(lf), 1e-3), 0.55, 1.45);
	// Photo fine structure only where a photo pixel is no bigger
	// than a few screen pixels; close up it is blur, so PBR carries.
	float hf_on = smoothstep(60.0, 260.0, dist_m);
	vec3 near_c = base * det * mix(1.0, ratio, hfk * hf_on);
	near_c *= mix(1.0, paving(g), pave * (1.0 - steep));
	float wf = smoothstep(near_m, far_m, dist_m) * farc;
	vec3 alb = mix(near_c, mix(base, hf, 0.6), wf);
	alb *= COLOR.a;
	// Edge band: hand off to the far terrain's rendered albedo
	// (COLOR.rgb = FarTerrainBuilder.far_albedo_at: drape or ramp).
	float half_e = extent_u * 0.5;
	float cheb = max(abs(wpos.x), abs(wpos.z));
	float edge = smoothstep(half_e * 0.90, half_e * 0.985, cheb);
	alb = mix(alb, COLOR.rgb, edge);
	ALBEDO = value_clamp(alb);
	vec3 nm = W.x * tile(n0, ua, ub) + W.y * tile(n1, ua, ub)
		+ W.z * tile(n2, ua, ub) + W.w * tile(n3, ua, ub);
	NORMAL_MAP = mix(nm, vec3(0.5, 0.5, 1.0), max(wf, edge));
	NORMAL_MAP_DEPTH = 0.8;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
}
"""
