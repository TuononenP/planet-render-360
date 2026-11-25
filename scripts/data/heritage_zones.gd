class_name HeritageZones
extends RefCounted

## Protected archaeological areas where the map's untagged footprints are
## not a town: the monastery halls, stalls and guard posts inside the
## Angkor park stay one or two storeys and never turn into apartment
## blocks, and footprints of the stone monuments the landmark models
## draw (a `historic` gate or ruin) give way to those models.
## Central Park keeps only its own tree mix (TreeSpecies "nyc_park");
## Djurgården its oaks ("stockholm_park"), Kungsträdgården and
## Humlegården their lime avenues ("lime_avenue").
## Zones are lat/lon boxes, outermost first; a point inside several takes
## the outer rules overlaid by the inner ones. Rule keys:
##   max_storeys      cap on an inferred (untagged) height, in storeys
##   no_kinds         inferred kinds that become a house (or a hut)
##   drop_historic    drop footprints with a `historic` tag (true: any;
##                    an Array: only those values) the models draw
##   ruins_untyped    an unnamed, untyped footprint is ancient too (inside
##                    Angkor Thom nearly every mapped footprint is a ruin)
##   ruins            ancient structures the map draws as plain footprints
##                    (named prasats, Khleangs, `historic` ruins) build as
##                    weathered stone (the "ruins" kind), not houses
##   no_archetype     OSM temple candidates build no generic model here
##   religious_tower  false: no pagoda / spire on a religious building
##   tree_keep        share of canopy-raster trees kept (open woodland)
##   tree_mix         TreeSpecies mix name for the zone's trees
##   ground           "wild": park grass reads as unmown meadow
##   no_marina        no yachts moored along mapped piers (MarinaBuilder)
##   no_new_era       the region's newest period row is never picked
##   trees_only       the zone sets a tree mix and nothing else: no
##                    footprints change or drop and no glade is cut

## Rules round a temple outside the park, in its village.
const OUTER_TEMPLE := {"max_storeys": 2, "no_kinds": ["apartments", "commercial", "office", "farm"],
	"no_archetype": true, "religious_tower": false, "ruins": true, "no_marina": true, "tree_keep": 0.55,
	"tree_mix": "khmer", "ground": "wild"}

