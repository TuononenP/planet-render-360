class_name FacadeComposer
extends RefCounted

## Procedural facade textures over the bundled photographic wall sets —
## the tiled family (punched, strip, balcony, clapboard, industrial,
## adobe, curtain, tiles): ONE storey of BAYS bays (CELL px per bay, so
## CELL px = bay_m x storey height). BuildingBuilder._walls repeats it
## per real storey and per real bay of each wall edge, so windows keep
## their real size on a 4 m shed and a 90 m slab alike. Tiles are tiny
## (512x128), so the material budget is per (set, pattern, look,
## variant), not per storey count. T4.6: a regional window vocabulary
## (casement, french, sash, wide, small), balconettes, per-building
## variants (which bays carry shutters, blinds, lit panes, loggias),
## sky-reflective curtain glass and the Japanese tiled front. The Paris
## full facade, ground storeys and legacy glass live in StoreyComposer.
## Drawn colours are linear, like the photographic bases.

## Dark PRD glass base (#2E3A40, linear) for window panes in solid walls.
const GLASS := Color(0.0273, 0.0423, 0.0513)
## Curtain-wall glass reflects sky: blue-grey, lighter toward the top
## (a black slab is what an unlit pane looks like, not a tower).
const SKY_GLASS := Color(0.105, 0.155, 0.205)
const SKY_GLASS_TOP := Color(0.20, 0.27, 0.34)
const SPANDREL := Color(0.30, 0.31, 0.32)
const MULLION := Color(0.52, 0.54, 0.56)
const CELL := 128
const BAYS := 4
const TILED: Array[String] = ["punched", "strip", "balcony", "clapboard",
	"industrial", "adobe", "curtain", "tiles"]
const WINDOWS: Array[String] = ["casement", "french", "sash", "wide", "small"]
## Photo repeats per bay cell: brick courses and boards must read at
## real size, so those bases tile 2x2 inside each bay.
const PHOTO_REPS := {"brick": 2, "wood": 2}
## Share of a photo's contrast kept once it is shrunk to a bay cell:
## concrete's streaks and blotches read as dirty noise at ~4 cm/px.
const KEEP_CONTRAST := {"concrete": 0.4, "stone": 0.7, "render": 0.7}

static func is_tiled(pattern: String) -> bool:
	return pattern in TILED

## Texture set for a tiled pattern: {albedo, normal, rough} (the last two
## null at detail 0). `look` carries the region's frame/shutter colours,
## window vocabulary, balconette share and the building variant;
## `loader(set, map)` returns a bundled PBR map (MaterialLibrary._set_image
## — passed in so this class names no other project class).
static func compose_tile(set_name: String, pattern: String, detail: int,
		look: Dictionary, loader: Callable) -> Dictionary:
	var W := CELL * BAYS
	var glass := set_name == "glass"
	if glass:
		pattern = "curtain"
	var alb: Image
	var nor: Image = null
	var rgh: Image = null
	if glass:
		alb = Image.create(W, CELL, false, Image.FORMAT_RGBA8)
		alb.fill(SKY_GLASS)
	else:
		var reps: int = PHOTO_REPS.get(set_name, 1)
		# The bundled planks run vertically; siding runs horizontally.
		var turn := set_name == "wood" and pattern == "clapboard"
		alb = _wall_layer(loader, set_name, "diff", reps, turn)
		if detail >= 1:
			nor = _wall_layer(loader, set_name, "nor", reps, turn)
			rgh = _wall_layer(loader, set_name, "rough", reps, turn)
	if detail >= 1 and nor == null:
		nor = Image.create(W, CELL, false, Image.FORMAT_RGBA8)
		nor.fill(Color(0.5, 0.5, 1.0))
		rgh = Image.create(W, CELL, false, Image.FORMAT_RGBA8)
		rgh.fill(Color(0.6, 0.6, 0.6))
	var frame: Color = look.get("frame", Color(0.85, 0.83, 0.78))
	var shutter: Color = look.get("shutter", Color(0.3, 0.4, 0.3))
	var shutter_p := float(look.get("shutter_p", 0.0))
	var win := str(look.get("window", "casement"))
	var rails := float(look.get("rails", 0.0))
	var variant := float(look.get("variant", 0))
	if pattern == "clapboard":
		_boards(alb, nor, W)
	elif pattern == "industrial":
		_ribs(alb, nor, W)
	elif pattern == "tiles":
		_grout(alb, nor, W)
		if win == "casement":
			win = "wide"
	for bay in BAYS:
		var ox := bay * CELL
		var hv := _hash(float(bay) * 9.3 + float(pattern.length()) + variant * 4.1, 3.7)
		var hr := _hash(float(bay) * 2.7 + variant * 1.3, 8.9)
		match pattern:
			"punched", "tiles":
				_window(alb, nor, rgh, ox, hv, frame, shutter, shutter_p, detail, win,
					hr < rails)
			"clapboard":
				_window(alb, nor, rgh, ox, hv, frame, shutter, shutter_p, detail,
					"small" if win == "casement" else win, hr < rails)
			"strip":
				_strip(alb, nor, rgh, ox, hv, frame)
			"balcony":
				_balcony(alb, nor, rgh, ox, hv, frame, variant)
			"industrial":
				_clerestory(alb, nor, rgh, ox, bay, frame)
			"adobe":
				_adobe(alb, nor, rgh, ox, bay, hv, frame)
			"curtain":
				_curtain(alb, nor, rgh, ox, hv)
	alb.generate_mipmaps()
	var d := {"albedo": ImageTexture.create_from_image(alb)}
	if nor != null and rgh != null:
		nor.generate_mipmaps(true)
		rgh.generate_mipmaps()
		d["normal"] = ImageTexture.create_from_image(nor)
		d["rough"] = ImageTexture.create_from_image(rgh)
	else:
		d["normal"] = null
		d["rough"] = null
	return d

