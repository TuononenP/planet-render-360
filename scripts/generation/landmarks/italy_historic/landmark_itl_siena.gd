class_name LandmarkItlSiena
extends RefCounted

## The Palazzo Pubblico of Siena (1297-1310) and the Torre del Mangia
## (1325-48) in true metres: the travertine and brick town hall bowed to
## the shell of the Piazza del Campo, the slender brick tower at its left
## end with the Cappella di Piazza at its foot.

const FACADE_TILT := 0.21
const TOWER := Vector3(-31.5, 0, -1.4)

## Origin at the middle of the Campo front facing +Z. The central block
## (four storeys, 31 m to its crown) has a travertine ground floor of
## Sienese arches (a pointed arch over a flat-headed door), three brick
## floors of three-light windows with white marble colonnettes, the
## crenellated attic with the 1425 bronze disc of the Christogram, and a
## corbelled crown of swallow-tail merlons; two wings swing forward round
## the curve of the Campo. The Torre del Mangia: a brick shaft of almost
## 70 m with the clock, Lippo Memmi's travertine crown of inverted-pyramid
## corbels, the open bell chamber with the Sunto bell, its merlons, the
## marble cap at 88 m and the lightning rod to 102 m. The Cappella di
## Piazza (1352): marble piers with saints in tabernacles under
## Federighi's Renaissance arches.
static func torre_del_mangia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A24B2F", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC1A4", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DCCB", 2.0))
	lm.use("Grey", LandmarkMaterials.pbr("limestone", "#BDB8AB", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E372F", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	# Central block.
	lm.box("Stone", Vector3(0, 5.0, -18.0), Vector3(40.0, 10.0, 36.0))
	lm.box("Brick", Vector3(0, 20.5, -18.0), Vector3(40.0, 21.0, 36.0))
	_front(lm, Vector3.ZERO, Vector3.RIGHT, Vector3(0, 0, 1), 40.0, 5, [11.6, 19.4], true)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 0.04), Vector3.RIGHT, Vector3(0, 0, 1), 26.8, 9, 4.2, 1.4, 2.4, true)
	LandmarkItlParts.arch_frieze(lm, "Marble", Vector3(-20.9, 31.0, 0.9), Vector3(20.9, 31.0, 0.9), Vector3(0, 0, 1), 1.5,
		1.1, true)
	LandmarkItlUtil.gallery(lm, "Marble", "Shadow", Vector3(0, 31.0, -18.0), 20.0, 18.0, 0.0, 0.9, 1.1, 2.0, true, 1.5)
	# The Christogram disc with its flame rays.
	var dc := Vector3(0, 28.6, 0.12)
	lm.disc("Gold", dc, Vector3(0, 0, 1), 1.6, 24)
	lm.disc("Shadow", dc + Vector3(0, 0, 0.03), Vector3(0, 0, 1), 1.1, 20)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.beam("Gold", dc + Vector3(cos(a), sin(a), 0) * 1.6, dc + Vector3(cos(a), sin(a), 0) * (2.2 if k % 2 == 0 else 1.9),
			0.14, 0.06)
	# Wings, swung forward round the curve of the Campo.
	for s in [-1.0, 1.0]:
		var a: float = FACADE_TILT if s < 0.0 else -FACADE_TILT
		var b := Basis(Vector3.UP, a)
		var wl := 18.0 if s < 0.0 else 16.0
		var inner := Vector3(s * 20.0, 0, 0)
		var mid := inner + b * Vector3(s * wl * 0.5, 0, -15.0)
		lm.box("Stone", mid + Vector3(0, 5.0, 0), Vector3(wl, 10.0, 30.0), b)
		lm.box("Brick", mid + Vector3(0, 17.5, 0), Vector3(wl, 15.0, 30.0), b)
		var fc := inner + b * Vector3(s * wl * 0.5, 0, 0)
		_front(lm, fc, b * Vector3(1, 0, 0), b * Vector3(0, 0, 1), wl, 2, [11.4, 18.6], false)
		LandmarkItlUtil.gallery(lm, "Marble", "Shadow", mid + Vector3(0, 25.0, 0), wl * 0.5, 15.0, a, 0.8, 1.0, 1.8, true,
			1.4)
	_cappella(lm)
	_tower(lm)
	lm.commit(model)

