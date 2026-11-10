extends SceneTree

## Headless: godot --headless --script tests/rail_viaduct_test.gd
## A viaduct mapped a bridge way per track: no parapet stands between
## two tracks side by side, the outer edges keep theirs, and a track on
## its own keeps both.

func _init() -> void:
	_run()

func _track(z: float) -> Dictionary:
	return OsmTags._rail_entry({"railway": "rail", "bridge": "yes"},
		PackedVector2Array([Vector2(-80, z), Vector2(80, z)]))

func _deck_verts(data: LocationData, tracks: Array) -> int:
	var surf := RoadBuilder._Surface.new(data, GroundTruth.new(data))
	var batches := {}
	var beside := RailBuilder.deck_index(tracks, 1.0)
	for t in tracks:
		RailBuilder._way(batches, t, surf, [], 1.0, data, null, beside)
	return (batches["deck"] as RoadBuilder._Batch).verts.size() if batches.has("deck") else 0

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
	if RailBuilder.deck_beside(RailBuilder.deck_index([_track(0.0), _track(20.0)], 1.0), Vector2(10, 0), Vector2(0, 1), 1.0):
		failures.append("a track 20 m away is not alongside")
	var lone := _deck_verts(data, [_track(0.0)])
	var apart := _deck_verts(data, [_track(0.0), _track(20.0)])
	var joined := _deck_verts(data, [_track(0.0), _track(4.0)])
	if lone == 0 or apart != 2 * lone:
		failures.append("tracks apart keep every parapet: %d / %d" % [lone, apart])
	if joined >= apart:
		failures.append("tracks side by side must drop the parapets between them: %d / %d" % [joined, apart])
	failures.remove_at(0)
	if failures.is_empty():
		print("RAIL VIADUCT OK: no parapet between tracks side by side, outer edges and lone tracks keep theirs")
		quit(0)
	else:
		for f in failures:
			printerr("RAIL VIADUCT FAIL: ", f)
		quit(1)
