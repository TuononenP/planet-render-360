class_name BuildingMasses
extends RefCounted

## The masses one OSM building extrudes as, resolved once per build and
## shared by the extruder and PartyWalls (a neighbour's wall top decides
## which of a building's walls are hidden): each building:part, else the
## footprint itself, with its ring and courtyard holes, wall height, roof
## form and rise, storeys and merged tags.
## Heights: a total from `height` includes the roof (OSM semantics), so
## the roof is carved out of it; a total from `building:levels` counts
## only the storeys under the roof (`roof:levels` are separate in OSM),
## so the roof stands on top — a Paris block tagged 6 levels under a
## mansard is six storeys of facade plus the mansard, not five.
## `roof:levels` sizes a pitched roof's rise when `roof:height` is absent;
## `min_height` / `building:min_level` lift a part's base (overhangs,
## towers on podiums). Parts' own roof tags win over the parent's.

## Part roof keys that fall back to the parent's when the part leaves
## them untagged (OsmTags._roof_tags writes "" / 0 for absent tags).
const INHERITED_ROOF_KEYS: Array[String] = ["roof_shape", "roof_colour",
	"roof_material", "roof_height_m", "roof_levels"]

static var _plans: Dictionary = {}

static func begin_build() -> void:
	_plans.clear()

## Stable identity of a mass: its centroid (internal units).
static func key_of(x: float, z: float) -> String:
	return "%.2f,%.2f" % [x, z]

## Masses of `b` (cached per build): Array of
## {ring, holes, centre, key, wall_m, min_m, rh_m, shape, storeys, b_eff,
##  main, look}. Heights in metres above the lowest ground under the ring.
static func plan(b: Dictionary, ctx: Dictionary) -> Array:
	var fp0: Variant = b.get("footprint", null)
	var ck := key_of(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	if fp0 is PackedVector2Array and not (fp0 as PackedVector2Array).is_empty():
		var f := fp0 as PackedVector2Array
		ck += "|%d|%s" % [f.size(), key_of(f[0].x, f[0].y)]
	if _plans.has(ck):
		return _plans[ck] as Array
	var out: Array = []
	var look := BuildingHeights._look_for(b, ctx)
	var parent_res := BuildingHeights._resolve_total(b, b, ctx, {}, look)
	var legacy := not b.has("height_source")
	var parent_shape := BuildingHeights._effective_shape(str(b.get("roof_shape", "")),
		str(look["roof_shape"]), legacy)
	var masses: Array = b.get("parts", [])
	var single := masses.is_empty()
	if single:
		masses = [b]
	var main_mass := _largest(masses)
	var fh := float(look["floor_h"])
	for mi in masses.size():
		if not (masses[mi] is Dictionary):
			continue
		var md := masses[mi] as Dictionary
		var fp: Variant = md.get("footprint", PackedVector2Array())
		if not (fp is PackedVector2Array):
			continue
		var ring := BuildingWalls._clean_ring(fp)
		if ring.size() < 3:
			continue
		var res := parent_res if single \
			else BuildingHeights._resolve_total(md, b, ctx, parent_res, look)
		# T4.3: storeys drive the window rows (tagged levels, else the
		# resolved total over the regional floor height).
		var storeys := int(md.get("levels", b.get("levels", 0)))
		if storeys <= 0:
			storeys = maxi(1, roundi(float(res["total_m"]) / fh))
		var b_eff := b.duplicate()
		for k in md:
			# An untagged part roof key ("" / 0) inherits the parent's tag.
			if k in INHERITED_ROOF_KEYS and (str(md[k]) == "" \
					if md[k] is String else float(md[k]) <= 0.0):
				continue
			b_eff[k] = md[k]
		var shape := parent_shape
		# A gable-fronted house (Amsterdam) needs the ridge its street gable
		# stands on: an untagged hip or mansard on a parcel ring turns gabled.
		if str(b.get("roof_shape", "")) == "" and str(md.get("roof_shape", "")) == "" \
				and str((look.get("relief", {}) as Dictionary).get("gable", "")) != "" \
				and shape in ["hipped", "mansard", "half-hipped", "pyramidal"] and RoofForms.boxy(ring):
			shape = "gabled"
		var roof_tag := float(b.get("roof_height_m", 0.0))
		if not single:
			if str(md.get("roof_shape", "")) != "":
				shape = BuildingHeights._effective_shape(str(md["roof_shape"]), parent_shape, false)
			if float(md.get("roof_height_m", 0.0)) > 0.0:
				roof_tag = float(md["roof_height_m"])
		var roof_levels := int(b_eff.get("roof_levels", 0))
		if roof_tag <= 0.0 and roof_levels > 0 and shape != "flat":
			roof_tag = float(roof_levels) * fh * 0.95
		var total := float(res["total_m"])
		var rh := BuildingHeights._roof_height_m(shape, BuildingHeights._ring_span_m(ring),
			roof_tag, float(look["pitch"]))
		var wall := total
		if str(res["source"]) != "levels" or legacy:
			rh = minf(rh, maxf(total - 0.5, 0.0))
			wall = total - rh
		if legacy:
			wall = clampf(wall, 7.2, 76.0)
		var min_m := maxf(float(md.get("min_height_m", 0.0)), float(md.get("min_level", 0)) * fh)
		if min_m > wall - 1.0:
			min_m = 0.0  # a min above the top is a tagging slip, not a floating box
		var holes: Array = []
		for h in md.get("holes", []):
			if h is PackedVector2Array:
				var hr := BuildingWalls._clean_ring(h)
				if hr.size() >= 3:
					holes.append(hr)
		var cx := float(md.get("x", 0.0))
		var cz := float(md.get("z", 0.0))
		out.append({"ring": ring, "holes": holes, "centre": Vector2(cx, cz),
			"key": key_of(cx, cz) + "#%d" % mi, "wall_m": wall, "min_m": min_m,
			"rh_m": rh, "shape": shape, "storeys": storeys, "b_eff": b_eff,
			"main": mi == main_mass, "look": look})
	_plans[ck] = out
	return out

## Index of the largest footprint: roofline detail goes on it only (a
## church of five parts has one tower, not five).
static func _largest(masses: Array) -> int:
	var best := 0
	var best_area := -1.0
	for i in masses.size():
		var fp: Variant = (masses[i] as Dictionary).get("footprint", null) \
			if masses[i] is Dictionary else null
		if fp is PackedVector2Array and (fp as PackedVector2Array).size() >= 3:
			var ar := absf(RingGeometry.signed_area(fp as PackedVector2Array))
			if ar > best_area:
				best_area = ar
				best = i
	return best