## A front `w` wide centred on `o` (ground, on the face): travertine floor
## of Sienese arches, marble string courses, rows of trifore at `rows`.
static func _front(lm: LandmarkMesh, o: Vector3, right: Vector3, out: Vector3, w: float, bays: int, rows: Array,
		central: bool) -> void:
	var basis := Basis(right, Vector3.UP, out)
	var pitch := w / float(bays)
	for y in [10.0, 18.4]:
		lm.box("Marble", o + Vector3(0, y, 0) + out * 0.2, Vector3(w + 0.8, 0.6, 0.5), basis)
	for i in bays:
		var s := (float(i) - float(bays - 1) * 0.5) * pitch
		var p := o + right * s
		# Sienese arch: pointed arch over a segmental-headed doorway.
		LandmarkItlParts.gothic_window(lm, "Stone", "Shadow", p + Vector3(0, 0.3, 0), out, pitch * 0.42, 7.6, 1, true, 0.4,
			0.5)
		var seg := LandmarkItlParts.arch_pts(p + Vector3(0, 4.3, 0) + out * 0.2, right, pitch * 0.21, false, 6)
		for k in seg.size() - 1:
			lm.beam("Stone", seg[k] - Vector3(0, (seg[k].y - 4.3) * 0.6, 0),
				seg[k + 1] - Vector3(0, (seg[k + 1].y - 4.3) * 0.6, 0), 0.4, 0.45, out)
		for y in rows:
			_trifora(lm, p + Vector3(0, float(y), 0), out, minf(pitch * 0.5, 3.6), 5.6)
	if central:
		LandmarkItlParts.quoins(lm, "Stone", o + right * w * 0.5, -right, -out, 0.0, 10.0, 0.7, 1.3, 0.15)

## Three-light window with marble colonnettes under a pointed brick arch,
## the Sienese tympanum over the lights.
static func _trifora(lm: LandmarkMesh, o: Vector3, out: Vector3, w: float, h: float) -> void:
	LandmarkItlParts.gothic_window(lm, "Marble", "Shadow", o, out, w, h, 3, true, 0.25, 0.2)
	var r := Vector3.UP.cross(out).normalized()
	var arc := LandmarkItlParts.arch_pts(o + Vector3(0, h - w * 0.866, 0) + out * 0.08, r, w * 0.5 + 0.45, true, 8)
	for k in arc.size() - 1:
		lm.beam("Brick", arc[k], arc[k + 1], 0.16, 0.4, out)

## Cappella di Piazza at the tower foot: four marble piers with saints in
## tabernacles, three round arches above, carved frieze, low roof.
static func _cappella(lm: LandmarkMesh) -> void:
	var c := Vector3(TOWER.x, 0, 5.4)
	lm.box("Marble", c + Vector3(0, 0.3, 0), Vector3(13.2, 0.6, 7.2))
	lm.box("Marble", c + Vector3(0, 5.0, -2.6), Vector3(12.4, 10.0, 1.2))
	for i in 4:
		var x := -5.6 + 3.733 * float(i)
		var p := c + Vector3(x, 0.6, 2.6)
		lm.box("Marble", p + Vector3(0, 3.2, 0), Vector3(1.1, 6.4, 1.1))
		# Tabernacle niche with a saint on the pier's front.
		lm.box("Marble", p + Vector3(0, 3.6, 0.7), Vector3(1.0, 2.8, 0.3))
		lm.spire("Marble", p + Vector3(0, 5.0, 0.7), 0.5, 1.4)
		LandmarkKits.statue_figure(lm, "Grey", p + Vector3(0, 2.2, 0.85), 2.0)
		lm.box("Marble", p + Vector3(0, 6.6, 0), Vector3(1.4, 0.4, 1.4))
	for i in 3:
		var x := -5.6 + 3.733 * (float(i) + 0.5)
		LandmarkDetail.arch(lm, "Marble", c + Vector3(x, 6.8, 2.6), Vector3(0, 0, 1), 2.7, 0.35, 0.4)
	lm.box("Marble", c + Vector3(0, 9.4, 2.3), Vector3(12.8, 1.0, 1.4))
	LandmarkDetail.cornice(lm, "Marble", c + Vector3(-6.4, 9.9, 3.0), c + Vector3(6.4, 9.9, 3.0), Vector3(0, 0, 1), 0.6,
		true)
	lm.box("Marble", c + Vector3(0, 9.6, 0), Vector3(12.4, 0.8, 5.4))
	lm.box("Grey", c + Vector3(0, 10.6, 0.1), Vector3(13.0, 0.4, 6.4))
	for sx in [-1.0, 1.0]:
		lm.box("Marble", c + Vector3(float(sx) * 6.0, 5.0, 0), Vector3(0.6, 10.0, 5.4))

