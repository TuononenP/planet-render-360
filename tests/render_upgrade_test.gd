extends SceneTree

## Headless: godot --headless --script tests/render_upgrade_test.gd
## The rendering upgrade's contracts, independent of a GPU:
## - grade: glow only from HDR highlights, ambient from the sky;
## - facades: frames and glass paint over the tinted wall (detail layer),
##   lit panes are an emission map that is dark by day and lit at night,
##   per-building wall tints average 1;
## - roofs: UVs measured on the roof plane (no stretch on steep slopes);
## - terrain: every photographic layer exists, palette weights sum to 1;
## - water: the sea grid carries shore distance growing away from land;
## - roads: shared nodes are junctions, ribbons carry lanes/rank/junction;
## - ground cover: none on Fast, some on High, never on buildings.

func _init() -> void:
	_run()

func _flat(preset: int, height: float = 3.0) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(height)
	data.water_level = -3.0
	data.seed_value = 7
	data.latitude = 48.8566
	data.longitude = 2.3522
	return data

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	# Grade.
	var env := Environment.new()
	PostGrade.apply(env)
	if env.glow_bloom > 0.0 or env.glow_hdr_threshold < 1.0:
		failures.append("glow should come from HDR highlights only (bloom %.2f, threshold %.2f)"
			% [env.glow_bloom, env.glow_hdr_threshold])
	if env.ambient_light_sky_contribution < 1.0 or env.tonemap_mode != Environment.TONE_MAPPER_ACES:
		failures.append("ambient should be the sky, tonemap ACES")
	# Facade layers.
	var look := {"frame": Color(0.8, 0.8, 0.78), "window": "casement", "variant": 1}
	var texs := FacadeComposer.compose_tile("limestone", "punched", 1, look,
		Callable(MaterialLibrary, "_set_image"))
	if not (texs.get("paint") is Texture2D) or not (texs.get("emit") is Texture2D):
		failures.append("tiled facades should carry paint and emission layers")
	else:
		var paint := (texs["paint"] as Texture2D).get_image()
		paint.clear_mipmaps()
		var clear := 0
		var painted := 0
		for y in range(0, paint.get_height(), 4):
			for x in range(0, paint.get_width(), 4):
				if paint.get_pixel(x, y).a < 0.1:
					clear += 1
				elif paint.get_pixel(x, y).a > 0.9:
					painted += 1
		if clear == 0 or painted == 0:
			failures.append("paint layer should hold windows over a clear wall (%d clear, %d painted)" % [clear, painted])
	var m := FacadeTextures._material_from(texs, "limestone", 1, Color(2.0, 1.8, 1.6))
	if not m.detail_enabled or m.detail_albedo == null:
		failures.append("facade material should paint frames as a detail layer")
	if not m.emission_enabled or m.emission_energy_multiplier != 0.0:
		failures.append("lit panes should be an emission map, dark until night")
	if not WallVariety.is_wall(m) or not m.vertex_color_use_as_albedo:
		failures.append("facade materials should take the per-building wall tint")
	var holder := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.material = m
	holder.mesh = box
	var world := Node3D.new()
	world.add_child(holder)
	CityLights.apply(world, 1.0)
	if m.emission_energy_multiplier <= 0.0:
		failures.append("CityLights should light marked facades at night")
	CityLights.apply(world, 0.0)
	world.free()
	if CityLights.amount_for(0.0, 0.0) != 0.0 or CityLights.amount_for(1.0, 0.0) < 1.0:
		failures.append("city lights should be off by day and full at night")
	var mean := Color(0, 0, 0)
	for i in 3000:
		mean += WallVariety.tint_for(float(i % 60) * 17.0 - 500.0, float(i / 60) * 29.0 - 700.0)
	mean = mean / 3000.0
	if absf(mean.r - 1.0) > 0.015 or absf(mean.g - 1.0) > 0.015 or absf(mean.b - 1.0) > 0.015:
		failures.append("wall tints should average 1 (AC-12), got %s" % mean)
	# Roof UVs on a 60° slope: 1 m down the slope is 1 m of texture.
	var n60 := Vector3(sin(deg_to_rad(60.0)), cos(deg_to_rad(60.0)), 0.0)
	var ax := RoofGeometry.slope_axes(n60)
	var a3 := Vector3.ZERO
	var b3 := a3 + (ax[1] as Vector3)
	if absf(b3.dot(ax[1]) - a3.dot(ax[1]) - 1.0) > 0.001 or absf((ax[0] as Vector3).y) > 0.001 \
			or absf((ax[1] as Vector3).dot(n60)) > 0.001:
		failures.append("roof slope axes should lie in the roof plane, u level")
	# Courtyard blocks: a U-shaped footprint takes the inset roof (every
	# face up-facing, none spanning the courtyard); a small L keeps its ridge.
	var u_ring := PackedVector2Array([Vector2(0, 0), Vector2(60, 0), Vector2(60, 40),
		Vector2(45, 40), Vector2(45, 14), Vector2(15, 14), Vector2(15, 40), Vector2(0, 40)])
	var l_ring := PackedVector2Array([Vector2(0, 0), Vector2(12, 0), Vector2(12, 6),
		Vector2(6, 6), Vector2(6, 12), Vector2(0, 12)])
	if not RoofGeometry.needs_inset(u_ring) or RoofGeometry.needs_inset(l_ring):
		failures.append("only large non-convex footprints should take the inset roof")
	var u_roof := RoofGeometry.form_mesh(u_ring, 10.0, 3.0, "hipped")
	if u_roof == null:
		failures.append("a courtyard block should still get a roof")
	else:
		var ua := u_roof.surface_get_arrays(0)
		var uv: PackedVector3Array = ua[Mesh.ARRAY_VERTEX]
		var un: PackedVector3Array = ua[Mesh.ARRAY_NORMAL]
		var down := 0
		var inside_court := 0
		for i in uv.size():
			if un[i].y <= 0.0:
				down += 1
		for i in range(0, uv.size(), 3):
			var c3 := (uv[i] + uv[i + 1] + uv[i + 2]) / 3.0
			if c3.x > 16.0 and c3.x < 44.0 and c3.z > 15.0:
				inside_court += 1
		if down > 0 or inside_court > 0:
			failures.append("inset roof: %d down-facing normals, %d faces over the courtyard" % [down, inside_court])
	# Roof tile courses snap to the roof's own axes: two facets 20 degrees
	# apart on a curved footprint share one frame.
	var fu := Vector2(1, 0)
	var nf1 := Vector3(sin(deg_to_rad(10.0)) * 0.5, 0.87, cos(deg_to_rad(10.0)) * 0.5).normalized()
	var nf2 := Vector3(sin(deg_to_rad(30.0)) * 0.5, 0.87, cos(deg_to_rad(30.0)) * 0.5).normalized()
	if (RoofGeometry.slope_axes(nf1, fu)[0] as Vector3).distance_to(
			RoofGeometry.slope_axes(nf2, fu)[0] as Vector3) > 0.001:
		failures.append("nearby roof facets should share their tile courses")
	# No wall tint is brighter than clean white paint.
	for hex in ["#ffffff", "#f4efe4", "#f2ead8"]:
		var wc := ArchitectureStyle._tint([hex], 0.3, 2)
		if wc.r * 0.2126 + wc.g * 0.7152 + wc.b * 0.0722 > ArchitectureStyle.WALL_ALBEDO_MAX + 0.001:
			failures.append("wall tint %s exceeds the albedo cap" % hex)
	# Terrain layers and palette.
	for s in TerrainTextures.LAYERS:
		if not MaterialLibrary.PBR_SETS.has(s) or not FileAccess.file_exists(
				MaterialLibrary.TEXTURE_DIR + str(s) + "_diff.jpg"):
			failures.append("terrain layer %s should be a bundled set" % s)
	if TerrainTextures.means().size() != TerrainTextures.LAYERS.size() \
			or TerrainTextures.TILE_M.size() != TerrainTextures.LAYERS.size():
		failures.append("terrain layer tables should align")
	var pal := GroundMaterial.palette()
	for cls in GroundMaterial.ID:
		var id: int = GroundMaterial.ID[cls]
		if id == 0:
			continue
		var w0 := pal.get_pixel(id, 0)
		var w1 := pal.get_pixel(id, 3)
		var sum := w0.r + w0.g + w0.b + w0.a + w1.r + w1.g + w1.b + w1.a
		if absf(sum - 1.0) > 0.02:
			failures.append("class %s layer weights sum to %.2f" % [cls, sum])
	# Sea grid: west half land at 5 m, east half sea.
	var sea := _flat(RenderSettings.Preset.HIGH)
	var g := sea.grid_size
	for z in g:
		for x in g:
			sea.heights[z * g + x] = 5.0 if x < g / 2 else -4.0
	var ground := GroundTruth.new(sea)
	var root := Node3D.new()
	WaterSurface.add_sea_grid(root, ground, ground.render_y(0.0), WaterSurface.material(2))
	var mi := root.get_child(0) as MeshInstance3D if root.get_child_count() > 0 else null
	if mi == null:
		failures.append("sea grid should build a surface")
	else:
		var arr := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		var near_shore := 1.0
		var open_sea := 0.0
		for i in verts.size():
			if absf(verts[i].z) < 50.0:
				if verts[i].x > 4.0 and verts[i].x < 20.0:
					near_shore = minf(near_shore, cols[i].b)
				if verts[i].x > 800.0:
					open_sea = maxf(open_sea, cols[i].b)
			if cols[i].g < 0.5:
				near_shore = -1.0
		if near_shore < 0.0 or near_shore > 0.75 or open_sea < 0.99:
			failures.append("sea grid shore distance: near %.2f, open %.2f (want low near the coast, 1 offshore, sea flag set)"
				% [near_shore, open_sea])
	root.free()
	# Roads: two ways sharing a node.
	var rd := _flat(RenderSettings.Preset.HIGH)
	rd.roads = [
		{"class": "residential", "width_m": 8.0, "lanes": 2, "points": PackedVector2Array([Vector2(-60, 0), Vector2(0, 0), Vector2(60, 0)])},
		{"class": "residential", "width_m": 8.0, "lanes": 2, "points": PackedVector2Array([Vector2(0, -60), Vector2(0, 0), Vector2(0, 60)])},
	]
	rd.buildings = [{"x": 300.0, "z": 300.0, "size_x": 10.0, "size_z": 10.0, "height": 9.0}]
	var junc := RoadSurface.junctions(rd)
	if RoadSurface.junction_frac(junc, Vector2(0, 0)) > 0.01 or RoadSurface.junction_frac(junc, Vector2(50, 0)) < 0.99:
		failures.append("the shared node should be a junction (%.2f at it, %.2f 50 m away)"
			% [RoadSurface.junction_frac(junc, Vector2(0, 0)), RoadSurface.junction_frac(junc, Vector2(50, 0))])
	var roads := RoadBuilder.build_roads(rd, GroundTruth.new(rd))
	var attr_ok := false
	for c in roads.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override is ShaderMaterial:
			var ra := (c as MeshInstance3D).mesh.surface_get_arrays(0)
			var rc: PackedColorArray = ra[Mesh.ARRAY_COLOR]
			var u2: PackedVector2Array = ra[Mesh.ARRAY_TEX_UV2]
			attr_ok = rc.size() == (ra[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() \
				and absf(rc[0].r - 0.25) < 0.01 and absf(u2[0].x - 8.0) < 0.01
	if not attr_ok:
		failures.append("asphalt ribbons should use RoadSurface with lanes and width per vertex")
	roads.free()
	# Ground cover on a park polygon.
	for preset in [RenderSettings.Preset.FAST, RenderSettings.Preset.HIGH]:
		var pd := _flat(preset)
		pd.land_polygons = [{"class": "grass", "points": PackedVector2Array([Vector2(-80, -80),
			Vector2(80, -80), Vector2(80, 80), Vector2(-80, 80)])}]
		pd.buildings = [{"x": 0.0, "z": 0.0, "size_x": 20.0, "size_z": 20.0, "height": 9.0,
			"footprint": PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])}]
		var pg := GroundTruth.new(pd)
		var mask := VegetationMask.new(pd, pg)
		var placed := GroundCover.plan(pd, pg, mask)
		var count := 0
		var on_building := 0
		for kind in placed:
			for e in placed[kind]:
				count += 1
				var o: Vector3 = e[0]
				if absf(o.x) < 9.0 and absf(o.z) < 9.0:
					on_building += 1
		if preset == RenderSettings.Preset.FAST and count != 0:
			failures.append("Fast should not pay for ground cover (%d)" % count)
		if preset == RenderSettings.Preset.HIGH and (count < 200 or on_building > 0):
			failures.append("High park cover: %d instances, %d on the building" % [count, on_building])
	failures.erase(failures[0])
	if failures.is_empty():
		print("RENDER UPGRADE OK: grade, facade paint + night lights, wall tints, roof UVs, terrain layers, sea shore, road junctions, ground cover")
		quit(0)
	else:
		for f in failures:
			printerr("RENDER UPGRADE FAIL: ", f)
		quit(1)
