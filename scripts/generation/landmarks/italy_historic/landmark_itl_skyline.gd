class_name LandmarkItlSkyline
extends RefCounted

## San Gimignano's tower skyline and the Two Towers of Bologna in true
## metres: slender medieval tower-houses of stone and brick, their
## crowns corbelled and battlemented, the Bologna pair leaning.

# --- San Gimignano --------------------------------------------------------

## [x east, z south (metres from the Torre Grossa), half-width, height,
## footprint angle cw from east in degrees, battlemented]. Positions of
## the Salvucci and Ardinghelli pairs from OpenStreetMap; both pairs were
## cut down to about half of their 13th-century ~52 m.
const SG_TOWERS := [
	[0.0, 0.0, 4.5, 54.0, 7.0, true],       # Torre Grossa (Palazzo Comunale)
	[47.7, -24.3, 2.3, 51.0, 67.0, true],   # Torre Rognosa (Podesta)
	[41.2, -36.4, 2.6, 47.0, 150.0, false], # Torre Chigi
	[28.3, -59.7, 2.7, 38.0, 153.0, false], # Torre Pettini
	[82.4, 5.5, 3.4, 36.0, 179.0, false],   # Torre del Diavolo
	[4.8, 64.2, 3.5, 40.0, 109.0, false],   # Torre dei Cugnanesi
	[7.0, 95.1, 3.3, 28.0, 112.0, false],   # Torre Campatelli (28 m)
	[17.0, -49.6, 2.9, 31.0, 160.0, false], # Salvucci, the taller
	[23.2, -53.6, 2.7, 27.0, 160.0, false], # Salvucci, the shorter
	[35.6, 15.8, 2.8, 26.0, 20.0, false],   # Ardinghelli, west
	[41.0, 18.8, 2.6, 24.0, 20.0, false],   # Ardinghelli, east
]

## Origin at the foot of the Torre Grossa in the true compass frame
## (+X east, -Z north): the 54 m Grossa on the Palazzo Comunale, the
## Podesta palace with the 51 m Rognosa and its loggia, the Romanesque
## Collegiata on its steps and the surrounding tower-houses (the twin
## Salvucci and Ardinghelli pairs among them), each a square shaft of
## weathered stone with putlog holes, arched lower storeys under brick
## archivolts, slits and paired windows, and a corbelled top or merlons.
## The octagonal well of 1273 stands in the Piazza della Cisterna.
static func san_gimignano(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B09A74", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CDBE9C", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#40382E", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A9573B", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9E5638", 2.5))
	for t in SG_TOWERS:
		_tower(lm, Vector3(t[0], 0, t[1]), t[2], t[3], -deg_to_rad(t[4]), t[5])
	_palaces(lm)
	_collegiata(lm, Vector3(-27.5, 0, -27.6), deg_to_rad(72.0))
	_well(lm, Vector3(58.0, 0, 26.0))
	lm.commit(model)

## The Palazzo Comunale at the foot of the Grossa and the Podesta palace
## with its loggia.
static func _palaces(lm: LandmarkMesh) -> void:
	var rc := -deg_to_rad(7.0)
	var bc := Basis(Vector3.UP, rc)
	lm.box("Stone", Vector3(-3.0, 12.5, 14.0), Vector3(30.0, 25.0, 14.0), bc)
	for sgn in [-1.0, 1.0]:
		var out: Vector3 = bc * Vector3(0, 0, sgn)
		var base := Vector3(-3.0, 0, 14.0) + out * 7.0
		var right: Vector3 = bc * Vector3.RIGHT
		for i in 4:
			var s := (float(i) - 1.5) * 6.5
			for y in [9.0, 17.0]:
				LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", base + right * s + Vector3(0, float(y), 0), out, 1.8,
					3.8, 2, false, 0.22)
		for i in 3:
			var s := (float(i) - 1.0) * 8.0
			LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", base + right * s + Vector3(0, 0.2, 0), out, 3.2, 5.0, 1,
				false, 0.3, 0.4)
		LandmarkItlParts.arch_frieze(lm, "Stone", base - right * 15.8 + Vector3(0, 25.0, 0) + out * 0.8,
			base + right * 15.8 + Vector3(0, 25.0, 0) + out * 0.8, out, 1.7, 1.2)
		lm.box("Trim", base + out * 0.15 + Vector3(0, 7.8, 0), Vector3(30.4, 0.4, 0.4), bc)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", Vector3(-3.0, 25.0, 14.0), 15.0, 7.0, rc, 0.8, 1.2, 1.8, false, 1.4)
	var rp := -deg_to_rad(76.0)
	var bp := Basis(Vector3.UP, rp)
	var pc := Vector3(52.5, 0, -21.0)
	lm.box("Stone", pc + Vector3(0, 8.5, 0), Vector3(20.0, 17.0, 18.0), bp)
	var pf := pc + bp * Vector3(0, 0, 9.0)
	var pout: Vector3 = bp * Vector3(0, 0, 1)
	var pr: Vector3 = bp * Vector3.RIGHT
	# Loggia of the Podesta: a great round arch on the piazza.
	LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", pf - pr * 3.0 + Vector3(0, 0.2, 0), pout, 8.0, 9.5, 1, false,
		0.5, 0.6)
	for i in 3:
		LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", pf + pr * (-6.0 + 5.8 * float(i)) + Vector3(0, 11.0, 0), pout,
			1.6, 3.4, 2, false, 0.2)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", pc + Vector3(0, 17.0, 0), 10.0, 9.0, rp, 0.6, 1.0, 1.5, false, 1.3)

