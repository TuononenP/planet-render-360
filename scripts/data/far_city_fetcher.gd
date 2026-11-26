class_name FarCityFetcher
extends Node

## T5.4 — the far city's real data: ONE aggregated request per place
## (register rate discipline), Postpass first and then Overpass
## (LayerRequest), cached, best-effort.
##  - built-up landuse (residential / commercial / industrial / retail
##    ways + multipolygon relations) to RADIUS_M: where the distant city
##    is and what kind of fabric it is (LocationData.far_landuse);
##  - real tall buildings (height ≥ TOWER_MIN_M or ≥ TOWER_MIN_LEVELS
##    levels) with their footprints: the only source of far modern-tower
##    clusters (LocationData.far_towers) — La Défense appears west of
##    Paris because OSM maps it, never because a rule guessed it.
## Absence is graceful: a failed/uncached fetch emits empty arrays and
## SettlementMap falls back to the far imagery drapes alone. Building
## parts are asked for only around the tall outlines (PARTS_REACH_M), not
## across the whole disc.

signal finished(landuse: Array, towers: Array)

const RADIUS_M := 12000
const TOWER_MIN_M := 50
const TOWER_MIN_LEVELS := 15
const CAP_LANDUSE := 6000
const CAP_RELATIONS := 400
const CAP_TOWERS := 3000
## Higher server-side limits leave room for client-side prominence selection.
const CAP_TOWER_CANDIDATES := 12000
const CAP_NEAR_TOWERS := 6000
const CAP_NEAR_PARTS := 8000
const CAP_TOWER_PARTS := 12000
const NEAR_RADIUS_M := 4000
## Parts are fetched only this close to a tall outline or part, where
## _nest_parts can place them; parts elsewhere in the disc were dropped
## after a 12 km download. Measured to the outline (`around.set`), so it
## also reaches parts in the middle of a podium up to ~200 m across.
## No QUERY_VERSION bump: a cached payload that holds every part is a
## superset and parses the same.
const PARTS_REACH_M := 100
## Bump only this layer when the tower selector changes.
const QUERY_VERSION := 3
const ATTEMPT_TIMEOUT := 45.0
const LANDUSE := "^(residential|commercial|industrial|retail)$"

var offline_mode := false
## {ms, bytes, cached, landuse, towers} of the last fetch.
var timings: Dictionary = {}

var _req: LayerRequest
var _busy := false
## A streamed run (GenerationPipeline.background) asks around the nearest
## point of a lattice COARSE_CELLS wider than StreamLattice's (~2.7 km for a
## 12 km far-city radius) so consecutive stretches share one query and cache;
## features are still placed around the stretch's own centre.
const COARSE_CELLS := 6
var coarse := false
var warm_only := false

const PARSED_CACHE_MAX := 3
static var _parsed_cache: Array = []  # [{key, lat, lon, bytes, partial, landuse, towers}]
static var _parsed_mutex := Mutex.new()

static func clear_static_caches() -> void:
	_parsed_mutex.lock()
	_parsed_cache.clear()
	_parsed_mutex.unlock()

static func _lookup_parsed(key: String, mtime: int) -> Dictionary:
	_parsed_mutex.lock()
	var found := {}
	for i in range(_parsed_cache.size() - 1, -1, -1):
		if str(_parsed_cache[i]["key"]) == key and int(_parsed_cache[i].get("mtime", -2)) == mtime:
			found = _parsed_cache[i]
			break
	_parsed_mutex.unlock()
	return found

static func _store_parsed(key: String, mtime: int, lat: float, lon: float, bytes: int, partial: bool, parsed: Dictionary) -> void:
	if key.is_empty() or parsed.is_empty():
		return
	_parsed_mutex.lock()
	for i in range(_parsed_cache.size() - 1, -1, -1):
		if str(_parsed_cache[i]["key"]) == key:
			_parsed_cache.remove_at(i)
			break
	_parsed_cache.append({"key": key, "mtime": mtime, "lat": lat, "lon": lon, "bytes": bytes, "partial": partial,
		"landuse": parsed["landuse"], "towers": parsed["towers"]})
	while _parsed_cache.size() > PARSED_CACHE_MAX:
		_parsed_cache.pop_front()
	_parsed_mutex.unlock()