## The photographic base tiled across the whole strip: one bay cell holds
## `reps` x `reps` copies, so the grain is real-sized and repeats cleanly.
static func _wall_layer(loader: Callable, set_name: String, map_name: String,
		reps: int, turn: bool = false) -> Image:
	var src := (loader.call(set_name, map_name) as Image).duplicate() as Image
	src.convert(Image.FORMAT_RGBA8)
	var n := CELL / reps
	src.resize(n, n, Image.INTERPOLATE_BILINEAR)
	if map_name == "diff" and KEEP_CONTRAST.has(set_name):
		_soften(src, float(KEEP_CONTRAST[set_name]))
	if turn:
		src.rotate_90(CLOCKWISE)
		if map_name == "nor":  # rotate the tangent frame with the image
			for y in n:
				for x in n:
					var c := src.get_pixel(x, y)
					src.set_pixel(x, y, Color(c.g, 1.0 - c.r, c.b, 1.0))
	var out := Image.create(CELL * BAYS, CELL, false, Image.FORMAT_RGBA8)
	for ty in reps:
		for tx in BAYS * reps:
			out.blit_rect(src, Rect2i(0, 0, n, n), Vector2i(tx * n, ty * n))
	return out

static func _hash(x: float, z: float) -> float:
	return fmod(absf(sin(x * 12.9898 + z * 78.233) * 43758.5453), 1.0)

## Pull every pixel toward the image mean, keeping `keep` of its contrast.
static func _soften(img: Image, keep: float) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var mean := Color(0, 0, 0, 0)
	for y in h:
		for x in w:
			mean += img.get_pixel(x, y)
	mean = mean / float(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(mean.r + (c.r - mean.r) * keep,
				mean.g + (c.g - mean.g) * keep, mean.b + (c.b - mean.b) * keep, 1.0))

static func _lin(c: Color) -> Color:
	return c.srgb_to_linear()

## Window size (w, h, top y) per regional vocabulary, in cell px
## (CELL px = one bay x one storey): casement (default), french (tall,
## narrow, floor-length), sash (UK/US vertical sliding), wide (Japanese /
## East Asian aluminium sliders), small (timber houses, chalets).
static func _window_box(win: String) -> Vector3i:
	match win:
		"french":
			return Vector3i(38, 84, 22)
		"sash":
			return Vector3i(40, 72, 24)
		"wide":
			return Vector3i(76, 50, 32)
		"small":
			return Vector3i(32, 46, 34)
	return Vector3i(44, 66, 26)

