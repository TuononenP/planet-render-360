class_name LandmarkChSalzburg
extends RefCounted

## Hohensalzburg Fortress for LandmarkChCastles, in true metres: the
## white-rendered outer ring (about 450 m round, the city front about
## 150 m) on the rock, long axis east-west (X), the four towers of 1462
## on the ring, the Kuenburg bastion of 1681 (over 30 m) on the north,
## the four-storey Hoher Stock residence in the centre with its corner
## turrets, the Reckturm at the east end, St George's church, the bell
## tower and the arsenal and granary ranges. Draws on the castle
## builder's material keys (Plaster, Rock, Roof, Windows, Gilt).

const ROCK := [Vector2(-66, -18), Vector2(-44, -30), Vector2(8, -29), Vector2(50, -30), Vector2(68, -16),
	Vector2(70, 6), Vector2(50, 25), Vector2(0, 31), Vector2(-40, 27), Vector2(-64, 12)]

static func build(lm: LandmarkMesh) -> void:
	var rock := PackedVector2Array(ROCK)
	lm.poly_prism("Rock", rock, 0.0, 1.5)
	_ring(lm)
	_hoher_stock(lm, Vector3(20.0, 0, -8.0))
	_reckturm(lm, Vector3(44.0, 0, -8.0))
	_church_and_bell(lm)
	_ranges(lm)

## Curtain walls with buttresses, the wall-walk parapet with its
## embrasures, the round towers and the Kuenburg bastion.
static func _ring(lm: LandmarkMesh) -> void:
	var n := ROCK.size()
	for i in n:
		var a: Vector2 = ROCK[i]
		var b: Vector2 = ROCK[(i + 1) % n]
		var p := Vector3(a.x, 0, a.y)
		var q := Vector3(b.x, 0, b.y)
		LandmarkChParts.wall(lm, "Plaster", p, q, 0.0, 11.0, 2.4)
		LandmarkChParts.wall(lm, "Rock", p, q, 11.0, 11.6, 3.0)
		var dir := (q - p).normalized()
		var out := Vector3(dir.z, 0, -dir.x)
		if out.dot(p + q) < 0.0:
			out = -out
		LandmarkCeParts.merlons(lm, "Plaster", p + Vector3(0, 11.6, 0) + out * 0.9, q + Vector3(0, 11.6, 0) + out * 0.9,
			2.6, 1.3, 1.4, 0.8)
		var cnt := int(p.distance_to(q) / 9.0)
		for k in range(1, cnt):
			var f := p.lerp(q, float(k) / float(cnt)) + out * 1.2
			LandmarkChParts.buttress(lm, "Plaster", f, out, 1.8, 2.2, 8.0, 2)
			LandmarkChParts.frame_window(lm, "Rock", "Windows", f + dir * 4.5 + Vector3(0, 7.5, 0), out, 0.6, 1.0, 0.15, 0.12)
	# Round towers of 1462 at four corners of the ring.
	for k in [[0, 20.0, 8.0], [3, 18.0, 8.0], [5, 22.0, 9.0], [7, 17.0, 7.0]]:
		var v: Vector2 = ROCK[int(k[0])]
		var p := Vector3(v.x, 0, v.y)
		var h: float = k[1]
		lm.frustum("Plaster", p, 5.0, 4.6, h, 24)
		lm.frustum("Rock", p + Vector3(0, h, 0), 5.3, 5.3, 0.9, 24)
		for j in 6:
			var a := TAU * float(j) / 6.0
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkChParts.frame_window(lm, "Rock", "Windows", p + d * 4.7 + Vector3(0, h * 0.7, 0), d, 0.7, 1.2, 0.15, 0.12)
			LandmarkChParts.frame_window(lm, "Rock", "Windows", p + d * 4.85 + Vector3(0, h * 0.35, 0), d, 0.4, 0.9, 0.12, 0.1)
		lm.lathe("Roof", p + Vector3(0, h + 0.9, 0), PackedVector2Array([Vector2(5.5, 0), Vector2(4.6, 0.8),
			Vector2(2.4, float(k[2]) * 0.6), Vector2(0.2, float(k[2]))]), 16)
		LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h + 0.9 + float(k[2]), 0), 1.2, 0.2)
	# Kuenburg bastion: a tall angled bastion on the north (city) side.
	var kb := PackedVector2Array([Vector2(-8, -29), Vector2(16, -29), Vector2(12, -38), Vector2(2, -42), Vector2(-6, -37)])
	lm.poly_prism("Plaster", kb, 0.0, 14.0)
	lm.poly_prism("Rock", PackedVector2Array([Vector2(-8.5, -28.5), Vector2(16.5, -28.5), Vector2(12.5, -38.5),
		Vector2(2, -42.6), Vector2(-6.5, -37.5)]), 14.0, 14.6)
	for i in 4:
		var a := kb[i + 1]
		var b := kb[(i + 2) % kb.size()] if i < 3 else kb[0]
		var pa := Vector3(a.x, 14.6, a.y)
		var pb := Vector3(b.x, 14.6, b.y)
		LandmarkCeParts.merlons(lm, "Plaster", pa, pb, 2.8, 1.5, 1.4, 1.0)
		var dir := (pb - pa).normalized()
		var out := Vector3(-dir.z, 0, dir.x)
		if out.z > 0.0:
			out = -out
		for k in 3:
			LandmarkChParts.frame_window(lm, "Rock", "Windows", pa.lerp(pb, (float(k) + 0.5) / 3.0) - Vector3(0, 6.0, 0)
				+ out * 0.05, out, 0.8, 1.0, 0.15, 0.12)

