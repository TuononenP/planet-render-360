class_name LandmarkWhCivic
extends RefCounted

## The Roman Baths of Bath in true metres, y = 0 at the ground (Brussels
## Town Hall and the Belfry of Bruges are LandmarkWhLowCountries).

## Raise of the bath site: the Great Bath lies 1.6 m deep below its
## pavement, so the site stands on a raised block instead of a pit.
const SITE := 1.9

## Roman Baths (49 m to the tip of the Abbey tower): the Great Bath
## (22 x 12 m, 1.6 m deep, lead-lined, green water, Roman steps on every
## side) in its pavement, ringed by stubby Tuscan columns on their
## bases under the Victorian terrace (1894-97) whose balustrade carries
## the statues of Roman emperors and governors; the Grand Pump Room
## (1789-99) to the north with its Corinthian portico, tall arched
## windows and balustraded parapet; and beyond it Bath Abbey (1499-
## 1616): the west front with the ladder turrets climbed by carved
## angels, the great west window, the flying buttresses and the
## oblong crossing tower with its pierced parapet and corner pinnacles.
static func roman_baths(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9C9A0", 3.5))
	lm.use("Paving", LandmarkMaterials.pbr("stone", "#9E9886", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#667078", 2.5))
	lm.use("Water", LandmarkMaterials.paint("#4F7F58", 0.1, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	_great_bath(lm)
	_pump_room(lm)
	_abbey(lm, -52.0)
	LandmarkWhKit.shift(lm, Vector3(-48.6, 0, 27.2))
	lm.commit(model)

## The Great Bath on its raised site: pavement, the stepped basin round
## the green water over its lead floor, the colonnade, the terrace and
## its statue-lined balustrade.
static func _great_bath(lm: LandmarkMesh) -> void:
	var y := SITE
	for r in [[0.0, -9.0, 34.0, 6.0], [0.0, 9.0, 34.0, 6.0], [-14.0, 0.0, 6.0, 12.0], [14.0, 0.0, 6.0, 12.0]]:
		LandmarkWestKit.blk(lm, "Paving", r[0], 0, r[1], r[2], y, r[3])
	LandmarkWestKit.blk(lm, "Slate", 0, 0, 0, 22.0, 0.3, 12.0)
	lm.quad("Water", Vector3(-11, y - 0.35, 6), Vector3(11, y - 0.35, 6), Vector3(11, y - 0.35, -6),
		Vector3(-11, y - 0.35, -6), Vector3.UP)
	# Four Roman steps down into the water on every side.
	for k in 4:
		var t := float(k) * 0.55
		var sy := y - 0.35 * float(k + 1)
		for sx in [-1.0, 1.0]:
			LandmarkWestKit.blk(lm, "Paving", sx * (11.0 - t - 0.275), 0, 0, 0.55, sy, 12.0 - 2.0 * t)
		for sz in [-1.0, 1.0]:
			LandmarkWestKit.blk(lm, "Paving", 0, 0, sz * (6.0 - t - 0.275), 22.0 - 2.0 * t, sy, 0.55)
	# Tuscan columns on their square bases round the pool, entablature.
	for sz in [-1.0, 1.0]:
		for k in 12:
			_bath_column(lm, Vector3(lerpf(-15.0, 15.0, float(k) / 11.0), y, sz * 9.5))
	for sx in [-1.0, 1.0]:
		for k in 4:
			_bath_column(lm, Vector3(sx * 15.0, y, lerpf(-4.5, 4.5, float(k) / 3.0)))
	for r in [[0.0, -9.5, 32.0, 2.4], [0.0, 9.5, 32.0, 2.4], [-15.0, 0.0, 2.4, 20.0], [15.0, 0.0, 2.4, 20.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], y + 5.6, r[1], r[2], 1.1, r[3])
	# The terrace over the ambulatory, its balustrade and statues.
	for r in [[0.0, -13.0, 40.0, 5.0], [0.0, 13.0, 40.0, 5.0], [-18.0, 0.0, 4.0, 21.0], [18.0, 0.0, 4.0, 21.0]]:
		LandmarkWestKit.blk(lm, "Paving", r[0], y + 6.7, r[1], r[2], 0.5, r[3])
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], y + 6.7, r[3])
	var ty := y + 7.2
	for sz in [-1.0, 1.0]:
		var e: float = sz * 10.8
		for k in 8:
			var px := -17.5 + 5.0 * float(k)
			LandmarkWestKit.blk(lm, "Stone", px, ty, e, 1.1, 1.6, 1.1)
			LandmarkKits.statue_figure(lm, "Stone", Vector3(px, ty + 1.6, e), 2.7)
			if k < 7:
				LandmarkWhGothic.balusters(lm, "Stone", Vector3(px + 0.55, ty, e), Vector3(px + 4.45, ty, e), 1.1, 0.4)
		for s2 in [-1.0, 1.0]:
			LandmarkWhGothic.balusters(lm, "Stone", Vector3(s2 * 17.5, ty, e), Vector3(s2 * 16.4, ty, e), 1.1, 0.4)
	for sx in [-1.0, 1.0]:
		LandmarkWhGothic.balusters(lm, "Stone", Vector3(sx * 16.4, ty, -10.2), Vector3(sx * 16.4, ty, 10.2), 1.1, 0.4)
		for k in 3:
			var pz := -5.0 + 5.0 * float(k)
			LandmarkWestKit.blk(lm, "Stone", sx * 16.4, ty, pz, 1.1, 1.6, 1.1)
			LandmarkKits.statue_figure(lm, "Stone", Vector3(sx * 16.4, ty + 1.6, pz), 2.7)

## A stubby Tuscan column of the Great Bath on its square Roman base.
static func _bath_column(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Stone", p + Vector3(0, 0.4, 0), Vector3(1.4, 0.8, 1.4))
	LandmarkDetail.column(lm, "Stone", p + Vector3(0, 0.8, 0), 0.5, 4.8, "doric", 0)

## The Grand Pump Room north of the bath: the hall with its tall arched
## windows between Corinthian pilasters, the tetrastyle Corinthian
## portico under its pediment, cornice and balustraded parapet.
static func _pump_room(lm: LandmarkMesh) -> void:
	var fn := Vector3(0, 0, 1)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -32.0, 44.0, 14.0, 18.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -32.0, 44.6, 1.2, 18.6)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-22.0, 13.0, -23.0), Vector3(22.0, 13.0, -23.0), fn, 1.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 14.0, -32.0, 44.6, 0.4, 18.6)
	LandmarkWestKit.hip(lm, "Slate", Vector3(0, 14.4, -32.0), 40.0, 15.0, 2.5, 0.8)
	LandmarkWhGothic.balusters(lm, "Stone", Vector3(-22.0, 14.4, -22.9), Vector3(22.0, 14.4, -22.9), 1.1, 0.42)
	for k in 7:
		var px := -18.0 + 6.0 * float(k)
		if absf(px) < 5.0:
			continue
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(px, 2.6, -22.9), fn, 3.0, 5.4)
		LandmarkWhGothic.archivolt(lm, "Stone", Vector3(px, 8.0, -22.9), fn, 3.0, 0.35, 0.25)
		lm.box("Stone", Vector3(px, 2.3, -22.8), Vector3(3.6, 0.3, 0.4), Basis(), 0.0)
		LandmarkWhGothic.oculus(lm, "Glass", "Stone", Vector3(px, 11.0, -22.95), fn, 0.6, false)
	for k in 8:
		var px := -21.0 + 6.0 * float(k)
		LandmarkWestKit.blk(lm, "Stone", px, 1.2, -22.75, 0.9, 11.8, 0.5)
	for k in 4:
		LandmarkDetail.column(lm, "Stone", Vector3(lerpf(-4.5, 4.5, float(k) / 3.0), 1.2, -24.5), 0.55, 9.8,
			"corinthian", 0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -24.5, 11.6, 1.2, 3.4)
	LandmarkWestKit.blk(lm, "Stone", 0, 11.0, -24.5, 11.0, 1.4, 3.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-5.6, 12.2, -23.0), Vector3(5.6, 12.2, -23.0), fn, 0.6)
	lm.gable("Stone", Vector3(0, 12.8, -24.5), 11.4, 3.2, 2.4, Basis(), 0.0, "Stone")
	LandmarkWhKit.arch_round(lm, "Glass", Vector3(0, 1.2, -23.0), fn, 2.6, 4.6)