## Shifts previously loaded far_landuse and far_towers from the live centre
## into a new streamed centre's XZ frame (adding `offset` = old centre in new
## frame). Used as an immediate fallback when the next coarse cell is still
## waiting behind PostpassGate.
static func remap_far(landuse: Array, towers: Array, offset: Vector2) -> Dictionary:
	var lu_out: Array = []
	for poly in landuse:
		if not (poly is Dictionary):
			continue
		var d: Dictionary = (poly as Dictionary).duplicate()
		d["points"] = _shift_ring(d.get("points", PackedVector2Array()), offset)
		var holes: Array = []
		for h in d.get("holes", []):
			holes.append(_shift_ring(h, offset))
		d["holes"] = holes
		lu_out.append(d)
	var tw_out: Array = []
	for tw in towers:
		if not (tw is Dictionary):
			continue
		var d: Dictionary = (tw as Dictionary).duplicate()
		d["x"] = float(d.get("x", 0.0)) + offset.x
		d["z"] = float(d.get("z", 0.0)) + offset.y
		if d.has("footprint"):
			d["footprint"] = _shift_ring(d["footprint"], offset)
		if d.has("holes"):
			var holes: Array = []
			for h in d["holes"]:
				holes.append(_shift_ring(h, offset))
			d["holes"] = holes
		if d.has("parts"):
			var parts: Array = []
			for p in d["parts"]:
				if p is Dictionary:
					var pd: Dictionary = (p as Dictionary).duplicate()
					if pd.has("x"):
						pd["x"] = float(pd["x"]) + offset.x
					if pd.has("z"):
						pd["z"] = float(pd["z"]) + offset.y
					if pd.has("footprint"):
						pd["footprint"] = _shift_ring(pd["footprint"], offset)
					if pd.has("holes"):
						var pholes: Array = []
						for ph in pd["holes"]:
							pholes.append(_shift_ring(ph, offset))
						pd["holes"] = pholes
					parts.append(pd)
			d["parts"] = parts
		tw_out.append(d)
	return {"landuse": lu_out, "towers": tw_out}

