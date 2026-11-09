class_name FacadeTextures
extends RefCounted

## Distant-facade sets, glass and facade texture/material creation
## for FacadeMaterials. Look selection stays in FacadeMaterials;
## this class builds the shared distant materials and textures.
static func distant_facades(fidelity: int, region: String = "") -> Array:
	var look := _distant_look(region)
	var cls := (1 if fidelity <= 1 else 2)
	var key := "%d|%s" % [cls, region if not look.is_empty() else ""]
	if FacadeMaterials._distant_mats.has(key):
		return FacadeMaterials._distant_mats[key] as Array
	var detail := 0 if cls == 1 else 1
	var out: Array = []
	if look.is_empty():
		for i in 4:
			out.append(_facade_material_for("limestone", 6, detail,
				FacadeMaterials.LIMESTONE_TINTS[[0, 1, 4, 3][i]] * FacadeMaterials._limestone_calib()))
	else:
		var set_name := str(look["wall_set"])
		for c in (look["tints"] as Array):
			var col: Color = c
			var tint := Color.WHITE
			if col.a > 0.0:
				tint = FacadeMaterials._calib(set_name, col)
			out.append(_facade_material_for(set_name, 6, detail, tint,
				str(look["pattern"]), look))
	FacadeMaterials._distant_mats[key] = out
	return out

static func _distant_look(region: String) -> Dictionary:
	if region == "" or MaterialLibrary.REGION_MATERIALS.has(region) \
			or not ArchitectureStyle.has_region(region):
		return {}
	var look := ArchitectureStyle.distant_look(region)
	if str(look["pattern"]) == "haussmann":
		return {}
	return look

## The 2 shared distant roofs per region (two regional tints, or a
## slate/membrane pair for the legacy regions). Albedo-only at F1.
static func distant_roofs(region: String, fidelity: int = 2) -> Array:
	var look := _distant_look(region)
	var legacy := region
	if not MaterialLibrary.REGION_MATERIALS.has(legacy):
		legacy = "urban"
	var cls := (region if not look.is_empty() else legacy) \
		+ ("|1" if fidelity <= 1 else "|2")
	if FacadeMaterials._distant_roof_mats.has(cls):
		return FacadeMaterials._distant_roof_mats[cls] as Array
	var detail := 0 if fidelity <= 1 else 1
	var out: Array = []
	if look.is_empty():
		var first := str((MaterialLibrary.REGION_MATERIALS[legacy] as Dictionary)["roof"])
		var second := "slate" if first != "slate" else "membrane"
		out = [FacadeMaterials.roof_set_material(first, FacadeMaterials.roof_base_tint(first), detail),
			FacadeMaterials.roof_set_material(second, FacadeMaterials.roof_base_tint(second), detail)]
	else:
		var set_name := str(look["roof_set"])
		for c in (look["roof_colours"] as Array):
			var col: Color = c
			var tint := FacadeMaterials.roof_base_tint(set_name)
			if col.a > 0.0:
				tint = FacadeMaterials._roof_floor(set_name, FacadeMaterials._keep_chroma(set_name, FacadeMaterials._calib(set_name, col)))
			out.append(FacadeMaterials.roof_set_material(set_name, tint, detail))
	FacadeMaterials._distant_roof_mats[cls] = out
	return out

## Procedural glass curtain wall (no CC0 photographic glass exists
## upstream): sky-reflective blue-grey panes, aluminium mullions and
## spandrels, low pane roughness; tier depth like the other facades.
static func glass_material(detail: int = 1) -> StandardMaterial3D:
	detail = clampi(detail, 0, 2)
	if FacadeMaterials._glass_mats.has(detail):
		return FacadeMaterials._glass_mats[detail] as StandardMaterial3D
	var m := _facade_material_for("glass", 0, detail, Color.WHITE)
	FacadeMaterials._glass_mats[detail] = m
	return m

# --- Texture composition + material assembly ---

## Composed facade textures for one set + pattern + rows + tier detail,
## cached and bounded. detail: 0 albedo-only (F1 distant), 1 full PBR,
## 2 full PBR + recess AO and deeper bevels (F3). Tiled patterns ignore
## `rows` and read `look` (frame/shutter colours, window vocabulary,
## variant).
static func facade_texs(set_name: String, rows: int, detail: int,
		pattern: String = "haussmann", look: Dictionary = {}) -> Dictionary:
	var tiled := FacadeComposer.is_tiled(pattern)
	if set_name == "glass" and not tiled:
		rows = 0
	elif not tiled:
		rows = clampi(rows, 1, 8)
	if set_name != "glass" and not MaterialLibrary.PBR_SETS.has(set_name):
		set_name = "limestone"
	detail = clampi(detail, 0, 2)
	var variant := int(look.get("variant", 0))
	var key := "%s|%d|%d|%d" % [set_name, rows, detail, variant]
	if tiled:
		key = "%s|%s|%d|%s|%d" % [set_name, pattern, detail, FacadeMaterials._look_key(look), variant]
	if FacadeMaterials._facade_texs.has(key):
		return FacadeMaterials._facade_texs[key] as Dictionary
	if FacadeMaterials._facade_texs.size() >= FacadeMaterials.TEX_CAP:
		for k in FacadeMaterials._facade_texs:
			if str(k).begins_with(set_name + "|" + (pattern + "|" if tiled else "")):
				return FacadeMaterials._facade_texs[k] as Dictionary
		# The fallback itself may exceed the cap by this one entry; refusing
		# it would recurse forever in a city with no limestone cached yet.
		if key != "limestone|6|1|0":
			return facade_texs("limestone", 6, 1)
	var loader := Callable(MaterialLibrary, "_set_image")
	var d: Dictionary
	if tiled:
		d = composed(["tile", set_name, pattern, detail, look], func() -> Dictionary:
			return FacadeComposer.compose_tile(set_name, pattern, detail, look, loader))
	elif set_name == "glass":
		d = composed(["glass", detail], func() -> Dictionary:
			return StoreyComposer.compose_glass(detail))
	else:
		d = composed(["storeys", set_name, rows, detail, variant], func() -> Dictionary:
			return StoreyComposer.compose_haussmann(set_name, rows, detail, loader, variant))
	FacadeMaterials._facade_texs[key] = d
	return d

