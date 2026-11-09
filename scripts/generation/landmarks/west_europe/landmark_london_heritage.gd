class_name LandmarkLondonHeritage
extends RefCounted

## Two London churches in true metres, y = 0 at street level: St Paul's
## Cathedral and Westminster Abbey (the Abbey lives in LandmarkLondonAbbey;
## the Tower of London and Buckingham Palace are LandmarkLondonPalaces).

## Screen-wall height (top of the upper entablature) and the lower-order
## cornice height of St Paul's.
const SP_WALL := 28.0
const SP_LOW := 13.8

## St Paul's Cathedral (111 m to the cross), Wren 1675-1710, fitted to the
## OSM footprint: 157 m long (west steps -87 m to the apse tip +70 m from
## the crossing), 37 m across nave and choir, 41 m across the crossing,
## transept fronts at +-37 m with semicircular six-column porticoes
## reaching +-44 m, west front 54 m wide between the outer faces of the
## two 68 m towers. Origin = the crossing centre, nave along X with the
## west front at -X. (The real axis runs ENE, about 5.5 deg north of east;
## the registry carries no yaw for it.)
## Elevations: two-order screen walls (coupled pilasters, arched windows
## below, blind niches above, balustrade at 29.4 m); the clerestory roof
## behind; west portico of 12 coupled Corinthian columns below and 8
## Composite above under a pediment with Paul, Peter and James; two
## baroque towers (square clock stage, columned open stage, stepped lead
## dome, ball and cross); the dome: plinth, 32-column peristyle (8 niche
## bays) to 50.5 m, Stone Gallery 53.9 m, windowed attic, ribbed lead
## shell, Golden Gallery 85.4 m, lantern, ball and cross at 111.3 m.
static func st_pauls(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2CCBF", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8A9195", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var outline := _sp_outline()
	lm.poly_prism("Stone", outline, 0.0, SP_WALL, false)
	lm.poly_prism("Lead", outline, SP_WALL, SP_WALL + 0.3, true)
	var n := outline.size()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		LandmarkWestKit.rail(lm, "Stone", Vector3(a.x, SP_WALL + 0.3, a.y), Vector3(b.x, SP_WALL + 0.3, b.y), 1.4, 1.1)
	_sp_roofs(lm)
	_sp_walls(lm)
	_sp_apse(lm)
	for sz in [-1.0, 1.0]:
		_sp_transept_front(lm, sz)
	_sp_west_portico(lm)
	for sz in [-1.0, 1.0]:
		_sp_tower(lm, Vector3(-72.0, 0, sz * 19.5), sz > 0.0)
	_sp_dome(lm, Vector3(0, 28.3, 0))
	lm.commit(model)

## Clockwise outline of the screen walls (x, z): west block with the
## towers, the 37 m nave, the corner bays at the crossing, the transept
## arms, the choir and its straight east wall.
static func _sp_outline() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-79.5, -27.0), Vector2(-52.5, -27.0), Vector2(-52.5, -18.5),
		Vector2(-26.5, -18.5), Vector2(-26.5, -22.5), Vector2(-20.5, -22.5), Vector2(-20.5, -37.0),
		Vector2(20.5, -37.0), Vector2(20.5, -22.5), Vector2(26.5, -22.5), Vector2(26.5, -18.5),
		Vector2(61.1, -18.5), Vector2(61.1, 18.5), Vector2(26.5, 18.5), Vector2(26.5, 22.5),
		Vector2(20.5, 22.5), Vector2(20.5, 37.0), Vector2(-20.5, 37.0), Vector2(-20.5, 22.5),
		Vector2(-26.5, 22.5), Vector2(-26.5, 18.5), Vector2(-52.5, 18.5), Vector2(-52.5, 27.0),
		Vector2(-79.5, 27.0)])