## Window with frame, sill and lintel shadow (shutters on a share of
## bays), glazing bars per vocabulary, optional wrought-iron balconette.
static func _window(alb: Image, nor: Image, rgh: Image, ox: int, hv: float,
		frame: Color, shutter: Color, shutter_p: float, detail: int,
		win: String, rail: bool) -> void:
	var box := _window_box(win)
	var ww := box.x
	var wh := box.y
	var wy := box.z
	var wx := ox + (CELL - ww) / 2
	var dark := Color(0.03, 0.03, 0.03)
	if hv < shutter_p and win != "wide":
		var sw := mini(ww / 2 + 2, (CELL - ww) / 2 - 6)
		alb.fill_rect(Rect2i(wx - sw - 4, wy - 2, sw, wh + 4), shutter)
		alb.fill_rect(Rect2i(wx + ww + 4, wy - 2, sw, wh + 4), shutter)
		for ly in range(wy, wy + wh, 6):
			alb.fill_rect(Rect2i(wx - sw - 4, ly, sw, 1), dark)
			alb.fill_rect(Rect2i(wx + ww + 4, ly, sw, 1), dark)
	alb.fill_rect(Rect2i(wx - 4, wy - 7, ww + 8, 3), dark)
	alb.fill_rect(Rect2i(wx - 3, wy - 3, ww + 6, wh + 6), frame)
	var pane := GLASS
	if hv > 0.93:
		pane = Color(0.55, 0.36, 0.14)  # lit interior
	elif hv > 0.78:
		pane = Color(0.20, 0.19, 0.17)  # curtain drawn
	alb.fill_rect(Rect2i(wx, wy, ww, wh), pane)
	alb.fill_rect(Rect2i(wx, wy, ww, maxi(wh / 6, 2)), _lin(Color(0.24, 0.30, 0.35)))
	match win:
		"sash":
			alb.fill_rect(Rect2i(wx, wy + wh / 2 - 1, ww, 4), frame)
			for k in [1, 2]:
				alb.fill_rect(Rect2i(wx + ww * k / 3 - 1, wy, 2, wh), frame)
			alb.fill_rect(Rect2i(wx, wy + wh / 4, ww, 2), frame)
			alb.fill_rect(Rect2i(wx, wy + wh * 3 / 4, ww, 2), frame)
		"wide":
			alb.fill_rect(Rect2i(wx + ww / 2 - 1, wy, 3, wh), frame)
			if hv > 0.45 and hv <= 0.78:  # frosted / screened half
				alb.fill_rect(Rect2i(wx + ww / 2 + 2, wy + 2, ww / 2 - 4, wh - 4),
					_lin(Color(0.62, 0.64, 0.64)))
		"french":
			alb.fill_rect(Rect2i(wx + ww / 2 - 1, wy, 3, wh), frame)
			alb.fill_rect(Rect2i(wx, wy + wh / 3, ww, 2), frame)
			alb.fill_rect(Rect2i(wx, wy + wh * 2 / 3, ww, 2), frame)
		_:
			alb.fill_rect(Rect2i(wx + ww / 2 - 1, wy, 3, wh), frame)
			alb.fill_rect(Rect2i(wx, wy + wh * 2 / 5, ww, 3), frame)
	alb.fill_rect(Rect2i(wx - 6, wy + wh + 3, ww + 12, 4), frame)
	alb.fill_rect(Rect2i(wx - 6, wy + wh + 7, ww + 12, 2), dark)
	if rail:
		var iron := _lin(Color(0.11, 0.11, 0.12))
		var ry := wy + wh - wh / 4
		alb.fill_rect(Rect2i(wx - 4, ry, ww + 8, 2), iron)
		alb.fill_rect(Rect2i(wx - 4, wy + wh, ww + 8, 2), iron)
		for bx in range(wx - 4, wx + ww + 4, 4):
			alb.fill_rect(Rect2i(bx, ry, 1, wh / 4), iron)
	if nor != null:
		var lo := Color(0.38, 0.38, 1.0)
		var hi := Color(0.62, 0.62, 1.0) if detail >= 2 else Color(0.62, 0.5, 1.0)
		nor.fill_rect(Rect2i(wx - 3, wy - 3, ww + 6, 3), lo)
		nor.fill_rect(Rect2i(wx - 3, wy - 3, 3, wh + 6), lo)
		nor.fill_rect(Rect2i(wx + ww, wy - 3, 3, wh + 6), hi)
		nor.fill_rect(Rect2i(wx - 3, wy + wh, ww + 6, 3), hi)
		rgh.fill_rect(Rect2i(wx, wy, ww, wh), Color(0.2, 0.2, 0.2))

