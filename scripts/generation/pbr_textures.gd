class_name PbrTextures
extends RefCounted

## CC0 PBR texture loading and material construction for
## MaterialLibrary: set images, weather tiling, calibration tints
## and cached PBR materials. Set tables and caches stay in
## MaterialLibrary (single source); this class is the loader.
## Strength of a photo set's normal map on walls and roofs: softened to keep
## specular shimmer down at Balanced, which has no MSAA.
const PHOTO_NORMAL_SCALE := 0.7
static var _mutex := Mutex.new()
## Set when _pbr_mats went past its 64 cap (see pbr_material).
static var cap_reached := false
## Parallel build stages (WorldBuildGraph), per pool thread: the cache a
## stage sees and its rank in the serial stage order. Keys round tint and
## repeat, so two stages can ask one key with slightly different values;
## serially the earliest stage's first request made it. Here a lower rank
## asking an entry a later stage made rewrites those two values, so the
## shared material ends as the serial build leaves it.
static var _stage := {}
static var _rank_of := {}

static func push_stage(cache: Dictionary, rank: int) -> void:
	_mutex.lock()
	_stage[OS.get_thread_caller_id()] = [cache, rank]
	_mutex.unlock()

static func pop_stage() -> void:
	_mutex.lock()
	_stage.erase(OS.get_thread_caller_id())
	_mutex.unlock()

## Called before a parallel build's stages start.
static func begin_stages() -> void:
	_mutex.lock()
	_rank_of.clear()
	cap_reached = false
	_mutex.unlock()

## Path of one set map: the 2K file on desktop Ultra builds
## (MaterialLibrary.hi_res) when it is bundled, else the 1K one.
static func map_path(set_name: String, map_name: String, hi_res: bool = MaterialLibrary.hi_res) -> String:
	var file := ("concrete" if set_name == "roof_concrete" else set_name) + "_" + map_name + ".jpg"
	if hi_res and ResourceLoader.exists(MaterialLibrary.TEXTURE_DIR + "2k/" + file):
		return MaterialLibrary.TEXTURE_DIR + "2k/" + file
	return MaterialLibrary.TEXTURE_DIR + file

static func _set_image(set_name: String, map_name: String, hi_res: bool = MaterialLibrary.hi_res) -> Image:
	var path := map_path(set_name, map_name, hi_res)
	var key := set_name + ":" + map_name + (":2k" if path.contains("/2k/") else "")
	_mutex.lock()
	if MaterialLibrary._set_images.has(key):
		var cached: Image = MaterialLibrary._set_images[key] as Image
		_mutex.unlock()
		return cached
	_mutex.unlock()
	var img: Image = null
	if ResourceLoader.exists(path):
		var texture := ResourceLoader.load(path) as Texture2D
		var loaded := texture.get_image() if texture != null else null
		if loaded != null and not loaded.is_empty() and loaded.get_width() >= 64:
			img = loaded
			if img.is_compressed():
				img.decompress()
			img.clear_mipmaps()
			if map_name == "diff":
				img.srgb_to_linear()
				if set_name == "terracotta":
					_weather_tiles(img)
				elif set_name == "sheet_metal":
					RoofMetalMaps.paint(img)
				elif set_name == "membrane":
					_destripe(img)
				elif set_name == "roof_concrete":  # its bands run down the columns
					img.rotate_90(CLOCKWISE)
					_destripe(img)
					img.rotate_90(COUNTERCLOCKWISE)
			elif map_name == "nor" and set_name == "membrane":
				_destripe_normal(img, 1)
			elif map_name == "nor" and set_name == "roof_concrete":
				img.rotate_90(CLOCKWISE)
				_destripe_normal(img, 0)
				img.rotate_90(COUNTERCLOCKWISE)
	if img == null:
		_mutex.lock()
		var has_warned := MaterialLibrary._set_images.has("warned:" + set_name)
		_mutex.unlock()
		if not has_warned:
			_mutex.lock()
			MaterialLibrary._set_images["warned:" + set_name] = true
			_mutex.unlock()
			push_warning("MaterialLibrary: bundled PBR set '%s' unreadable; procedural fallback." % set_name)
		img = Image.create(64, 64, false, Image.FORMAT_RGB8)
		if map_name == "nor":
			img.fill(Color(0.5, 0.5, 1.0))
		else:
			MaterialLibrary.speckle(img, Color(0.5, 0.5, 0.5), 700, 3.1, 0.08)
	if map_name == "nor" and set_name in ["copper", "sheet_metal"]:
		img = RoofMetalMaps.normals(img)
	_mutex.lock()
	MaterialLibrary._set_images[key] = img
	_mutex.unlock()
	return img