## Clerestory walls and low lead roofs of nave, choir and transepts,
## standing behind the screen walls.
static func _sp_roofs(lm: LandmarkMesh) -> void:
	var rot := Basis(Vector3.UP, PI * 0.5)
	lm.box("Stone", Vector3(3.75, 29.8, 0), Vector3(112.5, 3.0, 18.0), Basis(), 0.0)
	lm.gable("Lead", Vector3(3.75, 31.3, 0), 18.0, 112.5, 3.4, rot, 0.4, "Stone")
	lm.box("Stone", Vector3(0, 29.8, 0), Vector3(19.0, 3.0, 74.0), Basis(), 0.0)
	lm.gable("Lead", Vector3(0, 31.3, 0), 19.0, 74.0, 2.8, Basis(), 0.4, "Stone")
	for sz in [-1.0, 1.0]:
		var s: float = sz
		var n := Vector3(0, 0, s)
		for x in [-48.0, -41.0, -34.0, -27.0, 27.0, 34.0, 41.0, 48.0, 55.0]:
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(x, 30.0, s * 9.0), n, 1.5, 2.2, true, 0.2)
		for q in [-1.0, 1.0]:
			var qx: float = q
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(qx * 9.5, 30.0, s * 30.0), Vector3(qx, 0, 0), 1.5, 2.2, true, 0.2)

## One face of a two-order screen wall centred at `c` (y = 0) facing `n`:
## `bays` bays of arched window below and blind niche above between
## coupled pilasters, a lower cornice, a dentilled main cornice and a
## base course.
static func _sp_bays(lm: LandmarkMesh, c: Vector3, n: Vector3, length: float, bays: int) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var b := Basis(r, Vector3.UP, nn)
	for k in bays:
		var p := c + r * ((float(k) + 0.5) / float(bays) - 0.5) * length
		LandmarkDetail.window(lm, "Stone", "Glass", p + Vector3(0, 6.4, 0), nn, 2.2, 5.6, true)
		LandmarkDetail.window(lm, "Stone", "Stone", p + Vector3(0, 21.0, 0), nn, 1.7, 4.2, false, 0.2)
	for k in bays + 1:
		var p := c + r * (float(k) / float(bays) - 0.5) * length
		for px in [-0.55, 0.55]:
			var q: float = px
			lm.box("Stone", p + r * q + Vector3(0, 6.9, 0) + nn * 0.25, Vector3(0.7, 13.4, 0.5), b, 0.0)
			lm.box("Stone", p + r * q + Vector3(0, 21.0, 0) + nn * 0.25, Vector3(0.65, 13.4, 0.5), b, 0.0)
	var a0 := c - r * length * 0.5
	var b0 := c + r * length * 0.5
	lm.box("Stone", c + Vector3(0, 0.6, 0) + nn * 0.15, Vector3(length, 1.2, 0.3), b, 0.0)
	LandmarkDetail.cornice(lm, "Stone", a0 + Vector3(0, SP_LOW - 0.6, 0), b0 + Vector3(0, SP_LOW - 0.6, 0), nn, 0.9, false)
	LandmarkDetail.cornice(lm, "Stone", a0 + Vector3(0, SP_WALL - 1.2, 0), b0 + Vector3(0, SP_WALL - 1.2, 0), nn, 1.2)

## Every long wall face of the church.
static func _sp_walls(lm: LandmarkMesh) -> void:
	for sz in [-1.0, 1.0]:
		var s: float = sz
		_sp_bays(lm, Vector3(-66.0, 0, s * 27.0), Vector3(0, 0, s), 27.0, 4)
		_sp_bays(lm, Vector3(-39.5, 0, s * 18.5), Vector3(0, 0, s), 26.0, 4)
		_sp_bays(lm, Vector3(43.8, 0, s * 18.5), Vector3(0, 0, s), 34.6, 5)
		for q in [-1.0, 1.0]:
			var qx: float = q
			_sp_bays(lm, Vector3(qx * 23.5, 0, s * 22.5), Vector3(0, 0, s), 6.0, 1)
			_sp_bays(lm, Vector3(qx * 20.5, 0, s * 29.75), Vector3(qx, 0, 0), 14.5, 2)
			_sp_bays(lm, Vector3(qx * 14.0, 0, s * 37.0), Vector3(0, 0, s), 13.0, 2)
		_sp_bays(lm, Vector3(61.1, 0, s * 13.75), Vector3(1, 0, 0), 9.5, 1)
		# West faces of the two tower blocks.
		_sp_bays(lm, Vector3(-79.5, 0, s * 19.5), Vector3(-1, 0, 0), 15.0, 2)