## Bath Abbey at z = az, nave along X: aisled nave and choir, the narrow
## transepts, the west front and its ladder turrets, the tower.
static func _abbey(lm: LandmarkMesh, az: float) -> void:
	LandmarkWhKit.aisled_body(lm, "Stone", "Slate", "Glass", 50.0, 83.0, 6.5, 21.0, 10.5, 12.0, 4.0, 5, az)
	LandmarkWhKit.aisled_body(lm, "Stone", "Slate", "Glass", 95.0, 119.0, 6.5, 21.0, 10.5, 12.0, 4.0, 3, az)
	LandmarkWestKit.blk(lm, "Stone", 89.0, 0, az, 12.0, 21.0, 36.0)
	lm.gable("Slate", Vector3(89.0, 21.0, az), 12.0, 36.0, 3.5, Basis(), 0.3, "Stone")
	for sz in [-1.0, 1.0]:
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(89.0, 6.0, az + sz * 18.0), Vector3(0, 0, sz), 6.0, 9.0,
			2.2, 5, 0.35)
	# East window: the square-headed Perpendicular east end.
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(119.1, 6.0, az), Vector3(1, 0, 0), 8.0, 10.0, 2.0, 7, 0.4)
	# West front: the great window, the door, the ladder turrets.
	var wn := Vector3(-1, 0, 0)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(49.9, 6.0, az), wn, 6.0, 10.0, 2.4, 7, 0.4)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(49.9, 0.2, az), wn, 2.6, 3.4, 1.0, 1, 0.5)
	lm.gable("Stone", Vector3(50.1, 21.0, az), 13.0, 0.6, 3.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(49.8, 21.0, az - 6.5), Vector3(49.8, 21.0, az + 6.5), wn, 1.2)
	for sz in [-1.0, 1.0]:
		var tc := Vector3(50.8, 0, az + sz * 7.2)
		lm.lathe("Stone", tc, PackedVector2Array([Vector2(1.8, 0), Vector2(1.6, 26.0)]),
			8, 1.0, 1.0, PI / 8.0, false)
		for y in [12.0, 21.0]:
			lm.frustum("Stone", tc + Vector3(0, y, 0), 1.85, 1.85, 0.4, 8, PI / 8.0)
		LandmarkWhKit.crenel_ring(lm, "Stone", tc + Vector3(0, 26.0, 0), 1.6, 8, 0.6, 0.9, 0.3)
		lm.lathe("Stone", tc + Vector3(0, 26.0, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(0, 5.0)]),
			8, 1.0, 1.0, PI / 8.0, false)
		# Jacob's ladder: two rails and rungs up the turret's west face,
		# the climbing angels on them.
		var face := tc + wn * 1.75
		for s2 in [-0.45, 0.45]:
			lm.beam("Stone", face + Vector3(0, 6.0, s2), face + Vector3(0, 22.0, s2), 0.15, 0.15)
		for k in 14:
			lm.beam("Stone", face + Vector3(0, 6.5 + 1.1 * float(k), -0.45), face + Vector3(0, 6.5 + 1.1 * float(k), 0.45),
				0.1, 0.1)
		for k in 4:
			LandmarkWhGothic.jamb_figure(lm, "Stone", face + wn * 0.25 + Vector3(0, 7.5 + 3.6 * float(k), 0), 1.4)
	LandmarkWhKit.square_tower(lm, "Stone", "Glass", Vector3(89.0, 0, az), 11.0, 43.2, 20.0,
		[Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)], 2.4, 2.6)
