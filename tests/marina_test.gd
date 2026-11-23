extends SceneTree

## Headless: godot --headless --script tests/marina_test.gd
## Marina boats (MarinaBuilder, desktop Ultra): OSM piers parse (floating
## flag), boats moor stern-to on both sides of a pier, only in water, never
## overlapping a pontoon or each other, the same harbour gets the same
## fleet, and the meshes build.

func _init() -> void:
	var failures: Array[String] = []
	var text := JSON.stringify({"elements": [
		{"type": "way", "id": 1, "tags": {"man_made": "pier", "floating": "yes"},
			"geometry": [{"lat": 43.7300, "lon": 7.4200}, {"lat": 43.7300, "lon": 7.4215}]},
		{"type": "way", "id": 2, "tags": {"man_made": "pier"},
			"geometry": [{"lat": 43.7302, "lon": 7.4200}, {"lat": 43.7302, "lon": 7.4210}]},
	]})
	var parsed := OsmParser.parse_features(text, 43.7300, 7.4200)
	var piers: Array = parsed["piers"]
	if piers.size() != 2 or not bool(piers[0]["floating"]) or bool(piers[1]["floating"]):
		failures.append("two piers, the first floating: %s" % [piers])
	var m := WorldScale.metres_to_units()
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.ULTRA)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(-6.0)  # open water over the whole extent
	d.water_level = 0.0
	d.seed_value = 7
	d.latitude = 43.73
	d.longitude = 7.42
	# One 160 m floating pontoon along x and a land finger it must not cross.
	d.piers = [{"points": PackedVector2Array([Vector2(-80.0 * m, 0.0), Vector2(80.0 * m, 0.0)]), "floating": true, "width_m": NAN}]
	var ground := GroundTruth.new(d)
	var p := MarinaBuilder.plan(d, ground, m)
	var boats: Array = p["boats"]
	if boats.size() < 12:
		failures.append("a 160 m pontoon should berth a fleet, got %d boats" % boats.size())
	var north := 0
	var south := 0
	var overlap := false
	for b in boats:
		var o: Vector3 = b[0]
		var yaw: float = b[1]
		if o.z < 0.0:
			north += 1
		else:
			south += 1
		# Stern-to: the bow points straight away from the pier.
		var bow := Vector2(cos(yaw), -sin(yaw))
		if absf(bow.x) > 0.01 or absf(absf(o.z) / m - 1.6) > 0.2:
			failures.append("a boat should lie perpendicular, stern 1.6 m off the axis: z %.2f yaw %.2f" % [o.z / m, yaw])
			break
	if north < 4 or south < 4:
		failures.append("boats on both sides: %d / %d" % [north, south])
	# No two boats within a hull's beam of each other along the pontoon.
	var xs: Array = []
	for b in boats:
		xs.append([(b[0] as Vector3).x / m, signf((b[0] as Vector3).z), float(b[2]) * 10.0])
	for i in xs.size():
		for j in range(i + 1, xs.size()):
			if xs[i][1] == xs[j][1] and absf(float(xs[i][0]) - float(xs[j][0])) < 0.3 * minf(float(xs[i][2]), float(xs[j][2])):
				overlap = true
	if overlap:
		failures.append("two boats overlap on one side of the pontoon")
	var again := MarinaBuilder.plan(d, ground, m)["boats"] as Array
	if again.size() != boats.size() or (again[0][0] as Vector3) != (boats[0][0] as Vector3):
		failures.append("the same harbour should get the same fleet")
	# Flat dry terrain (no carved water, like Monaco's harbour): a floating
	# pontoon still berths boats, a quay does not, and a building blocks a berth.
	var dry := LocationData.new()
	RenderSettings.apply_preset(dry, RenderSettings.Preset.ULTRA)
	dry.heights.resize(dry.grid_size * dry.grid_size)
	dry.heights.fill(5.0)
	dry.water_level = 0.0
	dry.seed_value = 7
	dry.latitude = 43.73
	dry.longitude = 7.42
	dry.piers = d.piers
	var dground := GroundTruth.new(dry)
	var flat := (MarinaBuilder.plan(dry, dground, m)["boats"] as Array).size()
	if flat < 12:
		failures.append("a floating pontoon on a flat datum basin should berth boats, got %d" % flat)
	var quay: Dictionary = (dry.piers[0] as Dictionary).duplicate()
	quay["floating"] = false
	dry.piers = [quay]
	if (MarinaBuilder.plan(dry, dground, m)["boats"] as Array).size() != 0:
		failures.append("a quay on dry ground gets no berths")
	dry.piers = d.piers
	dry.buildings = [{"x": 0.0, "z": 12.0 * m, "size_x": 160.0 * m, "size_z": 20.0 * m, "height": 9.0,
		"footprint": PackedVector2Array([Vector2(-80, 2) * m, Vector2(80, 2) * m, Vector2(80, 22) * m, Vector2(-80, 22) * m])}]
	var blocked := (MarinaBuilder.plan(dry, dground, m, VegetationMask.new(dry, dground))["boats"] as Array)
	var on_south := blocked.filter(func(b: Array) -> bool: return (b[0] as Vector3).z > 0.0).size()
	if on_south != 0 or blocked.size() < 4:
		failures.append("a building should block the south berths only: %d south, %d total" % [on_south, blocked.size()])
	# A mapped structure can also stand on carved water; it must veto
	# the boat rather than being bypassed by the water-depth check.
	var wet_building := LocationData.new()
	wet_building.grid_size = 49
	wet_building.heights.resize(49 * 49)
	wet_building.heights.fill(3.0)
	wet_building.water_level = 0.5
	wet_building.land_polygons = [{"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-1200, 0), Vector2(1200, 0),
			Vector2(1200, 1200), Vector2(-1200, 1200)])}]
	wet_building.buildings = dry.buildings
	var wet_ground := GroundTruth.new(wet_building)
	var wet_mask := VegetationMask.new(wet_building, wet_ground)
	if wet_ground.water_at(0.0, 10.0 * m) <= MarinaBuilder.MIN_DEPTH_M * m:
		failures.append("the obstruction fixture must stand on carved water")
	if MarinaBuilder._wet(wet_ground, Vector2(0, 10) * m, m, 0.0, wet_mask):
		failures.append("a building on mapped water must block a berth")
	# A floating pontoon flush against a river quay (water on south, flat grass
	# bank on north, as at Forum Marinum in Turku) must never berth boats onto
	# the dry bank even when the bank sits within FLAT_M of the water level.
	var riverside := LocationData.new()
	RenderSettings.apply_preset(riverside, RenderSettings.Preset.ULTRA)
	riverside.grid_size = 49
	riverside.heights.resize(49 * 49)
	riverside.heights.fill(2.0)
	riverside.water_level = 0.0
	riverside.seed_value = 7
	riverside.latitude = 60.437
	riverside.longitude = 22.238
	riverside.country = "FI"
	riverside.land_polygons = [{"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-600, 0) * m, Vector2(600, 0) * m,
			Vector2(600, 400) * m, Vector2(-600, 400) * m])}]
	riverside.piers = [{"points": PackedVector2Array([Vector2(-40.0 * m, 0.5 * m), Vector2(40.0 * m, 0.5 * m)]),
		"floating": true, "width_m": NAN}]
	var rground := GroundTruth.new(riverside)
	var rboats: Array = MarinaBuilder.plan(riverside, rground, m, VegetationMask.new(riverside, rground))["boats"]
	if rboats.is_empty():
		failures.append("a riverside floating pontoon should still berth boats on its water side")
	for rb in rboats:
		var ro: Vector3 = rb[0]
		var ryaw: float = rb[1]
		var rout := Vector2(cos(ryaw), -sin(ryaw))
		var rbow := Vector2(ro.x, ro.z) + rout * float(rb[2]) * MarinaBuilder.MESH_LEN_M
		if rground.water_at(ro.x, ro.z) <= 0.0 or rground.water_at(rbow.x, rbow.y) <= 0.0:
			failures.append("a riverside pontoon moored a boat onto dry land: stern=%s bow=%s" % [ro, rbow])
			break
	# A steep ramp across the berths (quay slope): boats would be buried, none placed.
	var ramp := LocationData.new()
	RenderSettings.apply_preset(ramp, RenderSettings.Preset.ULTRA)
	ramp.heights.resize(ramp.grid_size * ramp.grid_size)
	for zi in ramp.grid_size:
		for xi in ramp.grid_size:
			ramp.heights[zi * ramp.grid_size + xi] = float(zi) * 10.0
	ramp.water_level = -50.0
	ramp.seed_value = 7
	ramp.latitude = 43.73
	ramp.longitude = 7.42
	ramp.piers = d.piers
	var steep := (MarinaBuilder.plan(ramp, GroundTruth.new(ramp), m)["boats"] as Array).size()
	if steep != 0:
		failures.append("berths across a steep ramp should stay empty, got %d boats" % steep)
	# Finland's fleet (HarbourVesselData.FLEET_PROFILES): the same berths, but
	# varnished wooden hulls, more sailboats and fewer big white yachts. Other
	# countries keep the default fleet.
	if MarinaBuilder.fleet_of(d)["hulls"] != MarinaBuilder.HULL_COLOURS:
		failures.append("a place without a profile should keep the default hull colours")
	d.country = "FI"
	var fi_boats := MarinaBuilder.plan(d, ground, m)["boats"] as Array
	d.country = ""
	if fi_boats.size() < 12:
		failures.append("the Finnish fleet should berth boats too, got %d" % fi_boats.size())
	var share := func(list: Array, test: Callable) -> float:
		var hits := 0
		for b: Array in list:
			if test.call(b):
				hits += 1
		return float(hits) / maxf(float(list.size()), 1.0)
	var is_wood := func(b: Array) -> bool: return (b[4] as Color).r > (b[4] as Color).b + 0.25
	var is_sail := func(b: Array) -> bool: return str(b[3]) == "sail"
	var is_yacht := func(b: Array) -> bool: return str(b[3]) == "yacht"
	if float(share.call(fi_boats, is_wood)) < 0.15 or float(share.call(boats, is_wood)) > 0.02:
		failures.append("Finnish hulls should include wooden browns, the default none: %.2f / %.2f" % [
			share.call(fi_boats, is_wood), share.call(boats, is_wood)])
	if float(share.call(fi_boats, is_sail)) <= float(share.call(boats, is_sail)):
		failures.append("the Finnish fleet should carry more sailboats than the default")
	if float(share.call(fi_boats, is_yacht)) >= float(share.call(boats, is_yacht)):
		failures.append("the Finnish fleet should carry fewer flybridge yachts than the default")
	var root := Node3D.new()
	var n := MarinaBuilder.build(root, d, ground)
	if RenderQuality.ultra_desktop(d.quality_preset) and (n != boats.size() or not root.has_node("Marina/Pontoons")):
		failures.append("build should add the boats and the pontoon deck, got %d" % n)
	var high := Node3D.new()
	var hd := LocationData.new()
	RenderSettings.apply_preset(hd, RenderSettings.Preset.HIGH)
	hd.piers = d.piers
	if MarinaBuilder.build(high, hd, ground) != 0:
		failures.append("boats are desktop Ultra only")
	for kind in ["motor", "sail"]:
		var mesh := MarinaBuilder.mesh(kind)
		var box := mesh.get_aabb()
		if mesh.get_surface_count() < 3 or absf(box.size.x - 10.0) > 0.6:
			failures.append("%s mesh: %d surfaces, %.1f m long" % [kind, mesh.get_surface_count(), box.size.x])
	root.free()
	high.free()
	if failures.is_empty():
		print("MARINA OK: piers parsed, %d boats stern-to on both sides, wet and clear of each other, deterministic, meshes" % boats.size())
		quit(0)
	else:
		for f in failures:
			printerr("MARINA FAIL: ", f)
		quit(1)
