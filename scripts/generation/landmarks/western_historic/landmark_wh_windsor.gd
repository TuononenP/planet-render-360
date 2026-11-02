class_name LandmarkWhWindsor
extends RefCounted

## Windsor Castle in true metres, y = 0 at the ground of the wards, long
## axis along X (Lower Ward west, Upper Ward east).

## Windsor Castle (45 m to the top of the Round Tower's flag turret):
## the royal fortress on its chalk bluff. The Round Tower on its 15 m
## motte at the centre (raised by Wyatville in the 1820s, with its flag
## turret); the Upper Ward quadrangle of the State Apartments and
## private ranges to the east, with Wyatville's Gothic windows,
## battlements and square towers (the George IV Gateway on the south
## front); the Lower Ward to the west with St George's Chapel (1475-
## 1528; Perpendicular, no tower: pinnacled buttresses carrying the
## King's Beasts, the great west window and the polygonal transept
## ends), the Horseshoe Cloister, the Military Knights' lodgings and the
## Curfew Tower with its conical roof; the Norman Gate between the wards
## and the crenellated curtain with its towers round the whole.
static func windsor_castle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#BDB5A0", 4.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#5A636A", 2.5))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4A", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	# Curtain wall round the whole castle, a tower at each corner.
	var pts: Array[Vector2] = [Vector2(-250, -44), Vector2(-120, -48), Vector2(-45, -50), Vector2(45, -56),
		Vector2(190, -62), Vector2(192, 60), Vector2(45, 56), Vector2(-45, 52), Vector2(-120, 48), Vector2(-250, 44)]
	for i in pts.size():
		var a := Vector3(pts[i].x, 0.0, pts[i].y)
		var b := Vector3(pts[(i + 1) % pts.size()].x, 0.0, pts[(i + 1) % pts.size()].y)
		LandmarkWhKit.crenel_wall(lm, "Stone", a, b, 10.0, 3.0, 3.0)
		# Battered plinth and a string course under the parapet.
		var d := b - a
		var bs := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.box("Stone", (a + b) * 0.5 + Vector3(0, 1.5, 0), Vector3(4.2, 3.0, d.length()), bs)
		lm.box("Stone", (a + b) * 0.5 + Vector3(0, 9.0, 0), Vector3(3.6, 0.4, d.length()), bs, 0.0)
		lm.frustum("Stone", a, 5.6, 5.0, 18.0, 14)
		lm.frustum("Stone", a, 6.4, 5.6, 3.5, 14)
		LandmarkWhGothic.machicolation_ring(lm, "Stone", a + Vector3(0, 16.0, 0), 5.0, 1.4, 1.6)
		lm.frustum("Stone", a + Vector3(0, 17.2, 0), 5.6, 5.6, 0.8, 14)
		LandmarkWhKit.crenel_ring(lm, "Stone", a + Vector3(0, 18.0, 0), 5.2, 9, 2.0, 1.3, 1.0)
		LandmarkWhGothic.slit_ring(lm, "Glass", a, 5.3, 4, [7.0, 12.0], 2.0)
	_round_tower(lm)
	_upper_ward(lm)
	# Norman Gate between the wards, two drum towers over the passage.
	for sz in [-1.0, 1.0]:
		lm.frustum("Stone", Vector3(-50.0, 0, sz * 9.0), 5.6, 5.2, 18.0, 14)
		LandmarkWhGothic.machicolation_ring(lm, "Stone", Vector3(-50.0, 16.0, sz * 9.0), 5.2, 1.4, 1.6)
		lm.frustum("Stone", Vector3(-50.0, 17.2, sz * 9.0), 5.8, 5.8, 0.8, 14)
		LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(-50.0, 18.0, sz * 9.0), 5.4, 9, 2.0, 1.2, 1.0)
		LandmarkWhGothic.slit_ring(lm, "Glass", Vector3(-50.0, 0, sz * 9.0), 5.4, 4, [6.0, 11.0], 2.0)
	LandmarkWestKit.blk(lm, "Stone", -50.0, 0, 0, 8.0, 16.0, 8.0)
	LandmarkWestKit.arch_wall(lm, "Stone", Basis(), Vector3(-50.0, 0, 0), 4.0, 4.2, 2.0, 3.0, 9.0)
	_lower_ward(lm)
	lm.commit(model)

