class_name LandmarkWhFortress
extends RefCounted

## Two southern French fortresses in true metres, y = 0 at the ground of
## the main front: the Palais des Papes and the Cité of Carcassonne (the
## Château de Chambord is LandmarkWhChambord).

## Palais des Papes (52 m to the top of the Trouillas tower; 1335-64):
## the pale limestone fortress-palace of Avignon. The Old Palace of
## Benedict XII round its cloister to the north, the Trouillas tower at
## its north-east corner; the New Palace of Clement VI along the west
## front to the Place du Palais (-X) with the Porte des Champeaux
## between its two octagonal turrets, and along the south the Grand
## Audience under the 52 m Great Chapel, the Tour de la Gâche at the
## south-west and Saint-Laurent at the south-east corner; the Cour
## d'Honneur between them. Every outer wall is ribbed with buttresses
## carrying tall pointed arcs-mâchicoulis about 15 m up, under the
## crenellated crowns; the base is battered.
static func palais_des_papes(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2C6A4", 3.5))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8F8774", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B0643F", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	# The rock of the Doms under the walls: a battered plinth.
	lm.poly_prism("Rock", PackedVector2Array([Vector2(-57, -52), Vector2(57, -52), Vector2(57, 52),
		Vector2(-57, 52)]), 0.0, 1.2)
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
	lm.gable("Tile", Vector3(-20.0, 38.0, -46.0), 8.0, 70.0, 2.5, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	# The outer walls, edge by edge (x0, z0, x1, z1, h): battered foot,
	# buttresses with the arcs-mâchicoulis between, crenellated crown.
	for e in [[-55.0, -50.0, 15.0, -50.0, 38.0], [15.0, -50.0, 55.0, -50.0, 34.0],
			[55.0, -50.0, 55.0, 12.0, 34.0], [55.0, 12.0, 55.0, 50.0, 40.0], [55.0, 50.0, -55.0, 50.0, 40.0],
			[-55.0, 50.0, -55.0, 12.0, 40.0], [-55.0, 12.0, -55.0, -12.0, 34.0], [-55.0, -12.0, -55.0, -50.0, 38.0]]:
		var a := Vector3(e[0], 0, e[1])
		var b := Vector3(e[2], 0, e[3])
		var h: float = e[4]
		_arcaded_wall(lm, a, b, h)
		_crown_edge(lm, a + Vector3(0, h, 0), b + Vector3(0, h, 0))
	# Great Chapel windows on the south front, smaller ones elsewhere.
	for k in 7:
		var bx := -42.0 + 14.0 * float(k)
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(bx, 21.0, 50.3), Vector3(0, 0, 1), 3.0, 9.0, 3.0, 2, 0.4)
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(bx, 6.0, 50.3), Vector3(0, 0, 1), 1.2, 3.0, 1.0, 1, 0.3)
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(-45, 0, -50.0), Vector3(10, 0, -50.0), Vector3(0, 0, -1),
		6, 1.2, 3.0, 20.0, 1.0, 1, 0.3)
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(-24, 0, 12.1), Vector3(14, 0, 12.1), Vector3(0, 0, 1),
		5, 2.4, 9.0, 12.0, 2.6, 2, 0.3)
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(-24, 0, -11.9), Vector3(14, 0, -11.9), Vector3(0, 0, -1),
		5, 2.0, 8.0, 14.0, 2.4, 2, 0.3)
	LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(55.0, 0, -40), Vector3(55.0, 0, 40), Vector3(1, 0, 0),
		6, 1.4, 4.0, 18.0, 1.2, 1, 0.3)
	_champeaux(lm, Vector3(-55.0, 0, 26.0))
	# Towers: (x, z, size, body height); the Trouillas tower tops at 52 m.
	for t in [[45.0, -45.0, 14.0, 50.8], [-49.0, -44.0, 13.0, 49.0], [-49.0, 44.0, 13.0, 47.0],
			[49.0, 44.0, 13.0, 50.0], [-14.0, -46.0, 12.0, 46.0], [18.0, 49.0, 11.0, 48.0],
			[-30.0, 49.0, 11.0, 47.0], [53.0, -10.0, 11.0, 44.0], [-54.0, 0.0, 10.0, 43.0]]:
		var sz: float = t[2]
		var th: float = t[3]
		var tx: float = t[0]
		var tz: float = t[1]
		LandmarkWestKit.blk(lm, "Stone", tx, 0, tz, sz, th, sz)
		LandmarkWestKit.blk(lm, "Stone", tx, 0, tz, sz + 1.6, 4.0, sz + 1.6)
		LandmarkWestKit.blk(lm, "Stone", tx, th - 2.6, tz, sz + 1.8, 2.6, sz + 1.8)
		var hs := sz * 0.5
		var cs := [Vector3(tx - hs, 0, tz - hs), Vector3(tx + hs, 0, tz - hs), Vector3(tx + hs, 0, tz + hs),
			Vector3(tx - hs, 0, tz + hs)]
		for i in 4:
			var p0: Vector3 = cs[i]
			var p1: Vector3 = cs[(i + 1) % 4]
			var o := (p0 + p1) * 0.5 - Vector3(tx, 0, tz)
			LandmarkWhGothic.machicolation_run(lm, "Stone", p0 + Vector3(0, th - 4.4, 0), p1 + Vector3(0, th - 4.4, 0),
				o, 1.8, 1.5)
			var fn := o.normalized()
			var mid := (p0 + p1) * 0.5
			LandmarkWhGothic.window(lm, "Glass", "Stone", mid + Vector3(0, th * 0.62, 0), fn, 1.2, 3.2, 1.0, 1, 0.25)
			LandmarkWhGothic.slit(lm, "Glass", mid + Vector3(0, th * 0.35, 0), fn, 2.4)
		_crown_rect(lm, tx, tz, sz + 1.8, th)
	lm.commit(model)

