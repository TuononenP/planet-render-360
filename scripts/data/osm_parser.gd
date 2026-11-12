class_name OsmParser
extends RefCounted

## Overpass JSON -> LocationData feature arrays. Owns parse_features
## (element dispatch + dedup), building:part nesting, payload merge
## and the v1 roads shim. Tag/geometry rules live in OsmTags/OsmGeometry.
## Spacing of the trees placed along a natural=tree_row way (metres).
const TREE_ROW_M := 8.0

## Street furniture kind of a node ("" when it is none): bench, bin,
## bollard, signals or bus_stop (StreetFurniture).
static func furniture_kind(tags: Dictionary) -> String:
	match str(tags.get("amenity", "")):
		"bench": return "bench"
		"waste_basket": return "bin"
	match str(tags.get("highway", "")):
		"traffic_signals": return "signals"
		"bus_stop": return "bus_stop"
	if str(tags.get("railway", "")) == "subway_entrance":
		return "subway_entrance"
	if str(tags.get("barrier", "")) == "bollard":
		return "bollard"
	return ""

static func parse_features(text: String, c_lat: float, c_lon: float) -> Dictionary:
	var buildings: Array = []
	var roads: Array = []
	var land: Array = []
	var landmarks: Array = []
	var waterways: Array = []
	var trees: Array = []
	var barriers: Array = []
	var railways: Array = []
	var furniture: Array = []
	var tram_stops: Array = []
	var bus_stops: Array = []
	var rail_platforms: Array = []
	var rail_stations: Array = []
	var pois: Array = []
	var piers: Array = []
	var shore_structures: Array = []
	var bridge_areas: Array = []
	var country := ""
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"buildings": buildings, "roads": roads, "land": land,
			"landmarks": landmarks, "waterways": waterways, "trees": trees,
			"barriers": barriers, "country": country, "railways": railways,
			"furniture": furniture, "pois": pois, "piers": piers, "shore_structures": shore_structures,
			"tram_stops": tram_stops, "bus_stops": bus_stops,
			"rail_platforms": rail_platforms, "rail_stations": rail_stations, "bridge_areas": bridge_areas}
	# Tiered statements print some elements twice (measured: 23 dupes in
	# a Paris 800 m response); first occurrence wins.
	var seen := {}
	var part_ways: Array = []
	for el in parsed.get("elements", []):
		if not (el is Dictionary):
			continue
		if el.has("id"):
			var key := str(el.get("type", "")) + ":" + str(el["id"])
			if seen.has(key):
				continue
			seen[key] = true
		var raw_tags: Variant = el.get("tags", {})
		var el_tags: Dictionary = raw_tags if raw_tags is Dictionary else {}
		var source_id := "%s:%d" % [el.get("type", "way"), int(el.get("id", 0))]
		var source_starts := [buildings.size(), roads.size(), land.size()]
		var shore_kind := str(el_tags.get("man_made", ""))
		if shore_kind != "quay" and str(el_tags.get("barrier", "")) == "retaining_wall":
			shore_kind = "retaining_wall"
		if shore_kind != "quay" and shore_kind != "retaining_wall" and str(el_tags.get("embankment", "")) == "yes":
			shore_kind = "embankment"
		if shore_kind in ["quay", "retaining_wall", "embankment"] and el.has("geometry"):
			var shore_points := PackedVector2Array()
			for node in el["geometry"]:
				if node is Dictionary and node.has("lat") and node.has("lon"):
					shore_points.append(WorldScale.xz_from_latlon(float(node["lat"]), float(node["lon"]), c_lat, c_lon))
			if shore_points.size() >= 2:
				shore_structures.append({"points": shore_points, "kind": shore_kind,
					"id": "%s:%d" % [el.get("type", "way"), int(el.get("id", 0))],
					"material": str(el_tags.get("material", el_tags.get("surface", ""))),
					"height_m": OsmTags._tag_metres(el_tags.get("height", ""), 0.1, 30.0)})
		if (el_tags.has("building") or el_tags.has("building:part")) and OsmTags.underground(el_tags):
			continue
		# Construction footprints can carry the planned final height. Treating
		# that as an existing tower invents a skyline years before completion.
		if str(el_tags.get("building", "")) == "construction" or str(el_tags.get("building:part", "")) == "construction":
			continue
		# The is_in country area: tags only, no geometry.
		if str(el.get("type", "")) == "area":
			if country == "":
				country = str(el_tags.get("ISO3166-1", el_tags.get("ISO3166-1:alpha2", ""))).to_upper()
			continue
		# Point features (lighthouses, towers are often single nodes).
		if str(el.get("type", "")) == "node" and el.has("lat") and el.has("lon"):
			for category in ["shop", "amenity", "office", "tourism", "craft", "advertising"]:
				if el_tags.has(category):
					var pt := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
					pois.append({"x": pt.x, "z": pt.y, "category": category,
						"kind": str(el_tags[category]), "name": str(el_tags.get("name", "")),
						"brand": str(el_tags.get("brand", ""))})
					break
			var node_arch := OsmTags.archetype_for(el_tags)
			if node_arch != "":
				var np := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				landmarks.append({
					"x": np.x, "z": np.y, "archetype": node_arch,
					"name": str(el_tags.get("name", "")),
					"wikipedia": OsmTags.wiki_tag(el_tags),
					"height": float(str(el_tags.get("height", "30")).replace("m", "")),
					"size_x": 8.0, "size_z": 8.0})
			if str(el_tags.get("natural", "")) == "tree":
				var tp := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				var tree := {"x": tp.x, "z": tp.y}
				tree.merge(OsmTags.tree_tags(el_tags))
				trees.append(tree)
			var fk := furniture_kind(el_tags)
			if fk != "":
				var fp := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				furniture.append({"x": fp.x, "z": fp.y, "kind": fk,
					"shelter": str(el_tags.get("shelter", "")) == "yes"})
			var stop := OsmTags.stop_kind(el_tags)
			if stop != "":
				var sp := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				(tram_stops if stop == "tram" else bus_stops).append({"x": sp.x, "z": sp.y,
					"name": str(el_tags.get("name", ""))})
			if OsmTags.rail_station(el_tags):
				var rp := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				rail_stations.append({"x": rp.x, "z": rp.y, "name": str(el_tags.get("name", ""))})
			continue
		# Multipolygon relations (fetched via the nwr land/water
		# statements): stitched outer rings with inner-ring holes.
		# Boundary/route relations are not areas and are skipped.
		if str(el.get("type", "")) == "relation":
			if str(el_tags.get("man_made", "")) == "bridge" and el.has("members"):
				for r in OsmGeometry._relation_rings(el.get("members", []), c_lat, c_lon):
					_bridge_area(bridge_areas, el_tags, r["outer"], source_id)
			elif str(el_tags.get("type", "")) == "multipolygon" \
					and el.has("members") and (OsmApiFallback.names_building(el_tags) or (el_tags.has("defensive_works") and not el_tags.has("building:part"))):
				_relation_buildings(el_tags, el.get("members", []), c_lat, c_lon,
					buildings, landmarks)
			elif str(el_tags.get("type", "")) == "multipolygon" \
					and el.has("members") and str(el_tags.get("building:part", "no")) != "no":
				# A part with holes (a cloister court, a ring of chapels):
				# each outer nests like a part way, carrying its inners.
				for r in OsmGeometry._relation_rings(el.get("members", []), c_lat, c_lon):
					var pr: PackedVector2Array = r["outer"]
					part_ways.append({"tags": el_tags, "points": pr, "osm_id": source_id,
						"aabb": OsmGeometry._ring_aabb(pr), "holes": r["holes"]})
			elif str(el_tags.get("type", "")) == "multipolygon" \
					and el.has("members") and OsmTags.paved_area_class(el_tags, true) != "":
				# A square mapped with holes (a statue plinth, a fountain).
				var area_cls := OsmTags.paved_area_class(el_tags, true)
				for r in OsmGeometry._relation_rings(el.get("members", []), c_lat, c_lon):
					roads.append(OsmTags._area_entry(el_tags, area_cls, r["outer"], r["holes"]))
			elif str(el_tags.get("type", "")) == "multipolygon" \
					and el.has("members"):
				var members: Array = el.get("members", [])
				for entry in OsmGeometry._relation_land(el_tags, members, c_lat, c_lon):
					if str(entry["class"]) == "water":
						entry["tidal"] = OsmTags.tidal(el_tags)
						entry["still_pool"] = OsmTags.still_pool(el_tags)
					if str(entry["class"]) == "forest":
						(entry as Dictionary).merge(OsmTags.tree_tags(el_tags))
					land.append(entry)
				var rel_arch := OsmTags.archetype_for(el_tags)
				if rel_arch != "":
					var outs := OsmGeometry._join_rings(
						OsmGeometry._member_segments(members, true, c_lat, c_lon))
					if not outs.is_empty():
						var box := OsmGeometry._ring_aabb(outs[0])
						landmarks.append({
							"x": box.get_center().x, "z": box.get_center().y,
							"archetype": rel_arch,
							"name": str(el_tags.get("name", "")),
							"wikipedia": OsmTags.wiki_tag(el_tags),
							"height": 30.0,
							"size_x": clampf(box.size.x, 6.0, 240.0),
							"size_z": clampf(box.size.y, 6.0, 240.0)})
			_stamp_sources([buildings, roads, land], source_starts, source_id)
			continue
		if not el.has("geometry"):
			continue
		var geom: Array = el.get("geometry", [])
		if geom.size() < 2:
			continue
		var pts: Array[Vector2] = []
		var min_x := INF
		var max_x := -INF
		var min_z := INF
		var max_z := -INF
		for node in geom:
			# Overpass emits null for way nodes clipped out of the query
			# area; skipping them (as OsmGeometry does) keeps one clipped
			# way from discarding the whole response.
			if not (node is Dictionary):
				continue
			var p := WorldScale.xz_from_latlon(float(node.get("lat", c_lat)),
				float(node.get("lon", c_lon)), c_lat, c_lon)
			pts.append(p)
			min_x = minf(min_x, p.x)
			max_x = maxf(max_x, p.x)
			min_z = minf(min_z, p.y)
			max_z = maxf(max_z, p.y)
		var poly := PackedVector2Array(pts)
		var aabb := Rect2(min_x, min_z, max_x - min_x, max_z - min_z)
		# A platform is noted for StationTrains whatever else it is drawn as.
		if OsmTags.rail_platform(el_tags):
			rail_platforms.append({"points": poly})
		if OsmApiFallback.names_building(el_tags):
			var entry := OsmTags._building_entry(el_tags, poly, aabb)
			buildings.append(entry)
			var arch := OsmTags.archetype_for(el_tags)
			if arch != "":
				var lmk := {
					"x": entry["x"], "z": entry["z"], "archetype": arch,
					"name": str(el_tags.get("name", "")),
					"wikipedia": OsmTags.wiki_tag(el_tags),
					"height": entry["height"],
					"size_x": entry["size_x"], "size_z": entry["size_z"]}
				_framed_landmark(lmk, poly, entry["height_source"] != "default")
				landmarks.append(lmk)
		elif str(el_tags.get("building:part", "no")) != "no":
			part_ways.append({"tags": el_tags, "points": poly, "aabb": aabb, "osm_id": source_id})
		elif el_tags.has("highway"):
			# A closed highway area (a square) is filled, not outlined.
			var sq := OsmTags.paved_area_class(el_tags)
			if OsmTags.buried_highway(el_tags):
				pass  # A road tunnel, metro passage or indoor corridor.
			elif OsmTags.unbuilt_highway(el_tags):
				pass  # A proposed or demolished road: nothing stands there.
			elif sq != "" and OsmTags._tag_truthy(el_tags.get("bridge", "")):
				pass  # A deck area: the bridge's own ways (or its model) carry it, not the ground.
			elif sq != "" and OsmGeometry._is_closed(poly) and poly.size() >= 4:
				roads.append(OsmTags._area_entry(el_tags, sq, poly, []))
			elif sq == "" or not OsmGeometry._is_closed(poly):
				roads.append(OsmTags._road_entry(el_tags, poly))
		elif OsmTags.rail_class(el_tags) != "":
			railways.append(OsmTags._rail_entry(el_tags, poly))
		elif OsmTags.paved_area_class(el_tags) != "" and OsmTags.land_class(el_tags) == "" \
				and OsmGeometry._is_closed(poly) and poly.size() >= 4:
			roads.append(OsmTags._area_entry(el_tags,
				OsmTags.paved_area_class(el_tags), poly, []))
		elif el_tags.has("waterway"):
			if OsmTags.buried_waterway(el_tags):
				pass  # A culverted drain or piped brook runs under the street.
			elif str(el_tags.get("waterway", "")) == "riverbank" \
					and OsmGeometry._is_closed(poly):
				land.append({"class": "water", "points": poly, "holes": []})
			else:
				waterways.append(OsmTags._waterway_entry(el_tags, poly))
		elif str(el_tags.get("natural", "")) == "coastline":
			waterways.append(OsmTags._waterway_entry(el_tags, poly, "coastline"))
		elif str(el_tags.get("man_made", "")) == "bridge":
			if OsmGeometry._is_closed(poly) and poly.size() >= 4:
				_bridge_area(bridge_areas, el_tags, poly, source_id)
		elif str(el_tags.get("man_made", "")) == "pier" and poly.size() >= 2:
			# A jetty or marina pontoon (floating=yes): MarinaBuilder.
			piers.append({"points": poly, "floating": str(el_tags.get("floating", "")) == "yes",
				"width_m": OsmTags._tag_metres(el_tags.get("width", ""), 0.5, 40.0)})
		elif el_tags.has("barrier"):
			barriers.append({"points": poly,
				"osm_id": source_id,
				"class": str(el_tags.get("barrier", "yes")),
				"height_m": OsmTags._tag_metres(el_tags.get("height", ""), 0.1, 30.0),
				"material": str(el_tags.get("material", "")),
				"fence_type": str(el_tags.get("fence_type", ""))})
			(barriers.back() as Dictionary).merge(OsmTags.fortification_tags(el_tags))
		elif el_tags.has("defensive_works") and OsmGeometry._is_closed(poly) and poly.size() >= 4:
			buildings.append(OsmTags._building_entry(el_tags, poly, aabb))
		else:
			var arch2 := OsmTags.archetype_for(el_tags)
			if arch2 != "":
				var lmk2 := {
					"x": (min_x + max_x) / 2.0, "z": (min_z + max_z) / 2.0,
					"archetype": arch2, "name": str(el_tags.get("name", "")),
					"wikipedia": OsmTags.wiki_tag(el_tags),
					"height": 30.0,
					"size_x": clampf(max_x - min_x, 6.0, 240.0),
					"size_z": clampf(max_z - min_z, 6.0, 240.0)}
				_framed_landmark(lmk2, poly, false)
				landmarks.append(lmk2)
			var cls := OsmTags.land_class(el_tags)
			if cls != "" and geom.size() >= 3:
				var entry := {"class": cls, "points": poly, "holes": []}
				if cls == "water":
					entry["tidal"] = OsmTags.tidal(el_tags)
					entry["still_pool"] = OsmTags.still_pool(el_tags)
				if cls == "forest":
					entry.merge(OsmTags.tree_tags(el_tags))
				if cls == "grass":
					entry["sward"] = OsmTags.sward(el_tags)
				if cls == "urban" and OsmTags.harbour_use(el_tags) != "":
					entry["harbour_use"] = OsmTags.harbour_use(el_tags)
				land.append(entry)
			elif str(el_tags.get("natural", "")) == "tree_row":
				# A mapped row of trees: one tree every TREE_ROW_M along it.
				for tp in OsmGeometry.along(poly, TREE_ROW_M):
					var tree := {"x": tp.x, "z": tp.y, "row": true}
					tree.merge(OsmTags.tree_tags(el_tags))
					trees.append(tree)
		_stamp_sources([buildings, roads, land], source_starts, source_id)
	RoadWidths.from_sidewalks(roads, trees)
	_drop_duplicate_buildings(buildings)
	_drop_duplicate_parts(part_ways)
	_nest_parts(buildings, part_ways)
	BuildingReferences.apply(buildings)
	SuomenlinnaSite.apply(buildings, barriers, c_lat, c_lon, landmarks)
	_monument_landmarks(buildings, landmarks)
	LandmarkFidelity.mark(buildings, landmarks)
	return {"buildings": buildings, "roads": roads, "land": land,
		"landmarks": landmarks, "waterways": waterways, "trees": trees,
		"barriers": barriers, "country": country, "railways": railways,
		"furniture": furniture, "pois": pois, "piers": piers, "shore_structures": shore_structures,
		"tram_stops": tram_stops, "bus_stops": bus_stops,
		"rail_platforms": rail_platforms, "rail_stations": rail_stations, "bridge_areas": bridge_areas}

