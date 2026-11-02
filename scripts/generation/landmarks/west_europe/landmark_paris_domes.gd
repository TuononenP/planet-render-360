class_name LandmarkParisDomes
extends RefCounted

## The Panthéon and Les Invalides in true metres, y = 0 at street level.

## Panthéon (83 m): Soufflot's Greek-cross church (1758-1790), 110 x 84 m,
## its windows walled up in 1791 so the flanks are blind walls under a
## garland frieze and dentilled cornice; the portico of 22 fluted
## Corinthian columns (18 free, 4 engaged) with David d'Angers' pediment
## on the north (-Z) front; the drum ringed by a peristyle of 32
## Corinthian columns under a balustraded gallery, the windowed attic,
## the smooth stone dome, and the round colonnaded lantern with its
## cupola and cross over the crossing.
static func pantheon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC8B6", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#8B9296", 2.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#B9B3A6", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var c := Vector3(0, 28, 10.0)
	# Cross-plan walls (26 m), garland frieze, cornice and flat lead roofs.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 10.0, 30.0, 26.0, 90.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 10.0, 84.0, 26.0, 30.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 10.0, 31.0, 1.4, 91.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 10.0, 85.0, 1.4, 31.0)
	LandmarkWestKit.blk(lm, "Dome", 0, 27.5, 10.0, 28.0, 0.5, 88.0)
	LandmarkWestKit.blk(lm, "Dome", 0, 27.5, 10.0, 82.0, 0.5, 28.0)
	# The cross's twelve outer faces: (start, end, normal) on the plan.
	var faces := [[Vector2(-15, -35), Vector2(15, -35), Vector2(0, -1)], [Vector2(15, 55), Vector2(-15, 55), Vector2(0, 1)],
		[Vector2(-42, -5), Vector2(-42, 25), Vector2(-1, 0)], [Vector2(42, 25), Vector2(42, -5), Vector2(1, 0)],
		[Vector2(-15, -35), Vector2(-15, -5), Vector2(-1, 0)], [Vector2(15, -5), Vector2(15, -35), Vector2(1, 0)],
		[Vector2(-15, 25), Vector2(-15, 55), Vector2(-1, 0)], [Vector2(15, 55), Vector2(15, 25), Vector2(1, 0)],
		[Vector2(-42, -5), Vector2(-15, -5), Vector2(0, -1)], [Vector2(15, -5), Vector2(42, -5), Vector2(0, -1)],
		[Vector2(-15, 25), Vector2(-42, 25), Vector2(0, 1)], [Vector2(42, 25), Vector2(15, 25), Vector2(0, 1)]]
	for f in faces:
		var a2: Vector2 = f[0]
		var b2: Vector2 = f[1]
		var n2: Vector2 = f[2]
		var n := Vector3(n2.x, 0, n2.y)
		var a := Vector3(a2.x, 0, a2.y)
		var b := Vector3(b2.x, 0, b2.y)
		LandmarkDetail.cornice(lm, "Stone", a + Vector3(0, 25.0, 0), b + Vector3(0, 25.0, 0), n, 1.6)
		lm.box("Stone", (a + b) * 0.5 + Vector3(0, 22.6, 0) + n * 0.15, Vector3(a.distance_to(b) if n2.y != 0.0 else 0.3,
			2.4, 0.3 if n2.y != 0.0 else a.distance_to(b)))
		# Garlands festooned along the frieze and pilasters at the corners.
		var count := int(a.distance_to(b) / 3.0)
		for k in count:
			var p0 := a.lerp(b, float(k) / float(count)) + n * 0.4 + Vector3(0, 23.4, 0)
			var p1 := a.lerp(b, float(k + 1) / float(count)) + n * 0.4 + Vector3(0, 23.4, 0)
			var pm := (p0 + p1) * 0.5 - Vector3(0, 0.8, 0)
			lm.beam("Stone", p0, pm, 0.35, 0.3)
			lm.beam("Stone", pm, p1, 0.35, 0.3)
		for e in [a, b]:
			lm.box("Stone", e + Vector3(0, 11.0, 0) + n * 0.25 - (b - a).normalized() * 1.0 * (1.0 if e == b else -1.0),
				Vector3(2.0 if n2.y != 0.0 else 0.5, 22.0, 0.5 if n2.y != 0.0 else 2.0))
		# Blind window frames of the walled-up 1791 openings.
		var nb := int(a.distance_to(b) / 10.0)
		for k in nb:
			var p := a.lerp(b, (float(k) + 0.5) / float(nb))
			LandmarkDetail.arch(lm, "Stone", p + Vector3(0, 13.0, 0), n, 3.2, 0.45, 0.2)
	_pantheon_portico(lm)
	# Peristyle drum: 32 columns, entablature, balustrade, attic, dome.
	lm.frustum("Stone", c, 10.2, 10.2, 11.5, 32)
	lm.frustum("Stone", c, 12.4, 12.4, 0.6, 32)
	for k in 32:
		var a := TAU * float(k) / 32.0
		LandmarkWestKit.shaft(lm, "Stone", c + Vector3(cos(a), 0, sin(a)) * 11.6 + Vector3(0, 0.6, 0), 0.5, 10.9, 12)
	lm.lathe("Stone", c + Vector3(0, 11.5, 0), PackedVector2Array([Vector2(12.3, 0), Vector2(12.3, 1.2),
		Vector2(12.8, 1.5), Vector2(12.8, 1.8)]), 32)
	for k in 32:
		var a0 := TAU * float(k) / 32.0
		var a1 := TAU * float(k + 1) / 32.0
		LandmarkWestKit.rail(lm, "Stone", c + Vector3(cos(a0) * 12.5, 13.3, sin(a0) * 12.5),
			c + Vector3(cos(a1) * 12.5, 13.3, sin(a1) * 12.5), 1.1, 0.6)
	lm.frustum("Stone", c + Vector3(0, 13.3, 0), 10.6, 10.6, 4.7, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Stone", "Glass", c + d * 10.6 + Vector3(0, 15.7, 0), d, 1.2, 2.4, false, 0.2)
	lm.lathe("Stone", c + Vector3(0, 17.4, 0), PackedVector2Array([Vector2(10.6, 0), Vector2(11.0, 0.35),
		Vector2(11.1, 0.6)]), 32)
	lm.lathe("Dome", c + Vector3(0, 18.0, 0), LandmarkWestKit.dome_prof(10.6, 21.0, 14, 1.1), 32)
	# Round lantern: eight columns, cupola, cross (83 m).
	var lb := c + Vector3(0, 38.6, 0)
	lm.frustum("Stone", lb, 3.4, 3.3, 0.8, 16)
	lm.frustum("Stone", lb + Vector3(0, 0.8, 0), 2.4, 2.4, 5.7, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		LandmarkWestKit.shaft(lm, "Stone", lb + Vector3(cos(a), 0, sin(a)) * 3.0 + Vector3(0, 0.8, 0), 0.26, 5.2, 8)
	lm.frustum("Stone", lb + Vector3(0, 6.0, 0), 3.3, 3.4, 0.9, 16)
	lm.lathe("Dome", c + Vector3(0, 45.5, 0), LandmarkWestKit.dome_prof(3.0, 3.0, 6), 16)
	lm.lathe("Gilt", c + Vector3(0, 48.3, 0), LandmarkWestKit.ball(0.4), 8)
	LandmarkWestKit.cross(lm, "Gilt", c + Vector3(0, 48.0, 0), 7.0)
	lm.commit(model)

## Portico: stylobate steps, 18 free fluted Corinthian columns and 4
## engaged ones, entablature with dentils and the sculpted pediment.
static func _pantheon_portico(lm: LandmarkMesh) -> void:
	for k in 7:
		LandmarkWestKit.blk(lm, "Steps", 0, 0, -59.5 + 0.7 * float(k), 46.0 - 1.0 * float(k), 0.5 * float(k + 1), 1.0)
	LandmarkWestKit.blk(lm, "Steps", 0, 0, -46.0, 42.0, 3.5, 22.0)
	for row in 3:
		var z := -55.5 + 6.0 * float(row)
		for i in 6:
			var x := -16.0 + 6.4 * float(i)
			if row > 0 and i > 0 and i < 5 and row == 1:
				continue
			LandmarkDetail.column(lm, "Stone", Vector3(x, 3.5, z), 0.9, 19.0, "corinthian", 12)
	for x in [-9.6, -3.2, 3.2, 9.6]:
		LandmarkDetail.column(lm, "Stone", Vector3(x, 3.5, -49.5), 0.9, 19.0, "corinthian", 12)
	for x in [-16.0, -9.6, 9.6, 16.0]:
		lm.box("Stone", Vector3(x, 13.0, -35.4), Vector3(2.2, 19.0, 0.8))
	# Entablature (architrave, frieze with the dedication, cornice).
	LandmarkWestKit.blk(lm, "Stone", 0, 22.5, -46.0, 37.6, 1.6, 22.4)
	LandmarkWestKit.blk(lm, "Stone", 0, 24.1, -46.0, 37.6, 1.6, 22.4)
	lm.box("Gilt", Vector3(0, 24.9, -57.25), Vector3(20.0, 0.6, 0.08), Basis(), 0.0)
	var front := Vector3(0, 0, -1)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-18.8, 25.7, -57.2), Vector3(18.8, 25.7, -57.2), front, 1.4)
	for sx in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Stone", Vector3(sx * 18.8, 25.7, -57.2), Vector3(sx * 18.8, 25.7, -35.0),
			Vector3(sx, 0, 0), 1.4)
	lm.gable("Stone", Vector3(0, 27.1, -46.0), 38.0, 22.4, 7.0, Basis(), 0.6, "Stone")
	# Raking cornices and the pediment group (Patrie between Liberty and History).
	for sx in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(sx * 19.6, 27.3, -57.6), Vector3(0, 34.3, -57.6), 1.0, 0.9)
	for k in 13:
		var x := -12.0 + 2.0 * float(k)
		var hh := 3.6 - absf(x) * 0.22
		if hh > 0.9:
			LandmarkWestKit.figure(lm, "Stone", Vector3(x, 27.2, -56.9), hh)

