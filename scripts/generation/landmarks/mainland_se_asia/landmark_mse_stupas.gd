class_name LandmarkMseStupas
extends RefCounted

## Buddhist monuments of Laos and Myanmar in true metres: Pha That Luang
## in Vientiane (45 m: the golden stupa on three square terraces inside
## its 85 m cloister) and the Ananda Temple of Bagan (1105, 51 m: the
## whitewashed cruciform temple, 53 m square with four gabled porches
## 88 m across, two curved roofs and four terraces under the gilded
## sikhara and hti).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const PHA_THAT_LUANG_M := 45.0
const ANANDA_M := 51.0

## Small bell pinnacle of height h: cream body, gilded tip.
static func _pinnacle(lm: LandmarkMesh, body: String, gold: String, base: Vector3, r: float,
		h: float, seg: int = 6) -> void:
	lm.lathe(body, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 1.08, h * 0.15),
		Vector2(r * 0.72, h * 0.42), Vector2(r * 0.5, h * 0.58), Vector2(r * 0.36, h * 0.72),
		Vector2(0.0, h * 0.74)]), seg)
	lm.lathe(gold, base + Vector3(0, h * 0.7, 0), PackedVector2Array([Vector2(r * 0.22, 0),
		Vector2(r * 0.3, h * 0.07), Vector2(r * 0.1, h * 0.17), Vector2(0.0, h * 0.3)]), seg)

