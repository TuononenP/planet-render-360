class_name LandmarkLpKrak
extends RefCounted

## Krak des Chevaliers in true metres, compass frame (+X east, -Z north).

## Concentric Hospitaller castle on its spur, y = 0 on the outer ward (the
## rock talus rises round the foot of the outer curtain). The outer
## curtain (9 m) of round towers with machicolated parapets, arrow loops
## and box machicolations, the east gate tower and the long vaulted ramp
## up to the inner ward; the raised inner ward behind its steep glacis
## with the four great round towers (the Warden's tower at the south-west,
## 34 m, with its upper hall windows), the square towers, the cistern
## (birket) between the walls on the south; inside, the vaulted chapel
## (21.5 x 8.5 m) with its apse and the Hall of the Knights with the
## Gothic loggia on the court. Every roof is a flat terrace.
static func krak(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#C9B78F", 4.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8D7D63", 8.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#1F1A15", 3.0, 0.92))
	var ring := PackedVector2Array([Vector2(-36, -62), Vector2(0, -66), Vector2(34, -56),
		Vector2(42, -20), Vector2(42, 25), Vector2(34, 58), Vector2(-2, 66), Vector2(-34, 56),
		Vector2(-44, 20), Vector2(-44, -24)])
	var ctr := Vector2.ZERO
	for p in ring:
		ctr += p / float(ring.size())
	lm.poly_prism("Rock", ring, 0.0, 0.3)
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		var mid := (p + q) * 0.5
		var e := (q - p).normalized()
		var out2 := Vector2(e.y, -e.x)
		if out2.dot(mid - ctr) < 0.0:
			out2 = -out2
		var out := Vector3(out2.x, 0, out2.y)
		var a := Vector3(p.x, 0, p.y)
		var b := Vector3(q.x, 0, q.y)
		# Rock talus sloping up to the curtain's foot.
		lm.quad("Rock", a + out * 9.0, b + out * 9.0, b + out * 1.6 + Vector3(0, 3.0, 0), a + out * 1.6 + Vector3(0, 3.0, 0),
			(out * 3.0 + Vector3.UP * 7.4).normalized())
		_curtain(lm, a, b, out, 9.0, 3.5)
		_round_tower(lm, a, 5.0, 13.0)
		if p.distance_to(q) > 40.0:
			_round_tower(lm, (a + b) * 0.5, 4.6, 12.0)
	# East gate tower and the vaulted ramp climbing north to the inner ward.
	var gt := Vector3(44.5, 0, 2.5)
	lm.box("Wall", gt + Vector3(0, 7.0, 0), Vector3(9.0, 14.0, 11.0))
	LandmarkLpParts.arch_panel(lm, "Dark", gt + Vector3(4.52, 0, 0), PI * 0.5, 1.6, 3.2, 1.9)
	LandmarkLpDetail.arch_band(lm, "Wall", gt + Vector3(4.5, 0, 0), PI * 0.5, 1.6, 3.2, 1.9, 0.5, 0.25)
	lm.box("Wall", gt + Vector3(5.0, 11.0, 0), Vector3(1.0, 1.4, 6.0))
	for k in 6:
		lm.box("Wall", gt + Vector3(4.8, 10.0, -2.5 + float(k)), Vector3(0.6, 0.6, 0.4))
	LandmarkLpParts.merlons(lm, "Wall", gt + Vector3(4.2, 14.0, -5.5), gt + Vector3(4.2, 14.0, 5.5), 1.0, 1.2, 0.9, 2.0)
	lm.box("Wall", Vector3(33.0, 4.5, -22.0), Vector3(7.0, 9.0, 44.0))
	for i in 7:
		lm.box("Dark", Vector3(36.52, 5.0, -40.0 + 6.0 * float(i)), Vector3(0.06, 1.6, 0.3), Basis(), 0.0)
	# Birket: the cistern between the walls on the south.
	lm.box("Rock", Vector3(-2.0, 0.6, 51.0), Vector3(62.0, 1.2, 10.0))
	lm.box("Dark", Vector3(-2.0, 1.1, 51.0), Vector3(60.0, 0.1, 8.0), Basis(), 0.0)
	_inner_ward(lm)
	lm.commit(model)

## Curtain from a to b (foot level) `h` high, `th` thick, facing `out`:
## wall, arrow loops, wall-walk merlons with loopholes, a box machicolation
## on each long run.
static func _curtain(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, h: float, th: float) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var span := a.distance_to(b)
	lm.box("Wall", (a + b) * 0.5 + Vector3(0, h * 0.5, 0), Vector3(span, h, th), basis)
	lm.box("Wall", (a + b) * 0.5 + out * (th * 0.5 + 0.1) + Vector3(0, 0.6, 0), Vector3(span, 1.2, 0.6), basis)
	var face := out * (th * 0.5 + 0.03)
	var n := int(span / 6.0)
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		lm.box("Dark", a.lerp(b, t) + face + Vector3(0, h * 0.45, 0), Vector3(0.25, 1.6, 0.06), basis, 0.0)
	var mc := int(span / 2.2)
	for i in mc:
		var p := a.lerp(b, (float(i) + 0.5) / float(mc)) + out * (th * 0.5 - 0.5) + Vector3(0, h, 0)
		lm.box("Wall", p + Vector3(0, 0.6, 0), Vector3(1.1, 1.2, 1.0), basis)
		lm.box("Dark", p + out * 0.52 + Vector3(0, 0.6, 0), Vector3(0.12, 0.6, 0.04), basis, 0.0)
	if span > 30.0:
		var m := (a + b) * 0.5 + out * (th * 0.5 + 0.7) + Vector3(0, h - 1.6, 0)
		lm.box("Wall", m + Vector3(0, 0.8, 0), Vector3(3.2, 1.6, 1.4), basis)
		for s in [-1.0, 0.0, 1.0]:
			lm.box("Wall", m + dir * (float(s) * 1.2) - Vector3(0, 0.5, 0), Vector3(0.4, 0.6, 1.2), basis)
		lm.box("Wall", m + Vector3(0, 1.75, 0), Vector3(3.4, 0.3, 1.6), basis)

## Round tower of radius r rising to `top`: battered base, string course,
## two rings of arrow loops, corbelled machicolation and merlons with loops.
static func _round_tower(lm: LandmarkMesh, base: Vector3, r: float, top: float) -> void:
	var prof := PackedVector2Array([Vector2(r * 1.3, 0.0), Vector2(r * 1.15, top * 0.25), Vector2(r, top * 0.4),
		Vector2(r, top - 2.4), Vector2(r * 1.14, top - 2.0), Vector2(r * 1.14, top)])
	lm.lathe("Wall", base, prof, 24)
	lm.frustum("Wall", base + Vector3(0, top * 0.4, 0), r + 0.15, r + 0.15, 0.4, 24)
	LandmarkLpDetail.slit_ring(lm, "Dark", base, r, top * 0.55, 6, 1.8, 0.28)
	LandmarkLpDetail.slit_ring(lm, "Dark", base, r, top * 0.78, 6, 1.6, 0.28, PI / 6.0)
	var nc := int(TAU * r / 1.4)
	for k in nc:
		var a := TAU * float(k) / float(nc)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Wall", base + d * (r + 0.25) + Vector3(0, top - 2.65, 0), Vector3(0.45, 0.6, 0.55), Basis.looking_at(d))
	var nm := int(TAU * r * 1.14 / 2.0)
	for k in nm:
		var a := TAU * float(k) / float(nm)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Wall", base + d * r * 1.08 + Vector3(0, top + 0.6, 0), Vector3(1.0, 1.2, 0.9), Basis.looking_at(d))
		lm.box("Dark", base + d * (r * 1.08 + 0.46) + Vector3(0, top + 0.6, 0), Vector3(0.12, 0.6, 0.04),
			Basis.looking_at(d), 0.0)

## Sloping skirt of four trapezoids from the rectangle `outer` (half-extents
## in x, z) at y = 0 up to `inner` at height h, centred on c.
static func _glacis(lm: LandmarkMesh, c: Vector3, outer: Vector2, inner: Vector2, h: float) -> void:
	var o := [Vector3(-outer.x, 0, -outer.y), Vector3(outer.x, 0, -outer.y),
		Vector3(outer.x, 0, outer.y), Vector3(-outer.x, 0, outer.y)]
	var n := [Vector3(-inner.x, h, -inner.y), Vector3(inner.x, h, -inner.y),
		Vector3(inner.x, h, inner.y), Vector3(-inner.x, h, inner.y)]
	var out_n := [Vector3(0, outer.y - inner.y, -h), Vector3(h, outer.x - inner.x, 0),
		Vector3(0, outer.y - inner.y, h), Vector3(-h, outer.x - inner.x, 0)]
	for i in 4:
		var j := (i + 1) % 4
		lm.quad("Wall", c + (o[i] as Vector3), c + (o[j] as Vector3), c + (n[j] as Vector3),
			c + (n[i] as Vector3), (out_n[i] as Vector3).normalized())

## Square tower of side s from the inner ward up to `top`: loops, merlons.
static func _square_tower(lm: LandmarkMesh, c: Vector3, s: float, y0: float, top: float) -> void:
	lm.box("Wall", c + Vector3(0, (y0 + top) * 0.5, 0), Vector3(s, top - y0, s))
	lm.box("Wall", c + Vector3(0, top - 0.3, 0), Vector3(s + 0.8, 0.6, s + 0.8))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var d := LandmarkLpParts.outward(yaw)
		var r := LandmarkLpParts.across(yaw)
		for u in [-s * 0.25, s * 0.25]:
			lm.box("Dark", c + d * (s * 0.5 + 0.03) + r * float(u) + Vector3(0, (y0 + top) * 0.5, 0),
				Vector3(0.3, 1.8, 0.06), Basis(Vector3.UP, yaw), 0.0)
		var e := c + d * (s * 0.5) + Vector3(0, top, 0)
		LandmarkLpParts.merlons(lm, "Wall", e - r * (s * 0.5), e + r * (s * 0.5), 1.0, 1.2, 0.8, 2.0)

## Inner ward: platform and glacis, curtains, towers, chapel, hall, loggia.
static func _inner_ward(lm: LandmarkMesh) -> void:
	var cx := -1.0
	var cz := 3.0
	lm.box("Wall", Vector3(cx, 6.0, cz), Vector3(52, 12.0, 70))
	_glacis(lm, Vector3(cx, 0, cz), Vector2(33.0, 42.0), Vector2(26.0, 35.0), 12.0)
	for s in [-1.0, 1.0]:
		var sx := float(s)
		lm.box("Wall", Vector3(cx + sx * 25.0, 16.0, cz), Vector3(3.0, 8.0, 70))
		lm.box("Wall", Vector3(cx, 16.0, cz + sx * 34.0), Vector3(52, 8.0, 3.0))
		LandmarkLpParts.merlons(lm, "Wall", Vector3(cx + sx * 25.6, 20.0, cz - 35.0),
			Vector3(cx + sx * 25.6, 20.0, cz + 35.0), 1.0, 1.2, 1.0, 2.2)
		LandmarkLpParts.merlons(lm, "Wall", Vector3(cx - 26.0, 20.0, cz + sx * 34.6),
			Vector3(cx + 26.0, 20.0, cz + sx * 34.6), 1.0, 1.2, 1.0, 2.2)
		for i in 9:
			lm.box("Dark", Vector3(cx + sx * 26.53, 16.0, cz - 30.0 + 7.5 * float(i)), Vector3(0.06, 1.8, 0.3), Basis(), 0.0)
			lm.box("Dark", Vector3(cx - 22.0 + 5.5 * float(i), 16.0, cz + sx * 35.53), Vector3(0.3, 1.8, 0.06), Basis(), 0.0)
	# The great round towers on the south and west; the Warden's upper hall.
	_round_tower(lm, Vector3(-27.0, 0, 38.0), 8.2, 34.0)
	_round_tower(lm, Vector3(-1.0, 0, 41.0), 7.6, 31.0)
	_round_tower(lm, Vector3(25.0, 0, 38.0), 7.2, 29.5)
	_round_tower(lm, Vector3(-27.0, 0, 3.0), 6.6, 27.5)
	for k in 8:
		var a := TAU * float(k) / 8.0 + 0.2
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkLpParts.arch_panel(lm, "Dark", Vector3(-27.0, 0, 38.0) + d * 8.22 + Vector3(0, 26.4, 0), PI * 0.5 - a,
			0.6, 1.8, 1.0)
	for t in [Vector3(-1, 0, -32), Vector3(25, 0, -32), Vector3(25, 0, 6)]:
		_square_tower(lm, t as Vector3, 8.5, 12.0, 26.0)
	# Chapel (north): nave 21.5 x 8.5 m, apse, west door, windows, flat roof.
	var ch := Vector3(-1.0, 12.0, -18.0)
	lm.box("Wall", ch + Vector3(0, 4.5, 0), Vector3(21.5, 9.0, 8.5))
	lm.box("Wall", ch + Vector3(0, 9.2, 0), Vector3(22.1, 0.4, 9.1))
	lm.frustum("Wall", ch + Vector3(10.75, 0, 0), 3.6, 3.6, 8.0, 12)
	LandmarkLpParts.arch_panel(lm, "Dark", ch + Vector3(-10.77, 0, 0), -PI * 0.5, 1.1, 2.6, 1.6)
	LandmarkLpDetail.arch_band(lm, "Wall", ch + Vector3(-10.75, 0, 0), -PI * 0.5, 1.1, 2.6, 1.6, 0.35, 0.3)
	for i in 3:
		for s in [-1.0, 1.0]:
			LandmarkLpParts.arch_panel(lm, "Dark", ch + Vector3(-7.2 + 7.2 * float(i), 4.6, float(s) * 4.27),
				0.0 if s > 0.0 else PI, 0.45, 1.6, 0.7)
			lm.box("Wall", ch + Vector3(-3.6 + 7.2 * float(i) - 3.6, 4.0, float(s) * 4.6), Vector3(1.0, 8.0, 0.8))
	# Hall of the Knights (west) and its Gothic loggia on the court.
	var hl := Vector3(-19.0, 12.0, 8.0)
	lm.box("Wall", hl + Vector3(0, 4.5, 0), Vector3(10.0, 9.0, 36.0))
	lm.box("Wall", hl + Vector3(0, 9.2, 0), Vector3(10.6, 0.4, 36.6))
	var bays := LandmarkLpDetail.bays(7, 24.0, 1.2, 3.4, 2.0)
	var lf := hl + Vector3(8.5, 0, 0)
	lm.box("Wall", lf + Vector3(-1.75, 7.3, 0), Vector3(3.5, 0.6, 24.0))
	LandmarkLpParts.slab(lm, "Wall", LandmarkLpParts.arcade_outline(24.0, 7.0, bays, 8), lf, PI * 0.5, 1.0)
	lm.box("Dark", lf + Vector3(-3.2, 2.8, 0), Vector3(0.1, 5.6, 23.6), Basis(), 0.0)
	for ar in bays:
		var z: float = -float(ar[0])
		lm.frustum("Wall", lf + Vector3(-0.5, 0, z), 0.12, 0.1, 4.4, 8)
		LandmarkLpDetail.arch_band(lm, "Wall", lf + Vector3(0, 0, z), PI * 0.5, 1.2, 3.4, 2.0, 0.25, 0.15)
		lm.disc("Wall", lf + Vector3(0.05, 4.3, z), Vector3(1, 0, 0), 0.35, 10)
	LandmarkLpParts.merlons(lm, "Wall", lf + Vector3(-0.3, 7.6, -12.0), lf + Vector3(-0.3, 7.6, 12.0), 0.8, 0.9, 0.6, 1.8)
