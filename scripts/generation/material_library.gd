class_name MaterialLibrary
extends RefCounted

## Shared texture + material construction for all generation builders.
## Split out of TerrainBuilder in T1.1a with identical (v1) outputs;
## TerrainBuilder and later the T1.1b/T1.1c builders call this instead
## of building materials inline (contract §4 common rules).
## Contract: docs/world-model-contract.md §4. T4.3: photographic CC0 PBR
## sets (assets/textures, register-gated T0.4) with OSM tag → satellite
## → regional resolution, real-storey window grids, and a ≤6-material
## distant budget. Colour maps are linearised at load for CPU work and
## raw-sampling shaders, and all tints are computed in linear space
## against linear PRD targets; StandardMaterial3D inputs are re-encoded
## to sRGB at the boundary (_set_tex, pbr_material — T4.7).

# --- v2 API (contract §4; T4.3 photographic PBR resolution) ---

## Facade for an OSM material/region style with a real storey count.
## `style` is an OSM `material` value or a region class; unknown styles
## resolve through the regional default, never to a flat colour. Rows
## equal the storey count (1..8, clamped); `storeys` <= 0 keeps the v1
## six-row look. The tint variant is picked deterministically.
## T4.6: implemented by FacadeMaterials, reached by path so this class
## never names it (FacadeMaterials depends on this one — no class cycle).
func facade_material(style: String, storeys: int) -> Material:
	return load(FACADES).facade_for_building({"material": style}, style, storeys,
		2, false, float(absi(hash(style + ":" + str(storeys)))))

## Roof material honouring `kind` (roof:material/shape family: flat,
## slate, tile/terracotta, concrete, metal, glass, wood, membrane...).
## Empty/unknown kinds resolve from the colour hint (satellite sample).
## Alpha 0 (no imagery), vegetation-green, or near-black samples fall
## back to slate (v1 rule).
func roof_material(kind: String, colour_hint: Color) -> Material:
	return load(FACADES).roof_for_building({"roof_material": kind}, "urban", kind,
		colour_hint, 2, false)

const FACADES := "res://scripts/generation/facade_materials.gd"

## Bundled photographic PBR sets: set name → Poly Haven asset id,
## linear-space mean albedo (measured at 64²), scalar roughness for the
## albedo-only path, and metallic. Paths are
## assets/textures/<set>_{diff,nor,rough}.jpg (1k, CC0 — see the
## data-source register). Glass is absent upstream (0 catalog hits for
## "glass"), so it is the one procedural set — see StoreyComposer.compose_glass.
## New textures change only this table, never the resolution code.
static var PBR_SETS := {
	"limestone": {"asset": "beige_wall_001", "mean": Color(0.3404, 0.2623, 0.1878), "rough": 0.88, "metal": 0.0},
	"stone": {"asset": "old_sandstone_02", "mean": Color(0.2498, 0.1399, 0.0489), "rough": 0.93, "metal": 0.0},
	"render": {"asset": "white_stucco", "mean": Color(0.6796, 0.6514, 0.6305), "rough": 0.94, "metal": 0.0},
	"brick": {"asset": "brick_wall_001", "mean": Color(0.1358, 0.0737, 0.0484), "rough": 0.90, "metal": 0.0},
	"concrete": {"asset": "concrete", "mean": Color(0.1715, 0.1470, 0.1060), "rough": 0.92, "metal": 0.0},
	"wood": {"asset": "brown_planks_03", "mean": Color(0.1521, 0.1309, 0.1047), "rough": 0.85, "metal": 0.0},
	"slate": {"asset": "grey_roof_tiles_02", "mean": Color(0.1897, 0.1964, 0.1927), "rough": 0.62, "metal": 0.08},
	"terracotta": {"asset": "clay_roof_tiles", "mean": Color(0.3325, 0.1070, 0.0513), "rough": 0.80, "metal": 0.0},
	"membrane": {"asset": "bitumen", "mean": Color(0.0433, 0.0375, 0.0347), "rough": 0.95, "metal": 0.0},
	"asphalt": {"asset": "asphalt_01", "mean": Color(0.1002, 0.0798, 0.0619), "rough": 0.97, "metal": 0.0},
	"pavement": {"asset": "concrete_pavement", "mean": Color(0.2140, 0.1761, 0.1342), "rough": 0.95, "metal": 0.0},
	"grass": {"asset": "grass_ground", "mean": Color(0.1562, 0.1180, 0.0482), "rough": 0.97, "metal": 0.0},
	"rock": {"asset": "brown_mud_rocks_01", "mean": Color(0.0854, 0.0639, 0.0380), "rough": 0.97, "metal": 0.0},
}

