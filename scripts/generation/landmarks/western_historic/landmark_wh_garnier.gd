class_name LandmarkWhGarnier
extends RefCounted

## The Palais Garnier in true metres, y = 0 at the Place de l'Opéra,
## main front to the south (+Z).

## Palais Garnier (56 m to the Apollo group; 1861-75): the Beaux-Arts
## opera house, about 154 m deep and 125 m across the side pavilions.
## The front: a perron, seven arches between rusticated piers with the
## four sculpture groups (La Danse among them) at the avant-corps, the
## loggia of sixteen coupled monolithic Corinthian columns with the
## composers' busts in oculi, the gilded attic frieze and the gilded
## groups of Harmony and Poetry over the end avant-corps. Behind it the
## auditorium under its low ribbed verdigris dome and crown lantern, the
## two side rotundas (the Pavillon de l'Empereur with its carriage
## ramps to the west), and the stage house whose pediment carries the
## golden Apollo raising his lyre between two Pegasus groups.
static func palais_garnier(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D3C6A6", 3.5))
	lm.use("Column", LandmarkMaterials.pbr("stone", "#A8906F", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4C555B", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#6F9A86", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var fz := 64.0
	var fn := Vector3(0, 0, 1)
	for k in 3:
		LandmarkWestKit.blk(lm, "Stone", 0, 0, fz + 3.0 - 0.9 * float(k), 76.0 - 2.0 * float(k),
			0.5 * float(k + 1), 6.0 - 1.8 * float(k))
	# Front block: arcade storey, loggia storey, entablature, attic.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 47.0, 72.0, 9.5, 34.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 9.5, 44.0, 72.0, 20.5, 28.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 9.5, 61.0, 72.0, 0.7, 6.0)
	_arcade(lm, fz)
	_loggia(lm, fz)
	# Entablature, gilded frieze, cornice and attic with its masks.
	LandmarkWestKit.blk(lm, "Stone", 0, 23.0, 60.0, 74.0, 2.9, 8.4)
	LandmarkWestKit.blk(lm, "Gilt", 0, 24.3, 64.25, 62.0, 0.9, 0.12)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-37.0, 25.6, 64.2), Vector3(37.0, 25.6, 64.2), fn, 1.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 25.9, 59.0, 72.0, 3.6, 6.0)
	for k in 15:
		var x := -31.5 + 4.5 * float(k)
		LandmarkWestKit.blk(lm, "Stone", x, 26.3, 62.1, 1.2, 2.8, 0.3)
		lm.lathe("Gilt", Vector3(x + 2.25, 27.7, 62.0), LandmarkWestKit.ball(0.45), 8)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-36.0, 29.5, 62.0), Vector3(36.0, 29.5, 62.0), fn, 0.7, false)
	LandmarkWestKit.blk(lm, "Roof", 0, 29.5, 46.0, 72.0, 0.8, 32.0)
	# Avant-corps at each end: arched bay, pediment, gilded group on top.
	for sx in [-1.0, 1.0]:
		var ax: float = sx * 34.25
		LandmarkWestKit.blk(lm, "Stone", ax, 9.5, 61.0, 5.5, 20.0, 7.0)
		LandmarkWestKit.blk(lm, "Stone", ax, 29.5, 61.0, 6.0, 1.0, 7.5)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(ax, 12.0, 64.55), fn, 2.2, 5.0)
		LandmarkWhGothic.archivolt(lm, "Stone", Vector3(ax, 17.0, 64.5), fn, 2.2, 0.5, 0.3)
		lm.disc("Glass", Vector3(ax, 21.0, 64.56), fn, 0.9, 16)
		lm.gable("Stone", Vector3(ax, 30.5, 64.0), 6.2, 1.2, 1.6, Basis(), 0.0, "Stone")
		LandmarkWestKit.blk(lm, "Stone", ax, 30.5, 61.0, 2.4, 1.5, 2.4)
		LandmarkKits.statue_figure(lm, "Gilt", Vector3(ax, 32.0, 61.0), 3.6, true)
		for s2 in [-1.0, 1.0]:
			LandmarkKits.statue_figure(lm, "Gilt", Vector3(ax + s2 * 1.2, 32.0, 60.2), 2.4)
	_pavilions(lm)
	# Auditorium block, the ribbed copper dome and its crown lantern.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 9.0, 68.0, 33.0, 42.0)
	LandmarkWestKit.blk(lm, "Roof", 0, 33.0, 9.0, 66.0, 0.8, 40.0)
	LandmarkKits.dome_on_drum(lm, "Stone", "Dome", Vector3(0, 33.8, 6.0), 12.8, 3.4, 8.6, 0.0, 40, 24)
	lm.frustum("Stone", Vector3(0, 45.6, 6.0), 2.4, 2.2, 0.6, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Stone", Vector3(cos(a) * 2.0, 46.2, 6.0 + sin(a) * 2.0), 0.18, 0.16, 1.8, 8)
	lm.frustum("Stone", Vector3(0, 46.2, 6.0), 1.4, 1.4, 1.8, 12)
	lm.lathe("Dome", Vector3(0, 48.0, 6.0), LandmarkWestKit.dome_prof(2.5, 2.2, 6), 16)
	# Crown on the lantern: gilt fleurons round the top.
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Gilt", Vector3(cos(a) * 1.9, 48.6, 6.0 + sin(a) * 1.9), Vector3(0.3, 1.0, 0.3), Basis(), 0.0)
	lm.lathe("Gilt", Vector3(0, 50.1, 6.0), LandmarkWestKit.ball(0.4), 8)
	_stage_house(lm)
	LandmarkWhKit.shift(lm, Vector3(0, 0, 13.0))
	lm.commit(model)

## The arcade storey: seven arches with voussoirs and keystones between
## rusticated piers, and the four sculpture groups on pedestals before
## the end piers.
static func _arcade(lm: LandmarkMesh, fz: float) -> void:
	var fn := Vector3(0, 0, 1)
	for k in 7:
		var x := -27.0 + 9.0 * float(k)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(x, 0.8, fz + 0.12), fn, 6.0, 4.5)
		LandmarkDetail.arch(lm, "Stone", Vector3(x, 5.3, fz + 0.05), fn, 6.0, 0.7, 0.4)
	for k in 8:
		var x := -31.5 + 9.0 * float(k)
		LandmarkWestKit.blk(lm, "Stone", x, 0, fz + 0.3, 3.0, 9.5, 0.7)
		# Rusticated courses: banded blocks proud of the pier.
		for j in 6:
			LandmarkWestKit.blk(lm, "Stone", x, 0.9 + 1.4 * float(j), fz + 0.75, 3.1, 1.1, 0.25)
		if absf(x) > 20.0:
			LandmarkWestKit.blk(lm, "Stone", x, 0, fz + 2.2, 2.6, 1.8, 2.4)
			LandmarkKits.statue_figure(lm, "Column", Vector3(x, 1.8, fz + 2.4), 3.4, true)
			LandmarkKits.statue_figure(lm, "Column", Vector3(x + signf(x) * 0.8, 1.8, fz + 2.0), 2.8)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-36.0, 9.0, fz + 0.6), Vector3(36.0, 9.0, fz + 0.6), fn, 0.6, false)

