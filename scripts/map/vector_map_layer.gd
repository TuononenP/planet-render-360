class_name VectorMapLayer
extends Control

## The design system Map style on the picker: OpenFreeMap vector tiles drawn
## in the `map-*` palette, with hillshade from the Terrarium DEM and labels
## on top. MapTileView keeps input, centre, zoom and the pin; this layer
## only draws what its `view` shows.
##
## A picker zoom Z (256px tiles) shows vector data zoom d = Z - 1 (512px
## tiles, as MapLibre lays them out), overzoomed past 14. Tiles decode and
## build on worker threads; a built tile becomes a VectorTileNode whose
## draw list Godot replays, so panning only moves nodes. While a new zoom
## streams in, the previous zoom's nodes stay up, scaled, so the map never
## blanks.

const MAX_TASKS := 3
## Built tiles kept in memory across zooms (each up to ~1 MB in a city).
const MAX_BUILT := 48
const MAX_BYTES := 64
const MAX_DEM := 64
const EARTH_CIRCUMFERENCE_M := 40075016.686

var view: MapTileView

var _omt: VectorTileFetcher
var _dem: VectorTileFetcher
var _tiles: Control  # VectorTileNode children, under the labels
var _labels: MapLabels
## Keys are Vector4i(x, y, data zoom, picker zoom).
var _nodes: Dictionary = {}
var _built: Dictionary = {}
var _built_order: Array[Vector4i] = []
var _tasks: Dictionary = {}  # Vector4i -> WorkerThreadPool task id
var _task_queue: Array[Vector4i] = []
var _wanted: Array[Vector4i] = []
var _bytes: Dictionary = {}  # Vector3i(z, x, y) -> raw tile body
var _bytes_order: Array[Vector3i] = []
var _dem_tex: Dictionary = {}  # Vector3i(z, x, y) -> Texture2D
var _dem_order: Array[Vector3i] = []
var _state: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_tiles = Control.new()
	_tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tiles.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_tiles)
	_labels = MapLabels.new()
	add_child(_labels)
	_omt = VectorTileFetcher.new(VectorTileFetcher.Kind.VECTOR)
	add_child(_omt)
	_omt.tile_ready.connect(_on_tile)
	_dem = VectorTileFetcher.new(VectorTileFetcher.Kind.DEM)
	add_child(_dem)
	_dem.tile_ready.connect(_on_dem)

func _exit_tree() -> void:
	for id in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(int(id))
	_tasks.clear()

## Data zoom for a picker zoom.
static func data_zoom(zoom: int) -> int:
	return clampi(zoom - 1, 0, VectorTileFetcher.VECTOR_MAX_ZOOM)

## Tiles (Vector3i z/x/y at data zoom d) covering a view whose top-left is
## `origin` in global pixels at picker zoom `zoom`, centre first.
static func tiles_for(origin: Vector2, view_size: Vector2, zoom: int) -> Array:
	var d := data_zoom(zoom)
	var tile_px := 256.0 * pow(2.0, zoom - d)
	var last := (1 << d) - 1
	var x0 := clampi(int(floor(origin.x / tile_px)), 0, last)
	var x1 := clampi(int(floor((origin.x + view_size.x) / tile_px)), 0, last)
	var y0 := clampi(int(floor(origin.y / tile_px)), 0, last)
	var y1 := clampi(int(floor((origin.y + view_size.y) / tile_px)), 0, last)
	var tiles: Array = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			tiles.append(Vector3i(d, x, y))
	var centre := Vector2i((origin + view_size / 2.0) / tile_px)
	return MapTileView.centre_out_order(tiles, centre)

## Ask for everything the view needs; called by MapTileView.refresh_tiles.
func refresh() -> void:
	if view == null or _omt == null:
		return
	var zoom := view.zoom_level
	var origin := TileFetcher.global_pixel(view.centre_lat, view.centre_lon, zoom) - view.focus_point()
	var tiles := tiles_for(origin, view.size, zoom)
	_wanted.clear()
	var fetch: Array = []
	var shade := zoom - 1 <= MapStyle.SHADE_MAX_ZOOM
	for t in tiles:
		var tile: Vector3i = t
		var k := Vector4i(tile.y, tile.z, tile.x, zoom)
		_wanted.append(k)
		if shade and not _dem_tex.has(tile):
			_dem.request_tile(tile.x, tile.y, tile.z)
		if _nodes.has(k):
			continue
		if _built.has(k):
			_make_node(k)
		elif _bytes.has(tile):
			_queue_build(k)
		else:
			fetch.append(tile)
			_omt.request_tile(tile.x, tile.y, tile.z)
	_omt.discard_queued_except(fetch)
	_dem.discard_queued_except(tiles if shade else [])
	_prune()
	_sync(true)

