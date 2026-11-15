extends SceneTree

## Headless verification for far-landmark octahedral impostors (Feature B):
##   tools/godot_bg.sh --headless --path . --script tests/impostor_test.gd
## Covers:
##   1) Bake contract: 4x 256x256 RGBA8 cardinal views + alpha mask + 8-face
##      dihedral octahedron mesh, lit texels on geometry, transparent surround,
##      Eiffel spire reaching the top rows, front-facing clockwise winding.
##   2) Determinism & landmark-local invariance: fresh builds produce
##      bit-identical SHA-256 digests; rotating the landmark root does not
##      perturb its local cardinal views.
##   3) Placement & LodRing routing: <= 3000 m keeps pure real mesh;
##      3000..4200 m pairs real mesh + impostor with alpha-dither cross-fade
##      margins at 3000 m (no pop); > 4200 m strips unreachable real parts
##      leaving one octahedral MeshInstance3D; AC-12 positions match across
##      every preset.
##   4) Parallel-vs-serial equality on a world with far landmarks.
##   5) Fallback: forced or empty-mesh bake failure keeps the real landmark
##      mesh on the skyline and records a fallback note.
##   6) WorldCache / PackedScene round-trip: baked view images survive
##      pack -> save (.scn) -> load -> instantiate -> restore_cached
##      bit-identically even in the headless dummy renderer.

const SIZE := LandmarkImpostor.SIZE
const R := LandmarkImpostor.R_IMPOSTOR_M

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures: Array[String] = []
	failures.append_array(_test_bake_shapes())
	failures.append_array(_test_determinism())
	failures.append_array(_test_placement_and_lod())
	failures.append_array(await _test_parallel_equality())
	failures.append_array(_test_fallback())
	failures.append_array(_test_cache_round_trip())
	if failures.is_empty():
		print("IMPOSTOR OK: 4x256 CPU bake, 8-face octahedron, determinism, LodRing cross-fade, parallel equality, fallback, cache round-trip")
		quit(0)
	else:
		for f in failures:
			printerr("IMPOSTOR FAIL: ", f)
		quit(1)

static func _alpha_cov(bytes: PackedByteArray) -> float:
	var n := 0
	var i := 3
	while i < bytes.size():
		if bytes[i] > 0:
			n += 1
		i += 4
	return float(n) / maxf(float(bytes.size()) / 4.0, 1.0)

static func _row_cov(bytes: PackedByteArray, row0: int, row1: int) -> float:
	var r0 := clampi(row0, 0, SIZE - 1)
	var r1 := clampi(row1, r0, SIZE - 1)
	var n := 0
	var total := 0
	for r in range(r0, r1 + 1):
		for c in SIZE:
			total += 1
			if bytes[(r * SIZE + c) * 4 + 3] > 0:
				n += 1
	return float(n) / float(maxi(total, 1))

static func _digest(out: Dictionary) -> String:
	if not bool(out.get("ok", false)):
		return ""
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	for t in out["textures"]:
		hc.update((t as Image).get_data())
	hc.update((out["mask"] as Image).get_data())
	return hc.finish().hex_encode()

