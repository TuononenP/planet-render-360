class_name OsmTags
extends RefCounted

## OSM tag interpretation for OsmFetcher: raw tags -> archetypes,
## land classes, widths, heights and contract building/road/waterway
## entries. Pure functions over tag dictionaries.
## Any notable feature, anywhere: OSM tags decide the archetype, and
## LandmarkBuilder renders that archetype on the fly at the feature's
## true position. This is what makes landmarks work for any place the
## user can pick, not just the curated registry in LocationData.
static func archetype_for(tags: Dictionary) -> String:
	var b := str(tags.get("building", ""))
	var mm := str(tags.get("man_made", ""))
	if str(tags.get("attraction", "")) == "big_wheel":
		return "big_wheel"
	if mm == "lighthouse" or b == "lighthouse":
		return "lighthouse"
	if mm == "windmill":
		return "windmill"
	if mm == "tower" or b == "tower":
		return "tower"
	if b == "cathedral":
		return "cathedral"
	if b in ["church", "chapel"]:
		return "church"
	if b == "mosque":
		return "mosque"
	if b in ["temple", "synagogue"]:
		return "temple"
	if b == "castle" or str(tags.get("historic", "")) == "castle":
		return "castle"
	if b == "stadium" or str(tags.get("leisure", "")) == "stadium":
		return "stadium"
	return ""

## "obelisk" / "column" for a historic monument or memorial (a building
## way such as Nelson's Column, or man_made=obelisk|column), "" otherwise.
## The parser turns the tall slender ones into free-standing landmarks.
static func monument_kind(tags: Dictionary) -> String:
	var mm := str(tags.get("man_made", ""))
	if mm not in ["obelisk", "column"] \
			and str(tags.get("historic", "")) not in ["monument", "memorial"]:
		return ""
	var name := str(tags.get("name", "")).to_lower()
	if mm == "obelisk" or str(tags.get("memorial", "")) == "obelisk" \
			or name.contains("obelisk") or name.contains("obelisco"):
		return "obelisk"
	return "column"

## The feature's `wikipedia` tag ("en:Eiffel Tower"), "" when untagged:
## the landmark panel reads that article directly (WikiFetcher).
static func wiki_tag(tags: Dictionary) -> String:
	return str(tags.get("wikipedia", "")).strip_edges()

## Contract-§2.6 land cover class (T2.4): the v1 set
## (water/forest/grass/field/urban) plus wetland/sand/rock/glacier/
## orchard/cemetery/pitch/quarry. "" = unmapped — documented in the
## register (docs/data-source-register.md, "Land-cover tag mapping"),
## never silently defaulted to a wrong class. Order is most-specific
## first so multi-key combos (e.g. leisure=pitch on landuse=meadow)
## resolve to the specific class.
## Tree tags carried to vegetation (genus / species / leaf_type /
## leaf_cycle, lowercased; absent keys omitted) — on tree nodes, tree
## rows and forest polygons.
static func tree_tags(tags: Dictionary) -> Dictionary:
	var out := {}
	for k in ["genus", "species", "leaf_type", "leaf_cycle"]:
		var v := str(tags.get(k, "")).strip_edges().to_lower()
		if v != "":
			out[k] = v
	return out

static func land_class(tags: Dictionary) -> String:
	var natural := str(tags.get("natural", ""))
	var landuse := str(tags.get("landuse", ""))
	var leisure := str(tags.get("leisure", ""))
	# A marina (Port Hercule) is a basin of water: carving it lets the sea
	# plane show where the smoothed DEM reads quay height across the harbour.
	if natural == "water" or natural == "bay" or tags.has("water") \
			or landuse in ["reservoir", "basin"] or leisure == "marina":
		return "water"
	if natural in ["wetland", "mud"]:
		return "wetland"
	if natural == "glacier":
		return "glacier"
	if natural in ["beach", "sand", "dune"]:
		return "sand"
	if natural in ["bare_rock", "rock", "scree", "shingle"]:
		return "rock"
	if natural == "wood" or landuse == "forest":
		return "forest"
	if landuse in ["orchard", "vineyard"]:
		return "orchard"
	if leisure == "pitch":
		return "pitch"
	if natural in ["grassland", "scrub", "heath"] \
			or landuse in ["meadow", "grass", "recreation_ground"] \
			or leisure in ["park", "garden"]:
		return "grass"
	if landuse in ["farmland", "farmyard"]:
		return "field"
	if landuse == "cemetery":
		return "cemetery"
	if landuse == "quarry":
		return "quarry"
	if landuse in ["residential", "commercial", "industrial", "retail"]:
		return "urban"
	return ""

