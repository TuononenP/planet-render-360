extends SceneTree

## Kruunuvuorensilta: godot --headless --script tests/kruunuvuorensilta_test.gd
## Offline. The Crown Bridge is a searchable registry bridge whose model
## follows its mapped curve end to end, keeps 20 m clearance over the main
## span within a tram's grade, stands its 135 m pylon on the artificial
## islet with 17 stay pairs, and clears the mapped decks along the curve
## (not along a straight chord). A bridge's deck area is not laid on the
## ground under it.

const BRIDGE_AREA := """{"elements": [
 {"type": "way", "id": 1, "tags": {"highway": "pedestrian", "area": "yes", "bridge": "yes", "layer": "2"},
  "geometry": [{"lat": 60.1730, "lon": 25.0010}, {"lat": 60.1730, "lon": 25.0020},
   {"lat": 60.1734, "lon": 25.0020}, {"lat": 60.1734, "lon": 25.0010}, {"lat": 60.1730, "lon": 25.0010}]},
 {"type": "way", "id": 2, "tags": {"highway": "pedestrian", "area": "yes"},
  "geometry": [{"lat": 60.1740, "lon": 25.0010}, {"lat": 60.1740, "lon": 25.0020},
   {"lat": 60.1744, "lon": 25.0020}, {"lat": 60.1744, "lon": 25.0010}, {"lat": 60.1740, "lon": 25.0010}]}
]}"""

func _init() -> void:
	var failures: Array[String] = []
	var entry := LocationData.entry_for_type("kruunuvuorensilta")
	if entry.is_empty():
		_finish(["kruunuvuorensilta missing from the registry"])
		return
	if str(entry.get("kind", "")) != "Bridge" or str(entry.get("base", "")) != "sea":
		failures.append("should be a sea-based Bridge entry")
	for name: String in ["Kruunuvuorensilta", "Crown Bridge Helsinki", "Kronbergsbron"]:
		var got := LocationData.landmark_for(float(entry["lat"]), float(entry["lon"]), name)
		if got != "kruunuvuorensilta":
			failures.append("searching '%s' gives %s" % [name, got])
	_check_model(failures)
	_check_profile(failures)
	_check_clearance(failures, entry)
	var parsed := OsmParser.parse_features(BRIDGE_AREA, 60.1736, 25.0022)
	var areas := (parsed["roads"] as Array).filter(func(r: Dictionary) -> bool: return bool(r.get("area", false)))
	if areas.size() != 1:
		failures.append("a bridge's deck area should not be laid on the ground (got %d areas, want 1)" % areas.size())
	_finish(failures)

func _check_model(failures: Array[String]) -> void:
	var root := LandmarkBuilder.build("kruunuvuorensilta")
	var parts := LandmarkBuilder.parts(root)
	if parts.size() < 2 or parts.size() > 16:
		failures.append("model should be 2..16 parts, got %d" % parts.size())
	var bounds := AABB()
	var tris := 0
	var stays := 0
	for i in parts.size():
		var part: MeshInstance3D = parts[i]
		var box := part.transform * part.mesh.get_aabb()
		bounds = box if i == 0 else bounds.merge(box)
		var n: int = part.mesh.surface_get_array_len(0) / 3
		tris += n
		if str(part.name).ends_with("Stay"):
			stays = n
	if absf(bounds.end.y - 135.0) > 2.0:
		failures.append("pylon top %.1f m, want 135 m" % bounds.end.y)
	# The deck runs the mapped curve from the Palosaari underpass to Kruunuvuorenranta.
	var first := KruunuvuorensiltaLine.CENTRE[0]
	var last := KruunuvuorensiltaLine.CENTRE[KruunuvuorensiltaLine.CENTRE.size() - 1]
	if bounds.position.x > first.x + 2.0 or bounds.end.x < last.x - 2.0 \
			or bounds.position.z > first.y + 2.0 or bounds.end.z < last.y - 2.0:
		failures.append("deck bounds %s do not reach both landings" % bounds)
	# 17 stay pairs in two planes: 34 beams of 8 triangles.
	if stays != 34 * 8:
		failures.append("expected 34 stays (272 triangles), got %d triangles" % stays)
	if tris > 60000:
		failures.append("%d triangles is over the 60k budget" % tris)
	print("KRUUNUVUORENSILTA model: %d parts, %d tris, bounds %s" % [parts.size(), tris, bounds])
	# Night: the deck's own lamps and the red aviation lights glow, and the
	# floodlights stand round the pylon aimed up it, not round the bounds.
	var names := parts.map(func(m: MeshInstance3D) -> String: return str(m.name))
	for lamp in ["Lamp", "BeaconLamp"]:
		if not names.has(lamp):
			failures.append("no %s part for the night" % lamp)
	var spots := LandmarkLights.dress(root, "kruunuvuorensilta")
	if spots != 6:
		failures.append("expected 6 pylon floodlights, got %d" % spots)
	var c := LandmarkFhCrownBridge.at(LandmarkFhCrownBridge.pylon_s())
	var holder := root.get_node_or_null("LandmarkLights")
	for spot in (holder.get_children() if holder != null else []):
		var p := (spot as Node3D).position
		var aim := -(spot as Node3D).transform.basis.z
		if Vector2(p.x, p.z).distance_to(Vector2(c.x, c.y)) > 30.0 or aim.y < 0.5:
			failures.append("floodlight at %s should stand by the pylon and aim up it" % p)
	root.free()