func _test_bake_shapes() -> Array[String]:
	var failures: Array[String] = []
	var tower := LandmarkBuilder.build_archetype("tower", 60.0, Vector2(24.0, 24.0), "western_europe")
	var out := LandmarkImpostor.bake(tower)
	tower.free()
	if not bool(out.get("ok", false)):
		failures.append("archetype tower bake failed: %s" % str(out.get("note", "")))
		return failures
	var texs: Array = out["textures"]
	var mask: Image = out["mask"]
	if texs.size() != 4 or mask.get_size() != Vector2i(SIZE, SIZE):
		failures.append("expected 4x %dx%d views + mask" % [SIZE, SIZE])
		return failures
	var t0: Image = texs[0]
	var t0_bytes := t0.get_data()
	var cov0 := _alpha_cov(t0_bytes)
	if absf(cov0 - _alpha_cov(mask.get_data())) > 0.005:
		failures.append("mask alpha disagrees with front view")
	if cov0 < 0.25 or cov0 > 0.98:
		failures.append("tower front coverage implausible (%f) — should fill silhouette with transparent margin" % cov0)
	if _alpha_cov((texs[1] as Image).get_data()) < 0.25:
		failures.append("tower east view under-covered")
	var lit := 0
	for i in SIZE * SIZE:
		var o := i * 4
		if t0_bytes[o + 3] > 0 and (int(t0_bytes[o]) + int(t0_bytes[o + 1]) + int(t0_bytes[o + 2])) > 30:
			lit += 1
	if lit < int(SIZE * SIZE * 0.2):
		failures.append("baked tower has too few lit texels (%d)" % lit)
	if absf(float(out["height"]) - 60.0) > 8.0:
		failures.append("baked tower height %.1f m far from 60 m" % float(out["height"]))

	var mesh: ArrayMesh = out["mesh"]
	if mesh.get_surface_count() != 8:
		failures.append("octahedron expected 8 wing surfaces, got %d" % mesh.get_surface_count())
	else:
		var expected_views := [0, 1, 1, 0, 2, 3, 3, 2]
		for s in 8:
			var arr := MeshArrays.surface(mesh, s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if verts.size() != 4 or idx.size() != 6:
				failures.append("octahedron face %d is not an indexed quad" % s)
				continue
			var tri_n := (verts[idx[2]] - verts[idx[0]]).cross(verts[idx[1]] - verts[idx[0]])
			if tri_n.dot(norms[0]) <= 0.0:
				failures.append("octahedron face %d is wound back-facing" % s)
			var mat := mesh.surface_get_material(s) as StandardMaterial3D
			if mat == null or mat.albedo_texture == null:
				failures.append("octahedron face %d missing albedo texture" % s)
			elif int(mat.albedo_texture.get_meta("view", -1)) != expected_views[s]:
				failures.append("octahedron face %d bound wrong cardinal view" % s)

	var eiffel := LandmarkBuilder.build("eiffel")
	var eo := LandmarkImpostor.bake(eiffel)
	eiffel.free()
	if not bool(eo.get("ok", false)):
		failures.append("eiffel bake failed: %s" % str(eo.get("note", "")))
	else:
		if float(eo["height"]) < 300.0:
			failures.append("eiffel height %.1f m (want >= 300 m)" % float(eo["height"]))
		var ec := (eo["textures"][0] as Image).get_data()
		# Row 0 is the top (+Y spire), row SIZE-1 is the base (y0): spire is narrower than base!
		var top_cov := _row_cov(ec, 2, 18)
		var base_cov := _row_cov(ec, SIZE - 28, SIZE - 6)
		if top_cov < 0.01:
			failures.append("eiffel spire missing from top rows (cov=%f)" % top_cov)
		if base_cov <= top_cov * 2.0:
			failures.append("eiffel base should be wider than spire (base=%f top=%f)" % [base_cov, top_cov])
	return failures

func _test_determinism() -> Array[String]:
	var failures: Array[String] = []
	var e1 := LandmarkBuilder.build("eiffel")
	var e2 := LandmarkBuilder.build("eiffel")
	var d1 := _digest(LandmarkImpostor.bake(e1))
	var d2 := _digest(LandmarkImpostor.bake(e2))
	e1.free()
	e2.free()
	if d1 == "" or d1 != d2:
		failures.append("fresh Eiffel bakes are not bit-identical")

	var tb_plain := LandmarkBuilder.build("tower_bridge")
	var tb_rot := LandmarkBuilder.build("tower_bridge")
	tb_rot.position = Vector3(4100.0, 12.0, -2300.0)
	tb_rot.rotation.y = deg_to_rad(137.0)
	var dp := _digest(LandmarkImpostor.bake(tb_plain))
	var dr := _digest(LandmarkImpostor.bake(tb_rot, 137.0))
	tb_plain.free()
	tb_rot.free()
	if dp != dr:
		failures.append("landmark root transform leaked into local cardinal views")
	return failures

func _flat_paris_data(preset: int = RenderSettings.Preset.HIGH) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, preset)
	d.grid_size = 16
	d.heights.resize(256)
	d.heights.fill(35.0)
	d.water_level = -3.0
	d.seed_value = 7
	d.country = "fr"
	d.latitude = 48.8566
	d.longitude = 2.3522
	# Eiffel Tower stands ~4232 m WSW of Paris city centre (> STRIP_REAL_M = 4200 m).
	d.landmark_type = "eiffel"
	d.has_landmark_site = true
	d.landmark_lat = 48.85826
	d.landmark_lon = 2.29450
	d.landmark_candidates = [
		# Near candidate (< 3000 m): keeps pure real mesh.
		{"type": "notre_dame", "x": 450.0, "z": 320.0, "yaw_deg": 20.0, "mapped": false},
		# Threshold-band candidate (3000..4200 m): paired real + impostor with cross-fade!
		{"type": "sacre_coeur", "x": -480.0, "z": -3350.0, "yaw_deg": 0.0, "mapped": false},
		# Very far candidate (6000 m, far_r0 = 4500): culled on Fast (4500), shown on High (12001).
		{"archetype": "tower", "x": 6000.0, "z": 0.0, "height": 55.0, "size_x": 18.0, "size_z": 18.0, "yaw": 0.2, "mapped": false},
	]
	return d