## A man_made=bridge outline (BridgeStructures builds one deck per
## outline): {points (closed ring), layer, bridge_structure,
## bridge_material, osm_id}.
static func _bridge_area(out: Array, tags: Dictionary, ring: PackedVector2Array, source_id: String) -> void:
	if ring.size() < 4:
		return
	out.append({"points": ring, "layer": OsmTags._tag_int(tags.get("layer", 1), -10, 10),
		"bridge_structure": str(tags.get("bridge:structure", "")),
		"bridge_material": str(tags.get("bridge:material", tags.get("material", ""))),
		"name": str(tags.get("name", "")), "osm_id": source_id})

## Building multipolygon relation (courtyard blocks): one building per
## stitched outer ring, its contained inner rings as `holes`. Tags live
## on the relation, so every outer shares them; a landmark archetype is
## emitted once, sized from the first outer.
static func _stamp_sources(collections: Array, starts: Array, source_id: String) -> void:
	for i in collections.size():
		for j in range(int(starts[i]), collections[i].size()):
			collections[i][j]["osm_id"] = source_id

static func _relation_buildings(tags: Dictionary, members: Array, c_lat: float,
		c_lon: float, buildings: Array, landmarks: Array) -> void:
	var arch := OsmTags.archetype_for(tags)
	for r in OsmGeometry._relation_rings(members, c_lat, c_lon):
		var outer: PackedVector2Array = r["outer"]
		var entry := OsmTags._building_entry(tags, outer, OsmGeometry._ring_aabb(outer))
		entry["holes"] = r["holes"]
		buildings.append(entry)
		if arch != "":
			var lmk := {
				"x": entry["x"], "z": entry["z"], "archetype": arch,
				"name": str(tags.get("name", "")),
				"wikipedia": OsmTags.wiki_tag(tags),
				"height": entry["height"],
				"size_x": entry["size_x"], "size_z": entry["size_z"]}
			_framed_landmark(lmk, outer, entry["height_source"] != "default")
			landmarks.append(lmk)
			arch = ""

