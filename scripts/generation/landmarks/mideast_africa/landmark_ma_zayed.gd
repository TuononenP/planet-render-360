class_name LandmarkMaZayed
extends RefCounted

## The Sheikh Zayed Grand Mosque, Abu Dhabi (2007), in true metres. Built
## with the qibla (the prayer hall) toward +Z; the registry yaw turns the
## main axis to its real bearing, about 12 degrees south of west.

## Platform top: every part stands on the raised marble podium.
const G := 1.2
const ARCADE_H := 13.0
const BAY := 7.0

## White Sivec-marble complex on its podium: the prayer hall (z 60..140)
## under the 32.2 m main dome (85 m to the finial), two flanking domes and
## a field of smaller ones; the 17,000 m2 courtyard ringed on three sides
## by domed double arcades on gold-capped columns, a domed east gate, the
## four 107 m minarets at the courtyard corners, and the reflecting pools
## and outer colonnades along the north and south flanks (82 domes in
## all).
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F1EEE6", 6.0))
	lm.use("Floor", LandmarkMaterials.pbr("pavement", "#E4DCCB", 5.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#2A3A3C"))
	lm.use("Pool", LandmarkMaterials.glass("#2C6478"))
	lm.box("Floor", Vector3(0, G * 0.5, 25), Vector3(236, G, 270))
	# Courtyard paving, a step proud of the podium.
	lm.box("Floor", Vector3(0, G + 0.1, -9), Vector3(138, 0.2, 120))
	_prayer_hall(lm)
	# Courtyard arcades: north (+X) and south (-X) flanks, the east side.
	_arcade(lm, Vector3(75, G, -80), Vector3(0, 0, 1), 133.0, Vector3(-1, 0, 0))
	_arcade(lm, Vector3(-75, G, 53), Vector3(0, 0, -1), 133.0, Vector3(1, 0, 0))
	_arcade(lm, Vector3(-70, G, -75), Vector3(1, 0, 0), 140.0, Vector3(0, 0, 1))
	_east_gate(lm, Vector3(0, G, -75))
	# Reflecting pools and the outer colonnades beyond them.
	for s in [-1.0, 1.0]:
		lm.box("Pool", Vector3(s * 89.0, G + 0.05, 25), Vector3(14, 0.3, 214))
		lm.box("Marble", Vector3(s * 96.6, G + 0.35, 25), Vector3(1.2, 0.7, 214))
		lm.box("Marble", Vector3(s * 81.4, G + 0.35, 25), Vector3(1.2, 0.7, 214))
		_outer_colonnade(lm, s)
	for sx in [-1.0, 1.0]:
		for z in [56.0, -78.0]:
			_minaret(lm, Vector3(sx * 76.0, G, z))
	lm.commit(model)

# --- Prayer hall ---

## Hall block (140 x 80 m, 24 m walls) with blind arcading round its
## outer walls, the seven-bay domed portico onto the courtyard, the main
## dome on its raised square base and drum, two flanking domes over the
## side halls and smaller domes over the corners.
static func _prayer_hall(lm: LandmarkMesh) -> void:
	var y0 := G
	var wh := 24.0
	lm.box("Marble", Vector3(0, y0 + wh * 0.5, 100), Vector3(140, wh, 80))
	# Blind pointed arcading with glazed windows on the three outer walls.
	LandmarkMaParts.arched_bays(lm, "Marble", "Glass", Vector3(-70, y0, 140.0), Vector3.RIGHT,
		Vector3.BACK, 140.0, wh - 2.0, 14, 5.6, 12.0, 4.6, 0.7, "Marble")
	for s in [-1.0, 1.0]:
		LandmarkMaParts.arched_bays(lm, "Marble", "Glass", Vector3(s * 70.0, y0, 60.0 if s > 0.0 else 140.0),
			Vector3(0, 0, s), Vector3(s, 0, 0), 80.0, wh - 2.0, 8, 5.6, 12.0, 4.6, 0.7, "Marble")
	# Crowning cornice and a low parapet round the roof.
	var top := y0 + wh
	for e in [[Vector3(-70.8, top, 140.8), Vector3(70.8, top, 140.8), Vector3.BACK],
			[Vector3(70.8, top, 59.2), Vector3(70.8, top, 140.8), Vector3.RIGHT],
			[Vector3(-70.8, top, 59.2), Vector3(-70.8, top, 140.8), Vector3.LEFT]]:
		LandmarkDetail.cornice(lm, "Marble", e[0] - Vector3(0, 1.2, 0), e[1] - Vector3(0, 1.2, 0), e[2], 1.2, false)
	lm.box("Marble", Vector3(0, top + 0.6, 140.6), Vector3(142, 1.2, 0.6))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 70.6, top + 0.6, 100), Vector3(0.6, 1.2, 81))
	# Portico onto the courtyard: an open arcade, its domes, gold columns.
	_portico(lm, Vector3(-70, y0, 52), 140.0)
	# Main dome: raised square base, octagonal shoulder, windowed drum.
	var mz := 100.0
	var mb := Vector3(0, top, mz)
	lm.box("Marble", mb + Vector3(0, 5, 0), Vector3(44, 10, 44))
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var r: Vector3 = Vector3.UP.cross(d)
		LandmarkMaParts.arched_bays(lm, "Marble", "Glass", mb + d * 22.0 - r * 22.0, r, d, 44.0, 10.0, 5,
			4.4, 4.5, 3.4, 0.5)
	lm.frustum("Marble", mb + Vector3(0, 10, 0), 23.0, 19.0, 4.0, 8, PI / 8.0)
	var drum := mb + Vector3(0, 14, 0)
	lm.frustum("Marble", drum, 16.1, 16.1, 9.0, 16, PI / 16.0)
	LandmarkMaParts.arched_ring(lm, "Marble", "Glass", drum, 16.6, 16, 9.0, 2.6, 4.5, 2.4, 0.45, PI / 16.0)
	lm.frustum("Marble", drum + Vector3(0, 9, 0), 17.4, 17.6, 1.0, 32)
	_dome(lm, drum + Vector3(0, 10, 0), 16.9, 30.0, 32, 6.6)
	# Flanking domes over the two side halls.
	for s in [-1.0, 1.0]:
		var fb := Vector3(s * 42.0, top, mz)
		lm.box("Marble", fb + Vector3(0, 3, 0), Vector3(22, 6, 22))
		lm.frustum("Marble", fb + Vector3(0, 6, 0), 8.6, 8.6, 4.5, 16, PI / 16.0)
		LandmarkMaParts.arched_ring(lm, "Marble", "Glass", fb + Vector3(0, 6, 0), 8.9, 12, 4.5, 1.6, 2.2, 1.4,
			0.3, PI / 12.0)
		_dome(lm, fb + Vector3(0, 10.5, 0), 9.2, 15.5, 24, 3.6)
	# Smaller domes over the hall's corners and back bays.
	for p in [Vector2(-60, 70), Vector2(60, 70), Vector2(-60, 130), Vector2(60, 130), Vector2(-60, 100),
			Vector2(60, 100), Vector2(-30, 130), Vector2(30, 130), Vector2(-30, 70), Vector2(30, 70),
			Vector2(0, 132)]:
		var b := Vector3(p.x, top, p.y)
		lm.frustum("Marble", b, 4.6, 4.6, 2.2, 16)
		_dome(lm, b + Vector3(0, 2.2, 0), 4.8, 7.0, 16, 2.0)

