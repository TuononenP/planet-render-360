class_name HeritageZones
extends RefCounted

## Protected archaeological areas where the map's untagged footprints are
## not a town: the monastery halls, stalls and guard posts inside the
## Angkor park stay one or two storeys and never turn into apartment
## blocks, and footprints of the stone monuments the landmark models
## draw (a `historic` gate or ruin) give way to those models.
## Zones are lat/lon boxes, outermost first; a point inside several takes
## the outer rules overlaid by the inner ones. Rule keys:
##   max_storeys      cap on an inferred (untagged) height, in storeys
##   no_kinds         inferred kinds that become a house (or a hut)
##   drop_historic    drop footprints with any `historic` tag
##   no_archetype     OSM temple candidates build no generic model here
##   religious_tower  false: no pagoda / spire on a religious building
##   tree_keep        share of canopy-raster trees kept (open woodland)
##   tree_mix         TreeSpecies mix name for the zone's trees
##   ground           "wild": park grass reads as unmown meadow

const ZONES := [
	{"id": "angkor_park", "lat": [13.395, 13.480], "lon": [103.800, 103.960],
		"rules": {"max_storeys": 2, "no_kinds": ["apartments", "commercial", "office", "farm"],
			"no_archetype": true, "religious_tower": false,
			"tree_keep": 0.45, "tree_mix": "khmer", "ground": "wild"}},
	# The moat-bounded island of Angkor Wat (its outer wall plus the berm).
	{"id": "angkor_wat_island", "lat": [13.40839, 13.41655], "lon": [103.86144, 103.87170],
		"rules": {"max_storeys": 1, "drop_historic": true, "tree_keep": 0.35}},
	# Angkor Thom, the 3 km walled city round the Bayon.
	{"id": "angkor_thom", "lat": [13.4276, 13.4547], "lon": [103.8451, 103.8728],
		"rules": {"max_storeys": 1, "drop_historic": true}},
]

## Merged rules at (lat, lon); empty outside every zone.
static func rule_at(lat: float, lon: float) -> Dictionary:
	var out := {}
	for z in ZONES:
		var la: Array = z["lat"]
		var lo: Array = z["lon"]
		if lat >= float(la[0]) and lat <= float(la[1]) and lon >= float(lo[0]) and lon <= float(lo[1]):
			out.merge(z["rules"] as Dictionary, true)
	return out

## Merged rules at local metre (x, z) of `data` (viewpoint at the origin).
static func rule_at_xz(data: LocationData, x: float, z: float) -> Dictionary:
	var ll := WorldScale.latlon_from_xz(x, z, data.latitude, data.longitude)
	return rule_at(ll.x, ll.y)

## True when any zone overlaps a `radius_m` box round (lat, lon): the
## cheap gate that keeps every other place on its untouched path.
static func near(lat: float, lon: float, radius_m: float) -> bool:
	var dlat := radius_m / 110540.0
	var dlon := radius_m / (111320.0 * maxf(cos(deg_to_rad(lat)), 0.01))
	for z in ZONES:
		var la: Array = z["lat"]
		var lo: Array = z["lon"]
		if lat + dlat >= float(la[0]) and lat - dlat <= float(la[1]) \
				and lon + dlon >= float(lo[0]) and lon - dlon <= float(lo[1]):
			return true
	return false

## Applies the zone rules to the map in place: buildings
## (apply_buildings) and the sward of park grass (a `ground: "wild"` zone
## paints mapped lawns as unmown meadow in GroundMaterial).
static func apply(data: LocationData) -> void:
	if not near(data.latitude, data.longitude, WorldScale.DETAILED_EXTENT_M):
		return
	apply_buildings(data)
	for poly in data.land_polygons:
		if not (poly is Dictionary) or str((poly as Dictionary).get("class", "")) != "grass":
			continue
		var pts: Variant = (poly as Dictionary).get("points", null)
		if not (pts is PackedVector2Array) or (pts as PackedVector2Array).is_empty():
			continue
		var c := Vector2.ZERO
		for q in (pts as PackedVector2Array):
			c += q
		c /= float((pts as PackedVector2Array).size())
		if str(rule_at_xz(data, c.x, c.y).get("ground", "")) == "wild":
			(poly as Dictionary)["sward"] = "wild"

## The building half of apply: drops monument footprints, settles the
## kind of untagged footprints and marks the storey cap and tower rule
## that BuildingHeights / ArchitectureStyle read.
static func apply_buildings(data: LocationData) -> void:
	var kept: Array = []
	for b in data.buildings:
		if not (b is Dictionary):
			kept.append(b)
			continue
		var bd := b as Dictionary
		var rules := rule_at_xz(data, float(bd.get("x", 0.0)), float(bd.get("z", 0.0)))
		if rules.is_empty() or apply_building(bd, rules):
			kept.append(bd)
	data.buildings = kept

## One building under `rules`; false when it is dropped.
static func apply_building(b: Dictionary, rules: Dictionary) -> bool:
	if bool(rules.get("drop_historic", false)) and str(b.get("historic", "")) != "":
		return false
	var area := BuildingHeights._area_m2(b)
	var kind := ArchitectureStyle.kind_for(b, "mid", area)
	if kind in (rules.get("no_kinds", []) as Array):
		b["kind"] = "hut" if area > 0.0 and area < 45.0 else "house"
		b["use"] = ""
	if rules.has("max_storeys"):
		b["zone_storeys"] = int(rules["max_storeys"])
	if rules.has("religious_tower") and not bool(rules["religious_tower"]):
		b["no_tower"] = true
	return true

## OSM landmark candidates outside zones that bar generic archetypes.
static func filter_candidates(data: LocationData, candidates: Array) -> Array:
	if not near(data.latitude, data.longitude, WorldScale.DETAILED_EXTENT_M):
		return candidates
	return candidates.filter(func(c: Variant) -> bool:
		if not (c is Dictionary):
			return true
		var cd := c as Dictionary
		var rules := rule_at_xz(data, float(cd.get("x", 0.0)), float(cd.get("z", 0.0)))
		return not bool(rules.get("no_archetype", false)))