## The Round Tower: the turfed motte, revetment ring, the shell keep
## (heightened in the 1830s) with its Gothic windows, battlements and
## the flag turret with its conical cap.
static func _round_tower(lm: LandmarkMesh) -> void:
	lm.lathe("Lawn", Vector3(0, 0, 0), PackedVector2Array([Vector2(56, 0), Vector2(44, 5), Vector2(34, 10),
		Vector2(26.5, 15.0)]), 32)
	lm.frustum("Stone", Vector3(0, 12.0, 0), 27.0, 25.0, 3.5, 32)
	LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(0, 15.5, 0), 25.0, 40, 1.8, 1.0, 0.8)
	lm.frustum("Stone", Vector3(0, 15.0, 0), 14.2, 13.4, 21.0, 32)
	lm.frustum("Stone", Vector3(0, 15.0, 0), 15.0, 14.2, 3.0, 32)
	lm.frustum("Stone", Vector3(0, 25.0, 0), 14.0, 14.0, 0.5, 32)
	lm.frustum("Stone", Vector3(0, 34.5, 0), 13.4, 14.6, 2.5, 32)
	LandmarkWhGothic.machicolation_ring(lm, "Stone", Vector3(0, 33.2, 0), 13.4, 1.6, 1.8)
	LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(0, 37.0, 0), 14.2, 26, 2.0, 1.4, 1.2)
	# Buttress strips round the keep and two rings of windows.
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Stone", d * 14.0 + Vector3(0, 25.0, 0), Vector3(1.2, 19.0, 1.0), Basis(Vector3.UP, atan2(d.x, d.z)))
		var wd := Vector3(cos(a + PI / 12.0), 0, sin(a + PI / 12.0))
		LandmarkWhGothic.window(lm, "Glass", "Stone", wd * 13.75 + Vector3(0, 19.0, 0), wd, 1.2, 2.4, 0.8, 1, 0.25)
		LandmarkWhGothic.window(lm, "Glass", "Stone", wd * 13.6 + Vector3(0, 27.0, 0), wd, 1.4, 3.4, 1.0, 2, 0.25)
	# Flag turret.
	var ft := Vector3(9.0, 15.0, -9.0)
	lm.frustum("Stone", ft, 2.8, 2.5, 26.0, 12)
	LandmarkWhGothic.machicolation_ring(lm, "Stone", ft + Vector3(0, 24.4, 0), 2.5, 1.0, 1.2)
	lm.frustum("Stone", ft + Vector3(0, 25.4, 0), 2.9, 2.9, 0.6, 12)
	LandmarkWhKit.crenel_ring(lm, "Stone", ft + Vector3(0, 26.0, 0), 2.6, 7, 1.2, 1.2, 0.7)
	lm.lathe("Slate", ft + Vector3(0, 26.0, 0), PackedVector2Array([Vector2(2.6, 0), Vector2(0, 4.0)]), 12)
	for y in [29.0, 35.0]:
		LandmarkWhGothic.slit(lm, "Glass", ft + Vector3(0, y - 15.0, 0) + Vector3(2.62, 0, 0), Vector3(1, 0, 0), 1.8)

## Battlemented range a -> b (ground points) of height h facing out:
## the block, a string course, merlons, Wyatville's two-light Gothic
## windows on both storeys with hood moulds, and buttress strips.
static func _range(lm: LandmarkMesh, a: Vector3, b: Vector3, depth: float, h: float, out: Vector3,
		ys: Array) -> void:
	var dir := (b - a).normalized()
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5 - out * depth * 0.5
	lm.box("Stone", mid + Vector3(0, h * 0.5, 0), Vector3(dl, h, depth), Basis(dir, Vector3.UP, dir.cross(Vector3.UP)))
	lm.box("Stone", mid + Vector3(0, h - 0.4, 0), Vector3(dl + 0.8, 0.8, depth + 0.8),
		Basis(dir, Vector3.UP, dir.cross(Vector3.UP)))
	for s in [-1.0, 1.0]:
		var e := mid + out * float(s) * (depth * 0.5 + 0.2) + Vector3(0, h, 0)
		LandmarkWestKit.merlons(lm, "Stone", e - dir * dl * 0.5, e + dir * dl * 0.5, 2.4, 1.2, 1.2, 0.5)
	var bays := maxi(int(dl / 6.0), 1)
	for i in bays:
		var p := a.lerp(b, (float(i) + 0.5) / float(bays))
		for y in ys:
			LandmarkWhGothic.window(lm, "Glass", "Stone", p + out * 0.05 + Vector3(0, float(y), 0), out, 1.9, 2.8, 0.9,
				1, 0.25)
		if i > 0:
			var q := a.lerp(b, float(i) / float(bays))
			lm.box("Stone", q + out * 0.3 + Vector3(0, h * 0.5, 0), Vector3(0.9, h, 0.6), Basis(dir, Vector3.UP, out),
				0.0)

