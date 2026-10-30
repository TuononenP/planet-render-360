class_name FacadeMaterials
extends RefCounted

## Building facade and roof materials (T4.3 resolution, T4.6 regional
## authenticity v2). Split out of MaterialLibrary so that class keeps the
## shared PBR sets, ground, water and foliage, and this one owns what a
## building wears: OSM tags → satellite sample → ArchitectureStyle look,
## per-building deterministic variants (tint, window pattern, ground
## floor), the ground-storey material (shopfronts, signage bands, the
## rendered base of a chalet), and the ≤6 shared distant materials
## (PRD §6). Textures are composed by FacadeComposer (tiled storeys) and
## StoreyComposer (Paris full facades, ground floors, glass).
## Depends on MaterialLibrary (one direction only — MaterialLibrary never
## names this class, so no class-load cycle).

## Facade texture / material cache caps. Overflow reuses the first
## material of the same set+pattern family (never another region's look).
const TEX_CAP := 160
const MAT_CAP := 192

## Roof luminance floor (linear, Rec.709): a tinted roof never reads
## near-black under the §3.3 light (PRD #46525E slate is ≈0.08).
const ROOF_MIN_LUMA := 0.075

static var _facade_mats: Array = []
static var _facade_texs: Dictionary = {}
static var _facade_cache: Dictionary = {}
static var _family_first: Dictionary = {}
static var _ground_cache: Dictionary = {}
static var _distant_mats: Dictionary = {}
static var _distant_roof_mats: Dictionary = {}
static var _glass_mats: Dictionary = {}
static var _roof_mats: Dictionary = {}

## Drop every per-place cache (and MaterialLibrary's): a session that
## visits several places must never render a later city in an earlier
## one's materials. Built worlds keep theirs through their references.
static func begin_build() -> void:
	_facade_texs.clear()
	_facade_cache.clear()
	_family_first.clear()
	_ground_cache.clear()
	_distant_mats.clear()
	_distant_roof_mats.clear()
	_roof_mats.clear()
	BuildingTrim._mats.clear()
	MaterialLibrary.begin_build()

## Live census for the T4.3/T7.2 instance-count asserts.
static func material_instance_count() -> Dictionary:
	var dist_f := 0
	for k in _distant_mats:
		dist_f += (_distant_mats[k] as Array).size()
	var dist_r := 0
	for k in _distant_roof_mats:
		dist_r += (_distant_roof_mats[k] as Array).size()
	var base := MaterialLibrary.material_instance_count()
	return {
		"facade_v1": _facade_mats.size(),
		"facade_near": _facade_cache.size(),
		"ground_floor": _ground_cache.size(),
		"facade_textures": _facade_texs.size(),
		"distant_facade": dist_f,
		"distant_roof": dist_r,
		"roof_tint": _roof_mats.size(),
		"roof_sets": int(base["roof_sets"]),
		"ground": int(base["ground"]),
		"glass": _glass_mats.size(),
		"total": _facade_mats.size() + _facade_cache.size() + _ground_cache.size()
			+ dist_f + _roof_mats.size() + int(base["roof_sets"])
			+ int(base["ground"]) + _glass_mats.size(),
	}

static func _calib(set_name: String, target: Color) -> Color:
	return MaterialLibrary._calib_tint(
		(MaterialLibrary.PBR_SETS[set_name] as Dictionary)["mean"], target)

# --- Paris limestone (PRD §4.2) ---

## Six limestone tints (PRD §4.2: hue ≤±4%, value ±8%) around the
## #D6C5A3 calibration; warm, neutral and cool-grey stones alternate so a
## street of blocks is not one yellow.
const LIMESTONE_TINTS := [Color(1.0, 0.99, 0.96), Color(0.95, 0.94, 0.92),
	Color(1.04, 1.01, 0.94), Color(0.93, 0.91, 0.89), Color(1.0, 0.96, 0.90),
	Color(0.97, 0.96, 0.99)]

static func _limestone_calib() -> Color:
	return _calib("limestone", MaterialLibrary.PRD_LIMESTONE)

static func _limestone_tint(seed_v: float) -> Color:
	return LIMESTONE_TINTS[absi(hash(str(seed_v))) % LIMESTONE_TINTS.size()] \
		* _limestone_calib()