## Harbour use of industrial land behind a quay (CargoBerths): "port"
## when tagged as a port, shipyard, container terminal or harbour,
## "industrial" otherwise, "" for other land. landuse=port itself stays
## out of the land cover (it would invite infill or shadow other cover).
static func harbour_use(tags: Dictionary) -> String:
	if str(tags.get("landuse", "")) != "industrial":
		return ""
	if str(tags.get("harbour", "")) == "yes" \
			or str(tags.get("industrial", "")) in ["port", "shipyard", "container_terminal"]:
		return "port"
	return "industrial"

## How a green area is kept: "mown" for parks, gardens, lawns, pitches,
## golf courses, village greens and cemeteries, "wild" for meadows,
## grassland, heath and scrub, "" when the tags do not say.
static func sward(tags: Dictionary) -> String:
	var natural := str(tags.get("natural", ""))
	var landuse := str(tags.get("landuse", ""))
	var leisure := str(tags.get("leisure", ""))
	if leisure in ["park", "garden", "pitch", "golf_course", "common"] \
			or landuse in ["grass", "recreation_ground", "village_green", "cemetery"] \
			or str(tags.get("amenity", "")) == "grave_yard":
		return "mown"
	if landuse == "meadow" or natural in ["grassland", "heath", "scrub"]:
		return "wild"
	return ""

## Metres from a raw OSM tag value, including feet ("100 ft", "100'"):
## NAN when missing, unparseable, or outside [lo, hi] (callers fall
## through to their next source — never a silent 0).
static func _tag_metres(raw: Variant, lo: float, hi: float) -> float:
	var s := str(raw).strip_edges().to_lower()
	var factor := 1.0
	if s.ends_with("ft"):
		s = s.trim_suffix("ft").strip_edges()
		factor = 0.3048
	elif s.ends_with("'"):
		s = s.trim_suffix("'").strip_edges()
		factor = 0.3048
	else:
		s = s.trim_suffix("m").strip_edges()
	if not s.is_valid_float():
		return NAN
	var v := s.to_float() * factor
	return v if v >= lo and v <= hi else NAN

## Clamped int from a raw tag value; 0 when missing/unparseable.
static func _tag_int(raw: Variant, lo: int, hi: int) -> int:
	var s := str(raw).strip_edges()
	if not s.is_valid_int():
		return 0
	return clampi(s.to_int(), lo, hi)

## Railway classes drawn as track (platforms and disused lines are not).
const RAIL_CLASSES := ["rail", "tram", "light_rail", "subway", "narrow_gauge",
	"monorail", "funicular"]

## Track class of a railway way, or "" when it is not drawn track.
static func rail_class(tags: Dictionary) -> String:
	var cls := str(tags.get("railway", ""))
	return cls if cls in RAIL_CLASSES else ""

## Transit stop kind of a node: "tram" (railway=tram_stop, or a
## stop_position with tram=yes), "bus" (highway=bus_stop) or "".
static func stop_kind(tags: Dictionary) -> String:
	if str(tags.get("railway", "")) == "tram_stop" or (str(tags.get("public_transport", "")) == "stop_position"
			and str(tags.get("tram", "")) == "yes"):
		return "tram"
	if str(tags.get("highway", "")) == "bus_stop":
		return "bus"
	return ""

## Whether a way is a railway platform StationTrains may stand a train
## at: railway=platform, or a public transport platform for trains. One
## under ground has no open track beside it.
static func rail_platform(tags: Dictionary) -> bool:
	if underground(tags) or _tag_truthy(tags.get("tunnel", "")) or _tag_truthy(tags.get("indoor", "")):
		return false
	return str(tags.get("railway", "")) == "platform" or (str(tags.get("public_transport", "")) == "platform"
		and str(tags.get("train", "")) == "yes")

## Whether a node is a mainline railway station (railway=station or
## halt; a metro's or a light railway's is not).
static func rail_station(tags: Dictionary) -> bool:
	return str(tags.get("railway", "")) in ["station", "halt"] \
		and not str(tags.get("station", "")) in ["subway", "light_rail", "monorail", "funicular"] \
		and str(tags.get("subway", "")) != "yes"

