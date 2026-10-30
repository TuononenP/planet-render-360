class_name StoreyComposer
extends RefCounted

## Storey-aware facade textures (T4.6), split from FacadeComposer:
##  - compose_haussmann: the Paris full-facade texture, rows = real
##    storeys counted from the ground: rusticated shopfront ground floor
##    with fascias and a carriage door, entresol, continuous wrought-iron
##    balconies on the 2nd and 5th floors (PRD §4.2), balconettes on the
##    others, French windows with lintels, main cornice with dentils,
##    and the 1.5 m base grime. Four deterministic variants per row count
##    (pediments, balconette rhythm, shutters ≤30%, fascia palette).
##  - compose_ground: one ground storey (BAYS bays) for tiled facades —
##    shopfronts, Japanese signage bands, a chalet's rendered base, a
##    rusticated plinth.
##  - compose_glass: the legacy full-wall curtain glass.
## Drawn colours are linear, like the photographic bases. Names only
## FacadeComposer (one direction), never the material classes.

const PARIS_BAYS := 6
const S := 512

## Shop fascia palette (sRGB): Paris dark lacquers; others pick from the
## region's ground colour via the look.
const PARIS_FASCIA := ["#1f3a2c", "#4a1c22", "#1d2433", "#2a2523", "#3b4a3a", "#5a2a1a"]

static func _lin(hex: String) -> Color:
	var c := Color.html(hex)
	c.a = 1.0
	return c.srgb_to_linear()

static func _h(x: float, z: float) -> float:
	return FacadeComposer._hash(x, z)

## Window pane: dark PRD glass with a sky-reflection band at the top,
## the odd lit or curtained pane by hash.
static func _pane(alb: Image, r: Rect2i, hv: float) -> void:
	var glass := FacadeComposer.GLASS
	if hv > 0.94:
		glass = _lin("#d9a25a")  # lit interior
	elif hv > 0.80:
		glass = _lin("#5b5550")  # drawn curtain
	alb.fill_rect(r, glass)
	var sky_h := maxi(r.size.y / 5, 2)
	alb.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, sky_h), _lin("#3c4c58"))
	alb.fill_rect(Rect2i(r.position.x, r.position.y + sky_h, r.size.x, maxi(sky_h / 2, 1)),
		_lin("#2c3840"))

## Wrought-iron rail: top bar, bottom bar, balusters with a scroll dot.
static func _rail(alb: Image, x0: int, x1: int, y: int, h: int, iron: Color) -> void:
	alb.fill_rect(Rect2i(x0, y, x1 - x0, 2), iron)
	alb.fill_rect(Rect2i(x0, y + h - 2, x1 - x0, 2), iron)
	for bx in range(x0, x1, 4):
		alb.fill_rect(Rect2i(bx, y, 1, h), iron)
	for bx in range(x0 + 2, x1 - 2, 8):
		alb.fill_rect(Rect2i(bx, y + h / 2 - 1, 3, 3), iron)

static func _bevel(nor: Image, r: Rect2i, b: int, deep: bool) -> void:
	if nor == null:
		return
	var lo := Color(0.38, 0.38, 1.0)
	var hi := Color(0.62, 0.62, 1.0) if deep else Color(0.62, 0.5, 1.0)
	nor.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, b), lo)
	nor.fill_rect(Rect2i(r.position.x, r.position.y, b, r.size.y), lo)
	nor.fill_rect(Rect2i(r.end.x - b, r.position.y, b, r.size.y), hi)
	nor.fill_rect(Rect2i(r.position.x, r.end.y - b, r.size.x, b), hi)

static func _base(loader: Callable, set_name: String, map_name: String, w: int,
		h: int) -> Image:
	var img := (loader.call(set_name, map_name) as Image).duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	return img