## Remap a linear clay-tile image to weathered terracotta (see
## MaterialLibrary.TERRACOTTA_CONTRAST): per channel, out = target·(1 + k·(in/mean − 1)).
static func _weather_tiles(img: Image) -> void:
	var to: Color = (MaterialLibrary.PBR_SETS["terracotta"] as Dictionary)["mean"]
	var fr := MaterialLibrary.TERRACOTTA_PHOTO_MEAN
	var k := MaterialLibrary.TERRACOTTA_CONTRAST
	if img.is_compressed():
		img.decompress()
	# 512² keeps ~4.5 cm texels at the 11 m roof repeat and a quarter
	# of the per-pixel remap cost.
	if img.get_width() > 512:
		img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(
				clampf(to.r * (1.0 + k * (c.r / fr.r - 1.0)), 0.0, 1.0),
				clampf(to.g * (1.0 + k * (c.g / fr.g - 1.0)), 0.0, 1.0),
				clampf(to.b * (1.0 + k * (c.b / fr.b - 1.0)), 0.0, 1.0)))

## Takes the roll bands out of the linear bitumen photo (three per tile, most
## of its contrast, and a flat roof's tint amplifies them): each row is scaled
## to the image mean, per channel, so the grain and the set's mean both stay.
static func _destripe(img: Image) -> void:
	if img.get_width() > 512:
		img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	var w := img.get_width()
	var h := img.get_height()
	var rows := PackedColorArray()
	rows.resize(h)
	var mean := Color(0, 0, 0, 0)
	for y in h:
		var sum := Color(0, 0, 0, 0)
		for x in w:
			sum += img.get_pixel(x, y)
		rows[y] = sum / float(w)
		mean += rows[y] / float(h)
	for y in h:
		var gain := Color(mean.r / maxf(rows[y].r, 0.0001), mean.g / maxf(rows[y].g, 0.0001),
			mean.b / maxf(rows[y].b, 0.0001))
		for x in w:
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r * gain.r, c.g * gain.g, c.b * gain.b))