## One tower-house: stone shaft with putlog holes, arched lower storeys
## under brick archivolts, slits, paired windows near the top, and a
## battlemented crown or a corbelled slab.
static func _tower(lm: LandmarkMesh, c: Vector3, hw: float, h: float, rot: float, merlons: bool) -> void:
	var rows := []
	var y := 14.0
	while y < h - 9.0:
		rows.append([y, 0.55, 1.9, 1, 0.0, false])
		y += 7.5
	rows.append([h - 10.0, 0.9, 2.8, 2, hw * 0.9, false])
	var base_y := h - 3.2 if merlons else h - 1.4
	var hw1 := hw * 0.93
	LandmarkItlUtil.tower(lm, "Stone", "Shadow", c, hw, c + Vector3(0, base_y, 0), hw1, rot, rows)
	for k in 4:
		var b := Basis(Vector3.UP, rot + PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		var lift := 10.0
		# Putlog holes (the face draws in slightly; holes sit on it).
		while lift < base_y - 4.0:
			var ww := lerpf(hw, hw1, (lift + 4.5) / base_y)
			LandmarkItlParts.putlogs(lm, "Shadow", c + n * (ww + 0.01) - r * ww + Vector3(0, lift, 0), r, n, ww * 2.0,
				0.0, minf(9.0, base_y - 4.0 - lift), 1.5, 2.6, 0.2)
			lift += 10.0
		# Ground and first-floor arches with brick archivolts, two faces.
		if k < 2:
			LandmarkItlParts.gothic_window(lm, "Brick", "Shadow", c + n * hw + Vector3(0, 0.1, 0), n, hw * 1.0, 3.8, 1,
				k == 0, 0.25, 0.35)
			LandmarkItlParts.gothic_window(lm, "Brick", "Shadow", c + n * hw * 0.99 + Vector3(0, 5.6, 0), n, hw * 0.75,
				3.4, 1, false, 0.2, 0.3)
		lm.box("Trim", c + n * (lerpf(hw, hw1, 9.6 / base_y) + 0.05) + Vector3(0, 9.6, 0), Vector3(hw * 2.0 + 0.2, 0.3, 0.3),
			b, 0.0)
	if merlons:
		LandmarkItlUtil.gallery(lm, "Stone", "Shadow", c + Vector3(0, base_y, 0), hw1, hw1, rot, 0.7, 1.4, 1.5, false, 1.1)
	else:
		var bb := Basis(Vector3.UP, rot)
		lm.box("Trim", c + Vector3(0, h - 1.2, 0), Vector3(hw1 * 2.0 + 0.6, 0.4, hw1 * 2.0 + 0.6), bb)
		lm.box("Trim", c + Vector3(0, h - 0.4, 0), Vector3(hw1 * 2.0 + 1.0, 0.8, hw1 * 2.0 + 1.0), bb)
		for k in 4:
			var b := Basis(Vector3.UP, rot + PI * 0.5 * float(k))
			var n := b * Vector3(0, 0, 1)
			var r := b * Vector3(1, 0, 0)
			var cnt := maxi(int(hw1 * 2.0 / 1.0), 3)
			for i in cnt:
				var s := (float(i) + 0.5) / float(cnt) * hw1 * 2.0 - hw1
				lm.box("Trim", c + n * (hw1 + 0.15) + r * s + Vector3(0, h - 1.75, 0), Vector3(0.35, 0.7, 0.3), b, 0.0)

## The Collegiata: plain Romanesque basilica on its steps, facade turned
## to the piazza (local +Z) with its two doors, nave and aisles under
## tiled roofs, clerestory windows, a round apse behind.
static func _collegiata(lm: LandmarkMesh, c: Vector3, rot: float) -> void:
	var b := Basis(Vector3.UP, rot)
	var fwd := b * Vector3(0, 0, 1)
	var right := b * Vector3.RIGHT
	lm.box("Trim", c + b * Vector3(0, 8.5, 0), Vector3(9.0, 17.0, 40.0), b)
	lm.gable("Tile", c + b * Vector3(0, 17.0, 0), 9.0, 40.0, 3.0, b, 0.5, "Trim")
	for s in [-1.0, 1.0]:
		lm.box("Trim", c + b * Vector3(float(s) * 6.25, 5.5, 0), Vector3(5.5, 11.0, 40.0), b)
		lm.gable("Tile", c + b * Vector3(float(s) * 6.25, 11.0, 0), 5.5, 40.0, 1.4, b, 0.3, "Trim")
	lm.frustum("Trim", c + b * Vector3(0, 0, -20.0), 6.5, 6.5, 14.0, 16)
	lm.spire("Tile", c + b * Vector3(0, 14.0, -20.0), 6.6, 3.0, 0.0, 16)
	SEuUtil.steps_up(lm, "Trim", c + fwd * 20.0, fwd, 14.0, 0.9, 0.5, 7)
	for s in [-1.0, 1.0]:
		LandmarkItlParts.gothic_window(lm, "Stone", "Shadow", c + fwd * 20.0 + right * float(s) * 3.6 + Vector3(0, 3.5, 0),
			fwd, 2.4, 4.6, 1, false, 0.3, 0.35)
		var side := b * Vector3(float(s), 0, 0)
		for i in 7:
			var z := -16.0 + 5.3 * float(i)
			LandmarkItlParts.gothic_window(lm, "Stone", "Shadow", c + b * Vector3(float(s) * 4.5, 12.2, z), side, 1.0, 2.8,
				1, false, 0.15)
			LandmarkItlParts.gothic_window(lm, "Stone", "Shadow", c + b * Vector3(float(s) * 9.0, 5.0, z), side, 1.0, 3.0,
				1, false, 0.15)
	lm.disc("Shadow", c + fwd * 20.06 + Vector3(0, 13.0, 0), fwd, 1.1, 16)
	lm.disc("Stone", c + fwd * 20.03 + Vector3(0, 13.0, 0), fwd, 1.4, 16)
	LandmarkItlParts.arch_frieze(lm, "Trim", c + fwd * 20.0 - right * 4.5 + Vector3(0, 16.8, 0),
		c + fwd * 20.0 + right * 4.5 + Vector3(0, 16.8, 0), fwd, 1.1, 0.6)

## The 1273 well: an octagonal travertine basin on steps, two columns
## carrying the winch beam.
static func _well(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Trim", c, 3.6, 3.6, 0.3, 8, PI / 8.0)
	lm.frustum("Trim", c + Vector3(0, 0.3, 0), 3.1, 3.1, 0.3, 8, PI / 8.0)
	lm.frustum("Stone", c + Vector3(0, 0.6, 0), 2.4, 2.4, 1.0, 8, PI / 8.0)
	lm.frustum("Trim", c + Vector3(0, 1.6, 0), 2.55, 2.55, 0.2, 8, PI / 8.0)
	lm.frustum("Shadow", c + Vector3(0, 1.0, 0), 2.0, 2.0, 0.62, 8, PI / 8.0)
	for s in [-1.0, 1.0]:
		LandmarkItlParts.column(lm, "Trim", c + Vector3(float(s) * 1.9, 1.8, 0), 0.22, 3.2, 8)
	lm.box("Trim", c + Vector3(0, 5.15, 0), Vector3(4.6, 0.5, 0.6))
	lm.beam("Shadow", c + Vector3(-1.6, 4.6, 0), c + Vector3(1.6, 4.6, 0), 0.2, 0.2)

# --- Bologna --------------------------------------------------------------

const ASINELLI_H := 97.2
const GARISENDA_H := 47.5

## Origin at the Asinelli in the true compass frame (+X east, -Z north):
## the 97.2 m Asinelli, a brick shaft drawing in at two setbacks, leaning
## 2.23 m west, wrapped at its foot by the 1488 rocchetta (arcaded,
## battlemented), topped by an overhanging corbelled crown and a small
## brick cell under a low pyramid; 18 m to the north the 48 m Garisenda,
## stouter, leaning 3.2 m (4 degrees), its foot cased in selenite blocks
## and its top cut off at the corbel crown. Both shafts pocked with
## putlog holes.
static func bologna(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A4533A", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBD9F", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C3229", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9C4E36", 2.0))
	var arot := -deg_to_rad(21.0)
	var alean := Vector2(-2.23, 0.0)
	_leaning_tower(lm, Vector3.ZERO, arot, alean, ASINELLI_H, 4.2, [[0.0, 4.2], [30.0, 3.95], [30.0, 3.85],
		[60.0, 3.6], [60.0, 3.5], [88.0, 3.3]], [14.0, 26.0, 38.0, 50.0, 62.0, 72.0], 88.0, 1.6, 1.5)
	_rocchetta(lm, arot)
	var grot := -deg_to_rad(1.0)
	var glean := Vector2(3.0, -1.1)
	_leaning_tower(lm, Vector3(1.0, 0, -17.9), grot, glean, GARISENDA_H, 4.3, [[0.0, 4.3], [44.7, 3.9]],
		[14.0, 22.0, 30.0, 38.0], 44.7, 1.1, 1.1)
	_selenite(lm, Vector3(1.0, 0, -17.9), grot, glean / GARISENDA_H, 4.3, 3.9, 44.7, 8.6)
	# Asinelli's crown cell and cap sit inside the merlons.
	var lean := alean / ASINELLI_H
	var top := Vector3(lean.x * 91.0, 91.0, lean.y * 91.0)
	LandmarkItlUtil.tower(lm, "Brick", "Shadow", top, 2.6, top + Vector3(lean.x * 4.0, 4.0, lean.y * 4.0), 2.6, arot,
		[[92.8, 0.9, 1.8, 2, 2.2, false]])
	var cap := Vector3(lean.x * 95.0, 95.0, lean.y * 95.0)
	lm.box("Stone", cap + Vector3(0, 0.15, 0), Vector3(6.0, 0.3, 6.0), Basis(Vector3.UP, arot))
	lm.spire("Roof", cap + Vector3(0, 0.3, 0), 3.0, 1.9)
	lm.commit(model)

## A leaning tower: brick shaft in segments `prof` ([y, half-width] pairs;
## a repeated y is a setback with a stone band), slit rows, then the
## corbelled gallery with `mer_h` merlons at `crown_y`. `lean` is the
## horizontal offset of the top over the full height `h`.
static func _leaning_tower(lm: LandmarkMesh, c: Vector3, rot: float, lean: Vector2, h: float, base_hw: float,
		prof: Array, slit_ys: Array, crown_y: float, mer_h: float, proj: float) -> void:
	var k := lean / h
	var at := func(y: float) -> Vector3:
		return c + Vector3(k.x * y, y, k.y * y)
	var rows := []
	for y in slit_ys:
		rows.append([y, 0.7, 2.4, 1, 0.0, false])
	rows.append([crown_y - 8.0, 0.9, 2.6, 2, 1.6, false])
	for i in prof.size() - 1:
		var y0: float = prof[i][0]
		var y1: float = prof[i + 1][0]
		var w0: float = prof[i][1]
		var w1: float = prof[i + 1][1]
		if y1 - y0 < 0.01:
			lm.box("Stone", at.call(y0) + Vector3(0, 0.25, 0), Vector3(w0 * 2.0 + 0.2, 0.5, w0 * 2.0 + 0.2),
				Basis(Vector3.UP, rot), 0.0)
			continue
		var seg_rows := []
		for r in rows:
			if float(r[0]) >= y0 and float(r[0]) + float(r[2]) <= y1:
				seg_rows.append(r)
		LandmarkItlUtil.tower(lm, "Brick", "Shadow", at.call(y0), w0, at.call(y1), w1, rot, seg_rows)
		for q in 4:
			var b := Basis(Vector3.UP, rot + PI * 0.5 * float(q))
			var n := b * Vector3(0, 0, 1)
			var r := b * Vector3(1, 0, 0)
			var y := y0 + 4.0
			while y < y1 - 2.0:
				var t := (y - y0) / (y1 - y0)
				var ww := lerpf(w0, w1, t)
				LandmarkItlParts.putlogs(lm, "Shadow", at.call(y) + n * (ww + 0.01) - r * ww, r, n, ww * 2.0, 0.0,
					minf(9.0, y1 - 2.0 - y), 1.6, 3.0, 0.24)
				y += 10.0
	# Door at the foot.
	LandmarkItlParts.gothic_window(lm, "Stone", "Shadow", at.call(0.0) + Basis(Vector3.UP, rot) * Vector3(0, 0, base_hw),
		Basis(Vector3.UP, rot) * Vector3(0, 0, 1), 1.6, 3.2, 1, false, 0.25, 0.3)
	var top_hw: float = prof[prof.size() - 1][1]
	for q in 4:
		var b := Basis(Vector3.UP, rot + PI * 0.5 * float(q))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		var o: Vector3 = at.call(crown_y) + n * (top_hw + proj)
		LandmarkItlParts.arch_frieze(lm, "Brick", o - r * (top_hw + proj), o + r * (top_hw + proj), n, 1.3, 2.2)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", at.call(crown_y), top_hw, top_hw, rot, proj, 2.4, mer_h, false, 1.2)

## The rocchetta (1488) round the Asinelli's foot: a battlemented stone
## block with an arcade of shops on the street fronts.
static func _rocchetta(lm: LandmarkMesh, rot: float) -> void:
	var b := Basis(Vector3.UP, rot)
	var hx := 6.6
	var hz := 6.2
	lm.box("Stone", Vector3(0, 3.6, 0), Vector3(hx * 2.0, 7.2, hz * 2.0), b)
	for q in 4:
		var bq := Basis(Vector3.UP, rot + PI * 0.5 * float(q))
		var n := bq * Vector3(0, 0, 1)
		var r := bq * Vector3(1, 0, 0)
		var d := hz if q % 2 == 0 else hx
		var w := hx if q % 2 == 0 else hz
		var cnt := 3 if q < 2 else 2
		for i in cnt:
			var s := (float(i) - float(cnt - 1) * 0.5) * (w * 2.0 / float(cnt))
			LandmarkItlParts.gothic_window(lm, "Stone", "Shadow", n * d + r * s + Vector3(0, 0.2, 0), n,
				w * 2.0 / float(cnt) * 0.6, 4.8, 1, false, 0.3, 0.35)
		LandmarkItlParts.arch_frieze(lm, "Stone", n * (d + 0.3) - r * w + Vector3(0, 7.2, 0),
			n * (d + 0.3) + r * w + Vector3(0, 7.2, 0), n, 1.3, 0.8)
	LandmarkItlUtil.crown(lm, "Stone", Vector3(0, 7.2, 0), hx - 0.25, hz - 0.25, rot, 0.9, 1.8, 1.2, 0.5, false)

## Selenite casing of the Garisenda's foot: bossed blocks in staggered
## courses on all four faces up to `top_y`.
static func _selenite(lm: LandmarkMesh, c: Vector3, rot: float, k: Vector2, hw0: float, hw1: float, h: float,
		top_y: float) -> void:
	for q in 4:
		var b := Basis(Vector3.UP, rot + PI * 0.5 * float(q))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		var y := 0.0
		var row := 0
		while y < top_y:
			var ww := lerpf(hw0, hw1, (y + 0.3) / h)
			var p := c + Vector3(k.x * (y + 0.3), y + 0.3, k.y * (y + 0.3)) + n * (ww + 0.1)
			var off := 0.0 if row % 2 == 0 else 0.6
			var cnt := int((ww * 2.0 - off) / 1.2)
			for i in cnt:
				var s := -ww + off + 1.2 * (float(i) + 0.5)
				lm.box("Stone", p + r * s, Vector3(1.1, 0.55, 0.2), b, 0.0)
			y += 0.6
			row += 1
