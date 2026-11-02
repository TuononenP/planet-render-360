class_name SEuRomeSacred
extends RefCounted

## St Peter's Basilica and the Pantheon in true metres.

# --- St Peter's -------------------------------------------------------

const BODY_TOP := 44.8
const DRUM_Y := 58.0
const SHELL_Y := 90.2
const LANTERN_Y := 116.2

## Origin under Michelangelo's dome (136.6 m to the cross). Facade and
## Bernini's colonnaded oval face east (+X): Maderno's 114.7 m facade
## (45.5 m to the balustrade) of eight giant Corinthian columns, the
## pediment over the central four, five portals, the Benediction Loggia
## windows, the attic and the thirteen 5.7 m statues of Christ, John the
## Baptist and eleven apostles, the two clocks; Michelangelo's apsed
## Greek cross behind with its giant pilasters and attic, the nave roof;
## the dome on its drum of sixteen buttresses with paired columns and
## sixteen pedimented windows, the sixteen-ribbed shell with three tiers
## of lucarnes, the lantern of paired columns, ball and cross; the two
## minor domes; the piazza's four-row Tuscan colonnades (284 columns,
## 140 statues), the obelisk and the two fountains.
static func peters(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6CAAE", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DDC6", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4338", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#A0A5A6", 3.0, 0.55, 0.3))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#BDB4A2", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.glass("#3A6E7A"))
	_body(lm)
	_facade(lm)
	_dome(lm)
	# Vignola's two minor domes over the Gregorian and Clementine chapels.
	for sz in [-1.0, 1.0]:
		var mc := Vector3(34.0, BODY_TOP, sz * 34.0)
		lm.box("Stone", mc + Vector3(0, 2.0, 0), Vector3(17.0, 4.0, 17.0))
		LandmarkKits.dome_on_drum(lm, "Stone", "Dome", mc + Vector3(0, 4.0, 0), 7.0, 7.0, 8.0, 5.0, 24, 8)
	_piazza(lm)
	lm.commit(model)

