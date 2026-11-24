class_name OsmAeroway
extends RefCounted

## Parses OSM `aeroway=*` elements (runways, taxiways, taxilanes, aprons,
## parking positions, gates, helipads, aerodrome tags) into a compact
## dictionary carried on `LocationData.aeroways`.
##
## Kept in its own class so OsmParser stays under the 1,000-line limit.

static func empty() -> Dictionary:
	return {
		"runways": [],
		"taxiways": [],
		"aprons": [],
		"stands": [],
		"gates": [],
		"helipads": [],
		"aerodrome": "",
	}

static func is_empty(aw: Dictionary) -> bool:
	if aw.is_empty():
		return true
	return (aw.get("runways", []) as Array).is_empty() \
		and (aw.get("taxiways", []) as Array).is_empty() \
		and (aw.get("aprons", []) as Array).is_empty() \
		and (aw.get("stands", []) as Array).is_empty() \
		and (aw.get("gates", []) as Array).is_empty() \
		and (aw.get("helipads", []) as Array).is_empty()

## Consumes an OSM node with `aeroway` tag.
static func parse_node(aw: Dictionary, tags: Dictionary, pt: Vector2) -> void:
	var kind := str(tags.get("aeroway", ""))
	match kind:
		"parking_position":
			(aw["stands"] as Array).append({
				"x": pt.x, "z": pt.y, "dir": Vector2.ZERO,
				"ref": str(tags.get("ref", "")),
			})
		"gate":
			(aw["gates"] as Array).append({
				"x": pt.x, "z": pt.y, "ref": str(tags.get("ref", "")),
			})
		"helipad":
			(aw["helipads"] as Array).append(_helipad_entry(tags, pt, 9.0))
		"aerodrome":
			_record_aerodrome(aw, tags)

## Consumes an OSM way with `aeroway` tag (`poly` already in local world XZ).
static func parse_way(aw: Dictionary, tags: Dictionary, poly: PackedVector2Array, aabb: Rect2) -> void:
	if poly.size() < 2:
		return
	var kind := str(tags.get("aeroway", ""))
	match kind:
		"runway":
			var w := OsmTags._tag_metres(tags.get("width", ""), 10.0, 120.0)
			if w <= 0.0:
				w = 45.0
			(aw["runways"] as Array).append({
				"points": poly, "width_m": w, "ref": str(tags.get("ref", "")),
			})
		"taxiway", "taxilane":
			var w := OsmTags._tag_metres(tags.get("width", ""), 5.0, 60.0)
			if w <= 0.0:
				w = 18.0 if kind == "taxiway" else 12.0
			(aw["taxiways"] as Array).append({
				"points": poly, "width_m": w, "kind": kind,
			})
		"apron":
			if poly.size() >= 3:
				(aw["aprons"] as Array).append({"points": poly, "holes": []})
		"parking_position":
			# Linear parking_position way: last vertex is nose-wheel stop,
			# vector from previous vertex gives the aircraft nose heading.
			var last := poly[poly.size() - 1]
			var prev := poly[poly.size() - 2]
			var d := last - prev
			var dir := d.normalized() if d.length() > 0.5 else Vector2.ZERO
			(aw["stands"] as Array).append({
				"x": last.x, "z": last.y, "dir": dir,
				"ref": str(tags.get("ref", "")),
			})
		"helipad":
			var c := aabb.get_center()
			var r := clampf(maxf(aabb.size.x, aabb.size.y) * 0.5, 6.0, 30.0)
			(aw["helipads"] as Array).append(_helipad_entry(tags, c, r))
		"aerodrome":
			_record_aerodrome(aw, tags)

## Consumes an OSM multipolygon relation with `aeroway` tag.
static func parse_relation(aw: Dictionary, tags: Dictionary, members: Array,
		c_lat: float, c_lon: float) -> void:
	var kind := str(tags.get("aeroway", ""))
	match kind:
		"apron":
			for r in OsmGeometry._relation_rings(members, c_lat, c_lon):
				var outer: PackedVector2Array = r["outer"]
				if outer.size() >= 3:
					(aw["aprons"] as Array).append({"points": outer, "holes": r["holes"]})
		"helipad":
			for r in OsmGeometry._relation_rings(members, c_lat, c_lon):
				var outer: PackedVector2Array = r["outer"]
				if outer.size() >= 3:
					var box := OsmGeometry._ring_aabb(outer)
					(aw["helipads"] as Array).append(_helipad_entry(tags, box.get_center(),
						clampf(maxf(box.size.x, box.size.y) * 0.5, 6.0, 30.0)))
		"aerodrome":
			_record_aerodrome(aw, tags)

static func _helipad_entry(tags: Dictionary, pt: Vector2, radius_m: float) -> Dictionary:
	var loc := str(tags.get("location", "")).to_lower()
	var rooftop := loc in ["roof", "rooftop"] \
		or OsmTags._tag_int(tags.get("layer", 0), -10, 10) > 0 \
		or str(tags.get("level", "")) != ""
	var name := str(tags.get("name", ""))
	var low := name.to_lower()
	var emergency := str(tags.get("emergency", "")).to_lower() in ["yes", "designated", "official"] \
		or str(tags.get("access", "")).to_lower() == "emergency" \
		or low.contains("hospital") or low.contains("medical") or low.contains("rescue") \
		or low.contains("ambulance") or low.contains("sairaala") or low.contains("sjukhus") \
		or low.contains("krankenhaus") or low.contains("hôpital")
	return {
		"x": pt.x, "z": pt.y, "radius_m": radius_m,
		"rooftop": rooftop, "emergency": emergency, "name": name,
	}

static func _record_aerodrome(aw: Dictionary, tags: Dictionary) -> void:
	var t := str(tags.get("aerodrome:type", tags.get("aerodrome", ""))).to_lower()
	if t == "":
		t = "public"
	var cur := str(aw.get("aerodrome", ""))
	if cur == "" or (t.contains("international") and not cur.contains("international")):
		aw["aerodrome"] = t
