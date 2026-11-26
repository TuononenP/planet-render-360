class_name LandmarkVisit
extends RefCounted

## Where to stand to see a landmark. Clicking one (map marker or 360
## callout) never puts the camera on it: the viewpoint backs off by a
## standoff that suits its kind, so a tower fills the view and a peak
## stands whole on the horizon. Also owns the shared landmark site shape
## used by the map, the callouts and the landmark panel:
##   {id, name, kind, icon, lat, lon, height_m, description,
##    wiki_lang, wiki_title, source}   source: curated | osm | wiki

const PEAK_M := 2500.0
const WATER_M := 1000.0
const DEFAULT_M := 300.0
const MIN_M := 180.0
const MAX_M := 700.0
## Get closer: this share of the standoff, never nearer than CLOSE_MIN_M.
const CLOSE_FACTOR := 0.4
const CLOSE_MIN_M := 80.0
## Explore arrival from a map selection: the eye stands this close to a
## regular landmark, so it fills the opening view. Peaks and water keep
## their wide standoffs (a summit or bay is not seen from 50 m).
const ARRIVAL_M := 50.0

static func site(name: String, lat: float, lon: float, description: String = "",
		source: String = "wiki", height_m: float = 0.0) -> Dictionary:
	var k := kind_for(description if description != "" else name)
	return {"id": "%s:%.5f,%.5f" % [source, lat, lon], "name": name,
		"kind": k[0], "icon": k[1], "lat": lat, "lon": lon,
		"height_m": height_m, "description": description,
		"wiki_lang": "", "wiki_title": "", "source": source}

## Curated registry entry (LocationData.landmarks()) -> site. The
## category comes from the entry's `kind` (registry_kind_icon), so the
## map, the list rows and the 360 callouts each draw their own icon
## instead of every curated landmark sharing one.
static func from_registry(entry: Dictionary) -> Dictionary:
	var k := registry_kind_icon(str(entry.get("kind", "")), str(entry["name"]))
	var s := site(str(entry["name"]), float(entry["lat"]), float(entry["lon"]),
		"Landmark", "curated", float(entry.get("height_m", 0.0)))
	s["id"] = "curated:" + str(entry["type"])
	s["kind"] = k[0]
	s["icon"] = k[1]
	s["wiki_lang"] = "en"
	s["wiki_title"] = str(entry.get("wiki_title", entry["name"]))
	return s

## [kind label, Lucide icon] for a curated registry entry: its `kind`
## field first (Temple, Station, Bridge...), falling back to kind_for()
## on the name for the core icons that carry no kind (Eiffel Tower ->
## Building) and for kinds with no dedicated glyph. Labels stay within
## kind_for's vocabulary plus Station, Airport, Terminal, Theatre,
## Statue, Memorial, Bridge, Market and Hotel; Peak and Water keep
## their wide standoffs. statue.svg is project-drawn in the Lucide
## outline style (Lucide ships no statue glyph).
static func registry_kind_icon(kind: String, entry_name: String) -> Array:
	var m := _category_for(kind.strip_edges().to_lower())
	if m.is_empty():
		m = _category_for(entry_name.to_lower())
	if m.is_empty():
		m = ["Landmark", "landmark"]
	return m

## [kind label, Lucide icon] for already-lowered text, {} when nothing
## matches. One table serves the entry's `kind` and, for the core icons
## that carry no kind, its name (Eiffel Tower -> Building).
static func _category_for(t: String) -> Array:
	for w in ["cathedral", "church", "basilica", "chapel", "abbey", "mosque",
			"temple", "synagogue", "shrine", "pagoda", "stupa", "gurdwara",
			"monastery", "minster", "duomo"]:
		if t.contains(w):
			return ["Place of worship", "church"]
	for w in ["palace", "castle", "fortress", "citadel", "manor", "kremlin",
			"chateau", "château", "residence"]:
		if t.contains(w):
			return ["Castle", "castle"]
	if t.contains("fort") and not t.contains("effort"):
		return ["Castle", "castle"]
	if t.contains("station") and not t.contains("power"):
		return ["Station", "train-front"]
	if t.contains("airport"):
		return ["Airport", "plane"]
	for w in ["ferry", "cruise", "harbour", "harbor", "terminal", "quay"]:
		if t.contains(w):
			return ["Terminal", "ship"]
	for w in ["museum", "gallery", "arts centre", "science centre",
			"exhibition", "museo"]:
		if t.contains(w):
			return ["Museum", "school"]
	for w in ["opera", "theatre", "theater", "concert hall"]:
		if t.contains(w):
			return ["Theatre", "drama"]
	if t.contains("statue") or t == "moai":
		return ["Statue", "statue"]
	for w in ["memorial", "monument", "tomb", "mausoleum", "obelisk",
			"arch", "column", "stela", "cenotaph"]:
		if t.contains(w):
			return ["Memorial", "landmark"]
	if t.contains("bridge"):
		return ["Bridge", "bridge"]
	for w in ["market", "shopping", "department store", "store", "bazaar", "mall"]:
		if t.contains(w):
			return ["Market", "store"]
	if t.contains("hotel") or t.contains("hostel"):
		return ["Hotel", "hotel"]
	for w in ["tower", "lighthouse", "skyscraper", "stadium", "arena",
			"office", "commercial", "headquarters", "casino", "apartment"]:
		if t.contains(w):
			return ["Building", "building-2"]
	for w in ["garden", "piazza", "square", "park", "plaza"]:
		if t.contains(w):
			return ["Park", "leaf"]
	for w in ["mountain", "peak", "summit", "volcano", "massif", "glacier", "hill"]:
		if t.contains(w):
			return ["Peak", "mountain"]
	for w in ["lake", "island", "waterfall", "beach", "bay"]:
		if t.contains(w):
			return ["Water", "landmark"]
	return []