## Small glazed ceramic tiles (Japanese / East Asian mid-rise fronts):
## a fine grout grid blended over the photo, a bevel per course.
static func _grout(alb: Image, nor: Image, w: int) -> void:
	var lines := Image.create(w, CELL, false, Image.FORMAT_RGBA8)
	for y in range(0, CELL, 6):
		lines.fill_rect(Rect2i(0, y, w, 1), Color(0, 0, 0, 0.22))
		var off := 0 if (y / 6) % 2 == 0 else 6
		for x in range(off, w, 12):
			lines.fill_rect(Rect2i(x, y, 1, 6), Color(0, 0, 0, 0.16))
		if nor != null:
			nor.fill_rect(Rect2i(0, y, w, 1), Color(0.5, 0.4, 1.0))
	alb.blend_rect(lines, Rect2i(0, 0, w, CELL), Vector2i.ZERO)

## Continuous ribbon window between floor slabs (functionalist / office
## fronts): a slimmer band than v1 (it read as horizontal stripes), sky
## reflection, a mullion every quarter bay, blinds on some bays.
static func _strip(alb: Image, nor: Image, rgh: Image, ox: int, hv: float,
		frame: Color) -> void:
	alb.fill_rect(Rect2i(ox, 0, CELL, 4), _lin(Color(0.62, 0.60, 0.56)))
	alb.fill_rect(Rect2i(ox, 4, CELL, 2), Color(0.03, 0.03, 0.03))
	alb.fill_rect(Rect2i(ox, 36, CELL, 46), frame)
	var pane := Rect2i(ox + 2, 39, CELL - 4, 40)
	# Ribbon panes in a solid wall read like windows (dark, a sky band at
	# the head), not a curtain wall: a saturated blue band per storey was
	# the "striped" look.
	alb.fill_rect(pane, GLASS.lerp(SKY_GLASS, 0.35))
	alb.fill_rect(Rect2i(ox + 2, 39, CELL - 4, 9), _lin(Color(0.24, 0.30, 0.35)))
	if hv > 0.72:  # blind half drawn
		alb.fill_rect(Rect2i(ox + 2, 39, CELL - 4, 18), _lin(Color(0.80, 0.77, 0.70)))
	for k in 4:
		alb.fill_rect(Rect2i(ox + k * CELL / 4 - 1, 39, 3, 40), frame)
	if nor != null:
		nor.fill_rect(Rect2i(ox, 36, CELL, 3), Color(0.5, 0.38, 1.0))
		nor.fill_rect(Rect2i(ox, 79, CELL, 3), Color(0.5, 0.62, 1.0))
		nor.fill_rect(Rect2i(ox, 4, CELL, 2), Color(0.5, 0.62, 1.0))
		rgh.fill_rect(pane, Color(0.15, 0.15, 0.15))

