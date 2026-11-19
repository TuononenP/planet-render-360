extends SceneTree

func _init() -> void:
	var data := LocationData.new()
	data.grid_size = 8
	data.heights.resize(64)
	data.heights.fill(3.0)
	data.water_level = -3.0
	var ground := GroundTruth.new(data)
	var points := PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	var heights: Array[float] = []
	for tagged in [2.75, NAN]:
		data.barriers = [{"class": "fence", "points": points, "height_m": tagged}]
		var holder := Node3D.new()
		StreetProps._barriers(holder, data, ground, {"m2u": 1.0, "season": 0})
		if holder.get_child_count() != 1:
			printerr("BARRIER HEIGHT FAIL: expected a fence mesh")
			quit(1)
			return
		var mesh: Mesh = (holder.get_child(0) as MeshInstance3D).mesh
		heights.append(mesh.get_aabb().size.y)
		holder.free()
	if absf(heights[0] - 2.75) > 0.001 or absf(heights[1] - 1.5) > 0.001:
		printerr("BARRIER HEIGHT FAIL: tagged height and default: ", heights)
		quit(1)
		return
	data.barriers = [
		{"class": "fence", "points": points, "fence_type": "chain_link"},
		{"class": "fence", "points": points, "material": "wood"},
		{"class": "fence", "points": points}]
	var holder := Node3D.new()
	StreetProps._barriers(holder, data, ground, {"m2u": 1.0, "season": 0})
	for name in ["Prop_barrier_chain_link", "Prop_barrier_wood_fence", "Prop_barrier_fence"]:
		if holder.get_node_or_null(name) == null:
			printerr("BARRIER HEIGHT FAIL: missing material batch ", name)
			quit(1)
			return
	holder.free()
	# A landmark that builds its own walls (model_rects_m: Helsinki
	# Cathedral's statue precinct, local (0.6, 97)) drops the mapped
	# barriers and buildings inside it and keeps those outside.
	var e := LocationData.entry_for_type("helsinki_cathedral")
	data.latitude = float(e["lat"])
	data.longitude = float(e["lon"])
	data.landmark_type = "helsinki_cathedral"
	data.has_landmark_site = true
	data.landmark_lat = data.latitude
	data.landmark_lon = data.longitude
	var axis := LandmarkSites.axis(e)
	var statue := axis * 0.6 + Vector2(-axis.y, axis.x) * 97.0
	var away := statue + Vector2(0, 30)
	for at in [statue, away]:
		data.barriers = [{"class": "retaining_wall", "points": PackedVector2Array([at - Vector2(3, 0), at + Vector2(3, 0)])}]
		var site_holder := Node3D.new()
		StreetProps._barriers(site_holder, data, ground, {"m2u": 1.0, "season": 0})
		var drawn := site_holder.get_child_count() > 0
		site_holder.free()
		var kept := BuildingBuilder._accepted(data, {"x": at.x, "z": at.y}, TerrainBuilder.landmark_site_xz(data), 1200.0)
		if drawn != (at == away) or kept != (at == away):
			printerr("BARRIER HEIGHT FAIL: model rect at ", at, " drew wall ", drawn, " kept building ", kept)
			quit(1)
			return
	var bad := _terrain_checks()
	if bad != "":
		printerr("BARRIER HEIGHT FAIL: ", bad)
		quit(1)
		return
	print("BARRIER HEIGHT OK: mapped height and fallback, retaining walls, railings on edges")
	quit(0)

const SIZE := 129
const STEP_M := 2.0

## A ground `low` m high for x < -1 and `high` m for x > 1 (a step edge
## along z at x = 0, a 2 m ramp between the two rows of posts), with the
## flights of steps `steps` held on it.
func _stepped(low: float, high: float, steps: Array = []) -> GroundTruth:
	var m := WorldScale.metres_to_units()
	var g := GroundTruth.new(null)
	g._size = SIZE
	g._step_units = STEP_M * m
	g._half_units = float(SIZE) * 0.5 * STEP_M * m
	g.water_level_m = -100.0
	g._surface.resize(SIZE * SIZE)
	g._level.resize(SIZE * SIZE)
	g._level.fill(-INF)
	for z in SIZE:
		for x in SIZE:
			var wx := (float(x) - float(SIZE) * 0.5) * STEP_M
			g._surface[z * SIZE + x] = lerpf(low, high, clampf((wx + 1.0) / 2.0, 0.0, 1.0))
	g.steps = steps
	return g

## The one mesh the barriers of `data` make on `ground`, or null.
func _mesh(data: LocationData, ground: GroundTruth) -> Mesh:
	var holder := Node3D.new()
	StreetProps._barriers(holder, data, ground, {"m2u": 1.0, "season": 0})
	var mesh: Mesh = (holder.get_child(0) as MeshInstance3D).mesh if holder.get_child_count() > 0 else null
	holder.free()
	return mesh

