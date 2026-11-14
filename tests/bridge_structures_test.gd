extends SceneTree

## Headless: bridge structures (BridgeStructures) on the Länsiväylä
## crossing of Gräsanoja at Niittykumpu, Espoo (tests/fixtures/
## lansivayla_creek_bridge.json, © OpenStreetMap contributors, ODbL). Its
## three man_made=bridge outlines are three structures with their
## carriageways and links on them. Each stands at one level. No parapet
## stands inside an outline. The cycleway bridge along the creek passes
## under, never up through a deck. No barrier runs over a deck, and the
## next crossing west, which has no outline, is a structure cut from its
## roads that meets each of them. Synthetic cases: two outlines 6 m apart stay two
## structures, a road and a railway share one outline, a switchback
## footbridge with no outline keeps its ramps, and the ramp arm of a
## T-shaped outline comes down to its path instead of running flat.

const LAT := 60.1661
const LON := 24.7537
## Outline way -> the bridge ways on it.
const AREAS := {
	"way:576434349": ["way:8151614", "way:17492716"],
	"way:576434351": ["way:133114972"],
	"way:576434350": ["way:133114983"],
}

func _init() -> void:
	var failures: Array[String] = []
	var d := _fixture()
	var ground := GroundTruth.new(d)
	var surf := RoadBuilder._Surface.new(d, ground)
	var index := surf.road_bridges
	var plan := index.structures
	plan.prepare(surf, 1.0)
	var by_area := {}
	for a: Dictionary in d.bridge_areas:
		for s: BridgeStructures.Structure in plan.structures:
			# The deck is cut to its roads inside the mapped outline.
			if Geometry2D.is_point_in_polygon(RingGeometry.centroid(s.ring), a["points"]):
				by_area[str(a["osm_id"])] = s
	for id: String in AREAS:
		var s: BridgeStructures.Structure = by_area.get(id, null)
		if s == null:
			failures.append("outline %s must be a structure" % id)
			continue
		var ids: Array = []
		for li in s.members:
			ids.append(str(index.lines[li]["road"].get("osm_id", "")))
		ids.sort()
		var want: Array = (AREAS[id] as Array).duplicate()
		want.sort()
		if ids != want:
			failures.append("outline %s should carry %s, has %s" % [id, want, ids])
		_one_level(s, index, surf, failures, id)
	_no_parapets_inside(d, ground, by_area, failures)
	_cycleway_under(d, surf, by_area, failures)
	_barriers_stop(d, ground, failures)
	_fallback_west(d, surf, failures)
	_abutments(failures)
	_twins(failures)
	_road_and_rail(failures)
	_switchback(failures)
	_arm(failures)
	_rise_for_path(failures)
	if failures.is_empty():
		print("bridge structures: OK")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		quit(1)

## The crossing on level ground with its creek carved in: inland water
## takes its level from its banks, so the decks have little room over the
## cycleway along the bank.
func _fixture() -> LocationData:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/lansivayla_creek_bridge.json")
	var parsed := OsmParser.parse_features(text, LAT, LON)
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.seed_value = 7
	d.latitude = LAT
	d.longitude = LON
	d.roads = parsed["roads"]
	d.barriers = parsed["barriers"]
	d.waterways = parsed["waterways"]
	d.land_polygons = OsmGeometry.land_by_priority(parsed["land"])
	d.bridge_areas = parsed["bridge_areas"]
	return d

