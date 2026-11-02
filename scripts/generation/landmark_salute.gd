class_name LandmarkSalute
extends RefCounted

## Santa Maria della Salute (Longhena, 1631-1687) in true metres: the
## octagonal church in white Istrian stone on its raised platform, the
## triumphal-arch façade to the Grand Canal (+Z) with four Composite
## columns on pedestals, the great arched portal and statues over the
## broad steps; on the other faces the chapel fronts, each with paired
## pilasters, a thermal (Diocletian) window and a pediment carrying
## statues; above the attic the drum ringed by sixteen great scroll
## volutes ("orecchioni") each carrying a statue, the ribbed lead main
## dome and its colonnaded lantern with the Virgin as Capitana da Mar
## (~60 m); and behind it (−Z) the presbytery under a smaller dome with
## its lantern, flanked by the two slim campanili.

const TOP_M := 60.0
## The octagon is 47 m across its flats.
const OCT_R := 25.4
const BODY_M := 24.0
const DRUM_R := 15.0
const PLINTH_M := 1.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#ECE6DA", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F4F0E6", 2.0))
	lm.use("Lead", LandmarkMaterials.pbr("concrete", "#8A8F94", 2.0, 0.5, 0.4))
	lm.use("Windows", LandmarkMaterials.glass("#2A3338"))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#BDB6A8", 2.0))
	var oct_rot := PI / 8.0
	# Platform, octagonal body, entablature and attic.
	lm.frustum("Steps", Vector3.ZERO, OCT_R + 2.5, OCT_R + 2.5, PLINTH_M, 8, oct_rot)
	lm.frustum("Stone", Vector3(0, PLINTH_M, 0), OCT_R, OCT_R, BODY_M - PLINTH_M, 8, oct_rot)
	lm.frustum("Trim", Vector3(0, PLINTH_M, 0), OCT_R + 0.4, OCT_R + 0.35, 1.6, 8, oct_rot)
	lm.frustum("Trim", Vector3(0, BODY_M - 2.6, 0), OCT_R + 0.3, OCT_R + 0.3, 1.2, 8, oct_rot)
	lm.lathe("Trim", Vector3(0, BODY_M - 1.4, 0), PackedVector2Array([Vector2(OCT_R + 0.3, 0),
		Vector2(OCT_R + 0.6, 0.5), Vector2(OCT_R + 0.7, 0.9), Vector2(OCT_R + 1.0, 1.4)]), 8, 1.0, 1.0, oct_rot, false)
	lm.frustum("Trim", Vector3(0, BODY_M, 0), OCT_R + 1.0, OCT_R + 1.0, 0.4, 8, oct_rot)
	lm.frustum("Stone", Vector3(0, BODY_M + 0.4, 0), OCT_R - 1.5, OCT_R - 1.5, 3.6, 8, oct_rot)
	lm.frustum("Trim", Vector3(0, BODY_M + 4.0, 0), OCT_R - 1.2, OCT_R - 1.2, 0.5, 8, oct_rot)
	var apothem := OCT_R * cos(PI / 8.0)
	for f in 8:
		var a := PI * 0.25 * f + PI * 0.5
		var r := Basis(Vector3.UP, a)
		var out := r * Vector3(0, 0, 1)
		# Corner pilasters at each angle of the octagon.
		var corner := Basis(Vector3.UP, a + PI / 8.0) * Vector3(0, 0, OCT_R)
		lm.box("Trim", corner + Vector3(0, BODY_M * 0.5, 0), Vector3(2.0, BODY_M - 3.0, 2.0),
			Basis(Vector3.UP, a + PI / 8.0))
		if f == 0 or f == 4:
			continue
		_chapel_front(lm, out * apothem, r, out)
	_canal_front(lm, Vector3(0, 0, apothem))
	_drum_and_dome(lm)
	_presbytery(lm)
	lm.commit(model)