func _terrain_checks() -> String:
	var m := WorldScale.metres_to_units()
	var data := LocationData.new()
	var edge := PackedVector2Array([Vector2(0, -1.5) * m, Vector2(0, 1.5) * m])
	# A retaining wall holds back the drop across it: from the lower side
	# (3 m) up to the higher (4 m) and its coping; level ground keeps 1.2 m.
	data.barriers = [{"class": "retaining_wall", "points": edge}]
	var wall := _mesh(data, _stepped(3.0, 4.0))
	if wall == null or absf(wall.get_aabb().end.y - (4.0 + StreetProps.COPING_M)) > 0.02:
		return "retaining wall top %s, want %.2f" % [wall.get_aabb().end.y if wall != null else "none", 4.0 + StreetProps.COPING_M]
	var flat := _mesh(data, _stepped(3.0, 3.0))
	if flat == null or absf(flat.get_aabb().end.y - 4.2) > 0.02:
		return "level retaining wall top %s, want 4.2" % [flat.get_aabb().end.y if flat != null else "none"]
	data.barriers = [{"class": "retaining_wall", "points": edge, "height_m": 2.0}]
	var tagged := _mesh(data, _stepped(3.0, 4.0))
	if tagged == null or absf(tagged.get_aabb().end.y - (3.5 + 2.0)) > 0.02:
		return "tagged retaining wall top %s, want 5.5 (its own height on the ground under it)" % [tagged.get_aabb().end.y if tagged != null else "none"]

	# A fence along a metre-high edge stands on the upper ground; on level
	# ground it stands where it is.
	data.barriers = [{"class": "fence", "points": edge}]
	var fence := _mesh(data, _stepped(3.0, 4.0))
	if fence == null or absf(fence.get_aabb().position.y - 4.0) > 0.02:
		return "fence on a 1 m edge stands at %s, want 4.0" % [fence.get_aabb().position.y if fence != null else "none"]
	var level_fence := _mesh(data, _stepped(3.0, 3.0))
	if level_fence == null or absf(level_fence.get_aabb().position.y - 3.0) > 0.02:
		return "fence on level ground stands at %s, want 3.0" % [level_fence.get_aabb().position.y if level_fence != null else "none"]

	# A fence ring round a statue is its 1.1 m railing, unless it is tagged.
	var ring := PackedVector2Array([Vector2(-3, -3) * m, Vector2(3, -3) * m, Vector2(3, 3) * m, Vector2(-3, 3) * m, Vector2(-3, -3) * m])
	var pedestal := PackedVector2Array([Vector2(-1, -1) * m, Vector2(1, -1) * m, Vector2(1, 1) * m, Vector2(-1, 1) * m])
	data.buildings = [{"statue": "yes", "x": 0.0, "z": 0.0, "footprint": pedestal}]
	data.barriers = [{"class": "fence", "points": ring}]
	var round_statue := _mesh(data, _stepped(3.0, 3.0))
	if round_statue == null or absf(round_statue.get_aabb().size.y - 1.1) > 0.02:
		return "fence round a statue is %s m tall, want 1.1" % [round_statue.get_aabb().size.y if round_statue != null else "none"]
	data.barriers = [{"class": "fence", "points": ring, "height_m": 2.0}]
	var tagged_ring := _mesh(data, _stepped(3.0, 3.0))
	if tagged_ring == null or absf(tagged_ring.get_aabb().size.y - 2.0) > 0.02:
		return "tagged fence round a statue is %s m tall, want 2.0" % [tagged_ring.get_aabb().size.y if tagged_ring != null else "none"]
	data.buildings = []
	data.barriers = [{"class": "fence", "points": ring}]
	var plain_ring := _mesh(data, _stepped(3.0, 3.0))
	if plain_ring == null or absf(plain_ring.get_aabb().size.y - 1.5) > 0.02:
		return "fence round nothing is %s m tall, want 1.5" % [plain_ring.get_aabb().size.y if plain_ring != null else "none"]

	# A fence mapped across a flight of steps (a way's strip, or an area)
	# stops at it.
	var across := PackedVector2Array([Vector2(4, -1.5) * m, Vector2(4, 1.5) * m])
	data.barriers = [{"class": "fence", "points": across}]
	var way := {"road": 0, "points": PackedVector2Array([Vector2(-1, 0) * m, Vector2(9, 0) * m]),
		"y_top": 3.0, "y_bot": 0.0, "n": 18, "width": 2.0 * m, "handrail": false, "area": false,
		"ring": PackedVector2Array(), "holes": []}
	var area := way.duplicate()
	area["area"] = true
	area["ring"] = PackedVector2Array([Vector2(0, -3) * m, Vector2(8, -3) * m, Vector2(8, 3) * m, Vector2(0, 3) * m])
	if _mesh(data, _stepped(3.0, 3.0)) == null:
		return "a fence off the stairs is drawn"
	for flight: Dictionary in [way, area]:
		if _mesh(data, _stepped(3.0, 3.0, [flight])) != null:
			return "a fence across a %s is drawn" % ("steps area" if bool(flight["area"]) else "flight")
	return ""
