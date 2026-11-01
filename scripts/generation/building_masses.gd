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
static var _mutex := Mutex.new()

static func begin_build() -> void:
	_mutex.lock()
	_plans.clear()
	_mutex.unlock()

## Releases the plans (each holds a copy of its building's tags) once the
## city is built; nothing reads them after the build.
static func end_build() -> void:
	_mutex.lock()
	_plans.clear()
	_mutex.unlock()

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
	_mutex.lock()
	if _plans.has(ck):
		var cached: Array = _plans[ck] as Array
		_mutex.unlock()
		return cached
	_mutex.unlock()
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
		var capped := not single and str(md.get("roof_shape", "")) == "" and _capped(masses, mi, ring)
		if not single:
			if str(md.get("roof_shape", "")) != "":
				shape = BuildingHeights._effective_shape(str(md["roof_shape"]), parent_shape, false)
			if float(md.get("roof_height_m", 0.0)) > 0.0:
				roof_tag = float(md["roof_height_m"])
			# An untagged part another part stands on (a drum under its dome)
			# is flat: its roof is the next part's floor.
			if capped:
				shape = "flat"
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
		# A part that is only roof (a dome on its drum: min_height at the
		# drum top, the rest roof:height) keeps its lift; any other min
		# above the top is a tagging slip, not a floating box.
		if min_m > wall - 1.0 and not (rh > 0.0 and min_m <= wall + 0.01):
			min_m = 0.0
		# Untagged arch and ramp parts of a mapped building=bridge (the Rialto)
		# are stone: left to the infill mix, the sloped parts drew an
		# outbuilding's orange plank roof.
		if str(b.get("kind", "")) == "bridge":
			if str(b_eff.get("material", "")) == "":
				b_eff["material"] = "stone"
				if str(b_eff.get("colour", "")) == "":
					b_eff["colour"] = "#d8d2c4"
			if str(b_eff.get("roof_material", "")) == "":
				b_eff["roof_material"] = "concrete"
				if str(b_eff.get("roof_colour", "")) == "":
					b_eff["roof_colour"] = "#d8d2c4"
		# A tall slender part of a church is a campanile (Venice maps ~140):
		# a brick shaft under a pointed roof, not a grey rod.
		var span_m := BuildingHeights._ring_span_m(ring)
		if str(look["kind"]) == "religious" and min_m <= 0.0 and wall >= 14.0 \
				and span_m <= 8.0 and shape not in RoofDomes.SHAPES and not capped:
			if str(b_eff.get("material", "")) == "":
				b_eff["material"] = "brick"
				# Untagged: Venetian red brick, not the row's pale stone tint.
				if str(b_eff.get("colour", "")) == "":
					b_eff["colour"] = "#b0583c"
			shape = "pyramidal"
			var cone := minf(maxf(rh, span_m * 1.4), wall * 0.3)
			wall -= cone - rh
			rh = cone
		# A black colour tag on a raised part of a church is the mapper's
		# belfry opening: drawn literally it is a pure-black hole in the
		# tower, so the part takes the style's wall instead.
		if str(look["kind"]) == "religious" and min_m > 0.0:
			var tag := MaterialLibrary.parse_colour_tag(str(b_eff.get("colour", "")))
			if tag.a > 0.0 and tag.get_luminance() < 0.12:
				b_eff["colour"] = ""
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
			# A mapped landmark's parts are its towers and domes: no made-up
			# tower, stacks or dormers on any of them.
			"main": mi == main_mass and not bool(b.get("mapped_landmark", false)),
			"look": look})
	_mutex.lock()
	if _plans.has(ck):
		var raced: Array = _plans[ck] as Array
		_mutex.unlock()
		return raced
	_plans[ck] = out
	_mutex.unlock()
	return out

## True when another part stands on part `mi`: lifted to this part's
## top (within 1 m) with its centre inside this ring.
static func _capped(masses: Array, mi: int, ring: PackedVector2Array) -> bool:
	var top := float((masses[mi] as Dictionary).get("height", 0.0))
	for j in masses.size():
		if j == mi or not (masses[j] is Dictionary):
			continue
		var o := masses[j] as Dictionary
		var lift := float(o.get("min_height_m", 0.0))
		if lift > 0.0 and absf(lift - top) <= 1.0 and RingGeometry.point_in_ring(
				Vector2(float(o.get("x", 0.0)), float(o.get("z", 0.0))), ring):
			return true
	return false

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
