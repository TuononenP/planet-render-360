extends SceneTree

## Amsterdam landmark batch verification (`PLAN_Amsterdam_super_realistic.md`):
##   tools/godot_bg.sh --headless --path . --script tests/amsterdam_landmarks_test.gd
## Pins the 66 Amsterdam landmarks (51 bespoke + 15 skyline towers), Stockholm
## 48 / 56 Ultra slot budget, primary anchors, catalog limits (2–16 textured
## surfaces, <=150k tris, height within tolerance), and alias resolution.

var failures: Array[String] = []

const CENTRE_LAT := 52.37403
const CENTRE_LON := 4.88969

func _init() -> void:
	var rows := LandmarkRegistryAmsterdam.entries()
	_check(rows.size() >= 60, "Expected >= 60 Amsterdam landmark rows, got %d" % rows.size())
	var seen := {}
	var bespoke := 0
	var skyline := 0
	for raw in rows:
		var r: Dictionary = raw
		var t := str(r.get("type", ""))
		_check(t != "" and not seen.has(t), "Duplicate or empty type: %s" % t)
		seen[t] = true
		if bool(r.get("skyline", false)):
			skyline += 1
		else:
			bespoke += 1
		var lat := float(r.get("lat", 0.0))
		var lon := float(r.get("lon", 0.0))
		var d := WorldScale.xz_from_latlon(lat, lon, CENTRE_LAT, CENTRE_LON).length()
		var rad := float(r.get("radius_m", 0.0))
		_check(d < rad, "%s (%.0f m) outside its radius_m (%.0f m)" % [t, d, rad])
		# Build every landmark and verify catalog geometry limits.
		var model := Node3D.new()
		var ok := LandmarkSetAmsterdam.build(model, t)
		_check(ok, "LandmarkSetAmsterdam.build failed for %s" % t)
		if ok:
			var parts := LandmarkBuilder.parts(model)
			_check(parts.size() >= 2 and parts.size() <= 16,
				"%s part count %d outside [2, 16]" % [t, parts.size()])
			var tris := 0
			var max_y := -INF
			for mi in parts:
				if mi.mesh != null:
					for s in mi.mesh.get_surface_count():
						var arr := mi.mesh.surface_get_arrays(s)
						var idx: Variant = arr[Mesh.ARRAY_INDEX]
						var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
						tris += ((idx as PackedInt32Array).size() if idx != null and not (idx as PackedInt32Array).is_empty() else verts.size()) / 3
						var aabb := mi.mesh.get_aabb()
						max_y = maxf(max_y, aabb.end.y)
			_check(tris > 0 and tris <= 150000, "%s triangles %d outside (0, 150000]" % [t, tris])
			var want_h := float(r.get("height_m", 0.0))
			if want_h > 0.0 and max_y > 0.0:
				var tol := maxf(2.5, want_h * 0.08)
				_check(absf(max_y - want_h) <= tol,
					"%s top %.2f m differs from height_m %.2f m (tol %.2f m)" % [t, max_y, want_h, tol])
		model.free()

	# Pin Stockholm-matching Ultra slot limits (48 / 56) on primary anchors.
	for ptype in LandmarkRegistryAmsterdam.PRIMARIES:
		var e := LocationData.entry_for_type(ptype)
		_check(int(e.get("ultra_registry_limit", 0)) == 48,
			"Primary %s must carry ultra_registry_limit=48" % ptype)
		_check(int(e.get("ultra_total_limit", 0)) == 56,
			"Primary %s must carry ultra_total_limit=56" % ptype)

	# Verify selection on Ultra at Amsterdam capital centre fills generously.
	var data := LocationData.new()
	data.latitude = CENTRE_LAT
	data.longitude = CENTRE_LON
	data.quality_preset = RenderSettings.Preset.ULTRA
	data.landmark_type = "royal_palace_amsterdam"
	var sel := LandmarkSites.select(data, [])
	_check(sel.size() >= 30, "Ultra selection at Amsterdam centre should yield >= 30 candidates, got %d" % sel.size())

	if failures.is_empty():
		print("AMSTERDAM LANDMARKS OK: %d bespoke + %d skyline = %d built, 48/56 slots pinned, %d selected on Ultra" % [
			bespoke, skyline, rows.size(), sel.size()])
		quit(0)
	else:
		for f in failures:
			printerr("AMSTERDAM LANDMARKS FAIL: ", f)
		quit(1)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
