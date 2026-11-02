class_name LandmarkItlSkyline
extends RefCounted

## San Gimignano's tower skyline and the Two Towers of Bologna in true
## metres: slender medieval tower-houses of stone and brick, their
## crowns corbelled and battlemented, the Bologna pair leaning.

# --- San Gimignano --------------------------------------------------------

## [x east, z south (metres from the Torre Grossa), half-width, height,
## footprint angle cw from east in degrees, battlemented].
const SG_TOWERS := [
	[0.0, 0.0, 4.5, 54.0, 7.0, true],       # Torre Grossa (Palazzo Comunale)
	[47.7, -24.3, 2.3, 51.0, 67.0, true],   # Torre Rognosa (Podesta)
	[41.2, -36.4, 2.6, 47.0, 150.0, false], # Torre Chigi
	[28.3, -59.7, 2.7, 38.0, 153.0, false], # Torre Pettini
	[82.4, 5.5, 3.4, 36.0, 179.0, false],   # Torre del Diavolo
	[4.8, 64.2, 3.5, 40.0, 109.0, false],   # Torre dei Cugnanesi
	[7.0, 95.1, 3.3, 33.0, 112.0, false],   # Torre Campatelli
]

## Origin at the foot of the Torre Grossa in the true compass frame
## (+X east, -Z north): the 54 m Grossa on the Palazzo Comunale, the
## Podesta palace with the 51 m Rognosa, the Romanesque Collegiata
## and the surrounding stone tower-houses, each a square shaft of
## weathered stone with arrow slits, a corbelled top and, on the civic
## towers, merlons.
static func san_gimignano(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B09A74", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CDBE9C", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#40382E", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A9573B", 2.5))
	for t in SG_TOWERS:
		_tower(lm, Vector3(t[0], 0, t[1]), t[2], t[3], -deg_to_rad(t[4]), t[5])
	# Palazzo Comunale at the foot of the Grossa and the Podesta palace.
	var rc := -deg_to_rad(7.0)
	var bc := Basis(Vector3.UP, rc)
	lm.box("Stone", Vector3(-3.0, 12.5, 14.0), Vector3(30.0, 25.0, 14.0), bc)
	for sgn in [-1.0, 1.0]:
		var out: Vector3 = bc * Vector3(0, 0, sgn)
		var base := Vector3(-3.0, 0, 14.0) + out * 7.05
		SEuUtil.face_row(lm, "Shadow", base, bc * Vector3.RIGHT, out, 9.0, 4, 6.5, 1.6, 3.6, true)
		SEuUtil.face_row(lm, "Shadow", base, bc * Vector3.RIGHT, out, 17.0, 4, 6.5, 1.6, 3.6, true)
		SEuUtil.face_row(lm, "Shadow", base, bc * Vector3.RIGHT, out, 0.0, 3, 8.0, 3.0, 4.6, true)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", Vector3(-3.0, 25.0, 14.0), 15.0, 7.0, rc, 0.8, 1.2, 1.8, false, 1.4)
	var rp := -deg_to_rad(76.0)
	var bp := Basis(Vector3.UP, rp)
	lm.box("Stone", Vector3(52.5, 8.5, -21.0), Vector3(20.0, 17.0, 18.0), bp)
	SEuUtil.face_row(lm, "Shadow", Vector3(52.5, 0, -21.0) + bp * Vector3(0, 0, 9.05), bp * Vector3.RIGHT, bp * Vector3(0, 0, 1),
		0.0, 3, 5.8, 3.6, 5.8, true)
	SEuUtil.face_row(lm, "Shadow", Vector3(52.5, 0, -21.0) + bp * Vector3(0, 0, 9.05), bp * Vector3.RIGHT, bp * Vector3(0, 0, 1),
		9.5, 3, 5.8, 1.5, 3.4, true)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", Vector3(52.5, 17.0, -21.0), 10.0, 9.0, rp, 0.6, 1.0, 1.5, false, 1.3)
	_collegiata(lm, Vector3(-27.5, 0, -27.6), deg_to_rad(72.0))
	lm.commit(model)

## One tower-house: stone shaft, arrow slits and a pair of paired
## windows near the top, battlemented crown or a plain corbelled slab.
static func _tower(lm: LandmarkMesh, c: Vector3, hw: float, h: float, rot: float, merlons: bool) -> void:
	var rows := []
	var y := 7.0
	while y < h - 9.0:
		rows.append([y, 0.55, 1.9, 1, 0.0, false])
		y += 7.5
	rows.append([h - 10.0, 0.9, 2.8, 2, hw * 0.9, false])
	var base_y := h - 3.2 if merlons else h - 1.0
	LandmarkItlUtil.tower(lm, "Stone", "Shadow", c, hw, c + Vector3(0, base_y, 0), hw * 0.93, rot, rows)
	if merlons:
		LandmarkItlUtil.gallery(lm, "Stone", "Shadow", c + Vector3(0, base_y, 0), hw * 0.93, hw * 0.93, rot,
			0.7, 1.4, 1.5, false, 1.1)
	else:
		lm.box("Trim", c + Vector3(0, h - 0.5, 0), Vector3(hw * 2.0 + 0.9, 1.0, hw * 2.0 + 0.9), Basis(Vector3.UP, rot))

## The Collegiata: plain Romanesque basilica on its steps, facade turned
## to the piazza (local +Z), nave under a tiled gable, round apse behind.
static func _collegiata(lm: LandmarkMesh, c: Vector3, rot: float) -> void:
	var b := Basis(Vector3.UP, rot)
	var fwd := b * Vector3(0, 0, 1)
	lm.box("Trim", c + b * Vector3(0, 8.5, 0), Vector3(17.0, 17.0, 40.0), b)
	lm.gable("Tile", c + b * Vector3(0, 17.0, 0), 17.0, 40.0, 4.6, b, 0.5, "Trim")
	lm.frustum("Trim", c + b * Vector3(0, 0, -20.0), 6.5, 6.5, 14.0, 12)
	lm.spire("Tile", c + b * Vector3(0, 14.0, -20.0), 6.6, 3.0, 0.0, 8)
	SEuUtil.steps_up(lm, "Trim", c + fwd * 20.0, fwd, 9.0, 0.9, 0.5, 7)
	SEuUtil.opening(lm, "Shadow", c + fwd * 20.06 + Vector3(0, 3.5, 0), b * Vector3.RIGHT, Vector3.UP, 3.0, 5.2)
	lm.disc("Shadow", c + fwd * 20.06 + Vector3(0, 12.0, 0), fwd, 1.3, 14)
	for sgn in [-1.0, 1.0]:
		var out: Vector3 = b * Vector3(sgn, 0, 0)
		SEuUtil.face_row(lm, "Shadow", c + out * 8.55, b * Vector3(0, 0, 1), out, 6.0, 6, 5.5, 1.0, 5.0, false)

# --- Bologna --------------------------------------------------------------

const ASINELLI_H := 97.2
const GARISENDA_H := 47.5

## Origin at the Asinelli in the true compass frame (+X east, -Z north):
## the 97.2 m Asinelli, a brick shaft on a stone base, leaning 2.2 m,
## topped by an overhanging battlemented crown and a small brick cell
## under a low pyramid; 19 m to the north the 47.5 m Garisenda, shorter
## and stouter, leaning 3.2 m, its top cut off at the corbel crown.
static func bologna(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A4533A", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBD9F", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C3229", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9C4E36", 2.0))
	_leaning_tower(lm, Vector3.ZERO, -deg_to_rad(21.0), Vector2(-1.5, -1.6), ASINELLI_H, 9.0, 4.9, 4.2, 3.65,
		[14.0, 26.0, 38.0, 50.0, 62.0, 72.0], 88.0, 1.6)
	_leaning_tower(lm, Vector3(2.4, 0, -18.8), -deg_to_rad(1.0), Vector2(3.0, -1.1), GARISENDA_H, 8.5, 4.9, 4.3, 3.9,
		[14.0, 22.0, 30.0, 38.0], 44.7, 1.1)
	# Asinelli's crown cell and cap sit inside the merlons.
	var lean := Vector2(-1.5, -1.6) / ASINELLI_H
	var top := Vector3(lean.x * 91.0, 91.0, lean.y * 91.0)
	LandmarkItlUtil.tower(lm, "Brick", "Shadow", top, 2.6, top + Vector3(lean.x * 4.0, 4.0, lean.y * 4.0), 2.6,
		-deg_to_rad(21.0), [[92.8, 0.9, 1.8, 2, 2.2, false]])
	var cap := Vector3(lean.x * 95.0, 95.0, lean.y * 95.0)
	lm.spire("Roof", cap, 3.0, 2.2)
	lm.commit(model)