## The loggia: sixteen coupled monolithic Corinthian columns (8 pairs)
## framing seven bays, each bay with a balustrade, a pair of small
## columns under a lintel and an oculus holding a gilded composer's
## bust; tall arched windows in the wall behind.
static func _loggia(lm: LandmarkMesh, fz: float) -> void:
	var fn := Vector3(0, 0, 1)
	for k in 8:
		var x := -28.0 + 8.0 * float(k)
		for dx in [-1.0, 1.0]:
			LandmarkDetail.column(lm, "Column", Vector3(x + dx, 10.2, 62.6), 0.66, 12.8, "corinthian", 0)
	for k in 7:
		var x := -24.0 + 8.0 * float(k)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(x, 11.0, 58.1), fn, 4.2, 6.0)
		LandmarkWhGothic.archivolt(lm, "Stone", Vector3(x, 17.0, 58.05), fn, 4.2, 0.4, 0.25)
		LandmarkWhGothic.balusters(lm, "Stone", Vector3(x - 2.6, 10.2, 62.6), Vector3(x + 2.6, 10.2, 62.6), 1.1, 0.42)
		for dx in [-1.6, 1.6]:
			lm.frustum("Column", Vector3(x + dx, 11.3, 61.4), 0.26, 0.22, 5.0, 10)
			lm.box("Stone", Vector3(x + dx, 16.5, 61.4), Vector3(0.6, 0.4, 0.6), Basis(), 0.0)
			lm.box("Stone", Vector3(x + dx, 11.4, 61.4), Vector3(0.6, 0.2, 0.6), Basis(), 0.0)
		LandmarkWestKit.blk(lm, "Stone", x, 16.7, 61.4, 4.2, 0.6, 0.8)
		# Oculus with the gilded bust.
		var oc := Vector3(x, 19.6, 61.0)
		for j in 16:
			var a0 := TAU * float(j) / 16.0
			var a1 := TAU * float(j + 1) / 16.0
			lm.beam("Stone", oc + Vector3(cos(a0), sin(a0), 0) * 1.25, oc + Vector3(cos(a1), sin(a1), 0) * 1.25, 0.4,
				0.3, fn)
		lm.disc("Glass", oc - Vector3(0, 0, 0.1), fn, 1.1, 16)
		lm.frustum("Gilt", oc - Vector3(0, 0.95, 0), 0.4, 0.3, 0.6, 8)
		lm.lathe("Gilt", oc - Vector3(0, 0.35, 0), LandmarkWestKit.ball(0.36), 8)