static func _shift_ring(pts: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = pts[i] + offset
	return out
## The centre asked about (and cached under), and the one parsed around.
var _lat := 0.0
var _lon := 0.0
var _c_lat := 0.0
var _c_lon := 0.0
var _cache := ""
var _t0 := 0
var _parse_task := -1
## Bumped per fetch and cancel: a parse finishing late is dropped.
var _gen := 0
var _partial := false

func _ready() -> void:
	_req = LayerRequest.new(ATTEMPT_TIMEOUT, ATTEMPT_TIMEOUT)
	add_child(_req)
	_req.answered.connect(_on_answered)
	_req.exhausted.connect(func(reason: String, _attempts: int) -> void:
		_fallback(reason))

## The parse task must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_parse()

## The main instance first, as no mirror answers (2026-11-11, see
## OsmFetcher.ENDPOINTS). Named by host so reordering
## OsmFetcher.ENDPOINTS cannot change them.
static func endpoints() -> Array[String]:
	return OsmFetcher.endpoint_order(["//overpass-api.de", "private.coffee"])

func is_busy() -> bool:
	return _busy

static func cache_path(lat: float, lon: float) -> String:
	# osm_v* prefix: accounted in the osm cache layer (CacheStore.layer_of).
	return "%s/osm_v%d_%d_%d_farcity%d_q%d.json" % [CacheStore.base_dir(),
		CacheStore.DATA_VERSION, CacheStore.quant(lat), CacheStore.quant(lon), RADIUS_M, QUERY_VERSION]

static func legacy_cache_path(lat: float, lon: float) -> String:
	return "%s/osm_v%d_%d_%d_farcity%d.json" % [CacheStore.base_dir(),
		CacheStore.DATA_VERSION, CacheStore.quant(lat), CacheStore.quant(lon), RADIUS_M]

## Select both ways and multipolygon relations, retaining the explicit
## feet conversion rather than treating a feet-tagged height as metres.
static func _tower_selectors(around: String) -> String:
	var out := ""
	for typ in ["way", "relation"]:
		var mp := '["type"="multipolygon"]' if typ == "relation" else ""
		for key in ["building", "building:part"]:
			out += ('%s["%s"]%s["height"!~"([fF][tT]|\u0027) *$"]'
				+ '(if:number(t["height"])>=%d)%s;') % [typ, key, mp, TOWER_MIN_M, around]
			out += ('%s["%s"]%s["height"~"([fF][tT]|\u0027) *$"]'
				+ '(if:number(t["height"])*0.3048>=%d)%s;') % [typ, key, mp, TOWER_MIN_M, around]
			out += '%s["%s"]%s(if:number(t["building:levels"])>=%d)%s;' \
				% [typ, key, mp, TOWER_MIN_LEVELS, around]
	return out

static func build_query(lat: float, lon: float, radius_m: int = RADIUS_M) -> String:
	var around := "(around:%d,%.6f,%.6f)" % [radius_m, lat, lon]
	var near := "(around:%d,%.6f,%.6f)" % [mini(radius_m, NEAR_RADIUS_M), lat, lon]
	# The near set is printed separately before the wider set: Overpass's
	# output cap is ID-ordered, so it must not erase the foreground.
	return "[out:json][timeout:%d];" % OsmFetcher.OVERPASS_TIMEOUT_S \
		+ 'way["landuse"~"%s"]%s;out geom %d;' % [LANDUSE, around, CAP_LANDUSE] \
		+ 'relation["landuse"~"%s"]["type"="multipolygon"]%s;out geom %d;' \
			% [LANDUSE, around, CAP_RELATIONS] \
		+ '(%s)->.near; .near out geom %d;' % [_tower_selectors(near), CAP_NEAR_TOWERS] \
		+ '(%s)->.wide; .wide out geom %d;' % [_tower_selectors(around), CAP_TOWER_CANDIDATES] \
		+ _parts_of(".near", CAP_NEAR_PARTS) + _parts_of(".wide", CAP_TOWER_PARTS)

## Building parts within PARTS_REACH_M of the tall set `set_name`.
static func _parts_of(set_name: String, cap: int) -> String:
	var reach := "(around%s:%d)" % [set_name, PARTS_REACH_M]
	return '(way["building:part"]%s;relation["building:part"]["type"="multipolygon"]%s;);out geom %d;' \
		% [reach, reach, cap]

func cancel() -> void:
	_gen += 1
	if _req != null:
		_req.cancel()
	_busy = false

## Bundled snapshots load on a worker; created on first use.
var _snapshots: SnapshotReader

func _reader() -> SnapshotReader:
	if _snapshots == null:
		_snapshots = SnapshotReader.new()
		add_child(_snapshots)
	return _snapshots

func fetch(lat: float, lon: float) -> void:
	cancel()
	var gen := _gen
	_c_lat = lat
	_c_lon = lon
	if coarse:
		var cell := StreamLattice.snap(Vector2(lat, lon), COARSE_CELLS)
		lat = cell.x
		lon = cell.y
	_lat = lat
	_lon = lon
	_t0 = Time.get_ticks_msec()
	_cache = cache_path(lat, lon)
	_busy = true
	_partial = false
	var snapshot := BundledOsm.entry_for(lat, lon, "far", QUERY_VERSION)
	var disk_newer := BundledOsm.cache_is_newer(_cache, snapshot) and FileAccess.file_exists(_cache)
	var disk_mtime := int(FileAccess.get_modified_time(_cache)) if disk_newer else -1
	if disk_newer:
		var mem := _lookup_parsed(_cache, disk_mtime)
		if not mem.is_empty():
			_partial = bool(mem["partial"])
			if warm_only:
				_emit_deferred(gen, int(mem["bytes"]), true, {"landuse": [], "towers": []})
				return
			_remap_off_thread(gen, mem)
			return
		if warm_only:
			var f := FileAccess.open(_cache, FileAccess.READ)
			var flen := int(f.get_length()) if f != null else 0
			if flen > 64:
				CacheStore.note_read(_cache)
				_emit_deferred(gen, flen, true, {"landuse": [], "towers": []})
				return
		_read_and_parse_off_thread(_cache, disk_mtime, true)
		return
	var bundled_mem := _lookup_parsed(_cache + "#bundled", 0)
	if not bundled_mem.is_empty():
		_partial = false
		if warm_only:
			_emit_deferred(gen, int(bundled_mem["bytes"]), true, {"landuse": [], "towers": []})
			return
		_remap_off_thread(gen, bundled_mem)
		return
	var bundled := await _reader().read(snapshot)
	if gen != _gen:
		return
	if bundled != "":
		if warm_only:
			_emit_deferred(gen, bundled.length(), true, {"landuse": [], "towers": []})
			return
		_parse_off_thread(bundled, true, false, true)
		return
	_request()

func _request() -> void:
	if offline_mode:
		_fallback("offline")
		return
	# An older or partial copy (see _fallback) is served rather than
	# waiting the full first-byte time on a queued instance.
	var has_copy := false
	for old_path in _fallback_paths(_lat, _lon):
		has_copy = has_copy or FileAccess.file_exists(old_path)
	_req.overpass.first_byte_timeout = OverpassRequest.FALLBACK_FIRST_BYTE_S if has_copy \
		else OverpassRequest.FIRST_BYTE_TIMEOUT
	_req.run(PostpassLayers.build_far_body(_lat, _lon), "data=" + build_query(_lat, _lon).uri_encode(),
		func(text: String) -> String: return "" if _usable(text) else "unusable payload",
		endpoints())

func _on_answered(text: String) -> void:
	OsmFetcher._write_cache(_cache, text)
	if warm_only:
		_emit(text.length(), false, {"landuse": [], "towers": []})
		return
	_parse_off_thread(text, false)

## Older payloads are usable offline, but never prevent a live refresh of
## the new query when the network is available.
func _fallback(reason: String) -> void:
	for old_path in _fallback_paths(_lat, _lon):
		var old := OsmFetcher._read_cache(old_path)
		var payload: Variant = JSON.parse_string(old) if old != "" else null
		if payload is Dictionary and payload.get("elements", null) is Array:
			_partial = str(payload.get("remark", "")).strip_edges() != ""
			print("FarCityFetcher: %s; using %sfar-city cache" % [reason, "partial " if _partial else "older "])
			_parse_off_thread(old, true, true)
			return
	print("FarCityFetcher: %s; far city from imagery only" % reason)
	_emit(0, false, parse("", _lat, _lon))

static func _fallback_paths(lat: float, lon: float) -> Array[String]:
	return [cache_path(lat, lon), cache_path(lat, lon).replace("_q%d.json" % QUERY_VERSION,
		"_q%d.json" % (QUERY_VERSION - 1)), legacy_cache_path(lat, lon)]

static func _usable(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and (parsed as Dictionary).get("elements", null) is Array \
		and str(parsed.get("remark", "")).strip_edges() == ""

func _emit_deferred(gen: int, bytes: int, cached: bool, parsed: Dictionary) -> void:
	(func() -> void:
		if gen == _gen:
			_emit(bytes, cached, parsed)).call_deferred()

func _remap_off_thread(gen: int, mem: Dictionary) -> void:
	_join_parse()
	var c_lat := _c_lat
	var c_lon := _c_lon
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		var base_lat := float(mem["lat"])
		var base_lon := float(mem["lon"])
		var out: Dictionary
		if is_equal_approx(base_lat, c_lat) and is_equal_approx(base_lon, c_lon):
			out = {"landuse": mem["landuse"], "towers": mem["towers"]}
		else:
			var offset := WorldScale.xz_from_latlon(base_lat, base_lon, c_lat, c_lon)
			out = remap_far(mem["landuse"], mem["towers"], offset)
		_on_parsed.call_deferred(gen, int(mem["bytes"]), true, out))

static func _read_parsed_disk(path: String, mtime: int, base_lat: float, base_lon: float) -> Dictionary:
	var ppath := path + ".parsed"
	if not FileAccess.file_exists(ppath):
		return {}
	var f := FileAccess.open(ppath, FileAccess.READ)
	if f == null:
		return {}
	var raw: Variant = f.get_var(false)
	f.close()
	if not (raw is Dictionary):
		return {}
	var d: Dictionary = raw
	if int(d.get("mtime", -1)) != mtime or int(d.get("ver", -1)) != QUERY_VERSION \
			or not is_equal_approx(float(d.get("lat", NAN)), base_lat) \
			or not is_equal_approx(float(d.get("lon", NAN)), base_lon):
		return {}
	if not (d.get("landuse") is Array) or not (d.get("towers") is Array):
		return {}
	return d

static func _write_parsed_disk(path: String, mtime: int, base_lat: float, base_lon: float,
		bytes: int, parsed: Dictionary) -> void:
	var ppath := path + ".parsed"
	var tmp := "%s.tmp.%d" % [ppath, OS.get_thread_caller_id()]
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({"mtime": mtime, "ver": QUERY_VERSION, "lat": base_lat, "lon": base_lon,
		"bytes": bytes, "landuse": parsed["landuse"], "towers": parsed["towers"]}, false)
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(ppath))