static func _finish(alb: Image, nor: Image, rgh: Image, depth: bool = false) -> Dictionary:
	# Composed in linear; encode for the sRGB-decoding albedo sampler.
	alb.linear_to_srgb()
	alb.generate_mipmaps()
	var d := {"albedo": ImageTexture.create_from_image(alb), "normal": null, "rough": null}
	if depth and rgh != null:
		d["depth"] = FacadeComposer.depth_from_rough(rgh)
	if nor != null and rgh != null:
		nor.generate_mipmaps(true)
		rgh.generate_mipmaps()
		d["normal"] = ImageTexture.create_from_image(nor)
		d["rough"] = ImageTexture.create_from_image(rgh)
	return d

## Paris Haussmann facade over a photographic wall base; `rows` real
## storeys (1..8) spanning the wall height, PARIS_BAYS bays across.
static func compose_haussmann(set_name: String, rows: int, detail: int,
		loader: Callable, variant: int = 0) -> Dictionary:
	rows = clampi(rows, 1, 8)
	var alb := _base(loader, set_name, "diff", S, S)
	var nor: Image = null
	var rgh: Image = null
	if detail >= 1:
		nor = _base(loader, set_name, "nor", S, S)
		rgh = _base(loader, set_name, "rough", S, S)
	var frame := _lin("#ece6d6")
	var cornice := _lin("#e6d9bc")
	var shadow := _lin("#8f8068")
	var iron := _lin("#1c1d20")
	var groove := Color(0.03, 0.03, 0.03)
	var shutter := _lin("#8a9294")
	var fascia := _lin(PARIS_FASCIA[(variant * 2 + rows) % PARIS_FASCIA.size()])
	var bay_w := float(S) / float(PARIS_BAYS)
	# Main cornice with dentils under the roof.
	var top := 12
	alb.fill_rect(Rect2i(0, 0, S, 8), cornice)
	alb.fill_rect(Rect2i(0, 8, S, 4), shadow)
	for dx in range(0, S, 8):
		alb.fill_rect(Rect2i(dx, 8, 4, 3), cornice)
	if nor != null:
		nor.fill_rect(Rect2i(0, 0, S, 3), Color(0.5, 0.7, 1.0))
		nor.fill_rect(Rect2i(0, 8, S, 4), Color(0.5, 0.3, 1.0))
	# Row heights: ground floor 1.3x, entresol 0.85x (when present).
	var weights: Array[float] = []
	var total := 0.0
	for r in rows:
		var rfb := rows - 1 - r
		var w := 1.0
		if rfb == 0 and rows >= 2:
			w = 1.3
		elif rfb == 1 and rows >= 5:
			w = 0.85
		weights.append(w)
		total += w
	var y := float(top)
	var avail := float(S - top)
	for r in rows:
		var rfb := rows - 1 - r
		var rh := avail * weights[r] / total
		var ry := int(y)
		var rhi := int(rh)
		y += rh
		if rfb == 0 and rows >= 2:
			_paris_ground(alb, nor, rgh, ry, rhi, bay_w, fascia, frame, variant)
			continue
		# String course at the floor line.
		alb.fill_rect(Rect2i(0, ry, S, 2), cornice)
		alb.fill_rect(Rect2i(0, ry + 2, S, 1), shadow)
		var rusticated := rfb == 1 and rows >= 5
		if rusticated:
			for gy in range(ry + 6, ry + rhi, 9):
				alb.fill_rect(Rect2i(0, gy, S, 1), shadow)
		var balcony := (rfb == 2 and rows >= 4) or (rfb == 5 and rows >= 7) \
			or (rfb == rows - 1 and rows in [5, 6] and variant % 2 == 0)
		var win_h := int(rh * (0.55 if rusticated else 0.70))
		var fy := ry + int(rh * (0.22 if rusticated else 0.16))
		var win_w := mini(int(win_h * 0.56), int(bay_w * 0.5))
		for col in PARIS_BAYS:
			var hv := _h(float(col) * 9.3 + float(variant) * 1.7, float(r) * 3.9)
			var ix := int(float(col) * bay_w + (bay_w - win_w) * 0.5)
			var wr := Rect2i(ix, fy, win_w, win_h)
			if detail >= 2:
				alb.fill_rect(Rect2i(ix - 6, fy - 5, win_w + 12, 2), groove)
				alb.fill_rect(Rect2i(ix - 6, fy + win_h + 3, win_w + 12, 2), groove)
			if variant == 2 and hv < 0.25 and not rusticated:  # ≤30% shutters
				var sw := maxi(win_w / 2, 6)
				alb.fill_rect(Rect2i(ix - sw - 2, fy, sw, win_h), shutter)
				alb.fill_rect(Rect2i(ix + win_w + 2, fy, sw, win_h), shutter)
				for ly in range(fy, fy + win_h, 4):
					alb.fill_rect(Rect2i(ix - sw - 2, ly, sw, 1), shadow)
					alb.fill_rect(Rect2i(ix + win_w + 2, ly, sw, 1), shadow)
			# Lintel / pediment: heavier on the noble (2nd) floor.
			if rfb == 2 and variant != 1:
				var pw := win_w + 14
				for k in 5:
					alb.fill_rect(Rect2i(ix - 7 + k * 2, fy - 8 - k, pw - k * 4, 1), cornice)
				alb.fill_rect(Rect2i(ix - 7, fy - 7, pw, 3), cornice)
				alb.fill_rect(Rect2i(ix - 7, fy - 4, pw, 1), shadow)
			else:
				alb.fill_rect(Rect2i(ix - 5, fy - 6, win_w + 10, 4), cornice)
				alb.fill_rect(Rect2i(ix - 5, fy - 2, win_w + 10, 1), shadow)
			alb.fill_rect(Rect2i(ix - 4, fy - 3, win_w + 8, win_h + 6), frame)
			_pane(alb, wr, hv)
			# French window leaves: centre mullion + transoms.
			alb.fill_rect(Rect2i(ix + win_w / 2 - 1, fy, 2, win_h), frame)
			alb.fill_rect(Rect2i(ix, fy + win_h / 3, win_w, 2), frame)
			alb.fill_rect(Rect2i(ix, fy + win_h * 2 / 3, win_w, 2), frame)
			_bevel(nor, Rect2i(ix - 4, fy - 3, win_w + 8, win_h + 6), 3, detail >= 2)
			if rgh != null:
				rgh.fill_rect(wr, Color(0.2, 0.2, 0.2))
			# Balconette across the lower window (variant rhythm).
			var balconette := not balcony and not rusticated \
				and (variant == 0 or (variant == 3 and rfb % 2 == 1))
			if balconette:
				_rail(alb, ix - 3, ix + win_w + 3, fy + win_h - win_h / 4, win_h / 4, iron)
		if balcony:
			# Continuous stone slab + wrought-iron railing over the
			# window bottoms across the whole front.
			var by := fy + win_h - int(rh * 0.06)
			var rail_h := int(rh * 0.24)
			alb.fill_rect(Rect2i(0, by, S, 4), cornice)
			alb.fill_rect(Rect2i(0, by + 4, S, 3), shadow)
			for cx in range(4, S, 21):
				alb.fill_rect(Rect2i(cx, by + 7, 4, 3), cornice)  # consoles
			_rail(alb, 0, S, by - rail_h, rail_h, iron)
			if nor != null:
				nor.fill_rect(Rect2i(0, by, S, 2), Color(0.5, 0.75, 1.0))
				nor.fill_rect(Rect2i(0, by + 4, S, 3), Color(0.5, 0.25, 1.0))
			if rgh != null:
				rgh.fill_rect(Rect2i(0, by - rail_h, S, rail_h), Color(0.5, 0.5, 0.5))
	# Base grime: bottom ~1.5 m darkened ≈15% (PRD §4.2).
	var gh := maxi(int(float(S - top) / float(rows) * 0.45), 12)
	var grime := Image.create(S, gh, false, Image.FORMAT_RGBA8)
	for gy in gh:
		var t := float(gy) / float(gh)
		grime.fill_rect(Rect2i(0, gy, S, 1), Color(0, 0, 0, t * 0.22))
	alb.blend_rect(grime, Rect2i(0, 0, S, gh), Vector2i(0, S - gh))
	return _finish(alb, nor, rgh, detail >= 2)

