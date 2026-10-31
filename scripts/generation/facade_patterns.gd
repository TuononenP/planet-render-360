class_name FacadePatterns
extends RefCounted

## City / era tiled facade patterns for FacadeComposer (same contract:
## one storey of BAYS bays, CELL px per bay, windows centred in each bay
## cell so 3D relief can align with them):
##   panel      prefab concrete panel grid: joint lines, per-panel tone,
##              wide ribbon-ish windows on a sill slab; shutter_p >= 0.5
##              paints a spandrel colour band in the shutter colour
##              (Singapore HDB) with an AC box now and then — else bare
##              panels (Plattenbau, HLM, council slabs).
##   ornate     punched windows in moulded surrounds, alternating
##              triangular / flat pediments, keystones, a string course
##              at sill level (Gründerzeit, Victorian, stucco terraces).
##   brownstone tall narrow 2-over-2 sashes under heavy stone lintels,
##              bracketed sills, dressed-stone coursing (NYC, greystones).
##   shophouse  tall arched French windows between pilasters, louvred
##              shutters (open or closed), frieze and sill string
##              (Singapore / Malaysia / HK shophouses).
## Mouldings are light/shadow on the base layer (they take the wall's own
## tint, like StoreyComposer's stone relief); frames, glass, shutters and
## bands go on the paint layer (FacadePaint). FacadeComposer passes its
## look values in `pv` and owns the shared window table, pane and hash.

const NAMES: Array[String] = ["panel", "ornate", "brownstone", "shophouse"]
## Matches FacadeComposer.CELL (pinned by tests/architecture_test.gd).
const CELL := 128
const DARK := Color(0.03, 0.03, 0.03)
const IRON := Color(0.0116, 0.0116, 0.0137)
const JOINT := Color(0.0, 0.0, 0.0, 0.34)
const JOINT_LIGHT := Color(1.0, 1.0, 1.0, 0.10)

static func has(pattern: String) -> bool:
	return pattern in NAMES

## Wall-material pass over the whole strip (base layer, takes the tint):
## panel joints, stone coursing, string courses, pilasters.
static func prepass(pattern: String, base: Image, nor: Image, w: int, pv: Dictionary) -> void:
	var variant := int(pv.get("variant", 0))
	match pattern:
		"panel":
			for bay in w / CELL:
				var ox := bay * CELL
				var tone := FacadeComposer._hash(float(bay) * 3.1 + float(variant) * 1.7, 2.3)
				var c := Color(1, 1, 1, 0.07) if tone > 0.5 else Color(0, 0, 0, 0.07)
				FacadePaint.shade(base, Rect2i(ox, 0, CELL, CELL), c)
			for x in range(0, w, CELL):
				FacadePaint.shade(base, Rect2i(x, 0, 2, CELL), JOINT)
				FacadePaint.shade(base, Rect2i(x + 2, 0, 1, CELL), JOINT_LIGHT)
			FacadePaint.shade(base, Rect2i(0, CELL - 3, w, 2), JOINT)
			FacadePaint.shade(base, Rect2i(0, CELL - 1, w, 1), JOINT_LIGHT)
			FacadePaint.shade(base, Rect2i(0, 92, w, 1), Color(0, 0, 0, 0.22))
			if nor != null:
				for x in range(0, w, CELL):
					nor.fill_rect(Rect2i(x, 0, 2, CELL), Color(0.38, 0.5, 1.0))
					nor.fill_rect(Rect2i(x + 2, 0, 1, CELL), Color(0.62, 0.5, 1.0))
				nor.fill_rect(Rect2i(0, CELL - 3, w, 2), Color(0.5, 0.38, 1.0))
		"ornate":
			_band(base, nor, w, 106, 6)
			_band(base, nor, w, 0, 3)
		"brownstone":
			for y in [0, 40, 80]:
				FacadePaint.shade(base, Rect2i(0, y, w, 1), Color(0, 0, 0, 0.12))
				FacadePaint.shade(base, Rect2i(0, y + 1, w, 1), Color(1, 1, 1, 0.06))
			_band(base, nor, w, 0, 4)
		"shophouse":
			_band(base, nor, w, 0, 12)
			for x in range(4, w, 10):
				FacadePaint.shade(base, Rect2i(x, 12, 5, 3), FacadePaint.SHADOW)
			_band(base, nor, w, 106, 4)
			for x in range(0, w + 1, CELL):
				var r := Rect2i(x - 7, 15, 14, 91)
				FacadePaint.shade(base, r, FacadePaint.LIGHT)
				FacadePaint.shade(base, Rect2i(x + 6, 15, 2, 91), FacadePaint.SHADOW)
				FacadePaint.shade(base, Rect2i(x - 9, 15, 18, 4), FacadePaint.LIGHT)
				if nor != null:
					var rr := r.intersection(Rect2i(0, 0, w, CELL))
					if rr.size.x > 0:
						nor.fill_rect(Rect2i(rr.position.x, 15, 1, 91), Color(0.38, 0.5, 1.0))