## One railway dict: the gauge (mm tag, else 1000 mm tram / 1435 mm),
## whether the track is set in a street (trams unless embedded=no, or
## embedded=yes), whether a cable runs in a slot between the rails
## (`cable_tram=cable`, or a street tram with `electrified=no`: San
## Francisco maps most of its cable-car track only so) and the bed width
## (ballast shoulders past the rails). Track under a roof (`covered`) is
## left undrawn like a tunnel's, and marked: a station's shed is no
## tunnel to StationTrains.
static func _rail_entry(tags: Dictionary, pts: PackedVector2Array) -> Dictionary:
	var cls := rail_class(tags)
	var gauge_mm := _tag_int(str(tags.get("gauge", "")).split(";")[0], 0, 3000)
	if gauge_mm < 300:
		gauge_mm = 1000 if cls == "tram" else 1435
	var gauge := float(gauge_mm) / 1000.0
	var emb := str(tags.get("embedded", "")).strip_edges().to_lower()
	var embedded := emb in ["yes", "partial"] or (cls == "tram" and emb != "no")
	return {"points": pts, "class": cls, "gauge_m": gauge, "embedded": embedded,
		"electrified": str(tags.get("electrified", "")),
		"cable": cls == "tram" and (str(tags.get("cable_tram", "")).strip_edges().to_lower() in ["cable", "yes"]
			or str(tags.get("electrified", "")).strip_edges().to_lower() == "no"),
		"bridge": _tag_truthy(tags.get("bridge", "")),
		"tunnel": _tag_truthy(tags.get("tunnel", "")) or underground(tags)
			or _tag_truthy(tags.get("covered", "")),
		"covered": _tag_truthy(tags.get("covered", "")) and not _tag_truthy(tags.get("tunnel", ""))
			and not underground(tags),
		"layer": _tag_int(tags.get("layer", 0), -10, 10),
		"width_m": gauge + (0.3 if embedded else 1.9)}

## Highway class of a paved area mapped as a closed way or multipolygon
## (a square, a pedestrian zone): highway=* with area=yes,
## area:highway=pedestrian, or place=square; "" otherwise. Indoor and
## underground ones (a station concourse) are not drawn. A multipolygon
## (`is_area`) is an area without area=yes.
static func paved_area_class(tags: Dictionary, is_area: bool = false) -> String:
	if _tag_truthy(tags.get("indoor", "")) or _tag_truthy(tags.get("tunnel", "")) \
			or underground(tags) or _tag_int(tags.get("layer", 0), -10, 10) < 0:
		return ""
	if tags.has("highway") and (is_area or str(tags.get("area", "")) == "yes"):
		return str(tags["highway"])
	if str(tags.get("area:highway", "")) == "pedestrian":
		return "pedestrian"
	if str(tags.get("place", "")) == "square" and not tags.has("building"):
		return "pedestrian"
	if str(tags.get("amenity", "")) == "parking" and not tags.has("building") \
			and str(tags.get("parking", "surface")) in ["", "surface"] \
			and str(tags.get("surface", "")) not in ["grass", "ground", "dirt", "earth", "sand", "mud"]:
		return "parking"
	return ""

## One paved-area road dict: a filled polygon (`area`, outer ring
## `points` without the closing repeat, `holes`) that RoadBuilder lays
## flat instead of a ribbon; width_m stays the class default for the
## consumers that only walk its outline.
static func _area_entry(tags: Dictionary, cls: String, outer: PackedVector2Array,
		holes: Array) -> Dictionary:
	var ring := outer
	if ring.size() >= 2 and ring[0].distance_to(ring[ring.size() - 1]) < 0.01:
		ring = ring.slice(0, ring.size() - 1)
	return {"points": ring, "holes": holes, "area": true, "class": cls,
		"width_m": road_class_width(cls), "lanes": 0,
		"surface": str(tags.get("surface", "")), "bridge": false, "tunnel": false,
		"layer": _tag_int(tags.get("layer", 0), -10, 10)}