## Balcony bay (panel blocks, Japanese mansions, Mediterranean flats):
## window + balcony door behind a slab, and per variant either a pale
## solid parapet, frosted-glass panels, or a light metal railing.
static func _balcony(alb: Image, nor: Image, rgh: Image, ox: int, hv: float,
		frame: Color, variant: float) -> void:
	var slab := _lin(Color(0.78, 0.77, 0.74))
	var dark := Color(0.03, 0.03, 0.03)
	alb.fill_rect(Rect2i(ox + 10, 24, 40, 56), frame)
	alb.fill_rect(Rect2i(ox + 13, 27, 34, 50), GLASS)
	alb.fill_rect(Rect2i(ox + 13, 27, 34, 9), _lin(Color(0.24, 0.30, 0.35)))
	alb.fill_rect(Rect2i(ox + 29, 27, 3, 50), frame)
	alb.fill_rect(Rect2i(ox + 58, 20, 58, 76), frame)
	alb.fill_rect(Rect2i(ox + 61, 23, 52, 73), GLASS)
	alb.fill_rect(Rect2i(ox + 61, 23, 52, 10), _lin(Color(0.24, 0.30, 0.35)))
	alb.fill_rect(Rect2i(ox + 86, 23, 3, 73), frame)
	alb.fill_rect(Rect2i(ox, 96, CELL, 8), slab)
	alb.fill_rect(Rect2i(ox, 104, CELL, 3), dark)
	var kind := int(variant + hv * 1.6) % 3
	match kind:
		0:  # solid parapet, slightly lighter than the wall
			alb.fill_rect(Rect2i(ox, 70, CELL, 26), slab)
			alb.fill_rect(Rect2i(ox, 68, CELL, 2), frame)
			alb.fill_rect(Rect2i(ox, 94, CELL, 2), _lin(Color(0.55, 0.54, 0.52)))
		1:  # frosted glass panels
			alb.fill_rect(Rect2i(ox, 70, CELL, 26), _lin(Color(0.60, 0.66, 0.68)))
			for k in 4:
				alb.fill_rect(Rect2i(ox + k * 32, 70, 2, 26), frame)
			alb.fill_rect(Rect2i(ox, 68, CELL, 3), frame)
		_:  # light metal railing
			alb.fill_rect(Rect2i(ox, 70, CELL, 3), frame)
			for bx in range(ox, ox + CELL, 6):
				alb.fill_rect(Rect2i(bx, 70, 2, 26), frame)
	if hv > 0.8:  # laundry / screen at one end
		alb.fill_rect(Rect2i(ox + 4, 74, 22, 18), _lin(Color(0.86, 0.84, 0.80)))
	if nor != null:
		nor.fill_rect(Rect2i(ox, 96, CELL, 3), Color(0.5, 0.75, 1.0))
		nor.fill_rect(Rect2i(ox, 104, CELL, 3), Color(0.5, 0.25, 1.0))
		nor.fill_rect(Rect2i(ox, 68, CELL, 2), Color(0.5, 0.7, 1.0))
		rgh.fill_rect(Rect2i(ox + 13, 27, 34, 50), Color(0.2, 0.2, 0.2))
		rgh.fill_rect(Rect2i(ox + 61, 23, 52, 47), Color(0.2, 0.2, 0.2))

## Horizontal siding: a fine dark/light line pair every 7 px, blended so
## the photo/paint colour survives.
static func _boards(alb: Image, nor: Image, w: int) -> void:
	var lines := Image.create(w, CELL, false, Image.FORMAT_RGBA8)
	for y in range(0, CELL, 7):
		lines.fill_rect(Rect2i(0, y, w, 1), Color(0, 0, 0, 0.30))
		lines.fill_rect(Rect2i(0, y + 1, w, 1), Color(1, 1, 1, 0.10))
		if nor != null:
			nor.fill_rect(Rect2i(0, y, w, 1), Color(0.5, 0.38, 1.0))
			nor.fill_rect(Rect2i(0, y + 1, w, 1), Color(0.5, 0.62, 1.0))
	alb.blend_rect(lines, Rect2i(0, 0, w, CELL), Vector2i.ZERO)

## Vertical corrugated-sheet ribs, with a heavier seam at each bay edge.
static func _ribs(alb: Image, nor: Image, w: int) -> void:
	var lines := Image.create(w, CELL, false, Image.FORMAT_RGBA8)
	for x in range(0, w, 8):
		lines.fill_rect(Rect2i(x, 0, 1, CELL), Color(0, 0, 0, 0.26))
		lines.fill_rect(Rect2i(x + 1, 0, 2, CELL), Color(1, 1, 1, 0.08))
		if nor != null:
			nor.fill_rect(Rect2i(x, 0, 2, CELL), Color(0.38, 0.5, 1.0))
			nor.fill_rect(Rect2i(x + 2, 0, 2, CELL), Color(0.62, 0.5, 1.0))
	for x in range(0, w, CELL):
		lines.fill_rect(Rect2i(x, 0, 2, CELL), Color(0, 0, 0, 0.5))
	alb.blend_rect(lines, Rect2i(0, 0, w, CELL), Vector2i.ZERO)