## Seven-bay hall portico, 8 m deep: an arcade on paired columns, its
## roof slab and a dome over each bay.
static func _portico(lm: LandmarkMesh, origin: Vector3, w: float) -> void:
	var bays := 14
	var pitch := w / float(bays)
	var h := 17.0
	LandmarkMaParts.arched_bays(lm, "Marble", "", origin, Vector3.RIGHT, Vector3.FORWARD, w, h, bays,
		pitch - 1.8, 9.0, 5.0, 0.9, "Gold")
	lm.box("Marble", origin + Vector3(w * 0.5, h + 0.6, 4.0), Vector3(w + 1.0, 1.2, 9.0))
	for i in bays + 1:
		var x := origin.x + pitch * float(i)
		_column(lm, Vector3(x, origin.y, origin.z - 1.3), 9.0)
	for i in bays:
		if i % 2 == 0:
			continue
		var c := origin + Vector3(pitch * (float(i) + 0.5), h + 1.2, 4.0)
		lm.frustum("Marble", c, 3.4, 3.4, 1.4, 16)
		_dome(lm, c + Vector3(0, 1.4, 0), 3.6, 5.2, 16, 1.6)

# --- Courtyard arcades ---

## Double arcade `length` m long from `start` along `along`: a pointed
## arcade on gold-capped columns facing the courtyard (`inward`), a
## second facing out over the pool, the roof slab and a dome per bay.
static func _arcade(lm: LandmarkMesh, start: Vector3, along: Vector3, length: float,
		inward: Vector3) -> void:
	var bays := int(length / BAY)
	var pitch := length / float(bays)
	var depth := 9.0
	var h := ARCADE_H
	var front := start + inward * 0.0
	LandmarkMaParts.arched_bays(lm, "Marble", "", front, along, inward, length, h, bays, pitch - 1.6,
		6.5, 4.0, 0.8, "Gold", 5)
	var back := start - inward * depth + along * length
	LandmarkMaParts.arched_bays(lm, "Marble", "", back, -along, -inward, length, h, bays, pitch - 1.6,
		6.5, 4.0, 0.8, "", 5)
	var mid := start + along * length * 0.5 - inward * depth * 0.5
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	lm.box("Marble", mid + Vector3(0, h + 0.6, 0), Vector3(length + 1.0, 1.2, depth + 2.0), basis)
	lm.box("Marble", mid + Vector3(0, 0.15, 0), Vector3(length, 0.3, depth), basis)
	for i in bays + 1:
		var p := start + along * pitch * float(i)
		_column(lm, p + inward * 1.2, 6.5)
		_column(lm, p - inward * (depth + 1.2), 6.5)
	for i in bays:
		var c := start + along * pitch * (float(i) + 0.5) - inward * depth * 0.5 + Vector3(0, h + 1.2, 0)
		lm.frustum("Marble", c, 3.0, 3.0, 1.2, 12)
		_dome(lm, c + Vector3(0, 1.2, 0), 3.2, 4.4, 12, 1.4)

