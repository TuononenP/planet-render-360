class_name MapLabels
extends Control

## The vector map's top layer: the 15° graticule at continental zooms, then
## every label, placed in priority order with collision culling across
## tiles. Faces follow the design system Map style: Instrument Sans for
## places and streets, Instrument Serif (slanted) for water, IBM Plex Mono
## for peak elevations, each over a map-label-halo outline.

const HALO := 4
const PAD := 3.0
const MAX_LABELS := 160
## Graticule up to this picker zoom (style zoom 7).
const GRATICULE_MAX_ZOOM := 8

## [{text, kind, priority, size, pos (screen), angle, run, sub?}]
var _candidates: Array = []
var _placed: Array = []  # [label, rect] in draw order
var _graticule: Array = []  # [PackedVector2Array, equator?]
var _fonts: Dictionary = {}
var _widths: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

## New candidates in screen space; lays them out and redraws.
func set_labels(candidates: Array, graticule: Array) -> void:
	_candidates = candidates
	_graticule = graticule
	_layout()
	queue_redraw()

func placed_count() -> int:
	return _placed.size()

func _font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var f: Font
	match kind:
		"country", "suburb", "state":
			var v := FontVariation.new()
			v.base_font = UiTheme.sans(600 if kind == "country" else 500)
			v.spacing_glyph = 2 if kind == "country" else 1
			f = v
		"city", "peak", "landmark":
			f = UiTheme.sans(500)
		"water", "river":
			var v := FontVariation.new()
			v.base_font = UiTheme.display()
			v.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.2, 1), Vector2.ZERO)
			v.spacing_glyph = 1
			f = v
		"ele":
			f = UiTheme.data(true)
		_:
			f = UiTheme.sans(400)
	_fonts[kind] = f
	return f

func _color(kind: String) -> Color:
	var c := MapStyle.colors()
	match kind:
		"state", "village", "suburb", "landmark":
			return c["label_minor"]
		"water", "river":
			return c["water_label"]
		"road":
			return c["road_label"]
		"peak":
			return c["peak"]
	return c["label"]

func _text_width(text: String, kind: String, font_size: int) -> float:
	var key := "%s|%s|%d" % [kind, text, font_size]
	if not _widths.has(key):
		if _widths.size() > 4000:
			_widths.clear()
		_widths[key] = _font(kind).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return _widths[key]

func _layout() -> void:
	_placed.clear()
	var view := Rect2(Vector2.ZERO, size).grow(-4.0)
	var taken: Array[Rect2] = []
	for c in _candidates:
		if _placed.size() >= MAX_LABELS:
			break
		var label: Dictionary = c
		var kind := str(label["kind"])
		var font_size := int(label["size"])
		var w := _text_width(str(label["text"]), kind, font_size)
		var h := float(font_size) * 1.25
		var pos: Vector2 = label["pos"]
		var run := float(label["run"])
		var rect: Rect2
		if run > 0.0:
			if run < w + 12.0:
				continue  # the street is shorter than its name here
			var angle := float(label["angle"])
			var half := Vector2(w / 2.0, h / 2.0)
			var corners := [Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
				Vector2(half.x, half.y), Vector2(-half.x, half.y)]
			rect = Rect2(pos, Vector2.ZERO)
			for k in corners:
				rect = rect.expand(pos + (k as Vector2).rotated(angle))
		elif kind == "peak":
			var sub_w := _text_width(str(label.get("sub", "")), "ele", 11)
			rect = Rect2(pos.x - maxf(w, sub_w) / 2.0 - 6.0, pos.y - 6.0, maxf(w, sub_w) + 12.0, h * 2.0 + 6.0)
		else:
			rect = Rect2(pos - Vector2(w, h) / 2.0, Vector2(w, h))
		rect = rect.grow(PAD)
		if not view.encloses(rect):
			continue
		var clear := true
		for t in taken:
			if t.intersects(rect):
				clear = false
				break
		if not clear:
			continue
		taken.append(rect)
		_placed.append([label, rect])

func _draw() -> void:
	var c := MapStyle.colors()
	for g in _graticule:
		draw_polyline(g[0], c["graticule"], 1.4 if bool(g[1]) else 0.8, true)
	var halo: Color = c["label_halo"]
	for p in _placed:
		var label: Dictionary = p[0]
		var kind := str(label["kind"])
		var text := str(label["text"])
		var font_size := int(label["size"])
		var font := _font(kind)
		var color := _color(kind)
		var pos: Vector2 = label["pos"]
		var w := _text_width(text, kind, font_size)
		var ascent := font.get_ascent(font_size)
		if float(label["run"]) > 0.0:
			draw_set_transform(pos, float(label["angle"]), Vector2.ONE)
			_text(font, Vector2(-w / 2.0, ascent / 2.0 - 1.0), text, font_size, color, halo)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "peak":
			var tri := PackedVector2Array([pos + Vector2(0, -4), pos + Vector2(4, 3), pos + Vector2(-4, 3)])
			draw_colored_polygon(tri, halo)
			draw_colored_polygon(PackedVector2Array([tri[0] + Vector2(0, 1.5),
				tri[1] + Vector2(-1.3, -0.8), tri[2] + Vector2(1.3, -0.8)]), color)
			_text(font, Vector2(pos.x - w / 2.0, pos.y + 6.0 + ascent), text, font_size, color, halo)
			var sub := str(label.get("sub", ""))
			var sub_w := _text_width(sub, "ele", 11)
			_text(_font("ele"), Vector2(pos.x - sub_w / 2.0, pos.y + 6.0 + ascent + font_size * 1.15),
				sub, 11, c["peak_ele"], halo)
		else:
			if kind == "landmark":
				# A small diamond above the name marks the landmark itself.
				var dc := pos - Vector2(0, float(font_size) * 0.5 + 7.0)
				draw_colored_polygon(PackedVector2Array([dc + Vector2(0, -3.5), dc + Vector2(3.5, 0),
					dc + Vector2(0, 3.5), dc + Vector2(-3.5, 0)]), color)
			_text(font, Vector2(pos.x - w / 2.0, pos.y + ascent / 2.0 - 1.0), text, font_size, color, halo)

func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, halo: Color) -> void:
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, HALO, halo)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