func _check_profile(failures: Array[String]) -> void:
	var sp := LandmarkFhCrownBridge.pylon_s()
	var total := LandmarkFhCrownBridge.length_m()
	if absf(total - 1195.0) > 10.0:
		failures.append("deck length %.0f m, want about 1195 m (1191 m bridge + underpass)" % total)
	var c := LandmarkFhCrownBridge.at(sp)
	if c.x < -70.0 or c.x > 2.0 or c.y < -132.0 or c.y > -66.0:
		failures.append("pylon (%.0f, %.0f) is not on the artificial islet" % [c.x, c.y])
	var s := sp
	while s <= sp + LandmarkFhCrownBridge.MAIN_SPAN_M:
		var soffit := LandmarkFhCrownBridge.deck_y(s) - LandmarkFhCrownBridge.DEPTH_M
		if soffit < 20.0:
			failures.append("main span soffit %.1f m at %.0f m, want >= 20 m clearance" % [soffit, s - sp])
			break
		s += 10.0
	var y0 := LandmarkFhCrownBridge.deck_y(0.0)
	var y1 := LandmarkFhCrownBridge.deck_y(total)
	if absf(y0 - LandmarkFhCrownBridge.WEST_Y) > 0.5 or absf(y1 - LandmarkFhCrownBridge.EAST_Y) > 0.5:
		failures.append("landings at %.1f / %.1f m, want %.1f / %.1f m" % [y0, y1,
			LandmarkFhCrownBridge.WEST_Y, LandmarkFhCrownBridge.EAST_Y])
	s = 0.0
	while s < total - 5.0:
		var grade := absf(LandmarkFhCrownBridge.deck_y(s + 5.0) - LandmarkFhCrownBridge.deck_y(s)) / 5.0
		if grade > 0.055:
			failures.append("grade %.1f %% at %.0f m is too steep for the tram" % [grade * 100.0, s])
			break
		s += 5.0
	for p in LandmarkFhCrownBridge.pier_s():
		if p > sp and p < sp + LandmarkFhCrownBridge.MAIN_SPAN_M - 1.0:
			failures.append("a pier at %.0f m stands in the main span" % (p - sp))

func _check_clearance(failures: Array[String], entry: Dictionary) -> void:
	var clear := LandmarkSites.clear_m(entry)
	var at := Vector2.ZERO
	# The mapped cycleway at the bend and near both landings is replaced.
	for p: Vector2 in [Vector2(-34.0, -77.0), Vector2(400.0, 307.0), Vector2(-434.0, -278.0), Vector2(372.0, 272.0)]:
		if LandmarkSites.span_dist(p, at, entry) >= clear:
			failures.append("deck point %s is outside the clearance" % p)
	# The straight chord between the landings passes 100 m off the curve:
	# the water there is not the bridge.
	if LandmarkSites.span_dist(Vector2(0.0, 54.0), at, entry) < 60.0:
		failures.append("the clearance follows the chord, not the curve")
	var tram := PackedVector2Array([Vector2(-420, -280), Vector2(-238, -212), Vector2(-64, -108),
		Vector2(146, 44), Vector2(300, 183), Vector2(452, 369)])
	var spans := [[at, entry]]
	if not LandmarkSites.outside_spans(_dense(tram), spans).is_empty():
		failures.append("the mapped tram deck should be replaced along its whole length")
	var beside := PackedVector2Array()
	for p in tram:
		beside.append(p + Vector2(-40.0, 40.0))
	if LandmarkSites.outside_spans(_dense(beside), spans).is_empty():
		failures.append("a deck 50 m off the bridge should be kept")

func _dense(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var n := ceili(pts[i].distance_to(pts[i + 1]) / 5.0)
		for k in n:
			out.append(pts[i].lerp(pts[i + 1], float(k) / n))
	out.append(pts[pts.size() - 1])
	return out

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("KRUUNUVUORENSILTA OK")
		quit(0)
	else:
		for f in failures:
			printerr("KRUUNUVUORENSILTA FAIL: ", f)
		quit(1)