## Hoher Stock: the four-storey residence, framed windows on every face,
## the hip roof with dormers and chimneys, round corner turrets.
static func _hoher_stock(lm: LandmarkMesh, hs: Vector3) -> void:
	lm.box("Plaster", hs + Vector3(0, 15.0, 0), Vector3(36.0, 30.0, 20.0))
	LandmarkChParts.band(lm, "Rock", 29.5, 18.0, 10.0, 0.8, 0.5, hs)
	LandmarkChParts.band(lm, "Rock", 0.0, 18.0, 10.0, 1.6, 0.3, hs)
	LandmarkCeParts.hip(lm, "Roof", hs + Vector3(0, 30.0, 0), 37.0, 21.0, 11.0)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for r in 5:
			for i in 9:
				LandmarkChParts.frame_window(lm, "Rock", "Windows", hs + Vector3(-15.2 + 3.8 * i, 7.0 + 5.2 * r, sz * 10.0), n,
					1.4, 2.4, 0.2, 0.15)
		for i in 4:
			var dp := hs + Vector3(-12.0 + 8.0 * i, 31.6, sz * 7.0)
			var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
			lm.box("Plaster", dp + Vector3(0, 0.9, 0), Vector3(1.8, 1.8, 1.6), b)
			lm.gable("Roof", dp + Vector3(0, 1.8, 0), 1.8, 1.6, 1.0, b, 0.12, "Plaster")
			LandmarkChParts.frame_window(lm, "Rock", "Windows", dp + b * Vector3(0, 0.9, 0.8), b.z, 0.8, 1.0, 0.12, 0.1)
	for sx in [-1.0, 1.0]:
		for r in 5:
			for i in 4:
				LandmarkChParts.frame_window(lm, "Rock", "Windows", hs + Vector3(sx * 18.0, 7.0 + 5.2 * r, -6.0 + 4.0 * i),
					Vector3(sx, 0, 0), 1.4, 2.4, 0.2, 0.15)
		lm.box("Plaster", hs + Vector3(sx * 9.0, 38.0, 0), Vector3(1.2, 4.0, 1.8))
	for sz in [-1.0, 1.0]:
		var p := hs + Vector3(-18.0, 0, sz * 10.0)
		lm.frustum("Plaster", p, 3.2, 3.0, 32.0, 20)
		lm.frustum("Rock", p + Vector3(0, 31.4, 0), 3.4, 3.4, 0.6, 20)
		for y in [12.0, 20.0, 27.0]:
			for d in [Vector3.LEFT, Vector3(0, 0, sz), Vector3(-0.707, 0, 0.707 * sz)]:
				LandmarkChParts.frame_window(lm, "Rock", "Windows", p + d * 3.05 + Vector3(0, y, 0), d, 0.8, 1.4, 0.15, 0.12)
		lm.lathe("Roof", p + Vector3(0, 32.0, 0), PackedVector2Array([Vector2(3.8, 0), Vector2(3.2, 0.8),
			Vector2(1.6, 5.0), Vector2(0.15, 9.0)]), 16)
		LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, 41.0, 0), 1.2, 0.2)