## A building or part that lies wholly below the surface: tagged
## location=underground, or every `level` (single, "a;b" or "a-b")
## below zero. Such a hall under a square must not stand on top of it.
static func underground(tags: Dictionary) -> bool:
	if str(tags.get("location", "")).strip_edges() == "underground":
		return true
	var raw := str(tags.get("level", "")).strip_edges()
	if raw == "":
		return false
	for part in raw.replace(";", " ").split(" ", false):
		var hi := part.strip_edges()
		for i in range(1, hi.length()):
			if hi[i] == "-" and hi[i - 1].is_valid_int():
				hi = hi.substr(i + 1)  # a range "a-b": its top
				break
		if not hi.is_valid_float() or hi.to_float() >= 0.0:
			return false
	return true

## OSM boolean tags: anything present except explicit no/false/0.
static func _tag_truthy(raw: Variant) -> bool:
	var s := str(raw).strip_edges().to_lower()
	return s != "" and s != "no" and s != "false" and s != "0"

## Default carriageway width per highway class (contract §2.5: the
## `width` tag wins, then `lanes` × 3.0, then this table).
static func road_class_width(road_class: String) -> float:
	match road_class:
		"motorway":
			return 15.0
		"trunk":
			return 12.0
		"primary":
			return 10.0
		"secondary":
			return 8.0
		"tertiary":
			return 7.0
		"living_street":
			return 5.0
		"service":
			return 4.0
		"track":
			return 3.5
		"cycleway":
			return 2.5
		"path", "footway", "steps", "corridor", "elevator", "bridleway":
			return 2.0
		_:
			return 6.0

## Default channel width per waterway class (contract §2.6); the
## `width` tag wins when present. Coastline is a boundary, not a
## channel, so it carries 0.
static func waterway_class_width(water_class: String) -> float:
	match water_class:
		"river":
			return 12.0
		"canal":
			return 10.0
		"fairway", "link":
			return 0.0  # Navigation routes do not define physical water channels.
		"stream":
			return 3.0
		"ditch", "drain":
			return 2.0
		"coastline":
			return 0.0
		_:
			return 4.0

## Resolved {height, height_source, levels} per contract §2.4: `height`
## tag → `building:levels` × 3.2 (v1 factor; regional floor heights are
## T4.2) → inherit (building parts only) → 10.0 v1 default. `estimate`
## never fires here — the fetcher holds no regional table; T4.2 refines
## `default` into regional inference.
static func _resolve_height(tags: Dictionary, inherit: Dictionary = {}) -> Dictionary:
	var raw_levels := str(tags.get("building:levels", 0)).strip_edges()
	var levels := clampf(raw_levels.to_float(), 0.0, 200.0) if raw_levels.is_valid_float() else 0.0
	var h := _tag_metres(tags.get("height", ""), 0.5, 1000.0)
	if not is_nan(h):
		return {"height": h, "height_source": "tag_height", "levels": levels}
	if levels > 0:
		return {"height": maxf(6.0, float(levels) * 3.2),
			"height_source": "levels", "levels": levels}
	if not inherit.is_empty():
		return {"height": float(inherit["height"]),
			"height_source": str(inherit["height_source"]), "levels": 0}
	return {"height": 10.0, "height_source": "default", "levels": 0}
## One contract-§2.4 building dict: full footprint polygon (rotation and
## L/T/courtyard shapes preserved — no AABB reduction), centroid XZ,
## and every rich tag. The AABB size keys stay as the corrupt-geometry
## fallback with their v1 clamp (3–34 units, now 12–136 m).
static func _building_entry(tags: Dictionary, pts: PackedVector2Array,
		aabb: Rect2) -> Dictionary:
	var res := _resolve_height(tags)
	var centre := OsmGeometry._polygon_centroid(pts, aabb.get_center())
	var entry := {
		"footprint": pts,
		# Inner rings (courtyards); only multipolygon relations fill it.
		"holes": [],
		"x": centre.x, "z": centre.y,
		"size_x": clampf(aabb.size.x, 12.0, 136.0),
		"size_z": clampf(aabb.size.y, 12.0, 136.0),
		"height": res["height"], "height_source": res["height_source"],
		"levels": res["levels"],
		"colour": wall_colour(tags),
		"material": wall_material(tags),
		"parts": [],
		"name": str(tags.get("name", "")),
		# Type tags ArchitectureStyle keys off: the raw `building` value
		# (house, apartments, warehouse, ...), a use hint for the untyped
		# `yes`, and religion/denomination for places of worship.
		"kind": str(tags.get("building", "yes")),
		"use": _building_use(tags),
		"religion": str(tags.get("religion", "")),
		"denomination": str(tags.get("denomination", "")),
		# Age / protection hints for style and weathering.
		"start_year": _start_year(tags.get("start_date", "")),
		"heritage": _tag_truthy(tags.get("heritage", "")) \
			or tags.has("heritage:operator") \
			or str(tags.get("historic", "")) in ["building", "yes"],
		"architecture": str(tags.get("building:architecture", "")).strip_edges().to_lower(),
		"monument": monument_kind(tags),
	}
	entry.merge(_roof_tags(tags))
	entry.merge(fortification_tags(tags))
	if str(entry["kind"]) in ["ship", "boat", "houseboat"]:
		entry["vessel_kind"] = str(tags.get("ship:type", tags.get("seamark:ship:type", "motor"))) \
			.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	return entry