## Industrial sheds: a high clerestory light in alternate bays only.
static func _clerestory(alb: Image, nor: Image, rgh: Image, ox: int, bay: int,
		frame: Color) -> void:
	if bay % 2 == 0:
		return
	alb.fill_rect(Rect2i(ox + 10, 18, CELL - 20, 26), frame)
	alb.fill_rect(Rect2i(ox + 13, 21, CELL - 26, 20), GLASS)
	alb.fill_rect(Rect2i(ox + CELL / 2 - 1, 21, 3, 20), frame)
	if rgh != null:
		rgh.fill_rect(Rect2i(ox + 13, 21, CELL - 26, 20), Color(0.2, 0.2, 0.2))

## Plain plaster with a few small deep-set openings (every other bay), and
## now and then a carved wooden lattice screen.
static func _adobe(alb: Image, nor: Image, rgh: Image, ox: int, bay: int,
		hv: float, frame: Color) -> void:
	if bay % 2 == 1 and hv < 0.8:
		return
	var dark := Color(0.03, 0.03, 0.03)
	if hv > 0.7:  # lattice screen
		var wood := _lin(Color(0.38, 0.27, 0.17))
		alb.fill_rect(Rect2i(ox + 40, 34, 48, 56), wood)
		for g in range(0, 48, 8):
			alb.fill_rect(Rect2i(ox + 40 + g, 34, 2, 56), dark)
		for g in range(0, 56, 8):
			alb.fill_rect(Rect2i(ox + 40, 34 + g, 48, 2), dark)
		return
	var wx := ox + 54
	alb.fill_rect(Rect2i(wx - 3, 37, 26, 36), frame)
	alb.fill_rect(Rect2i(wx, 40, 20, 30), GLASS)
	alb.fill_rect(Rect2i(wx, 40, 20, 4), dark)  # deep reveal shadow
	alb.fill_rect(Rect2i(wx, 40, 3, 30), dark)
	if nor != null:
		nor.fill_rect(Rect2i(wx - 3, 37, 26, 3), Color(0.5, 0.38, 1.0))
		nor.fill_rect(Rect2i(wx - 3, 37, 3, 36), Color(0.38, 0.5, 1.0))
		rgh.fill_rect(Rect2i(wx, 40, 20, 30), Color(0.2, 0.2, 0.2))

## Glass curtain wall: sky-reflective blue-grey panes (lighter at the
## top of each storey, per-bay variance), aluminium mullions, transom and
## a light spandrel at the floor line — reads as a glazed tower, not a
## black slab.
static func _curtain(alb: Image, nor: Image, rgh: Image, ox: int, hv: float) -> void:
	var v := 0.85 + hv * 0.35
	for y in 96:
		var sky := SKY_GLASS_TOP.lerp(SKY_GLASS, float(y) / 96.0)
		alb.fill_rect(Rect2i(ox, y, CELL, 1), Color(sky.r * v, sky.g * v, sky.b * v))
	alb.fill_rect(Rect2i(ox, 96, CELL, 32), SPANDREL)
	alb.fill_rect(Rect2i(ox, 100, CELL, 2), _lin(Color(0.42, 0.43, 0.44)))
	alb.fill_rect(Rect2i(ox, 0, 4, CELL), MULLION)
	alb.fill_rect(Rect2i(ox + CELL / 2 - 1, 0, 3, 96), MULLION)
	alb.fill_rect(Rect2i(ox, 93, CELL, 4), MULLION)
	alb.fill_rect(Rect2i(ox, 28, CELL, 2), MULLION)
	if nor != null:
		nor.fill_rect(Rect2i(ox, 0, 2, CELL), Color(0.38, 0.5, 1.0))
		nor.fill_rect(Rect2i(ox + 2, 0, 2, CELL), Color(0.62, 0.5, 1.0))
		nor.fill_rect(Rect2i(ox, 93, CELL, 2), Color(0.5, 0.38, 1.0))
		nor.fill_rect(Rect2i(ox, 95, CELL, 2), Color(0.5, 0.62, 1.0))
		rgh.fill_rect(Rect2i(ox, 0, CELL, 96), Color(0.08, 0.08, 0.08))
		rgh.fill_rect(Rect2i(ox, 96, CELL, 32), Color(0.5, 0.5, 0.5))
