extends SceneTree

## Headless: godot --headless --script tests/duplicate_masses_test.gd
## Masses OSM maps twice must be built once, or their walls and roofs
## z-fight: one outline as a tagged way and a building relation (Helsinki's
## Eol, Panu), the same building:part twice, and a raised part whose floor
## lies below the top of the lower part it stands in (the band between
## drawn by both). Parts nest where they stand: a U-shaped part whose
## centroid sits in its notch, or a ring-shaped part whose centroid lands
## on the small building in its courtyard, goes to the building covering
## it, and an orphan part never takes another part as its own.

var _fails := 0

func _init() -> void:
	_parse_way_and_relation()
	_merge_and_stacks()
	_duplicate_parts()
	_seat_lifts()
	_nesting()
	_keyhole_overlap()
	_far_nesting()
	_orphan_seats()
	if _fails == 0:
		print("DUPLICATE MASSES OK: way+relation, repeated parts, raised part band, part nesting, keyhole overlap, far nesting, orphan seats")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)

func _geom(pts: Array) -> Array:
	var out: Array = []
	for p in pts:
		out.append({"lat": p[0], "lon": p[1]})
	return out

func _parse_way_and_relation() -> void:
	var ring := [[60.1700, 24.9500], [60.1700, 24.9504], [60.1703, 24.9504], [60.1703, 24.9500], [60.1700, 24.9500]]
	var other := [[60.1710, 24.9500], [60.1710, 24.9504], [60.1713, 24.9504], [60.1713, 24.9500], [60.1710, 24.9500]]
	var payload := {"elements": [
		{"type": "way", "id": 1, "tags": {"building": "yes"}, "geometry": _geom(ring)},
		{"type": "relation", "id": 2, "tags": {"type": "multipolygon", "building": "office",
			"height": "21", "name": "Eol"},
			"members": [{"type": "way", "ref": 1, "role": "outer", "geometry": _geom(ring)}]},
		{"type": "way", "id": 3, "tags": {"building": "yes"}, "geometry": _geom(other)},
	]}
	var parsed := OsmParser.parse_features(JSON.stringify(payload), 60.170, 24.950)
	var bs: Array = parsed["buildings"]
	_check(bs.size() == 2, "one outline mapped twice builds once (got %d)" % bs.size())
	var eol := bs.filter(func(b: Dictionary) -> bool: return str(b.get("name", "")) == "Eol")
	_check(eol.size() == 1 and str(eol[0].get("osm_id", "")) == "relation:2",
		"the copy with a height and name stays")
	_check(eol.size() == 1 and OsmParser.ids_of(eol[0]) == ["relation:2", "way:1"],
		"the dropped copy's id stays reachable as an alias")

func _merge_and_stacks() -> void:
	var sq := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var hole := PackedVector2Array([Vector2(4, 4), Vector2(6, 4), Vector2(6, 6), Vector2(4, 6)])
	var way := {"footprint": sq, "osm_id": "way:5", "height": 40.0, "height_source": "tag_height",
		"levels": 0, "holes": [], "name": ""}
	var rel := {"footprint": sq, "osm_id": "relation:6", "height": 10.0, "height_source": "default",
		"levels": 0, "holes": [hole], "name": ""}
	var canopy := {"footprint": sq, "osm_id": "way:7", "kind": "roof", "min_height_m": 3.0,
		"height": 4.0, "height_source": "tag_height", "holes": []}
	var bs := [way, rel, canopy]
	OsmParser._drop_duplicate_buildings(bs)
	_check(bs.size() == 2, "a canopy on the same outline is not a copy (got %d)" % bs.size())
	var kept: Dictionary = bs[0]
	_check(str(kept["osm_id"]) == "relation:6" and (kept["holes"] as Array).size() == 1
		and is_equal_approx(float(kept["height"]), 40.0) and str(kept["height_source"]) == "tag_height",
		"the kept copy takes the other's mapped height")
	_check(OsmParser.ids_of(kept).has("way:5"), "the merged way id is an alias")

func _duplicate_parts() -> void:
	var sq := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var turned := PackedVector2Array([Vector2(10, 0), Vector2(10, 10), Vector2(0, 10), Vector2(0, 0), Vector2(10, 0)])
	var parts := [
		{"tags": {"building:part": "yes", "height": "12"}, "points": sq},
		{"tags": {"building:part": "yes", "height": "12"}, "points": turned},
		{"tags": {"building:part": "yes", "height": "20"}, "points": sq},
	]
	parts.append({"tags": {"building:part": "yes", "height": "12"}, "points": sq, "holes": [
		PackedVector2Array([Vector2(4, 4), Vector2(6, 4), Vector2(6, 6), Vector2(4, 6)])]})
	parts.append({"tags": {"building:part": "yes", "height": "12", "building:colour": "red"}, "points": sq})
	OsmParser._drop_duplicate_parts(parts)
	_check(parts.size() == 4, "a repeated part is kept once; courtyards and finishes differ (got %d)" % parts.size())