## A palace wall a -> b (ground points) `h` high, its foot battered,
## buttress piers every ~7 m and the pointed arcs-mâchicoulis springing
## between them, the arch heads rising to about 0.6 h.
static func _arcaded_wall(lm: LandmarkMesh, a: Vector3, b: Vector3, h: float) -> void:
	var dir := (b - a).normalized()
	var out := Vector3(-dir.z, 0, dir.x)
	var mid := (a + b) * 0.5
	if mid.dot(out) < 0.0:
		out = -out
	var dl := a.distance_to(b)
	var bays := maxi(int(round(dl / 7.0)), 1)
	var bw := dl / float(bays)
	var bs := Basis(dir, Vector3.UP, out)
	lm.box("Stone", mid + out * 0.6 + Vector3(0, 1.8, 0), Vector3(dl, 3.6, 1.2), bs)
	for i in bays + 1:
		var p := a + dir * bw * float(i)
		lm.box("Stone", p + out * 0.9 + Vector3(0, h * 0.4, 0), Vector3(1.6, h * 0.8, 1.8), bs)
	for i in bays:
		var c := a + dir * bw * (float(i) + 0.5) + out * 1.0
		LandmarkWhGothic._run(lm, "Stone", LandmarkWhGothic._arch_pts(c, dir, bw * 0.5 - 0.6, h * 0.42, h * 0.18, 4),
			out, 0.9, 1.4)
		# The arch spandrel band carrying the crown.
		lm.box("Stone", c + Vector3(0, h * 0.7, 0) - out * 0.1, Vector3(bw, 1.0, 1.6), bs, 0.0)

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

