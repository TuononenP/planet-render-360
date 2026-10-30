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

	# Building height scale: 20 m is 20 units since the T7.0 metre
	# cutover (v1: 5 units on the 4 m-unit world).
	var m2u_t := WorldScale.metres_to_units()
	var data := _flat_data()
	data.buildings = [{"x": 0.0, "z": 0.0, "size_x": 10.0, "size_z": 8.0, "height": 20.0, "name": "t"}]
	var world := TerrainBuilder.build_world(data)
	var yr := _rect_mass_yrange(world, Vector2.ZERO, Vector2(10, 8))
	# 20 m stand above the ground; the walls also sink 0.6 below it.
	if absf(yr.y - yr.x - (20.0 + 0.6) * m2u_t) > 0.01:
		failures.append("20m building should stand 20 world units above its ground, got %s" % str(yr))
	# Buildings sit on the processed ground (flat 3.0, sunk 0.6), never float.
	elif absf(yr.x - 2.4) > 0.01:
		failures.append("building base should be at 2.4 on flat ground, got %f" % yr.x)
	world.free()

	# Terrain normals must follow the slope, not all point up.
	var slope := _flat_data()
	for z in 8:
		for x in 8:
			# 60 m per 343 m post on the 2400 m extent (slope ≈ 0.17).
			slope.heights[z * 8 + x] = float(x) * 60.0
	var sm := TerrainBuilder._terrain_mesh(slope)
	var normals: PackedVector3Array = sm.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var tilted := false
	for n in normals:
		if absf(n.x) > 0.05:
			tilted = true
	if not tilted:
		failures.append("sloped terrain should have tilted normals")
	sm.free()

	# Water polygons carve the terrain below their OWN bank-levelled
	# surface (T7.0 step 0: never down to the global datum — v1 dug
	# ~190 m trenches at Interlaken).
	var river := _flat_data()
	river.land_polygons = [{"class": "water", "points": PackedVector2Array(
		[Vector2(-500, -500), Vector2(500, -500), Vector2(500, 500), Vector2(-500, 500)])}]
	var rground := GroundTruth.new(river)
	var rm := TerrainBuilder._terrain_mesh(river, rground)
	var verts: PackedVector3Array = rm.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var carved := 0
	for v in verts:
		if absf(v.x) < 500.0 and absf(v.z) < 500.0:
			var lvl := rground.water_level_at(v.x, v.z)
			if v.y > lvl - 1.0 or v.y < lvl - GroundTruth.CARVE_DEPTH_M - 0.01:
				failures.append("water polygon post %s should sit %.1f m under its surface %.2f, got %.2f"
					% [str(Vector2(v.x, v.z)), GroundTruth.CARVE_DEPTH_M, lvl, v.y])
				break
			carved += 1
	if carved == 0:
		failures.append("water polygon should carve terrain posts")
	if absf(rground.water_level_at(0.0, 0.0) - (3.0 - GroundTruth.FREEBOARD_M)) > 0.01:
		failures.append("water surface should sit a freeboard under its 3.0 banks, got %f"
			% rground.water_level_at(0.0, 0.0))
	if rground.water_at(0.0, 0.0) < 1.0 or rground.water_at(900.0, 900.0) > 0.0:
		failures.append("carved polygon should hold water, its banks stay dry")
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
	if LandmarkBuilder.parts(lm).size() < 10:
		failures.append("eiffel landmark should have >=10 parts, got %d" % LandmarkBuilder.parts(lm).size())
	lm.free()

	# Tokyo Tower gets its own multi-part landmark at its real site.
	if LocationData.landmark_for(35.6586, 139.7454, "Tokyo, Japan") != "tokyo":
		failures.append("Tokyo Tower site should map to the tokyo landmark")
	var tokyo := _flat_data()
	tokyo.landmark_type = "tokyo"
	var tm := TerrainBuilder._landmark(tokyo)
	if LandmarkBuilder.parts(tm).size() < 10:
		failures.append("tokyo landmark should have >=10 parts, got %d" % LandmarkBuilder.parts(tm).size())
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
	if LandmarkBuilder.parts(church).size() < 4:
		failures.append("church archetype should be multi-part, got %d" % LandmarkBuilder.parts(church).size())
	church.free()

	# Seasons recolour the canopy: autumn warm, summer green.
	var autumn_leaf := TerrainBuilder._leaves(LocationData.Season.AUTUMN)[0] as StandardMaterial3D
	if autumn_leaf.albedo_color.r <= autumn_leaf.albedo_color.g:
		failures.append("autumn leaves should be warm (r>g), got %s" % str(autumn_leaf.albedo_color))
	var summer_leaf := TerrainBuilder._leaves(LocationData.Season.SUMMER)[0] as StandardMaterial3D
	if summer_leaf.albedo_color.g <= summer_leaf.albedo_color.r:
		failures.append("summer leaves should be green (g>r), got %s" % str(summer_leaf.albedo_color))

	# GroundTruth probe (T1.4): building/tree/terrain/road heights at
	# the same XZ agree within 0.05 m at 50 sampled points per
	# location, samplers behave, and no builder reads raw heights.
	var g0 := failures.size()
	_probe_ground(failures, "city", _probe_data(false))
	_probe_ground(failures, "hills", _probe_data(true))
	_probe_grep_gate(failures)
	if failures.size() == g0:
		print("GROUNDTRUTH OK: 50-point height agreement + samplers + builder grep gate (city, hills)")

	# T4.1 footprint probe: real OSM rings extrude as drawn (rotation,
	# concave shapes, both windings), corrupt rings fall back to AABB.
	var f0 := failures.size()
	_probe_footprints(failures)
	if failures.size() == f0:
		print("FOOTPRINTS OK: rotation + L-shape + windings + AABB fallback")

	# v2 attributed roads (§2.5, pipeline closure W2): dicts build
	# ribbons at width_m, tunnels are skipped, v1 bare centrelines
	# still work.
	var r0 := failures.size()
	_probe_roads(failures)
	if failures.size() == r0:
		print("ROADS OK: v2 dicts + tunnel skip + v1 compat")

	if failures.is_empty():
		print("SCENERY OK: building scale, terrain normals, water carve, landmark parts")
		quit(0)
	else:
		for f in failures:
			printerr("SCENERY FAIL: ", f)
		quit(1)

