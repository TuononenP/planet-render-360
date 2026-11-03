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
	var look := BuildingHeights._look_for(b, ctx)
	var parent_res := BuildingHeights._resolve_total(b, b, ctx, {}, look)
	var legacy := not b.has("height_source")
	var parent_shape := BuildingHeights._effective_shape(str(b.get("roof_shape", "")),
		str(look["roof_shape"]), legacy)
	var fh := float(look["floor_h"])
	var masses: Array = b.get("parts", [])
	var single := masses.is_empty()
	if single:
		var stepped := _prewar_setbacks(b, look, parent_res, ctx)
		if not stepped.is_empty():
			masses = stepped
			single = false
		else:
			masses = [b]
	var out := _plan_masses(b, ctx, masses, single, look, parent_res, legacy, parent_shape, fh)
	if not single:
		# Judged on the planned lifts, so a part plan() stands on the ground
		# (a mistagged min) never gets a block under it.
		var base := _missing_base(b, out)
		if not base.is_empty():
			out = _plan_masses(b, ctx, [base] + masses, false, look, parent_res, legacy,
				parent_shape, fh)
	_mutex.lock()
	if _plans.has(ck):
		var raced: Array = _plans[ck] as Array
		_mutex.unlock()
		return raced
	_plans[ck] = out
	_mutex.unlock()
	return out

## On Ultra, unparted prewar New York towers get two modest, seeded-free
## setbacks. Tagged building parts remain authoritative. Holes and narrow
## or fragmented insets stay as the mapped single mass.
static func _prewar_setbacks(b: Dictionary, look: Dictionary, res: Dictionary, ctx: Dictionary) -> Array:
	if int(ctx.get("fidelity", 0)) < 3 or str(look.get("era", "")) != "nyc_prewar" \
			or not (b.get("parts", []) as Array).is_empty() or not (b.get("holes", []) as Array).is_empty() \
			or float(b.get("min_height_m", 0.0)) > 0.0 or int(b.get("min_level", 0)) > 0:
		return []
	var h := float(res.get("total_m", 0.0))
	var levels := int(b.get("levels", 0))
	if levels <= 0:
		levels = roundi(h / maxf(float(look.get("floor_h", 3.2)), 1.0))
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if levels < 20 or ring.size() < 3 or h < 55.0:
		return []
	var m := WorldScale.metres_to_units()
	var span := BuildingHeights._ring_span_m(ring)
	if span < 18.0:
		return []
	var inset := clampf(span * 0.075, 1.5, 4.0) * m
	var mid := _inset_ring(ring, inset)
	var top := _inset_ring(ring, inset * 2.0)
	if mid.is_empty() or top.is_empty():
		return []
	var cuts := [0.0, h * 0.58, h * 0.80, h]
	var rings := [ring, mid, top]
	var out: Array = []
	for i in 3:
		var part := b.duplicate()
		part.erase("parts")
		part["footprint"] = rings[i]
		var centre := RingGeometry.centroid(rings[i])
		part["x"] = centre.x
		part["z"] = centre.y
		part["height"] = cuts[i + 1]
		part["height_source"] = "tag_height"
		part["min_height_m"] = cuts[i]
		part["min_level"] = 0
		part["levels"] = maxi(1, roundi(float(levels) * (cuts[i + 1] - cuts[i]) / h))
		if i < 2:
			part["roof_shape"] = "flat"
			part["roof_height_m"] = 0.0
			part["roof_levels"] = 0
		out.append(part)
	return out

static func _inset_ring(ring: PackedVector2Array, inset: float) -> PackedVector2Array:
	var pieces := RingGeometry._solid_parts(Geometry2D.offset_polygon(ring, -inset))
	if pieces.size() != 1:
		return PackedVector2Array()
	var result: PackedVector2Array = pieces[0]
	if result.size() < 3 or absf(RingGeometry.signed_area(result)) < absf(RingGeometry.signed_area(ring)) * 0.2:
		return PackedVector2Array()
	return result

## Plans each of `masses` (the parts, the outline under them, or the
## building itself when `single`) as plan() returns them.
static func _plan_masses(b: Dictionary, ctx: Dictionary, masses: Array, single: bool,
		look: Dictionary, parent_res: Dictionary, legacy: bool, parent_shape: String,
		fh: float) -> Array:
	var out: Array = []
	var main_mass := _largest(masses)
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
			# Parts with no facade tags keep the building's mapped finish.
			if k in ["colour", "material"] and str(md[k]).strip_edges() == "":
				continue
			# An untagged part roof key ("" / 0) inherits the parent's tag.
			if k in INHERITED_ROOF_KEYS and (str(md[k]) == "" \
					if md[k] is String else float(md[k]) <= 0.0):
				continue
			b_eff[k] = md[k]
		NycCrownMaterials.apply(b, md, b_eff)
		var shape := parent_shape
		# A gable-fronted house (Amsterdam) needs the ridge its street gable
		# stands on: an untagged hip or mansard on a parcel ring turns gabled.
		if str(b.get("roof_shape", "")) == "" and str(md.get("roof_shape", "")) == "" \
				and str((look.get("relief", {}) as Dictionary).get("gable", "")) != "" \
				and shape in ["hipped", "mansard", "half-hipped", "pyramidal"] and RoofForms.boxy(ring):
			shape = "gabled"
		var roof_tag := float(b.get("roof_height_m", 0.0))
		var capped := not single and str(md.get("roof_shape", "")) == "" and _capped(masses, mi, ring, fh)
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
		var min_m := _lift_m(md, fh)
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
	return out

## The outline as a mass from the ground to the lowest part when every
## part is lifted: a tower mapped with only its rooftop parts (375 Pearl
## Street, New York: penthouses at min_height 155 over a 155 m outline)
## otherwise drew its penthouses floating over an empty lot. {} when a
## planned part already stands on the ground (`planned`: the parts as
## _plan_masses planned them), and for skybridges, canopies and
## outlines that are lifted themselves (open underneath for real).
static func _missing_base(b: Dictionary, planned: Array) -> Dictionary:
	if str(b.get("kind", "")) in ["bridge", "roof"] or float(b.get("min_height_m", 0.0)) > 0.0 \
			or int(b.get("min_level", 0)) > 0:
		return {}
	var lowest := INF
	for m in planned:
		var lift := float((m as Dictionary)["min_m"])
		if lift <= 0.0:
			return {}
		lowest = minf(lowest, lift)
	if lowest == INF:
		return {}
	var base := b.duplicate()
	base.erase("parts")
	base["height"] = lowest
	base["height_source"] = "tag_height"
	base["min_height_m"] = 0.0
	base["min_level"] = 0
	# Its roof is the parts' floor (flat, via _capped).
	base["roof_shape"] = ""
	base["roof_height_m"] = 0.0
	base["roof_levels"] = 0
	return base

## A mass's base above the ground (metres): min_height, or min_level
## storeys of the look's floor height `fh`, whichever is higher.
static func _lift_m(md: Dictionary, fh: float) -> float:
	return maxf(float(md.get("min_height_m", 0.0)), float(md.get("min_level", 0)) * fh)

## True when another part stands on part `mi`: lifted to this part's
## top (within 1 m) with its centre inside this ring.
static func _capped(masses: Array, mi: int, ring: PackedVector2Array, fh: float) -> bool:
	var top := float((masses[mi] as Dictionary).get("height", 0.0))
	for j in masses.size():
		if j == mi or not (masses[j] is Dictionary):
			continue
		var o := masses[j] as Dictionary
		var lift := _lift_m(o, fh)
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