## The six v1 limestone facade variants (legacy box fallback + overflow).
static func facades() -> Array:
	if not _facade_mats.is_empty():
		return _facade_mats
	for tint in LIMESTONE_TINTS:
		_facade_mats.append(_facade_material_for("limestone", 6, 1,
			tint * _limestone_calib()))
	return _facade_mats

# --- Facades ---

## Facade for one §2.4 building dict: OSM `material` → the building's
## ArchitectureStyle wall (legacy regional default when `style` is
## empty); `building:colour` tints toward the tag (quantized, so the
## cache stays bounded) else the style's paint colour, else a
## deterministic variant tint. Tiled patterns repeat per real storey and
## bay; the Paris pattern keeps rows = storeys (1..8). Distant buildings
## share the ≤4 distant facades of their region (PRD §6).
static func facade_for_building(b: Dictionary, region: String, storeys: int,
		fidelity: int, distant: bool, seed_v: float = 0.0,
		style: Dictionary = {}) -> Material:
	if distant:
		var dfs := distant_facades(fidelity, region)
		return dfs[absi(hash(str(seed_v))) % dfs.size()]
	if style.is_empty() and not MaterialLibrary.REGION_MATERIALS.has(region):
		region = "urban"
	var set_name := _wall_set(b, style, region)
	var pattern := _pattern(b, style, set_name)
	if set_name == "glass":
		pattern = "curtain"
	var rows := 6
	if storeys > 0:
		rows = clampi(storeys, 1, 8)
	var detail := 2 if fidelity >= 3 else 1
	var tint := _wall_tint(b, style, set_name, seed_v)
	var tiled := FacadeComposer.is_tiled(pattern)
	var tex_rows := 0 if (set_name == "glass" or tiled) else rows
	var variant := int(style.get("variant", 0))
	if fidelity <= 1:
		variant = 0  # F1: one texture per look (mobile memory)
	var look_key := ""
	if tiled:
		look_key = _look_key(style) + "|%d" % variant
	elif not style.is_empty():
		look_key = "%.1f|%d" % [float(style["bay_m"]), variant]
	var key := "%s|%s|%d|%d|%s|%s" % [set_name, pattern, tex_rows, detail,
		tint.to_html(), look_key]
	if _facade_cache.has(key):
		return _facade_cache[key] as Material
	var family := set_name + "|" + pattern
	if _facade_cache.size() >= MAT_CAP:
		if _family_first.has(family):
			return _family_first[family] as Material
		return facades()[absi(hash(str(seed_v))) % facades().size()]
	var look := style.duplicate()
	look["variant"] = variant
	var m := _facade_material_for(set_name, rows, detail, tint, pattern, look)
	_facade_cache[key] = m
	if not _family_first.has(family):
		_family_first[family] = m
	return m

static func _wall_set(b: Dictionary, style: Dictionary, region: String) -> String:
	var mat_tag := str(b.get("material", "")).strip_edges().to_lower()
	var set_name: String = MaterialLibrary.MATERIAL_TAGS.get(mat_tag, "")
	if set_name != "":
		return set_name
	if not style.is_empty():
		return str(style["wall_set"])
	return str((MaterialLibrary.REGION_MATERIALS[region] as Dictionary)["wall"])

static func _pattern(b: Dictionary, style: Dictionary, set_name: String) -> String:
	if style.is_empty():
		return "haussmann"
	var pattern := str(style["pattern"])
	var mat_tag := str(b.get("material", "")).strip_edges().to_lower()
	if MaterialLibrary.MATERIAL_TAGS.get(mat_tag, "") == "wood" \
			and pattern in ["punched", "strip", "balcony", "adobe", "tiles"]:
		return "clapboard"
	if set_name == "wood" and pattern in ["strip", "balcony", "tiles"]:
		return "clapboard"
	return pattern

