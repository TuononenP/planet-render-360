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
	sh.code = GroundShader.CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
	var m := ShaderMaterial.new()
	m.shader = sh
	var m2u := WorldScale.metres_to_units()
	m.set_shader_parameter("photo", photo)
	m.set_shader_parameter("class_map", ImageTexture.create_from_image(class_map(data)))
	m.set_shader_parameter("palette", ImageTexture.create_from_image(palette(data.season,
		ClimateModel.grass_tint(data, data.season))))
	ClimateModel.apply_snow(m, data)
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
## `dry` (linear, alpha 1) replaces the grass colour in dry-summer and
## arid climates (ClimateModel.grass_tint); alpha 0 keeps the season's.
static func palette(season: int = LocationData.Season.SUMMER, dry: Color = Color(0, 0, 0, 0)) -> Image:
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
	if dry.a > 0.0:
		grass = Color(dry.r, dry.g, dry.b).linear_to_srgb()
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
