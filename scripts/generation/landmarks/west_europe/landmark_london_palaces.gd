class_name LandmarkLondonPalaces
extends RefCounted

## The Tower of London and Buckingham Palace in true metres, y = 0 at
## street level.

## Tower of London (27.5 m): the White Tower (1078-1100), 36 x 32.5 m,
## with its pilaster strips, Wren's paired round-headed windows, the
## battlements, three square turrets and the round north-east one, all
## crowned with ogee lead cupolas and gilt vanes, the chapel apse and the
## south forebuilding stair; the inner curtain with its thirteen towers
## (Beauchamp, Bell, Bloody, Wakefield, Salt, Martin, Devereux...), the
## outer curtain with the Byward and Middle Towers and St Thomas's Tower
## over Traitors' Gate, the grass moat; the Waterloo Block (the Jewel
## House), the Chapel Royal of St Peter ad Vincula and the half-timbered
## Queen's House on Tower Green. Thames to the south (+Z).
static func tower_of_london(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#CFC6B2", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#9B8F7C", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4A", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Timber", LandmarkMaterials.paint("#3B3026", 0.8, 0.0))
	lm.use("Render", LandmarkMaterials.pbr("render", "#E8E2D2", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A49C8C", 4.0))
	_white_tower(lm)
	var inner: Array[Vector2] = [Vector2(-100, -55), Vector2(-35, -62), Vector2(45, -58), Vector2(62, -20),
		Vector2(62, 38), Vector2(10, 45), Vector2(-60, 40), Vector2(-100, 10)]
	var outer: Array[Vector2] = [Vector2(-135, -100), Vector2(0, -108), Vector2(110, -95), Vector2(120, -10),
		Vector2(112, 60), Vector2(40, 84), Vector2(-70, 86), Vector2(-130, 40)]
	var moat: Array[Vector2] = [Vector2(-165, -130), Vector2(0, -140), Vector2(140, -125), Vector2(150, -10),
		Vector2(140, 75), Vector2(40, 96), Vector2(-75, 98), Vector2(-160, 55)]
	lm.poly_prism("Lawn", PackedVector2Array(moat), 0.0, 0.03)
	lm.poly_prism("Paving", PackedVector2Array(outer), 0.0, 0.06)
	lm.poly_prism("Lawn", PackedVector2Array(inner), 0.0, 0.09)
	LandmarkWestKit.blk(lm, "Paving", -10.0, 0, 110.0, 300.0, 0.6, 24.0)
	_ring(lm, inner, 9.0, 3.0, 9.0, 15.0, false)
	_ring(lm, outer, 6.5, 2.5, 9.0, 11.0, true)
	# Mid-wall towers: Beauchamp (west), Bloody (south gate), Wakefield.
	_round_tower(lm, Vector3(-100, 0, -22), 8.0, 16.0)
	LandmarkWestKit.blk(lm, "Wall", -22.0, 0, 42.6, 12.0, 15.0, 10.0)
	LandmarkWestKit.merlons(lm, "Wall", Vector3(-28, 15, 37.8), Vector3(-16, 15, 37.8), 1.6, 0.9, 1.0, 0.6)
	LandmarkWestKit.merlons(lm, "Wall", Vector3(-28, 15, 47.4), Vector3(-16, 15, 47.4), 1.6, 0.9, 1.0, 0.6)
	LandmarkDetail.arch(lm, "Wall", Vector3(-22.0, 3.5, 47.6), Vector3(0, 0, 1), 5.0, 0.7)
	lm.box("Timber", Vector3(-22.0, 3.0, 47.65), Vector3(4.6, 6.0, 0.1), Basis(), 0.0)
	_round_tower(lm, Vector3(2, 0, 45), 9.5, 17.0)
	# Byward and Middle Towers (twin drums) at the west entrance, and
	# St Thomas's Tower over Traitors' Gate on the river front.
	for gx in [-150.0, -126.0]:
		for gz in [-6.0, 6.0]:
			_round_tower(lm, Vector3(gx, 0, 70.0 + gz), 5.5, 13.0)
		LandmarkWestKit.blk(lm, "Wall", gx, 0, 70.0, 8.0, 12.0, 8.0)
		LandmarkDetail.arch(lm, "Wall", Vector3(gx - 4.0, 3.0, 70.0), Vector3(-1, 0, 0), 4.0, 0.6)
	LandmarkWestKit.blk(lm, "Wall", -10.0, 0, 88.0, 26.0, 10.0, 10.0)
	LandmarkWestKit.merlons(lm, "Wall", Vector3(-23, 10, 93.0), Vector3(3, 10, 93.0), 2.0, 1.0, 1.0, 0.8)
	LandmarkDetail.arch(lm, "Wall", Vector3(-10.0, 1.0, 93.0), Vector3(0, 0, 1), 18.0, 1.2)
	lm.box("Timber", Vector3(-10.0, 3.5, 93.05), Vector3(14.0, 6.5, 0.15), Basis(), 0.0)
	for gx in [-23.0, 3.0]:
		_round_tower(lm, Vector3(gx, 0, 93.0), 3.5, 13.0)
	_ward_buildings(lm)
	lm.commit(model)

## The White Tower: keep, turrets with cupolas, windows, apse, stair.
static func _white_tower(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "White", 0, 0, 0, 36.0, 24.0, 32.0)
	LandmarkWestKit.blk(lm, "White", 0, 0, 0, 37.0, 2.0, 33.0)
	var keep: Array[Vector2] = [Vector2(-18, -16), Vector2(18, -16), Vector2(18, 16), Vector2(-18, 16)]
	for i in 4:
		var a := Vector3(keep[i].x, 0, keep[i].y)
		var b := Vector3(keep[(i + 1) % 4].x, 0, keep[(i + 1) % 4].y)
		var dir := (b - a).normalized()
		var n := dir.cross(Vector3.UP).normalized() * -1.0
		if n.dot(a + b) < 0.0:
			n = -n
		LandmarkWestKit.merlons(lm, "White", a + Vector3(0, 24.0, 0), b + Vector3(0, 24.0, 0), 2.6, 1.4, 1.2, 0.8)
		# Pilaster strips and paired round-headed windows in each bay.
		var span := a.distance_to(b)
		var bays := 4
		for k in bays + 1:
			var p := a.lerp(b, float(k) / float(bays))
			lm.box("White", p + Vector3(0, 12.0, 0) + n * 0.3, Vector3(2.2, 24.0, 0.6), Basis.looking_at(n))
		for k in bays:
			var p := a.lerp(b, (float(k) + 0.5) / float(bays))
			for y in [8.0, 14.5, 20.0]:
				for q in [-1.0, 1.0]:
					LandmarkDetail.window(lm, "White", "Glass", p + dir * q * 1.3 * (span / 36.0) + Vector3(0, y, 0), n,
						1.0, 2.4, true, 0.25)
	# Turrets: three square, the round north-east one; ogee cupolas, vanes.
	for s in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var t := Vector3(s.x * 16.0, 0, s.y * 14.0)
		LandmarkWestKit.blk(lm, "White", t.x, 0, t.z, 6.0, 25.2, 6.0)
		LandmarkWestKit.blk(lm, "White", t.x, 25.2, t.z, 6.6, 0.5, 6.6)
		lm.lathe("Slate", t + Vector3(0, 25.7, 0), LandmarkWestKit.ogee_prof(2.9, 2.3), 4, 1.0, 1.0, PI * 0.25, false)
		_vane(lm, t + Vector3(0, 28.0, 0))
	var ne := Vector3(16, 0, -14)
	lm.frustum("White", ne, 4.4, 4.4, 25.2, 16)
	lm.frustum("White", ne + Vector3(0, 25.2, 0), 4.7, 4.7, 0.5, 16)
	lm.lathe("Slate", ne + Vector3(0, 25.7, 0), LandmarkWestKit.ogee_prof(4.2, 2.3), 16)
	_vane(lm, ne + Vector3(0, 28.0, 0))
	# St John's Chapel apse (south-east) and the forebuilding stair (south).
	lm.lathe("White", Vector3(17, 0, 10), PackedVector2Array([Vector2(5.8, 0), Vector2(5.8, 22.0)]), 16,
		1.0, 1.0, 0.0, false)
	LandmarkWestKit.merlons(lm, "White", Vector3(22.8, 22.0, 6.0), Vector3(22.8, 22.0, 14.0), 2.4, 1.2, 1.0, 0.8)
	LandmarkWestKit.blk(lm, "White", -8.0, 0, 18.5, 10.0, 7.0, 5.0)
	for k in 8:
		lm.box("Timber", Vector3(-1.0 + 1.2 * float(k), 0.45 * float(k) + 0.2, 21.5), Vector3(1.2, 0.4, 2.2), Basis(), 0.0)
	lm.beam("Timber", Vector3(-1.5, 1.0, 22.6), Vector3(8.6, 4.6, 22.6), 0.15, 0.15)
	lm.box("Timber", Vector3(-8.0, 9.0, 16.4), Vector3(4.0, 4.0, 0.1), Basis(), 0.0)

## Gilt weathervane: a crown-topped spindle and a pennant.
static func _vane(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Gilt", base + Vector3(0, 0.55, 0), Vector3(0.08, 1.1, 0.08), Basis(), 0.0)
	lm.box("Gilt", base + Vector3(0.25, 0.85, 0), Vector3(0.5, 0.3, 0.03), Basis(), 0.0)
	lm.lathe("Gilt", base + Vector3(0, 1.0, 0), LandmarkWestKit.ball(0.12), 6)

## Round tower (drum) on `base`: battered foot, string course, arrow
## loops and a crenellated parapet on a flat roof.
static func _round_tower(lm: LandmarkMesh, base: Vector3, d: float, h: float) -> void:
	var r := d * 0.5
	lm.lathe("Wall", base, PackedVector2Array([Vector2(r * 1.12, 0), Vector2(r, h * 0.2), Vector2(r, h)]), 16,
		1.0, 1.0, 0.0, true)
	lm.frustum("Wall", base + Vector3(0, h, 0), r * 1.06, r * 1.06, 0.4, 16)
	var cnt := maxi(int(TAU * r / 2.2), 6)
	for k in cnt:
		var a := TAU * float(k) / float(cnt)
		var dir := Vector3(cos(a), 0, sin(a))
		lm.box("Wall", base + dir * r * 0.98 + Vector3(0, h + 0.4 + 0.6, 0), Vector3(1.1, 1.2, r * 0.18), Basis.looking_at(dir))
		if k % 2 == 0:
			lm.box("Glass", base + dir * (r + 0.01) + Vector3(0, h * 0.55, 0), Vector3(0.25, 1.6, 0.05), Basis.looking_at(dir), 0.0)

## Curtain wall round `pts` with a tower at every corner: wall walk
## battlements and, inside, a lean-to of the wall walk; square towers
## crenellated with corner bartizans, round drums by _round_tower.
static func _ring(lm: LandmarkMesh, pts: Array[Vector2], wall_h: float, thick: float,
		tower: float, tower_h: float, round: bool) -> void:
	for i in pts.size():
		var a := Vector3(pts[i].x, 0, pts[i].y)
		var b := Vector3(pts[(i + 1) % pts.size()].x, 0, pts[(i + 1) % pts.size()].y)
		var d := b - a
		lm.box("Wall", (a + b) * 0.5 + Vector3(0, wall_h * 0.5, 0), Vector3(thick, wall_h, d.length()),
			Basis(Vector3.UP, atan2(d.x, d.z)))
		LandmarkWestKit.merlons(lm, "Wall", a + Vector3(0, wall_h, 0), b + Vector3(0, wall_h, 0), 2.4, 1.2, 1.0,
			thick * 0.9)
		if round:
			_round_tower(lm, a, tower, tower_h)
		else:
			LandmarkWestKit.blk(lm, "Wall", a.x, 0, a.z, tower, tower_h, tower)
			LandmarkWestKit.blk(lm, "Wall", a.x, tower_h - 1.2, a.z, tower + 0.6, 0.6, tower + 0.6)
			for s in 4:
				var bs := Basis(Vector3.UP, PI * 0.5 * float(s))
				LandmarkWestKit.merlons(lm, "Wall", a + bs * Vector3(-tower * 0.5, tower_h, tower * 0.5),
					a + bs * Vector3(tower * 0.5, tower_h, tower * 0.5), 1.8, 1.0, 1.1, 0.6)
				for y in [tower_h * 0.35, tower_h * 0.65]:
					lm.box("Glass", a + bs * Vector3(0, y, tower * 0.5 + 0.01), Vector3(0.3, 1.8, 0.05), bs, 0.0)
			lm.frustum("Wall", a + Vector3(tower * 0.5 - 0.8, tower_h, -tower * 0.5 + 0.8), 0.9, 0.9, 2.4, 8)
			lm.lathe("Slate", a + Vector3(tower * 0.5 - 0.8, tower_h + 2.4, -tower * 0.5 + 0.8),
				LandmarkWestKit.ogee_prof(1.0, 1.4), 8)

## Waterloo Block, the Chapel Royal and the Queen's House.
static func _ward_buildings(lm: LandmarkMesh) -> void:
	# Waterloo Block (1845): Gothic-revival barracks with corner turrets.
	LandmarkWestKit.blk(lm, "Wall", 2.0, 0, -40.0, 84.0, 15.0, 14.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(2.0, 15.0, -40.0), 84.0, 14.0, 3.0, 0.7)
	LandmarkDetail.pierced_face(lm, "Wall", "Glass", Vector3(-40.0, 0, -33.0), Vector3(1, 0, 0), Vector3(0, 0, 1),
		84.0, 15.0, 24, 3, Vector2(1.6, 2.6), 1.6, 4.4, 0.35)
	LandmarkWestKit.merlons(lm, "Wall", Vector3(-40, 15.0, -32.8), Vector3(44, 15.0, -32.8), 2.0, 1.0, 1.0, 0.5)
	for x in [-40.0, -12.0, 16.0, 44.0]:
		LandmarkWestKit.blk(lm, "Wall", x, 0, -33.5, 4.0, 18.5, 4.0)
		LandmarkWestKit.merlons(lm, "Wall", Vector3(x - 2.0, 18.5, -31.5), Vector3(x + 2.0, 18.5, -31.5), 1.4, 0.7, 0.8, 0.4)
	LandmarkWestKit.portal(lm, "Wall", "Timber", Vector3(2.0, 0, -33.0), Vector3(0, 0, 1), 3.0, 5.5, 2, true)
	# Chapel Royal of St Peter ad Vincula (1519) with its bell turret.
	var c := Vector3(-72.0, 0, -42.0)
	LandmarkWestKit.blk(lm, "Wall", c.x, 0, c.z, 30.0, 8.0, 12.0)
	lm.gable("Slate", c + Vector3(0, 8.0, 0), 12.0, 30.0, 4.5, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	for k in 5:
		LandmarkWestKit.lancet(lm, "White", "Glass", c + Vector3(-12.0 + 6.0 * float(k), 1.8, 6.0), Vector3(0, 0, 1),
			2.2, 4.4, true, 0.2)
	LandmarkWestKit.blk(lm, "Wall", c.x - 13.5, 0, c.z, 4.0, 13.0, 4.0)
	LandmarkWestKit.merlons(lm, "Wall", Vector3(c.x - 15.5, 13.0, c.z + 2.0), Vector3(c.x - 11.5, 13.0, c.z + 2.0), 1.3, 0.6, 0.8, 0.4)
	lm.frustum("Render", c + Vector3(-13.5, 13.0, 0), 1.0, 1.0, 2.0, 8)
	lm.lathe("Slate", c + Vector3(-13.5, 15.0, 0), LandmarkWestKit.ogee_prof(1.2, 1.8), 8)
	_vane(lm, c + Vector3(-13.5, 16.8, 0))
	# Queen's House (1540): jettied, half-timbered Tudor range.
	var q := Vector3(-78.0, 0, 24.0)
	LandmarkWestKit.blk(lm, "Render", q.x, 0, q.z, 26.0, 4.0, 10.0)
	LandmarkWestKit.blk(lm, "Render", q.x, 4.0, q.z - 0.4, 26.0, 4.0, 10.8)
	LandmarkWestKit.blk(lm, "Render", q.x, 8.0, q.z - 0.8, 26.0, 3.6, 11.6)
	lm.gable("Slate", q + Vector3(0, 11.6, -0.8), 11.6, 26.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Render")
	var fz := q.z - 6.65
	for k in 27:
		var x := q.x - 13.0 + float(k)
		for st in 3:
			var z := q.z - 5.0 - 0.4 * float(st) - 0.03
			lm.box("Timber", Vector3(x, 4.0 * float(st) + 2.0, z), Vector3(0.22, 3.8, 0.06), Basis(), 0.0)
	for st in 3:
		var z := q.z - 5.0 - 0.4 * float(st) - 0.04
		lm.box("Timber", Vector3(q.x, 4.0 * float(st) + 0.15, z), Vector3(26.0, 0.3, 0.08), Basis(), 0.0)
		for k in 5:
			lm.box("Glass", Vector3(q.x - 10.0 + 5.0 * float(k), 4.0 * float(st) + 2.0, z - 0.02), Vector3(2.4, 1.4, 0.04),
				Basis(), 0.0)
	for k in 4:
		lm.gable("Slate", Vector3(q.x - 9.0 + 6.0 * float(k), 11.6, fz + 1.0), 3.6, 2.0, 2.4, Basis(), 0.2, "Render")
		LandmarkWestKit.chimney(lm, "Wall", Vector3(q.x - 12.0 + 8.0 * float(k), 14.0, q.z + 1.0), 1.0, 1.6, 3.2)

## Buckingham Palace (24 m): the quadrangle of 1825-1850 behind Aston
## Webb's 1913 Portland-stone east front (+X, facing The Mall): 108 m
## long, rusticated ground floor, two storeys under a giant Corinthian
## order — coupled columns and the pediment with the royal arms on the
## centre, pilasters and pediments on the end pavilions — the central
## balcony, the attic balustrade, chimney stacks; the garden front's
## central bow (west), and the gilded forecourt railings and gates.
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
	for r in [[49.0, 0.0, 22.0, 108.0], [-49.0, 0.0, 22.0, 108.0], [0.0, 43.0, 120.0, 22.0],
			[0.0, -43.0, 120.0, 22.0]]:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], 19.0, r[3])
		LandmarkWestKit.blk(lm, "Stone", r[0], 19.0, r[1], r[2] + 0.8, 1.0, r[3] + 0.8)
		LandmarkWestKit.blk(lm, "Slate", r[0], 20.0, r[1], r[2] - 2.0, 0.8, r[3] - 2.0)
	LandmarkWestKit.blk(lm, "Court", 0, 0, 0, 76.0, 0.3, 64.0)
	for k in 6:
		LandmarkWestKit.chimney(lm, "Stone", Vector3(49.0, 20.8, -40.0 + 16.0 * float(k)), 1.4, 3.6, 2.6)
		LandmarkWestKit.chimney(lm, "Stone", Vector3(-49.0, 20.8, -40.0 + 16.0 * float(k)), 1.4, 3.6, 2.6)
	var e := Vector3(1, 0, 0)
	# East front: 23 bays, three storeys, giant pilasters, cornice, balustrade.
	LandmarkWestKit.blk(lm, "Stone", 60.6, 0, 0, 1.2, 6.0, 108.0)
	for k in 12:
		LandmarkWestKit.blk(lm, "Stone", 61.25, 0.5 * float(k), 0, 0.1, 0.12, 108.0)
	# The rusticated ground-floor skin projects beyond the main wall, so
	# its windows must sit on that face rather than inside the solid skin.
	LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(61.22, 0, -52.0), Vector3(61.22, 0, 52.0), e, 23,
		[1.8], [Vector2(1.6, -3.2)], 0.0)
	LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(60.0, 0, -52.0), Vector3(60.0, 0, 52.0), e, 23,
		[7.4, 13.4], [Vector2(1.8, 3.8), Vector2(1.6, 3.0)], 0.0)
	for k in 24:
		var z := -52.0 + 104.0 * float(k) / 23.0
		if absf(z) > 13.0:
			lm.box("Stone", Vector3(60.35, 12.4, z), Vector3(0.7, 12.4, 1.1))
	LandmarkDetail.cornice(lm, "Stone", Vector3(60.0, 18.6, -54.0), Vector3(60.0, 18.6, 54.0), e, 1.2)
	LandmarkWestKit.rail(lm, "Stone", Vector3(60.4, 20.0, -54.0), Vector3(60.4, 20.0, 54.0), 1.2, 0.6)
	# End pavilions with pilasters and segmental pediments.
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", 61.0, 0, sz * 46.0, 3.0, 21.0, 16.0)
		LandmarkWestKit.blk(lm, "Stone", 61.0, 21.0, sz * 46.0, 4.0, 1.0, 17.0)
		for pz in [-6.5, -2.2, 2.2, 6.5]:
			lm.box("Stone", Vector3(62.7, 13.0, sz * 46.0 + pz), Vector3(0.6, 14.0, 1.2))
		LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(62.55, 0, sz * 46.0 - 6.2),
			Vector3(62.55, 0, sz * 46.0 + 6.2), e, 3, [1.8, 7.4, 13.4],
			[Vector2(1.6, -3.2), Vector2(1.8, 3.8), Vector2(1.6, 3.0)])
		lm.gable("Stone", Vector3(62.0, 22.0, sz * 46.0), 14.0, 2.4, 2.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	# Centre: coupled giant Corinthian columns, balcony, pediment.
	LandmarkWestKit.blk(lm, "Stone", 62.0, 0, 0, 4.0, 20.0, 26.0)
	LandmarkWestKit.bay_run(lm, "Stone", "Glass", Vector3(64.05, 0, -10.0), Vector3(64.05, 0, 10.0), e, 5,
		[1.8, 7.4, 13.4], [Vector2(1.6, -3.2), Vector2(1.8, 3.8), Vector2(1.6, 3.0)])
	for pz in [-10.5, -4.5, 4.5, 10.5]:
		for dz in [-0.8, 0.8]:
			LandmarkDetail.column(lm, "Stone", Vector3(64.6, 6.0, pz + dz), 0.55, 12.4, "corinthian", 0)
	LandmarkWestKit.blk(lm, "Stone", 63.0, 6.0, 0, 6.0, 0.6, 18.0)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(65.6, 6.6, -8.0), Vector3(65.6, 6.6, 8.0), 1.1, 4.0)
	LandmarkWestKit.blk(lm, "Stone", 63.0, 18.4, 0, 6.0, 1.6, 26.0)
	lm.gable("Stone", Vector3(63.0, 20.0, 0), 26.0, 6.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	lm.box("Gilt", Vector3(66.1, 21.4, 0), Vector3(0.2, 2.0, 3.0), Basis(), 0.0)
	# Garden front: pierced storeys and the central bow.
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-60.0, 0, 54.0), Vector3(0, 0, -1), Vector3(-1, 0, 0),
		108.0, 19.0, 27, 3, Vector2(1.7, 3.2), 2.0, 5.8, 0.35)
	lm.lathe("Stone", Vector3(-60, 0, 0), PackedVector2Array([Vector2(12, 0), Vector2(12, 19)]), 20, 0.5, 1.0)
	for k in 7:
		var a := PI * 0.5 + PI * (float(k) + 0.5) / 7.0
		var d := Vector3(cos(a) * 0.5, 0, sin(a)).normalized()
		var p := Vector3(-60, 0, 0) + Vector3(cos(a) * 6.0, 0, sin(a) * 12.0)
		for y in [3.6, 9.4, 15.0]:
			lm.box("Glass", p + Vector3(0, y, 0) + d * 0.05, Vector3(1.6, 3.0, 0.08), Basis.looking_at(d), 0.0)
	# Forecourt: railings with gilded tips, piers, the Centre Gate.
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
	lm.commit(model)