## Archetypes on every mapping path (building way, plain way, building
## relation) stand on their outline's own frame: true bearing and
## along/across footprint, so a church turned to its street is not built
## on an inflated AABB. Observation wheels, when the height is only a
## default, also take the height a wheel of the footprint's length would
## have, so a 120 m wheel is not built from a 10 m placeholder.
static func _framed_landmark(lmk: Dictionary, poly: PackedVector2Array, height_known: bool) -> void:
	if lmk["archetype"] != "big_wheel":
		if poly.size() >= 3:
			lmk.merge(_wheel_frame(poly), true)
		return
	if poly.size() < 2:
		return
	lmk.merge(_wheel_frame(poly), true)
	if not height_known:
		lmk["height"] = maxf(float(lmk["height"]),
			float(lmk["size_z"]) / LandmarkWheel.DIAMETER_PER_HEIGHT)

## An observation wheel is mapped as a thin slab along the wheel; its
## longest edge gives the wheel plane. Returns the yaw that turns local
## +Z onto that edge, with the footprint measured along it (size_z) and
## across it (size_x), so the wheel stands at its true bearing.
static func _wheel_frame(poly: PackedVector2Array) -> Dictionary:
	var u := Vector2(0, 1)
	var best := 0.0
	for i in poly.size() - 1:
		var e := poly[i + 1] - poly[i]
		if e.length() > best:
			best = e.length()
			u = e / best
	var v := Vector2(-u.y, u.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		var q := Vector2(p.dot(v), p.dot(u))
		lo = lo.min(q)
		hi = hi.max(q)
	return {"yaw": atan2(u.x, u.y), "size_x": hi.x - lo.x, "size_z": hi.y - lo.y}

## Tall slender memorials (Nelson's Column, obelisks) mapped as buildings
## become free-standing column / obelisk landmarks, so they are not built
## as windowed towers. Judged on the tallest piece (the building or one of
## its parts: Nelson's 46 m shaft stands on a 30 m plinth-and-lions
## footprint): at least 20 m high and 2.5x taller than it is wide, so
## memorial halls, statue groups and low shrines stay buildings.
const MONUMENT_MIN_HEIGHT_M := 20.0
const MONUMENT_SLENDERNESS := 2.5

static func _monument_landmarks(buildings: Array, landmarks: Array) -> void:
	for b in buildings:
		var kind := str((b as Dictionary).get("monument", ""))
		if kind == "":
			continue
		var h := float(b["height"])
		var ring: PackedVector2Array = b["footprint"]
		for part in b["parts"]:
			if float(part["height"]) > h:
				h = float(part["height"])
				ring = part["footprint"]
		var box := OsmGeometry._ring_aabb(ring)
		if h < MONUMENT_MIN_HEIGHT_M or h < MONUMENT_SLENDERNESS * maxf(box.size.x, box.size.y):
			continue
		var at := Vector2(float(b["x"]), float(b["z"]))
		var listed := false
		for lm in landmarks:
			if Vector2(float(lm["x"]), float(lm["z"])).distance_to(at) < 6.0:
				listed = true
		if listed:
			continue
		landmarks.append({"x": at.x, "z": at.y, "archetype": kind,
			"name": str(b.get("name", "")), "height": h,
			"size_x": 24.0, "size_z": 24.0, "monument": true})

## Order-free identity of a ring: its vertices (closing duplicate
## dropped) rounded to a centimetre and sorted.
static func ring_signature(ring: PackedVector2Array) -> String:
	var n := ring.size()
	if n > 1 and ring[0].distance_to(ring[n - 1]) < 0.01:
		n -= 1
	var keys := PackedStringArray()
	for i in n:
		keys.append("%.2f,%.2f" % [ring[i].x, ring[i].y])
	keys.sort()
	return ",".join(keys)

## One outline mapped as two buildings (a tagged way and the building
## relation using it as its outer, or two relations on one outer way)
## built both: their walls and roofs coincided and z-fought under two
## facades. One stays, the copy that says most (courtyards, a mapped
## height, a name), else the first; it takes what only the other mapped
## and lists the other's id in `alias_ids` (id-keyed lookups: far-city
## tower suppression, reference rows). Outlines that stand at different
## floors (a roof canopy or a bridge building over another) are not
## copies.
static func _drop_duplicate_buildings(buildings: Array) -> void:
	var at := {}
	var drop := {}
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		var fp: Variant = b.get("footprint", null)
		if not (fp is PackedVector2Array) or (fp as PackedVector2Array).size() < 3:
			continue
		var sig := "%s|%s|%s|%s" % [ring_signature(fp), str(b.get("min_height_m", 0.0)),
			str(b.get("min_level", 0)), str(b.get("kind", "")) == "roof"]
		if not at.has(sig):
			at[sig] = i
			continue
		var j: int = at[sig]
		var keep: Dictionary = buildings[j]
		var lose := b
		if _building_detail(b) > _building_detail(buildings[j]):
			keep = b
			lose = buildings[j]
			drop[j] = true
			at[sig] = i
		else:
			drop[i] = true
		_absorb(keep, lose)
	if drop.is_empty():
		return
	var kept: Array = []
	for i in buildings.size():
		if not drop.has(i):
			kept.append(buildings[i])
	buildings.assign(kept)

## `keep` takes from the copy `lose` the courtyards, mapped height and
## name it lacks, and its id(s) as aliases.
static func _absorb(keep: Dictionary, lose: Dictionary) -> void:
	if (keep.get("holes", []) as Array).is_empty() and not (lose.get("holes", []) as Array).is_empty():
		keep["holes"] = lose["holes"]
	if str(keep.get("height_source", "default")) == "default" \
			and str(lose.get("height_source", "default")) != "default":
		for k in ["height", "height_source", "levels"]:
			keep[k] = lose[k]
	if str(keep.get("name", "")) == "" and str(lose.get("name", "")) != "":
		keep["name"] = lose["name"]
	var aliases: Array = keep.get("alias_ids", [])
	if str(lose.get("osm_id", "")) != "":
		aliases.append(str(lose["osm_id"]))
	aliases.append_array(lose.get("alias_ids", []))
	if not aliases.is_empty():
		keep["alias_ids"] = aliases

## The ids `b` was mapped under: its own and any merged copy's.
static func ids_of(b: Dictionary) -> Array:
	var out: Array = []
	if str(b.get("osm_id", "")) != "":
		out.append(str(b["osm_id"]))
	out.append_array(b.get("alias_ids", []))
	return out

static func _building_detail(b: Dictionary) -> int:
	return (4 if not (b.get("holes", []) as Array).is_empty() else 0) \
		+ (2 if str(b.get("height_source", "default")) != "default" else 0) \
		+ (1 if str(b.get("name", "")) != "" else 0)

## The same building:part mapped twice (same rings, same tags) drew two
## coincident masses; only the first is kept. Parts that differ in any
## tag (height, finish) or in their courtyards are distinct masses
## (PartyWalls lets the taller keep a shared wall).
static func _drop_duplicate_parts(part_ways: Array) -> void:
	var seen := {}
	var kept: Array = []
	for pw in part_ways:
		var tags: Dictionary = pw["tags"]
		var sig := ring_signature(pw["points"])
		for h in pw.get("holes", []):
			sig += "|h" + ring_signature(h)
		var keys := tags.keys()
		keys.sort()
		for k in keys:
			sig += "|%s=%s" % [k, tags[k]]
		if seen.has(sig):
			continue
		seen[sig] = true
		kept.append(pw)
	part_ways.assign(kept)

## Nest building:part ways into their parents by centroid containment
## (smallest containing footprint wins; AABB pre-filter keeps the
## Paris case — 807 parts × 2504 buildings — cheap). A part without
## its own height tags inherits the parent mass height. Parts with no
## containing parent are real masses the payload left orphaned, so
## they are emitted as buildings rather than dropped.
static func _nest_parts(buildings: Array, part_ways: Array) -> void:
	var boxes: Array[Rect2] = []
	for b in buildings:
		var fp: PackedVector2Array = b["footprint"]
		boxes.append(OsmGeometry._ring_aabb(fp))
	for pw in part_ways:
		var tags: Dictionary = pw["tags"]
		var pts: PackedVector2Array = pw["points"]
		var paabb: Rect2 = pw["aabb"]
		var centre := OsmGeometry._polygon_centroid(pts, paabb.get_center())
		var best := -1
		var best_area := INF
		for i in buildings.size():
			if not boxes[i].has_point(centre):
				continue
			var fp: PackedVector2Array = buildings[i]["footprint"]
			if not OsmGeometry._point_in_ring(centre, fp):
				continue
			var area := boxes[i].size.x * boxes[i].size.y
			if area < best_area:
				best = i
				best_area = area
		if best < 0:
			var orphan := OsmTags._building_entry(tags, pts, paabb)
			orphan["holes"] = pw.get("holes", [])
			orphan["orphan_part"] = true
			orphan["osm_id"] = str(pw.get("osm_id", ""))
			buildings.append(orphan)
			boxes.append(paabb)
			continue
		var parent: Dictionary = buildings[best]
		var res := OsmTags._resolve_height(tags, {
			"height": parent["height"],
			"height_source": parent["height_source"]})
		var part := {
			"footprint": pts, "x": centre.x, "z": centre.y,
			"size_x": clampf(paabb.size.x, 12.0, 136.0),
			"size_z": clampf(paabb.size.y, 12.0, 136.0),
			"height": res["height"], "height_source": res["height_source"],
			"levels": res["levels"],
			"colour": OsmTags.wall_colour(tags),
			"material": OsmTags.wall_material(tags),
			"holes": pw.get("holes", []),
		}
		# Parts carry their own roof (domes, towers, stepped wings).
		part.merge(OsmTags._roof_tags(tags))
		part.merge(OsmTags.fortification_tags(tags))
		part["osm_id"] = str(pw.get("osm_id", ""))
		for key in ["name", "building", "amenity", "tourism"]:
			if tags.has(key):
				part[{"building": "kind", "amenity": "use", "tourism": "use"}.get(key, key)] = str(tags[key])
		(parent["parts"] as Array).append(part)
	_ground_orphans(buildings)

## Smallest footprint (m²) a lifted orphan part must have to be grounded:
## skybridges and walkway roofs between towers stay up.
const GROUND_ORPHAN_M2 := 200.0

## A building:part outside every building outline stands alone; lifted
## off the ground (min_height / building:min_level) with nothing under it
## — its lower parts lost to a cap or the query edge — it floated as a
## slab over the skyline (New York). A part that high implies a building
## below, so it stands on the ground instead.
static func _ground_orphans(buildings: Array) -> void:
	for b in buildings:
		var o: Dictionary = b
		if not bool(o.get("orphan_part", false)):
			continue
		var lift := float(o.get("min_height_m", 0.0))
		if lift <= 0.0 and int(o.get("min_level", 0)) > 0:
			lift = float(o["min_level"]) * 3.0
		var fp: PackedVector2Array = o["footprint"]
		if lift <= 0.0 or absf(RingGeometry.signed_area(fp)) < GROUND_ORPHAN_M2:
			continue
		var at := Vector2(float(o["x"]), float(o["z"]))
		var held := false
		for other in buildings:
			var u: Dictionary = other
			if is_same(u, o) or float(u.get("height", 0.0)) < lift - 1.5 \
					or float(u.get("min_height_m", 0.0)) >= lift:
				continue
			if OsmGeometry._point_in_ring(at, u["footprint"] as PackedVector2Array):
				held = true
				break
		if not held:
			o["min_height_m"] = 0.0
			o["min_level"] = 0
## Concatenate two Overpass responses' element lists, detailed first so
## the parse-time id-dedup keeps the detailed copy. Either side may be
## "" or invalid — the other side still parses.
static func merge_payloads(first: String, second: String) -> String:
	var els: Array = []
	var a: Variant = JSON.parse_string(first) if first != "" else {}
	if a is Dictionary:
		els.append_array(a.get("elements", []))
	var b: Variant = JSON.parse_string(second) if second != "" else {}
	if b is Dictionary:
		els.append_array(b.get("elements", []))
	return JSON.stringify({"elements": els})

## TRANSITIONAL (deleted with V13 in T4.4): bare-centreline roads for
## RoadBuilder, which still speaks v1 (the pipeline moved to §2.5 dicts
## in closure W2); _finish downgrades at the frozen signal edge.
static func roads_to_v1(roads: Array) -> Array:
	var out: Array = []
	for r in roads:
		if r is Dictionary:
			out.append((r as Dictionary).get("points", PackedVector2Array()))
		else:
			out.append(r)
	return out