func _read_and_parse_off_thread(path: String, mtime: int, cached: bool) -> void:
	_join_parse()
	var gen := _gen
	var base_lat := _lat
	var base_lon := _lon
	var c_lat := _c_lat
	var c_lon := _c_lon
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		var disk := _read_parsed_disk(path, mtime, base_lat, base_lon)
		if not disk.is_empty():
			var d_bytes := int(disk.get("bytes", 0))
			var parsed := {"landuse": disk["landuse"], "towers": disk["towers"]}
			_store_parsed(path, mtime, base_lat, base_lon, d_bytes, false, parsed)
			if not (is_equal_approx(base_lat, c_lat) and is_equal_approx(base_lon, c_lon)):
				parsed = remap_far(parsed["landuse"], parsed["towers"],
					WorldScale.xz_from_latlon(base_lat, base_lon, c_lat, c_lon))
			_on_parsed.call_deferred(gen, d_bytes, cached, parsed)
			return
		var text := OsmFetcher._read_cache(path)
		if text == "" or OverpassRequest.payload_error(text) != "":
			_on_parsed.call_deferred(gen, 0, cached, {})
			return
		var parsed := _parse_single(text, base_lat, base_lon, true)
		if not parsed.is_empty():
			_store_parsed(path, mtime, base_lat, base_lon, text.length(), false, parsed)
			_write_parsed_disk(path, mtime, base_lat, base_lon, text.length(), parsed)
			if not (is_equal_approx(base_lat, c_lat) and is_equal_approx(base_lon, c_lon)):
				parsed = remap_far(parsed["landuse"], parsed["towers"],
					WorldScale.xz_from_latlon(base_lat, base_lon, c_lat, c_lon))
		_on_parsed.call_deferred(gen, text.length(), cached, parsed))

