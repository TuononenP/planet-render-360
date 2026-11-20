class_name StockholmTram
extends RefCounted

## Djurgårdslinjen (line 7N, the "Spårväg City" ways of OSM) for the vehicle
## plan, where the bundled snapshot carries none of it: Hamngatan and
## Norrmalmstorg, Nybroplan, Strandvägen, then past Djurgårdsbron to
## Waldemarsudde. The points are the mapped track simplified to 2 m (OSM, one
## of the two tracks), as [lat, lon]. A map whose own data maps tram track on
## the corridor (a live fetch) keeps that and gets no line from here.
const LINE := [
	[59.33262, 18.06833], [59.33279, 18.07158], [59.33291, 18.07256], [59.33294, 18.07550],
	[59.33285, 18.07604], [59.33148, 18.08116], [59.33140, 18.08160], [59.33164, 18.09144],
	[59.33173, 18.09218], [59.33174, 18.09296], [59.33171, 18.09327], [59.33168, 18.09338],
	[59.33157, 18.09352],
	# Djurgårdsbron: no tram stands on the bridge itself (its deck is the road's).
	[59.33027, 18.09431], [59.32847, 18.09635], [59.32829, 18.09651], [59.32808, 18.09662],
	[59.32791, 18.09664], [59.32759, 18.09653], [59.32698, 18.09620], [59.32670, 18.09615],
	[59.32646, 18.09619], [59.32547, 18.09688], [59.32501, 18.09727], [59.32473, 18.09758],
	[59.32456, 18.09786], [59.32433, 18.09840], [59.32421, 18.09888], [59.32367, 18.10203],
	[59.32346, 18.10303], [59.32336, 18.10365], [59.32308, 18.10609], [59.32306, 18.10670],
	[59.32309, 18.10784], [59.32329, 18.11012], [59.32326, 18.11028], [59.32319, 18.11043],
	[59.32286, 18.11058], [59.32276, 18.11070], [59.32268, 18.11096], [59.32265, 18.11126],
]
## Index of the first point after Djurgårdsbron.
const AFTER_BRIDGE := 13
## Centre to centre of the two tracks (m).
const TRACK_GAP_M := 3.0

## Adds the line's two tracks to `data.railways` (west and east of Djurgårdsbron) in
## Stockholm when the map carries no tram track on the corridor: embedded in the
## street and electrified, so RailBuilder lays it flush, OverheadWires hangs its
## contact wire and poles, and TransitVehicles runs the vintage cars on it like on
## mapped track. Ways outside the built square are the builders' to cull.
static func complete(data: LocationData) -> void:
	if CityStyles.region_at(data.latitude, data.longitude) != "stockholm":
		return
	# Test-only: STOCKHOLM_TRAM_FORCE=1 swaps the mapped corridor track for the added line,
	# so a capture can show the added ways where live data maps the line.
	if OS.get_environment("STOCKHOLM_TRAM_FORCE") == "1":
		data.railways = data.railways.filter(func(r: Variant) -> bool: return not (r is Dictionary
			and str((r as Dictionary).get("class", "")) == "tram" and _on_line(data, r)))
	elif _mapped(data):
		return
	var m := WorldScale.metres_to_units()
	var pts := PackedVector2Array()
	for ll: Array in LINE:
		pts.append(WorldScale.xz_from_latlon(float(ll[0]), float(ll[1]), data.latitude, data.longitude) * m)
	var tags := {"railway": "tram", "embedded": "yes", "electrified": "contact_line", "gauge": "1435"}
	var added: Array = []
	for span: Array in [[0, AFTER_BRIDGE], [AFTER_BRIDGE, pts.size()]]:
		var way := pts.slice(int(span[0]), int(span[1]))
		added.append(OsmTags._rail_entry(tags, way))
		# The second track, TRACK_GAP_M beside it: one track a way, so trams pass.
		added.append(OsmTags._rail_entry(tags, _beside(way, TRACK_GAP_M * m)))
	data.railways = data.railways + added
	print("STOCKHOLM-TRAM added %d ways, %d mapped railways" % [added.size(), data.railways.size() - added.size()])

## `way` moved `gap` to its left at every vertex (the bisector of its two
## segments, its length held to 2 x gap at sharp corners).
static func _beside(way: PackedVector2Array, gap: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in way.size():
		var before := (way[i] - way[maxi(i - 1, 0)]).normalized() if i > 0 else Vector2.ZERO
		var after := (way[mini(i + 1, way.size() - 1)] - way[i]).normalized() if i < way.size() - 1 else Vector2.ZERO
		var dir := (before + after).normalized() if before != Vector2.ZERO and after != Vector2.ZERO else (before + after)
		var normal := Vector2(-dir.y, dir.x)
		var miter := 1.0
		if before != Vector2.ZERO and after != Vector2.ZERO:
			miter = minf(1.0 / maxf(normal.dot(Vector2(-after.y, after.x)), 0.5), 2.0)
		out.append(way[i] + normal * gap * miter)
	return out

static func _on_line(data: LocationData, rail: Dictionary) -> bool:
	for p: Vector2 in rail.get("points", PackedVector2Array()):
		if TramSpecs.on_djurgarden_line(WorldScale.latlon_from_xz(p.x, p.y, data.latitude, data.longitude)):
			return true
	return false

## True when `data` maps tram track on Djurgårdslinjen's corridor.
static func _mapped(data: LocationData) -> bool:
	for r in data.railways:
		if not (r is Dictionary) or str((r as Dictionary).get("class", "")) != "tram":
			continue
		for p: Vector2 in (r as Dictionary).get("points", PackedVector2Array()):
			var ll := WorldScale.latlon_from_xz(p.x / WorldScale.metres_to_units(), p.y / WorldScale.metres_to_units(),
				data.latitude, data.longitude)
			if TramSpecs.on_djurgarden_line(ll):
				return true
	return false
