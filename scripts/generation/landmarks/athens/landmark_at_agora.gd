class_name LandmarkAtAgora
extends RefCounted

## The Stoa of Attalos, the Tower of the Winds, the Choragic Monument of
## Lysicrates and the Monument of Philopappos in true metres.

# --- Stoa of Attalos ---------------------------------------------------

## Origin at the middle of the stoa, colonnade toward +Z (yaw_deg turns it
## west onto the Agora). The reconstructed two-storey hall, 115 x 19.6 m,
## 12 m to the ridge: 45 Doric columns outside below (triglyph frieze,
## two triglyphs a bay) and 45 Ionic above behind a parapet of panels,
## the 22 Ionic columns of the inner row below and the palm-capital
## columns above it, a back wall and a shop wall with 21 doors per floor,
## end walls with antae under the pediments and the tiled roof.
static func stoa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D7BF", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CBB993", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4439", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B2663F", 3.0))
	var y0 := 0.6
	var half := 57.5
	AtUtil.steps(lm, "Stone", Vector3(0, y0, 0), 115.0, 19.6, 2, 0.3, 0.5)
	lm.box("Stone", Vector3(0, 5.8, -9.1), Vector3(115.0, 10.4, 1.4))
	lm.box("Stone", Vector3(0, 5.8, -5.0), Vector3(113.0, 10.4, 0.8))
	lm.box("Stone", Vector3(0, 6.5, 2.0), Vector3(113.0, 0.4, 14.0))
	for i in 21:
		var x := -52.0 + 5.2 * float(i)
		AtUtil.doorway(lm, "Marble", "Shadow", Vector3(x, y0, -4.6), Vector3.BACK, 1.6, 3.0)
		AtUtil.doorway(lm, "Marble", "Shadow", Vector3(x, 6.7, -4.6), Vector3.BACK, 1.6, 2.8)
	# End walls with antae, closing the two aisles under the pediments.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * (half - 0.6), 5.8, 0.0), Vector3(1.2, 10.4, 19.0))
		lm.box("Marble", Vector3(s * (half - 0.6), 2.95, 8.9), Vector3(1.4, 4.7, 1.0))
		lm.box("Marble", Vector3(s * (half - 0.6), 8.6, 8.4), Vector3(1.3, 4.0, 0.9))
		lm.box("Marble", Vector3(s * (half - 0.6), y0 + 0.2, 0.0), Vector3(1.4, 0.4, 19.2))
	# Outer colonnades: Doric below (45 columns), Ionic above.
	var n := 45
	var x0 := -54.6
	var pitch := 109.2 / float(n - 1)
	for i in n:
		var x := x0 + pitch * float(i)
		AtUtil.doric(lm, "Marble", Vector3(x, y0, 8.5), 4.8, 0.37, 20)
		AtUtil.ionic(lm, "Marble", Vector3(x, 6.7, 8.0), 3.3, 0.28, 0, 0.0)
		if i < n - 1:
			# Parapet panel between the upper columns.
			lm.box("Marble", Vector3(x + pitch * 0.5, 6.7 + 0.5, 8.0), Vector3(pitch - 0.6, 1.0, 0.14))
			lm.box("Marble", Vector3(x + pitch * 0.5, 7.25, 8.0), Vector3(pitch - 0.5, 0.1, 0.3), Basis(), 0.0)
	AtUtil.entab(lm, "Marble", "Stone", Vector3(0, y0 + 4.8, 8.5), 112.0, 1.0, 0.55, 0.55, 0.3,
		Basis(), false, false)
	AtUtil.triglyphs(lm, "Shadow", Vector3(x0, 6.225, 9.0), Vector3(-x0, 6.225, 9.0), (n - 1) * 3 + 1,
		Vector3.BACK, 0.45, 0.3)
	AtUtil.entab(lm, "Marble", "Stone", Vector3(0, 10.0, 8.0), 112.0, 0.9, 0.4, 0.35, 0.25, Basis(), true, false)
	# Inner row: 22 Ionic columns below, palm capitals above.
	for i in 22:
		var x := -52.5 + 5.0 * float(i)
		AtUtil.ionic(lm, "Marble", Vector3(x, y0, 1.5), 5.9, 0.4, 0, 0.0)
		AtUtil.fluted(lm, "Marble", Vector3(x, 6.7, 1.5), 3.0, 0.27, 0.23, 0)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Marble", Vector3(x, 9.7, 1.5) + d * 0.2, Vector3(x, 10.1, 1.5) + d * 0.42, 0.18, 0.05,
				d.cross(Vector3.UP))
		lm.box("Marble", Vector3(x, 10.15, 1.5), Vector3(0.75, 0.12, 0.75))
	lm.box("Marble", Vector3(0, y0 + 5.9 + 0.2, 1.5), Vector3(110.0, 0.4, 0.7))
	lm.box("Marble", Vector3(0, 10.4, 1.5), Vector3(110.0, 0.5, 0.6))
	var rq := Basis(Vector3.UP, PI * 0.5)
	AtUtil.roof(lm, "Roof", "Marble", "Stone", Vector3(0, 11.0, 0), 19.6, 115.0, 1.0, 0.3, rq)
	AtUtil.roof_tiles(lm, "Roof", Vector3(0, 11.0, 0), 19.6, 115.0, 1.0, rq, 0.3, 1.2)
	lm.commit(model)

