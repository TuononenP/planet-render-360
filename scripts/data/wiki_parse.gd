class_name WikiParse
extends RefCounted

## URLs and parsers for WikiFetcher (landmark details): Wikipedia
## GeoSearch for nearby landmarks, the REST page summary for the panel,
## and Commons imageinfo for a free photo and its credit. Pure functions
## so tests run on fixtures, never the network.
##
## GeoSearch returns every geotagged article (stations, schools, events)
## nearest first and its coordinate `type` is almost always empty, so
## nearby landmarks are picked by their short description: a physical-
## place word keeps a page, a non-place word drops it, and article
## length ranks what is left (verified 2026-11-01: Matterhorn, Eiffel
## Tower, Turku Cathedral rank at the top of their areas).

const LANG := "en"
const MAX_SITES := 25
const PHOTO_WIDTH := 640

## Whole words (a trailing "s" is ignored): "arch" must not keep "research".
const KEEP := ["tower", "cathedral", "church", "chapel", "basilica", "abbey",
	"monastery", "mosque", "temple", "shrine", "synagogue", "castle", "palace",
	"fortress", "fort", "citadel", "museum", "gallery", "bridge", "monument",
	"memorial", "statue", "arch", "obelisk", "column", "garden", "park",
	"square", "plaza", "mountain", "peak", "summit", "massif", "volcano",
	"glacier", "lake", "waterfall", "island", "lighthouse", "stadium", "arena",
	"opera", "theatre", "theater", "observatory", "building", "skyscraper",
	"pyramid", "ruin", "archaeological", "gate", "landmark", "hill", "canyon",
	"cliff", "beach", "fountain", "amphitheatre", "windmill", "dome", "minaret"]
## Word prefixes, plus phrases matched anywhere in the description.
const DROP := ["station", "school", "universit", "college", "street", "avenue",
	"boulevard", "road", "district", "arrondissement", "commune",
	"municipalit", "neighbourhood", "neighborhood", "suburb", "village",
	"company", "organization", "organisation", "attack", "massacre", "event",
	"election", "hotel", "hospital", "tramway", "railway", "metro", "bus",
	"airport", "battle", "ship", "range", "province", "region", "hut"]
const DROP_PHRASES := ["town in", "city in", "place in", "fire of"]

static func nearby_url(lat: float, lon: float, radius_m: int) -> String:
	return ("https://%s.wikipedia.org/w/api.php?action=query&format=json&formatversion=2"
		+ "&generator=geosearch&ggscoord=%.5f%%7C%.5f&ggsradius=%d&ggslimit=500"
		+ "&ggsprimary=primary&prop=info%%7Cdescription%%7Ccoordinates") \
		% [LANG, lat, lon, clampi(radius_m, 10, 10000)]

static func summary_url(lang: String, title: String) -> String:
	return "https://%s.wikipedia.org/api/rest_v1/page/summary/%s" % [lang,
		title.strip_edges().replace(" ", "_").uri_encode()]

static func imageinfo_url(file: String) -> String:
	return ("https://commons.wikimedia.org/w/api.php?action=query&format=json"
		+ "&formatversion=2&titles=File:%s&prop=imageinfo&iiprop=url%%7Cextmetadata"
		+ "&iiurlwidth=%d&iiextmetadatafilter=Artist%%7CLicenseShortName") \
		% [file.replace(" ", "_").uri_encode(), PHOTO_WIDTH]

## True when a description names a physical place worth a marker.
static func is_place(description: String) -> bool:
	var d := description.to_lower()
	for phrase in DROP_PHRASES:
		if d.contains(phrase):
			return false
	var words := _words(d)
	for w in words:
		for prefix in DROP:
			if w.begins_with(prefix):
				return false
	for w in words:
		if w in KEEP or w.trim_suffix("s") in KEEP or w.trim_suffix("es") in KEEP:
			return true
	return false

static func _words(lowered: String) -> PackedStringArray:
	var re := RegEx.new()
	re.compile("\\p{L}+")
	var out := PackedStringArray()
	for m in re.search_all(lowered):
		out.append(m.get_string())
	return out

## GeoSearch payload -> landmark sites (LandmarkVisit shape), longest
## articles first, at most MAX_SITES.
static func parse_nearby(text: String) -> Array:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return []
	var query: Variant = (parsed as Dictionary).get("query", {})
	var pages: Variant = (query as Dictionary).get("pages", []) if query is Dictionary else []
	if not pages is Array:
		return []
	var keep: Array = []
	for p in pages:
		if not p is Dictionary:
			continue
		var page := p as Dictionary
		var desc := str(page.get("description", ""))
		var coords: Variant = page.get("coordinates", [])
		if not is_place(desc) or not coords is Array or (coords as Array).is_empty():
			continue
		var c: Dictionary = (coords as Array)[0]
		keep.append([int(page.get("length", 0)), page, c])
	keep.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	var out: Array = []
	for item in keep.slice(0, MAX_SITES):
		var page: Dictionary = item[1]
		var title := str(page.get("title", ""))
		var site := LandmarkVisit.site(title, float(item[2].get("lat", 0.0)),
			float(item[2].get("lon", 0.0)), str(page.get("description", "")), "wiki")
		site["wiki_lang"] = LANG
		site["wiki_title"] = title
		out.append(site)
	return out

