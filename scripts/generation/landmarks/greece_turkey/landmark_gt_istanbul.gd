class_name LandmarkGtIstanbul
extends RefCounted

## Two imperial Ottoman complexes of Istanbul in true metres: the Topkapi
## Palace and Sinan's Suleymaniye Mosque.

# --- Suleymaniye -------------------------------------------------------------

const SULEY_TOP := 76.0

## Suleymaniye Mosque, origin under the great dome, courtyard to -Z and
## prayer hall to +Z: the 58 x 57 m hall with its 26.5 m dome rising to
## 53 m on a square of tympana, the semi-domes before and behind, the
## four weight turrets, five alternating domes down each aisle, the
## 47 x 57 m courtyard with its domed arcade and ablution fountain, and
## four minarets: two of 76 m (three balconies) beside the hall and two
## lower ones at the far courtyard corners.
static func suleymaniye(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#CFC6B1", 4.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#E1D9C6", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#767D84", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#B9B1A0", 4.0))
	# Prayer hall with its cornice, the central square and the semi-domes.
	LandmarkGtUtil.block(lm, "Wall", -29.0, 29.0, 0.0, 24.0, -28.5, 28.5)
	LandmarkGtUtil.block(lm, "Pale", -29.4, 29.4, 24.0, 24.8, -28.9, 28.9)
	LandmarkGtUtil.block(lm, "Wall", -13.25, 13.25, 24.8, 36.5, -13.25, 13.25)
	for end in [-1.0, 1.0]:
		var z0: float = minf(end * 13.25, end * 26.5)
		var z1: float = maxf(end * 13.25, end * 26.5)
		LandmarkGtUtil.block(lm, "Wall", -13.25, 13.25, 24.8, 28.5, z0, z1)
		LandmarkGtUtil.half_dome(lm, "Lead", Vector3(0, 28.5, end * 13.25), 13.25, 11.5, Vector3(0, 0, end), 8, 20)
		for sx in [-1.0, 1.0]:
			# Weight turret at each corner of the central square.
			var tp := Vector3(sx * 13.25, 24.8, end * 13.25)
			lm.frustum("Wall", tp, 2.6, 2.3, 14.2, 12)
			lm.lathe("Lead", tp + Vector3(0, 14.2, 0), SEuUtil.dome(2.5, 2.4, 5), 12)
	# Great dome, its drum windows and the gilt alem.
	var dc := Vector3(0, 36.5, 0)
	LandmarkKits.dome_on_drum(lm, "Wall", "Lead", dc, 13.25, 4.5, 10.6, 0.9, 40)
	for k in 32:
		var a := TAU * float(k) / 32.0
		lm.box("Windows", dc + Vector3(cos(a) * 13.3, 2.3, sin(a) * 13.3), Vector3(1.0, 2.8, 0.6),
			Basis(Vector3.UP, PI * 0.5 - a))
	lm.beam("Gilt", Vector3(0, 52.0, 0), Vector3(0, 53.0, 0), 0.25, 0.25)
	# Aisle domes, large and small alternating.
	for sx in [-1.0, 1.0]:
		for i in 5:
			var r := 5.2 if i % 2 == 0 else 3.9
			lm.lathe("Lead", Vector3(sx * 21.2, 24.8, -22.8 + 11.4 * float(i)), SEuUtil.dome(r, r * 0.85, 6), 18)
		SEuUtil.face_row(lm, "Windows", Vector3(sx * 13.25, 0, 0), Vector3(0, 0, 1), Vector3(sx, 0, 0),
			26.5, 3, 7.5, 3.4, 8.5)
	# Window tiers on the hall walls (the courtyard front keeps its portal).
	for sx in [-1.0, 1.0]:
		for tier in [[3.5, 2.0, 3.6], [11.0, 2.4, 5.0], [18.5, 2.0, 4.0]]:
			SEuUtil.face_row(lm, "Windows", Vector3(sx * 29.0, 0, 0), Vector3(0, 0, 1), Vector3(sx, 0, 0),
				float(tier[0]), 7, 7.4, float(tier[1]), float(tier[2]))
	for tier in [[3.5, 2.0, 3.6], [11.0, 2.4, 5.0], [18.5, 2.0, 4.0]]:
		SEuUtil.face_row(lm, "Windows", Vector3(0, 0, 28.5), Vector3(1, 0, 0), Vector3(0, 0, 1),
			float(tier[0]), 7, 7.4, float(tier[1]), float(tier[2]))
		if float(tier[0]) > 8.0:
			SEuUtil.face_row(lm, "Windows", Vector3(0, 0, -28.5), Vector3(1, 0, 0), Vector3(0, 0, -1),
				float(tier[0]), 7, 7.4, float(tier[1]), float(tier[2]))
	SEuUtil.face_row(lm, "Windows", Vector3(0, 0, -28.5), Vector3(1, 0, 0), Vector3(0, 0, -1), 0.0, 1, 1.0, 5.0, 11.0, true)
	# Courtyard: paving, three arcaded bands and the portico before the hall.
	LandmarkGtUtil.block(lm, "Court", -28.5, 28.5, 0.0, 0.15, -75.5, -28.5)
	for band in [[-28.5, 28.5, -75.5, -68.5], [-28.5, -21.5, -68.5, -35.5], [21.5, 28.5, -68.5, -35.5],
			[-28.5, 28.5, -35.5, -28.5]]:
		LandmarkGtUtil.block(lm, "Pale", band[0], band[1], 6.8, 7.5, band[2], band[3])
	LandmarkGtUtil.block(lm, "Wall", -28.5, 28.5, 0.0, 6.8, -75.5, -74.3)
	LandmarkGtUtil.block(lm, "Wall", -28.5, -27.3, 0.0, 6.8, -75.5, -35.5)
	LandmarkGtUtil.block(lm, "Wall", 27.3, 28.5, 0.0, 6.8, -75.5, -35.5)
	for i in 11:
		var x := -21.5 + 4.3 * float(i)
		lm.frustum("Pale", Vector3(x, 0, -68.5), 0.42, 0.36, 6.8, 10)
		lm.frustum("Pale", Vector3(x, 0, -35.5), 0.42, 0.36, 6.8, 10)
	for i in range(1, 8):
		var z := -68.5 + 4.125 * float(i)
		lm.frustum("Pale", Vector3(-21.5, 0, z), 0.42, 0.36, 6.8, 10)
		lm.frustum("Pale", Vector3(21.5, 0, z), 0.42, 0.36, 6.8, 10)
	for i in 8:
		lm.lathe("Lead", Vector3(-24.5 + 7.0 * float(i), 7.5, -72.0), SEuUtil.dome(3.3, 2.7, 4), 12)
	for i in 5:
		for sx in [-1.0, 1.0]:
			lm.lathe("Lead", Vector3(sx * 25.0, 7.5, -65.0 + 5.8 * float(i)), SEuUtil.dome(3.3, 2.7, 4), 12)
		lm.lathe("Lead", Vector3(-20.0 + 10.0 * float(i), 7.5, -32.0), SEuUtil.dome(3.3, 2.7, 4), 12)
	# Ablution fountain: eight columns under a small dome.
	lm.frustum("Pale", Vector3(0, 0.15, -52.0), 3.4, 3.2, 0.7, 16)
	for k in 8:
		var af := TAU * float(k) / 8.0
		lm.frustum("Pale", Vector3(cos(af) * 2.6, 0.85, -52.0 + sin(af) * 2.6), 0.2, 0.17, 3.0, 8)
	lm.lathe("Lead", Vector3(0, 3.85, -52.0), SEuUtil.dome(3.2, 2.0, 5), 16)
	# Minarets: tall pair by the hall, shorter pair at the far corners.
	for sx in [-1.0, 1.0]:
		LandmarkGtUtil.minaret(lm, "Pale", "Lead", Vector3(sx * 32.0, 0, -29.0), 2.0, SULEY_TOP, [0.5, 0.7, 0.86])
		LandmarkGtUtil.minaret(lm, "Pale", "Lead", Vector3(sx * 31.0, 0, -77.5), 1.85, 63.0, [0.55, 0.8])
	lm.commit(model)

# --- Topkapi -----------------------------------------------------------------

const TOPKAPI_TOP := 38.0

## Topkapi Palace, origin in the middle of the Second Court (Divan
## Square), the way in from the Gate of Salutation at +Z and the Gate of
## Felicity at -Z: the Gate of Salutation between its two octagonal
## lead-capped towers, the crenellated walls, the Imperial Council hall
## with the Tower of Justice (the tallest structure of the palace) on
## the left, the Harem's roofs behind it, the kitchens with their ten
## domes and twenty chimneys on the right, the Gate of Felicity under its
## great eaves, the Audience Chamber, the Treasury and Ahmed III's
## library of the Third Court and the kiosks of the Fourth Court.
static func topkapi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5CAB0", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E8E2D2", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#70777E", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A35B3C", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B38465", 3.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#B8AE98", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#34302B", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	LandmarkGtUtil.block(lm, "Court", -36.0, 36.0, 0.0, 0.15, -56.0, 56.0)
	LandmarkGtUtil.block(lm, "Court", -36.0, 36.0, 0.0, 2.5, -105.0, -56.0)
	_salutation(lm, Vector3(0, 0, 58.0))
	_council(lm)
	_harem(lm)
	_kitchens(lm)
	_felicity(lm, Vector3(0, 0, -51.0))
	# Third and Fourth Court: Audience Chamber, Treasury, library, kiosks.
	LandmarkGtUtil.block(lm, "Marble", -9.0, 9.0, 2.5, 8.5, -70.0, -58.0)
	lm.gable("Lead", Vector3(0, 8.5, -64.0), 12.0, 18.0, 3.4, Basis(Vector3.UP, PI * 0.5), 0.9, "Marble")
	LandmarkGtUtil.block(lm, "Stone", -34.0, -10.0, 2.5, 8.0, -90.0, -78.0)
	for i in 5:
		lm.lathe("Lead", Vector3(-30.0 + 5.4 * float(i), 8.0, -84.0), SEuUtil.dome(2.6, 2.2, 5), 12)
	LandmarkGtUtil.block(lm, "Marble", 10.0, 21.0, 2.5, 9.0, -92.0, -81.0)
	lm.lathe("Lead", Vector3(15.5, 9.0, -86.5), SEuUtil.dome(4.4, 3.4, 6), 16)
	_kiosk(lm, Vector3(16.0, 2.5, -100.0))
	LandmarkGtUtil.block(lm, "Marble", -26.0, -14.0, 2.5, 8.0, -103.0, -93.0)
	lm.lathe("Lead", Vector3(-20.0, 8.0, -98.0), SEuUtil.dome(4.6, 3.6, 6), 16)
	lm.commit(model)

## Gate of Salutation at `c` (the middle of its court face): crenellated
## gate block with a pointed passage, flanked by two octagonal towers
## under tall lead cones, and the crenellated walls running out.
static func _salutation(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Stone", c.x - 9.0, c.x + 9.0, 0.0, 11.0, c.z - 5.0, c.z + 5.0)
	for sz in [-1.0, 1.0]:
		SEuUtil.opening(lm, "Dark", Vector3(0, 0, c.z + sz * 5.05), Vector3(1, 0, 0) * sz, Vector3.UP, 5.0, 8.0, true)
		LandmarkCeParts.merlons(lm, "Stone", Vector3(c.x - 9.0, 11.0, c.z + sz * 4.7),
			Vector3(c.x + 9.0, 11.0, c.z + sz * 4.7), 1.8, 0.9, 1.1, 0.8)
	for sx in [-1.0, 1.0]:
		var tp := Vector3(c.x + sx * 12.5, 0, c.z)
		lm.frustum("Stone", tp, 4.6, 4.3, 18.0, 8)
		lm.frustum("Marble", tp + Vector3(0, 17.0, 0), 4.9, 4.9, 1.0, 8)
		lm.spire("Lead", tp + Vector3(0, 18.0, 0), 4.9, 10.0, 0.0, 8)
		LandmarkGtUtil.block(lm, "Stone", c.x + sx * 22.0 - 11.0, c.x + sx * 22.0 + 11.0, 0.0, 7.0, c.z - 1.5, c.z + 1.5)
		LandmarkCeParts.merlons(lm, "Stone", Vector3(c.x + sx * 17.0, 7.0, c.z), Vector3(c.x + sx * 33.0, 7.0, c.z),
			2.0, 1.0, 1.0, 1.2)

## Imperial Council: a long hall of three domes beside the court with an
## arcade, and the Tower of Justice beyond it.
static func _council(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Stone", -49.0, -37.0, 0.0, 8.0, -36.0, -6.0)
	for i in 3:
		lm.lathe("Lead", Vector3(-43.0, 8.0, -29.0 + 10.0 * float(i)), SEuUtil.dome(4.2, 3.4, 6), 16)
	for i in 8:
		lm.frustum("Marble", Vector3(-35.8, 0, -33.0 + 3.6 * float(i)), 0.3, 0.26, 5.4, 10)
	LandmarkGtUtil.block(lm, "Marble", -36.6, -35.0, 5.4, 6.0, -34.0, -5.0)
	# Tower of Justice: square shaft, belvedere with arches, pyramid roof.
	var tc := Vector3(-43.5, 0, -43.0)
	LandmarkGtUtil.block(lm, "Stone", tc.x - 4.5, tc.x + 4.5, 0.0, 22.0, tc.z - 4.5, tc.z + 4.5)
	for tier in [[5.0, 1.6, 2.6], [12.0, 1.6, 3.0], [18.0, 1.6, 3.0]]:
		for k in 4:
			var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
			SEuUtil.opening(lm, "Dark", tc + out * 4.55 + Vector3(0, float(tier[0]), 0), Vector3.UP.cross(out), Vector3.UP,
				float(tier[1]), float(tier[2]), true)
	LandmarkGtUtil.block(lm, "Marble", tc.x - 5.0, tc.x + 5.0, 22.0, 22.7, tc.z - 5.0, tc.z + 5.0)
	for j in 4:
		var off := -3.7 + 2.467 * float(j)
		lm.frustum("Marble", tc + Vector3(off, 22.7, 3.7), 0.3, 0.26, 3.9, 8)
		lm.frustum("Marble", tc + Vector3(off, 22.7, -3.7), 0.3, 0.26, 3.9, 8)
		if j == 1 or j == 2:
			lm.frustum("Marble", tc + Vector3(3.7, 22.7, off), 0.3, 0.26, 3.9, 8)
			lm.frustum("Marble", tc + Vector3(-3.7, 22.7, off), 0.3, 0.26, 3.9, 8)
	LandmarkGtUtil.block(lm, "Marble", tc.x - 5.0, tc.x + 5.0, 26.6, 27.3, tc.z - 5.0, tc.z + 5.0)
	lm.spire("Lead", tc + Vector3(0, 27.3, 0), 5.2, 9.7, 0.0, 4)
	lm.beam("Gilt", tc + Vector3(0, 36.9, 0), tc + Vector3(0, TOPKAPI_TOP, 0), 0.3, 0.3)

## The Harem: a rambling mass of tile-roofed blocks of varied height
## behind the council hall, with a few lead domes.
static func _harem(lm: LandmarkMesh) -> void:
	for ix in 4:
		for iz in 6:
			if (ix == 0 and iz == 5) or (ix == 3 and iz == 0):
				continue
			var n := ix * 6 + iz
			var h := 6.5 + 4.0 * LandmarkGtUtil.hash01(n, 4)
			var c := Vector3(-92.0 + 10.2 * float(ix), 0, -38.0 + 9.4 * float(iz))
			LandmarkGtUtil.block(lm, "Stone", c.x - 5.0, c.x + 5.0, 0.0, h, c.z - 4.5, c.z + 4.5)
			if LandmarkGtUtil.hash01(n, 8) > 0.82:
				lm.lathe("Lead", c + Vector3(0, h, 0), SEuUtil.dome(3.4, 2.8, 6), 14)
			else:
				var turn := Basis(Vector3.UP, PI * 0.5) if LandmarkGtUtil.hash01(n, 6) > 0.5 else Basis()
				lm.gable("Tile", c + Vector3(0, h, 0), 9.0, 10.0, 2.6, turn, 0.6, "Stone")

## The kitchens along the court's east side: portico, ten domed kitchens
## and their twenty tall chimneys.
static func _kitchens(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Brick", 34.0, 46.0, 0.0, 6.5, -38.0, 38.0)
	LandmarkGtUtil.block(lm, "Stone", 32.0, 34.5, 5.2, 5.9, -38.0, 38.0)
	for i in 19:
		lm.frustum("Marble", Vector3(33.0, 0, -36.0 + 4.0 * float(i)), 0.3, 0.26, 5.2, 10)
	for i in 10:
		var z := -34.2 + 7.6 * float(i)
		lm.lathe("Lead", Vector3(40.0, 6.5, z), SEuUtil.dome(3.4, 2.4, 5), 14)
		for cx in [36.8, 43.2]:
			lm.frustum("Brick", Vector3(cx, 6.5, z), 1.0, 0.85, 4.8, 10)
			lm.frustum("Lead", Vector3(cx, 11.3, z), 1.15, 0.0, 2.2, 10)

## Gate of Felicity at `c`: marble gate hall with six slender columns
## and the huge overhanging roof.
static func _felicity(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Marble", c.x - 12.0, c.x + 12.0, 0.0, 6.5, c.z - 5.0, c.z + 4.0)
	LandmarkGtUtil.block(lm, "Dark", c.x - 2.2, c.x + 2.2, 0.0, 5.0, c.z + 3.95, c.z + 4.1)
	for i in 6:
		lm.frustum("Marble", Vector3(c.x - 10.0 + 4.0 * float(i), 0, c.z + 6.6), 0.32, 0.27, 5.8, 10)
	lm.gable("Lead", c + Vector3(0, 6.9, 0.8), 15.0, 28.0, 4.6, Basis(Vector3.UP, PI * 0.5), 2.6, "Marble")

## Cruciform kiosk (Baghdad Kiosk) on its terrace at `c`: four iwans round
## a square domed hall.
static func _kiosk(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Marble", c.x - 4.5, c.x + 4.5, c.y, c.y + 7.0, c.z - 4.5, c.z + 4.5)
	LandmarkGtUtil.block(lm, "Marble", c.x - 6.8, c.x + 6.8, c.y, c.y + 5.0, c.z - 2.4, c.z + 2.4)
	LandmarkGtUtil.block(lm, "Marble", c.x - 2.4, c.x + 2.4, c.y, c.y + 5.0, c.z - 6.8, c.z + 6.8)
	lm.lathe("Lead", c + Vector3(0, 7.0, 0), SEuUtil.dome(4.6, 4.2, 7), 20)
