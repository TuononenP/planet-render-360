extends SceneTree

## Headless: godot --headless --script tests/tram_test.gd
## Trams (TramSpecs, TramModel, TramRoute, TransitVehicles): every type
## builds grounded, outward-facing sections near and far within budget;
## the city and the track pick the type and livery; ways join into one
## route across shared nodes with a continuous, monotonic pose; an
## articulated tram's bogies stay on a curve; trams keep out of tunnels,
## off bridges and apart; and the quality gate holds.

const LIVERY := {"modern3": "helsinki", "modern5": "generic2", "modern2": "helsinki", "lrv": "sf_lrv",
	"heritage": "lisbon", "cable": "sf_cable", "pcc": "pcc_green"}

func _init() -> void:
	_run()

func _data(lat: float, lon: float) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.latitude = lat
	data.longitude = lon
	data.buildings = []
	return data

func _rail(tags: Dictionary, pts: Array) -> Dictionary:
	var all := {"railway": "tram"}
	all.merge(tags, true)
	return OsmTags._rail_entry(all, PackedVector2Array(pts))

## A quarter circle of radius `r` leaving `from` eastward, turning south.
func _arc(from: Vector2, r: float) -> Array:
	var out: Array = []
	for i in 19:
		var a := deg_to_rad(5.0 * float(i))
		out.append(from + Vector2(sin(a), 1.0 - cos(a)) * r)
	return out

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	_models(failures)
	_selection(failures)
	_route(failures)
	_placement(failures)
	failures.remove_at(0)
	if failures.is_empty():
		print("TRAM OK: every type builds grounded and outward-facing near and far, cities pick their trams, routes join and pose continuously, bogies hold a curve, placement keeps clear and gated")
		quit(0)
	else:
		for failure in failures:
			printerr("TRAM FAIL: ", failure)
		quit(1)

