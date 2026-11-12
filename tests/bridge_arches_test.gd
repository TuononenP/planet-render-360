extends SceneTree

## Headless: godot --headless --script tests/bridge_arches_test.gd
## Bridge arches (BridgeArches): a deck crossing 45+ m of water stands on
## piers with arched openings (geometry reaching well below the slab, a
## pier every ~32 m), a short crossing stays a plain slab, and every
## triangle of the added walls faces outward.

func _init() -> void:
	var failures: Array[String] = []
	var long_r := _deck_range(140.0)
	var short_r := _deck_range(20.0)
	# The slab alone spans ~3.5 m (camber, depth, parapet); piers add the height of the span.
	var long_h := long_r.y - long_r.x
	var short_h := short_r.y - short_r.x
	if long_h < short_h + 2.0:
		failures.append("a 140 m crossing should reach down to piers: %.1f m vs %.1f m for a 20 m one" % [long_h, short_h])
	for c in [[{"bridge_structure": "arch", "bridge_material": "stone"}, "masonry"],
			[{"bridge_structure": "arch", "bridge_material": "steel"}, "steel_arch"],
			[{"name": "Västerbron"}, "steel_arch"], [{"name": "Centralbron"}, "girder"],
			[{}, "unknown"], [{"name": "Västerbron", "bridge_structure": "girder"}, "girder"]]:
		if BridgeArches.structure(c[0]) != c[1]:
			failures.append("structure for %s should be %s" % [c[0], c[1]])
	# A girder is a slab on its abutments (BridgeStructures); only the
	# masonry bridge's piers and arches stand down in the water.
	var masonry_r := _deck_range(140.0, "masonry")
	var girder_r := _deck_range(140.0, "girder")
	print("masonry reaches %.2f m, girder %.2f m" % [masonry_r.x, girder_r.x])
	if masonry_r.x > girder_r.x - 1.0:
		failures.append("a masonry deck must receive arch geometry that a girder does not: reaches %.2f m, the girder %.2f m" % [masonry_r.x, girder_r.x])
	var tags := OsmTags._road_entry({"highway": "primary", "bridge": "yes", "bridge:structure": "arch", "bridge:material": "steel", "name": "Västerbron"}, PackedVector2Array([Vector2.ZERO, Vector2.ONE]))
	if BridgeArches.structure(tags) != "steel_arch" or tags.get("name") != "Västerbron":
		failures.append("OSM bridge structure, material and name must reach the builder")
	var land := _data(20.0, "girder")
	land.land_polygons = []
	var ground := GroundTruth.new(land)
	var surf := RoadBuilder._Surface.new(land, ground)
	var dry := PackedVector2Array([Vector2(-80, 0), Vector2(-40, 0), Vector2.ZERO, Vector2(40, 0), Vector2(80, 0)])
	var low := RoadBuilder.deck_profile(dry, surf, 1.0, 7.0, 0)
	var high := RoadBuilder.deck_profile(dry, surf, 1.0, 7.0, 1)
	if high.size() != dry.size() or high[2] < surf.height(0, 0) + 5.0 or high[2] <= low[2] + 2.0:
		failures.append("layer 1 dry viaduct should rise about 5 m over land")
	# An elevated bridge meets the ground at both ends, however short: a 21 m
	# footbridge peaks below the full 5 m, a long road viaduct reaches it.
	var foot := RoadBuilder._resample(PackedVector2Array([Vector2(0, 0), Vector2(21, 0)]), 2.0)
	var foot_deck := RoadBuilder.deck_profile(foot, surf, 1.0, 1.0, 1)
	var road_deck := RoadBuilder.deck_profile(dry, surf, 1.0, 7.0, 1)
	var ground_y := surf.height(0, 0)
	for d in [foot_deck, road_deck]:
		if d[0] > ground_y + 0.5 or d[d.size() - 1] > ground_y + 0.5:
			failures.append("an elevated bridge must start and end at the ground, ends at %.1f / %.1f m over it" % [d[0] - ground_y, d[d.size() - 1] - ground_y])
	var foot_peak := foot_deck[foot_deck.size() / 2] - ground_y
	if foot_peak < 2.0 or foot_peak > 5.0 or foot_deck[1] <= foot_deck[0]:
		failures.append("a short footbridge should ramp up toward its middle, peak %.1f m" % foot_peak)
	var dist := PackedFloat32Array([0, 40, 80, 120, 160])
	var pier_batch := RoadBuilder._Batch.new()
	RoadBuilder._land_piers(pier_batch, dry, dist, high, surf, 1.0)
	if pier_batch.indices.is_empty():
		failures.append("elevated dry bridge must have supporting piers")
	var parsed := RoadBuilder._parse({"points": dry, "bridge": true, "layer": 2, "class": "primary"}, 1.0)
	if int(parsed.get("layer", 0)) != 2:
		failures.append("OSM layer must reach the road builder")
	var spans := _spans(140.0)
	if spans < 3 or spans > 6:
		failures.append("140 m of water should take ~4 spans, got %d" % spans)
	if _spans(20.0) != 0:
		failures.append("a 20 m crossing gets no arches")
	if failures.is_empty():
		print("BRIDGE ARCHES OK: %d spans over 140 m of water, %.1f m vertical extent vs %.1f m for a plain slab" % [spans, long_h, short_h])
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE ARCHES FAIL: ", f)
		quit(1)

