extends SceneTree

## Offline regressions for the submerged/DEM-buried Alcatraz visit.
## godot --headless --path . --script tests/alcatraz_test.gd

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _data() -> LocationData:
	var d := LocationData.new()
	var e := LocationData.entry_for_type("alcatraz")
	d.latitude = float(e["lat"])
	d.longitude = float(e["lon"])
	d.landmark_type = "alcatraz"
	d.has_landmark_site = true
	d.landmark_lat = d.latitude
	d.landmark_lon = d.longitude
	d.grid_size = 49
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(-55.0)
	d.centre_elevation_m = 38.0
	d.water_level = -48.6
	return d

func _run() -> void:
	var d := _data()
	var g := GroundTruth.new(d)
	var e := LocationData.entry_for_type("alcatraz")
	var hero := TerrainBuilder._landmark(d, g)
	_check(absf(g.asl_y(hero.position.y)) < 0.01, "island origin must be sea level, not the -48.6 m fallback datum")
	var top := -INF
	var tris := 0
	for part in LandmarkBuilder.parts(hero):
		top = maxf(top, (part.transform * part.mesh.get_aabb()).end.y)
		tris += part.mesh.surface_get_array_len(0) / 3
	_check(absf(top - float(e["height_m"])) < 0.5, "lighthouse tip must stand 69 m above the sea")
	_check(tris < 150000, "island must remain inside the landmark triangle budget")
	for p in [Vector2(24, 2), Vector2(115.2, -68.5), Vector2(-158.3, 6.9), Vector2(-187.5, -57.7)]:
		_check(_roof_at(hero, p) > LandmarkSfAlcatraz.ground_height(p) + 6.0,
			"cellhouse, barracks, industries and powerhouse must rise above the rock at %s" % p)
	hero.free()
	var spawn := View360.spawn_xz(d)
	_check(g.asl_y(View360.eye_y(d, g, spawn)) >= View360.EYE_HEIGHT_M - 0.01,
		"plain pin arrival must clear the visible ocean")
	d.focus = LandmarkVisit.from_registry(e)
	_check(absf(g.asl_y(View360.focus_point(d, g, d.focus).y) - 34.5) < 0.01,
		"focus height is measured from sea level, not added to the DEM summit")
	_check(g.asl_y(View360.eye_y(d, g, Vector2.ZERO)) > 60.0,
		"landmark visit on the rock uses authored ground instead of seabed")
	d.view = {"eye_m": 4.0}
	_check(g.asl_y(View360.eye_y(d, g, spawn)) >= 4.0, "saved coastal eye also clears the ocean")
	d.view = {}
	var rig := CameraRig.new()
	for pos in [spawn, Vector2.ZERO]:
		rig.position = Vector3(pos.x, View360.eye_y(d, g, pos), pos.y)
		var state := ViewLink.capture(d, g, rig)
		d.view = ViewLink.to_view(state)
		_check(absf(View360.eye_y(d, g, pos) - rig.position.y) < 0.01,
			"saved island and offshore views must restore the same eye height")
		d.view = {}
	rig.free()
	var axis := LandmarkSites.axis(e)
	var across := Vector2(-axis.y, axis.x)
	for p in [Vector2(24, 2), Vector2(101, 3), Vector2(130, -100), Vector2(220, 0)]:
		var world_p: Vector2 = axis * p.x + across * p.y
		var h := LandmarkSfAlcatraz.ground_height(p)
		_check(h >= 3.0, "cellhouse, lighthouse, dock and parade ground must be dry")
		_check(absf(g.asl_y(LandmarkTerrain.ground_y(d, g, world_p)) - h) < 0.01,
			"island ground must respect registry rotation")
	_check(LandmarkSfAlcatraz.ground_height(Vector2(0, 200)) < 0.0, "open sea stays outside the rock")
	_check(absf(LandmarkSfAlcatraz.ground_height(Vector2(115.2, -68.5)) - 14.0) < 0.1,
		"Building 64 stands on its lower terrace, not on the summit")
	_check(LandmarkSfAlcatraz.ground_height(Vector2(38.3, -84.8)) < 11.0,
		"gatehouse stays near the dock instead of becoming a tall concrete plinth")
	var near := TerrainBuilder._terrain_mesh(d, g)
	var a := near.mesh.surface_get_arrays(0)
	_check((a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() < 48 * 48 * 6, "near DEM must yield to the island")
	_check(not _covers(a, Vector2.ZERO), "near terrain must not cover the cellhouse")
	near.free()
	# A coarse triangle can enclose the entire island with all vertices
	# outside it. This was the distant green lump hiding its buildings.
	var verts := PackedVector3Array([Vector3(-800, 80, -800), Vector3(800, 80, -800), Vector3(0, 80, 1000),
		Vector3(2000, 80, 2000), Vector3(2100, 80, 2000), Vector3(2000, 80, 2100)])
	var cut := LandmarkTerrain.cut_indices(d, verts, PackedInt32Array([0, 1, 2, 3, 4, 5]))
	_check(cut == PackedInt32Array([3, 4, 5]), "cut crossing triangles but preserve unrelated land")
	# Alcatraz must also clear its drape when it is a secondary landmark
	# viewed from San Francisco, not just on a visit to the island.
	d.landmark_type = "none"
	d.landmark_candidates = [{"type": "alcatraz", "x": 3000.0, "z": 0.0, "yaw_deg": 35.0, "base": "sea"}]
	for i in verts.size():
		verts[i].x += 3000.0
	_check(LandmarkTerrain.cut_indices(d, verts, PackedInt32Array([0, 1, 2])).is_empty(),
		"secondary island must clear distant terrain")
	var water := WaterBuilder.build_water(d, g)
	_check(water.has_node("IslandSea"), "distant terrain opening must contain ocean")
	water.free()
	d.landmark_candidates = []
	_check(LandmarkTerrain.cut_indices(d, verts, PackedInt32Array([0, 1, 2])).size() == 3,
		"worlds without the island keep their terrain")
	if failures.is_empty():
		print("ALCATRAZ OK: sea datum, dry arrival, authored ground, near/far DEM clearance, buildings, %d triangles" % tris)
		quit(0)
	else:
		for f in failures:
			printerr("ALCATRAZ FAIL: ", f)
		quit(1)

func _covers(arrays: Array, p: Vector2) -> bool:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in range(0, idx.size(), 3):
		var a := verts[idx[i]]
		var b := verts[idx[i + 1]]
		var c := verts[idx[i + 2]]
		if Geometry2D.is_point_in_polygon(p, PackedVector2Array([Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)])):
			return true
	return false

func _roof_at(hero: Node3D, p: Vector2) -> float:
	var y := -INF
	for part in LandmarkBuilder.parts(hero):
		var a := part.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		for i in range(0, verts.size(), 3):
			var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3(p.x, 100.0, p.y), Vector3.DOWN,
				verts[i], verts[i + 1], verts[i + 2])
			if hit is Vector3:
				y = maxf(y, (hit as Vector3).y)
	return y