## Michelangelo's Greek cross with its three apses and Maderno's nave:
## giant Corinthian pilasters, two tiers of windows, the attic with its
## own windows and the roofs.
static func _body(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(41.0, BODY_TOP * 0.5, 0), Vector3(142.0, BODY_TOP, 58.0))
	lm.box("Stone", Vector3(0, BODY_TOP * 0.5, 0), Vector3(116.0, BODY_TOP, 116.0))
	lm.box("Stone", Vector3(-40.0, BODY_TOP * 0.5, 0), Vector3(40.0, BODY_TOP, 58.0))
	var apses := [Vector3(0, 0, 58.0), Vector3(0, 0, -58.0), Vector3(-60.0, 0, 0)]
	for ac in apses:
		var c: Vector3 = ac
		lm.frustum("Stone", c, 29.0, 29.0, BODY_TOP, 24)
		lm.frustum("Trim", c + Vector3(0, 32.0, 0), 29.6, 29.6, 1.4, 24)
		var away := c.normalized()
		for k in 13:
			var a := atan2(away.z, away.x) - PI * 0.5 + PI * float(k) / 12.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Trim", c + d * 29.3 + Vector3(0, 16.0, 0), Vector3(2.4, 32.0, 1.0),
				Basis(Vector3.UP, atan2(d.x, d.z)))
			if k < 12:
				var am := a + PI / 24.0
				var dm := Vector3(cos(am), 0, sin(am))
				var o := c + dm * 28.95
				SEuParts.niche(lm, "Trim", "Shadow", o + Vector3(0, 6.0, 0), dm, 2.4, 5.0, SEuParts.RECT, 0.35)
				SEuParts.niche(lm, "Trim", "Shadow", o + Vector3(0, 18.0, 0), dm, 2.6, 6.5, SEuParts.ROUND, 0.35)
				SEuParts.niche(lm, "Trim", "Shadow", o + Vector3(0, 36.5, 0), dm, 2.4, 4.0, SEuParts.RECT, 0.3)
		lm.lathe("Dome", c + Vector3(0, BODY_TOP, 0), SEuUtil.dome(27.5, 6.0, 5), 24)
	# Long walls of the nave and the cross arms: pilasters, two tiers of
	# windows, the attic windows and the main cornice.
	var runs := [[Vector3(76.0, 0, 29.0), Vector3(1, 0, 0), Vector3(0, 0, 1), 72.0],
		[Vector3(76.0, 0, -29.0), Vector3(1, 0, 0), Vector3(0, 0, -1), 72.0],
		[Vector3(40.0, 0, 43.5), Vector3(0, 0, 1), Vector3(1, 0, 0), 29.0],
		[Vector3(40.0, 0, -43.5), Vector3(0, 0, 1), Vector3(1, 0, 0), 29.0],
		[Vector3(-40.0, 0, 43.5), Vector3(0, 0, 1), Vector3(-1, 0, 0), 29.0],
		[Vector3(-40.0, 0, -43.5), Vector3(0, 0, 1), Vector3(-1, 0, 0), 29.0]]
	for run in runs:
		var c: Vector3 = run[0]
		var rt: Vector3 = run[1]
		var out: Vector3 = run[2]
		var length: float = run[3]
		var n := maxi(int(length / 9.0), 2)
		var basis := Basis(rt, Vector3.UP, out)
		for i in n + 1:
			var x := -length * 0.5 + length * float(i) / float(n)
			lm.box("Trim", c + rt * x + out * 0.5 + Vector3(0, 16.0, 0), Vector3(2.4, 32.0, 1.0), basis)
			if i < n:
				var xm := x + length * 0.5 / float(n)
				SEuParts.niche(lm, "Trim", "Shadow", c + rt * xm + Vector3(0, 6.0, 0), out, 2.4, 5.0, SEuParts.RECT, 0.35)
				SEuParts.niche(lm, "Trim", "Shadow", c + rt * xm + Vector3(0, 18.0, 0), out, 2.6, 6.5, SEuParts.ROUND, 0.35)
				SEuParts.niche(lm, "Trim", "Shadow", c + rt * xm + Vector3(0, 36.5, 0), out, 2.4, 4.0, SEuParts.RECT, 0.3)
		LandmarkDetail.cornice(lm, "Trim", c - rt * length * 0.5 + Vector3(0, 32.0, 0),
			c + rt * length * 0.5 + Vector3(0, 32.0, 0), out, 1.8, false)
		lm.box("Trim", c + Vector3(0, BODY_TOP - 0.4, 0) + out * 0.3, Vector3(length + 0.6, 0.8, 0.8), basis)
	# Nave roof (barrel vault under a lead-covered pitched roof).
	lm.gable("Dome", Vector3(78.0, BODY_TOP, 0), 30.0, 70.0, 8.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
	for s in [-1.0, 1.0]:
		lm.gable("Dome", Vector3(0, BODY_TOP, s * 42.0), 30.0, 30.0, 8.0, Basis(), 0.4, "Stone")
	lm.gable("Dome", Vector3(-40.0, BODY_TOP, 0), 30.0, 40.0, 8.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")

## Maderno's facade (x = 112..120), its stair and attic.
static func _facade(lm: LandmarkMesh) -> void:
	var fx := 120.0
	var w := 114.7
	lm.box("Stone", Vector3(116.0, 22.75, 0), Vector3(8.0, 45.5, w))
	# Projecting centre under the pediment.
	lm.box("Stone", Vector3(fx + 1.0, 22.75, 0), Vector3(2.0, 45.5, 30.0))
	var nx := Vector3(1, 0, 0)
	var zv := Vector3(0, 0, 1)
	lm.box("Trim", Vector3(fx + 1.5, 0.6, 0), Vector3(5.0, 1.2, w + 1.0))
	# Eight giant columns and the pilasters between the bays.
	var col_z := [-41.0, -29.5, -13.5, -4.5, 4.5, 13.5, 29.5, 41.0]
	for z in col_z:
		var front := absf(float(z)) < 15.0
		LandmarkDetail.column(lm, "Trim", Vector3(fx + (3.6 if front else 1.6), 1.2, float(z)), 1.4, 27.0,
			"corinthian", 0)
	for z in [-55.0, -50.0, -35.0, -21.5, 21.5, 35.0, 50.0, 55.0]:
		lm.box("Trim", Vector3(fx + 0.5, 14.1, float(z)), Vector3(1.0, 25.8, 2.8))
	# Entablature and cornice over the order, broken forward at the centre.
	lm.box("Trim", Vector3(fx + 0.4, 30.0, 0), Vector3(1.0, 4.4, w))
	lm.box("Trim", Vector3(fx + 2.6, 30.0, 0), Vector3(4.0, 4.4, 31.0))
	LandmarkDetail.cornice(lm, "Trim", Vector3(fx + 0.9, 32.2, w * 0.5), Vector3(fx + 0.9, 32.2, -w * 0.5), nx, 1.8, true)
	LandmarkDetail.cornice(lm, "Trim", Vector3(fx + 4.6, 32.2, 15.5), Vector3(fx + 4.6, 32.2, -15.5), nx, 1.8, true)
	lm.gable("Trim", Vector3(fx + 2.6, 34.0, 0), 31.0, 4.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Stone")
	lm.disc("Gold", Vector3(fx + 4.7, 36.0, 0), nx, 1.6, 16)
	# Ground storey: five portico entrances (the centre one square-headed).
	for z in [-37.0, -21.5, 0.0, 21.5, 37.0]:
		var zz: float = z
		var ff := fx + (2.0 if absf(zz) < 15.0 else 0.0)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(ff, 1.2, zz), nx, 5.6, 13.0,
			SEuParts.RECT if zz == 0.0 else SEuParts.ROUND, 0.5, 0.8, false)
		# Benediction Loggia and the windows of the upper storey.
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(ff, 17.0, zz), nx, 4.6, 8.4, SEuParts.ROUND, 0.5, 0.6)
		lm.gable("Trim", Vector3(ff + 0.5, 26.6, zz), 6.4, 1.2, 1.4, Basis(Vector3.UP, PI * 0.5), 0.0, "Trim")
	for z in [-46.0, -9.0, 9.0, 46.0]:
		var zz: float = z
		var ff := fx + (2.0 if absf(zz) < 15.0 else 0.0)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(ff, 3.0, zz), nx, 2.6, 6.0, SEuParts.RECT, 0.35)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(ff, 17.0, zz), nx, 2.6, 5.0, SEuParts.RECT, 0.35)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(ff, 11.0, zz), nx, 2.0, 4.2, SEuParts.ROUND, 0.3)
	# Attic: windows and pilasters, the balustrade and thirteen statues.
	for i in 11:
		var z := -w * 0.5 + 7.0 + (w - 14.0) * float(i) / 10.0
		var ff := fx + (2.0 if absf(z) < 15.0 else 0.0)
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(ff, 36.0, z), nx, 2.6, 3.4, SEuParts.RECT, 0.3)
	LandmarkDetail.cornice(lm, "Trim", Vector3(fx + 0.6, 43.4, w * 0.5), Vector3(fx + 0.6, 43.4, -w * 0.5), nx, 1.0, false)
	SEuParts.rail(lm, "Trim", Vector3(116.0 + 3.6, 44.4, -w * 0.5 + 1.0),
		Vector3(116.0 + 3.6, 44.4, w * 0.5 - 1.0), 1.1, 9.0)
	for i in 13:
		var z := -42.0 + 7.0 * float(i)
		lm.box("Trim", Vector3(117.0, 45.0, z), Vector3(2.0, 1.2, 2.0))
		SEuParts.figure(lm, "Trim", Vector3(117.0, 45.6, z), 5.7, i == 6, -PI * 0.5)
	# Valadier's clocks at the two ends, over the arches of the bell towers.
	for s in [-1.0, 1.0]:
		var cz: float = s * (w * 0.5 - 4.0)
		lm.box("Stone", Vector3(116.0, 49.0, cz), Vector3(8.0, 7.0, 8.0))
		lm.disc("Trim", Vector3(120.05, 49.0, cz), nx, 2.6, 20)
		lm.disc("Shadow", Vector3(120.1, 49.0, cz), nx, 2.2, 20)
		lm.lathe("Dome", Vector3(116.0, 52.5, cz), SEuUtil.dome(3.4, 2.6, 5), 16)
		SEuUtil.finial(lm, "Gold", Vector3(116.0, 55.1, cz), 1.8)
	# The sagrato stair.
	SEuUtil.steps_up(lm, "Steps", Vector3(124.0, 0, 0), Vector3.RIGHT, 100.0, 1.6, 0.18, 6)
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(130.0, 2.0, s * 51.0), Vector3(3.0, 4.0, 3.0))
		SEuParts.figure(lm, "Trim", Vector3(130.0, 4.0, s * 51.0), 5.5, s > 0.0, -PI * 0.5)