## PRD colour bases in linear space (tints multiply linearised maps):
## limestone #D6C5A3 and slate #46525E (PRD §4.2), glass #2E3A40.
static var PRD_LIMESTONE := Color(0.6724, 0.5583, 0.3663)
static var PRD_SLATE := Color(0.0612, 0.0844, 0.1119)
static var PRD_GLASS := Color(0.0273, 0.0423, 0.0513)

## OSM `material` / `building:material` values → PBR set. English and
## common tag spellings; unlisted values fall through to the regional
## default (never to a flat colour).
static var MATERIAL_TAGS := {
	"brick": "brick", "brickwork": "brick",
	"concrete": "concrete", "cement": "concrete", "cement_block": "concrete",
	"glass": "glass", "mirror": "glass",
	"wood": "wood", "timber": "wood", "planks": "wood", "thatch": "wood",
	"stone": "stone", "sandstone": "stone", "granite": "stone",
	"marble": "stone", "masonry": "stone", "ashlar": "stone", "rubble": "stone",
	"limestone": "limestone", "chalk": "limestone", "travertine": "limestone",
	"plaster": "render", "render": "render", "stucco": "render",
	"metal": "concrete", "steel": "concrete", "aluminium": "concrete",
	"tin": "concrete",
	"tile": "terracotta", "ceramic": "terracotta",
	"canvas": "render", "fabric": "render",
}

## `roof:material` values and roof_material() kinds → PBR set.
static var ROOF_TAGS := {
	"slate": "slate", "slates": "slate", "slate_tile": "slate",
	"tile": "terracotta", "tiles": "terracotta", "terracotta": "terracotta",
	"clay": "terracotta", "clay_tile": "terracotta", "ceramic": "terracotta",
	"concrete": "concrete", "cement": "concrete",
	"metal": "slate", "steel": "slate", "zinc": "slate", "copper": "terracotta",
	"glass": "glass",
	"wood": "wood", "shingle": "wood", "shingles": "wood", "thatch": "wood",
	"gravel": "membrane", "bitumen": "membrane", "felt": "membrane",
	"asphalt": "membrane", "membrane": "membrane", "epdm": "membrane",
	"tar": "membrane", "pvc": "membrane", "plastic": "membrane",
	"flat": "membrane", "flat_roof": "membrane",
	"grass": "grass", "sod": "grass", "turf": "grass", "green": "grass",
}

## Documented per-region wall/roof defaults (T4.2 region classes):
## Paris limestone + slate mansards (PRD §4.2), dense-modern render +
## flat membrane, brick + slate towns, render + terracotta rural.
static var REGION_MATERIALS := {
	"haussmann": {"wall": "limestone", "roof": "slate"},
	"urban_dense": {"wall": "render", "roof": "membrane"},
	"urban": {"wall": "brick", "roof": "slate"},
	"rural": {"wall": "render", "roof": "terracotta"},
}

## Roof texture repeat: the ring-cap/apex UVs span 0.05/unit, so a scale
## of 20 tiles the 1k slate every ~2.5 m (≈23 cm courses); terracotta
## barrels read at ~4.5 m, felt/concrete at ~6 m. BoxMesh-capped AABB
## fallbacks (0..1 UVs) tile denser — accepted on that logged path.
static var ROOF_UV := {
	"slate": 20.0, "terracotta": 11.0, "membrane": 8.0,
	"concrete": 8.0, "wood": 8.0, "glass": 4.0, "grass": 6.0,
}

## Land class → ground PBR set (T2.4 §2.6 classes; water surfaces use
## water_material(), never this map).
static var GROUND_SETS := {
	"grass": "grass", "forest": "grass", "field": "grass",
	"orchard": "grass", "cemetery": "grass", "pitch": "grass",
	"wetland": "grass", "urban": "pavement", "sand": "pavement",
	"rock": "rock", "quarry": "rock", "glacier": "render",
}

