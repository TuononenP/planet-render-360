extends SceneTree

## Headless: godot --headless --script tests/stockholm_transit_test.gd
## Stockholm's rail and street kit: the above-ground tunnelbana stands
## SL's blue C20 units (Helsinki's metro stays orange), Tvärbanan runs
## blue light-rail cars and Djurgårdslinjen a vintage car, a mapped subway
## entrance gets the blue T sign in Sweden and nothing in Paris, and the
## tree mix has oak on Djurgården and limes in Kungsträdgården and
## Humlegården (and nowhere else in the city).

func _init() -> void:
	_run()

func _rail(tags: Dictionary) -> Dictionary:
	return OsmTags._rail_entry(tags, PackedVector2Array([Vector2.ZERO, Vector2(10, 0)]))

func _share(rows: Array, species: String) -> float:
	var total := 0.0
	var own := 0.0
	for r: Array in rows:
		total += float(r[1])
		if str(r[0]) == species:
			own += float(r[1])
	return own / maxf(total, 0.001)

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	# Tunnelbana: open subway track runs blue C20 units, tunnelled track none.
	var subway := _rail({"railway": "subway"})
	var tunnel := _rail({"railway": "subway", "tunnel": "yes"})
	var sto := TrainSpecs.pick("stockholm", "SE", subway, 0.5)
	if str(sto.get("kind", "")) != "metro" or str(sto.get("livery", "")) != "stockholm_metro":
		failures.append("Stockholm's surface subway should run the blue metro unit: %s" % sto)
	var blue := TrainSpecs.livery("stockholm_metro")
	var lower: Color = blue["lower"]
	if lower.b < lower.r + 0.3 or absf(float(blue["gauge"]) - 1.435) > 0.001:
		failures.append("the C20 livery should be blue on standard gauge: %s" % blue)
	var hel := TrainSpecs.pick("helsinki", "FI", subway, 0.5)
	if str(hel.get("livery", "")) != "helsinki_metro" or TrainSpecs.livery("helsinki_metro")["lower"] != TrainSpecs.METRO_ORANGE:
		failures.append("Helsinki's metro should stay orange: %s" % hel)
	if not TrainSpecs.pick("stockholm", "SE", tunnel, 0.5).is_empty() or not TrainSpecs.pick("", "SE", subway, 0.5).is_empty():
		failures.append("no train stands on Stockholm's tunnel track or on a subway in an unknown region")
	# Trams: Tvärbanan (light rail) and Lidingöbanan (tram) are blue, the
	# Djurgården corridor's tram a vintage car, other cities unchanged.
	var tvar := _rail({"railway": "light_rail", "gauge": "1435"})
	var street := _rail({"railway": "tram"})
	var inland := Vector2(59.2950, 17.9900)
	var djur := Vector2(59.3262, 18.0980)
	var pick := TramSpecs.pick("stockholm", "SE", tvar, 0.5, inland)
	if str(pick.get("kind", "")) != "modern5" or str(pick.get("livery", "")) != "stockholm":
		failures.append("Tvärbanan should run the blue SL light-rail car: %s" % pick)
	if TramSpecs.pick("stockholm", "SE", street, 0.5, inland) != pick or TramSpecs.pick("stockholm", "SE", street, 0.5) != pick:
		failures.append("Lidingöbanan and an unlocated tram run the same blue car")
	var sl_blue: Color = TramSpecs.livery("stockholm")["lower"]
	if sl_blue.b < sl_blue.r + 0.3:
		failures.append("the SL tram livery should be blue")
	var heritage := TramSpecs.pick("stockholm", "SE", street, 0.5, djur)
	if str(heritage.get("kind", "")) != "heritage" or str(heritage.get("livery", "")) != "stockholm_heritage":
		failures.append("Djurgårdslinjen should run the vintage car: %s" % heritage)
	if str(TramSpecs.pick("stockholm", "SE", tvar, 0.5, djur).get("kind", "")) != "modern5":
		failures.append("light rail on Djurgården is not the vintage line")
	if not TramSpecs.livery("stockholm_heritage").has("lower") or TramSpecs.pick("lisbon", "PT", street, 0.5, djur).get("livery", "") == "stockholm_heritage" \
			or not TramSpecs.pick("", "DE", tvar, 0.5).is_empty() or TramSpecs.pick("helsinki", "FI", street, 0.1, djur).get("kind", "") != "nr2":
		failures.append("other cities keep their trams, and light rail is no tram outside Stockholm and San Francisco")
	# The T sign at a subway entrance: Sweden yes, Paris no (no NYC stairwell either).
	var family := StreetFurniture.furniture_family("stockholm", "SE", "stockholm")
	if not StreetFurniture.shows_entrances(family) or StreetFurniture.mesh_key("subway_entrance", family) != "t_sign":
		failures.append("a Swedish subway entrance should be the T sign: %s / %s" % [family, StreetFurniture.mesh_key("subway_entrance", family)])
	var paris := StreetFurniture.furniture_family("france", "FR", "paris")
	if StreetFurniture.shows_entrances(paris) or StreetFurniture.shows_entrances("nordic") or not StreetFurniture.shows_entrances("nyc") \
			or StreetFurniture.mesh_key("subway_entrance", "nyc") != "subway_entrance":
		failures.append("Paris and Helsinki draw no entrance; New York keeps its stairwell")
	var m := WorldScale.metres_to_units()
	var d := LocationData.new()
	d.roads = [{"class": "primary", "width_m": 10.0, "points": PackedVector2Array([Vector2(-200, 0), Vector2(0, 0), Vector2(200, 0)])}]
	var roads := StreetFurniture.RoadIndex.new(d, m, 400.0 * m)
	var spot := StreetFurniture.spots({"x": 50.0 * m, "z": 6.0 * m, "kind": "subway_entrance"}, roads, family, m)
	if spot.size() != 1 or str(spot[0][2]) != "t_sign":
		failures.append("a mapped entrance should place one T sign: %s" % [spot])
	var mesh := StreetFurniture.mesh("t_sign")
	var top := 0.0
	var has_blue := false
	for s in mesh.get_surface_count():
		for v: Vector3 in mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			top = maxf(top, v.y)
		var mat := mesh.surface_get_material(s) as StandardMaterial3D
		has_blue = has_blue or (mat != null and mat.albedo_color.b > mat.albedo_color.r + 0.3)
	if mesh.get_surface_count() < 2 or top < 2.5 or top > 3.2 or not has_blue:
		failures.append("the T sign should be a blue plate on a pole of about 3 m: %d surfaces, top %s, blue %s" % [mesh.get_surface_count(), top, has_blue])
	# Tree mix: oak on Djurgården, limes in the two parks, the generic mix elsewhere.
	var zone := HeritageZones.rule_at(59.3262, 18.1100)
	var park := TreeSpecies.mix(str(zone.get("tree_mix", "")), "park")
	if str(zone.get("tree_mix", "")) != "stockholm_park" or _share(park, "oak") < 0.3 or _share(TreeSpecies.mix("boreal", "park"), "oak") > 0.0:
		failures.append("Djurgården's park mix should carry oak the boreal mix lacks: %s" % [park])
	for at in [Vector2(59.3312, 18.0714), Vector2(59.3375, 18.0745)]:
		var avenue := HeritageZones.rule_at(at.x, at.y)
		if str(avenue.get("tree_mix", "")) != "lime_avenue" or _share(TreeSpecies.mix("lime_avenue", "park"), "lime") < 0.6:
			failures.append("%s should be a lime avenue: %s" % [at, avenue])
	if not HeritageZones.rule_at(59.3293, 18.0686 + 0.02).is_empty() or not HeritageZones.rule_at(59.3000, 18.0000).is_empty():
		failures.append("the rest of Stockholm keeps the generic mix")
	if not HeritageZones.is_trees_only(zone):
		failures.append("Djurgården's zone must not touch footprints or cut glades")
	for sp: String in ["oak", "lime", "zelkova"]:
		if not TreeSpecies.SPECIES.has(sp):
			failures.append("%s is not a modelled species" % sp)
	_tram_line_checks(failures)
	failures.remove_at(0)
	if failures.is_empty():
		print("STOCKHOLM TRANSIT OK: blue C20 metro, SL and Djurgården trams, T sign, oak and lime mix")
	else:
		for f in failures:
			printerr("STOCKHOLM TRANSIT FAIL: ", f)
	quit(0 if failures.is_empty() else 1)

