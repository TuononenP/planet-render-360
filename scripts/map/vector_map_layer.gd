class_name VectorMapLayer
extends Control

## The design system Map style on the picker: OpenFreeMap vector tiles drawn
## in the `map-*` palette, with hillshade from the Terrarium DEM and labels
## on top. MapTileView keeps input, centre, zoom and the pin; this layer
## only draws what its `view` shows.
##
## A picker zoom Z (256px tiles) shows vector data zoom d = Z - 1 (512px
## tiles, as MapLibre lays them out), overzoomed past 14. Tiles decode and
## build on worker threads, and DEM tiles bake their hillshade there too; a
## built tile becomes a VectorTileNode whose draw list Godot replays, so a
## pan only moves nodes and shifts the laid-out labels. While a new zoom
## streams in, the previous zoom's nodes stay up, scaled, so the map never
## blanks.

const MAX_TASKS := 3
## Built tiles kept in memory across zooms (each up to ~1 MB in a city).
const MAX_BUILT := 48
const MAX_BYTES := 64
const MAX_SHADE := 64
## Covered beyond the view on every side, so a drag reveals drawn map.
const MARGIN_PX := 256.0
## A failed tile is not asked for again for this long.
const RETRY_MS := 30000
const EARTH_CIRCUMFERENCE_M := 40075016.686
## Zoom steps either side of the current one warmed over the whole view.
const PREFETCH_FULL_STEPS := 2

var view: MapTileView

var _omt: VectorTileFetcher
var _dem: VectorTileFetcher
var _tiles: Control  # VectorTileNode children, under the labels
var _labels: MapLabels
## Tile keys are Vector4i(x, y, data zoom, picker zoom); DEM keys Vector3i.
var _nodes: Dictionary = {}
var _built: Dictionary = {}
var _built_order: Array[Vector4i] = []
var _tasks: Dictionary = {}  # tile or DEM key -> WorkerThreadPool task id
var _task_queue: Array = []  # tile (Vector4i) and DEM (Vector3i) keys
var _wanted: Array[Vector4i] = []
var _bytes: Dictionary = {}  # Vector3i(z, x, y) -> raw tile body
var _bytes_order: Array[Vector3i] = []
var _dem_png: Dictionary = {}  # Vector3i -> Terrarium PNG awaiting its bake
var _shade: Dictionary = {}  # Vector3i -> baked hillshade texture
var _shade_order: Array[Vector3i] = []
var _failed: Dictionary = {}  # Vector3i -> msec of the failure
var _state: Array = []
var _layout_shift := Vector2.ZERO
var _layout_zoom := -1
## Shared with worker builds; set on the way out so they stop early.
var _cancel: Array = [false]
## Off for test and capture runs (started with --script; the app never
## is), so they never bulk-download tiles around the places they pick.
static var warm_up_enabled := not OS.get_cmdline_args().has("--script")
## A place picked before the view had a size, warmed once it has one.
var _warm_at: Variant = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The parent is already sized when we enter: take its full rect now
	# (offsets too), not just anchors, or the layer stays 0 x 0.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tiles = Control.new()
	_tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tiles)
	_tiles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_labels = MapLabels.new()
	add_child(_labels)
	_omt = VectorTileFetcher.new(VectorTileFetcher.Kind.VECTOR)
	add_child(_omt)
	_omt.tile_ready.connect(_on_tile)
	_omt.tile_failed.connect(_on_failed)
	_dem = VectorTileFetcher.new(VectorTileFetcher.Kind.DEM)
	add_child(_dem)
	_dem.tile_ready.connect(_on_dem)

func _exit_tree() -> void:
	_join_tasks()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_tasks()

## Stop queued work and wait for running builds (they see _cancel and
## return early), so no task outlives this node.
func _join_tasks() -> void:
	_cancel[0] = true
	_task_queue.clear()
	for id in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(int(id))
	_tasks.clear()

## Data zoom for a picker zoom.
static func data_zoom(zoom: int) -> int:
	return clampi(zoom - 1, 0, VectorTileFetcher.VECTOR_MAX_ZOOM)