## Interim preset → PRD fidelity mapping (T7.4 redefines tiers; until
## then Fast builds F1, Balanced/High F2, Ultra F3).
static func fidelity_for_preset(preset: int) -> int:
	match clampi(preset, 0, 3):
		0:
			return 1
		3:
			return 3
	return 2

## Full-detail radius in metres per PRD §3.4 density column; buildings
## past it share the ≤6 distant materials.
static func full_detail_radius_m(fidelity: int) -> float:
	match fidelity:
		1:
			return 150.0
		3:
			return 600.0
	return 300.0

const TEXTURE_DIR := "res://assets/textures/"

## T4.7: the clay-tile photo is a dark, high-contrast red (linear mean
## 0.106/0.035/0.012, gaps near-black) that reads as harsh red with
## black speckle. At load it is remapped to weathered tiles: mean →
## the table's terracotta mean (#9C5C40), relative contrast × 0.6 (no
## pixel below ~0.4× the mean, tile-to-tile value variation kept).
const TERRACOTTA_PHOTO_MEAN := Color(0.1064, 0.0346, 0.0118)
const TERRACOTTA_CONTRAST := 0.6

static var _set_images: Dictionary = {}
static var _set_texs: Dictionary = {}
static var _pbr_mats: Dictionary = {}

## One bundled map as a linear-space Image, cached. Colour maps are
## linearised (no hardware sRGB decode on runtime textures); normal and
## roughness maps are data and stay raw. A missing/unreadable set warns
## once and falls back to a procedural grain (register fallback order).

# --- Delegators: implementation in PbrTextures. ---
static func _set_image(set_name: String, map_name: String) -> Image:
	return PbrTextures._set_image(set_name, map_name)

static func _weather_tiles(img: Image) -> void:
	PbrTextures._weather_tiles(img)

static func _set_tex(set_name: String, map_name: String) -> Texture2D:
	return PbrTextures._set_tex(set_name, map_name)

static func _calib_tint(mean: Color, target: Color) -> Color:
	return PbrTextures._calib_tint(mean, target)

static func pbr_material(set_name: String, tint: Color = Color.WHITE,
		uv_scale: float = 1.0, detail: int = 1) -> StandardMaterial3D:
	return PbrTextures.pbr_material(set_name, tint, uv_scale, detail)

static func parse_colour_tag(s: String) -> Color:
	return PbrTextures.parse_colour_tag(s)

func ground_material(land_class: String) -> Material:
	if _ground_mats.has(land_class) and has_ground_class(land_class):
		return _ground_mats[land_class]
	var m: Material
	if has_ground_class(land_class) and land_class != "water":
		var set_name: String = GROUND_SETS[land_class]
		var row: Dictionary = PBR_SETS[set_name]
		m = pbr_material(set_name,
			_calib_tint(row["mean"], ground_color(land_class)))
	else:
		m = _mat(ground_color(land_class))
	if has_ground_class(land_class):
		_ground_mats[land_class] = m
	return m

## Per-class ground colour for the full contract §2.6 set (T3.5): the
## v1 five keep their exact colours; the eight T2.4 additions (sand /
## rock / wetland / glacier / orchard / cemetery / pitch / quarry) get
## their own entries so no mapped class falls back. Rock matches the
## PRD #6E6A62 terrain rock; sand is a warm beach tone distinct from
## field tan and urban pavement. "" / unmapped → the settled-ground
## fallback (callers test has_ground_class first when the distinction
## matters, e.g. shore blending).
static func ground_color(land_class: String) -> Color:
	match land_class:
		"water":
			return Color(0.30, 0.50, 0.60)
		"forest":
			return Color(0.27, 0.41, 0.25)
		"grass":
			return Color(0.47, 0.60, 0.37)
		"field":
			return Color(0.70, 0.63, 0.43)
		"urban":
			return Color(0.64, 0.61, 0.55)
		"wetland":
			return Color(0.38, 0.42, 0.27)
		"sand":
			return Color(0.76, 0.69, 0.54)
		"rock":
			return Color(0.43, 0.42, 0.38)
		"glacier":
			return Color(0.82, 0.89, 0.92)
		"orchard":
			return Color(0.38, 0.52, 0.27)
		"cemetery":
			return Color(0.44, 0.51, 0.36)
		"pitch":
			return Color(0.36, 0.55, 0.28)
		"quarry":
			return Color(0.66, 0.62, 0.55)
	return Color(0.54, 0.51, 0.45)

