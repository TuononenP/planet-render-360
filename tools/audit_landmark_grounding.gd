extends SceneTree

## Audits every ground-anchored registry landmark against cached DEMs
## (HelsinkiDem 1 m, GroundModel national bare-earth rasters, Terrarium z14)
## to detect landmarks buried by site_ground_y / _hero_y corner drag.
##
## Run headlessly:
##   tools/godot_bg.sh --headless --path . --script tools/audit_landmark_grounding.gd -- \
##     --output=/path/to/audit.tsv --missing=/path/to/missing.tsv

var _hkidem_index: Array = []   # [{lat, lon, path}]
var _gmodel_index: Array = []   # [{src, lat, lon, path, ext, cells}]
var _raster_cache: Dictionary = {}  # path -> decoded raster
var _tile_cache: Dictionary = {}    # path -> PackedFloat32Array

func _init() -> void:
	_run()

func _run() -> void:
	var out_path := "/Users/petri/.gemini/antigravity/brain/c9d7a3d5-916d-4420-b636-bf969e7b624c/scratch/grounding_audit.tsv"
	var miss_path := "/Users/petri/.gemini/antigravity/brain/c9d7a3d5-916d-4420-b636-bf969e7b624c/scratch/missing_dem.tsv"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			out_path = arg.substr(9)
		elif arg.begins_with("--missing="):
			miss_path = arg.substr(10)

	_index_cache()
	print("CACHE INDEX: %d hkidem, %d gmodel windows" % [_hkidem_index.size(), _gmodel_index.size()])

	var stairs := LandmarkStairCut.stairs()
	var terraces := LandmarkStairCut.terraces()
	var rows: Array = []
	var missing_rows := PackedStringArray(["type\tname\tlat\tlon\tz14_x\tz14_y\thkidem\tgmodel"])
	var skipped := {"non_ground": 0, "relief_island": 0, "outline": 0, "stair_terrace": 0}
	var sources := {}

	for entry in LocationData.landmarks():
		var type := str(entry["type"])
		var base := str(entry.get("base", "ground"))
		if base != "ground":
			skipped["non_ground"] += 1
			continue
		if type in LandmarkTerrain.ISLANDS or type in LandmarkTerrain.RELIEFS:
			skipped["relief_island"] += 1
			continue
		if not LandmarkTerrain.outline(type).is_empty():
			skipped["outline"] += 1
			continue
		if stairs.has(type) or terraces.has(type):
			skipped["stair_terrace"] += 1
			continue

		var lat := float(entry["lat"])
		var lon := float(entry["lon"])
		var sampler := _find_sampler(lat, lon)
		if sampler.is_empty():
			var xy := _ll_to_tile(lat, lon, 14)
			missing_rows.append("%s\t%s\t%.6f\t%.6f\t%d\t%d\t%s\t%s" % [
				type, str(entry.get("name", "")), lat, lon, xy.x, xy.y,
				"1" if HelsinkiDem.covers(lat, lon) else "0",
				GroundModel.source_for(lat, lon)])
			continue

		var src := str(sampler["src"])
		sources[src] = int(sources.get(src, 0)) + 1

		# Build model bounds in true metres.
		var hero := LandmarkBuilder.build(type)
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for part in LandmarkBuilder.parts(hero):
			var xf := part.transform
			var p := part.get_parent() as Node3D
			while p != null and p != hero:
				xf = p.transform * xf
				p = p.get_parent() as Node3D
			var box: AABB = xf * part.mesh.get_aabb()
			lo = lo.min(box.position)
			hi = hi.max(box.end)
		hero.free()
		if not is_finite(lo.x):
			continue

		var yaw_rad := -deg_to_rad(float(entry.get("yaw_deg", 0.0)))
		var sample_w := func(wx: float, wz: float) -> float:
			var pt_lat := lat - wz / 110540.0
			var pt_lon := lon + wx / (111320.0 * cos(deg_to_rad(lat)))
			return _sample(sampler, pt_lat, pt_lon)
		var sample_l := func(lx: float, lz: float) -> float:
			var v := Vector3(lx, 0.0, lz).rotated(Vector3.UP, yaw_rad)
			return sample_w.call(v.x, v.z)

		var center_h: float = sample_w.call(0.0, 0.0)
		if is_nan(center_h):
			continue

		# Compute current _hero_y logic.
		var half := minf(LandmarkSites.clear_m(entry) * 0.5, 45.0) if entry.has("clear_m") else 20.0
		if entry.has("base_half_m"):
			half = float(entry["base_half_m"])
		var ax := 0.0
		var az := 0.0
		if entry.has("base_at_m"):
			var at: Array = entry["base_at_m"]
			var off := Vector3(float(at[0]), 0.0, float(at[1])).rotated(Vector3.UP, yaw_rad)
			ax = off.x
			az = off.z
			half = 0.0
		var site_lo := INF
		for o in [Vector2.ZERO, Vector2(half, half), Vector2(-half, half),
				Vector2(half, -half), Vector2(-half, -half)]:
			var h: float = sample_w.call(ax + o.x, az + o.y)
			if not is_nan(h):
				site_lo = minf(site_lo, h)
		if not is_finite(site_lo):
			continue
		var drop_m := float(entry.get("base_drop_m", 0.0))
		var root_y := site_lo - 0.3 + drop_m

		# Sample rotated model footprint (5x5 grid over horizontal AABB).
		var fp_min := INF
		var fp_max := -INF
		var fp_vals: Array[float] = []
		for iz in 5:
			var tz := float(iz) / 4.0
			var lz := lerpf(lo.z, hi.z, tz)
			for ix in 5:
				var tx := float(ix) / 4.0
				var lx := lerpf(lo.x, hi.x, tx)
				var h: float = sample_l.call(lx, lz)
				if not is_nan(h):
					fp_min = minf(fp_min, h)
					fp_max = maxf(fp_max, h)
					fp_vals.append(h)
		if fp_vals.is_empty():
			continue
		fp_vals.sort()
		var fp_med := fp_vals[fp_vals.size() / 2]
		var fp_relief := fp_max - fp_min
		var center_bury := center_h - root_y
		var max_bury := fp_max - root_y
		var outside_drag := fp_min - (root_y + 0.3)

		rows.append({
			"type": type, "name": str(entry.get("name", "")), "src": src,
			"lat": lat, "lon": lon, "clear_m": LandmarkSites.clear_m(entry),
			"half": half, "has_base_at": entry.has("base_at_m"),
			"drop_m": drop_m, "min_y": lo.y, "max_y": hi.y,
			"w": hi.x - lo.x, "d": hi.z - lo.z,
			"center_h": center_h, "root_y": root_y,
			"fp_min": fp_min, "fp_med": fp_med, "fp_max": fp_max, "fp_relief": fp_relief,
			"center_bury": center_bury, "max_bury": max_bury, "outside_drag": outside_drag,
		})

	# Sort by outside_drag descending, then center_bury descending.
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if absf(float(a["outside_drag"]) - float(b["outside_drag"])) > 0.15:
			return float(a["outside_drag"]) > float(b["outside_drag"])
		return float(a["center_bury"]) > float(b["center_bury"]))

	var tsv := PackedStringArray([
		"type\tname\tsrc\tlat\tlon\tclear_m\thalf_m\tbase_at\tdrop_m\tmin_y\tmax_y\tw_m\td_m\tcenter_h\troot_y\tfp_min\tfp_max\tfp_relief\tcenter_bury\tmax_bury\toutside_drag"
	])
	for r in rows:
		tsv.append("%s\t%s\t%s\t%.5f\t%.5f\t%.1f\t%.1f\t%s\t%.1f\t%.2f\t%.1f\t%.1f\t%.1f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f" % [
			r["type"], r["name"], r["src"], r["lat"], r["lon"], r["clear_m"], r["half"],
			"1" if r["has_base_at"] else "0", r["drop_m"], r["min_y"], r["max_y"], r["w"], r["d"],
			r["center_h"], r["root_y"], r["fp_min"], r["fp_max"], r["fp_relief"],
			r["center_bury"], r["max_bury"], r["outside_drag"]])

	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(tsv) + "\n")
		f.close()
	var mf := FileAccess.open(miss_path, FileAccess.WRITE)
	if mf != null:
		mf.store_string("\n".join(missing_rows) + "\n")
		mf.close()

	print("AUDIT SUMMARY: audited=%d missing_dem=%d skipped=%s sources=%s" % [
		rows.size(), missing_rows.size() - 1, str(skipped), str(sources)])
	print("\n--- TOP 30 BY OUTSIDE_DRAG / CENTER_BURY ---")
	var shown := 0
	for r in rows:
		if shown >= 30 and float(r["outside_drag"]) < 1.0 and float(r["center_bury"]) < 2.0:
			break
		print("  %-32s [%-9s] drag=%+5.2f  cbury=%+5.2f  maxb=%+5.2f  fprel=%4.2f  half=%4.1f  minY=%+.1f  w=%.0fx%.0f  (%s)" % [
			r["type"], r["src"], r["outside_drag"], r["center_bury"], r["max_bury"],
			r["fp_relief"], r["half"], r["min_y"], r["w"], r["d"], r["name"]])
		shown += 1
	quit(0)