## The side pavilions: two rotundas under ribbed domes with arched
## windows and pilasters, joined to the auditorium by short blocks; the
## Pavillon de l'Empereur (west) with its double carriage ramp.
static func _pavilions(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		var c := Vector3(sx * 47.0, 0, 28.0)
		LandmarkKits.dome_on_drum(lm, "Stone", "Dome", c, 10.5, 24.0, 6.0, 3.2, 32, 16)
		LandmarkWestKit.blk(lm, "Stone", sx * 44.0, 0, 6.0, 16.0, 24.0, 20.0)
		LandmarkWestKit.hip(lm, "Roof", Vector3(sx * 44.0, 24.0, 6.0), 17.0, 21.0, 5.0, 0.5)
		lm.frustum("Stone", c + Vector3(0, 11.0, 0), 10.9, 10.9, 0.8, 32)
		for k in 10:
			var a := TAU * (float(k) + 0.5) / 10.0
			var d := Vector3(cos(a), 0, sin(a))
			if d.x * sx < -0.5:
				continue
			LandmarkDetail.window(lm, "Stone", "Glass", c + d * 10.6 + Vector3(0, 5.0, 0), d, 2.2, 5.0, true, 0.3)
			LandmarkWhGothic.oculus(lm, "Glass", "Stone", c + d * 10.6 + Vector3(0, 17.5, 0), d, 1.1, false)
		LandmarkWestKit.blk(lm, "Stone", sx * 44.0, 0, 6.0, 16.6, 1.0, 20.6)
	# Double ramp of the Pavillon de l'Empereur.
	for sz in [-1.0, 1.0]:
		var a := Vector3(-60.5, 0.5, 28.0 + sz * 22.0)
		var b := Vector3(-60.5, 6.0, 28.0 + sz * 4.0)
		lm.beam("Stone", a, b, 5.0, 1.0, Vector3(1, 0, 0), true)
		LandmarkWhGothic.balusters(lm, "Stone", a + Vector3(-2.4, 0.5, 0), b + Vector3(-2.4, 0.5, 0), 1.0, 0.4)
	LandmarkWestKit.blk(lm, "Stone", -60.5, 0, 28.0, 5.0, 6.5, 8.0)

## The stage house with its pedimented south gable: cornice, tympanum
## oculus, the golden Apollo raising his lyre at the apex between the
## two Pegasus groups at the ends, and the administration block behind.
static func _stage_house(lm: LandmarkMesh) -> void:
	var fn := Vector3(0, 0, 1)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -46.0, 48.0, 41.0, 68.0)
	lm.gable("Roof", Vector3(0, 41.0, -46.0), 48.0, 68.0, 9.0, Basis(), 0.4, "Stone")
	LandmarkDetail.cornice(lm, "Stone", Vector3(-24.4, 39.8, -11.9), Vector3(24.4, 39.8, -11.9), fn, 1.2, true)
	# Raking cornices of the pediment.
	for sx in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(sx * 24.6, 41.2, -11.6), Vector3(0, 50.2, -11.6), 0.9, 1.2, fn)
	lm.disc("Glass", Vector3(0, 44.0, -11.85), fn, 2.0, 20)
	for k in 3:
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(-12.0 + 12.0 * float(k), 30.0, -11.85), fn, 5.0, 4.0)
		LandmarkWhGothic.archivolt(lm, "Stone", Vector3(-12.0 + 12.0 * float(k), 34.0, -11.9), fn, 5.0, 0.5, 0.3)
	for k in 9:
		var x := -22.0 + 5.5 * float(k)
		LandmarkWestKit.blk(lm, "Stone", x, 26.0, -11.7, 1.2, 13.0, 0.6)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -88.0, 60.0, 27.0, 16.0)
	LandmarkWestKit.hip(lm, "Roof", Vector3(0, 27.0, -88.0), 61.0, 17.0, 4.0, 0.5)
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-28, 0, -96.1), Vector3(28, 0, -96.1), Vector3(0, 0, -1), 4.0,
		1.6, 3.0, [4.0, 11.0, 18.0, 24.0])
	# Apollo group on the apex (56 m) and the Pegasus groups.
	LandmarkWestKit.blk(lm, "Stone", 0, 49.6, -12.0, 3.4, 1.6, 3.0)
	LandmarkKits.statue_figure(lm, "Gilt", Vector3(0, 51.2, -12.0), 4.8, true)
	lm.box("Gilt", Vector3(0.9, 55.4, -12.0), Vector3(0.9, 1.1, 0.15), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		var p := Vector3(sx * 22.8, 41.0, -12.6)
		LandmarkWestKit.blk(lm, "Stone", p.x, p.y, p.z, 3.0, 1.0, 2.0)
		_pegasus(lm, "Dome", p + Vector3(0, 1.0, 0), -sx)

## A rearing winged horse about 4 m tall, facing along `facing` X.
static func _pegasus(lm: LandmarkMesh, key: String, base: Vector3, facing: float) -> void:
	var f := Vector3(facing, 0, 0)
	var hip := base + Vector3(0, 1.4, 0) - f * 0.8
	var chest := base + Vector3(0, 2.3, 0) + f * 0.6
	lm.beam(key, hip, chest, 0.9, 0.8)
	lm.beam(key, chest, chest + f * 0.5 + Vector3(0, 1.1, 0), 0.5, 0.45)
	lm.box(key, chest + f * 0.9 + Vector3(0, 1.2, 0), Vector3(0.8, 0.35, 0.35), Basis(), 0.0)
	for sz in [-0.25, 0.25]:
		lm.beam(key, hip + Vector3(0, 0, sz), base + Vector3(0, 0, sz) - f * 0.9, 0.22, 0.22)
		lm.beam(key, chest + Vector3(0, 0, sz), chest + f * 0.7 + Vector3(0, -0.3, sz), 0.2, 0.2)
		# Wings swept up and back.
		var root := (hip + chest) * 0.5 + Vector3(0, 0.4, sz * 1.4)
		lm.beam(key, root, root + Vector3(0, 1.3, sz * 3.0) - f * 0.6, 0.7, 0.12)
		lm.beam(key, root + Vector3(0, 1.3, sz * 3.0) - f * 0.6, root + Vector3(0, 1.6, sz * 4.4) - f * 1.4, 0.5, 0.1)
	lm.beam(key, hip, hip - f * 0.9 - Vector3(0, 0.7, 0), 0.18, 0.18)