## Les Invalides (107 m): Hardouin-Mansart's Dôme church (1679-1708) —
## the 60 m square body, the south front with its Doric and Corinthian
## orders and pediment; the drum with twelve windows between coupled
## columns and buttress consoles, its attic; the 12-ribbed gilded dome
## with trophies between the ribs, the lantern and its needle — then the
## Soldiers' Church behind and the Hôtel round the 102 x 64 m court of
## honour with its arcaded storeys and the 196 m north front, its
## trophy dormers and central frontispiece (north, -Z).
static func invalides(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D3C7A8", 3.5))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#59616A", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Rib", LandmarkMaterials.paint("#E6BE63", 0.3, 0.85))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Court", LandmarkMaterials.pbr("gravel", "#BDB3A0", 5.0))
	_dome_church(lm)
	_hotel(lm)
	lm.commit(model)

static func _dome_church(lm: LandmarkMesh) -> void:
	var s := Vector3(0, 0, 1)
	# Square body with corner pavilions, cornice and balustrade.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 60.0, 30.0, 60.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 30.0, 0, 62.0, 1.2, 62.0)
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		var n: Vector3 = b * s
		var r: Vector3 = b * Vector3(1, 0, 0)
		LandmarkDetail.cornice(lm, "Stone", b * Vector3(-30, 28.6, 30), b * Vector3(30, 28.6, 30), n, 1.4)
		LandmarkWestKit.rail(lm, "Stone", b * Vector3(-30.5, 31.2, 30.5), b * Vector3(30.5, 31.2, 30.5), 1.2, 0.7)
		for x in [-24.0, 24.0]:
			LandmarkDetail.window(lm, "Stone", "Glass", b * Vector3(x, 0, 30) + Vector3(0, 7.0, 0), n, 2.6, 6.5, true)
			LandmarkDetail.window(lm, "Stone", "Glass", b * Vector3(x, 0, 30) + Vector3(0, 19.0, 0), n, 2.2, 4.5, false)
			for px in [-4.0, 4.0]:
				lm.box("Stone", b * Vector3(x + px, 0, 30.3) + Vector3(0, 13.0, 0), Vector3(1.2, 26.0, 0.6), b)
		if i != 0:
			LandmarkDetail.window(lm, "Stone", "Glass", n * 30.0 + Vector3(0, 9.0, 0), n, 4.0, 9.0, true)
			lm.gable("Stone", n * 31.0 + Vector3(0, 28.6, 0) + r * 0.0, 16.0, 2.0, 3.5, b, 0.4, "Stone")
	# South front: Doric lower order, Corinthian upper order, pediment.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 31.5, 34.0, 26.0, 3.0)
	for k in 4:
		LandmarkWestKit.blk(lm, "Stone", 0, 0, 36.5 + 1.0 * float(3 - k), 40.0 - 2.0 * float(k), 0.4 * float(k + 1), 1.0)
	for x in [-13.0, -9.0, -3.0, 3.0, 9.0, 13.0]:
		LandmarkDetail.column(lm, "Stone", Vector3(x, 1.6, 34.6), 0.75, 11.0, "doric", 20)
	LandmarkWestKit.blk(lm, "Stone", 0, 12.6, 33.5, 34.0, 2.0, 3.2)
	for x in [-7.0, -3.0, 3.0, 7.0]:
		LandmarkDetail.column(lm, "Stone", Vector3(x, 14.6, 34.1), 0.6, 8.6, "corinthian", 12)
	for x in [-12.0, 12.0]:
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(x, 18.5, 33.0), s, 2.0, 4.6, true)
	LandmarkWestKit.blk(lm, "Stone", 0, 23.2, 33.0, 22.0, 1.6, 3.6)
	lm.gable("Stone", Vector3(0, 24.8, 33.0), 22.0, 3.6, 4.6, Basis(), 0.5, "Stone")
	LandmarkDetail.window(lm, "Stone", "Glass", Vector3(0, 6.0, 33.0), s, 3.6, 8.0, true)
	for k in 5:
		LandmarkWestKit.figure(lm, "Stone", Vector3(-6.0 + 3.0 * float(k), 24.8, 34.6), 2.4)
	# Drum: twelve windows between coupled columns, consoles, attic.
	var d0 := Vector3(0, 32.4, 0)
	lm.frustum("Stone", d0, 15.0, 15.0, 1.6, 32)
	lm.frustum("Stone", d0, 13.6, 13.6, 15.0, 32)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Stone", "Glass", d0 + d * 13.6 + Vector3(0, 6.5, 0), d, 2.0, 6.0, true)
		var a2 := a + PI / 12.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		var t := d2.cross(Vector3.UP)
		for sgn in [-1.0, 1.0]:
			LandmarkWestKit.shaft(lm, "Stone", d0 + d2 * 14.6 + t * 0.8 * float(sgn) + Vector3(0, 1.6, 0), 0.45, 10.6, 10)
		lm.box("Stone", d0 + d2 * 14.6 + Vector3(0, 12.9, 0), Vector3(2.8, 1.2, 1.4), Basis.looking_at(d2))
		lm.beam("Stone", d0 + d2 * 14.2 + Vector3(0, 13.5, 0), d0 + d2 * 13.7 + Vector3(0, 17.4, 0), 1.0, 0.8)
		lm.disc("Glass", d0 + Vector3(0, 15.6, 0) + d * 13.75, d, 0.8, 10)
	lm.lathe("Stone", d0 + Vector3(0, 12.2, 0), PackedVector2Array([Vector2(13.6, 0), Vector2(15.2, 0.8),
		Vector2(15.4, 1.3)]), 32)
	lm.frustum("Stone", d0 + Vector3(0, 13.5, 0), 13.7, 13.6, 1.5, 32)
	# Gilded dome with ribs and trophies between them (to 75 m).
	var db := Vector3(0, 47, 0)
	var prof := LandmarkWestKit.dome_prof(13.6, 28.0, 14, 1.1)
	lm.lathe("Gold", db, prof, 32)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var dir := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			lm.beam("Rib", db + dir * (prof[j].x + 0.2) + Vector3(0, prof[j].y, 0),
				db + dir * (prof[j + 1].x + 0.2) + Vector3(0, prof[j + 1].y, 0), 0.7, 0.45)
		var a2 := a + PI / 12.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		var tb := db + d2 * 12.4 + Vector3(0, 5.5, 0)
		lm.lathe("Rib", tb, LandmarkWestKit.ogee_prof(1.1, 3.4), 8)
		lm.box("Rib", tb + Vector3(0, -0.5, 0), Vector3(2.4, 1.0, 1.0), Basis.looking_at(d2))
		var garland := db + d2 * (LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 13.6), Vector2(14, 11.2),
			Vector2(22, 7.5)]), 15.0) + 0.3) + Vector3(0, 15.0, 0)
		lm.lathe("Rib", garland, LandmarkWestKit.ball(0.6), 6)
	# Lantern with its columns, the gilded cupola and needle (107 m).
	lm.frustum("Stone", Vector3(0, 75, 0), 4.4, 4.2, 1.0, 16)
	lm.frustum("Stone", Vector3(0, 76, 0), 3.4, 3.2, 11.0, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var t := Vector3(-sin(a), 0, cos(a))
		for sgn in [-1.0, 1.0]:
			lm.frustum("Gold", Vector3(cos(a) * 4.0, 76, sin(a) * 4.0) + t * 0.45 * float(sgn), 0.24, 0.2, 10.4, 8)
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)) * 3.35
			+ Vector3(0, 79.5, 0), Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)), 1.0, 3.6, true, 0.15)
	lm.frustum("Stone", Vector3(0, 86.4, 0), 4.4, 4.5, 0.8, 16)
	lm.lathe("Gold", Vector3(0, 87.2, 0), LandmarkWestKit.dome_prof(3.9, 5.8, 8, 1.8), 16)
	lm.lathe("Gold", Vector3(0, 93, 0), PackedVector2Array([Vector2(0.7, 0), Vector2(0.35, 5.0),
		Vector2(0.08, 14.0)]), 8)
	lm.lathe("Gold", Vector3(0, 98, 0), LandmarkWestKit.ball(0.9), 8)
	LandmarkWestKit.cross(lm, "Gold", Vector3(0, 104.0, 0), 3.0)

