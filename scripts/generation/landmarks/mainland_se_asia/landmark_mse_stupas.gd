class_name LandmarkMseStupas
extends RefCounted

## Buddhist monuments of Laos and Myanmar in true metres: Pha That Luang
## in Vientiane (45 m: the golden stupa on three square terraces inside
## its cloister) and the Ananda Temple of Bagan (51 m: the whitewashed
## cruciform temple with five receding terraces and the gilded sikhara).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")

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

# --- Pha That Luang ---

## Pha That Luang: the cloister gallery 85 m square, three terraces (68 m,
## 48 m and 30 m square) ringed by gilded lotus-bud pinnacles, and the
## golden stupa, a lotus bud swelling in waves up to a tapering spire.
static func pha_that_luang(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E4D8BE", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B04A2D", 2.0))
	lm.use("Red", LandmarkMaterials.pbr("wood", "#8E2D22", 2.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	U.cloister(lm, "Plaster", "Tile", Vector3.ZERO, 42.5, 42.5, 4.0, 4.2, 2.2)
	lm.box("Red", Vector3(0, 2.1, 42.6), Vector3(5.0, 4.2, 0.2))
	var tops := [[34.0, 5.0, 0.0], [24.0, 10.5, 5.0], [15.0, 16.5, 10.5]]
	for t in tops:
		var hw: float = t[0]
		var y1: float = t[1]
		var y0: float = t[2]
		lm.box("Plaster", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0, y1 - y0, hw * 2.0))
		lm.box("Plaster", Vector3(0, y1 + 0.2, 0), Vector3(hw * 2.0 + 1.0, 0.4, hw * 2.0 + 1.0))
		lm.box("Gold", Vector3(0, y0 + 0.9, 0), Vector3(hw * 2.0 + 0.4, 0.3, hw * 2.0 + 0.4))
		var n := int(hw * 0.5)
		for i in n:
			var f := -hw + 1.2 + (hw * 2.0 - 2.4) * float(i) / float(n - 1)
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				_pinnacle(lm, "Plaster", "Gold", Vector3(0, y1 + 0.4, 0) + b * Vector3(f, 0, hw - 0.9), 0.55, 2.4)
		# Niches in the terrace faces.
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for k in 5:
				lm.box("Dark", b * Vector3(-hw * 0.7 + hw * 0.35 * float(k), (y0 + y1) * 0.5, hw + 0.05),
					Vector3(1.6, (y1 - y0) * 0.5, 0.15), b)
	# The stupa on the top terrace: a square lotus-petal pedestal with a
	# pinnacle on each corner, the ringed vase-shaped bud and its long spire.
	lm.box("Gold", Vector3(0, 16.9, 0), Vector3(23.0, 0.8, 23.0))
	lm.spire("Gold", Vector3(0, 17.3, 0), 10.2, 4.6, 7.4)
	var prof := PackedVector2Array([Vector2(6.8, 0), Vector2(7.4, 0.9), Vector2(6.0, 2.2), Vector2(6.6, 3.1),
		Vector2(5.2, 4.8), Vector2(5.5, 5.6), Vector2(4.2, 7.8), Vector2(4.4, 8.5), Vector2(3.2, 10.5),
		Vector2(3.3, 11.2), Vector2(2.4, 13.0), Vector2(1.9, 15.0), Vector2(1.3, 17.5), Vector2(0.9, 20.0),
		Vector2(0.55, 22.0), Vector2(0.0, PHA_THAT_LUANG_M - 21.9)])
	lm.lathe("Gold", Vector3(0, 21.9, 0), prof, 20)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pinnacle(lm, "Gold", "Gold", Vector3(sx * 10.6, 16.5, sz * 10.6), 1.1, 6.0, 8)
	lm.commit(model)

# --- Ananda Temple ---

## Ananda Temple: the 53 m square body with four gabled porches (88 m
## across), five receding terraces ringed with stupa pinnacles, the white
## curvilinear sikhara and the gilded stupa crown (51 m).
static func ananda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EFEADB", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A4573A", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	lm.box("Brick", Vector3(0, 0.6, 0), Vector3(90.0, 1.2, 27.0))
	lm.box("Brick", Vector3(0, 0.6, 0), Vector3(27.0, 1.2, 90.0))
	lm.box("Plaster", Vector3(0, 7.4, 0), Vector3(53.0, 12.4, 53.0))
	lm.box("Plaster", Vector3(0, 13.9, 0), Vector3(55.0, 1.0, 55.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Porch: gabled block with stepped roofs and the arched doorway.
		lm.box("Plaster", b * Vector3(0, 7.2, 35.0), Vector3(20.0, 12.0, 17.0), b)
		lm.box("Dark", b * Vector3(0, 4.6, 43.55), Vector3(5.0, 8.0, 0.2), b)
		lm.box("Plaster", b * Vector3(0, 8.8, 43.6), Vector3(8.0, 0.8, 0.3), b)
		U.tiered_roof(lm, "Plaster", "Plaster", "Gold", b * Vector3(0, 13.2, 35.0), b, 21.0, 18.0, 3.6, 3, 0.0)
		for x in [-21.0, -15.0, 15.0, 21.0]:
			lm.box("Dark", b * Vector3(x, 7.0, 26.55), Vector3(2.4, 4.6, 0.2), b)
	# Five receding terraces, each with stupa pinnacles on its ledge.
	var widths := [46.0, 38.0, 30.0, 23.0, 16.0]
	var y := 14.4
	for i in 5:
		var w: float = widths[i]
		lm.box("Plaster", Vector3(0, y + 1.6, 0), Vector3(w, 3.2, w))
		lm.box("Gold", Vector3(0, y + 3.3, 0), Vector3(w + 0.5, 0.25, w + 0.5))
		var e := w * 0.5 - 1.5
		for c in [Vector2(-e, -e), Vector2(e, -e), Vector2(e, e), Vector2(-e, e), Vector2(0, -e),
				Vector2(e, 0), Vector2(0, e), Vector2(-e, 0)]:
			_pinnacle(lm, "Plaster", "Gold", Vector3(c.x, y + 3.2, c.y), 0.9 if i < 3 else 0.7, 3.4, 8)
		y += 3.2
	# Sikhara: square curvilinear spire, then the crown of stupa and finial.
	lm.lathe("Plaster", Vector3(0, y, 0), PackedVector2Array([Vector2(10.6, 0), Vector2(9.8, 2.4),
		Vector2(8.6, 5.2), Vector2(7.0, 8.0), Vector2(5.3, 10.4), Vector2(4.0, 12.0)]), 4, 1.0, 1.0, PI * 0.25, false)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Dark", b * Vector3(0, y + 3.2, 6.45), Vector3(2.2, 2.0, 0.4), b)
	y += 12.0
	lm.lathe("Plaster", Vector3(0, y, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(4.2, 0.5),
		Vector2(4.0, 1.3), Vector2(3.0, 2.0)]), 8)
	y += 2.0
	var ch := ANANDA_M - y
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(2.8, 0), Vector2(3.0, ch * 0.08),
		Vector2(2.4, ch * 0.34), Vector2(1.5, ch * 0.53), Vector2(1.0, ch * 0.62), Vector2(1.3, ch * 0.7),
		Vector2(0.8, ch * 0.81), Vector2(1.0, ch * 0.9), Vector2(0.5, ch * 0.96), Vector2(0.0, ch)]), 14)
	lm.commit(model)
