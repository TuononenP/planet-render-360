class_name AsiaFronts
extends RefCounted

## East Asian street-front cues FacadeRelief adds after StreetFront, on
## the same ReliefKit (one building is still one mesh):
## - `danji_number` (0..1 odds): a Seoul apartment-complex slab's block
##   number ("101", "102" ...) painted large near the top of its narrow end
##   walls, under an accent band in the complex's colour. The number is the
##   mapped one when the building's name carries it ("파크팰리스 103동"),
##   else seeded in the 101–130 range every danji uses;
## - `sign_bands` (0..1 odds per street stretch): Korean shop streets'
##   horizontal sign boards across the front at every lower storey;
## - `sign_stack` (0..1 odds per street stretch): a Tokyo zakkyo building's
##   vertical sign column running the full height of its front.
## Rolls are seeded per building and stretch.

const DANJI_COLOURS := ["#2c3a4f", "#3a4a3a", "#5a2a2e", "#27465e", "#3d3d42"]
const ACCENTS := ["#2f6db0", "#3a8a5a", "#b0423a", "#d08a2a", "#6a4a9a", "#2a8a8a"]
const BAND_COLOURS := ["#d8262e", "#1f5fb8", "#f2c230", "#1f9e5a", "#f4f1e8", "#e2531f", "#7a2a8a"]
## Slab test: the end wall is at most this share of the long side.
const SLAB_RATIO := 0.45
const END_MIN_M := 7.0
const END_MAX_M := 32.0
const MIN_STOREYS := 10
## Sign bands on storeys 1..this (Korean boards rarely climb higher).
const BAND_STOREYS := 5
## Seven-segment strokes per digit: a b c d e f g.
const SEGMENTS := ["1111110", "0110000", "1101101", "1111001", "0110011",
	"1011011", "1011111", "1110000", "1111111", "1111011"]

static func add(kit: ReliefKit, spans: Array, rows: Array, d: Dictionary) -> void:
	if rows.is_empty():
		return
	var relief: Dictionary = (d["look"] as Dictionary).get("relief", {})
	if not (relief.has("danji_number") or relief.has("sign_bands") or relief.has("sign_stack")):
		return
	var seed_v := float(d["seed"])
	var raised := bool(d.get("raised", false))
	if ArchitectureStyle._h(seed_v, 141) < float(relief.get("danji_number", 0.0)):
		_danji(kit, spans, rows, d, seed_v)
	for i in spans.size():
		var sp: Dictionary = spans[i]
		if not sp["street"] or raised:
			continue
		var salt := float(i) * 1.71
		if ArchitectureStyle._h(seed_v + salt, 142) < float(relief.get("sign_bands", 0.0)):
			_bands(kit, sp, rows, seed_v + salt)
		if ArchitectureStyle._h(seed_v + salt, 143) < float(relief.get("sign_stack", 0.0)):
			_stack(kit, sp, rows, seed_v + salt)

## Block number from the mapped name ("103동", "파크팰리스 103동"), else seeded.
static func danji_number(b: Dictionary, seed_v: float) -> int:
	var hit := dong_regex().search(str(b.get("name", "")))
	if hit != null:
		return int(hit.get_string(1))
	return 101 + int(ArchitectureStyle._h(seed_v, 144) * 30.0) % 30

## The "NNN동" block-name pattern, compiled once.
static var _dong_rx: RegEx
static func dong_regex() -> RegEx:
	if _dong_rx == null:
		_dong_rx = RegEx.create_from_string("(\\d{3,4})\\s*동")
	return _dong_rx

## True when the stretch is the narrow end of a slab (`ring` in internal units).
static func is_slab_end(ring: PackedVector2Array, len_m: float) -> bool:
	if len_m < END_MIN_M or len_m > END_MAX_M:
		return false
	var m := WorldScale.metres_to_units()
	var longest := 0.0
	for i in ring.size():
		longest = maxf(longest, ring[i].distance_to(ring[(i + 1) % ring.size()]) / m)
	return len_m <= longest * SLAB_RATIO

static func _danji(kit: ReliefKit, spans: Array, rows: Array, d: Dictionary, seed_v: float) -> void:
	if rows.size() < MIN_STOREYS:
		return
	var ring: PackedVector2Array = d["ring"]
	var number := str(danji_number(d.get("b", {}), seed_v))
	var ink := ReliefKit.flat(str(DANJI_COLOURS[int(ArchitectureStyle._h(seed_v, 145) * 5.0) % 5]), 0.7)
	var accent := ReliefKit.flat(str(ACCENTS[int(ArchitectureStyle._h(seed_v, 146) * 6.0) % 6]), 0.6)
	var done := 0
	for sp in spans:
		if done >= 2 or not is_slab_end(ring, float(sp["len_m"])):
			continue
		_end_wall(kit, sp, rows, number, ink, accent)
		done += 1

