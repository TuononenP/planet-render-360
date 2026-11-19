extends SceneTree

## Turku landmarks, bridges and architecture tests (offline):
## tools/godot_bg.sh --headless --path . --script tests/turku_landmarks_test.gd

var failures: Array[String] = []

const EXPECTED_TYPES := [
	"turku_cathedral", "turku_castle", "mikaelinkirkko", "martinkirkko",
	"turku_orthodox_church", "turku_art_museum", "vartiovuori_observatory",
	"turku_market_hall", "turku_main_library", "turku_city_theatre",
	"kakola_prison", "vanha_suurtori", "suomen_joutsen", "fori_ferry",
	"samppalinnan_maauimala", "paavo_nurmen_stadion", "turku_kauppatori",
]

const EXPECTED_BRIDGES := [
	"br_turku_tuomiokirkkosilta", "br_turku_kirjastosilta", "br_turku_auransilta",
	"br_turku_teatterisilta", "br_turku_myllysilta", "br_turku_martinsilta",
]

func _init() -> void:
	# 1. All 14 Turku landmarks exist, have non-empty meshes, and sit inside Turku.
	for t in EXPECTED_TYPES:
		var e := LocationData.entry_for_type(t)
		_check(not e.is_empty(), "Registry entry present for %s" % t)
		if e.is_empty():
			continue
		var lat := float(e.get("lat", 0.0))
		var lon := float(e.get("lon", 0.0))
		_check(lat > 60.42 and lat < 60.47 and lon > 22.20 and lon < 22.30,
			"%s coordinates inside Turku: %s, %s" % [t, lat, lon])
		var root := LandmarkBuilder.build(t)
		var meshes := _count_meshes(root)
		_check(meshes > 0, "%s built %d meshes" % [t, meshes])
		root.free()
	# 2. All 6 Aurajoki bridges exist with conf >= 2 and build cleanly.
	for bid in EXPECTED_BRIDGES:
		var row := BridgeSpecs.row_for(bid)
		_check(not row.is_empty(), "BridgeSpec present for %s" % bid)
		if not row.is_empty():
			_check(int(row.get("conf", 0)) >= BridgeSpec.MIN_BUILT_CONF, "%s conf >= 2" % bid)
			var b := LandmarkBuilder.build_bridge(bid, float(row.get("clear", 4.5)))
			_check(_count_meshes(b) > 0, "%s bridge built geometry" % bid)
			b.free()
	# 3. Turku architecture districts & Föli bus livery.
	var z := CityStyles.zone_at(60.4518, 22.2666)
	_check(not z.is_empty() and str(z[0]) == "turku", "Turku centre resolves to city 'turku'")
	var f_ports := CityStyles.local_frame("turku", 60.4480, 22.2480)
	var ports := BuildingEra.refine("turku", "house", {"x": 0.0, "z": 0.0, "levels": 2}, f_ports, 0.5, 140.0)
	_check(ports == "turku_wood", "Port Arthur house resolves to turku_wood (got %s)" % ports)
	var f_ruissalo := CityStyles.local_frame("turku", 60.4290, 22.1500)
	var ruissalo := BuildingEra.refine("turku", "house", {"x": 0.0, "z": 0.0, "levels": 2}, f_ruissalo, 0.5, 180.0)
	_check(ruissalo == "turku_villa", "Ruissalo house resolves to turku_villa (got %s)" % ruissalo)
	_check(TransitVehicles.BUS_PAINT.has("turku"), "Föli bus paint present for turku")
	# 4. Samppalinnan maauimala & Paavo Nurmen Stadion aliases, dimensions, SEAT_META, clearance & terrain cut.
	_check_sports_venues()
	# 5. Turku Kauppatori model, walker breezeway, slope conform & Orthodox church tree keep-out.
	_check_kauppatori()
	if failures.is_empty():
		print("TURKU LANDMARKS OK: %d landmarks, %d bridges, districts & Föli livery" % [
			EXPECTED_TYPES.size(), EXPECTED_BRIDGES.size()])
		quit(0)
	else:
		for msg in failures:
			printerr("TURKU LANDMARKS FAIL: ", msg)
		quit(1)