## The same bands in a normal map: they tilt whole rows (one channel, `ch`),
## and would return as relief once a roof's normal map is on.
static func _destripe_normal(img: Image, ch: int) -> void:
	if img.get_width() > 512:
		img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	var w := img.get_width()
	var h := img.get_height()
	var rows := PackedFloat32Array()
	rows.resize(h)
	var mean := 0.0
	for y in h:
		var sum := 0.0
		for x in w:
			sum += img.get_pixel(x, y)[ch]
		rows[y] = sum / float(w)
		mean += rows[y] / float(h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			c[ch] = clampf(c[ch] + mean - rows[y], 0.0, 1.0)
			img.set_pixel(x, y, c)

## Runtime texture of one set map for StandardMaterial3D (pbr_material),
## mipmapped (T4.7: without mips the tiled roofs and road ribbons alias
## to speckle at distance). albedo_texture is a source_color sampler the
## renderer sRGB-decodes (runtime ImageTextures included — measured on
## Metal), so the colour map is re-encoded to sRGB here; handing it the
## linearised image decoded it twice (dark, over-contrasted roofs and
## near-black asphalt). The cached Image stays linear and mip-free for
## the CPU composers and the GroundMaterial shader (raw samplers).
static func _set_tex(set_name: String, map_name: String) -> Texture2D:
	var key := "t:" + set_name + ":" + map_name + (":2k" if map_path(set_name, map_name).contains("/2k/") else "")
	_mutex.lock()
	if MaterialLibrary._set_texs.has(key):
		var cached_t: Texture2D = MaterialLibrary._set_texs[key] as Texture2D
		_mutex.unlock()
		return cached_t
	_mutex.unlock()
	var img := (_set_image(set_name, map_name) as Image).duplicate() as Image
	if map_name == "diff":
		img.linear_to_srgb()
	if not img.has_mipmaps():
		img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_mutex.lock()
	MaterialLibrary._set_texs[key] = t
	_mutex.unlock()
	return t

## Per-channel tint taking a set mean to a target, clamped so texture
## contrast survives (no channel pushed past 0.3×–2.8×).
static func _calib_tint(mean: Color, target: Color) -> Color:
	return Color(
		clampf(target.r / maxf(mean.r, 0.004), 0.3, 2.8),
		clampf(target.g / maxf(mean.g, 0.004), 0.3, 2.8),
		clampf(target.b / maxf(mean.b, 0.004), 0.3, 2.8))

## Shared single-set PBR material, cached by set + tint + repeat.
## detail 0 is the F1 distant path: albedo only, scalar roughness.
## `tint` is LINEAR (every calibration here is target/mean in linear);
## albedo_color is a source_color uniform the renderer sRGB-decodes, so
## it is stored encoded (T4.7 — passing the linear tint raw squared it:
## near-black navy asphalt and slate, blown-out bright tints).
## Locked: the parallel world build reaches it from several tasks. The
## 64 cap and its fallbacks follow insertion order, which only a serial
## build fixes, so cap_reached records any build that went past 64
## distinct keys and WorldBuildGraph then rebuilds serially.
static func pbr_material(set_name: String, tint: Color = Color.WHITE,
		uv_scale: float = 1.0, detail: int = 1) -> StandardMaterial3D:
	var key := "%s|%s|%.2f|%d" % [set_name, tint.to_html(), uv_scale, detail]
	_mutex.lock()
	var ctx: Array = _stage.get(OS.get_thread_caller_id(), [MaterialLibrary._pbr_mats, -1])
	var mats: Dictionary = ctx[0]
	var rank: int = ctx[1]
	if mats.has(key):
		var cached: StandardMaterial3D = mats[key] as StandardMaterial3D
		if rank >= 0 and rank < int(_rank_of.get(cached.get_instance_id(), rank)):
			cached.albedo_color = tint.linear_to_srgb()
			cached.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
			_rank_of[cached.get_instance_id()] = rank
		_mutex.unlock()
		return cached
	if mats.size() >= 64:
		if is_same(mats, MaterialLibrary._pbr_mats):
			cap_reached = true
		# Full: reuse one of the same set (a brick chimney must not come
		# back as the first slate ever made).
		var reuse: StandardMaterial3D = mats.values()[0] as StandardMaterial3D
		for k in mats:
			if str(k).begins_with(set_name + "|"):
				reuse = mats[k] as StandardMaterial3D
				break
		_mutex.unlock()
		return reuse
	_mutex.unlock()
	var row: Dictionary = MaterialLibrary.PBR_SETS.get(set_name, MaterialLibrary.PBR_SETS["limestone"])
	var m := StandardMaterial3D.new()
	m.albedo_texture = _set_tex(set_name, "diff")
	m.albedo_color = tint.linear_to_srgb()
	if detail >= 1:
		m.normal_texture = _set_tex(set_name, "nor")
		m.roughness_texture = _set_tex(set_name, "rough")
		m.roughness = 1.0
	else:
		m.roughness = float(row["rough"])
	m.metallic = float(row["metal"])
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	_mutex.lock()
	if mats.has(key):  # another stage made it meanwhile: share theirs
		var other: StandardMaterial3D = mats[key] as StandardMaterial3D
		if rank >= 0 and rank < int(_rank_of.get(other.get_instance_id(), rank)):
			other.albedo_color = m.albedo_color
			other.uv1_scale = m.uv1_scale
			_rank_of[other.get_instance_id()] = rank
		m = other
	else:
		if mats.size() >= 64 and is_same(mats, MaterialLibrary._pbr_mats):
			cap_reached = true  # two stages raced past the cap
		mats[key] = m
		if rank >= 0:
			_rank_of[m.get_instance_id()] = rank
	_mutex.unlock()
	return m

## OSM `building:colour` / `roof:colour`: #rgb/#rrggbb hex (with or
## without #) plus the common named colours (tuned table first, then any
## CSS colour name via Color.from_string), returned linear with
## alpha 1; unparseable/empty reads alpha 0 (caller keeps its tint).
static func parse_colour_tag(s: String) -> Color:
	var t := s.strip_edges().to_lower()
	if t == "":
		return Color(0, 0, 0, 0)
	if t.begins_with("#"):
		t = t.substr(1)
	var hex_ok := t.length() == 6 or t.length() == 3
	if hex_ok:
		for i in t.length():
			if "0123456789abcdef".find(t.substr(i, 1)) < 0:
				hex_ok = false
	if hex_ok:
		if t.length() == 3:
			t = t.substr(0, 1) + t.substr(0, 1) + t.substr(1, 1) \
				+ t.substr(1, 1) + t.substr(2, 1) + t.substr(2, 1)
		var c := Color.html(t)
		c.a = 1.0
		return c.srgb_to_linear()
	var named := {
		"white": "FFFFFF", "black": "232323", "grey": "8A8A8A",
		"gray": "8A8A8A", "darkgrey": "4A4A4A", "darkgray": "4A4A4A",
		"lightgrey": "C8C8C8", "lightgray": "C8C8C8", "red": "9E3B2E",
		"brown": "6B4A2F", "beige": "F0E6CE", "yellow": "D9B23C",
		"cream": "F2EAD8", "green": "5A6B3C", "blue": "3C5A78",
		"orange": "B25A2A", "pink": "D8A0A0", "terracotta": "A9522F",
	}
	if named.has(t):
		var c := Color.html(named[t])
		c.a = 1.0
		return c.srgb_to_linear()
	# Any other CSS/X11 name (lightyellow, tan, darksalmon...). Godot's
	# table only spells "gray", so British "grey" is normalised first.
	var css := t.replace(" ", "").replace("_", "").replace("grey", "gray")
	var sentinel := Color(-1, -1, -1, -1)
	var named_c := Color.from_string(css, sentinel)
	if named_c != sentinel and named_c.a > 0.0:
		named_c.a = 1.0
		return named_c.srgb_to_linear()
	return Color(0, 0, 0, 0)

## Photographic PBR ground per land class (T4.3): the T2.4 §2.6 class
## maps to a bundled set (GROUND_SETS) calibrated toward the class
## palette colour, so the no-satellite path reads photographic instead
## of flat. (Contract names this parameter `class`; renamed: `class`
## is reserved.) One shared material per class (PRD §6 budget
## direction); water surfaces use water_material(), and unknown or
## unmapped ("") classes share the settled-ground fallback, never a
## wrong class colour.