## REST summary -> {title, description, extract, url, image}; {} when
## the payload is not a standard article (disambiguation, missing).
static func parse_summary(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {}
	var d := parsed as Dictionary
	if str(d.get("type", "")) != "standard" or str(d.get("extract", "")) == "":
		return {}
	var urls: Variant = d.get("content_urls", {})
	var desktop: Variant = (urls as Dictionary).get("desktop", {}) if urls is Dictionary else {}
	var image: Variant = d.get("originalimage", {})
	return {
		"title": str(d.get("title", "")),
		"description": str(d.get("description", "")),
		"extract": str(d.get("extract", "")),
		"url": str((desktop as Dictionary).get("page", "")) if desktop is Dictionary else "",
		"image": str((image as Dictionary).get("source", "")) if image is Dictionary else "",
	}

## Only Commons files carry a free licence; /wikipedia/<lang>/ uploads
## are often non-free logos (the Eiffel Tower's lead image is one).
static func is_free_image(url: String) -> bool:
	return url.contains("/wikipedia/commons/")

## Commons file name of an image URL ("Matterhorn_from_Domhütte_-_2.jpg").
static func image_file(url: String) -> String:
	if not is_free_image(url):
		return ""
	var path := url.split("?")[0]
	var parts := path.split("/")
	# Thumbnails end in "<w>px-<file>" under /thumb/<a>/<ab>/<file>/.
	var idx := parts.find("thumb")
	var file := parts[idx + 3] if idx >= 0 and parts.size() > idx + 3 else parts[parts.size() - 1]
	return file.uri_decode()

## Commons imageinfo -> {url, credit}; credit is "Artist · Licence" in
## plain text. {} when the file has no thumbnail.
static func parse_imageinfo(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {}
	var query: Variant = (parsed as Dictionary).get("query", {})
	var pages: Variant = (query as Dictionary).get("pages", []) if query is Dictionary else []
	if not pages is Array or (pages as Array).is_empty():
		return {}
	var infos: Variant = ((pages as Array)[0] as Dictionary).get("imageinfo", [])
	if not infos is Array or (infos as Array).is_empty():
		return {}
	var ii: Dictionary = (infos as Array)[0]
	var url := str(ii.get("thumburl", ""))
	if url == "":
		return {}
	var meta: Dictionary = ii.get("extmetadata", {}) if ii.get("extmetadata", {}) is Dictionary else {}
	var artist := plain_text(str((meta.get("Artist", {}) as Dictionary).get("value", ""))) \
		if meta.get("Artist", {}) is Dictionary else ""
	var licence := str((meta.get("LicenseShortName", {}) as Dictionary).get("value", "")) \
		if meta.get("LicenseShortName", {}) is Dictionary else ""
	if artist.length() > 60:
		artist = artist.substr(0, 59).strip_edges() + "…"
	var parts: Array = []
	for s in [artist, licence]:
		if str(s) != "":
			parts.append(s)
	return {"url": url, "credit": " · ".join(parts)}

## HTML fragment -> one line of text (Commons Artist fields are HTML).
static func plain_text(html: String) -> String:
	var re := RegEx.new()
	re.compile("<[^>]*>")
	var t := re.sub(html, " ", true)
	t = t.replace("&amp;", "&").replace("&quot;", "\"").replace("&#39;", "'").replace("&nbsp;", " ")
	re.compile("\\s+")
	return re.sub(t, " ", true).strip_edges()

## The nearby article for a site known only by name (an OSM callout):
## same name ignoring case and punctuation, or one contains the other
## and is most of it ("Turku Cathedral" / "The Turku Cathedral", never
## a bare "Tower" for "Eiffel Tower").
static func match_name(name: String, sites: Array) -> Dictionary:
	var want := _norm(name)
	if want.length() < 3:
		return {}
	for s in sites:
		if _norm(str(s.get("name", ""))) == want:
			return s
	for s in sites:
		var n := _norm(str(s.get("name", "")))
		var short := mini(n.length(), want.length())
		if short >= 0.6 * maxi(n.length(), want.length()) and (n.contains(want) or want.contains(n)):
			return s
	return {}

static func _norm(s: String) -> String:
	var re := RegEx.new()
	re.compile("[^\\p{L}\\p{N}]+")
	return re.sub(s.to_lower(), "", true)

## OSM `wikipedia` tag "fi:Turun tuomiokirkko" -> ["fi", "Turun tuomiokirkko"].
static func split_tag(tag: String) -> Array:
	var i := tag.find(":")
	if i <= 0 or i > 12:
		return []
	return [tag.substr(0, i).strip_edges(), tag.substr(i + 1).strip_edges()]