static func _wall_tint(b: Dictionary, style: Dictionary, set_name: String,
		seed_v: float) -> Color:
	var tag := MaterialLibrary.parse_colour_tag(str(b.get("colour", "")))
	var painted: Color = style.get("wall_colour", Color(0, 0, 0, 0))
	if tag.a > 0.0:
		var q := Color(roundf(tag.r * 16.0) / 16.0,
			roundf(tag.g * 16.0) / 16.0, roundf(tag.b * 16.0) / 16.0)
		if set_name == "glass":
			# A colour tag on glass names the glazing's hue, not an albedo
			# to multiply the sky reflection by (dark tags made black slabs).
			var mx := maxf(maxf(q.r, q.g), maxf(q.b, 0.001))
			return Color.WHITE.lerp(Color(q.r / mx, q.g / mx, q.b / mx), 0.45)
		return _calib(set_name, q)
	if set_name == "glass":
		return Color.WHITE
	if painted.a > 0.0 and MaterialLibrary.PBR_SETS.has(set_name):
		return _keep_chroma(set_name, _calib(set_name, painted))
	if set_name == "limestone":
		return _limestone_tint(seed_v)
	var variants := [Color(0.96, 0.96, 0.96), Color.WHITE, Color(1.04, 1.03, 1.02)]
	return variants[absi(hash(str(seed_v))) % variants.size()]

## Brick and terracotta photos are already strongly coloured: a
## per-channel calibration toward a red target multiplies that chroma and
## turns mortar pink and courses into stripes. Pull such tints 40% toward
## their own grey so the photo's colour carries the hue.
static func _keep_chroma(set_name: String, tint: Color) -> Color:
	if set_name == "slate":
		return MaterialLibrary.neutral_slate(tint)
	if set_name != "brick" and set_name != "terracotta":
		return tint
	var g := (tint.r + tint.g + tint.b) / 3.0
	return tint.lerp(Color(g, g, g), 0.4)

## Texture-identity part of a tiled look (frame/shutter colours, window
## vocabulary, balconette share, bay).
static func _look_key(look: Dictionary) -> String:
	return "%s|%s|%.1f|%s|%.1f|%.1f" % [
		(look.get("frame", Color.WHITE) as Color).to_html(false),
		(look.get("shutter", Color.BLACK) as Color).to_html(false),
		snappedf(float(look.get("shutter_p", 0.0)), 0.1),
		str(look.get("window", "casement")),
		snappedf(float(look.get("rails", 0.0)), 0.1),
		float(look.get("bay_m", 3.2))]

## Ground-storey material for a building whose look has a ground
## treatment (shopfront, signage band, rendered chalet base, rusticated
## plinth), or null (none / distant / F1). One storey of BAYS bays, the
## same real-bay UV mapping as the tiled facade above it. Shared per
## (set, kind, fascia colour, look): a street of shops costs a handful.
static func ground_for_building(b: Dictionary, fidelity: int, distant: bool,
		style: Dictionary) -> Material:
	if distant or fidelity <= 1 or style.is_empty():
		return null
	var kind := str(style.get("ground", ""))
	if kind == "":
		return null
	var set_name := _wall_set(b, style, "urban")
	if set_name == "glass" or set_name == "wood":
		set_name = "render" if kind == "render" else "concrete"
	if kind == "render":
		set_name = "render"
	elif kind == "stone":
		set_name = "stone"
	var tint := Color.WHITE
	if kind == "render":
		tint = _calib("render", ArchitectureStyle._lin("#f1ece0"))
	elif kind == "stone":
		tint = _calib("stone", ArchitectureStyle._lin("#b8ab92"))
	else:
		tint = _wall_tint(b, style, set_name, float(style.get("variant", 0)))
	var detail := 2 if fidelity >= 3 else 1
	var fascia: Color = style.get("ground_colour", Color(0, 0, 0, 0))
	if fascia.a <= 0.0:
		fascia = ArchitectureStyle._lin("#2e3b34")
	var key := "%s|%s|%s|%s|%d|%s|%d" % [set_name, kind, tint.to_html(),
		fascia.to_html(false), detail, _look_key(style), int(style.get("variant", 0))]
	if _ground_cache.has(key):
		return _ground_cache[key] as Material
	if _ground_cache.size() >= 48:
		return _ground_cache.values()[0] as Material
	var tkey := "ground|" + key
	var texs: Dictionary
	if _facade_texs.has(tkey):
		texs = _facade_texs[tkey]
	else:
		texs = StoreyComposer.compose_ground(set_name, kind, detail, style, fascia,
			Callable(MaterialLibrary, "_set_image"))
		_facade_texs[tkey] = texs
	var m := _material_from(texs, set_name, detail, tint)
	m.set_meta("fc_uv", Vector3(maxf(float(style.get("bay_m", 3.2)), 1.0),
		float(FacadeComposer.BAYS), 1.0))
	FacadeTextures.set_recess(m, texs.get("depth"), maxf(float(style.get("bay_m", 3.2)), 1.0)
		* float(FacadeComposer.BAYS), float(style.get("floor_h", 3.3)) * 1.15)
	_ground_cache[key] = m
	return m

