class_name StoHeroConcert
extends RefCounted

## Stockholm Concert Hall (Konserthuset, Ivar Tengbom, 1924-1926) on
## Hötorget. True metres, origin at ground level at the footprint centre,
## front toward +Z (Hötorget, WSW; the registry yaw_deg turns it onto its
## compass facing). 22.2 m to the crest of the attic.
##
## From the photos (visual-plan/refs/landmarks/stockholm_concert_hall/):
## - A plain block of rendered brick in a muted "coelin" blue (grey-blue,
##   not saturated), 48.4 x 60.2 m, a heavy projecting granite cornice at
##   20.6 m, a set-back attic over it (flat dark roof, a little taller
##   than the cornice) and short balustrade runs of five panels along the
##   front's roof edge.
## - The front is the colonnade of ten warm-grey granite Corinthian
##   columns, 18 m, on a low stylobate with broad shallow steps right
##   across the front, the plain granite entablature breaking forward over
##   them; the blue wall behind the columns carries, in nine bays, a row
##   of tall wrought-iron lattice doors (dark, in granite frames), tall
##   windows in every other bay (five) and a row of small square windows
##   under the entablature (nine). The wide corner pylons either side of
##   the colonnade are blank blue wall.
## - Carl Milles' Orpheus fountain (1936) stands left of centre at the
##   foot of the steps: Orpheus on a tall pedestal over the basin, the
##   shades round him; two tall flagpoles with gilt tridents stand on the
##   square to the right.
## - The sides: five rows of small windows with stone surrounds over granite
##   shop fronts, side doors under copper canopies; the back to Sveavägen
##   closed but for seven tall windows.
## Sources: sv.wikipedia "Konserthuset, Stockholm" (48.42 x 60.2 m, 22.2 m
## to the roof crest, ten 18 m granite columns, coelin blue, copper
## roof); OSM way 18779818 (outline) and way 163989308 (the fountain).

const TOP := 22.2
const WALL := 20.6
const X0 := -24.9
const X1 := 25.4
const Z0 := -30.5
const Z1 := 28.3
const RECESS := 26.8
const CX := 0.25
const ZF := 31.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#7A8EB4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#9AA9C6", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A39088", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#1F262B"))
	lm.use("Lattice", LandmarkMaterials.pbr("concrete", "#2A2C30", 2.0, 0.6, 0.4))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#55565A", 2.0, 0.85))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4A5C4E", 2.0, 0.42, 0.6))
	lm.use("Water", LandmarkMaterials.glass("#3A5868"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_masses(lm)
	_sides(lm)
	_colonnade(lm)
	_orpheus(lm, Vector3(CX - 12.0, 0, 41.0))
	_flagpoles(lm)
	lm.commit(model)

## The block, the corner pylons, the cornice, the set-back attic with its
## flat roof, and the balustrade runs along the front roof edge.
static func _masses(lm: LandmarkMesh) -> void:
	var cz := (Z0 + Z1) * 0.5
	var lx := X1 - X0
	LandmarkFhUtil.blk(lm, "Render", CX, 0.0, (Z0 + RECESS) * 0.5, lx, WALL, RECESS - Z0)
	for s in [-1.0, 1.0]:
		var px: float = (X1 - 3.25) if s > 0.0 else (X0 + 3.3)
		LandmarkFhUtil.blk(lm, "Render", px, 0.0, (RECESS + Z1) * 0.5, 6.5, WALL, Z1 - RECESS)
	LandmarkFhUtil.blk(lm, "Granite", CX, 0.0, cz, lx + 0.5, 0.8, Z1 - Z0 + 0.5)
	LandmarkFhParts.box_band(lm, "Trim", CX, cz, lx, Z1 - Z0, WALL - 0.9, 0.5, 0.55)
	LandmarkFhParts.box_band(lm, "Granite", CX, cz, lx, Z1 - Z0, 3.9, 0.45, 0.3)
	# The cornice and the flat roof under the attic.
	LandmarkFhUtil.blk(lm, "Granite", CX, WALL - 0.05, cz, lx - 0.4, 0.2, Z1 - Z0 - 0.4)
	LandmarkFhParts.box_band(lm, "Granite", CX, cz, lx, Z1 - Z0, WALL - 0.1, 0.25, 0.15)
	LandmarkFhUtil.blk(lm, "Roof", CX, WALL + 0.1, cz, lx - 0.8, 0.1, Z1 - Z0 - 0.8)
	# The set-back attic over the stage: blue walls, four small arched windows on the front.
	var ax := lx - 8.0
	var az0 := Z0 + 2.0
	var az1 := Z1 - 10.0
	LandmarkFhUtil.blk(lm, "Render", CX, WALL, (az0 + az1) * 0.5, ax, TOP - WALL - 0.1, az1 - az0)
	LandmarkFhUtil.blk(lm, "Roof", CX, TOP - 0.1, (az0 + az1) * 0.5, ax + 0.4, 0.2, az1 - az0 + 0.4)
	for k in 4:
		var x := CX - 9.0 + 6.0 * float(k)
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, WALL + 0.9, az1 + 0.02), Vector3.BACK, 1.2, 1.4, true, 0.2)
	# Balustrade runs along the front roof edge.
	for k in 5:
		var x0 := CX - 18.0 + 9.0 * float(k)
		LandmarkDetail.balustrade(lm, "Granite", Vector3(x0 - 2.0, WALL + 0.1, Z1 - 1.2), Vector3(x0 + 2.0, WALL + 0.1, Z1 - 1.2), 1.0, 1.3, 2)