## Michelangelo's dome: plinth, drum of sixteen buttresses with paired
## columns between pedimented windows, attic, ribbed shell with three
## tiers of lucarnes, and the lantern, ball and cross.
static func _dome(lm: LandmarkMesh) -> void:
	var r := 21.8
	lm.frustum("Stone", Vector3(0, BODY_TOP, 0), 25.5, 25.5, DRUM_Y - BODY_TOP - 3.0, 32)
	lm.frustum("Trim", Vector3(0, DRUM_Y - 3.0, 0), 26.0, 25.6, 1.0, 32)
	lm.frustum("Stone", Vector3(0, DRUM_Y - 2.0, 0), 24.4, 24.4, 2.0, 32)
	lm.frustum("Stone", Vector3(0, DRUM_Y, 0), r, r, 30.0, 32)
	var col_h := 18.0
	var cy := DRUM_Y + 1.5
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var rt := Vector3.UP.cross(d)
		var basis := Basis(rt, Vector3.UP, d)
		# Buttress with two Corinthian columns side by side on its face.
		lm.box("Stone", d * (r + 1.6) + Vector3(0, cy + col_h * 0.5 - 0.75, 0), Vector3(4.6, col_h + 1.5, 3.2), basis)
		for s in [-1.0, 1.0]:
			SEuParts.col(lm, "Trim", d * (r + 3.6) + rt * 1.35 * s + Vector3(0, cy, 0), 0.75, col_h, "corinthian", 10)
		lm.box("Trim", d * (r + 2.4) + Vector3(0, cy + col_h + 1.0, 0), Vector3(5.4, 2.0, 5.0), basis)
		# Window between the buttresses, pediments alternating.
		var am := a + TAU / 32.0
		var dm := Vector3(cos(am), 0, sin(am))
		var rm := Vector3.UP.cross(dm)
		SEuParts.niche(lm, "Trim", "Shadow", dm * (r * cos(PI / 32.0)) + Vector3(0, cy + 4.0, 0), dm, 2.8, 8.6,
			SEuParts.RECT, 0.45)
		var pc := dm * (r + 0.3) + Vector3(0, cy + 13.4, 0)
		if k % 2 == 0:
			lm.gable("Trim", pc, 4.6, 0.8, 1.4, Basis(rm, Vector3.UP, dm) * Basis(Vector3.UP, PI * 0.5), 0.1, "Trim")
		else:
			SEuParts.arch_ring(lm, "Trim", pc, rm, dm, 3.8, 0.4, 0.8, false, 6)
	lm.frustum("Trim", Vector3(0, cy + col_h, 0), r + 0.6, r + 0.6, 2.0, 32)
	lm.lathe("Trim", Vector3(0, cy + col_h + 2.0, 0), PackedVector2Array([Vector2(r + 0.6, 0),
		Vector2(r + 1.4, 0.6), Vector2(r + 1.8, 1.0)]), 32, 1.0, 1.0, 0.0, true, false)
	# Attic with festoons over the buttresses.
	var at_y := cy + col_h + 3.0
	lm.frustum("Stone", Vector3(0, at_y, 0), r + 0.3, r + 0.3, SHELL_Y - at_y, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Trim", d * (r + 0.6) + Vector3(0, at_y + (SHELL_Y - at_y) * 0.5, 0), Vector3(2.2, SHELL_Y - at_y, 0.8),
			Basis(Vector3.UP.cross(d), Vector3.UP, d))
		var am := a + TAU / 32.0
		var dm := Vector3(cos(am), 0, sin(am))
		lm.disc("Trim", dm * (r + 0.5) + Vector3(0, at_y + 2.2, 0), dm, 1.0, 10)
	lm.frustum("Trim", Vector3(0, SHELL_Y - 0.6, 0), r + 1.0, r + 0.8, 0.6, 32)
	# Shell and its sixteen ribs.
	var shell := SEuUtil.ogive(r, LANTERN_Y - SHELL_Y, 14)
	lm.lathe("Dome", Vector3(0, SHELL_Y, 0), shell, 48)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in shell.size() - 2:
			lm.beam("Trim", d * (shell[j].x + 0.3) + Vector3(0, SHELL_Y + shell[j].y, 0),
				d * (shell[j + 1].x + 0.3) + Vector3(0, SHELL_Y + shell[j + 1].y, 0), 1.3, 0.9)
		# Three tiers of lucarnes between the ribs, shrinking upward.
		var am := a + TAU / 32.0
		var dm := Vector3(cos(am), 0, sin(am))
		var rm := Vector3.UP.cross(dm)
		for t in 3:
			var j := 3 + t * 3
			var p := shell[j]
			var sc := 1.0 - 0.22 * float(t)
			var base := dm * (p.x - 0.3) + Vector3(0, SHELL_Y + p.y, 0)
			lm.box("Dome", base + Vector3(0, 1.0 * sc, 0) + dm * 0.6, Vector3(2.4 * sc, 2.2 * sc, 2.0), Basis(rm, Vector3.UP, dm))
			lm.disc("Shadow", base + Vector3(0, 1.0 * sc, 0) + dm * 1.62, dm, 0.6 * sc, 10)
			lm.gable("Trim", base + Vector3(0, 2.1 * sc, 0) + dm * 0.6, 2.6 * sc, 2.2, 0.8 * sc,
				Basis(rm, Vector3.UP, dm), 0.1, "Trim")
	# Lantern: ring of sixteen paired columns round the windowed core,
	# cornice, ribbed cupola, spire, ball and cross.
	var ly := LANTERN_Y
	lm.frustum("Trim", Vector3(0, ly - 0.4, 0), 5.6, 5.4, 1.0, 24)
	lm.frustum("Stone", Vector3(0, ly + 0.6, 0), 3.6, 3.6, 8.4, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var rt := Vector3.UP.cross(d)
		lm.box("Stone", d * 4.0 + Vector3(0, ly + 4.4, 0), Vector3(1.6, 7.6, 1.6), Basis(rt, Vector3.UP, d))
		for s in [-1.0, 1.0]:
			SEuParts.col(lm, "Trim", d * 4.95 + rt * 0.55 * s + Vector3(0, ly + 0.6, 0), 0.3, 7.6, "corinthian", 8)
		var am := a + TAU / 16.0
		var dm := Vector3(cos(am), 0, sin(am))
		SEuParts.niche(lm, "Trim", "Shadow", dm * 3.5 + Vector3(0, ly + 2.0, 0), dm, 1.3, 4.6, SEuParts.ROUND, 0.25)
	lm.frustum("Trim", Vector3(0, ly + 8.2, 0), 5.5, 5.6, 1.2, 24)
	lm.lathe("Dome", Vector3(0, ly + 9.4, 0), PackedVector2Array([Vector2(4.6, 0), Vector2(4.4, 1.4),
		Vector2(3.6, 2.6), Vector2(2.2, 3.6), Vector2(1.0, 4.4), Vector2(0.6, 5.2), Vector2(0.0, 5.4)]), 24)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Trim", d * 4.7 + Vector3(0, ly + 9.4, 0), d * 2.3 + Vector3(0, ly + 13.0, 0), 0.35, 0.25)
		lm.beam("Trim", d * 2.3 + Vector3(0, ly + 13.0, 0), d * 0.7 + Vector3(0, ly + 14.6, 0), 0.3, 0.25)
	lm.frustum("Stone", Vector3(0, ly + 14.4, 0), 0.7, 0.45, 1.6, 12)
	lm.lathe("Gold", Vector3(0, ly + 16.0, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.9, 0.3),
		Vector2(1.25, 1.2), Vector2(0.9, 2.1), Vector2(0.0, 2.4)]), 16)
	var cross_y := ly + 18.4
	lm.box("Gold", Vector3(0, cross_y + (136.6 - cross_y) * 0.5, 0), Vector3(0.35, 136.6 - cross_y, 0.35))
	lm.box("Gold", Vector3(0, 136.6 - 0.9, 0), Vector3(0.35, 0.35, 1.7))