func _test_placement_and_lod() -> Array[String]:
	var failures: Array[String] = []
	var d := _flat_paris_data(RenderSettings.Preset.HIGH)
	var g := GroundTruth.new(d)
	var world := TerrainBuilder.build_world(d, g)
	LodRing.apply(world, RenderSettings.Preset.HIGH)

	var saw_stripped := false
	var saw_paired := false
	var saw_near := false
	var far6k_imp: MeshInstance3D = null
	for c in world.get_children():
		if str(c.get_meta("lod_layer", "")) != "Landmarks" or not (c is Node3D):
			continue
		var lm := c as Node3D
		var dist := Vector2(lm.position.x, lm.position.z).length()
		var parts := LandmarkBuilder.parts(lm)
		if dist < R - 50.0:
			saw_near = true
			if bool(lm.get_meta("lod_impostor", false)):
				failures.append("near landmark %s (%.0f m) should remain pure real mesh" % [lm.name, dist])
		elif dist > LandmarkImpostor.STRIP_REAL_M + 10.0:
			saw_stripped = true
			if not bool(lm.get_meta("lod_impostor", false)) or parts.size() != 1:
				failures.append("far landmark %s (%.0f m) should strip to 1 impostor mesh, got %d parts" % [lm.name, dist, parts.size()])
			if dist > 5500.0 and parts.size() == 1:
				far6k_imp = parts[0]
		elif dist > R + 10.0:
			saw_paired = true
			var imp_node := lm.get_node_or_null("Impostor") as MeshInstance3D
			if imp_node == null or parts.size() < 2:
				failures.append("threshold-band landmark %s (%.0f m) should pair real mesh + impostor" % [lm.name, dist])
			else:
				if not is_equal_approx(imp_node.visibility_range_begin, R) \
						or not is_equal_approx(imp_node.visibility_range_begin_margin, LandmarkImpostor.CROSSFADE_M) \
						or imp_node.visibility_range_fade_mode != GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF:
					failures.append("paired impostor missing smooth cross-fade at R_IMPOSTOR_M")
				for p in parts:
					if p != imp_node and (not is_equal_approx(p.visibility_range_end, R) \
							or not is_equal_approx(p.visibility_range_end_margin, LandmarkImpostor.CROSSFADE_M)):
						failures.append("paired near part missing cross-fade end at R_IMPOSTOR_M")
						break
	if not (saw_near and saw_paired and saw_stripped):
		failures.append("expected near, paired and stripped landmarks in fixture (%s/%s/%s)" % [saw_near, saw_paired, saw_stripped])

	# Preset switch via LodRing: Fast (FAR_CITY_M = 4500) hides the 6 km impostor (far_r0 = 4500),
	# High shows it, without moving any landmark node (AC-12).
	if far6k_imp != null:
		if far6k_imp.visibility_range_end < 10000.0:
			failures.append("High preset should show 6 km impostor, got end=%f" % far6k_imp.visibility_range_end)
		var pos_before := (far6k_imp.get_parent() as Node3D).position
		LodRing.apply(world, RenderSettings.Preset.FAST)
		if not is_equal_approx(far6k_imp.visibility_range_end, 1.0):
			failures.append("Fast preset should cull 6 km impostor (far_r0=4500), got end=%f" % far6k_imp.visibility_range_end)
		if not (far6k_imp.get_parent() as Node3D).position.is_equal_approx(pos_before):
			failures.append("LodRing preset switch moved landmark")
	world.free()
	return failures