## The semicircular apse on the straight east wall: niches and windows
## round a half drum under the balustrade.
static func _sp_apse(lm: LandmarkMesh) -> void:
	var c := Vector3(60.7, 0, 0)
	lm.frustum("Stone", c, 9.0, 9.0, SP_WALL, 20)
	lm.disc("Lead", c + Vector3(0, SP_WALL + 0.3, 0), Vector3.UP, 9.0, 20)
	for k in 5:
		var a := PI * (-0.5 + (float(k) + 0.5) / 5.0)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Stone", "Glass", c + d * 9.0 + Vector3(0, 6.4, 0), d, 2.0, 5.6, true)
		LandmarkDetail.window(lm, "Stone", "Stone", c + d * 9.0 + Vector3(0, 21.0, 0), d, 1.6, 4.2, false, 0.2)
	for k in 6:
		var a := PI * (-0.5 + float(k) / 5.0)
		lm.box("Stone", c + Vector3(cos(a), 0, sin(a)) * 9.05 + Vector3(0, 13.9, 0), Vector3(0.8, 27.6, 0.5),
			Basis.looking_at(Vector3(cos(a), 0, sin(a))), 0.0)
	for k in 20:
		var a0 := PI * (-0.5 + float(k) / 20.0)
		var a1 := PI * (-0.5 + float(k + 1) / 20.0)
		for y in [SP_LOW - 0.1, SP_WALL - 0.6]:
			var yy: float = y
			lm.beam("Stone", c + Vector3(cos(a0) * 9.2, yy, sin(a0) * 9.2), c + Vector3(cos(a1) * 9.2, yy, sin(a1) * 9.2),
				0.9, 0.9)
	for k in 20:
		var a0 := PI * (-0.5 + float(k) / 20.0)
		var a1 := PI * (-0.5 + float(k + 1) / 20.0)
		LandmarkWestKit.rail(lm, "Stone", c + Vector3(cos(a0) * 9.0, SP_WALL + 0.3, sin(a0) * 9.0),
			c + Vector3(cos(a1) * 9.0, SP_WALL + 0.3, sin(a1) * 9.0), 1.4, 1.1)

## Transept front on the side `sz`: the semicircular portico of six
## Corinthian columns under a half-dome, the pediment above the cornice
## and the three statues crowning it.
static func _sp_transept_front(lm: LandmarkMesh, sz: float) -> void:
	var f := Vector3(0, 0, sz * 37.0)
	lm.frustum("Stone", f, 7.0, 7.0, 1.2, 20)
	for k in 6:
		var a := PI * float(k) / 5.0
		LandmarkDetail.column(lm, "Stone", f + Vector3(cos(a) * 6.1, 1.2, sz * sin(a) * 6.1), 0.62, 12.8,
			"corinthian", 0, 12)
	for k in 10:
		var a0 := PI * float(k) / 10.0
		var a1 := PI * float(k + 1) / 10.0
		lm.beam("Stone", f + Vector3(cos(a0) * 6.1, 14.8, sz * sin(a0) * 6.1), f + Vector3(cos(a1) * 6.1, 14.8,
			sz * sin(a1) * 6.1), 1.7, 1.5)
		for j in 4:
			var t0 := PI * 0.5 * float(j) / 4.0
			var t1 := PI * 0.5 * float(j + 1) / 4.0
			var p0 := Vector3(cos(a0) * cos(t0), sin(t0), sz * sin(a0) * cos(t0)) * 6.2
			var p1 := Vector3(cos(a0) * cos(t1), sin(t1), sz * sin(a0) * cos(t1)) * 6.2
			var q1 := Vector3(cos(a1) * cos(t1), sin(t1), sz * sin(a1) * cos(t1)) * 6.2
			var q0 := Vector3(cos(a1) * cos(t0), sin(t0), sz * sin(a1) * cos(t0)) * 6.2
			var b := f + Vector3(0, 15.6, 0)
			lm.quad("Lead", b + p0, b + q0, b + q1, b + p1, ((p0 + q1) * 0.5).normalized())
	for k in 2:
		LandmarkWestKit.blk(lm, "Stone", 0, 0, sz * (44.5 + float(k)), 9.0 + 2.0 * float(k), 0.4 - 0.15 * float(k), 1.0)
	LandmarkDetail.window(lm, "Stone", "Glass", f + Vector3(0, 6.0, sz * 0.1), Vector3(0, 0, sz), 2.2, 5.6, true)
	LandmarkDetail.cornice(lm, "Stone", f + Vector3(-12.5, SP_WALL - 1.2, sz * 0.05), f + Vector3(12.5, SP_WALL - 1.2, sz * 0.05),
		Vector3(0, 0, sz), 1.2)
	lm.gable("Stone", f + Vector3(0, SP_WALL + 0.3, sz * 0.4), 24.0, 2.0, 4.8, Basis(), 0.5, "Stone")
	for k in 3:
		LandmarkDetail.window(lm, "Stone", "Stone", f + Vector3(-4.0 + 4.0 * float(k), 24.2, sz * 0.1), Vector3(0, 0, sz), 1.6, 3.8, false, 0.2)
	LandmarkKits.statue_figure(lm, "Stone", f + Vector3(0, SP_WALL + 5.1, sz * 0.4), 3.4)
	for x in [-11.5, 11.5]:
		var xx: float = x
		LandmarkKits.statue_figure(lm, "Stone", f + Vector3(xx, SP_WALL + 0.5, sz * 0.4), 3.0)

