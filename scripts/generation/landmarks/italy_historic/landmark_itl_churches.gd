class_name LandmarkItlChurches
extends RefCounted

## The Mole Antonelliana of Turin (Alessandro Antonelli, 1863-89) in true
## metres: an unreinforced brick and stone block under a square pavilion
## dome, a two-tier colonnaded tempietto, a round lantern and a needle
## spire of ten terraces under a twelve-pointed star.

const MOLE_HW := 21.3
const LOGGIA_Y := 28.0
const ATTIC_Y := 38.0
const CUBE_TOP := 46.0
const DOME_Y := 48.0
const TEMPLE_Y := 85.0
const SPIRE_Y := 113.0
const SPIRE_TOP := 163.5

## Origin at the centre of the block, the Via Montebello front (+Z) with
## its granite pronaos. 167.5 m: the stepped plinth and the 42.6 m block
## (giant half-columns between two storeys of windows, a loggia of twenty
## columns a side, an attic of lunettes and a heavy dentilled cornice),
## the 37 m concave pavilion dome with corner ribs, bands and dormers, the
## tempietto (two orders, six columns a side, balcony at 85 m), the round
## lantern, the octagonal spire with ten ringed terraces (the first on
## eight columns) and the 2.4 m twelve-pointed star on its rod.
static func mole_antonelliana(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#D3BE92", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EBE1C6", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("limestone", "#C2AE86", 3.0))
	lm.use("Spire", LandmarkMaterials.pbr("limestone", "#B9B8AE", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#463D33", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B7B1AA", 2.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Trim", Vector3(0, 1.0, 0), Vector3(50.0, 2.0, 50.0))
	lm.box("Trim", Vector3(0, 2.7, 0), Vector3(47.0, 1.4, 47.0))
	lm.box("Wall", Vector3(0, (3.4 + LOGGIA_Y) * 0.5, 0), Vector3(MOLE_HW * 2.0, LOGGIA_Y - 3.4, MOLE_HW * 2.0))
	lm.box("Wall", Vector3(0, (LOGGIA_Y + ATTIC_Y) * 0.5, 0), Vector3(MOLE_HW * 2.0 - 5.0, ATTIC_Y - LOGGIA_Y,
		MOLE_HW * 2.0 - 5.0))
	lm.box("Wall", Vector3(0, (ATTIC_Y + CUBE_TOP) * 0.5, 0), Vector3(MOLE_HW * 2.0, CUBE_TOP - ATTIC_Y, MOLE_HW * 2.0))
	for k in 4:
		_block_face(lm, k)
	lm.box("Trim", Vector3(0, CUBE_TOP + 1.0, 0), Vector3(MOLE_HW * 2.0 + 1.2, 2.0, MOLE_HW * 2.0 + 1.2))
	_pronaos(lm)
	_dome(lm)
	_tempietto(lm)
	_spire(lm)
	lm.commit(model)

## One face of the block (k quarter turns from +Z).
static func _block_face(lm: LandmarkMesh, k: int) -> void:
	var b := Basis(Vector3.UP, PI * 0.5 * float(k))
	var out := b * Vector3(0, 0, 1)
	var right := b * Vector3(1, 0, 0)
	var face := out * MOLE_HW
	var skin := 0.4
	# Two storeys of windows in four bays, cut through a skin.
	LandmarkDetail.pierced_face(lm, "Wall", "Shadow", face - right * (MOLE_HW - 0.6) + Vector3(0, 3.4, 0), right, out,
		MOLE_HW * 2.0 - 1.2, LOGGIA_Y - 3.4 - 0.6, 4, 2, Vector2(3.6, 7.6), 2.2, 11.6, skin)
	var fo := face + out * skin
	for i in 4:
		var s := -MOLE_HW + 0.6 + (MOLE_HW * 2.0 - 1.2) * (float(i) + 0.5) / 4.0
		for j in 2:
			var y := 3.4 + 2.2 + 11.6 * float(j) + 7.6
			LandmarkDetail.arch(lm, "Trim", fo + right * s + Vector3(0, y - 1.9, 0), out, 3.6, 0.4, 0.2)
			lm.box("Trim", fo + right * s + Vector3(0, y - 7.6 - 0.2, 0.0) + out * 0.15, Vector3(4.4, 0.35, 0.5), b)
	# Giant half-columns between the bays, string courses.
	for i in 5:
		var s := -MOLE_HW + 0.6 + (MOLE_HW * 2.0 - 1.2) * float(i) / 4.0
		if absf(s) > MOLE_HW - 1.0:
			s = signf(s) * (MOLE_HW - 1.4)
		LandmarkItlParts.column(lm, "Trim", fo + right * s + out * 0.2 + Vector3(0, 3.4, 0), 0.8, LOGGIA_Y - 3.4 - 1.4, 14)
	for y in [3.4 + 13.0, LOGGIA_Y - 1.0]:
		lm.box("Trim", fo + Vector3(0, y, 0) + out * 0.2, Vector3(MOLE_HW * 2.0 + 0.6, 0.8 if y > 20.0 else 0.6, 0.8), b)
	# Loggia: twenty columns a side in front of the recessed wall.
	for i in 20:
		var s := -MOLE_HW + 1.0 + (MOLE_HW * 2.0 - 2.0) * float(i) / 19.0
		LandmarkItlParts.column(lm, "Trim", face + right * s - out * 0.6 + Vector3(0, LOGGIA_Y, 0), 0.38,
			ATTIC_Y - LOGGIA_Y - 0.8, 10)
	lm.box("Trim", face - out * 0.6 + Vector3(0, ATTIC_Y - 0.4, 0), Vector3(MOLE_HW * 2.0, 0.8, 1.4), b)
	SEuUtil.face_row(lm, "Shadow", face + out * (-2.5 + 0.02), right, out, LOGGIA_Y + 0.5, 10, 3.9, 1.6, 7.0)
	# Attic: five lunette windows, then the dentilled main cornice.
	for i in 5:
		var s := (float(i) - 2.0) * 7.8
		LandmarkItlUtil.lunette(lm, "Shadow", face + out * 0.05 + right * s + Vector3(0, ATTIC_Y + 2.4, 0), right, 4.6)
		lm.quad("Shadow", face + out * 0.05 + right * (s - 2.3) + Vector3(0, ATTIC_Y + 1.2, 0),
			face + out * 0.05 + right * (s + 2.3) + Vector3(0, ATTIC_Y + 1.2, 0),
			face + out * 0.05 + right * (s + 2.3) + Vector3(0, ATTIC_Y + 2.45, 0),
			face + out * 0.05 + right * (s - 2.3) + Vector3(0, ATTIC_Y + 2.45, 0), out)
		LandmarkDetail.arch(lm, "Trim", face + right * s + Vector3(0, ATTIC_Y + 2.4, 0), out, 4.6, 0.45, 0.25)
		lm.box("Trim", face + right * s + Vector3(0, ATTIC_Y + 1.0, 0) + out * 0.15, Vector3(5.4, 0.4, 0.5), b)
	LandmarkDetail.cornice(lm, "Trim", face - right * (MOLE_HW + 0.6) + Vector3(0, CUBE_TOP - 1.6, 0),
		face + right * (MOLE_HW + 0.6) + Vector3(0, CUBE_TOP - 1.6, 0), out, 1.6, true)
	LandmarkItlParts.quoins(lm, "Trim", face + right * MOLE_HW + Vector3(0, 0, 0), -right, -out, 3.4, LOGGIA_Y, 1.0, 2.0,
		0.5)

## The granite pronaos on the Via Montebello front: six columns on a
## stepped podium, entablature and a balustraded terrace.
static func _pronaos(lm: LandmarkMesh) -> void:
	var z := MOLE_HW + 5.0
	var col_h := 20.0
	SEuUtil.steps_up(lm, "Trim", Vector3(0, 0, MOLE_HW + 7.0), Vector3(0, 0, 1), 28.0, 0.5, 0.42, 8)
	lm.box("Trim", Vector3(0, 1.7, MOLE_HW + 3.5), Vector3(28.0, 3.4, 7.0))
	for i in 6:
		var x := -12.5 + 5.0 * float(i)
		LandmarkDetail.column(lm, "Granite", Vector3(x, 3.4, z), 0.95, col_h, "corinthian", 0)
	var ey := 3.4 + col_h
	lm.box("Trim", Vector3(0, ey + 0.7, MOLE_HW + 3.0), Vector3(28.4, 1.4, 6.4))
	lm.box("Wall", Vector3(0, ey + 2.0, MOLE_HW + 3.0), Vector3(28.0, 1.2, 6.2))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-14.6, ey + 2.6, MOLE_HW + 6.2), Vector3(14.6, ey + 2.6, MOLE_HW + 6.2),
		Vector3(0, 0, 1), 1.1, true)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(-14.0, ey + 3.7, MOLE_HW + 6.0), Vector3(14.0, ey + 3.7, MOLE_HW + 6.0),
		1.1, 4.7)
	SEuUtil.opening(lm, "Shadow", Vector3(0, 3.4, MOLE_HW + 0.45), Vector3.RIGHT, Vector3.UP, 4.4, 9.0)

