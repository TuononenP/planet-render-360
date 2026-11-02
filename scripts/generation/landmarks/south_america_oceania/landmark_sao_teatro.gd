class_name LandmarkSaoTeatro
extends RefCounted

## Teatro Amazonas detail, drawn into the mesh LandmarkSaoCities set up
## (material keys Wall, Trim, Base, Roof, Windows, DomeG/Y/B). Faces +Z.

const ROOF_Y := LandmarkSaoCities.OPERA_ROOF_Y
const FRONT_Z := LandmarkSaoCities.OPERA_FRONT_Z
const BACK_Z := LandmarkSaoCities.OPERA_BACK_Z
const HW := LandmarkSaoCities.OPERA_HW
const DOME_Z := LandmarkSaoCities.DOME_Z
const PODIUM_Y := LandmarkSaoCities.PODIUM_Y
const BAY := 5.0
const PORTICO_HW := 13.0
const PORTICO_D := 7.0
const STRING_Y := 10.6
const DOME_STEPS := 12
const GORES := 24

static func build(lm: LandmarkMesh) -> void:
	_mass(lm)
	_sides(lm)
	_front_wings(lm)
	_portico(lm)
	_dome(lm)

## Granite podium, rose walls, string course, cornice and the roof.
static func _mass(lm: LandmarkMesh) -> void:
	var cz := (FRONT_Z + BACK_Z) * 0.5
	var l := FRONT_Z - BACK_Z
	lm.box("Base", Vector3(0, PODIUM_Y * 0.5, cz + 1.0), Vector3(HW * 2.0 + 3.0, PODIUM_Y, l + 5.0))
	lm.box("Wall", Vector3(0, (PODIUM_Y + ROOF_Y) * 0.5, cz), Vector3(HW * 2.0, ROOF_Y - PODIUM_Y, l))
	lm.box("Trim", Vector3(0, PODIUM_Y + 0.3, cz), Vector3(HW * 2.0 + 0.5, 0.6, l + 0.5))
	lm.box("Trim", Vector3(0, STRING_Y, cz), Vector3(HW * 2.0 + 0.5, 0.5, l + 0.5))
	lm.box("Trim", Vector3(0, ROOF_Y - 0.7, cz), Vector3(HW * 2.0 + 0.3, 1.4, l + 0.3))
	for s in [-1.0, 1.0]:
		var x: float = float(s) * (HW + 0.15)
		LandmarkDetail.cornice(lm, "Trim", Vector3(x, ROOF_Y, BACK_Z - 0.15), Vector3(x, ROOF_Y, FRONT_Z + 0.15),
			Vector3(float(s), 0, 0), 1.0, false)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-HW - 0.15, ROOF_Y, BACK_Z - 0.15),
		Vector3(HW + 0.15, ROOF_Y, BACK_Z - 0.15), Vector3.FORWARD, 1.0, false)
	lm.gable("Roof", Vector3(0, ROOF_Y + 1.0, cz), HW * 2.0 - 1.0, l - 1.0, 5.0, Basis(), 0.2, "Wall")
	# Rusticated joints along the podium.
	for k in 3:
		lm.box("Base", Vector3(0, 0.7 + 0.7 * float(k), FRONT_Z + 3.52), Vector3(HW * 2.0 + 3.0, 0.08, 0.06), Basis(), 0.0)

## The long side facades: pilasters on every bay, arched windows below
## the string course and pedimented ones above.
static func _sides(lm: LandmarkMesh) -> void:
	var bays := int((FRONT_Z - BACK_Z) / BAY)
	for sv in [-1.0, 1.0]:
		var s: float = sv
		var n := Vector3(s, 0, 0)
		for k in bays + 1:
			var z := BACK_Z + (FRONT_Z - BACK_Z) * float(k) / float(bays)
			lm.box("Trim", Vector3(s * (HW + 0.15), (PODIUM_Y + ROOF_Y - 1.4) * 0.5, z),
				Vector3(0.3, ROOF_Y - 1.4 - PODIUM_Y, 0.9))
		for k in bays:
			var z := BACK_Z + (FRONT_Z - BACK_Z) * (float(k) + 0.5) / float(bays)
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(s * HW, 6.6, z), n, 1.8, 4.2, true, 0.25)
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(s * HW, 14.8, z), n, 1.7, 3.2, false, 0.25)
		# Balustrade on the cornice.
		_light_balustrade(lm, Vector3(s * (HW - 0.3), ROOF_Y + 0.2, BACK_Z + 1.0),
			Vector3(s * (HW - 0.3), ROOF_Y + 0.2, FRONT_Z - 1.0))
	var back := int(HW * 2.0 / BAY)
	for k in back:
		var x := -HW + HW * 2.0 * (float(k) + 0.5) / float(back)
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 14.8, BACK_Z), Vector3.FORWARD, 1.7, 3.2, false, 0.25)

