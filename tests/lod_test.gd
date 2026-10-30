extends SceneTree

## LOD rings (T7.1) + AC-12 layout invariance:
## godot --headless --script tests/lod_test.gd
## The same place built at every preset places every object at the same
## transform (GroundTruth is preset-independent; only the terrain mesh
## density changes), LodRing.apply only changes visibility ranges /
## shadow casting, and the build-time merge keeps every vertex in place.

func _init() -> void:
	_run()

func _data(preset: int) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset)
	var n := data.grid_size
	data.heights.resize(n * n)
	for z in n:
		for x in n:
			data.heights[z * n + x] = 3.0 + 6.0 * sin(float(x) * 0.05) * cos(float(z) * 0.04)
	data.water_level = -3.0
	data.seed_value = 11
	data.landmark_type = "eiffel"
	data.has_landmark_site = true
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.landmark_lat = 48.8600
	data.landmark_lon = 2.3400
	data.buildings = []
	for i in 12:
		var c := Vector2(cos(float(i)) * (100.0 + 60.0 * i), sin(float(i)) * (100.0 + 60.0 * i))
		data.buildings.append({"x": c.x, "z": c.y, "size_x": 20.0, "size_z": 14.0,
			"height": 18.0, "name": "b%d" % i, "footprint": PackedVector2Array([
				c + Vector2(-10, -7), c + Vector2(10, -7), c + Vector2(10, 7), c + Vector2(-10, 7)])})
	return data

## Transform key per non-terrain node: name-free (pos rounded to 1 cm).
func _keys(world: Node3D) -> Dictionary:
	var out := {}
	for c in world.get_children():
		if not (c is Node3D) or str(c.get_meta("lod_layer", "")) == "":
			continue
		if str(c.get_meta("lod_layer", "")) == "Vegetation":
			continue  # scatter density is a per-preset count, not layout
		var p := (c as Node3D).global_transform.origin if c.is_inside_tree() else (c as Node3D).position
		out["%s|%.2f|%.2f|%.2f" % [c.get_meta("lod_layer"), p.x, p.y, p.z]] = true
	return out

func _run() -> void:
	var failures: Array[String] = []
	# Ring tables rise with the preset.
	for p in 3:
		if not (LodRing.detail_m(p) < LodRing.detail_m(p + 1) and LodRing.trees_m(p) < LodRing.trees_m(p + 1)):
			failures.append("ring radii should rise with the preset")
	# 1) Same layout at every preset (buildings + landmark transforms).
	var base := {}
	var landmark_y := []
	for p in [0, 1, 2, 3]:
		var data := _data(p)
		var ground := GroundTruth.new(data)
		var world := TerrainBuilder.build_world(data, ground)
		var keys := _keys(world)
		for c in world.get_children():
			if str(c.get_meta("lod_layer", "")) == "Landmarks" and c is Node3D:
				landmark_y.append((c as Node3D).position)
		if p == 0:
			base = keys
		else:
			for k in base:
				if str(k).begins_with("Buildings|") or str(k).begins_with("Landmarks|"):
					if not keys.has(k):
						failures.append("preset %d moved/dropped %s" % [p, k])
						break
		# 2) apply() changes ranges only, never transforms.
		var before := {}
		for c in world.get_children():
			if c is Node3D:
				before[c] = (c as Node3D).transform
		LodRing.apply(world, p)
		for c in before:
			if (c as Node3D).transform != before[c]:
				failures.append("LodRing.apply moved %s" % c.name)
				break
		# 3) Merge keeps every building vertex: union AABB unchanged.
		var aabb_before := _bld_aabb(world)
		var merged := LodRing.merge_buildings(world)
		var aabb_after := _bld_aabb(world)
		if merged == 0:
			failures.append("preset %d: nothing merged" % p)
		if not aabb_before.position.is_equal_approx(aabb_after.position) \
				or not aabb_before.size.is_equal_approx(aabb_after.size):
			failures.append("merge changed building extent %s -> %s" % [aabb_before, aabb_after])
		world.free()
	for i in landmark_y.size():
		if not (landmark_y[i] as Vector3).is_equal_approx(landmark_y[0]):
			failures.append("landmark moved across presets: %s" % str(landmark_y))
			break
	_impostor_checks(failures)
	_material_leak_checks(failures)
	if failures.is_empty():
		print("LOD OK: preset-invariant layout (buildings + landmark), apply ranges only, merge keeps geometry, T7.3 capped buildings become impostors at identical footprints/heights, T7.2 materials shared (no per-building leak)")
		quit(0)
	else:
		for f in failures:
			printerr("LOD FAIL: ", f)
		quit(1)

