class_name TurkuStreets
extends RefCounted

## The City of Turku's surveyed street areas (Katualueet, CC BY 4.0) from
## the city's open WFS (`turku.asiointi.fi/TeklaOGCWeb/WFS.ashx`, EPSG:3877):
##  - carriageway parts (Ajorata, Pysäköintialue) give each OSM street its
##    measured kerb-to-kerb width (RoadWidths.from_polygons) and mark
##    cobblestone/sett streets (Nupukivi, Noppakivi, Luonnonkivi, Graniitti);
##  - light-traffic parts (Jalkakäytävä, Pyöräkaista, Pyörätie, Yhdistetty
##    kevyen liikenteen väylä, Tori, Aukio, Kävelykatu) become `paved_areas`
##    painted at full resolution in GroundMaterial.

const URL := "https://turku.asiointi.fi/TeklaOGCWeb/WFS.ashx"
const LAYER := "GIS:Katualueet"
const CREDIT := "Street areas: © City of Turku, register of public areas (CC BY 4.0)"
const HALF_M := 800.0
const MAX_FEATURES := 15000

const DRIVE := ["Ajorata", "Ajorata, muu", "Ajorata (Silta)"]
const PARKING := ["Pysäköintialue", "Pysäköintikaista", "Pysäköintipaikka"]
const WALK := [
	"Jalkakäytävä", "Pyöräkaista", "Pyörätie", "Yhdistetty kevyen liikenteen väylä",
	"Jalankulku- ja pyörätie", "Kävelykatu", "Pihakatu", "Tori", "Aukio",
	"Tonttiliittymä", "Muu liikennealue",
]
const GRAVEL := ["Kivituhka", "Sora", "Murske", "Hiekka"]
const SETTS := ["Nupukivi", "Noppakivi", "Graniittinoppakivi", "Graniitti", "Luonnonkivi", "Kiveys"]

static func covers(lat: float, lon: float) -> bool:
	return TurkuTrees.covers(lat, lon)

static func request_url(lat: float, lon: float) -> String:
	var p := Gk23.forward(lat, lon)
	var e := roundf(p[0])
	var n := roundf(p[1])
	return "%s?service=WFS&version=1.1.0&request=GetFeature&typeName=%s&maxFeatures=%d&bbox=%d,%d,%d,%d" % [
		URL, LAYER, MAX_FEATURES,
		int(e - HALF_M), int(n - HALF_M), int(e + HALF_M), int(n + HALF_M)]

## Parses GML FeatureCollection into rows {type, material, rings: [PackedFloat64Array]}.
## Outer ring first, interior holes after. Returns null on non-WFS input.
static func decode(text: String) -> Variant:
	if text.find("FeatureCollection") < 0:
		return null
	var xml := XMLParser.new()
	if xml.open_buffer(text.to_utf8_buffer()) != OK:
		return null
	var rows: Array = []
	var in_item := false
	var in_poly := false
	var in_interior := false
	var tag := ""
	var kind := ""
	var material := ""
	var outer := PackedFloat64Array()
	var holes: Array = []
	var pos_chunks: PackedStringArray = []
	while xml.read() == OK:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				var name := TurkuTrees._local_name(xml.get_node_name())
				if name == "Katualueet":
					in_item = true
					kind = ""
					material = ""
				elif in_item:
					if name == "Polygon":
						in_poly = true
						outer = PackedFloat64Array()
						holes = []
					elif name == "interior":
						in_interior = true
					elif name == "exterior":
						in_interior = false
					elif name == "posList":
						pos_chunks = PackedStringArray()
					tag = name
			XMLParser.NODE_TEXT:
				if in_item and tag != "":
					var val := xml.get_node_data()
					match tag:
						"Katuosalaji":
							kind += val
						"Pintamateriaali":
							material += val
						"posList":
							pos_chunks.append(val)
			XMLParser.NODE_ELEMENT_END:
				var name := TurkuTrees._local_name(xml.get_node_name())
				if name == "posList" and in_poly:
					var flat := _parse_pos_list(" ".join(pos_chunks))
					if flat.size() >= 6:
						if in_interior:
							holes.append(flat)
						else:
							outer = flat
					pos_chunks = PackedStringArray()
				elif name == "Polygon" and in_poly:
					in_poly = false
					if outer.size() >= 6:
						var rings: Array = [outer]
						rings.append_array(holes)
						rows.append({
							"type": kind.strip_edges(),
							"material": material.strip_edges(),
							"rings": rings,
						})
				elif name == "Katualueet":
					in_item = false
				if name == tag:
					tag = ""
	return rows

static func _parse_pos_list(text: String) -> PackedFloat64Array:
	var tokens := text.split(" ", false)
	var n := tokens.size() / 2
	var out := PackedFloat64Array()
	out.resize(n * 2)
	var k := 0
	for i in n:
		var sx := tokens[i * 2]
		var sy := tokens[i * 2 + 1]
		if sx.is_valid_float() and sy.is_valid_float():
			out[k] = float(sx)
			out[k + 1] = float(sy)
			k += 2
	out.resize(k)
	return out

static func localise(rows: Array, c_lat: float, c_lon: float) -> Array:
	var f := Gk23.frame(c_lat, c_lon)
	var out: Array = []
	for r in rows:
		var rings: Array = []
		for flat: PackedFloat64Array in r["rings"]:
			var pts := PackedVector2Array()
			for i in range(0, flat.size() - 1, 2):
				pts.append(Gk23.frame_xz(f, flat[i], flat[i + 1]))
			if pts.size() >= 2 and pts[0].distance_to(pts[pts.size() - 1]) < 0.01:
				pts.remove_at(pts.size() - 1)
			rings.append(pts)
		if (rings[0] as PackedVector2Array).size() >= 3:
			out.append({"type": r["type"], "material": r["material"], "points": rings[0], "holes": rings.slice(1)})
	return out

static func walk_class(part: Dictionary) -> String:
	if not (str(part["type"]) in WALK):
		return ""
	var material := str(part["material"])
	for g in GRAVEL:
		if material.begins_with(g):
			return "path"
	for s in SETTS:
		if material.begins_with(s):
			return "sett"
	return "urban"

## Merges surveyed Turku street areas into `data` (local metres).
static func apply(data: LocationData, rows: Array) -> Dictionary:
	var drive: Array = []
	var parking: Array = []
	var paved: Array = []
	for part in localise(rows, data.latitude, data.longitude):
		var t := str(part["type"])
		if t in DRIVE:
			drive.append(part)
		elif t in PARKING:
			parking.append(part)
		else:
			var cls := walk_class(part)
			if cls != "":
				paved.append({"class": cls, "points": part["points"], "holes": part["holes"]})
	data.paved_areas = paved
	var widths := RoadWidths.from_polygons(data.roads, drive, parking, not paved.is_empty()) \
		if not drive.is_empty() else 0
	HelsinkiStreets._keep_bands_without_pavement(data.roads, paved)
	var squares := HelsinkiStreets.sett_squares(data.roads, paved)
	var setts := HelsinkiStreets.surfaces(data.roads, drive) if not drive.is_empty() else 0
	return {"drive": drive.size(), "parking": parking.size(), "widths": widths, "paved": paved.size(),
		"setts": setts, "squares": squares}