## The Torre del Mangia.
static func _tower(lm: LandmarkMesh) -> void:
	var t := TOWER
	var rows := [[16.0, 0.8, 2.8, 1, 0.0, false], [42.0, 0.8, 2.8, 1, 0.0, false], [54.0, 0.8, 2.8, 1, 0.0, false],
		[62.0, 0.8, 2.8, 2, 1.8, false]]
	LandmarkItlUtil.tower(lm, "Brick", "Shadow", t, 3.75, t + Vector3(0, 69.0, 0), 3.75, 0.0, rows)
	# Clock dial on the Campo face.
	var cc := t + Vector3(0, 34.0, 3.8)
	lm.disc("Marble", cc, Vector3(0, 0, 1), 1.5, 24)
	lm.disc("Shadow", cc + Vector3(0, 0, 0.03), Vector3(0, 0, 1), 1.2, 24)
	lm.beam("Gold", cc + Vector3(0, 0, 0.08), cc + Vector3(-0.5, 0.75, 0.08), 0.1, 0.04)
	# Pilaster strips and putlog holes up the shaft.
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		LandmarkItlParts.putlogs(lm, "Shadow", t + n * 3.75 - r * 3.4, r, n, 6.8, 6.0, 66.0, 1.7, 3.2, 0.2)
		for s in [-1.0, 1.0]:
			lm.box("Brick", t + n * 3.85 + r * 3.45 * float(s) + Vector3(0, 34.5, 0), Vector3(0.6, 69.0, 0.3), b)
	# Travertine crown: inverted-pyramid corbels with arches, merlons.
	var cy := 69.0
	lm.box("Stone", t + Vector3(0, cy + 0.6, 0), Vector3(7.2, 1.2, 7.2))
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		for i in 5:
			var s := -3.0 + 1.5 * float(i)
			var p := t + n * 3.5 + r * s + Vector3(0, cy + 1.2, 0)
			lm.lathe("Stone", p - Vector3(0, 1.4, 0) + n * 0.5, PackedVector2Array([Vector2(0.05, 0), Vector2(0.25, 1.0),
				Vector2(0.45, 2.0), Vector2(0.5, 2.6)]), 4, 1.0, 1.0, PI * 0.25, false)
		LandmarkItlParts.arch_frieze(lm, "Stone", t + n * 4.6 - r * 4.6 + Vector3(0, cy + 2.4, 0),
			t + n * 4.6 + r * 4.6 + Vector3(0, cy + 2.4, 0), n, 1.5, 1.2, true)
		lm.disc("Marble", t + n * 3.8 + Vector3(0, cy - 2.8, 0), n, 0.7, 12)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", t + Vector3(0, cy + 2.4, 0), 3.9, 3.9, 0.0, 0.9, 1.0, 1.6, false, 1.1)
	# Bell chamber: pale loggia, two arches a side, the Sunto inside.
	var by := cy + 3.3
	lm.box("Grey", t + Vector3(0, by + 0.2, 0), Vector3(6.0, 0.4, 6.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Grey", t + Vector3(float(sx) * 2.55, by + 4.0, float(sz) * 2.55), Vector3(0.9, 7.6, 0.9))
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		lm.frustum("Grey", t + n * 2.55 + Vector3(0, by + 0.4, 0), 0.22, 0.2, 5.4, 8)
		for s in [-1.0, 1.0]:
			var arc := LandmarkItlParts.arch_pts(t + n * 2.55 + r * 1.27 * float(s) + Vector3(0, by + 5.8, 0), r, 1.05,
				true, 6)
			for j in arc.size() - 1:
				lm.beam("Grey", arc[j], arc[j + 1], 0.6, 0.4, n)
		lm.box("Grey", t + n * 2.55 + Vector3(0, by + 7.75, 0), Vector3(6.0, 0.3, 0.7), b)
	lm.lathe("Gold", t + Vector3(0, by + 1.4, 0), PackedVector2Array([Vector2(0.99, 0), Vector2(0.95, 0.2),
		Vector2(0.7, 0.8), Vector2(0.62, 1.6), Vector2(0.5, 2.1), Vector2(0.0, 2.34)]), 14)
	var gy := by + 7.9
	LandmarkItlUtil.gallery(lm, "Grey", "Shadow", t + Vector3(0, gy, 0), 3.0, 3.0, 0.0, 0.5, 0.8, 1.1, false, 0.9)
	# Marble cap: drum, small cupola and the lightning rod to 102 m.
	var my := gy + 2.8
	lm.frustum("Marble", t + Vector3(0, my, 0), 2.0, 1.9, 1.2, 16)
	lm.lathe("Marble", t + Vector3(0, my + 1.2, 0), SEuUtil.dome(2.1, 1.8, 6), 16)
	lm.frustum("Marble", t + Vector3(0, my + 3.0, 0), 0.4, 0.3, 0.8, 8)
	var top := my + 3.8
	lm.frustum("Shadow", t + Vector3(0, top, 0), 0.12, 0.05, 102.0 - top - 0.4, 6)
	lm.frustum("Gold", t + Vector3(0, 101.6, 0), 0.08, 0.0, 0.4, 6)