## A city's payload (~10 MB) takes ~0.3 s to check and parse: on a
## worker, so the loading screen keeps drawing. A cached payload that is
## not usable comes back empty and the network is asked instead. A
## `trusted` payload (a bundled snapshot, pinned by length and SHA-256 and
## checked when it was made) is not checked again.
func _parse_off_thread(text: String, cached: bool, fallback: bool = false, trusted: bool = false) -> void:
	_join_parse()
	var gen := _gen
	var cache_key := (_cache + "#bundled") if trusted else (_cache if not fallback else "")
	var mtime := 0 if trusted else (int(FileAccess.get_modified_time(_cache)) if cache_key != "" and FileAccess.file_exists(_cache) else -1)
	var partial := _partial
	var base_lat := _lat
	var base_lon := _lon
	var c_lat := _c_lat
	var c_lon := _c_lon
	var check_remark := cached and not fallback and not trusted
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		var parsed := _parse_single(text, base_lat, base_lon, check_remark)
		if not parsed.is_empty():
			if cache_key != "" and mtime >= 0:
				_store_parsed(cache_key, mtime, base_lat, base_lon, text.length(), partial, parsed)
			if not (is_equal_approx(base_lat, c_lat) and is_equal_approx(base_lon, c_lon)):
				parsed = remap_far(parsed["landuse"], parsed["towers"],
					WorldScale.xz_from_latlon(base_lat, base_lon, c_lat, c_lon))
		_on_parsed.call_deferred(gen, text.length(), cached, parsed))

func _join_parse() -> void:
	if _parse_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_parse_task)
		_parse_task = -1

## A stale parse returns before joining: the task id may already be a
## newer parse's (the next _parse_off_thread joined this one).
func _on_parsed(gen: int, bytes: int, cached: bool, parsed: Dictionary) -> void:
	if gen != _gen:
		return
	_join_parse()
	if parsed.is_empty():
		_request()
		return
	_emit(bytes, cached, parsed)

func _emit(bytes: int, cached: bool, parsed: Dictionary) -> void:
	timings = {"ms": Time.get_ticks_msec() - _t0, "bytes": bytes,
		"cached": cached, "partial": _partial, "landuse": (parsed["landuse"] as Array).size(),
		"towers": (parsed["towers"] as Array).size()}
	_busy = false
	finished.emit(parsed["landuse"], parsed["towers"])