static func _end_wall(kit: ReliefKit, sp: Dictionary, rows: Array, number: String,
		ink: Material, accent: Material) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	# Digits run left to right as seen from outside (looking along -n),
	# whichever way the ring winds.
	var ax := Vector3(n.y, 0.0, -n.x)
	var az := Vector3(n.x, 0.0, n.y)
	var len := float(sp["len_m"]) * m
	var mid: Vector2 = (sp["a"] as Vector2) + dir * len * 0.5
	var top := float(rows[-1]["y1"])
	# Accent band across the top of the end wall.
	var band_h := 0.9 * m
	kit.box(accent, Vector3(mid.x, top - 0.6 * m - band_h * 0.5, mid.y) + az * 0.04 * m, ax, az,
		Vector3(len * 0.92, band_h, 0.06 * m))
	# The number under it: digits as tall as ~1.3 storeys, fitted to the wall.
	var h := clampf(float(sp["len_m"]) * 0.22, 2.4, 4.2) * m
	var dw := h * 0.56
	var gap := h * 0.22
	var count := number.length()
	var total := dw * count + gap * (count - 1)
	if total > len * 0.82:
		var k := len * 0.82 / total
		h *= k
		dw *= k
		gap *= k
		total *= k
	var y_mid := top - 0.6 * m - band_h - 0.9 * m - h * 0.5
	if y_mid - h * 0.5 < float(rows[0]["y1"]):
		return
	for i in count:
		var cx := -total * 0.5 + dw * 0.5 + float(i) * (dw + gap)
		var c := Vector3(mid.x, y_mid, mid.y) + ax * cx + az * 0.04 * m
		_digit(kit, ink, c, ax, az, int(number[i]), dw, h)

## One seven-segment digit centred at `c`, `w` wide and `h` tall.
static func _digit(kit: ReliefKit, mat: Material, c: Vector3, ax: Vector3, az: Vector3,
		digit: int, w: float, h: float) -> void:
	var s := SEGMENTS[clampi(digit, 0, 9)] as String
	var t := h * 0.15
	var depth := 0.05 * WorldScale.metres_to_units()
	var hw := w * 0.5 - t * 0.5
	var hh := h * 0.5 - t * 0.5
	var horiz := Vector3(w - t * 0.4, t, depth)
	var vert := Vector3(t, hh, depth)
	# a (top), d (bottom), g (middle): horizontal strokes.
	if s[0] == "1":
		kit.box(mat, c + Vector3.UP * hh, ax, az, horiz)
	if s[3] == "1":
		kit.box(mat, c - Vector3.UP * hh, ax, az, horiz)
	if s[6] == "1":
		kit.box(mat, c, ax, az, horiz)
	# b (top right), c (bottom right), e (bottom left), f (top left).
	if s[1] == "1":
		kit.box(mat, c + ax * hw + Vector3.UP * hh * 0.5, ax, az, vert)
	if s[2] == "1":
		kit.box(mat, c + ax * hw - Vector3.UP * hh * 0.5, ax, az, vert)
	if s[4] == "1":
		kit.box(mat, c - ax * hw - Vector3.UP * hh * 0.5, ax, az, vert)
	if s[5] == "1":
		kit.box(mat, c - ax * hw + Vector3.UP * hh * 0.5, ax, az, vert)

## Horizontal lit boards across the front under each lower storey's windows.
static func _bands(kit: ReliefKit, sp: Dictionary, rows: Array, seed_v: float) -> void:
	var m := WorldScale.metres_to_units()
	var len := float(sp["len_m"]) * m
	if len < 4.0 * m:
		return
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var mid: Vector2 = (sp["a"] as Vector2) + dir * len * 0.5
	for r in range(1, mini(rows.size() - 1, BAND_STOREYS + 1)):
		var row: Dictionary = rows[r]
		var y_lo := float(row["y0"]) + 0.08 * m
		var y_hi := float(row["win0"]) - 0.05 * m
		var bh := clampf(y_hi - y_lo, 0.5 * m, 1.1 * m)
		if ArchitectureStyle._h(seed_v + float(r), 147) < 0.15:
			continue  # an unlet floor
		var hex := str(BAND_COLOURS[int(ArchitectureStyle._h(seed_v + float(r), 148) * 7.0) % 7])
		var w := len * (0.7 + 0.25 * ArchitectureStyle._h(seed_v + float(r), 149))
		kit.box(ReliefKit.sign(hex), Vector3(mid.x, y_lo + bh * 0.5, mid.y) + az * 0.1 * m, ax, az,
			Vector3(w, bh, 0.14 * m))

## A full-height vertical sign column near one end of the front.
static func _stack(kit: ReliefKit, sp: Dictionary, rows: Array, seed_v: float) -> void:
	var m := WorldScale.metres_to_units()
	if rows.size() < 4:
		return
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var len := float(sp["len_m"]) * m
	var y0 := float(rows[0]["y1"]) + 0.3 * m
	var y1 := float(rows[-1]["y1"]) + 0.6 * m
	var t := 1.2 * m if ArchitectureStyle._h(seed_v, 150) < 0.5 else len - 1.2 * m
	var p: Vector2 = (sp["a"] as Vector2) + dir * t
	var hex := str(BAND_COLOURS[int(ArchitectureStyle._h(seed_v, 151) * 7.0) % 7])
	kit.box(ReliefKit.sign(hex), Vector3(p.x, (y0 + y1) * 0.5, p.y) + az * 0.75 * m, ax, az,
		Vector3(0.22 * m, y1 - y0, 1.3 * m))
	# The boards stacked on its face, one per floor in alternating colours.
	for r in range(1, rows.size()):
		var row: Dictionary = rows[r]
		var alt := str(BAND_COLOURS[int(ArchitectureStyle._h(seed_v + float(r), 152) * 7.0) % 7])
		kit.box(ReliefKit.sign(alt), Vector3(p.x, (float(row["y0"]) + float(row["y1"])) * 0.5, p.y)
			+ az * 0.75 * m, ax, az, Vector3(0.3 * m, (float(row["y1"]) - float(row["y0"])) * 0.82, 1.15 * m))
