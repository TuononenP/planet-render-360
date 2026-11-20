extends SceneTree

## Headless: godot --headless --script tests/stockholm_districts_test.gd
## Stockholm's district fabrics (CityStyles.DISTRICTS, BuildingEra's
## Stockholm arm, ArchitectureCitiesWaterfront rows): Klara is post-war
## modernism with flat roofs, Kungsholmen and Södermalm are stone city
## without Östermalm's copper corner domes, Gärdet is funkis, Gamla stan
## has a varied roofscape, Djurgården has villas, Million Programme panel
## only in its real suburbs, falu-red timber only in the cottage
## districts; and the districts carry on into the far fabric.

const ZOOM := 13

func _init() -> void:
	var failures: Array[String] = []
	_era_checks(failures)
	_row_checks(failures)
	_far_checks(failures)
	if failures.is_empty():
		print("STOCKHOLM DISTRICTS OK: district fabrics, narrowed timber and panel rules, far carry-over")
		quit(0)
	else:
		for f in failures:
			printerr("STOCKHOLM DISTRICTS FAIL: ", f)
		quit(1)

## The era for a building at the centre of a local frame at (lat, lon).
func _era(lat: float, lon: float, b: Dictionary, area: float = 400.0, seed_v: float = 0.37) -> String:
	var ctx := CityStyles.local_frame("stockholm", lat, lon)
	var bb := b.duplicate()
	bb["x"] = 0.0
	bb["z"] = 0.0
	var kind := ArchitectureStyle.kind_for(bb, "dense", area)
	return BuildingEra.refine("stockholm", kind, bb, ctx, seed_v, area)

func _era_checks(failures: Array[String]) -> void:
	var apt := {"kind": "apartments"}
	var cases := [
		["Klara commercial", 59.3340, 18.0630, {"kind": "commercial"}, "stockholm_postwar"],
		["Hötorget slab", 59.3345, 18.0635, {"kind": "commercial", "levels": 18}, "stockholm_postwar"],
		["Klara 1890 block", 59.3330, 18.0600, {"kind": "apartments", "start_year": 1890}, "stockholm_stenstad"],
		["Kungsholmen block", 59.3330, 18.0450, apt, "stockholm_stenstad"],
		["Kungsholmen 1905 block", 59.3335, 18.0420, {"kind": "apartments", "start_year": 1905}, "stockholm_stenstad"],
		["Södermalm block", 59.3150, 18.0720, apt, "stockholm_stenstad"],
		["Östermalm block", 59.3380, 18.0850, apt, "stockholm_stone"],
		["Gärdet lamella", 59.3460, 18.0980, apt, "stockholm_funkis"],
		["Gamla stan block", 59.3251, 18.0711, apt, "stockholm_medieval"],
		["Tensta slab", 59.3945, 17.9025, {"kind": "apartments", "levels": 8}, "stockholm_miljon"],
		["Tensta 1970 slab", 59.3945, 17.9025, {"kind": "apartments", "start_year": 1970}, "stockholm_miljon"],
		["Husby slab", 59.4100, 17.9270, {"kind": "apartments", "start_year": 1972}, "stockholm_miljon"],
		["Södermalm 1972 infill", 59.3150, 18.0720, {"kind": "apartments", "start_year": 1972}, "stockholm_postwar"],
		["Kungsholmen 1980 infill", 59.3330, 18.0450, {"kind": "apartments", "start_year": 1980}, "stockholm_postwar"],
		["Södermalm house", 59.3150, 18.0720, {"kind": "house"}, "stockholm_villa"],
		["Södermalm 1880 house", 59.3150, 18.0720, {"kind": "house", "start_year": 1880}, "stockholm_villa"],
		["Mariaberget cottage", 59.3195, 18.0595, {"kind": "house"}, "stockholm_wood"],
		["Vita Bergen cottage", 59.3125, 18.0925, {"kind": "house", "start_year": 1780}, "stockholm_wood"],
		["Vita Bergen untagged cottage", 59.3125, 18.0925, {"kind": "house"}, "stockholm_wood"],
		["Djurgårdsstaden cottage", 59.3222, 18.1025, {"kind": "house"}, "stockholm_wood"],
		["Djurgården villa", 59.3250, 18.1300, {"kind": "house"}, "stockholm_villa"],
		["Djurgården restaurant", 59.3250, 18.1300, {"kind": "commercial", "levels": 2}, "stockholm_villa"],
		["tagged wooden house", 59.3150, 18.0720, {"kind": "house", "architecture": "wooden"}, "stockholm_wood"],
		["tagged Million Programme", 59.3150, 18.0720, {"kind": "apartments", "architecture": "million_programme"}, "stockholm_miljon"],
	]
	for cs in cases:
		var got := _era(float(cs[1]), float(cs[2]), cs[3] as Dictionary)
		if got != str(cs[4]):
			failures.append("%s: expected %s, got %s" % [cs[0], cs[4], got])
	# No seed turns a central house red or a central apartment block into panel.
	for i in 40:
		var s := float(i) * 0.0247 + 0.003
		var h := _era(59.3150, 18.0720, {"kind": "house"}, 120.0, s)
		if h == "stockholm_wood":
			failures.append("a Södermalm house became falu-red timber (seed %.3f)" % s)
			break
		for lat_lon in [[59.3150, 18.0720], [59.3330, 18.0450], [59.3340, 18.0630], [59.3000, 18.0300]]:
			var a := _era(float(lat_lon[0]), float(lat_lon[1]), {"kind": "apartments", "start_year": 1965 + i % 11}, 600.0, s)
			if a == "stockholm_miljon":
				failures.append("a %d block at %s became Million Programme" % [1965 + i % 11, lat_lon])
				return