## Single-pass JSON decode + geometry extraction; returns {} when `check_remark`
## rejects a damaged/truncated payload, avoiding parsing ~10 MB JSON twice.
static func _parse_single(text: String, c_lat: float, c_lon: float, check_remark: bool) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if not (parsed is Dictionary):
		return {} if check_remark else {"landuse": [], "towers": []}
	var dict := parsed as Dictionary
	if check_remark and (not (dict.get("elements", null) is Array) or str(dict.get("remark", "")).strip_edges() != ""):
		return {}
	return _parse_dict(dict, c_lat, c_lon)

## {landuse, towers} in metre XZ around (c_lat, c_lon). Tall outlines
## retain their own roofs and their mapped parts, including relation rings.
static func parse(text: String, c_lat: float, c_lon: float) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if not (parsed is Dictionary):
		return {"landuse": [], "towers": []}
	return _parse_dict(parsed as Dictionary, c_lat, c_lon)

static func _parse_dict(parsed: Dictionary, c_lat: float, c_lon: float) -> Dictionary:
	var landuse: Array = []
	var towers: Array = []
	var part_ways: Array = []
	var seen := {}
	for el in parsed.get("elements", []):
		if not (el is Dictionary):
			continue
		var key := "%s:%d" % [el.get("type", ""), int(el.get("id", 0))]
		if seen.has(key):
			continue
		seen[key] = true
		var raw_tags: Variant = el.get("tags", {})
		var tags: Dictionary = raw_tags if raw_tags is Dictionary else {}
		if OsmTags.unbuilt_or_demolished(tags):
			continue
		var lu := str(tags.get("landuse", ""))
		var rings := _rings(el, c_lat, c_lon)
		for ring_data in rings:
			var pts: PackedVector2Array = ring_data[0]
			var holes: Array = ring_data[1]
			var box := RingGeometry.aabb(pts)
			if tags.has("building:part") and not tags.has("building"):
				part_ways.append({"tags": tags, "points": pts, "aabb": box, "holes": holes, "osm_id": key})
			elif tags.has("building"):
				var tower := OsmTags._building_entry(tags, pts, box)
				tower["osm_id"] = key
				tower["holes"] = holes
				towers.append(tower)
			elif lu != "":
				landuse.append({"class": lu, "points": pts, "holes": holes})
	# Match before applying the tower cap: a low podium can own a tall
	# crown, and selecting by its own height would discard the parent.
	_nest_parts(towers, part_ways)
	towers = select_towers(towers, CAP_TOWERS)
	return {"landuse": landuse, "towers": towers}

static func _rings(el: Dictionary, c_lat: float, c_lon: float) -> Array:
	var out: Array = []
	if str(el.get("type", "")) == "relation":
		var members: Array = el.get("members", [])
		var outer := OsmFetcher._join_rings(OsmFetcher._member_segments(members, true, c_lat, c_lon))
		var inner := OsmFetcher._join_rings(OsmFetcher._member_segments(members, false, c_lat, c_lon))
		for ring in outer:
			var holes: Array = []
			for hole in inner:
				if (hole as PackedVector2Array).size() > 0 and (outer.size() == 1 or OsmFetcher._point_in_ring(hole[0], ring)):
					holes.append(hole)
			out.append([ring, holes])
		return out
	var pts := PackedVector2Array()
	for node in el.get("geometry", []):
		if node is Dictionary:
			pts.append(WorldScale.xz_from_latlon(float(node.get("lat", c_lat)),
				float(node.get("lon", c_lon)), c_lat, c_lon))
	if pts.size() >= 2 and pts[0].distance_to(pts[pts.size() - 1]) < 0.01:
		pts.remove_at(pts.size() - 1)
	if pts.size() >= 3:
		out.append([pts, []])
	return out

## Approximate angular prominence; deterministic ties do not depend on OSM id.
static func select_towers(input: Array, cap: int) -> Array:
	var sorted := input.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := Vector2(float(a["x"]), float(a["z"])).length()
		var db := Vector2(float(b["x"]), float(b["z"])).length()
		var sa := _tower_height(a) / sqrt(1.0 + da / 1000.0)
		var sb := _tower_height(b) / sqrt(1.0 + db / 1000.0)
		if not is_equal_approx(sa, sb):
			return sa > sb
		if not is_equal_approx(da, db):
			return da < db
		return float(a["x"]) < float(b["x"]))
	return sorted.slice(0, maxi(0, cap))