## Paris ground floor: rusticated stone, shopfront per bay with a lacquer
## fascia, and a tall carriage door (porte cochère) in one bay.
static func _paris_ground(alb: Image, nor: Image, rgh: Image, ry: int, rh: int,
		bay_w: float, fascia: Color, frame: Color, variant: int) -> void:
	var shadow := _lin("#8f8068")
	var light := _lin("#e6d9bc")
	alb.fill_rect(Rect2i(0, ry, S, 4), light)  # entablature over the shops
	alb.fill_rect(Rect2i(0, ry + 4, S, 2), shadow)
	for gy in range(ry + 10, ry + rh, 8):
		alb.fill_rect(Rect2i(0, gy, S, 1), shadow)
	var door := (variant + 2) % PARIS_BAYS
	for col in PARIS_BAYS:
		var x0 := int(float(col) * bay_w)
		var ox := x0 + int(bay_w * 0.1)
		var ow := int(bay_w * 0.8)
		if col == door:
			var dw := int(bay_w * 0.56)
			var dx := x0 + (int(bay_w) - dw) / 2
			alb.fill_rect(Rect2i(dx - 3, ry + 10, dw + 6, rh - 10), light)
			alb.fill_rect(Rect2i(dx, ry + 13, dw, rh - 13), _lin("#2b3a30"))
			alb.fill_rect(Rect2i(dx + dw / 2 - 1, ry + 13, 2, rh - 13), _lin("#151a16"))
			for py in range(ry + 22, ry + rh - 4, 14):
				alb.fill_rect(Rect2i(dx + 3, py, dw - 6, 1), _lin("#151a16"))
			_bevel(nor, Rect2i(dx - 3, ry + 10, dw + 6, rh - 10), 3, false)
			continue
		var fy := ry + 9
		var fh := maxi(rh / 7, 6)
		alb.fill_rect(Rect2i(ox, fy, ow, fh), fascia)
		var hv := _h(float(col) * 3.3 + float(variant), 11.0)
		if hv > 0.3:  # sign lettering
			alb.fill_rect(Rect2i(ox + ow / 5, fy + fh / 3, ow * 3 / 5, maxi(fh / 3, 2)),
				_lin("#d8cba8"))
		var gy0 := fy + fh + 2
		var gh := ry + rh - gy0 - 3
		alb.fill_rect(Rect2i(ox, gy0, ow, gh), fascia)
		var pane := Rect2i(ox + 3, gy0 + 2, ow - 6, gh - 8)
		alb.fill_rect(pane, _lin("#2a2e30"))
		alb.fill_rect(Rect2i(pane.position.x, pane.position.y + pane.size.y / 3,
			pane.size.x, pane.size.y * 2 / 3), _lin("#4a4438") if hv > 0.5 else _lin("#33383a"))
		alb.fill_rect(Rect2i(ox + ow / 2 - 1, gy0, 2, gh), fascia)
		alb.fill_rect(Rect2i(ox, ry + rh - 8, ow, 5), fascia)  # stall riser
		_bevel(nor, Rect2i(ox, gy0, ow, gh), 3, false)
		if rgh != null:
			rgh.fill_rect(pane, Color(0.18, 0.18, 0.18))