## Preserve defensive construction independently of a building's present use.
static func fortification_tags(tags: Dictionary) -> Dictionary:
	var out := {}
	for key in ["defensive_works", "bunker_type", "casemate"]:
		if tags.has(key):
			out[key] = str(tags[key])
	return out

## A building's wall colour: `building:colour`, else the facade's own
## (`building:facade:colour`). "" when neither is mapped.
static func wall_colour(tags: Dictionary) -> String:
	var c := str(tags.get("building:colour", "")).strip_edges()
	return c if c != "" else str(tags.get("building:facade:colour", "")).strip_edges()

## A building's wall material: `building:material`, `material`, the facade's
## own (`building:facade:material`), else its cladding (`building:cladding`).
## "" when none is mapped.
static func wall_material(tags: Dictionary) -> String:
	for key in ["building:material", "material", "building:facade:material", "building:cladding"]:
		var m := str(tags.get(key, "")).strip_edges()
		if m != "":
			return m
	return ""

## `roof:angle` in degrees ("35", "35°", "35 deg"); 0 when absent or outside 5-75.
static func _roof_angle(raw: Variant) -> float:
	var s := str(raw).strip_edges().to_lower().replace("°", "").replace("deg", "").strip_edges()
	if not s.is_valid_float():
		return 0.0
	var a := s.to_float()
	return a if a >= 5.0 and a <= 75.0 else 0.0

## Compass points of `roof:direction`, as bearings in degrees.
const COMPASS := {"n": 0.0, "nne": 22.5, "ne": 45.0, "ene": 67.5, "e": 90.0, "ese": 112.5,
	"se": 135.0, "sse": 157.5, "s": 180.0, "ssw": 202.5, "sw": 225.0, "wsw": 247.5,
	"w": 270.0, "wnw": 292.5, "nw": 315.0, "nnw": 337.5}

## `roof:direction` as a bearing in degrees (0-360, the way the roof slopes
## down): a number or a compass point ("NE"); -1 when absent or unreadable.
static func _roof_dir(raw: Variant) -> float:
	var s := str(raw).strip_edges().to_lower().replace("°", "")
	if COMPASS.has(s):
		return float(COMPASS[s])
	if s.is_valid_float():
		return fposmod(s.to_float(), 360.0)
	return -1.0

## Roof and vertical-extent keys shared by buildings and their parts:
## roof shape/colour/material as raw strings, metres, degrees and level counts
## as numbers (0 when absent or out of range).
static func _roof_tags(tags: Dictionary) -> Dictionary:
	var roof_h := _tag_metres(tags.get("roof:height", ""), 0.5, 100.0)
	var min_h := _tag_metres(tags.get("min_height", ""), 0.0, 1000.0)
	return {
		"roof_shape": str(tags.get("roof:shape", "")),
		"roof_colour": str(tags.get("roof:colour", "")),
		"roof_material": str(tags.get("roof:material", "")),
		"roof_angle": _roof_angle(tags.get("roof:angle", "")),
		"roof_dir": _roof_dir(tags.get("roof:direction", "")),
		"roof_orient": str(tags.get("roof:orientation", "")).strip_edges().to_lower(),
		"roof_height_m": 0.0 if is_nan(roof_h) else roof_h,
		"roof_levels": _tag_int(tags.get("roof:levels", 0), 0, 10),
		"min_height_m": 0.0 if is_nan(min_h) else min_h,
		"min_level": _tag_int(tags.get("building:min_level", 0), 0, 200),
	}

