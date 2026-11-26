extends SceneTree

## Headless: tools/godot_bg.sh --headless --path . --script tests/pasila_trains_test.gd
## Verifies Pasila station area accuracy and collision-free stationed + moving trains:
## 1. Mall of Tripla builds an open elevated portal over Pasila's railway tracks.
## 2. Station-overbuild tunnel=yes track segments stitch continuously and RailPlatforms
##    generates ground-level concrete platforms, safety edges and canopies.
## 3. A multi-track Pasila-like through-station with converging switch throats spawns
##    both stationed and moving trains that run for 10 minutes with zero collisions
##    (moving-vs-moving and moving-vs-stationed).

const Tripla = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_tripla.gd")

func _init() -> void:
	_run()

func _data() -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(10.0)
	data.water_level = -3.0
	data.latitude = 60.1988
	data.longitude = 24.9336
	data.country = "FI"
	data.buildings = []
	return data

func _rail(tags: Dictionary, pts: Array) -> Dictionary:
	var all := {"railway": "rail", "gauge": "1524", "electrified": "contact_line"}
	all.merge(tags, true)
	return OsmTags._rail_entry(all, PackedVector2Array(pts))

func _build_pasila_yard(data: LocationData) -> void:
	# 10 parallel north-south tracks (spacing 5.5 m..11 m across 5 island platforms),
	# each split into north open approach, station portal (tunnel=yes, layer=-1),
	# and south viaduct bridge (bridge=yes, layer=1) + converging switch throats.
	var xs := [-48.0, -42.0, -28.0, -22.0, -8.0, -2.0, 12.0, 18.0, 32.0, 38.0]
	for i in xs.size():
		var x: float = xs[i]
		# Converge pairs slightly at north (-480..-360) and south (+340..+480) to create switch throats.
		var pair_x: float = (xs[i - 1] + x) * 0.5 if i % 2 == 1 else (x + xs[i + 1]) * 0.5
		data.railways.append(_rail({}, [Vector2(pair_x, -520), Vector2(x, -340), Vector2(x, -80)]))
		data.railways.append(_rail({"tunnel": "yes", "layer": "-1"}, [Vector2(x, -80), Vector2(x, 60)]))
		data.railways.append(_rail({}, [Vector2(x, 60), Vector2(x, 90)]))
		data.railways.append(_rail({"bridge": "yes", "layer": "1"}, [Vector2(x, 90), Vector2(x, 210)]))
		data.railways.append(_rail({}, [Vector2(x, 210), Vector2(x, 340), Vector2(pair_x, 520)]))
	# 5 island platforms between adjacent track pairs (open north stretch z = -280..-70).
	for p_x: float in [-35.0, -15.0, 5.0, 25.0, 45.0]:
		data.rail_platforms.append({"points": PackedVector2Array([
			Vector2(p_x - 3.2, -280), Vector2(p_x + 3.2, -280),
			Vector2(p_x + 3.2, -70), Vector2(p_x - 3.2, -70), Vector2(p_x - 3.2, -280)])})
		# Covered concourse platform continuation (z = -70..+50).
		data.rail_platforms.append({"points": PackedVector2Array([
			Vector2(p_x - 3.2, -70), Vector2(p_x + 3.2, -70),
			Vector2(p_x + 3.2, 50), Vector2(p_x - 3.2, 50), Vector2(p_x - 3.2, -70)])})
	data.rail_stations = [{"x": 0.0, "z": -10.0, "name": "Pasila"}]

func _run() -> void:
	var failures: Array[String] = ["sentinel: run did not finish"]
	_check_tripla_portal(failures)
	_check_portals_and_platforms(failures)
	_check_bridge_piers_and_roof_snap(failures)
	_check_stationed_and_moving_no_collisions(failures)
	failures.remove_at(0)
	if failures.is_empty():
		print("PASS: pasila_trains_test")
		quit(0)
	else:
		for f in failures:
			push_error("FAIL: " + f)
			print("FAIL: " + f)
		quit(1)

func _check_tripla_portal(failures: Array[String]) -> void:
	var model := Node3D.new()
	Tripla.build(model)
	var mesh_count := 0
	var blocked_track_verts := 0
	# Track 8 centreline at z = -50 is x ≈ 142 m (well away from the 6 platform-island piers).
	for child in model.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
			mesh_count += 1
			var m := (child as MeshInstance3D).mesh
			for si in m.get_surface_count():
				var arrays := m.surface_get_arrays(si)
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				for v in verts:
					if v.x > 140.0 and v.x < 144.0 and v.z > -65.0 and v.z < -35.0 and v.y > 0.5 and v.y < 6.8:
						blocked_track_verts += 1
	if mesh_count == 0:
		failures.append("Mall of Tripla should build meshes")
	if blocked_track_verts > 0:
		failures.append("Pasila station concourse must leave open track portal (found %d blocking verts)" % blocked_track_verts)
	model.free()

