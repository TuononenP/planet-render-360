extends SceneTree

## BuildingTerraces (offline): godot --headless --script tests/building_terraces_test.gd
## A footprint on ground steeper than a plinth can take is cut across the
## slope into terraces that cover it, each seating with its uphill wall
## buried no deeper than BURY_MAX_M. Gentle ground, raised parts and
## courtyard blocks are left whole.

func _init() -> void:
	_run()

func _ground(slope_m_per_post: float) -> GroundTruth:
	var d := LocationData.new()
	d.grid_size = 64
	d.heights.resize(64 * 64)
	for z in 64:
		for x in 64:
			d.heights[z * 64 + x] = 20.0 + slope_m_per_post * float(x) + 0.3 * slope_m_per_post * float(z)
	d.water_level = -3.0
	return GroundTruth.new(d)

func _mass(ring: PackedVector2Array) -> Dictionary:
	var c := Vector2.ZERO
	for p in ring:
		c += p
	return {"ring": ring, "centre": c / float(ring.size()), "min_m": 0.0, "shape": "gabled",
		"rh_m": 3.0, "key": "k#0", "wall_m": 12.0}

func _run() -> void:
	var failures: Array[String] = []
	var m := WorldScale.metres_to_units()
	# An L-shaped block, 30 m across.
	var ring := PackedVector2Array([Vector2(-15, -15) * m, Vector2(15, -15) * m, Vector2(15, 0) * m,
		Vector2(0, 0) * m, Vector2(0, 15) * m, Vector2(-15, 15) * m])
	var area := absf(RingGeometry.signed_area(ring))
	var gentle := _ground(1.0)
	if not BuildingTerraces.terraces(_mass(ring), gentle, -INF).is_empty():
		failures.append("gentle ground was terraced")
	var cliff := _ground(30.0)
	var whole := BuildingFoundation.sample(cliff, ring, Vector2.ZERO)
	if (float(whole["high"]) - float(whole["low"])) / m <= BuildingFoundation.PLINTH_TALL_M + BuildingFoundation.BURY_MAX_M:
		failures.append("test slope too gentle: %.1f m relief" % [(float(whole["high"]) - float(whole["low"])) / m])
	var steps := BuildingTerraces.terraces(_mass(ring), cliff, -INF)
	if steps.size() < 2:
		failures.append("cliff site got %d terraces" % steps.size())
	var covered := 0.0
	for step: Dictionary in steps:
		var piece: PackedVector2Array = step["ring"]
		covered += absf(RingGeometry.signed_area(piece))
		if step.has("key") or str(step["shape"]) != "flat":
			failures.append("terrace kept the whole block's key or roof: %s" % [step.keys()])
		var seat := BuildingFoundation.sample(cliff, piece, step["centre"])
		var buried := (float(seat["high"]) - float(seat["floor"])) / m
		if buried > BuildingFoundation.BURY_MAX_M + 0.05:
			failures.append("terrace %d buried %.2f m uphill" % [int(step["terrace"]), buried])
	if absf(covered - area) > area * 0.01:
		failures.append("terraces cover %.0f of %.0f m²" % [covered / (m * m), area / (m * m)])
	var raised := _mass(ring)
	raised["min_m"] = 6.0
	if not BuildingTerraces.terraces(raised, cliff, -INF).is_empty():
		failures.append("a raised part was terraced")
	var court := _mass(ring)
	court["holes"] = [PackedVector2Array([Vector2(-10, -10) * m, Vector2(-5, -10) * m, Vector2(-5, -5) * m])]
	if not BuildingTerraces.terraces(court, cliff, -INF).is_empty():
		failures.append("a courtyard block was terraced")
	if failures.is_empty():
		print("building_terraces_test passed")
		quit(0)
	else:
		for f in failures:
			printerr(f)
		quit(1)