# --- Roofs ---

## Roof for one §2.4 building: `roof:material` (+ `roof:colour`) →
## satellite sample family → flat shape to the style's flat set, pitched
## to the style's regional set + colour (legacy regional set when `style`
## is empty). Distant buildings share the 2 regional distant roofs.
static func roof_for_building(b: Dictionary, region: String, shape: String,
		colour_hint: Color, fidelity: int, distant: bool,
		seed_v: float = 0.0, style: Dictionary = {}) -> Material:
	if distant:
		var drs := distant_roofs(region, fidelity)
		return drs[absi(hash(str(seed_v))) % drs.size()]
	if not MaterialLibrary.REGION_MATERIALS.has(region):
		region = "urban"
	var tag_set: String = MaterialLibrary.ROOF_TAGS.get(
		str(b.get("roof_material", "")).strip_edges().to_lower(), "")
	if tag_set != "":
		var tint := roof_base_tint(tag_set)
		var tag := MaterialLibrary.parse_colour_tag(str(b.get("roof_colour", "")))
		if tag.a > 0.0 and tag_set != "glass":
			var q := Color(roundf(tag.r * 12.0) / 12.0,
				roundf(tag.g * 12.0) / 12.0, roundf(tag.b * 12.0) / 12.0)
			tint = _roof_floor(tag_set, _keep_chroma(tag_set, _calib(tag_set, q)))
		return roof_set_material(tag_set, tint)
	var styled := str(style.get("roof_set", ""))
	if not MaterialLibrary._degenerate_roof_sample(colour_hint):
		return roof_for_color(colour_hint, _sample_set(colour_hint, shape, styled))
	if shape == "flat":
		var flat_set := styled if styled in ["membrane", "concrete"] else "membrane"
		var ftint := roof_base_tint(flat_set)
		var fpaint: Color = style.get("roof_colour", Color(0, 0, 0, 0))
		if fpaint.a > 0.0 and flat_set == styled:
			ftint = _roof_floor(flat_set, _calib(flat_set, fpaint))
		return roof_set_material(flat_set, ftint)
	if styled != "":
		var painted: Color = style.get("roof_colour", Color(0, 0, 0, 0))
		var tint2 := roof_base_tint(styled)
		if painted.a > 0.0 and MaterialLibrary.PBR_SETS.has(styled):
			tint2 = _roof_floor(styled, _keep_chroma(styled, _calib(styled, painted)))
		return roof_set_material(styled, tint2)
	var reg_set := str((MaterialLibrary.REGION_MATERIALS[region] as Dictionary)["roof"])
	return roof_set_material(reg_set, roof_base_tint(reg_set))

## Base tint per roof set: slate calibrates to the PRD base; flat
## membrane/concrete read as weathered gravel grey (the bundled bitumen
## photo is near-black, which is not what a flat roof looks like from
## above); the rest read photographic.
static func roof_base_tint(set_name: String) -> Color:
	match set_name:
		"slate":
			return MaterialLibrary.neutral_slate(_calib("slate", MaterialLibrary.PRD_SLATE))
		"membrane":
			return _calib("membrane", ArchitectureStyle._lin("#8c8882"))
		"concrete":
			return _calib("concrete", ArchitectureStyle._lin("#a9a59c"))
	return Color.WHITE

