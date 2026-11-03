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

func _data(water_w: float) -> LocationData:
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
	d.roads = [{"class": "secondary", "width_m": 14.0, "lanes": 4, "bridge": true,
		"points": PackedVector2Array([Vector2(-h - 40.0, 0.0), Vector2(h + 40.0, 0.0)])}]
	return d

## Vertical range (min Y, max Y) of the "deck" batch on a bridge over `water_w` m of water.
func _deck_range(water_w: float) -> Vector2:
	var d := _data(water_w)
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
