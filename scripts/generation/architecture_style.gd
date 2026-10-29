class_name ArchitectureStyle
extends RefCounted

## Regional + typological building style. Answers "what does a building
## of this kind look like in this part of the world" when the map is
## silent: a Finnish apartment block is not a Parisian one, a farm is not
## a warehouse. Real data always wins — OSM `building:material`,
## `building:colour`, `roof:*`, `height`, `building:levels` and the
## satellite roof sample are applied on top by MaterialLibrary and
## BuildingBuilder; this class only supplies the defaults beneath them.
## Tables live in ArchitectureData (reviewable, docs/architecture-styles.md).

const KINDS: Array[String] = ["house", "apartments", "commercial",
	"industrial", "religious", "civic", "farm", "outbuilding"]
## Per-building texture variants (which bays get shutters, blinds, lit
## panes, loggias; Paris pediments/balconettes/fascias). Seeded per
## building so a street is not a row of clones.
const VARIANTS := 3

static var _profile_cache: Dictionary = {}

## Style region for a viewpoint: first matching coarse box, else "generic"
## (the temperate-mixed GENERIC profile).
static func region_for(lat: float, lon: float) -> String:
	for box in ArchitectureData.BOXES:
		var b: Array = box
		if lat >= float(b[1]) and lat <= float(b[3]) \
				and lon >= float(b[2]) and lon <= float(b[4]):
			return str(b[0])
	return "generic"

static func has_region(region: String) -> bool:
	return region == "generic" or ArchitectureData.REGIONS.has(region)

## Building kind from the OSM `building` value, then its `use` hint
## (amenity/shop/...), then levels / footprint area / density for the
## untyped `yes`. area_m2 <= 0 means unknown. Density is dense|mid|rural.
static func kind_for(b: Dictionary, density: String, area_m2: float) -> String:
	var named: String = ArchitectureData.KIND_TAGS.get(
		str(b.get("kind", "")).to_lower(), "")
	if named != "":
		return named
	var used: String = ArchitectureData.USE_TAGS.get(
		str(b.get("use", "")).to_lower(), "")
	if used != "":
		return used
	var levels := int(b.get("levels", 0))
	if area_m2 > 0.0 and area_m2 < 45.0:
		return "outbuilding"
	if levels >= 4:
		return "apartments"
	if levels >= 1 and levels <= 2 and (area_m2 <= 0.0 or area_m2 < 400.0):
		return "house"
	match density:
		"dense":
			return "apartments" if area_m2 >= 100.0 or area_m2 <= 0.0 else "house"
		"rural":
			return "farm" if area_m2 >= 300.0 else "house"
	return "apartments" if area_m2 >= 350.0 else "house"

## Merged kind profile: GENERIC <- BASE chain <- region row (see the key
## legend in ArchitectureData). Cached; callers must not mutate it.
static func profile(region: String, kind: String) -> Dictionary:
	var key := region + "|" + kind
	if _profile_cache.has(key):
		return _profile_cache[key] as Dictionary
	var generic: Dictionary = ArchitectureData.GENERIC
	var merged: Dictionary = (generic.get(kind, generic["house"]) as Dictionary).duplicate()
	var chain: Array[String] = []
	var r := region
	while r != "" and chain.size() < 4:
		chain.push_front(r)
		r = str(ArchitectureData.BASE.get(r, ""))
	for name in chain:
		var kinds: Dictionary = ArchitectureData.REGIONS.get(name, {})
		var row: Dictionary = kinds.get(kind, {})
		for k in row:
			merged[k] = row[k]
	_profile_cache[key] = merged
	return merged

