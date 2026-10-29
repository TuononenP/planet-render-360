extends SceneTree

## Regional / typological building style: godot --headless --script tests/architecture_test.gd
## Guards that buildings differ by country and kind (and stay stable):
## the region table, kind classification, profile completeness, facade tile
## textures, real-bay wall UVs, roof alignment, infill variety, and the
## per-build material cache reset (an overflow used to fall back to the
## Paris facade for every later city in a session).

const CITIES := {
	"paris": [48.8566, 2.3522, "haussmann"], "london": [51.5074, -0.1278, "west_europe_brick"],
	"dublin": [53.3498, -6.2603, "west_europe_brick"], "amsterdam": [52.3676, 4.9041, "west_europe_brick"],
	"copenhagen": [55.6761, 12.5683, "west_europe_brick"], "berlin": [52.52, 13.405, "central_europe"],
	"vienna": [48.2082, 16.3738, "central_europe"], "prague": [50.0755, 14.4378, "central_europe"],
	"warsaw": [52.2297, 21.0122, "central_europe"], "interlaken": [46.6863, 7.8632, "alpine"],
	"zurich": [47.3769, 8.5417, "alpine"], "innsbruck": [47.2692, 11.4041, "alpine"],
	"helsinki": [60.1699, 24.9384, "nordic"], "turku": [60.4518, 22.2666, "nordic"],
	"stockholm": [59.3293, 18.0686, "nordic"], "oslo": [59.9139, 10.7522, "nordic"],
	"reykjavik": [64.1466, -21.9426, "nordic"], "madrid": [40.4168, -3.7038, "mediterranean"],
	"barcelona": [41.3874, 2.1686, "mediterranean"], "lisbon": [38.7223, -9.1393, "mediterranean"],
	"rome": [41.9028, 12.4964, "mediterranean"], "athens": [37.9838, 23.7275, "mediterranean"],
	"cairo": [30.0444, 31.2357, "middle_east"], "istanbul": [41.0082, 28.9784, "middle_east"],
	"dubai": [25.2048, 55.2708, "middle_east"], "algiers": [36.7538, 3.0588, "middle_east"],
	"tokyo": [35.6762, 139.6503, "japan"], "seoul": [37.5665, 126.978, "east_asia"],
	"shanghai": [31.2304, 121.4737, "east_asia"], "hong_kong": [22.3193, 114.1694, "east_asia"],
	"mumbai": [19.076, 72.8777, "south_asia"], "delhi": [28.6139, 77.209, "south_asia"],
	"bangkok": [13.7563, 100.5018, "southeast_asia"], "singapore": [1.3521, 103.8198, "southeast_asia"],
	"jakarta": [-6.2088, 106.8456, "southeast_asia"], "new_york": [40.7128, -74.006, "north_america"],
	"houston": [29.7604, -95.3698, "north_america"], "los_angeles": [34.0522, -118.2437, "north_america"],
	"toronto": [43.6532, -79.3832, "north_america"], "mexico_city": [19.4326, -99.1332, "latin_america"],
	"rio": [-22.9068, -43.1729, "latin_america"], "buenos_aires": [-34.6037, -58.3816, "latin_america"],
	"sydney": [-33.8688, 151.2093, "australia"], "auckland": [-36.8509, 174.7645, "australia"],
	"moscow": [55.7558, 37.6173, "eastern_europe"], "st_petersburg": [59.9311, 30.3609, "eastern_europe"],
	"kyiv": [50.4501, 30.5234, "eastern_europe"], "tallinn": [59.437, 24.7536, "eastern_europe"],
	"lagos": [6.5244, 3.3792, "sub_saharan_africa"], "nairobi": [-1.2921, 36.8219, "sub_saharan_africa"],
	"cape_town": [-33.9249, 18.4241, "sub_saharan_africa"],
}

const PROFILE_KEYS := ["w", "p", "bay", "fr", "sh", "sp", "r", "pitch", "rf", "fh", "st", "ch", "eq"]
const ROOF_SETS := ["slate", "terracotta", "membrane", "concrete", "wood"]