func _seat_lifts() -> void:
	var podium := PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(20, 20), Vector2(0, 20)])
	var tower := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var beside := PackedVector2Array([Vector2(30, 0), Vector2(40, 0), Vector2(40, 10), Vector2(30, 10)])
	var out := [
		{"ring": podium, "holes": [], "centre": Vector2(10, 10), "min_m": 0.0, "wall_m": 29.0, "storeys": 9},
		{"ring": tower, "holes": [], "centre": Vector2(5, 5), "min_m": 26.0, "wall_m": 60.0, "storeys": 10},
		{"ring": beside, "holes": [], "centre": Vector2(35, 5), "min_m": 26.0, "wall_m": 60.0, "storeys": 10},
	]
	BuildingMasses._seat_lifts(out)
	_check(is_equal_approx(float(out[1]["min_m"]), 29.0), "raised part inside the podium starts at its top")
	_check(int(out[1]["storeys"]) == 9, "its storeys shrink with the wall (got %d)" % int(out[1]["storeys"]))
	_check(is_equal_approx(float(out[2]["min_m"]), 26.0), "a raised part outside it keeps its lift")

func _ring(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(p[0], p[1]))
	return out

func _building(id: String, ring: PackedVector2Array) -> Dictionary:
	var b := OsmTags._building_entry({"building": "yes"}, ring, OsmGeometry._ring_aabb(ring))
	b["osm_id"] = id
	return b

func _part(id: String, ring: PackedVector2Array) -> Dictionary:
	return {"tags": {"building:part": "yes", "height": "12"}, "points": ring,
		"aabb": OsmGeometry._ring_aabb(ring), "osm_id": id}

func _parts_of(b: Dictionary) -> Array:
	return (b["parts"] as Array).map(func(p: Dictionary) -> String: return str(p["osm_id"]))

func _nesting() -> void:
	# A U whose centroid (x 15, z ~13.6) lies in its own open notch.
	var u := _ring([[0, 0], [30, 0], [30, 30], [20, 30], [20, 10], [10, 10], [10, 30], [0, 30]])
	var u_home := _building("way:1", u)
	var bs := [u_home]
	OsmParser._nest_parts(bs, [_part("way:2", u)])
	_check(bs.size() == 1 and _parts_of(u_home) == ["way:2"],
		"a part whose centroid falls in its notch nests in the building it fills")
	# A block mapped as a U part, with a small building in its notch at
	# the part's centroid: the part belongs to the block.
	var block := _building("way:3", _ring([[0, 0], [30, 0], [30, 30], [0, 30]]))
	var kiosk := _building("way:4", _ring([[13, 11], [17, 11], [17, 16], [13, 16]]))
	bs = [block, kiosk]
	OsmParser._nest_parts(bs, [_part("way:5", u)])
	_check(_parts_of(block) == ["way:5"] and _parts_of(kiosk).is_empty(),
		"a part barely touching its centroid's building goes to the one covering it")
	# A steeple tier half over its tower outline, wholly inside the church:
	# the tower its centroid stands in keeps it.
	var church := _building("way:6", _ring([[0, 0], [40, 0], [40, 40], [0, 40]]))
	var tower := _building("way:7", _ring([[10, 10], [20, 10], [20, 20], [10, 20]]))
	bs = [church, tower]
	OsmParser._nest_parts(bs, [_part("way:8", _ring([[12, 6], [22, 6], [22, 16], [12, 16]]))])
	_check(_parts_of(tower) == ["way:8"] and _parts_of(church).is_empty(),
		"a part well over its centroid's building stays there")
	# Two parts outside every building: the small one inside the large one
	# stays its own mass, so the large one keeps drawing its mass.
	bs = []
	OsmParser._nest_parts(bs, [_part("way:9", _ring([[100, 0], [140, 0], [140, 40], [100, 40]])),
		_part("way:10", _ring([[110, 10], [120, 10], [120, 20], [110, 20]]))])
	_check(bs.size() == 2 and bs.all(func(b: Dictionary) -> bool:
		return bool(b.get("orphan_part", false)) and (b["parts"] as Array).is_empty()),
		"an orphan part is never another part's parent")
	# A part next to a building, touching it on a sliver, stays an orphan.
	var lone := _building("way:11", _ring([[0, 0], [10, 0], [10, 10], [0, 10]]))
	bs = [lone]
	OsmParser._nest_parts(bs, [_part("way:12", _ring([[9, 0], [30, 0], [30, 10], [9, 10]]))])
	_check(bs.size() == 2 and _parts_of(lone).is_empty(), "a part mostly outside every building stays an orphan")
	# A U part with only a kiosk at its centroid: an orphan, the kiosk keeps its mass.
	var stall := _building("way:13", _ring([[13, 11], [17, 11], [17, 16], [13, 16]]))
	bs = [stall]
	OsmParser._nest_parts(bs, [_part("way:14", u)])
	_check(bs.size() == 2 and _parts_of(stall).is_empty(),
		"a part barely touching its centroid's building, with no better home, is an orphan")
	# A ring part (a courtyard hole) round a hall filling the courtyard:
	# the hall covers none of the part, so it does not take it.
	var hall := _building("way:15", _ring([[4, 4], [26, 4], [26, 26], [4, 26]]))
	var ring_part := _part("way:16", _ring([[0, 0], [30, 0], [30, 30], [0, 30]]))
	ring_part["holes"] = [_ring([[4, 4], [26, 4], [26, 26], [4, 26]])]
	bs = [hall]
	OsmParser._nest_parts(bs, [ring_part])
	_check(bs.size() == 2 and _parts_of(hall).is_empty(), "a part's courtyard does not count as covered")
	# An outline mapped as a tower's base inside its podium part: the
	# centroid's building covers a sliver of the podium, but the podium
	# covers all of it, so the podium is still its part.
	var base := _building("way:17", _ring([[15, 15], [25, 15], [25, 25], [15, 25]]))
	bs = [base]
	OsmParser._nest_parts(bs, [_part("way:18", _ring([[0, 0], [40, 0], [40, 40], [0, 40]]))])
	_check(bs.size() == 1 and _parts_of(base) == ["way:18"],
		"a podium part round its tower outline nests in it")
	# Two buildings cover a U part alike: the smaller one takes it.
	var wing := _building("way:22", _ring([[0, 0], [30, 0], [30, 30], [0, 30]]))
	var nave := _building("way:23", _ring([[-20, -20], [50, -20], [50, 50], [-20, 50]]))
	bs = [nave, wing]
	OsmParser._nest_parts(bs, [_part("way:24", u)])
	_check(_parts_of(wing) == ["way:24"] and _parts_of(nave).is_empty(),
		"of two buildings covering a part alike, the smaller takes it")

