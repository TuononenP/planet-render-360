class_name TowerMassing
extends RefCounted

## Stacked masses for an unparted flat-roofed tower, so a skyline is not all
## plain extrusions: stepped upper tiers on masonry towers of the zoning era,
## and on modern towers a podium under an inset shaft, a narrower crown, or
## neither. The form follows the resolved look and the building's position,
## so no style row needs a key. Tagged building parts stay authoritative;
## holes, thin or fragmented insets and landmarks keep the mapped single mass.

const KINDS := ["commercial", "apartments"]
const MASONRY := ["brick", "limestone", "stone"]
## Masonry towers tagged later than this are not setback-era buildings.
const SETBACK_UNTIL := 1965
## Modern forms start here; a tagged older tower stays a plain extrusion.
const MODERN_FROM := 1955
## Share of modern towers with a podium, and with a crown; the rest are plain.
const PODIUM_SHARE := 0.4
const CROWN_SHARE := 0.3
## An inset shaft must keep this share of the podium, or it reads as a spike.
const MIN_SHAFT_SHARE := 0.35
## The 1916 resolution: a tower may rise without limit on a quarter of the lot.
const MIN_TOWER_SHARE := 0.25
const STREET_WALL_M := 40.0
const PENCIL_LEVELS := 55
const PENCIL_SPAN_M := 34.0

## Parts for `b` (as BuildingMasses plans building:part), or [] for one mass.
## `shape` is the building's effective roof form, `res` its resolved height.
static func stack(b: Dictionary, look: Dictionary, res: Dictionary, ctx: Dictionary,
		shape: String) -> Array:
	if int(ctx.get("fidelity", 0)) < 2 or shape != "flat" or not b.has("height_source") \
			or bool(b.get("mapped_landmark", false)) or not (str(look.get("kind", "")) in KINDS) \
			or not (b.get("parts", []) as Array).is_empty() or not (b.get("holes", []) as Array).is_empty() \
			or float(b.get("min_height_m", 0.0)) > 0.0 or int(b.get("min_level", 0)) > 0:
		return []
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if ring.size() < 3:
		return []
	var fh := maxf(float(look.get("floor_h", 3.2)), 1.0)
	var h := float(res.get("total_m", 0.0))
	var levels := int(b.get("levels", 0))
	if levels <= 0:
		levels = roundi(h / fh)
	var span := BuildingHeights._ring_span_m(ring)
	var seed_v := TerrainBuilder._hash(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	var m := WorldScale.metres_to_units()
	match _form(b, look, levels, h, span, seed_v):
		"setback":
			return _setback_stack(b, ring, h, span, levels)
		"podium":
			var shaft := BuildingMasses._inset_ring(ring, clampf(span * 0.14, 3.0, 8.0) * m)
			if shaft.is_empty() or absf(RingGeometry.signed_area(shaft)) \
					< absf(RingGeometry.signed_area(ring)) * MIN_SHAFT_SHARE:
				return []
			var base := float(3 + int(ArchitectureStyle._h(seed_v, 52) * 3.0)) * fh
			return _parts(b, [ring, shaft], [0.0, base, h], levels)
		"crown":
			var top := BuildingMasses._inset_ring(ring, clampf(span * 0.18, 2.5, 7.0) * m)
			var cap := float(2 + int(ArchitectureStyle._h(seed_v, 53) * 2.0)) * fh
			return _parts(b, [ring, top], [0.0, h - cap, h], levels)
	return []

## The 1916 zoning profile: a street wall, then tiers stepping in with height
## to a tower on at least a quarter of the lot, which keeps the top 45%.
static func _setback_stack(b: Dictionary, ring: PackedVector2Array, h: float, span: float,
		levels: int) -> Array:
	var inset := clampf(span * 0.08, 3.0, 9.0) * WorldScale.metres_to_units()
	var lot := absf(RingGeometry.signed_area(ring))
	var rings: Array = [ring]
	for i in clampi(2 + int(h / 60.0), 3, 6) - 1:
		var r := BuildingMasses._inset_ring(ring, inset * float(i + 1))
		if r.is_empty() or absf(RingGeometry.signed_area(r)) < lot * MIN_TOWER_SHARE:
			break
		rings.append(r)
	if rings.size() < 2:
		return []
	var street := minf(h * 0.35, STREET_WALL_M)
	var cuts: Array = [0.0, street]
	var steps := rings.size() - 2
	for i in steps:
		cuts.append(street + (h - street) * 0.55 * float(i + 1) / float(steps))
	cuts.append(h)
	return _parts(b, rings, cuts, levels)

## "setback", "podium", "crown" or "" (the tower stays one mass).
static func _form(b: Dictionary, look: Dictionary, levels: int, h: float, span: float,
		seed_v: float) -> String:
	var wall := str(look.get("wall_set", ""))
	var glazed := wall == "glass" or str(look.get("pattern", "")) == "curtain"
	var year := int(b.get("start_year", 0))
	if wall in MASONRY and not glazed:
		return "setback" if levels >= 20 and h >= 55.0 and span >= 18.0 and year <= SETBACK_UNTIL else ""
	if (str(look.get("kind", "")) != "commercial" and not glazed) or (year > 0 and year < MODERN_FROM):
		return ""
	# A slender supertall rises straight from its lot; a step would be a spike.
	if levels >= PENCIL_LEVELS and span < PENCIL_SPAN_M:
		return ""
	var pick := ArchitectureStyle._h(seed_v, 50)
	if pick < PODIUM_SHARE:
		return "podium" if levels >= 12 and h >= 40.0 and span >= 30.0 else ""
	if pick < PODIUM_SHARE + CROWN_SHARE:
		return "crown" if levels >= 15 and h >= 50.0 and span >= 20.0 else ""
	return ""

## One part per ring between successive `cuts`, each flat but the top one,
## which carries the roofline detail. [] when an inset ring failed.
static func _parts(b: Dictionary, rings: Array, cuts: Array, levels: int) -> Array:
	var out: Array = []
	var h := float(cuts.back())
	for i in rings.size():
		var ring: PackedVector2Array = rings[i]
		if ring.is_empty():
			return []
		var part := b.duplicate()
		part.erase("parts")
		part["footprint"] = ring
		var centre := RingGeometry.centroid(ring)
		part["x"] = centre.x
		part["z"] = centre.y
		part["height"] = cuts[i + 1]
		part["height_source"] = "tag_height"
		part["min_height_m"] = cuts[i]
		part["min_level"] = 0
		part["levels"] = maxi(1, roundi(float(levels) * (float(cuts[i + 1]) - float(cuts[i])) / h))
		if i < rings.size() - 1:
			part["roof_shape"] = "flat"
			part["roof_height_m"] = 0.0
			part["roof_levels"] = 0
		else:
			part["stack_top"] = true
		out.append(part)
	return out