## Composed facade textures kept from the last build, keyed by the exact
## composer inputs. The per-build caches key by rounded values (the first
## request decides) and are cleared per build, so this sits under them:
## a season or preset rebuild, or the next place, reuses compositions
## whose inputs are identical, so the pixels are too. end_build keeps
## only what that build used, which its world references anyway.
static var _store := {}
static var _store_used := {}

static func composed(inputs: Array, make: Callable) -> Dictionary:
	var k := var_to_str(inputs)
	_store_used[k] = true
	if _store.has(k):
		return _store[k] as Dictionary
	var d: Dictionary = make.call()
	_store[k] = d
	return d

static func end_build() -> void:
	for k in _store.keys():
		if not _store_used.has(k):
			_store.erase(k)
	_store_used.clear()

static func _material_from(texs: Dictionary, set_name: String, detail: int,
		tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = texs["albedo"] as Texture2D
	# `tint` is linear; albedo_color is sRGB-decoded (as pbr_material).
	m.albedo_color = tint.linear_to_srgb()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if set_name == "glass":
		# Dark albedo, strong reflection: glass is mostly what it mirrors.
		m.metallic = 0.6
		m.metallic_specular = 0.7
	else:
		m.metallic = float((MaterialLibrary.PBR_SETS[set_name] as Dictionary)["metal"])
	if detail >= 1 and texs["normal"] != null:
		m.normal_texture = texs["normal"] as Texture2D
		m.roughness_texture = texs["rough"] as Texture2D
		m.roughness = 1.0
	else:
		m.roughness = 0.3 if set_name == "glass" else 0.9
	# Frames, glass and mouldings paint over the tinted wall in their own
	# colours (FacadePaint); the detail normal is the facade's own, so
	# painted bevels keep their relief.
	if texs.get("paint") is Texture2D:
		m.detail_enabled = true
		m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		m.detail_albedo = texs["paint"] as Texture2D
		if m.normal_texture != null:
			m.detail_normal = m.normal_texture
	CityLights.mark(m, texs.get("emit"))
	WallVariety.mark(m)  # per-building tint + foot shade
	m.set_meta("facade_set", set_name)  # FacadeShader swaps these on Ultra
	return m

static func _facade_material_for(set_name: String, rows: int, detail: int,
		tint: Color, pattern: String = "haussmann",
		look: Dictionary = {}) -> StandardMaterial3D:
	var texs := facade_texs(set_name, rows, detail, pattern, look)
	var m := _material_from(texs, set_name, detail, tint)
	var tiled := FacadeComposer.is_tiled(pattern)
	var bay_m := maxf(float(look.get("bay_m", 3.2)), 1.0)
	var floor_m := float(look.get("floor_h", 3.3))
	m.set_meta("facade_rows", rows)
	m.set_meta("facade_floor_m", floor_m)
	m.set_meta("facade_pattern", pattern)
	if not look.is_empty():
		m.set_meta("fc_uv", Vector3(bay_m,
			float(FacadeComposer.BAYS if tiled else StoreyComposer.PARIS_BAYS),
			1.0 if tiled else 0.0))
	# One texture spans BAYS bays × one storey (tiled) or the Paris bays
	# × the whole wall (rows storeys).
	set_recess(m, texs.get("depth"), bay_m * float(FacadeComposer.BAYS if tiled else StoreyComposer.PARIS_BAYS),
		floor_m * (1.0 if tiled else float(rows)))
	return m

## Window reveals (Ultra, composed depth map): deep parallax sets the
## glass RECESS_M behind the wall face. Godot shifts UVs by up to
## heightmap_scale × 0.01 at full depth, so the scale is the reveal over
## the texture's span in metres (geometric mean of its width and height:
## one scale serves both axes).
const RECESS_M := 0.25

static func set_recess(m: StandardMaterial3D, depth: Variant, u_m: float, v_m: float) -> void:
	if not (depth is Texture2D):
		return
	m.heightmap_enabled = true
	m.heightmap_texture = depth as Texture2D
	m.heightmap_deep_parallax = true
	m.heightmap_min_layers = 8
	m.heightmap_max_layers = 32
	m.heightmap_scale = RECESS_M / sqrt(maxf(u_m * v_m, 1.0)) * 100.0

## UV mapping of a style-resolved facade for BuildingBuilder._walls:
## x = metres per window bay, y = bays per texture width, z = 1 when one
## storey tiles vertically (tiled patterns) and 0 when rows already span
## the wall height (Paris). Zero for the legacy one-texture-per-wall
## materials.
static func facade_uv(mat: Material) -> Vector3:
	if mat != null and mat.has_meta("fc_uv"):
		return mat.get_meta("fc_uv") as Vector3
	return Vector3.ZERO
