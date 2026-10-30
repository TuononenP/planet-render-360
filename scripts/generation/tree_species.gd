class_name TreeSpecies
extends RefCounted

## Species table + climate/land-cover species mix for T5.1 vegetation.
## Every size is in true metres (scaled by WorldScale.metres_to_units()
## at instancing), so trees are right before and after the metre
## cutover. Geometry generators live in TreeMeshLibrary.
##
## gen "broad": trunk + main/secondary branches + leaf-card clusters on
##   a crown ellipsoid (bole = clear-trunk fraction, crown_r = crown
##   radius / height, leader = how far the trunk runs into the crown,
##   up = branch elevation bias, droop = tip droop).
## gen "conifer": whorls of drooping branch cards on a cone/column.
## gen "palm": curved ringed trunk + arching V-folded fronds.

const SPECIES := {
	"plane": {"gen": "broad", "h": 20.0, "h_var": 0.25, "bole": 0.30, "crown_r": 0.33,
		"leader": 0.35, "branches": 7, "trunk_r": 0.34, "up": 0.55, "droop": 0.0,
		"clusters": 58, "card": 3.4, "leaf": "broad", "bark": "plane",
		"tint": "broad", "evergreen": false},
	"lime": {"gen": "broad", "h": 18.0, "h_var": 0.2, "bole": 0.22, "crown_r": 0.27,
		"leader": 0.8, "branches": 9, "trunk_r": 0.30, "up": 0.6, "droop": 0.15,
		"clusters": 62, "card": 3.0, "leaf": "broad", "bark": "furrowed",
		"tint": "lime", "evergreen": false},
	"oak": {"gen": "broad", "h": 17.0, "h_var": 0.25, "bole": 0.22, "crown_r": 0.42,
		"leader": 0.25, "branches": 6, "trunk_r": 0.45, "up": 0.35, "droop": 0.05,
		"clusters": 60, "card": 3.4, "leaf": "broad", "bark": "furrowed",
		"tint": "oak", "evergreen": false},
	"birch": {"gen": "broad", "h": 16.0, "h_var": 0.25, "bole": 0.25, "crown_r": 0.19,
		"leader": 0.95, "branches": 11, "trunk_r": 0.17, "up": 0.65, "droop": 0.55,
		"clusters": 52, "card": 2.2, "leaf": "birch", "bark": "birch",
		"tint": "birch", "evergreen": false},
	"olive": {"gen": "broad", "h": 7.0, "h_var": 0.2, "bole": 0.28, "crown_r": 0.48,
		"leader": 0.2, "branches": 5, "trunk_r": 0.28, "up": 0.45, "droop": 0.1,
		"clusters": 40, "card": 2.2, "leaf": "olive", "bark": "furrowed",
		"tint": "olive", "evergreen": true},
	"tropical": {"gen": "broad", "h": 16.0, "h_var": 0.3, "bole": 0.35, "crown_r": 0.45,
		"leader": 0.3, "branches": 7, "trunk_r": 0.32, "up": 0.4, "droop": 0.05,
		"clusters": 60, "card": 3.4, "leaf": "broad", "bark": "plane",
		"tint": "tropical", "evergreen": true},
	"scots_pine": {"gen": "broad", "h": 21.0, "h_var": 0.2, "bole": 0.62, "crown_r": 0.17,
		"leader": 0.85, "branches": 9, "trunk_r": 0.28, "up": 0.3, "droop": 0.0,
		"clusters": 40, "card": 2.4, "leaf": "pine", "bark": "pine",
		"tint": "pine", "evergreen": true},
	"stone_pine": {"gen": "broad", "h": 14.0, "h_var": 0.2, "bole": 0.58, "crown_r": 0.52,
		"leader": 0.15, "branches": 7, "trunk_r": 0.32, "up": 0.75, "droop": 0.0,
		"clusters": 48, "card": 2.8, "leaf": "pine", "bark": "pine",
		"tint": "pine", "evergreen": true, "flat_top": true},
	"spruce": {"gen": "conifer", "h": 25.0, "h_var": 0.25, "crown_base": 0.05,
		"base_r": 0.18, "whorl": 0.85, "per_whorl": 6, "pitch": -0.12, "droop": 0.35,
		"trunk_r": 0.32, "leaf": "needle", "bark": "spruce", "tint": "spruce",
		"evergreen": true, "column": false},
	"cypress": {"gen": "conifer", "h": 14.0, "h_var": 0.2, "crown_base": 0.04,
		"base_r": 0.1, "whorl": 0.5, "per_whorl": 5, "pitch": 1.0, "droop": 0.0,
		"trunk_r": 0.2, "leaf": "cypress", "bark": "furrowed", "tint": "cypress",
		"evergreen": true, "column": true},
	"palm": {"gen": "palm", "h": 11.0, "h_var": 0.3, "fronds": 15, "frond_len": 4.2,
		"trunk_r": 0.22, "leaf": "palm", "bark": "palm", "tint": "palm",
		"evergreen": true},
}

