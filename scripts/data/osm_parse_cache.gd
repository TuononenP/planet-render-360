class_name OsmParseCache
extends RefCounted

## Small in-memory LRU of parsed OsmFetcher results keyed by the exact set of
## payload cache paths and centre coordinates. When StreamScout warms a lattice
## centre ahead of time, its parsed features stay ready in memory so the live
## streamed build skips re-reading, merging and re-parsing the same JSON files.

const MAX_ENTRIES := 4
const DISK_VERSION := 1
const PARSER_FILES := ["res://scripts/data/osm_fetcher.gd", "res://scripts/data/osm_tags.gd",
	"res://scripts/data/osm_relations.gd", "res://scripts/data/osm_parse_cache.gd"]

static var _entries: Array = []  # [{key: String, parsed: Dictionary}]
static var _mutex := Mutex.new()
static var _ver_cache := ""

static func _disk_ver() -> String:
	if _ver_cache != "":
		return _ver_cache
	var parts := PackedStringArray([str(CacheStore.DATA_VERSION), str(DISK_VERSION)])
	if OS.is_debug_build():
		for p in PARSER_FILES:
			if FileAccess.file_exists(p):
				parts.append(str(FileAccess.get_modified_time(p)))
	_ver_cache = "|".join(parts)
	return _ver_cache

static func _disk_path(key: String) -> String:
	# osm_v* prefix: accounted in the osm cache layer (CacheStore.layer_of).
	return "%s/osm_v%d_parsed_%08x.bin" % [CacheStore.base_dir(), CacheStore.DATA_VERSION, hash(key) & 0xffffffff]

static func load_or_parse(key: String, parse_fn: Callable) -> Dictionary:
	var hit := _read_disk(key)
	if not hit.is_empty():
		return hit
	var parsed: Dictionary = parse_fn.call()
	if not parsed.is_empty() and not key.is_empty():
		_write_disk(key, parsed)
	return parsed

static func _read_disk(key: String) -> Dictionary:
	if key.is_empty() or DisplayServer.get_name() == "headless":
		return {}
	var path := _disk_path(key)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var raw: Variant = f.get_var(false)
	f.close()
	if not (raw is Dictionary):
		return {}
	var d: Dictionary = raw
	if str(d.get("key", "")) != key or str(d.get("ver", "")) != _disk_ver():
		return {}
	var parsed: Variant = d.get("parsed")
	return parsed as Dictionary if parsed is Dictionary else {}

static func _write_disk(key: String, parsed: Dictionary) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var path := _disk_path(key)
	var tmp := "%s.tmp.%d" % [path, OS.get_thread_caller_id()]
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({"key": key, "ver": _disk_ver(), "parsed": parsed}, false)
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))

static func make_key(lat: float, lon: float, parts: PackedStringArray) -> String:
	return "%.6f_%.6f|%s" % [lat, lon, "|".join(parts)]

static func take(key: String) -> Dictionary:
	if key.is_empty():
		return {}
	_mutex.lock()
	var found: Dictionary = {}
	for i in range(_entries.size() - 1, -1, -1):
		if str(_entries[i]["key"]) == key:
			found = _entries[i]["parsed"]
			# Consume on take so callers (CityOpenData, HeritageZones) never
			# mutate an entry that a later build would read again.
			_entries.remove_at(i)
			break
	_mutex.unlock()
	return found

static func store(key: String, parsed: Dictionary) -> void:
	if key.is_empty() or parsed.is_empty():
		return
	_mutex.lock()
	for i in range(_entries.size() - 1, -1, -1):
		if str(_entries[i]["key"]) == key:
			_entries.remove_at(i)
			break
	_entries.append({"key": key, "parsed": parsed})
	while _entries.size() > MAX_ENTRIES:
		_entries.pop_front()
	_mutex.unlock()

static func clear() -> void:
	_mutex.lock()
	_entries.clear()
	_mutex.unlock()