## Construction year from `start_date`: "1890", "1890-05-01", "~1890",
## "1890s", "before 1900" read the first four-digit year; century
## notation "C19" reads its midpoint (1850). 0 when unknown.
static func _start_year(raw: Variant) -> int:
	var s := str(raw).strip_edges().to_lower()
	if s.length() >= 2 and s.begins_with("c") and s.substr(1).is_valid_int():
		var c := s.substr(1).to_int()
		return (c - 1) * 100 + 50 if c >= 1 and c <= 21 else 0
	var run := 0
	for i in s.length():
		if not "0123456789".contains(s[i]):
			run = 0
			continue
		run += 1
		var next_digit := i + 1 < s.length() and "0123456789".contains(s[i + 1])
		if run == 4 and not next_digit:
			var y := s.substr(i - 3, 4).to_int()
			return y if y >= 1000 and y <= 2100 else 0
	return 0

## What a building is used for, from the first of amenity / shop /
## office / tourism / craft / industrial / man_made that is present
## ("" when none). A shop reads as "shop"; the rest keep their value
## (place_of_worship, school, hotel, works, ...).
static func _building_use(tags: Dictionary) -> String:
	if tags.has("shop"):
		return "shop"
	if tags.has("office"):
		return "office"
	if tags.has("industrial") or tags.has("craft"):
		return "industrial"
	for key in ["amenity", "tourism", "man_made"]:
		if tags.has(key):
			return str(tags[key])
	return ""

## A painted pedestrian/cycle crossing way (footway=crossing,
## cycleway=crossing, highway=crossing, not tagged unmarked): RoadBuilder
## paints it over the carriageway it crosses.
static func is_crossing(tags: Dictionary) -> bool:
	return crossing_style(tags) not in ["", "none"]

## Paint of a crossing way: "" when it is no crossing, "none" unpainted
## (unmarked, a plain coloured surface, or not at grade), a named style
## (zebra, ladder, lines, dashes), or "auto" when mapped as painted with
## no style given (RoadSurface.crossing_finish picks the country's).
static func crossing_style(tags: Dictionary) -> String:
	if str(tags.get("footway", "")) != "crossing" and str(tags.get("cycleway", "")) != "crossing" \
			and str(tags.get("highway", "")) != "crossing":
		return ""
	var crossing := str(tags.get("crossing", ""))
	var marks := str(tags.get("crossing:markings", ""))
	if crossing in ["bridge", "underpass"] or marks == "no" \
			or (marks == "" and crossing in ["unmarked", "no", "informal"]):
		return "none"
	# First token: zebra:bicolour, zebra;dots, zebra,_dots, ladder:skewed.
	var first := marks.get_slice(";", 0).get_slice(":", 0).get_slice(",", 0)
	match first:
		"zebra", "ladder", "lines", "dashes":
			return first
		"dots":
			return "dashes"
		"surface", "pictograms":
			return "none"
	return "auto"

## One contract-§2.5 attributed road dict.
static func _road_entry(tags: Dictionary, pts: PackedVector2Array) -> Dictionary:
	var road_class := str(tags.get("highway", "unclassified"))
	var lanes := _tag_int(tags.get("lanes", 0), 0, 20)
	var width_m := road_class_width(road_class)
	var w := _tag_metres(tags.get("width", tags.get("est_width", "")), 0.5, 100.0)
	var parking := parking_sides(tags)
	if not is_nan(w):
		width_m = w
	else:
		if lanes > 0:
			width_m = float(lanes) * 3.0
		# `lanes` counts traffic lanes: a tagged parking lane widens the road.
		if parking > 0:
			width_m += PARKING_LANE_M * float((parking & 1) + (parking >> 1))
	return {"points": pts, "width_m": width_m, "lanes": lanes,
		"width_tagged": not is_nan(w), "parking": parking, "lit": str(tags.get("lit", "")) == "yes",
		"kerb_line": str(tags.get("footway", "")) == "sidewalk",
		"surface": str(tags.get("surface", "")),
		"crossing": is_crossing(tags),
		"crossing_style": crossing_style(tags),
		"crossing_signal": str(tags.get("crossing", "")) in ["traffic_signals", "pedestrian_signals"] \
			or _tag_truthy(tags.get("crossing:signals", "")),
		"crossing_scramble": _tag_truthy(tags.get("crossing:scramble", "")),
		"bridge": _tag_truthy(tags.get("bridge", "")),
		"bridge_structure": str(tags.get("bridge:structure", "")),
		"bridge_material": str(tags.get("bridge:material", tags.get("material", ""))),
		"name": str(tags.get("name", "")),
		"tunnel": _tag_truthy(tags.get("tunnel", "")),
		"layer": _tag_int(tags.get("layer", 0), -10, 10),
		"sidewalk": sidewalk_sides(tags), "sidewalk_separate": sidewalk_sides(tags, true),
		"oneway": oneway(tags), "cycle_lane": cycle_lane_sides(tags),
		"lanes_forward": _tag_int(tags.get("lanes:forward", 0), 0, 20),
		"lanes_backward": _tag_int(tags.get("lanes:backward", 0), 0, 20),
		"unmarked": str(tags.get("lane_markings", "")).strip_edges().to_lower() == "no",
		"turn_forward": turn_lanes(tags, "forward"), "turn_backward": turn_lanes(tags, "backward"), "trolley_wire": str(tags.get("trolley_wire", "")) == "yes",
		"class": road_class}