## Side and back fronts: five rows of windows over the shop fronts on the
## sides, the side doors under copper canopies and the seven tall windows
## of the back.
static func _sides(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var x: float = X1 if s > 0.0 else X0
		var o := Vector3(s, 0, 0)
		LandmarkFhParts.pierce(lm, "Render", "Windows", Vector3(x, 0, Z0), Vector3(x, 0, Z1), o, 4.4,
			WALL - 5.5, 13, 5, Vector2(1.3, 1.9), 1.0, 3.0, 0.35)
		for k in 12:
			if k == 6:
				continue
			var z := Z0 + 2.4 + (Z1 - Z0 - 4.8) * (float(k) + 0.5) / 12.0
			var basis := Basis(Vector3.UP, s * PI * 0.5)
			lm.box("Windows", Vector3(x + s * 0.03, 2.2, z), Vector3(3.0, 2.6, 0.06), basis, 0.0)
			lm.box("Granite", Vector3(x + s * 0.1, 3.65, z), Vector3(3.5, 0.3, 0.2), basis, 0.0)
			for e in [-1.0, 1.0]:
				lm.box("Granite", Vector3(x + s * 0.1, 2.2, z + float(e) * 1.65), Vector3(0.25, 2.9, 0.2), basis, 0.0)
		# Side door and its baldachin canopy.
		var dz := Z0 + 2.4 + (Z1 - Z0 - 4.8) * 6.5 / 12.0
		lm.box("Windows", Vector3(x + s * 0.03, 1.9, dz), Vector3(0.06, 3.0, 2.4), Basis(), 0.0)
		lm.box("Copper", Vector3(x + s * 1.1, 3.6, dz), Vector3(2.2, 0.25, 3.6))
		lm.lathe("Copper", Vector3(x + s * 1.1, 3.72, dz), PackedVector2Array([Vector2(2.4, 0), Vector2(1.8, 0.6),
			Vector2(0.0, 1.1)]), 4, 0.6, 0.85, PI * 0.25, false)
		for e in [-1.0, 1.0]:
			lm.beam("Copper", Vector3(x + s * 2.1, 3.6, dz + float(e) * 1.6), Vector3(x + s * 0.1, 2.8, dz + float(e) * 1.6),
				0.1, 0.1)
	# The back to Sveavägen: seven tall windows.
	for k in 7:
		var x := CX - 15.0 + 5.0 * float(k)
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 10.6, Z0 - 0.02), Vector3(0, 0, -1), 1.8, 11.0, false, 0.25)

