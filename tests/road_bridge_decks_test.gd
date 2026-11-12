extends SceneTree

## Headless: road bridge ways sharing one overpass (RoadBridgeDecks). Two
## parallel carriageways over a ditch find each other beside them (so the
## edges between them carry no parapet and the deck fills the gap), stand
## at one level (a narrow way takes the wider road's deck, not the other
## way round), keep their layer's clearance and piers over the ditch; a
## lone bridge, a rail bridge alongside and a long water crossing are left
## as before, and proposed or demolished roads are not drawn.

func _init() -> void:
	var failures: Array[String] = []
	var d := _data(6.0)
	var surf := RoadBuilder._Surface.new(d, GroundTruth.new(d))
	var a: PackedVector2Array = d.roads[0]["points"]
	var dense := RoadBuilder._resample(a, 4.0)
	var sides := RoadBridgeDecks.beside(dense, 3.5, surf, 1.0, a)
	if sides.is_empty():
		failures.append("parallel carriageway 8 m away must be found beside the deck")
	else:
		var near := 0
		var far := 0
		for s in 2:
			for g: float in (sides["d"][s] as PackedFloat32Array):
				if absf(g - 8.0) < 0.5:
					near += 1
				elif g != 0.0:
					far += 1
		if near < dense.size() - 2 or far > 0:
			failures.append("expected one side ~8 m from the twin on every segment, got %d near, %d other" % [near, far])
	if not RoadBridgeDecks.mostly_land(dense, surf):
		failures.append("an 80 m overpass over a 6 m ditch is mostly land")
	var deck := RoadBuilder.deck_profile(dense, surf, 1.0, 3.5, 1)
	var mid := deck[deck.size() / 2] - surf.height(0, -4)
	if mid < 4.0:
		failures.append("layer 1 overpass over a ditch should keep ~5 m clearance, got %.1f m" % mid)
	# Equal twins meet at one height; a narrow way beside a road takes the
	# road's deck (a footpath's steep ramp must not lift the road).
	var b: PackedVector2Array = d.roads[1]["points"]
	var la := RoadBridgeDecks.levelled(dense, 3.5, 1, surf, 1.0, a)
	var lb := RoadBridgeDecks.levelled(RoadBuilder._resample(b, 4.0), 3.5, 1, surf, 1.0, b)
	if absf(la[la.size() / 2] - lb[lb.size() / 2]) > 0.05:
		failures.append("twin carriageways should meet: %.2f vs %.2f m" % [la[la.size() / 2], lb[lb.size() / 2]])
	var mixed := _data(6.0)
	(mixed.roads[1] as Dictionary)["width_m"] = 2.5
	var msurf := RoadBuilder._Surface.new(mixed, GroundTruth.new(mixed))
	var path: PackedVector2Array = mixed.roads[1]["points"]
	var path_dense := RoadBuilder._resample(path, 4.0)
	var path_deck := RoadBridgeDecks.levelled(path_dense, 1.25, 1, msurf, 1.0, path)
	var road_deck := RoadBridgeDecks.levelled(dense, 3.5, 1, msurf, 1.0, a)
	var road_own := RoadBuilder.deck_profile(dense, msurf, 1.0, 3.5, 1)
	var pm := path_deck.size() / 2
	if absf(path_deck[pm] - road_own[road_own.size() / 2]) > 0.3:
		failures.append("a footway beside a road should take the road's deck: %.2f vs %.2f m" % [path_deck[pm], road_own[road_own.size() / 2]])
	# Its own deck, as sampled by the shared profile cache (within 0.3 m).
	if absf(road_deck[road_deck.size() / 2] - road_own[road_own.size() / 2]) > 0.3:
		failures.append("the road must keep its own deck beside a narrower way: %.2f vs %.2f m" % [road_deck[road_deck.size() / 2], road_own[road_own.size() / 2]])
	# A chain side by side (narrow road, cycleway, wide road) is one group:
	# every member stands at the wide road's deck, not only its neighbour's.
	var chain := _data(6.0, false)
	chain.roads = [
		{"class": "primary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(-40, -6), Vector2(40, -6)])},
		{"class": "cycleway", "width_m": 2.5, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(-40, 0), Vector2(40, 0)])},
		{"class": "primary", "width_m": 3.0, "lanes": 1, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(-40, 5), Vector2(40, 5)])}]
	var csurf := RoadBuilder._Surface.new(chain, GroundTruth.new(chain))
	var levels: Array[float] = []
	for r in chain.roads:
		var cp: PackedVector2Array = (r as Dictionary)["points"]
		var cd := RoadBuilder._resample(cp, 4.0)
		var cdeck := RoadBridgeDecks.levelled(cd, float((r as Dictionary)["width_m"]) * 0.5, 1, csurf, 1.0, cp, str((r as Dictionary)["class"]))
		levels.append(cdeck[cdeck.size() / 2])
	if absf(levels[0] - levels[1]) > 0.05 or absf(levels[0] - levels[2]) > 0.05:
		failures.append("a side-by-side chain should share the wide road's level: %s" % [levels])
	# Crossing on another layer: a path under a road bridge dips (or the
	# road rises) to leave headroom; on the same layer a narrow way running
	# onto a wider deck takes its height there and drops its parapets.
	var cross := _data(30.0, false)
	cross.roads.append({"class": "cycleway", "width_m": 2.5, "bridge": true, "layer": 0,
		"points": PackedVector2Array([Vector2(0, -40), Vector2(0, 40)])})
	var xsurf := RoadBuilder._Surface.new(cross, GroundTruth.new(cross))
	var road_pts: PackedVector2Array = cross.roads[0]["points"]
	var path_pts: PackedVector2Array = cross.roads[1]["points"]
	var rd := RoadBuilder._resample(road_pts, 4.0)
	var pd := RoadBuilder._resample(path_pts, 4.0)
	var rdeck := RoadBridgeDecks.levelled(rd, 3.5, 1, xsurf, 1.0, road_pts, "primary")
	var pdeck := RoadBridgeDecks.levelled(pd, 1.25, 0, xsurf, 1.0, path_pts, "cycleway")
	var r_at := rdeck[RoadBridgeDecks._closest(rd, Vector2(0, -4))]
	var p_at := pdeck[RoadBridgeDecks._closest(pd, Vector2(0, -4))]
	# Over water the path cannot dip the full headroom: the road stands at
	# least HIDE_M over it, so its parapet stays under the road slab.
	if r_at - p_at < RoadBridgeDecks.HIDE_M - 0.05:
		failures.append("a path under a road bridge needs %.1f m deck to deck, got %.2f" % [RoadBridgeDecks.HIDE_M, r_at - p_at])
	var same := _data(30.0, false)
	same.roads.append({"class": "cycleway", "width_m": 2.5, "bridge": true, "layer": 1,
		"points": PackedVector2Array([Vector2(0, -30), Vector2(0, 30)])})
	var ssurf := RoadBuilder._Surface.new(same, GroundTruth.new(same))
	var spts: PackedVector2Array = same.roads[1]["points"]
	var sd := RoadBuilder._resample(spts, 2.0)
	var on: Array = []
	var sdeck := RoadBridgeDecks.levelled(sd, 1.25, 1, ssurf, 1.0, spts, "cycleway", on)
	var host := RoadBuilder.deck_profile(rd, ssurf, 1.0, 3.5, 1)
	var si := RoadBridgeDecks._closest(sd, Vector2(0, -4))
	if int(on[si]) != 1 or absf(sdeck[si] - host[RoadBridgeDecks._closest(rd, Vector2(0, -4))]) > 0.3:
		failures.append("a cycleway crossing a road deck on its layer should run onto it (on=%s, %.2f vs %.2f)" % [on[si], sdeck[si], host[RoadBridgeDecks._closest(rd, Vector2(0, -4))]])
	# Lone bridge, and a rail bridge alongside: not road neighbours.
	var lone := _data(6.0, false)
	if not RoadBridgeDecks.beside(dense, 3.5, RoadBuilder._Surface.new(lone, GroundTruth.new(lone)), 1.0, a).is_empty():
		failures.append("a lone bridge must keep both parapets")
	var rail := _data(6.0, false)
	rail.railways = [{"class": "rail", "bridge": true, "points": PackedVector2Array([Vector2(-40, 4), Vector2(40, 4)])}]
	if not RoadBridgeDecks.beside(dense, 3.5, RoadBuilder._Surface.new(rail, GroundTruth.new(rail)), 1.0, a).is_empty():
		failures.append("a rail bridge alongside is its own structure, not a road neighbour")
	var river := _data(140.0, false)
	var river_surf := RoadBuilder._Surface.new(river, GroundTruth.new(river))
	var span := RoadBuilder._resample(PackedVector2Array([Vector2(-110, 0), Vector2(110, 0)]), 4.0)
	if RoadBridgeDecks.mostly_land(span, river_surf):
		failures.append("a 220 m bridge over 140 m of water is a water crossing")
	# Built through the road builder: the twins' shared edges lose their
	# parapets; the lifted overpass over the ditch keeps its piers.
	var twin_parapets := _deck_vertices(_data(6.0))
	var apart := _data(6.0)
	(apart.roads[1] as Dictionary)["points"] = PackedVector2Array([Vector2(-40, 60), Vector2(40, 60)])
	var apart_parapets := _deck_vertices(apart)
	if twin_parapets >= apart_parapets:
		failures.append("twin decks should drop their shared parapets: %d vs %d vertices apart" % [twin_parapets, apart_parapets])
	var ditch := _deck_vertices(_data(6.0, false))
	var dry_data := _data(6.0, false)
	dry_data.land_polygons = []
	var dry := _deck_vertices(dry_data)
	if ditch < dry - 16:
		failures.append("an overpass over a ditch must stand on piers like a dry one: %d vs %d vertices" % [ditch, dry])
	# A wall mapped across a road stops at its carriageway (it runs under
	# the bridge there): no barrier piece stands in the lanes.
	var grid := StreetProps._road_grid(_data(6.0, false), 1.0)
	if not StreetProps._on_road(Vector2(10, -4), grid, 1.0) or StreetProps._on_road(Vector2(10, 8), grid, 1.0):
		failures.append("barriers must stop on a road's carriageway, not beside it")
	# A proposed or demolished road is mapped but not drawn (Telasilta,
	# a planned bridge beside this overpass, was drawn as a real road).
	for c in [[{"highway": "proposed", "bridge": "yes"}, true], [{"highway": "razed"}, true],
			[{"highway": "disused"}, true], [{"highway": "construction", "construction": "proposed"}, true],
			[{"highway": "primary"}, false], [{"highway": "construction"}, false]]:
		if OsmTags.unbuilt_highway(c[0]) != c[1]:
			failures.append("unbuilt_highway(%s) should be %s" % [c[0], c[1]])
	if failures.is_empty():
		print("ROAD BRIDGE DECKS OK")
		quit(0)
	else:
		for f in failures:
			printerr("ROAD BRIDGE DECKS FAIL: ", f)
		quit(1)

