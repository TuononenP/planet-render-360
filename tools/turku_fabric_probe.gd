extends SceneTree

## How often Turku's per-building facts reach the look a building is drawn
## with: TurkuNotable rows, enriched turku_lod2 (height, roof, start_year,
## kind via RegisterCodes), and district era distribution. Reads the bundled
## Turku OSM snapshot (turku_detailed) and bundled turku_lod2 cells offline.
## Run headlessly:
## tools/godot_bg.sh --headless --path . --script tools/turku_fabric_probe.gd \
##   -- [--preset=3]

func _init() -> void:
	var args := {"lat": "60.4518", "lon": "22.2666", "preset": "3"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var lat := float(args["lat"])
	var lon := float(args["lon"])
	var osm := BundledOsm.read("turku_detailed")
	if osm == "":
		printerr("FABRIC no bundled turku_detailed snapshot")
		quit(2)
		return
	var feats := OsmParser.parse_features(osm, lat, lon)
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.country = "FI"
	data.quality_preset = int(args["preset"])
	data.buildings = feats["buildings"]
	var lod2 := HelsinkiLod2.rows_for(lat, lon)
	var st := HelsinkiLod2.apply(data.buildings, lat, lon, lod2)
	print("FABRIC lod2 rows=%d matched=%d filled=%d" % [st["rows"], st["matched"], st["filled"]])
	var ctx := BuildingHeights._height_context(data)
	var n := 0
	var notable := 0
	var with_year := 0
	var lod2_roof := 0
	var lod2_roof_ok := 0
	var eras := {}
	for b in data.buildings:
		var bd := b as Dictionary
		if bool(bd.get("suppressed", false)) or bool(bd.get("landmark", false)):
			continue
		n += 1
		var look := BuildingHeights._look_for(bd, ctx)
		var era := str(look["era"])
		eras[era] = int(eras.get(era, 0)) + 1
		if int(bd.get("start_year", 0)) >= 1700:
			with_year += 1
		var enriched: Dictionary = bd.get("enriched", {})
		if enriched.has(TurkuNotable.PROVENANCE):
			notable += 1
		if (enriched.get(HelsinkiLod2.PROVENANCE, []) as Array).has("roof_shape"):
			lod2_roof += 1
			var drawn := BuildingHeights._effective_shape(str(bd.get("roof_shape", "")), str(look["roof_shape"]), false)
			if drawn == BuildingHeights._effective_shape(str(bd["roof_shape"]), "", false):
				lod2_roof_ok += 1
	print("FABRIC buildings=%d notable=%d with_year=%d (%.1f%%)" % [
		n, notable, with_year, 100.0 * float(with_year) / maxf(1.0, float(n))])
	print("FABRIC lod2_roof=%d drawn_as_lod2=%d" % [lod2_roof, lod2_roof_ok])
	var keys := eras.keys()
	keys.sort_custom(func(x, y): return int(eras[x]) > int(eras[y]))
	for k in keys:
		print("FABRIC era %s %d" % [k, eras[k]])
	quit(0)
