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

func _test_city(name: String, lat: float, lon: float, min_bldgs: int, min_wc: int) -> bool:
	var ok := true
	if not TurkuLod2Meshes.covers(lat, lon):
		push_error("FAIL: TurkuLod2Meshes.covers(%s) is false" % name)
		return false
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
	var use_gk23 := TurkuLod2Meshes.is_gk23(lat, lon)
	var frame := Gk23.frame(lat, lon) if use_gk23 else Gk25.frame(lat, lon)
	var xz := Gk23.frame_xz(frame, float(st["e"]), float(st["n"])) if use_gk23 \
		else Gk25.frame_xz(frame, float(st["e"]), float(st["n"]))
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
	}]
	var ground := GroundTruth.new(data)
	var root := Node3D.new()
	var standing := PackedByteArray([1])
	var ctx := {"region": name.to_lower(), "density": "urban", "fidelity": 2, "eye": Vector2.ZERO,
		"eye_reach": Vector2.ZERO, "sea_y": -INF, "tone": 0.0}
	var handled := Lod2MeshBuilder.build_corridor(root, data, ground, data.buildings, standing, ctx)
	if handled.size() != 1 or handled[0] != 1:
		push_error("FAIL: %s Lod2MeshBuilder did not match synthetic building" % name)
		ok = false
	var upgraded := FacadeShader.upgrade(root)
	if upgraded < 1:
		push_error("FAIL: %s FacadeShader did not upgrade LoD2 wall material" % name)
		ok = false
	root.free()
	return ok

func _initialize() -> void:
	var ok := true
	for city in ["turku", "helsinki", "espoo"]:
		if not FacadeComposer.smooth_plaster("render", {"city": city}):
			push_error("FAIL: smooth_plaster should be true for %s" % city)
			ok = false
	ok = _test_city("Turku", 60.4495, 22.2675, 2000, 500) and ok
	ok = _test_city("Helsinki", 60.1695, 24.9522, 2000, 25) and ok
	ok = _test_city("Espoo", 60.1775, 24.8050, 1000, 50) and ok
	if ok:
		print("PASS: lod2_mesh_test")
		quit(0)
	else:
		quit(1)
