class_name TerrainLens
extends Control

## The loading screen's terrain preview (design system: TerrainLens):
## a round instrument dial over the chosen spot. The bezel carries the
## overall progress as an accent arc from north; the disc fills in as
## real data lands — contours traced from the DEM grid after
## Elevation, the satellite mosaic draped under them after Imagery,
## building blocks after Buildings & landmarks. Nothing is drawn
## before its data has arrived, and nothing animates on its own: each
## layer cross-fades in once (duration-slow) when it lands.
##
## Inputs are in a unit square over the detailed extent
## (WorldScale.DETAILED_EXTENT_M), north up, centred on the viewpoint.

const BEZEL := 20.0
const LEVELS := 15
const MAX_GRID := 64  # contour sampling cap: keeps tracing well under a frame budget
const SEGMENTS := 96
const FADE_SEC := 0.6

var progress := 0.0:
	set(v):
		progress = clampf(v, 0.0, 1.0)
		queue_redraw()
var failed := false:
	set(v):
		failed = v
		queue_redraw()
## A layer fell back to estimates: a caution tick marks the progress head.
var degraded := false:
	set(v):
		degraded = v
		queue_redraw()

var _contours := PackedVector2Array()  # unit-square segment pairs
var _index_contours := PackedVector2Array()  # every 4th level
var _drape: Texture2D
var _drape_uv := Rect2(0, 0, 1, 1)
var _blocks: Array[Rect2] = []  # unit-square building boxes
var _view := 1.0  # share of the unit square the disc shows, centred
var _fade := {"contours": 0.0, "imagery": 0.0, "buildings": 0.0}
var _screen_cache := {}  # unit-square arrays mapped to the current disc
var _glow: GradientTexture2D

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.colors = PackedColorArray([UiTheme.HORIZON_NIGHT, UiTheme.SKY_000])
	_glow = GradientTexture2D.new()
	_glow.gradient = g
	_glow.width = 256
	_glow.height = 256
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	resized.connect(func() -> void:
		_screen_cache.clear()
		queue_redraw())

## Back to an empty dial for a new place.
func clear() -> void:
	_contours = PackedVector2Array()
	_index_contours = PackedVector2Array()
	_drape = null
	_blocks.clear()
	_view = 1.0
	for k in _fade:
		_fade[k] = 0.0
	_screen_cache.clear()
	progress = 0.0
	failed = false
	degraded = false

## Trace contours from a row-major (z * grid + x) metre height grid.
## Flat ground (under 4 m of relief) has nothing to sketch.
func set_terrain(heights: PackedFloat32Array, grid: int) -> void:
	if grid < 2 or heights.size() != grid * grid:
		return
	var step := maxi(1, int(ceil(float(grid - 1) / float(MAX_GRID))))
	var n := (grid - 1) / step + 1
	var f := PackedFloat32Array()
	f.resize(n * n)
	var lo := INF
	var hi := -INF
	for j in n:
		for i in n:
			var v := heights[mini(j * step, grid - 1) * grid + mini(i * step, grid - 1)]
			f[j * n + i] = v
			lo = minf(lo, v)
			hi = maxf(hi, v)
	if hi - lo < 4.0:
		return
	var gap := (hi - lo) / float(LEVELS + 1)
	var inv := 1.0 / float(n - 1)
	var normal := PackedVector2Array()
	var index := PackedVector2Array()
	for j in n - 1:
		for i in n - 1:
			var a := f[j * n + i]
			var b := f[j * n + i + 1]
			var c := f[(j + 1) * n + i + 1]
			var d := f[(j + 1) * n + i]
			var first := maxi(1, int(ceil((minf(minf(a, b), minf(c, d)) - lo) / gap)))
			var last := mini(LEVELS, int(floor((maxf(maxf(a, b), maxf(c, d)) - lo) / gap)))
			for l in range(first, last + 1):
				var lv := lo + gap * l
				var pts := PackedVector2Array()
				_cross(pts, a, b, lv, Vector2(i, j), Vector2(i + 1, j))
				_cross(pts, b, c, lv, Vector2(i + 1, j), Vector2(i + 1, j + 1))
				_cross(pts, d, c, lv, Vector2(i, j + 1), Vector2(i + 1, j + 1))
				_cross(pts, a, d, lv, Vector2(i, j), Vector2(i, j + 1))
				# Packed arrays are values: append to the target directly.
				for k in range(0, pts.size() - 1, 2):
					if l % 4 == 0:
						index.append(pts[k] * inv)
						index.append(pts[k + 1] * inv)
					else:
						normal.append(pts[k] * inv)
						normal.append(pts[k + 1] * inv)
	_contours = normal
	_index_contours = index
	_screen_cache.clear()
	_fade_in("contours")

static func _cross(pts: PackedVector2Array, v0: float, v1: float, lv: float,
		p0: Vector2, p1: Vector2) -> void:
	if (v0 < lv) != (v1 < lv):
		pts.append(p0.lerp(p1, (lv - v0) / (v1 - v0)))

## Show only the centred `fraction` of the unit square (when imagery
## covers less than the full extent). Set before the first layer lands.
func set_view(fraction: float) -> void:
	_view = clampf(fraction, 0.1, 1.0)
	_screen_cache.clear()
	queue_redraw()

## Drape a texture; `uv` is the texture region covering the disc's view.
func set_imagery(tex: Texture2D, uv: Rect2) -> void:
	if tex == null:
		return
	_drape = tex
	_drape_uv = uv
	_fade_in("imagery")

func set_buildings(boxes: Array[Rect2]) -> void:
	if boxes.is_empty():
		return
	_blocks = boxes
	_screen_cache.clear()
	_fade_in("buildings")

