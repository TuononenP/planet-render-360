class_name LandmarkGtCelsus
extends RefCounted

## The Library of Celsus at Ephesus in true metres, front to +Z, origin
## at the middle of the facade wall's foot (the stair runs out to +Z).

const CEL_COLS := [-10.2, -7.4, -4.6, -1.8, 1.8, 4.6, 7.4, 10.2]
const CEL_PY := 2.7
const CEL_LOW := 3.9
const CEL_LOW_H := 5.6
const CEL_ENT := 9.5
const CEL_UP := 11.4
const CEL_UP_H := 3.6
const CEL_UP_ENT := 15.0
const CEL_TOP := 17.0

## Library of Celsus (c. AD 117-120, facade re-erected 1970-78), 21 m
## wide and 17 m high: nine steps up to the podium; the lower storey's
## four aediculae, each a pair of Ionic-capitalled columns with honey
## Synnada marble shafts on a shared pedestal under a projecting
## entablature, with the statues of Sophia, Arete, Ennoia and Episteme
## in the niches behind them; the three doors between the pairs (the
## middle one the largest) in moulded frames; the upper storey's three
## Corinthian aediculae set over the doors (so the orders stagger) with
## the windows behind them, a triangular pediment in the middle and
## segmental ones either side, single columns at the ends; and the
## roofless 16.7 x 10.9 m reading hall behind with the apse of the
## statue of Athena.
static func celsus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DDD2B9", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B8AA8E", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#40382E", 3.0))
	lm.use("Statue", LandmarkMaterials.pbr("limestone", "#EFE8D8", 2.0))
	lm.use("Shaft", LandmarkMaterials.pbr("limestone", "#C9A878", 2.0))
	# Steps (nine, the top one the podium) and the hall floor.
	for k in 9:
		LandmarkGtUtil.block(lm, "Stone", -10.9, 10.9, 0.0, CEL_PY - 0.3 * float(k), 0.0, 2.6 + 0.42 * float(k))
	LandmarkGtUtil.block(lm, "Stone", -10.5, 10.5, 0.0, CEL_PY, -12.4, 0.0)
	_hall(lm)
	# Facade wall with its doors, windows and statue niches.
	var lower_niche := [-8.8, -3.2, 3.2, 8.8]
	var cuts: Array = [[0.0, CEL_PY, 2.6, 5.4], [-6.0, CEL_PY, 1.9, 4.4], [6.0, CEL_PY, 1.9, 4.4],
		[0.0, 11.5, 1.9, 2.8], [-6.0, 11.7, 1.5, 2.3], [6.0, 11.7, 1.5, 2.3]]
	for x in lower_niche:
		cuts.append([x, 4.2, 1.5, 3.4])
		cuts.append([x, 11.6, 1.1, 2.4])
	_wall_cut(lm, "Marble", -10.5, 10.5, CEL_PY, CEL_UP_ENT + 0.9, -1.0, 0.0, cuts)
	for c in cuts:
		var cx: float = c[0]
		var y0: float = c[1]
		var w: float = c[2]
		var h: float = c[3]
		var is_door := y0 <= CEL_PY + 0.01
		var is_niche := absf(absf(cx) - 3.2) < 0.01 or absf(absf(cx) - 8.8) < 0.01
		if is_niche:
			LandmarkGtUtil.block(lm, "Marble", cx - w * 0.5, cx + w * 0.5, y0, y0 + h, -1.0, -0.6)
			LandmarkGtUtil.block(lm, "Marble", cx - w * 0.5 - 0.1, cx + w * 0.5 + 0.1, y0 - 0.25, y0, -0.6, 0.15)
		_frame(lm, cx, y0, w, h, is_door)
	for x in lower_niche:
		LandmarkGtUtil.block(lm, "Marble", x - 0.45, x + 0.45, 4.2, 4.5, -0.6, -0.1)
		LandmarkKits.statue_figure(lm, "Statue", Vector3(x, 4.5, -0.33), 2.5)
	# Lower order: four paired aediculae.
	for p in 4:
		var xa: float = CEL_COLS[p * 2]
		var xb: float = CEL_COLS[p * 2 + 1]
		_pedestal(lm, xa - 0.7, xb + 0.7, CEL_PY, CEL_LOW, 0.4, 2.5)
		for x in [xa, xb]:
			_column(lm, Vector3(float(x), CEL_LOW, 1.5), 0.36, CEL_LOW_H, "ionic")
		_entablature(lm, xa - 0.75, xb + 0.75, CEL_ENT, 1.3, -0.05, 2.35, true)
	_entablature(lm, -10.6, 10.6, CEL_ENT, 1.3, -0.05, 0.5, false)
	# Upper order: aediculae over the doors, single columns at the ends.
	var groups := [[CEL_COLS[0]], [CEL_COLS[1], CEL_COLS[2]], [CEL_COLS[3], CEL_COLS[4]], [CEL_COLS[5], CEL_COLS[6]],
		[CEL_COLS[7]]]
	for g in groups:
		var xs: Array = g
		var x0: float = float(xs[0]) - 0.6
		var x1: float = float(xs[xs.size() - 1]) + 0.6
		_pedestal(lm, x0, x1, CEL_ENT + 1.3, CEL_UP, 0.5, 2.2)
		for x in xs:
			_column(lm, Vector3(float(x), CEL_UP, 1.3), 0.28, CEL_UP_H, "corinthian")
		_entablature(lm, x0 - 0.05, x1 + 0.05, CEL_UP_ENT, 0.9, -0.05, 2.0, true)
	_entablature(lm, -10.6, 10.6, CEL_UP_ENT, 0.9, -0.05, 0.4, false)
	# Pediments: triangular over the middle aedicula, segmental beside it.
	var py := CEL_UP_ENT + 0.9
	LandmarkGtUtil.pediment(lm, "Marble", "Marble", Vector3(0, py, 2.05), Vector3.BACK, 5.0, CEL_TOP - py, 2.1)
	LandmarkDetail.cornice(lm, "Marble", Vector3(-2.5, py, 2.05), Vector3(2.5, py, 2.05), Vector3.BACK, 0.18, false)
	for sx in [-1.0, 1.0]:
		_segmental(lm, Vector3(sx * 6.0, py, 2.05), 4.4, 0.8, 2.1)
	lm.commit(model)

