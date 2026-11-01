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

static func site(name: String, lat: float, lon: float, description: String = "",
		source: String = "wiki", height_m: float = 0.0) -> Dictionary:
	var k := kind_for(description if description != "" else name)
	return {"id": "%s:%.5f,%.5f" % [source, lat, lon], "name": name,
		"kind": k[0], "icon": k[1], "lat": lat, "lon": lon,
		"height_m": height_m, "description": description,
		"wiki_lang": "", "wiki_title": "", "source": source}

## Curated registry entry (LocationData.landmarks()) -> site.
static func from_registry(entry: Dictionary) -> Dictionary:
	var s := site(str(entry["name"]), float(entry["lat"]), float(entry["lon"]),
		"Landmark", "curated", float(entry.get("height_m", 0.0)))
	s["id"] = "curated:" + str(entry["type"])
	s["kind"] = "Landmark"
	s["icon"] = "landmark"
	s["wiki_lang"] = "en"
	s["wiki_title"] = str(entry.get("wiki_title", entry["name"]))
	return s

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
			return ["Museum", "building-2"]
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

## Viewpoint (lat, lon) standoff_m away from the landmark on `bearing_deg`.
static func viewpoint(s: Dictionary, bearing_deg: float) -> Vector2:
	var lat := float(s["lat"])
	var lon := float(s["lon"])
	var d := standoff_m(s)
	var b := deg_to_rad(bearing_deg)
	# WorldScale: +X east, +Z south.
	var xz := Vector2(sin(b) * d, -cos(b) * d)
	return WorldScale.latlon_from_xz(xz.x, xz.y, lat, lon)

## Compass bearing (degrees) of world XZ offset `d` (+X east, +Z south).
static func bearing_of(d: Vector2) -> float:
	return fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)