const ZONES := [
	{"id": "angkor_park", "lat": [13.395, 13.480], "lon": [103.800, 103.960],
		"rules": {"max_storeys": 2, "no_kinds": ["apartments", "commercial", "office", "farm"],
			"no_archetype": true, "religious_tower": false, "ruins": true, "no_marina": true,
			"tree_keep": 0.45, "tree_mix": "khmer", "ground": "wild"}},
	# The moat-bounded island of Angkor Wat (its outer wall plus the berm).
	{"id": "angkor_wat_island", "lat": [13.40839, 13.41655], "lon": [103.86144, 103.87170],
		"rules": {"max_storeys": 1, "drop_historic": true, "tree_keep": 0.35}},
	# Angkor Thom, the 3 km walled city round the Bayon.
	# The walls and gates are LandmarkAngkorThomWalls; its other ruins stand.
	{"id": "angkor_thom", "lat": [13.4266, 13.4560], "lon": [103.8436, 103.8744],
		"rules": {"max_storeys": 1, "drop_historic": ["city_gate", "citywalls"], "ruins_untyped": true}},
	# The temples beyond the park, each in its village: the Roluos group
	# (Bakong, Preah Ko, Lolei), Banteay Srei, Beng Mealea, Phnom Krom.
	{"id": "roluos", "lat": [13.325, 13.362], "lon": [103.955, 103.990], "rules": OUTER_TEMPLE},
	{"id": "banteay_srei", "lat": [13.585, 13.612], "lon": [103.948, 103.976], "rules": OUTER_TEMPLE},
	{"id": "beng_mealea", "lat": [13.464, 13.488], "lon": [104.215, 104.243], "rules": OUTER_TEMPLE},
	{"id": "phnom_krom", "lat": [13.276, 13.296], "lon": [103.802, 103.822], "rules": OUTER_TEMPLE},
	# Siem Reap town: shophouses, wats and low resort hotels, not the
	# region's newest 6-14 storey white blocks.
	{"id": "central_park", "lat": [40.7644, 40.8005], "lon": [-73.9820, -73.9490],
		"rules": {"tree_mix": "nyc_park"}},
	{"id": "djurgarden", "lat": [59.318, 59.345], "lon": [18.090, 18.160],
		"rules": {"tree_mix": "stockholm_park", "trees_only": true}},
	{"id": "amsterdam_canals", "lat": [52.345, 52.392], "lon": [4.855, 4.935],
		"rules": {"tree_mix": "amsterdam", "trees_only": true}},
	{"id": "kungstradgarden", "lat": [59.3298, 59.3340], "lon": [18.0685, 18.0745],
		"rules": {"tree_mix": "lime_avenue", "trees_only": true}},
	{"id": "humlegarden", "lat": [59.3355, 59.3395], "lon": [18.0700, 18.0780],
		"rules": {"tree_mix": "lime_avenue", "trees_only": true}},
	{"id": "miami_metro", "lat": [25.55, 26.02], "lon": [-80.42, -80.08],
		"rules": {"tree_mix": "miami", "trees_only": true}},
	{"id": "singapore_island", "lat": [1.18, 1.48], "lon": [103.60, 104.06],
		"rules": {"tree_mix": "singapore", "trees_only": true}},
	{"id": "siem_reap_town", "lat": [13.330, 13.395], "lon": [103.820, 103.900],
		"rules": {"max_storeys": 5, "no_new_era": true, "tree_mix": "khmer"}},
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

## Whether `rules` are empty or only set a tree mix (trees_only).
static func is_trees_only(rules: Dictionary) -> bool:
	return rules.is_empty() or bool(rules.get("trees_only", false))

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
	if bool(rules.get("trees_only", false)):
		return true
	var historic := str(b.get("historic", ""))
	var drop: Variant = rules.get("drop_historic", false)
	if historic != "" and ((drop is bool and drop) or (drop is Array and (drop as Array).has(historic))):
		return false
	if rules.has("max_storeys"):
		b["zone_storeys"] = int(rules["max_storeys"])
	var untyped := str(b.get("kind", "")) == "yes" and str(b.get("name", "")) == "" \
		and str(b.get("use", "")) == ""
	if bool(rules.get("ruins", false)) and (ancient(b) or (untyped and bool(rules.get("ruins_untyped", false)))):
		b["kind"] = "khmer_ruin"
		b["use"] = ""
		b["no_tower"] = true
		# A Suor Prat tower or a Khleang stands two storeys of stone.
		b["zone_storeys"] = maxi(int(b.get("zone_storeys", 2)), 2)
		return true
	var area := BuildingHeights._area_m2(b)
	var kind := ArchitectureStyle.kind_for(b, "mid", area)
	if kind in (rules.get("no_kinds", []) as Array):
		b["kind"] = "hut" if area > 0.0 and area < 45.0 else "house"
		b["use"] = ""
	if rules.has("religious_tower") and not bool(rules["religious_tower"]):
		b["no_tower"] = true
	if bool(rules.get("no_new_era", false)):
		b["no_new_era"] = true
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

## Inside a zone, footprints a landmark model clears (the temple's own
## mapped outline, often its whole enclosure) leave the map altogether:
## otherwise the ground still paints them as paving, a grey slab the size
## of Ta Prohm under the model and its trees.
static func drop_cleared(data: LocationData) -> void:
	if not near(data.latitude, data.longitude, WorldScale.DETAILED_EXTENT_M):
		return
	var site := TerrainBuilder.landmark_site_xz(data)
	data.buildings = data.buildings.filter(func(b: Variant) -> bool:
		if not (b is Dictionary):
			return true
		var bd := b as Dictionary
		if is_trees_only(rule_at_xz(data, float(bd.get("x", 0.0)), float(bd.get("z", 0.0)))):
			return true
		return BuildingBuilder._accepted(data, bd, site, INF))

## Words naming an ancient Khmer structure, and a living monastery.
const ANCIENT_WORDS := ["prasat", "ប្រាសាទ", "khleang", "kleang", "pithu", "suor prat", "temple", "ruin"]
const MODERN_WORDS := ["wat ", "វត្ត", "pagoda", "monastery", "school"]

## True for a footprint of an ancient structure: a `historic` tag or a
## building=ruins, or a temple (or untyped building) named like a prasat or
## an ancient temple, but never a named living wat.
static func ancient(b: Dictionary) -> bool:
	var name := str(b.get("name", "")).to_lower()
	for w in MODERN_WORDS:
		if name.contains(w):
			return false
	if str(b.get("historic", "")) != "" or str(b.get("kind", "")) == "ruins":
		return true
	if str(b.get("kind", "")) not in ["temple", "yes", "shrine"]:
		return false
	for w in ANCIENT_WORDS:
		if name.contains(w):
			return true
	return false