## Wall slab between the extents (front face at z1) with rectangular
## openings `cuts` ([centre x, bottom y, w, h]) passing right through:
## built strip by strip between the openings' edges.
static func _wall_cut(lm: LandmarkMesh, key: String, x0: float, x1: float, y0: float, y1: float, z0: float,
		z1: float, cuts: Array) -> void:
	var xs: Array[float] = [x0, x1]
	for c in cuts:
		xs.append(float(c[0]) - float(c[2]) * 0.5)
		xs.append(float(c[0]) + float(c[2]) * 0.5)
	xs.sort()
	for i in xs.size() - 1:
		var a := xs[i]
		var b := xs[i + 1]
		if b - a < 0.01:
			continue
		var m := (a + b) * 0.5
		var spans: Array = []
		for c in cuts:
			if absf(m - float(c[0])) < float(c[2]) * 0.5:
				spans.append([float(c[1]), float(c[1]) + float(c[3])])
		spans.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
		var y := y0
		for sp in spans:
			if float(sp[0]) > y + 0.01:
				LandmarkGtUtil.block(lm, key, a, b, y, float(sp[0]), z0, z1)
			y = maxf(y, float(sp[1]))
		if y1 > y + 0.01:
			LandmarkGtUtil.block(lm, key, a, b, y, y1, z0, z1)