func _init() -> void:
	_run()

func _flat_data(lat: float, lon: float) -> LocationData:
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.grid_size = 8
	data.heights.resize(64)
	for i in 64:
		data.heights[i] = 3.0
	data.water_level = -3.0
	data.seed_value = 7
	return data

func _rect(cx: float, cz: float, w_m: float, d_m: float, yaw: float) -> PackedVector2Array:
	var m := WorldScale.metres_to_units()
	var ring := PackedVector2Array()
	for k in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		ring.append(Vector2(cx, cz) * m + (k * Vector2(w_m, d_m) * 0.5 * m).rotated(yaw))
	return ring

func _bld(kind: String, cx: float, cz: float, w_m: float, d_m: float, levels: int,
		yaw: float = 0.0, extra: Dictionary = {}) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var b := {"x": cx * m, "z": cz * m, "size_x": w_m * m, "size_z": d_m * m,
		"footprint": _rect(cx, cz, w_m, d_m, yaw), "height": float(levels) * 3.0,
		"height_source": "levels" if levels > 0 else "default", "levels": levels,
		"kind": kind, "use": "", "religion": "", "denomination": "", "colour": "",
		"material": "", "roof_shape": "", "roof_colour": "", "roof_material": "",
		"roof_height_m": 0.0, "parts": [], "name": ""}
	for k in extra:
		b[k] = extra[k]
	return b