## Width of a parking lane along a kerb (m).
const PARKING_LANE_M := 2.2
const PARKING_YES: Array[String] = ["lane", "street_side", "on_kerb", "half_on_kerb", "shoulder",
	"parallel", "diagonal", "perpendicular", "marked", "yes"]
const PARKING_NO: Array[String] = ["no", "no_parking", "no_stopping", "separate", "fire_lane"]

## Sides of a road with kerbside parking, as bits (1 left, 2 right) from
## `parking:both|left|right` (and the older `parking:lane:*`); -1 when
## the road says nothing about parking.
static func parking_sides(tags: Dictionary) -> int:
	var sides := -1
	for scheme in ["parking:", "parking:lane:"]:
		for side in [["both", 3], ["left", 1], ["right", 2]]:
			var v := str(tags.get(scheme + str(side[0]), "")).strip_edges().to_lower()
			if v in PARKING_YES:
				sides = maxi(sides, 0) | int(side[1])
			elif v in PARKING_NO:
				sides = maxi(sides, 0) & ~int(side[1])
	return sides

## The turns painted on each lane in `direction` ("forward" or "backward"),
## left to right in the direction of travel: [["left"], ["through", "right"]].
## A plain `turn:lanes` means forward. Merges and `none` paint nothing.
static func turn_lanes(tags: Dictionary, direction: String) -> Array:
	var value := str(tags.get("turn:lanes:" + direction, "")).strip_edges().to_lower()
	if value == "" and direction == "forward":
		value = str(tags.get("turn:lanes", "")).strip_edges().to_lower()
	var out: Array = []
	if value == "":
		return out
	for lane in value.split("|"):
		var turns: Array = []
		for raw in lane.split(";"):
			var t := raw.strip_edges()
			if t in ["left", "slight_left", "sharp_left"] and not turns.has("left"):
				turns.append("left")
			elif t in ["right", "slight_right", "sharp_right"] and not turns.has("right"):
				turns.append("right")
			elif t == "through" and not turns.has("through"):
				turns.append("through")
		out.append(turns)
	return out

## Sides of a road with a painted bike lane, as bits (1 left, 2 right)
## from `cycleway` and `cycleway:both|left|right`. A bare `cycleway=lane`
## on a one-way street is one lane, on its right unless tagged otherwise.
static func cycle_lane_sides(tags: Dictionary) -> int:
	var sides := 0
	if str(tags.get("cycleway", "")).strip_edges().to_lower() == "lane":
		sides = 2 if oneway(tags) != 0 else 3
	for side in [["both", 3], ["left", 1], ["right", 2]]:
		var v := str(tags.get("cycleway:" + str(side[0]), "")).strip_edges().to_lower()
		if v == "lane":
			sides |= int(side[1])
		elif v != "":
			sides &= ~int(side[1])
	return sides

