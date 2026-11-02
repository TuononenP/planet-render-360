class_name LandmarkItlSighs
extends RefCounted

## The Bridge of Sighs (Ponte dei Sospiri, Antonio Contin, 1600-03) in
## true metres: the enclosed white Istrian limestone passage between the
## Doge's Palace and the New Prisons over the Rio di Palazzo.

const SPAN_HW := 3.4
const BODY_HW := 5.0
const HALF_W := 1.9
const ARCH_Y := 5.0
const ARCH_RISE := 1.3
const BODY_Y0 := 7.0
const BODY_Y1 := 10.4

## Built along +X (the palace at -X, the prisons at +X), water at y = 0.
## The 11 m passage, 3.8 m wide, on a flattened arch over the 6.8 m canal:
## rusticated end pilasters, an archivolt of voussoirs carrying eleven
## carved heads (a lion's in the middle), reclining figures in the
## spandrels, two windows a side behind stone grilles of four eight-leaf
## rosettes each, a dentilled cornice, corner volutes and Doge Marino
## Grimani's arms under Justice on the crest, and a low lead roof; the
## palace's Istrian stone flank and the rusticated prison wall either side.
static func bridge_of_sighs(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#EAE3D3", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F2EDE0", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E362E", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8A8E8F", 2.0))
	lm.use("Pink", LandmarkMaterials.pbr("limestone", "#E2CFC3", 3.0))
	lm.use("Grey", LandmarkMaterials.pbr("limestone", "#CFC8B8", 3.0))
	# Passage core, string course, roof.
	lm.box("Stone", Vector3(0, (BODY_Y0 + BODY_Y1) * 0.5, 0), Vector3(BODY_HW * 2.0, BODY_Y1 - BODY_Y0, HALF_W * 2.0))
	lm.box("Trim", Vector3(0, BODY_Y0 + 0.2, 0), Vector3(BODY_HW * 2.0 + 0.4, 0.4, HALF_W * 2.0 + 0.9))
	lm.box("Trim", Vector3(0, BODY_Y1 + 0.2, 0), Vector3(BODY_HW * 2.0 + 0.8, 0.4, HALF_W * 2.0 + 0.6))
	lm.gable("Roof", Vector3(0, BODY_Y1 + 0.45, 0), HALF_W * 2.0, BODY_HW * 2.0 + 0.4, 0.9,
		Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	_soffit(lm)
	for sgn in [-1.0, 1.0]:
		_face(lm, float(sgn))
	_flanks(lm)
	lm.commit(model)

## The flattened arch: soffit and the solid spandrel faces up to the body.
static func _soffit(lm: LandmarkMesh) -> void:
	var prev := Vector2(-SPAN_HW, ARCH_Y)
	for k in range(1, 17):
		var t := float(k) / 16.0
		var p := Vector2(-SPAN_HW + SPAN_HW * 2.0 * t, ARCH_Y + ARCH_RISE * sin(PI * t))
		var d := p - prev
		var n := Vector3(d.y, -d.x, 0).normalized()
		if n.y > 0.0:
			n = -n
		lm.quad("Stone", Vector3(prev.x, prev.y, -HALF_W), Vector3(p.x, p.y, -HALF_W), Vector3(p.x, p.y, HALF_W),
			Vector3(prev.x, prev.y, HALF_W), n)
		for zz in [-HALF_W, HALF_W]:
			lm.quad("Stone", Vector3(prev.x, prev.y, zz), Vector3(p.x, p.y, zz), Vector3(p.x, BODY_Y0, zz),
				Vector3(prev.x, BODY_Y0, zz), Vector3(0, 0, signf(zz)))
		prev = p

## One canal front (sgn = +1 faces +Z).
static func _face(lm: LandmarkMesh, sgn: float) -> void:
	var out := Vector3(0, 0, sgn)
	var z := HALF_W * sgn
	var right := Vector3(-sgn, 0, 0)
	var skin := 0.3
	# Wall skin with the two window openings, laid over the core.
	# The front between the two buildings spans the canal (6.8 m).
	LandmarkDetail.pierced_face(lm, "Stone", "Shadow", Vector3(SPAN_HW * sgn, BODY_Y0 + 0.4, z), right, out,
		SPAN_HW * 2.0, BODY_Y1 - BODY_Y0 - 0.4, 2, 1, Vector2(1.5, 2.0), 0.5, 3.0, skin)
	var fz := z + sgn * skin
	# Rusticated pilasters at both ends, from the arch springing up.
	for ex in [-1.0, 1.0]:
		LandmarkItlParts.rustic_pier(lm, "Trim", Vector3(float(ex) * (SPAN_HW - 0.3), ARCH_Y - 0.6, fz - sgn * 0.1),
			Vector3.RIGHT, out, 0.6, BODY_Y1 - ARCH_Y + 0.6, 0.55, 0.22)
	# Archivolt: voussoirs along the flattened arch with eleven heads.
	var pts: Array[Vector3] = []
	for k in 16:
		var t := (float(k) + 0.5) / 16.0
		pts.append(Vector3(-SPAN_HW + SPAN_HW * 2.0 * t, ARCH_Y + ARCH_RISE * sin(PI * t), z + sgn * 0.12))
	for k in 16:
		var t0 := float(k) / 16.0
		var t1 := float(k + 1) / 16.0
		var a := Vector3(-SPAN_HW + SPAN_HW * 2.0 * t0, ARCH_Y + ARCH_RISE * sin(PI * t0), z + sgn * 0.12)
		var b := Vector3(-SPAN_HW + SPAN_HW * 2.0 * t1, ARCH_Y + ARCH_RISE * sin(PI * t1), z + sgn * 0.12)
		var dir := (b - a).normalized()
		var up := out.cross(dir).normalized()
		if up.y < 0.0:
			up = -up
		lm.box("Trim", (a + b) * 0.5 + up * 0.3, Vector3(a.distance_to(b) * 0.94, 0.6, 0.24),
			Basis(dir, up, out))
	for i in 11:
		var t := (float(i) + 0.5) / 11.0
		var hp := Vector3(-SPAN_HW + SPAN_HW * 2.0 * t, ARCH_Y + ARCH_RISE * sin(PI * t) + 0.32, z + sgn * 0.3)
		var big := 1.4 if i == 5 else 1.0
		SEuUtil.blob(lm, "Trim", hp, 0.13 * big, 0.17 * big, 0.12 * big, Vector3.ZERO, false, 4, 8)
	lm.box("Trim", Vector3(0, ARCH_Y + ARCH_RISE + 0.45, z + sgn * 0.2), Vector3(0.5, 0.9, 0.4))
	# Reclining figures on the spandrels.
	for ex in [-1.0, 1.0]:
		var fc := Vector3(float(ex) * 2.1, BODY_Y0 - 0.45, z + sgn * 0.22)
		SEuUtil.blob(lm, "Trim", fc, 0.75, 0.22, 0.2, Vector3.ZERO, false, 5, 10)
		SEuUtil.blob(lm, "Trim", fc + Vector3(float(ex) * 0.75, 0.25, 0), 0.14, 0.17, 0.14, Vector3.ZERO, false, 4, 8)
	# Window surrounds: jambs, sill, pediment; stone grilles inside.
	for wx in [-1.7, 1.7]:
		var x: float = wx
		var wb := BODY_Y0 + 0.9
		for jx in [-0.88, 0.88]:
			lm.box("Trim", Vector3(x + float(jx), wb + 1.0, fz + sgn * 0.08), Vector3(0.26, 2.2, 0.16))
		lm.box("Trim", Vector3(x, wb - 0.12, fz + sgn * 0.12), Vector3(2.0, 0.22, 0.32))
		lm.box("Trim", Vector3(x, wb + 2.12, fz + sgn * 0.1), Vector3(2.1, 0.2, 0.26))
		lm.gable("Trim", Vector3(x, wb + 2.22, fz + sgn * 0.05), 2.0, 0.3, 0.45, Basis(), 0.0, "Trim")
		_grille(lm, Vector3(x, wb, z + sgn * skin * 0.5), out)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-SPAN_HW - 0.3, BODY_Y1 - 0.35, fz),
		Vector3(SPAN_HW + 0.3, BODY_Y1 - 0.35, fz), out, 0.5, true)
	# Crest: corner volutes, the Grimani shield and Justice above it.
	for ex in [-1.0, 1.0]:
		_volute(lm, Vector3(float(ex) * (SPAN_HW - 0.4), BODY_Y1 + 0.4, fz - sgn * 0.1), out, -float(ex))
	var sc := Vector3(0, BODY_Y1 + 0.4, fz - sgn * 0.15)
	lm.box("Trim", sc + Vector3(0, 0.35, 0), Vector3(1.0, 0.7, 0.3))
	lm.disc("Trim", sc + Vector3(0, 0.45, sgn * 0.17), out, 0.32, 12)
	for vx in [-1.0, 1.0]:
		_volute(lm, sc + Vector3(float(vx) * 0.75, 0.0, 0), out, -float(vx), 0.32)
	LandmarkKits.statue_figure(lm, "Trim", sc + Vector3(0, 0.7, 0), 0.8, true)