## Lift a roof tint so its mean albedo keeps ROOF_MIN_LUMA (no black
## roofs from dark palette entries or shadowed satellite samples).
static func _roof_floor(set_name: String, tint: Color) -> Color:
	if not MaterialLibrary.PBR_SETS.has(set_name):
		return tint
	var mean: Color = (MaterialLibrary.PBR_SETS[set_name] as Dictionary)["mean"]
	var luma := 0.2126 * mean.r * tint.r + 0.7152 * mean.g * tint.g \
		+ 0.0722 * mean.b * tint.b
	if luma >= ROOF_MIN_LUMA or luma <= 0.0:
		return tint
	var k := ROOF_MIN_LUMA / luma
	return Color(minf(tint.r * k, 2.8), minf(tint.g * k, 2.8), minf(tint.b * k, 2.8))

static func roof_set_material(set_name: String, tint: Color, detail: int = 1) -> Material:
	if set_name == "glass":
		return glass_material(1)
	var m := MaterialLibrary.pbr_material(set_name, tint,
		float(MaterialLibrary.ROOF_UV.get(set_name, 8.0)), detail)
	RoofVariety.mark(m)  # RoofSnow overlay + per-building tint
	return m

## Satellite sample → roof set + tint through a bounded quantized cache.
## Red-dominant samples read terracotta, dark greys slate, mid greys flat
## membrane; degenerate samples fall back to slate (v1 rule). The tint is
## floored so shadowed samples never turn a roof black.
static func roof_for_color(c: Color, set_name: String = "") -> Material:
	if MaterialLibrary._degenerate_roof_sample(c):
		return MaterialLibrary.slate()
	if set_name == "":
		set_name = _sample_set(c, "", "")
	var tint := _roof_floor(set_name,
		_keep_chroma(set_name, MaterialLibrary._sat_roof_tint(set_name, c)))
	tint = Color(roundf(tint.r * 12.0) / 12.0, roundf(tint.g * 12.0) / 12.0,
		roundf(tint.b * 12.0) / 12.0)
	var key := "%s|%s" % [set_name, tint.to_html()]
	if _roof_mats.has(key):
		return _roof_mats[key] as Material
	if _roof_mats.size() > 28:
		return MaterialLibrary.slate()
	var m := roof_set_material(set_name, tint)
	_roof_mats[key] = m
	return m

## Roof set for a satellite sample: the photo gives the colour, the
## shape and regional style give the finish. Red-dominant samples read
## terracotta; otherwise a pitched roof keeps the style's slate/metal or
## timber shingle (a grey Paris mansard is zinc/slate, not bitumen), and
## a flat roof its membrane/concrete. With no style: v1 families.
static func _sample_set(c: Color, shape: String, styled: String) -> String:
	if c.r > c.g * 1.12 and c.r > c.b * 1.15:
		return "terracotta"
	if styled != "" and shape != "":
		if shape == "flat":
			return styled if styled in ["membrane", "concrete"] else "membrane"
		return styled if styled in ["slate", "wood"] else "slate"
	if c.r + c.g + c.b < 1.05:
		return "slate"
	return "membrane"

# --- Distant budget (PRD §6: 4 walls + 2 roofs) ---

## The 4 shared distant facades: the region's apartment fabric,
## albedo-only at F1 (PRD §3.4), full PBR at F2/F3. Legacy and Paris
## regions keep four limestone tints.

# --- Delegators: implementation in FacadeTextures. ---
static func _material_from(texs: Dictionary, set_name: String, detail: int,
		tint: Color) -> StandardMaterial3D:
	return FacadeTextures._material_from(texs, set_name, detail, tint)

static func _facade_material_for(set_name: String, rows: int, detail: int,
		tint: Color, pattern: String = "haussmann",
		look: Dictionary = {}) -> StandardMaterial3D:
	return FacadeTextures._facade_material_for(set_name, rows, detail, tint, pattern, look)

static func distant_facades(fidelity: int, region: String = "") -> Array:
	return FacadeTextures.distant_facades(fidelity, region)

static func distant_roofs(region: String, fidelity: int = 2) -> Array:
	return FacadeTextures.distant_roofs(region, fidelity)

static func glass_material(detail: int = 1) -> StandardMaterial3D:
	return FacadeTextures.glass_material(detail)

static func facade_texs(set_name: String, rows: int, detail: int,
		pattern: String = "haussmann", look: Dictionary = {}) -> Dictionary:
	return FacadeTextures.facade_texs(set_name, rows, detail, pattern, look)

static func facade_uv(mat: Material) -> Vector3:
	return FacadeTextures.facade_uv(mat)

