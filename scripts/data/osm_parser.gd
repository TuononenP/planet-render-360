class_name OsmParser
extends RefCounted

## Overpass JSON -> LocationData feature arrays. Owns parse_features
## (element dispatch + dedup), building:part nesting, payload merge
## and the v1 roads shim. Tag/geometry rules live in OsmTags/OsmGeometry.
## Spacing of the trees placed along a natural=tree_row way (metres).
const TREE_ROW_M := 8.0

static func parse_features(text: String, c_lat: float, c_lon: float) -> Dictionary:
	var buildings: Array = []
	var roads: Array = []
	var land: Array = []
	var landmarks: Array = []
	var waterways: Array = []
	var trees: Array = []
	var barriers: Array = []
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"buildings": buildings, "roads": roads, "land": land,
			"landmarks": landmarks, "waterways": waterways, "trees": trees,
			"barriers": barriers}
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
		# Point features (lighthouses, towers are often single nodes).
		if str(el.get("type", "")) == "node" and el.has("lat") and el.has("lon"):
			var node_arch := OsmTags.archetype_for(el_tags)
			if node_arch != "":
				var np := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				landmarks.append({
					"x": np.x, "z": np.y, "archetype": node_arch,
					"name": str(el_tags.get("name", "")),
					"height": float(str(el_tags.get("height", "30")).replace("m", "")),
					"size_x": 8.0, "size_z": 8.0})
			if str(el_tags.get("natural", "")) == "tree":
				var tp := WorldScale.xz_from_latlon(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				var tree := {"x": tp.x, "z": tp.y}
				tree.merge(OsmTags.tree_tags(el_tags))
				trees.append(tree)
			continue
		# Multipolygon relations (fetched via the nwr land/water
		# statements): stitched outer rings with inner-ring holes.
		# Boundary/route relations are not areas and are skipped.
		if str(el.get("type", "")) == "relation":
			if str(el_tags.get("type", "")) == "multipolygon" \
					and el.has("members") and el_tags.has("building"):
				_relation_buildings(el_tags, el.get("members", []), c_lat, c_lon,
					buildings, landmarks)
			elif str(el_tags.get("type", "")) == "multipolygon" \
					and el.has("members"):
				var members: Array = el.get("members", [])
				for entry in OsmGeometry._relation_land(el_tags, members, c_lat, c_lon):
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
							"height": 30.0,
							"size_x": clampf(box.size.x, 6.0, 240.0),
							"size_z": clampf(box.size.y, 6.0, 240.0)})
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
		if el_tags.has("building"):
			var entry := OsmTags._building_entry(el_tags, poly, aabb)
			buildings.append(entry)
			var arch := OsmTags.archetype_for(el_tags)
			if arch != "":
				landmarks.append({
					"x": entry["x"], "z": entry["z"], "archetype": arch,
					"name": str(el_tags.get("name", "")),
					"height": entry["height"],
					"size_x": entry["size_x"], "size_z": entry["size_z"]})
		elif el_tags.has("building:part"):
			part_ways.append({"tags": el_tags, "points": poly, "aabb": aabb})
		elif el_tags.has("highway"):
			roads.append(OsmTags._road_entry(el_tags, poly))
		elif el_tags.has("waterway"):
			if str(el_tags.get("waterway", "")) == "riverbank" \
					and OsmGeometry._is_closed(poly):
				land.append({"class": "water", "points": poly, "holes": []})
			else:
				waterways.append(OsmTags._waterway_entry(el_tags, poly))
		elif str(el_tags.get("natural", "")) == "coastline":
			waterways.append(OsmTags._waterway_entry(el_tags, poly, "coastline"))
		elif el_tags.has("barrier"):
			barriers.append({"points": poly,
				"class": str(el_tags.get("barrier", "yes"))})
		else:
			var arch2 := OsmTags.archetype_for(el_tags)
			if arch2 != "":
				landmarks.append({
					"x": (min_x + max_x) / 2.0, "z": (min_z + max_z) / 2.0,
					"archetype": arch2, "name": str(el_tags.get("name", "")),
					"height": 30.0,
					"size_x": clampf(max_x - min_x, 6.0, 240.0),
					"size_z": clampf(max_z - min_z, 6.0, 240.0)})
			var cls := OsmTags.land_class(el_tags)
			if cls != "" and geom.size() >= 3:
				var entry := {"class": cls, "points": poly, "holes": []}
				if cls == "forest":
					entry.merge(OsmTags.tree_tags(el_tags))
				land.append(entry)
			elif str(el_tags.get("natural", "")) == "tree_row":
				# A mapped row of trees: one tree every TREE_ROW_M along it.
				for tp in OsmGeometry.along(poly, TREE_ROW_M):
					var tree := {"x": tp.x, "z": tp.y, "row": true}
					tree.merge(OsmTags.tree_tags(el_tags))
					trees.append(tree)
	_nest_parts(buildings, part_ways)
	_monument_landmarks(buildings, landmarks)
	return {"buildings": buildings, "roads": roads, "land": land,
		"landmarks": landmarks, "waterways": waterways, "trees": trees,
		"barriers": barriers}

## Building multipolygon relation (courtyard blocks): one building per
## stitched outer ring, its contained inner rings as `holes`. Tags live
## on the relation, so every outer shares them; a landmark archetype is
## emitted once, sized from the first outer.
static func _relation_buildings(tags: Dictionary, members: Array, c_lat: float,
		c_lon: float, buildings: Array, landmarks: Array) -> void:
	var arch := OsmTags.archetype_for(tags)
	for r in OsmGeometry._relation_rings(members, c_lat, c_lon):
		var outer: PackedVector2Array = r["outer"]
		var entry := OsmTags._building_entry(tags, outer, OsmGeometry._ring_aabb(outer))
		entry["holes"] = r["holes"]
		buildings.append(entry)
		if arch != "":
			landmarks.append({
				"x": entry["x"], "z": entry["z"], "archetype": arch,
				"name": str(tags.get("name", "")),
				"height": entry["height"],
				"size_x": entry["size_x"], "size_z": entry["size_z"]})
			arch = ""

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
			"size_x": 24.0, "size_z": 24.0})

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
			buildings.append(OsmTags._building_entry(tags, pts, paabb))
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
			"colour": str(tags.get("building:colour", "")),
			"material": str(tags.get("building:material", tags.get("material", ""))),
		}
		# Parts carry their own roof (domes, towers, stepped wings).
		part.merge(OsmTags._roof_tags(tags))
		(parent["parts"] as Array).append(part)
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