## A chapel front on one octagon face: paired Composite pilasters on
## pedestals each side, an entablature, the thermal window (a lunette
## split by two mullions) over a small arched window, a pediment with
## a statue on its apex and one at each end.
static func _chapel_front(lm: LandmarkMesh, face: Vector3, r: Basis, out: Vector3) -> void:
	for s in [-1.0, 1.0]:
		for k in 2:
			var x: float = s * (6.0 + 1.9 * k)
			lm.box("Trim", face + r * Vector3(x, PLINTH_M + 1.6, 0.5), Vector3(1.6, 3.2, 1.0), r)
			lm.box("Trim", face + r * Vector3(x, PLINTH_M + 3.2 + 7.6, 0.3), Vector3(1.2, 15.2, 0.6), r)
			lm.box("Trim", face + r * Vector3(x, PLINTH_M + 18.8, 0.4), Vector3(1.6, 1.4, 0.8), r)
	var ey := BODY_M - 4.0
	lm.box("Trim", face + r * Vector3(0, ey - 0.3, 0.5), Vector3(17.4, 0.9, 1.0), r)
	LandmarkDetail.cornice(lm, "Trim", face + r * Vector3(-8.9, ey + 0.15, 1.0), face + r * Vector3(8.9, ey + 0.15, 1.0),
		out, 0.9)
	# Thermal window: half-round head, two mullions.
	var wc := face + Vector3(0, 15.0, 0) + out * 0.05
	var wr := 3.6
	lm.disc("Windows", wc, out, wr, 16)
	LandmarkDetail.arch(lm, "Trim", wc, out, wr * 2.0, 0.7, 0.4)
	lm.box("Trim", wc + r * Vector3(0, -0.2, 0.2), Vector3(wr * 2.0 + 1.4, 0.5, 0.5), r)
	for s in [-1.0, 1.0]:
		lm.box("Trim", wc + r * Vector3(s * wr * 0.36, wr * 0.45, 0.15), Vector3(0.35, wr * 0.9, 0.3), r, 0.0)
	LandmarkDetail.window(lm, "Trim", "Windows", face + Vector3(0, 7.5, 0), out, 2.4, 5.0, true)
	lm.gable("Trim", face + Vector3(0, ey + 0.9, 0) + out * 0.5, 17.6, 1.4, 2.8, r, 0.3, "Stone")
	LandmarkKits.statue_figure(lm, "Trim", face + Vector3(0, ey + 3.7, 0) + out * 0.5, 2.2)
	for s in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Trim", face + r * Vector3(s * 8.4, ey + 0.9, 0.7), 2.0)