## The main east gate: a tall block with a pointed iwan arch each way
## and a dome on a drum.
static func _east_gate(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Marble", c + Vector3(0, 11, -4.5), Vector3(22, 22, 13))
	for d in [-1.0, 1.0]:
		var face := c + Vector3(-11, 0, -4.5 + d * 6.5)
		var r := Vector3(d, 0, 0)
		var o := face if d > 0.0 else face + Vector3(22, 0, 0)
		LandmarkMaParts.arched_bays(lm, "Marble", "Glass", o, r, Vector3(0, 0, d), 22.0, 20.0, 1, 10.0,
			9.0, 7.0, 1.2, "Gold")
	var top := c + Vector3(0, 22, -4.5)
	lm.frustum("Marble", top, 6.0, 6.0, 3.0, 16)
	_dome(lm, top + Vector3(0, 3, 0), 6.3, 9.0, 24, 2.6)

## Outer colonnade beyond the pool on side `s`: columns along both
## edges, a flat roof and a small dome every other bay.
static func _outer_colonnade(lm: LandmarkMesh, s: float) -> void:
	var x := s * 102.0
	var n := 20
	var z0 := -80.0
	var pitch := 214.0 / float(n)
	for i in n + 1:
		var z := z0 + pitch * float(i)
		for dx in [-3.0, 3.0]:
			_column(lm, Vector3(x + dx, G, z), 7.0)
	lm.box("Marble", Vector3(x, G + 7.9, z0 + 107.0), Vector3(8.6, 1.8, 216))
	for i in n:
		var z := z0 + pitch * (float(i) + 0.5)
		lm.beam("Marble", Vector3(x - 3.0, G + 7.0, z), Vector3(x + 3.0, G + 7.0, z), 0.5, 0.8)
		if i % 2 == 0:
			var c := Vector3(x, G + 8.8, z)
			_dome(lm, c, 2.6, 3.8, 12, 1.2)

# --- Parts ---

## Marble column with a gold palm capital, `h` to the capital top.
static func _column(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.box("Marble", base + Vector3(0, 0.25, 0), Vector3(1.3, 0.5, 1.3), Basis(), 0.0)
	lm.lathe("Marble", base + Vector3(0, 0.5, 0), PackedVector2Array([Vector2(0.52, 0),
		Vector2(0.46, 0.4), Vector2(0.42, h - 1.9)]), 10, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Gold", base + Vector3(0, h - 1.4, 0), PackedVector2Array([Vector2(0.42, 0),
		Vector2(0.5, 0.3), Vector2(0.78, 0.9), Vector2(0.86, 1.2)]), 8, 1.0, 1.0, 0.0, true, false)
	lm.box("Gold", base + Vector3(0, h - 0.1, 0), Vector3(1.6, 0.2, 1.6), Basis(), 0.0)

## White onion-shouldered dome (radius r at the springing, h tall) with
## its gilded finial `fin` m tall: a ring, three gold balls and the
## crescent.
static func _dome(lm: LandmarkMesh, base: Vector3, r: float, h: float, seg: int, fin: float) -> void:
	var p := PackedVector2Array()
	for q in [[1.0, 0.0], [1.05, 0.1], [1.07, 0.22], [1.03, 0.36], [0.93, 0.5], [0.77, 0.64],
			[0.56, 0.77], [0.34, 0.88], [0.15, 0.96], [0.04, 1.0]]:
		p.append(Vector2(r * float(q[0]), h * float(q[1])))
	lm.lathe("Marble", base, p, seg)
	var t := base + Vector3(0, h, 0)
	if fin < 2.0:
		# Small domes: a gilt ball and spike.
		LandmarkMaParts.sphere(lm, "Gold", t + Vector3(0, fin * 0.25, 0), fin * 0.16, 8, 4)
		lm.frustum("Gold", t + Vector3(0, fin * 0.35, 0), fin * 0.06, 0.0, fin * 0.65, 6)
		return
	lm.frustum("Gold", t - Vector3(0, fin * 0.05, 0), fin * 0.12, fin * 0.09, fin * 0.14, 10)
	var y := fin * 0.09
	for k in 3:
		var br := fin * (0.11 - 0.025 * float(k))
		LandmarkMaParts.sphere(lm, "Gold", t + Vector3(0, y + br, 0), br, 10, 6)
		y += br * 2.0 + fin * 0.04
	lm.frustum("Gold", t + Vector3(0, y, 0), fin * 0.025, fin * 0.02, fin * 0.6 - y + fin * 0.25, 6)
	LandmarkMaParts.crescent(lm, "Gold", t + Vector3(0, fin * 0.85, 0), fin * 0.13, fin * 0.03)