func _fade_in(key: String) -> void:
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		_fade[key] = v
		queue_redraw(), 0.0, 1.0, FADE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _disc() -> Array:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	return [c, r, r - BEZEL]

## Unit-square segments mapped to the disc, dropping segments that
## fall outside it; cached until the lens or the data changes.
func _mapped(key: String, src: PackedVector2Array, origin: Vector2, span: float,
		c: Vector2, rd: float) -> PackedVector2Array:
	if _screen_cache.has(key):
		return _screen_cache[key]
	var out := PackedVector2Array()
	var r2 := rd * rd
	for k in range(0, src.size() - 1, 2):
		var p := origin + _to_disc(src[k]) * span
		var q := origin + _to_disc(src[k + 1]) * span
		if p.distance_squared_to(c) < r2 and q.distance_squared_to(c) < r2:
			out.append(p)
			out.append(q)
	_screen_cache[key] = out
	return out

func _to_disc(u: Vector2) -> Vector2:
	return (u - Vector2(0.5, 0.5)) / _view + Vector2(0.5, 0.5)

func _draw_disc_texture(tex: Texture2D, uv: Rect2, c: Vector2, r: float, tint: Color) -> void:
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for k in SEGMENTS:
		var dir := Vector2.from_angle(TAU * k / SEGMENTS)
		pts.append(c + dir * r)
		uvs.append(uv.position + uv.size * (dir * 0.5 + Vector2(0.5, 0.5)))
	draw_polygon(pts, PackedColorArray([tint]), uvs, tex)

func _draw() -> void:
	var d := _disc()
	var c: Vector2 = d[0]
	var r: float = d[1]
	var rd: float = d[2]
	if rd <= 8.0:
		return
	var origin := c - Vector2(rd, rd)
	var span := rd * 2.0
	_draw_disc_texture(_glow, Rect2(0, 0, 1, 1), c, rd, Color.WHITE)
	if _drape != null and _fade["imagery"] > 0.0:
		# Slightly dimmed so contours and blocks read over bright imagery.
		_draw_disc_texture(_drape, _drape_uv, c, rd, Color(0.78, 0.8, 0.84, 0.9 * _fade["imagery"]))
	var grat: float = 1.0 - _fade["contours"]
	if grat > 0.0:
		var gl := Color(UiTheme.LINE, UiTheme.LINE.a * grat)
		draw_arc(c, rd * 0.34, 0.0, TAU, 64, gl, 1.0, true)
		draw_arc(c, rd * 0.68, 0.0, TAU, 64, gl, 1.0, true)
		draw_line(c - Vector2(rd, 0), c + Vector2(rd, 0), gl, 1.0, true)
		draw_line(c - Vector2(0, rd), c + Vector2(0, rd), gl, 1.0, true)
	if _fade["contours"] > 0.0:
		var fc: float = _fade["contours"]
		var thin := _mapped("contours", _contours, origin, span, c, rd)
		var bold := _mapped("index", _index_contours, origin, span, c, rd)
		if thin.size() >= 2:
			draw_multiline(thin, Color(UiTheme.INK, 0.32 * fc), 1.0, true)
		if bold.size() >= 2:
			draw_multiline(bold, Color(UiTheme.INK, 0.72 * fc), 1.5, true)
	if _fade["buildings"] > 0.0:
		var bc := Color(UiTheme.INK, 0.88 * _fade["buildings"])
		for box in _blocks:
			var rect := Rect2(origin + _to_disc(box.position) * span, box.size / _view * span)
			if rect.get_center().distance_to(c) < rd - 2.0:
				draw_rect(rect, bc)
	draw_arc(c, rd, 0.0, TAU, SEGMENTS, UiTheme.GLASS_EDGE, 1.0, true)
	# Bezel: progress arc from north over a line track, then the ticks.
	var ring := r - 3.0
	draw_arc(c, ring, 0.0, TAU, SEGMENTS, UiTheme.LINE, 3.0, true)
	if progress > 0.0:
		var col := UiTheme.SIGNAL_ERROR if failed else UiTheme.TEAL
		var a0 := -PI / 2.0
		var a1 := a0 + TAU * progress
		draw_arc(c, ring, a0, a1, maxi(4, int(SEGMENTS * progress)), col, 3.0, true)
		draw_circle(c + Vector2.from_angle(a0) * ring, 1.5, col, true, -1.0, true)
		draw_circle(c + Vector2.from_angle(a1) * ring, 1.5, col, true, -1.0, true)
	if degraded and progress > 0.0:
		var head := Vector2.from_angle(-PI / 2.0 + TAU * progress)
		draw_line(c + head * (ring - 7.0), c + head * (ring + 7.0), UiTheme.SIGNAL_CAUTION, 3.0, true)
	for k in range(1, 72):
		var dir := Vector2.from_angle(deg_to_rad(k * 5.0) - PI / 2.0)
		var major := k % 6 == 0
		var r0 := rd + 5.0
		var r1 := r0 + (8.0 if major else 4.0)
		draw_line(c + dir * r0, c + dir * r1,
			UiTheme.MUTED if major else Color(UiTheme.LINE_STRONG, 0.6),
			1.5 if major else 1.0, true)
	var mono := UiTheme.data(true)
	draw_string(mono, c + Vector2(-20, -rd - 5.0), "N", HORIZONTAL_ALIGNMENT_CENTER, 40, 11, UiTheme.INK)
	# Where the viewer will stand.
	draw_arc(c, 11.0, 0.0, TAU, 48, UiTheme.TEAL, 1.5, true)
	draw_circle(c, 6.0, UiTheme.SKY_000, true, -1.0, true)
	draw_circle(c, 4.5, UiTheme.TEAL, true, -1.0, true)
