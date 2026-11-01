class_name RoundedPhoto
extends Control

## A photo cover-cropped into a rounded rectangle (History cards and
## rows, the Recents rail). The texture is drawn as a textured polygon,
## so the corners round without a shader or a clipping mask.

const SEGMENTS := 6

var texture: Texture2D
var radius := float(UiTheme.RADIUS_S)
## Round only the top corners (a card's thumbnail over its text).
var top_only := false

func _init(tex: Texture2D = null, corner: float = UiTheme.RADIUS_S, top: bool = false) -> void:
	texture = tex
	radius = corner
	top_only = top
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Outline of a w x h rectangle with rounded corners (clockwise from the
## top-left arc); bottom corners square when `top_only`.
static func outline(w: float, h: float, r: float, top: bool) -> PackedVector2Array:
	r = clampf(r, 0.0, minf(w, h) / 2.0)
	var pts := PackedVector2Array()
	var corners := [[Vector2(r, r), PI], [Vector2(w - r, r), PI * 1.5],
		[Vector2(w - r, h - r), 0.0], [Vector2(r, h - r), PI * 0.5]]
	for i in 4:
		var c: Vector2 = corners[i][0]
		if top and i >= 2:
			pts.append(Vector2(c.x + (r if i == 2 else -r), h))
			continue
		var a0: float = corners[i][1]
		for k in SEGMENTS + 1:
			var a := a0 + (PI / 2.0) * float(k) / float(SEGMENTS)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

## Texture coordinates for `pts` in a w x h box showing the texture
## cropped to cover it, centred.
static func cover_uvs(pts: PackedVector2Array, w: float, h: float, tw: float, th: float) -> PackedVector2Array:
	var s := maxf(w / tw, h / th)
	var uw := w / (tw * s)
	var uh := h / (th * s)
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(Vector2((1.0 - uw) / 2.0 + p.x / w * uw, (1.0 - uh) / 2.0 + p.y / h * uh))
	return uvs

func _draw() -> void:
	if texture == null or size.x < 2.0 or size.y < 2.0:
		return
	var pts := outline(size.x, size.y, radius, top_only)
	draw_colored_polygon(pts, Color.WHITE,
		cover_uvs(pts, size.x, size.y, float(texture.get_width()), float(texture.get_height())), texture)
