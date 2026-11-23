extends SceneTree

## Headless: godot --headless --script tests/rail_viaduct_test.gd
## A viaduct mapped a bridge way per track: no parapet stands between
## two tracks side by side, the outer edges keep theirs, and a track on
## its own keeps both. Tracks side by side share one deck level
## (RailDecks).

func _init() -> void:
	_run()

func _track(z: float) -> Dictionary:
	return OsmTags._rail_entry({"railway": "rail", "bridge": "yes"},
		PackedVector2Array([Vector2(-80, z), Vector2(80, z)]))

func _batch_verts(data: LocationData, tracks: Array, key: String) -> int:
	var surf := RoadBuilder._Surface.new(data, GroundTruth.new(data))
	var batches := {}
	var beside := RailBuilder.deck_index(tracks, 1.0)
	data.railways = tracks
	if not beside.is_empty():
		beside["decks"] = RailDecks.of(data, surf, 1.0)
	for t in tracks:
		RailBuilder._way(batches, t, surf, [], 1.0, data, null, beside)
	return (batches[key] as RoadBuilder._Batch).verts.size() if batches.has(key) else 0

func _deck_verts(data: LocationData, tracks: Array) -> int:
	return _batch_verts(data, tracks, "deck_brick")

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var data := LocationData.new()
	data.latitude = 51.5
	data.longitude = -0.11
	data.grid_size = 64
	data.heights.resize(4096)
	data.heights.fill(5.0)
	data.water_level = -3.0
	var pair := RailBuilder.deck_index([_track(0.0), _track(4.0)], 1.0)
	if not RailBuilder.deck_beside(pair, Vector2(10, 0), Vector2(0, 1), 1.0):
		failures.append("a track 4 m away must count as alongside")
	if RailBuilder.deck_beside(pair, Vector2(10, 0), Vector2(0, -1), 1.0):
		failures.append("the outer edge of a pair has no track alongside")
	if RailBuilder.deck_beside(RailBuilder.deck_index([_track(0.0), _track(60.0)], 1.0), Vector2(10, 0), Vector2(0, 1), 1.0):
		failures.append("a track 60 m away is not alongside")
	var lone := _deck_verts(data, [_track(0.0)])
	var apart := _deck_verts(data, [_track(0.0), _track(60.0)])
	var joined := _deck_verts(data, [_track(0.0), _track(4.0)])
	if lone == 0 or apart != 2 * lone:
		failures.append("tracks apart keep every parapet: %d / %d" % [lone, apart])
	if joined >= apart:
		failures.append("tracks side by side must drop the parapets between them: %d / %d" % [joined, apart])
	# A gap between two track groups is slabbed over; a wider one, or none, is not.
	var bare := _batch_verts(data, [_track(0.0), _track(60.0)], "rail_deck")
	var gapped := _batch_verts(data, [_track(0.0), _track(20.0)], "rail_deck")
	var touching := _batch_verts(data, [_track(0.0), _track(4.0)], "rail_deck")
	if gapped <= bare or gapped <= touching:
		failures.append("a 20 m gap between decks should get a slab: %d vs bare %d, touching %d" % [gapped, bare, touching])
	if _batch_verts(data, [_track(0.0), _track(20.0)], "deck_brick") == 0:
		failures.append("viaduct fascias are brick")
	# Ground falling across the viaduct: the tracks share the higher level.
	var n := data.grid_size
	for z in n:
		for x in n:
			data.heights[z * n + x] = 5.0 + 0.2 * float(z)
	var surf := RoadBuilder._Surface.new(data, GroundTruth.new(data))
	var tracks: Array = [_track(0.0), _track(4.0), _track(40.0)]
	data.railways = tracks
	var decks := RailDecks.of(data, surf, 1.0)
	var tops: Array[float] = []
	var raws: Array[float] = []
	for t: Dictionary in tracks:
		var pts := RoadBuilder._resample(t["points"], 1.5)
		var raw := RoadBuilder.deck_profile(pts, surf, 1.0, 1.65, 0, false)
		raws.append(raw[pts.size() / 2])
		tops.append(decks.level(pts, raw)[pts.size() / 2])
	if absf(raws[0] - raws[1]) < 0.02:
		failures.append("the test ground should step the two decks apart: %s" % [raws])
	if absf(tops[0] - tops[1]) > 0.002 or absf(tops[0] - maxf(raws[0], raws[1])) > 0.002:
		failures.append("tracks side by side must share the higher deck level: %s from %s" % [tops, raws])
	if absf(tops[2] - raws[2]) > 0.0001:
		failures.append("a track on its own keeps its profile: %s from %s" % [tops[2], raws[2]])

	# Miami elevated concrete guideways (Metrorail / Metromover) & elevated stations.
	var mi_data := LocationData.new()
	mi_data.latitude = 25.7743
	mi_data.longitude = -80.1855
	mi_data.grid_size = 64
	mi_data.heights.resize(4096)
	mi_data.heights.fill(5.0)
	mi_data.water_level = -3.0
	if RailViaductLook.look_for(mi_data, "monorail") != "concrete_guideway" \
			or RailViaductLook.look_for(mi_data, "subway") != "concrete_guideway":
		failures.append("Miami monorail and subway bridges must select concrete_guideway")
	if RailViaductLook.look_for(data, "subway") != "brick" \
			or RailViaductLook.look_for(data, "monorail") != "brick":
		failures.append("London bridges must select brick")
	var mi_mono := OsmTags._rail_entry({"railway": "monorail", "bridge": "yes"},
		PackedVector2Array([Vector2(-80, 0.0), Vector2(80, 0.0)]))
	var mi_sub := OsmTags._rail_entry({"railway": "subway", "bridge": "yes"},
		PackedVector2Array([Vector2(-80, 12.0), Vector2(80, 12.0)]))
	var mi_tracks: Array = [mi_mono, mi_sub]
	if _batch_verts(mi_data, mi_tracks, "deck_concrete") == 0:
		failures.append("Miami guideways must emit deck_concrete fascias and piers")
	if _batch_verts(mi_data, mi_tracks, "deck_brick") != 0:
		failures.append("Miami guideways must emit zero deck_brick vertices")
	if _batch_verts(mi_data, [mi_mono], "guideway_slab") == 0:
		failures.append("Miami monorail must emit guideway_slab top finish")
	var mi_surf := RoadBuilder._Surface.new(mi_data, GroundTruth.new(mi_data))
	var mi_batches := {}
	mi_data.railways = mi_tracks
	var mi_beside := RailBuilder.deck_index(mi_tracks, 1.0)
	mi_beside["decks"] = RailDecks.of(mi_data, mi_surf, 1.0)
	for mt in mi_tracks:
		RailBuilder._way(mi_batches, mt, mi_surf, [], 1.0, mi_data, null, mi_beside)
	var conc_batch: RoadBuilder._Batch = mi_batches["deck_concrete"]
	var max_guide_y := -INF
	for v in conc_batch.verts:
		if absf(v.x) < 15.0:
			max_guide_y = maxf(max_guide_y, v.y)
	# Ground is at 5.0 m; elevated layer 1 deck + 1.0 m parapet stands ~11.0 m (~5 m+ above ground).
	if max_guide_y < 9.5:
		failures.append("Miami guideway should stand ~5 m above ground (5.0 m), got max y %.2f" % max_guide_y)
	# Adding a rail_stations node beside the Miami guideway generates elevated station canopy geometry.
	mi_data.rail_stations = [{"x": 0.0, "z": 3.5, "name": "Government Center"}]
	var root := Node3D.new()
	RailBuilder.build(root, mi_data, GroundTruth.new(mi_data))
	var canopy_mi := root.get_node_or_null("Rail_station_canopy") as MeshInstance3D
	if canopy_mi == null or canopy_mi.mesh == null or canopy_mi.mesh.get_surface_count() == 0:
		failures.append("a rail_stations node beside a Miami guideway must build Rail_station_canopy geometry")
	else:
		var c_aabb := canopy_mi.mesh.get_aabb()
		if c_aabb.end.y < 14.0:
			failures.append("elevated station canopy should stand above platform & guideway, got top %.2f" % c_aabb.end.y)
	root.free()

	failures.remove_at(0)
	if failures.is_empty():
		print("RAIL VIADUCT OK: no parapet between tracks side by side, outer edges and lone tracks keep theirs, one level across")
		quit(0)
	else:
		for f in failures:
			printerr("RAIL VIADUCT FAIL: ", f)
		quit(1)