## Square battlemented tower: shaft, machicolated crown, merlons, and a
## stair turret on one corner when `turret`.
static func _sq_tower(lm: LandmarkMesh, c: Vector3, s: float, h: float, turret: bool) -> void:
	LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, s, h, s)
	LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, s + 1.2, 3.0, s + 1.2)
	LandmarkWestKit.blk(lm, "Stone", c.x, h, c.z, s + 1.4, 1.4, s + 1.4)
	var hs := s * 0.5
	var cs := [Vector3(c.x - hs, 0, c.z - hs), Vector3(c.x + hs, 0, c.z - hs), Vector3(c.x + hs, 0, c.z + hs),
		Vector3(c.x - hs, 0, c.z + hs)]
	for i in 4:
		var p0: Vector3 = cs[i]
		var p1: Vector3 = cs[(i + 1) % 4]
		var o := ((p0 + p1) * 0.5 - Vector3(c.x, 0, c.z)).normalized()
		LandmarkWhGothic.machicolation_run(lm, "Stone", p0 + Vector3(0, h - 1.6, 0), p1 + Vector3(0, h - 1.6, 0), o,
			1.6, 1.5)
		var mid := (p0 + p1) * 0.5
		for y in [h * 0.35, h * 0.65]:
			LandmarkWhGothic.window(lm, "Glass", "Stone", mid + o * 0.05 + Vector3(0, y, 0), o, 1.8, 3.0, 1.0, 1, 0.25)
	LandmarkWhKit.crenel_ring(lm, "Stone", Vector3(c.x, h + 1.4, c.z), s * 0.62, 8, 2.4, 1.2, 1.0)
	if turret:
		var tp := Vector3(c.x + hs, 0, c.z - hs)
		lm.frustum("Stone", tp, 2.0, 2.0, h + 5.0, 10)
		LandmarkWhKit.crenel_ring(lm, "Stone", tp + Vector3(0, h + 5.0, 0), 1.9, 6, 1.1, 1.0, 0.6)

## The Upper Ward: four ranges round the quadrangle (State Apartments
## to the north), the corner and gate towers, the George IV Gateway.
static func _upper_ward(lm: LandmarkMesh) -> void:
	_range(lm, Vector3(62, 0, -40), Vector3(190, 0, -40), 20.0, 22.0, Vector3(0, 0, 1), [5.0, 13.0])
	_range(lm, Vector3(62, 0, 38), Vector3(190, 0, 38), 20.0, 20.0, Vector3(0, 0, -1), [5.0, 12.0])
	_range(lm, Vector3(78, 0, -30), Vector3(78, 0, 28), 16.0, 18.0, Vector3(1, 0, 0), [5.0, 11.5])
	_range(lm, Vector3(174, 0, -30), Vector3(174, 0, 28), 16.0, 22.0, Vector3(-1, 0, 0), [5.0, 13.0])
	# Outward faces of the north (State Apartments) and east ranges.
	for k in 18:
		var x := 66.0 + 7.0 * float(k)
		for y in [6.0, 14.0]:
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(x, y, -60.05), Vector3(0, 0, -1), 1.9, 3.4, 1.0, 1, 0.3)
	for k in 9:
		var z := -36.0 + 8.0 * float(k)
		for y in [6.0, 14.0]:
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(190.05, y, z), Vector3(1, 0, 0), 1.9, 3.4, 1.0, 1, 0.3)
	for t in [[66.0, -56.0, 28.0], [188.0, -58.0, 30.0], [188.0, 56.0, 26.0], [66.0, 52.0, 24.0], [126.0, -62.0, 27.0],
			[150.0, -62.0, 25.0]]:
		_sq_tower(lm, Vector3(t[0], 0, t[1]), 12.0, t[2], int(t[0]) % 2 == 0)
	# George IV Gateway on the south range: twin towers over the arch.
	for sx in [-1.0, 1.0]:
		_sq_tower(lm, Vector3(126.0 + sx * 7.5, 0, 52.0), 8.0, 26.0, false)
	LandmarkWestKit.blk(lm, "Stone", 126.0, 0, 52.0, 7.0, 21.0, 8.0)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(126.0, 0.2, 56.05), Vector3(0, 0, 1), 4.6, 5.0, 2.2, 1, 0.5)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(126.0, 11.0, 56.05), Vector3(0, 0, 1), 3.4, 4.0, 1.6, 3, 0.3)