## The Porte des Champeaux on the west front at `c` (foot of the wall):
## the pointed gateway, Clement VI's arms panel, and the two octagonal
## turrets on the arch piers with crocketed stone pyramids.
static func _champeaux(lm: LandmarkMesh, c: Vector3) -> void:
	var wn := Vector3(-1, 0, 0)
	LandmarkWestKit.blk(lm, "Stone", c.x - 1.8, 0, c.z, 2.4, 16.0, 12.0)
	LandmarkWhGothic.window(lm, "Glass", "Stone", c + Vector3(-3.05, 0.4, 0), wn, 3.6, 4.2, 2.6, 1, 0.5)
	LandmarkWestKit.blk(lm, "Stone", c.x - 3.1, 8.2, c.z, 0.4, 2.4, 3.0)
	for s in [-1.0, 1.0]:
		var tc: Vector3 = c + Vector3(-3.6, 0, s * 4.4)
		lm.lathe("Stone", tc, PackedVector2Array([Vector2(1.8, 0), Vector2(1.8, 2.0), Vector2(1.5, 3.0),
			Vector2(1.5, 41.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		for y in [12.0, 22.0, 32.0]:
			lm.frustum("Stone", tc + Vector3(0, y, 0), 1.65, 1.65, 0.4, 8, PI / 8.0)
		LandmarkWhKit.crenel_ring(lm, "Stone", tc + Vector3(0, 41.0, 0), 1.45, 8, 0.6, 0.9, 0.35)
		lm.lathe("Stone", tc + Vector3(0, 41.0, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(0.0, 6.0)]), 8,
			1.0, 1.0, PI / 8.0, false)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			for j in 3:
				var t := (float(j) + 0.6) / 3.6
				lm.box("Stone", tc + d * 1.25 * (1.0 - t) + Vector3(0, 41.0 + 6.0 * t, 0), Vector3(0.22, 0.25, 0.22),
					Basis(), 0.0)
			LandmarkWhGothic.slit(lm, "Glass", tc + d * 1.52 + Vector3(0, 18.0 + 8.0 * float(k % 2), 0), d, 1.6)

## Cité de Carcassonne (32 m to the Tour de la Justice): the double
## ring of walls (3 km in all, 52 towers) round the hill, the inner wall
## with 28 towers and the outer with 16 under Viollet-le-Duc's pointed
## slate roofs, battered feet, corbel tables and arrow slits; the Porte
## Narbonnaise (east) between its two great spurred towers behind a
## barbican, the Porte d'Aude (west); the Château Comtal at the west end
## with its timber hoardings, semicircular barbican and dry moat; the
## basilica of Saint-Nazaire with its crenellated west tower, Romanesque
## nave and glazed Gothic choir; and the terracotta roofs of the old
## town between. Long axis east-west.
static func carcassonne(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#B4A486", 4.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#5B646B", 2.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A85A3C", 3.0))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#6A4A32", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("gravel", "#A09580", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#1A1D1F"))
	var inner := _oval(28, 250.0, 118.0, PI / 28.0)
	var core := _scaled(inner, 0.9)
	var outer := _oval(16, 276.0, 144.0, 0.15)
	lm.poly_prism("Ground", outer, 0.0, 0.15)
	# Inner wall (10 m, towers 22 m + roof) and outer wall (7 m, low towers).
	for i in inner.size():
		var a := Vector3(inner[i].x, 0, inner[i].y)
		var b := Vector3(inner[(i + 1) % inner.size()].x, 0, inner[(i + 1) % inner.size()].y)
		LandmarkWhKit.crenel_wall(lm, "Wall", a, b, 10.0, 3.2, 3.4)
		var th := 18.0 + float(i % 3) * 1.4
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", a, 4.8, 4.4, th, 8.5, 12)
		LandmarkWhGothic.slit_ring(lm, "Glass", a, 4.65, 5, [7.0, 13.0], 1.8)
		if i % 4 == 1:
			_hoarding(lm, a + Vector3(0, th - 2.6, 0), 4.4, 2.6)
	for i in outer.size():
		var a := Vector3(outer[i].x, 0, outer[i].y)
		var b := Vector3(outer[(i + 1) % outer.size()].x, 0, outer[(i + 1) % outer.size()].y)
		LandmarkWhKit.crenel_wall(lm, "Wall", a, b, 7.0, 2.6, 3.4)
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", a, 3.6, 3.3, 11.0, 5.5, 10)
		LandmarkWhGothic.slit_ring(lm, "Glass", a, 3.5, 4, [5.0], 1.6)
	_narbonnaise(lm)
	_comtal(lm)
	_saint_nazaire(lm, Vector3(112.0, 0, 66.0))
	# The old town: terracotta-roofed houses on a loose grid inside the wall.
	var bc := Vector3(112.0, 0, 66.0)
	var seed_v := 7
	for gx in range(-230, 235, 17):
		for gz in range(-110, 115, 17):
			seed_v = (seed_v * 1103515245 + 12345) & 0x7fffffff
			var p := Vector2(float(gx) + float(seed_v % 5), float(gz) + float((seed_v >> 4) % 5))
			var near_castle := p.x < -160.0 and absf(p.y) < 50.0
			var near_church := p.distance_to(Vector2(bc.x + 8.0, bc.z)) < 36.0
			var near_gate := p.x > 236.0
			if (seed_v >> 8) % 100 < 38 or near_castle or near_church or near_gate:
				continue
			if not Geometry2D.is_point_in_polygon(p, core):
				continue
			var w := 9.0 + float((seed_v >> 12) % 5)
			var d := 8.0 + float((seed_v >> 16) % 5)
			var hh := 6.0 + float((seed_v >> 18) % 3) * 1.5
			var turn := (seed_v >> 20) % 2 == 1
			LandmarkWestKit.blk(lm, "Wall", p.x, 0, p.y, w, hh, d)
			lm.gable("Tile", Vector3(p.x, hh, p.y), w, d, 3.2, Basis(Vector3.UP, PI * 0.5 if turn else 0.0), 0.4, "Wall")
			# Windows and a door on the long faces.
			var n := Vector3(0, 0, 1) if turn else Vector3(1, 0, 0)
			var half := d if turn else w
			for s in [-1.0, 1.0]:
				var face := Vector3(p.x, 0, p.y) + n * (half * 0.5 + 0.05) * float(s)
				var r := LandmarkWhKit.along(n * float(s))
				for k in 2:
					lm.box("Glass", face + r * (float(k) - 0.5) * 3.2 + Vector3(0, hh - 2.2, 0), Vector3(0.9, 1.3, 0.1),
						Basis(r, Vector3.UP, n * float(s)), 0.0)
	lm.commit(model)

## A timber hoarding (hourd) round a tower top at `c`: a ring of posts
## on beam ends, a boarded gallery wall and its eaves under the roof.
static func _hoarding(lm: LandmarkMesh, c: Vector3, rad: float, h: float) -> void:
	var r := rad + 1.0
	lm.frustum("Timber", c, r, r, h, 14)
	var cnt := 14
	for i in cnt:
		var a := TAU * (float(i) + 0.5) / float(cnt)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Timber", c + d * (rad - 0.2) - Vector3(0, 0.3, 0), c + d * (r + 0.3) - Vector3(0, 0.3, 0), 0.25, 0.3)
		lm.beam("Timber", c + d * (r + 0.05), c + d * (r + 0.05) + Vector3(0, h, 0), 0.2, 0.2)

## The Porte Narbonnaise: two great towers with their spurs (becs) on
## the field side, the vaulted passage between under a machicolated
## chamber, and the barbican in front.
static func _narbonnaise(lm: LandmarkMesh) -> void:
	for sz in [-1.0, 1.0]:
		var tc := Vector3(255.0, 0, sz * 10.0)
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", tc, 6.4, 6.0, 19.0, 9.0, 16)
		# The spur: a wedge of masonry pointing east.
		lm.poly_prism("Wall", PackedVector2Array([Vector2(tc.x + 4.0, tc.z - 4.6), Vector2(tc.x + 9.6, tc.z),
			Vector2(tc.x + 4.0, tc.z + 4.6)]), 0.0, 15.0)
		LandmarkWhGothic.slit_ring(lm, "Glass", tc, 6.2, 7, [6.0, 11.0, 15.5], 2.0)
		_hoarding(lm, tc + Vector3(0, 16.0, 0), 6.0, 3.0)
		LandmarkWestKit.blk(lm, "Wall", 255.0, 0, sz * 3.45, 12.0, 3.0, 2.1)
	LandmarkWestKit.arch_wall(lm, "Wall", Basis(Vector3.UP, PI * 0.5), Vector3(255.0, 0, 0), 4.5, 6.0, 2.4, 3.0, 12.0)
	LandmarkWestKit.blk(lm, "Wall", 255.0, 12.0, 0, 12.0, 4.0, 9.0)
	LandmarkWhGothic.machicolation_run(lm, "Wall", Vector3(261.0, 12.0, -4.5), Vector3(261.0, 12.0, 4.5),
		Vector3(1, 0, 0), 1.6, 1.4)
	LandmarkWestKit.merlons(lm, "Wall", Vector3(261.5, 16.0, -4.5), Vector3(261.5, 16.0, 4.5), 2.4, 1.2, 1.2, 0.8)
	lm.gable("Slate", Vector3(255.0, 16.0, 0), 9.0, 12.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Wall")
	# Barbican: a low crenellated half-ring before the gate.
	for k in 8:
		var a0 := -PI * 0.5 + PI * float(k) / 8.0
		var a1 := -PI * 0.5 + PI * float(k + 1) / 8.0
		var o := Vector3(270.0, 0, 0)
		LandmarkWhKit.crenel_wall(lm, "Wall", o + Vector3(cos(a0), 0, sin(a0)) * 14.0,
			o + Vector3(cos(a1), 0, sin(a1)) * 14.0, 6.0, 2.0, 2.6)

## The Château Comtal at the west end: the courtyard castle, its towers
## with timber hoardings on the town side, the semicircular barbican to
## the east beyond its dry moat, and the Porte d'Aude below to the west.
static func _comtal(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "Wall", -210.0, 0, 0, 64.0, 13.0, 56.0)
	LandmarkWestKit.blk(lm, "Ground", -210.0, 13.0, 0, 52.0, 0.4, 44.0)
	LandmarkWestKit.blk(lm, "Wall", -222.0, 13.0, -14.0, 36.0, 9.0, 14.0)
	lm.gable("Slate", Vector3(-222.0, 22.0, -14.0), 14.0, 36.0, 6.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	LandmarkWhGothic.window_row(lm, "Glass", "Wall", Vector3(-240, 0, -21.05), Vector3(-204, 0, -21.05),
		Vector3(0, 0, 1), 5, 1.2, 2.2, 15.5, 1.0, 2, 0.25)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var big: bool = q.x < 0.0 and q.y < 0.0
		var tc := Vector3(-210.0 + q.x * 32.0, 0, q.y * 28.0)
		var th := 22.0 if big else 20.0
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", tc, 6.4, 6.0, th, 10.0 if big else 8.5, 14)
		LandmarkWhGothic.slit_ring(lm, "Glass", tc, 6.2, 6, [6.0, 12.0], 2.0)
		if q.x > 0.0:
			_hoarding(lm, tc + Vector3(0, th - 3.0, 0), 6.0, 3.0)
	# The east curtain on the moat, with its gate between two towers.
	LandmarkWhKit.crenel_wall(lm, "Wall", Vector3(-178, 0, -28), Vector3(-178, 0, -4), 14.0, 3.0)
	LandmarkWhKit.crenel_wall(lm, "Wall", Vector3(-178, 0, 4), Vector3(-178, 0, 28), 14.0, 3.0)
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.round_tower(lm, "Wall", "Slate", Vector3(-176.0, 0, sz * 5.5), 3.2, 3.0, 17.0, 6.0, 12)
	LandmarkWestKit.arch_wall(lm, "Wall", Basis(Vector3.UP, PI * 0.5), Vector3(-178.0, 0, 0), 2.5, 1.6, 2.0, 3.0, 14.0)
	for k in 2:
		LandmarkWhGothic.machicolation_run(lm, "Wall", Vector3(-176.6, 10.4, -27.0 + 31.0 * float(k)),
			Vector3(-176.6, 10.4, -4.0 + 31.0 * float(k)), Vector3(1, 0, 0), 1.6, 1.5)
	# Bridge over the moat and the semicircular barbican.
	LandmarkWestKit.blk(lm, "Wall", -170.0, 0, 0, 14.0, 2.2, 5.0)
	for k in 10:
		var a0 := -PI * 0.5 + PI * float(k) / 10.0
		var a1 := -PI * 0.5 + PI * float(k + 1) / 10.0
		var o := Vector3(-163.0, 0, 0)
		LandmarkWhKit.crenel_wall(lm, "Wall", o + Vector3(cos(a0), 0, sin(a0)) * 18.0,
			o + Vector3(cos(a1), 0, sin(a1)) * 18.0, 7.0, 2.4, 2.6)
	# Porte d'Aude: the west gate in the inner wall, a square tower pair.
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Wall", -252.0, 0, 52.0 + sz * 5.0, 7.0, 16.0, 6.0)
		LandmarkWestKit.merlons(lm, "Wall", Vector3(-255.6, 16.0, 49.0 + sz * 5.0), Vector3(-255.6, 16.0, 55.0 + sz * 5.0),
			2.0, 1.0, 1.1, 0.8)
	LandmarkWestKit.arch_wall(lm, "Wall", Basis(Vector3.UP, PI * 0.5), Vector3(-252.0, 0, 52.0), 2.0, 3.5, 1.6, 2.6,
		12.0)

## Basilica of Saint-Nazaire at `bc`: the crenellated Romanesque west
## tower-front, the nave under one roof, the Gothic transept with its
## roses and the glazed polygonal choir between slim buttresses.
static func _saint_nazaire(lm: LandmarkMesh, bc: Vector3) -> void:
	LandmarkWestKit.blk(lm, "Wall", bc.x - 14.0, 0, bc.z, 30.0, 14.0, 15.0)
	lm.gable("Slate", bc + Vector3(-14.0, 14.0, 0), 15.0, 30.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for k in 4:
			var x := bc.x - 25.0 + 7.0 * float(k)
			LandmarkWhKit.arch_round(lm, "Glass", Vector3(x, 7.0, bc.z + sz * 7.55), n, 1.2, 2.4)
			LandmarkWhGothic.archivolt(lm, "Wall", Vector3(x, 9.4, bc.z + sz * 7.5), n, 1.2, 0.3, 0.25)
			LandmarkWestKit.blk(lm, "Wall", x + 3.5, 0, bc.z + sz * 7.9, 1.2, 13.0, 0.8)
		LandmarkWhGothic.rose(lm, "Glass", "Wall", bc + Vector3(8.0, 11.0, sz * 17.1), n, 3.4, 12)
		LandmarkWhGothic.window(lm, "Glass", "Wall", bc + Vector3(8.0, 2.0, sz * 17.05), n, 2.2, 4.0, 1.8, 2, 0.3)
	LandmarkWestKit.blk(lm, "Wall", bc.x + 8.0, 0, bc.z, 14.0, 18.0, 34.0)
	lm.gable("Slate", bc + Vector3(8.0, 18.0, 0), 14.0, 34.0, 6.0, Basis(), 0.5, "Wall")
	# The choir: seven sides, nearly all glass, between buttresses.
	lm.lathe("Wall", bc + Vector3(22.0, 0, 0), PackedVector2Array([Vector2(8.5, 0), Vector2(8.5, 18.0)]), 7,
		1.0, 1.0, PI / 7.0, false)
	lm.lathe("Slate", bc + Vector3(22.0, 18.0, 0), PackedVector2Array([Vector2(9.0, 0), Vector2(0, 8.0)]), 7)
	for k in 7:
		var a := TAU * float(k) / 7.0
		var d := Vector3(cos(a), 0, sin(a))
		if d.x < -0.3:
			continue
		var ap := 8.5 * cos(PI / 7.0)
		LandmarkWhGothic.window(lm, "Glass", "Wall", bc + Vector3(22.0, 3.0, 0) + d * ap, d, 3.6, 10.0, 2.6, 3, 0.3)
		var bd := Vector3(cos(a + PI / 7.0), 0, sin(a + PI / 7.0))
		LandmarkWhGothic.buttress(lm, "Wall", bc + Vector3(22.0, 0, 0) + bd * 8.5, bd, 1.0, 1.6, 16.0, 3)
		LandmarkWhGothic.pinnacle(lm, "Wall", bc + Vector3(22.0, 16.0, 0) + bd * 9.1, 0.4, 1.4, 2.4)
	# The west tower-front: a fortified block with merlons.
	LandmarkWestKit.blk(lm, "Wall", bc.x - 31.0, 0, bc.z, 6.0, 24.0, 16.0)
	var t0 := bc + Vector3(-34.0, 24.0, -8.0)
	var cs := [t0, t0 + Vector3(6, 0, 0), t0 + Vector3(6, 0, 16), t0 + Vector3(0, 0, 16)]
	for i in 4:
		LandmarkWestKit.merlons(lm, "Wall", cs[i], cs[(i + 1) % 4], 2.0, 1.0, 1.4, 0.8)
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.arch_round(lm, "Glass", bc + Vector3(-34.05, 16.0, sz * 4.0), Vector3(-1, 0, 0), 1.6, 3.0)
		LandmarkWhGothic.slit(lm, "Glass", bc + Vector3(-34.05, 8.0, sz * 4.0), Vector3(-1, 0, 0), 2.4)

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