func _bld_aabb(world: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for c in world.get_children():
		if c is MeshInstance3D and str(c.get_meta("lod_layer", "")) == "Buildings":
			var a := (c as MeshInstance3D).transform * (c as MeshInstance3D).get_aabb()
			out = a if first else out.merge(a)
			first = false
	return out

## T7.3 / AC-12: more real buildings than the Fast cap. Every real
## footprint corner must exist on every preset at the same wall-top
## height — past the cap a building becomes a batched impostor mass,
## never dropped — and the impostors share few materials.
func _impostor_checks(failures: Array[String]) -> void:
	var cap := RenderSettings.max_buildings_for(0)
	var tops := []
	for p in [0, 3]:
		var data := _data(p)
		data.buildings = []
		var k := 0
		for gx in range(-13, 13):
			for gz in range(-13, 13):
				var c := Vector2(float(gx) * 42.0 + 21.0, float(gz) * 42.0 + 21.0)
				var h := 10.0 + float((gx * 7 + gz * 3) % 5) * 4.0
				data.buildings.append({"x": c.x, "z": c.y, "size_x": 16.0, "size_z": 12.0,
					"height": h, "name": "g%d" % k, "footprint": PackedVector2Array([
						c + Vector2(-8, -6), c + Vector2(8, -6), c + Vector2(8, 6), c + Vector2(-8, 6)])})
				k += 1
		var root := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
		var st := BuildingBuilder.last_stats
		if p == 0 and int(st.get("impostors", 0)) < data.buildings.size() - cap - 40:
			failures.append("Fast should turn the %d over-cap buildings into impostors, got %s"
				% [data.buildings.size() - cap, str(st)])
		var top := {}
		var imp_mats := {}
		for c in root.get_children():
			# build_buildings' own subtree: children carry no layer meta
			# until adopted, except the batched impostors / far city.
			if not (c is MeshInstance3D) or str(c.get_meta("lod_layer", "Buildings")) != "Buildings":
				continue
			var mi := c as MeshInstance3D
			if bool(mi.get_meta("lod_impostor", false)):
				imp_mats[mi.material_override] = true
			for s in mi.mesh.get_surface_count():
				for v in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					var w := mi.transform * v
					var key := "%.2f,%.2f" % [w.x, w.z]
					top[key] = maxf(float(top.get(key, -INF)), w.y)
		if p == 0 and imp_mats.size() > 8:
			failures.append("impostors should share the distant set, got %d materials" % imp_mats.size())
		var corners := {}
		for b in data.buildings:
			for q in (b["footprint"] as PackedVector2Array):
				var key := "%.2f,%.2f" % [q.x, q.y]
				corners[key] = top.get(key, -INF)
		tops.append(corners)
		root.free()
	var missing := 0
	var moved := 0
	for key in tops[0]:
		if float(tops[0][key]) == -INF or float(tops[1][key]) == -INF:
			missing += 1
		elif absf(float(tops[0][key]) - float(tops[1][key])) > 0.01:
			moved += 1
	if missing > 0:
		failures.append("AC-12: %d real footprint corners missing on a preset (dropped buildings)" % missing)
	if moved > 0:
		failures.append("AC-12: %d footprint corners change height between presets" % moved)

## T7.2: materials are shared, never minted per building. Four times the
## buildings in the same place must not add materials beyond the bounded
## per-place caches (variants, quantized tints), and after the LodRing
## merge the draw count follows cells x materials, not buildings.
func _material_leak_checks(failures: Array[String]) -> void:
	var counts := []
	var meshes := []
	for side in [10, 20]:
		var data := _data(RenderSettings.Preset.HIGH)
		data.buildings = []
		var k := 0
		for gx in side:
			for gz in side:
				var c := Vector2(float(gx - side / 2) * 30.0 + 15.0, float(gz - side / 2) * 30.0 + 15.0)
				data.buildings.append({"x": c.x, "z": c.y, "size_x": 16.0, "size_z": 12.0,
					"height": 12.0 + float((gx * 7 + gz * 3) % 5) * 3.0, "name": "m%d" % k,
					"footprint": PackedVector2Array([c + Vector2(-8, -6), c + Vector2(8, -6),
						c + Vector2(8, 6), c + Vector2(-8, 6)])})
				k += 1
		var root := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
		var flat := Node3D.new()
		for c in root.get_children():
			root.remove_child(c)
			if not c.has_meta("lod_layer"):
				c.set_meta("lod_layer", "Buildings")
			flat.add_child(c)
		root.free()
		LodRing.merge_buildings(flat)
		var mats := {}
		var n := 0
		for c in flat.get_children():
			if not (c is MeshInstance3D) or str(c.get_meta("lod_layer", "")) != "Buildings":
				continue
			var mi := c as MeshInstance3D
			n += 1
			for si in mi.mesh.get_surface_count():
				var m := mi.get_active_material(si)
				if m != null:
					mats[m.get_instance_id()] = true
		counts.append(mats.size())
		meshes.append(n)
		flat.free()
	if counts[1] > counts[0] + 8:
		failures.append("T7.2: 4x buildings added %d materials (%d -> %d): per-building material leak"
			% [counts[1] - counts[0], counts[0], counts[1]])
	if meshes[1] > counts[1] * 4:
		failures.append("T7.2: %d merged building meshes for %d materials: merge not batching" % [meshes[1], counts[1]])
	print("LOD T7.2 materials 100 -> 400 buildings: %d -> %d, merged meshes %d -> %d" % [counts[0], counts[1], meshes[0], meshes[1]])
