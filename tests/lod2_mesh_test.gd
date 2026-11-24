extends SceneTree

## Verifies binary v2 PackedInt32Array .lod2m bundles across Turku, Helsinki, and Espoo:
## 1. Smooth plaster enabled for Turku, Helsinki, Espoo.
## 2. Binary v2 zstd decompression + SHA-256 integrity + MAGIC/VERSION checks.
## 3. Sampled roofs & street-level walls present in all 3 cities.
## 4. Lod2MeshBuilder builds from PackedInt32Array with zero JSON parsing,
##    suppresses duplicate OSM extrusions, and upgrades cleanly via FacadeShader.

func _count_cells(lat: float, lon: float) -> Dictionary:
	var bufs := TurkuLod2Meshes.cells_for(lat, lon)
	var total := 0
	var with_rc := 0
	var with_wc := 0
	var first_e := 0.0
	var first_n := 0.0
	var first_area := 100.0
	for buf: PackedInt32Array in bufs:
		var count := buf[2]
		var off := TurkuLod2Meshes.HEADER_INTS
		for _i in count:
			if off + TurkuLod2Meshes.BLDG_HEADER_INTS > buf.size():
				break
			if total == 0:
				first_e = float(buf[off]) * 0.1
				first_n = float(buf[off + 1]) * 0.1
				first_area = float(buf[off + 2]) * 0.1
			if buf[off + 7] > 0:
				with_rc += 1
			if buf[off + 9] > 0:
				with_wc += 1
			total += 1
			var nwv := buf[off + 10]
			var nwi := buf[off + 11]
			var nrv := buf[off + 12]
			var nri := buf[off + 13]
			off += TurkuLod2Meshes.BLDG_HEADER_INTS + nwv * 5 + nwi + nrv * 5 + nri
	return {"cells": bufs.size(), "total": total, "rc": with_rc, "wc": with_wc,
		"e": first_e, "n": first_n, "area": first_area}

