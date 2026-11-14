extends SceneTree

## An elevated mapped way over a registry landmark must land on that
## landmark's roof (its candidate height), not on the generic
## layer x 5 m viaduct clearance: Bryga's layer-5 park bridges over the
## 20 m Redi podium are the Helsinki case.
func _init() -> void:
	var failures: Array[String] = []
	var pts := PackedVector2Array([Vector2(-100, 0), Vector2(-50, 0), Vector2.ZERO, Vector2(50, 0), Vector2(100, 0)])
	var plain := _data([])
	var plain_surf := RoadBuilder._Surface.new(plain, GroundTruth.new(plain))
	var plain_deck := RoadBuilder.deck_profile(pts, plain_surf, 1.0, 1.0, 5)
	var ground_y := plain_surf.height(0, 0)
	if plain_deck[2] < ground_y + 20.0:
		failures.append("control: layer-5 viaduct should keep its generic clearance, mid %.1f" % (plain_deck[2] - ground_y))
	var roofed := _data([{"x": 0.0, "z": 0.0, "type": "redi_shopping_centre", "height": 20.0, "clear_m": 60.0}])
	var surf := RoadBuilder._Surface.new(roofed, GroundTruth.new(roofed))
	if absf(surf.landmark_roof_y(Vector2.ZERO) - (ground_y + 20.0)) > 0.6:
		failures.append("roof site should read ground + 20 m, got %.1f" % (surf.landmark_roof_y(Vector2.ZERO) - ground_y))
	if surf.landmark_roof_y(Vector2(200, 0)) > -1e8:
		failures.append("200 m away is not on the roof")
	var deck := RoadBuilder.deck_profile(pts, surf, 1.0, 1.0, 5)
	if absf(deck[2] - (ground_y + 20.0)) > 1.0:
		failures.append("bridge over the roof should land at roof height, mid %.1f m over ground (generic layer height %.1f)" % [deck[2] - ground_y, plain_deck[2] - ground_y])
	if deck[0] > ground_y + 1.0 or deck[deck.size() - 1] > ground_y + 1.0:
		failures.append("bridge must still meet the ground beyond the roof, ends %.1f / %.1f" % [deck[0] - ground_y, deck[deck.size() - 1] - ground_y])
	if failures.is_empty():
		print("ROOF DECK OK: layer-5 bridge lands on a 20 m landmark roof, ground beyond it")
		quit(0)
	else:
		for f in failures:
			printerr("ROOF DECK FAIL: ", f)
		quit(1)

func _data(candidates: Array) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.latitude = 60.187
	d.longitude = 24.979
	d.landmark_candidates = candidates
	return d
