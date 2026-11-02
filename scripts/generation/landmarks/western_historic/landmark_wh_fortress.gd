class_name LandmarkWhFortress
extends RefCounted

## Three French fortress-palaces in true metres, y = 0 at the ground
## of the main front: the Palais des Papes, the Cité of Carcassonne and
## the Château de Chambord.

## Palais des Papes (52 m to the top of the Trouillas tower): the
## pale limestone fortress-palace of Avignon on its rock. The Old
## Palace round its cloister to the north, the New Palace and Great
## Chapel along the south front to the Place du Palais (+Z), the
## Cour d'Honneur between them, the buttressed walls under their
## machicolated crowns and the square towers at the corners and gates.
static func palais_des_papes(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2C6A4", 3.5))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8F8774", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B0643F", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.poly_prism("Rock", PackedVector2Array([Vector2(-60, -55), Vector2(60, -55), Vector2(62, 54),
		Vector2(-62, 54)]), -12.0, -0.3)
	# Old Palace ring round the cloister, east block, link and New Palace.
	var ring := [[-20.0, -46.0, 70.0, 8.0], [-20.0, -16.0, 70.0, 8.0], [-45.0, -31.0, 20.0, 22.0],
		[5.0, -31.0, 20.0, 22.0]]
	for r in ring:
		LandmarkWestKit.blk(lm, "Stone", r[0], 0, r[1], r[2], 38.0, r[3])
	LandmarkWestKit.blk(lm, "Stone", -40.0, 0, 0, 30.0, 34.0, 24.0)
	LandmarkWestKit.blk(lm, "Stone", 35.0, 0, -19.0, 40.0, 34.0, 62.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 31.0, 110.0, 40.0, 38.0)
	# Terracotta roofs of the Great Chapel and the Grand Tinel hall.
	lm.gable("Tile", Vector3(0, 40.0, 36.0), 16.0, 56.0, 4.5, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	lm.gable("Tile", Vector3(35.0, 34.0, -19.0), 22.0, 40.0, 4.5, Basis(), 0.3, "Stone")
	# Crenellated crowns on the outer wall tops, edge by edge (x0, z0, x1, z1, h).
	for e in [[-55.0, -50.0, 15.0, -50.0, 38.0], [15.0, -50.0, 55.0, -50.0, 34.0],
			[55.0, -50.0, 55.0, 12.0, 34.0], [55.0, 12.0, 55.0, 50.0, 40.0], [55.0, 50.0, -55.0, 50.0, 40.0],
			[-55.0, 50.0, -55.0, 12.0, 40.0], [-55.0, 12.0, -55.0, -12.0, 34.0], [-55.0, -12.0, -55.0, -50.0, 38.0]]:
		_crown_edge(lm, Vector3(e[0], e[4], e[1]), Vector3(e[2], e[4], e[3]))
	# Buttresses and tall lancets on the south front, small windows elsewhere.
	for k in 8:
		var bx := -49.0 + 14.0 * float(k)
		LandmarkWestKit.blk(lm, "Stone", bx, 0, 51.6, 3.2, 34.0, 3.6)
		LandmarkWestKit.blk(lm, "Stone", bx, 34.0, 51.9, 3.6, 1.6, 4.2)
		if k < 7:
			LandmarkWhKit.lancet(lm, "Glass", Vector3(bx + 7.0, 17.0, 50.1), Vector3(0, 0, 1), 2.6, 11.0, 3.0)
			LandmarkWhKit.lancet(lm, "Glass", Vector3(bx + 7.0, 6.0, 50.1), Vector3(0, 0, 1), 1.0, 3.0, 1.0)
	LandmarkWhKit.lancet(lm, "Glass", Vector3(-55.1, 0, -4.0), Vector3(-1, 0, 0), 4.0, 6.0, 3.4)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-45, 0, -50.1), Vector3(10, 0, -50.1), Vector3(0, 0, -1),
		6, 1.0, 3.0, 20.0, 1.0)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-24, 0, 12.1), Vector3(14, 0, 12.1), Vector3(0, 0, 1),
		5, 2.4, 9.0, 12.0, 2.6)
	LandmarkWhKit.lancet_row(lm, "Glass", Vector3(-24, 0, -11.9), Vector3(14, 0, -11.9), Vector3(0, 0, -1),
		5, 2.0, 8.0, 14.0, 2.4)
	# Towers: (x, z, size, body height); the Trouillas tower tops at 52 m.
	for t in [[45.0, -45.0, 14.0, 50.8], [-49.0, -44.0, 13.0, 49.0], [-49.0, 44.0, 13.0, 47.0],
			[49.0, 44.0, 13.0, 50.0], [-14.0, -46.0, 12.0, 46.0], [18.0, 49.0, 11.0, 48.0],
			[-30.0, 49.0, 11.0, 47.0], [53.0, -10.0, 11.0, 44.0], [-54.0, 0.0, 10.0, 43.0]]:
		var sz: float = t[2]
		LandmarkWestKit.blk(lm, "Stone", t[0], 0, t[1], sz, t[3], sz)
		LandmarkWestKit.blk(lm, "Stone", t[0], t[3] - 2.6, t[1], sz + 1.8, 2.6, sz + 1.8)
		_crown_rect(lm, t[0], t[1], sz + 1.8, t[3])
		LandmarkWhKit.lancet_row(lm, "Glass", Vector3(t[0] - sz * 0.25, 0, t[1] + sz * 0.51),
			Vector3(t[0] + sz * 0.25, 0, t[1] + sz * 0.51), Vector3(0, 0, 1), 2, 1.1, 4.0, t[3] * 0.62, 1.2)
	lm.commit(model)