## Whether a class has its own ground-colour entry (all 13 §2.6
## classes; "" and unmapped tags do not).
static func has_ground_class(land_class: String) -> bool:
	match land_class:
		"water", "forest", "grass", "field", "urban", "wetland", \
		"sand", "rock", "glacier", "orchard", "cemetery", "pitch", \
		"quarry":
			return true
	return false

## Shore-blend apron material (T3.5): per-vertex land-class colours
## over a photographic grain, so WaterBuilder's shoreline band reads
## as wet-to-dry cover instead of a flat tint. One shared instance.
static func shore_material() -> StandardMaterial3D:
	if _shore_mat == null:
		_shore_mat = StandardMaterial3D.new()
		_shore_mat.vertex_color_use_as_albedo = true
		_shore_mat.albedo_texture = detail_texture()
		_shore_mat.roughness = 0.95
		# Apron strips wind either way (landward flips per station),
		# so back-face culling is off — like the water shader.
		_shore_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _shore_mat

## Seine PBR water (v1 construction moved from TerrainBuilder._water).
func water_material() -> Material:
	# Seine PBR: river blue #3A7CA5 (r1), roughness 0.08-0.15,
	# dielectric reflection (env sky + sun spec), micro-wave normals.
	var m := _mat(Color(0.23, 0.49, 0.65), 0.12)
	m.metallic = 0.04
	m.albedo_texture = detail_texture()
	m.normal_texture = detail_texture()
	m.normal_scale = 0.35
	m.uv1_scale = Vector3(48.0, 48.0, 48.0)
	return m

# --- Moved v1 constructors (identical outputs) ---

static var _leaf_mats_by_season: Dictionary = {}
static var _slate_mat: StandardMaterial3D
static var _detail_tex: Texture2D
static var _leaf_tex: Texture2D
static var _leaf_card_tex: Texture2D
static var _roof_mats: Dictionary = {}
static var _ground_mats: Dictionary = {}
static var _shore_mat: StandardMaterial3D

