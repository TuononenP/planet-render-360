class_name TowerLooks
extends RefCounted

## High-rise finishes outside New York (NycTowerLooks has its own tables): a
## glazed tower takes a glazing type common to its region, and any modern
## tall tower earns the plant floors and skyline top. Mapped finishes that are
## not glass stay as mapped. Sets finish fields only; era stays.

const GULF := ["gulf", "arab", "dubai", "doha", "riyadh", "abu_dhabi", "mideast", "kuwait"]
const ASIA := ["east_asia", "japan", "tokyo", "shanghai", "seoul", "hong_kong", "singapore", "se_asia", "beijing", "bangkok", "kuala"]
const EUROPE := ["europe", "london", "paris", "nordic", "frankfurt", "haussmann", "mediterranean", "alpine", "berlin", "madrid", "stockholm", "helsinki"]

## [glazing id, cumulative share] by region family.
const PALETTES := {
	"gulf": [["gold_reflective", 0.30], ["silver_reflective", 0.60], ["lowe_blue", 0.85], ["clear_fin", 1.0]],
	"asia": [["lowe_blue", 0.35], ["green_glass", 0.60], ["clear_fin", 0.85], ["silver_reflective", 1.0]],
	"europe": [["clear_fin", 0.50], ["lowe_blue", 0.80], ["intl_bronze", 1.0]],
}

## `look` for building `b`, with a tower finish when `b` is a modern tower.
static func apply(b: Dictionary, look: Dictionary, seed_v: float) -> Dictionary:
	if look.has("tower_look") or bool(b.get("mapped_landmark", false)) \
			or not (str(look.get("kind", "")) in NycTowerLooks.KINDS) or not NycTowerLooks._is_tower(b, look):
		return look
	var tag := str(b.get("material", "")).strip_edges().to_lower()
	var mapped := str(MaterialLibrary.MATERIAL_TAGS.get(tag, ""))
	if mapped != "" and mapped != "glass":
		return look
	var out := look.duplicate()
	if mapped == "glass" or str(look.get("wall_set", "")) == "glass":
		var id := glazing(look, int(b.get("start_year", 0)), ArchitectureStyle._h(seed_v, 72))
		out["tower_look"] = id
		out["curtain"] = id
		out["wall_set"] = "glass"
		out["pattern"] = "curtain"
		out["relief"] = {"mullion": true}
	else:
		out["tower_look"] = "solid"
	return out

## The region's glazing at share `h`; recent towers lean to clear glass.
static func glazing(look: Dictionary, year: int, h: float) -> String:
	var family := _family(str(look.get("region", "")), str(look.get("city", "")))
	if family == "":
		return NycTowerLooks._glass_of(year, h)
	if year >= 2013 and h < 0.4:
		return "clear_fin"
	for row in PALETTES[family]:
		if h <= float((row as Array)[1]):
			return str((row as Array)[0])
	return "clear_fin"

static func _family(region: String, city: String) -> String:
	for key in GULF:
		if key in region or key in city:
			return "gulf"
	for key in ASIA:
		if key in region or key in city:
			return "asia"
	for key in EUROPE:
		if key in region or key in city:
			return "europe"
	return ""