# --- Tower of the Winds --------------------------------------------------

## Origin at the centre of the octagon, faces to the compass points: the
## 8 m marble Horologion of Andronikos Kyrrhestes on its three steps,
## 12 m with its roof of 24 radiating marble slabs carved as tiles and
## the capital that carried the bronze Triton vane; the frieze of the
## eight flying winds under a cornice of lion-head spouts, eight
## sundials, the two pedimented porches (north-east and north-west) on
## pairs of baseless Corinthian columns, and the ruined round water
## turret against the south face.
static func tower_of_winds(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DFD3BA", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB78F", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F463B", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#D5C8AC", 2.0))
	var rot := PI / 8.0
	var rr := 4.0 / cos(rot)
	for k in 3:
		var r := rr + 0.9 - 0.3 * float(k)
		lm.frustum("Marble", Vector3(0, 0.2 * float(k), 0), r, r, 0.2, 8, rot)
	lm.frustum("Marble", Vector3(0, 0.6, 0), rr, rr, 7.9, 8, rot)
	lm.frustum("Marble", Vector3(0, 0.6, 0), rr * 1.03, rr * 1.03, 0.35, 8, rot)
	lm.frustum("Honey", Vector3(0, 7.25, 0), rr * 1.015, rr * 1.015, 1.15, 8, rot)
	lm.frustum("Marble", Vector3(0, 8.4, 0), rr * 1.04, rr * 1.06, 0.2, 8, rot)
	lm.frustum("Marble", Vector3(0, 8.6, 0), rr * 1.1, rr * 1.12, 0.3, 8, rot)
	lm.lathe("Roof", Vector3.ZERO, PackedVector2Array([Vector2(4.95, 8.9), Vector2(0.35, 11.4)]), 8, 1.0, 1.0,
		rot, false)
	# The 24 slab joints with their cover tiles, and the crowning capital.
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		var f := cos(PI / 8.0) / cos(fposmod(a - rot, PI / 4.0) - PI / 8.0)
		lm.beam("Roof", d * 4.9 * f + Vector3(0, 8.95, 0), d * 0.4 + Vector3(0, 11.38, 0), 0.16, 0.12)
	lm.lathe("Roof", Vector3(0, 11.35, 0), PackedVector2Array([Vector2(0.45, 0), Vector2(0.38, 0.12),
		Vector2(0.28, 0.25), Vector2(0.34, 0.45), Vector2(0.2, 0.6), Vector2(0.0, 0.65)]), 12)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, atan2(dir.x, dir.z))
		var tang := b.x
		# Flying wind god on the frieze: body, head, wings and drapery.
		var fc := dir * 4.06 + Vector3(0, 7.8, 0)
		lm.beam("Marble", fc - tang * 0.55 + Vector3(0, 0.05, 0), fc + tang * 0.65 + Vector3(0, 0.15, 0), 0.38, 0.16,
			Vector3.UP)
		lm.beam("Marble", fc - tang * 0.5, fc - tang * 1.0 - Vector3(0, 0.3, 0), 0.22, 0.12, Vector3.UP)
		lm.lathe("Marble", fc + tang * 0.75 + Vector3(0, 0.25, 0), SEuUtil.dome(0.15, 0.18, 3), 8)
		lm.beam("Marble", fc + Vector3(0, 0.2, 0), fc - tang * 0.6 + Vector3(0, 0.55, 0), 0.25, 0.05, dir)
		# Lion-head spouts in the cornice and the sundial's hour lines.
		for t in [-1.0, 1.0]:
			lm.lathe("Marble", dir * 4.25 + tang * 1.0 * float(t) + Vector3(0, 8.62, 0), SEuUtil.dome(0.13, 0.15, 3), 8)
		var apex := dir * 4.04 + Vector3(0, 6.6, 0)
		for j in 7:
			var foot := dir * 4.04 + tang * (-1.5 + 0.5 * float(j)) + Vector3(0, 2.6 + absf(float(j) - 3.0) * 0.25, 0)
			lm.beam("Shadow", apex, foot, 0.05, 0.03, tang)
		lm.beam("Shadow", dir * 4.04 + tang * -1.55 + Vector3(0, 4.6, 0), dir * 4.04 + tang * 1.55 + Vector3(0, 4.6, 0),
			0.05, 0.03, tang)
		lm.beam("Honey", apex, apex + dir * 0.5 - Vector3(0, 0.2, 0), 0.04, 0.04)
	# Porches on the north-east and north-west faces.
	for a in [-PI * 0.25, -PI * 0.75]:
		var dir := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, atan2(dir.x, dir.z))
		lm.box("Marble", dir * 5.0 + Vector3(0, 0.3, 0), Vector3(3.0, 0.6, 2.2), b)
		AtUtil.doorway(lm, "Marble", "Shadow", dir * 4.04 + Vector3(0, 0.6, 0), dir, 1.3, 2.8)
		for t in [-0.95, 0.95]:
			var cb: Vector3 = dir * 5.6 + b.x * t + Vector3(0, 0.6, 0)
			AtUtil.fluted(lm, "Marble", cb, 3.0, 0.2, 0.17, 20)
			lm.lathe("Marble", cb + Vector3(0, 3.0, 0), PackedVector2Array([Vector2(0.17, 0),
				Vector2(0.22, 0.25), Vector2(0.3, 0.45)]), 12)
			for i in 8:
				var la := TAU * float(i) / 8.0
				var ld := Vector3(cos(la), 0, sin(la))
				lm.beam("Marble", cb + Vector3(0, 3.0, 0) + ld * 0.16, cb + Vector3(0, 3.42, 0) + ld * 0.28, 0.12,
					0.03, ld.cross(Vector3.UP))
			lm.box("Marble", cb + Vector3(0, 3.53, 0), Vector3(0.62, 0.14, 0.62), b, 0.0)
		var top := AtUtil.entab(lm, "Marble", "Marble", dir * 4.9 + Vector3(0, 4.2, 0), 2.6, 1.6, 0.3, 0.25, 0.2,
			b, true, true)
		lm.gable("Roof", dir * 4.9 + Vector3(0, top, 0), 2.8, 1.8, 0.65, b, 0.15, "Marble")
	# The water turret: a ruined half-round tower against the south face.
	lm.lathe("Honey", Vector3(0, 0, 4.0), PackedVector2Array([Vector2(2.6, 0), Vector2(2.6, 5.6)]), 16, 1.0, 1.0,
		0.0, true, false)
	for k in 8:
		var a := PI * float(k) / 8.0
		lm.box("Honey", Vector3(cos(a) * 2.6, 5.6 + 0.25 * float(k % 3), 4.0 + sin(a) * 2.6), Vector3(0.9, 0.5, 0.5),
			Basis(Vector3.UP, -a))
	lm.commit(model)

