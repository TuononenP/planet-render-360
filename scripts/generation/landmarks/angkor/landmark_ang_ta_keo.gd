class_name LandmarkAngTaKeo
extends RefCounted

## Ta Keo in true metres: the unfinished temple-mountain of Jayavarman V
## and Suryavarman I in bare, uncarved sandstone. Built facing +X (east).

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const E = preload("res://scripts/generation/landmarks/angkor/landmark_ang_east.gd")

const T1 := 2.0      ## first terrace above the ground
const T2 := 7.5      ## second terrace, 5.5 m higher
const STEP := 14.0 / 3.0  ## each of the three pyramid steps
const TOP := 21.5    ## summit platform above the ground

## Ta Keo (45 m): the five-tier mountain: the 122 x 106 m first terrace
## with its wall and four three-passage gopuras and the two long tiled
## galleries on the east side; the second terrace 5.5 m higher with its
## inner gallery wall (80 x 75 m), gopuras, east-corner gallery buildings
## and two libraries; the three-step pyramid (60 m square narrowing to
## 47 m, 14 m high) with a steep stair on every face; and on the summit the
## quincunx of five sanctuary towers on 0.8 m basements, the central one on
## a 4 m basement rising to 45 m: all cut off bare, never carved. A short
## stretch of the 500 m causeway runs out to the east. Built facing +X.
static func ta_keo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A7E6A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#9A8E78", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#25221E", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("brick", "#8A4E36", 3.0))
	var wall: Array[String] = ["Stone", "Trim", "Dark"]
	var footing: Array[String] = ["Laterite", "Trim", "Dark"]
	# First terrace: laterite basement, sandstone coping, wall on a laterite base.
	lm.box("Laterite", Vector3(0, T1 * 0.5, 0), Vector3(122.0, T1, 106.0))
	lm.box("Trim", Vector3(0, T1 + 0.1, 0), Vector3(122.6, 0.2, 106.6), Basis(), 0.0)
	E.gallery(lm, footing, Vector3(0, T1, 0), 57.0, 49.0, 1.2, 1.6, 7.0, 7.0, false, false)
	E.gallery(lm, wall, Vector3(0, T1 + 1.5, 0), 57.0, 49.0, 2.0, 1.4, 7.0, 7.0, false, false)
	# Long galleries along the inside of the east wall (wood-and-tile roofs).
	for s in [-1.0, 1.0]:
		var gz: float = s * 30.5
		lm.box("Stone", Vector3(54.0, T1 + 1.4, gz), Vector3(3.6, 2.8, 34.0))
		for i in 8:
			lm.box("Dark", Vector3(52.15, T1 + 1.7, gz - 15.75 + 4.5 * float(i)), Vector3(0.12, 1.0, 1.4),
				Basis(), 0.0)
		lm.gable("Tile", Vector3(54.0, T1 + 2.8, gz), 4.4, 34.0, 1.6, Basis(), 0.3, "Stone")
	# Second terrace: the 80 x 75 m platform and its gallery wall.
	lm.box("Stone", Vector3(0, (T1 + T2) * 0.5, 0), Vector3(80.0, T2 - T1, 75.0))
	lm.box("Trim", Vector3(0, T2 - 0.2, 0), Vector3(80.8, 0.4, 75.8))
	lm.box("Trim", Vector3(0, T1 + 0.4, 0), Vector3(81.0, 0.8, 76.0), Basis(), 0.0)
	E.gallery(lm, wall, Vector3(0, T2, 0), 36.0, 33.5, 2.8, 1.4, 6.0, 6.0, true, false)
	for s in [-1.0, 1.0]:
		# Gallery buildings at the east corners, libraries by the pyramid.
		lm.box("Stone", Vector3(33.0, T2 + 1.4, s * 24.0), Vector3(3.4, 2.8, 12.0))
		lm.gable("Tile", Vector3(33.0, T2 + 2.8, s * 24.0), 4.2, 12.0, 1.4, Basis(), 0.3, "Stone")
		lm.box("Stone", Vector3(33.0, T2 + 1.5, s * 12.0), Vector3(3.4, 3.0, 5.0))
		lm.box("Dark", Vector3(31.25, T2 + 1.5, s * 12.0), Vector3(0.12, 1.6, 1.3), Basis(), 0.0)
		lm.gable("Stone", Vector3(33.0, T2 + 3.0, s * 12.0), 3.8, 5.4, 1.1, Basis(), 0.3, "Stone")
	# Gopuras: second terrace (inner wall) and first terrace (outer wall).
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		var odd := i % 2 == 1
		_gopura(lm, Vector3.UP * T2 + b * Vector3(0, 0, 36.0 if odd else 33.5), b, 14.0, 7.0, 5.0, 7.5)
		_gopura(lm, Vector3.UP * T1 + b * Vector3(0, 0, 57.0 if odd else 49.0), b, 16.0, 7.0, 5.0, 7.5)
		# Stairs: T2 -> T1 and T1 -> ground in front of each gopura.
		var d1 := 40.0 if odd else 37.5
		var d0 := 61.0 if odd else 53.0
		U.stair(lm, "Stone", Vector3.UP * T1 + b * Vector3(0, 0, d1), b, 6.0, 12, 0.5, (T2 - T1) / 12.0)
		U.stair(lm, "Stone", b * Vector3(0, 0, d0), b, 6.0, 5, 0.45, T1 / 5.0)
	# The three pyramid steps and the stair up every face.
	var half: Array[float] = [30.0, 26.75, 23.5]
	for j in 3:
		var y0 := T2 + STEP * float(j)
		lm.box("Stone", Vector3(0, y0 + STEP * 0.5, 0), Vector3(half[j] * 2.0, STEP, half[j] * 2.0))
		lm.box("Trim", Vector3(0, y0 + STEP - 0.15, 0), Vector3(half[j] * 2.0 + 0.5, 0.3, half[j] * 2.0 + 0.5),
			Basis(), 0.0)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			U.stair(lm, "Stone", b * Vector3(0, y0, half[j]) , b, 7.0, 10, 0.325, STEP / 10.0)
	# Summit: the basement of the central tower, five unfinished towers.
	lm.box("Stone", Vector3(0, TOP + 2.0, 0), Vector3(17.0, 4.0, 17.0))
	lm.box("Trim", Vector3(0, TOP + 3.9, 0), Vector3(17.6, 0.3, 17.6), Basis(), 0.0)
	_bare_tower(lm, Vector3(0, TOP + 4.0, 0), 5.0, 19.5, 3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 15.0, TOP, sz * 15.0)
			lm.box("Stone", p + Vector3(0, 0.4, 0), Vector3(11.0, 0.8, 11.0))
			_bare_tower(lm, p + Vector3(0, 0.8, 0), 3.7, 14.2, 3)
	# A stretch of the causeway to the East Baray landing stage.
	lm.box("Laterite", Vector3(82.0, 0.4, 0), Vector3(36.0, 0.8, 9.0))
	lm.box("Trim", Vector3(82.0, 0.85, 0), Vector3(36.0, 0.1, 9.4), Basis(), 0.0)
	# Kneeling Nandi at the foot of the east stair.
	lm.box("Stone", Vector3(67.0, 1.3, 0), Vector3(2.4, 1.0, 1.2))
	lm.box("Stone", Vector3(66.2, 2.0, 0), Vector3(0.8, 0.8, 0.7))
	lm.commit(model)