## One bay's openings (paint layer) plus its mouldings (base layer).
static func bay(pattern: String, alb: Image, nor: Image, rgh: Image, emit: Image,
		base: Image, ox: int, bay_i: int, hv: float, pv: Dictionary) -> void:
	match pattern:
		"panel":
			_panel(alb, nor, rgh, emit, base, ox, hv, pv)
		"ornate":
			_ornate(alb, nor, rgh, emit, base, ox, bay_i, hv, pv)
		"brownstone":
			_brownstone(alb, nor, rgh, emit, base, ox, hv, pv)
		"shophouse":
			_shophouse(alb, nor, rgh, emit, base, ox, hv, pv)

static func _panel(alb: Image, nor: Image, rgh: Image, emit: Image, base: Image,
		ox: int, hv: float, pv: Dictionary) -> void:
	var frame: Color = pv["frame"]
	var r := Rect2i(ox + 22, 30, 84, 50)
	_win(alb, nor, rgh, emit, r, frame, pv["glass"], hv, 3, 1)
	# Concrete sill slab under the window.
	alb.fill_rect(Rect2i(ox + 18, 83, 92, 4), Color(0.50, 0.49, 0.46))
	alb.fill_rect(Rect2i(ox + 18, 87, 92, 1), DARK)
	FacadePaint.streaks(base, ox + 20, ox + 108, 88, 30, hv * 17.0, 0.12)
	if float(pv.get("shutter_p", 0.0)) >= 0.5:
		var band: Color = pv["shutter"]
		alb.fill_rect(Rect2i(ox, 96, CELL, 14), band)
		alb.fill_rect(Rect2i(ox, 96, 2, 14), DARK.lerp(band, 0.5))
		if hv > 0.82:  # air-conditioner box beside the window
			alb.fill_rect(Rect2i(ox + 4, 58, 15, 13), Color(0.62, 0.62, 0.60))
			alb.fill_rect(Rect2i(ox + 6, 60, 11, 9), Color(0.30, 0.30, 0.30))
	if nor != null:
		nor.fill_rect(Rect2i(ox + 18, 83, 92, 2), Color(0.5, 0.75, 1.0))

static func _ornate(alb: Image, nor: Image, rgh: Image, emit: Image, base: Image,
		ox: int, bay_i: int, hv: float, pv: Dictionary) -> void:
	var box := FacadeComposer._window_box(str(pv.get("window", "casement")))
	var ww := box.x
	var wh := box.y
	var wy := box.z
	var wx := ox + (CELL - ww) / 2
	var cx := ox + CELL / 2
	# Moulded architrave around the opening.
	FacadePaint.shade(base, Rect2i(wx - 8, wy - 6, ww + 16, wh + 12), FacadePaint.LIGHT)
	FacadePaint.shade(base, Rect2i(wx + ww + 6, wy - 4, 2, wh + 10), FacadePaint.SHADOW)
	# Alternating pediments: triangular / flat cornice, keystone between.
	if (bay_i + int(pv.get("variant", 0))) % 2 == 0 and wy >= 22:
		for i in 9:
			var half := (ww + 18) / 2 - i * (ww + 18) / 18
			FacadePaint.shade(base, Rect2i(cx - half, wy - 9 - i, half * 2, 1), FacadePaint.LIGHT)
		FacadePaint.shade(base, Rect2i(wx - 9, wy - 8, ww + 18, 2), FacadePaint.SHADOW)
	else:
		FacadePaint.shade(base, Rect2i(wx - 11, wy - 12, ww + 22, 5), FacadePaint.LIGHT)
		FacadePaint.shade(base, Rect2i(wx - 11, wy - 7, ww + 22, 2), FacadePaint.SHADOW)
		FacadePaint.shade(base, Rect2i(cx - 4, wy - 7, 8, 8), FacadePaint.LIGHT)
	# Bracketed sill.
	FacadePaint.shade(base, Rect2i(wx - 9, wy + wh + 4, ww + 18, 4), FacadePaint.LIGHT)
	FacadePaint.shade(base, Rect2i(wx - 9, wy + wh + 8, ww + 18, 2), FacadePaint.SHADOW)
	var frame: Color = pv["frame"]
	var cols := 2 if ww < 60 else 3
	var rows := 2 if str(pv.get("window", "")) in ["sash", "french"] else 1
	_win(alb, nor, rgh, emit, Rect2i(wx, wy, ww, wh), frame, pv["glass"], hv, cols, rows)
	FacadePaint.streaks(base, wx - 4, wx + ww + 4, wy + wh + 10, CELL / 3, hv * 29.0)
	var hr := FacadeComposer._hash(float(bay_i) * 2.7 + float(pv.get("variant", 0)) * 1.3, 8.9)
	if hr < float(pv.get("rails", 0.0)):
		_rail(alb, wx - 4, wy + wh - wh / 4, ww + 8, wh / 4)
	if nor != null:
		nor.fill_rect(Rect2i(wx - 8, wy - 6, ww + 16, 2), Color(0.5, 0.35, 1.0))
		nor.fill_rect(Rect2i(wx - 9, wy + wh + 4, ww + 18, 2), Color(0.5, 0.7, 1.0))