## West front: steps, the two-tier portico (twelve coupled Corinthian
## columns, eight Composite above) in front of the wall between the
## towers, the pediment and its statues.
static func _sp_west_portico(lm: LandmarkMesh) -> void:
	var rot := Basis(Vector3.UP, PI * 0.5)
	var w := Vector3(-1, 0, 0)
	LandmarkWestKit.blk(lm, "Stone", -82.0, 0, 0, 5.5, 1.2, 25.0)
	for k in 4:
		LandmarkWestKit.blk(lm, "Stone", -85.2 - 0.9 * float(k), 0, 0, 0.9, 0.9 - 0.3 * float(k), 29.0 - 1.5 * float(k))
	for pair in 6:
		var z := -10.0 + 4.0 * float(pair)
		for dz in [-0.7, 0.7]:
			var d: float = dz
			LandmarkDetail.column(lm, "Stone", Vector3(-83.4, 1.2, z + d), 0.62, 12.8, "corinthian", 0, 12)
	LandmarkWestKit.blk(lm, "Stone", -82.0, 14.0, 0, 5.3, 1.6, 24.6)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-84.65, 15.2, -12.3), Vector3(-84.65, 15.2, 12.3), w, 0.9)
	for pair in 4:
		var z := -6.0 + 4.0 * float(pair)
		for dz in [-0.7, 0.7]:
			var d: float = dz
			LandmarkDetail.column(lm, "Stone", Vector3(-82.3, 15.6, z + d), 0.5, 11.0, "corinthian", 0, 12)
	LandmarkWestKit.blk(lm, "Stone", -81.6, 26.6, 0, 4.1, 1.4, 17.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-83.65, 27.2, -8.5), Vector3(-83.65, 27.2, 8.5), w, 0.9)
	LandmarkWestKit.blk(lm, "Stone", -81.6, 28.0, 0, 4.1, 0.3, 17.0)
	lm.gable("Stone", Vector3(-81.6, 28.3, 0), 17.4, 4.1, 4.4, rot, 0.4, "Stone")
	LandmarkDetail.window(lm, "Stone", "Glass", Vector3(-79.5, 1.2 + 3.4, 0), w, 2.6, 6.8, true)
	for z in [-8.0, -4.0, 4.0, 8.0]:
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(-79.5, 1.2 + 3.0, z), w, 1.6, 5.2, true)
	for z in [-4.0, 0.0, 4.0]:
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(-79.5, 21.0, z), w, 1.5, 4.8, false, 0.2)
	for k in 7:
		LandmarkWestKit.figure(lm, "Stone", Vector3(-83.5, 28.3, -6.0 + 2.0 * float(k)), 2.4 - absf(-6.0 + 2.0 * float(k)) * 0.1)
	LandmarkKits.statue_figure(lm, "Stone", Vector3(-81.6, 32.6, 0), 3.4)
	for sz in [-1.0, 1.0]:
		var s: float = sz
		LandmarkKits.statue_figure(lm, "Stone", Vector3(-81.6, 28.3, s * 8.3), 3.2)