## Grand Canal front: a triumphal arch of four Composite columns on
## pedestals, the round-headed portal under its archivolt, niches with
## statues between the outer column pairs, the attic and pediment with
## the statue group, and the broad flight of steps down to the water.
static func _canal_front(lm: LandmarkMesh, front: Vector3) -> void:
	var f := front + Vector3(0, 0, 1.2)
	lm.box("Stone", f + Vector3(0, 12.0 + PLINTH_M * 0.5, 0), Vector3(18.0, 24.0 - PLINTH_M, 2.4))
	# Portal and archivolt.
	lm.box("Windows", f + Vector3(0, PLINTH_M + 5.0, 1.21), Vector3(5.2, 10.0, 0.1))
	lm.disc("Windows", f + Vector3(0, PLINTH_M + 10.0, 1.22), Vector3(0, 0, 1), 2.6, 16)
	LandmarkDetail.arch(lm, "Trim", f + Vector3(0, PLINTH_M + 10.0, 1.2), Vector3(0, 0, 1), 5.2, 0.8, 0.5)
	for s in [-1.0, 1.0]:
		lm.box("Trim", f + Vector3(s * 3.0, PLINTH_M + 5.0, 1.4), Vector3(0.8, 10.0, 0.5))
	# Columns on pedestals; niches with statues between the outer pairs.
	for x in [-7.6, -4.6, 4.6, 7.6]:
		var cx: float = x
		lm.box("Trim", f + Vector3(cx, PLINTH_M + 1.8, 2.2), Vector3(2.2, 3.6, 2.2))
		LandmarkDetail.column(lm, "Trim", f + Vector3(cx, PLINTH_M + 3.6, 2.2), 0.72, 14.0, "corinthian", 0)
	for s in [-1.0, 1.0]:
		var nc := f + Vector3(s * 6.1, PLINTH_M + 7.0, 1.21)
		lm.box("Windows", nc + Vector3(0, -0.6, 0), Vector3(1.6, 3.6, 0.1))
		lm.disc("Windows", nc + Vector3(0, 1.2, 0.01), Vector3(0, 0, 1), 0.8, 10)
		LandmarkKits.statue_figure(lm, "Trim", nc + Vector3(0, -2.4, 0.3), 2.6)
		lm.box("Trim", f + Vector3(s * 6.1, PLINTH_M + 12.5, 1.4), Vector3(1.8, 1.6, 0.4))
	# Entablature over the columns, attic, pediment and statues.
	var ey := PLINTH_M + 17.6
	lm.box("Trim", f + Vector3(0, ey + 0.9, 1.6), Vector3(19.0, 1.8, 3.4))
	LandmarkDetail.cornice(lm, "Trim", f + Vector3(-9.6, ey + 1.8, 3.3), f + Vector3(9.6, ey + 1.8, 3.3),
		Vector3(0, 0, 1), 1.0)
	lm.box("Stone", f + Vector3(0, ey + 3.6, 1.2), Vector3(17.0, 2.6, 2.6))
	lm.gable("Trim", f + Vector3(0, ey + 4.9, 1.4), 18.4, 3.0, 2.6, Basis(), 0.3, "Stone")
	for s in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Trim", f + Vector3(s * 8.8, ey + 4.9, 1.6), 2.4, s > 0.0)
		LandmarkKits.statue_figure(lm, "Trim", f + Vector3(s * 7.6, ey + 2.8, 3.4), 2.2)
	LandmarkKits.statue_figure(lm, "Trim", f + Vector3(0, ey + 7.5, 1.4), 2.6, true)
	# Steps down to the canal.
	for k in 6:
		lm.box("Steps", f + Vector3(0, 0.1 + 0.2 * k, 9.0 - 1.2 * k), Vector3(30.0 - k, 0.2 + 0.4 * k, 1.4))