# --- Choragic Monument of Lysicrates -----------------------------------

## Origin at the centre of the square base. The 335 BC prize monument: a
## square limestone podium with its crowning moulding, a three-stepped
## round base, the marble cylinder ringed by six engaged Corinthian
## columns with tripods carved in the panels between their capitals,
## the architrave, the frieze of Dionysus and the pirates, the dentil
## cornice, the roof carved as one block of overlapping laurel leaves
## and the acanthus finial with its three scrolls that carried the
## bronze tripod (9.9 m).
static func lysicrates(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4D8C0", 2.0))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB892", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5A5044", 2.0))
	AtUtil.steps(lm, "Honey", Vector3(0, 0.4, 0), 3.5, 3.5, 2, 0.2, 0.3)
	lm.box("Honey", Vector3(0, 2.25, 0), Vector3(3.1, 3.7, 3.1))
	for s in [-1.0, 1.0]:
		for ax in 2:
			var o := Vector3(s, 0, 0) if ax == 0 else Vector3(0, 0, s)
			var rt := Vector3(0, 0, 1) if ax == 0 else Vector3(1, 0, 0)
			LandmarkDetail.cornice(lm, "Marble", o * 1.55 + rt * -1.6 + Vector3(0, 3.85, 0),
				o * 1.55 + rt * 1.6 + Vector3(0, 3.85, 0), o, 0.25, true)
	lm.box("Marble", Vector3(0, 4.2, 0), Vector3(3.5, 0.2, 3.5))
	for k in 3:
		lm.frustum("Marble", Vector3(0, 4.3 + 0.05 * float(k), 0), 1.65 - 0.1 * float(k), 1.65 - 0.1 * float(k), 0.05, 32)
	lm.frustum("Marble", Vector3(0, 4.45, 0), 1.25, 1.25, 3.25, 32)
	for k in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		AtUtil.corinthian(lm, "Marble", Vector3(cos(a) * 1.4, 4.45, sin(a) * 1.4), 3.25, 0.18, 24)
		# Carved tripod in the panel between this column and the next.
		var am := TAU * float(k + 1) / 6.0
		var d := Vector3(cos(am), 0, sin(am))
		var tc := d * 1.27 + Vector3(0, 7.0, 0)
		var rt := Vector3.UP.cross(d).normalized()
		for t in [-1.0, 0.0, 1.0]:
			lm.beam("Marble", tc + rt * 0.22 * float(t), tc + rt * 0.08 * float(t) + Vector3(0, 0.45, 0), 0.04,
				0.04, d)
		lm.lathe("Marble", tc + Vector3(0, 0.45, 0) + d * 0.02, PackedVector2Array([Vector2(0.08, 0),
			Vector2(0.18, 0.12), Vector2(0.2, 0.2)]), 8)
	lm.frustum("Marble", Vector3(0, 7.7, 0), 1.62, 1.62, 0.3, 32)
	lm.frustum("Marble", Vector3(0, 7.7, 0), 1.66, 1.66, 0.1, 32)
	lm.frustum("Shadow", Vector3(0, 8.0, 0), 1.5, 1.5, 0.35, 32)
	# Frieze figures: Dionysus' satyrs and the pirates turning to dolphins.
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.lathe("Marble", Vector3(cos(a) * 1.48, 8.02, sin(a) * 1.48), PackedVector2Array([Vector2(0.06, 0),
			Vector2(0.08, 0.15), Vector2(0.05, 0.25), Vector2(0.0, 0.31)]), 6)
	lm.frustum("Marble", Vector3(0, 8.35, 0), 1.8, 1.8, 0.2, 32)
	for k in 48:
		var a := TAU * float(k) / 48.0
		lm.box("Marble", Vector3(cos(a) * 1.62, 8.4, sin(a) * 1.62), Vector3(0.08, 0.1, 0.12),
			Basis(Vector3.UP, -a), 0.0)
	lm.lathe("Marble", Vector3(0, 8.55, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.55, 0.05),
		Vector2(1.25, 0.35), Vector2(0.8, 0.65), Vector2(0.4, 0.85)]), 32)
	for ring in 3:
		var rr := 1.45 - 0.33 * float(ring)
		var y := 8.62 + 0.24 * float(ring)
		for k in 16 - 3 * ring:
			var a := TAU * (float(k) + 0.5 * float(ring)) / float(16 - 3 * ring)
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Marble", d * rr + Vector3(0, y, 0), d * (rr - 0.3) + Vector3(0, y + 0.26, 0), 0.26, 0.05,
				d.cross(Vector3.UP))
	lm.lathe("Honey", Vector3(0, 9.4, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(0.5, 0.15),
		Vector2(0.28, 0.3), Vector2(0.3, 0.45), Vector2(0.0, 0.5)]), 16)
	for k in 3:
		var a := TAU * float(k) / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Honey", d * 0.25 + Vector3(0, 9.6, 0), d * 0.6 + Vector3(0, 9.8, 0), 0.08, 0.1)
		lm.beam("Honey", d * 0.6 + Vector3(0, 9.8, 0), d * 0.68 + Vector3(0, 9.65, 0), 0.08, 0.1)
	lm.commit(model)