func _test_city(name: String, lat: float, lon: float, min_bldgs: int, min_wc: int,
		expect_mesh: bool = true, check_nb: bool = true) -> bool:
	var ok := true
	if not TurkuLod2Meshes.covers(lat, lon):
		push_error("FAIL: TurkuLod2Meshes.covers(%s) is false" % name)
		return false
	var credits := TurkuLod2Meshes.credits_for(lat, lon)
	if credits.is_empty():
		push_error("FAIL: %s TurkuLod2Meshes.credits_for is empty" % name)
		ok = false
	var t0 := Time.get_ticks_msec()
	var st := _count_cells(lat, lon)
	var ms := Time.get_ticks_msec() - t0
	print("%s binary v2: %d cells, %d buildings (%d roofs, %d street walls) decoded in %d ms" % [
		name, int(st["cells"]), int(st["total"]), int(st["rc"]), int(st["wc"]), ms])
	if int(st["total"]) < min_bldgs:
		push_error("FAIL: %s expected >= %d buildings, got %d" % [name, min_bldgs, int(st["total"])])
		ok = false
	if int(st["wc"]) < min_wc:
		push_error("FAIL: %s expected >= %d wall samples, got %d" % [name, min_wc, int(st["wc"])])
		ok = false

	# Synthetic build test for this city
	var crs := 1 if TurkuLod2Meshes.is_gk23(lat, lon) \
		else (2 if TurkuLod2Meshes.is_rd_new(lat, lon) else 0)
	var frame := Gk23.frame(lat, lon) if crs == 1 \
		else (RdNew.frame(lat, lon) if crs == 2 else Gk25.frame(lat, lon))
	var xz := Gk23.frame_xz(frame, float(st["e"]), float(st["n"])) if crs == 1 \
		else (RdNew.frame_xz(frame, float(st["e"]), float(st["n"])) if crs == 2 \
		else Gk25.frame_xz(frame, float(st["e"]), float(st["n"])))
	var m2u := WorldScale.metres_to_units()
	var half := maxf(3.0, sqrt(float(st["area"])) * 0.5)
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.grid_size = 4
	data.heights = PackedFloat32Array()
	data.heights.resize(16)
	data.heights.fill(5.0)
	data.quality_preset = RenderSettings.Preset.ULTRA
	# Add a second non-overlapping neighbour 6.5 m away (within MAX_MATCH_M) to verify
	# _find_osm_overlaps never falsely suppresses an adjacent building.
	var nb_x := xz.x + half + 6.5
	var nb_z := xz.y
	data.buildings = [{
		"x": xz.x * m2u,
		"z": xz.y * m2u,
		"footprint": PackedVector2Array([
			Vector2(xz.x - half, xz.y - half) * m2u,
			Vector2(xz.x + half, xz.y - half) * m2u,
			Vector2(xz.x + half, xz.y + half) * m2u,
			Vector2(xz.x - half, xz.y + half) * m2u,
		]),
		"kind": "apartments",
	}, {
		"x": nb_x * m2u,
		"z": nb_z * m2u,
		"footprint": PackedVector2Array([
			Vector2(nb_x - 2.0, nb_z - 2.0) * m2u,
			Vector2(nb_x + 2.0, nb_z - 2.0) * m2u,
			Vector2(nb_x + 2.0, nb_z + 2.0) * m2u,
			Vector2(nb_x - 2.0, nb_z + 2.0) * m2u,
		]),
		"kind": "house",
	}]
	var ground := GroundTruth.new(data)
	var root := Node3D.new()
	var standing := PackedByteArray([1, 1])
	var ctx := {"region": name.to_lower(), "density": "urban", "fidelity": 2, "eye": Vector2.ZERO,
		"eye_reach": Vector2.ZERO, "sea_y": -INF, "tone": 0.0}
	var handled := Lod2MeshBuilder.build_corridor(root, data, ground, data.buildings, standing, ctx)
	if expect_mesh:
		if handled.size() != 2 or handled[0] != 1:
			push_error("FAIL: %s Lod2MeshBuilder did not match synthetic building" % name)
			ok = false
		if check_nb and handled[1] != 0:
			push_error("FAIL: %s Lod2MeshBuilder falsely suppressed non-overlapping neighbour" % name)
			ok = false
		var upgraded := FacadeShader.upgrade(root)
		if upgraded < 1:
			push_error("FAIL: %s FacadeShader did not upgrade LoD2 wall material" % name)
			ok = false
	else:
		if handled[0] != 0:
			push_error("FAIL: %s attribute-only record should leave BuildingBuilder to extrude" % name)
			ok = false
		if str((data.buildings[0] as Dictionary).get("roof_colour", "")) == "":
			push_error("FAIL: %s attribute-only record did not enrich roof_colour" % name)
			ok = false
	root.free()
	return ok

func _wall_buf(verts_m: Array, tris: Array) -> PackedInt32Array:
	var buf := PackedInt32Array()
	for v: Vector3 in verts_m:
		buf.append(roundi(v.x * 100.0))
		buf.append(roundi(v.y * 100.0))
		buf.append(roundi(v.z * 100.0))
	for t: Vector3i in tris:
		buf.append(t.x)
		buf.append(t.y)
		buf.append(t.z)
	return buf