## Drum ringed by sixteen orecchioni (spiral scrolls rising from the
## attic to the drum cornice) with statues on their feet, the drum's
## arched windows between pilasters, the ribbed lead dome, and the
## lantern: a ring of columns, a little dome, and the Virgin on top.
static func _drum_and_dome(lm: LandmarkMesh) -> void:
	var drum_y := BODY_M + 4.5
	var drum_h := 11.0
	lm.frustum("Stone", Vector3(0, drum_y, 0), DRUM_R, DRUM_R, drum_h, 32)
	lm.frustum("Trim", Vector3(0, drum_y, 0), DRUM_R + 0.4, DRUM_R + 0.3, 0.8, 32)
	for k in 16:
		var a := TAU * (k + 0.5) / 16.0
		var dir := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Windows", dir * DRUM_R + Vector3(0, drum_y + 5.4, 0), dir, 1.6, 4.0, true, 0.2)
	for k in 16:
		var a := TAU * k / 16.0
		var dir := Vector3(cos(a), 0, sin(a))
		var side := dir.cross(Vector3.UP)
		lm.box("Trim", dir * (DRUM_R + 0.25) + Vector3(0, drum_y + drum_h * 0.5, 0), Vector3(1.0, drum_h - 1.0, 0.6),
			Basis.looking_at(dir))
		_volute(lm, dir, side, drum_y)
		LandmarkKits.statue_figure(lm, "Trim", dir * (DRUM_R + 5.3) + Vector3(0, BODY_M + 4.5 + 2.3, 0), 2.0,
			k % 4 == 0)
	lm.frustum("Trim", Vector3(0, drum_y + drum_h, 0), DRUM_R + 0.6, DRUM_R + 0.8, 1.0, 32)
	# Main dome (lead) with raised ribs.
	var dome_y := drum_y + drum_h + 1.0
	lm.frustum("Stone", Vector3(0, dome_y - 0.4, 0), DRUM_R + 0.2, DRUM_R + 0.2, 1.0, 32)
	lm.lathe("Lead", Vector3(0, dome_y, 0), _dome(15.5, 10.0), 40)
	var pts := _dome(15.65, 10.1)
	for k in 16:
		var a := TAU * k / 16.0
		for j in pts.size() - 2:
			lm.beam("Lead", Vector3(cos(a) * pts[j].x, dome_y + pts[j].y, sin(a) * pts[j].x),
				Vector3(cos(a) * pts[j + 1].x, dome_y + pts[j + 1].y, sin(a) * pts[j + 1].x), 0.45, 0.3)
	# Lantern: plinth, eight column pairs round a core, cornice, cupola.
	var lan_y := dome_y + 9.6
	lm.frustum("Stone", Vector3(0, lan_y, 0), 4.0, 3.8, 1.0, 16)
	lm.frustum("Stone", Vector3(0, lan_y + 1.0, 0), 2.6, 2.6, 3.6, 8, PI / 8.0)
	for k in 8:
		var a := TAU * k / 8.0
		lm.lathe("Trim", Vector3(cos(a) * 3.3, lan_y + 1.0, sin(a) * 3.3), PackedVector2Array([
			Vector2(0.3, 0), Vector2(0.24, 0.2), Vector2(0.22, 3.3), Vector2(0.32, 3.6)]), 8)
		_dome_scroll(lm, Vector3(cos(a), 0, sin(a)), lan_y + 4.6)
	lm.frustum("Trim", Vector3(0, lan_y + 4.6, 0), 3.8, 3.9, 0.6, 16)
	lm.lathe("Lead", Vector3(0, lan_y + 5.2, 0), _dome(3.0, 1.8), 16)
	lm.lathe("Trim", Vector3(0, lan_y + 7.0, 0), PackedVector2Array([Vector2(0.6, 0), Vector2(0.4, 0.4),
		Vector2(0.55, 0.7), Vector2(0.45, 0.9)]), 10)
	LandmarkKits.statue_figure(lm, "Trim", Vector3(0, lan_y + 7.9, 0), TOP_M - lan_y - 7.9, true)

## One orecchione: a great scroll in the radial plane `dir`, its foot
## curled outward on the attic and its back sweeping up to the drum
## cornice, built as a ribbon of beams with a spiral eye at the foot.
static func _volute(lm: LandmarkMesh, dir: Vector3, side: Vector3, drum_y: float) -> void:
	var foot := dir * (DRUM_R + 5.0) + Vector3(0, BODY_M + 4.5, 0)
	var top := dir * (DRUM_R + 0.6) + Vector3(0, drum_y + 10.4, 0)
	# Back of the scroll: a concave sweep from the foot up to the drum.
	var prev := foot + Vector3(0, 2.2, 0)
	for i in range(1, 9):
		var t := float(i) / 8.0
		var p := (foot + Vector3(0, 2.2, 0)).lerp(top, t) + dir * sin(PI * t) * -1.2
		lm.beam("Trim", prev, p, 1.6, 0.9, side)
		prev = p
	# Spiral eye at the foot, unrolling outward.
	var c := foot + Vector3(0, 1.1, 0)
	var sp_prev := c + Vector3(0, 1.1, 0)
	for i in range(1, 13):
		var t := float(i) / 12.0
		var ang := PI * 0.5 + t * TAU * 1.1
		var rr := 1.1 * (1.0 - t * 0.7)
		var p := c + dir * cos(ang) * rr + Vector3(0, sin(ang) * rr, 0)
		lm.beam("Trim", sp_prev, p, 1.7, 0.35, side)
		sp_prev = p
	lm.box("Trim", foot + Vector3(0, 0.15, 0), Vector3(2.0, 0.3, 2.4), Basis.looking_at(dir))