## Square pavilion dome: concave-convex four-sided shell, corner ribs,
## horizontal bands and three tiers of dormers on each face.
static func _dome(lm: LandmarkMesh) -> void:
	var tab := [[20.0, 0.0], [19.3, 3.0], [18.0, 6.0], [16.6, 10.0], [15.0, 14.0], [13.4, 18.5], [11.8, 23.0],
		[10.5, 27.0], [9.4, 31.0], [8.6, 34.0], [8.0, 37.0]]
	var dome := PackedVector2Array()
	for p in tab:
		dome.append(Vector2(float(p[0]) * sqrt(2.0), float(p[1])))
	var base := Vector3(0, DOME_Y, 0)
	lm.lathe("Dome", base, dome, 4, 1.0, 1.0, PI * 0.25, false)
	# Corner ribs.
	for k in 4:
		var d := Vector3(cos(PI * 0.25 + PI * 0.5 * float(k)), 0, sin(PI * 0.25 + PI * 0.5 * float(k)))
		for j in tab.size() - 1:
			var p0 := base + d * float(tab[j][0]) * sqrt(2.0) + Vector3(0, float(tab[j][1]), 0)
			var p1 := base + d * float(tab[j + 1][0]) * sqrt(2.0) + Vector3(0, float(tab[j + 1][1]), 0)
			lm.beam("Trim", p0 + d * 0.3, p1 + d * 0.3, 1.2, 0.7, d.cross(Vector3.UP))
	# Bands and dormers on each face.
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := b * Vector3(0, 0, 1)
		var right := b * Vector3(1, 0, 0)
		for y in [6.0, 14.0, 23.0, 31.0]:
			var hw := _dome_hw(tab, y)
			lm.box("Trim", base + out * (hw + 0.1) + Vector3(0, y, 0), Vector3(hw * 2.0, 0.5, 0.6), b, 0.0)
		var tiers := [[9.5, 3], [18.8, 3], [27.0, 1]]
		for t in tiers:
			var y: float = t[0]
			var n: int = t[1]
			var hw := _dome_hw(tab, y)
			for i in n:
				var s := (float(i) - float(n - 1) * 0.5) * hw * 0.55
				var c := base + out * hw + right * s + Vector3(0, y, 0)
				lm.box("Trim", c + Vector3(0, 1.3, 0) + out * 0.4, Vector3(2.0, 2.8, 1.6), b)
				lm.quad("Shadow", c + out * 1.22 + right * -0.6 + Vector3(0, 0.3, 0),
					c + out * 1.22 + right * 0.6 + Vector3(0, 0.3, 0), c + out * 1.22 + right * 0.6 + Vector3(0, 2.1, 0),
					c + out * 1.22 + right * -0.6 + Vector3(0, 2.1, 0), out)
				lm.gable("Dome", c + Vector3(0, 2.7, 0) + out * 0.4, 2.2, 1.8, 0.8, b, 0.1, "Trim")

