extends SceneTree

## Kruunuvuorensilta: godot --headless --script tests/kruunuvuorensilta_test.gd
## Offline. The Crown Bridge is a searchable registry bridge whose model
## follows its mapped curve end to end, keeps 20 m clearance over the main
## span within a tram's grade, stands its 135 m pylon on the artificial
## islet with 17 stay pairs each way from its cable opening to both deck
## edges, and clears the mapped decks along the curve
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
		if str(part.name).ends_with("StayLamp"):
			stays = n
	if absf(bounds.end.y - 135.0) > 2.0:
		failures.append("pylon top %.1f m, want 135 m" % bounds.end.y)
	# The deck runs the mapped curve from the Palosaari underpass to Kruunuvuorenranta.
	var first := KruunuvuorensiltaLine.CENTRE[0]
	var last := KruunuvuorensiltaLine.CENTRE[KruunuvuorensiltaLine.CENTRE.size() - 1]
	if bounds.position.x > first.x + 2.0 or bounds.end.x < last.x - 2.0 \
			or bounds.position.z > first.y + 2.0 or bounds.end.z < last.y - 2.0:
		failures.append("deck bounds %s do not reach both landings" % bounds)
	# 17 stay pairs each way in two planes: 68 beams of 8 triangles.
	if stays != 68 * 8:
		failures.append("expected 68 stays (544 triangles), got %d triangles" % stays)
	# Piers and pylon stand on caps that reach below the waterline.
	if bounds.position.y > -LandmarkFhCrownBridge.CAP_DEPTH_M + 0.5:
		failures.append("piers should reach %.0f m under the water, lowest point %.1f m" % [
			LandmarkFhCrownBridge.CAP_DEPTH_M, bounds.position.y])
	_check_pylon(failures)
	_check_stays(failures)
	if tris > 66000:
		failures.append("%d triangles is over the 66k budget" % tris)
	print("KRUUNUVUORENSILTA model: %d parts, %d tris, bounds %s" % [parts.size(), tris, bounds])
	# Night: the deck's own lamps and the red aviation lights glow, and the
	# floodlights stand round the pylon aimed up it, not round the bounds.
	var names := parts.map(func(m: MeshInstance3D) -> String: return str(m.name))
	for lamp in ["Lamp", "BeaconLamp"]:
		if not names.has(lamp):
			failures.append("no %s part for the night" % lamp)
	# Six floodlights up the pylon first, then the poles' deck downlights.
	# The stays are plain white by day (no glow of their own) and glow only
	# once the hero is dressed to follow the night.
	var stay_part: MeshInstance3D = null
	for part: MeshInstance3D in parts:
		if str(part.name).ends_with("StayLamp"):
			stay_part = part
	var stay_mat := stay_part.mesh.surface_get_material(0) as StandardMaterial3D if stay_part != null else null
	if stay_mat == null or stay_mat.emission_energy_multiplier > 0.0:
		failures.append("the stays should not glow by day")
	var spots := LandmarkLights.dress(root, "kruunuvuorensilta")
	var night_mat := stay_part.get_surface_override_material(0) if stay_part != null else null
	if night_mat == null or float(night_mat.get_meta(CityLights.META, 0.0)) <= 0.0:
		failures.append("the dressed stays should glow at night")
	if spots != LandmarkFhCrownBridge.flood_spots().size() or spots < 16:
		failures.append("expected 6 pylon floodlights and 10+ deck downlights, got %d spots" % spots)
	# Red night halos round the top aviation light and the mast's two pairs.
	var halos := root.get_node_or_null("BeaconHalos")
	if halos == null or halos.get_child_count() != 5:
		failures.append("expected 5 beacon halos, got %d" % (halos.get_child_count() if halos != null else 0))
	var c := LandmarkFhCrownBridge.at(LandmarkFhCrownBridge.pylon_s())
	var holder := root.get_node_or_null("LandmarkLights")
	var k := 0
	for spot in (holder.get_children() if holder != null else []):
		var p := (spot as Node3D).position
		var aim := -(spot as Node3D).transform.basis.z
		if k < 6 and (Vector2(p.x, p.z).distance_to(Vector2(c.x, c.y)) > 30.0 or aim.y < 0.5):
			failures.append("floodlight at %s should stand by the pylon and aim up it" % p)
		if k >= 6 and (aim.y > -0.9 or (spot as SpotLight3D).spot_range >= p.y):
			failures.append("deck light at %s should shine down onto the deck only" % p)
		k += 1
	root.free()