# --- Monument of Philopappos ---------------------------------------------

## Origin at the middle of the socle, the concave facade toward -Z
## (yaw_deg onto the Acropolis). What survives of the AD 114-116 tomb of
## Gaius Julius Antiochus Philopappos (9.8 x 9.3 m): the 3.08 m socle,
## the curved front of Pentelic marble with the frieze of his consular
## procession (chariot and lictors) between pilasters, and above it the
## Corinthian pilasters framing the arched central niche with the
## seated Philopappos and the left one with Antiochus IV; only the base
## of the right niche (Seleucus I) is left, so the facade stands for
## about two thirds of its width.
static func philopappos(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E1D5BC", 2.0))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D2BE98", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5C5246", 2.0))
	AtUtil.steps(lm, "Honey", Vector3(0, 0.5, 0), 10.4, 9.3, 2, 0.25, 0.5)
	lm.box("Honey", Vector3(0, 1.79, 0), Vector3(9.8, 2.58, 9.3))
	lm.box("Marble", Vector3(0, 3.23, -0.2), Vector3(10.2, 0.3, 9.7))
	var arc := PackedVector2Array()
	for i in 21:
		var x := -4.9 + 0.49 * float(i)
		arc.append(Vector2(x, _front_z(x)))
	# Lower storey across the whole front, upper storey on the left two thirds.
	var lower: PackedVector2Array = arc.duplicate()
	lower.append(Vector2(4.9, 3.0))
	lower.append(Vector2(-4.9, 3.0))
	lm.poly_prism("Marble", lower, 3.38, 5.3)
	var upper := PackedVector2Array()
	for i in 15:
		upper.append(arc[i])
	upper.append(Vector2(arc[14].x, 3.0))
	upper.append(Vector2(-4.9, 3.0))
	lm.poly_prism("Marble", upper, 5.3, 9.0)
	# Broken edge of the lost right third.
	for k in 4:
		lm.box("Marble", Vector3(2.2 + 0.4 * float(k), 5.3 + 0.35 * float(3 - k), _front_z(2.2) + 0.8),
			Vector3(0.5, 0.7 * float(3 - k) + 0.1, 1.4))
	# Procession frieze: a chariot and lictors in relief.
	for i in 20:
		var p0 := arc[i]
		var p1 := arc[i + 1]
		lm.quad("Honey", Vector3(p0.x, 3.9, p0.y - 0.08), Vector3(p1.x, 3.9, p1.y - 0.08),
			Vector3(p1.x, 4.9, p1.y - 0.08), Vector3(p0.x, 4.9, p0.y - 0.08), Vector3(0, 0, -1))
	for i in 11:
		var x := -4.2 + 0.85 * float(i)
		if i == 5:
			lm.box("Marble", Vector3(x, 4.25, _front_z(x) - 0.2), Vector3(1.0, 0.55, 0.25))
			for s in [-1.0, 1.0]:
				lm.disc("Marble", Vector3(x + 0.3 * float(s), 4.2, _front_z(x) - 0.33), Vector3.FORWARD, 0.25, 12)
		LandmarkKits.statue_figure(lm, "Marble", Vector3(x, 3.95, _front_z(x) - 0.15), 0.9)
	LandmarkDetail.cornice(lm, "Marble", Vector3(-4.9, 4.95, _front_z(4.9) - 0.1), Vector3(4.9, 4.95,
		_front_z(4.9) - 0.1), Vector3.FORWARD, 0.3, true)
	for x in [-4.5, -1.5, 1.5, 4.5]:
		var xx: float = x
		lm.box("Honey", Vector3(xx, 4.4, _front_z(xx) - 0.12), Vector3(0.6, 1.9, 0.25))
	# Upper storey: Corinthian pilasters, niches with their statues.
	for x in [-4.5, -1.5, 1.5]:
		var xx: float = x
		var z := _front_z(xx)
		lm.box("Honey", Vector3(xx, 7.0, z - 0.17), Vector3(0.7, 3.4, 0.35))
		lm.lathe("Honey", Vector3(xx, 8.7, z - 0.17), PackedVector2Array([Vector2(0.3, 0), Vector2(0.38, 0.3),
			Vector2(0.48, 0.5)]), 8, 1.0, 0.6)
		lm.box("Honey", Vector3(xx, 9.0 - 0.17, z - 0.2), Vector3(0.95, 0.34, 0.45))
	for x in [-3.0, 0.0]:
		var xx: float = x
		var z := _front_z(xx)
		SEuUtil.opening(lm, "Shadow", Vector3(xx, 5.5, z - 0.06), Vector3(-1, 0, 0), Vector3.UP, 1.8,
			3.1 if xx == 0.0 else 2.8)
		if xx == 0.0:
			LandmarkDetail.arch(lm, "Honey", Vector3(0, 7.7, z - 0.06), Vector3.FORWARD, 1.8, 0.22, 0.15)
		else:
			lm.box("Honey", Vector3(xx, 8.4, z - 0.12), Vector3(2.1, 0.22, 0.2))
		seated(lm, Vector3(xx, 5.5, z - 0.45), 2.0)
	lm.box("Marble", Vector3(3.0, 5.6, _front_z(3.0) - 0.3), Vector3(1.8, 0.5, 0.6))
	lm.box("Marble", Vector3(-1.0, 9.2, -0.9), Vector3(8.4, 0.4, 7.8))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-4.9, 9.0, _front_z(-1.0) - 0.15), Vector3(2.0, 9.0,
		_front_z(-1.0) - 0.15), Vector3.FORWARD, 0.25, true)
	lm.commit(model)

