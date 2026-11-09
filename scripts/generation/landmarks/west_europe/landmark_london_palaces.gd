class_name LandmarkLondonPalaces
extends RefCounted

## The Tower of London (LandmarkTowerOfLondon) and Buckingham Palace in
## true metres, y = 0 at street level.

static func tower_of_london(model: Node3D) -> void:
	LandmarkTowerOfLondon.build(model)

## Buckingham Palace (24 m, 108 m x 120 m): the quadrangle of Nash and
## Blore (1825-50) behind Aston Webb's 1913 Portland-stone east front
## (+X, facing The Mall): 23 bays, a rusticated ground floor, the piano
## nobile and a second floor under a cornice and balustrade, the three
## pedimented, giant-order pavilions (the centre 26 m wide with six
## Corinthian columns, the arms in the pediment and the Royal Family's
## balcony over a four-column porch, the ends 16 m with pilasters and
## low pediments), slated roofs with chimney stacks and a flagpole; the
## north, south and quadrangle faces pierced by three storeys of windows,
## the garden front's central bow (west), and Bromsgrove Guild's gilded
## forecourt railings, piers and Centre Gate (the Queen Victoria Memorial
## is not modelled). Orientation: the model's +X is the Mall front
## (registry yaw -18); by the Mall's bearing (Admiralty Arch to the
## Victoria Memorial is about 058 degrees) the real front looks about 12
## degrees further north than the registry places it.
## East front and gates: https://www.royal.uk/royal-residences-buckingham-palace
## Historic east-front photograph: https://historicengland.org.uk/images-books/photos/item/BL22460/001
static func buckingham(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D0C8B2", 3.5))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#5A6168", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Court", LandmarkMaterials.pbr("gravel", "#BBB3A1", 5.0))
	lm.use("Iron", LandmarkMaterials.paint("#1E2124", 0.6, 0.4))
	_ranges(lm)
	_east_front(lm)
	_portico(lm)
	_other_faces(lm)
	_forecourt(lm)
	lm.commit(model)

## The four ranges round the quadrangle: walls to the cornice, a stone
## course, a low slated gable roof with chimney stacks, the courtyard.
static func _ranges(lm: LandmarkMesh) -> void:
	for r in [[49.0, 0.0, 22.0, 108.0, 0.0], [-49.0, 0.0, 22.0, 108.0, 0.0], [0.0, 43.0, 120.0, 22.0, 1.0],
			[0.0, -43.0, 120.0, 22.0, 1.0]]:
		var w: float = r[2]
		var l: float = r[3]
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], w, 19.0, l)
		LandmarkWestKit.blk(lm, "Stone", r[0], 18.4, r[1], w + 1.0, 0.8, l + 1.0)
		LandmarkWestKit.blk(lm, "Stone", r[0], 19.2, r[1], w + 0.6, 0.9, l + 0.6)
		if float(r[4]) < 0.5:
			lm.gable("Slate", Vector3(r[0], 20.1, r[1]), w - 0.4, l - 0.4, 2.0, Basis(), 0.0, "Slate")
		else:
			lm.gable("Slate", Vector3(r[0], 20.1, r[1]), l - 0.4, w - 0.4, 2.0, Basis(Vector3.UP, PI * 0.5), 0.0, "Slate")
	LandmarkWestKit.blk(lm, "Court", 0, 0, 0, 76.0, 0.3, 64.0)
	for k in 6:
		LandmarkWestKit.chimney(lm, "Stone", Vector3(49.0, 20.6, -40.0 + 16.0 * float(k)), 1.4, 3.4, 2.6)
		LandmarkWestKit.chimney(lm, "Stone", Vector3(-49.0, 20.6, -40.0 + 16.0 * float(k)), 1.4, 3.4, 2.6)
	for k in 7:
		LandmarkWestKit.chimney(lm, "Stone", Vector3(-52.0 + 17.0 * float(k), 20.6, 43.0), 3.4, 1.4, 2.6)
		LandmarkWestKit.chimney(lm, "Stone", Vector3(-52.0 + 17.0 * float(k), 20.6, -43.0), 3.4, 1.4, 2.6)
	# Flagpole for the Royal Standard on the east range.
	lm.frustum("Iron", Vector3(52.0, 21.0, 0), 0.14, 0.07, 4.4, 6)