## Soldiers' Church and the Hôtel des Invalides round its court.
static func _hotel(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -51.0, 30.0, 22.0, 42.0)
	lm.gable("Slate", Vector3(0, 22.0, -51.0), 30.0, 42.0, 9.0, Basis(), 0.8, "Stone")
	for sx in [-1.0, 1.0]:
		for k in 5:
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(sx * 15.0, 12.0, -68.0 + 8.0 * float(k)),
				Vector3(sx, 0, 0), 2.4, 6.0, true)
	LandmarkWestKit.blk(lm, "Court", 0, 0, -145.0, 64.0, 0.3, 102.0)
	# Ranges: [cx, cz, w, d] — south, the court of honour's wings, the
	# outer wings of the side courts, the north front.
	var ranges := [[0.0, -83.0, 134.0, 22.0], [-40.0, -145.0, 16.0, 102.0], [40.0, -145.0, 16.0, 102.0],
		[-90.0, -145.0, 16.0, 102.0], [90.0, -145.0, 16.0, 102.0], [0.0, -204.0, 196.0, 16.0]]
	for r in ranges:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], 21.0, r[3])
		LandmarkWestKit.hip(lm, "Slate", Vector3(r[0], 21.0, r[1]), r[2] + 1.0, r[3] + 1.0, 6.5, 0.9)
	# North front (z = -212): pierced storeys, dormers, frontispiece.
	var nf := Vector3(0, 0, -1)
	for sx in [-1.0, 1.0]:
		var o := Vector3(sx * 98.0 if sx < 0.0 else 13.0, 0, -212.0)
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", o, Vector3(1, 0, 0), nf, 85.0, 20.0, 22, 4,
			Vector2(1.7, 2.8), 2.0, 4.8, 0.4)
		for k in 22:
			var x := o.x + 85.0 * (float(k) + 0.5) / 22.0
			LandmarkWestKit.dormer(lm, "Stone", "Slate", "Glass", Vector3(x, 21.6, -211.0), nf, 2.0, 2.6, 2.2)
		LandmarkWestKit.blk(lm, "Stone", sx * 98.5, 0, -205.0, 9.0, 23.0, 18.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(sx * 98.5, 23.0, -205.0), 10.0, 19.0, 6.0, 0.3)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -213.0, 26.0, 30.0, 6.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(0, 30.0, -213.0), 27.0, 7.0, 5.0, 0.8)
	LandmarkDetail.arch(lm, "Stone", Vector3(0, 8.0, -216.0), nf, 9.0, 1.0)
	lm.box("Glass", Vector3(0, 6.0, -216.05), Vector3(8.0, 12.0, 0.1), Basis(), 0.0)
	LandmarkWestKit.round_arch(lm, "Gold", Vector3(0, 15.5, -216.1), nf, 6.0, 0.4, 0.3, 10)
	for x in [-10.0, -7.0, 7.0, 10.0]:
		LandmarkDetail.column(lm, "Stone", Vector3(x, 0, -216.6), 0.6, 13.0, "ionic", 0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-13.0, 13.0, -216.0), Vector3(13.0, 13.0, -216.0), nf, 1.2)
	for x in [-8.5, 8.5]:
		LandmarkKits.statue_figure(lm, "Stone", Vector3(x, 14.2, -216.2), 2.6)
	# Court of honour (64 x 102 m): two-tier arcades on its four sides.
	for cr in [[Vector3(-32, 0, -94), Vector3(32, 0, -94), Vector3(0, 0, -1), 13],
			[Vector3(-32, 0, -196), Vector3(32, 0, -196), Vector3(0, 0, 1), 13],
			[Vector3(-32, 0, -94), Vector3(-32, 0, -196), Vector3(1, 0, 0), 21],
			[Vector3(32, 0, -94), Vector3(32, 0, -196), Vector3(-1, 0, 0), 21]]:
		var a: Vector3 = cr[0]
		var b: Vector3 = cr[1]
		var n: Vector3 = cr[2]
		var cnt: int = cr[3]
		var basis := Basis.looking_at(n)
		for k in cnt:
			var p := a.lerp(b, (float(k) + 0.5) / float(cnt))
			for tier in 2:
				lm.box("Glass", p + Vector3(0, 2.6 + 6.5 * float(tier), 0) + n * 0.02, Vector3(3.0, 5.0, 0.1), basis, 0.0)
				LandmarkWestKit.round_arch(lm, "Stone", p + Vector3(0, 4.0 + 6.5 * float(tier), 0), n, 3.2, 0.45, 0.4, 6)
				lm.box("Stone", p + Vector3(0, 6.5 * float(tier) + 3.0, 0) + n * 0.2 + (b - a).normalized() * 2.35,
					Vector3(0.8, 6.0, 0.4), basis, 0.0)