func _row_checks(failures: Array[String]) -> void:
	for era in ["stockholm_stenstad", "stockholm_postwar", "stockholm_villa", "stockholm_medieval", "stockholm_funkis"]:
		if not ArchitectureStyle.has_region(era):
			failures.append("no %s row" % era)
			return
	# Kungsholmen / Södermalm stone city: no corner domes; Östermalm keeps them.
	for kind in ["apartments", "commercial"]:
		var rv: Dictionary = ArchitectureStyle.profile("stockholm_stenstad", kind).get("rv", {})
		if float(rv.get("corner_dome", 0.0)) > 0.0:
			failures.append("stone city %s must not carry corner domes" % kind)
	if float((ArchitectureStyle.profile("stockholm_stone", "apartments").get("rv", {}) as Dictionary).get("corner_dome", 0.0)) <= 0.0:
		failures.append("Östermalm stone should keep its copper corner domes")
	# Klara: glass-and-stone commercial slabs, flat roofs.
	var klara := ArchitectureStyle.profile("stockholm_postwar", "commercial")
	if _shapes(klara) != ["flat"]:
		failures.append("Klara commercial roofs should be flat, got %s" % [_shapes(klara)])
	var walls := (klara["w"] as Array).map(func(w: Array) -> String: return str(w[0]))
	if not walls.has("glass") or not walls.has("stone"):
		failures.append("Klara commercial walls should be glass and stone, got %s" % [walls])
	# Gärdet funkis: pale render, mostly flat roofs.
	var funkis := ArchitectureStyle.profile("stockholm_funkis", "apartments")
	if not _shapes(funkis).has("flat"):
		failures.append("funkis lamellas need flat roofs")
	# Gamla stan: dormers, chimneys, several ridge forms, black and red metal.
	var med := ArchitectureStyle.profile("stockholm_medieval", "apartments")
	if float(med.get("dm", 0.0)) < 0.3 or float(med.get("ch", 0.0)) < 0.5:
		failures.append("Gamla stan needs dormers and chimneys, got dm=%s ch=%s" % [med.get("dm"), med.get("ch")])
	if _shapes(med).size() < 3:
		failures.append("Gamla stan needs varied ridges, got %s" % [_shapes(med)])
	var tints: Array = ((med["rf"] as Array)[0] as Array)[1]
	var dark := false
	var red := false
	for t in tints:
		var c := Color.html(str(t))
		dark = dark or c.get_luminance() < 0.2
		red = red or (c.r > c.g * 1.6 and c.r > 0.4)
	if str(((med["rf"] as Array)[0] as Array)[0]) != "sheet_metal" or not dark or not red:
		failures.append("Gamla stan roofs should be black and red-painted sheet metal, got %s" % [med["rf"]])
	# Villas are not falu red by default.
	var villa := ArchitectureStyle.profile("stockholm_villa", "house")
	for w in (villa["w"] as Array):
		var reds := 0
		for t in ((w as Array)[1] as Array):
			var c := Color.html(str(t))
			if c.r > c.g * 1.6:
				reds += 1
		if reds > 0:
			failures.append("villa %s palette carries falu red" % (w as Array)[0])