## Unfinished tower of total height h, half-width hw at the foot: `tiers`
## receding storeys of plain redented walls with a dark doorway to every
## face on the lowest, the courses simply stopped at the top.
static func _bare_tower(lm: LandmarkMesh, base: Vector3, hw: float, h: float, tiers: int) -> void:
	var sh := h / float(tiers)
	for k in tiers:
		var w := hw * (1.0 - 0.14 * float(k))
		var wh := sh * 0.82
		var y := sh * float(k)
		lm.box("Stone", base + Vector3(0, y + wh * 0.5, 0), Vector3(w * 2.0, wh, w * 2.0))
		lm.box("Trim", base + Vector3(0, y + wh + sh * 0.09, 0), Vector3(w * 2.0 + 0.6, sh * 0.18, w * 2.0 + 0.6))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box("Stone", base + b * Vector3(0, y + wh * 0.5, w + 0.5), Vector3(w * 0.8, wh, 1.0), b)
			if k == 0:
				lm.box("Dark", base + b * Vector3(0, y + wh * 0.32, w + 1.01), Vector3(w * 0.34, wh * 0.62, 0.08),
					b, 0.0)
				# Doubled vestibule in front of the doorway.
				lm.box("Stone", base + b * Vector3(0, y + wh * 0.3, w + 1.6), Vector3(w * 0.55, wh * 0.6, 1.2), b)
			else:
				lm.box("Trim", base + b * Vector3(0, y + wh * 0.5, w + 1.03), Vector3(w * 0.5, wh * 0.6, 0.06),
					b, 0.0)
	# Ragged top: the last course laid only at the corners.
	var wt := hw * (1.0 - 0.14 * float(tiers - 1))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Trim", base + Vector3(sx * wt * 0.7, h - sh * 0.02, sz * wt * 0.7),
				Vector3(wt * 0.5, sh * 0.04, wt * 0.5), Basis(), 0.0)

## Plain gopura of three passages on a wall line (basis +Z out of the
## temple): a tall central block carrying a two-storey bare tower, lower
## gabled blocks to each side, a dark passage through each.
static func _gopura(lm: LandmarkMesh, base: Vector3, basis: Basis, span: float, depth: float,
		h: float, tower_h: float) -> void:
	var cw := span * 0.44
	var sw := (span - cw) * 0.5
	lm.box("Trim", base + basis * Vector3(0, 0.25, 0), Vector3(span + 1.0, 0.5, depth + 1.0), basis)
	lm.box("Stone", base + basis * Vector3(0, 0.5 + h * 0.5, 0), Vector3(cw, h, depth), basis)
	lm.box("Trim", base + basis * Vector3(0, 0.5 + h + 0.15, 0), Vector3(cw + 0.6, 0.3, depth + 0.6), basis)
	for s in [-1.0, 1.0]:
		var cx: float = s * (cw * 0.5 + sw * 0.5)
		lm.box("Stone", base + basis * Vector3(cx, 0.5 + h * 0.35, 0), Vector3(sw, h * 0.7, depth * 0.85), basis)
		lm.gable("Tile", base + basis * Vector3(cx, 0.5 + h * 0.7, 0), sw, depth * 0.85, h * 0.22, basis, 0.3,
			"Stone")
		for f in [-1.0, 1.0]:
			lm.box("Dark", base + basis * Vector3(cx, 0.5 + h * 0.28, f * depth * 0.425), Vector3(1.3, h * 0.46, 0.1),
				basis, 0.0)
			lm.box("Dark", base + basis * Vector3(0, 0.5 + h * 0.32, f * depth * 0.5), Vector3(2.2, h * 0.64, 0.1),
				basis, 0.0)
	_bare_tower(lm, base + basis * Vector3(0, 0.5 + h + 0.3, 0), cw * 0.38, tower_h, 2)