func _walls_of(node: Node3D) -> Array:
	var out: Array = []
	for c in node.get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.mesh is ArrayMesh and mi.mesh.get_surface_count() == 1:
			var arr: Array = mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			if verts.size() > 0 and verts.size() % 4 == 0 and uvs.size() == verts.size() \
					and mi.material_override is StandardMaterial3D \
					and (mi.material_override as StandardMaterial3D).albedo_texture != null \
					and not (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty() \
					and (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array)[0].y == 0.0:
				out.append(mi)
	return out

func _run() -> void:
	var failures: Array[String] = []
	_region_checks(failures)
	_kind_checks(failures)
	_profile_checks(failures)
	_resolve_checks(failures)
	_tile_checks(failures)
	_build_checks(failures)
	_infill_checks(failures)
	_cache_checks(failures)
	_authenticity_checks(failures)
	if failures.is_empty():
		print("ARCHITECTURE OK: %d city regions, kinds, %d-region profiles, tiles, UVs, roofs, infill, cache" % [CITIES.size(), ArchitectureData.REGIONS.size()])
		quit(0)
	else:
		for f in failures:
			printerr("ARCHITECTURE FAIL: ", f)
		quit(1)

func _region_checks(failures: Array[String]) -> void:
	for city in CITIES:
		var row: Array = CITIES[city]
		var got := ArchitectureStyle.region_for(float(row[0]), float(row[1]))
		if got != str(row[2]):
			failures.append("%s: region %s, expected %s" % [city, got, row[2]])
	if ArchitectureStyle.region_for(0.0, -140.0) != "generic":
		failures.append("open ocean should fall back to generic")

func _kind_checks(failures: Array[String]) -> void:
	var cases := [
		[{"kind": "house"}, "dense", 200.0, "house"],
		[{"kind": "apartments"}, "rural", 50.0, "apartments"],
		[{"kind": "warehouse"}, "mid", 900.0, "industrial"],
		[{"kind": "church"}, "mid", 300.0, "religious"],
		[{"kind": "yes", "use": "place_of_worship"}, "mid", 300.0, "religious"],
		[{"kind": "yes", "use": "school"}, "mid", 900.0, "civic"],
		[{"kind": "yes", "use": "shop"}, "dense", 200.0, "commercial"],
		[{"kind": "barn"}, "rural", 400.0, "farm"],
		[{"kind": "garage"}, "dense", 20.0, "outbuilding"],
		[{"kind": "yes"}, "dense", 20.0, "outbuilding"],
		[{"kind": "yes", "levels": 7}, "mid", 300.0, "apartments"],
		[{"kind": "yes", "levels": 2}, "mid", 120.0, "house"],
		[{"kind": "yes"}, "dense", 300.0, "apartments"],
		[{"kind": "yes"}, "rural", 400.0, "farm"],
		[{"kind": "yes"}, "mid", 120.0, "house"],
		[{}, "mid", 0.0, "house"],
	]
	for c in cases:
		var got := ArchitectureStyle.kind_for(c[0], str(c[1]), float(c[2]))
		if got != str(c[3]):
			failures.append("kind_for(%s, %s, %s) = %s, expected %s" % [c[0], c[1], c[2], got, c[3]])

func _profile_checks(failures: Array[String]) -> void:
	var regions: Array = ["generic"]
	for box in ArchitectureData.BOXES:
		if not regions.has(box[0]):
			regions.append(box[0])
	for region in regions:
		if region != "generic" and not ArchitectureData.REGIONS.has(region):
			failures.append("region %s has no REGIONS row" % region)
		for kind in ArchitectureStyle.KINDS:
			var p := ArchitectureStyle.profile(str(region), kind)
			for key in PROFILE_KEYS:
				if not p.has(key):
					failures.append("%s/%s missing key %s" % [region, kind, key])
			if failures.size() > 20:
				return
			for w in (p["w"] as Array):
				var set_name := str((w as Array)[0])
				if set_name != "glass" and not MaterialLibrary.PBR_SETS.has(set_name):
					failures.append("%s/%s wall set %s is not a bundled set" % [region, kind, set_name])
				for hex in ((w as Array)[1] as Array):
					if not Color.html_is_valid(str(hex)):
						failures.append("%s/%s bad wall colour %s" % [region, kind, hex])
			for r in (p["rf"] as Array):
				if not ROOF_SETS.has(str((r as Array)[0])):
					failures.append("%s/%s roof set %s unknown" % [region, kind, (r as Array)[0]])
				for hex in ((r as Array)[1] as Array):
					if not Color.html_is_valid(str(hex)):
						failures.append("%s/%s bad roof colour %s" % [region, kind, hex])
			var patterns: Array = []
			if p["p"] is Array:
				for pr in (p["p"] as Array):
					patterns.append(str((pr as Array)[0]))
			else:
				patterns.append(str(p["p"]))
			for pattern in patterns:
				if pattern != "haussmann" and not FacadeComposer.is_tiled(pattern):
					failures.append("%s/%s unknown pattern %s" % [region, kind, pattern])
			if not FacadeComposer.WINDOWS.has(str(p.get("wn", "casement"))):
				failures.append("%s/%s unknown window %s" % [region, kind, p.get("wn")])
			for g in (p.get("g", []) as Array):
				if not ["none", "shop", "signage", "render", "stone"].has(str((g as Array)[0])):
					failures.append("%s/%s unknown ground %s" % [region, kind, (g as Array)[0]])
			for sh in (p["r"] as Array):
				if not ["flat", "gabled", "hipped", "mansard", "pyramidal", "dome"].has(str((sh as Array)[0])):
					failures.append("%s/%s unknown roof shape %s" % [region, kind, (sh as Array)[0]])
			var st: Array = p["st"]
			if int(st[0]) < 1 or int(st[1]) < int(st[0]):
				failures.append("%s/%s bad storey range %s" % [region, kind, st])

func _resolve_checks(failures: Array[String]) -> void:
	var a := ArchitectureStyle.resolve({"kind": "apartments"}, "nordic", "mid", 0.37, 400.0)
	var b := ArchitectureStyle.resolve({"kind": "apartments"}, "nordic", "mid", 0.37, 400.0)
	if a != b:
		failures.append("resolve must be deterministic for a seed")
	var colours := {}
	var shapes := {}
	for i in 60:
		var r := ArchitectureStyle.resolve({"kind": "house"}, "nordic", "mid", float(i) * 0.0173 + 0.01, 120.0)
		colours[(r["wall_colour"] as Color).to_html()] = true
		shapes[r["roof_shape"]] = true
	if colours.size() < 4:
		failures.append("nordic houses should vary in colour, got %d" % colours.size())
	# Real data wins: a tagged material/colour overrides the style wall.
	var tagged := FacadeMaterials.facade_for_building({"material": "brick", "colour": "#aa5533"},
		"nordic", 4, 2, false, 0.5, ArchitectureStyle.resolve({"kind": "house"}, "nordic", "mid", 0.5, 120.0))
	var plain := FacadeMaterials.facade_for_building({}, "nordic", 4, 2, false, 0.5,
		ArchitectureStyle.resolve({"kind": "house"}, "nordic", "mid", 0.5, 120.0))
	if (tagged as StandardMaterial3D).albedo_texture == (plain as StandardMaterial3D).albedo_texture:
		failures.append("building:material=brick must override the Nordic timber wall")
	# Regions read differently: apartments differ in wall/pattern across the world.
	var combos := {}
	for region in ["haussmann", "nordic", "middle_east", "japan", "north_america", "eastern_europe",
			"mediterranean", "west_europe_brick", "sub_saharan_africa", "latin_america"]:
		var r := ArchitectureStyle.resolve({"kind": "apartments"}, region, "mid", 0.4, 600.0)
		combos["%s/%s/%s" % [r["wall_set"], r["pattern"], r["roof_shape"]]] = true
	if combos.size() < 7:
		failures.append("apartment looks should differ across regions, got only %d distinct: %s" % [combos.size(), combos.keys()])
	var tower := ArchitectureStyle.resolve({"kind": "yes", "use": "place_of_worship", "religion": "muslim"},
		"nordic", "mid", 0.3, 300.0)
	if tower["tower"] != "minaret":
		failures.append("religion=muslim must give a minaret, got %s" % tower["tower"])
	var orth := ArchitectureStyle.resolve({"kind": "yes", "use": "place_of_worship",
		"religion": "christian", "denomination": "russian_orthodox"}, "nordic", "mid", 0.3, 300.0)
	if orth["tower"] != "onion":
		failures.append("orthodox church must get onion domes, got %s" % orth["tower"])

func _tile_checks(failures: Array[String]) -> void:
	var look := {"frame": Color(0.9, 0.9, 0.9), "shutter": Color(0.3, 0.4, 0.3), "shutter_p": 0.4, "bay_m": 3.2}
	var loader := Callable(MaterialLibrary, "_set_image")
	for pat in FacadeComposer.TILED:
		var set_name := "glass" if pat == "curtain" else "render"
		for detail in [0, 1]:
			var d := FacadeComposer.compose_tile(set_name, pat, detail, look, loader)
			var alb := (d["albedo"] as Texture2D).get_image()
			if alb.get_width() != FacadeComposer.CELL * FacadeComposer.BAYS or alb.get_height() != FacadeComposer.CELL:
				failures.append("%s tile should be %dx%d, got %s" % [pat, FacadeComposer.CELL * FacadeComposer.BAYS, FacadeComposer.CELL, alb.get_size()])
			if not alb.has_mipmaps():
				failures.append("%s tile needs mipmaps (distance shimmer)" % pat)
			if (detail == 0) != (d["normal"] == null):
				failures.append("%s detail %d: normal map presence wrong" % [pat, detail])

func _build_checks(failures: Array[String]) -> void:
	# Same building, two countries -> different wall textures.
	var textures := {}
	for place in [["helsinki", 60.17, 24.94], ["cairo", 30.04, 31.24], ["paris", 48.8566, 2.3522]]:
		var data := _flat_data(float(place[1]), float(place[2]))
		data.buildings = [_bld("apartments", 0.0, 0.0, 30.0, 14.0, 5)]
		var node := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
		var walls := _walls_of(node)
		var found := false
		# T4.5: with OSM present and no settlement evidence there is no
		# infill any more, so the check reads the real block's own upper
		# facade (the tallest wall mesh at the origin), as its intent says.
		var tallest := 0.0
		for mi in walls:
			var mat := (mi as MeshInstance3D).material_override as StandardMaterial3D
			var bb := (mi as MeshInstance3D).mesh.get_aabb()
			var ctr := bb.get_center()
			if Vector2(ctr.x, ctr.z).length() < 20.0 and bb.size.y > tallest:
				tallest = bb.size.y
				textures[place[0]] = mat.albedo_texture
				found = true
		if not found:
			failures.append("%s: no facade wall found" % place[0])
		node.free()
	var distinct := {}
	for k in textures:
		distinct[textures[k]] = true
	if distinct.size() < 3:
		failures.append("Helsinki/Cairo/Paris apartments must use 3 different facade textures, got %d" % distinct.size())

	# Real-bay UVs: a 15 m edge on a 3.0 m bay is 5 bays = 1.25 tiles; v = storeys.
	var d2 := _flat_data(60.17, 24.94)
	d2.buildings = [_bld("apartments", 0.0, 0.0, 15.0, 15.0, 4)]
	var n2 := BuildingBuilder.build_buildings(d2, GroundTruth.new(d2))
	var uv_ok := false
	for mi in _walls_of(n2):
		var arr: Array = (mi as MeshInstance3D).mesh.surface_get_arrays(0)
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var max_u := 0.0
		var max_v := 0.0
		for uv in uvs:
			max_u = maxf(max_u, uv.x)
			max_v = maxf(max_v, uv.y)
		if absf(max_u - 1.25) < 0.01 and max_v >= 3.0 and max_v <= 5.0:
			uv_ok = true
	if not uv_ok:
		failures.append("tiled walls: 15 m edge should span 1.25 tiles and v should follow storeys")
	n2.free()
	# A sliver wall (a pillar) shows only the blank margin, never a squeezed window row.
	var ring := PackedVector2Array([Vector2(0, 0), Vector2(0.1, 0), Vector2(0.1, 0.1), Vector2(0, 0.1)])
	var holder := Node3D.new()
	var mat := FacadeMaterials.facade_for_building({}, "nordic", 4, 2, false, 0.5,
		ArchitectureStyle.resolve({"kind": "apartments"}, "nordic", "mid", 0.5, 400.0))
	BuildingBuilder._walls(holder, ring, 0.0, 3.0, mat, 4.0)
	var sliver: Array = (holder.get_child(0) as MeshInstance3D).mesh.surface_get_arrays(0)
	var sliver_u := 0.0
	for uv in (sliver[Mesh.ARRAY_TEX_UV] as PackedVector2Array):
		sliver_u = maxf(sliver_u, uv.x)
	if sliver_u > 0.05:
		failures.append("a 0.4 m wall must map the blank margin only, got u=%f" % sliver_u)
	holder.free()

	# Roof ridge follows the footprint's long side, not the world X axis.
	var d3 := _flat_data(51.5, -0.12)
	d3.buildings = [_bld("house", 0.0, 0.0, 20.0, 8.0, 2, 0.5, {"roof_shape": "gabled"})]
	var n3 := BuildingBuilder.build_buildings(d3, GroundTruth.new(d3))
	var ridge: Array[Vector3] = []
	var best_y := -INF
	for c in n3.get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.name != "Detail" and mi.mesh is ArrayMesh and mi.mesh.get_surface_count() == 1:
			var verts: PackedVector3Array = (mi.mesh.surface_get_arrays(0))[Mesh.ARRAY_VERTEX]
			for v in verts:
				if v.y > best_y + 0.001 and absf(v.x) < 24.0 * WorldScale.metres_to_units() and absf(v.z) < 24.0 * WorldScale.metres_to_units():
					best_y = v.y
	for c in n3.get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.name != "Detail" and mi.mesh is ArrayMesh and mi.mesh.get_surface_count() == 1:
			for v in ((mi.mesh.surface_get_arrays(0))[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				if absf(v.y - best_y) < 0.001 and absf(v.x) < 24.0 * WorldScale.metres_to_units() and absf(v.z) < 24.0 * WorldScale.metres_to_units():
					ridge.append(v)
	if ridge.size() < 2:
		failures.append("gabled roof ridge not found")
	else:
		var span := Vector2.ZERO
		for a in ridge:
			for b in ridge:
				if Vector2(a.x - b.x, a.z - b.z).length() > span.length():
					span = Vector2(a.x - b.x, a.z - b.z)
		var want := Vector2(1, 0).rotated(0.5)
		if absf(span.normalized().dot(want)) < 0.98:
			failures.append("ridge should run along the rotated long side, got %s" % span.normalized())
	n3.free()

	# A mosque gets a minaret and dome (a Detail mesh); a Finnish flat block does not.
	var d4 := _flat_data(30.04, 31.24)
	d4.buildings = [_bld("yes", 0.0, 0.0, 16.0, 12.0, 0, 0.0,
		{"use": "place_of_worship", "religion": "muslim", "height_source": "default"})]
	var n4 := BuildingBuilder.build_buildings(d4, GroundTruth.new(d4))
	var detail := n4.find_child("Detail", false, false) as MeshInstance3D
	if detail == null:
		failures.append("a mosque needs its minaret/dome Detail mesh")
	elif detail.mesh.get_surface_count() < 2:
		failures.append("mosque detail should have several material surfaces")
	n4.free()

func _infill_checks(failures: Array[String]) -> void:
	# OSM silent: each region's infill mixes several facades, the regions
	# differ from each other, and no place reuses another place's materials
	# (the per-build cache reset — checked by object identity).
	var mats_by_place := {}
	var sigs_by_place := {}
	for place in [["helsinki", 60.17, 24.94], ["cairo", 30.04, 31.24], ["tokyo", 35.68, 139.65]]:
		var data := _flat_data(float(place[1]), float(place[2]))
		data.quality_preset = 2
		var node := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
		var mats := {}
		var sigs := {}
		for mi in _walls_of(node):
			var mat := (mi as MeshInstance3D).material_override as StandardMaterial3D
			mats[mat] = true
			sigs["%s|%s" % [mat.albedo_color.to_html(), str(mat.get_meta("fc_uv", Vector3.ZERO))]] = true
		if mats.size() < 3:
			failures.append("%s infill should mix >=3 facade materials, got %d" % [place[0], mats.size()])
		mats_by_place[place[0]] = mats
		sigs_by_place[place[0]] = sigs
		node.free()
	var names: Array = mats_by_place.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			for m in (mats_by_place[names[i]] as Dictionary):
				if (mats_by_place[names[j]] as Dictionary).has(m):
					failures.append("per-build cache reset: %s reuses a %s material" % [names[j], names[i]])
					return
			if (sigs_by_place[names[i]] as Dictionary).keys() == (sigs_by_place[names[j]] as Dictionary).keys():
				failures.append("%s and %s infill should not look identical" % [names[i], names[j]])

func _cache_checks(failures: Array[String]) -> void:
	var data := _flat_data(60.17, 24.94)
	data.buildings = [_bld("apartments", 0.0, 0.0, 30.0, 14.0, 5)]
	var node := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
	node.free()
	if int(FacadeMaterials.material_instance_count()["facade_near"]) < 1:
		failures.append("a build should leave facade materials cached")
	FacadeMaterials.begin_build()
	var counts := FacadeMaterials.material_instance_count()
	if int(counts["facade_near"]) != 0 or int(counts["distant_facade"]) != 0:
		failures.append("begin_build must drop per-place facade caches, got %s" % counts)
	# Many places in one session must never saturate into the Paris fallback.
	for i in 12:
		var d := _flat_data(10.0 + float(i) * 4.0, 20.0 + float(i) * 11.0)
		d.buildings = [_bld("apartments", 0.0, 0.0, 30.0, 14.0, 5), _bld("house", 40.0, 0.0, 10.0, 9.0, 2)]
		BuildingBuilder.build_buildings(d, GroundTruth.new(d)).free()
	if int(FacadeMaterials.material_instance_count()["facade_near"]) >= 96:
		failures.append("per-build reset should keep the facade cache far below its cap")

## T4.6 regional authenticity v2, fixture-based (no live fetches): each
## region's street-level signature is distinct, the headline regional
## traits hold (Paris Haussmann, Tokyo signage + light fronts, Nordic
## punched plaster, Alpine chalet base + eaves), a street varies per
## building, no roof is near-black, and the distant budget stays at 6.
func _authenticity_checks(failures: Array[String]) -> void:
	var regions: Array = ["generic"]
	for box in ArchitectureData.BOXES:
		if not regions.has(box[0]):
			regions.append(box[0])
	var sigs := {}
	for region in regions:
		var sig := []
		for kind in ["house", "apartments", "commercial"]:
			var looks := {}
			for i in 24:
				var r := ArchitectureStyle.resolve({"kind": kind}, str(region), "dense", float(i) * 0.041 + 0.013, 400.0)
				looks["%s/%s/%s/%s" % [r["wall_set"], r["pattern"], r["window"], r["ground"]]] = true
			var keys: Array = looks.keys()
			keys.sort()
			sig.append(",".join(keys))
		sigs["|".join(sig)] = region
	if sigs.size() < regions.size():
		failures.append("every region needs its own street signature, %d distinct of %d" % [sigs.size(), regions.size()])
	# Paris: Haussmann fronts with no separate ground band (it is drawn in).
	var pa := ArchitectureStyle.resolve({"kind": "apartments"}, "haussmann", "dense", 0.3, 600.0)
	if pa["pattern"] != "haussmann" or pa["ground"] != "" or float(pa["bay_m"]) > 2.4:
		failures.append("Paris apartments must be Haussmann, ground drawn in, bay <= 2.4 m, got %s" % pa)
	var variants := {}
	for i in 30:
		variants[ArchitectureStyle.resolve({"kind": "apartments"}, "haussmann", "dense", float(i) * 0.031, 600.0)["variant"]] = true
	if variants.size() < 3:
		failures.append("Paris blocks should spread over facade variants, got %d" % variants.size())
	# Tokyo: commercial gets a signage ground floor, fronts never all glass.
	var jp_ground := {}
	var jp_patterns := {}
	for i in 30:
		var r := ArchitectureStyle.resolve({"kind": "commercial"}, "japan", "dense", float(i) * 0.029 + 0.01, 300.0)
		jp_ground[r["ground"]] = true
		jp_patterns[r["pattern"]] = true
	if not jp_ground.has("signage"):
		failures.append("Tokyo commercial needs signage-band ground floors")
	if not jp_patterns.has("tiles") or jp_patterns.size() < 3:
		failures.append("Tokyo commercial should mix tiled, ribbon and curtain fronts, got %s" % jp_patterns.keys())
	# Nordic apartments: mostly punched windows (the ribbon was the stripes).
	var punched := 0
	for i in 40:
		if ArchitectureStyle.resolve({"kind": "apartments"}, "nordic", "mid", float(i) * 0.023 + 0.007, 600.0)["pattern"] == "punched":
			punched += 1
	if punched < 20:
		failures.append("Nordic apartments should be mostly punched, got %d/40" % punched)
	# Alpine chalet: rendered ground storey, timber above, wide eaves.
	var ch := ArchitectureStyle.resolve({"kind": "house"}, "alpine", "mid", 0.4, 120.0)
	if ch["ground"] != "render" or ch["wall_set"] != "wood" or float(ch["eave"]) < 1.0:
		failures.append("Alpine house should be a chalet (render base, wood, eave >= 1 m), got %s" % ch)
	var hotel := ArchitectureStyle.resolve({"kind": "hotel"}, "alpine", "mid", 0.4, 600.0)
	if hotel["window"] != "french" or float(hotel["rails"]) < 0.5:
		failures.append("Alpine hotels should be Belle Epoque (french windows + balconettes), got %s" % hotel)
	# Built: a chalet's roof overhangs its walls; Tokyo shops get a ground band.
	var d1 := _flat_data(46.6863, 7.8632)
	d1.buildings = [_bld("house", 0.0, 0.0, 12.0, 9.0, 2, 0.0, {"roof_shape": "gabled"})]
	var n1 := BuildingBuilder.build_buildings(d1, GroundTruth.new(d1))
	var reach := 0.0
	for c in n1.get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.mesh is ArrayMesh and mi.name != "Detail":
			for v in (mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				if absf(v.x) < 30.0 and absf(v.z) < 30.0:
					reach = maxf(reach, absf(v.z))
	if reach < 9.0 * 0.5 + 1.0 * 0.9:
		failures.append("alpine roof should overhang the 9 m wall by ~1.3 m, reach %.3f units" % reach)
	n1.free()
	var d2 := _flat_data(35.6595, 139.7005)
	d2.buildings = [_bld("commercial", 0.0, 0.0, 20.0, 14.0, 5)]
	var n2 := BuildingBuilder.build_buildings(d2, GroundTruth.new(d2))
	var wall_mats := {}
	for mi in _walls_of(n2):
		var arr: Array = (mi as MeshInstance3D).mesh.surface_get_arrays(0)
		var ys := (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array)
		if absf(ys[0].x) < 16.0 * WorldScale.metres_to_units() and absf(ys[0].z) < 16.0 * WorldScale.metres_to_units():
			wall_mats[(mi as MeshInstance3D).material_override] = true
	if wall_mats.size() < 2:
		failures.append("Tokyo shop block should have a separate signage ground storey, got %d wall materials" % wall_mats.size())
	n2.free()
	# No near-black roofs: style roofs and distant roofs keep the floor.
	for region in regions:
		for kind in ["house", "apartments", "industrial"]:
			for i in 6:
				var look := ArchitectureStyle.resolve({"kind": kind}, str(region), "mid", float(i) * 0.17 + 0.05, 300.0)
				for shape in ["flat", str(look["roof_shape"])]:
					var m := FacadeMaterials.roof_for_building({}, str(region), shape, Color(0, 0, 0, 0), 2, false, 0.3, look) as StandardMaterial3D
					if m != null and _albedo_luma(m) < FacadeMaterials.ROOF_MIN_LUMA * 0.98:
						failures.append("%s/%s %s roof too dark: %.3f" % [region, kind, shape, _albedo_luma(m)])
						return
		FacadeMaterials.begin_build()
		var dist := FacadeMaterials.distant_facades(2, str(region)).size() + FacadeMaterials.distant_roofs(str(region), 2).size()
		if dist > 6:
			failures.append("%s distant materials %d > 6 (PRD §6)" % [region, dist])
	var sat := FacadeMaterials.roof_for_color(Color(0.12, 0.12, 0.13)) as StandardMaterial3D
	if sat != null and _albedo_luma(sat) < FacadeMaterials.ROOF_MIN_LUMA * 0.98:
		failures.append("a shadowed satellite roof sample must not render black: %.3f" % _albedo_luma(sat))

## Mean albedo luminance of a set-based material (set mean x tint).
func _albedo_luma(m: StandardMaterial3D) -> float:
	for set_name in MaterialLibrary.PBR_SETS:
		if m.albedo_texture == MaterialLibrary._set_tex(set_name, "diff"):
			var mean: Color = (MaterialLibrary.PBR_SETS[set_name] as Dictionary)["mean"]
			# albedo_color is sRGB-encoded (source_color); the tint is linear.
			var t := m.albedo_color.srgb_to_linear()
			return 0.2126 * mean.r * t.r + 0.7152 * mean.g * t.g + 0.0722 * mean.b * t.b
	return 1.0