## Half-width of the dome face at height y over the dome base.
static func _dome_hw(tab: Array, y: float) -> float:
	for j in tab.size() - 1:
		var y0: float = tab[j][1]
		var y1: float = tab[j + 1][1]
		if y <= y1:
			return lerpf(float(tab[j][0]), float(tab[j + 1][0]), clampf((y - y0) / (y1 - y0), 0.0, 1.0))
	return float(tab[tab.size() - 1][0])

## The tempietto: the 85 m balcony and two colonnaded tiers, six
## columns a side, then the cap and the round lantern.
static func _tempietto(lm: LandmarkMesh) -> void:
	lm.box("Trim", Vector3(0, TEMPLE_Y - 0.6, 0), Vector3(17.0, 1.2, 17.0))
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var a := b * Vector3(-8.3, TEMPLE_Y, 8.3)
		var e := b * Vector3(8.3, TEMPLE_Y, 8.3)
		LandmarkItlParts.railing(lm, "Spire", a, e, 1.1, 1.2)
	_tier(lm, TEMPLE_Y, 7.6, 5.2, 6.8, 0.5, 8.4)
	_tier(lm, TEMPLE_Y + 10.4, 6.0, 3.6, 5.0, 0.38, 6.6)
	var y := TEMPLE_Y + 10.4 + 8.6
	var cap := PackedVector2Array()
	for p in [[5.6, 0.0], [5.0, 1.0], [4.0, 2.2], [3.2, 3.2], [3.0, 3.6]]:
		cap.append(Vector2(float(p[0]) * sqrt(2.0), float(p[1])))
	lm.lathe("Dome", Vector3(0, y, 0), cap, 4, 1.0, 1.0, PI * 0.25, false)
	# Round lantern: drum with a ring of columns, terrace on top.
	var ly := y + 3.6
	var lh := SPIRE_Y - ly - 1.0
	lm.frustum("Wall", Vector3(0, ly, 0), 3.0, 2.8, lh, 16)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, ly, 0), 2.9, 16, 8, 1.0, 1.0, lh - 2.4, false)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		LandmarkItlParts.column(lm, "Trim", Vector3(cos(a) * 3.6, ly, sin(a) * 3.6), 0.26, lh, 8, false)
	lm.frustum("Trim", Vector3(0, SPIRE_Y - 1.0, 0), 4.4, 4.6, 1.0, 20)