## Flat ground at 3 m with a water strip `water_w` wide across x = 0, and
## two parallel layer-1 carriageways 8 m apart over it (one when `twin`
## is false).
func _data(water_w: float, twin: bool = true) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.seed_value = 7
	d.latitude = 60.17
	d.longitude = 24.77
	var h := water_w * 0.5
	d.land_polygons = [{"class": "water", "holes": [], "points": PackedVector2Array([
		Vector2(-h, -300), Vector2(h, -300), Vector2(h, 300), Vector2(-h, 300)])}]
	d.roads = [{"class": "primary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
		"points": PackedVector2Array([Vector2(-40, -4), Vector2(40, -4)])}]
	if twin:
		d.roads.append({"class": "primary", "width_m": 7.0, "lanes": 2, "bridge": true, "layer": 1,
			"points": PackedVector2Array([Vector2(-40, 4), Vector2(40, 4)])})
	return d

## Vertices in the "deck" batch (fascias, parapets, underside, piers) for `d`.
func _deck_vertices(d: LocationData) -> int:
	var roads := RoadBuilder.build_roads(d, GroundTruth.new(d))
	var count := 0
	for c in roads.get_children():
		if c is MeshInstance3D and str(c.name) == "Road_deck":
			count += ((c as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	roads.free()
	return count
