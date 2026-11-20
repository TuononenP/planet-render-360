class_name TramBoards
extends RefCounted

## Route boards of Helsinki's trams (H-7): an amber LED matrix over the
## windscreen and a smaller one on each side by the front door, showing
## the route number and its destination. A board is its own surface
## ("RouteBoard") with UVs over the whole panel; TramModel lays the
## panels on a cab section whose livery has "boards", and
## TransitVehicles points that surface at the material of the tram's
## route (material()), so one cached mesh serves every route.
## * The matrix is ROWS x COLS LEDs, LED_PX texels each: a lit LED is an
##   amber dot, an unlit one a faint grey dot on the black panel. The
##   number is drawn in a 5 x 7 font at twice its size, the destination
##   at twice its height (the condensed letters of a tram's board).
## * By day the lit dots are amber paint; at night they glow with the
##   city (CityLights).

const ROWS := 16
const COLS := 100
const LED_PX := 4
const SURFACE := "RouteBoard"
## The board over the windscreen and the side ones (metres).
const FRONT_W := 1.5
const SIDE_W := 1.1
const NOSE_COLS := 8
## An LED cell is this many times taller than wide on the panel.
const LED_ASPECT := 1.6
const LIT := Color8(255, 158, 32)

## Helsinki's tram routes as [number, destination], uppercase as the
## font has it; and those of Raide-Jokeri's light rail (route 15).
const HELSINKI := [["1", "KÄPYLÄ"], ["2", "PASILA"], ["3", "MEILAHTI"], ["3", "KAIVOPUISTO"],
	["4", "MUNKKINIEMI"], ["4", "KATAJANOKKA"], ["5", "KATAJANOKKA"], ["6", "ARABIA"], ["6", "HIETALAHTI"],
	["7", "PASILA"], ["8", "JÄTKÄSAARI"], ["8", "ARABIA"], ["9", "PASILA"], ["9", "JÄTKÄSAARI"],
	["10", "KIRURGI"]]
const JOKERI := [["15", "KEILANIEMI"], ["15", "ITÄKESKUS"]]

## 5 x 7 glyphs, a row a string, top first.
const FONT := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
	"G": ["01110", "10001", "10000", "10111", "10001", "10001", "01111"],
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
	"J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"],
	"K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"N": ["10001", "10001", "11001", "10101", "10011", "10001", "10001"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	"V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	"Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	"Ä": ["01010", "00000", "01110", "10001", "11111", "10001", "10001"],
	"Ö": ["01010", "00000", "01110", "10001", "10001", "10001", "01110"],
	"0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
	"3": ["11111", "00010", "00100", "00010", "00001", "10001", "01110"],
	"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
	"5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
	"6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
	"-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
}

static var _materials := {}

## The routes a tram on `rail` in CityStyles region `region` may show
## ([] where trams carry no boards).
static func routes(region: String, rail: Dictionary) -> Array:
	if not region in ["helsinki", "espoo"]:
		return []
	return JOKERI if str(rail.get("class", "")) == "light_rail" else HELSINKI

## The board a tram shows, [number, destination], from its hash `h`
## (0..1); [] where trams carry none.
static func pick(region: String, rail: Dictionary, h: float) -> Array:
	var list := routes(region, rail)
	if list.is_empty():
		return []
	return list[mini(int(h * list.size()), list.size() - 1)]

## The LED matrix of `board` ([number, destination]): ROWS strings of
## COLS "0" / "1", top first.
static func matrix(board: Array) -> PackedStringArray:
	var grid: Array = []
	for r in ROWS:
		var row := PackedByteArray()
		row.resize(COLS)
		row.fill(0)
		grid.append(row)
	var num := str(board[0])
	var x := 2
	for ch in num:
		_glyph(grid, ch, x, 1, 2, 2)
		x += 12
	var dest := str(board[1])
	var span := dest.length() * 6 - 1
	var left := x + 2
	_text(grid, dest, left + maxi((COLS - 2 - left - span) / 2, 0), 1, 1, 2)
	var out := PackedStringArray()
	for row: PackedByteArray in grid:
		var s := ""
		for b in row:
			s += "1" if b > 0 else "0"
		out.append(s)
	return out

static func _text(grid: Array, text: String, x: int, y: int, sx: int, sy: int) -> void:
	for ch in text:
		_glyph(grid, ch, x, y, sx, sy)
		x += 6 * sx

## Lights glyph `ch` with its top left LED at (x, y), scaled sx by sy.
static func _glyph(grid: Array, ch: String, x: int, y: int, sx: int, sy: int) -> void:
	var rows: Array = FONT.get(ch, [])
	for r in rows.size():
		var bits := str(rows[r])
		for c in bits.length():
			if bits[c] != "1":
				continue
			for dy in sy:
				for dx in sx:
					var gx := x + c * sx + dx
					var gy := y + r * sy + dy
					if gx >= 0 and gx < COLS and gy >= 0 and gy < ROWS:
						(grid[gy] as PackedByteArray)[gx] = 1