## Tiles (Vector3i z/x/y at data zoom d) covering a view whose top-left is
## `origin` in global pixels at picker zoom `zoom`, grown by `margin` on
## every side, centre first.
static func tiles_for(origin: Vector2, view_size: Vector2, zoom: int, margin: float = MARGIN_PX) -> Array:
	var d := data_zoom(zoom)
	var tile_px := 256.0 * pow(2.0, zoom - d)
	var last := (1 << d) - 1
	var x0 := clampi(int(floor((origin.x - margin) / tile_px)), 0, last)
	var x1 := clampi(int(floor((origin.x + view_size.x + margin) / tile_px)), 0, last)
	var y0 := clampi(int(floor((origin.y - margin) / tile_px)), 0, last)
	var y1 := clampi(int(floor((origin.y + view_size.y + margin) / tile_px)), 0, last)
	var tiles: Array = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			tiles.append(Vector3i(d, x, y))
	var centre := Vector2i((origin + view_size / 2.0) / tile_px)
	return MapTileView.centre_out_order(tiles, centre)

## Tiles to warm around (lat, lon) for every other picker zoom, nearest
## zoom to `current_zoom` first: {"vector": [Vector3i], "dem": [Vector3i]},
## each covering just the view. Zooms more than PREFETCH_FULL_STEPS away
## warm only the middle half of the view around the pin (the part a zoom
## shows first), which keeps the dense deep zooms from costing tens of MB
## per pick. Static and pure so tests can pin it.
static func prefetch_plan(lat: float, lon: float, view_size: Vector2, focus: Vector2, current_zoom: int) -> Dictionary:
	var zooms: Array[int] = []
	for step in range(1, MapTileView.MAX_ZOOM - MapTileView.MIN_ZOOM + 1):
		for z in [current_zoom + step, current_zoom - step]:
			if z >= MapTileView.MIN_ZOOM and z <= MapTileView.MAX_ZOOM:
				zooms.append(z)
	var vector: Array[Vector3i] = []
	var dem: Array[Vector3i] = []
	# Picker zooms past the data's deepest share its tiles: plan each once
	# (the current one is the view's job).
	var planned: Array[int] = [data_zoom(current_zoom)]
	for zoom in zooms:
		if planned.has(data_zoom(zoom)):
			continue
		planned.append(data_zoom(zoom))
		var origin := TileFetcher.global_pixel(lat, lon, zoom) - focus
		var span := view_size
		if absi(zoom - current_zoom) > PREFETCH_FULL_STEPS:
			span = view_size / 2.0
			origin = TileFetcher.global_pixel(lat, lon, zoom) - span / 2.0
		for t in tiles_for(origin, span, zoom, 0.0):
			var tile: Vector3i = t
			vector.append(tile)
			if tile.x <= MapStyle.SHADE_MAX_ZOOM:
				dem.append(tile)
	return {"vector": vector, "dem": dem}

## Warm the disk cache around a newly picked place for every zoom, behind
## the visible tiles, so zooming there later does not wait on the network.
func prefetch_around(lat: float, lon: float) -> void:
	if view == null or _omt == null or not warm_up_enabled:
		return
	_omt.clear_prefetch()
	_dem.clear_prefetch()
	if view.size.x < 1.0 or view.size.y < 1.0:
		_warm_at = Vector2(lat, lon)  # not laid out yet: refresh() warms it
		return
	_warm_at = null
	var plan := prefetch_plan(lat, lon, view.size, view.focus_point(), view.zoom_level)
	for t in plan["vector"]:
		_omt.prefetch_tile(t.x, t.y, t.z)
	for t in plan["dem"]:
		_dem.prefetch_tile(t.x, t.y, t.z)

## Ask for everything the view needs; called by MapTileView.refresh_tiles.
func refresh() -> void:
	if view == null or _omt == null or not is_inside_tree():
		return
	var zoom := view.zoom_level
	var origin := TileFetcher.global_pixel(view.centre_lat, view.centre_lon, zoom) - view.focus_point()
	var tiles := tiles_for(origin, view.size, zoom)
	_wanted.clear()
	var fetch: Array = []
	var shade := zoom - 1 <= MapStyle.SHADE_MAX_ZOOM
	var now := Time.get_ticks_msec()
	for t in tiles:
		var tile: Vector3i = t
		var k := Vector4i(tile.y, tile.z, tile.x, zoom)
		_wanted.append(k)
		if shade and not _shade.has(tile) and not _dem_png.has(tile):
			_dem.request_tile(tile.x, tile.y, tile.z)
		if _nodes.has(k):
			continue
		if _built.has(k):
			_make_node(k)
		elif _bytes.has(tile):
			_queue(k)
		elif now - int(_failed.get(tile, -RETRY_MS)) >= RETRY_MS:
			fetch.append(tile)
			_omt.request_tile(tile.x, tile.y, tile.z)
	_omt.discard_queued_except(fetch)
	_dem.discard_queued_except(tiles if shade else [])
	_prune()
	_sync(true)
	# After the view's own tiles, so they are queued first.
	if _warm_at != null and view.size.x >= 1.0 and view.size.y >= 1.0:
		var at: Vector2 = _warm_at
		prefetch_around(at.x, at.y)

