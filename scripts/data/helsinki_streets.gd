class_name HelsinkiStreets
extends RefCounted

## The City of Helsinki's surveyed street areas (YLRE street and green
## area parts, CC BY 4.0) from its open WFS, round the viewpoint:
##  - carriageway parts (Ajorata, parking strips, traffic islands) give
##    each OSM street its measured kerb-to-kerb width (RoadWidths
##    .from_polygons), so ribbons, painted kerbs, raised kerbs, parking
##    and grading follow the real street;
##  - light-traffic parts (pavements, squares, park paths, cycle tracks)
##    become `paved_areas` the ground class map paints at full resolution,
##    replacing the inferred pavement bands beside surveyed streets.
## Helsinki only; data on every preset.

const URL := "https://kartta.hel.fi/ws/geoserver/avoindata/wfs"
const LAYERS := {
	"carriageway": "avoindata:YLRE_Katu_ja_viherosat_ajorata_alue",
	"walkways": "avoindata:YLRE_Katu_ja_viherosat_kevytliikenne_alue",
}
const CREDIT := "Street areas: © City of Helsinki, register of public areas (CC BY 4.0)"
## The window: the eye's surroundings, where kerbs and pavements show.
const HALF_M := 800.0
const MAX_FEATURES := 20000
## Carriageway parts a car drives or parks on; islands and driveways
## are not part of the street's width.
const DRIVE := ["Ajorata", "Ajorata, muu", "Ajorata (Silta)"]
const PARKING := ["Pysäköintialue"]
## Light-traffic parts → ground class (GroundMaterial.ID); steps stay
## with the terrain.
const SKIP_WALK := ["Portaat", "Lämmitettävät portaat"]
const GRAVEL := ["Kivituhka", "Sora", "Murske"]

static func covers(lat: float, lon: float) -> bool:
	return HelsinkiRegister.covers(lat, lon)

static func request_url(layer: String, lat: float, lon: float) -> String:
	var p := Gk25.forward(lat, lon)
	var e := roundf(p[0])
	var n := roundf(p[1])
	return "%s?service=WFS&version=2.0.0&request=GetFeature&typeNames=%s&outputFormat=application/json&count=%d&propertyName=alatyyppi,materiaali,geom&bbox=%d,%d,%d,%d,EPSG:3879" % [
		URL, LAYERS[layer], MAX_FEATURES, int(e - HALF_M), int(n - HALF_M), int(e + HALF_M), int(n + HALF_M)]

## Rows {type, material, rings: [PackedFloat64Array e,n,...]} (outer
## first); null when the text is no feature collection.
static func decode(text: String) -> Variant:
	if not text.strip_edges().begins_with("{"):
		return null
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("features"):
		return null
	var rows: Array = []
	for f in (parsed as Dictionary)["features"]:
		if not (f is Dictionary):
			continue
		var g: Variant = (f as Dictionary).get("geometry")
		if not (g is Dictionary):
			continue
		var polys: Array = []
		match str((g as Dictionary).get("type", "")):
			"Polygon":
				polys = [(g as Dictionary)["coordinates"]]
			"MultiPolygon":
				polys = (g as Dictionary)["coordinates"]
		var p: Dictionary = (f as Dictionary).get("properties", {})
		for poly in polys:
			var rings: Array = []
			for ring in poly:
				var flat := PackedFloat64Array()
				for c in ring:
					flat.append(float(c[0]))
					flat.append(float(c[1]))
				if flat.size() >= 6:
					rings.append(flat)
			if not rings.is_empty():
				rows.append({"type": _str(p.get("alatyyppi")), "material": _str(p.get("materiaali")), "rings": rings})
	return rows

static func _str(v: Variant) -> String:
	return "" if v == null else str(v).strip_edges()

## `rows` in local metres round (c_lat, c_lon): {type, material, points,
## holes}.
static func localise(rows: Array, c_lat: float, c_lon: float) -> Array:
	var f := Gk25.frame(c_lat, c_lon)
	var out: Array = []
	for r in rows:
		var rings: Array = []
		for flat: PackedFloat64Array in r["rings"]:
			var pts := PackedVector2Array()
			for i in range(0, flat.size() - 1, 2):
				pts.append(Gk25.frame_xz(f, flat[i], flat[i + 1]))
			if pts.size() >= 2 and pts[0].distance_to(pts[pts.size() - 1]) < 0.01:
				pts.remove_at(pts.size() - 1)
			rings.append(pts)
		if (rings[0] as PackedVector2Array).size() >= 3:
			out.append({"type": r["type"], "material": r["material"], "points": rings[0], "holes": rings.slice(1)})
	return out

## Ground class of a light-traffic part: "path" for stone dust and
## gravel, else "urban" (paving); "" for parts left to the terrain.
static func walk_class(part: Dictionary) -> String:
	if str(part["type"]) in SKIP_WALK:
		return ""
	return "path" if str(part["material"]) in GRAVEL else "urban"

## Merges both layers into `data` (local metres): street widths from the
## carriageway, pavements into data.paved_areas. Returns the counts.
static func apply(data: LocationData, carriageway: Array, walkways: Array) -> Dictionary:
	var drive: Array = []
	var parking: Array = []
	for part in localise(carriageway, data.latitude, data.longitude):
		if str(part["type"]) in DRIVE:
			drive.append(part)
		elif str(part["type"]) in PARKING:
			parking.append(part)
	var paved: Array = []
	for part in localise(walkways, data.latitude, data.longitude):
		var cls := walk_class(part)
		if cls != "":
			paved.append({"class": cls, "points": part["points"], "holes": part["holes"]})
	data.paved_areas = paved
	# Without the surveyed pavements a street keeps its inferred bands.
	var widths := RoadWidths.from_polygons(data.roads, drive, parking, not paved.is_empty()) \
		if not drive.is_empty() else 0
	_keep_bands_without_pavement(data.roads, paved)
	return {"drive": drive.size(), "parking": parking.size(), "widths": widths, "paved": paved.size()}

## Pavement within this of a surveyed street's kerb counts as its own (m).
const BESIDE_M := 2.5

## A surveyed street paints no inferred pavement band (GroundMaterial):
## only where a surveyed pavement actually lies beside it. One with none
## beside any of its segments (a gap in the walkways answer) is unmarked.
static func _keep_bands_without_pavement(roads: Array, paved: Array) -> void:
	var grid := RoadWidths._poly_grid(paved) if not paved.is_empty() else {}
	for r in roads:
		if not (r is Dictionary) or not bool((r as Dictionary).get("surveyed", false)):
			continue
		var road: Dictionary = r
		var pts: PackedVector2Array = road["points"]
		var half := float(road.get("width_m", 6.0)) * 0.5 + BESIDE_M
		var beside := false
		for i in pts.size() - 1:
			var d := pts[i + 1] - pts[i]
			if d.length() < 1.0:
				continue
			var mid := (pts[i] + pts[i + 1]) * 0.5
			var n := Vector2(d.y, -d.x).normalized() * half
			if RoadWidths._inside(mid + n, paved, grid) or RoadWidths._inside(mid - n, paved, grid):
				beside = true
				break
		if not beside:
			road.erase("surveyed")