## Little consoles from the lantern's cornice down onto the dome.
static func _dome_scroll(lm: LandmarkMesh, dir: Vector3, y: float) -> void:
	lm.beam("Trim", dir * 3.6 + Vector3(0, y - 0.4, 0), dir * 4.6 + Vector3(0, y - 3.6, 0), 0.4, 0.6)

## Presbytery: lower block with pilasters and windows, its drum, dome
## and lantern; the two campanili with belfry openings and cupolas.
static func _presbytery(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, -30.0)
	lm.box("Stone", c + Vector3(0, 11.0, 0), Vector3(30.0, 22.0, 16.0))
	lm.box("Trim", c + Vector3(0, 22.4, 0), Vector3(31.0, 0.8, 17.0))
	LandmarkDetail.cornice(lm, "Trim", c + Vector3(-15.5, 22.8, -8.5), c + Vector3(15.5, 22.8, -8.5),
		Vector3(0, 0, -1), 0.8)
	for s in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Trim", c + Vector3(s * 15.5, 22.8, -8.5), c + Vector3(s * 15.5, 22.8, 8.5),
			Vector3(s, 0, 0), 0.8)
	for k in 6:
		var x := -12.5 + 5.0 * k
		lm.box("Trim", c + Vector3(x, 11.0, -8.3), Vector3(1.0, 20.0, 0.6))
		if k < 5:
			LandmarkDetail.window(lm, "Trim", "Windows", c + Vector3(x + 2.5, 14.0, -8.0), Vector3(0, 0, -1), 1.6, 4.0, true)
	LandmarkKits.dome_on_drum(lm, "Stone", "Lead", c + Vector3(0, 23.2, 0), 8.0, 6.0, 7.0, 4.6, 32, 12)
	for s in [-1.0, 1.0]:
		var cx: float = s * 12.0
		var t := Vector3(cx, 0, -38.0)
		lm.box("Stone", t + Vector3(0, 17.0, 0), Vector3(4.6, 34.0, 4.6))
		for k in 3:
			lm.box("Trim", t + Vector3(0, 8.0 + 9.0 * k, 0), Vector3(5.0, 0.5, 5.0))
		# Belfry with an arched opening each side.
		lm.box("Stone", t + Vector3(0, 36.0, 0), Vector3(4.2, 4.0, 4.2))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			lm.box("Windows", t + r * Vector3(0, 35.6, 2.12), Vector3(1.6, 2.6, 0.1), r)
			lm.disc("Windows", t + r * Vector3(0, 36.9, 2.13), r * Vector3(0, 0, 1), 0.8, 10)
			for o in [-1.0, 1.0]:
				lm.box("Trim", t + r * Vector3(o * 1.6, 36.0, 2.2), Vector3(0.5, 4.0, 0.3), r)
		lm.box("Trim", t + Vector3(0, 38.4, 0), Vector3(5.4, 0.8, 5.4))
		lm.frustum("Stone", t + Vector3(0, 38.8, 0), 1.8, 1.8, 1.2, 8, PI / 8.0)
		lm.lathe("Lead", t + Vector3(0, 40.0, 0), _dome(2.0, 2.6), 12)
		lm.frustum("Trim", t + Vector3(0, 42.6, 0), 0.5, 0.1, 3.0, 6)

## A dome profile (radius, y): a raised half-circle of base radius r
## rising h, closed at the apex.
static func _dome(r: float, h: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 13:
		var t := PI * 0.5 * float(k) / 12.0
		pr.append(Vector2(cos(t) * r, sin(t) * h))
	pr[pr.size() - 1] = Vector2(0.0, h)
	return pr