func _models(failures: Array[String]) -> void:
	for kind: String in TramSpecs.KINDS:
		var livery: String = LIVERY[kind]
		var train := TramSpecs.train(kind)
		var length := TramSpecs.length_m(kind)
		var low := [INF, INF]
		var total := [0, 0]
		for sec: Dictionary in train:
			var id := str(sec["id"])
			var near := TramModel.mesh(kind, id, livery, bool(sec["tail"]))
			var far := TramModel.mesh(kind, id, livery, bool(sec["tail"]), true)
			if TramModel.mesh(kind, id, livery, bool(sec["tail"])) != near:
				failures.append("%s %s should share its mesh" % [kind, id])
			var counts: Array[int] = []
			for lod in 2:
				var m: ArrayMesh = [near, far][lod]
				var box := m.get_aabb()
				low[lod] = minf(low[lod], box.position.y)
				if box.position.y < -0.01 or box.end.y > TramModel.COLLECTOR_M + 0.1 \
						or box.size.x < float(sec["len"]) - 0.05 or box.size.x > float(sec["len"]) + 3.2 \
						or box.size.z < TramSpecs.width_m(kind) - 0.05 or box.size.z > TramSpecs.width_m(kind) + 0.8 \
						or absf(box.get_center().z) > 0.01:
					failures.append("%s %s lod %d bounds are not its section's: %s" % [kind, id, lod, box])
				var names := {}
				var tris := 0
				for si in m.get_surface_count():
					names[m.surface_get_name(si)] = m.surface_get_material(si)
					var arr := m.surface_get_arrays(si)
					var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
					var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
					tris += v.size() / 3
					for t in range(0, v.size(), 3):
						# Front faces as Godot winds them: clockwise about the normal.
						if (v[t + 1] - v[t]).cross(v[t + 2] - v[t]).dot(n[t] + n[t + 1] + n[t + 2]) > 0.0:
							failures.append("%s %s lod %d surface %s has a back-facing triangle" % [kind, id, lod, m.surface_get_name(si)])
							break
				counts.append(tris)
				total[lod] += tris
				var glass := names.get("Glass") as StandardMaterial3D
				if glass == null or not glass.has_meta(CityLights.META) or glass.roughness > 0.06:
					failures.append("%s %s lod %d needs smooth glass that lights at night" % [kind, id, lod])
				if not names.has("Roof") or not (names["Roof"] is ShaderMaterial):
					failures.append("%s %s lod %d roof should take snow" % [kind, id, lod])
				if lod == 1 and m.get_surface_count() > 3:
					failures.append("%s %s far mesh should fold to three surfaces: %s" % [kind, id, names.keys()])
			if counts[0] > 9000 or counts[1] > 1400 or counts[1] >= counts[0]:
				failures.append("%s %s triangle budget: near %d, far %d" % [kind, id, counts[0], counts[1]])
		for lod in 2:
			if absf(low[lod]) > 0.03:
				failures.append("%s lod %d wheels should stand on the rail (y = 0): %s" % [kind, lod, low[lod]])
		if total[0] > 30000 or total[1] > 5000:
			failures.append("%s train budget: near %d, far %d" % [kind, total[0], total[1]])
		# Sections butt up along the train, front first, joints shared.
		var x := length * 0.5
		for i in train.size():
			var sec: Dictionary = train[i]
			if absf(float(sec["at"]) - (x - float(sec["len"]) * 0.5)) > 0.001:
				failures.append("%s section %d is misplaced along the train" % [kind, i])
			x -= float(sec["len"]) + float(TramSpecs.KIND[kind]["gap"])
			if i > 0:
				var ahead: Dictionary = train[i - 1]
				var joint_a := float(ahead["at"]) + (ahead["sup"] as Vector2).x
				var joint_b := float(sec["at"]) + (sec["sup"] as Vector2).y
				if absf(joint_a - joint_b) > 0.001:
					failures.append("%s sections %d and %d should share their joint: %s vs %s" % [kind, i - 1, i, joint_a, joint_b])
	for row in [["modern3", 26.0, 29.0], ["modern5", 30.0, 34.0], ["modern2", 19.0, 21.5], ["lrv", 22.0, 24.0],
			["heritage", 8.3, 8.5], ["cable", 8.0, 8.6], ["pcc", 14.0, 14.5]]:
		var got := TramSpecs.length_m(row[0])
		if got < float(row[1]) or got > float(row[2]):
			failures.append("%s should be %s-%s m long, got %s" % [row[0], row[1], row[2], got])
	if TramSpecs.train("modern3").size() != 3 or TramSpecs.train("modern5").size() != 5:
		failures.append("the Helsinki car has three sections, the generic one five")

