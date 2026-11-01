class_name LandmarkFidelity
extends RefCounted

## Which OSM landmark candidates are mapped well enough to be drawn from
## their own masses (building:part naves, drums, domes and spires through
## BuildingMasses and RoofDomes) instead of a generic archetype. A mapped
## landmark keeps its real building and builds no archetype; the rest
## keep the archetype stand-in.

## Archetypes whose real form lives in their parts. Stadiums, wheels,
## lighthouses, windmills and monuments keep their models.
const ARCHETYPES: Array[String] = ["cathedral", "church", "mosque", "temple", "castle", "tower"]
## Share of the outline the ground-standing parts must cover: only the
## parts are drawn when parts exist, so a half-mapped church would be
## a nave floating beside a hole.
const MIN_PART_COVER := 0.6
const LATHED: Array[String] = ["dome", "onion", "cone"]

## True when building `b` (an OsmTags._building_entry with its nested
## parts) is a well-mapped `archetype`: two or more parts covering the
## outline, at least one with a form of its own (roof shape, lift or
## height), or a single tagged-height rotunda under a dome, onion or cone.
static func well_mapped(b: Dictionary, archetype: String) -> bool:
	if archetype not in ARCHETYPES:
		return false
	var fp: Variant = b.get("footprint", null)
	if not (fp is PackedVector2Array) or (fp as PackedVector2Array).size() < 3:
		return false
	var ring := fp as PackedVector2Array
	var area := absf(RingGeometry.signed_area(ring))
	if area <= 0.0:
		return false
	var parts: Array = b.get("parts", [])
	if parts.size() >= 2:
		var covered := 0.0
		var formed := false
		for p in parts:
			var pd := p as Dictionary
			var pfp: Variant = pd.get("footprint", null)
			if not (pfp is PackedVector2Array):
				continue
			var lifted := float(pd.get("min_height_m", 0.0)) > 0.0 or int(pd.get("min_level", 0)) > 0
			if not lifted:
				covered += absf(RingGeometry.signed_area(pfp as PackedVector2Array))
			if str(pd.get("roof_shape", "")) != "" or lifted \
					or absf(float(pd.get("height", 0.0)) - float(b.get("height", 0.0))) > 0.5:
				formed = true
		return formed and minf(covered / area, 1.0) >= MIN_PART_COVER
	if str(b.get("height_source", "")) != "tag_height" or ring.size() < 8 \
			or str(b.get("roof_shape", "")).strip_edges().to_lower() not in LATHED:
		return false
	var hull := absf(RingGeometry.signed_area(Geometry2D.convex_hull(ring)))
	return hull > 0.0 and area / hull >= 0.9

## Flags each building-derived candidate in `landmarks` whose building is
## well mapped: `mapped` on the candidate, `mapped_landmark` on the
## building. Candidates share their building's centroid exactly (the
## parser copies it), so the match is a key lookup; node and plain-way
## candidates have no building and never match.
static func mark(buildings: Array, landmarks: Array) -> void:
	var by_key := {}
	for i in buildings.size():
		var b := buildings[i] as Dictionary
		by_key[_key(float(b.get("x", 0.0)), float(b.get("z", 0.0)))] = i
	for lm in landmarks:
		var lmk := lm as Dictionary
		var k := _key(float(lmk.get("x", 0.0)), float(lmk.get("z", 0.0)))
		if not by_key.has(k):
			continue
		var b := buildings[int(by_key[k])] as Dictionary
		if well_mapped(b, str(lmk.get("archetype", ""))):
			b["mapped_landmark"] = true
			lmk["mapped"] = true

static func _key(x: float, z: float) -> String:
	return "%.3f,%.3f" % [x, z]