## A lighter balustrade for the long side runs: plinth, square
## balusters, handrail and a pier every 5 m.
static func _light_balustrade(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5
	lm.box("Trim", mid + Vector3(0, 0.08, 0), Vector3(dl, 0.16, 0.36), basis, 0.0)
	lm.box("Trim", mid + Vector3(0, 0.92, 0), Vector3(dl, 0.16, 0.4), basis, 0.0)
	var n := int(dl / 0.4)
	for i in n:
		lm.box("Trim", a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, 0.5, 0), Vector3(0.14, 0.68, 0.14), basis, 0.0)
	var piers := int(dl / 5.0)
	for i in piers + 1:
		lm.box("Trim", a.lerp(b, float(i) / float(piers)) + Vector3(0, 0.55, 0), Vector3(0.5, 1.1, 0.5), basis, 0.0)

## The front either side of the portico: quoined corners, two bays of
## windows each and a balustrade.
static func _front_wings(lm: LandmarkMesh) -> void:
	var n := Vector3.BACK
	for sv in [-1.0, 1.0]:
		var s: float = sv
		for x in [PORTICO_HW + 0.6, HW - 0.6]:
			lm.box("Trim", Vector3(s * float(x), (PODIUM_Y + ROOF_Y - 1.4) * 0.5, FRONT_Z + 0.2),
				Vector3(1.2, ROOF_Y - 1.4 - PODIUM_Y, 0.4))
			for k in 9:
				lm.box("Trim", Vector3(s * float(x), PODIUM_Y + 0.9 + 1.8 * float(k), FRONT_Z + 0.42),
					Vector3(1.5, 0.7, 0.12), Basis(), 0.0)
		for k in 2:
			var x: float = s * lerpf(PORTICO_HW + 3.6, HW - 3.6, float(k))
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 6.6, FRONT_Z), n, 1.9, 4.2, true, 0.3)
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 14.8, FRONT_Z), n, 1.8, 3.4, false, 0.3)
		LandmarkDetail.cornice(lm, "Trim", Vector3(s * (PORTICO_HW + 1.2), ROOF_Y, FRONT_Z + 0.15),
			Vector3(s * (HW + 0.15), ROOF_Y, FRONT_Z + 0.15), n, 1.0, true)
		LandmarkDetail.balustrade(lm, "Trim", Vector3(s * (PORTICO_HW + 1.2), ROOF_Y + 1.0, FRONT_Z),
			Vector3(s * (HW - 0.5), ROOF_Y + 1.0, FRONT_Z), 1.0, 4.0)