## Moulded frame round an opening on the facade: jambs and lintel band
## proud of the wall, with a cornice head over the doors.
static func _frame(lm: LandmarkMesh, cx: float, y0: float, w: float, h: float, door: bool) -> void:
	var fw := 0.28 if door else 0.18
	for s in [-1.0, 1.0]:
		var x: float = cx + float(s) * (w * 0.5 + fw * 0.5)
		LandmarkGtUtil.block(lm, "Marble", x - fw * 0.5, x + fw * 0.5, y0, y0 + h + fw, 0.0, 0.14)
	LandmarkGtUtil.block(lm, "Marble", cx - w * 0.5 - fw, cx + w * 0.5 + fw, y0 + h, y0 + h + fw, 0.0, 0.14)
	if door:
		LandmarkGtUtil.block(lm, "Marble", cx - w * 0.5 - fw, cx + w * 0.5 + fw, y0 + h + fw, y0 + h + fw + 0.45, 0.0, 0.1)
		LandmarkDetail.cornice(lm, "Marble", Vector3(cx - w * 0.5 - fw - 0.1, y0 + h + fw + 0.45, 0.1),
			Vector3(cx + w * 0.5 + fw + 0.1, y0 + h + fw + 0.45, 0.1), Vector3.BACK, 0.3, true)
	else:
		LandmarkGtUtil.block(lm, "Marble", cx - w * 0.5 - fw, cx + w * 0.5 + fw, y0 - 0.12, y0, 0.0, 0.2)