## Deterministic 0..1 value for (seed, salt) — same hash family as
## TerrainBuilder._hash so a building's look never changes between runs.
static func _h(seed_v: float, salt: int) -> float:
	return fposmod(sin(seed_v * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

static func _pick(items: Array, seed_v: float, salt: int) -> Variant:
	return items[int(_h(seed_v, salt) * float(items.size())) % items.size()]

static func _pick_weighted(pairs: Array, seed_v: float, salt: int) -> String:
	var total := 0.0
	for pr in pairs:
		total += float((pr as Array)[1])
	var t := _h(seed_v, salt) * total
	for pr in pairs:
		t -= float((pr as Array)[1])
		if t < 0.0:
			return str((pr as Array)[0])
	return str((pairs[0] as Array)[0])

## sRGB hex -> linear colour (materials tint linear textures).
static func _lin(hex: String) -> Color:
	var c := Color.html(hex)
	c.a = 1.0
	return c.srgb_to_linear()

## One tint from an sRGB hex palette, or alpha 0 when the palette is
## empty (keep the photo's own colour).
static func _tint(palette: Array, seed_v: float, salt: int) -> Color:
	if palette.is_empty():
		return Color(0, 0, 0, 0)
	return _lin(str(_pick(palette, seed_v, salt)))

## The full look of one building: wall/roof finish, window pattern,
## roof shape default, storeys, and the detail probabilities BuildingDetail
## rolls against. `b` is the §2.4 building dict (kind/use/levels/religion
## tags); seed_v is the building's stable 0..1 hash.
static func resolve(b: Dictionary, region: String, density: String,
		seed_v: float, area_m2: float) -> Dictionary:
	var kind := kind_for(b, density, area_m2)
	var p := profile(region, kind)
	var wall: Array = _pick(p["w"] as Array, seed_v, 1)
	var roof: Array = _pick(p["rf"] as Array, seed_v, 4)
	var shape := _pick_weighted(p["r"] as Array, seed_v, 3)
	var pattern := _pattern_of(p, seed_v, 13)
	if str(wall[0]) == "glass":
		pattern = "curtain"
	elif str(wall[0]) == "wood" and pattern in ["strip", "balcony", "tiles"]:
		pattern = "clapboard"
	var ground := _ground_of(p, kind, density, seed_v)
	var st: Array = p["st"]
	var lo := int(st[0])
	var hi := int(st[1])
	if kind == "apartments" or kind == "commercial":
		if density == "dense":
			lo += 1
			hi = int(ceil(float(hi) * 1.5))
		elif density == "rural":
			lo = maxi(1, lo - 1)
			hi = maxi(lo, hi - 2)
	var storeys := lo + int(_h(seed_v, 5) * float(hi - lo + 1))
	var fh := float(p["fh"])
	var rise := 0.0 if shape == "flat" else clampf(2.4 * float(p["pitch"]), 1.2, 4.0)
	return {
		"region": region, "kind": kind,
		"wall_set": str(wall[0]), "wall_colour": _tint(wall[1] as Array, seed_v, 2),
		"pattern": pattern, "bay_m": float(p["bay"]),
		"frame": _lin(str(p["fr"])), "shutter": _lin(str(p["sh"])),
		"shutter_p": float(p["sp"]),
		"roof_shape": shape, "pitch": float(p["pitch"]),
		"roof_set": str(roof[0]), "roof_colour": _tint(roof[1] as Array, seed_v, 6),
		"floor_h": fh, "storeys": storeys, "default_h": float(storeys) * fh + rise,
		"chimney": float(p["ch"]), "dormer": float(p.get("dm", 0.0)),
		"equip": float(p.get("eq", 0.0)),
		"tower": _tower(p, b),
		"window": str(p.get("wn", "casement")), "rails": float(p.get("rl", 0.0)),
		"ground": ground, "ground_colour": _tint(p.get("gc", []) as Array, seed_v, 15),
		"eave": float(p.get("ev", 0.3)),
		"variant": int(_h(seed_v, 14) * float(VARIANTS)) % VARIANTS,
	}

## Window pattern: a plain id, or weighted [[id, weight], ...] so a street
## mixes punched, balcony and ribbon fronts the way real ones do.
static func _pattern_of(p: Dictionary, seed_v: float, salt: int) -> String:
	var v: Variant = p["p"]
	if v is Array:
		return _pick_weighted(v as Array, seed_v, salt)
	return str(v)

## Ground-storey treatment ("" none, shop, signage, render, stone) from
## the profile's weighted `g` list. Shops need a street: rural apartment
## blocks and houses outside dense cores keep a plain ground floor.
static func _ground_of(p: Dictionary, kind: String, density: String,
		seed_v: float) -> String:
	var g: Variant = p.get("g", [])
	if not (g is Array) or (g as Array).is_empty():
		return ""
	var pick := _pick_weighted(g as Array, seed_v, 16)
	if pick in ["shop", "signage"] and density == "rural" and kind != "commercial":
		return ""
	return "" if pick == "none" else pick

## Religious tower from the building's own religion/denomination tags
## (real data) over the regional default.
static func _tower(p: Dictionary, b: Dictionary) -> String:
	var regional := str(p.get("tw", ""))
	var religion := str(b.get("religion", "")).to_lower()
	var denomination := str(b.get("denomination", "")).to_lower()
	match religion:
		"muslim":
			return "minaret"
		"buddhist":
			return "pagoda"
		"hindu", "sikh":
			return "shikhara"
		"jewish", "shinto":
			return ""
		"christian":
			if denomination.contains("orthodox"):
				return "onion"
			if regional in ["minaret", "pagoda", "shikhara", ""]:
				return "spire"
	return regional

## Shared look for the distant-block materials (PRD §6 keeps those at 4
## walls + 2 roofs per place): the region's apartment fabric. Tints are
## linear colours with alpha 0 when the palette is the photo's own.
static func distant_look(region: String) -> Dictionary:
	var p := profile(region, "apartments")
	var walls: Array = p["w"]
	var wall: Array = walls[0]
	for w in walls:
		if str((w as Array)[0]) != "glass":
			wall = w
			break
	var tints: Array = []
	for i in 4:
		tints.append(_tint(wall[1] as Array, float(i) * 1.7 + 0.3, 9))
	var roofs: Array = p["rf"]
	var roof: Array = roofs[0]
	return {"wall_set": str(wall[0]), "tints": tints,
		"pattern": _distant_pattern(p, str(wall[0])), "bay_m": float(p["bay"]),
		"frame": _lin(str(p["fr"])), "shutter": _lin(str(p["sh"])),
		"shutter_p": float(p["sp"]), "window": str(p.get("wn", "casement")),
		"rails": float(p.get("rl", 0.0)), "variant": 0,
		"roof_set": str(roof[0]), "roof_colours": [_tint(roof[1] as Array, 0.4, 10),
			_tint(roof[1] as Array, 2.1, 10)]}

## The distant blocks' single pattern: the heaviest-weighted one.
static func _distant_pattern(p: Dictionary, wall_set: String) -> String:
	var v: Variant = p["p"]
	var out := str(v)
	if v is Array:
		var best := -1.0
		for pr in (v as Array):
			if float((pr as Array)[1]) > best:
				best = float((pr as Array)[1])
				out = str((pr as Array)[0])
	if wall_set == "wood" and out in ["strip", "balcony", "tiles"]:
		out = "clapboard"
	return out

## Kind for a procedural infill building (OSM silent): the region's mix.
static func infill_kind(region: String, seed_v: float) -> String:
	var mix: Dictionary = ArchitectureData.INFILL_MIX.get(region, ArchitectureData.INFILL_DEFAULT)
	var pairs: Array = []
	for k in mix:
		pairs.append([k, mix[k]])
	return _pick_weighted(pairs, seed_v, 7)

## Footprint (metres, width x depth) for a procedural building of a kind.
static func infill_size_m(kind: String, a: float, b: float) -> Vector2:
	match kind:
		"apartments":
			return Vector2(lerpf(16.0, 34.0, a), lerpf(11.0, 15.0, b))
		"commercial":
			return Vector2(lerpf(14.0, 32.0, a), lerpf(12.0, 22.0, b))
		"industrial":
			return Vector2(lerpf(22.0, 44.0, a), lerpf(16.0, 28.0, b))
		"civic":
			return Vector2(lerpf(18.0, 34.0, a), lerpf(14.0, 24.0, b))
		"farm":
			return Vector2(lerpf(14.0, 30.0, a), lerpf(9.0, 14.0, b))
		"outbuilding":
			return Vector2(lerpf(4.0, 9.0, a), lerpf(3.0, 6.0, b))
	return Vector2(lerpf(8.0, 13.0, a), lerpf(7.0, 11.0, b))

## Religious-landmark look for LandmarkBuilder archetypes (church, mosque,
## temple...): regional stone/roof colours and the tower silhouette.
static func religious_look(region: String) -> Dictionary:
	var p := profile(region, "religious")
	var wall: Array = (p["w"] as Array)[0]
	var roof: Array = (p["rf"] as Array)[0]
	return {"stone": _tint(wall[1] as Array, 0.5, 11), "roof": _tint(roof[1] as Array, 0.5, 12),
		"tower": str(p.get("tw", "spire")), "pitch": float(p["pitch"])}