func _selection(failures: Array[String]) -> void:
	var street := _rail({"gauge": "1000"}, [Vector2.ZERO, Vector2(10, 0)])
	var narrow := _rail({"gauge": "900"}, [Vector2.ZERO, Vector2(10, 0)])
	var standard := _rail({"gauge": "1435"}, [Vector2.ZERO, Vector2(10, 0)])
	var cable := _rail({"gauge": "1067", "electrified": "no", "cable_tram": "cable"}, [Vector2.ZERO, Vector2(10, 0)])
	var light := OsmTags._rail_entry({"railway": "light_rail", "gauge": "1435"}, PackedVector2Array([Vector2.ZERO, Vector2(10, 0)]))
	var heavy := OsmTags._rail_entry({"railway": "rail"}, PackedVector2Array([Vector2.ZERO, Vector2(10, 0)]))
	var rows := [
		["helsinki", "FI", street, 0.9, "modern3", "helsinki"],
		["helsinki", "FI", street, 0.1, "modern2", "helsinki"],
		["lisbon", "PT", narrow, 0.5, "heritage", "lisbon"],
		["lisbon", "PT", standard, 0.5, "modern3", "lisbon_modern"],
		["", "PT", standard, 0.5, "heritage", "porto"],
		["", "pt", narrow, 0.2, "heritage", "porto"],
		["san_francisco", "US", cable, 0.5, "cable", "sf_cable"],
		["san_francisco", "US", standard, 0.0, "pcc", "pcc_green"],
		["san_francisco", "US", standard, 0.99, "pcc", "pcc_orange"],
		["san_francisco", "US", light, 0.5, "lrv", "sf_lrv"],
		["", "DE", street, 0.5, "modern5", ""],
		["haussmann", "FR", standard, 0.5, "modern5", ""],
	]
	for row: Array in rows:
		var got := TramSpecs.pick(row[0], row[1], row[2], row[3])
		if str(got.get("kind", "")) != row[4] or (row[5] != "" and str(got.get("livery", "")) != row[5]):
			failures.append("%s/%s on %s m gauge should run %s %s, got %s" % [row[0], row[1],
				(row[2] as Dictionary)["gauge_m"], row[4], row[5], got])
	var generic := TramSpecs.pick("", "DE", street, 0.2)
	if not str(generic.get("livery", "")).begins_with("generic") or generic != TramSpecs.pick("", "DE", street, 0.8):
		failures.append("a city without its own fleet runs one generic livery: %s" % generic)
	var band: Color = TramSpecs.livery(str(generic["livery"]))["band"]
	if not band in TramSpecs.GENERIC_BANDS or TramSpecs.livery(str(generic["livery"]))["lower"] != TramSpecs.WHITE:
		failures.append("the generic tram is white with a palette band")
	var hel := TramSpecs.livery("helsinki")
	if (hel["lower"] as Color).g < (hel["lower"] as Color).r * 2.0 or (hel["upper"] as Color).v < 0.85:
		failures.append("Helsinki's trams are green under a pale top")
	if not TramSpecs.pick("", "DE", heavy, 0.5).is_empty() or not TramSpecs.pick("", "DE", light, 0.5).is_empty() \
			or not TramSpecs.pick("san_francisco", "US", heavy, 0.5).is_empty():
		failures.append("no tram runs on heavy rail, or on light rail outside San Francisco")