## One ground storey (FacadeComposer.CELL x BAYS) for a tiled facade.
## kind: shop | signage | render | stone. `fascia` is linear.
static func compose_ground(set_name: String, kind: String, detail: int,
		look: Dictionary, fascia: Color, loader: Callable) -> Dictionary:
	var C := FacadeComposer.CELL
	var W := C * FacadeComposer.BAYS
	var alb := FacadeComposer._wall_layer(loader, set_name, "diff",
		int(FacadeComposer.PHOTO_REPS.get(set_name, 1)))
	var nor: Image = null
	var rgh: Image = null
	if detail >= 1:
		var reps := int(FacadeComposer.PHOTO_REPS.get(set_name, 1))
		nor = FacadeComposer._wall_layer(loader, set_name, "nor", reps)
		rgh = FacadeComposer._wall_layer(loader, set_name, "rough", reps)
	var frame: Color = look.get("frame", Color(0.85, 0.83, 0.78))
	var shutter: Color = look.get("shutter", Color(0.3, 0.4, 0.3))
	var variant := int(look.get("variant", 0))
	var dark := Color(0.03, 0.03, 0.03)
	# Floor line separating the ground storey from the storeys above.
	alb.fill_rect(Rect2i(0, 0, W, 4), _lin("#bdb6a8"))
	alb.fill_rect(Rect2i(0, 4, W, 2), dark)
	if nor != null:
		nor.fill_rect(Rect2i(0, 0, W, 3), Color(0.5, 0.7, 1.0))
	var door := variant % FacadeComposer.BAYS
	for bay in FacadeComposer.BAYS:
		var ox := bay * C
		var hv := _h(float(bay) * 5.1 + float(variant) * 2.3, 7.7)
		match kind:
			"shop", "signage":
				var sign_h := 30 if kind == "signage" else 16
				var sign := fascia
				if kind == "signage":
					var pal := ["#c8302a", "#f2efe6", "#e8b820", "#2a5aa8", "#1e1e22", "#3a8a4a"]
					sign = _lin(pal[int(hv * 97.0) % pal.size()])
				alb.fill_rect(Rect2i(ox + 4, 10, C - 8, sign_h), sign)
				if hv > 0.25:
					var ink := _lin("#f4f0e4") if sign.get_luminance() < 0.3 else _lin("#20201e")
					alb.fill_rect(Rect2i(ox + 18, 10 + sign_h / 3, C - 36, maxi(sign_h / 3, 3)), ink)
				var gy := 12 + sign_h
				var gh := C - gy - 6
				if bay == door:
					alb.fill_rect(Rect2i(ox + 40, gy, 48, gh + 6), frame)
					alb.fill_rect(Rect2i(ox + 44, gy + 3, 40, gh + 3), _lin("#3a3f42"))
					alb.fill_rect(Rect2i(ox + 63, gy + 3, 2, gh + 3), frame)
				else:
					alb.fill_rect(Rect2i(ox + 6, gy, C - 12, gh), frame)
					var pane := Rect2i(ox + 9, gy + 3, C - 18, gh - 6)
					alb.fill_rect(pane, _lin("#30363a"))
					var lit := kind == "signage" or hv > 0.55
					alb.fill_rect(Rect2i(pane.position.x, pane.position.y + pane.size.y / 3,
						pane.size.x, pane.size.y * 2 / 3), _lin("#9a8a6a") if lit else _lin("#454a4c"))
					alb.fill_rect(Rect2i(ox + C / 2 - 1, gy, 2, gh), frame)
					alb.fill_rect(Rect2i(ox + 6, C - 10, C - 12, 4), _lin("#5a5a58"))
					if rgh != null:
						rgh.fill_rect(pane, Color(0.18, 0.18, 0.18))
				if kind == "signage" and hv > 0.6:  # hanging vertical sign
					alb.fill_rect(Rect2i(ox + 2, 0, 10, 46), _lin(["#c8302a", "#e8b820", "#f2efe6"][bay % 3]))
				if nor != null:
					nor.fill_rect(Rect2i(ox + 6, gy, C - 12, 3), Color(0.5, 0.38, 1.0))
					nor.fill_rect(Rect2i(ox + 4, 10 + sign_h, C - 8, 2), Color(0.5, 0.3, 1.0))
			"render", "stone":
				if kind == "stone":
					for gy in range(14, C, 12):
						alb.fill_rect(Rect2i(ox, gy, C, 1), _lin("#6a6050"))
				if bay == door and kind == "render":
					alb.fill_rect(Rect2i(ox + 42, 34, 44, C - 34), frame)
					alb.fill_rect(Rect2i(ox + 46, 38, 36, C - 38), _lin("#5a3f2a"))
					continue
				var ww := 40
				var wh := 50
				var wx := ox + (C - ww) / 2
				var wy := 34
				if kind == "render" and hv < 0.7:
					alb.fill_rect(Rect2i(wx - 22, wy, 18, wh), shutter)
					alb.fill_rect(Rect2i(wx + ww + 4, wy, 18, wh), shutter)
					for ly in range(wy, wy + wh, 5):
						alb.fill_rect(Rect2i(wx - 22, ly, 18, 1), dark)
						alb.fill_rect(Rect2i(wx + ww + 4, ly, 18, 1), dark)
				alb.fill_rect(Rect2i(wx - 3, wy - 3, ww + 6, wh + 6), frame)
				_pane(alb, Rect2i(wx, wy, ww, wh), hv)
				alb.fill_rect(Rect2i(wx + ww / 2 - 1, wy, 3, wh), frame)
				alb.fill_rect(Rect2i(wx - 5, wy + wh + 3, ww + 10, 4), frame)
				_bevel(nor, Rect2i(wx - 3, wy - 3, ww + 6, wh + 6), 3, detail >= 2)
				if rgh != null:
					rgh.fill_rect(Rect2i(wx, wy, ww, wh), Color(0.2, 0.2, 0.2))
	# Ground-line grime.
	var grime := Image.create(W, 24, false, Image.FORMAT_RGBA8)
	for gy in 24:
		grime.fill_rect(Rect2i(0, gy, W, 1), Color(0, 0, 0, float(gy) / 24.0 * 0.25))
	alb.blend_rect(grime, Rect2i(0, 0, W, 24), Vector2i(0, C - 24))
	return _finish(alb, nor, rgh, detail >= 2)