func _test_wall_layout() -> bool:
	var ok := true
	# 1. Clean rectangular 6 m x 9 m wall facing +Z (south): 100% windowed, 0 blank,
	#    integer bay span (2 bays -> u in [0, 0.5]) and integer storey span (3 storeys -> v in [0, 3]).
	var rect_v := [Vector3(-3, 0, 5), Vector3(3, 0, 5), Vector3(3, 9, 5), Vector3(-3, 9, 5)]
	var rect_t := [Vector3i(0, 2, 1), Vector3i(0, 3, 2)]
	var rbuf := _wall_buf(rect_v, rect_t)
	var rdec := Lod2WallLayout.decode(rbuf, 0, rect_v.size() * 3, rect_v.size(), rect_t.size() * 3,
		0.0, 0.0, 0.0, 1.0, 2.8, 4.0, 3.0, 0.0, true)
	var rwin: Array = rdec["windowed"]
	var rblk: Array = rdec["blank"]
	if (rwin[0] as PackedVector3Array).size() != 6 or not (rblk[0] as PackedVector3Array).is_empty():
		push_error("FAIL: rectangular wall expected 6 windowed verts & 0 blank, got %d / %d" % [
			(rwin[0] as PackedVector3Array).size(), (rblk[0] as PackedVector3Array).size()])
		ok = false
	else:
		var u_lo := INF
		var u_hi := -INF
		var v_lo := INF
		var v_hi := -INF
		for uv: Vector2 in (rwin[2] as PackedVector2Array):
			u_lo = minf(u_lo, uv.x); u_hi = maxf(u_hi, uv.x)
			v_lo = minf(v_lo, uv.y); v_hi = maxf(v_hi, uv.y)
		if absf(u_lo) > 0.01 or absf(u_hi - 0.5) > 0.01 or absf(v_lo) > 0.01 or absf(v_hi - 3.0) > 0.01:
			push_error("FAIL: rectangular wall UVs not snapped to whole bays/storeys: u=[%.3f,%.3f] v=[%.3f,%.3f]" % [
				u_lo, u_hi, v_lo, v_hi])
			ok = false

	# 2. Narrow Dutch gable wall (6 m wide, 9 m eave, 13.5 m peak): lower 9 m body
	#    windowed, triangular gable peak completely blank (no diagonally cut windows).
	var gab_v := [Vector3(-3, 0, 5), Vector3(3, 0, 5), Vector3(3, 9, 5), Vector3(0, 13.5, 5), Vector3(-3, 9, 5)]
	var gab_t := [Vector3i(0, 3, 4), Vector3i(0, 1, 3), Vector3i(1, 2, 3)]
	var gbuf := _wall_buf(gab_v, gab_t)
	var gdec := Lod2WallLayout.decode(gbuf, 0, gab_v.size() * 3, gab_v.size(), gab_t.size() * 3,
		0.0, 0.0, 0.0, 1.0, 2.8, 4.0, 3.0, 0.0, true)
	var gwin_v: PackedVector3Array = (gdec["windowed"] as Array)[0]
	var gblk_v: PackedVector3Array = (gdec["blank"] as Array)[0]
	var max_win_y := -INF
	for p in gwin_v:
		max_win_y = maxf(max_win_y, p.y)
	if gwin_v.is_empty() or gblk_v.is_empty() or max_win_y > 9.05:
		push_error("FAIL: gable wall should keep windows <= 9.0 m eave and gable blank, got win=%d blk=%d max_win_y=%.2f" % [
			gwin_v.size(), gblk_v.size(), max_win_y])
		ok = false

	# 3. Sloped-roof wall (10 m wide, top sloping 9.0 m -> 11.4 m): rows below 9.0 m
	#    windowed, sloped top wedge blank (no roof-sliced top windows).
	var slp_v := [Vector3(-5, 0, 5), Vector3(5, 0, 5), Vector3(5, 11.4, 5), Vector3(-5, 9.0, 5)]
	var slp_t := [Vector3i(0, 2, 1), Vector3i(0, 3, 2)]
	var sbuf := _wall_buf(slp_v, slp_t)
	var sdec := Lod2WallLayout.decode(sbuf, 0, slp_v.size() * 3, slp_v.size(), slp_t.size() * 3,
		0.0, 0.0, 0.0, 1.0, 2.5, 4.0, 3.0, 0.0, true)
	var swin_v: PackedVector3Array = (sdec["windowed"] as Array)[0]
	var sblk_v: PackedVector3Array = (sdec["blank"] as Array)[0]
	var max_swin_y := -INF
	for p in swin_v:
		max_swin_y = maxf(max_swin_y, p.y)
	if swin_v.is_empty() or sblk_v.is_empty() or max_swin_y > 9.05:
		push_error("FAIL: sloped-roof wall should keep windows <= 9.0 m and sloped wedge blank, got win=%d blk=%d max_y=%.2f" % [
			swin_v.size(), sblk_v.size(), max_swin_y])
		ok = false

	# 4. Narrow 0.7 m pilaster strip (height 12 m): 100% blank, 0 windowed verts.
	var pil_v := [Vector3(0, 0, 5), Vector3(0.7, 0, 5), Vector3(0.7, 12, 5), Vector3(0, 12, 5)]
	var pil_t := [Vector3i(0, 2, 1), Vector3i(0, 3, 2)]
	var pbuf := _wall_buf(pil_v, pil_t)
	var pdec := Lod2WallLayout.decode(pbuf, 0, pil_v.size() * 3, pil_v.size(), pil_t.size() * 3,
		0.0, 0.0, 0.0, 1.0, 2.6, 4.0, 3.0, 0.0, true)
	if not ((pdec["windowed"] as Array)[0] as PackedVector3Array).is_empty() \
			or ((pdec["blank"] as Array)[0] as PackedVector3Array).size() != 6:
		push_error("FAIL: narrow pilaster strip must be 100% blank masonry")
		ok = false

	# 5. Wide tall gable (14 m wide, 9 m eave, 18 m peak): centered upper attic
	#    windows fit inside the wide gable while outer diagonal slopes stay blank.
	var wg_v := [Vector3(-7, 0, 5), Vector3(7, 0, 5), Vector3(7, 9, 5), Vector3(0, 18, 5), Vector3(-7, 9, 5)]
	var wg_t := [Vector3i(0, 3, 4), Vector3i(0, 1, 3), Vector3i(1, 2, 3)]
	var wbuf := _wall_buf(wg_v, wg_t)
	var wdec := Lod2WallLayout.decode(wbuf, 0, wg_v.size() * 3, wg_v.size(), wg_t.size() * 3,
		0.0, 0.0, 0.0, 1.0, 2.8, 4.0, 3.0, 0.0, true)
	var wg_win_v: PackedVector3Array = (wdec["windowed"] as Array)[0]
	var wg_blk_v: PackedVector3Array = (wdec["blank"] as Array)[0]
	var wg_max_y := -INF
	var wg_above_eave_max_abs_x := 0.0
	for p in wg_win_v:
		wg_max_y = maxf(wg_max_y, p.y)
		if p.y > 9.05:
			wg_above_eave_max_abs_x = maxf(wg_above_eave_max_abs_x, absf(p.x))
	if wg_blk_v.is_empty() or wg_max_y < 11.9 or wg_above_eave_max_abs_x > 4.5:
		push_error("FAIL: wide gable should keep centred attic windows inside slopes and slopes blank (max_y=%.2f max_x=%.2f blk=%d)" % [
			wg_max_y, wg_above_eave_max_abs_x, wg_blk_v.size()])
		ok = false

	# 6. Wide 44 m x 19.8 m rectangular wall rotated 3.2 deg off bucket axis: both
	#    triangles must merge into ONE rectangular patch with identical storey UVs
	#    (zero diagonal staircase kink across the quad).
	var ang := deg_to_rad(23.2)
	var dx := cos(ang) * 44.0
	var dz := sin(ang) * 44.0
	var ang_v := [Vector3(0, 0, 0), Vector3(dx, 0, dz), Vector3(dx, 19.8, dz), Vector3(0, 19.8, 0)]
	var ang_t := [Vector3i(0, 2, 1), Vector3i(0, 3, 2)]
	var abuf := _wall_buf(ang_v, ang_t)
	var adec := Lod2WallLayout.decode(abuf, 0, ang_v.size() * 3, ang_v.size(), ang_t.size() * 3,
		0.0, 0.0, 0.0, 1.0, 3.2, 4.0, 3.3, 0.0, false)
	var awin_uv: PackedVector2Array = (adec["windowed"] as Array)[2]
	if awin_uv.size() != 6 or absf(awin_uv[0].y - 6.0) > 0.02 or absf(awin_uv[3].y - 6.0) > 0.02 \
			or absf(awin_uv[1].y) > 0.02 or absf(awin_uv[5].y) > 0.02:
		push_error("FAIL: 44 m angled rectangular wall split across diagonal: uvs=%s" % [awin_uv])
		ok = false

	# 7. FacadeMaterials.blank_for_facade matches facade tint & upgrades via FacadeShader.
	FacadeMaterials.begin_build()
	var look := ArchitectureStyle.resolve({"kind": "apartments", "material": "brick", "colour": "#5c342b"},
		"amsterdam", "urban", 0.3, 120.0)
	var fac := FacadeMaterials.facade_for_building({"kind": "apartments", "material": "brick", "colour": "#5c342b"},
		"amsterdam", 4, 2, false, 0.3, look)
	var blk := FacadeMaterials.blank_for_facade(fac)
	if not (blk is StandardMaterial3D) or (blk as StandardMaterial3D).detail_enabled \
			or (blk as StandardMaterial3D).heightmap_enabled \
			or (blk as StandardMaterial3D).albedo_color != (fac as StandardMaterial3D).albedo_color:
		push_error("FAIL: blank_for_facade did not produce a matched windowless material")
		ok = false
	var blk_sh := FacadeShader.from_standard(blk as StandardMaterial3D)
	if bool(blk_sh.get_shader_parameter("has_paint")) or bool(blk_sh.get_shader_parameter("has_depth")) \
			or not bool(blk_sh.get_shader_parameter("has_photo")):
		push_error("FAIL: blank FacadeShader parameters mismatch")
		ok = false

	# 8. Held skillion gable mesh (MeshArrays.hold, as in BuildingBuilder._extrude_masses)
	#    keeps explicit roof:direction even on party-bounded rings and dresses vertical
	#    ramp walls with outward-facing multi-storey windows.
	var m2u := WorldScale.metres_to_units()
	var sk_ring := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(28.0 * m2u, 0.0),
		Vector2(28.0 * m2u, 24.0 * m2u), Vector2(0.0, 24.0 * m2u),
	])
	var sk_axis := RoofForms.axis_from_tags({"roof_dir": 180.0}, sk_ring)
	var sk_party := PackedByteArray([1, 1, 1, 1])
	MeshArrays.hold()
	var sk_roof := RoofGeometry.form_mesh(sk_ring, 6.0 * m2u, 50.0 * m2u, "skillion",
		sk_party, false, [], sk_axis)
	var sk_gables := RoofGeometry.split_gables(sk_roof, sk_ring, PackedByteArray())
	var sk_dressed := Lod2WallLayout.dress_gable_mesh(sk_gables[0] as ArrayMesh, 6.0 * m2u,
		3.8 * m2u, 3.2, 4.0, true)
	MeshArrays.release()
	if sk_dressed[0] == null or (sk_dressed[0] as ArrayMesh).get_surface_count() != 1:
		push_error("FAIL: dress_gable_mesh dropped held skillion walls under MeshArrays.hold()")
		ok = false
	var sk_roof_v: PackedVector3Array = MeshArrays.surface(sk_roof, 0)[Mesh.ARRAY_VERTEX]
	var south_max_y := -INF
	var north_max_y := -INF
	for p in sk_roof_v:
		if p.z > 20.0 * m2u:
			south_max_y = maxf(south_max_y, p.y / m2u)
		elif p.z < 4.0 * m2u:
			north_max_y = maxf(north_max_y, p.y / m2u)
	if south_max_y > 6.5 or north_max_y < 55.5:
		push_error("FAIL: skillion with explicit roof:direction=180 flipped on party ring (south=%.1f north=%.1f)" % [
			south_max_y, north_max_y])
		ok = false
	return ok


func _initialize() -> void:
	var ok := _test_wall_layout()
	for city in ["turku", "helsinki", "espoo"]:
		if not FacadeComposer.smooth_plaster("render", {"city": city}):
			push_error("FAIL: smooth_plaster should be true for %s" % city)
			ok = false
	ok = _test_city("Turku", 60.4495, 22.2675, 2000, 500, true) and ok
	ok = _test_city("Helsinki", 60.1695, 24.9522, 2000, 25, false) and ok
	ok = _test_city("Espoo", 60.1775, 24.8050, 1000, 50, false) and ok
	ok = _test_city("Amsterdam", 52.37403, 4.88969, 2000, 500, true, false) and ok
	if ok:
		print("PASS: lod2_mesh_test")
		quit(0)
	else:
		quit(1)