func _route(failures: Array[String]) -> void:
	var data := _data(60.17, 24.94)
	var bend := _arc(Vector2(200, 0), 40.0)
	var end: Vector2 = bend[bend.size() - 1]
	data.railways = [
		_rail({"gauge": "1000"}, [Vector2(100, 0), Vector2(200, 0)]),
		# Mapped against the line: joined by its far end, reversed.
		_rail({"gauge": "1000"}, [Vector2(100, 0), Vector2(40, 0), Vector2(0, 0)]),
		_rail({"gauge": "1000"}, bend),
		# A junction: the branch leaves at a right angle and stays its own route.
		_rail({"gauge": "1000"}, [Vector2(100, 0), Vector2(100, -80)]),
		_rail({"gauge": "1000", "tunnel": "yes"}, [end, end + Vector2(0, 100)]),
	]
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var routes := TramRoute.chains(data, ground, m2u)
	var want := 200.0 + PI * 0.5 * 40.0
	if routes.size() != 2 or absf(routes[0].length_m - want) > 0.5 or absf(routes[1].length_m - 80.0) > 0.01:
		failures.append("three ways sharing nodes should join into one %.1f m route beside the branch: %s" % [want,
			routes.map(func(r: TramRoute) -> float: return r.length_m)])
		return
	var route := routes[0]
	for i in range(1, route.cum.size()):
		if route.cum[i] <= route.cum[i - 1]:
			failures.append("arc length must grow along the route")
			break
	var ends := [route.xz_at(0.0), route.xz_at(route.length_m)]
	if not (Vector2(0, 0) in ends) or not (end in ends) or TramRoute.mouths(data).size() != 2:
		failures.append("the route should run from the first way's far end to the tunnel mouth: %s" % [ends])
	var step := 0.25
	var prev := route.pose_at(0.0)
	var s := step
	while s <= route.length_m:
		var pose := route.pose_at(s)
		if pose.origin.distance_to(prev.origin) > step * 1.01 or pose.origin.distance_to(prev.origin) < step * 0.9 \
				or pose.basis.x.dot(prev.basis.x) < 0.995 or absf(pose.basis.x.length() - 1.0) > 0.001:
			failures.append("pose_at should move evenly and turn smoothly at %.2f m" % s)
			break
		if absf(route.nearest(Vector2(pose.origin.x, pose.origin.z)).x - s) > 0.01:
			failures.append("nearest() should give back the arc length at %.2f m" % s)
			break
		prev = pose
		s += step
	var rail_y := ground.height_at_world(50.0, 0.0) + RailBuilder.STREET_RAIL_LIFT_M
	if absf(route.pose_at(50.0).origin.y - rail_y) > 0.001:
		failures.append("a street tram stands on the flush rail heads: %s vs %s" % [route.pose_at(50.0).origin.y, rail_y])
	if absf(TramRoute.rail_lift_m(_rail({"embedded": "no"}, [Vector2.ZERO, Vector2(1, 0)]))
			- (RailBuilder.BED_LIFT_M + RailBuilder.RAIL_HEIGHT_M)) > 0.001:
		failures.append("on ballast a tram stands on the raised rail")
	# An articulated tram through the bend: every bogie on the line.
	var on_bend := 200.0 + PI * 0.25 * 40.0
	if (route.xz_at(0.0) as Vector2) != Vector2(0, 0):
		on_bend = route.length_m - on_bend
	for kind: String in ["modern5", "modern3", "modern2"]:
		var train := TramSpecs.train(kind)
		var poses := route.place_train(on_bend, train)
		for i in train.size():
			var sec: Dictionary = train[i]
			var pose := poses[i]
			if bool(sec["flip"]):
				pose.basis = pose.basis * Basis(Vector3.UP, PI)
			var spec := TramSpecs.section(kind, str(sec["id"]))
			var bogies: Array = spec.get("bogies", [])
			for x: float in bogies:
				var at := pose * Vector3(x, 0.0, 0.0)
				var off := route.nearest(Vector2(at.x, at.z)).y
				if off > 0.05 or absf(at.y - rail_y) > 0.05:
					failures.append("%s section %d bogie at %.2f is %.3f m off the track" % [kind, i, x, off])
			if i > 0 and (poses[i - 1].basis.x.dot(poses[i].basis.x) > 0.9999 or poses[i - 1].basis.x.dot(poses[i].basis.x) < 0.9):
				failures.append("%s sections %d and %d should bend at their joint" % [kind, i - 1, i])