## Reckturm: tall square tower at the east end with corner bartizans, a
## gallery of windows and the pyramid cap with its gilt finial.
static func _reckturm(lm: LandmarkMesh, rt: Vector3) -> void:
	lm.box("Plaster", rt + Vector3(0, 17.0, 0), Vector3(8.0, 34.0, 8.0))
	LandmarkChParts.band(lm, "Rock", 30.0, 4.0, 4.0, 0.8, 0.4, rt)
	LandmarkChParts.band(lm, "Rock", 33.4, 4.0, 4.0, 0.6, 0.5, rt)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		for y in [12.0, 18.0]:
			LandmarkChParts.frame_window(lm, "Rock", "Windows", rt + b * Vector3(0, y, 4.0), n, 0.8, 1.6, 0.15, 0.12)
		for x in [-1.8, 0.0, 1.8]:
			LandmarkChParts.frame_window(lm, "Rock", "Windows", rt + b * Vector3(x, 24.0, 4.0), n, 1.0, 2.4, 0.15, 0.12)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := rt + Vector3(sx * 4.0, 0, sz * 4.0)
			lm.lathe("Plaster", p + Vector3(0, 26.0, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.9, 1.4),
				Vector2(1.1, 2.0)]), 10)
			lm.frustum("Plaster", p + Vector3(0, 28.0, 0), 1.1, 1.05, 6.0, 10)
			lm.lathe("Roof", p + Vector3(0, 34.0, 0), PackedVector2Array([Vector2(1.35, 0), Vector2(0.6, 2.0),
				Vector2(0.05, 3.6)]), 10)
	lm.spire("Roof", rt + Vector3(0, 34.0, 0), 4.6, 12.0, 0.0, 4)
	LandmarkChParts.finial(lm, "Gilt", rt + Vector3(0, 46.0, 0), SALZBURG_TOP - 46.0, 0.5)

const SALZBURG_TOP := 48.0

