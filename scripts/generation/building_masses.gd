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
	"roof_material", "roof_height_m", "roof_levels", "roof_dir", "roof_orient"]
## A part this share of the largest can carry a tower's roofline.
const MAIN_MIN_SHARE := 0.12

static var _plans: Dictionary = {}
static var _mutex := Mutex.new()

## Buildings whose mapped parts leave over a tenth of the outline uncovered,
## and that ground in m²: it stands unbuilt. Logged per build (BuildingBuilder)
## before deciding whether to fill it.
static var partial_outlines := 0
static var partial_lost_m2 := 0.0

static func begin_build() -> void:
	_mutex.lock()
	_plans.clear()
	partial_outlines = 0
	partial_lost_m2 = 0.0
	_mutex.unlock()

## Releases the plans (each holds a copy of its building's tags) once the
## city is built; nothing reads them after the build.
static func end_build() -> void:
	_mutex.lock()
	_plans.clear()
	_mutex.unlock()

## A raised part standing inside a lower part whose top is above the
## raised part's floor (min_level × the style's floor height under a
## tagged height) drew that band twice: inside the lower part, but on a
## shared edge in the same plane as its wall, the two facades z-fought.
## Such a part now starts at the lower part's wall top.
static func _seat_lifts(out: Array) -> void:
	var grow := 0.05 * WorldScale.metres_to_units()
	for x in out:
		var xm := x as Dictionary
		var lift := float(xm["min_m"])
		if lift <= 0.0:
			continue
		var seat := lift
		var xbox := RingGeometry.aabb(xm["ring"])
		for y in out:
			var ym := y as Dictionary
			var top := float(ym["wall_m"])
			if float(ym["min_m"]) > 0.0 or top <= seat + 0.05 or top > float(xm["wall_m"]) - 0.5 \
					or not RingGeometry.aabb(ym["ring"]).grow(grow).encloses(xbox) \
					or not _within(xm["ring"], ym["ring"]) or _in_hole(xm["centre"], ym["holes"]):
				continue
			seat = top
		if seat > lift:
			_lower_to(xm, seat)

## How far (m) a support's top may fall short of a lifted part's floor and
## still count as carrying it, and the widest gap (m) a lift is brought down
## across.
const FLOAT_SLACK_M := 1.5
const FLOAT_MAX_GAP_M := 15.0

## A lifted part over a mass whose top is lower (or over footprint no mass
## covers) hung in the air with open sky under it (Seoul: a box over a
## tower's roof). Within FLOAT_MAX_GAP_M it comes down to the highest top
## under its centre; with nothing under it, a part of at least
## OsmParser.GROUND_ORPHAN_M2 stands on the ground (as _ground_orphans does
## for a part outside every outline: keep the two in step). Smaller ones
## (skybridges, canopies) and bridge/roof buildings keep their lift.
static func _seat_floaters(b: Dictionary, out: Array) -> void:
	if str(b.get("kind", "")) in ["bridge", "roof"] or float(b.get("min_height_m", 0.0)) > 0.0 \
			or int(b.get("min_level", 0)) > 0:
		return
	var m2 := WorldScale.metres_to_units() * WorldScale.metres_to_units()
	# Judged on the lifts as planned, so the outcome does not depend on the
	# order the masses are visited in.
	var lifts: Array = out.map(func(m: Dictionary) -> float: return float(m["min_m"]))
	for xi in out.size():
		var xm := out[xi] as Dictionary
		var lift: float = lifts[xi]
		if lift <= 0.0:
			continue
		var centre: Vector2 = xm["centre"]
		var below := -1.0
		var carried := false
		for yi in out.size():
			var ym := out[yi] as Dictionary
			if yi == xi or float(lifts[yi]) >= lift \
					or not Geometry2D.is_point_in_polygon(centre, ym["ring"]) \
					or _in_hole(centre, ym["holes"]):
				continue
			var top := float(ym["wall_m"])
			# A pitched roof under the part carries it up to its ridge.
			if top + float(ym["rh_m"]) >= lift - FLOAT_SLACK_M:
				carried = true
				break
			below = maxf(below, top)
		if carried:
			continue
		var wall := float(xm["wall_m"])
		var seat := -1.0
		if below >= 0.0 and lift - below <= FLOAT_MAX_GAP_M:
			seat = below
		elif below < 0.0 and absf(RingGeometry.signed_area(xm["ring"])) / m2 >= OsmParser.GROUND_ORPHAN_M2:
			seat = 0.0
		if seat < 0.0 or wall - seat < 0.5:
			continue
		_lower_to(xm, seat)