func _on_tile(z: int, x: int, y: int, body: PackedByteArray) -> void:
	var tile := Vector3i(z, x, y)
	_failed.erase(tile)
	_bytes[tile] = body
	_bytes_order.erase(tile)
	_bytes_order.append(tile)
	while _bytes_order.size() > MAX_BYTES:
		_bytes.erase(_bytes_order.pop_front())
	for k in _wanted:
		if k.z == z and k.x == x and k.y == y and not _nodes.has(k):
			_queue(k)

func _on_failed(z: int, x: int, y: int) -> void:
	_failed[Vector3i(z, x, y)] = Time.get_ticks_msec()
	_prune()

func _on_dem(z: int, x: int, y: int, body: PackedByteArray) -> void:
	var tile := Vector3i(z, x, y)
	if _shade.has(tile):
		return
	_dem_png[tile] = body
	_queue(tile)

func _queue(k: Variant) -> void:
	if _tasks.has(k) or _task_queue.has(k):
		return
	_task_queue.append(k)
	_pump_tasks()

func _pump_tasks() -> void:
	if not is_inside_tree() or _cancel[0]:
		return
	while _tasks.size() < MAX_TASKS and not _task_queue.is_empty():
		var k: Variant = _task_queue.pop_front()
		if k is Vector4i:
			_start_build(k)
		else:
			_start_shade(k)

func _start_build(k: Vector4i) -> void:
	var tile := Vector3i(k.z, k.x, k.y)
	if not _wanted.has(k) or not _bytes.has(tile):
		return
	var body: PackedByteArray = _bytes[tile]
	var colors := MapStyle.colors()
	var style_zoom := float(k.w - 1)
	var px := 256.0 * pow(2.0, k.w - k.z)
	var cancel := _cancel
	var job := func() -> void:
		var decoded := MvtReader.read(VectorTileFetcher.inflate(body), MapStyle.wanted(style_zoom))
		_on_built.call_deferred(k, VectorTileBuilder.build(decoded, style_zoom, colors, px, cancel))
	# High priority: low-priority tasks only get a third of the pool.
	_tasks[k] = WorkerThreadPool.add_task(job, true)

func _start_shade(tile: Vector3i) -> void:
	if not _dem_png.has(tile):
		return
	var png: PackedByteArray = _dem_png[tile]
	_dem_png.erase(tile)
	var lat := TileFetcher.lat_lon_from_pixel(Vector2(tile.y + 0.5, tile.z + 0.5) * 256.0, tile.x).x
	var mpp := EARTH_CIRCUMFERENCE_M * cos(deg_to_rad(lat)) / (256.0 * pow(2.0, tile.x))
	var strength := MapStyle.shade_strength(float(tile.x), UiTheme.is_day)
	var c := MapStyle.colors()
	var dark: Color = c["hillshade_shadow"]
	var light: Color = c["hillshade_light"]
	var job := func() -> void:
		_on_shaded.call_deferred(tile, Hillshade.bake(png, mpp, strength, dark, light))
	_tasks[tile] = WorkerThreadPool.add_task(job, true)

func _finish_task(k: Variant) -> void:
	if _tasks.has(k):
		WorkerThreadPool.wait_for_task_completion(int(_tasks[k]))
		_tasks.erase(k)

func _on_built(k: Vector4i, built: Dictionary) -> void:
	_finish_task(k)
	if not is_inside_tree() or _cancel[0] or built.is_empty():
		return
	_built[k] = built
	_built_order.erase(k)
	_built_order.append(k)
	while _built_order.size() > MAX_BUILT:
		var old: Vector4i = _built_order.pop_front()
		if _wanted.has(old):
			_built_order.append(old)
			break
		_built.erase(old)
	if _wanted.has(k) and not _nodes.has(k):
		_make_node(k)
		_prune()
		_sync(true)
	_pump_tasks()