## Members meet: where two members' points share a cross-section of the
## structure (away from the abutments, where the deck eases onto the
## ground across its width), their decks agree within 2 cm.
func _one_level(s: BridgeStructures.Structure, index: RoadBridgeDecks.Index, surf: RoadBuilder._Surface,
		failures: Array[String], id: String) -> void:
	var decks: Array = []
	for li in s.members:
		var dense := RoadBuilder._resample(index.lines[li]["points"], 1.0)
		decks.append([dense, BridgeStructureMembers.heights(s, dense, index.lines[li], surf, 1.0)])
	var worst := 0.0
	for a in decks.size():
		for b in decks.size():
			if a == b:
				continue
			var pa: PackedVector2Array = decks[a][0]
			var pb: PackedVector2Array = decks[b][0]
			# Member b's deck at the same distance along the spine, between
			# its two points on either side of it.
			for i in pa.size():
				# Away from the abutments, where the deck eases onto the ground.
				if not s.contains(pa[i]) or absf(s.surface_at(pa[i]) - s.level_at(pa[i])) > 0.001:
					continue
				var at := s.along(pa[i])
				for j in pb.size() - 1:
					if not (s.contains(pb[j]) and s.contains(pb[j + 1])) \
							or absf(s.surface_at(pb[j]) - s.level_at(pb[j])) > 0.001 \
							or absf(s.surface_at(pb[j + 1]) - s.level_at(pb[j + 1])) > 0.001:
						continue
					var s0 := s.along(pb[j])
					var s1 := s.along(pb[j + 1])
					if absf(s1 - s0) < 1e-4 or at < minf(s0, s1) or at > maxf(s0, s1):
						continue
					var hb := lerpf(float(decks[b][1][j]), float(decks[b][1][j + 1]), (at - s0) / (s1 - s0))
					worst = maxf(worst, absf(float(decks[a][1][i]) - hb))
	if worst > 0.02:
		failures.append("%s: members should share one level, differ by %.2f m" % [id, worst])
	var lo := INF
	var hi := -INF
	for h in s.heights:
		lo = minf(lo, h)
		hi = maxf(hi, h)
	print("%s: level %.2f..%.2f m over %.0f m of spine" % [id, lo, hi, s.dist[s.dist.size() - 1]])