## Moves a mass's floor to `seat` (m), keeping its storey height.
static func _lower_to(xm: Dictionary, seat: float) -> void:
	var wall := float(xm["wall_m"])
	var lift := float(xm["min_m"])
	xm["storeys"] = maxi(1, roundi(float(int(xm["storeys"])) * (wall - seat) / (wall - lift)))
	xm["min_m"] = seat

static func _in_hole(p: Vector2, holes: Array) -> bool:
	for h in holes:
		if Geometry2D.is_point_in_polygon(p, h as PackedVector2Array):
			return true
	return false

## True when every vertex of `inner` lies inside `outer` or on its edge.
static func _within(inner: PackedVector2Array, outer: PackedVector2Array) -> bool:
	var tol := 0.05 * WorldScale.metres_to_units()
	for p in inner:
		if Geometry2D.is_point_in_polygon(p, outer):
			continue
		var on := false
		for i in outer.size():
			var q := Geometry2D.get_closest_point_to_segment(p, outer[i], outer[(i + 1) % outer.size()])
			if q.distance_to(p) <= tol:
				on = true
				break
		if not on:
			return false
	return true

## "@<osm id>" of `b` ("" without one), telling apart two buildings
## mapped on one outline.
static func _src_tag(b: Dictionary) -> String:
	var src := str(b.get("osm_id", ""))
	return "" if src.is_empty() else "@" + src

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
	# Buildings OSM stacks on one outline (a roof canopy over a building,
	# which OsmParser keeps apart) must neither share a plan nor a mass key:
	# PartyWalls would read the two as one mass.
	ck += _src_tag(b)
	_mutex.lock()
	if _plans.has(ck):
		var cached: Array = _plans[ck] as Array
		_mutex.unlock()
		return cached
	_mutex.unlock()
	# An untagged building borrows a tagged neighbour's finish and date
	# before its look resolves (NeighbourEvidence), so a block is built alike.
	b = NeighbourEvidence.with_peers(b, ctx)
	var look := BuildingHeights._look_for(b, ctx)
	var parent_res := BuildingHeights._resolve_total(b, b, ctx, {}, look)
	var legacy := not b.has("height_source")
	var parent_shape := BuildingHeights._effective_shape(str(b.get("roof_shape", "")),
		str(look["roof_shape"]), legacy)
	var fh := float(look["floor_h"])
	var masses: Array = b.get("parts", [])
	var single := masses.is_empty()
	if not single:
		_note_partial(b)
	if single:
		var stepped := TowerMassing.stack(b, look, parent_res, ctx, parent_shape)
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
		_seat_lifts(out)
		_seat_floaters(b, out)
	_mutex.lock()
	if _plans.has(ck):
		var raced: Array = _plans[ck] as Array
		_mutex.unlock()
		return raced
	_plans[ck] = out
	_mutex.unlock()
	return out