# --- Minarets ---

## 107 m minaret in four stages (the Mamluk-style square, octagon and
## cylinder of the real towers): a square base with tall blind arches,
## corbelled galleries between the stages, a columned lantern and the
## gold onion cap with its crescent.
static func _minaret(lm: LandmarkMesh, base: Vector3) -> void:
	var sq := 11.0
	lm.box("Marble", base + Vector3(0, 15, 0), Vector3(sq, 30, sq))
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var r: Vector3 = Vector3.UP.cross(d)
		var o: Vector3 = base + d * sq * 0.5 - r * sq * 0.5
		LandmarkMaParts.arched_bays(lm, "Marble", "Marble", o, r, d, sq, 14.0, 1, 5.0, 9.0, 3.5, 0.4)
		LandmarkMaParts.arched_bays(lm, "Marble", "Glass", o + Vector3(0, 15, 0), r, d, sq, 14.0, 2, 2.2,
			8.0, 2.2, 0.4)
	_gallery(lm, base + Vector3(0, 30, 0), 6.0, 8)
	var oct := base + Vector3(0, 30.0, 0)
	lm.frustum("Marble", oct, 4.9, 4.9, 34.0, 8, PI / 8.0)
	LandmarkMaParts.arched_ring(lm, "Marble", "Glass", oct + Vector3(0, 2, 0), 4.9, 8, 30.0, 1.4, 22.0,
		1.4, 0.3, PI / 8.0)
	_gallery(lm, base + Vector3(0, 64, 0), 5.3, 8)
	var cyl := base + Vector3(0, 64.0, 0)
	lm.frustum("Marble", cyl, 3.6, 3.4, 22.0, 16)
	for y in [5.0, 11.0, 17.0]:
		lm.frustum("Marble", cyl + Vector3(0, y, 0), 3.75, 3.75, 0.5, 16)
	_gallery(lm, base + Vector3(0, 86, 0), 4.6, 16)
	var lan := base + Vector3(0, 86.6, 0)
	lm.frustum("Glass", lan, 2.4, 2.4, 7.0, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.frustum("Marble", lan + Vector3(cos(a), 0, sin(a)) * 3.0, 0.32, 0.28, 7.0, 8)
	lm.frustum("Marble", lan + Vector3(0, 7.0, 0), 3.6, 3.7, 0.9, 16)
	var cap := lan + Vector3(0, 7.9, 0)
	lm.lathe("Gold", cap, LandmarkKits.onion_profile(3.0, 8.4), 20)
	lm.frustum("Gold", cap + Vector3(0, 8.2, 0), 0.12, 0.08, 3.2, 6)
	for k in 2:
		LandmarkMaParts.sphere(lm, "Gold", cap + Vector3(0, 8.9 + 0.9 * float(k), 0), 0.38 - 0.08 * float(k), 8, 4)
	LandmarkMaParts.crescent(lm, "Gold", cap + Vector3(0, 11.2, 0), 0.65, 0.16)

## Corbelled balcony at `b` of radius r: muqarnas-like corbel tiers, the
## floor and a pierced parapet of posts and rail.
static func _gallery(lm: LandmarkMesh, b: Vector3, r: float, sides: int) -> void:
	var rot := PI / float(sides)
	lm.lathe("Marble", b - Vector3(0, 2.4, 0), PackedVector2Array([Vector2(r * 0.78, 0),
		Vector2(r * 0.84, 0.6), Vector2(r * 0.9, 1.2), Vector2(r * 0.96, 1.8), Vector2(r, 2.4)]),
		sides, 1.0, 1.0, rot, sides > 8)
	lm.frustum("Marble", b, r, r, 0.4, sides, rot)
	var posts := sides * 3
	for i in posts:
		var a := TAU * float(i) / float(posts)
		lm.box("Marble", b + Vector3(cos(a) * r * 0.95, 1.0, sin(a) * r * 0.95), Vector3(0.22, 1.2, 0.22),
			Basis(), 0.0)
	lm.frustum("Marble", b + Vector3(0, 1.6, 0), r * 0.98, r * 0.98, 0.25, sides, rot)