func _check_portals_and_platforms(failures: Array[String]) -> void:
	var data := _data()
	_build_pasila_yard(data)
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var portals := TramRoute.station_portals(data, m2u)
	if portals.size() != 10:
		failures.append("expected 10 station portal rail ways, got %d" % portals.size())
	var carries := func(r: Dictionary) -> bool: return TrainSpecs.carries(r)
	var routes := TramRoute.chains(data, ground, m2u, carries, true, true)
	if routes.size() < 8:
		failures.append("portal stitching should yield continuous tracks through Pasila: %d" % routes.size())
	var long_routes := 0
	var decked_routes := 0
	for rt in routes:
		if rt.length_m > 900.0:
			long_routes += 1
		if not rt.heights.is_empty() and not rt.unsupported(0.0, rt.length_m):
			decked_routes += 1
	if long_routes < 8:
		failures.append("expected >= 8 continuous >900 m stitched routes through Pasila, got %d" % long_routes)
	if decked_routes < 8:
		failures.append("expected >= 8 routes with RailDecks bridge heights, got %d" % decked_routes)
	var mouths := TramRoute.mouths(data, carries, true)
	if not mouths.is_empty():
		failures.append("station portal ways should not emit artificial tunnel mouths: %d" % mouths.size())
	var root := Node3D.new()
	RailBuilder.build(root, data, ground)
	var names := {}
	for c in root.get_children():
		names[str(c.name)] = true
	for want in ["Rail_ballast", "Rail_rail", "Rail_platform_concrete", "Rail_platform_edge", "Rail_platform_canopy"]:
		if not names.has(want):
			failures.append("RailBuilder missing expected mesh %s" % want)
	root.free()

func _check_bridge_piers_and_roof_snap(failures: Array[String]) -> void:
	var data := _data()
	_build_pasila_yard(data)
	data.landmark_candidates = [{"x": 0.0, "z": 0.0, "type": "mall_of_tripla", "height": 30.0, "clear_m": 40.0}]
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var surf := RoadBuilder._Surface.new(data, ground)
	# Mall of Tripla must not lift adjacent layer-1 footbridges up to its 30 m roof.
	if surf.landmark_roof_y(Vector2.ZERO) > -1e8:
		failures.append("mall_of_tripla must not act as a 30 m rooftop deck for nearby footbridges")
	# Bridge piers must detect railway tracks underneath (both open and station-portal tracks).
	if not RoadBridgeBuild._on_rail_below(Vector2(-8.0, 0.0), surf, m2u):
		failures.append("bridge pier check must detect station-portal rail track at x=-8, z=0")
	if not RoadBridgeBuild._on_rail_below(Vector2(-8.0, 150.0), surf, m2u):
		failures.append("bridge pier check must detect viaduct rail track at x=-8, z=150")
	if RoadBridgeBuild._on_rail_below(Vector2(-15.0, 0.0), surf, m2u):
		failures.append("clear platform island between tracks at x=-15 should allow a bridge pier")

func _check_stationed_and_moving_no_collisions(failures: Array[String]) -> void:
	var data := _data()
	_build_pasila_yard(data)
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var plan := StationTrains.plan(data, ground, m2u)
	var stationed := 0
	var moving := 0
	for tr: Dictionary in plan:
		if bool(tr.get("moving", false)):
			moving += 1
		else:
			stationed += 1
	if stationed == 0 or moving == 0:
		failures.append("Pasila should have both stationed (%d) and moving (%d) trains" % [stationed, moving])
	var world := Node3D.new()
	var built := StationTrains.build(world, data, ground)
	if built != plan.size():
		failures.append("StationTrains.build built %d vs planned %d" % [built, plan.size()])
	var mover := VehicleMover.attach(world, data, ground)
	if mover == null or mover.count() != moving:
		failures.append("VehicleMover should drive %d moving trains, got %s" % [moving, 0 if mover == null else mover.count()])
		world.free()
		return
	var start_s := []
	for i in mover.count():
		start_s.append(mover.position_of(i))
	var max_disp := 0.0
	var collided := false
	# Simulate 10 minutes (6000 ticks at 0.1 s) checking every pair of visible trains.
	for step in 6000:
		mover.tick(0.1, Vector2.ZERO)
		var active: Array = []
		for i in mover.count():
			var t: Dictionary = mover._trains[i]
			max_disp = maxf(max_disp, absf(float(t["s"]) - float(start_s[i])))
			if not bool(t["hidden"]):
				var rt: TramRoute = t["route"]
				var half := float(t["length"]) * 0.5
				active.append({"a": rt.xz_at(float(t["s"]) - half), "b": rt.xz_at(float(t["s"]) + half), "hw": 1.5 * m2u, "id": "M%d" % i})
		for j in mover._static_trains.size():
			var st: Dictionary = mover._static_trains[j]
			var rt: TramRoute = st["route"]
			var half := float(st["length"]) * 0.5
			active.append({"a": rt.xz_at(float(st["s"]) - half), "b": rt.xz_at(float(st["s"]) + half), "hw": 1.5 * m2u, "id": "S%d" % j})
		for a_i in active.size():
			for b_i in range(a_i + 1, active.size()):
				var g := TransitVehicles._gap(active[a_i], active[b_i])
				var min_clear := float(active[a_i]["hw"]) + float(active[b_i]["hw"])
				if g < min_clear:
					failures.append("collision at tick %d between %s and %s: gap=%.2fm < %.2fm" % [
						step, active[a_i]["id"], active[b_i]["id"], g / m2u, min_clear / m2u])
					collided = true
					break
			if collided:
				break
		if collided:
			break
	if max_disp < 50.0:
		failures.append("moving trains should travel >50 m in 10 minutes (max %.1f m)" % max_disp)
	mover.stop()
	world.free()