## Counts `b` in partial_outlines when its parts cover under 90% of it.
static func _note_partial(b: Dictionary) -> void:
	var fp: Variant = b.get("footprint", null)
	if not (fp is PackedVector2Array) or (fp as PackedVector2Array).size() < 3:
		return
	var outline := fp as PackedVector2Array
	var total := absf(RingGeometry.signed_area(outline))
	if total <= 0.0:
		return
	var covered := 0.0
	for p in b.get("parts", []):
		var pf: Variant = (p as Dictionary).get("footprint", null)
		if pf is PackedVector2Array and (pf as PackedVector2Array).size() >= 3:
			for piece in Geometry2D.intersect_polygons(outline, pf):
				covered += absf(RingGeometry.signed_area(piece))
	if covered < total * 0.9:
		var m2 := WorldScale.metres_to_units() * WorldScale.metres_to_units()
		_mutex.lock()
		partial_outlines += 1
		partial_lost_m2 += (total - minf(covered, total)) / m2
		_mutex.unlock()

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
	# A generated tower's roofline detail belongs on its top, not on the
	# base the upper tiers stand on (TowerMassing).
	var main_mass := masses.size() - 1 if masses.back() is Dictionary \
		and bool((masses.back() as Dictionary).get("stack_top", false)) else _tower_main(masses, look)
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
		var min_m := _lift_m(md, fh)
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
		if bool(md.get("suomenlinna", false)):
			b_eff["fortress_form"] = str(md.get("fortress_form", ""))
		NycCrownMaterials.apply(b, md, b_eff)
		NycWaterfrontMaterials.apply(b, md, b_eff)
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
		# A mapped `roof:angle` fixes the pitch of a ridged roof: it rises
		# tan(angle) over half the span (the span the roof height is built on).
		var angle := float(b.get("roof_angle", 0.0))
		if not single and float(md.get("roof_angle", 0.0)) > 0.0:
			angle = float(md["roof_angle"])
		if roof_tag <= 0.0 and angle > 0.0 and shape in ["gabled", "hipped", "half-hipped", "pyramidal"]:
			var span := BuildingHeights._ring_span_m(ring)
			roof_tag = clampf(tan(deg_to_rad(angle)) * span * 0.5, 0.8, maxf(span * 0.9, 0.8))
		var total := float(res["total_m"])
		var rh := BuildingHeights._roof_height_m(shape, BuildingHeights._ring_span_m(ring),
			roof_tag, float(look["pitch"]))
		var wall := total
		if str(res["source"]) != "levels" or legacy:
			rh = minf(rh, maxf(total - 0.5, 0.0))
			wall = total - rh
		if legacy:
			wall = clampf(wall, 7.2, 76.0)
		# A part that is only roof (a dome on its drum: min_height at the
		# drum top, the rest roof:height) keeps its lift; any other min
		# above the top is a tagging slip, not a floating box.
		if min_m > wall - 1.0 and not (rh > 0.0 and min_m <= wall + 0.01):
			min_m = 0.0
		var storeys := int(md.get("levels", b.get("levels", 0) if single else 0))
		if storeys > 0 and min_m > 0.0:
			storeys = maxi(1, storeys - int(md.get("min_level", 0)))
		if storeys <= 0:
			storeys = maxi(1, roundi((float(res["total_m"]) - min_m) / fh))
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
		var part_look := look
		if MaterialLibrary.MATERIAL_TAGS.get(str(b_eff.get("material", "")), "") == "glass" \
				and (str(look.get("wall_set", "")) != "glass" or (min_m > 0.0 and wall - min_m < fh)):
			# A glazed lantern/atrium on a masonry building needs glazing
			# relief, not the parent's stone sills and string courses.
			part_look = look.duplicate()
			part_look["wall_set"] = "glass"
			part_look["pattern"] = "curtain"
			part_look["relief"] = {"mullion": true}
		out.append({"ring": ring, "holes": holes, "centre": Vector2(cx, cz),
			"key": key_of(cx, cz) + "#%d" % mi + _src_tag(b), "wall_m": wall, "min_m": min_m,
			"rh_m": rh, "shape": shape, "storeys": storeys, "b_eff": b_eff,
			"own_parts": not (b.get("parts", []) as Array).is_empty(),
			# A mapped landmark's parts are its towers and domes: no made-up
			# tower, stacks or dormers on any of them.
			"main": mi == main_mass and not bool(b.get("mapped_landmark", false)),
			"look": part_look})
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
## The mass that carries the roofline: a mapped tower's tallest substantial
## part (its largest is often the podium), else the largest.
static func _tower_main(masses: Array, look: Dictionary) -> int:
	var largest := _largest(masses)
	if not (str(look.get("kind", "")) in TowerMassing.KINDS) or not (masses[largest] is Dictionary):
		return largest
	var lot := absf(RingGeometry.signed_area((masses[largest] as Dictionary).get("footprint", PackedVector2Array())))
	var best := largest
	var tallest := float((masses[largest] as Dictionary).get("height", 0.0))
	for i in masses.size():
		if not (masses[i] is Dictionary):
			continue
		var fp: Variant = (masses[i] as Dictionary).get("footprint", null)
		if fp is PackedVector2Array and (fp as PackedVector2Array).size() >= 3 \
				and absf(RingGeometry.signed_area(fp as PackedVector2Array)) >= lot * MAIN_MIN_SHARE \
				and float((masses[i] as Dictionary).get("height", 0.0)) > tallest:
			tallest = float((masses[i] as Dictionary).get("height", 0.0))
			best = i
	return best

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