## Bernini's piazza: the oval (240 m across) closed by two curving
## colonnades four columns deep with three aisles, their entablature,
## balustrade and statues, the straight corridors back to the facade,
## the obelisk and the two fountains.
static func _piazza(lm: LandmarkMesh) -> void:
	var ex := 250.0
	var a := 96.0
	var b := 118.0
	var col_h := 13.0
	var t0 := -1.2
	var t1 := 1.35
	for sz in [-1.0, 1.0]:
		var rows := [-8.0, -3.2, 3.2, 8.0]
		for off in rows:
			var n := 36
			for k in n:
				var t := lerpf(t0, t1, (float(k) + 0.5) / float(n))
				var p := Vector3(ex + (a + float(off)) * sin(t), 0, sz * (b + float(off)) * cos(t))
				SEuParts.col(lm, "Trim", p + Vector3(0, 0.6, 0), 0.8, col_h, "tuscan", 6)
		var prev := Vector3.ZERO
		var steps := 30
		for k in steps + 1:
			var t := lerpf(t0, t1, float(k) / float(steps))
			var p := Vector3(ex + a * sin(t), 0, sz * b * cos(t))
			if k > 0:
				var dir := (p - prev).normalized()
				var side := Vector3.UP.cross(dir)
				lm.beam("Stone", prev + Vector3(0, col_h + 1.9, 0), p + Vector3(0, col_h + 1.9, 0), 19.0, 3.4, side)
				lm.beam("Trim", prev + Vector3(0, col_h + 3.9, 0), p + Vector3(0, col_h + 3.9, 0), 20.0, 0.8, side)
				lm.beam("Trim", prev + Vector3(0, col_h + 4.7, 0), p + Vector3(0, col_h + 4.7, 0), 17.6, 1.0, side)
				lm.beam("Shadow", prev + Vector3(0, 0.3, 0), p + Vector3(0, 0.3, 0), 18.8, 0.6, side)
				# Statues stand over both outer column rows.
				for s in [-1.0, 1.0]:
					var q: Vector3 = (prev + p) * 0.5 + side * 8.2 * s + Vector3(0, col_h + 5.2, 0)
					SEuParts.figure(lm, "Trim", q, 3.1, (k + int(s)) % 3 == 0)
			prev = p
		# Straight corridor (Braccio) from the facade corner to the oval:
		# a closed gallery with pilasters and windows.
		var q0 := Vector3(126.0, 0, sz * 58.0)
		var q1 := Vector3(ex + a * sin(t0), 0, sz * b * cos(t0))
		var dir := (q1 - q0).normalized()
		var side := Vector3.UP.cross(dir)
		lm.beam("Stone", q0 + Vector3(0, 9.0, 0), q1 + Vector3(0, 9.0, 0), 12.0, 18.0, side)
		lm.beam("Trim", q0 + Vector3(0, 18.4, 0), q1 + Vector3(0, 18.4, 0), 13.0, 0.8, side)
		var outs: Vector3 = side * signf(side.z) * sz
		var length := q0.distance_to(q1)
		var nb := int(length / 6.0)
		for i in nb:
			var p := q0.lerp(q1, (float(i) + 0.5) / float(nb))
			for s in [-1.0, 1.0]:
				var o: Vector3 = p + side * 6.0 * s
				var on: Vector3 = side * s
				lm.box("Trim", q0.lerp(q1, float(i) / float(nb)) + side * 6.1 * s + Vector3(0, 8.5, 0),
					Vector3(0.6, 17.0, 1.4), Basis(dir, Vector3.UP, on))
				SEuParts.niche(lm, "Trim", "Shadow", o + Vector3(0, 9.0, 0), on, 2.0, 3.6, SEuParts.RECT, 0.25)
			SEuParts.figure(lm, "Trim", p + outs * 5.0 + Vector3(0, 18.8, 0), 3.1)
	# Obelisk: stepped pedestal with the bronze lions, the 25.5 m shaft,
	# its pyramidion and the cross; 41 m in all.
	SEuParts.steps_block(lm, "Steps", Vector3(ex, 0, 0), 10.0, 10.0, 3, 0.4, 0.8)
	lm.box("Stone", Vector3(ex, 3.2, 0), Vector3(6.6, 4.0, 6.6))
	lm.box("Trim", Vector3(ex, 5.5, 0), Vector3(7.2, 0.6, 7.2))
	lm.box("Stone", Vector3(ex, 6.6, 0), Vector3(5.6, 1.6, 5.6))
	for k in 4:
		var d := Basis(Vector3.UP, PI * 0.5 * float(k)) * Vector3(1, 0, 1) * 2.6
		lm.box("Gold", Vector3(ex, 7.6, 0) + d, Vector3(1.4, 0.8, 1.4))
	lm.spire("Stone", Vector3(ex, 8.0, 0), 1.35, 25.5, 0.85)
	lm.spire("Stone", Vector3(ex, 33.5, 0), 0.85, 1.5)
	lm.lathe("Gold", Vector3(ex, 35.0, 0), SEuUtil.dome(0.8, 1.6, 5), 12)
	lm.box("Gold", Vector3(ex, 38.8, 0), Vector3(0.25, 4.4, 0.25))
	lm.box("Gold", Vector3(ex, 40.0, 0), Vector3(1.6, 0.25, 0.25))
	# Maderno's and Bernini's fountains on the oval's long axis.
	for s in [-1.0, 1.0]:
		var fc := Vector3(ex, 0, s * 60.0)
		lm.lathe("Stone", fc, PackedVector2Array([Vector2(9.0, 0), Vector2(9.0, 0.8), Vector2(8.6, 0.9),
			Vector2(8.4, 0.5)]), 32)
		lm.frustum("Water", fc + Vector3(0, 0.45, 0), 8.4, 8.4, 0.1, 32)
		lm.frustum("Stone", fc, 1.2, 0.9, 4.2, 12)
		lm.lathe("Stone", fc + Vector3(0, 4.2, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(3.4, 0.6),
			Vector2(3.6, 1.0), Vector2(3.0, 1.0)]), 24)
		lm.frustum("Stone", fc + Vector3(0, 5.0, 0), 0.6, 0.5, 2.0, 10)
		lm.lathe("Stone", fc + Vector3(0, 7.0, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(2.0, 0.5),
			Vector2(2.1, 0.8), Vector2(1.6, 0.8)]), 20)
		lm.lathe("Water", fc + Vector3(0, 7.8, 0), PackedVector2Array([Vector2(1.6, 0), Vector2(1.0, 0.8),
			Vector2(0.3, 1.6), Vector2(0.0, 1.8)]), 12)