## The panel texture of `board`: dots on black, mipmapped.
static func texture(board: Array) -> ImageTexture:
	var lit := matrix(board)
	var w := COLS * LED_PX
	var h := ROWS * LED_PX
	var px := PackedByteArray()
	px.resize(w * h * 3)
	for y in h:
		var gy := y / LED_PX
		var cy := y % LED_PX
		var row := lit[gy]
		for x in w:
			var cx := x % LED_PX
			var on := row[x / LED_PX] == "1"
			# A round dot in the cell: full in its middle, half at its edge.
			var dot := 0.0 if cx == LED_PX - 1 or cy == LED_PX - 1 else (1.0 if cx == 1 and cy == 1 else 0.6)
			var c := LIT * dot if on else Color(0.07, 0.07, 0.07) * dot
			var i := (y * w + x) * 3
			px[i] = int(clampf(c.r, 0.0, 1.0) * 255.0) + (0 if on else 4)
			px[i + 1] = int(clampf(c.g, 0.0, 1.0) * 255.0) + (0 if on else 4)
			px[i + 2] = int(clampf(c.b, 0.0, 1.0) * 255.0) + (0 if on else 4)
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGB8, px)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## The shared material of `board`: the panel by day, glowing by night.
static func material(board: Array) -> StandardMaterial3D:
	var key := "%s|%s" % [board[0], board[1]] if board.size() >= 2 else ""
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.25
	m.metallic_specular = 0.4
	if key != "":
		var tex := texture(board)
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_texture = tex
		CityLights.mark_glow(m, 1.2)
	else:
		m.albedo_color = Color(0.02, 0.02, 0.02)
	_materials[key] = m
	return m

## Lays the boards of a cab section on `lm` (surface SURFACE, which the
## caller registers): over the screen of its front nose, and on both
## sides just behind it. `w` is the half width, `belt` the screen's foot.
static func add(lm: LandmarkMesh, sec: Dictionary, w: float, belt: float) -> void:
	var nose: Dictionary = sec["front"]
	if nose.is_empty() or not bool(nose.get("board", false)):
		return
	var prof: Array = sec["prof"]
	var c := -1
	for i in prof.size():
		if str(prof[i][2]) == "upper":
			c = i
			break
	if c < 0 or c + 1 >= prof.size():
		return
	var y0 := float(prof[c][0])
	var y1 := float(prof[c + 1][0])
	var x_f := float(sec["len"]) * 0.5 - float(nose.get("len", 0.0))
	# Front: a strip following the nose's plan curve, a little proud of it.
	var fw := minf(FRONT_W, w * 2.0 * 0.6)
	var fh := minf((y1 - y0) * 0.75, fw * float(ROWS) / float(COLS) * LED_ASPECT)
	var ya := (y0 + y1) * 0.5 - fh * 0.5
	var yb := ya + fh
	for i in NOSE_COLS:
		var za := fw * 0.5 - fw * float(i) / float(NOSE_COLS)
		var zb := fw * 0.5 - fw * float(i + 1) / float(NOSE_COLS)
		var ua := float(i) / float(NOSE_COLS)
		var ub := float(i + 1) / float(NOSE_COLS)
		var a := Vector3(_nose_x(nose, x_f, w, belt, za, ya), ya, za)
		var b := Vector3(_nose_x(nose, x_f, w, belt, zb, ya), ya, zb)
		var cc := Vector3(_nose_x(nose, x_f, w, belt, zb, yb), yb, zb)
		var d := Vector3(_nose_x(nose, x_f, w, belt, za, yb), yb, za)
		var n := (b - a).cross(d - a).normalized()
		if n.x < 0.0:
			n = -n
		lm.tri(SURFACE, a, b, cc, n, n, n, Vector2(ua, 1.0), Vector2(ub, 1.0), Vector2(ub, 0.0))
		lm.tri(SURFACE, a, cc, d, n, n, n, Vector2(ua, 1.0), Vector2(ub, 0.0), Vector2(ua, 0.0))
	# Sides: just behind the nose, over the first window.
	var sh := minf(SIDE_W * float(ROWS) / float(COLS) * LED_ASPECT, (y1 - y0) * 0.8)
	var sw := sh * float(COLS) / float(ROWS) / LED_ASPECT
	var s0 := y0 + (y1 - y0 - sh) * 0.5
	var s1 := s0 + sh
	var z0 := w * float(prof[c][1])
	var z1 := w * float(prof[c + 1][1])
	var za0 := lerpf(z0, z1, (s0 - y0) / (y1 - y0)) + 0.012
	var za1 := lerpf(z0, z1, (s1 - y0) / (y1 - y0)) + 0.012
	var xb := x_f - 0.35
	var xa := xb - sw
	for side: float in [1.0, -1.0]:
		# The upper side leans in: its normal tips up.
		var n := Vector3(0.0, (za0 - za1) / maxf(s1 - s0, 1e-3), side).normalized()
		# Read left to right from outside: rear to front on +Z, front to rear on -Z.
		var u_rear := 0.0 if side > 0.0 else 1.0
		var a := Vector3(xa, s0, side * za0)
		var b := Vector3(xb, s0, side * za0)
		var cc := Vector3(xb, s1, side * za1)
		var d := Vector3(xa, s1, side * za1)
		lm.tri(SURFACE, a, b, cc, n, n, n, Vector2(u_rear, 1.0), Vector2(1.0 - u_rear, 1.0), Vector2(1.0 - u_rear, 0.0))
		lm.tri(SURFACE, a, cc, d, n, n, n, Vector2(u_rear, 1.0), Vector2(1.0 - u_rear, 0.0), Vector2(u_rear, 0.0))

## Where the nose's skin lies at height `y`, `z` off the centreline
## (TramModel._nose_row's bow and rake), plus a small lift off it.
static func _nose_x(nose: Dictionary, x_f: float, w: float, belt: float, z: float, y: float) -> float:
	var k := clampf(absf(z) / (w * 0.97), 0.0, 1.0)
	var bow := 1.0 - pow(k, float(nose["pow"]))
	var reach := maxf(float(nose["len"]) - float(nose["rake"]) * maxf(y - belt, 0.0), 0.03)
	return x_f + bow * reach + 0.015