## One west tower with its centre at `c` (ground): the clock stage in
## chamfered square plan to 43 m, the open columned stage, a balustraded
## drum, the stepped lead dome, the ball and cross (68 m).
static func _sp_tower(lm: LandmarkMesh, c: Vector3, clock: bool) -> void:
	var y := SP_WALL
	lm.poly_prism("Stone", _chamfer(c, 6.9, 1.5), y, 43.0, false)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s))
		var n: Vector3 = b * Vector3(0, 0, 1)
		var r: Vector3 = b * Vector3(1, 0, 0)
		LandmarkDetail.window(lm, "Stone", "Glass", c + n * 6.9 + Vector3(0, 35.5, 0), n, 2.8, 8.2, true)
		for q in [-3.6, -2.7, 2.7, 3.6]:
			var qq: float = q
			lm.box("Stone", c + n * 7.15 + r * qq + Vector3(0, 35.5, 0), Vector3(0.7, 13.5, 0.5), Basis(r, Vector3.UP, n), 0.0)
		LandmarkDetail.cornice(lm, "Stone", c + n * 6.9 + r * -6.9 + Vector3(0, 41.6, 0), c + n * 6.9 + r * 6.9 + Vector3(0, 41.6, 0), n, 1.4)
		LandmarkWestKit.rail(lm, "Stone", c + n * 6.9 + r * -6.9 + Vector3(0, 43.0, 0), c + n * 6.9 + r * 6.9 + Vector3(0, 43.0, 0), 1.2, 1.0)
	if clock:
		lm.disc("Gilt", c + Vector3(0, 40.0, 7.0), Vector3(0, 0, 1), 1.2, 20)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var urn := c + Vector3(q.x * 6.9, 43.0, q.y * 6.9)
		lm.lathe("Stone", urn, PackedVector2Array([Vector2(0.5, 0), Vector2(0.3, 0.5), Vector2(0.6, 1.0),
			Vector2(0.4, 1.6), Vector2(0.0, 1.9)]), 8)
	y = 43.0
	lm.poly_prism("Stone", _chamfer(c, 4.9, 2.0), y, 53.8, false)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s))
		var n: Vector3 = b * Vector3(0, 0, 1)
		LandmarkDetail.window(lm, "Stone", "Glass", c + n * 4.9 + Vector3(0, 48.4, 0), n, 2.0, 5.4, true)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var out := Vector3(q.x, 0, q.y).normalized()
		var tang := Vector3(-q.y, 0, q.x).normalized()
		for e in [-0.95, 0.95]:
			var ee: float = e
			LandmarkWestKit.shaft(lm, "Stone", c + out * 5.6 + tang * ee + Vector3(0, y, 0), 0.38, 10.8, 8)
	lm.box("Stone", c + Vector3(0, 54.4, 0), Vector3(12.4, 1.4, 12.4), Basis(), 0.0)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s))
		var n: Vector3 = b * Vector3(0, 0, 1)
		var r: Vector3 = b * Vector3(1, 0, 0)
		LandmarkWestKit.rail(lm, "Stone", c + n * 5.8 + r * -5.8 + Vector3(0, 55.1, 0), c + n * 5.8 + r * 5.8 + Vector3(0, 55.1, 0), 1.1, 1.0)
	lm.frustum("Stone", c + Vector3(0, 55.1, 0), 3.9, 3.7, 2.4, 16)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		lm.box("Glass", c + Vector3(cos(a) * 3.88, 56.4, sin(a) * 3.88), Vector3(0.8, 1.4, 0.1),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	var dome := c + Vector3(0, 57.5, 0)
	lm.lathe("Lead", dome, PackedVector2Array([Vector2(4.0, 0), Vector2(4.5, 0.6), Vector2(4.3, 1.5),
		Vector2(3.5, 2.6), Vector2(2.6, 3.5), Vector2(1.8, 4.3), Vector2(1.4, 5.0), Vector2(1.4, 5.5)]), 16)
	lm.frustum("Stone", dome + Vector3(0, 5.5, 0), 1.2, 1.1, 1.2, 12)
	lm.lathe("Lead", dome + Vector3(0, 6.7, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(0.9, 0.5), Vector2(0.0, 1.0)]), 12)
	lm.lathe("Gilt", dome + Vector3(0, 7.4, 0), LandmarkWestKit.ball(0.5), 10)
	LandmarkWestKit.cross(lm, "Gilt", dome + Vector3(0, 8.3, 0), 2.2)

