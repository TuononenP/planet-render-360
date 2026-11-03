class_name VesselMaterials
extends RefCounted

## Shared marine materials for the procedural vessels. One cached material
## per (name, maps) so a fleet of yachts shares white gelcoat, glass and
## steel across every prototype. `maps` false (FAST) leaves out the detail
## normal maps. Decks and roofs are marked so snow settles on them.
static var _cache := {}
static var _mutex := Mutex.new()

const PAINTS := {
	"white": ["#e9e7df", 0.42, 0.04], "cream": ["#d8d2bd", 0.5, 0.04],
	"steel": ["#c3c8ca", 0.28, 0.85], "dark": ["#26292c", 0.5, 0.1],
	"black": ["#15171a", 0.55, 0.1], "orange": ["#e0651c", 0.5, 0.05],
	"grey_deck": ["#7e8885", 0.7, 0.05], "pool": ["#2f8fb0", 0.12, 0.0],
	"tube": ["#3b4043", 0.8, 0.0], "antifoul": ["#6e211d", 0.75, 0.0],
	"navy": ["#1c2b46", 0.5, 0.05], "red": ["#a3281f", 0.5, 0.05],
}

## Cached material by name; unknown names fall back to white.
static func get_mat(name: String, maps: bool = true) -> StandardMaterial3D:
	var key := "%s|%d" % [name, int(maps)]
	_mutex.lock()
	if _cache.has(key):
		var hit: StandardMaterial3D = _cache[key]
		_mutex.unlock()
		return hit
	_mutex.unlock()
	var m: StandardMaterial3D
	match name:
		"glass":
			m = LandmarkMaterials.glass("#22343f")
		"teak":
			m = StandardMaterial3D.new()
			m.albedo_texture = MaterialLibrary._set_tex("wood", "diff")
			m.albedo_color = LandmarkMaterials.tint("wood", "#8a7860")
			m.uv1_scale = Vector3.ONE * 0.5
			m.roughness = 0.8
			if maps:
				m.normal_texture = MaterialLibrary._set_tex("wood", "nor")
				m.normal_enabled = true
			RoofVariety.mark(m)
		"canvas":
			m = StandardMaterial3D.new()
			m.albedo_color = Color("#e6e3d8")
			m.roughness = 0.92
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"hull_instance":
			# The instance colour paints the topsides (marina fleets).
			m = StandardMaterial3D.new()
			m.albedo_color = Color.WHITE
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.28
			m.metallic = 0.05
		_:
			var spec: Array = PAINTS.get(name, PAINTS["white"])
			m = paint(str(spec[0]), maps, float(spec[1]), float(spec[2]))
			if name in ["white", "cream", "grey_deck"]:
				RoofVariety.mark(m)
	_mutex.lock()
	_cache[key] = m
	_mutex.unlock()
	return m

## Painted sheet metal in `hex` (uncached; callers cache by colour).
static func paint(hex: String, maps: bool = true, rough: float = 0.5, metal: float = 0.05) -> StandardMaterial3D:
	var key := "paint|%s|%d|%.2f|%.2f" % [hex, int(maps), rough, metal]
	_mutex.lock()
	if _cache.has(key):
		var hit: StandardMaterial3D = _cache[key]
		_mutex.unlock()
		return hit
	_mutex.unlock()
	var m := StandardMaterial3D.new()
	m.albedo_texture = MaterialLibrary._set_tex("sheet_metal", "diff")
	m.albedo_color = FacadeMaterials._calib("sheet_metal", MaterialLibrary.parse_colour_tag(hex)).linear_to_srgb()
	m.uv1_scale = Vector3.ONE * 0.25
	m.roughness = rough
	m.metallic = metal
	if maps:
		m.normal_texture = MaterialLibrary._set_tex("sheet_metal", "nor")
		m.normal_enabled = true
	_mutex.lock()
	_cache[key] = m
	_mutex.unlock()
	return m

## Registers the standard marine surface keys on `lm`.
static func register(lm: LandmarkMesh, maps: bool, hull: Material, bottom: Material = null) -> void:
	lm.use("Hull", hull)
	lm.use("Boot", bottom if bottom != null else get_mat("antifoul", maps))
	lm.use("Bottom", bottom if bottom != null else get_mat("antifoul", maps))
	lm.use("Deck", get_mat("teak", maps))
	lm.use("White", get_mat("white", maps))
	lm.use("Glass", get_mat("glass", maps))
	lm.use("Steel", get_mat("steel", maps))
	lm.use("Dark", get_mat("dark", maps))
	lm.use("Canvas", get_mat("canvas", maps))