## A leaning tower: stone base to `base_h`, brick shaft with slit rows
## to the crown at `crown_y`, corbelled gallery with `mer_h` merlons on
## top. `lean` is the horizontal offset of the top over the full height `h`.
static func _leaning_tower(lm: LandmarkMesh, c: Vector3, rot: float, lean: Vector2, h: float,
		base_h: float, base_hw: float, hw0: float, hw1: float, slit_ys: Array, crown_y: float, mer_h: float) -> void:
	var k := lean / h
	var p0 := c + Vector3(k.x * -2.0, -2.0, k.y * -2.0)
	var pb := c + Vector3(k.x * base_h, base_h, k.y * base_h)
	var rows_base := [[0.4, 2.8, 5.4, 1, 0.0, true]]
	LandmarkItlUtil.tower(lm, "Stone", "Shadow", p0, base_hw + 0.1, pb, base_hw - 0.1, rot, rows_base)
	var rows := []
	for y in slit_ys:
		rows.append([y, 0.7, 2.4, 1, 0.0, false])
	rows.append([crown_y - 8.0, 0.9, 2.6, 2, 1.6, false])
	var pc := c + Vector3(k.x * crown_y, crown_y, k.y * crown_y)
	LandmarkItlUtil.tower(lm, "Brick", "Shadow", pb, hw0, pc, hw1, rot, rows)
	LandmarkItlUtil.gallery(lm, "Stone", "Shadow", pc, hw1, hw1, rot, 1.1, 2.4, mer_h, false, 1.2)
