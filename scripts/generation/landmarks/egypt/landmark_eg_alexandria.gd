class_name LandmarkEgAlexandria
extends RefCounted

## Two landmarks of the Alexandria waterfront in true metres, +X east and
## -Z north (the sea): the Mamluk Citadel of Qaitbay on the Pharos spit
## and the Bibliotheca Alexandrina.

# --- Citadel of Qaitbay ---

## The 1477 sea fort on the foundations of the Pharos: a 100 x 68 m
## curtain wall of 9 m crowned with round-topped merlons, round towers at
## the corners and along the walls, the gate between two towers on the
## east side; and the square three-storey keep (30 m, 17 m high) with
## its arrow-slit windows, the half-round towers rising at its four
## corners, the arched entrance up its stair, the battlemented roof and
## the small minaret of its mosque standing above it to 24 m.
static func qaitbay(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#D2BC90", 3.5))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#A39278", 6.0))
	lm.box("Rock", Vector3(0, 0.15, 0), Vector3(118.0, 0.3, 86.0), Basis(), 0.0)
	for k in 14:
		var a := TAU * float(k) / 14.0
		lm.box("Rock", Vector3(cos(a) * 58.0, 0.6, sin(a) * 42.0), Vector3(6.0, 1.2, 4.0), Basis(Vector3.UP, a))
	var hx := 50.0
	var hz := 34.0
	var corners := [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		LandmarkEgParts.wall(lm, "Wall", a, b, 9.0, 3.0)
		_merlons(lm, Vector3(a.x, 9.0, a.y), Vector3(b.x, 9.0, b.y), 1.5)
		# Arrow slits along the curtain.
		var dir := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
		var out := dir.cross(Vector3.UP)
		if out.dot(Vector3(a.x + b.x, 0, a.y + b.y)) < 0.0:
			out = -out
		var ln := a.distance_to(b)
		for k in int(ln / 8.0):
			var p := Vector3(a.x, 0, a.y) + dir * (8.0 * float(k) + 4.0) + out * 1.52 + Vector3(0, 5.5, 0)
			lm.box("Dark", p, Vector3(0.25, 1.4, 0.25), Basis(), 0.0)
	for s in corners:
		_tower(lm, Vector3(s.x, 0, s.y), 6.2, 12.0)
	for p in [Vector2(0, -hz), Vector2(0, hz), Vector2(-hx, 0), Vector2(-25.0, -hz), Vector2(25.0, -hz)]:
		_tower(lm, Vector3(p.x, 0, p.y), 3.6, 10.5)
	for z in [-9.0, 9.0]:
		_tower(lm, Vector3(hx, 0, z), 3.8, 11.5)
	lm.box("Wall", Vector3(hx + 1.0, 6.0, 0), Vector3(1.2, 2.0, 12.0))
	lm.box("Dark", Vector3(hx + 1.62, 3.0, 0), Vector3(0.1, 6.0, 4.0), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Wall", Vector3(hx + 1.5, 6.0, 0), Vector3.RIGHT, 4.0, 0.6, 0.4)
	_keep(lm, Vector3(-2.0, 0, 0))
	lm.commit(model)

## The keep: three storeys under string courses, slit windows, the
## corner half-towers, the stair and arched portal on the east face, the
## battlements and the minaret on the roof.
static func _keep(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Wall", c + Vector3(0, 7.5, 0), Vector3(30.0, 15.0, 30.0))
	for k in 2:
		lm.box("Wall", c + Vector3(0, 5.0 + 5.0 * float(k), 0), Vector3(30.6, 0.4, 30.6), Basis(), 0.0)
	_merlons(lm, c + Vector3(-15.0, 15.0, -15.0), c + Vector3(15.0, 15.0, -15.0), 1.0)
	_merlons(lm, c + Vector3(15.0, 15.0, -15.0), c + Vector3(15.0, 15.0, 15.0), 1.0)
	_merlons(lm, c + Vector3(15.0, 15.0, 15.0), c + Vector3(-15.0, 15.0, 15.0), 1.0)
	_merlons(lm, c + Vector3(-15.0, 15.0, 15.0), c + Vector3(-15.0, 15.0, -15.0), 1.0)
	for f in 4:
		var n := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(n)
		for row in 3:
			for k in 5:
				var x := -8.0 + 4.0 * float(k)
				if f == 1 and row == 0 and absf(x) < 1.0:
					continue
				var p := c + n * 15.05 + rt * x + Vector3(0, 2.6 + 5.0 * float(row), 0)
				lm.box("Dark", p, Vector3(0.5, 1.8, 0.1), Basis.looking_at(n), 0.0)
				lm.lathe("Wall", p + Vector3(0, 0.9, 0) + n * 0.05, PackedVector2Array([Vector2(0.45, 0),
					Vector2(0.0, 0.5)]), 6, 1.0, 0.3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_tower(lm, c + Vector3(sx * 15.0, 0, sz * 15.0), 4.8, 17.0)
	# Stair and arched portal on the east face.
	for k in 10:
		var sh := 0.5 + 0.5 * float(k)
		lm.box("Wall", c + Vector3(21.0 - 0.6 * float(k), sh * 0.5, -6.0), Vector3(0.6, sh, 3.0))
	lm.box("Wall", c + Vector3(16.5, 2.5, -6.0), Vector3(3.0, 5.0, 3.6))
	lm.box("Dark", c + Vector3(15.06, 7.2, 0), Vector3(0.1, 3.4, 2.0), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Wall", c + Vector3(15.1, 8.9, 0), Vector3.RIGHT, 2.0, 0.4, 0.3)
	# Minaret of the keep's mosque: square base, octagonal shaft, gallery, bulb.
	var m := c + Vector3(0, 15.0, 0)
	lm.box("Wall", m + Vector3(0, 1.6, 0), Vector3(3.6, 3.2, 3.6))
	lm.lathe("Wall", m + Vector3(0, 3.2, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.4, 3.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.lathe("Wall", m + Vector3(0, 5.8, 0), PackedVector2Array([Vector2(1.4, 0), Vector2(1.9, 0.5),
		Vector2(1.9, 0.9), Vector2(1.0, 0.9)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI * 0.25
		lm.frustum("Wall", m + Vector3(cos(a) * 0.8, 6.7, sin(a) * 0.8), 0.15, 0.12, 1.4, 6)
	lm.lathe("Wall", m + Vector3(0, 8.1, 0), LandmarkKits.onion_profile(1.0, 0.9), 12)

## Round tower of radius r and height h on `base`: battered drum, a
## string course, the machicolated parapet ring and its merlons.
static func _tower(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Wall", base, PackedVector2Array([Vector2(r * 1.08, 0), Vector2(r, h * 0.3), Vector2(r, h - 1.2)]), 20)
	lm.frustum("Wall", base + Vector3(0, h * 0.45, 0), r * 1.03, r * 1.03, 0.35, 20)
	lm.lathe("Wall", base + Vector3(0, h - 1.2, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 1.08, 0.4),
		Vector2(r * 1.1, 1.2)]), 20)
	var n := maxi(int(TAU * r / 1.6), 8)
	for k in n:
		var a := TAU * float(k) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		var p := base + d * r * 1.04 + Vector3(0, h, 0)
		lm.box("Wall", p + Vector3(0, 0.45, 0), Vector3(0.8, 0.9, 0.5), Basis.looking_at(d), 0.0)
		lm.lathe("Wall", p + Vector3(0, 0.9, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(0.3, 0.2),
			Vector2(0.0, 0.32)]), 6, 1.0, 0.6, -a)
		if k % 3 == 0:
			lm.box("Dark", base + d * (r + 0.02) + Vector3(0, h * 0.62, 0), Vector3(0.25, 1.2, 0.1),
				Basis.looking_at(d), 0.0)

## Round-topped Mamluk merlons along a wall top a-b, `pitch` m apart.
static func _merlons(lm: LandmarkMesh, a: Vector3, b: Vector3, pitch: float) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var n := int(a.distance_to(b) / (pitch * 2.0))
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.box("Wall", p + Vector3(0, 0.6, 0), Vector3(pitch, 1.2, 0.8), basis, 0.0)
		lm.lathe("Wall", p + Vector3(0, 1.2, 0), PackedVector2Array([Vector2(pitch * 0.5, 0),
			Vector2(pitch * 0.35, 0.25), Vector2(0.0, 0.4)]), 6, 1.0, 0.8 / pitch)

# --- Bibliotheca Alexandrina ---

## The 160 m cylinder (2002) of Aswan granite carved with letters of 120
## scripts, standing in a reflecting pool on the sea side, capped by the
## tilted disc roof that rises from 10 m on the sea side (-Z) to 32 m
## inland: a grid of glazed skylight "eyelids" in alternating glass and
## aluminium bands. On the plaza west, the 18 m sphere of the planetarium.
static func bibliotheca(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8B86", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#6C8EA3"))
	lm.use("Alu", LandmarkMaterials.paint("#B9BEC2", 0.35, 0.6))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#BDB6A8", 6.0))
	lm.use("Dark", LandmarkMaterials.paint("#3B3E42", 0.5, 0.2))
	lm.use("Water", LandmarkMaterials.glass("#2F4A55"))
	var r := 80.0
	lm.disc("Plaza", Vector3(0, 0.15, 0), Vector3.UP, r + 14.0, 48)
	# Reflecting pool round the sea-side half of the drum.
	for i in 24:
		var a0 := PI + PI * float(i) / 24.0
		var a1 := PI + PI * float(i + 1) / 24.0
		var p0 := Vector3(sin(a0), 0.2, cos(a0))
		var p1 := Vector3(sin(a1), 0.2, cos(a1))
		lm.quad("Water", Vector3(p0.x * r, 0.2, p0.z * r), Vector3(p1.x * r, 0.2, p1.z * r),
			Vector3(p1.x * (r + 10.0), 0.2, p1.z * (r + 10.0)), Vector3(p0.x * (r + 10.0), 0.2, p0.z * (r + 10.0)),
			Vector3.UP)
	var foot := PackedVector3Array()
	var rim := PackedVector3Array()
	var n := 64
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		foot.append(Vector3(r * sin(a), 0.0, r * cos(a)))
		rim.append(Vector3(r * sin(a), _roof_y(r * cos(a)), r * cos(a)))
	lm.grid("Granite", [foot, rim], Vector3.ZERO, true)
	# Carved characters in rows across the inland half of the wall.
	for row in 6:
		var y := 4.0 + 3.2 * float(row)
		for i in 70:
			var a := -PI * 0.45 + PI * 0.9 * (float(i) + 0.5 * float(row % 2)) / 70.0
			var d := Vector3(sin(a), 0, cos(a))
			if y + 2.0 > _roof_y(r * d.z) - 1.0:
				continue
			var j := 0.5 + 0.5 * sin(float(i * 13 + row * 7))
			lm.box("Granite", d * (r + 0.08) + Vector3(0, y, 0), Vector3(0.6 + 1.2 * j, 1.6, 0.16),
				Basis.looking_at(d), 0.0)
	# Roof disc in wedge bands, then the skylight grid on top of it.
	var normal := Vector3(0, 1.0, -11.0 / 80.0).normalized()
	var radii: Array[float] = [0.0, 30.0, 58.0, r]
	for i in n:
		var key := "Glass" if i % 4 < 2 else "Alu"
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		for k in 3:
			var p0 := _roof_pt(radii[k], a0)
			var p1 := _roof_pt(radii[k], a1)
			var q0 := _roof_pt(radii[k + 1], a0)
			var q1 := _roof_pt(radii[k + 1], a1)
			if k == 0:
				lm.tri(key, p0, q1, q0, normal, normal, normal, Vector2(p0.x, p0.z),
					Vector2(q1.x, q1.z), Vector2(q0.x, q0.z))
			else:
				lm.quad(key, p0, p1, q1, q0, normal)
	_skylights(lm, r)
	for i in n:
		lm.beam("Alu", rim[i] - Vector3(0, 0.2, 0), rim[i + 1] - Vector3(0, 0.2, 0), 1.0, 1.4,
			Vector3.UP, true)
	# Planetarium sphere on its ring, west on the plaza.
	var pc := Vector3(-r - 30.0, 0, 30.0)
	lm.frustum("Granite", pc, 7.0, 6.4, 3.0, 24)
	var sph := PackedVector2Array()
	for k in 17:
		var t := -PI * 0.3 + PI * 0.8 * float(k) / 16.0
		sph.append(Vector2(9.0 * cos(t), 9.0 + 9.0 * sin(t)))
	sph[16] = Vector2(0.0, 18.0)
	lm.lathe("Dark", pc + Vector3(0, 3.0 - sph[0].y, 0), sph, 32)
	lm.commit(model)

## The roof's skylights: on an 8 m grid inside the rim, each cell a
## sloped glazed eyelid facing north (the sea, -Z) over an aluminium back.
static func _skylights(lm: LandmarkMesh, r: float) -> void:
	var step := 8.0
	var k := int(r / step)
	for gx in range(-k, k):
		for gz in range(-k, k):
			var x0 := float(gx) * step + 0.8
			var x1 := x0 + step - 1.6
			var z0 := float(gz) * step + 1.0
			var z1 := z0 + step - 2.0
			if Vector2(maxf(absf(x0), absf(x1)), maxf(absf(z0), absf(z1))).length() > r - 2.0:
				continue
			var lift := 1.2
			var a := Vector3(x0, _roof_y(z0) + 0.05, z0)
			var b := Vector3(x1, _roof_y(z0) + 0.05, z0)
			var c := Vector3(x1, _roof_y(z1) + 0.05 + lift, z1)
			var d := Vector3(x0, _roof_y(z1) + 0.05 + lift, z1)
			var gn := (b - a).cross(d - a).normalized()
			if gn.y < 0.0:
				gn = -gn
			lm.quad("Glass", a, b, c, d, gn)
			var c0 := Vector3(x1, _roof_y(z1) + 0.05, z1)
			var d0 := Vector3(x0, _roof_y(z1) + 0.05, z1)
			lm.quad("Alu", d0, c0, c, d, Vector3.BACK)
			lm.tri("Alu", a, d, d0, Vector3.LEFT, Vector3.LEFT, Vector3.LEFT, Vector2.ZERO, Vector2(step, lift),
				Vector2(step, 0))
			lm.tri("Alu", b, c0, c, Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT, Vector2.ZERO, Vector2(step, 0),
				Vector2(step, lift))

## Roof plane height at depth z (10 m at the sea side, 32 m inland).
static func _roof_y(z: float) -> float:
	return 20.7 + 11.0 * z / 80.0

static func _roof_pt(rad: float, a: float) -> Vector3:
	var z := rad * cos(a)
	return Vector3(rad * sin(a), _roof_y(z), z)