static func _mat(color: Color, roughness: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

## Twin of TerrainBuilder._hash (kept local so this library has no
## TerrainBuilder dependency); both must stay the same pure function.
static func _hash(x: float, z: float) -> float:
	return fmod(absf(sin(x * 12.9898 + z * 78.233) * 43758.5453), 1.0)

## Photographic-style grain: thousands of tiny speckles over a base so
## no surface reads as a flat colour slab at Fidelity 2-3 (PRD §3.1).
static func speckle(img: Image, base: Color, n: int, seed_v: float, amp: float) -> void:
	img.fill(base)
	for i in n:
		var x := int(_hash(i * 1.37, seed_v) * float(img.get_width() - 2))
		var y := int(_hash(seed_v, i * 2.11) * float(img.get_height() - 2))
		var v := (_hash(i * 3.7, seed_v * 1.3) - 0.5) * 2.0 * amp
		img.fill_rect(Rect2i(x, y, 2, 2), Color(
			clampf(base.r + v, 0.0, 1.0), clampf(base.g + v * 0.95, 0.0, 1.0),
			clampf(base.b + v * 0.85, 0.0, 1.0)))

static func detail_texture() -> Texture2D:
	if _detail_tex != null:
		return _detail_tex
	var img := Image.create(128, 128, true, Image.FORMAT_RGBA8)
	speckle(img, Color(0.94, 0.94, 0.94), 2600, 4.2, 0.10)
	_detail_tex = ImageTexture.create_from_image(img)
	return _detail_tex

## Satellite drape material (T3.2): the mosaic imagery is the albedo
## and the mesh vertex colours are only an achromatic slope shade. PRD
## §4.4 caps ground luminance at 0.85; the cap is enforced here as a
## material-level multiplier — the texture itself is never darkened —
## so sampled albedo cannot exceed 0.85 while the vertex shade stays
## within [0.85, 1.0]. Fixed factor (not adaptive) so quality tiers,
## which stitch different zooms, tone the same ground identically.
static func satellite_ground_material(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.albedo_color = Color(0.85, 0.85, 0.85)
	m.roughness = 0.97
	# Anisotropic filtering: at grazing view angles the default
	# filter smears the drape into streaks (the melted foreground).
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

## Photographic slate (T4.3): the bundled grey-slate set calibrated
## to the PRD #46525E base. Still the shared fallback for missing
## imagery and degenerate satellite samples (roof_for_color rules).
static func slate() -> StandardMaterial3D:
	if _slate_mat != null:
		return _slate_mat
	var row: Dictionary = PBR_SETS["slate"]
	_slate_mat = pbr_material("slate", neutral_slate(_calib_tint(row["mean"], PRD_SLATE)),
		float(ROOF_UV["slate"]))
	RoofVariety.mark(_slate_mat)
	return _slate_mat

## Paris slate and zinc photograph as a neutral, faintly cool grey. The
## per-channel calibration onto the PRD #46525E base (linear B/R 1.83)
## rendered a saturated blue under the warm sky, so blue-cast slate tints
## are pulled this far toward their own grey (PRD base → ≈#4D5358, +3%
## luminance). Red/green painted metal roofs (b ≤ r) keep their hue.
const SLATE_GREY_PULL := 0.55

static func neutral_slate(tint: Color) -> Color:
	if tint.b <= tint.r:
		return tint
	var g := (tint.r + tint.g + tint.b) / 3.0
	return tint.lerp(Color(g, g, g, tint.a), SLATE_GREY_PULL)

static func leaf_texture() -> Texture2D:
	if _leaf_tex != null:
		return _leaf_tex
	var img := Image.create(128, 128, true, Image.FORMAT_RGBA8)
	speckle(img, Color(0.84, 0.87, 0.82), 3200, 6.4, 0.08)
	_leaf_tex = ImageTexture.create_from_image(img)
	return _leaf_tex

# --- Facade/roof-for-building materials moved to FacadeMaterials (T4.6).

## Drop the per-place PBR/roof dedup caches (FacadeMaterials.begin_build
## drops the facade ones and calls this). They are bounded and persist
## across generations — a session visiting a few places would otherwise
## fill them and render later cities in earlier ones' materials.
static func begin_build() -> void:
	_pbr_mats.clear()
	_roof_mats.clear()

## Live census of this library's caches (FacadeMaterials.material_instance_count
## adds the facade/roof families on top for the T4.3/T7.2 asserts).
static func material_instance_count() -> Dictionary:
	return {
		"roof_tint": _roof_mats.size(),
		"roof_sets": _pbr_mats.size(),
		"ground": _ground_mats.size(),
		"total": _roof_mats.size() + _pbr_mats.size() + _ground_mats.size(),
	}

static func leaves(season: int = LocationData.Season.SUMMER) -> Array:
	var key := LocationData.clamp_season(season)
	if _leaf_mats_by_season.has(key):
		return _leaf_mats_by_season[key]
	var palettes: Array = [
		[Color(0.38, 0.55, 0.30), Color(0.45, 0.60, 0.33), Color(0.32, 0.48, 0.27)],  # spring
		[Color(0.30, 0.45, 0.26), Color(0.36, 0.50, 0.28), Color(0.24, 0.38, 0.22)],  # summer
		[Color(0.72, 0.42, 0.20), Color(0.65, 0.35, 0.16), Color(0.55, 0.45, 0.20)],  # autumn
		[Color(0.35, 0.30, 0.24), Color(0.30, 0.36, 0.24), Color(0.38, 0.33, 0.26)],  # winter
	]
	var mats: Array = []
	for c in palettes[key]:
		# +-10% hue/value variance per material (PRD §4.4); the leaf
		# speckle texture stops canopies reading as flat blobs.
		for v in [0.92, 1.0, 1.08]:
			var m := _mat(Color(c.r * v, c.g * v, c.b * (2.0 - v) * 0.96), 0.92)
			m.albedo_texture = leaf_texture()
			mats.append(m)
	_leaf_mats_by_season[key] = mats
	return mats

## Leaf-cluster alpha texture: crossed alpha cards read as foliage
## mass from any angle, where a shaded sphere reads as a lollipop.
static func leaf_card_texture() -> Texture2D:
	if _leaf_card_tex != null:
		return _leaf_card_tex
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 1100:
		var cx := 128.0 + (_hash(i * 1.71, 3.3) - 0.5) * 190.0
		var cy := 128.0 + (_hash(3.3, i * 2.39) - 0.5) * 190.0
		if Vector2(cx - 128.0, cy - 128.0).length() > 105.0:
			continue
		var v := 0.45 + _hash(i * 0.37, i * 0.91) * 0.5
		var leaf := Color(v * 0.90, v, v * 0.84, 1.0)
		var s := 3 + int(_hash(i * 5.1, 7.7) * 4.0)
		img.fill_rect(Rect2i(int(cx), int(cy), s, maxi(2, s - 1)), leaf)
	var tex := ImageTexture.create_from_image(img)
	_leaf_card_tex = tex
	return tex

## Real roof colour for one footprint, averaged from the satellite
## mosaic (the only view of a roof a map actually gives you). Alpha 0
## means "no imagery": the caller falls back to the slate material.
## `uv_fn` projects (data, world_x, world_z) to mosaic UV; passed in so
## this library stays independent of TerrainBuilder.satellite_uv.
static func sampled_roof_color(data: LocationData, wx: float, wz: float,
		size_x: float, size_z: float, uv_fn: Callable) -> Color:
	var img := data.satellite_image
	if img == null:
		return Color(0, 0, 0, 0)
	var acc := Color(0, 0, 0)
	var n := 0
	for dz in [-0.25, 0.0, 0.25]:
		for dx in [-0.25, 0.0, 0.25]:
			var uv: Vector2 = uv_fn.call(data, wx + dx * size_x, wz + dz * size_z)
			var px := clampi(int(uv.x * float(img.get_width())), 0, img.get_width() - 1)
			var py := clampi(int(uv.y * float(img.get_height())), 0, img.get_height() - 1)
			acc += img.get_pixel(px, py)
			n += 1
	return acc / float(maxi(n, 1))

## Sampled colour resolved through the shared quantized roof cache.
static func roof_mat(data: LocationData, pos: Vector3, size_x: float, size_z: float,
		uv_fn: Callable) -> Material:
	var c := sampled_roof_color(data, pos.x, pos.z, size_x, size_z, uv_fn)
	return roof_for_color(c)

## A satellite sample that carries no roof information: alpha 0 (no
## imagery), vegetation-green, or near-black (vegetation/shadow under
## the footprint, not a roof — v1 rule).
static func _degenerate_roof_sample(c: Color) -> bool:
	if c.a == 0.0:
		return true
	if (c.g > c.r * 1.04 and c.g > c.b * 1.05) or c.r + c.g + c.b < 0.30:
		return true
	return false

## Satellite sample → tint over a roof set (linearised, then quantized
## 1/12 per channel so the cache stays bounded like the v1 rule).
static func _sat_roof_tint(set_name: String, c: Color) -> Color:
	var lin := c.srgb_to_linear()
	var t := _calib_tint((PBR_SETS[set_name] as Dictionary)["mean"], lin)
	return Color(roundf(t.r * 12.0) / 12.0, roundf(t.g * 12.0) / 12.0,
		roundf(t.b * 12.0) / 12.0)

## Satellite sample resolved through the shared quantized roof cache.
## Red-dominant samples read terracotta, dark greys slate, mid greys
## flat membrane; degenerate samples fall back to slate (v1 rule).
static func roof_for_color(c: Color) -> Material:
	if _degenerate_roof_sample(c):
		return slate()
	var set_name := "membrane"
	if c.r > c.g * 1.12 and c.r > c.b * 1.15:
		set_name = "terracotta"
	elif c.r + c.g + c.b < 1.05:
		set_name = "slate"
	var tint := _sat_roof_tint(set_name, c)
	if set_name == "slate":
		tint = neutral_slate(tint)
	var key := "%s|%s" % [set_name, tint.to_html()]
	if _roof_mats.has(key):
		return _roof_mats[key] as Material
	if _roof_mats.size() > 28:
		return slate()
	var m := pbr_material(set_name, tint, float(ROOF_UV[set_name]))
	RoofVariety.mark(m)
	_roof_mats[key] = m
	return m