func _index_cache() -> void:
	var dir_path := ProjectSettings.globalize_path(CacheStore.base_dir())
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var fn := d.get_next()
	while fn != "":
		if fn.begins_with("hkidem_v1_") and fn.ends_with(".tif"):
			var stem := fn.substr(10, fn.length() - 14)
			var parts := stem.split("_")
			if parts.size() == 2:
				_hkidem_index.append({
					"lat": float(int(parts[0])) / 1000.0,
					"lon": float(int(parts[1])) / 1000.0,
					"path": dir_path.path_join(fn),
				})
		elif fn.begins_with("gmodel_v") and (fn.ends_with(".bil") or fn.ends_with(".tif")):
			var ext := fn.get_extension()
			var stem := fn.substr(0, fn.length() - ext.length() - 1)
			var parts := stem.split("_")
			# gmodel_v1_ign_48857_2352
			if parts.size() == 5:
				var src := parts[2]
				var cells := GroundModel.MML_CELLS if src in ["mml", "lm"] else GroundModel.CELLS
				_gmodel_index.append({
					"src": src,
					"lat": float(int(parts[3])) / 1000.0,
					"lon": float(int(parts[4])) / 1000.0,
					"path": dir_path.path_join(fn),
					"ext": ext,
					"cells": cells,
				})
		fn = d.get_next()
	d.list_dir_end()