func _on_tile(z: int, x: int, y: int, body: PackedByteArray) -> void:
	var tile := Vector3i(z, x, y)
	_bytes[tile] = body
	_bytes_order.erase(tile)
	_bytes_order.append(tile)
	while _bytes_order.size() > MAX_BYTES:
		_bytes.erase(_bytes_order.pop_front())
	for k in _wanted:
		if k.z == z and k.x == x and k.y == y and not _nodes.has(k):
			_queue_build(k)

func _queue_build(k: Vector4i) -> void:
	if _tasks.has(k) or _task_queue.has(k):
		return
	_task_queue.append(k)
	_pump_tasks()

func _pump_tasks() -> void:
	while _tasks.size() < MAX_TASKS and not _task_queue.is_empty():
		var k: Vector4i = _task_queue.pop_front()
		var tile := Vector3i(k.z, k.x, k.y)
		if not _wanted.has(k) or not _bytes.has(tile):
			continue
		var body: PackedByteArray = _bytes[tile]
		var colors := MapStyle.colors()
		var style_zoom := float(k.w - 1)
		var px := 256.0 * pow(2.0, k.w - k.z)
		_tasks[k] = WorkerThreadPool.add_task(func() -> void:
			var decoded := MvtReader.read(VectorTileFetcher.inflate(body), MapStyle.wanted(style_zoom))
			_on_built.call_deferred(k, VectorTileBuilder.build(decoded, style_zoom, colors, px)))

func _on_built(k: Vector4i, built: Dictionary) -> void:
	if _tasks.has(k):
		WorkerThreadPool.wait_for_task_completion(int(_tasks[k]))
		_tasks.erase(k)
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

func _make_node(k: Vector4i) -> void:
	var node := VectorTileNode.new()
	_tiles.add_child(node)
	node.setup(Vector3i(k.z, k.x, k.y), k.w, _built[k], 256.0 * pow(2.0, k.w - k.z))
	_nodes[k] = node
	_apply_dem(k)

func _on_dem(z: int, x: int, y: int, body: PackedByteArray) -> void:
	var img := Image.new()
	if img.load_png_from_buffer(body) != OK:
		return
	var tile := Vector3i(z, x, y)
	_dem_tex[tile] = ImageTexture.create_from_image(img)
	_dem_order.erase(tile)
	_dem_order.append(tile)
	while _dem_order.size() > MAX_DEM:
		_dem_tex.erase(_dem_order.pop_front())
	for k in _nodes:
		var key: Vector4i = k
		if key.z == z and key.x == x and key.y == y:
			_apply_dem(key)

func _apply_dem(k: Vector4i) -> void:
	var tile := Vector3i(k.z, k.x, k.y)
	var node: VectorTileNode = _nodes.get(k)
	if node == null or node.has_shade() or not _dem_tex.has(tile):
		return
	var lat := TileFetcher.lat_lon_from_pixel(Vector2(k.x + 0.5, k.y + 0.5) * 256.0, k.z).x
	var mpp := EARTH_CIRCUMFERENCE_M * cos(deg_to_rad(lat)) / (256.0 * pow(2.0, k.z))
	node.set_dem(_dem_tex[tile], mpp, MapStyle.shade_strength(float(k.w - 1), UiTheme.is_day),
		MapStyle.colors())

## Free nodes nobody needs. The previous zoom's nodes stay as stand-ins
## until every wanted tile of the new zoom has its node.
func _prune() -> void:
	var complete := true
	for k in _wanted:
		if not _nodes.has(k):
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

## Place the nodes for the view's centre/zoom and re-lay the labels when
## anything moved.
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
	var candidates: Array = []
	# Stand-ins (other zooms) first, so the current zoom draws over them.
	var order: Array = _nodes.keys()
	order.sort_custom(func(a: Vector4i, b: Vector4i) -> bool:
		return (a.w == zoom) == false and (b.w == zoom))
	for i in order.size():
		var key: Vector4i = order[i]
		var node: VectorTileNode = _nodes[key]
		if force:
			_tiles.move_child(node, i)
		var tile_px := 256.0 * pow(2.0, zoom - key.z)
		node.position = Vector2(key.x, key.y) * tile_px - centre_px + focus
		node.scale = Vector2.ONE * pow(2.0, zoom - key.w)
		if key.w != zoom:
			continue
		for l in node.data.get("labels", []):
			var label: Dictionary = (l as Dictionary).duplicate()
			label["pos"] = node.position + (label["pos"] as Vector2)
			candidates.append(label)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["priority"]) != int(b["priority"]):
			return int(a["priority"]) < int(b["priority"])
		return int(a.get("ele", 0)) > int(b.get("ele", 0)))
	_labels.set_labels(candidates, _graticule(zoom, centre_px, focus))

## 15° graticule lines in screen space (up to MapLabels.GRATICULE_MAX_ZOOM).
func _graticule(zoom: int, centre_px: Vector2, focus: Vector2) -> Array:
	var out: Array = []
	if zoom > MapLabels.GRATICULE_MAX_ZOOM:
		return out
	var shift := focus - centre_px
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