func _test_parallel_equality() -> Array[String]:
	var failures: Array[String] = []
	var d1 := _flat_paris_data(RenderSettings.Preset.HIGH)
	var g1 := GroundTruth.new(d1)
	var serial := TerrainBuilder._build_serial(d1, g1)

	var d2 := _flat_paris_data(RenderSettings.Preset.HIGH)
	var g2 := GroundTruth.new(d2)
	var th := Thread.new()
	th.start(func() -> Node3D: return WorldBuildGraph.build(d2, g2))
	while th.is_alive():
		await process_frame
	var parallel: Node3D = th.wait_to_finish()

	if serial.get_child_count() != parallel.get_child_count():
		failures.append("parallel vs serial child count mismatch (%d vs %d)" % [parallel.get_child_count(), serial.get_child_count()])
	else:
		for i in serial.get_child_count():
			var cs := serial.get_child(i)
			var cp := parallel.get_child(i)
			var ns := "" if str(cs.name).begins_with("@") else str(cs.name)
			var np := "" if str(cp.name).begins_with("@") else str(cp.name)
			if ns != np or cs.get_meta("lod_impostor", false) != cp.get_meta("lod_impostor", false):
				failures.append("parallel vs serial child %d differs (%s vs %s)" % [i, ns, np])
	serial.free()
	parallel.free()
	return failures

func _test_fallback() -> Array[String]:
	var failures: Array[String] = []
	LandmarkImpostor.fallback_notes.clear()
	LandmarkImpostor._fail_bake_test = true
	var d := _flat_paris_data(RenderSettings.Preset.BALANCED)
	d.landmark_candidates = []
	var world := TerrainBuilder._build_serial(d, GroundTruth.new(d))
	LandmarkImpostor._fail_bake_test = false

	var eiffel_node: Node3D = null
	for c in world.get_children():
		if str(c.name) == "Landmark_eiffel":
			eiffel_node = c as Node3D
	if eiffel_node == null:
		failures.append("fallback dropped the far Eiffel landmark")
	elif bool(eiffel_node.get_meta("lod_impostor", false)) or LandmarkBuilder.parts(eiffel_node).size() < 2:
		failures.append("failed bake should keep multi-part real Eiffel mesh intact")
	if LandmarkImpostor.fallback_notes.is_empty():
		failures.append("failed bake should record a fallback note")
	world.free()

	var empty_root := Node3D.new()
	if bool(LandmarkImpostor.bake(empty_root).get("ok", false)):
		failures.append("empty Node3D should fail bake cleanly")
	empty_root.free()
	return failures

func _test_cache_round_trip() -> Array[String]:
	var failures: Array[String] = []
	var d := _flat_paris_data(RenderSettings.Preset.BALANCED)
	d.landmark_candidates = []
	var world := TerrainBuilder._build_serial(d, GroundTruth.new(d))
	var path := "user://impostor_round_trip_%d.scn" % OS.get_process_id()
	WorldCache._own(world, world)
	var ps := PackedScene.new()
	if ps.pack(world) != OK:
		world.free()
		return ["PackedScene.pack failed"]
	if ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS) != OK:
		world.free()
		return ["ResourceSaver.save failed"]
	world.free()

	var loaded := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if loaded == null:
		return ["ResourceLoader.load returned null"]
	var inst := loaded.instantiate() as Node3D
	LandmarkImpostor.restore_cached(inst)

	var ref_eiffel := LandmarkBuilder.build("eiffel")
	var ref_bake := LandmarkImpostor.bake(ref_eiffel)
	ref_eiffel.free()
	var ref_hashes: Array[String] = []
	for t in ref_bake["textures"]:
		var hc := HashingContext.new()
		hc.start(HashingContext.HASH_SHA256)
		hc.update((t as Image).get_data())
		ref_hashes.append(hc.finish().hex_encode())

	var seen := {}
	for c in inst.get_children():
		if str(c.name) == "Landmark_eiffel":
			for p in LandmarkBuilder.parts(c as Node3D):
				for s in p.mesh.get_surface_count():
					var mat := p.mesh.surface_get_material(s) as StandardMaterial3D
					if mat == null or mat.albedo_texture == null:
						continue
					var v_idx := int(mat.albedo_texture.get_meta("view", -1))
					var img := mat.albedo_texture.get_meta("impostor_image", null) as Image
					if img == null or img.is_empty():
						img = mat.albedo_texture.get_image()
					if v_idx >= 0 and img != null and not img.is_empty():
						var hc := HashingContext.new()
						hc.start(HashingContext.HASH_SHA256)
						hc.update(img.get_data())
						seen[v_idx] = hc.finish().hex_encode()
	inst.free()
	if seen.size() != 4:
		failures.append("cache round-trip restored %d/4 view textures" % seen.size())
	else:
		for i in 4:
			if seen[i] != ref_hashes[i]:
				failures.append("cache round-trip view %d bytes differ from fresh bake" % i)
	return failures
