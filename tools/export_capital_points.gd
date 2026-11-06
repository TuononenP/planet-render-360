extends SceneTree

## Export the actual quick-pick coordinates for offline snapshot preparation.
## tools/godot_bg.sh --headless --path . --script tools/export_capital_points.gd -- /path/to/points.json
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Pass an output JSON path after --")
		quit(1)
		return
	var picks := LocationData.quick_picks()
	var index := PresetViews.ROWS.size()
	var out: Array = []
	for row in CapitalCatalog.ROWS:
		if str(row[0]) in CapitalCatalog.CURATED:
			continue
		var pick: Array = picks[index]
		var bundled := true
		for layer in ["detailed", "ring1600", "ring2500", "poi", "far"]:
			var version := OsmQuery.QUERY_VERSION if layer == "detailed" else (FarCityFetcher.QUERY_VERSION if layer == "far" else (OsmQuery.POI_VERSION if layer == "poi" else OsmQuery.RING_VERSION))
			var key := BundledOsm.entry_for(float(pick[2]), float(pick[3]), layer, version)
			if key == "" or BundledOsm.read(key) == "":
				bundled = false
		out.append({"code": row[0], "city": row[1], "name": pick[1],
			"lat": pick[2], "lon": pick[3], "bundled": bundled})
		index += 1
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	if file == null:
		printerr("Unable to write ", args[0])
		quit(1)
		return
	file.store_string(JSON.stringify(out, "  "))
	print("Exported %d capital points" % out.size())
	quit()