## A low mapped podium may carry the tower as a tall building:part.
static func _tower_height(tower: Dictionary) -> float:
	var h := float(tower.get("height", 0.0))
	for part in tower.get("parts", []):
		h = maxf(h, float((part as Dictionary).get("height", 0.0)))
	return h

## A detailed query can intersect a podium while clipping its tower parts
## outside the radius. Fill those parts from the wider query by OSM id;
## the detailed copy wins for every part both sources contain.
static func complete_buildings(buildings: Array, towers: Array) -> Array:
	var by_id := {}
	for tower in towers:
		var id := str(tower.get("osm_id", ""))
		if id != "":
			by_id[id] = tower
	var out: Array = []
	for building in buildings:
		var id := ""
		for alias in OsmParser.ids_of(building):
			if by_id.has(alias):
				id = alias
				break
		if id == "":
			out.append(building)
			continue
		var parts: Array = building.get("parts", []).duplicate()
		var seen := {}
		for part in parts:
			seen[str(part.get("osm_id", ""))] = true
		for part in by_id[id].get("parts", []):
			var part_id := str(part.get("osm_id", ""))
			if part_id != "" and not seen.has(part_id):
				parts.append(part)
				seen[part_id] = true
		var complete: Dictionary = building.duplicate()
		complete["parts"] = parts
		out.append(complete)
	return out

## Spatial bins bound parent lookup in dense skylines, unlike comparing
## every part with every tower in the 12 km disc.
static func _nest_parts(towers: Array, parts: Array) -> void:
	var cells := {}
	var cell_m := 200.0
	for i in towers.size():
		var box := RingGeometry.aabb(towers[i]["footprint"])
		var lo := Vector2i(floori(box.position.x / cell_m), floori(box.position.y / cell_m))
		var hi := Vector2i(floori(box.end.x / cell_m), floori(box.end.y / cell_m))
		for x in range(lo.x, hi.x + 1):
			for z in range(lo.y, hi.y + 1):
				var key := Vector2i(x, z)
				if not cells.has(key):
					cells[key] = []
				cells[key].append(i)
	for p in parts:
		var pts: PackedVector2Array = p["points"]
		var box: Rect2 = p["aabb"]
		var centre := OsmFetcher._polygon_centroid(pts, box.get_center())
		var cell := Vector2i(floori(centre.x / cell_m), floori(centre.y / cell_m))
		var best := -1
		var best_area := INF
		for i in cells.get(cell, []):
			var parent: Dictionary = towers[i]
			var fp: PackedVector2Array = parent["footprint"]
			var area := absf(RingGeometry.signed_area(fp))
			if area < best_area and OsmFetcher._point_in_ring(centre, fp):
				best = i
				best_area = area
		# As OsmParser._nest_parts: a centroid in a U's notch or on the hall
		# in a ring's courtyard goes to the tower covering most of the part.
		var holes: Array = p["holes"]
		var own := OsmParser.part_area(pts, holes)
		best = OsmParser.settle_parent(towers, best, pts, holes, own, func() -> Array:
			var near := {}
			for x in range(floori(box.position.x / cell_m), floori(box.end.x / cell_m) + 1):
				for z in range(floori(box.position.y / cell_m), floori(box.end.y / cell_m) + 1):
					for i in cells.get(Vector2i(x, z), []):
						near[i] = true
			var candidates := near.keys()
			candidates.sort()
			return candidates)
		if best >= 0:
			var parent: Dictionary = towers[best]
			var entry := OsmTags._building_entry(p["tags"], pts, box)
			entry["osm_id"] = p.get("osm_id", "")
			if str(entry["height_source"]) == "default":
				entry["height"] = parent["height"]
				entry["height_source"] = parent["height_source"]
			entry["holes"] = p["holes"]
			(parent["parts"] as Array).append(entry)
		else:
			var orphan := OsmTags._building_entry(p["tags"], pts, box)
			orphan["osm_id"] = p.get("osm_id", "")
			if float(orphan["height"]) >= TOWER_MIN_M:
				orphan["min_height_m"] = 0.0
				orphan["min_level"] = 0
				orphan["holes"] = p["holes"]
				towers.append(orphan)
