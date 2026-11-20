class_name HullLettering
extends RefCounted

## Painted block lettering on a lofted hull (ship names, line names): a
## 5 x 7 dot-matrix face whose lit runs become thin boxes standing just
## proud of the plating, so one name is a few hundred triangles in the
## caller's own surface key. Metres, +X bow, the hull's HullLoft spec.
## Text reads left to right from either side: aft-to-bow on starboard
## (+Z), bow-to-aft on port. Unknown characters draw as spaces.

const ROWS := 7
const COLS := 5
const GLYPHS := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
	"G": ["01111", "10000", "10000", "10011", "10001", "10001", "01111"],
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"],
	"K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	"V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	"W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
	"Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	"Ä": ["01010", "00000", "01110", "10001", "11111", "10001", "10001"],
	"Ö": ["01010", "00000", "01110", "10001", "10001", "10001", "01110"],
	"-": ["00000", "00000", "00000", "01110", "00000", "00000", "00000"],
	"–": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
}

## Width of `text` set `height` m tall (letters plus one-column gaps).
static func width(text: String, height: float) -> float:
	var cell := height / float(ROWS)
	return maxf(float(text.length()) * float(COLS + 1) - 1.0, 0.0) * cell

## The lit runs of `text` as [column0, column1 (exclusive), row] in cells,
## columns counted from the text's start, rows from the top.
static func runs(text: String) -> Array:
	var out: Array = []
	for i in text.length():
		var glyph: Array = GLYPHS.get(text[i].to_upper(), [])
		for row in glyph.size():
			var bits: String = glyph[row]
			var start := -1
			for col in COLS + 1:
				var lit := col < COLS and bits[col] == "1"
				if lit and start < 0:
					start = col
				elif not lit and start >= 0:
					out.append([i * (COLS + 1) + start, i * (COLS + 1) + col, row])
					start = -1
	return out

## Paints `text` `height` m tall on the hull sides, centred at `x_mid`
## with its middle at `y_mid` above the waterline; `sides` picks the
## sides (-1 port, 1 starboard). Returns the number of boxes laid.
static func on_hull(lm: LandmarkMesh, key: String, spec: Dictionary, text: String, x_mid: float,
		y_mid: float, height: float, sides: Array = [-1.0, 1.0]) -> int:
	var cell := height / float(ROWS)
	var half_w := width(text, height) * 0.5
	var count := 0
	for r in runs(text):
		var u0 := float(r[0]) * cell - half_w
		var u1 := float(r[1]) * cell - half_w
		var y := y_mid + height * 0.5 - (float(r[2]) + 0.5) * cell
		for side in sides:
			var s := float(side)
			# Starboard reads aft to bow (+X), port bow to aft.
			var xa := x_mid + u0 * s
			var xb := x_mid + u1 * s
			var x := (xa + xb) * 0.5
			var z := (HullLoft.side_z(spec, x, y) + 0.06) * s
			lm.box(key, Vector3(x, y, z), Vector3(absf(xb - xa), cell * 0.92, 0.05), Basis(), 0.0)
			count += 1
	return count

## Paints `text` on a flat wall facing +Z or -Z (`side`) at local
## (x_mid, y_mid, z): superstructure fronts and sides.
static func on_wall(lm: LandmarkMesh, key: String, text: String, x_mid: float, y_mid: float, z: float,
		height: float, side: float) -> int:
	var cell := height / float(ROWS)
	var half_w := width(text, height) * 0.5
	var count := 0
	for r in runs(text):
		var u0 := float(r[0]) * cell - half_w
		var u1 := float(r[1]) * cell - half_w
		var y := y_mid + height * 0.5 - (float(r[2]) + 0.5) * cell
		var x := x_mid + (u0 + u1) * 0.5 * signf(side)
		lm.box(key, Vector3(x, y, z + 0.03 * signf(side)), Vector3(u1 - u0, cell * 0.92, 0.05), Basis(), 0.0)
		count += 1
	return count