# --- T1.4 GroundTruth probe (appended; existing checks above untouched) ---

func _probe_data(hilly: bool) -> LocationData:
	var data := LocationData.new()
	data.grid_size = 32
	data.heights.resize(32 * 32)
	for z in 32:
		for x in 32:
			var h := 3.0
			if hilly:
				h += 14.0 * sin(float(x) * 0.22) * cos(float(z) * 0.19) \
					+ 0.05 * (float(x) - 16.0)
			else:
				h += 1.5 * sin(float(x) * 0.35) * cos(float(z) * 0.3) \
					+ 0.02 * (float(x) - 16.0)
			data.heights[z * 32 + x] = h
	data.water_level = -3.0
	data.relief_metres = 800.0 if hilly else 60.0
	data.seed_value = 43 if hilly else 42
	if hilly:
		# No water polygon: the synthetic river runs (carve + quays).
		data.land_polygons = [
			{"class": "forest", "points": PackedVector2Array(
				[Vector2(0, 40), Vector2(60, 40), Vector2(60, 90), Vector2(0, 90)])},
			{"class": "grass", "points": PackedVector2Array(
				[Vector2(-90, -90), Vector2(-40, -90), Vector2(-40, -40), Vector2(-90, -40)])},
		]
		data.buildings = [
			{"x": 20.0, "z": 20.0, "size_x": 10.0, "size_z": 8.0, "height": 20.0},
			{"x": -30.0, "z": 30.0, "size_x": 8.0, "size_z": 8.0, "height": 12.0},
			{"x": 50.0, "z": -40.0, "size_x": 6.0, "size_z": 6.0, "height": 10.0},
			{"x": -50.0, "z": -50.0, "size_x": 12.0, "size_z": 10.0, "height": 14.0},
		]
		data.roads = [PackedVector2Array(
			[Vector2(-90, 60), Vector2(-45, 60), Vector2(0, 60), Vector2(45, 60), Vector2(90, 60)])]
	else:
		data.land_polygons = [
			{"class": "water", "points": PackedVector2Array(
				[Vector2(-70, -70), Vector2(-20, -70), Vector2(-20, -20), Vector2(-70, -20)])},
			{"class": "forest", "points": PackedVector2Array(
				[Vector2(20, 20), Vector2(70, 20), Vector2(70, 70), Vector2(20, 70)])},
			{"class": "grass", "points": PackedVector2Array(
				[Vector2(-70, 20), Vector2(-20, 20), Vector2(-20, 70), Vector2(-70, 70)])},
		]
		data.buildings = [
			{"x": 0.0, "z": 0.0, "size_x": 10.0, "size_z": 8.0, "height": 20.0},
			{"x": 30.0, "z": -30.0, "size_x": 8.0, "size_z": 8.0, "height": 12.0},
			{"x": 55.0, "z": 10.0, "size_x": 6.0, "size_z": 6.0, "height": 30.0},
			{"x": -10.0, "z": 60.0, "size_x": 12.0, "size_z": 10.0, "height": 8.0},
			{"x": -60.0, "z": -5.0, "size_x": 8.0, "size_z": 12.0, "height": 16.0},
			{"x": 70.0, "z": -60.0, "size_x": 10.0, "size_z": 10.0, "height": 25.0},
		]
		var line := PackedVector2Array()
		for i in 11:
			line.append(Vector2(-100.0 + float(i) * 20.0, -45.0))
		data.roads = [line, PackedVector2Array(
			[Vector2(45, -100), Vector2(45, 0), Vector2(45, 100)])]
	_scale_fixture(data, K)
	return data