func _check_sports_venues() -> void:
	var alias_cases := {
		"Samppalinnan maauimala": "samppalinnan_maauimala",
		"Samppis": "samppalinnan_maauimala",
		"Paavo Nurmen stadion": "paavo_nurmen_stadion",
		"Paavo Nurmi Stadium": "paavo_nurmen_stadion",
	}
	for query in alias_cases:
		var got := LocationData.landmark_for(60.444, 22.263, query)
		_check(got == alias_cases[query], "Alias '%s' resolves to %s (got %s)" % [query, alias_cases[query], got])
	_check(LocationData.landmark_for(60.4518, 22.2666, "Turku, Finland") == "turku_cathedral",
		"Turku centre still resolves to turku_cathedral")

	var s_root := LandmarkBuilder.build("samppalinnan_maauimala")
	var s_box := _full_aabb(s_root)
	_check(s_box.end.y >= 10.5 and s_box.end.y <= 13.0,
		"Samppalinna diving tower top 10.5..13.0 m (got %.2f)" % s_box.end.y)
	_check(maxf(s_box.size.x, s_box.size.z) >= 85.0,
		"Samppalinna span >= 85 m (got %.2f x %.2f)" % [s_box.size.x, s_box.size.z])
	_check(_has_seated_child(s_root, "ChildrensPool"), "Samppalinna has SEAT_META ChildrensPool")
	s_root.free()

	var p_root := LandmarkBuilder.build("paavo_nurmen_stadion")
	var p_box := _full_aabb(p_root)
	_check(p_box.end.y >= 19.0 and p_box.end.y <= 21.5,
		"Paavo Nurmi canopy top 19.0..21.5 m (got %.2f)" % p_box.end.y)
	_check(p_box.size.x >= 190.0 and p_box.size.z >= 120.0,
		"Paavo Nurmi span >= 190x120 m (got %.2f x %.2f)" % [p_box.size.x, p_box.size.z])
	for cname in ["WestRearPavilion", "NorthServiceBuilding", "EntranceKiosks"]:
		_check(_has_seated_child(p_root, cname), "Paavo Nurmi has SEAT_META %s" % cname)
	p_root.free()

	# Clearance & Karikon huvila preservation at Paavo Nurmen Stadion.
	var p_entry := LocationData.entry_for_type("paavo_nurmen_stadion")
	var p_lat := float(p_entry["lat"])
	var p_lon := float(p_entry["lon"])
	var clear := LandmarkSites.clear_m(p_entry)
	for osm_pt in [[60.442758, 22.260556, "way 24206308"], [60.442985, 22.260117, "way 777857700"]]:
		var xz := WorldScale.xz_from_latlon(float(osm_pt[0]), float(osm_pt[1]), p_lat, p_lon)
		_check(LandmarkSites.span_dist(xz, Vector2.ZERO, p_entry) < clear,
			"Paavo Nurmi clears %s" % osm_pt[2])
	var karikko := WorldScale.xz_from_latlon(60.443600, 22.261451, p_lat, p_lon)
	_check(LandmarkSites.span_dist(karikko, Vector2.ZERO, p_entry) >= clear
		and not LandmarkSites.in_model_rect(karikko, Vector2.ZERO, p_entry),
		"Karikon huvila preserved outside Paavo Nurmi clearance")

	# Terrain terrace cuts preserve datum at base_at_m while lowering basin/track bumps.
	_check_terrace_cut("samppalinnan_maauimala", Vector2(-38.0, 0.0), Vector2(0.0, 0.0), -1.0)
	_check_terrace_cut("paavo_nurmen_stadion", Vector2(0.0, 0.0), Vector2(30.0, 10.0), 0.0)