## Webb's front: rusticated base, string courses, three storeys of
## windows in 23 bays, giant pilasters between the wing bays, the
## modillion cornice and the balustrade, and the end pavilions.
static func _east_front(lm: LandmarkMesh) -> void:
	var e := Vector3(1, 0, 0)
	# Rusticated ground-floor skin with its horizontal joints.
	LandmarkWestKit.blk(lm, "Stone", 60.6, 0, 0, 1.2, 6.0, 108.0)
	for k in 12:
		LandmarkWestKit.blk(lm, "Stone", 61.25, 0.5 * float(k), 0, 0.1, 0.12, 108.0)
	LandmarkWestKit.blk(lm, "Stone", 61.1, 6.0, 0, 1.6, 0.5, 108.4)
	LandmarkWestKit.blk(lm, "Stone", 60.35, 12.0, 0, 0.7, 0.4, 108.0)
	# Wing bays: arched ground floor on the skin, square windows above.
	for sz in [-1.0, 1.0]:
		var z0: float = sz * 13.0
		var z1: float = sz * 38.0
		LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(61.22, 0, z0), Vector3(61.22, 0, z1), e, 5, [1.6],
			[Vector2(1.5, -3.3)])
		LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(60.0, 0, z0), Vector3(60.0, 0, z1), e, 5, [7.7, 13.6],
			[Vector2(1.8, 3.9), Vector2(1.5, 3.0)])
	for k in 24:
		var z := -52.0 + 104.0 * float(k) / 23.0
		if absf(z) > 13.5 and absf(z) < 37.5:
			lm.box("Stone", Vector3(60.35, 12.4, z), Vector3(0.7, 12.4, 1.1))
	LandmarkDetail.cornice(lm, "Stone", Vector3(60.0, 18.6, -54.0), Vector3(60.0, 18.6, 54.0), e, 1.2)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(60.5, 20.0, -54.0), Vector3(60.5, 20.0, 54.0), 1.2, 4.5, 6)
	# End pavilions: pilasters, an attic course and a low pediment.
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", 61.2, 0, sz * 46.0, 2.4, 21.0, 16.0)
		LandmarkWestKit.blk(lm, "Stone", 61.4, 21.0, sz * 46.0, 3.2, 0.9, 16.8)
		LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(62.42, 0, sz * 46.0 - 5.0),
			Vector3(62.42, 0, sz * 46.0 + 5.0), e, 3, [1.6, 7.7, 13.6],
			[Vector2(1.5, -3.3), Vector2(1.8, 3.9), Vector2(1.5, 3.0)])
		for pz in [-7.3, -2.6, 2.6, 7.3]:
			lm.box("Stone", Vector3(62.7, 13.5, sz * 46.0 + pz), Vector3(0.6, 14.4, 1.1))
		LandmarkDetail.cornice(lm, "Stone", Vector3(62.4, 20.4, sz * 46.0 - 8.4), Vector3(62.4, 20.4, sz * 46.0 + 8.4), e, 1.0)
		lm.gable("Stone", Vector3(61.4, 21.9, sz * 46.0), 15.0, 3.2, 1.9, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")

## The centre pavilion: four-column porch under the balcony, French
## window, six giant Corinthian columns, entablature and pediment.
static func _portico(lm: LandmarkMesh) -> void:
	var e := Vector3(1, 0, 0)
	LandmarkWestKit.blk(lm, "Stone", 62.0, 0, 0, 4.0, 20.0, 26.0)
	# Ground floor: porch of stout columns, its flat roof the balcony.
	LandmarkWestKit.blk(lm, "Stone", 65.3, 5.9, 0, 3.0, 0.8, 18.0)
	for pz in [-7.4, -2.5, 2.5, 7.4]:
		LandmarkDetail.column(lm, "Stone", Vector3(65.6, 0.0, pz), 0.5, 5.9, "tuscan", 0)
	lm.box("Glass", Vector3(64.04, 2.7, 0), Vector3(0.1, 5.2, 14.0), Basis(), 0.0)
	for pz in [-5.0, 0.0, 5.0]:
		LandmarkDetail.arch(lm, "Stone", Vector3(64.1, 2.4, pz), e, 3.0, 0.4, 0.2)
	# Balcony: balustrade round three sides, the arched French window.
	LandmarkDetail.balustrade(lm, "Stone", Vector3(66.7, 6.7, -9.0), Vector3(66.7, 6.7, 9.0), 1.1, 4.5, 6)
	for sz in [-1.0, 1.0]:
		LandmarkDetail.balustrade(lm, "Stone", Vector3(64.2, 6.7, float(sz) * 9.0), Vector3(66.7, 6.7, float(sz) * 9.0), 1.1, 5.0, 6)
	LandmarkDetail.window(lm, "Stone", "Glass", Vector3(64.0, 7.7 + 3.0, 0), e, 3.0, 6.0, true, 0.35)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(64.0, 0, float(sz) * 2.6), Vector3(64.0, 0, float(sz) * 13.0), e, 2,
			[7.7, 13.6], [Vector2(1.8, 3.9), Vector2(1.5, 3.0)])
	LandmarkDetail.window(lm, "Stone", "Glass", Vector3(64.0, 13.6 + 1.5, 0), e, 1.6, 3.0, false, 0.3)
	# Six giant columns, entablature, pediment with the royal arms.
	for pz in [-12.6, -7.8, -2.6, 2.6, 7.8, 12.6]:
		LandmarkDetail.column(lm, "Stone", Vector3(64.6, 7.0, pz), 0.55, 11.4, "corinthian", 0)
	LandmarkWestKit.blk(lm, "Stone", 63.2, 18.4, 0, 5.4, 1.6, 27.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(65.9, 20.0, -13.8), Vector3(65.9, 20.0, 13.8), e, 0.9, true)
	lm.gable("Stone", Vector3(63.2, 20.9, 0), 26.0, 5.4, 3.2, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	lm.box("Gilt", Vector3(65.95, 22.1, 0), Vector3(0.15, 1.4, 3.0), Basis(), 0.0)
	lm.lathe("Gilt", Vector3(65.95, 22.8, 0), LandmarkWestKit.ball(0.4), 8)
	# Panels between the columns.
	for pz in [-5.2, 5.2]:
		lm.box("Stone", Vector3(64.2, 17.2, pz), Vector3(0.3, 1.0, 3.2))

## North, south, quadrangle and garden faces: three storeys of pierced
## windows, the garden front's central bow.
static func _other_faces(lm: LandmarkMesh) -> void:
	var win := Vector2(1.7, 3.2)
	# Outer north (-Z) and south (+Z) wings.
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(60.0, 0, -54.0), Vector3(-1, 0, 0), Vector3(0, 0, -1),
		120.0, 19.0, 24, 3, win, 2.0, 5.8, 0.35)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-60.0, 0, 54.0), Vector3(1, 0, 0), Vector3(0, 0, 1),
		120.0, 19.0, 24, 3, win, 2.0, 5.8, 0.35)
	# Quadrangle faces.
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(38.0, 0, -32.0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
		64.0, 19.0, 13, 3, win, 2.0, 5.8, 0.3)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-38.0, 0, 32.0), Vector3(0, 0, -1), Vector3(1, 0, 0),
		64.0, 19.0, 13, 3, win, 2.0, 5.8, 0.3)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-38.0, 0, -32.0), Vector3(1, 0, 0), Vector3(0, 0, 1),
		76.0, 19.0, 15, 3, win, 2.0, 5.8, 0.3)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(38.0, 0, 32.0), Vector3(-1, 0, 0), Vector3(0, 0, -1),
		76.0, 19.0, 15, 3, win, 2.0, 5.8, 0.3)
	# Garden front (west): pierced storeys and the central bow.
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-60.0, 0, 54.0), Vector3(0, 0, -1), Vector3(-1, 0, 0),
		108.0, 19.0, 27, 3, Vector2(1.7, 3.2), 2.0, 5.8, 0.35)
	lm.lathe("Stone", Vector3(-60, 0, 0), PackedVector2Array([Vector2(12, 0), Vector2(12, 19)]), 20, 0.5, 1.0)
	lm.lathe("Stone", Vector3(-60, 18.6, 0), PackedVector2Array([Vector2(12.6, 0), Vector2(12.6, 0.8)]), 20, 0.5, 1.0)
	for k in 7:
		var a := PI * 0.5 + PI * (float(k) + 0.5) / 7.0
		var d := Vector3(cos(a) * 0.5, 0, sin(a)).normalized()
		var p := Vector3(-60, 0, 0) + Vector3(cos(a) * 6.0, 0, sin(a) * 12.0)
		for y in [3.6, 9.4, 15.0]:
			lm.box("Glass", p + Vector3(0, y, 0) + d * 0.05, Vector3(1.6, 3.0, 0.08), Basis.looking_at(d), 0.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-60.0, 18.6, 54.0), Vector3(-60.0, 18.6, -54.0), Vector3(-1, 0, 0), 1.2, false)