## One tier: slab, cell, six columns a side, entablature.
static func _tier(lm: LandmarkMesh, y0: float, slab_hw: float, cell_hw: float, ring_hw: float, col_r: float,
		col_h: float) -> void:
	lm.box("Trim", Vector3(0, y0 + 0.4, 0), Vector3(slab_hw * 2.0, 0.8, slab_hw * 2.0))
	lm.box("Wall", Vector3(0, y0 + 0.8 + col_h * 0.5, 0), Vector3(cell_hw * 2.0, col_h, cell_hw * 2.0))
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := b * Vector3(0, 0, 1)
		var right := b * Vector3(1, 0, 0)
		for i in 5:
			var s := -ring_hw + 2.0 * ring_hw * float(i) / 5.0
			LandmarkItlParts.column(lm, "Trim", out * ring_hw + right * s + Vector3(0, y0 + 0.8, 0), col_r, col_h, 10)
		SEuUtil.face_row(lm, "Shadow", out * (cell_hw + 0.02), right, out, y0 + 1.6, 3, cell_hw * 0.62, 1.1,
			col_h * 0.6)
	var ey := y0 + 0.8 + col_h
	lm.box("Trim", Vector3(0, ey + 0.5, 0), Vector3(ring_hw * 2.0 + 1.4, 1.0, ring_hw * 2.0 + 1.4))
	lm.box("Trim", Vector3(0, ey + 1.15, 0), Vector3(ring_hw * 2.0 + 2.0, 0.3, ring_hw * 2.0 + 2.0))