## Season tints (sRGB), applied over the near-neutral leaf atlases:
## [spring, summer, autumn, winter]. Winter on deciduous species is the
## bare-branch mesh, so its entry is the evergreen winter shade.
const TINTS := {
	"broad": [Color(0.50, 0.66, 0.30), Color(0.36, 0.50, 0.24), Color(0.86, 0.56, 0.22), Color(0.3, 0.4, 0.22)],
	"lime": [Color(0.54, 0.70, 0.30), Color(0.38, 0.54, 0.24), Color(0.90, 0.74, 0.28), Color(0.3, 0.4, 0.22)],
	"oak": [Color(0.52, 0.64, 0.30), Color(0.33, 0.46, 0.22), Color(0.70, 0.46, 0.20), Color(0.3, 0.4, 0.22)],
	"birch": [Color(0.58, 0.74, 0.32), Color(0.44, 0.60, 0.26), Color(0.95, 0.80, 0.28), Color(0.3, 0.4, 0.22)],
	"olive": [Color(0.52, 0.58, 0.42), Color(0.48, 0.54, 0.38), Color(0.48, 0.53, 0.38), Color(0.45, 0.50, 0.37)],
	"tropical": [Color(0.30, 0.50, 0.20), Color(0.27, 0.46, 0.18), Color(0.30, 0.46, 0.20), Color(0.27, 0.44, 0.18)],
	"pine": [Color(0.34, 0.46, 0.25), Color(0.30, 0.42, 0.22), Color(0.30, 0.41, 0.22), Color(0.26, 0.36, 0.21)],
	"spruce": [Color(0.24, 0.37, 0.22), Color(0.21, 0.34, 0.20), Color(0.21, 0.33, 0.20), Color(0.19, 0.29, 0.19)],
	"cypress": [Color(0.24, 0.37, 0.20), Color(0.22, 0.35, 0.19), Color(0.22, 0.34, 0.19), Color(0.20, 0.31, 0.18)],
	"palm": [Color(0.40, 0.54, 0.25), Color(0.38, 0.52, 0.24), Color(0.40, 0.52, 0.25), Color(0.38, 0.50, 0.24)],
}

## Bark colour behind impostor bark pixels (impostors store luminance).
const BARK_TINT := {
	"plane": Color(0.62, 0.60, 0.48), "furrowed": Color(0.40, 0.35, 0.30),
	"pine": Color(0.55, 0.36, 0.24), "birch": Color(0.80, 0.79, 0.75),
	"spruce": Color(0.38, 0.30, 0.25), "palm": Color(0.48, 0.42, 0.33),
}

static func names() -> Array:
	return SPECIES.keys()

static func spec(name: String) -> Dictionary:
	return SPECIES.get(name, SPECIES["lime"])

static func is_evergreen(name: String) -> bool:
	return bool(spec(name).get("evergreen", false))

static func tint(name: String, season: int) -> Color:
	var row: Array = TINTS.get(str(spec(name).get("tint", "broad")), TINTS["broad"])
	return row[LocationData.clamp_season(season)]

## Biome for a place: coarse climate from the architecture region,
## latitude, and the viewpoint altitude (metres ASL).
## Biome for a place: the CHELSA climate class (ClimateModel) where the
## climate is known, keeping the regional species flavour where climate
## and region agree it is temperate (alpine / east Asian mixes); the
## regional + latitude rule below otherwise.
static func biome_for_data(data: LocationData) -> String:
	var regional := biome_for(data.latitude, data.longitude, data.centre_elevation_m)
	var climatic := ClimateModel.biome(data)
	if climatic == "":
		return regional
	if climatic == "temperate" and regional in ["alpine", "east_asia"]:
		return regional
	# Summer-dry climates outside the Mediterranean basin (California,
	# central Chile, the Cape, SW Australia): live oak, pine and cypress
	# rather than the olive / stone pine / palm of the Old World mix.
	if climatic == "mediterranean" and regional not in ["mediterranean", "arid"]:
		return "dry_coast"
	return climatic