## Square plan of half-width `hw` with each corner cut by `ch`, centred
## on the XZ of `c`.
static func _chamfer(c: Vector3, hw: float, ch: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for q in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		var qq: Vector2 = q
		var sx := qq.x
		var sy := qq.y
		var p0 := Vector2(c.x + sx * hw, c.z + sy * (hw - ch))
		var p1 := Vector2(c.x + sx * (hw - ch), c.z + sy * hw)
		if sx * sy > 0.0:
			pts.append(p0)
			pts.append(p1)
		else:
			pts.append(p1)
			pts.append(p0)
	return pts

## Wren's dome over the crossing, `d` at the roof level of the crossing:
## drum plinth, the 32-column peristyle with its eight niche bays, the
## Stone Gallery, the attic, the ribbed lead shell, the Golden Gallery,
## the lantern, ball and cross (111.3 m).
static func _sp_dome(lm: LandmarkMesh, d: Vector3) -> void:
	# Plinth (28.3 - 38 m) and the wall behind the colonnade.
	lm.lathe("Stone", d, PackedVector2Array([Vector2(21.6, 0), Vector2(21.6, 8.9), Vector2(22.0, 9.1),
		Vector2(22.0, 9.7), Vector2(20.4, 9.7)]), 40)
	lm.frustum("Stone", d + Vector3(0, 9.0, 0), 17.6, 17.6, 13.4, 40)
	var y0 := 38.0
	for k in 32:
		var a := TAU * float(k) / 32.0
		LandmarkWestKit.shaft(lm, "Stone", Vector3(cos(a) * 19.0, y0, sin(a) * 19.0) + Vector3(d.x, 0, d.z), 0.62, 12.5, 10)
		if k % 4 == 3:
			# Niche bay between two columns: solid wall bulge with a niche.
			var a2 := a + PI / 32.0
			var dir := Vector3(cos(a2), 0, sin(a2))
			lm.box("Stone", Vector3(d.x, 0, d.z) + dir * 18.6 + Vector3(0, y0 + 6.2, 0), Vector3(2.7, 12.4, 1.8),
				Basis.looking_at(dir), 0.0)
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(d.x, 0, d.z) + dir * 19.5 + Vector3(0, y0 + 5.6, 0), dir, 1.3, 4.6, true, 0.2)
	# Entablature, Stone Gallery balustrade.
	lm.lathe("Stone", d + Vector3(0, 50.5 - d.y, 0), PackedVector2Array([Vector2(19.8, 0), Vector2(20.2, 0.05),
		Vector2(20.2, 1.3), Vector2(20.8, 1.4), Vector2(20.9, 2.0), Vector2(18.0, 2.0)]), 40)
	for k in 40:
		var a0 := TAU * float(k) / 40.0
		var a1 := TAU * float(k + 1) / 40.0
		LandmarkWestKit.rail(lm, "Stone", d + Vector3(cos(a0) * 20.4, 52.5 - d.y, sin(a0) * 20.4),
			d + Vector3(cos(a1) * 20.4, 52.5 - d.y, sin(a1) * 20.4), 1.4, 0.8)
	# Attic: pilasters between windows, then the cornice under the dome.
	lm.frustum("Stone", d + Vector3(0, 52.5 - d.y, 0), 17.3, 17.3, 7.0, 40)
	for k in 32:
		var a := TAU * float(k) / 32.0
		var dir := Vector3(cos(a), 0, sin(a))
		lm.box("Stone", d + dir * 17.45 + Vector3(0, 56.0 - d.y, 0), Vector3(0.9, 7.0, 0.4), Basis.looking_at(dir), 0.0)
		var a2 := a + PI / 32.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		lm.box("Glass", d + d2 * 17.35 + Vector3(0, 55.9 - d.y, 0), Vector3(1.2, 3.0, 0.1), Basis.looking_at(d2), 0.0)
	lm.lathe("Stone", d + Vector3(0, 59.5 - d.y, 0), PackedVector2Array([Vector2(17.3, 0), Vector2(17.9, 0.2),
		Vector2(18.1, 0.5), Vector2(17.4, 0.5)]), 40)
	# Lead shell with 32 ribs.
	var base := d + Vector3(0, 60.0 - d.y, 0)
	var prof := LandmarkWestKit.dome_prof(17.1, 27.0, 18, 1.0)
	lm.lathe("Lead", base, prof, 40)
	for k in 32:
		var dir := Vector3(cos(TAU * float(k) / 32.0), 0, sin(TAU * float(k) / 32.0))
		for j in prof.size() - 4:
			lm.beam("Lead", base + dir * (prof[j].x + 0.12) + Vector3(0, prof[j].y, 0),
				base + dir * (prof[j + 1].x + 0.12) + Vector3(0, prof[j + 1].y, 0), 0.45, 0.3)
	# Golden Gallery, lantern, cap, ball and cross.
	var g := d + Vector3(0, 85.2 - d.y, 0)
	lm.frustum("Gilt", g, 6.4, 6.0, 0.8, 24)
	for k in 16:
		var a0 := TAU * float(k) / 16.0
		var a1 := TAU * float(k + 1) / 16.0
		LandmarkWestKit.rail(lm, "Gilt", g + Vector3(cos(a0) * 6.0, 0.8, sin(a0) * 6.0),
			g + Vector3(cos(a1) * 6.0, 0.8, sin(a1) * 6.0), 1.0, 0.5)
	var lan := d + Vector3(0, 86.0 - d.y, 0)
	lm.frustum("Stone", lan, 5.0, 4.6, 1.2, 16)
	lm.frustum("Stone", lan + Vector3(0, 1.2, 0), 4.4, 4.0, 11.2, 16)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s) + PI * 0.25)
		for q in [-1.0, 1.0]:
			var qq: float = q
			LandmarkWestKit.shaft(lm, "Stone", lan + b * Vector3(qq * 1.3, 1.2, 4.7), 0.3, 9.0, 8)
		lm.box("Stone", lan + b * Vector3(0, 10.6, 4.6), Vector3(3.8, 0.6, 1.0), b, 0.0)
		LandmarkDetail.window(lm, "Stone", "Glass", lan + b * Vector3(0, 6.0, 4.1), b * Vector3(0, 0, 1), 1.2, 4.6, true, 0.15)
	lm.lathe("Stone", lan + Vector3(0, 12.4, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(5.0, 0.2),
		Vector2(5.0, 0.7), Vector2(4.2, 0.7)]), 16)
	lm.lathe("Lead", lan + Vector3(0, 13.1, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(3.4, 0.8),
		Vector2(2.4, 1.8), Vector2(1.5, 2.9), Vector2(0.9, 3.7), Vector2(0.5, 4.0), Vector2(0.0, 4.0)]), 16)
	lm.lathe("Gilt", lan + Vector3(0, 16.5, 0), LandmarkWestKit.ball(1.1), 12)
	LandmarkWestKit.cross(lm, "Gilt", lan + Vector3(0, 18.3, 0), 7.0)

## Westminster Abbey: see LandmarkLondonAbbey.
static func westminster_abbey(model: Node3D) -> void:
	LandmarkLondonAbbey.build(model)
