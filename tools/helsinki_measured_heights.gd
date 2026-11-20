extends SceneTree

## Registry height against the City of Helsinki LoD2 model for every
## registry landmark the LoD2 bundle covers (Helsinki and Espoo). For each
## row it takes the LoD2 buildings whose centroid lies within `clear_m`
## (at most 60 m) of the entry and reports the one nearest the entry, the
## tallest, and the registry height's difference from the tallest. Towers
## on a podium or monuments without a building row read low or empty: check
## those against a published figure (docs/helsinki-landmark-sources.md).
## Run headlessly:
## tools/godot_bg.sh --headless --path . --script tools/helsinki_measured_heights.gd

func _init() -> void:
	print("HEIGHTS type\tmodel_m\tnearest_m\tnearest_d\ttallest_m\tdiff_m\tcount")
	for e in LocationData.landmarks():
		var entry := e as Dictionary
		var lat := float(entry["lat"])
		var lon := float(entry["lon"])
		if lat < 60.10 or lat > 60.32 or lon < 24.60 or lon > 25.25:
			continue
		if str(entry.get("kind", "")) == "Bridge" or bool(entry.get("secondary", false)):
			continue
		var at := Gk25.forward(lat, lon)
		var reach := minf(LandmarkSites.clear_m(entry), 60.0)
		var nearest_h := 0.0
		var nearest_d := INF
		var tallest := 0.0
		var count := 0
		for r in HelsinkiLod2.rows_for(lat, lon):
			var row := r as Array
			var d := Vector2(float(row[1]) - at[0], float(row[2]) - at[1]).length()
			if d > reach:
				continue
			count += 1
			tallest = maxf(tallest, float(row[4]))
			if d < nearest_d:
				nearest_d = d
				nearest_h = float(row[4])
		var model := float(entry.get("height_m", 0.0))
		print("HEIGHTS %s\t%.1f\t%.1f\t%.0f\t%.1f\t%+.1f\t%d" % [entry["type"], model, nearest_h,
			nearest_d if count > 0 else -1.0, tallest, model - tallest if count > 0 else 0.0, count])
	quit(0)