# --- Pantheon ---------------------------------------------------------

const ROT_R := 28.0

## Origin at the centre of the rotunda; the portico faces north (-Z).
## Hadrian's rebuilding (c. 113-125): the brick-faced drum (43.3 m
## inside, walls about 6 m thick so 56 m across) in three bands marked
## by cornices, the seven step rings round the springing of the dome,
## the shallow outer dome to the open 8.9 m oculus at 43.3 m; the
## intermediate block with its second pediment, and the portico of
## sixteen monolithic unfluted granite Corinthian columns (11.9 m
## shafts, 1.5 m across) - eight across the front, then two rows of
## four behind columns 1, 3, 6 and 8 making three aisles - under the
## entablature with the M·AGRIPPA inscription and the pediment.
static func pantheon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9C6E52", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#9B9486", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C8B87", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D9CDB4", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#6C5A3C", 2.0, 0.4, 0.7))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#463F36", 3.0))
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#A78C80", 2.0))
	var r := ROT_R
	# Drum in three bands, each topped by a cornice.
	lm.frustum("Trim", Vector3.ZERO, r + 0.4, r + 0.4, 0.8, 48)
	lm.frustum("Brick", Vector3(0, 0.8, 0), r, r, 29.2, 48)
	for y in [8.6, 20.6]:
		lm.lathe("Trim", Vector3(0, float(y), 0), PackedVector2Array([Vector2(r, 0), Vector2(r + 0.35, 0.3),
			Vector2(r + 0.5, 0.7), Vector2(r + 0.7, 0.9), Vector2(r, 0.9)]), 48, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Trim", Vector3(0, 28.6, 0), PackedVector2Array([Vector2(r, 0), Vector2(r + 0.4, 0.35),
		Vector2(r + 0.9, 0.9), Vector2(r + 1.2, 1.4), Vector2(r, 1.4)]), 48, 1.0, 1.0, 0.0, true, false)
	# Relieving arches and blind windows in the brick of each band.
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		if d.z < -0.55:
			continue
		var rt := Vector3.UP.cross(d)
		SEuParts.arch_ring(lm, "Brick", d * (r - 0.05) + Vector3(0, 13.0, 0), rt, d, 6.0, 0.6, 0.25, false, 6)
		SEuParts.arch_ring(lm, "Brick", d * (r - 0.05) + Vector3(0, 23.2, 0), rt, d, 5.0, 0.55, 0.25, false, 6)
		SEuParts.niche(lm, "Brick", "Shadow", d * (r - 0.05) + Vector3(0, 21.6, 0), d, 1.6, 2.6, SEuParts.RECT, 0.2)
	# Step rings round the base of the dome, then the shallow outer dome
	# to the oculus with its bronze ring.
	var y := 30.0
	var sr := r - 0.5
	for k in 7:
		lm.frustum("Dome", Vector3(0, y, 0), sr, sr, 0.75, 48)
		lm.frustum("Dome", Vector3(0, y + 0.75, 0), sr, sr - 0.9, 0.01, 48)
		y += 0.75
		sr -= 1.1
	var dprof := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		dprof.append(Vector2(lerpf(sr + 0.3, 4.45, pow(t, 0.8)), y + (43.3 - y) * sin(t * PI * 0.5)))
	lm.lathe("Dome", Vector3.ZERO, dprof, 48, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Bronze", Vector3(0, 42.9, 0), PackedVector2Array([Vector2(4.95, 0), Vector2(4.95, 0.4),
		Vector2(4.45, 0.4), Vector2(4.45, 0.0)]), 32, 1.0, 1.0, 0.0, false, false)
	# Intermediate block between rotunda and portico, with its upper
	# (vestigial) pediment.
	var zb := -(r - 2.0)
	lm.box("Brick", Vector3(0, 13.5, zb - 4.0), Vector3(34.0, 27.0, 12.0))
	lm.box("Trim", Vector3(0, 27.4, zb - 4.0), Vector3(34.6, 0.8, 12.6))
	lm.gable("Tile", Vector3(0, 27.8, zb - 4.0), 34.0, 12.0, 6.6, Basis(), 0.4, "Brick")
	LandmarkDetail.cornice(lm, "Trim", Vector3(-17.0, 27.8, zb - 10.0), Vector3(17.0, 27.8, zb - 10.0),
		Vector3(0, 0, -1), 0.9, true)
	# Portico: podium, sixteen columns, entablature, pediment.
	var zf := zb - 10.0 - 15.5
	var pz := (zb - 10.0 + zf) * 0.5
	lm.box("Trim", Vector3(0, 0.6, pz - 1.0), Vector3(34.4, 1.2, 17.6))
	SEuUtil.steps_up(lm, "Trim", Vector3(0, 0, zf - 1.8), Vector3(0, 0, -1), 26.0, 0.45, 0.2, 5)
	var cols := PackedVector2Array()
	var xs := [-14.7, -10.5, -6.3, -2.1, 2.1, 6.3, 10.5, 14.7]
	for x in xs:
		cols.append(Vector2(float(x), zf))
	for row in 2:
		for x in [-14.7, -6.3, 6.3, 14.7]:
			cols.append(Vector2(float(x), zf + 5.1 * float(row + 1)))
	for i in cols.size():
		var c := cols[i]
		LandmarkDetail.column(lm, "Granite" if i < 8 else "Pink", Vector3(c.x, 1.2, c.y), 0.75, 14.15,
			"corinthian", 0)
	# Pilasters (antae) and the bronze doors between the inner columns.
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(s * 14.7, 8.3, zb - 10.4), Vector3(1.6, 14.2, 0.8))
		lm.box("Trim", Vector3(s * 6.3, 8.3, zb - 10.4), Vector3(1.6, 14.2, 0.8))
	SEuParts.niche(lm, "Trim", "Bronze", Vector3(0, 1.2, zb - 10.05), Vector3(0, 0, -1), 6.4, 12.0, SEuParts.RECT, 0.6, 0.8, false)
	for s in [-1.0, 1.0]:
		SEuParts.niche(lm, "Trim", "Shadow", Vector3(s * 10.5, 2.0, zb - 10.05), Vector3(0, 0, -1), 3.0, 8.0,
			SEuParts.ROUND, 0.4)
	var ey := 15.35
	lm.box("Trim", Vector3(0, ey + 0.75, pz), Vector3(32.0, 1.5, 16.0))
	lm.box("Trim", Vector3(0, ey + 2.2, pz), Vector3(32.0, 1.4, 16.0))
	# The bronze-lettered inscription panel on the frieze.
	for i in 16:
		lm.box("Bronze", Vector3(-11.0 + 22.0 * float(i) / 15.0, ey + 2.2, zf - 1.02), Vector3(0.7, 0.8, 0.06))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-16.0, ey + 2.9, zf - 1.0), Vector3(16.0, ey + 2.9, zf - 1.0),
		Vector3(0, 0, -1), 1.1, true)
	for s in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * 16.0, ey + 2.9, zf - 1.0), Vector3(s * 16.0, ey + 2.9, zb - 10.0),
			Vector3(s, 0, 0), 1.1, true)
	lm.gable("Tile", Vector3(0, ey + 4.0, pz), 32.0, 16.0, 5.6, Basis(), 0.6, "Trim")
	# Raking cornices of the pediment and the empty tympanum's eagle hole.
	for s in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(s * 16.6, ey + 4.0, zf - 1.3), Vector3(0, ey + 9.6, zf - 1.3), 0.9, 1.0)
	lm.disc("Shadow", Vector3(0, ey + 6.2, zf - 0.85), Vector3(0, 0, -1), 0.9, 12)
	lm.commit(model)
