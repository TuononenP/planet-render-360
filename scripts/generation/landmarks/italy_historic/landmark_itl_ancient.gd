class_name LandmarkItlAncient
extends RefCounted

## The Forum of Pompeii in true metres: the 143 x 38 m paved square of
## the Roman town as the excavations left it, with the ruined public
## buildings round it.

const G := 0.3
const COL_X := 17.2
const COL_Z0 := -44.0
const COL_Z1 := 66.0

## Origin at the middle of the forum, the Temple of Jupiter at the north
## (-Z) head facing the square (+Z), +X east. The travertine-paved square
## between the Doric colonnades of the west, east and south sides (lower
## order ~5 m, a stretch of the upper Ionic order still standing at the
## south-west, gaps where columns fell), statue bases and the speaker's
## platform; the temple podium (3 m) with its stair, cella walls and
## broken Corinthian columns, the two brick honorific arches flanking it
## (the tallest remains, 10.6 m). West: the Basilica (55 x 24 m, 28
## brick columns, the tribunal), the Temple of Apollo in its porticoed
## court, the granary and the weights table. East: the Macellum with the
## bases of its tholos, the Sanctuary of the Lares, the Temple of
## Vespasian, the Building of Eumachia, the Comitium. South: the three
## apsed municipal halls.
static func pompeii_forum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pave", LandmarkMaterials.pbr("limestone", "#BDB5A3", 4.0))
	lm.use("Col", LandmarkMaterials.pbr("limestone", "#CFC3A8", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9B5A3C", 2.5))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#B98B5E", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#463C32", 3.0))
	lm.box("Pave", Vector3(-8.0, G * 0.5, 5.0), Vector3(136.0, G, 170.0), Basis(), 0.0)
	_colonnades(lm)
	_temple(lm)
	_basilica(lm, Vector3(-48.5, G, 52.0))
	_apollo(lm, Vector3(-40.5, G, -23.0))
	_east(lm)
	lm.commit(model)

## A ruined wall from a to b (on the pavement): pieces ~2.4 m long of
## broken height between h*0.4 and h, a doorway gap every few pieces.
static func _wall(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, t: float, seed_v: float,
		doors: int = 4) -> void:
	var d := b - a
	var n := maxi(int(round(d.length() / 2.4)), 1)
	var basis := Basis(d.normalized(), Vector3.UP, d.normalized().cross(Vector3.UP))
	var step := d.length() / float(n)
	for i in n:
		if doors > 0 and i % doors == doors / 2 and n > 3:
			continue
		var hh := h * (0.4 + 0.6 * absf(sin(float(i) * 1.37 + seed_v * 2.1)))
		var p := a + d.normalized() * step * (float(i) + 0.5)
		lm.box(key, p + Vector3(0, hh * 0.5, 0), Vector3(step * 1.01, hh, t), basis)
		# Ragged top course, set back.
		if hh > 2.0:
			var h2 := hh * 0.12 * (1.0 + sin(float(i) * 3.1 + seed_v))
			lm.box(key, p + Vector3(0, hh + h2 * 0.5, 0) + d.normalized() * step * 0.2, Vector3(step * 0.55, h2, t * 0.8),
				basis, 0.0)

## A rectangle of ruined walls (centre c, w along X, d along Z).
static func _ring(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, h: float, t: float, seed_v: float) -> void:
	var hx := w * 0.5
	var hz := d * 0.5
	var pts := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for i in 4:
		_wall(lm, key, c + (pts[i] as Vector3), c + (pts[(i + 1) % 4] as Vector3), h, t, seed_v + float(i))

## Doric colonnades on three sides, broken architraves, upper Ionic stretch.
static func _colonnades(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var x: float = s * COL_X
		for i in 37:
			if (i + (3 if s > 0.0 else 0)) % 9 == 5:
				continue
			var z := COL_Z0 + (COL_Z1 - COL_Z0) * float(i) / 36.0
			var hh := 4.8 if (i * 7 + int(s * 3.0)) % 11 != 2 else 2.4
			LandmarkDetail.column(lm, "Col", Vector3(x, G, z), 0.42, hh, "doric", 0)
		for i in 36:
			if i % 7 != 3 and i % 9 != 5:
				var z0 := COL_Z0 + (COL_Z1 - COL_Z0) * float(i) / 36.0
				lm.box("Col", Vector3(x, G + 5.2, z0 + 1.53), Vector3(0.9, 0.8, 110.0 / 36.0 - 0.05))
		# Back wall of the portico (ruined) and stylobate step.
		_wall(lm, "Stucco", Vector3(s * 21.0, G, COL_Z0 - 2.0), Vector3(s * 21.0, G, COL_Z1 + 2.0), 4.5, 0.7, 1.0 + s, 5)
		lm.box("Col", Vector3(x, G + 0.12, (COL_Z0 + COL_Z1) * 0.5), Vector3(1.6, 0.24, COL_Z1 - COL_Z0 + 2.0))
	for i in 13:
		var x := -COL_X + 2.0 * COL_X * float(i) / 12.0
		LandmarkDetail.column(lm, "Col", Vector3(x, G, COL_Z1), 0.42, 4.8, "doric", 0)
	for i in 12:
		var x0 := -COL_X + 2.0 * COL_X * float(i) / 12.0
		if i % 5 != 2:
			lm.box("Col", Vector3(x0 + COL_X / 12.0, G + 5.2, COL_Z1), Vector3(2.0 * COL_X / 12.0 - 0.05, 0.8, 0.9))
	# Upper order surviving at the south-west: Ionic columns on the gallery.
	for i in 6:
		var z := COL_Z1 - (COL_Z1 - COL_Z0) * float(i) / 36.0
		LandmarkDetail.column(lm, "Col", Vector3(-COL_X, G + 5.6, z), 0.3, 3.6, "ionic", 0)
	lm.box("Col", Vector3(-COL_X, G + 9.45, COL_Z1 - 7.6), Vector3(0.7, 0.5, 16.0))
	# Statue bases along the square and the speaker's platform (west).
	for i in 7:
		var z := -30.0 + 13.0 * float(i)
		var px := -10.5 if i % 2 == 0 else 10.5
		lm.box("Col", Vector3(px, G + 1.0, z), Vector3(2.2, 2.0, 4.2))
		lm.box("Col", Vector3(px, G + 2.15, z), Vector3(2.5, 0.3, 4.5))
		lm.box("Col", Vector3(px, G + 0.15, z), Vector3(2.6, 0.3, 4.6))
	lm.box("Pave", Vector3(-COL_X + 2.4, G + 1.0, 18.0), Vector3(4.0, 2.0, 12.0))
	SEuUtil.steps_up(lm, "Pave", Vector3(-COL_X + 4.4, G, 18.0), Vector3(1, 0, 0), 3.0, 0.35, 0.33, 6)
	for i in 3:
		lm.box("Col", Vector3(-4.0 + 4.0 * float(i), G + 1.4, 60.0), Vector3(2.4, 2.8, 2.4))

## Temple of Jupiter: podium with mouldings, stair, cella, column stumps;
## the honorific arches either side of it.
static func _temple(lm: LandmarkMesh) -> void:
	var pz := -65.0
	var top := G + 3.4
	lm.box("Pave", Vector3(0, G + 1.7, pz), Vector3(17.0, 3.4, 26.0))
	for y in [G + 0.25, top - 0.25]:
		lm.box("Col", Vector3(0, y, pz), Vector3(17.6, 0.5, 26.6))
	SEuUtil.steps_up(lm, "Col", Vector3(0, G, pz + 13.0), Vector3(0, 0, 1), 9.0, 0.5, 0.425, 8)
	# Cella: brick walls with stucco remnants, the back door into the vault.
	lm.box("Brick", Vector3(-5.6, top + 3.0, pz - 3.5), Vector3(1.4, 6.0, 15.0))
	lm.box("Brick", Vector3(5.6, top + 2.4, pz - 3.5), Vector3(1.4, 4.8, 15.0))
	lm.box("Brick", Vector3(0, top + 3.2, pz - 11.3), Vector3(12.6, 6.4, 1.4))
	lm.box("Stucco", Vector3(-6.35, top + 1.6, pz - 3.5), Vector3(0.12, 3.2, 14.0))
	lm.box("Brick", Vector3(-4.0, top + 2.3, pz + 4.4), Vector3(3.0, 4.6, 1.4))
	lm.box("Brick", Vector3(4.0, top + 2.0, pz + 4.4), Vector3(3.0, 4.0, 1.4))
	# Inner colonnade bases in the cella.
	for s in [-1.0, 1.0]:
		for i in 4:
			lm.frustum("Col", Vector3(s * 3.4, top, pz - 8.5 + 3.4 * float(i)), 0.42, 0.38, 1.2 + 0.3 * float(i % 2), 12)
	# Portico: six Corinthian columns across, four deep, broken stumps.
	var hs := [7.0, 3.0, 5.4, 2.2, 6.2, 3.6]
	for row in 3:
		for i in 6:
			var h: float = float(hs[(i + row * 3) % 6]) - float(row) * 0.9
			var p := Vector3(-6.75 + 2.7 * float(i), top, pz + 11.4 - 3.0 * float(row))
			lm.box("Col", p + Vector3(0, 0.2, 0), Vector3(1.5, 0.4, 1.5))
			lm.lathe("Col", p + Vector3(0, 0.4, 0), PackedVector2Array([Vector2(0.62, 0), Vector2(0.62, 0.15),
				Vector2(0.52, 0.3), Vector2(0.5, 0.45)]), 16, 1.0, 1.0, 0.0, true, false)
			_stump(lm, p + Vector3(0, 0.85, 0), 0.5, maxf(h - 0.85, 0.8), 0.37 * float(i + row))
	# The two arches beside the temple: brick core, travertine remnants.
	for s in [-1.0, 1.0]:
		var ax: float = s * 15.0
		LandmarkColosseum.arch_bay(lm, "Brick", "Shadow", Vector3(ax - 4.0, G, -58.0), Vector3(ax + 4.0, G, -58.0),
			0.0, 10.6, 0.46, 0.58, 3.6)
		for e in [-1.0, 1.0]:
			lm.box("Brick", Vector3(ax + float(e) * 3.1, G + 5.3, -59.8), Vector3(1.8, 10.6, 3.6))
			lm.box("Col", Vector3(ax + float(e) * 3.1, G + 0.6, -58.0), Vector3(2.0, 1.2, 0.3))
		for y in [4.6, 8.6]:
			lm.box("Col", Vector3(ax, G + float(y), -57.95), Vector3(8.2, 0.35, 0.25))
		SEuUtil.opening(lm, "Shadow", Vector3(ax - float(s) * 3.1, G + 1.6, -57.9), Vector3.RIGHT, Vector3.UP, 1.0, 2.4)

## A fluted column stump broken off at height h: 20 shallow flutes and a
## jagged top.
static func _stump(lm: LandmarkMesh, base: Vector3, r: float, h: float, seed_v: float) -> void:
	var cols := 40
	var rows: Array = []
	for t in [0.0, 0.5, 1.0]:
		var ring := PackedVector3Array()
		for i in cols + 1:
			var a := TAU * float(i) / float(cols)
			var dep := 0.0 if i % 2 == 0 else r * 0.06
			var rr := r * (1.0 - 0.04 * float(t)) - dep
			var y := float(t) * h
			if float(t) >= 1.0:
				y += 0.3 * sin(a * 3.0 + seed_v)
			ring.append(base + Vector3(cos(a) * rr, y, sin(a) * rr))
		rows.append(ring)
	lm.grid("Col", rows, base + Vector3(0, h * 0.5, 0), true)
	lm.disc("Col", base + Vector3(0, h, 0), Vector3.UP, r * 0.94, 12)

## The Basilica: outer walls with half-columns, 28 brick columns round
## the nave as stumps, the raised tribunal at the west end.
static func _basilica(lm: LandmarkMesh, c: Vector3) -> void:
	var w := 55.0
	var d := 24.0
	_ring(lm, "Brick", c, w, d, 8.0, 1.2, 1.0)
	for s in [-1.0, 1.0]:
		for i in 12:
			var x := c.x - w * 0.5 + 4.5 * (float(i) + 0.6)
			lm.frustum("Stucco", Vector3(x, c.y, c.z + float(s) * (d * 0.5 - 0.7)), 0.45, 0.42, 3.0 + 2.5 * absf(sin(float(i))), 10)
	# Peristyle of 28 brick columns (10 a side, 4 at the ends).
	for i in 28:
		var p: Vector3
		if i < 20:
			var side := -1.0 if i < 10 else 1.0
			p = Vector3(c.x - 21.0 + 42.0 * float(i % 10) / 9.0, c.y, c.z + side * 6.5)
		else:
			var side := -1.0 if i < 24 else 1.0
			p = Vector3(c.x + side * 21.0, c.y, c.z - 6.5 + 13.0 * (float((i - 20) % 4) + 0.5) / 4.0)
		var h := 1.6 + 7.0 * absf(sin(float(i) * 1.7))
		lm.frustum("Brick", p, 0.62, 0.6, h, 16)
		lm.frustum("Stucco", p, 0.66, 0.66, minf(h, 1.2), 16)
	# Tribunal: raised platform with columns at the west end.
	var tx := c.x - w * 0.5 + 5.0
	lm.box("Col", Vector3(tx, c.y + 1.2, c.z), Vector3(8.0, 2.4, 14.0))
	for i in 6:
		LandmarkDetail.column(lm, "Col", Vector3(tx + 3.2, c.y + 2.4, c.z - 6.0 + 2.4 * float(i)), 0.32,
			3.0 + 1.2 * float(i % 2), "corinthian", 0)
	# Entrance on the forum: the five-door vestibule step.
	lm.box("Col", Vector3(c.x + w * 0.5 + 1.0, c.y + 0.25, c.z), Vector3(2.0, 0.5, 22.0))

## Temple of Apollo in its courtyard: enclosure, portico of 48 columns
## (shown as the survivors), podium with stair and stumps, the altar and
## the bronze Apollo; the granary and weights table to the north.
static func _apollo(lm: LandmarkMesh, c: Vector3) -> void:
	var w := 39.0
	var d := 34.0
	_ring(lm, "Stucco", c, w, d, 6.0, 0.9, 7.0)
	for i in 28:
		var t := float(i) / 28.0
		var per := 2.0 * (w + d - 8.0)
		var u := t * per
		var p: Vector3
		var ww := w - 4.0
		var dd := d - 4.0
		if u < ww:
			p = c + Vector3(-ww * 0.5 + u, 0, -dd * 0.5)
		elif u < ww + dd:
			p = c + Vector3(ww * 0.5, 0, -dd * 0.5 + (u - ww))
		elif u < 2.0 * ww + dd:
			p = c + Vector3(ww * 0.5 - (u - ww - dd), 0, dd * 0.5)
		else:
			p = c + Vector3(-ww * 0.5, 0, dd * 0.5 - (u - 2.0 * ww - dd))
		LandmarkItlParts.column(lm, "Col", p, 0.3, 3.4 + (1.2 if i % 3 == 0 else 0.0), 8)
	var tc := c + Vector3(-3.0, 0, -4.0)
	lm.box("Pave", tc + Vector3(0, 1.1, 0), Vector3(9.0, 2.2, 17.0))
	lm.box("Col", tc + Vector3(0, 2.3, 0), Vector3(9.4, 0.3, 17.4))
	SEuUtil.steps_up(lm, "Col", tc + Vector3(0, 0, 8.5), Vector3(0, 0, 1), 6.0, 0.4, 0.37, 6)
	for i in 6:
		_stump(lm, tc + Vector3(-3.0 + 1.2 * float(i), 2.45, 5.5), 0.36, 1.0 + 1.8 * absf(sin(float(i) * 2.3)), float(i))
	lm.frustum("Col", tc + Vector3(0, 2.45, -2.0), 1.6, 1.6, 0.8, 16)
	lm.box("Col", tc + Vector3(0, 0.55, 12.0), Vector3(2.4, 1.1, 1.6))
	lm.box("Col", c + Vector3(16.0, 1.0, 4.0), Vector3(1.0, 2.0, 1.0))
	LandmarkKits.statue_figure(lm, "Shadow", c + Vector3(16.0, 2.0, 4.0), 1.8, true)
	_ring(lm, "Brick", Vector3(-33.0, G, -55.0), 24.0, 22.0, 6.5, 1.0, 5.0)
	for i in 8:
		LandmarkItlParts.column(lm, "Brick", Vector3(-23.0, G, -64.0 + 2.6 * float(i)), 0.4, 5.6, 8)
	lm.box("Col", Vector3(-20.0, G + 0.6, -36.0), Vector3(1.0, 1.2, 4.0))

## The east side: Macellum with its tholos, Sanctuary of the Lares,
## Temple of Vespasian, Building of Eumachia with its portico, Comitium,
## and the three halls on the south side.
static func _east(lm: LandmarkMesh) -> void:
	# Macellum: shops round a court, the twelve bases of the tholos.
	var mc := Vector3(38.0, G, -48.0)
	_ring(lm, "Brick", mc, 34.0, 36.0, 6.0, 1.0, 11.0)
	_wall(lm, "Brick", mc + Vector3(-12.0, 0, -18.0), mc + Vector3(-12.0, 0, 18.0), 4.0, 0.6, 3.0, 2)
	_wall(lm, "Brick", mc + Vector3(12.0, 0, -18.0), mc + Vector3(12.0, 0, 18.0), 4.0, 0.6, 4.0, 2)
	for i in 12:
		var a := TAU * float(i) / 12.0
		lm.box("Col", mc + Vector3(cos(a) * 5.0, 0.4, sin(a) * 5.0), Vector3(1.0, 0.8, 1.0))
	lm.frustum("Col", mc, 2.4, 2.4, 0.5, 12)
	# Sanctuary of the Lares: walls with niches and the apse at the back.
	var lc := Vector3(31.0, G, -17.0)
	_ring(lm, "Stucco", lc, 20.0, 22.0, 7.5, 1.1, 2.0)
	lm.lathe("Brick", lc + Vector3(10.0, 0, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(6.0, 6.5)]), 16, 1.0, 1.0,
		0.0, false, false)
	# Temple of Vespasian: precinct, small podium with stair, the altar.
	var vc := Vector3(30.0, G, 4.0)
	_ring(lm, "Stucco", vc, 18.0, 16.0, 6.0, 0.8, 9.0)
	lm.box("Pave", vc + Vector3(5.5, 1.3, 0), Vector3(5.0, 2.6, 7.0))
	SEuUtil.steps_up(lm, "Col", vc + Vector3(3.0, 0, 0), Vector3(-1, 0, 0), 3.0, 0.35, 0.37, 7)
	lm.box("Col", vc + Vector3(-2.0, 0.8, 0), Vector3(2.0, 1.6, 1.4))
	for i in 4:
		LandmarkItlParts.column(lm, "Col", Vector3(21.5, G, vc.z - 6.0 + 4.0 * float(i)), 0.32, 4.6, 8)
	# Building of Eumachia: portico of columns on the forum, marble door.
	var ec := Vector3(40.5, G, 33.0)
	_ring(lm, "Brick", ec, 39.0, 38.0, 8.5, 1.2, 13.0)
	for i in 11:
		var z := ec.z - 17.0 + 3.4 * float(i)
		LandmarkDetail.column(lm, "Col", Vector3(19.4, G, z), 0.38, 4.6 if i % 4 != 1 else 2.0, "tuscan", 0)
	lm.box("Col", Vector3(21.0, G + 3.0, ec.z), Vector3(0.6, 6.0, 4.6))
	SEuUtil.opening(lm, "Shadow", Vector3(20.68, G, ec.z), Vector3(0, 0, -1), Vector3.UP, 2.6, 4.8)
	for i in 4:
		lm.frustum("Col", ec + Vector3(-6.0 + 4.0 * float(i), 0, 0), 0.4, 0.38, 3.2, 12)
	lm.lathe("Brick", ec + Vector3(19.5, 0, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(5.0, 6.0)]), 14, 1.0, 1.0,
		0.0, false, false)
	# Comitium.
	_ring(lm, "Brick", Vector3(30.5, G, 64.0), 19.0, 20.0, 7.0, 1.2, 17.0)
	# The three municipal halls across the south end, apses at the back.
	for i in 3:
		var hc := Vector3(-11.5 + 11.5 * float(i), G, 81.0)
		_ring(lm, "Brick", hc, 10.5, 18.0, 8.0, 1.2, 20.0 + float(i))
		lm.lathe("Brick", hc + Vector3(0, 0, 9.0), PackedVector2Array([Vector2(4.6, 0), Vector2(4.6, 7.0)]), 14, 1.0, 1.0,
			0.0, false, false)
		lm.box("Col", hc + Vector3(0, 0.25, -9.6), Vector3(8.0, 0.5, 1.4))