## The octagonal needle with its ten ringed terraces, rod and star.
static func _spire(lm: LandmarkMesh) -> void:
	var h := SPIRE_TOP - SPIRE_Y
	lm.lathe("Spire", Vector3(0, SPIRE_Y, 0), PackedVector2Array([Vector2(2.6, 0), Vector2(2.2, h * 0.2),
		Vector2(1.7, h * 0.45), Vector2(1.2, h * 0.7), Vector2(0.7, h * 0.88), Vector2(0.25, h)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	for k in 10:
		var y := SPIRE_Y + 1.6 + 4.6 * float(k)
		var r := lerpf(5.0, 2.25, float(k) / 9.0)
		var c := Vector3(0, y, 0)
		lm.lathe("Spire", c - Vector3(0, 0.9, 0), PackedVector2Array([Vector2(r * 0.45, 0), Vector2(r * 0.8, 0.6),
			Vector2(r, 0.9), Vector2(r, 1.15)]), 16)
		var posts := 16 if k < 5 else 12
		for i in posts:
			var a := TAU * float(i) / float(posts)
			var p := c + Vector3(cos(a), 0, sin(a)) * r * 0.95 + Vector3(0, 0.25, 0)
			lm.beam("Spire", p, p + Vector3(0, 1.0, 0), 0.06, 0.06)
			var a1 := TAU * float(i + 1) / float(posts)
			var q := c + Vector3(cos(a1), 0, sin(a1)) * r * 0.95 + Vector3(0, 1.25, 0)
			lm.beam("Spire", p + Vector3(0, 1.0, 0), q, 0.08, 0.06)
		if k == 0:
			for i in 8:
				var a := TAU * (float(i) + 0.5) / 8.0
				LandmarkItlParts.column(lm, "Spire", c + Vector3(0, 0.25, 0) + Vector3(cos(a), 0, sin(a)) * r * 0.7,
					0.2, 3.6, 8, false)
			lm.frustum("Spire", c + Vector3(0, 3.85, 0), r * 0.8, r * 0.75, 0.4, 16)
	lm.frustum("Gold", Vector3(0, SPIRE_TOP - 0.2, 0), 0.12, 0.08, 1.8, 6)
	_star(lm, Vector3(0, 167.5 - 1.2, 0), 1.2)

## Three-dimensional twelve-pointed star: a spike toward each vertex of
## an icosahedron (one straight up) round a small ball.
static func _star(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	lm.lathe("Gold", c - Vector3(0, r * 0.25, 0), SEuUtil.dome(r * 0.25, r * 0.5, 6), 10)
	var dirs: Array[Vector3] = [Vector3.UP, Vector3.DOWN]
	var lat := atan(0.5)
	for i in 5:
		var a := TAU * float(i) / 5.0
		dirs.append(Vector3(cos(a) * cos(lat), sin(lat), sin(a) * cos(lat)))
		var b := a + TAU / 10.0
		dirs.append(Vector3(cos(b) * cos(lat), -sin(lat), sin(b) * cos(lat)))
	for d in dirs:
		var side := d.cross(Vector3.RIGHT if absf(d.x) < 0.9 else Vector3.FORWARD).normalized()
		var side2 := d.cross(side)
		var tip := c + d * r
		var ring: Array[Vector3] = []
		for k in 6:
			var a := TAU * float(k) / 6.0
			ring.append(c + d * r * 0.15 + (side * cos(a) + side2 * sin(a)) * r * 0.16)
		for k in 6:
			var p0 := ring[k]
			var p1 := ring[(k + 1) % 6]
			var nrm := ((p0 + p1) * 0.5 - c - d * r * 0.15).normalized()
			lm.tri("Gold", p0, p1, tip, nrm, nrm, d, Vector2.ZERO, Vector2(0.2, 0), Vector2(0.1, r))