# A ring-shaped part mapped as one self-touching way: the clipper returns
# its courtyard as a clockwise piece, which must count against the overlap.
func _keyhole_overlap() -> void:
	var keyhole := _ring([[0, 0], [40, 0], [40, 40], [0, 40], [0, 20], [10, 20], [10, 30],
		[30, 30], [30, 10], [10, 10], [10, 20], [0, 20]])
	var big := _ring([[-10, -10], [50, -10], [50, 50], [-10, 50]])
	var got := OsmGeometry.overlap_area(keyhole, big)
	_check(absf(got - 1200.0) < 0.5, "a keyhole way's courtyard is not overlap (got %.1f, want 1200)" % got)

# FarCityFetcher nests like OsmParser: a U part whose centroid lies in its
# notch joins the tower it fills instead of standing as its own tower.
func _far_nesting() -> void:
	var u := _ring([[0, 0], [30, 0], [30, 30], [20, 30], [20, 10], [10, 10], [10, 30], [0, 30]])
	var tower := _building("way:20", u)
	var towers := [tower]
	var part := _part("way:21", u)
	part["holes"] = []
	part["tags"] = {"building:part": "yes", "height": "80"}
	FarCityFetcher._nest_parts(towers, [part])
	_check(towers.size() == 1 and _parts_of(tower) == ["way:21"],
		"a far part whose centroid falls in its notch nests in its tower (got %d towers)" % towers.size())

func _orphan(id: String, ring: PackedVector2Array, min_m: float, top: float, min_level: int = 0) -> Dictionary:
	var o := _building(id, ring)
	o["orphan_part"] = true
	o["min_height_m"] = min_m
	o["min_level"] = min_level
	o["height"] = top
	return o

# Lifted orphan parts stand on the orphan below them: the support is
# grounded first whatever the order, and only the floor height moves.
func _orphan_seats() -> void:
	var podium := _ring([[0, 0], [30, 0], [30, 30], [0, 30]])
	var crown := _ring([[5, 5], [25, 5], [25, 25], [5, 25]])
	var upper := _orphan("way:30", crown, 40.0, 80.0)
	var lower := _orphan("way:31", podium, 30.0, 45.0)
	var bs := [upper, lower]
	OsmParser._ground_orphans(bs)
	_check(float(lower["min_height_m"]) == 0.0, "an unsupported lifted orphan is grounded")
	_check(float(upper["min_height_m"]) == 45.0,
		"an orphan listed before its support still starts on its top (got %s)" % upper["min_height_m"])
	var by_level := _orphan("way:32", crown, 0.0, 80.0, 10)
	var ground := _orphan("way:33", podium, 0.0, 45.0)
	bs = [by_level, ground]
	OsmParser._ground_orphans(bs)
	_check(float(by_level["min_height_m"]) == 45.0 and int(by_level["min_level"]) == 10,
		"a seat moves only the floor height, min_level keeps its storey count")