func _find_sampler(lat: float, lon: float) -> Dictionary:
	# 1. HelsinkiDem 1m
	if HelsinkiDem.covers(lat, lon):
		var best_d := 1200.0
		var best_path := ""
		for item in _hkidem_index:
			var dist := WorldScale.xz_from_latlon(lat, lon, float(item["lat"]), float(item["lon"])).length()
			if dist < best_d:
				best_d = dist
				best_path = str(item["path"])
		if best_path != "":
			var r := _load_hkidem(best_path)
			if not r.is_empty():
				return {"src": "hkidem", "raster": r}
	# 2. GroundModel national bare-earth window
	var best_gd := 1200.0
	var best_g: Dictionary = {}
	for item in _gmodel_index:
		var dist := WorldScale.xz_from_latlon(lat, lon, float(item["lat"]), float(item["lon"])).length()
		if dist < best_gd:
			best_gd = dist
			best_g = item
	if not best_g.is_empty():
		var r := _load_gmodel(best_g)
		if not r.is_empty():
			return {"src": "gm_" + str(best_g["src"]), "raster": r}
	# 3. GSI PNG tiles (Japan)
	var gsi_xy := _ll_to_tile(lat, lon, 15)
	var gsi_path := ProjectSettings.globalize_path(GroundModelFetcher.gsi_tile_path("gsi5a", 15, gsi_xy.x, gsi_xy.y))
	if FileAccess.file_exists(gsi_path):
		return {"src": "gm_gsi5a", "zoom": 15}
	# 4. Terrarium z14 PNG tiles
	var t_xy := _ll_to_tile(lat, lon, 14)
	var t_path := ProjectSettings.globalize_path(CacheStore.dem_path(14, t_xy.x, t_xy.y))
	if FileAccess.file_exists(t_path):
		return {"src": "terr14", "zoom": 14}
	return {}

