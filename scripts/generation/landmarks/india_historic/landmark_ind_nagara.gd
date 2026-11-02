class_name LandmarkIndNagara
extends RefCounted

## Two north and east Indian temples in true metres: the Konark Sun
## Temple (Kalinga style, as it stands) and the Kandariya Mahadeva Temple
## of Khajuraho (nagara style). Both face +X (east).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")

## Konark Sun Temple (30 m, the jagamohana as it stands): the 4.5 m
## platform of the chariot with 12 carved wheels either side, the ruined
## walls of the fallen sanctum, the jagamohana (porch hall) with three
## receding tiers of stepped pidas under a flat crown, and the Nata
## Mandir (dance hall) on its own raised platform to the east.
static func konark_sun_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E7B66", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5A4E44", 2.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#9A6A48", 3.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#7C8C55", 4.0))
	lm.box("Lawn", Vector3(0, -0.2, 0), Vector3(120.0, 0.4, 90.0))
	# Chariot platform: moulded base and the plinth, 56 x 32 m.
	lm.box("Stone", Vector3(-12, 0.5, 0), Vector3(58.0, 1.0, 34.0))
	lm.box("Stone", Vector3(-12, 2.75, 0), Vector3(56.0, 3.5, 32.0))
	lm.box("Dark", Vector3(-12, 4.4, 0), Vector3(56.4, 0.4, 32.4))
	# Twelve wheels per side: 3.7 m discs with a rim, 8 spokes and a hub.
	for k in 12:
		for s in [-1.0, 1.0]:
			_wheel(lm, Vector3(-35.5 + 4.5 * float(k), 2.9, s * 16.1), s)
	# The fallen sanctum: back and side walls left standing to 8-13 m.
	lm.box("Stone", Vector3(-38, 9.0, 0), Vector3(4.0, 9.0, 24.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(-27, 8.0, s * 11.0), Vector3(26.0, 7.0, 4.0))
		lm.box("Laterite", Vector3(-27, 8.0, s * 8.8), Vector3(24.0, 6.6, 0.4))
		for y in [6.5, 9.5]:
			lm.box("Dark", Vector3(-27, y, s * 13.1), Vector3(26.0, 0.5, 0.2))
	lm.box("Stone", Vector3(-34, 14.0, 0), Vector3(2.5, 4.0, 10.0))
	# Jagamohana: 20 m square hall, cornice, three tiers of stepped pidas.
	lm.box("Stone", Vector3(-4, 10.0, 0), Vector3(20.0, 11.0, 20.0))
	lm.box("Stone", Vector3(-4, 15.95, 0), Vector3(22.0, 0.9, 22.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for dx in [-6.0, 6.0]:
			lm.box("Dark", Vector3(-4, 9.5, 0) + b * Vector3(dx, 0, 10.05), Vector3(2.4, 4.5, 0.2), b)
		lm.box("Dark", Vector3(-4, 14.0, 0) + b * Vector3(0, 0, 10.05), Vector3(14.0, 0.5, 0.2), b)
	# y0, steps, step height, start width, end width
	for t in [[16.4, 6, 0.767, 19.0, 14.6], [22.2, 5, 0.76, 13.8, 10.8], [27.0, 4, 0.6, 9.4, 7.0]]:
		var y0: float = t[0]
		var n: int = t[1]
		for i in n:
			var w := lerpf(float(t[3]), float(t[4]), float(i) / float(n - 1))
			lm.box("Stone", Vector3(-4, y0 + (float(i) + 0.5) * float(t[2]), 0), Vector3(w, float(t[2]), w))
		if y0 < 26.0:
			lm.box("Dark", Vector3(-4, y0 + float(n) * float(t[2]) + 0.6, 0), Vector3(float(t[4]) - 1.8, 1.2,
				float(t[4]) - 1.8))
	lm.box("Stone", Vector3(-4, 29.7, 0), Vector3(5.0, 0.6, 5.0))
	# East porch and its stair, then the Nata Mandir with its pillars and tiered roof.
	lm.box("Stone", Vector3(9.5, 8.5, 0), Vector3(7.0, 8.0, 11.0))
	lm.box("Dark", Vector3(13.1, 7.0, 0), Vector3(0.2, 5.0, 3.5))
	lm.box("Stone", Vector3(9.5, 12.8, 0), Vector3(8.0, 0.6, 12.0))
	IU.stairs(lm, "Stone", Vector3(16, 0, 0), Basis(Vector3.UP, PI * 0.5), 10.0, 5, 0.9, 1.0)
	lm.box("Stone", Vector3(32, 2.5, 0), Vector3(18.0, 5.0, 17.0))
	lm.box("Dark", Vector3(32, 4.9, 0), Vector3(18.4, 0.4, 17.4))
	for i in 3:
		for j in 4:
			lm.box("Stone", Vector3(26.5 + 5.5 * float(i), 7.4, (float(j) - 1.5) * 4.0), Vector3(1.2, 4.8, 1.2))
	for i in 4:
		var w := 17.0 - 3.6 * float(i)
		lm.box("Stone", Vector3(32, 10.3 + 1.0 * float(i), 0), Vector3(w, 1.0, w * 0.94))
	IU.stairs(lm, "Stone", Vector3(41, 0, 0), Basis(Vector3.UP, PI * 0.5), 8.0, 5, 1.0, 1.0)
	IU.stairs(lm, "Stone", Vector3(23, 0, 0), Basis(Vector3.UP, -PI * 0.5), 8.0, 5, 1.0, 1.0)
	lm.commit(model)

## One chariot wheel on the platform side: dark face disc, rim, spokes, hub.
## `s` is the side (+1 south face, -1 north face); the axle runs along Z.
static func _wheel(lm: LandmarkMesh, c: Vector3, s: float) -> void:
	lm.disc("Dark", c, Vector3(0, 0, s), 1.85, 20)
	var zc := c + Vector3(0, 0, s * 0.2)
	for i in 16:
		var a0 := TAU * float(i) / 16.0
		var a1 := TAU * float(i + 1) / 16.0
		lm.beam("Stone", zc + Vector3(cos(a0), sin(a0), 0) * 1.7, zc + Vector3(cos(a1), sin(a1), 0) * 1.7,
			0.4, 0.4, Vector3(0, 0, 1))
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 16.0
		lm.beam("Stone", zc + Vector3(cos(a), sin(a), 0) * 0.3, zc + Vector3(cos(a), sin(a), 0) * 1.6,
			0.3, 0.3, Vector3(0, 0, 1))
	lm.box("Stone", zc, Vector3(0.9, 0.9, 0.5))

## Kandariya Mahadeva Temple (31 m): the largest Khajuraho temple on its
## 4 m plinth, a train of four roofs rising from the entrance porch through
## the mandapa and the maha mandapa (with lateral balconies) to the
## curvilinear shikhara of the sanctum, ringed by 84 clinging miniature
## spires, with the ribbed amalaka and the kalasha on top.
static func kandariya_mahadeva(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B79776", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#C7AE8E", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5E4C3E", 2.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#7C8C55", 4.0))
	lm.box("Lawn", Vector3(0, -0.2, 0), Vector3(90.0, 0.4, 70.0))
	lm.box("Stone", Vector3(0, 0.6, 0), Vector3(46.0, 1.2, 30.0))
	lm.box("Stone", Vector3(0, 2.6, 0), Vector3(44.0, 2.8, 28.0))
	lm.box("Dark", Vector3(0, 4.05, 0), Vector3(44.4, 0.3, 28.4))
	IU.stairs(lm, "Stone", Vector3(23, 0, 0), Basis(Vector3.UP, PI * 0.5), 9.0, 5, 0.8, 0.9)
	# Blocks from the sanctum to the porch: x0, x1, half width, wall top, roof steps.
	var blocks := [[-17.0, -3.0, 6.6, 13.0, 0], [-3.0, 7.0, 7.4, 12.2, 8], [7.0, 12.5, 5.2, 10.5, 6],
		[12.5, 17.0, 4.0, 9.0, 5]]
	for bk in blocks:
		var cx := (float(bk[0]) + float(bk[1])) * 0.5
		var w := float(bk[1]) - float(bk[0])
		var hz: float = bk[2]
		var top: float = bk[3]
		lm.box("Stone", Vector3(cx, (4.2 + top) * 0.5, 0), Vector3(w, top - 4.2, hz * 2.0))
		lm.box("Pale", Vector3(cx, top + 0.2, 0), Vector3(w + 0.8, 0.5, hz * 2.0 + 0.8))
		for y in [6.8, 9.3]:
			if y < top - 0.5:
				for sz in [-1.0, 1.0]:
					lm.box("Dark", Vector3(cx, y, sz * (hz + 0.08)), Vector3(w - 0.6, 0.55, 0.2))
		# Phamsana roof: receding slabs rising to the next block's cornice.
		var steps: int = bk[4]
		for i in steps:
			var f := float(i) / float(steps)
			lm.box("Stone", Vector3(cx, top + 0.7 + 0.9 * float(i) + 0.45, 0),
				Vector3(w * (1.02 - 0.5 * f), 0.9, hz * 2.0 * (1.0 - 0.66 * f)))
	# Balconies on the lateral transepts of the maha mandapa.
	for sz in [-1.0, 1.0]:
		lm.box("Pale", Vector3(2.0, 8.0, sz * 8.6), Vector3(6.0, 3.6, 1.6))
		lm.box("Dark", Vector3(2.0, 8.0, sz * 9.45), Vector3(3.6, 2.2, 0.2))
		lm.spire("Stone", Vector3(2.0, 9.8, sz * 8.6), 3.0, 1.6, 0.4)
	lm.box("Dark", Vector3(17.1, 6.4, 0), Vector3(0.2, 3.6, 3.2))
	# Shikhara of the sanctum: curved square spire, 13 -> 27.5 m.
	var tower := Vector3(-10.0, 13.0, 0)
	var prof := PackedVector2Array()
	for i in 11:
		var t := float(i) / 10.0
		prof.append(Vector2(6.0 * 1.414 * (1.0 - 0.62 * pow(t, 1.5)), 14.5 * t))
	lm.lathe("Stone", tower, prof, 4, 1.0, 1.0, PI * 0.25, false)
	# Vertical ribs (lata) up each face, following the curve of the tower.
	for side in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(side))
		for sx in [-1.0, 1.0]:
			for i in 10:
				var t0 := float(i) / 10.0
				var t1 := float(i + 1) / 10.0
				var h0 := 6.0 * (1.0 - 0.62 * pow(t0, 1.5))
				var h1 := 6.0 * (1.0 - 0.62 * pow(t1, 1.5))
				lm.beam("Pale", tower + rb * Vector3(sx * h0 * 0.42, 14.5 * t0, h0 + 0.1),
					tower + rb * Vector3(sx * h1 * 0.42, 14.5 * t1, h1 + 0.1), 0.45, 0.35, rb * Vector3(1, 0, 0))
	# Clinging urushringa: rows of miniature spires up each face and corner.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for lvl in 4:
			var t := 0.12 + 0.2 * float(lvl)
			var hw: float = 6.0 * (1.0 - 0.62 * pow(t, 1.5))
			var count := maxi(3 - lvl, 1)
			for k in count:
				var x := (float(k) - float(count - 1) * 0.5) * (hw * 1.2 if count > 1 else 0.0)
				_mini(lm, "Stone", tower + b * Vector3(x, 14.5 * t, hw - 0.3), 1.3 - 0.15 * float(lvl),
					5.6 - 0.8 * float(lvl), b)
		for lvl in 2:
			var t := 0.1 + 0.26 * float(lvl)
			var hw: float = 6.0 * (1.0 - 0.62 * pow(t, 1.5)) - 0.4
			_mini(lm, "Stone", tower + b * Vector3(hw, 14.5 * t, hw), 1.2, 5.0 - 1.2 * float(lvl), b)
	# Amalaka (ribbed disc) and kalasha: 27.5 -> 31 m.
	lm.lathe("Pale", tower + Vector3(0, 14.5, 0), PackedVector2Array([Vector2(2.7, 0), Vector2(3.4, 0.5),
		Vector2(3.1, 1.1), Vector2(2.5, 1.6), Vector2(1.8, 2.0)]), 16)
	lm.lathe("Pale", tower + Vector3(0, 16.5, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(1.3, 0.5),
		Vector2(1.0, 1.0), Vector2(0.5, 1.3), Vector2(0.0, 1.5)]), 10)
	lm.commit(model)

## Miniature tower (urushringa): curved square spire of half width hw and
## height h standing at `p` (turned by `b`).
static func _mini(lm: LandmarkMesh, key: String, p: Vector3, hw: float, h: float, _b: Basis) -> void:
	var r := hw * 1.414
	lm.lathe(key, p, PackedVector2Array([Vector2(r, 0), Vector2(r * 1.05, h * 0.25), Vector2(r * 0.9, h * 0.5),
		Vector2(r * 0.62, h * 0.75), Vector2(r * 0.3, h * 0.92), Vector2(0.0, h)]), 4, 1.0, 1.0, PI * 0.25,
		false)
