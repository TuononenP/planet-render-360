extends SceneTree

## How often Helsinki's per-building facts reach the look a building is
## drawn with: the register's facade material (HelsinkiRegister) against
## the resolved wall set and the palette its colour came from, the LoD2
## roof form (HelsinkiLod2) against the drawn roof shape, and the
## HelsinkiNotable rows. Reads the cached centre answer (OSM r1200 and the
## register window) and the bundled LoD2 cells; prints era counts too.
## Run headlessly:
## tools/godot_bg.sh --headless --path . --script tools/helsinki_fabric_probe.gd \
##   -- [--lat=60.168 --lon=24.953 --preset=3]

func _init() -> void:
	var args := {"lat": "60.168", "lon": "24.953", "preset": "3"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var lat := float(args["lat"])
	var lon := float(args["lon"])
	var osm := FileAccess.get_file_as_string(CacheStore.osm_path(lat, lon, 1200))
	if osm == "":
		printerr("FABRIC no cached OSM answer at ", CacheStore.osm_path(lat, lon, 1200))
		quit(2)
		return
	var feats := OsmParser.parse_features(osm, lat, lon)
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.country = "FI"
	data.quality_preset = int(args["preset"])
	data.buildings = feats["buildings"]
	var reg_text := FileAccess.get_file_as_string(CityOpenData.cache_path("register", lat, lon))
	var reg: Variant = HelsinkiRegister.decode(reg_text) if reg_text != "" else null
	var out := CityOpenData.merge(data, reg if reg is Array else [], [], [], [], false)
	for line in out["log"]:
		print("FABRIC ", line)
	var ctx := BuildingHeights._height_context(data)
	var n := 0
	var reg_mat := 0
	var reg_mat_set_ok := 0
	var reg_mat_foreign_paint := 0
	var lod2_roof := 0
	var lod2_roof_ok := 0
	var notable := 0
	var eras := {}
	var foreign := {}
	for b in data.buildings:
		var bd := b as Dictionary
		if bool(bd.get("suppressed", false)) or bool(bd.get("landmark", false)):
			continue
		n += 1
		var look := BuildingHeights._look_for(bd, ctx)
		var era := str(look["era"])
		eras[era] = int(eras.get(era, 0)) + 1
		var enriched: Dictionary = bd.get("enriched", {})
		if enriched.has(HelsinkiNotable.PROVENANCE):
			notable += 1
		if (enriched.get(HelsinkiRegister.PROVENANCE, []) as Array).has("material"):
			reg_mat += 1
			var mapped := str(MaterialLibrary.MATERIAL_TAGS.get(str(bd["material"]), ""))
			if FacadeMaterials._wall_set(bd, look, str(ctx["region"])) == mapped:
				reg_mat_set_ok += 1
			# The colour comes from the style's palette: one drawn for a
			# different finish paints the mapped one (Jugend ochre on concrete).
			if str(look["wall_set"]) != mapped and (look["wall_colour"] as Color).a > 0.0:
				reg_mat_foreign_paint += 1
				var k := "%s<-%s" % [mapped, look["wall_set"]]
				foreign[k] = int(foreign.get(k, 0)) + 1
		if (enriched.get(HelsinkiLod2.PROVENANCE, []) as Array).has("roof_shape"):
			lod2_roof += 1
			var drawn := BuildingHeights._effective_shape(str(bd.get("roof_shape", "")), str(look["roof_shape"]), false)
			if drawn == BuildingHeights._effective_shape(str(bd["roof_shape"]), "", false):
				lod2_roof_ok += 1
	print("FABRIC buildings=%d notable=%d" % [n, notable])
	print("FABRIC register_material=%d wall_set_matches=%d foreign_paint=%d %s" % [reg_mat, reg_mat_set_ok,
		reg_mat_foreign_paint, str(foreign)])
	print("FABRIC lod2_roof=%d drawn_as_lod2=%d" % [lod2_roof, lod2_roof_ok])
	var keys := eras.keys()
	keys.sort_custom(func(x, y): return int(eras[x]) > int(eras[y]))
	for k in keys:
		print("FABRIC era %s %d" % [k, eras[k]])
	quit(0)
