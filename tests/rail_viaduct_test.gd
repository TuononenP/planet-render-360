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
	failures.remove_at(0)
	if failures.is_empty():
		print("RAIL VIADUCT OK: no parapet between tracks side by side, outer edges and lone tracks keep theirs, one level across")
		quit(0)
	else:
		for f in failures:
			printerr("RAIL VIADUCT FAIL: ", f)
		quit(1)