## Seated statue `h` tall (to the top of the head) on its throne at `p`,
## facing `fwd`: throne block, thighs, robed body, head, arms on the
## knees. Shared with the Academy's Plato and Socrates.
static func seated(lm: LandmarkMesh, p: Vector3, h: float, fwd: Vector3 = Vector3.FORWARD) -> void:
	var bz := -fwd.normalized()
	var bx := Vector3.UP.cross(bz)
	var b := Basis(bx, Vector3.UP, bz)
	var T := func(x: float, y: float, z: float) -> Vector3:
		return p + bx * x + Vector3.UP * y + bz * z
	lm.box("Marble", T.call(0.0, h * 0.2, 0.1), Vector3(h * 0.45, h * 0.4, h * 0.35), b)
	lm.box("Marble", T.call(0.0, h * 0.45, 0.25), Vector3(h * 0.45, h * 0.5, h * 0.08), b)
	for s in [-1.0, 1.0]:
		var sd: float = s
		lm.beam("Marble", T.call(sd * h * 0.08, h * 0.44, 0.1), T.call(sd * h * 0.08, h * 0.44, -h * 0.17),
			h * 0.11, h * 0.1)
		lm.frustum("Marble", T.call(sd * h * 0.08, 0.0, -h * 0.17), h * 0.06, h * 0.05, h * 0.42, 8)
		lm.beam("Marble", T.call(sd * h * 0.15, h * 0.75, 0.08), T.call(sd * h * 0.12, h * 0.55, -h * 0.05),
			h * 0.06, h * 0.06)
		lm.beam("Marble", T.call(sd * h * 0.12, h * 0.55, -h * 0.05), T.call(sd * h * 0.1, h * 0.5, -h * 0.17),
			h * 0.05, h * 0.05)
	lm.lathe("Marble", T.call(0.0, h * 0.45, 0.08), PackedVector2Array([Vector2(h * 0.14, 0),
		Vector2(h * 0.13, h * 0.15), Vector2(h * 0.16, h * 0.3), Vector2(h * 0.08, h * 0.36)]), 12)
	lm.lathe("Marble", T.call(0.0, h * 0.82, 0.06), PackedVector2Array([Vector2(h * 0.04, 0),
		Vector2(h * 0.07, h * 0.04), Vector2(h * 0.075, h * 0.1), Vector2(h * 0.05, h * 0.16),
		Vector2(0.0, h * 0.18)]), 10)

## Front surface of the curved facade: the centre sits back, the ends come forward.
static func _front_z(x: float) -> float:
	return -3.6 - 1.0 * (x / 4.9) * (x / 4.9)
