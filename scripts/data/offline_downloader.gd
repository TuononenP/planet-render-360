class_name OfflineDownloader
extends Node

## "Download for offline": warms every on-device cache for a place
## (DEM + far DEM, OSM features, satellite mosaic) without rendering
## it, so opening it later works with networking disabled. The
## fetchers already write user://cache; this just drives them all
## and reports progress. Map-picker tiles cache themselves as the
## user pans; they are not bulk-prefetched (tile usage policy).

signal progress(done: int, total: int)
signal finished(ok_count: int, total: int)

const JOBS := 4  # detailed DEM, far DEM, OSM, satellite

var _done := 0
var _ok := 0
var _running := false

func download(lat: float, lon: float, quality_preset: int = 2) -> void:
	if _running:
		return
	_running = true
	_done = 0
	_ok = 0
	var dem := DemFetcher.new()
	add_child(dem)
	dem.succeeded.connect(func(_h: PackedFloat32Array, _g: int) -> void: _job(true))
	dem.failed.connect(func(_r: String) -> void: _job(false))
	dem.fetch(lat, lon, RenderSettings.grid_size_for(quality_preset))
	var far := DemFetcher.new()
	add_child(far)
	far.succeeded.connect(func(_h: PackedFloat32Array, _g: int) -> void: _job(true))
	far.failed.connect(func(_r: String) -> void: _job(false))
	far.fetch_far(lat, lon, RenderSettings.far_grid_size_for(quality_preset))
	var osm := OsmFetcher.new()
	add_child(osm)
	osm.succeeded.connect(func(_b: Array, _r: Array, _l: Array, _lm: Array) -> void: _job(true))
	osm.failed.connect(func(_r: String) -> void: _job(false))
	osm.fetch(lat, lon)
	var sat := SatelliteFetcher.new()
	add_child(sat)
	sat.succeeded.connect(func(_t: Texture2D, _i: Image, _o: Vector2, _z: int) -> void: _job(true))
	sat.failed.connect(func(_r: String) -> void: _job(false))
	sat.fetch(lat, lon, 16)

func _job(ok: bool) -> void:
	if ok:
		_ok += 1
	_done += 1
	progress.emit(_done, JOBS)
	if _done >= JOBS:
		_running = false
		finished.emit(_ok, JOBS)
		for child in get_children():
			child.queue_free()

## Total bytes held in the offline cache (DEM/OSM/satellite/tiles).
static func cache_size_bytes() -> int:
	return _dir_size("user://cache")

static func _dir_size(path: String) -> int:
	var total := 0
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path + "/" + name
		if dir.current_is_dir():
			total += _dir_size(full)
		else:
			var f := FileAccess.open(full, FileAccess.READ)
			if f != null:
				total += int(f.get_length())
		name = dir.get_next()
	dir.list_dir_end()
	return total

## Delete the whole offline cache (history entries stay; their
## places simply re-download on next open).
static func clear_cache() -> void:
	_remove_dir("user://cache")
	DirAccess.make_dir_recursive_absolute("user://cache")

static func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path + "/" + name
		if dir.current_is_dir():
			_remove_dir(full)
		else:
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