## Points evenly spaced round a square of half-width hw (n of them,
## starting at a corner), at height y.
static func _round_square(hw: float, n: int, y: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in n:
		var t := 4.0 * float(i) / float(n)
		var side := int(t)
		var f := (t - float(side)) * 2.0 - 1.0
		var p := Vector2(f * hw, -hw).rotated(PI * 0.5 * float(side))
		out.append(Vector3(p.x, y, p.y))
	return out

# --- Pha That Luang ---

## Pha That Luang: the cloister gallery 85 m square with a gateway in each
## side, small windows in its outer wall and red posts on the court, three terraces (68 m, 48 m and 30 m square) each with a stair
## and gilded arched gate on every face, the lowest crowned by bai sema,
## the middle by a ring of upturned lotus petals, the top by the 30 small
## stupas; and the golden stupa: a square lotus-petal pedestal, the
## four-sided swelling bud with its ringed mouldings and the long
## tapering spire.
static func pha_that_luang(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E4D8BE", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B04A2D", 2.0))
	lm.use("Red", LandmarkMaterials.pbr("wood", "#8E2D22", 2.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	U.cloister(lm, "Plaster", "Tile", Vector3.ZERO, 42.5, 42.5, 4.0, 4.2, 2.2)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var gc := b * Vector3(0, 0, 40.5)
		lm.box("Plaster", gc + Vector3(0, 3.0, 0), Vector3(7.0, 6.0, 5.0), b)
		LandmarkAsiaSouthUtil.arch_wall(lm, "Plaster", gc + b * Vector3(0, 0, 2.6), b, 7.0, 6.0, 0.4, 3.0, 4.2)
		lm.box("Red", gc + b * Vector3(0, 2.0, 2.2), Vector3(2.8, 4.0, 0.1), b, 0.0)
		K.roof_piece(lm, "Tile", "", "Gold", "Plaster", gc + Vector3(0, 6.0, 0), b, 7.6, 5.4, 2.6, 0.8, 0.6, 1.4, 1)
		# Small windows along the cloister's outer wall and the posts of its
		# open inner side.
		for k in 18:
			var x := -38.0 + 76.0 * float(k) / 17.0
			if absf(x) < 5.5:
				continue
			K.thai_window(lm, "Plaster", "Dark", "Gold", b * Vector3(x, 1.2, 42.52), b, 0.9, 1.5)
		U.posts(lm, "Red", b * Vector3(-37.5, 0, 38.2), b * Vector3(37.5, 0, 38.2), 26, 4.2, 0.4, 0.0)
	var tops := [[34.0, 5.0, 0.0], [24.0, 10.5, 5.0], [15.0, 16.5, 10.5]]
	for ti in 3:
		var t: Array = tops[ti]
		var hw: float = t[0]
		var y1: float = t[1]
		var y0: float = t[2]
		lm.box("Plaster", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0, y1 - y0, hw * 2.0))
		lm.box("Plaster", Vector3(0, y1 - 0.2, 0), Vector3(hw * 2.0 + 1.0, 0.4, hw * 2.0 + 1.0))
		lm.box("Plaster", Vector3(0, y0 + 0.3, 0), Vector3(hw * 2.0 + 0.6, 0.6, hw * 2.0 + 0.6))
		lm.box("Gold", Vector3(0, y0 + 0.9, 0), Vector3(hw * 2.0 + 0.4, 0.3, hw * 2.0 + 0.4))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			# Niches in the terrace face, a stair and gilded arched gate on the axis.
			for k in 6:
				var x := -hw * 0.8 + hw * 1.6 * float(k) / 5.0
				if absf(x) < 4.0:
					continue
				lm.box("Dark", b * Vector3(x, (y0 + y1) * 0.5, hw + 0.04), Vector3(1.4, (y1 - y0) * 0.45, 0.1), b, 0.0)
				K.outline_prism(lm, "Gold", b * Vector3(x, (y0 + y1) * 0.5 + (y1 - y0) * 0.23, hw + 0.08), b,
					K.flame_outline(2.0, 1.2), 0.1)
			U.stairs(lm, "Plaster", b * Vector3(0, y0, hw), b, 4.0, int((y1 - y0) / 0.4), 0.36, (y1 - y0) / float(int((y1 - y0) / 0.4)))
			# Naga balustrades down the stair, the heads reared at the foot.
			var run := 0.36 * float(int((y1 - y0) / 0.4))
			for sx in [-1.0, 1.0]:
				var a := b * Vector3(sx * 2.3, y1 + 0.6, hw)
				var f := b * Vector3(sx * 2.3, y0 + 0.7, hw + run)
				lm.beam("Gold", a, a.lerp(f, 0.5) + Vector3(0, 0.15, 0), 0.45, 0.5)
				lm.beam("Gold", a.lerp(f, 0.5) + Vector3(0, 0.15, 0), f, 0.45, 0.5)
				lm.beam("Gold", f, f + Vector3(0, 1.4, 0) + b * Vector3(0, 0, 0.3), 0.5, 0.5)
				lm.box("Gold", f + Vector3(0, 1.6, 0) + b * Vector3(0, 0, 0.55), Vector3(0.9, 0.7, 0.8), b)
			lm.box("Gold", b * Vector3(0, y1 + 1.6, hw - 0.8), Vector3(4.0, 3.2, 1.0), b)
			lm.box("Dark", b * Vector3(0, y1 + 1.3, hw - 0.28), Vector3(1.8, 2.6, 0.1), b, 0.0)
			K.outline_prism(lm, "Gold", b * Vector3(0, y1 + 3.2, hw - 0.8), b, K.flame_outline(4.4, 2.8), 0.6)
		match ti:
			0:
				var c := [Vector3(-hw + 0.6, y1, -hw + 0.6), Vector3(hw - 0.6, y1, -hw + 0.6),
					Vector3(hw - 0.6, y1, hw - 0.6), Vector3(-hw + 0.6, y1, hw - 0.6)]
				for i in 4:
					K.sema_wall(lm, "Plaster", c[i], c[(i + 1) % 4], 0.8, 0.5, 1.8)
			1:
				for p in _round_square(hw - 0.9, 120, y1):
					var o := Vector3(p.x, 0, p.z)
					var out := Vector3(signf(o.x) if absf(o.x) > absf(o.z) - 0.01 else 0.0, 0,
						signf(o.z) if absf(o.z) > absf(o.x) - 0.01 else 0.0).normalized()
					var b := Basis(Vector3.UP, atan2(out.x, out.z)) * Basis(Vector3.RIGHT, 0.25)
					K.outline_prism(lm, "Gold", p, b, PackedVector2Array([Vector2(-0.5, 0), Vector2(0.5, 0),
						Vector2(0.48, 0.8), Vector2(0.3, 1.5), Vector2(0, 2.0), Vector2(-0.3, 1.5), Vector2(-0.48, 0.8)]), 0.14)
			2:
				for p in _round_square(hw - 1.2, 30, y1):
					_pinnacle(lm, "Gold", "Gold", p, 0.55, 3.0, 8)
	# The stupa on the top terrace: a square lotus-petal pedestal, the
	# swelling four-sided bud with its ringed mouldings, the long spire.
	K.redent_lathe(lm, "Gold", Vector3(0, 16.5, 0), PackedVector2Array([Vector2(11.4, 0), Vector2(11.4, 0.8),
		Vector2(10.8, 1.0), Vector2(10.8, 1.6), Vector2(10.0, 1.8), Vector2(9.4, 3.6), Vector2(8.0, 5.2)]), 0.1)
	for p in _round_square(9.6, 32, 18.4):
		var o := Vector3(p.x, 0, p.z)
		var out := Vector3(signf(o.x) if absf(o.x) > absf(o.z) - 0.01 else 0.0, 0,
			signf(o.z) if absf(o.z) > absf(o.x) - 0.01 else 0.0).normalized()
		var b := Basis(Vector3.UP, atan2(out.x, out.z)) * Basis(Vector3.RIGHT, 0.35)
		K.outline_prism(lm, "Gold", p, b, PackedVector2Array([Vector2(-1.0, 0), Vector2(1.0, 0), Vector2(0.95, 1.2),
			Vector2(0.55, 2.4), Vector2(0, 3.0), Vector2(-0.55, 2.4), Vector2(-0.95, 1.2)]), 0.2)
	var prof := PackedVector2Array([Vector2(6.8, 0), Vector2(7.4, 0.9), Vector2(6.0, 2.2), Vector2(6.6, 3.1),
		Vector2(5.2, 4.8), Vector2(5.5, 5.6), Vector2(4.2, 7.8), Vector2(4.4, 8.5), Vector2(3.2, 10.5),
		Vector2(3.3, 11.2), Vector2(2.4, 13.0), Vector2(2.55, 13.4), Vector2(1.9, 15.0), Vector2(1.3, 17.5),
		Vector2(1.38, 17.8), Vector2(0.9, 20.0), Vector2(0.55, 22.0), Vector2(0.0, PHA_THAT_LUANG_M - 21.7)])
	K.redent_lathe(lm, "Gold", Vector3(0, 21.7, 0), prof, 0.1, 0.0, 1)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pinnacle(lm, "Gold", "Gold", Vector3(sx * 10.6, 16.5, sz * 10.6), 1.1, 6.0, 8)
	lm.commit(model)

# --- Ananda Temple ---

## Ananda Temple: the 53 m square body with four gabled porches (88 m
## across) under stepped pediments with flame finials, two tiers of
## windows with flame pediments, battlemented parapets and a ringed
## stupa on each corner; two curved receding roofs and four terraces
## ringed with stupa pinnacles and glazed Jataka plaques; the white
## curvilinear sikhara with its niches and the gilded stupa and hti
## crown (51 m).
static func ananda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EFEADB", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A4573A", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	lm.use("Glaze", LandmarkMaterials.pbr("slate", "#4F7A4C", 2.0))
	lm.box("Brick", Vector3(0, 0.6, 0), Vector3(90.0, 1.2, 27.0))
	lm.box("Brick", Vector3(0, 0.6, 0), Vector3(27.0, 1.2, 90.0))
	lm.box("Brick", Vector3(0, 0.6, 0), Vector3(57.0, 1.2, 57.0))
	lm.box("Plaster", Vector3(0, 7.2, 0), Vector3(53.0, 12.0, 53.0))
	lm.box("Plaster", Vector3(0, 1.6, 0), Vector3(53.8, 0.8, 53.8))
	lm.box("Plaster", Vector3(0, 13.5, 0), Vector3(55.0, 1.0, 55.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Battlemented parapet on the body's edge, either side of the porch.
		for s in [-1.0, 1.0]:
			U.crenel_run(lm, "Plaster", b * Vector3(s * 12.0, 14.0, 26.6), b * Vector3(s * 26.6, 14.0, 26.6), 0.6, 0.6, 1.8)
		# Two tiers of windows with flame pediments, flanking the porch.
		for x in [-22.0, -16.5, 16.5, 22.0]:
			for row in 2:
				K.thai_window(lm, "Plaster", "Dark", "Plaster", b * Vector3(x, 3.0 + 4.6 * float(row), 26.52), b, 1.6,
					2.6 if row == 0 else 2.2)
		# Porch: gabled block with three receding pediments and the arched doorway.
		lm.box("Plaster", b * Vector3(0, 7.2, 35.0), Vector3(20.0, 12.0, 17.0), b)
		lm.box("Plaster", b * Vector3(0, 1.6, 35.0), Vector3(20.8, 0.8, 17.8), b)
		lm.box("Dark", b * Vector3(0, 4.6, 43.55), Vector3(5.0, 8.0, 0.2), b, 0.0)
		LandmarkDetail.arch(lm, "Plaster", b * Vector3(0, 8.6, 43.5), b * Vector3(0, 0, 1), 5.0, 0.7, 0.4)
		for sx in [-1.0, 1.0]:
			lm.box("Plaster", b * Vector3(sx * 4.0, 5.0, 43.8), Vector3(1.2, 9.0, 0.8), b)
			for zz in [30.0, 37.0]:
				K.thai_window(lm, "Plaster", "Dark", "Plaster", b * Vector3(sx * 10.02, 3.6, zz),
					b * Basis(Vector3.UP, PI * 0.5 * sx), 1.5, 2.6)
		U.tiered_roof(lm, "Plaster", "Plaster", "Gold", b * Vector3(0, 13.2, 35.0), b, 21.0, 18.0, 3.6, 3, 0.0)
		for k in 3:
			var pz := 43.6 - 2.0 * float(k)
			var py := 10.0 + 2.6 * float(k)
			K.outline_prism(lm, "Plaster", b * Vector3(0, py, pz), b, K.flame_outline(12.0 - 3.0 * float(k), 6.0 - 1.0 * float(k)), 0.6)
			lm.spire("Gold", b * Vector3(0, py + 6.0 - 1.0 * float(k), pz), 0.2, 1.6, 0.0)
		_pinnacle(lm, "Plaster", "Gold", b * Vector3(0, 20.6, 35.0), 1.6, 5.0, 10)
		for sx in [-1.0, 1.0]:
			_pinnacle(lm, "Plaster", "Gold", b * Vector3(sx * 9.4, 13.2, 43.0), 0.7, 3.0, 8)
	# Ringed stupas on the four outer corners of the body.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			K.small_chedi(lm, "Plaster", "Gold", Vector3(sx * 25.6, 14.0, sz * 25.6), 1.3, 7.0)
	# Two curved receding roofs.
	lm.lathe("Plaster", Vector3(0, 14.0, 0), PackedVector2Array([Vector2(37.4, 0), Vector2(33.0, 1.2), Vector2(30.5, 2.6),
		Vector2(30.4, 3.2)]), 4, 1.0, 1.0, PI * 0.25, false)
	lm.lathe("Plaster", Vector3(0, 17.2, 0), PackedVector2Array([Vector2(29.7, 0), Vector2(27.4, 1.1), Vector2(26.3, 2.4),
		Vector2(26.2, 3.0)]), 4, 1.0, 1.0, PI * 0.25, false)
	# Four terraces, each with stupa pinnacles and a band of glazed plaques.
	var widths := [36.0, 30.0, 24.0, 18.0]
	var y := 20.2
	for i in 4:
		var w: float = widths[i]
		lm.box("Plaster", Vector3(0, y + 1.6, 0), Vector3(w, 3.2, w))
		lm.box("Plaster", Vector3(0, y + 3.3, 0), Vector3(w + 0.6, 0.25, w + 0.6))
		var n := int(w / 1.6)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for k in n:
				var x := -w * 0.5 + 0.8 + (w - 1.6) * float(k) / float(n - 1)
				lm.quad("Glaze", b * Vector3(x - 0.5, y + 1.1, w * 0.5 + 0.03), b * Vector3(x + 0.5, y + 1.1, w * 0.5 + 0.03),
					b * Vector3(x + 0.5, y + 2.1, w * 0.5 + 0.03), b * Vector3(x - 0.5, y + 2.1, w * 0.5 + 0.03), b * Vector3(0, 0, 1))
			U.stairs(lm, "Plaster", b * Vector3(0, y, w * 0.5), b, 2.0, 6, 0.4, 3.2 / 6.0)
		var e := w * 0.5 - 1.2
		for c in [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e), Vector2(-e * 0.5, -e), Vector2(e * 0.5, -e),
				Vector2(e, -e * 0.5), Vector2(e, e * 0.5), Vector2(e * 0.5, e), Vector2(-e * 0.5, e), Vector2(-e, e * 0.5),
				Vector2(-e, -e * 0.5)]:
			_pinnacle(lm, "Plaster", "Gold", Vector3(c.x, y + 3.4, c.y), 0.8 if i < 2 else 0.6, 3.2, 8)
		y += 3.4
	# Sikhara: the redented curvilinear spire with a niche on each face.
	K.redent_lathe(lm, "Plaster", Vector3(0, y, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(7.9, 1.6),
		Vector2(7.4, 3.6), Vector2(6.5, 5.6), Vector2(5.3, 7.6), Vector2(4.1, 9.4), Vector2(3.4, 10.6)]), 0.14)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Dark", b * Vector3(0, y + 2.6, 7.75), Vector3(1.8, 2.4, 0.2), b, 0.0)
		K.outline_prism(lm, "Gold", b * Vector3(0, y + 3.9, 7.8), b, K.flame_outline(2.6, 2.6), 0.3)
	y += 10.6
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(4.0, 0.5),
		Vector2(3.8, 1.3), Vector2(3.0, 2.0)]), 16)
	y += 2.0
	var ch := ANANDA_M - y
	var hp := PackedVector2Array([Vector2(2.8, 0), Vector2(3.0, ch * 0.08), Vector2(2.4, ch * 0.3), Vector2(1.6, ch * 0.42)])
	for k in 6:
		var rr := 1.4 - 0.18 * float(k)
		var ky := ch * (0.45 + 0.07 * float(k))
		hp.append(Vector2(rr, ky))
		hp.append(Vector2(rr * 1.3, ky + ch * 0.015))
		hp.append(Vector2(rr * 0.9, ky + ch * 0.05))
	hp.append(Vector2(0.4, ch * 0.9))
	hp.append(Vector2(0.55, ch * 0.92))
	hp.append(Vector2(0.0, ch))
	lm.lathe("Gold", Vector3(0, y, 0), hp, 16)
	lm.commit(model)