## St George's church (1501) with its little tower, and the bell tower
## on the west of the ring.
static func _church_and_bell(lm: LandmarkMesh) -> void:
	var c := Vector3(-14.0, 0, -6.0)
	lm.box("Plaster", c + Vector3(0, 8.0, 0), Vector3(22.0, 16.0, 12.0))
	lm.gable("Roof", c + Vector3(0, 16.0, 0), 12.0, 22.0, 8.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for i in 4:
			var x := c.x - 7.2 + 4.8 * i
			LandmarkChParts.lancet(lm, "Rock", "Windows", Vector3(x, 5.0, c.z + sz * 6.0), n, 1.4, 6.0, 0, 0.2)
			LandmarkChParts.buttress(lm, "Plaster", Vector3(x + 2.4, 0, c.z + sz * 6.0), n, 1.0, 1.4, 12.0, 2)
	lm.frustum("Plaster", c + Vector3(11.0, 0, 0), 6.0, 6.0, 16.0, 8, PI / 8.0)
	lm.lathe("Roof", c + Vector3(11.0, 16.0, 0), PackedVector2Array([Vector2(6.4, 0), Vector2(0.0, 7.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	var ct := Vector3(-27.0, 0, -6.0)
	lm.box("Plaster", ct + Vector3(0, 13.0, 0), Vector3(6.0, 26.0, 6.0))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.arched_window(lm, "Rock", "Windows", ct + b * Vector3(0, 20.0, 3.0), b.z, 1.2, 3.0, 0.2)
	lm.spire("Roof", ct + Vector3(0, 26.0, 0), 3.4, 8.0, 0.0, 8)
	LandmarkChParts.finial(lm, "Gilt", ct + Vector3(0, 34.0, 0), 1.4, 0.25)
	var bt := Vector3(-48.0, 0, 8.0)
	lm.frustum("Plaster", bt, 4.8, 4.5, 24.0, 20)
	for k in 4:
		var a := TAU * float(k) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Rock", "Windows", bt + d * 4.55 + Vector3(0, 18.0, 0), d, 1.2, 3.0, 0.2)
		LandmarkChParts.frame_window(lm, "Rock", "Windows", bt + d * 4.7 + Vector3(0, 10.0, 0), d, 0.7, 1.4, 0.15, 0.12)
	lm.lathe("Roof", bt + Vector3(0, 24.0, 0), PackedVector2Array([Vector2(5.3, 0), Vector2(4.5, 0.8),
		Vector2(2.2, 6.0), Vector2(0.2, 10.0)]), 16)
	LandmarkChParts.finial(lm, "Gilt", bt + Vector3(0, 34.0, 0), 1.4, 0.25)

## Arsenal, granary and barrack ranges with framed windows, dormers.
static func _ranges(lm: LandmarkMesh) -> void:
	# [centre x, z, length (X), depth, eave, ridge rise, along X]
	for r in [[-26.0, 15.0, 26.0, 8.0, 14.0, 5.0], [26.0, 16.0, 50.0, 9.0, 14.0, 6.0],
			[-34.0, -21.0, 28.0, 8.0, 12.0, 5.0]]:
		var c := Vector3(r[0], 0, r[1])
		var l: float = r[2]
		var d: float = r[3]
		var e: float = r[4]
		lm.box("Plaster", c + Vector3(0, e * 0.5, 0), Vector3(l, e, d))
		lm.gable("Roof", c + Vector3(0, e, 0), d, l, float(r[5]), Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
		var cnt := int(l / 4.2)
		for sz in [-1.0, 1.0]:
			var n := Vector3(0, 0, sz)
			for row in 2:
				for i in cnt:
					var x := c.x - l * 0.5 + l * (float(i) + 0.5) / float(cnt)
					LandmarkChParts.frame_window(lm, "Rock", "Windows", Vector3(x, 4.0 + 5.0 * row, c.z + sz * d * 0.5), n,
						1.3, 2.2, 0.18, 0.14)
			var dn := maxi(cnt >> 1, 1)
			for i in dn:
				var x := c.x - l * 0.5 + l * (float(i) + 0.5) / float(dn)
				var dp := Vector3(x, e + 1.2, c.z + sz * d * 0.25)
				var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
				lm.box("Plaster", dp + Vector3(0, 0.7, 0), Vector3(1.4, 1.4, 1.2), b)
				lm.gable("Roof", dp + Vector3(0, 1.4, 0), 1.4, 1.2, 0.8, b, 0.1, "Plaster")
	var ea := Vector3(57.0, 0, -2.0)
	lm.box("Plaster", ea + Vector3(0, 6.0, 0), Vector3(14.0, 12.0, 16.0))
	lm.gable("Roof", ea + Vector3(0, 12.0, 0), 14.0, 16.0, 5.0, Basis(), 0.5, "Plaster")
	for sx in [-1.0, 1.0]:
		for i in 3:
			LandmarkChParts.frame_window(lm, "Rock", "Windows", ea + Vector3(sx * 7.0, 6.0, -5.0 + 5.0 * i), Vector3(sx, 0, 0),
				1.2, 2.2, 0.18, 0.14)