## Stone grille of one window (1.5 x 2.0 m, bottom centre `o`): a 2 x 2
## grid of cells, each an eight-leaf rosette in a ring.
static func _grille(lm: LandmarkMesh, o: Vector3, out: Vector3) -> void:
	var r := Vector3.UP.cross(out).normalized()
	var bar := 0.07
	for k in 3:
		var y := o.y + 1.0 * float(k)
		lm.beam("Trim", Vector3(o.x, y, o.z) - r * 0.75, Vector3(o.x, y, o.z) + r * 0.75, bar, bar, Vector3.UP)
		var xo := o + r * (-0.75 + 0.75 * float(k))
		lm.beam("Trim", xo, xo + Vector3(0, 2.0, 0), bar, bar, r)
	for cx in [-0.375, 0.375]:
		for cy in [0.5, 1.5]:
			var c := o + r * float(cx) + Vector3(0, float(cy), 0)
			var prev := c + r * 0.3
			for i in 8:
				var a := TAU * float(i + 1) / 8.0
				var p := c + (r * cos(a) + Vector3.UP * sin(a)) * 0.3
				lm.beam("Trim", prev, p, bar * 0.8, bar * 0.8, out)
				prev = p
				var ah := TAU * (float(i) + 0.5) / 8.0
				var leaf := (r * cos(ah) + Vector3.UP * sin(ah))
				lm.beam("Trim", c + leaf * 0.06, c + leaf * 0.27, bar * 1.1, bar * 0.6, out)
			lm.disc("Trim", c + out * 0.04, out, 0.07, 8)