func _check_kauppatori() -> void:
	for q in ["Turun kauppatori", "Turku Market Square"]:
		_check(LocationData.landmark_for(60.4517, 22.2669, q) == "turku_kauppatori",
			"Kauppatori alias '%s' resolves to turku_kauppatori" % q)
	var k_root := LandmarkBuilder.build("turku_kauppatori")
	var parts := LandmarkBuilder.parts(k_root)
	_check(parts.size() >= 2 and parts.size() <= 16,
		"Kauppatori parts in 2..16 (got %d)" % parts.size())
	var k_box := _full_aabb(k_root)
	_check(k_box.size.x >= 110.0 and k_box.size.z >= 110.0,
		"Kauppatori span >= 110 m (got %.1f x %.1f)" % [k_box.size.x, k_box.size.z])
	_check(k_box.end.y >= 10.5 and k_box.end.y <= 11.5,
		"Kauppatori mast top 10.5..11.5 m (got %.2f)" % k_box.end.y)
	k_root.free()

	var orth := LocationData.entry_for_type("turku_orthodox_church")
	_check(float(orth.get("tree_clear_m", 99.0)) <= 18.0,
		"Orthodox church tree_clear_m tightened <= 18 m")
	var k_entry := LocationData.entry_for_type("turku_kauppatori")
	var d := LocationData.new()
	d.latitude = float(k_entry["lat"])
	d.longitude = float(k_entry["lon"])
	d.landmark_type = "turku_kauppatori"
	d.has_landmark_site = true
	d.landmark_lat = d.latitude
	d.landmark_lon = d.longitude
	d.landmark_candidates = LandmarkSites.select(d, [])
	var cherry := WorldScale.xz_from_latlon(60.45190, 22.26640, d.latitude, d.longitude)
	_check(not LandmarkSites.tree_cleared(cherry, LandmarkSites.tree_clears(d)),
		"Kauppatori cherry grove not cleared by Orthodox church")

	var solids := ViewWalk._landmark_solids(d)
	var ax := LandmarkSites.axis(k_entry)
	var side := Vector2(-ax.y, ax.x)
	var aura_core := ax * -57.0 + side * -15.7
	var breezeway := ax * -3.3 + side * 58.2
	_check(ViewWalk.blocked(solids, aura_core), "Aurakatu pavilion glass core blocks walkers")
	_check(not ViewWalk.blocked(solids, breezeway), "Eerikinkatu 6.3 m central breezeway is walkable")

func _check_terrace_cut(type: String, base_local: Vector2, probe_local: Vector2, want_rel: float) -> void:
	var entry := LocationData.entry_for_type(type)
	var d := LocationData.new()
	d.latitude = float(entry["lat"])
	d.longitude = float(entry["lon"])
	d.landmark_type = type
	d.has_landmark_site = true
	d.landmark_lat = d.latitude
	d.landmark_lon = d.longitude
	var size := 241
	var step := WorldScale.detailed_extent_units() / float(size - 1)
	var surf := PackedFloat32Array()
	surf.resize(size * size)
	surf.fill(26.0)
	# Put a 2 m mound at probe_local so we confirm the hold lowers bumps while leaving base_local untouched.
	var axis := LandmarkSites.axis(entry)
	var side := Vector2(-axis.y, axis.x)
	var base_w := (axis * base_local.x + side * base_local.y) * WorldScale.metres_to_units()
	var probe_w := (axis * probe_local.x + side * probe_local.y) * WorldScale.metres_to_units()
	var half := float(size) * 0.5
	for z in size:
		for x in size:
			var wp := Vector2((float(x) - half) * step, (float(z) - half) * step)
			if wp.distance_to(probe_w) < 14.0:
				surf[z * size + x] = 28.0
	LandmarkStairCut.cut(surf, size, step, d)
	var base_after := LandmarkStairCut._sample(surf, size, step, base_w)
	var probe_after := LandmarkStairCut._sample(surf, size, step, probe_w)
	_check(absf(base_after - 26.0) < 0.05, "%s cut keeps base_at_m datum untouched (got %.3f)" % [type, base_after])
	_check(probe_after <= 26.0 + want_rel + 0.15,
		"%s cut holds probe <= %.2f (got %.3f)" % [type, 26.0 + want_rel, probe_after])

func _has_seated_child(root: Node3D, child_name: String) -> bool:
	var model := root.get_node_or_null("Model")
	if model == null:
		return false
	var c := model.get_node_or_null(child_name)
	return c != null and bool(c.get_meta(LandmarkTerrain.SEAT_META, false))

func _full_aabb(root: Node3D) -> AABB:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for part in LandmarkBuilder.parts(root):
		var xf := part.transform
		var p := part.get_parent() as Node3D
		while p != null and p != root:
			xf = p.transform * xf
			p = p.get_parent() as Node3D
		var b := xf * part.mesh.get_aabb()
		lo = lo.min(b.position)
		hi = hi.max(b.end)
	return AABB(lo, hi - lo)

func _count_meshes(node: Node) -> int:
	var n := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for c in node.get_children():
		n += _count_meshes(c)
	return n

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