## The probe fixtures were authored on the v1 220-unit extent; K keeps
## their layout relative to the (now 2400 m) extent and its posts.
const K := 2400.0 / 220.0

static func _scale_fixture(data: LocationData, k: float) -> void:
	for poly in data.land_polygons:
		var pts: PackedVector2Array = poly["points"]
		for i in pts.size():
			pts[i] *= k
		poly["points"] = pts
	for b in data.buildings:
		for key in ["x", "z", "size_x", "size_z"]:
			b[key] = float(b[key]) * k
	for i in data.roads.size():
		var line: PackedVector2Array = data.roads[i]
		for j in line.size():
			line[j] *= k
		data.roads[i] = line

## Agreement probe: every layer samples the same surface, so placed
## geometry agrees with GroundTruth within 0.05 m at 50 terrain points
## plus every authored building, tree trunk, and road segment.
func _probe_ground(failures: Array[String], label: String, data: LocationData) -> void:
	var ground := GroundTruth.new(data)
	var world := TerrainBuilder.build_world(data, ground)
	# Terrain mesh: the only 32x32 ArrayMesh (far mesh is empty here).
	var terrain: MeshInstance3D = null
	for child in world.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is ArrayMesh:
			var n: int = (child as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
			if n == data.grid_size * data.grid_size:
				terrain = child
	if terrain == null:
		failures.append("%s: terrain mesh missing from the world" % label)
		world.free()
		return
	var verts: PackedVector3Array = terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var worst := 0.0
	for i in 50:
		var v: Vector3 = verts[(i * 37 + 11) % verts.size()]
		worst = maxf(worst, absf(v.y - ground.height_at_world(v.x, v.z)))
	if worst > 0.05:
		failures.append("%s: terrain vs ground disagree by %f (bar 0.05)" % [label, worst])
	# Authored (footprint-less) buildings extrude as their AABB
	# rectangle, based at the lowest ground under it − 0.6.
	for b in data.buildings:
		var xz := Vector2(float(b["x"]), float(b["z"]))
		var ehw := clampf(float(b["height"]) * WorldScale.metres_to_units(), 7.2, 76.0)
		var size := Vector2(float(b["size_x"]), float(b["size_z"]))
		var yr := _rect_mass_yrange(world, xz, size)
		if yr.x == INF:
			failures.append("%s: authored building at %s not placed" % [label, str(xz)])
			continue
		var want := _rect_base(ground, xz, size)
		if absf(yr.x - want) > 0.05 or absf(yr.y - yr.x - ehw - 0.6) > 0.05:
			failures.append("%s: building at %s spans %s, want base %f height %f + 0.6 sink"
				% [label, str(xz), str(yr), want, ehw])
	# Tree trunks (T5.1): instanced species, one MultiMesh per
	# species/LOD/sector; every instance origin is the trunk base on
	# the ground (the mesh's root flare sinks below it).
	var trees := 0
	for child in world.get_children():
		if child is MultiMeshInstance3D and str(child.name).begins_with("VegTrees"):
			var origins: PackedVector3Array = child.get_meta("origins", PackedVector3Array())
			for p in origins:
				trees += 1
				if absf(p.y - ground.height_at_world(p.x, p.z)) > 0.05:
					failures.append("%s: tree at %s off ground by %f"
						% [label, str(Vector2(p.x, p.z)),
							absf(p.y - ground.height_at_world(p.x, p.z))])
	if trees == 0:
		failures.append("%s: no tree trunks found in the world" % label)
	# Roads (T4.4): draped ribbons merged per finish. Every vertex lies on
	# the drawn terrain — never below GroundTruth's bilinear surface, and
	# within the 0.05 m lift plus the terrain mesh's own crease (the mesh
	# triangle can sit above the bilinear sample on curved ground) — and
	# no non-bridge ribbon lays shards on water.
	var ribbons := 0
	var m2u := WorldScale.metres_to_units()
	for child in world.get_children():
		var mi := child as MeshInstance3D
		if mi == null or not str(mi.name).begins_with("Road_"):
			continue
		ribbons += 1
		var rv: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for v in rv:
			var off := v.y - ground.height_at_world(v.x, v.z)
			var lift := v.y - RoadBuilder.surface_height(data, ground, v.x, v.z)
			if off < -0.001 or lift > 0.05 * m2u + 0.0005:
				failures.append("%s: road vertex at %s off ground by %f"
					% [label, str(Vector2(v.x, v.z)), off])
				break
			if ground.water_at(v.x, v.z) > 0.0 and off < 0.5:
				failures.append("%s: road ribbon on water at %s" % [label, str(Vector2(v.x, v.z))])
				break
	if ribbons == 0:
		failures.append("%s: no road ribbons built" % label)
	_probe_samplers(failures, label, data, ground)
	world.free()

func _probe_samplers(failures: Array[String], label: String,
		data: LocationData, ground: GroundTruth) -> void:
	# Sampler contract: finite everywhere, clamped outside, honest extent.
	if not ground.is_inside(0.0, 0.0) or ground.is_inside(1500.0, 0.0):
		failures.append("%s: is_inside wrong at centre/edge" % label)
	var edge := ground.height_at_world(1500.0, 0.0)
	if is_nan(edge) or is_inf(edge):
		failures.append("%s: outside sample not finite" % label)
	elif absf(edge - ground.surface_at_post(data.grid_size - 1, data.grid_size / 2)) > 0.001:
		failures.append("%s: outside should clamp to the edge post" % label)
	var honest := WorldScale.detailed_extent_units() * 0.5 / WorldScale.metres_to_units()
	if absf(ground.extent_m - honest) > 0.0001:
		failures.append("%s: extent_m %f, honest %f" % [label, ground.extent_m, honest])
	var mn := INF
	for z in data.grid_size:
		for x in data.grid_size:
			mn = minf(mn, ground.surface_at_post(x, z))
	if absf(mn - ground.surface_min) > 0.0001:
		failures.append("%s: surface_min disagrees with the posts" % label)
	# Flat ground has zero slope everywhere; the hills do not.
	var flat := GroundTruth.new(_flat_data())
	if flat.slope_at(0.0, 0.0) != 0.0 or flat.slope_at(40.0, -30.0) != 0.0:
		failures.append("%s: flat slope should be exactly 0" % label)
	if flat.water_at(0.0, 0.0) != 0.0:
		failures.append("%s: flat dry land should read 0 depth" % label)
	var steep := 0.0
	for i in 20:
		var px := (-90.0 + float(i) * 9.0) * K
		steep = maxf(steep, ground.slope_at(px, -px * 0.5))
		if is_nan(steep) or is_inf(steep) or steep < 0.0:
			failures.append("%s: slope not a finite non-negative" % label)
			break
	# 14 m sine relief over 77 m posts on the 2400 m extent.
	if label == "hills" and steep < 0.02:
		failures.append("%s: hills should have slope, max %f" % [label, steep])
	if label == "city":
		if ground.water_at(-45.0 * K, -45.0 * K) < 0.5:
			failures.append("city: carved channel should hold water")
		if ground.water_at(0.0, 0.0) > 0.001:
			failures.append("city: dry land should read ~0 depth")
		if ground.land_class_at(45.0 * K, 45.0 * K) != "forest" \
				or ground.land_class_at(-45.0 * K, 45.0 * K) != "grass" \
				or ground.land_class_at(-45.0 * K, -45.0 * K) != "water" \
				or ground.land_class_at(0.0, 0.0) != "":
			failures.append("city: land_class_at misreads a polygon")
	else:
		if ground.land_class_at(30.0 * K, 65.0 * K) != "forest" \
				or ground.land_class_at(-65.0 * K, -65.0 * K) != "grass":
			failures.append("hills: land_class_at misreads a polygon")

## Grep gate (contract §8): outside comments, no builder file reads raw
## heights or the water global — GroundTruth constructs from them, the
## pipeline produces them, and that is the whole list.
func _probe_grep_gate(failures: Array[String]) -> void:
	var forbidden := ["data.heights", "display_heights", "data.height_at(",
		".height_at(", "data.water_level"]
	var allowed := {"ground_truth.gd": true, "pipeline.gd": true}
	var dir := DirAccess.open("res://scripts/generation")
	if dir == null:
		failures.append("grep gate: cannot open scripts/generation")
		return
	for f in dir.get_files():
		if not f.ends_with(".gd") or allowed.has(f):
			continue
		var fh := FileAccess.open("res://scripts/generation/" + f, FileAccess.READ)
		if fh == null:
			failures.append("grep gate: cannot read " + f)
			continue
		var ln := 0
		while not fh.eof_reached():
			ln += 1
			var code: String = fh.get_line().split("#", true, 1)[0]
			for pat in forbidden:
				if code.contains(pat):
					failures.append("grep gate: %s:%d reads %s" % [f, ln, pat])
	# No TerrainBuilder<->GroundTruth cycle: TerrainBuilder's signature
	# names GroundTruth, so GroundTruth must not name TerrainBuilder back —
	# the static cycle breaks compilation on the main-scene load order
	# (view_360 first) that the headless suite never exercises.
	var gt := FileAccess.open("res://scripts/generation/ground_truth.gd",
		FileAccess.READ)
	if gt == null:
		failures.append("grep gate: cannot read ground_truth.gd")
	else:
		var gln := 0
		while not gt.eof_reached():
			gln += 1
			var gcode: String = gt.get_line().split("#", true, 1)[0]
			if gcode.contains("TerrainBuilder"):
				failures.append(("grep gate: ground_truth.gd:%d names "
					+ "TerrainBuilder (cyclic dependency)") % gln)

# --- T4.1 true-footprint probe (appended; existing checks above untouched) ---

func _probe_footprints(failures: Array[String]) -> void:
	var data := _flat_data()
	# Diamond = square rotated 45° (CCW ring, area 32): an AABB
	# fallback would square it to 8x8 corners instead of these points.
	var diamond := PackedVector2Array([Vector2(4, 0), Vector2(0, 4),
		Vector2(-4, 0), Vector2(0, -4), Vector2(4, 0)])
	# Concave L (CW ring, area 48), closing duplicate included like OSM.
	var ell := PackedVector2Array([Vector2(26, -4), Vector2(26, 4),
		Vector2(30, 4), Vector2(30, 0), Vector2(34, 0), Vector2(34, -4),
		Vector2(26, -4)])
	data.buildings = [
		{"x": 0.0, "z": 0.0, "size_x": 8.0, "size_z": 8.0, "height": 20.0,
			"footprint": diamond},
		{"x": 30.0, "z": 0.0, "size_x": 8.0, "size_z": 8.0, "height": 12.0,
			"footprint": ell},
		{"x": 51.0, "z": 51.0, "size_x": 6.0, "size_z": 6.0, "height": 12.0,
			"footprint": PackedVector2Array([Vector2(50, 50), Vector2(52, 52)])},
		{"x": -40.0, "z": 0.0, "size_x": 10.0, "size_z": 8.0,
			"height": 20.0, "name": "v1"},
	]
	var ground := GroundTruth.new(data)
	var world := TerrainBuilder.build_world(data, ground)
	var base := 3.0 - 0.6
	var mu := WorldScale.metres_to_units()
	# Heights stand above the ground (3.0); the walls sink 0.6 below it.
	_check_extruded(failures, world, "diamond",
		PackedVector2Array([Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
			Vector2(0, -4)]), base, base + 0.6 + 20.0 * mu, 32.0)
	_check_extruded(failures, world, "L",
		PackedVector2Array([Vector2(26, -4), Vector2(26, 4), Vector2(30, 4),
			Vector2(30, 0), Vector2(34, 0), Vector2(34, -4)]),
		base, base + 0.6 + 12.0 * mu, 48.0)
	_check_fallback_box(failures, world, ground, Vector2(51, 51), Vector2(6, 6), 12.0 * mu)
	_check_fallback_box(failures, world, ground, Vector2(-40, 0), Vector2(10, 8), 20.0 * mu)
	_check_no_fallback_box(failures, world, Vector2(0, 0), 20.0 * mu)
	_check_no_fallback_box(failures, world, Vector2(30, 0), 12.0 * mu)
	world.free()

func _probe_roads(failures: Array[String]) -> void:
	var data := _flat_data()
	data.roads = [
		{"points": PackedVector2Array([Vector2(-10, 60), Vector2(10, 60)]),
			"width_m": 8.0, "lanes": 2, "surface": "", "bridge": false,
			"tunnel": false, "layer": 0, "class": "secondary"},
		{"points": PackedVector2Array([Vector2(-10, -60), Vector2(10, -60)]),
			"width_m": 6.0, "lanes": 0, "surface": "", "bridge": false,
			"tunnel": true, "layer": -1, "class": "secondary"},
		PackedVector2Array([Vector2(-10, 40), Vector2(10, 40)]),
	]
	# T4.4: ribbons merged per finish; check geometry by position — the
	# 8 m v2 road spans 8 units across (metres since T7.0), the v1 road
	# keeps its 6.8 m (v1 1.7-unit) ribbon, the tunnel builds nothing,
	# and every vertex lies flush on the (flat) ground: offset <= 0.05 m.
	var ground := GroundTruth.new(data)
	var roads := RoadBuilder.build_roads(data, ground)
	var spans := {60: [INF, -INF], 40: [INF, -INF], -60: [INF, -INF]}
	var worst := 0.0
	for child in roads.get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for v in verts:
			worst = maxf(worst, absf(v.y - ground.height_at_world(v.x, v.z)))
			for zc in spans:
				if absf(v.z - float(zc)) < 6.0:
					var sp: Array = spans[zc]
					sp[0] = minf(float(sp[0]), v.z)
					sp[1] = maxf(float(sp[1]), v.z)
	var w60: float = float(spans[60][1]) - float(spans[60][0])
	var w40: float = float(spans[40][1]) - float(spans[40][0])
	if absf(w60 - 8.0 * WorldScale.metres_to_units()) > 0.01:
		failures.append("8 m v2 road should be 8 units wide, got %s" % w60)
	if absf(w40 - 6.8) > 0.01:
		failures.append("v1 road should keep its 6.8 m ribbon, got %s" % w40)
	if float(spans[-60][1]) > -INF:
		failures.append("tunnel road should build no geometry")
	if worst > 0.05 * WorldScale.metres_to_units() + 0.0001:
		failures.append("road ribbons must sit flush (<=0.05 m), worst offset %.4f units" % worst)
	roads.free()

## One extruded ring: wall corners match the OSM points exactly
## (rotation preserved, nothing re-squared), every wall front face
## points outward, and the roof cap area equals the ring area.
func _check_extruded(failures: Array[String], world: Node3D, label: String,
		ring: PackedVector2Array, base: float, top: float, area: float) -> void:
	var walls: Array = []
	var roof: Array = []
	for child in world.get_children():
		if not (child is MeshInstance3D):
			continue
		var mi := child as MeshInstance3D
		if not (mi.mesh is ArrayMesh):
			continue
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		if verts.size() == ring.size() * 4 and _mesh_yrange(verts).x > base - 0.01 \
				and _mesh_yrange(verts).y < top + 0.01 and _corners_match(verts, ring, base):
			walls = arr
		elif verts.size() == ring.size() and _cap_match(verts, ring, top):
			roof = arr
	if walls.is_empty():
		failures.append("%s: wall mesh missing or corners differ from the ring" % label)
		return
	if roof.is_empty():
		failures.append("%s: roof cap mesh missing or corners differ from the ring" % label)
		return
	_check_wall_winding(failures, label, ring, walls)
	_check_roof_area(failures, label, ring, roof, area)

## Wall bottom verts are exactly the ring corners (each twice, shared
## by its two edges) at the base height.
static func _corners_match(verts: PackedVector3Array,
		ring: PackedVector2Array, base: float) -> bool:
	var want: Array = []
	for p in ring:
		want.append(p)
		want.append(p)
	var bottoms := 0
	for v in verts:
		if absf(v.y - base) > 0.01:
			continue
		bottoms += 1
		var hit := -1
		for i in want.size():
			if Vector2(v.x, v.z).distance_to(want[i]) < 0.01:
				hit = i
				break
		if hit < 0:
			return false
		want.remove_at(hit)
	return bottoms == ring.size() * 2 and want.is_empty()

## Roof verts are exactly the ring corners at the cap height.
static func _cap_match(verts: PackedVector3Array,
		ring: PackedVector2Array, top: float) -> bool:
	if verts.size() != ring.size():
		return false
	var want: Array = []
	for p in ring:
		want.append(p)
	for v in verts:
		if absf(v.y - top) > 0.01:
			return false
		var hit := -1
		for i in want.size():
			if Vector2(v.x, v.z).distance_to(want[i]) < 0.01:
				hit = i
				break
		if hit < 0:
			return false
		want.remove_at(hit)
	return want.is_empty()

static func _mesh_yrange(verts: PackedVector3Array) -> Vector2:
	var mn := INF
	var mx := -INF
	for v in verts:
		mn = minf(mn, v.y)
		mx = maxf(mx, v.y)
	return Vector2(mn, mx)

## Quads run in ring order: every stored normal and every triangle
## front face must equal the edge's outward normal.
func _check_wall_winding(failures: Array[String], label: String,
		ring: PackedVector2Array, walls: Array) -> void:
	var verts: PackedVector3Array = walls[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = walls[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = walls[Mesh.ARRAY_INDEX]
	var area2 := 0.0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		area2 += p.x * q.y - q.x * p.y
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		var n := Vector2(e.y, -e.x).normalized() if area2 > 0.0 \
			else Vector2(-e.y, e.x).normalized()
		var n3 := Vector3(n.x, 0.0, n.y)
		for j in 4:
			if normals[i * 4 + j].distance_to(n3) > 0.001:
				failures.append("%s: wall normal %d not outward" % [label, i])
				return
		for t in 2:
			var v0: Vector3 = verts[indices[i * 6 + t * 3]]
			var v1: Vector3 = verts[indices[i * 6 + t * 3 + 1]]
			var v2: Vector3 = verts[indices[i * 6 + t * 3 + 2]]
			var front := ((v2 - v0).cross(v1 - v0)).normalized()
			if front.dot(n3) < 0.99:
				failures.append("%s: wall triangle %d faces inward" % [label, i * 2 + t])
				return

## Roof triangles tile the ring area exactly and all face up.
func _check_roof_area(failures: Array[String], label: String,
		ring: PackedVector2Array, roof: Array, area: float) -> void:
	var verts: PackedVector3Array = roof[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = roof[Mesh.ARRAY_INDEX]
	var placed := 0.0
	var centroid := Vector2.ZERO
	for v in verts:
		centroid += Vector2(v.x, v.z)
	centroid /= float(maxi(verts.size(), 1))
	var want := Vector2.ZERO
	for p in ring:
		want += p
	want /= float(maxi(ring.size(), 1))
	if centroid.distance_to(want) > 0.01:
		failures.append("%s: roof centroid off by %f" % [label, centroid.distance_to(want)])
		return
	for t in indices.size() / 3:
		var v0: Vector3 = verts[indices[t * 3]]
		var v1: Vector3 = verts[indices[t * 3 + 1]]
		var v2: Vector3 = verts[indices[t * 3 + 2]]
		var e1 := Vector2(v1.x, v1.z) - Vector2(v0.x, v0.z)
		var e2 := Vector2(v2.x, v2.z) - Vector2(v0.x, v0.z)
		placed += absf(e1.x * e2.y - e1.y * e2.x) * 0.5
		var front := ((v2 - v0).cross(v1 - v0)).normalized()
		if front.dot(Vector3.UP) < 0.99:
			failures.append("%s: roof triangle %d faces down/sideways" % [label, t])
			return
	if absf(placed - area) / area > 0.001:
		failures.append("%s: roof area %f vs ring %f" % [label, placed, area])

## A corrupt/missing footprint still places its AABB, extruded as a
## rectangle mass (walls + roof, not a bare box) on the ground.
func _check_fallback_box(failures: Array[String], world: Node3D,
		ground: GroundTruth, xz: Vector2, size: Vector2, ehw: float) -> void:
	var yr := _rect_mass_yrange(world, xz, size)
	if yr.x == INF:
		failures.append("fallback AABB at %s not placed" % str(xz))
		return
	var want := _rect_base(ground, xz, size)
	if absf(yr.x - want) > 0.05 or absf(yr.y - yr.x - ehw - 0.6) > 0.05:
		failures.append("fallback at %s spans %s, want base %f height %f + 0.6 sink"
			% [str(xz), str(yr), want, ehw])

## Wall y-span [base, top] of the mass extruded from the AABB rectangle
## at xz (ground storey + upper walls combined); INF when missing.
static func _rect_mass_yrange(world: Node3D, xz: Vector2, size: Vector2) -> Vector2:
	var ring := BuildingBuilder._rect_ring(xz, size, 0.0)
	var out := Vector2(INF, -INF)
	for child in world.get_children():
		if not (child is MeshInstance3D) or not ((child as MeshInstance3D).mesh is ArrayMesh):
			continue
		var verts: PackedVector3Array = (child as MeshInstance3D).mesh \
			.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if verts.size() != ring.size() * 4:
			continue
		var yr := _mesh_yrange(verts)
		if _corners_match(verts, ring, yr.x):
			out = Vector2(minf(out.x, yr.x), maxf(out.y, yr.y))
	if out.x == INF:
		return Vector2(INF, INF)
	return out

## Extrusion base: lowest ground under the rectangle (centre + corners)
## sunk 0.6.
static func _rect_base(ground: GroundTruth, xz: Vector2, size: Vector2) -> float:
	var base := ground.height_at_world(xz.x, xz.y)
	for p in BuildingBuilder._rect_ring(xz, size, 0.0):
		base = minf(base, ground.height_at_world(p.x, p.y))
	return base - 0.6

## An extruded ring must not ALSO place an AABB box (no doubled mass).
func _check_no_fallback_box(failures: Array[String], world: Node3D,
		xz: Vector2, ehw: float) -> void:
	for child in world.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh \
				and absf((child as MeshInstance3D).scale.y - ehw) < 0.01 \
				and xz.distance_to(Vector2((child as MeshInstance3D).position.x,
					(child as MeshInstance3D).position.z)) < 2.0:
			failures.append("extruded ring at %s also placed an AABB box" % str(xz))
			return
