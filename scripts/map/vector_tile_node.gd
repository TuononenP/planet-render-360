class_name VectorTileNode
extends Control

## One vector tile on the map: replays VectorTileBuilder meshes, one
## canvas_item_add_triangle_array per batch. Godot records a canvas item's
## draw list once and replays it every frame, so a pan only moves the
## node; nothing is rebuilt until the zoom changes. Three layers, bottom to
## top: ground fills (land use, land cover, parks), the hillshade (a baked
## Hillshade texture), then water, roads, buildings, rail and borders.
## clip_contents trims the tile buffer, so neighbouring tiles meet without
## doubled translucent fills.

var key := Vector3i.ZERO  # data tile z/x/y
var built_zoom := 0  # the picker zoom the batches were built for
var data: Dictionary = {}

var _base: Control
var _shade: TextureRect
var _top: Control

func setup(tile: Vector3i, zoom: int, built: Dictionary, px_size: float) -> void:
	key = tile
	built_zoom = zoom
	data = built
	size = Vector2(px_size, px_size)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base = _layer(func() -> void: _draw_batches(_base, false))
	_shade = TextureRect.new()
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shade.stretch_mode = TextureRect.STRETCH_SCALE
	_shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_shade.size = size
	_shade.visible = false
	add_child(_shade)
	_top = _layer(func() -> void: _draw_batches(_top, true))

func _layer(painter: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = size
	c.draw.connect(painter)
	add_child(c)
	return c

## The baked hillshade (Hillshade.bake) for this tile.
func set_shade(texture: Texture2D) -> void:
	if texture == null or _shade == null:
		return
	_shade.texture = texture
	_shade.visible = true

func has_shade() -> bool:
	return _shade != null and _shade.visible

func _draw_batches(target: Control, top: bool) -> void:
	var ci := target.get_canvas_item()
	for b in data.get("batches", []):
		var batch: Dictionary = b
		if (float(batch["order"]) >= MapStyle.SHADE_ORDER) != top:
			continue
		var indices: PackedInt32Array = batch["indices"]
		if indices.is_empty():
			continue
		RenderingServer.canvas_item_add_triangle_array(ci, indices, batch["points"], batch["colors"])
