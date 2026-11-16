extends SceneTree

## Capital airports test: godot --headless --script tests/capital_airports_test.gd
## Offline. Each capital whose airport stands close to its centre has a
## hand-built airfield (LandmarkRegistryCapitalAirports): a named capital of
## CapitalCatalog, within AIRPORT_REACH_M of it, a secondary "Airport" (never
## displaces a capital's icon), a clear_rect_m that covers the whole model,
## and a model that reaches its height_m. The parked-aircraft kit builds
## each type at about its real length.

const AIRPORT_REACH_M := 8000.0
const MIN_AIRPORTS := 12
const REAL_LENGTH_M := {"narrow": 37.6, "wide": 58.8, "turboprop": 32.8, "light": 8.3}

func _init() -> void:
	var failures: Array[String] = []
	var capitals := {}
	for row in CapitalCatalog.ROWS:
		var cc := str(row[0])
		if not capitals.has(cc):
			capitals[cc] = []
		(capitals[cc] as Array).append(Vector2(float(row[3]), float(row[4])))
	var rows: Array = LandmarkRegistryCapitalAirports.entries()
	if rows.size() < MIN_AIRPORTS:
		failures.append("only %d capital airports (want %d)" % [rows.size(), MIN_AIRPORTS])
	var seen := {}
	for e in rows:
		var t := str(e["type"])
		if seen.has(t):
			failures.append("%s is listed twice" % t)
		seen[t] = true
		var cc := str(e.get("capital", ""))
		if not capitals.has(cc):
			failures.append("%s names no CapitalCatalog country (%s)" % [t, cc])
		else:
			var near := INF
			for p in capitals[cc]:
				near = minf(near, LocationData.distance_m((p as Vector2).x, (p as Vector2).y,
					float(e["lat"]), float(e["lon"])))
			if near > AIRPORT_REACH_M:
				failures.append("%s stands %.0f m from its capital" % [t, near])
		if str(e.get("kind", "")) != "Airport" or not bool(e.get("secondary", false)):
			failures.append("%s should be a secondary Airport" % t)
		var rect: Array = e.get("clear_rect_m", [])
		if rect.size() != 4:
			failures.append("%s lacks clear_rect_m" % t)
		if not LandmarkBuilder.is_bespoke(t):
			failures.append("%s has no hand-built model" % t)
			continue
		var root := LandmarkBuilder.build(t)
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for m in LandmarkBuilder.parts(root):
			var box := m.transform * m.mesh.get_aabb()
			lo = lo.min(box.position)
			hi = hi.max(box.end)
		var h := float(e["height_m"])
		if absf(hi.y - h) > maxf(2.0, h * 0.03):
			failures.append("%s should stand %.1f m tall, got %.1f m" % [t, h, hi.y])
		if rect.size() == 4:
			var x0 := float(rect[0]) - float(rect[2])
			var x1 := float(rect[0]) + float(rect[2])
			var z0 := float(rect[1]) - float(rect[3])
			var z1 := float(rect[1]) + float(rect[3])
			if lo.x < x0 - 1.0 or hi.x > x1 + 1.0 or lo.z < z0 - 1.0 or hi.z > z1 + 1.0:
				failures.append("%s model spans x %.0f..%.0f z %.0f..%.0f outside clear_rect_m x %.0f..%.0f z %.0f..%.0f"
					% [t, lo.x, hi.x, lo.z, hi.z, x0, x1, z0, z1])
		root.free()
	# Hand-built airports never displace a capital's own icon.
	if LocationData.landmark_for(64.1355, -21.8954, "Reykjavik") == "reykjavik_airport":
		failures.append("Reykjavik should not open on its airport")
	# The set owns only its own types.
	var probe := Node3D.new()
	if LandmarkSetCapitalAirports.build(probe, "no_such_airport"):
		failures.append("an unknown type should not be built by the airport set")
	probe.free()
	# The aircraft kit: every kind about its real length, with geometry.
	for kind in REAL_LENGTH_M:
		var lm := LandmarkMesh.new()
		LandmarkAircraft.mats(lm)
		LandmarkAircraft.place(lm, kind, "#C8102E", Vector2.ZERO, 0.0)
		var holder := Node3D.new()
		lm.commit(holder)
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for m in holder.get_children():
			var box := (m as MeshInstance3D).mesh.get_aabb()
			lo = lo.min(box.position)
			hi = hi.max(box.end)
		var want: float = REAL_LENGTH_M[kind]
		if absf((hi.x - lo.x) - want) > want * 0.1:
			failures.append("a %s should be about %.1f m long, got %.1f m" % [kind, want, hi.x - lo.x])
		if lm.triangle_count() < 100:
			failures.append("a %s has only %d triangles" % [kind, lm.triangle_count()])
		holder.free()
	if failures.is_empty():
		print("capital_airports_test: PASS (%d airports)" % rows.size())
		quit(0)
	else:
		for f in failures:
			printerr("capital_airports_test FAIL: ", f)
		quit(1)
