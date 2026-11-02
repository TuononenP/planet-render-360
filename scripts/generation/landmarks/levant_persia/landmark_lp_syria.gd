class_name LandmarkLpSyria
extends RefCounted

## Two Syrian landmarks in true metres, built in compass frame (+X east,
## -Z north): the Umayyad Mosque of Damascus and the Crusader castle of
## Krak des Chevaliers.

# --- Umayyad Mosque, Damascus ---

## 157 x 97 m Roman temenos: arcaded courtyard (122 x 50 m) on the north,
## the three-aisled prayer hall (136 x 37 m) on the south with its gabled
## lead roofs, the high central transept front and the Dome of the Eagle
## (36 m) on its octagonal drum; the Dome of the Treasury on eight columns;
## the Minarets of Jesus (SE, 77 m), the Bride (north) and Qaitbay (SW).
static func umayyad(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DAC9A2", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8E989F", 5.0, 0.45))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#D6C8A8", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#231D17", 3.0, 0.92))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Court", Vector3(0, -0.2, 0), Vector3(160, 0.4, 100))
	# Outer walls and the three courtyard wings (north, east, west).
	lm.box("Stone", Vector3(0, 7.5, -47.25), Vector3(157, 15.0, 2.5))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 71.5, 5.5, -17.0), Vector3(15.0, 11.0, 61.0))
		_arcade(lm, Vector3(s * 61.0, 0, -16.5), -s * PI * 0.5, 49.0, 6)
	lm.box("Stone", Vector3(0, 5.5, -42.0), Vector3(157, 11.0, 8.0))
	_arcade(lm, Vector3(0, 0, -38.0), 0.0, 122.0, 16)
	# Prayer hall: courtyard arcade, three E-W lead roofs, transept, dome.
	lm.box("Stone", Vector3(0, 7.5, 28.25), Vector3(157, 15.0, 40.5))
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(136.0, 14.0,
		_bays(17, 8.0, 2.2, 5.0), 6), Vector3(0, 0, 8.0), PI, 3.0)
	lm.box("Dark", Vector3(0, 3.5, 11.05), Vector3(136.0, 7.0, 0.1))
	for z in [14.2, 26.5]:
		lm.gable("Lead", Vector3(0, 15.0, z), 12.4, 157.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	lm.gable("Lead", Vector3(0, 15.0, 40.8), 15.6, 157.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	lm.box("Stone", Vector3(0, 10.0, 28.25), Vector3(24.0, 20.0, 40.5))
	lm.gable("Lead", Vector3(0, 20.0, 28.25), 24.0, 40.5, 4.0, Basis(), 0.0, "Stone")
	LandmarkLpParts.iwan(lm, "Stone", "Dark", Vector3(0, 0, 6.0), PI, 24.0, 24.0, 4.2, 9.0, 6.5, 5.0)
	var dc := Vector3(0, 0, 28.25)
	lm.frustum("Stone", dc + Vector3(0, 18.0, 0), 8.8, 8.8, 10.5, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		lm.box("Dark", dc + Vector3(cos(a) * 8.1, 24.0, sin(a) * 8.1), Vector3(0.3, 3.4, 2.4),
			Basis(Vector3.UP, -a))
	lm.lathe("Lead", dc + Vector3(0, 28.5, 0), LandmarkLpParts.dome_profile(9.2, 7.5, 8, 0.25), 24)
	# Dome of the Treasury on eight columns, in the western courtyard.
	var tc := Vector3(-36.0, 0, -22.0)
	lm.frustum("Stone", tc, 3.9, 3.7, 2.8, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Stone", tc + Vector3(cos(a) * 3.2, 2.8, sin(a) * 3.2), 0.4, 0.34, 5.6, 8)
	lm.frustum("Stone", tc + Vector3(0, 8.4, 0), 3.7, 3.5, 3.0, 8, PI / 8.0)
	lm.lathe("Lead", tc + Vector3(0, 11.4, 0), LandmarkLpParts.dome_profile(3.8, 3.4, 6, 0.1), 16)
	# Minarets: Jesus (tallest), the Bride on the north wall, Qaitbay.
	_minaret(lm, Vector3(74.0, 0, 44.0), 6.6, 44.0, 2.9, 16.0, 15.4)
	_minaret(lm, Vector3(0.0, 0, -45.0), 5.6, 36.0, 2.5, 12.0, 11.5)
	_minaret(lm, Vector3(-74.0, 0, 44.0), 5.6, 30.0, 2.5, 11.0, 10.5)
	lm.commit(model)

## Row of `n` equal round-arched bays along `length` in front of a wing:
## arcade slab (3 m) over a dark plate, then a plain upper storey.
static func _arcade(lm: LandmarkMesh, front: Vector3, yaw: float, length: float, n: int) -> void:
	var r := LandmarkLpParts.across(yaw)
	var f := LandmarkLpParts.outward(yaw)
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(length, 6.4,
		_bays(n, length / float(n), 1.7, 3.8), 6), front, yaw, 3.0)
	lm.box("Dark", front - f * 3.05 + Vector3(0, 3.0, 0), Vector3(length * absf(r.x) + 0.1 * absf(f.x),
		6.0, length * absf(r.z) + 0.1 * absf(f.z)))
	lm.box("Stone", front - f * 1.5 + Vector3(0, 8.6, 0), Vector3(length * absf(r.x) + 3.0 * absf(f.x),
		4.4, length * absf(r.z) + 3.0 * absf(f.z)))
	for i in n * 2:
		var u := -length * 0.5 + (float(i) + 0.5) * length / float(n * 2)
		LandmarkLpParts.arch_panel(lm, "Dark", front + r * u + Vector3(0, 6.9, 0) + f * 0.04, yaw, 0.8, 1.6, 0.8)

## `n` arched bays of half-width a (spring height s) at pitch `pitch`,
## centred on u = 0, as arcade_outline entries.
static func _bays(n: int, pitch: float, a: float, s: float) -> Array:
	var out: Array = []
	for i in n:
		out.append([(float(i) - float(n - 1) * 0.5) * pitch, a, s, a])
	return out

## Damascene minaret: square shaft with two covered galleries, octagonal
## upper stage with an open gallery, lead spire and gilded finial. Top at
## base.y + sq_h + 0.8 + oct_h + spire_h + 0.8.
static func _minaret(lm: LandmarkMesh, base: Vector3, side: float, sq_h: float, oct_r: float,
		oct_h: float, spire_h: float) -> void:
	lm.box("Stone", base + Vector3(0, sq_h * 0.5, 0), Vector3(side, sq_h, side))
	for f in [0.42, 0.9]:
		lm.box("Stone", base + Vector3(0, sq_h * f, 0), Vector3(side + 1.0, 0.7, side + 1.0))
		lm.box("Dark", base + Vector3(0, sq_h * f - 2.3, 0), Vector3(side + 0.2, 3.0, side - 2.0))
		lm.box("Dark", base + Vector3(0, sq_h * f - 2.3, 0), Vector3(side - 2.0, 3.0, side + 0.2))
	var y0 := sq_h + 0.8
	lm.box("Stone", base + Vector3(0, sq_h + 0.4, 0), Vector3(side + 1.6, 0.8, side + 1.6))
	lm.frustum("Stone", base + Vector3(0, y0, 0), oct_r, oct_r * 0.92, oct_h, 8, PI / 8.0)
	lm.frustum("Stone", base + Vector3(0, y0 + oct_h * 0.55, 0), oct_r * 1.5, oct_r * 1.5, 0.5, 8, PI / 8.0)
	lm.frustum("Dark", base + Vector3(0, y0 + oct_h * 0.2, 0), oct_r * 0.97, oct_r * 0.97, oct_h * 0.2, 8,
		PI / 8.0)
	lm.spire("Lead", base + Vector3(0, y0 + oct_h, 0), oct_r * 1.0, spire_h, 0.0, 8)
	LandmarkLpParts.needle(lm, "Gold", base + Vector3(0, y0 + oct_h + spire_h, 0),
		PackedVector2Array([Vector2(0, 0.14), Vector2(0.8, 0.05)]), 6)

# --- Krak des Chevaliers ---

## Concentric Hospitaller castle on its spur (y = 0 is the outer ward; the
## rock under the 10-sided outer curtain goes 20 m below): outer wall of
## round towers with machicolated merlons, the raised inner ward behind its
## sloping glacis with four big round towers (the Grand Master's tower at
## the south-west, 34 m), square towers, the chapel and the Knights' hall.
static func krak(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#C9B78F", 4.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8D7D63", 8.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7F8387", 5.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#1F1A15", 3.0, 0.92))
	var ring := PackedVector2Array([Vector2(-36, -62), Vector2(0, -66), Vector2(34, -56),
		Vector2(42, -20), Vector2(42, 25), Vector2(34, 58), Vector2(-2, 66), Vector2(-34, 56),
		Vector2(-44, 20), Vector2(-44, -24)])
	lm.poly_prism("Rock", ring, -20.0, 0.0)
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		var a := Vector3(p.x, 4.5, p.y)
		var b := Vector3(q.x, 4.5, q.y)
		lm.beam("Wall", a, b, 3.5, 9.0)
		LandmarkLpParts.merlons(lm, "Wall", Vector3(p.x, 9.0, p.y), Vector3(q.x, 9.0, q.y), 1.0, 1.1, 1.0, 2.2)
		_round_tower(lm, Vector3(p.x, 0, p.y), 5.0, 13.0)
		if p.distance_to(q) > 40.0:
			_round_tower(lm, Vector3((p.x + q.x) * 0.5, 0, (p.y + q.y) * 0.5), 4.6, 12.0)
	# Inner ward: platform, sloping glacis, curtain wall.
	var cx := -1.0
	var cz := 3.0
	lm.box("Wall", Vector3(cx, 6.0, cz), Vector3(52, 12.0, 70))
	_glacis(lm, Vector3(cx, 0, cz), Vector2(33.0, 42.0), Vector2(26.0, 35.0), 12.0)
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(cx + s * 25.0, 16.0, cz), Vector3(3.0, 8.0, 70))
		lm.box("Wall", Vector3(cx, 16.0, cz + s * 34.0), Vector3(52, 8.0, 3.0))
		LandmarkLpParts.merlons(lm, "Wall", Vector3(cx + s * 25.0, 20.0, cz - 35.0),
			Vector3(cx + s * 25.0, 20.0, cz + 35.0), 1.0, 1.2, 1.0, 2.2)
		LandmarkLpParts.merlons(lm, "Wall", Vector3(cx - 26.0, 20.0, cz + s * 34.0),
			Vector3(cx + 26.0, 20.0, cz + s * 34.0), 1.0, 1.2, 1.0, 2.2)
	_round_tower(lm, Vector3(-27.0, 0, 38.0), 8.2, 34.0)
	_round_tower(lm, Vector3(-1.0, 0, 41.0), 7.6, 31.0)
	_round_tower(lm, Vector3(25.0, 0, 38.0), 7.2, 29.5)
	_round_tower(lm, Vector3(-27.0, 0, 3.0), 6.6, 27.5)
	for t in [Vector3(-1, 0, -32), Vector3(25, 0, -32), Vector3(25, 0, 6)]:
		lm.box("Wall", (t as Vector3) + Vector3(0, 19.0, 0), Vector3(8.5, 14.0, 8.5))
	# Chapel (north) and Knights' hall (west) in the inner court.
	lm.box("Wall", Vector3(-1, 16.0, -18), Vector3(22, 8.0, 11))
	lm.gable("Roof", Vector3(-1, 20.0, -18), 11.0, 22.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.4, "Wall")
	lm.box("Wall", Vector3(-19, 16.5, 8), Vector3(10, 9.0, 36))
	lm.gable("Roof", Vector3(-19, 21.0, 8), 10.0, 36.0, 3.0, Basis(), 0.4, "Wall")
	lm.commit(model)

## Round tower of radius r rising to `top`: battered base, straight shaft,
## corbelled (machicolated) head with a merlon ring.
static func _round_tower(lm: LandmarkMesh, base: Vector3, r: float, top: float) -> void:
	var prof := PackedVector2Array([Vector2(r * 1.3, -3.0), Vector2(r * 1.3, 0.0),
		Vector2(r * 1.15, top * 0.25), Vector2(r, top * 0.4), Vector2(r, top - 2.4),
		Vector2(r * 1.14, top - 2.0), Vector2(r * 1.14, top)])
	lm.lathe("Wall", base, prof, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.box("Wall", base + Vector3(cos(a) * r * 1.06, top + 0.6, sin(a) * r * 1.06),
			Vector3(1.0, 1.2, 1.2), Basis(Vector3.UP, -a))

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