## Machicolated crown along an edge a -> b (points at the wall top).
static func _crown_edge(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var d := b - a
	lm.box("Stone", (a + b) * 0.5 + Vector3(0, -1.1, 0), Vector3(2.6, 2.2, d.length() + 2.0),
		Basis(Vector3.UP, atan2(d.x, d.z)))
	LandmarkWestKit.merlons(lm, "Stone", a, b, 3.4, 1.8, 1.4, 1.1)

## Merlons round a square tower top of side `s` centred (cx, cz) at y.
static func _crown_rect(lm: LandmarkMesh, cx: float, cz: float, s: float, y: float) -> void:
	var h := s * 0.5
	var c := [Vector3(cx - h, y, cz - h), Vector3(cx + h, y, cz - h), Vector3(cx + h, y, cz + h),
		Vector3(cx - h, y, cz + h)]
	for i in 4:
		LandmarkWestKit.merlons(lm, "Stone", c[i], c[(i + 1) % 4], 3.0, 1.6, 1.2, 1.0)

## Cité de Carcassonne (32 m to the Tour de la Justice): the double
## ring of walls round the hill, 28 inner towers and 16 outer towers
## under pointed slate roofs, the Narbonnaise and Aude gates, the
## Château Comtal at the west end with its four towers, the Romanesque
## and Gothic basilica of Saint-Nazaire and the terracotta roofs of
## the old town between. Long axis east-west.
static func carcassonne(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#B4A486", 4.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#5B646B", 2.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A85A3C", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8C8372", 5.0))
	lm.use("Ground", LandmarkMaterials.pbr("gravel", "#A09580", 5.0))
	var inner := _oval(28, 250.0, 118.0, PI / 28.0)
	var core := _scaled(inner, 0.9)
	var outer := _oval(16, 276.0, 144.0, 0.15)
	lm.poly_prism("Rock", _oval(32, 292.0, 160.0, 0.1), -18.0, -0.3)
	lm.poly_prism("Ground", outer, -0.3, 0.05)
	# Inner wall (10 m, towers 22 m + roof) and outer wall (7 m, low towers).
	for i in inner.size():
		var a := Vector3(inner[i].x, 0, inner[i].y)
		var b := Vector3(inner[(i + 1) % inner.size()].x, 0, inner[(i + 1) % inner.size()].y)
		LandmarkWhKit.crenel_wall(lm, "Wall", a, b, 10.0, 3.2, 3.4)
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", a, 4.8, 4.4, 18.0 + float(i % 3) * 1.4, 8.5, 12)
	for i in outer.size():
		var a := Vector3(outer[i].x, 0, outer[i].y)
		var b := Vector3(outer[(i + 1) % outer.size()].x, 0, outer[(i + 1) % outer.size()].y)
		LandmarkWhKit.crenel_wall(lm, "Wall", a, b, 7.0, 2.6, 3.4)
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", a, 3.6, 3.3, 11.0, 5.5, 10)
	# Narbonnaise gate (east): two towers round a vaulted passage.
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", Vector3(255.0, 0, sz * 10.0), 6.4, 6.0, 19.0, 9.0, 14)
		LandmarkWestKit.blk(lm, "Wall", 255.0, 0, sz * 3.45, 12.0, 3.0, 2.1)
	LandmarkWestKit.arch_wall(lm, "Wall", Basis(Vector3.UP, PI * 0.5), Vector3(255.0, 0, 0), 4.5, 6.0, 2.4, 3.0, 12.0)
	# Château Comtal: courtyard castle at the west end, four corner towers.
	LandmarkWestKit.blk(lm, "Wall", -210.0, 0, 0, 64.0, 13.0, 56.0)
	LandmarkWestKit.blk(lm, "Ground", -210.0, 13.0, 0, 52.0, 0.4, 44.0)
	LandmarkWestKit.blk(lm, "Wall", -222.0, 13.0, -14.0, 36.0, 9.0, 14.0)
	lm.gable("Slate", Vector3(-222.0, 22.0, -14.0), 14.0, 36.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var big: bool = q.x < 0.0 and q.y < 0.0
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", Vector3(-210.0 + q.x * 32.0, 0, q.y * 28.0), 6.4, 6.0,
			22.0 if big else 20.0, 10.0 if big else 8.5, 14)
	LandmarkWhKit.crenel_wall(lm, "Wall", Vector3(-178, 0, -28), Vector3(-178, 0, 28), 14.0, 3.0)
	# Basilica Saint-Nazaire: nave, transept, polygonal apse, crossing tower.
	var bc := Vector3(112.0, 0, 66.0)
	LandmarkWestKit.blk(lm, "Wall", bc.x - 14.0, 0, bc.z, 30.0, 14.0, 15.0)
	lm.gable("Slate", bc + Vector3(-14.0, 14.0, 0), 15.0, 30.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	LandmarkWestKit.blk(lm, "Wall", bc.x + 8.0, 0, bc.z, 14.0, 18.0, 34.0)
	lm.gable("Slate", bc + Vector3(8.0, 18.0, 0), 14.0, 34.0, 6.0, Basis(), 0.5, "Wall")
	lm.lathe("Wall", bc + Vector3(22.0, 0, 0), PackedVector2Array([Vector2(8.5, 0), Vector2(8.5, 18.0)]), 7,
		1.0, 1.0, PI / 7.0, false)
	lm.lathe("Slate", bc + Vector3(22.0, 18.0, 0), PackedVector2Array([Vector2(9.0, 0), Vector2(0, 8.0)]), 7)
	LandmarkWestKit.blk(lm, "Wall", bc.x + 8.0, 18.0, bc.z, 7.0, 6.0, 7.0)
	LandmarkWestKit.hip(lm, "Slate", bc + Vector3(8.0, 24.0, 0), 7.6, 7.6, 5.0, 0.0)
	# The old town: terracotta-roofed houses on a loose grid inside the wall.
	var seed_v := 7
	for gx in range(-230, 235, 17):
		for gz in range(-110, 115, 17):
			seed_v = (seed_v * 1103515245 + 12345) & 0x7fffffff
			var p := Vector2(float(gx) + float(seed_v % 5), float(gz) + float((seed_v >> 4) % 5))
			var near_castle := p.x < -170.0 and absf(p.y) < 40.0
			var near_church := p.distance_to(Vector2(bc.x + 8.0, bc.z)) < 34.0
			var near_gate := p.x > 236.0
			if (seed_v >> 8) % 100 < 38 or near_castle or near_church or near_gate:
				continue
			if not Geometry2D.is_point_in_polygon(p, core):
				continue
			var w := 9.0 + float((seed_v >> 12) % 5)
			var d := 8.0 + float((seed_v >> 16) % 5)
			LandmarkWestKit.blk(lm, "Wall", p.x, 0, p.y, w, 6.0, d)
			lm.gable("Tile", Vector3(p.x, 6.0, p.y), w, d, 3.2, Basis(Vector3.UP, PI * 0.5 * float((seed_v >> 20) % 2)),
				0.4, "Wall")
	lm.commit(model)

## Wobbly oval of `n` vertices (semi-axes a along X, b along Z).
static func _oval(n: int, a: float, b: float, phase: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var t := TAU * float(i) / float(n) + phase
		var k := 1.0 + 0.05 * sin(3.0 * t + 0.5) + 0.03 * sin(5.0 * t)
		pts.append(Vector2(cos(t) * a * k, sin(t) * b * k))
	return pts

static func _scaled(pts: PackedVector2Array, f: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p * f)
	return out

## Château de Chambord (56 m to the lantern finial): the Renaissance
## keep with a round tower at each corner, its tuffeau walls in four
## storeys of tall windows, the roof terrace's skyline of dormers,
## chimney stacks and turrets, the great lantern over the double-helix
## staircase, and the two wings behind closing the court. Front +Z.
static func chambord(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9D0B8", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#3F474D", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Keep: 108 x 36 m between the tower centres, four storeys to 26 m.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 108.0, 26.0, 56.0)
	for y in [6.0, 12.5, 19.0, 26.0]:
		LandmarkWestKit.blk(lm, "Stone", 0, y - 0.3, 0, 110.0, 0.6, 58.0)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for y in [2.2, 8.4, 14.9, 21.0]:
			LandmarkWestKit.win_line(lm, "Glass", Vector3(-42, 0, sz * 28.0), Vector3(42, 0, sz * 28.0), n,
				5.6, 1.4, 3.4 if y < 20.0 else 2.6, [y + 1.6])
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.win_line(lm, "Glass", Vector3(sx * 54.0, 0, -6), Vector3(sx * 54.0, 0, 6), Vector3(sx, 0, 0),
			5.6, 1.4, 3.4, [3.8, 10.0, 16.5, 22.6])
	# Corner towers with their tall roofs and lantern pinnacles.
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var tc := Vector3(q.x * 54.0, 0, q.y * 18.0)
		lm.frustum("Stone", tc, 10.0, 10.0, 26.0, 20)
		lm.frustum("Stone", tc + Vector3(0, 25.0, 0), 10.8, 10.8, 1.4, 20)
		lm.lathe("Slate", tc + Vector3(0, 26.4, 0), PackedVector2Array([Vector2(10.8, 0), Vector2(8.6, 3.0),
			Vector2(5.0, 7.0), Vector2(2.0, 10.0), Vector2(0.0, 12.0)]), 20)
		LandmarkWhKit.pinnacle(lm, "Stone", tc + Vector3(0, 38.0, 0), 0.9, 2.0, 3.0)
		for k in 8:
			var a := TAU * float(k) / 8.0
			LandmarkWhKit.lancet(lm, "Glass", tc + Vector3(cos(a), 0, sin(a)) * 10.05 + Vector3(0, 7.0, 0),
				Vector3(cos(a), 0, sin(a)), 1.2, 3.0, 0.8)
	# Attic storey with a ring of dormers, steep slate roof, roof terrace.
	LandmarkWestKit.blk(lm, "Stone", 0, 26.0, 0, 104.0, 5.0, 52.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(0, 31.0, 0), 104.0, 52.0, 6.0, 0.55)
	for sz in [-1.0, 1.0]:
		for k in 12:
			var x := -40.5 + 7.4 * float(k)
			LandmarkWhKit.dormer(lm, "Stone", "Glass", Vector3(x, 28.0, sz * 26.0), Vector3(0, 0, sz), 2.4, 3.6)
	for sx in [-1.0, 1.0]:
		for k in 3:
			LandmarkWhKit.dormer(lm, "Stone", "Glass", Vector3(sx * 52.0, 28.0, -6.0 + 6.0 * float(k)),
				Vector3(sx, 0, 0), 2.4, 3.6)
	# Skyline on the terrace: chimney stacks and turrets in staggered rows.
	for k in 36:
		var row := floori(float(k) / 11.0)
		var cx := -44.0 + 8.8 * float(k % 11) + (4.4 if row % 2 == 1 else 0.0)
		var cz := -18.0 + 12.0 * float(row)
		if (absf(cx) < 12.0 and absf(cz) < 12.0) or Vector2(absf(cx) - 54.0, absf(cz) - 18.0).length() < 13.0:
			continue
		var ch := 5.5 + float((k * 7) % 5) * 0.8
		var by := _roof_y(cx, cz) - 0.3
		LandmarkWestKit.blk(lm, "Stone", cx, by, cz, 1.6, ch, 1.6)
		lm.spire("Slate", Vector3(cx, by + ch, cz), 1.1, 2.4)
	for k in 6:
		var tx := -30.0 + 12.0 * float(k)
		var tz := 14.0 if k % 2 == 0 else -14.0
		var tp := Vector3(tx, _roof_y(tx, tz) - 0.3, tz)
		lm.frustum("Stone", tp, 2.0, 1.8, 7.0, 10)
		lm.lathe("Slate", tp + Vector3(0, 7.0, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(0.0, 6.5)]), 10)
	# The lantern over the double-helix staircase (56 m).
	var lc := Vector3(0, 36.0, 0)
	lm.frustum("Stone", lc, 9.5, 8.2, 5.0, 20)
	lm.frustum("Stone", lc + Vector3(0, 5.0, 0), 8.8, 8.8, 1.2, 20)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.frustum("Stone", lc + Vector3(cos(a) * 6.8, 6.2, sin(a) * 6.8), 0.6, 0.5, 4.6, 8)
		LandmarkWhKit.pinnacle(lm, "Stone", lc + Vector3(cos(a) * 8.0, 6.2, sin(a) * 8.0), 0.35, 1.0, 2.0)
	lm.frustum("Glass", lc + Vector3(0, 6.2, 0), 6.5, 6.5, 4.6, 12)
	lm.frustum("Stone", lc + Vector3(0, 10.8, 0), 8.0, 7.6, 1.2, 20)
	lm.lathe("Stone", lc + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(6.8, 0), Vector2(5.6, 1.6),
		Vector2(3.6, 3.2), Vector2(2.0, 4.4), Vector2(1.0, 5.3), Vector2(0.0, 6.0)]), 12)
	lm.lathe("Gilt", lc + Vector3(0, 17.8, 0), LandmarkWestKit.ball(0.5), 8)
	LandmarkWestKit.cross(lm, "Gilt", lc + Vector3(0, 18.6, 0), 1.6)
	# Rear wings closing the court, with a round end tower each, and the low wall.
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", sx * 53.0, 0, -59.0, 22.0, 20.0, 62.0)
		lm.gable("Slate", Vector3(sx * 53.0, 20.0, -59.0), 22.0, 62.0, 9.0, Basis(), 0.6, "Stone")
		LandmarkWhKit.round_tower(lm, "Stone", "Slate", Vector3(sx * 53.0, 0, -90.0), 7.0, 6.6, 22.0, 12.0, 14)
		LandmarkWestKit.win_line(lm, "Glass", Vector3(sx * 41.9, 0, -85), Vector3(sx * 41.9, 0, -33), Vector3(-sx, 0, 0),
			5.6, 1.4, 3.2, [4.0, 11.0])
	LandmarkWhKit.crenel_wall(lm, "Stone", Vector3(-46, 0, -90), Vector3(46, 0, -90), 4.0, 1.2, 3.0)
	lm.commit(model)

## Height of the keep's hip roof (eaves 31 m, terrace 37 m) at (x, z).
static func _roof_y(x: float, z: float) -> float:
	var t := maxf(absf(x) / 52.0, absf(z) / 26.0)
	return 31.0 + 6.0 * clampf((1.0 - t) / 0.45, 0.0, 1.0)
