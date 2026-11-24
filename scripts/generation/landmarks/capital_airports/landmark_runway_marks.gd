class_name LandmarkRunwayMarks
extends RefCounted

## Paint on a hard runway in the airfield frame (X, Z metres; Y up): edge
## lines, the dashed centre line, threshold bars, the painted designators,
## the aiming-point bars and the first touchdown-zone pairs, to the layout
## of ICAO Annex 14 as seen from the air. Every mark is a flat quad lifted
## MARK_LIFT above the runway top.

const MARK_LIFT := 0.04
const EDGE_W := 0.9
const DASH_M := 30.0
const DASH_PERIOD_M := 50.0
const BAR_LEN_M := 30.0
const BAR_W := 1.8
const GLYPH_W := 4.0
const GLYPH_H := 9.0
const GLYPH_STROKE := 1.2
const GLYPH_GAP := 1.6

## Segments of a seven-segment cell: a top, b upper right, c lower right,
## d bottom, e lower left, f upper left, g middle.
const GLYPHS := {
	"0": "abcdef", "1": "bc", "2": "abdeg", "3": "abcdg", "4": "bcfg", "5": "acdfg",
	"6": "acdefg", "7": "abc", "8": "abcdefg", "9": "abcdfg",
	"L": "def", "R": "abfgec", "C": "afed",
}

## One runway: `r` is a layout runway {a, b, w, na, nb} and `top` the
## height of its surface.
static func paint(lm: LandmarkMesh, r: Dictionary, top: float) -> void:
	var a := _v2(r["a"])
	var b := _v2(r["b"])
	var length := a.distance_to(b)
	if length < 300.0:
		return
	var d := (b - a) / length
	var rt := Vector2(-d.y, d.x)
	var w := float(r["w"])
	var y := top + MARK_LIFT
	var thr := 6.0
	var lines_end := thr + BAR_LEN_M + 6.0
	# Edge lines run the strip between the thresholds.
	for s: float in [-1.0, 1.0]:
		var c := (a + b) * 0.5 + rt * s * (w * 0.5 - 1.2)
		strip(lm, "MarkW", c, d, rt, length - 2.0 * lines_end, EDGE_W, y)
	var cw := 0.9 if w >= 30.0 else 0.45
	var start := lines_end + 12.0
	var at := start
	while at + DASH_M <= length - start:
		strip(lm, "MarkW", a + d * (at + DASH_M * 0.5), d, rt, DASH_M, cw, y)
		at += DASH_PERIOD_M
	for end in 2:
		var o := a if end == 0 else b
		var out := d if end == 0 else -d
		_threshold(lm, o, out, rt, w, y)
		_designator(lm, o + out * (thr + BAR_LEN_M + 12.0), out, str(r["na"] if end == 0 else r["nb"]), y)
		_aiming_and_zones(lm, o, out, rt, w, length, y)

## Threshold bars: stripes across the strip, a gap at the centre line.
static func _threshold(lm: LandmarkMesh, o: Vector2, out: Vector2, rt: Vector2, w: float, y: float) -> void:
	var n := clampi(int(w / 3.8) / 2 * 2, 4, 16)
	var span := w - 7.0
	for i in n:
		var u := -span * 0.5 + span * float(i) / float(n - 1)
		if absf(u) < 1.0:
			continue
		strip(lm, "MarkW", o + out * (6.0 + BAR_LEN_M * 0.5) + rt * u, out, rt, BAR_LEN_M, BAR_W, y)

static func _aiming_and_zones(lm: LandmarkMesh, o: Vector2, out: Vector2, rt: Vector2, w: float, length: float,
		y: float) -> void:
	if length < 900.0:
		return
	var aim := 300.0 if length < 1500.0 else 400.0
	var long_bar := 30.0 if length < 1500.0 else 45.0
	for s: float in [-1.0, 1.0]:
		strip(lm, "MarkW", o + out * (aim + long_bar * 0.5) + rt * s * (w * 0.5 - 8.0 - minf(w * 0.1, 3.0)),
			out, rt, long_bar, 6.0, y)
	if w < 30.0 or length < 1200.0:
		return
	for k in 3:
		var at := 150.0 * float(k + 1)
		if at + 30.0 > aim - 20.0 and at < aim + 60.0:
			continue
		for s: float in [-1.0, 1.0]:
			for off: float in [0.0, 3.3]:
				strip(lm, "MarkW", o + out * (at + 11.0) + rt * s * (w * 0.5 - 9.0 - off), out, rt, 22.5, 1.8, y)

## The painted number or letters, read by a pilot landing along `inward`
## (from the threshold into the runway): the glyph tops point down the
## runway and the baseline sits on `anchor`.
static func _designator(lm: LandmarkMesh, anchor: Vector2, inward: Vector2, text: String, y: float) -> void:
	var right := Vector2(-inward.y, inward.x)
	var n := text.length()
	var total := float(n) * GLYPH_W + float(n - 1) * GLYPH_GAP
	for i in n:
		var u0 := -total * 0.5 + float(i) * (GLYPH_W + GLYPH_GAP) + GLYPH_W * 0.5
		glyph(lm, text[i], anchor + right * u0, inward, right, y)

## One glyph with its baseline at `base`, `up` its top direction and
## `right` its reading direction.
static func glyph(lm: LandmarkMesh, ch: String, base: Vector2, up: Vector2, right: Vector2, y: float) -> void:
	var segs: String = GLYPHS.get(ch, "")
	var s := GLYPH_STROKE
	var half_v := GLYPH_H * 0.5
	for seg in segs:
		var u := 0.0
		var v := 0.0
		var su := GLYPH_W
		var sv := s
		match seg:
			"a": v = GLYPH_H - s * 0.5
			"d": v = s * 0.5
			"g": v = half_v
			"b": u = GLYPH_W * 0.5 - s * 0.5; v = GLYPH_H * 0.75; su = s; sv = half_v
			"c": u = GLYPH_W * 0.5 - s * 0.5; v = GLYPH_H * 0.25; su = s; sv = half_v
			"e": u = -GLYPH_W * 0.5 + s * 0.5; v = GLYPH_H * 0.25; su = s; sv = half_v
			"f": u = -GLYPH_W * 0.5 + s * 0.5; v = GLYPH_H * 0.75; su = s; sv = half_v
		var centre := base + right * u + up * v
		strip(lm, "MarkW", centre, up, right, sv, su, y)

## A flat painted rectangle: `along_len` long (along `d`) and `wid` wide
## (along `rt`), centred on `c`, at height `y`. Subdivided every 40 m so
## long edge lines drape cleanly onto conforming runways.
static func strip(lm: LandmarkMesh, key: String, c: Vector2, d: Vector2, rt: Vector2, along_len: float,
		wid: float, y: float) -> void:
	if along_len <= 0.0:
		return
	var segs := maxi(1, int(ceil(along_len / 40.0)))
	var a := c - d * along_len * 0.5
	var b := c + d * along_len * 0.5
	var hw := rt * wid * 0.5
	for k in segs:
		var p0 := a.lerp(b, float(k) / float(segs))
		var p1 := a.lerp(b, float(k + 1) / float(segs))
		lm.quad(key, _v3(p0 - hw, y), _v3(p1 - hw, y), _v3(p1 + hw, y), _v3(p0 + hw, y), Vector3.UP)

static func _v2(p) -> Vector2:
	return Vector2(float(p[0]), float(p[1]))

static func _v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)