## [kind label, Lucide icon] from a short description or archetype.
static func kind_for(text: String) -> Array:
	var t := text.to_lower()
	for w in ["mountain", "peak", "summit", "volcano", "massif", "glacier", "hill"]:
		if t.contains(w):
			return ["Peak", "mountain"]
	for w in ["lake", "island", "waterfall", "beach", "bay"]:
		if t.contains(w):
			return ["Water", "landmark"]
	for w in ["church", "cathedral", "basilica", "chapel", "abbey", "mosque",
			"temple", "synagogue", "shrine"]:
		if t.contains(w):
			return ["Place of worship", "landmark"]
	for w in ["museum", "gallery", "opera", "theatre", "theater"]:
		if t.contains(w):
			return ["Museum", "school"]
	for w in ["park", "garden", "square", "plaza"]:
		if t.contains(w):
			return ["Park", "leaf"]
	for w in ["castle", "palace", "fortress", "fort"]:
		if t.contains(w):
			return ["Castle", "landmark"]
	for w in ["tower", "lighthouse", "building", "skyscraper", "stadium", "bridge"]:
		if t.contains(w):
			return ["Building", "building-2"]
	return ["Landmark", "landmark"]

## Metres between the viewpoint and the landmark.
static func standoff_m(s: Dictionary) -> float:
	match str(s.get("kind", "")):
		"Peak":
			return PEAK_M
		"Water":
			return WATER_M
	var h := float(s.get("height_m", 0.0))
	if h <= 0.0:
		return DEFAULT_M
	return clampf(h * 2.2, MIN_M, MAX_M)

## Metres between the viewpoint and the landmark for Get closer: near
## enough that a tower rises over the viewer and a facade fills the view.
static func close_standoff_m(s: Dictionary) -> float:
	return maxf(standoff_m(s) * CLOSE_FACTOR, CLOSE_MIN_M)

## Compass bearing (degrees, from the landmark) the viewer stands on by
## default: the scene opens at afternoon golden hour, so standing
## west-south-west (west-north-west south of the equator) puts the sun
## behind the viewer and on the landmark's face.
static func default_bearing(lat: float) -> float:
	return 250.0 if lat >= 0.0 else 290.0

## Metres between the Explore viewpoint and the landmark.
static func arrival_m(s: Dictionary) -> float:
	match str(s.get("kind", "")):
		"Peak":
			return PEAK_M
		"Water":
			return WATER_M
	return ARRIVAL_M

## Viewpoint (lat, lon) standoff_m away from the landmark on `bearing_deg`.
static func viewpoint(s: Dictionary, bearing_deg: float, override_m: float = -1.0) -> Vector2:
	var lat := float(s["lat"])
	var lon := float(s["lon"])
	var d := override_m if override_m > 0.0 else standoff_m(s)
	var b := deg_to_rad(bearing_deg)
	# WorldScale: +X east, +Z south.
	var xz := Vector2(sin(b) * d, -cos(b) * d)
	return WorldScale.latlon_from_xz(xz.x, xz.y, lat, lon)

## Viewpoint (lat, lon) arrival_m away from the landmark on `bearing_deg`:
## the Explore start for a map selection, 50 m from a regular landmark.
static func arrival_viewpoint(s: Dictionary, bearing_deg: float) -> Vector2:
	return viewpoint(s, bearing_deg, arrival_m(s))

## Compass bearing (degrees) of world XZ offset `d` (+X east, +Z south).
static func bearing_of(d: Vector2) -> float:
	return fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)