## The colonnade to Hötorget: ten granite Corinthian columns on the
## stylobate, the plain entablature over them, nine bays behind (lattice
## doors, tall windows in every other bay, small squares under the
## entablature), and the broad steps down to the square.
static func _colonnade(lm: LandmarkMesh) -> void:
	var zc := 29.4
	var base_y := 1.2
	var col_h := 18.0
	var x0 := CX - 16.9
	var x1 := CX + 16.9
	lm.box("Granite", Vector3(CX, base_y * 0.5, (RECESS + ZF) * 0.5), Vector3(37.4, base_y, ZF - RECESS))
	LandmarkFhUtil.steps(lm, "Granite", Vector3(CX, 0, ZF), Vector3(0, 0, 1), 37.4, 0.45, 0.2, 6)
	for i in 10:
		var x := lerpf(x0, x1, float(i) / 9.0)
		LandmarkDetail.column(lm, "Granite", Vector3(x, base_y, zc), 1.2, col_h, "corinthian", 0, 14)
	var ey := base_y + col_h
	var ez := (RECESS + ZF) * 0.5
	lm.box("Granite", Vector3(CX, ey + 0.55, ez), Vector3(38.4, 1.1, ZF - RECESS + 0.2))
	lm.box("Trim", Vector3(CX, WALL - 0.45, ez), Vector3(38.8, 0.9, ZF - RECESS + 0.6))
	lm.box("Roof", Vector3(CX, WALL + 0.1, ez), Vector3(39.0, 0.2, ZF - RECESS + 0.8))
	var z := RECESS + 0.02
	var n := Vector3(0, 0, 1)
	for i in 9:
		var x := lerpf(x0, x1, (float(i) + 0.5) / 9.0)
		# A tall lattice door in a granite frame.
		lm.box("Lattice", Vector3(x, base_y + 2.5, z + 0.04), Vector3(2.7, 5.0, 0.1), Basis(), 0.0)
		for e in [-1.0, 1.0]:
			lm.box("Granite", Vector3(x + float(e) * 1.6, base_y + 2.65, z + 0.12), Vector3(0.45, 5.3, 0.25))
		lm.box("Granite", Vector3(x, base_y + 5.2, z + 0.14), Vector3(3.7, 0.5, 0.3))
		for m in 4:
			lm.box("Granite", Vector3(x, base_y + 0.9 + 1.1 * float(m), z + 0.1), Vector3(2.7, 0.07, 0.07), Basis(), 0.0)
		# The small square window under the entablature.
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 17.9, z), n, 1.1, 1.1, false, 0.15)
		if i % 2 == 0:
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 9.7, z), n, 1.5, 3.3, false, 0.2)
	lm.box("Trim", Vector3(CX, base_y + 6.2, RECESS + 0.1), Vector3(37.0, 0.4, 0.2))

## Carl Milles' Orpheus group: a round granite basin with its water, the
## tall pedestal with Orpheus on top raising his lyre, eight shades on low
## plinths round it and the jets.
static func _orpheus(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Granite", c, 6.4, 6.2, 0.75, 24)
	lm.frustum("Water", c + Vector3(0, 0.75, 0), 5.8, 5.8, 0.02, 24)
	lm.frustum("Granite", c, 1.9, 1.7, 1.4, 12)
	lm.lathe("Granite", c + Vector3(0, 1.4, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(1.0, 0.5),
		Vector2(0.85, 4.6), Vector2(1.05, 5.0), Vector2(1.1, 5.4)]), 12)
	var ob := c + Vector3(0, 6.8, 0)
	LandmarkKits.statue_figure(lm, "Bronze", ob, 3.6, true)
	lm.box("Bronze", ob + Vector3(0.5, 3.6, 0.1), Vector3(0.5, 0.7, 0.1))
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 3.8
		lm.frustum("Granite", p, 0.5, 0.45, 0.9, 8)
		LandmarkKits.statue_figure(lm, "Bronze", p + Vector3(0, 0.9, 0), 2.3, k % 3 == 0)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 5.0 + Vector3(0, 0.77, 0)
		lm.frustum("Water", p, 0.08, 0.03, 1.6, 6)

## The two tall flagpoles on the square, each ending in a gilt trident
## (kept under the model's 22.2 m crest).
static func _flagpoles(lm: LandmarkMesh) -> void:
	for x in [CX + 11.0, CX + 19.4]:
		var p := Vector3(x, 0, 38.0)
		lm.frustum("Granite", p, 0.28, 0.2, 0.5, 8)
		lm.frustum("Lattice", p + Vector3(0, 0.5, 0), 0.1, 0.05, 20.2, 6)
		var tip := p + Vector3(0, 20.7, 0)
		lm.beam("Gilt", tip, tip + Vector3(0, 1.3, 0), 0.12, 0.12)
		for s in [-1.0, 0.0, 1.0]:
			lm.beam("Gilt", tip + Vector3(float(s) * 0.35, 0.7, 0), tip + Vector3(float(s) * 0.35, 1.4, 0), 0.07, 0.07)
		lm.beam("Gilt", tip + Vector3(-0.35, 0.7, 0), tip + Vector3(0.35, 0.7, 0), 0.07, 0.07)
