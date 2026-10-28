extends SceneTree

## Headless scenery test: godot --headless --script tests/scenery_test.gd
## Guards the visual-scale contract: real building proportions (metres x
## 0.25, not x 0.6 slabs), computed terrain normals, water carving from
## land polygons, and a multi-part Eiffel landmark.

func _init() -> void:
	_run()

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

	# Building height scale: 20 m should become 5 world units, not 12.
	var data := _flat_data()
	data.buildings = [{"x": 0.0, "z": 0.0, "size_x": 10.0, "size_z": 8.0, "height": 20.0, "name": "t"}]
	var world := TerrainBuilder.build_world(data)
	var wall_heights: Array[float] = []
	for child in world.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			wall_heights.append((child as MeshInstance3D).scale.y)
	if not wall_heights.has(5.0):
		failures.append("20m building should be 5 world units tall, got %s" % str(wall_heights))
	# Buildings sit on the processed ground (flat 3.0, sunk 0.6), never float.
	for child in world.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh \
				and absf((child as MeshInstance3D).scale.y - 5.0) < 0.01:
			var base := (child as MeshInstance3D).position.y - 2.5
			if absf(base - 2.4) > 0.01:
				failures.append("building base should be at 2.4 on flat ground, got %f" % base)
	world.free()

	# Terrain normals must follow the slope, not all point up.
	var slope := _flat_data()
	for z in 8:
		for x in 8:
			slope.heights[z * 8 + x] = float(x) * 6.0
	var sm := TerrainBuilder._terrain_mesh(slope)
	var normals: PackedVector3Array = sm.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var tilted := false
	for n in normals:
		if absf(n.x) > 0.05:
			tilted = true
	if not tilted:
		failures.append("sloped terrain should have tilted normals")
	sm.free()

	# Water polygons carve the terrain down to the water plane.
	var river := _flat_data()
	river.land_polygons = [{"class": "water", "points": PackedVector2Array(
		[Vector2(-200, -200), Vector2(200, -200), Vector2(200, 200), Vector2(-200, 200)])}]
	var rm := TerrainBuilder._terrain_mesh(river)
	var verts: PackedVector3Array = rm.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var carved := true
	for v in verts:
		if v.y > river.water_level + 0.4:
			carved = false
	if not carved:
		failures.append("water polygon should carve terrain to water level")
	rm.free()

	# Far terrain: real-DEM backdrop mesh exists, spans its extent, and
	# is buried near the viewpoint so it never pokes through the
	# detailed terrain, while distant relief is boosted upward.
	var far := _flat_data()
	far.far_grid_size = 16
	far.far_extent = 9000.0
	far.far_heights.resize(16 * 16)
	for z in 16:
		for x in 16:
			far.far_heights[z * 16 + x] = 3.0 + float(x) * 2.0
	var fm := TerrainBuilder._far_terrain(far)
	if fm.mesh == null or fm.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() != 16 * 16:
		failures.append("far terrain should build a 16x16 mesh")
	else:
		var fv: PackedVector3Array = fm.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		# Corner (far away, high raw height) must end up higher than a
		# near-centre vertex with the same raw profile would suggest:
		# boost grows with distance, bury shrinks it.
		if fv[15 * 16 + 15].y <= fv[8 * 16 + 8].y:
			failures.append("far terrain relief should rise with distance (corner %f vs centre %f)" % [fv[15 * 16 + 15].y, fv[8 * 16 + 8].y])
	fm.free()
	var nofar := TerrainBuilder._far_terrain(_flat_data())
	if nofar.mesh != null:
		failures.append("without far data there should be no far mesh")
	nofar.free()

	# Eiffel landmark is a multi-part structure, not one cylinder.
	var paris := _flat_data()
	paris.landmark_type = "eiffel"
	var lm := TerrainBuilder._landmark(paris)
	if lm.get_child_count() < 10:
		failures.append("eiffel landmark should have >=10 parts, got %d" % lm.get_child_count())
	lm.free()

	# Tokyo Tower gets its own multi-part landmark at its real site.
	if LocationData.landmark_for(35.6586, 139.7454, "Tokyo, Japan") != "tokyo":
		failures.append("Tokyo Tower site should map to the tokyo landmark")
	var tokyo := _flat_data()
	tokyo.landmark_type = "tokyo"
	var tm := TerrainBuilder._landmark(tokyo)
	if tm.get_child_count() < 10:
		failures.append("tokyo landmark should have >=10 parts, got %d" % tm.get_child_count())
	tm.free()

	# Satellite drape: terrain carries UVs into the mosaic, and the
	# viewpoint vertex lands at the mosaic centre.
	var sat := _flat_data()
	sat.grid_size = 8
	sat.heights.resize(64)
	for i in 64:
		sat.heights[i] = 3.0
	sat.latitude = 48.8566
	sat.longitude = 2.3522
	var sat_img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	sat.satellite_texture = ImageTexture.create_from_image(sat_img)
	sat.satellite_zoom = 16
	sat.satellite_origin_px = TileFetcher.global_pixel(48.8566, 2.3522, 16) - Vector2(384, 384)
	var smat := TerrainBuilder._terrain_mesh(sat)
	var sat_uvs: PackedVector2Array = smat.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	if sat_uvs.size() != 64:
		failures.append("satellite terrain should carry 64 UVs, got %d" % sat_uvs.size())
	else:
		var centre_uv := sat_uvs[4 * 8 + 4]
		if centre_uv.distance_to(Vector2(0.5, 0.5)) > 0.05:
			failures.append("viewpoint UV should sit at mosaic centre, got %s" % str(centre_uv))
	smat.free()
	if SatelliteFetcher.mosaic_tiles(48.8566, 2.3522, 16).size() != 9:
		failures.append("satellite mosaic should request 9 tiles")

	# Per-building roof extraction: a terracotta mosaic gives a
	# terracotta roof colour back for a footprint at its centre.
	var roof_data := _flat_data()
	roof_data.latitude = 48.8566
	roof_data.longitude = 2.3522
	var roof_img := Image.create(768, 768, false, Image.FORMAT_RGB8)
	roof_img.fill(Color(0.72, 0.30, 0.18))
	roof_data.satellite_image = roof_img
	roof_data.satellite_origin_px = TileFetcher.global_pixel(48.8566, 2.3522, 16) - Vector2(384, 384)
	var sampled := TerrainBuilder.sampled_roof_color(roof_data, 0.0, 0.0, 8.0, 8.0)
	if absf(sampled.r - 0.72) > 0.05 or absf(sampled.g - 0.30) > 0.05 \
			or absf(sampled.b - 0.18) > 0.05:
		failures.append("roof colour should sample the mosaic, got %s" % str(sampled))
	if TerrainBuilder.sampled_roof_color(_flat_data(), 0.0, 0.0, 8.0, 8.0).a != 0.0:
		failures.append("no imagery should report alpha 0 (slate fallback)")
	# Foliage cards: alpha texture has transparent and opaque texels.
	var card_tex := TerrainBuilder._leaf_card_texture()
	var card_img := card_tex.get_image()
	if card_img.get_pixel(0, 0).a != 0.0 or card_img.get_pixel(128, 128).a == 0.0:
		failures.append("leaf card texture should mix transparent and leaf texels")

	# Any-place landmarks: an OSM candidate renders as its archetype
	# model in the world, at its true position.
	var cand := _flat_data()
	cand.buildings = [{"x": 20.0, "z": -10.0, "size_x": 10.0, "size_z": 8.0,
		"height": 12.0, "name": "c", "roof_shape": ""}]
	cand.landmark_candidates = [{"x": 20.0, "z": -10.0, "archetype": "lighthouse",
		"name": "L", "height": 30.0, "size_x": 8.0, "size_z": 8.0}]
	var cworld := TerrainBuilder.build_world(cand)
	var found_light := false
	for child in cworld.get_children():
		if str(child.name).begins_with("Landmark_lighthouse"):
			found_light = true
	if not found_light:
		failures.append("landmark candidate should render its archetype in the world")
	cworld.free()
	var church := LandmarkBuilder.build_archetype("church", 40.0, Vector2(24, 18))
	if church.get_child_count() < 4:
		failures.append("church archetype should be multi-part, got %d" % church.get_child_count())
	church.free()

	# Seasons recolour the canopy: autumn warm, summer green.
	var autumn_leaf := TerrainBuilder._leaves(LocationData.Season.AUTUMN)[0] as StandardMaterial3D
	if autumn_leaf.albedo_color.r <= autumn_leaf.albedo_color.g:
		failures.append("autumn leaves should be warm (r>g), got %s" % str(autumn_leaf.albedo_color))
	var summer_leaf := TerrainBuilder._leaves(LocationData.Season.SUMMER)[0] as StandardMaterial3D
	if summer_leaf.albedo_color.g <= summer_leaf.albedo_color.r:
		failures.append("summer leaves should be green (g>r), got %s" % str(summer_leaf.albedo_color))

	if failures.is_empty():
		print("SCENERY OK: building scale, terrain normals, water carve, landmark parts")
		quit(0)
	else:
		for f in failures:
			printerr("SCENERY FAIL: ", f)
		quit(1)
