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
	if natural == "water" or natural == "bay" or tags.has("water") \
			or landuse in ["reservoir", "basin"]:
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

## Metres from a raw OSM tag value ("12", "12m", "12 m", "3.5"):
## NAN when missing, unparseable, or outside [lo, hi] (callers fall
## through to their next source — never a silent 0).
static func _tag_metres(raw: Variant, lo: float, hi: float) -> float:
	var s := str(raw).strip_edges().trim_suffix("m").strip_edges()
	if not s.is_valid_float():
		return NAN
	var v := s.to_float()
	return v if v >= lo and v <= hi else NAN

## Clamped int from a raw tag value; 0 when missing/unparseable.
static func _tag_int(raw: Variant, lo: int, hi: int) -> int:
	var s := str(raw).strip_edges()
	if not s.is_valid_int():
		return 0
	return clampi(s.to_int(), lo, hi)

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
		"fairway":
			return 20.0
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
	var levels := _tag_int(tags.get("building:levels", 0), 0, 200)
	var h := _tag_metres(tags.get("height", ""), 0.5, 400.0)
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
		"colour": str(tags.get("building:colour", "")),
		"material": str(tags.get("building:material", tags.get("material", ""))),
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
	return entry

## Roof and vertical-extent keys shared by buildings and their parts:
## roof shape/colour/material as raw strings, metres and level counts
## as numbers (0 when absent or out of range).
static func _roof_tags(tags: Dictionary) -> Dictionary:
	var roof_h := _tag_metres(tags.get("roof:height", ""), 0.5, 100.0)
	var min_h := _tag_metres(tags.get("min_height", ""), 0.0, 400.0)
	return {
		"roof_shape": str(tags.get("roof:shape", "")),
		"roof_colour": str(tags.get("roof:colour", "")),
		"roof_material": str(tags.get("roof:material", "")),
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

## One contract-§2.5 attributed road dict.
static func _road_entry(tags: Dictionary, pts: PackedVector2Array) -> Dictionary:
	var road_class := str(tags.get("highway", "unclassified"))
	var lanes := _tag_int(tags.get("lanes", 0), 0, 20)
	var width_m := road_class_width(road_class)
	var w := _tag_metres(tags.get("width", ""), 0.5, 100.0)
	if not is_nan(w):
		width_m = w
	elif lanes > 0:
		width_m = float(lanes) * 3.0
	return {"points": pts, "width_m": width_m, "lanes": lanes,
		"surface": str(tags.get("surface", "")),
		"bridge": _tag_truthy(tags.get("bridge", "")),
		"tunnel": _tag_truthy(tags.get("tunnel", "")),
		"layer": _tag_int(tags.get("layer", 0), -10, 10),
		"class": road_class}
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
	if wc == "coastline":
		width_m = 0.0
	return {"points": pts, "width_m": width_m, "class": wc}
