class_name OsmParseCache
extends RefCounted

## Small in-memory LRU of parsed OsmFetcher results keyed by the exact set of
## payload cache paths and centre coordinates. When StreamScout warms a lattice
## centre ahead of time, its parsed features stay ready in memory so the live
## streamed build skips re-reading, merging and re-parsing the same JSON files.

const MAX_ENTRIES := 4

static var _entries: Array = []  # [{key: String, parsed: Dictionary}]
static var _mutex := Mutex.new()

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