## The pylon is a needle through the deck's median: south of the
## separator, leaving the cycle path at least 2.5 m beside it; its two
## legs rise as a V from one foot on the plinth, are parted along the
## deck by a slit widest at the deck and closed where they merge; above
## the deck its outline never widens upwards; near the top a rectangular
## opening in each end face frames the whole cable zone, between two side
## walls, where the stays enter.
func _check_pylon(failures: Array[String]) -> void:
	var B := LandmarkFhCrownBridge
	var sp: float = B.pylon_s()
	var h: float = B.at(sp).z
	var yd: float = B.deck_y(sp)
	var path_edge: float = h - 0.3 - B.FOOTWAY_M
	var prev := Vector3(INF, INF, INF)
	var y := 0.0
	while y <= B.MAST_TOP_M:
		var q: Vector3 = B.pylon_section(y)
		if B.PYLON_X - q.z < B.SEPARATOR.y or B.PYLON_X + q.z > path_edge - 2.5:
			failures.append("pylon at %.0f m (%.1f..%.1f m across) leaves the median" % [y, B.PYLON_X - q.z, B.PYLON_X + q.z])
			break
		if y > yd and (q.x > prev.x + 0.001 or q.z > prev.z + 0.001):
			failures.append("pylon section widens at %.0f m" % y)
			break
		prev = q
		y += 2.0
	# Eight-sided legs: every corner cut, leaving a flat on each face.
	var deck: Vector3 = B.pylon_section(yd)
	var cut: float = B.pylon_chamfer(yd)
	if cut < 0.5 or cut * 2.0 > minf(deck.x - deck.y, deck.z * 2.0) - 0.8:
		failures.append("the legs should be octagons: corner cut %.2f m on a %.1f x %.1f m leg" % [cut, deck.x - deck.y, deck.z * 2.0])
	if B.pylon_chamfer(B.SLOT_M.y) > B.pylon_section(B.SLOT_M.y).z - B.SLOT_HALF:
		failures.append("the head's corner cut should not break into the cable opening")
	if B.pylon_section(yd).y < 1.5:
		failures.append("the legs should stand at least 3 m apart at the deck")
	if B.pylon_section(B.PLINTH_TOP_M).y > 0.001 or B.pylon_section(yd * 0.5).y >= B.pylon_section(B.pylon_knee_y()).y:
		failures.append("below the deck the legs should close as a V onto one foot")
	if B.JOIN_M < yd + 50.0 or B.JOIN_M >= B.SLOT_M.x or B.pylon_section(B.JOIN_M).y > 0.001:
		failures.append("the legs should merge well above the deck, under the cable opening (JOIN_M %.0f m)" % B.JOIN_M)
	if B.SLOT_M.x >= B.MAST_ANCHORS.x or B.MAST_ANCHORS.y >= B.SLOT_M.y:
		failures.append("the cable opening %s should frame the cable zone %s" % [B.SLOT_M, B.MAST_ANCHORS])
	# The opening is in the end faces: wide enough for a stay pair, with a
	# wall left on each side across the deck, and each stay starts inside it.
	if B.SLOT_HALF < B.STAY_TOP_HALF + 0.3 or B.pylon_section(B.SLOT_M.y).z - B.SLOT_HALF < 0.4:
		failures.append("the cable opening should hold a stay pair between side walls at least 0.4 m thick")
	var fr: Array = B.pylon_frame()
	for pair: Array in B.stay_pairs():
		var top: Vector3 = B.stay_ends(float(pair[0]), float(pair[1]), 1.0)[0]
		var rel := top - (fr[0] as Vector3)
		var q: Vector3 = B.pylon_section(top.y)
		var along := rel.dot(fr[1] as Vector3) * signf(float(pair[0]) - sp)
		if along < q.x - 1.5 or along > q.x or absf(rel.dot(fr[2] as Vector3)) > B.SLOT_HALF:
			failures.append("stay at %.0f m should start in the opening of the end face towards it" % (float(pair[0]) - sp))
			break

## Every stay runs from the cable opening to a bracket outside a deck
## edge: 17 pairs each way, 90 to 257 m long as published, coming in over
## the fences well above them and passing high over the tramway's poles
## and wires.
func _check_stays(failures: Array[String]) -> void:
	var B := LandmarkFhCrownBridge
	var sp: float = B.pylon_s()
	var pairs: Array = B.stay_pairs()
	if pairs.size() != 34 or B.STAY_OUT_M < 1.0:
		failures.append("expected 34 stay pairs on brackets at least 1 m outside the edges, got %d at %.1f m" % [
			pairs.size(), B.STAY_OUT_M])
	var shortest := INF
	var longest := 0.0
	for pair: Array in pairs:
		for side: float in [-1.0, 1.0]:
			var ends: Array = B.stay_ends(float(pair[0]), float(pair[1]), side)
			var top: Vector3 = ends[0]
			var low: Vector3 = ends[1]
			shortest = minf(shortest, top.distance_to(low))
			longest = maxf(longest, top.distance_to(low))
			for j in range(1, 400):
				var u := j / 400.0
				var p := low.lerp(top, u)
				# Arc length under the point: from a straight guess, stepped
				# along the heading.
				var s := lerpf(float(pair[0]), sp, u)
				for _i in 3:
					var c: Vector3 = B.at(s)
					s += (Vector2(p.x, p.z) - Vector2(c.x, c.y)).dot(B.heading(s))
				var at: Vector3 = B.at(s)
				var t: Vector2 = B.heading(s)
				var lat := (Vector2(p.x, p.z) - Vector2(at.x, at.y)).dot(Vector2(-t.y, t.x))
				var over: float = p.y - B.deck_y(s)
				if absf(lat) < at.z + 0.1 and over < 2.5:
					failures.append("stay at %.0f m crosses the fence line %.1f m over the deck" % [float(pair[0]) - sp, over])
					break
				if lat > -7.0 and lat < -0.2 and over < 9.5:
					failures.append("stay at %.0f m hangs %.1f m over the tramway" % [float(pair[0]) - sp, over])
					break
	if shortest < 85.0 or longest > 262.0 or longest < 250.0:
		failures.append("stays are %.0f to %.0f m long, want 90 to 257 m" % [shortest, longest])

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
	# Both stayed spans hang free of piers, with V piers on both approaches.
	var west := 0
	var east := 0
	for p in LandmarkFhCrownBridge.pier_s():
		if p > sp - LandmarkFhCrownBridge.BACK_SPAN_M + 1.0 and p < sp + LandmarkFhCrownBridge.MAIN_SPAN_M - 1.0:
			failures.append("a pier at %.0f m stands under the stays" % (p - sp))
		west += 1 if p < sp else 0
		east += 1 if p > sp else 0
	if west < 3 or east < 3:
		failures.append("expected V piers on both approaches, got %d west and %d east" % [west, east])

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