## A flat Ultra world centred on `at` (lat, lon).
func _world(at: Vector2, country: String) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.ULTRA)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.country = country
	d.latitude = at.x
	d.longitude = at.y
	return d

## Djurgårdslinjen's track is added where the snapshot maps none (StockholmTram):
## two embedded, electrified tram ways (RailBuilder lays them and OverheadWires
## hangs their wire), a vintage tram on Strandvägen, none in Paris, none added
## where the map carries the line itself, none on Djurgårdsbron.
func _tram_line_checks(failures: Array[String]) -> void:
	var m := WorldScale.metres_to_units()
	var d := _world(Vector2(59.3315, 18.0850), "SE")
	var g := GroundTruth.new(d)
	StockholmTram.complete(d)
	if d.railways.size() != 4 or str(d.railways[0]["class"]) != "tram" or str(d.railways[0]["electrified"]) != "contact_line" \
			or not bool(d.railways[0]["embedded"]):
		failures.append("Djurgårdslinjen should add two tracks of two embedded electrified tram ways, got %d" % d.railways.size())
	var routes := TramRoute.chains(d, g, m, func(rail: Dictionary) -> bool: return TramSpecs.carries("stockholm", rail))
	if routes.size() != 4 or routes[0].length_m < 1000.0:
		failures.append("the added track should give a west and an east route a track over Strandvägen, got %d" % routes.size())
	# Each track has a twin about 3 m beside it, centre to centre, along its length.
	for r in routes:
		for frac in [0.25, 0.5, 0.75]:
			var at := r.xz_at(r.length_m * float(frac))
			var nearest := INF
			for other in routes:
				if other == r:
					continue
				for k in other.points.size() - 1:
					nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(at, other.points[k], other.points[k + 1]).distance_to(at))
			if absf(nearest - 3.0 * m) > 0.8 * m:
				failures.append("a track's twin should lie 3 m beside it, found %.1f m" % (nearest / m))
				break
	var trams := TransitVehicles.plan(d, g, m)
	var heritage := 0
	for t: Dictionary in trams:
		heritage += 1 if str(t["kind"]) == "heritage" else 0
	var tracks := {}
	for t: Dictionary in trams:
		tracks[t["route"]] = true
	if tracks.size() < 2:
		failures.append("trams should run on both tracks, got %d track(s) used" % tracks.size())
	if heritage < 1:
		failures.append("a vintage tram should stand on Strandvägen, got %d of %d trams" % [heritage, trams.size()])
	# The wire is hung on it (OverheadWires reads contact_line track).
	var wired := false
	for r: Dictionary in d.railways:
		wired = wired or str(r.get("electrified", "")) == "contact_line"
	if not wired:
		failures.append("the added track should be electrified")
	# RailBuilder lays the added track flush in the street, OverheadWires hangs its wire.
	var rails := Node3D.new()
	RailBuilder.build(rails, d, g)
	if rails.get_child_count() < 1:
		failures.append("the added track should be laid as rails, got %d rail meshes" % rails.get_child_count())
	rails.free()
	if RenderQuality.ultra_desktop(d.quality_preset) and OverheadWires.plan(d, g).is_empty():
		failures.append("the added track should carry contact wire and poles")
	# A map's own track on the corridor takes over.
	var own := _world(Vector2(59.3315, 18.0850), "SE")
	own.railways = [OsmTags._rail_entry({"railway": "tram"}, PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]))]
	StockholmTram.complete(own)
	if own.railways.size() != 1:
		failures.append("a mapped tram way on the corridor should keep its own line")
	# Another city gets none, and the line stops short of the bridge.
	var paris := _world(Vector2(48.8566, 2.3522), "FR")
	StockholmTram.complete(paris)
	if not paris.railways.is_empty():
		failures.append("Paris gets no Djurgårdslinjen")
	var bridge := WorldScale.xz_from_latlon(59.3310, 18.0937, 59.3315, 18.0850) * m
	for r: Dictionary in d.railways:
		for p: Vector2 in r["points"]:
			if p.distance_to(bridge) < 40.0 * m:
				failures.append("no track on Djurgårdsbron's deck")
				return