## Pedestal (plinth, die, cap mouldings) from x0 to x1, y0..y1, standing
## out from the wall face (z 0) to z1, front at z = z1.
static func _pedestal(lm: LandmarkMesh, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> void:
	var h := y1 - y0
	LandmarkGtUtil.block(lm, "Marble", x0 - 0.08, x1 + 0.08, y0, y0 + h * 0.15, z0 - 0.1, z1 + 0.08)
	LandmarkGtUtil.block(lm, "Marble", x0, x1, y0 + h * 0.15, y1 - h * 0.15, 0.0, z1)
	LandmarkGtUtil.block(lm, "Marble", x0 - 0.06, x1 + 0.06, y1 - h * 0.15, y1, -0.05, z1 + 0.06)
	LandmarkGtUtil.block(lm, "Marble", x0 + 0.15, x1 - 0.15, y0 + h * 0.3, y1 - h * 0.3, z1, z1 + 0.04)

## Column of height h, lower radius r, at `base`: the LandmarkDetail
## order with the honey-coloured Synnada shaft laid over its marble.
static func _column(lm: LandmarkMesh, base: Vector3, r: float, h: float, order: String) -> void:
	LandmarkDetail.column(lm, "Marble", base, r, h, order, 0)
	var cap_h := r * (1.4 if order == "ionic" else 2.4)
	var bh := r * 0.9
	var sh := h - cap_h - bh
	lm.lathe("Shaft", base + Vector3(0, bh, 0), PackedVector2Array([Vector2(r * 1.01, 0), Vector2(r * 1.0, sh * 0.33),
		Vector2(r * 0.94, sh * 0.7), Vector2(r * 0.84, sh * 0.98)]), 20, 1.0, 1.0, 0.0, true, false)

## Entablature x0..x1 at y (h tall), z0..z1, front at z1: three-fascia
## architrave, frieze, and a dentilled cornice along the front (and
## the returns at both ends when `returns`).
static func _entablature(lm: LandmarkMesh, x0: float, x1: float, y: float, h: float, z0: float, z1: float,
		returns: bool) -> void:
	var ah := h * 0.45
	for f in 3:
		var o := 0.04 * float(f)
		LandmarkGtUtil.block(lm, "Marble", x0 - o, x1 + o, y + ah * float(f) / 3.0, y + ah * float(f + 1) / 3.0, z0, z1 + o)
	LandmarkGtUtil.block(lm, "Marble", x0, x1, y + ah, y + h * 0.75, z0, z1 - 0.02)
	LandmarkGtUtil.block(lm, "Marble", x0 + 0.1, x1 - 0.1, y + ah + 0.05, y + h * 0.75 - 0.05, z1 - 0.02, z1 + 0.03)
	var cy := y + h * 0.75
	LandmarkDetail.cornice(lm, "Marble", Vector3(x0 - 0.05, cy, z1), Vector3(x1 + 0.05, cy, z1), Vector3.BACK, h * 0.25, true)
	if returns:
		LandmarkDetail.cornice(lm, "Marble", Vector3(x0, cy, z0), Vector3(x0, cy, z1), Vector3.LEFT, h * 0.25, false)
		LandmarkDetail.cornice(lm, "Marble", Vector3(x1, cy, z1), Vector3(x1, cy, z0), Vector3.RIGHT, h * 0.25, false)
	LandmarkGtUtil.block(lm, "Marble", x0, x1, cy, cy + h * 0.25, z0, z1)

## Segmental pediment centred at `c` (middle of its base, front face):
## an arc of `rise` over a chord `w`, the raking cornice as voussoir-like
## blocks and the tympanum fan behind, `d` deep.
static func _segmental(lm: LandmarkMesh, c: Vector3, w: float, rise: float, d: float) -> void:
	var half := w * 0.5
	var rad := (half * half + rise * rise) / (2.0 * rise)
	var ctr := c + Vector3(0, rise - rad, 0)
	var a0 := asin(half / rad)
	var n := 12
	var prev := c + Vector3(-half, 0, 0)
	for i in n:
		var t := -a0 + 2.0 * a0 * float(i + 1) / float(n)
		var p := ctr + Vector3(sin(t) * rad, cos(t) * rad, 0)
		var mid := (prev + p) * 0.5
		var tng := (p - prev).normalized()
		lm.box("Marble", mid + (mid - ctr).normalized() * 0.12 - Vector3(0, 0, d * 0.5), Vector3(prev.distance_to(p) + 0.04,
			0.3, d + 0.1), Basis(tng, Vector3.BACK.cross(tng).normalized() * -1.0, Vector3.BACK))
		lm.tri("Marble", c, prev, p, Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2.ZERO,
			Vector2(prev.x - c.x, -(prev.y - c.y)), Vector2(p.x - c.x, -(p.y - c.y)))
		prev = p

## The roofless reading hall: its double side and back walls standing
## to ragged heights, the apse in the back wall, the niche rows.
static func _hall(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		for k in 6:
			var z0 := -12.4 + 2.07 * float(k)
			var h := 4.5 + 3.5 * LandmarkGtUtil.hash01(k, 7 + int(sx))
			LandmarkGtUtil.block(lm, "Stone", sx * 10.5 - 0.55, sx * 10.5 + 0.55, CEL_PY, CEL_PY + h, z0, z0 + 2.07 - 0.02)
			LandmarkGtUtil.block(lm, "Stone", sx * 8.6 - 0.4, sx * 8.6 + 0.4, CEL_PY, CEL_PY + h * 0.8, z0, z0 + 2.07 - 0.02)
	for k in 8:
		var x0 := -10.0 + 2.5 * float(k)
		if x0 > -2.6 and x0 < 2.4:
			continue
		var h2 := 5.0 + 3.0 * LandmarkGtUtil.hash01(k, 13)
		LandmarkGtUtil.block(lm, "Stone", x0, x0 + 2.48, CEL_PY, CEL_PY + h2, -12.4, -11.3)
	# Apse: a half ring of wall round the statue podium.
	for k in 9:
		var a := PI * float(k) / 9.0
		var b := PI * float(k + 1) / 9.0
		var m := (a + b) * 0.5
		var d := Vector3(cos(m), 0, -sin(m))
		lm.box("Stone", Vector3(0, CEL_PY + 3.4, -11.3) + d * 2.9, Vector3(2.9 * (b - a) + 0.05, 6.8, 0.9),
			Basis(Vector3.UP, m + PI * 0.5))
	LandmarkGtUtil.block(lm, "Marble", -1.6, 1.6, CEL_PY, CEL_PY + 1.2, -13.6, -11.3)
	for sx2 in [-1.0, 1.0]:
		for k2 in 3:
			LandmarkGtUtil.block(lm, "Dark", sx2 * 8.15 - 0.05, sx2 * 8.15 + 0.05, CEL_PY + 1.2, CEL_PY + 3.7,
				-9.5 + 3.2 * float(k2), -8.4 + 3.2 * float(k2))