static func _brownstone(alb: Image, nor: Image, rgh: Image, emit: Image, base: Image,
		ox: int, hv: float, pv: Dictionary) -> void:
	var box := window_box("brownstone", "")
	var ww := box.x
	var wh := box.y
	var wy := box.z
	var wx := ox + (CELL - ww) / 2
	# Heavy stone lintel with a projecting cap.
	FacadePaint.shade(base, Rect2i(wx - 11, wy - 17, ww + 22, 3), FacadePaint.LIGHT)
	FacadePaint.shade(base, Rect2i(wx - 9, wy - 14, ww + 18, 11), FacadePaint.LIGHT)
	FacadePaint.shade(base, Rect2i(wx - 9, wy - 3, ww + 18, 3), FacadePaint.SHADOW)
	# Sill on two brackets.
	FacadePaint.shade(base, Rect2i(wx - 7, wy + wh + 3, ww + 14, 6), FacadePaint.LIGHT)
	FacadePaint.shade(base, Rect2i(wx - 7, wy + wh + 9, ww + 14, 2), FacadePaint.SHADOW)
	for bx in [wx - 3, wx + ww - 1]:
		FacadePaint.shade(base, Rect2i(bx, wy + wh + 11, 4, 6), FacadePaint.LIGHT)
	var frame: Color = pv["frame"]
	_win(alb, nor, rgh, emit, Rect2i(wx, wy, ww, wh), frame, pv["glass"], hv, 2, 2)
	FacadePaint.streaks(base, wx - 6, wx + ww + 6, wy + wh + 11, CELL / 4, hv * 23.0)
	if nor != null:
		nor.fill_rect(Rect2i(wx - 11, wy - 17, ww + 22, 2), Color(0.5, 0.3, 1.0))
		nor.fill_rect(Rect2i(wx - 9, wy - 3, ww + 18, 3), Color(0.5, 0.72, 1.0))
		nor.fill_rect(Rect2i(wx - 7, wy + wh + 3, ww + 14, 2), Color(0.5, 0.3, 1.0))

static func _shophouse(alb: Image, nor: Image, rgh: Image, emit: Image, base: Image,
		ox: int, hv: float, pv: Dictionary) -> void:
	var box := window_box("shophouse", "")
	var ww := box.x
	var wh := box.y
	var wy := box.z
	var wx := ox + (CELL - ww) / 2
	var frame: Color = pv["frame"]
	var shutter: Color = pv["shutter"]
	# Arched fanlight over the opening (frame ring + glass).
	var rad := ww / 2 + 3
	var cx := wx + ww / 2
	for i in rad:
		var half := int(sqrt(float(rad * rad - i * i)))
		alb.fill_rect(Rect2i(cx - half, wy - 3 - i, half * 2, 1), frame)
		if i < rad - 3:
			var gh := int(sqrt(float((rad - 3) * (rad - 3) - i * i)))
			alb.fill_rect(Rect2i(cx - gh, wy - 3 - i, gh * 2, 1), pv["glass"])
	FacadePaint.shade(base, Rect2i(wx - 6, wy - rad - 6, ww + 12, 4), FacadePaint.LIGHT)
	var closed := hv > 0.72
	if closed:  # louvred shutters drawn over the window
		alb.fill_rect(Rect2i(wx - 3, wy - 3, ww + 6, wh + 6), frame)
		alb.fill_rect(Rect2i(wx, wy, ww, wh), shutter)
		alb.fill_rect(Rect2i(cx - 1, wy, 2, wh), DARK.lerp(shutter, 0.4))
		for ly in range(wy + 3, wy + wh, 5):
			alb.fill_rect(Rect2i(wx + 2, ly, ww - 4, 1), DARK.lerp(shutter, 0.55))
	else:
		_win(alb, nor, rgh, emit, Rect2i(wx, wy, ww, wh), frame, pv["glass"], hv, 2, 3)
		for sx in [wx - 21, wx + ww + 3]:  # open leaves folded against the wall
			alb.fill_rect(Rect2i(sx, wy - 2, 18, wh + 4), shutter)
			for ly in range(wy + 1, wy + wh, 5):
				alb.fill_rect(Rect2i(sx + 2, ly, 14, 1), DARK.lerp(shutter, 0.55))
	FacadePaint.shade(base, Rect2i(wx - 8, wy + wh + 3, ww + 16, 4), FacadePaint.LIGHT)
	FacadePaint.shade(base, Rect2i(wx - 8, wy + wh + 7, ww + 16, 2), FacadePaint.SHADOW)
	var hr := FacadeComposer._hash(float(ox) * 0.031 + float(pv.get("variant", 0)) * 1.3, 4.1)
	if hr < float(pv.get("rails", 0.0)):
		_rail(alb, wx - 6, wy + wh - 18, ww + 12, 18)
	if nor != null:
		nor.fill_rect(Rect2i(wx - 8, wy + wh + 3, ww + 16, 2), Color(0.5, 0.3, 1.0))