## Forecourt: railings with gilded tips, stone piers, the Centre Gate and
## the side gates.
static func _forecourt(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "Court", 77.0, 0, 0, 30.0, 0.08, 108.0)
	LandmarkWestKit.merlons(lm, "Iron", Vector3(92, 0, -62), Vector3(92, 0, 62), 0.4, 0.06, 3.0, 0.06)
	lm.beam("Iron", Vector3(92, 2.6, -62), Vector3(92, 2.6, 62), 0.12, 0.12)
	LandmarkWestKit.blk(lm, "Stone", 92.0, 0, 0, 1.2, 1.0, 124.0)
	for k in 9:
		var z := -60.0 + 15.0 * float(k)
		LandmarkWestKit.blk(lm, "Stone", 92.0, 0, z, 1.6, 4.4, 1.6)
		lm.lathe("Gilt", Vector3(92.0, 4.4, z), LandmarkWestKit.ball(0.5), 8)
	for gz in [-15.0, 15.0]:
		lm.box("Gilt", Vector3(92.0, 4.2, gz), Vector3(0.3, 1.2, 5.0), Basis(), 0.0)
		LandmarkWestKit.blk(lm, "Stone", 92.0, 0, gz - 3.0, 1.8, 6.0, 1.8)
		LandmarkWestKit.blk(lm, "Stone", 92.0, 0, gz + 3.0, 1.8, 6.0, 1.8)
	for gz in [-36.0, 36.0]:
		LandmarkWestKit.blk(lm, "Stone", 88.0, 0, gz, 1.4, 2.8, 1.4)
		lm.gable("Slate", Vector3(88.0, 2.8, gz), 1.6, 1.6, 0.6, Basis(), 0.1)
