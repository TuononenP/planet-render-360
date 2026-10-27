class_name CacheStore
extends RefCounted

## On-device history + cache index. No server, no account: a JSON file in
## user:// is the whole store. Generated terrain is reproducible from the
## stored coordinates + seed, so history entries double as cache keys.

const PATH := "user://history.json"
const MAX_ENTRIES := 50

var entries: Array[Dictionary] = []

func load_store() -> void:
	entries.clear()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				entries.append(item)

func save_store() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("CacheStore: cannot write %s" % PATH)
		return
	f.store_string(JSON.stringify(entries))

func add_entry(place_name: String, lat: float, lon: float) -> void:
	entries = entries.filter(func(e: Dictionary) -> bool:
		return not (abs(float(e.get("lat", 999.0)) - lat) < 0.0001 \
			and abs(float(e.get("lon", 999.0)) - lon) < 0.0001))
	entries.push_front({
		"name": place_name, "lat": lat, "lon": lon,
		"cached": true, "timestamp": Time.get_unix_time_from_system(),
	})
	while entries.size() > MAX_ENTRIES:
		entries.pop_back()
	save_store()

func clear() -> void:
	entries.clear()
	save_store()
