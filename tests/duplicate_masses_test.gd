extends SceneTree

## Headless: godot --headless --script tests/duplicate_masses_test.gd
## Masses OSM maps twice must be built once, or their walls and roofs
## z-fight: one outline as a tagged way and a building relation (Helsinki's
## Eol, Panu), the same building:part twice, and a raised part whose floor
## lies below the top of the lower part it stands in (the band between
## drawn by both).

var _fails := 0

func _init() -> void:
	_parse_way_and_relation()
	_merge_and_stacks()
	_duplicate_parts()
	_seat_lifts()
	if _fails == 0:
		print("DUPLICATE MASSES OK: way+relation, repeated parts, raised part band")
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