## The Lower Ward: St George's Chapel, the Horseshoe Cloister, the
## lodgings along the curtain and the Curfew Tower.
static func _lower_ward(lm: LandmarkMesh) -> void:
	# St George's Chapel: aisled nave and quire in one, polygonal
	# transept ends, the great west window, King's Beasts on the
	# buttress pinnacles, the Lady (Albert Memorial) Chapel to the east.
	LandmarkWhKit.aisled_body(lm, "Stone", "Slate", "Glass", -168.0, -100.0, 8.0, 21.0, 11.5, 13.0, 3.0, 8)
	for sz in [-1.0, 1.0]:
		var tc := Vector3(-134.0, 0, sz * 13.0)
		lm.lathe("Stone", tc, PackedVector2Array([Vector2(6.0, 0), Vector2(6.0, 17.0)]), 6, 1.0, 1.0, 0.0, false)
		lm.lathe("Slate", tc + Vector3(0, 17.0, 0), PackedVector2Array([Vector2(6.3, 0), Vector2(0.0, 3.0)]), 6,
			1.0, 1.0, 0.0, false)
		for k in 3:
			var a: float = sz * (PI * 0.5 + deg_to_rad(-60.0 + 60.0 * float(k)))
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkWhGothic.window(lm, "Glass", "Stone", tc + d * 5.15 + Vector3(0, 4.0, 0), d, 3.2, 8.0, 1.4, 3, 0.3)
		LandmarkWhGothic.parapet(lm, "Stone", tc + Vector3(-5.0, 17.0, sz * 3.0), tc + Vector3(5.0, 17.0, sz * 3.0),
			Vector3(0, 0, sz), 1.2)
	for sz in [-1.0, 1.0]:
		for k in 9:
			var x := -168.0 + 8.5 * float(k)
			var p := Vector3(x, 0, sz * 13.6)
			LandmarkWhGothic.pinnacle(lm, "Stone", p + Vector3(0, 14.5, 0), 0.5, 1.4, 1.2)
			LandmarkWhGothic.jamb_figure(lm, "Stone", p + Vector3(0, 17.3, 0), 1.6)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-168.1, 4.0, 0), Vector3(-1, 0, 0), 8.0, 10.0, 3.0, 9, 0.45)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-168.1, 1.0, 9.0), Vector3(-1, 0, 0), 2.6, 5.0, 1.4, 2, 0.3)
	LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-168.1, 1.0, -9.0), Vector3(-1, 0, 0), 2.6, 5.0, 1.4, 2,
		0.3)
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(-168.2, 21.0, -8.0), Vector3(-168.2, 21.0, 8.0), Vector3(-1, 0, 0),
		1.2)
	for sz in [-1.0, 1.0]:
		LandmarkWhGothic.pinnacle(lm, "Stone", Vector3(-168.5, 21.0, sz * 8.2), 0.7, 2.0, 3.0)
	LandmarkWestKit.blk(lm, "Stone", -90.0, 0, 0, 20.0, 18.0, 12.0)
	lm.gable("Slate", Vector3(-90.0, 18.0, 0), 12.0, 20.0, 3.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	for sz in [-1.0, 1.0]:
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(-99.0, 0, sz * 6.0), Vector3(-81.0, 0, sz * 6.0),
			Vector3(0, 0, sz), 3, 2.6, 7.0, 4.0, 1.6, 3, 0.3)
	# Lodgings of the Military Knights along both curtains, and the
	# Horseshoe Cloister round the chapel's west end.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, -sz)
		LandmarkWestKit.blk(lm, "Stone", -150.0, 0, sz * 38.0, 120.0, 9.0, 8.0)
		lm.gable("Slate", Vector3(-150.0, 9.0, sz * 38.0), 8.0, 120.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
		LandmarkWhGothic.window_row(lm, "Glass", "Stone", Vector3(-209.0, 0, sz * 33.95), Vector3(-91.0, 0, sz * 33.95),
			n, 20, 1.4, 2.2, 1.5, 0.8, 1, 0.2)
		for k in 10:
			var x := -204.0 + 12.0 * float(k)
			LandmarkWestKit.blk(lm, "Stone", x, 9.0, sz * 38.0, 1.4, 4.0, 1.4)
	for k in 7:
		var a := PI * 0.5 + PI * float(k) / 6.0
		var p := Vector3(-182.0, 0, 0) + Vector3(cos(a) * 0.6, 0, sin(a)) * 16.0
		LandmarkWestKit.blk(lm, "Stone", p.x, 0, p.z, 7.0, 7.0, 7.0, a)
		lm.gable("Slate", p + Vector3(0, 7.0, 0), 7.0, 7.0, 3.0, Basis(Vector3.UP, a), 0.3, "Stone")
	# The Curfew Tower (its French conical roof by Salvin, 1863).
	LandmarkWhKit.round_tower(lm, "Stone", "Slate", Vector3(-243.0, 0, 28.0), 7.0, 6.5, 24.0, 9.0, 16)
	LandmarkWhGothic.slit_ring(lm, "Glass", Vector3(-243.0, 0, 28.0), 6.8, 5, [6.0, 12.0, 18.0], 2.2)
	LandmarkWestKit.blk(lm, "Stone", -246.0, 0, 0, 8.0, 14.0, 12.0)
	LandmarkWestKit.merlons(lm, "Stone", Vector3(-250.0, 14.0, -6.0), Vector3(-250.0, 14.0, 6.0), 2.4, 1.2, 1.2, 0.6)
