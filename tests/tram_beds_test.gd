extends SceneTree

func _init() -> void:
	_run()

func _run() -> void:
	var data := LocationData.new()
	data.latitude = 60.176
	data.longitude = 24.805
	data.grid_size = 64
	data.heights.resize(4096)
	data.heights.fill(5.0)
	data.water_level = -3.0
	var ring := PackedVector2Array([Vector2(-200, -200), Vector2(200, -200), Vector2(200, 200), Vector2(-200, 200)])
	data.land_polygons = [{"class": "grass", "points": ring}]
	data.roads = [OsmTags._road_entry({"highway": "residential", "width": "8"},
		PackedVector2Array([Vector2(-100, 0), Vector2(100, 0)]))]
	var failures: Array[String] = []
	for offset in [0.0, 20.0]:
		var track := OsmTags._rail_entry({"railway": "tram"},
			PackedVector2Array([Vector2(-80, offset), Vector2(80, offset)]))
		data.railways = [track]
		var node := Node3D.new()
		RailBuilder.build(node, data, GroundTruth.new(data))
		var beds := 0
		for child in node.get_children():
			if str(child.name) == "Rail_grass_track":
				beds += 1
		if beds != (1 if offset > 0.0 else 0):
			failures.append("tram bed at offset %.1f: %d grass surfaces" % [offset, beds])
		node.free()
	# Shared road/tram bridges have one slab, with the tram's rails above.
	data.roads[0]["bridge"] = true
	var tram := OsmTags._rail_entry({"railway": "tram", "bridge": "yes"},
		PackedVector2Array([Vector2(-80, 0), Vector2(80, 0)]))
	var ground := GroundTruth.new(data)
	var batches := {}
	RailBuilder._way(batches, tram, RoadBuilder._Surface.new(data, ground), [], 1.0, data)
	if batches.has("rail_deck") or batches.has("deck") or not batches.has("rail"):
		failures.append("shared tram bridge must add rails without another deck")
	# The spatial index must preserve the original road-coverage query, including
	# cell boundaries, wide and degenerate segments, bridges and excluded roads.
	data.roads.append(OsmTags._road_entry({"highway": "residential", "width": "150"},
		PackedVector2Array([Vector2(-128, -64), Vector2(128, 64), Vector2(128, 64)])))
	data.roads.append(OsmTags._road_entry({"highway": "residential", "tunnel": "yes"},
		PackedVector2Array([Vector2(-250, 180), Vector2(250, 180)])))
	var road_index := RailBuilder.RoadIndex.new(data, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31871
	var probes := [Vector2(-64, -64), Vector2.ZERO, Vector2(128, 64), Vector2(64, 64)]
	for i in 2000:
		probes.append(Vector2(rng.randf_range(-300, 300), rng.randf_range(-220, 220)))
	for p in probes:
		if RailBuilder._on_road(p, data, 1.0) != road_index.contains(p):
			failures.append("road index disagrees at %s" % p)
			break
	if failures.is_empty():
		print("TRAM BEDS OK: grass reservations, carriageway track, one bridge slab")
		quit(0)
	else:
		for failure in failures:
			printerr("TRAM BEDS FAIL: ", failure)
		quit(1)
