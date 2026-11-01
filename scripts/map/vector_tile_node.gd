class_name VectorTileNode
extends Control

## One vector tile on the map: replays VectorTileBuilder batches. Godot
## records a canvas item's _draw once and replays it every frame, so a
## pan only moves the node; nothing is rebuilt until the zoom changes.
## Three layers, bottom to top: ground fills (land use, land cover, parks),
## the hillshade (a shader over the Terrarium DEM tile), then water, roads,
## buildings, rail and borders. clip_contents trims the tile buffer, so
## neighbouring tiles meet without doubled translucent fills.

const HILLSHADE := """
shader_type canvas_item;
uniform sampler2D dem : filter_nearest, repeat_disable;
uniform float mpp = 30.0;       // metres per DEM pixel at the tile's latitude
uniform float strength = 0.4;   // map-hillshade opacity at this zoom
uniform vec3 shade_dark;
uniform vec3 shade_light;

float height(ivec2 p) {
	ivec2 s = textureSize(dem, 0);
	vec3 c = texelFetch(dem, clamp(p, ivec2(0), s - 1), 0).rgb * 255.0;
	return c.r * 256.0 + c.g + c.b / 256.0 - 32768.0;
}

// Lambert minus flat ground, lit from the north-west at 45 degrees.
float shade_at(ivec2 p) {
	float a = height(p + ivec2(-1, -1)), b = height(p + ivec2(0, -1)), c = height(p + ivec2(1, -1));
	float d = height(p + ivec2(-1, 0)), f = height(p + ivec2(1, 0));
	float g = height(p + ivec2(-1, 1)), h = height(p + ivec2(0, 1)), i = height(p + ivec2(1, 1));
	float dzdx = ((c + 2.0 * f + i) - (a + 2.0 * d + g)) / (8.0 * mpp);
	float dzdy = ((g + 2.0 * h + i) - (a + 2.0 * b + c)) / (8.0 * mpp);
	vec3 n = normalize(vec3(-dzdx, -dzdy, 1.0));
	return dot(n, vec3(-0.5, -0.5, 0.70710678)) - 0.70710678;
}

void fragment() {
	vec2 st = UV * vec2(textureSize(dem, 0)) - 0.5;
	ivec2 p = ivec2(floor(st));
	vec2 t = fract(st);
	float s = mix(mix(shade_at(p), shade_at(p + ivec2(1, 0)), t.x),
		mix(shade_at(p + ivec2(0, 1)), shade_at(p + ivec2(1, 1)), t.x), t.y);
	float dark = clamp(-s * 2.5, 0.0, 1.0) * strength;
	float lit = clamp(s * 2.5, 0.0, 1.0) * strength * 0.6;
	COLOR = s < 0.0 ? vec4(shade_dark, dark) : vec4(shade_light, lit);
}
"""

var key := Vector3i.ZERO  # data tile z/x/y
var built_zoom := 0  # the picker zoom the batches were built for
var data: Dictionary = {}

var _base: Control
var _shade: ColorRect
var _top: Control

func setup(tile: Vector3i, zoom: int, built: Dictionary, px_size: float) -> void:
	key = tile
	built_zoom = zoom
	data = built
	size = Vector2(px_size, px_size)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base = _layer(func() -> void: _draw_batches(_base, false))
	_shade = ColorRect.new()
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.visible = false
	add_child(_shade)
	_top = _layer(func() -> void: _draw_batches(_top, true))

func _layer(painter: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(painter)
	add_child(c)
	return c

## Hillshade from a Terrarium tile covering this tile; `mpp` is metres per
## DEM pixel. Hidden when strength is ~0.
func set_dem(dem: Texture2D, mpp: float, strength: float, colors: Dictionary) -> void:
	if strength < 0.01 or dem == null:
		return
	var shader := Shader.new()
	shader.code = HILLSHADE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("dem", dem)
	mat.set_shader_parameter("mpp", mpp)
	mat.set_shader_parameter("strength", strength)
	var shadow: Color = colors["hillshade_shadow"]
	var light: Color = colors["hillshade_light"]
	mat.set_shader_parameter("shade_dark", Vector3(shadow.r, shadow.g, shadow.b))
	mat.set_shader_parameter("shade_light", Vector3(light.r, light.g, light.b))
	_shade.material = mat
	_shade.visible = true

func has_shade() -> bool:
	return _shade != null and _shade.visible

func _draw_batches(target: Control, top: bool) -> void:
	var ci := target.get_canvas_item()
	for b in data.get("fills", []):
		var batch: Dictionary = b
		if (float(batch["order"]) >= MapStyle.SHADE_ORDER) != top:
			continue
		var points: PackedVector2Array = batch["points"]
		var colors := PackedColorArray()
		colors.resize(points.size())
		colors.fill(batch["color"])
		RenderingServer.canvas_item_add_triangle_array(ci, batch["indices"], points, colors)
	for b in data.get("lines", []):
		var batch: Dictionary = b
		if (float(batch["order"]) >= MapStyle.SHADE_ORDER) != top:
			continue
		var color: Color = batch["color"]
		var width: float = batch["width"]
		if width < 1.0:
			# Hairlines: a 1px line faded by its width reads as thinner.
			color.a *= width
			width = 1.0
		for line in batch["polylines"]:
			target.draw_polyline(line, color, width, true)
		var segments: PackedVector2Array = batch["segments"]
		if not segments.is_empty():
			target.draw_multiline(segments, color, width, true)