static func biome_for(lat: float, lon: float, altitude_m: float) -> String:
	var region := ArchitectureStyle.region_for(lat, lon)
	var alat := absf(lat)
	if alat < 23.5 or (region == "southeast_asia" and alat < 18.0):
		return "tropical"
	if region == "alpine" or altitude_m > 900.0:
		return "alpine"
	if region == "nordic" or alat > 58.0:
		return "boreal"
	if region in ["east_asia", "japan"]:
		return "east_asia"
	if region == "middle_east":
		return "arid"
	if region == "mediterranean" or alat < 36.0:
		return "mediterranean"
	return "temperate"

## Weighted species mix for a biome + setting ("street" = OSM tree
## nodes/parks in a built-up place, "forest", "park", "rural").
static func mix(biome: String, setting: String) -> Array:
	match biome:
		"tropical":
			return [["palm", 0.45], ["tropical", 0.55]]
		"arid":
			return [["palm", 0.4], ["olive", 0.3], ["cypress", 0.2], ["plane", 0.1]]
		"mediterranean":
			if setting == "forest":
				return [["stone_pine", 0.45], ["olive", 0.15], ["oak", 0.25], ["cypress", 0.15]]
			if setting == "street":
				return [["plane", 0.55], ["lime", 0.1], ["stone_pine", 0.15], ["palm", 0.1], ["cypress", 0.1]]
			return [["stone_pine", 0.3], ["olive", 0.25], ["cypress", 0.2], ["plane", 0.15], ["palm", 0.1]]
		"dry_coast":
			if setting == "forest":
				return [["oak", 0.45], ["scots_pine", 0.3], ["cypress", 0.15], ["spruce", 0.1]]
			if setting == "street":
				return [["plane", 0.35], ["oak", 0.25], ["palm", 0.15], ["cypress", 0.15], ["lime", 0.1]]
			return [["oak", 0.45], ["scots_pine", 0.25], ["cypress", 0.2], ["plane", 0.1]]
		"boreal":
			if setting == "forest":
				return [["spruce", 0.42], ["scots_pine", 0.33], ["birch", 0.25]]
			if setting == "street":
				return [["lime", 0.4], ["birch", 0.35], ["plane", 0.1], ["spruce", 0.15]]
			return [["birch", 0.4], ["spruce", 0.25], ["scots_pine", 0.2], ["lime", 0.15]]
		"alpine":
			if setting == "forest":
				return [["spruce", 0.65], ["scots_pine", 0.1], ["lime", 0.15], ["birch", 0.1]]
			if setting == "street":
				return [["lime", 0.45], ["plane", 0.2], ["oak", 0.1], ["birch", 0.1], ["spruce", 0.15]]
			return [["spruce", 0.4], ["lime", 0.25], ["oak", 0.15], ["birch", 0.2]]
		"east_asia":
			if setting == "street":
				return [["plane", 0.45], ["lime", 0.3], ["scots_pine", 0.15], ["oak", 0.1]]
			return [["oak", 0.3], ["lime", 0.25], ["scots_pine", 0.25], ["spruce", 0.2]]
	if setting == "forest":
		return [["oak", 0.35], ["lime", 0.2], ["spruce", 0.2], ["scots_pine", 0.1], ["birch", 0.15]]
	if setting == "street":
		return [["plane", 0.5], ["lime", 0.3], ["oak", 0.1], ["birch", 0.1]]
	return [["oak", 0.3], ["lime", 0.3], ["plane", 0.2], ["birch", 0.2]]

## Deterministic weighted pick (u in [0, 1)).
static func pick(mix_rows: Array, u: float) -> String:
	var total := 0.0
	for r in mix_rows:
		total += float(r[1])
	var acc := 0.0
	for r in mix_rows:
		acc += float(r[1]) / total
		if u < acc:
			return str(r[0])
	return str(mix_rows[mix_rows.size() - 1][0])

## Altitude response: above the local treeline nothing grows; within
## 300 m below it conifers dominate and shrink.
static func treeline_m(lat: float) -> float:
	var alat := absf(lat)
	return clampf(2300.0 - maxf(alat - 40.0, 0.0) * 55.0, 600.0, 3900.0)