## A scroll (volute) on the crest, unrolling toward `side`, facing `out`.
static func _volute(lm: LandmarkMesh, c: Vector3, out: Vector3, side: float, s: float = 0.45) -> void:
	var r := Vector3.UP.cross(out).normalized()
	var prev := c + r * side * s
	for i in 12:
		var t := float(i + 1) / 12.0
		var a := t * TAU * 1.1
		var rr := s * (1.0 - t * 0.7)
		var p := c + r * side * cos(a) * rr + Vector3.UP * (sin(a) * rr + s)
		lm.beam("Trim", prev, p, 0.14 * s / 0.45, 0.22, out)
		prev = p

## The canal fronts of the Doge's Palace (-X) and the New Prisons (+X).
static func _flanks(lm: LandmarkMesh) -> void:
	lm.box("Pink", Vector3(-7.9, 5.5, 0), Vector3(8.4, 11.0, 14.0))
	lm.box("Grey", Vector3(7.4, 4.9, 0), Vector3(7.4, 9.8, 14.0))
	# Palace flank: Istrian stone skin, four bays of windows on three
	# storeys, framed and pedimented, a string course at each floor.
	var px := -SPAN_HW - 0.3
	LandmarkDetail.pierced_face(lm, "Pink", "Shadow", Vector3(px, 0, 7.0), Vector3(0, 0, -1), Vector3(1, 0, 0),
		14.0, 11.0, 4, 3, Vector2(1.3, 2.4), 1.4, 3.4, 0.3)
	for j in 3:
		var y := 1.4 + 3.4 * float(j)
		for i in 4:
			var zc := 7.0 - 3.5 * (float(i) + 0.5)
			if absf(zc) < HALF_W + 1.0 and j >= 2:
				continue
			LandmarkDetail.window(lm, "Trim", "Shadow", Vector3(-SPAN_HW + 0.02, y + 1.2, zc), Vector3(1, 0, 0),
				1.3, 2.4, false, 0.18)
		lm.box("Trim", Vector3(-SPAN_HW + 0.1, y - 0.35, 0), Vector3(0.3, 0.3, 14.0))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-SPAN_HW, 10.5, -7.0), Vector3(-SPAN_HW, 10.5, 7.0),
		Vector3(1, 0, 0), 0.5, false)
	# Prison front: rusticated courses and small barred windows.
	var qx := SPAN_HW + 0.3
	LandmarkDetail.pierced_face(lm, "Grey", "Shadow", Vector3(qx, 0, -7.0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
		14.0, 9.8, 4, 2, Vector2(1.0, 1.4), 2.6, 4.0, 0.3)
	for k in 18:
		var y := 0.25 + 0.55 * float(k)
		if y > 9.6:
			break
		lm.box("Grey", Vector3(SPAN_HW + 0.02, y, 0), Vector3(0.12, 0.08, 14.0), Basis(), 0.0)
	for j in 2:
		for i in 4:
			var zc := -7.0 + 3.5 * (float(i) + 0.5)
			var wy := 2.6 + 4.0 * float(j)
			for b in 4:
				var bz := zc - 0.375 + 0.25 * float(b)
				lm.beam("Shadow", Vector3(SPAN_HW - 0.05, wy, bz), Vector3(SPAN_HW - 0.05, wy + 1.4, bz), 0.05, 0.05)
	LandmarkDetail.cornice(lm, "Grey", Vector3(SPAN_HW, 9.3, 7.0), Vector3(SPAN_HW, 9.3, -7.0),
		Vector3(-1, 0, 0), 0.5, false)