## The projecting portico: steps, a ground arcade of five arches, the
## loggia of paired Corinthian columns with its balustrade, the
## entablature and the curved pediment.
static func _portico(lm: LandmarkMesh) -> void:
	var z0 := FRONT_Z
	var z1 := FRONT_Z + PORTICO_D
	var n := Vector3.BACK
	# Steps from the square up to the podium.
	for k in 8:
		var depth := 0.4 * float(8 - k)
		lm.box("Base", Vector3(0, PODIUM_Y * (float(k) + 0.5) / 8.0, z1 + depth * 0.5),
			Vector3(PORTICO_HW * 2.0 + 4.0 - 0.6 * float(k), PODIUM_Y / 8.0, depth), Basis(), 0.0)
	# Ground arcade: six piers, five arches over a dark loggia.
	var span := (PORTICO_HW * 2.0 - 6.0 * 1.6) / 5.0
	var spring := PODIUM_Y + 4.6
	lm.box("Windows", Vector3(0, (PODIUM_Y + STRING_Y) * 0.5, z1 - 3.0), Vector3(PORTICO_HW * 2.0 - 1.0, STRING_Y - PODIUM_Y, 0.2), Basis(), 0.0)
	for k in 6:
		var x := -PORTICO_HW + 0.8 + (span + 1.6) * float(k)
		lm.box("Trim", Vector3(x, (PODIUM_Y + STRING_Y) * 0.5, (z0 + z1) * 0.5), Vector3(1.6, STRING_Y - PODIUM_Y, PORTICO_D))
		lm.box("Trim", Vector3(x, spring - 0.2, z1 + 0.1), Vector3(2.0, 0.4, 0.4))
	for k in 5:
		var x := -PORTICO_HW + 1.6 + span * 0.5 + (span + 1.6) * float(k)
		LandmarkDetail.arch(lm, "Trim", Vector3(x, spring, z1), n, span, 0.6, 0.4)
		# Spandrel wall above each arch.
		for s in [-1.0, 1.0]:
			lm.box("Trim", Vector3(x + float(s) * span * 0.38, STRING_Y - 1.2, z1 - 0.2), Vector3(span * 0.25, 2.0, 0.4))
		lm.box("Trim", Vector3(x, STRING_Y - 0.5, z1 - 0.2), Vector3(span, 0.6, 0.4))
	# Loggia floor, balustrade and the colonnade above.
	lm.box("Trim", Vector3(0, STRING_Y + 0.1, (z0 + z1) * 0.5), Vector3(PORTICO_HW * 2.0 + 0.6, 0.8, PORTICO_D + 0.6))
	var col_h := 7.6
	var col_y := STRING_Y + 0.5
	for k in 6:
		var x := -PORTICO_HW + 0.8 + (span + 1.6) * float(k)
		for d in [-0.55, 0.55]:
			LandmarkDetail.column(lm, "Trim", Vector3(x + float(d), col_y, z1 - 0.6), 0.36, col_h, "corinthian", 12)
		# Pilaster on the wall behind.
		lm.box("Trim", Vector3(x, col_y + col_h * 0.5, z0 + 0.2), Vector3(1.0, col_h, 0.4))
	for k in 5:
		var x := -PORTICO_HW + 1.6 + span * 0.5 + (span + 1.6) * float(k)
		LandmarkDetail.balustrade(lm, "Trim", Vector3(x - span * 0.5, col_y, z1 - 0.6), Vector3(x + span * 0.5, col_y, z1 - 0.6), 1.0, 4.0)
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, col_y + 2.6, z0), n, 2.0, 5.2, true, 0.3)
	# Entablature, cornice and the segmental pediment.
	var ent_y := col_y + col_h
	lm.box("Trim", Vector3(0, ent_y + 0.6, (z0 + z1) * 0.5 - 0.3), Vector3(PORTICO_HW * 2.0 + 1.0, 1.2, PORTICO_D + 0.2))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-PORTICO_HW - 0.5, ent_y + 1.2, z1 - 0.2),
		Vector3(PORTICO_HW + 0.5, ent_y + 1.2, z1 - 0.2), n, 0.9, true)
	segment(lm, "Wall", Vector3(0, ent_y + 2.1, z1 - 1.0), PORTICO_HW * 2.0 - 4.0, 3.4, 1.0)
	segment(lm, "Trim", Vector3(0, ent_y + 2.1, z1 - 0.7), PORTICO_HW * 2.0 - 2.0, 4.0, 0.5)
	# Tympanum cartouche and the urns along the cornice.
	lm.disc("Trim", Vector3(0, ent_y + 3.6, z1 - 0.48), n, 1.1, 16)
	for k in 6:
		var x := -PORTICO_HW + 0.8 + (span + 1.6) * float(k)
		if absf(x) < PORTICO_HW - 4.0:
			continue
		lm.lathe("Trim", Vector3(x, ent_y + 2.1, z1 - 0.6), PackedVector2Array([Vector2(0.4, 0.0),
			Vector2(0.25, 0.3), Vector2(0.5, 0.9), Vector2(0.2, 1.4), Vector2(0.0, 1.7)]), 10)

## Segmental (curved) pediment of chord w and rise h, centred on `c`
## (chord midpoint, face line), `depth` deep, facing +Z.
static func segment(lm: LandmarkMesh, key: String, c: Vector3, w: float, h: float, depth: float) -> void:
	var r := (w * w * 0.25 + h * h) / (2.0 * h)
	var cy := h - r
	var a0 := asin(w * 0.5 / r)
	var steps := 14
	var prev := Vector3.ZERO
	for i in steps + 1:
		var a := lerpf(-a0, a0, float(i) / float(steps))
		var p := c + Vector3(r * sin(a), cy + r * cos(a), 0)
		if i > 0:
			for f in [0.0, -depth]:
				var off := Vector3(0, 0, float(f))
				lm.tri(key, c + off, prev + off, p + off, Vector3(0, 0, 1.0 if f == 0.0 else -1.0),
					Vector3(0, 0, 1.0 if f == 0.0 else -1.0), Vector3(0, 0, 1.0 if f == 0.0 else -1.0),
					Vector2(c.x, c.y), Vector2(prev.x, prev.y), Vector2(p.x, p.y))
			var up := ((prev + p) * 0.5 - (c + Vector3(0, cy, 0))).normalized()
			lm.quad(key, prev, p, p - Vector3(0, 0, depth), prev - Vector3(0, 0, depth), up)
		prev = p
	lm.quad(key, c - Vector3(w * 0.5, 0, 0), c + Vector3(w * 0.5, 0, 0), c + Vector3(w * 0.5, 0, -depth),
		c + Vector3(-w * 0.5, 0, -depth), Vector3.DOWN)