func _load_hkidem(path: String) -> Dictionary:
	if _raster_cache.has(path):
		return _raster_cache[path]
	var r := HelsinkiDem.decode(FileAccess.get_file_as_bytes(path))
	_raster_cache[path] = r
	return r

func _load_gmodel(item: Dictionary) -> Dictionary:
	var path := str(item["path"])
	if _raster_cache.has(path):
		return _raster_cache[path]
	var bytes := FileAccess.get_file_as_bytes(path)
	var r: Dictionary = {}
	if str(item["ext"]) == "tif":
		r = HelsinkiDem.decode(bytes)
	else:
		var w := GroundModelFetcher.window(float(item["lat"]), float(item["lon"]))
		var c: Vector2 = w["c"]
		var h: float = w["half"]
		var cells := int(item["cells"])
		r = GroundModel.decode_bil(bytes, cells, Vector2(c.x - h, c.y + h), 2.0 * h / float(cells))
		if not r.is_empty():
			GroundModel.fill_missing(r)
	_raster_cache[path] = r
	return r

func _sample(sampler: Dictionary, lat: float, lon: float) -> float:
	var src := str(sampler["src"])
	if src == "hkidem":
		var gk := HelsinkiDem.gk25(lat, lon)
		return HelsinkiDem.sample(sampler["raster"], gk.x, gk.y)
	if src.begins_with("gm_") and sampler.has("raster"):
		var m := GroundModel.merc(lat, lon)
		return GroundModel.sample(sampler["raster"], m.x, m.y)
	if src == "gm_gsi5a":
		return _sample_tile(lat, lon, 15, true)
	if src == "terr14":
		return _sample_tile(lat, lon, 14, false)
	return NAN

func _sample_tile(lat: float, lon: float, zoom: int, is_gsi: bool) -> float:
	var n := float(1 << zoom)
	var fx := (lon + 180.0) / 360.0 * n
	var fy := (1.0 - asinh(tan(deg_to_rad(lat))) / PI) * 0.5 * n
	var tx := int(floor(fx))
	var ty := int(floor(fy))
	var px := (fx - float(tx)) * 256.0 - 0.5
	var py := (fy - float(ty)) * 256.0 - 0.5
	var path := ProjectSettings.globalize_path(
		GroundModelFetcher.gsi_tile_path("gsi5a", zoom, tx, ty) if is_gsi else CacheStore.dem_path(zoom, tx, ty))
	var vals := _load_tile(path, is_gsi)
	if vals.size() != 256 * 256:
		return NAN
	var x0 := clampi(int(floor(px)), 0, 254)
	var y0 := clampi(int(floor(py)), 0, 254)
	var u := clampf(px - float(x0), 0.0, 1.0)
	var v := clampf(py - float(y0), 0.0, 1.0)
	var a := vals[y0 * 256 + x0]
	var b := vals[y0 * 256 + x0 + 1]
	var c := vals[(y0 + 1) * 256 + x0]
	var d := vals[(y0 + 1) * 256 + x0 + 1]
	if is_nan(a) or is_nan(b) or is_nan(c) or is_nan(d):
		return NAN
	return lerpf(lerpf(a, b, u), lerpf(c, d, u), v)

func _load_tile(path: String, is_gsi: bool) -> PackedFloat32Array:
	if _tile_cache.has(path):
		return _tile_cache[path]
	if not FileAccess.file_exists(path):
		_tile_cache[path] = PackedFloat32Array()
		return PackedFloat32Array()
	var bytes := FileAccess.get_file_as_bytes(path)
	var vals := GroundModel.decode_gsi_png(bytes) if is_gsi else GroundModel.decode_terrarium(bytes, 256)
	_tile_cache[path] = vals
	return vals

func _ll_to_tile(lat: float, lon: float, zoom: int) -> Vector2i:
	var n := float(1 << zoom)
	var tx := int(floor((lon + 180.0) / 360.0 * n))
	var ty := int(floor((1.0 - asinh(tan(deg_to_rad(lat))) / PI) * 0.5 * n))
	return Vector2i(tx, ty)
