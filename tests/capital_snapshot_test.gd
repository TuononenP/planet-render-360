extends SceneTree

## Validates the complete capital catalog. Pass --allow-missing only while
## regenerating snapshots to validate the subset already prepared.
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures: Array[String] = []
	var missing: Array[String] = []
	var complete := 0
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(BundledOsm.CAPITAL_MANIFEST))
	var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/osm_snapshots/capital_provenance.json"))
	if not manifest is Dictionary or not provenance is Dictionary:
		failures.append("capital manifest or provenance is unreadable")
	else:
		for key in manifest:
			var id := str(key).trim_suffix("_detailed").trim_suffix("_ring1600").trim_suffix("_ring2500").trim_suffix("_poi").trim_suffix("_far")
			if not provenance.has(id):
				failures.append("%s: missing source provenance" % key)
			elif not (provenance[id] as Dictionary).has_all(["coordinates", "source", "source_timestamp", "captured_at", "coverage", "query_versions", "attribution"]):
				failures.append("%s: incomplete source provenance" % key)
			else:
				var meta: Dictionary = provenance[id]
				var row: Array = manifest[key]
				if meta["coordinates"] != [row[0], row[1]] or str(meta["source_timestamp"]).trim_suffix("Z") != str(row[4]):
					failures.append("%s: provenance does not match the snapshot" % key)
	var picks := LocationData.quick_picks()
	# A snapshot left behind when a catalog point moves would ship unused.
	if manifest is Dictionary:
		var points := {}
		for pick in picks:
			points[Vector2(float(pick[2]), float(pick[3]))] = true
		for key in manifest:
			var row: Array = manifest[key]
			if not points.has(Vector2(float(row[0]), float(row[1]))):
				failures.append("%s: no catalog location at this point" % key)
		if provenance is Dictionary:
			for id in provenance:
				if not manifest.has(str(id) + "_detailed"):
					failures.append("%s: provenance without bundled layers" % id)
	for i in range(PresetViews.ROWS.size(), picks.size()):
		var pick: Array = picks[i]
		var pos := Vector2(float(pick[2]), float(pick[3]))
		var keys: Array[String] = []
		for layer in ["detailed", "ring1600", "ring2500", "poi", "far"]:
			var version := OsmQuery.QUERY_VERSION if layer == "detailed" else (FarCityFetcher.QUERY_VERSION if layer == "far" else (OsmQuery.POI_VERSION if layer == "poi" else OsmQuery.RING_VERSION))
			keys.append(BundledOsm.entry_for(pos.x, pos.y, layer, version))
		if keys.all(func(key: String) -> bool: return key == ""):
			missing.append(str(pick[1]))
			continue
		var ok := true
		for key in keys:
			if key == "" or BundledOsm.read(key) == "":
				failures.append("%s: missing or invalid layer %s" % [pick[1], key])
				ok = false
		if ok:
			complete += 1
	if not OS.get_cmdline_user_args().has("--allow-missing") and not missing.is_empty():
		failures.append("missing capital snapshots (%d): %s" % [missing.size(), ", ".join(missing)])
	if failures.is_empty():
		print("CAPITAL SNAPSHOTS OK: %d complete, %d not bundled" % [complete, missing.size()])
		quit(0)
	else:
		for failure in failures:
			printerr("CAPITAL SNAPSHOTS FAIL: ", failure)
		quit(1)