## Sides of a road with a sidewalk, as bits (1 left, 2 right) from
## `sidewalk` and `sidewalk:both|left|right`. `separate` counts: the
## footway is mapped as its own line, but the paving still runs from the
## kerb to the building line.
static func sidewalk_sides(tags: Dictionary, separate_only: bool = false) -> int:
	if separate_only:
		var separate := 3 if str(tags.get("sidewalk", "")).to_lower() == "separate" else 0
		for side in [["both", 3], ["left", 1], ["right", 2]]:
			var value := str(tags.get("sidewalk:" + str(side[0]), "")).strip_edges().to_lower()
			if value == "separate":
				separate |= int(side[1])
			elif value != "":
				separate &= ~int(side[1])
		return separate
	var sides := 0
	match str(tags.get("sidewalk", "")).strip_edges().to_lower():
		"both", "yes", "separate":
			sides = 3
		"left":
			sides = 1
		"right":
			sides = 2
	var both := str(tags.get("sidewalk:both", "")).strip_edges().to_lower()
	if both != "":
		sides = 3 if both in ["yes", "separate"] else 0
	for side in [["sidewalk:left", 1], ["sidewalk:right", 2]]:
		var v := str(tags.get(side[0], "")).strip_edges().to_lower()
		if v in ["yes", "separate"]:
			sides |= int(side[1])
		elif v == "no":
			sides &= ~int(side[1])
	return sides
## One contract-§2.6 waterway dict (river/stream/canal lines, plus
## coastline ways via forced_class).
static func _waterway_entry(tags: Dictionary, pts: PackedVector2Array,
		forced_class: String = "") -> Dictionary:
	var wc := forced_class if forced_class != "" \
		else str(tags.get("waterway", "stream"))
	var width_m := waterway_class_width(wc)
	var w := _tag_metres(tags.get("width", ""), 0.5, 500.0)
	if not is_nan(w):
		width_m = w
	if wc == "coastline" or navigation_waterway(wc):
		width_m = 0.0
	return {"points": pts, "width_m": width_m, "class": wc}

## A waterway under ground (tunnel=culvert/yes, location=underground,
## covered=yes): Helsinki maps its storm drains this way, and drawing
## them would lay water across squares and carve the street.
static func buried_waterway(tags: Dictionary) -> bool:
	return _tag_truthy(tags.get("tunnel", "")) or underground(tags) \
		or _tag_truthy(tags.get("covered", ""))

## A highway that is not built (proposed, planned, also as
## highway=construction + construction=proposed) or no longer there
## (abandoned, disused, razed, demolished): mapped, but nothing to draw.
static func unbuilt_highway(tags: Dictionary) -> bool:
	var h := str(tags.get("highway", ""))
	if h == "construction":
		return str(tags.get("construction", "")) in ["proposed", "planned"]
	return h in ["proposed", "planned", "abandoned", "disused", "razed", "demolished"]

## A highway no one sees from the street: a tunnel (building passages
## and culverts too), one at location=underground or indoors, or a
## corridor. Helsinki maps hundreds of service tunnels and metro
## passages. A negative `level` alone is kept: open ramps and sunken
## underpass approaches carry it too.
static func buried_highway(tags: Dictionary) -> bool:
	return _tag_truthy(tags.get("tunnel", "")) \
		or str(tags.get("location", "")).strip_edges() == "underground" \
		or _tag_truthy(tags.get("indoor", "")) or str(tags.get("highway", "")) == "corridor"

## Navigable routes across existing water must not carve or shade their
## own channels, even when a cached feature carries a positive width.
static func navigation_waterway(water_class: String) -> bool:
	return water_class in ["fairway", "link"]

## Direction along the mapped way: -1 reverse, 0 two-way, 1 forward.
static func oneway(tags: Dictionary) -> int:
	var value := str(tags.get("oneway", "")).strip_edges().to_lower()
	if value == "-1":
		return -1
	if value in ["yes", "true", "1"] or (value == "" and str(tags.get("junction", "")) == "roundabout"):
		return 1
	return 0

## Bays and tidal basins share the sea datum rather than an inland bank level.
static func tidal(tags: Dictionary) -> bool:
	return str(tags.get("natural", "")) == "bay" or str(tags.get("water", "")) == "sea" \
		or str(tags.get("tidal", "")) == "yes"

## Shallow ornamental/swimming basins use calm-water shading.
static func still_pool(tags: Dictionary) -> bool:
	return str(tags.get("artificial", "")) == "yes" or str(tags.get("leisure", "")) == "swimming_pool" \
		or str(tags.get("water", "")) == "basin"
