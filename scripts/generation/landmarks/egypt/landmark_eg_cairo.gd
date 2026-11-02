class_name LandmarkEgCairo
extends RefCounted

## Two great mosques of Islamic Cairo in true metres, built with the
## courtyard / entrance toward +Z and the qibla wall toward -Z (registry
## yaw_deg 136 turns the qibla onto its real bearing, south-east).

# --- Mosque of Muhammad Ali ---

## The Alabaster Mosque (1830-48, Citadel of Cairo): the 41 m square
## Ottoman prayer hall faced in alabaster, two tiers of arched windows
## on its walls, the central 21 m dome at 52 m on a windowed drum over
## four semidomes, four corner domes and four domed weight turrets, the
## mihrab apse projecting on the qibla side; the two 82 m pencil
## minarets with two balconies each at the courtyard corners; the 54 m
## courtyard (+Z) ringed by arcades of arches under 47 small domes, its
## domed ablution fountain and the iron clock tower given by Louis-
## Philippe over the far wall.
static func muhammad_ali(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#DACDAA", 4.0))
	lm.use("Lead", LandmarkMaterials.paint("#8E949A", 0.5, 0.3))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("limestone", "#C9BD9F", 6.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4650"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Ground", Vector3(0, 0.1, 34.0), Vector3(62.0, 0.2, 104.0), Basis(), 0.0)
	# Prayer hall: body, two tiers of arched windows, cornice.
	lm.box("Wall", Vector3(0, 12.0, 0), Vector3(41.0, 24.0, 41.0))
	LandmarkDetail.cornice(lm, "Wall", Vector3(-21.0, 23.2, 20.5), Vector3(21.0, 23.2, 20.5), Vector3.BACK, 1.0)
	LandmarkDetail.cornice(lm, "Wall", Vector3(21.0, 23.2, -20.5), Vector3(-21.0, 23.2, -20.5), Vector3.FORWARD, 1.0)
	LandmarkDetail.cornice(lm, "Wall", Vector3(20.5, 23.2, 21.0), Vector3(20.5, 23.2, -21.0), Vector3.RIGHT, 1.0)
	LandmarkDetail.cornice(lm, "Wall", Vector3(-20.5, 23.2, -21.0), Vector3(-20.5, 23.2, 21.0), Vector3.LEFT, 1.0)
	for f in 4:
		var n := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(n)
		for k in 5:
			var x := -14.0 + 7.0 * float(k)
			if f == 0 and absf(x) < 4.0:
				continue
			LandmarkDetail.window(lm, "Wall", "Glass", n * 20.5 + rt * x + Vector3(0, 7.0, 0), n, 2.2, 4.4, true, 0.3)
			LandmarkDetail.window(lm, "Wall", "Glass", n * 20.5 + rt * x + Vector3(0, 16.0, 0), n, 1.8, 3.4, true, 0.3)
	# Entrance portal from the courtyard.
	lm.box("Wall", Vector3(0, 7.0, 21.0), Vector3(7.6, 14.0, 1.0))
	lm.box("Dark", Vector3(0, 4.5, 21.55), Vector3(3.2, 7.0, 0.1), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Wall", Vector3(0, 8.0, 21.5), Vector3.BACK, 3.2)
	# Central block, semidomes, corner domes and the weight turrets.
	lm.box("Wall", Vector3(0, 29.4, 0), Vector3(31.0, 10.0, 31.0))
	for f in 4:
		var n := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		_semidome(lm, "Lead", n * 15.5 + Vector3(0, 24.4, 0), n, 9.5, 8.5, 4.6)
		for k in 3:
			var p := n * (15.5 + 4.6 * 0.92) + Vector3.UP.cross(n) * (float(k) - 1.0) * 4.5 + Vector3(0, 25.6, 0)
			lm.box("Dark", p, Vector3(1.0, 1.6, 1.0), Basis.looking_at(n), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkEgParts.dome(lm, "Lead", Vector3(sx * 17.0, 24.8, sz * 17.0), 3.8, 4.0, 16)
			_finial(lm, Vector3(sx * 17.0, 28.8, sz * 17.0), 1.2)
			var t := Vector3(sx * 14.5, 34.4, sz * 14.5)
			lm.frustum("Wall", t, 1.9, 1.8, 4.0, 8)
			LandmarkEgParts.dome(lm, "Lead", t + Vector3(0, 4.0, 0), 2.1, 2.2, 12)
			_finial(lm, t + Vector3(0, 6.2, 0), 1.0)
	LandmarkKits.dome_on_drum(lm, "Wall", "Lead", Vector3(0, 34.4, 0), 10.5, 2.6, 13.0, 2.0, 40)
	for k in 24:
		var a := TAU * (float(k) + 0.5) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Glass", Vector3(0, 35.8, 0) + d * 10.58, Vector3(0.9, 1.6, 0.1), Basis.looking_at(d), 0.0)
	_finial(lm, Vector3(0, 51.8, 0), 2.4)
	# Mihrab apse on the qibla side.
	lm.box("Wall", Vector3(0, 7.0, -22.5), Vector3(10.0, 14.0, 4.0))
	_semidome(lm, "Lead", Vector3(0, 14.0, -22.5), Vector3.FORWARD, 5.0, 4.0, 4.0)
	# Minarets on square bases at the courtyard corners of the hall.
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 23.0, 12.4, 22.5), Vector3(5.4, 24.8, 5.4))
		LandmarkKits.minaret(lm, "Wall", "Lead", Vector3(s * 23.0, 24.8, 22.5), 1.5, 57.2, 2)
	_ali_court(lm)
	lm.commit(model)

## The courtyard: arcades of round arches on marble columns along all
## four sides, each bay under its own small lead dome, the octagonal
## ablution fountain under its wide carved canopy and bulbous dome, and
## the clock tower over the far (north-west) wall.
static func _ali_court(lm: LandmarkMesh) -> void:
	var sides := [[Vector3(-22.5, 0, 24.0), Vector3(-22.5, 0, 71.0), Vector3.RIGHT],
		[Vector3(22.5, 0, 24.0), Vector3(22.5, 0, 71.0), Vector3.LEFT],
		[Vector3(-20.0, 0, 70.0), Vector3(20.0, 0, 70.0), Vector3.FORWARD]]
	for sd in sides:
		var a: Vector3 = sd[0]
		var b: Vector3 = sd[1]
		var face: Vector3 = sd[2]
		var n := 12 if a.x != b.x else 13
		var outv := -face
		for i in n:
			var p := a.lerp(b, float(i) / float(n - 1))
			LandmarkDetail.column(lm, "Wall", p, 0.32, 4.6, "tuscan", 0)
			if i < n - 1:
				var q := a.lerp(b, float(i + 1) / float(n - 1))
				var span := p.distance_to(q) - 0.6
				LandmarkDetail.arch(lm, "Wall", (p + q) * 0.5 + Vector3(0, 4.6, 0) + face * 0.15, face, span, 0.35, 0.4)
				var c := (p + q) * 0.5 + outv * 2.3
				LandmarkEgParts.dome(lm, "Lead", c + Vector3(0, 7.2, 0), 1.9, 1.5, 12)
				_finial(lm, c + Vector3(0, 8.7, 0), 0.5)
		LandmarkEgParts.wall(lm, "Wall", Vector2(a.x, a.z) + Vector2(outv.x, outv.z) * 4.6,
			Vector2(b.x, b.z) + Vector2(outv.x, outv.z) * 4.6, 9.0, 1.4)
		var mid := (a + b) * 0.5 + outv * 2.3
		var ln := a.distance_to(b) + 3.0
		var roof := Vector3(5.6, 1.2, ln) if a.x == b.x else Vector3(ln, 1.2, 5.6)
		lm.box("Wall", mid + Vector3(0, 6.6, 0), roof)
	# Ablution fountain: octagonal basin, eight columns, canopy and dome.
	var fc := Vector3(0, 0, 47.5)
	lm.lathe("Wall", fc, PackedVector2Array([Vector2(4.4, 0), Vector2(4.4, 1.2), Vector2(4.0, 1.4),
		Vector2(4.0, 3.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkDetail.column(lm, "Wall", fc + Vector3(cos(a), 0, sin(a)) * 5.0, 0.2, 4.6, "tuscan", 0)
	lm.lathe("Lead", fc + Vector3(0, 4.6, 0), PackedVector2Array([Vector2(6.4, 0), Vector2(6.0, 0.4),
		Vector2(4.6, 1.2), Vector2(3.6, 1.4)]), 16)
	lm.lathe("Lead", fc + Vector3(0, 5.9, 0), LandmarkKits.onion_profile(3.4, 4.6), 16)
	_finial(lm, fc + Vector3(0, 10.5, 0), 0.9)
	# Clock tower over the far wall.
	var ct := Vector3(0, 0, 74.5)
	lm.box("Wall", ct + Vector3(0, 6.0, 0), Vector3(5.6, 12.0, 5.6))
	lm.box("Dark", ct + Vector3(0, 14.5, 0), Vector3(4.4, 5.0, 4.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Dark", ct + Vector3(sx * 2.2, 12.0, sz * 2.2), 0.25, 0.2, 6.2, 6)
			lm.spire("Dark", ct + Vector3(sx * 2.2, 18.2, sz * 2.2), 0.3, 1.6)
	for k in 4:
		var n := Vector3(sin(PI * 0.5 * k), 0, cos(PI * 0.5 * k))
		lm.disc("Gold", ct + Vector3(0, 15.0, 0) + n * 2.25, n, 1.4, 20)
	lm.spire("Lead", ct + Vector3(0, 17.0, 0), 2.6, 5.0)
	_finial(lm, ct + Vector3(0, 22.0, 0), 0.8)

## Half dome of radius r and height h whose open side faces back along
## -`out` at `c` (the centre of its springing line), `ro` deep along
## `out`: a quarter-ellipsoid shell, smooth-shaded.
static func _semidome(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, r: float, h: float,
		ro: float = -1.0) -> void:
	var depth := r if ro < 0.0 else ro
	var rt := Vector3.UP.cross(out).normalized()
	var rows: Array = []
	for j in 7:
		var phi := PI * 0.5 * float(j) / 6.0
		var ring := PackedVector3Array()
		for i in 13:
			var th := PI * float(i) / 12.0
			var d := rt * cos(th) * r + out * sin(th) * depth
			ring.append(c + d * cos(phi) + Vector3(0, h * sin(phi), 0))
		rows.append(ring)
	lm.grid(key, rows, c, true)

## Brass crescent finial `h` tall: a stack of beads and the crescent.
static func _finial(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.frustum("Gold", base, h * 0.06, h * 0.04, h * 0.6, 6)
	for k in 2:
		lm.lathe("Gold", base + Vector3(0, h * (0.2 + 0.2 * float(k)), 0),
			LandmarkKits._dome_profile(h * 0.1, h * 0.1, 3), 8)
	var c := base + Vector3(0, h * 0.82, 0)
	var prev := c + Vector3(h * 0.18 * cos(-0.6), h * 0.18 * sin(-0.6), 0)
	for k in 6:
		var a := -0.6 - (TAU - 1.2) * float(k + 1) / 6.0
		var p := c + Vector3(h * 0.18 * cos(a), h * 0.18 * sin(a), 0)
		lm.beam("Gold", prev, p, h * 0.05, h * 0.03)
		prev = p

# --- Mosque-Madrasa of Sultan Hassan ---

## The Mamluk mosque and four-school madrasa (1356-63): a 150 x 68 m
## ashlar block, its long side facades divided into tall recessed panels
## each holding eight windows over four storeys of student cells, under a
## stalactite (muqarnas) cornice projecting 1.5 m and a cresting of
## fleurons; the 38 m entrance portal with its muqarnas hood set at an
## angle at the north corner; the open court between four vaulted iwans
## with the domed ablution fountain; behind the qibla iwan the square
## mausoleum with its windows, its stepped muqarnas transition and the
## bulbous dome; the two octagonal Mamluk minarets at the mausoleum's
## corners, the southern one 81 m (the tallest in Cairo), the northern
## one rebuilt smaller in 1672.
static func sultan_hassan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#C2AB84", 3.4))
	lm.use("Lead", LandmarkMaterials.paint("#8E949A", 0.5, 0.3))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("limestone", "#C9BD9F", 6.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Ground", Vector3(0, 0.1, 0), Vector3(84.0, 0.2, 164.0), Basis(), 0.0)
	# Massing round the court: the front range, the side ranges, the
	# qibla iwan block and the mausoleum.
	lm.box("Wall", Vector3(0, 18.0, 61.0), Vector3(68.0, 36.0, 28.0))
	lm.box("Wall", Vector3(0, 18.0, -31.0), Vector3(32.0, 36.0, 32.0))
	lm.box("Wall", Vector3(0, 15.0, -61.0), Vector3(28.0, 30.0, 28.0))
	for s in [-1.0, 1.0]:
		# Side ranges, opened where the side iwans cut into them, and the
		# madrasa blocks filling the court's corners.
		lm.box("Wall", Vector3(s * 30.5, 17.0, 0), Vector3(7.0, 34.0, 94.0))
		lm.box("Wall", Vector3(s * 21.5, 17.0, -19.75), Vector3(11.0, 34.0, 54.5))
		lm.box("Wall", Vector3(s * 21.5, 17.0, 35.75), Vector3(11.0, 34.0, 22.5))
		lm.box("Wall", Vector3(s * 12.25, 17.0, 39.5), Vector3(7.5, 34.0, 15.0))
		lm.box("Wall", Vector3(s * 14.5, 17.0, -7.5), Vector3(3.0, 34.0, 15.0))
		# Long facades: a pierced skin with the eight-window panels.
		var x: float = s * 34.0
		var o := Vector3(x, 0, -47.0 if s > 0.0 else 75.0)
		LandmarkDetail.pierced_face(lm, "Wall", "Dark", o, Vector3(0, 0, 1.0 if s > 0.0 else -1.0),
			Vector3(s, 0, 0), 122.0, 34.0, 12, 8, Vector2(1.3, 2.2), 4.0, 3.6, 0.6)
		for k in 13:
			lm.box("Wall", Vector3(x + s * 0.9, 16.0, -47.0 + 122.0 * float(k) / 12.0), Vector3(0.6, 32.0, 2.6))
		_muqarnas(lm, Vector3(x, 34.0, -47.0), Vector3(x, 34.0, 75.0), Vector3(s, 0, 0))
	_muqarnas(lm, Vector3(-34.0, 36.0, 75.0), Vector3(34.0, 36.0, 75.0), Vector3.BACK)
	for k in 6:
		LandmarkDetail.window(lm, "Wall", "Dark", Vector3(-25.0 + 10.0 * float(k), 24.0, 75.0), Vector3.BACK,
			1.4, 2.8, true, 0.3)
	_court(lm)
	_portal(lm, Vector3(-34.0, 0, 58.0))
	_mausoleum(lm)
	_mamluk_minaret(lm, Vector3(16.5, 0, -48.5), 81.0, 3.4)
	_mamluk_minaret(lm, Vector3(-16.5, 0, -48.5), 66.0, 3.0)
	lm.commit(model)

## Stalactite cornice along a-b on a wall facing `out`: three tiers of
## corbelled cells stepping outward 1.5 m, and the fleuron cresting.
static func _muqarnas(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3) -> void:
	var dir := (b - a).normalized()
	var ln := a.distance_to(b)
	var basis := Basis(dir, Vector3.UP, out)
	var n := int(ln / 1.4)
	for t in 3:
		var y := -2.4 + 0.8 * float(t)
		var o := 0.5 * float(t + 1)
		lm.box("Wall", (a + b) * 0.5 + out * (o - 0.25) + Vector3(0, y + 0.7, 0), Vector3(ln, 0.2, 0.5), basis, 0.0)
		for i in n:
			var p := a + dir * (ln * (float(i) + 0.5 * float(t % 2) + 0.25) / float(n)) + out * (o - 0.25)
			lm.box("Wall", p + Vector3(0, y + 0.3, 0), Vector3(0.7, 0.6, 0.5), basis, 0.0)
	lm.box("Wall", (a + b) * 0.5 + out * 0.75 + Vector3(0, 0.2, 0), Vector3(ln, 0.4, 1.6), basis, 0.0)
	var m := int(ln / 1.6)
	for i in m:
		var p := a + dir * (ln * (float(i) + 0.5) / float(m)) + out * 1.2 + Vector3(0, 0.4, 0)
		lm.box("Wall", p + Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.3), basis, 0.0)
		lm.lathe("Wall", p + Vector3(0, 0.9, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.38, 0.2),
			Vector2(0.0, 0.6)]), 4, 1.0, 0.5, PI * 0.25, false)

## The open court (34 x 32 m) between the four iwans: each a tall
## pointed-vault hall open to the court, the qibla iwan (-Z) the largest,
## and the octagonal ablution fountain under its bulbous wooden dome.
static func _court(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, 16.0)
	var iwans := [[Vector3.FORWARD, 26.0, 28.0, 14.0], [Vector3.BACK, 17.0, 22.0, 15.0],
		[Vector3.LEFT, 17.0, 20.0, 9.0], [Vector3.RIGHT, 17.0, 20.0, 9.0]]
	for iw in iwans:
		var d: Vector3 = iw[0]
		var span: float = iw[1]
		var h: float = iw[2]
		var deep: float = iw[3]
		var half_court := 16.0 if absf(d.z) > 0.5 else 17.0
		var mouth := c + d * half_court
		var rt := Vector3.UP.cross(d)
		# Pointed vault: two arcs of radius 0.6 span meeting at the crown,
		# run back `deep` m, with a moulded archivolt round the mouth.
		var rad := span * 0.6
		var tmax := acos(1.0 - span / (2.0 * rad))
		var ys := h - rad * sin(tmax)
		var arc := PackedVector3Array()
		for k in 11:
			var side := -1.0 if k <= 5 else 1.0
			var th := tmax * (float(k) / 5.0 if k <= 5 else float(10 - k) / 5.0)
			arc.append(mouth + rt * side * (span * 0.5 - rad + rad * cos(th)) + Vector3(0, ys + rad * sin(th), 0))
		# Rows run right to left so the soffit faces down into the iwan.
		var rows: Array = []
		for k in arc.size():
			var p := arc[arc.size() - 1 - k]
			rows.append(PackedVector3Array([p, p + d * deep]))
		lm.grid("Wall", rows)
		var top := 34.0 if absf(d.x) > 0.5 else 36.0
		lm.box("Wall", mouth + d * deep * 0.5 + Vector3(0, (h + top) * 0.5, 0),
			(rt.abs() * (span + 2.0) + d.abs() * deep) + Vector3(0, top - h, 0))
		for sd in [-1.0, 1.0]:
			lm.box("Wall", mouth + d * deep * 0.5 + rt * sd * (span * 0.5 + 0.5) + Vector3(0, h * 0.5, 0),
				rt.abs() * 1.0 + d.abs() * deep + Vector3(0, h, 0))
		for k in 10:
			LandmarkEgParts.rod(lm, "Wall", arc[k] - d * 0.3, arc[k + 1] - d * 0.3, 0.45, 6)
		for sd in [-1.0, 1.0]:
			LandmarkEgParts.rod(lm, "Wall", mouth + rt * sd * span * 0.5 - d * 0.3 + Vector3(0, 0.2, 0),
				mouth + rt * sd * span * 0.5 - d * 0.3 + Vector3(0, ys, 0), 0.45, 6)
		lm.quad("Dark", mouth + d * deep + rt * span * 0.5 + Vector3(0, 0.2, 0), mouth + d * deep - rt * span * 0.5 +
			Vector3(0, 0.2, 0), mouth + d * deep - rt * span * 0.5 + Vector3(0, h * 0.7, 0),
			mouth + d * deep + rt * span * 0.5 + Vector3(0, h * 0.7, 0), -d)
	var fc := c
	lm.lathe("Wall", fc, PackedVector2Array([Vector2(4.4, 0), Vector2(4.4, 1.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		lm.frustum("Wall", fc + Vector3(cos(a), 0, sin(a)) * 4.0, 0.25, 0.22, 5.0, 8)
	lm.lathe("Wall", fc + Vector3(0, 5.0, 0), PackedVector2Array([Vector2(4.6, 0), Vector2(4.6, 1.2),
		Vector2(4.2, 1.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Lead", fc + Vector3(0, 6.6, 0), LandmarkKits.onion_profile(4.0, 6.0), 16)
	_finial(lm, fc + Vector3(0, 12.6, 0), 1.2)

## The 38 m entrance portal on the long facade near the north corner,
## turned out 17 degrees from the wall: a tall recess under a semidome of
## stepped stalactite tiers, the bronze-clad door, flanking benches and
## the cornice and cresting carried round its frame.
static func _portal(lm: LandmarkMesh, c: Vector3) -> void:
	var basis := Basis(Vector3.UP, -PI * 0.5 + deg_to_rad(17.0))
	var P := func(v: Vector3) -> Vector3:
		return c + basis * v
	var out: Vector3 = basis * Vector3(0, 0, 1)
	var rt: Vector3 = basis * Vector3(1, 0, 0)
	lm.box("Wall", P.call(Vector3(-5.5, 19.0, 0)), Vector3(3.0, 38.0, 6.0), basis)
	lm.box("Wall", P.call(Vector3(5.5, 19.0, 0)), Vector3(3.0, 38.0, 6.0), basis)
	lm.box("Wall", P.call(Vector3(0, 19.0, -2.6)), Vector3(8.0, 38.0, 0.8), basis)
	lm.box("Wall", P.call(Vector3(0, 37.0, 0)), Vector3(14.0, 2.0, 6.4), basis)
	lm.box("Dark", P.call(Vector3(0, 4.5, -2.15)), Vector3(3.2, 9.0, 0.1), basis, 0.0)
	lm.box("Gold", P.call(Vector3(0, 4.5, -2.1)), Vector3(2.8, 8.6, 0.06), basis, 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Wall", P.call(Vector3(s * 3.0, 0.6, -0.8)), Vector3(1.6, 1.2, 3.0), basis)
		LandmarkEgParts.rod(lm, "Wall", P.call(Vector3(s * 4.0, 0.2, 3.0)), P.call(Vector3(s * 4.0, 34.0, 3.0)), 0.3, 8)
	# Muqarnas hood: rings of cells stepping out of the recess, crowned by
	# a fluted half dome.
	var hc: Vector3 = P.call(Vector3(0, 24.0, -2.2))
	for t in 6:
		var y := 14.0 + 1.6 * float(t)
		var r := 1.4 + 0.45 * float(t)
		var cells := 5 + t
		for i in cells:
			var a := PI * (float(i) + 0.5) / float(cells)
			var d: Vector3 = rt * cos(a) + out * sin(a)
			lm.box("Wall", P.call(Vector3(0, y, -2.2)) + d * r, Vector3(0.9, 1.4, 0.5), Basis.looking_at(d), 0.0)
	_semidome(lm, "Wall", hc, out, 4.0, 6.0)
	for s in [-1.0, 1.0]:
		lm.box("Wall", P.call(Vector3(s * 3.8, 14.0, -0.8)), Vector3(0.4, 28.0, 3.0), basis)
	LandmarkDetail.arch(lm, "Wall", P.call(Vector3(0, 27.0, 2.6)), out, 8.0, 0.8, 0.6)

## The mausoleum behind the qibla iwan: the 28 m square chamber with two
## tiers of grilled windows, the stepped muqarnas zone turning square to
## octagon, the drum and the tall bulbous dome with its crescent.
static func _mausoleum(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, -61.0)
	for f in 3:
		var n: Vector3 = [Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT][f]
		var rt := Vector3.UP.cross(n)
		for k in 3:
			var p: Vector3 = c + n * 14.0 + rt * (-7.0 + 7.0 * float(k))
			LandmarkDetail.window(lm, "Wall", "Dark", p + Vector3(0, 8.0, 0), n, 2.2, 4.6, false, 0.35)
			LandmarkDetail.window(lm, "Wall", "Dark", p + Vector3(0, 19.0, 0), n, 1.6, 3.4, true, 0.35)
		_muqarnas(lm, c + n * 14.0 + Vector3(0, 30.0, 0) - rt * 14.0, c + n * 14.0 + Vector3(0, 30.0, 0) + rt * 14.0, n)
	# Transition: chamfered corners stepping up to the octagonal drum.
	lm.lathe("Wall", c + Vector3(0, 30.0, 0), PackedVector2Array([Vector2(16.5, 0), Vector2(15.0, 1.4),
		Vector2(13.8, 1.6), Vector2(12.6, 3.0), Vector2(11.4, 3.2), Vector2(10.6, 4.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Wall", c + Vector3(0, 34.6, 0), PackedVector2Array([Vector2(10.4, 0), Vector2(10.4, 4.0),
		Vector2(10.9, 4.4), Vector2(10.9, 4.8)]), 16)
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Dark", c + Vector3(0, 36.6, 0) + d * 10.45, Vector3(0.8, 2.0, 0.1), Basis.looking_at(d), 0.0)
	var prof := PackedVector2Array([Vector2(10.4, 0), Vector2(10.9, 2.5), Vector2(10.8, 5.5),
		Vector2(9.8, 8.5), Vector2(8.0, 11.2), Vector2(5.6, 13.4), Vector2(3.0, 15.0), Vector2(1.0, 16.2),
		Vector2(0.0, 16.6)])
	lm.lathe("Lead", c + Vector3(0, 39.4, 0), prof, 32)
	_finial(lm, c + Vector3(0, 55.8, 0), 2.0)

## Octagonal Mamluk minaret `h` tall standing on `base`: a square shaft
## to above the roof, then octagonal and round storeys separated by
## balconies on stalactite corbels with their balustrades, and the
## eight-columned top pavilion under a bulb and crescent.
static func _mamluk_minaret(lm: LandmarkMesh, base: Vector3, h: float, r: float) -> void:
	var sq := 40.0
	lm.box("Wall", base + Vector3(0, sq * 0.5, 0), Vector3(r * 2.4, sq, r * 2.4))
	for k in 3:
		lm.box("Dark", base + Vector3(0, 18.0 + 7.0 * float(k), r * 1.21), Vector3(0.7, 1.8, 0.1), Basis(), 0.0)
	var y := sq
	var stages := [[r * 1.05, (h - sq) * 0.34, 8], [r * 0.9, (h - sq) * 0.26, 8], [r * 0.7, (h - sq) * 0.12, 16]]
	for st in stages:
		var rr: float = st[0]
		var sh: float = st[1]
		var sides: int = st[2]
		# Balcony on stepped corbels, parapet, then the storey.
		lm.lathe("Wall", base + Vector3(0, y - 1.6, 0), PackedVector2Array([Vector2(rr, 0), Vector2(rr * 1.15, 0.5),
			Vector2(rr * 1.2, 0.8), Vector2(rr * 1.35, 1.3), Vector2(rr * 1.45, 1.6)]), sides, 1.0, 1.0, PI / float(sides),
			false)
		lm.lathe("Wall", base + Vector3(0, y, 0), PackedVector2Array([Vector2(rr * 1.45, 0), Vector2(rr * 1.45, 0.3)]),
			sides, 1.0, 1.0, PI / float(sides), false)
		for k in sides * 2:
			var a := TAU * float(k) / float(sides * 2)
			lm.box("Wall", base + Vector3(cos(a) * rr * 1.38, y + 0.85, sin(a) * rr * 1.38), Vector3(0.18, 1.1, 0.18),
				Basis(), 0.0)
		lm.lathe("Wall", base + Vector3(0, y + 1.4, 0), PackedVector2Array([Vector2(rr * 1.42, 0), Vector2(rr * 1.42, 0.15)]),
			sides, 1.0, 1.0, PI / float(sides), false, false)
		lm.lathe("Wall", base + Vector3(0, y, 0), PackedVector2Array([Vector2(rr, 0), Vector2(rr * 0.97, sh)]), sides,
			1.0, 1.0, PI / float(sides), sides > 8)
		for k in sides:
			var a := TAU * (float(k) + 0.5) / float(sides)
			var d := Vector3(cos(a), 0, sin(a))
			if k % 2 == 0:
				lm.box("Dark", base + Vector3(0, y + sh * 0.5, 0) + d * rr * 0.93, Vector3(0.5, 1.6, 0.1),
					Basis.looking_at(d), 0.0)
		y += sh
	# Top pavilion: eight colonnettes, a cornice ring, the bulb and crescent.
	var pr := r * 0.55
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Wall", base + Vector3(cos(a) * pr, y, sin(a) * pr), 0.16, 0.14, 2.6, 6)
	lm.frustum("Wall", base + Vector3(0, y, 0), pr * 0.5, pr * 0.5, 2.6, 8)
	lm.frustum("Wall", base + Vector3(0, y + 2.6, 0), pr * 1.15, pr * 1.1, 0.5, 12)
	var top := h - (y + 3.1) - 2.0
	lm.lathe("Wall", base + Vector3(0, y + 3.1, 0), LandmarkKits.onion_profile(pr * 0.95, top), 16)
	_finial(lm, base + Vector3(0, h - 2.2, 0), 2.2)
