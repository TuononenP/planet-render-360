class_name LandmarkLpSyria
extends RefCounted

## The Umayyad Mosque of Damascus in true metres, built in compass frame
## (+X east, -Z north). Krak des Chevaliers is in LandmarkLpKrak.

# --- Umayyad Mosque, Damascus ---

## 157 x 97 m Roman temenos (705-715): the courtyard on the north ringed on
## three sides by porticoes of large round arches on alternating piers and
## paired columns under an upper storey of double arches, with the
## Treasury dome on eight Roman columns (west), the Dome of the Clocks
## (east) and the ablution fountain; the prayer hall (136 x 37 m) on the
## south: its courtyard arcade of 2 x 11 arches, three gabled lead roofs,
## the high transept with its pedimented, mosaic-clad front and the Dome of
## the Eagle (36 m) on an octagonal drum with two windows a side; the
## Minaret of Jesus (south-east, 77 m: square body with two covered
## galleries, octagonal stage, two open galleries, spire), the Minaret of
## the Bride on the north wall (four galleries, lead roof, spire) and
## Qaitbay's octagonal Mamluk minaret (south-west, three galleries).
static func umayyad(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DAC9A2", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8E989F", 5.0, 0.45))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#D6C8A8", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#231D17", 3.0, 0.92))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Mosaic", LandmarkMaterials.pbr("render", "#8C8A4A", 2.0, 0.35))
	lm.box("Court", Vector3(0, 0.1, 0), Vector3(160, 0.2, 100), Basis(), 0.0)
	# Outer Roman walls with pilasters and a cornice; the courtyard wings.
	lm.box("Stone", Vector3(0, 7.5, -47.25), Vector3(157, 15.0, 2.5))
	for i in 26:
		var x := -75.0 + 6.0 * float(i)
		lm.box("Stone", Vector3(x, 7.0, -48.7), Vector3(1.4, 14.0, 0.5))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(s) * 74.0, 6.0, -17.0), Vector3(9.0, 12.0, 61.0))
		for i in 10:
			lm.box("Stone", Vector3(float(s) * 78.7, 7.0, -44.0 + 6.0 * float(i)), Vector3(0.5, 14.0, 1.4))
		_portico(lm, Vector3(float(s) * 61.0, 0.2, -16.5), -float(s) * PI * 0.5, 49.0, 7, 8.4)
	_portico(lm, Vector3(0, 0.2, -38.0), 0.0, 122.0, 17, 7.9)
	_prayer_hall(lm)
	_courtyard_domes(lm)
	_minaret_jesus(lm, Vector3(74.0, 0, 44.0))
	_minaret_bride(lm, Vector3(0.0, 0, -45.0))
	_minaret_qaitbay(lm, Vector3(-74.0, 0, 44.0))
	lm.commit(model)

## Courtyard portico of `n` bays along `length` (front plane at `front`,
## facing yaw, `depth` back to the outer wall): round arches on piers,
## paired columns before the intermediate piers, the dark depth of the
## portico and the upper storey of double arched openings over it.
static func _portico(lm: LandmarkMesh, front: Vector3, yaw: float, length: float, n: int, depth: float) -> void:
	var r := LandmarkLpParts.across(yaw)
	var f := LandmarkLpParts.outward(yaw)
	var basis := Basis(Vector3.UP, yaw)
	var pitch := length / float(n)
	var lower := LandmarkLpDetail.bays(n, length, pitch * 0.34, 4.2)
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(length, 7.0, lower, 8), front, yaw, 1.6)
	lm.box("Dark", front - f * (depth - 0.05) + Vector3(0, 3.5, 0), Vector3(length, 7.0, 0.1), basis, 0.0)
	# Upper storey: two small round arches over every lower bay.
	var upper := LandmarkLpDetail.bays(n * 2, length, pitch * 0.17, 1.2)
	LandmarkLpDetail.arcade_skin(lm, "Stone", "Dark", front + Vector3(0, 7.0, 0), yaw, length, 3.6, upper, 0.6, 6)
	lm.box("Stone", front - f * (0.3 + depth * 0.5) + Vector3(0, 8.8, 0), Vector3(length, 3.6, depth - 0.6), basis)
	lm.box("Stone", front + f * 0.15 + Vector3(0, 10.75, 0), Vector3(length + 0.6, 0.3, 0.9), basis)
	# Paired columns before every other pier (pier, two columns, pier...).
	for i in range(1, n):
		if i % 3 == 0:
			continue
		var u := -length * 0.5 + pitch * float(i)
		LandmarkLpParts.column(lm, "Stone", front + r * u + f * 0.45, 0.32, 4.4, 0.6, 10)
		lm.box("Mosaic", front + r * u + f * 0.02 + Vector3(0, 5.6, 0), Vector3(pitch * 0.3, 1.2, 0.06), basis, 0.0)