## Drum with oculi and pilasters, the dome in green and yellow scales
## with a blue crown band and gilt ribs, and the lantern to 36 m.
static func _dome(lm: LandmarkMesh) -> void:
	var base := Vector3(0, ROOF_Y, DOME_Z)
	lm.frustum("Wall", base, 10.5, 10.5, 6.0, 40)
	lm.frustum("Trim", base, 10.9, 10.8, 0.8, 40)
	lm.lathe("Trim", base + Vector3(0, 5.6, 0), PackedVector2Array([Vector2(10.5, 0.0), Vector2(10.9, 0.3),
		Vector2(11.1, 0.9)]), 40)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Trim", base + d * 10.6 + Vector3(0, 3.2, 0), Vector3(0.7, 4.6, 0.3), Basis.looking_at(d))
		var b := TAU * (float(i) + 0.5) / 16.0
		var e := Vector3(cos(b), 0, sin(b))
		lm.disc("Windows", base + e * 10.52 + Vector3(0, 3.3, 0), e, 0.8, 12)
	var shell := base + Vector3(0, 6.5, 0)
	for g in GORES:
		var a0 := TAU * float(g) / float(GORES)
		var a1 := TAU * float(g + 1) / float(GORES)
		for i in DOME_STEPS:
			var key := "DomeB"
			if i < 8:
				var band := 0 if i < 4 else 1
				key = "DomeG" if (g + band) % 2 == 0 else "DomeY"
			var t0 := PI * 0.5 * float(i) / float(DOME_STEPS)
			var t1 := PI * 0.5 * float(i + 1) / float(DOME_STEPS)
			var p00 := shell + Vector3(cos(a0) * 10.3 * cos(t0), 7.2 * sin(t0), sin(a0) * 10.3 * cos(t0))
			var p10 := shell + Vector3(cos(a1) * 10.3 * cos(t0), 7.2 * sin(t0), sin(a1) * 10.3 * cos(t0))
			var p01 := shell + Vector3(cos(a0) * 10.3 * cos(t1), 7.2 * sin(t1), sin(a0) * 10.3 * cos(t1))
			var p11 := shell + Vector3(cos(a1) * 10.3 * cos(t1), 7.2 * sin(t1), sin(a1) * 10.3 * cos(t1))
			var n0 := Vector3(cos(a0) * cos(t0) / 10.3, sin(t0) / 7.2, sin(a0) * cos(t0) / 10.3).normalized()
			var n1 := Vector3(cos(a1) * cos(t0) / 10.3, sin(t0) / 7.2, sin(a1) * cos(t0) / 10.3).normalized()
			var n2 := Vector3(cos(a1) * cos(t1) / 10.3, sin(t1) / 7.2, sin(a1) * cos(t1) / 10.3).normalized()
			var n3 := Vector3(cos(a0) * cos(t1) / 10.3, sin(t1) / 7.2, sin(a0) * cos(t1) / 10.3).normalized()
			lm.tri(key, p00, p10, p11, n0, n1, n2, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
			lm.tri(key, p00, p11, p01, n0, n2, n3, Vector2(0, 0), Vector2(1, 1), Vector2(0, 1))
	# Gilt ribs over the gore seams.
	for g in 12:
		var a := TAU * float(g) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := shell + d * 10.4
		for i in range(1, DOME_STEPS):
			var t := PI * 0.5 * float(i) / float(DOME_STEPS)
			var p := shell + d * 10.4 * cos(t) + Vector3(0, 7.3 * sin(t), 0)
			lm.beam("Trim", prev, p, 0.3, 0.2, d.cross(Vector3.UP))
			prev = p
	var top := base + Vector3(0, 13.7, 0)
	lm.frustum("Trim", top - Vector3(0, 0.3, 0), 2.0, 1.9, 0.5, 16)
	lm.frustum("Windows", top, 1.4, 1.4, 1.2, 12)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.frustum("Trim", top + Vector3(cos(a) * 1.6, 0, sin(a) * 1.6), 0.16, 0.14, 1.2, 6)
	lm.frustum("Trim", top + Vector3(0, 1.2, 0), 1.9, 1.5, 0.3, 16)
	lm.lathe("DomeY", top + Vector3(0, 1.5, 0), PackedVector2Array([Vector2(1.4, 0.0), Vector2(1.1, 0.25),
		Vector2(0.4, 0.45), Vector2(0.15, 0.6), Vector2(0.05, 1.0), Vector2(0.0, 1.0)]), 12)