func _placement(failures: Array[String]) -> void:
	var data := _data(60.17, 24.94)
	data.railways = [
		_rail({"gauge": "1000"}, [Vector2(-500, 30), Vector2(-100, 30)]),
		_rail({"gauge": "1000", "bridge": "yes"}, [Vector2(-100, 30), Vector2(0, 30)]),
		_rail({"gauge": "1000"}, [Vector2(0, 30), Vector2(300, 30)]),
		_rail({"gauge": "1000", "tunnel": "yes"}, [Vector2(300, 30), Vector2(500, 30)]),
		_rail({"gauge": "1000"}, [Vector2(-500, -200), Vector2(500, -200)]),
		# The other track of a double line, 3 m off.
		_rail({"gauge": "1000"}, [Vector2(500, -203), Vector2(-500, -203)]),
	]
	for i in 10:
		data.tram_stops.append({"x": -450.0 + 100.0 * float(i), "z": -198.0, "name": "Stop %d" % i})
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var trains := TransitVehicles.plan(data, ground, m2u)
	var again := TransitVehicles.plan(data, ground, m2u)
	if trains.size() != again.size():
		failures.append("tram placement must be deterministic")
	if trains.size() < 4 or trains.size() > TransitVehicles.MAX_TRAINS:
		failures.append("2.7 km of open track should stand several trams: %d" % trains.size())
	var at_stop := 0
	for i in trains.size():
		var t: Dictionary = trains[i]
		if i < again.size() and (t["s"] != again[i]["s"] or t["kind"] != again[i]["kind"] or t["poses"] != again[i]["poses"]):
			failures.append("tram %d must stand the same on every build" % i)
		var a: Vector2 = t["a"]
		var b: Vector2 = t["b"]
		if not str(t["kind"]) in ["modern3", "modern2"] or str(t["livery"]) != "helsinki":
			failures.append("Helsinki should stand its own trams: %s" % t["kind"])
		if absf(a.distance_to(b) - float(t["length"])) > 0.05:
			failures.append("a tram's footprint should span its length: %s" % a.distance_to(b))
		for p: Vector2 in [a, b]:
			if absf(p.y - 30.0) < 1.0 and (p.x > 270.0 or (p.x > -101.0 and p.x < 1.0)):
				failures.append("a tram stands in the tunnel, within 30 m of its mouth or on the bridge at %s" % p)
		for stop: Dictionary in data.tram_stops:
			if ((a + b) * 0.5).distance_to(Vector2(float(stop["x"]), float(stop["z"]))) < 3.5:
				at_stop += 1
		for j in range(i + 1, trains.size()):
			if TransitVehicles._gap(t, trains[j]) < TransitVehicles.SPACING_M:
				failures.append("trams %d and %d stand under %s m apart" % [i, j, TransitVehicles.SPACING_M])
		var sections: Array = t["sections"]
		if (t["poses"] as Array).size() != sections.size():
			failures.append("a tram needs a pose per section")
	if at_stop < 1:
		failures.append("some trams should stand at the mapped stops")
	# Without stops (bundled payloads) the track still carries trams.
	data.tram_stops = []
	if TransitVehicles.plan(data, ground, m2u).size() < 3:
		failures.append("track without mapped stops should still stand trams")
	# Quality gate: desktop High and Ultra, phones Ultra only.
	if not TransitVehicles.enabled(RenderSettings.Preset.HIGH, true) or not TransitVehicles.enabled(RenderSettings.Preset.ULTRA, true) \
			or not TransitVehicles.enabled(RenderSettings.Preset.ULTRA, false) \
			or TransitVehicles.enabled(RenderSettings.Preset.HIGH, false) \
			or TransitVehicles.enabled(RenderSettings.Preset.BALANCED, true) or TransitVehicles.enabled(RenderSettings.Preset.FAST, true):
		failures.append("trams are for desktop High and Ultra and phone Ultra")
	RenderSettings.apply_preset(data, RenderSettings.Preset.BALANCED)
	var none := Node3D.new()
	if TransitVehicles.build(none, data, ground) != 0 or none.get_child_count() != 0:
		failures.append("Balanced builds no trams")
	none.free()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var holder := Node3D.new()
	var built := TransitVehicles.build(holder, data, ground)
	if built < 3 or holder.get_child_count() != 1:
		failures.append("Ultra should build the trams: %d" % built)
	else:
		var near := 0
		var far := 0
		for node in holder.get_child(0).get_children():
			var mi := node as MeshInstance3D
			if not mi.has_meta("lod_own"):
				failures.append("%s must own its visibility range (LodRing)" % mi.name)
			if mi.name.ends_with("_near"):
				near += 1
				if mi.visibility_range_begin != 0.0 or absf(mi.visibility_range_end - TransitVehicles.DETAIL_M * m2u) > 0.01:
					failures.append("%s should draw up to the detail range" % mi.name)
			elif mi.name.ends_with("_far"):
				far += 1
				if absf(mi.visibility_range_begin - TransitVehicles.DETAIL_M * m2u) > 0.01 or mi.visibility_range_end != 0.0:
					failures.append("%s should draw past the detail range" % mi.name)
				if mi.custom_aabb != (holder.get_child(0).get_node(str(mi.name).replace("_far", "_near")) as MeshInstance3D).custom_aabb:
					failures.append("%s and its near mesh must switch at one distance" % mi.name)
		if near == 0 or near != far:
			failures.append("every section needs a near and a far instance: %d / %d" % [near, far])
	holder.free()
