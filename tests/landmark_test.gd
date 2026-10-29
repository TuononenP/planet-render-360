extends SceneTree

## Landmark test: godot --headless --script tests/landmark_test.gd
## Offline. Guards the on-the-fly landmark contract:
## 1) searched names and city centres resolve to the right landmark,
## 2) every registry type builds a merged, textured, true-metre model
##    at its real height (Eiffel lattice per PRD AC-06),
## 3) OSM archetypes are textured, merged and regional,
## 4) models stand at the site's true bearing, clamped into the
##    terrain, and 5) the landmark's generic OSM box is suppressed.

## Initial great-circle bearing (degrees from north, clockwise).
static func _geodesic_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var p1 := deg_to_rad(lat1)
	var p2 := deg_to_rad(lat2)
	var dl := deg_to_rad(lon2 - lon1)
	var y := sin(dl) * cos(p2)
	var x := cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl)
	return fposmod(rad_to_deg(atan2(y, x)), 360.0)

func _flat_data() -> LocationData:
	var data := LocationData.new()
	data.grid_size = 8
	data.heights.resize(64)
	for i in 64:
		data.heights[i] = 3.0
	data.water_level = -3.0
	data.seed_value = 42
	return data

func _run() -> void:
	var failures: Array[String] = []

	# --- 1) Detection: by searched name, and by city centre ---
	var by_name := {
		"Turun tuomiokirkko, 1": "turku_cathedral",
		"Eiffel Tower": "eiffel",
		"Big Ben": "big_ben",
		"Colosseum": "colosseum",
		"Statue of Liberty": "statue_liberty",
		"Sydney Opera House": "sydney_opera",
	}
	for name in by_name:
		if LocationData.landmark_for(0.0, 0.0, name) != by_name[name]:
			failures.append("name '%s' should give %s" % [name, by_name[name]])
	var by_place := {
		Vector2(48.8566, 2.3522): "eiffel",       # Paris centre
		Vector2(60.4518, 22.2666): "turku_cathedral",  # Turku centre
		Vector2(60.1699, 24.9384): "helsinki_cathedral",
		Vector2(51.5074, -0.1278): "big_ben",     # London centre
		Vector2(41.9028, 12.4964): "colosseum",   # Rome centre
		Vector2(41.3874, 2.1686): "sagrada",      # Barcelona centre
		Vector2(30.0444, 31.2357): "pyramid",     # Cairo centre
		Vector2(40.7128, -74.0060): "statue_liberty",  # New York centre
		Vector2(-33.8688, 151.2093): "sydney_opera",
		Vector2(35.6762, 139.6503): "tokyo",      # Tokyo centre
	}
	for coords in by_place:
		var got := LocationData.landmark_for(coords.x, coords.y, "")
		if got != by_place[coords]:
			failures.append("place %s should give %s, got %s" % [coords, by_place[coords], got])
	if LocationData.landmark_for(51.1789, -115.5708, "Banff, Canada") != "none":
		failures.append("Banff should have no landmark")

	# --- 2) Every registry type builds a merged, textured, true-metre
	# model (T5.3): parts live under a "Model" node whose one uniform
	# scale is WorldScale.metres_to_units(); geometry is merged per
	# material (few draw calls) and every surface carries a
	# photographic albedo texture — never a flat colour.
	var heights := {"eiffel": 330.0, "tokyo": 332.9, "big_ben": 96.0,
		"colosseum": 48.0, "sagrada": 172.5, "pyramid": 138.5,
		"statue_liberty": 93.0, "sydney_opera": 67.0,
		"turku_cathedral": 86.0, "helsinki_cathedral": 62.0}
	for entry in LocationData.landmarks():
		var type := str(entry["type"])
		var model := LandmarkBuilder.build(type)
		_check_model(failures, type, model, float(heights.get(type, 0.0)))
		model.free()

	# --- 2b) Eiffel (PRD AC-06): open lattice of merged members — four
	# piers, arches, decks — tens of thousands of triangles in <= 12
	# draw calls, 125 m base, matte bronze-brown paint.
	var eiffel := LandmarkBuilder.build("eiffel")
	var e_parts := LandmarkBuilder.parts(eiffel)
	var names: Array = e_parts.map(func(m: MeshInstance3D) -> String: return str(m.name))
	for want in ["PierN", "PierE", "PierS", "PierW", "Arches", "Decks"]:
		if not names.has(want):
			failures.append("eiffel should have a %s part, got %s" % [want, names])
	var tris := 0
	for m in e_parts:
		tris += m.mesh.surface_get_array_len(0) / 3
	if tris < 15000 or e_parts.size() > 12:
		failures.append("eiffel lattice should be >=15k tris in <=12 parts, got %d in %d" % [tris, e_parts.size()])
	var pier := e_parts[names.find("PierS")]
	var span := pier.mesh.get_aabb().size
	if absf(maxf(span.x, span.z) - 62.5) > 3.0:
		failures.append("eiffel pier should reach the 62.5 m half-base, spans %s" % span)
	var iron := pier.mesh.surface_get_material(0) as StandardMaterial3D
	if iron.roughness < 0.5 or iron.metallic > 0.5:
		failures.append("eiffel paint should be matte (rough>=0.5, metal<=0.5)")
	eiffel.free()

	# --- 3) OSM archetypes: textured, multi-part, regional, and sized
	# from metres (height clamp 20–184 m).
	for arch in ["church", "cathedral", "castle", "lighthouse", "stadium",
			"mosque", "temple", "windmill", "tower"]:
		var a := LandmarkBuilder.build_archetype(arch, 60.0,
			Vector2(30, 40) * WorldScale.metres_to_units(), "nordic")
		_check_model(failures, "archetype " + arch, a, 0.0)
		a.free()
	var onion := LandmarkBuilder.build_archetype("church", 50.0, Vector2(16, 24), "eastern_europe")
	if not LandmarkBuilder.parts(onion).any(func(m: MeshInstance3D) -> bool:
			return str(m.name) == "Gilt"):
		failures.append("eastern-European church should carry gilded onion domes")
	onion.free()

	# --- 4) Placement (T5.2): the TRUE metre site — no clamp, no
	# rescale; View360 frames it by camera spawn + look. Scorecard (e):
	# bearing error ≤1° against the geodesic bearing, from the Paris
	# centre (Eiffel 4.2 km away) and from a viewpoint on the tower
	# (camera steps back FRAME_READ_M, the model never moves).
	var at_site := _flat_data()
	at_site.latitude = 60.4524
	at_site.longitude = 22.2781
	at_site.landmark_type = "turku_cathedral"
	at_site.has_landmark_site = true
	at_site.landmark_lat = 60.4524
	at_site.landmark_lon = 22.2781
	var pos_at := TerrainBuilder.landmark_world_pos(at_site)
	if pos_at.length() > 0.01:
		failures.append("a landmark at the viewpoint stays at its site (0), got %s" % str(pos_at))
	var cam_at := View360.spawn_xz(at_site)
	if absf(cam_at.distance_to(pos_at) - View360.FRAME_READ_M) > 0.5:
		failures.append("spawn should step back %.0f m from an on-site landmark, got %f"
			% [View360.FRAME_READ_M, cam_at.distance_to(pos_at)])
	for vp in [[48.8566, 2.3522, "Paris centre"], [48.8584, 2.2945, "Eiffel viewpoint"]]:
		var paris := _flat_data()
		paris.latitude = vp[0]
		paris.longitude = vp[1]
		paris.landmark_type = "eiffel"
		paris.has_landmark_site = true
		paris.landmark_lat = 48.85826
		paris.landmark_lon = 2.29450
		var site := TerrainBuilder.landmark_world_pos(paris)
		var cam := View360.spawn_xz(paris)
		var cam_ll := WorldScale.latlon_from_xz(cam.x, cam.y, paris.latitude, paris.longitude)
		var d := site - cam
		var model_brg := fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)
		var true_brg := _geodesic_bearing(cam_ll.x, cam_ll.y, 48.85826, 2.29450)
		var err := absf(wrapf(model_brg - true_brg, -180.0, 180.0))
		print("SCORECARD (e) %s: model bearing %.2f°, geodesic %.2f°, error %.3f°, distance %.0f m"
			% [vp[2], model_brg, true_brg, err, d.length()])
		if err > 1.0:
			failures.append("%s: Eiffel bearing error %.3f° > 1°" % [vp[2], err])
		# The spawn look faces the model (yaw 0 = north, CameraRig).
		var yaw := View360.landmark_yaw(paris, cam)
		var fwd := Vector2(-sin(yaw), -cos(yaw))
		if fwd.angle_to(d.normalized()) > deg_to_rad(0.5):
			failures.append("%s: spawn look should face the landmark" % vp[2])

	# --- 5) The cathedral's generic OSM box must not duplicate it ---
	var dup := _flat_data()
	dup.latitude = 60.4524
	dup.longitude = 22.2781
	dup.landmark_type = "turku_cathedral"
	dup.has_landmark_site = true
	dup.landmark_lat = 60.4524
	dup.landmark_lon = 22.2781
	dup.buildings = [{"x": 0.0, "z": 0.0, "size_x": 10.0, "size_z": 8.0, "height": 20.0, "name": "Turun tuomiokirkko"}]
	var world := TerrainBuilder.build_world(dup)
	var has_landmark := false
	for child in world.get_children():
		if child.name.begins_with("Landmark_"):
			has_landmark = true
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			var p := (child as MeshInstance3D).position
			if absf(p.x) < 1.0 and absf(p.z) < 1.0:
				failures.append("generic OSM box at the cathedral site should be suppressed")
	if not has_landmark:
		failures.append("build_world should add the Landmark_ node")
	world.free()

	if failures.is_empty():
		print("LANDMARK OK: registry detection, true-metre textured models, archetypes, true-bearing placement, OSM suppression")
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK FAIL: ", f)
		quit(1)

## True-metre, merged, textured model of the expected height (0 = any).
func _check_model(failures: Array[String], label: String, root: Node3D, height_m: float) -> void:
	var model := root.get_node_or_null("Model") as Node3D
	if model == null or not model.scale.is_equal_approx(Vector3.ONE * WorldScale.metres_to_units()):
		failures.append("%s should build under a Model node scaled metres_to_units" % label)
		return
	var parts := LandmarkBuilder.parts(root)
	if parts.size() < 2 or parts.size() > 16:
		failures.append("%s should be 2..16 merged parts, got %d" % [label, parts.size()])
	var top := 0.0
	for m in parts:
		var mat := m.mesh.surface_get_material(0) as StandardMaterial3D
		if mat == null or mat.albedo_texture == null:
			failures.append("%s part %s should use a textured PBR material" % [label, m.name])
		top = maxf(top, (m.transform * m.mesh.get_aabb()).end.y)
	if height_m > 0.0 and absf(top - height_m) > maxf(2.0, height_m * 0.03):
		failures.append("%s should stand %.1f m tall, got %.1f m" % [label, height_m, top])

func _init() -> void:
	_run()