## Prayer hall: walls, courtyard arcade, three roofs, transept, Eagle dome.
static func _prayer_hall(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 7.5, 28.25), Vector3(157, 15.0, 40.5))
	var arches: Array = []
	for i in 11:
		for s in [-1.0, 1.0]:
			arches.append([float(s) * (12.0 + 5.09 * (float(i) + 0.5)), 1.9, 5.4, 1.9])
	arches.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(136.0, 14.0, arches, 6), Vector3(0, 0.2, 8.0), PI, 3.0)
	lm.box("Dark", Vector3(0, 3.8, 11.05), Vector3(136.0, 7.2, 0.1), Basis(), 0.0)
	for ar in arches:
		lm.box("Stone", Vector3(float(ar[0]), 9.6, 7.9), Vector3(1.2, 2.0, 0.2), Basis(), 0.0)
		LandmarkLpParts.arch_panel(lm, "Dark", Vector3(float(ar[0]) - 0.9, 9.0, 7.98), PI, 0.5, 1.4, 0.5)
		LandmarkLpParts.arch_panel(lm, "Dark", Vector3(float(ar[0]) + 0.9, 9.0, 7.98), PI, 0.5, 1.4, 0.5)
	lm.box("Stone", Vector3(0, 14.2, 7.8), Vector3(137.0, 0.4, 0.8))
	for z in [14.2, 26.5]:
		lm.gable("Lead", Vector3(0, 15.0, z), 12.4, 157.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	lm.gable("Lead", Vector3(0, 15.0, 40.8), 15.6, 157.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	# Transept: high walls with clerestory windows, gable roof, mosaic front.
	lm.box("Stone", Vector3(0, 10.0, 28.25), Vector3(24.0, 20.0, 40.5))
	lm.gable("Lead", Vector3(0, 20.0, 28.25), 24.0, 40.5, 4.0, Basis(), 0.0, "Stone")
	for s in [-1.0, 1.0]:
		for i in 5:
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(float(s) * 12.02, 15.6, 12.0 + 8.0 * float(i)),
				float(s) * PI * 0.5, 0.8, 1.8, 0.8)
	var fz := 8.0
	var tri := LandmarkLpDetail.bays(3, 18.0, 2.1, 6.0)
	tri[1] = [0.0, 3.0, 6.4, 3.0]
	LandmarkLpDetail.arcade_skin(lm, "Stone", "Dark", Vector3(0, 0.2, fz - 0.6), PI, 24.0, 11.0, tri, 0.6, 8)
	LandmarkLpDetail.arcade_skin(lm, "Mosaic", "Dark", Vector3(0, 11.2, fz - 0.6), PI, 24.0, 8.6,
		LandmarkLpDetail.bays(3, 15.0, 1.4, 3.6), 0.6, 8)
	lm.box("Stone", Vector3(0, 11.1, fz - 1.3), Vector3(24.6, 0.4, 1.0))
	lm.box("Stone", Vector3(0, 20.0, fz - 0.9), Vector3(24.6, 0.4, 0.8))
	lm.box("Mosaic", Vector3(0, 21.0, fz - 0.15), Vector3(14.0, 1.6, 0.1), Basis(), 0.0)
	# Dome of the Eagle: octagonal drum, two windows a side, lead dome, finial.
	var dc := Vector3(0, 0, 28.25)
	lm.frustum("Stone", dc + Vector3(0, 18.0, 0), 8.8, 8.8, 10.5, 8, PI / 8.0)
	lm.frustum("Stone", dc + Vector3(0, 27.9, 0), 9.2, 9.3, 0.6, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var r := Vector3(-d.z, 0, d.x)
		for s in [-1.0, 1.0]:
			LandmarkLpParts.arch_panel(lm, "Dark", dc + d * 8.15 + r * (float(s) * 1.4) + Vector3(0, 22.4, 0),
				PI * 0.5 - a, 0.55, 2.4, 0.55)
		lm.box("Stone", dc + d * 8.1 + Vector3(0, 23.2, 0), Vector3(0.5, 4.6, 0.3), Basis.looking_at(d))
	lm.lathe("Lead", dc + Vector3(0, 28.5, 0), LandmarkLpParts.dome_profile(9.2, 6.6, 10, 0.25), 32)
	LandmarkLpParts.needle(lm, "Gold", dc + Vector3(0, 35.1, 0),
		PackedVector2Array([Vector2(0, 0.25), Vector2(0.4, 0.15), Vector2(0.9, 0.04)]), 8)

## Dome of the Treasury on eight columns (west), the Dome of the Clocks
## (east) and the ablution fountain kiosk in the middle of the court.
static func _courtyard_domes(lm: LandmarkMesh) -> void:
	for side in [-1.0, 1.0]:
		var tc := Vector3(float(side) * 36.0, 0.2, -22.0)
		var rr := 3.2 if side < 0.0 else 2.6
		for k in 8:
			var a := TAU * float(k) / 8.0
			LandmarkLpParts.column(lm, "Stone", tc + Vector3(cos(a) * rr, 0, sin(a) * rr), 0.32, 5.4, 0.7, 10)
		lm.frustum("Stone", tc + Vector3(0, 5.4, 0), rr + 0.6, rr + 0.5, 0.5, 8, PI / 8.0)
		lm.frustum("Mosaic", tc + Vector3(0, 5.9, 0), rr + 0.45, rr + 0.35, 3.0, 8, PI / 8.0)
		lm.frustum("Stone", tc + Vector3(0, 8.9, 0), rr + 0.6, rr + 0.5, 0.3, 8, PI / 8.0)
		lm.lathe("Lead", tc + Vector3(0, 9.2, 0), LandmarkLpParts.dome_profile(rr + 0.4, rr * 0.9, 6, 0.1), 16)
	var fc := Vector3(0, 0.2, -16.0)
	lm.frustum("Stone", fc, 4.0, 4.0, 0.6, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Stone", fc + Vector3(cos(a) * 3.2, 0.6, sin(a) * 3.2), 0.2, 0.18, 3.4, 8)
	lm.frustum("Stone", fc + Vector3(0, 4.0, 0), 3.7, 3.6, 0.4, 8, PI / 8.0)
	lm.lathe("Lead", fc + Vector3(0, 4.4, 0), LandmarkLpParts.dome_profile(3.4, 2.4, 5, 0.2), 16)

## Covered gallery round a square shaft of `side` at height y: corbelled
## floor, posts and a lead pent roof.
static func _covered_gallery(lm: LandmarkMesh, base: Vector3, side: float, y: float) -> void:
	var w := side + 2.4
	lm.box("Stone", base + Vector3(0, y - 0.6, 0), Vector3(side + 0.8, 0.6, side + 0.8))
	lm.box("Stone", base + Vector3(0, y - 0.15, 0), Vector3(w, 0.3, w))
	for sx in [-1.0, 1.0]:
		for i in 4:
			var t := -w * 0.5 + 0.3 + (w - 0.6) * float(i) / 3.0
			lm.box("Stone", base + Vector3(float(sx) * (w * 0.5 - 0.3), y + 1.4, t), Vector3(0.25, 2.8, 0.25), Basis(), 0.0)
			lm.box("Stone", base + Vector3(t, y + 1.4, float(sx) * (w * 0.5 - 0.3)), Vector3(0.25, 2.8, 0.25), Basis(), 0.0)
	lm.box("Dark", base + Vector3(0, y + 1.4, 0), Vector3(side + 0.1, 2.6, side + 0.1), Basis(), 0.0)
	lm.spire("Lead", base + Vector3(0, y + 2.8, 0), w * 0.5 + 0.3, 0.9, side * 0.5, 4)

## Open gallery round an octagonal stage of radius r at height y: corbel
## ring, floor and railing posts.
static func _open_gallery(lm: LandmarkMesh, base: Vector3, r: float, y: float) -> void:
	lm.frustum("Stone", base + Vector3(0, y - 0.8, 0), r, r * 1.45, 0.8, 8, PI / 8.0)
	lm.frustum("Stone", base + Vector3(0, y, 0), r * 1.5, r * 1.5, 0.25, 8, PI / 8.0)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Stone", base + Vector3(cos(a) * r * 1.42, y + 0.6, sin(a) * r * 1.42), Vector3(0.12, 0.9, 0.12),
			Basis(), 0.0)
	lm.frustum("Stone", base + Vector3(0, y + 1.05, 0), r * 1.45, r * 1.45, 0.12, 8, PI / 8.0)

## Minaret of Jesus (77 m): square body (6.6 m) with two covered galleries,
## octagonal stage with two open galleries and windows, pencil spire.
static func _minaret_jesus(lm: LandmarkMesh, base: Vector3) -> void:
	var side := 6.6
	lm.box("Stone", base + Vector3(0, 22.0, 0), Vector3(side, 44.0, side))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var d := LandmarkLpParts.outward(yaw)
		for y in [12.0, 21.0, 30.0, 39.0]:
			LandmarkLpParts.arch_panel(lm, "Dark", base + d * (side * 0.5 + 0.02) + Vector3(0, float(y), 0), yaw,
				0.4, 1.4, 0.4)
	_covered_gallery(lm, base, side, 18.5)
	_covered_gallery(lm, base, side, 40.4)
	lm.box("Stone", base + Vector3(0, 44.4, 0), Vector3(side + 1.6, 0.8, side + 1.6))
	var y0 := 44.8
	lm.frustum("Stone", base + Vector3(0, y0, 0), 2.9, 2.7, 16.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkLpParts.arch_panel(lm, "Dark", base + d * 2.62 + Vector3(0, y0 + 2.0, 0), PI * 0.5 - a, 0.45, 1.6, 0.45)
		LandmarkLpParts.arch_panel(lm, "Dark", base + d * 2.55 + Vector3(0, y0 + 10.4, 0), PI * 0.5 - a, 0.4, 1.4, 0.4)
	_open_gallery(lm, base, 2.8, y0 + 7.0)
	_open_gallery(lm, base, 2.7, y0 + 15.2)
	lm.spire("Lead", base + Vector3(0, y0 + 16.0, 0), 2.75, 15.4, 0.0, 8)
	LandmarkLpParts.needle(lm, "Gold", base + Vector3(0, y0 + 31.4, 0),
		PackedVector2Array([Vector2(0, 0.14), Vector2(0.3, 0.2), Vector2(0.5, 0.05), Vector2(0.8, 0.05)]), 6)

## Minaret of the Bride on the north wall: square tower with four
## galleries (the top one under a lead roof) and a slender spire.
static func _minaret_bride(lm: LandmarkMesh, base: Vector3) -> void:
	var side := 5.6
	lm.box("Stone", base + Vector3(0, 18.0, 0), Vector3(side, 36.0, side))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var d := LandmarkLpParts.outward(yaw)
		for y in [17.0, 25.0, 31.5]:
			LandmarkLpParts.arch_panel(lm, "Dark", base + d * (side * 0.5 + 0.02) + Vector3(0, float(y), 0), yaw,
				0.45, 1.6, 0.45)
	for y in [16.0, 23.0, 29.5]:
		lm.box("Stone", base + Vector3(0, float(y), 0), Vector3(side + 1.6, 0.4, side + 1.6))
		for sx in [-1.0, 1.0]:
			lm.box("Stone", base + Vector3(float(sx) * (side * 0.5 + 0.7), float(y) + 0.55, 0), Vector3(0.12, 0.7, side + 1.4),
				Basis(), 0.0)
			lm.box("Stone", base + Vector3(0, float(y) + 0.55, float(sx) * (side * 0.5 + 0.7)), Vector3(side + 1.4, 0.7, 0.12),
				Basis(), 0.0)
	_covered_gallery(lm, base, side, 36.4)
	lm.frustum("Stone", base + Vector3(0, 39.6, 0), 1.4, 1.3, 4.0, 8, PI / 8.0)
	lm.spire("Lead", base + Vector3(0, 43.6, 0), 1.5, 4.8, 0.0, 8)
	LandmarkLpParts.needle(lm, "Gold", base + Vector3(0, 48.4, 0), PackedVector2Array([Vector2(0, 0.1), Vector2(0.6, 0.04)]), 6)

## Qaitbay's minaret (1488): octagonal Mamluk shaft in receding stages,
## three muqarnas galleries, a pavilion of posts and the bulb finial.
static func _minaret_qaitbay(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Stone", base + Vector3(0, 7.0, 0), Vector3(5.6, 14.0, 5.6))
	var stages := [[14.0, 2.6, 11.0], [25.0, 2.2, 8.0], [33.0, 1.8, 5.0]]
	for st in stages:
		var y: float = st[0]
		var r: float = st[1]
		var h: float = st[2]
		lm.frustum("Stone", base + Vector3(0, y, 0), r, r * 0.97, h, 8, PI / 8.0)
		for k in 8:
			var a := TAU * (float(k) + 0.5) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkLpParts.arch_panel(lm, "Dark", base + d * (r * 0.95) + Vector3(0, y + h * 0.3, 0), PI * 0.5 - a,
				r * 0.18, h * 0.3, r * 0.2)
		_open_gallery(lm, base, r * 0.97, y + h)
	var top := 38.0 + 1.2
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Stone", base + Vector3(cos(a) * 1.2, top + 1.2, sin(a) * 1.2), Vector3(0.2, 2.4, 0.2), Basis(), 0.0)
	lm.frustum("Stone", base + Vector3(0, top + 2.4, 0), 1.5, 1.5, 0.3, 8, PI / 8.0)
	lm.lathe("Lead", base + Vector3(0, top + 2.7, 0), LandmarkLpParts.bulb_profile(1.2, 2.4, 1.15, 8, 1.3), 12)
	LandmarkLpParts.needle(lm, "Gold", base + Vector3(0, top + 5.1, 0), PackedVector2Array([Vector2(0, 0.08), Vector2(0.7, 0.04)]), 6)