## Legacy full-wall curtain glass: 8×8 sky-reflective panes (lighter
## toward the top, per-pane variance), aluminium mullions and spandrels.
static func compose_glass(detail: int) -> Dictionary:
	var alb := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var step := S / 8
	var mull := FacadeComposer.MULLION
	for py in 8:
		for px in 8:
			var v := 0.88 + _h(float(px) * 3.1, float(py) * 7.7) * 0.24
			var sky := FacadeComposer.SKY_GLASS.lerp(FacadeComposer.SKY_GLASS_TOP,
				1.0 - float(py) / 8.0)
			alb.fill_rect(Rect2i(px * step, py * step, step, step),
				Color(sky.r * v, sky.g * v, sky.b * v))
			alb.fill_rect(Rect2i(px * step, py * step + step - 10, step, 10),
				FacadeComposer.SPANDREL)
	for i in 9:
		alb.fill_rect(Rect2i(i * step - 2, 0, 4, S), mull)
		alb.fill_rect(Rect2i(0, i * step - 2, S, 4), mull)
	var nor: Image = null
	var rgh: Image = null
	if detail >= 1:
		nor = Image.create(S, S, false, Image.FORMAT_RGBA8)
		nor.fill(Color(0.5, 0.5, 1.0))
		rgh = Image.create(S, S, false, Image.FORMAT_RGBA8)
		rgh.fill(Color(0.12, 0.12, 0.12))
		for i in 9:
			nor.fill_rect(Rect2i(i * step - 3, 0, 2, S), Color(0.38, 0.5, 1.0))
			nor.fill_rect(Rect2i(i * step + 1, 0, 2, S), Color(0.62, 0.5, 1.0))
			nor.fill_rect(Rect2i(0, i * step - 3, S, 2), Color(0.5, 0.38, 1.0))
			nor.fill_rect(Rect2i(0, i * step + 1, S, 2), Color(0.5, 0.62, 1.0))
			rgh.fill_rect(Rect2i(i * step - 2, 0, 4, S), Color(0.5, 0.5, 0.5))
			rgh.fill_rect(Rect2i(0, i * step - 2, S, 4), Color(0.5, 0.5, 0.5))
	return _finish(alb, nor, rgh)
