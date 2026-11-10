class_name NycTowerLooks
extends RefCounted

## Which kind of tower a tall New York building is: the glazing or masonry
## of its time, from its mapped material and year, then its proportions.
## Sets finish fields only (era stays), so near, far and party-wall paths
## agree. Landmarks keep their own look.

const KINDS := ["commercial", "apartments"]
## Below both of these a building is not a tower.
const MIN_LEVELS := 15
const MIN_HEIGHT_M := 50.0
## Slender supertalls, as the nyc_pencil era rule.
const PENCIL_LEVELS := 55
const PENCIL_AREA_M2 := 850.0
const METAL_TAGS := ["metal", "steel", "aluminium", "aluminum", "metal_plates"]

## Solid towers: wall set, pattern and two hex finishes each.
const SOLID := {
	"postmodern_stone": ["stone", "strip", "#a89a8c", "#8e7f74"],
	"pencil_concrete": ["concrete", "panel", "#d8d6d0", "#c9c7c0"],
	"pencil_limestone": ["limestone", "pier", "#d6cbb6", "#c8bca4"],
	"prewar_buff": ["brick", "pier", "#b89a72", "#a98a64"],
	"prewar_lime": ["limestone", "pier", "#d8ccb0", "#cfc0a0"],
}

## `look` for building `b`, with a tower finish when `b` is one.
static func apply(b: Dictionary, look: Dictionary, area_m2: float, seed_v: float) -> Dictionary:
	if str(look.get("city", "")) != "new_york" or bool(b.get("mapped_landmark", false)) \
			or not (str(look.get("kind", "")) in KINDS) or not _is_tower(b, look):
		return look
	var id := pick(b, look, area_m2, seed_v)
	if id == "":
		return look
	var out := look.duplicate()
	out["tower_look"] = id
	if FacadeCurtainKit.has(id):
		out["curtain"] = id
		out["wall_set"] = "glass"
		out["pattern"] = "curtain"
		out["relief"] = {"mullion": true}
		return out
	var row: Array = SOLID[id]
	out["wall_set"] = row[0]
	out["pattern"] = row[1]
	out["wall_colour"] = ArchitectureStyle._lin(str(row[2 + int(ArchitectureStyle._h(seed_v, 73) * 2.0)]))
	out["relief"] = {"string_course": true}
	return out

static func _is_tower(b: Dictionary, look: Dictionary) -> bool:
	var levels := int(b.get("levels", 0))
	var height := float(b.get("height", 0.0))
	# A part-mapped tower's outline is often a bare footprint (a default
	# height): its parts carry the real height and storeys.
	for part in b.get("parts", []):
		levels = maxi(levels, int((part as Dictionary).get("levels", 0)))
		height = maxf(height, float((part as Dictionary).get("height", 0.0)))
	return levels >= MIN_LEVELS or height >= MIN_HEIGHT_M \
		or int(look.get("storeys", 0)) >= MIN_LEVELS and height <= 0.0

## The tower look id, or "" to keep the era's own finish.
static func pick(b: Dictionary, look: Dictionary, area_m2: float, seed_v: float) -> String:
	var raw := str(b.get("material", "")).strip_edges().to_lower()
	var mapped := str(MaterialLibrary.MATERIAL_TAGS.get(raw, ""))
	var year := int(b.get("start_year", 0))
	var levels := int(b.get("levels", 0))
	var pencil := levels >= PENCIL_LEVELS and area_m2 > 0.0 and area_m2 <= PENCIL_AREA_M2
	var h := ArchitectureStyle._h(seed_v, 71)
	var prewar := str(look.get("era", "")) == "nyc_prewar" or (year > 0 and year < 1946)
	if raw in METAL_TAGS:
		return "silver_reflective"
	match mapped:
		"glass":
			return _glass_of(year, h)
		"concrete":
			return "pencil_concrete" if pencil or year >= 2010 else ""
		"limestone", "stone":
			if prewar:
				return "prewar_lime"
			if pencil or year >= 2010:
				return "pencil_limestone"
			return "postmodern_stone"
		"brick":
			return "prewar_buff" if prewar else ""
		"":
			pass
		_:
			return ""
	if prewar:
		return "prewar_buff" if str(look.get("wall_set", "")) == "brick" else "prewar_lime"
	if year > 0:
		if year >= 1983 and year < 2000 and h < 0.35:
			return "postmodern_stone"
		return _glass_of(year, h)
	if pencil:
		return "clear_fin" if h < 0.6 else ("pencil_concrete" if h < 0.8 else "pencil_limestone")
	if str(look.get("wall_set", "")) != "glass":
		return ""
	return _glass_of(0, h)

## A curtain wall of its time; undated towers spread over the periods.
static func _glass_of(year: int, h: float) -> String:
	if year >= 2013:
		return "clear_fin"
	if year >= 1993:
		return "lowe_blue"
	if year >= 1975:
		return "silver_reflective"
	if year > 0:
		return "intl_bronze"
	if h < 0.35:
		return "lowe_blue"
	if h < 0.6:
		return "silver_reflective"
	return "clear_fin" if h < 0.85 else "intl_bronze"