## No parapet (deck geometry a parapet's height over the level) stands
## inside an outline shrunk by 0.5 m.
func _no_parapets_inside(d: LocationData, ground: GroundTruth, by_area: Dictionary, failures: Array[String]) -> void:
	var roads := RoadBuilder.build_roads(d, ground)
	var verts := PackedVector3Array()
	for c in roads.get_children():
		if c is MeshInstance3D and str(c.name) == "Road_deck":
			verts = (c as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	roads.free()
	if verts.is_empty():
		failures.append("the crossing must build deck geometry")
		return
	for id: String in AREAS:
		var s: BridgeStructures.Structure = by_area.get(id, null)
		if s == null:
			continue
		var inner := Geometry2D.offset_polygon(s.ring, -0.5)
		var bad := 0
		for v in verts:
			var p := Vector2(v.x, v.z)
			if v.y < s.level_at(p) + 0.5:
				continue
			for ring: PackedVector2Array in inner:
				if Geometry2D.is_point_in_polygon(p, ring):
					bad += 1
		if bad > 0:
			failures.append("%s: %d parapet vertices stand inside the outline" % [id, bad])

## The cycleway bridge along the creek (layer 0) never stands up through
## a deck: wherever it is drawn under one it keeps the slab's depth and a
## little air; where the deck leaves it no room it runs into the abutment.
func _cycleway_under(d: LocationData, surf: RoadBuilder._Surface, by_area: Dictionary, failures: Array[String]) -> void:
	var way := _road(d, "way:576434362")
	if way.is_empty():
		failures.append("the cycleway bridge under the motorway must parse")
		return
	var pts: PackedVector2Array = way["points"]
	var dense := RoadBuilder._resample(pts, 1.0)
	var deck := RoadBridgeDecks.levelled(dense, float(way["width_m"]) * 0.5, 0, surf, 1.0, pts, "cycleway")
	var buried := RoadBridgeDecks._no_room(dense, deck, float(way["width_m"]) * 0.5, 0, surf, 1.0)
	var under := 0
	for id: String in AREAS:
		var s: BridgeStructures.Structure = by_area.get(id, null)
		if s == null:
			continue
		for i in dense.size():
			if not s.contains(dense[i]):
				continue
			under += 1
			if buried[i] == 0 and s.level_at(dense[i]) - deck[i] < s.depth + 0.3 - 0.01:
				failures.append("the cycleway is drawn %.2f m under a deck at %s" % [s.level_at(dense[i]) - deck[i], dense[i]])
				return
	if under == 0:
		failures.append("the cycleway must run under the decks")

## A road bridge outline with no approach on the ground (nothing holds it
## down) over a footway bridge on the layer under it: the deck rises to
## leave the footway HIDE_M.
func _rise_for_path(failures: Array[String]) -> void:
	var d := _flat()
	d.roads = [
		{"class": "primary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(-15, 0), Vector2(15, 0)])},
		{"class": "footway", "width_m": 2.5, "bridge": true, "layer": 0,
			"points": PackedVector2Array([Vector2(0, -30), Vector2(0, 30)])}]
	d.bridge_areas = [{"points": _rect(-15, -5, 15, 5), "layer": 1}]
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	var plan := surf.road_bridges.structures
	plan.prepare(surf, 1.0)
	if plan.structures.size() != 1:
		failures.append("the road outline should be one structure")
		return
	var s: BridgeStructures.Structure = plan.structures[0]
	var path: PackedVector2Array = d.roads[1]["points"]
	var dense := RoadBuilder._resample(path, 1.0)
	var deck := RoadBridgeDecks.levelled(dense, 1.25, 0, surf, 1.0, path, "footway")
	var least := INF
	for i in dense.size():
		if s.contains(dense[i]):
			least = minf(least, s.level_at(dense[i]) - deck[i])
	if least < RoadBridgeDecks.HIDE_M - 0.05:
		failures.append("a footway under a free deck should pass %.1f m under it, has %.2f m" % [RoadBridgeDecks.HIDE_M, least])

## No barrier piece is drawn on an outline (the guard rails between the
## carriageways and the walls along the creek stop at the abutments).
func _barriers_stop(d: LocationData, ground: GroundTruth, failures: Array[String]) -> void:
	var holder := Node3D.new()
	StreetProps._barriers(holder, d, ground, {"m2u": 1.0, "season": 0})
	var bad := 0
	for c in holder.get_children():
		if not (c is MeshInstance3D):
			continue
		var mesh := (c as MeshInstance3D).mesh
		for sidx in mesh.get_surface_count():
			for v: Vector3 in (mesh.surface_get_arrays(sidx)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				for a: Dictionary in d.bridge_areas:
					if Geometry2D.is_point_in_polygon(Vector2(v.x, v.z), a["points"]):
						bad += 1
	holder.free()
	if bad > 0:
		failures.append("%d barrier vertices stand on a bridge outline" % bad)

## The crossing 70 m west has no outline: each of its carriageways and
## links is still a structure, its deck cut from the road, and meets its
## own approaches (built way by way on one copied profile, a deck stood
## 0.75 m under its own road).
func _fallback_west(d: LocationData, surf: RoadBuilder._Surface, failures: Array[String]) -> void:
	var plan := surf.road_bridges.structures
	plan.prepare(surf, 1.0)
	for id: String in ["way:133114973", "way:133114975", "way:133114982", "way:133114986"]:
		var way := _road(d, id)
		if way.is_empty():
			failures.append("the western bridge way %s must parse" % id)
			return
		var pts: PackedVector2Array = way["points"]
		var s := plan.of_line(surf.road_bridges.line_of(pts))
		if s == null:
			failures.append("%s, on no outline, should still be on a structure" % id)
			return
		var li := surf.road_bridges.line_of(pts)
		_meets(s, li, surf, failures, id, 0.3)

## Where the deck has no room over the cycleway along the bank, it still
## meets its approaches at both abutments (no step up onto the bridge),
## and the cycleway runs into the abutment rather than up through it.
func _abutments(failures: Array[String]) -> void:
	var d := _fixture()
	var ground := GroundTruth.new(d)
	var surf := RoadBuilder._Surface.new(d, ground)
	var plan := surf.road_bridges.structures
	plan.prepare(surf, 1.0)
	var by_area := {}
	for a: Dictionary in d.bridge_areas:
		for s: BridgeStructures.Structure in plan.structures:
			# The deck is cut to its roads inside the mapped outline.
			if Geometry2D.is_point_in_polygon(RingGeometry.centroid(s.ring), a["points"]):
				by_area[str(a["osm_id"])] = s
	# Nor does the cycleway stand up through them.
	_no_parapets_inside(d, ground, by_area, failures)
	for s: BridgeStructures.Structure in plan.structures:
		for li in s.members:
			_meets(s, li, surf, failures, "a deck", 1.0)

## The deck of index line `li` on `s` meets the ground where its road goes
## on at either end: at the end of its approach slab (BridgeApproaches) where
## it has one, else at the mapped end (over water: the first dry ground; on a
## bank's edge: the road a metre on).
func _meets(s: BridgeStructures.Structure, li: int, surf: RoadBuilder._Surface, failures: Array[String],
		id: String, tol: float) -> void:
	var line: Dictionary = surf.road_bridges.lines[li]
	var mapped: PackedVector2Array = line["points"]
	var pts := s.points_of(li, line)
	for side_i in 2:
		var at := mapped[0] if side_i == 0 else mapped[mapped.size() - 1]
		var back := mapped[1] if side_i == 0 else mapped[mapped.size() - 2]
		var road := BridgeLandings.approach_from(surf, at, (at - back).normalized())
		if road.is_empty():
			continue  # A joint in mid-air, not an abutment.
		var p := pts[0] if side_i == 0 else pts[pts.size() - 1]
		# The road a metre on: the ground at the end itself may be the edge
		# of a bank the deck's abutment stands on.
		var on := p + (p - (pts[1] if side_i == 0 else pts[pts.size() - 2])).normalized()
		var ref := maxf(surf.height(p.x, p.y), surf.height(on.x, on.y))
		if surf.ground.water_at(p.x, p.y) > 0.0:
			var dry := BridgeStructures._first_dry(road, surf, BridgeStructures.ABUTMENT_SEEK_M)
			ref = dry if not is_nan(dry) else ref
		var step := s.surface_at(p) - ref
		if absf(step) > tol:
			failures.append("%s should meet its approach, stands %.2f m off it at %s" % [id, step, p])

func _road(d: LocationData, id: String) -> Dictionary:
	for r: Variant in d.roads:
		if r is Dictionary and str((r as Dictionary).get("osm_id", "")) == id:
			return r
	return {}

func _flat() -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.latitude = 60.17
	d.longitude = 24.77
	d.land_polygons = [{"class": "water", "holes": [], "points": PackedVector2Array([
		Vector2(-5, -300), Vector2(5, -300), Vector2(5, 300), Vector2(-5, 300)])}]
	return d

func _rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1), Vector2(x0, z0)])