func _data(water_w: float, structure: String = "masonry") -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.seed_value = 7
	d.latitude = 51.5
	d.longitude = -0.12
	var h := water_w * 0.5
	d.land_polygons = [{"class": "water", "holes": [], "points": PackedVector2Array([
		Vector2(-h, -300), Vector2(h, -300), Vector2(h, 300), Vector2(-h, 300)])}]
	d.roads = [{"class": "secondary", "width_m": 14.0, "lanes": 4, "bridge": true, "bridge_structure": structure,
		"points": PackedVector2Array([Vector2(-h - 40.0, 0.0), Vector2(h + 40.0, 0.0)])}]
	return d

## Vertical range (min Y, max Y) of the "deck" batch on a bridge over `water_w` m of water.
func _deck_range(water_w: float, structure: String = "masonry") -> Vector2:
	var d := _data(water_w, structure)
	var roads := RoadBuilder.build_roads(d, GroundTruth.new(d))
	var lo := INF
	var hi := -INF
	for c in roads.get_children():
		if c is MeshInstance3D and str(c.name) == "Road_deck":
			for v in ((c as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				lo = minf(lo, v.y)
				hi = maxf(hi, v.y)
	roads.free()
	return Vector2(lo, hi)

func _deck_vertices(water_w: float, structure: String) -> int:
	var d := _data(water_w, structure)
	var roads := RoadBuilder.build_roads(d, GroundTruth.new(d))
	var count := 0
	for c in roads.get_children():
		if c is MeshInstance3D and str(c.name) == "Road_deck":
			count += (c.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	roads.free()
	return count

func _spans(water_w: float) -> int:
	var d := _data(water_w)
	var g := GroundTruth.new(d)
	var pts := PackedVector2Array([Vector2(-water_w * 0.5 - 40.0, 0.0), Vector2(water_w * 0.5 + 40.0, 0.0)])
	var dense := PackedVector2Array()
	for i in 41:
		dense.append(pts[0].lerp(pts[1], float(i) / 40.0))
	var dist := PackedFloat32Array([0.0])
	for i in range(1, dense.size()):
		dist.append(dist[i - 1] + dense[i].distance_to(dense[i - 1]))
	var deck := PackedFloat32Array()
	for p in dense:
		deck.append(g.water_level_at(p.x, p.y) + 5.0)
	return BridgeArches.add(RoadBuilder._Batch.new(), dense, dist, deck, 7.0, 0.9, g, 1.0)
