class_name WikiFetcher
extends Node

## Landmark details from Wikipedia and Wikimedia Commons (free, no key,
## no account; docs/data-source-register.md). Three channels, one
## request in flight each, a newer ask replacing a queued one:
##  - nearby(): GeoSearch -> landmark sites around a point (map markers,
##    360 callouts)
##  - describe(): REST page summary for the landmark panel, then the
##    lead photo when it is a Commons file, with its credit
## Every answer is cached under user://cache (CacheStore wiki_* keys,
## LRU tracked), so cached places keep their markers and cards offline.
## Requests identify the app with a contact URL (Wikimedia etiquette).

signal nearby_ready(lat: float, lon: float, radius_m: int, sites: Array)
signal info_ready(id: String, info: Dictionary)
signal info_failed(id: String, reason: String)
signal photo_ready(id: String, texture: Texture2D, credit: String)

const USER_AGENT := Brand.USER_AGENT
## Panel copy in the design system's voice: the card still shows the
## name, kind and readouts, so these read as a missing layer, not errors.
const NO_ARTICLE := "No article found for this place."
const OFFLINE := "You're offline. Details open when you're back online."
const UNREACHABLE := "Details didn't arrive. Try again in a moment."

## Test hook (OsmFetcher precedent): answer from the cache only.
var offline_mode := false
## Whether the last failed request found the device offline.
var offline := false

var _near_http: HTTPRequest
var _near_busy := false
var _near_queued: Array = []  # [lat, lon, radius_m] waiting behind the busy one
var _sum_http: HTTPRequest
var _info_http: HTTPRequest
var _img_http: HTTPRequest
var _detail_busy := false
var _want: Dictionary = {}  # the site the panel shows now

func _ready() -> void:
	_near_http = _make_http(20.0)
	_sum_http = _make_http(15.0)
	_info_http = _make_http(15.0)
	_img_http = _make_http(20.0)
	DirAccess.make_dir_recursive_absolute(CacheStore.base_dir())

func _make_http(timeout_s: float) -> HTTPRequest:
	var http := HTTPRequest.new()
	http.timeout = timeout_s
	add_child(http)
	return http

## Nearby landmark sites; answers through nearby_ready (instantly from
## the cache). Radius is clamped to GeoSearch's 10 km.
func nearby(lat: float, lon: float, radius_m: int) -> void:
	radius_m = clampi(radius_m, 500, 10000)
	if _near_busy:
		_near_queued = [lat, lon, radius_m]
		return
	_near_busy = true
	var res := await _fetch(_near_http, WikiParse.nearby_url(lat, lon, radius_m),
		CacheStore.wiki_near_path(lat, lon, radius_m))
	_near_busy = false
	nearby_ready.emit(lat, lon, radius_m, WikiParse.parse_nearby(res[1]) if res[0] else [])
	if not _near_queued.is_empty():
		var q := _near_queued
		_near_queued = []
		nearby(float(q[0]), float(q[1]), int(q[2]))

## Article for `site` (LandmarkVisit shape): info_ready or info_failed,
## then photo_ready when the lead image is free. Only the latest site
## asked for is answered.
func describe(site: Dictionary) -> void:
	_want = site
	if _detail_busy:
		return
	_detail_busy = true
	while true:
		var cur := _want
		await _describe_one(cur)
		if str(_want.get("id", "")) == str(cur.get("id", "")):
			break
	_detail_busy = false

## The article a site points at: [lang, title], or [] for none.
static func article_of(site: Dictionary) -> Array:
	if str(site.get("wiki_title", "")) != "":
		var lang := str(site.get("wiki_lang", ""))
		return [lang if lang != "" else WikiParse.LANG, str(site["wiki_title"])]
	return WikiParse.split_tag(str(site.get("wikipedia", "")))

func _describe_one(site: Dictionary) -> void:
	var id := str(site.get("id", ""))
	var art := article_of(site)
	if art.is_empty():
		info_failed.emit(id, NO_ARTICLE)
		return
	var res := await _fetch(_sum_http, WikiParse.summary_url(art[0], art[1]),
		CacheStore.wiki_summary_path(art[0], art[1]))
	if not _current(id):
		return
	var info := WikiParse.parse_summary(res[1]) if res[0] else {}
	if info.is_empty():
		info_failed.emit(id, NO_ARTICLE if res[0] or int(res[2]) == 404 \
			else (OFFLINE if offline else UNREACHABLE))
		return
	info_ready.emit(id, info)
	var file := WikiParse.image_file(str(info.get("image", "")))
	if file == "":
		return
	var meta := await _fetch(_info_http, WikiParse.imageinfo_url(file),
		CacheStore.wiki_photo_path(file))
	var photo := WikiParse.parse_imageinfo(meta[1]) if meta[0] else {}
	if photo.is_empty() or not _current(id):
		return
	var tex := await _fetch_texture(str(photo["url"]), CacheStore.wiki_photo_bytes_path(file))
	if tex != null and _current(id):
		photo_ready.emit(id, tex, str(photo["credit"]))

func _current(id: String) -> bool:
	return str(_want.get("id", "")) == id

## GET `url` through the cache: [ok, text, http code].
func _fetch(http: HTTPRequest, url: String, cache_path: String) -> Array:
	if FileAccess.file_exists(cache_path):
		CacheStore.note_read(cache_path)
		return [true, FileAccess.get_file_as_string(cache_path), 200]
	if offline_mode:
		offline = true
		return [false, "", 0]
	var got := await _request(http, url)
	var body: PackedByteArray = got[0]
	if body.is_empty():
		return [false, "", got[1]]
	var text := body.get_string_from_utf8()
	var f := FileAccess.open(cache_path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
		CacheStore.note_written(cache_path)
	return [true, text, 200]

func _fetch_texture(url: String, cache_path: String) -> Texture2D:
	var bytes := PackedByteArray()
	if FileAccess.file_exists(cache_path):
		CacheStore.note_read(cache_path)
		bytes = FileAccess.get_file_as_bytes(cache_path)
	elif not offline_mode:
		bytes = (await _request(_img_http, url, "image/*"))[0]
		if not bytes.is_empty():
			var f := FileAccess.open(cache_path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(bytes)
				f.close()
				CacheStore.note_written(cache_path)
	return decode_image(bytes)

## JPEG / PNG / WebP bytes -> texture, null when undecodable.
static func decode_image(bytes: PackedByteArray) -> Texture2D:
	if bytes.size() < 12:
		return null
	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if bytes[0] == 0xFF and bytes[1] == 0xD8:
		err = img.load_jpg_from_buffer(bytes)
	elif bytes[0] == 0x89 and bytes[1] == 0x50:
		err = img.load_png_from_buffer(bytes)
	elif bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		err = img.load_webp_from_buffer(bytes)
	if err != OK or img.is_empty():
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## One GET on `http`: [body, http code]; the body is empty on any
## failure (and `offline` says whether the device was offline).
func _request(http: HTTPRequest, url: String, accept: String = "application/json") -> Array:
	var err := http.request(url, ["User-Agent: %s" % USER_AGENT, "Accept: %s" % accept])
	if err != OK:
		push_warning("WikiFetcher: request failed to start: %s" % err)
		return [PackedByteArray(), 0]
	var done: Array = await http.request_completed
	var result: int = done[0]
	var code: int = done[1]
	offline = result in [HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CANT_RESOLVE]
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("WikiFetcher: %s failed (result=%d code=%d)" % [url.get_slice("?", 0), result, code])
		return [PackedByteArray(), code]
	return [done[3], code]