## Two outlines 6 m apart, a carriageway on each: two structures.
func _twins(failures: Array[String]) -> void:
	var d := _flat()
	d.roads = [
		{"class": "primary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(-20, -6.5), Vector2(20, -6.5)])},
		{"class": "primary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(-20, 6.5), Vector2(20, 6.5)])}]
	d.bridge_areas = [{"points": _rect(-20, -10.5, 20, -3), "layer": 1},
		{"points": _rect(-20, 3, 20, 10.5), "layer": 1}]
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	var plan := surf.road_bridges.structures
	if plan.structures.size() != 2:
		failures.append("two outlines 6 m apart should stay two structures, got %d" % plan.structures.size())
	elif plan.of_line(0) == plan.of_line(1):
		failures.append("each twin carriageway belongs to its own outline")

## A road and a railway on one outline share the structure.
func _road_and_rail(failures: Array[String]) -> void:
	var d := _flat()
	d.roads = [{"class": "secondary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
		"points": PackedVector2Array([Vector2(-20, -5), Vector2(20, -5)])}]
	d.railways = [{"class": "rail", "bridge": true, "layer": 1, "gauge_m": 1.524, "width_m": 3.0,
		"points": PackedVector2Array([Vector2(-20, 4), Vector2(20, 4)])}]
	d.bridge_areas = [{"points": _rect(-20, -10, 20, 8), "layer": 1}]
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	var plan := surf.road_bridges.structures
	if plan.structures.size() != 1:
		failures.append("a road and rail outline should be one structure, got %d" % plan.structures.size())
		return
	var s: BridgeStructures.Structure = plan.structures[0]
	if s.members.size() != 1 or s.rails.size() != 1:
		failures.append("the shared outline should list the road and the railway: %d roads, %d rails" % [s.members.size(), s.rails.size()])

## A switchback footbridge with no outline keeps its own ramps.
func _switchback(failures: Array[String]) -> void:
	var d := _flat()
	d.land_polygons = []
	var pts := PackedVector2Array([Vector2(-30, 0), Vector2(0, 0), Vector2(0, 4), Vector2(-30, 4)])
	d.roads = [{"class": "footway", "width_m": 2.5, "bridge": true, "layer": 1, "points": pts}]
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	if surf.road_bridges.structures.of_line(0) != null:
		failures.append("a footbridge with no outline must not be a structure")
	var dense := RoadBuilder._resample(pts, 2.0)
	var deck := RoadBridgeDecks.levelled(dense, 1.25, 1, surf, 1.0, pts, "footway")
	var ground := surf.height(-30, 0)
	if deck[0] - ground > 0.5 or deck[deck.size() / 2] - ground < 2.0:
		failures.append("a switchback footbridge should ramp from the ground: ends %.1f m, middle %.1f m" % [
			deck[0] - ground, deck[deck.size() / 2] - ground])

## A T-shaped outline: a road bridge and a cycleway arm leaving its side.
## The arm meets the road's level and comes down to the ground at its far
## end.
func _arm(failures: Array[String]) -> void:
	var d := _flat()
	d.land_polygons = []
	d.roads = [
		{"class": "primary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(0, -20), Vector2(0, 20)])},
		{"class": "cycleway", "width_m": 3.0, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(4, 0), Vector2(60, 0)])}]
	d.bridge_areas = [{"layer": 1, "points": PackedVector2Array([Vector2(-4, -20), Vector2(4, -20),
		Vector2(4, -2), Vector2(60, -2), Vector2(60, 2), Vector2(4, 2), Vector2(4, 20), Vector2(-4, 20), Vector2(-4, -20)])}]
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	var plan := surf.road_bridges.structures
	plan.prepare(surf, 1.0)
	if plan.structures.size() != 1 or (plan.structures[0] as BridgeStructures.Structure).members.size() != 2:
		failures.append("a T-shaped outline should be one structure with both ways")
		return
	var s: BridgeStructures.Structure = plan.structures[0]
	var ground := surf.height(60, 0)
	var main := s.level_at(Vector2(0, 0))
	var near := s.level_at(Vector2(4.5, 0))
	var far := s.level_at(Vector2(59.5, 0))
	if absf(near - main) > 0.15:
		failures.append("the arm should meet the road's level: %.2f vs %.2f m" % [near, main])
	if far - ground > 0.6:
		failures.append("the arm should come down to its path, ends %.2f m over the ground" % (far - ground))
	var mid := s.level_at(Vector2(32, 0))
	if mid > maxf(main, far) + 0.1:
		failures.append("the arm should ramp straight down, not hump: %.2f m at its middle" % (mid - ground))
	print("T arm: road %.2f m, arm start %.2f m, far end %.2f m over the ground" % [main - ground, near - ground, far - ground])