## Window: frame ring, pane (some lit, some curtained), sky band at the
## head, glazing bars (cols x rows), sill shadow; glass roughness 0.2 so
## FacadeComposer.depth_from_rough recesses it on Ultra.
static func _win(alb: Image, nor: Image, rgh: Image, emit: Image, r: Rect2i,
		frame: Color, _glass: Color, hv: float, cols: int, rows: int) -> void:
	alb.fill_rect(Rect2i(r.position.x - 4, r.position.y - 6, r.size.x + 8, 3), DARK)
	alb.fill_rect(r.grow(3), frame)
	FacadeComposer.glass_pane(alb, r, hv)
	FacadePaint.pane(emit, r, hv)
	for k in range(1, cols):
		alb.fill_rect(Rect2i(r.position.x + r.size.x * k / cols - 1, r.position.y, 3, r.size.y), frame)
	for k in range(1, rows):
		alb.fill_rect(Rect2i(r.position.x, r.position.y + r.size.y * k / rows - 1, r.size.x, 3), frame)
	alb.fill_rect(Rect2i(r.position.x - 3, r.end.y + 3, r.size.x + 6, 2), DARK)
	if nor != null:
		nor.fill_rect(Rect2i(r.position.x - 3, r.position.y - 3, r.size.x + 6, 3), Color(0.5, 0.3, 1.0))
		nor.fill_rect(Rect2i(r.position.x - 3, r.position.y - 3, 3, r.size.y + 6), Color(0.3, 0.5, 1.0))
		nor.fill_rect(Rect2i(r.end.x, r.position.y - 3, 3, r.size.y + 6), Color(0.7, 0.5, 1.0))
		nor.fill_rect(Rect2i(r.position.x - 3, r.end.y, r.size.x + 6, 3), Color(0.5, 0.7, 1.0))
	if rgh != null:
		rgh.fill_rect(r, Color(0.2, 0.2, 0.2))

## Wrought-iron balconette: top and bottom rail with balusters.
static func _rail(alb: Image, x: int, y: int, w: int, h: int) -> void:
	alb.fill_rect(Rect2i(x, y, w, 2), IRON)
	alb.fill_rect(Rect2i(x, y + h, w, 2), IRON)
	for bx in range(x, x + w, 4):
		alb.fill_rect(Rect2i(bx, y, 1, h), IRON)

## Moulded band across the strip (light face, shadow below), on the base.
static func _band(base: Image, nor: Image, w: int, y: int, h: int) -> void:
	FacadePaint.shade(base, Rect2i(0, y, w, h), FacadePaint.LIGHT)
	FacadePaint.shade(base, Rect2i(0, y + h, w, 2), FacadePaint.SHADOW)
	if nor != null:
		nor.fill_rect(Rect2i(0, y, w, 1), Color(0.5, 0.3, 1.0))
		nor.fill_rect(Rect2i(0, y + h, w, 2), Color(0.5, 0.72, 1.0))

## Window box (width, height, top; px of a 128 px storey) as painted by
## `pattern`: what FacadeRelief aligns 3D sills and balconettes to.
static func window_box(pattern: String, win: String) -> Vector3i:
	match pattern:
		"brownstone":
			return Vector3i(36, 76, 22)
		"shophouse":
			return Vector3i(40, 70, 30)
	return FacadeComposer._window_box(win)