func _shapes(prof: Dictionary) -> Array:
	return (prof["r"] as Array).map(func(r: Array) -> String: return str(r[0]))

## Districts reach the far field: from Gamla stan the far list holds the
## Million Programme suburbs, and the far fabric draws a district's own
## facade set where one lies in the built-up ring.
func _far_checks(failures: Array[String]) -> void:
	var far := CityStyles.far_districts("stockholm", 59.3251, 18.0711, SettlementMap.RADIUS_M)
	var eras := {}
	for fd in far:
		eras[str(fd[0])] = true
	for need in ["stockholm_miljon", "stockholm_stenstad", "stockholm_postwar", "stockholm_villa", "stockholm_funkis"]:
		if not eras.has(need):
			failures.append("far districts from Gamla stan miss %s" % need)
	for i in range(1, far.size()):
		if float(far[i][2]) < float(far[i - 1][2]):
			failures.append("far districts must run most local first")
			break
	if not CityStyles.far_districts("haussmann", 48.8566, 2.3522, SettlementMap.RADIUS_M).is_empty():
		failures.append("Paris must keep its one far profile")
	for native in [false, true]:
		if native and not FarCityBuilder._native:
			continue
		var data := _data()
		var mats := _far_materials(data, SettlementMap.build(data), native)
		if mats.is_empty():
			failures.append("far fabric (native=%s) built nothing" % native)
			continue
		for era in ["stockholm_stenstad", "stockholm_funkis"]:
			var hit := false
			for m in FacadeMaterials.distant_facades(MaterialLibrary.fidelity_for_preset(data.quality_preset), era):
				hit = hit or mats.has(m)
			if not hit:
				failures.append("far fabric (native=%s) never used the %s facades" % [native, era])
		var city := false
		for m in FacadeMaterials.distant_facades(MaterialLibrary.fidelity_for_preset(data.quality_preset), "stockholm"):
			city = city or mats.has(m)
		if not city:
			failures.append("far fabric (native=%s) lost the city facades outside the districts" % native)

## A Gamla stan viewpoint over a synthetic far drape whose west half is a
## busy roofscape (Kungsholmen and Fredhäll lie there), the rest field.
func _data() -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, 2)
	data.latitude = 59.3251
	data.longitude = 18.0711
	data.seed_value = 5
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.far_grid_size = 16
	data.far_heights.resize(16 * 16)
	data.far_heights.fill(3.0)
	var origin := FarSurface.global_px(data, -6500.0, -6500.0, ZOOM)
	var far_c := FarSurface.global_px(data, 6500.0, 6500.0, ZOOM)
	var size := Vector2i(int(far_c.x - origin.x), int(far_c.y - origin.y))
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	var west_px := FarSurface.global_px(data, -800.0, 0.0, ZOOM).x - origin.x
	for y in size.y:
		for x in size.x:
			var c := Color(0.5, 0.48, 0.42)
			if float(x) < west_px:
				var v := 0.22 + 0.4 * fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)
				c = Color(v, v, v * 0.97)
			img.set_pixel(x, y, c)
	data.far_drapes = [{"zoom": ZOOM, "origin_px": origin, "size_px": size,
		"texture": null, "image": img, "reach_m": 9500.0}]
	return data

func _far_materials(data: LocationData, smap: SettlementMap, native: bool) -> Dictionary:
	var was := FarCityBuilder._native
	FarCityBuilder._native = native and was
	var root := Node3D.new()
	FarCityBuilder.build(root, data, GroundTruth.new(data), smap)
	FarCityBuilder._native = was
	var out := {}
	for n in root.get_children():
		if n is MeshInstance3D and (n as MeshInstance3D).material_override != null:
			out[(n as MeshInstance3D).material_override] = true
	root.free()
	return out