func _on_shaded(tile: Vector3i, image: Image) -> void:
	_finish_task(tile)
	if not is_inside_tree() or _cancel[0]:
		return
	if image != null:
		_shade[tile] = ImageTexture.create_from_image(image)
		_shade_order.erase(tile)
		_shade_order.append(tile)
		while _shade_order.size() > MAX_SHADE:
			_shade.erase(_shade_order.pop_front())
		for k in _nodes:
			var key: Vector4i = k
			if key.z == tile.x and key.x == tile.y and key.y == tile.z:
				(_nodes[key] as VectorTileNode).set_shade(_shade[tile])
	_pump_tasks()

func _make_node(k: Vector4i) -> void:
	var node := VectorTileNode.new()
	_tiles.add_child(node)
	node.setup(Vector3i(k.z, k.x, k.y), k.w, _built[k], 256.0 * pow(2.0, k.w - k.z))
	_nodes[k] = node
	var tile := Vector3i(k.z, k.x, k.y)
	if _shade.has(tile):
		node.set_shade(_shade[tile])

## Free nodes nobody needs. The previous zoom's nodes stay as stand-ins
## until every wanted tile of the new zoom has its node (or failed).
func _prune() -> void:
	var complete := true
	for k in _wanted:
		if not _nodes.has(k) and not _failed.has(Vector3i(k.z, k.x, k.y)):
			complete = false
			break
	var zoom := view.zoom_level if view != null else 0
	for k in _nodes.keys():
		var key: Vector4i = k
		if _wanted.has(key):
			continue
		if key.w != zoom and not complete:
			continue
		(_nodes[key] as Node).queue_free()
		_nodes.erase(key)

func _process(_delta: float) -> void:
	_sync(false)

## Place the nodes for the view's centre/zoom. Labels are laid out again
## only when forced (a refresh, a new tile, a zoom); in between, a pan just
## shifts the laid-out labels with the map.
func _sync(force: bool) -> void:
	if view == null:
		return
	var zoom := view.zoom_level
	var centre_px := TileFetcher.global_pixel(view.centre_lat, view.centre_lon, zoom)
	var focus := view.focus_point()
	var state := [centre_px, zoom, size, focus]
	if not force and state == _state:
		return
	_state = state
	var shift := focus - centre_px
	if force:
		# Stand-ins (other zooms) first, so the current zoom draws over them.
		var order: Array = _nodes.keys()
		order.sort_custom(func(a: Vector4i, b: Vector4i) -> bool:
			return a.w != zoom and b.w == zoom)
		for i in order.size():
			_tiles.move_child(_nodes[order[i]] as Node, i)
	for k in _nodes:
		var key: Vector4i = k
		var node: VectorTileNode = _nodes[key]
		node.position = Vector2(key.x, key.y) * 256.0 * pow(2.0, zoom - key.z) + shift
		node.scale = Vector2.ONE * pow(2.0, zoom - key.w)
	if force or zoom != _layout_zoom:
		_layout_labels(zoom, shift)
	else:
		_labels.position = shift - _layout_shift

func _layout_labels(zoom: int, shift: Vector2) -> void:
	var candidates: Array = []
	for k in _nodes:
		var key: Vector4i = k
		if key.w != zoom:
			continue
		var node: VectorTileNode = _nodes[key]
		for l in node.data.get("labels", []):
			var label: Dictionary = (l as Dictionary).duplicate()
			label["pos"] = node.position + (label["pos"] as Vector2)
			candidates.append(label)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["priority"]) != int(b["priority"]):
			return int(a["priority"]) < int(b["priority"])
		return int(a.get("ele", 0)) > int(b.get("ele", 0)))
	_layout_shift = shift
	_layout_zoom = zoom
	_labels.position = Vector2.ZERO
	_labels.set_labels(candidates, _graticule(zoom, shift))

## 15° graticule lines in screen space (up to MapLabels.GRATICULE_MAX_ZOOM).
func _graticule(zoom: int, shift: Vector2) -> Array:
	var out: Array = []
	if zoom > MapLabels.GRATICULE_MAX_ZOOM:
		return out
	for lon in range(-180, 181, 15):
		var line := PackedVector2Array()
		for lat in range(-85, 86, 5):
			line.append(TileFetcher.global_pixel(lat, lon, zoom) + shift)
		out.append([line, false])
	for lat in range(-75, 76, 15):
		var line := PackedVector2Array()
		for lon in range(-180, 181, 10):
			line.append(TileFetcher.global_pixel(lat, lon, zoom) + shift)
		out.append([line, lat == 0])
	return out
