class_name LandmarkSaoAncient
extends RefCounted

## Pre-Columbian monuments in true metres: the Inca citadel of Machu
## Picchu and the fifteen moai of Ahu Tongariki on Rapa Nui.

# --- Machu Picchu ---

const PLAZA_Y := 16.2
const TERRACES := 9
const TERRACE_RISE := 1.8
const TERRACE_DEPTH := 6.5

## [x, z, width, length] of the thatched stone houses on the upper town.
const HOUSES := [[-40.0, 4.0, 6.0, 12.0], [-32.0, 4.0, 6.0, 12.0], [-24.0, 4.0, 6.0, 12.0],
	[28.0, 2.0, 6.0, 12.0], [36.0, 2.0, 6.0, 12.0], [44.0, 2.0, 6.0, 12.0],
	[-40.0, -14.0, 7.0, 10.0], [-30.0, -14.0, 7.0, 10.0], [38.0, -14.0, 7.0, 10.0],
	[46.0, -14.0, 7.0, 10.0], [-18.0, -20.0, 6.0, 8.0], [14.0, -8.0, 5.0, 9.0]]

## Compact citadel: nine agricultural terraces climbing 16 m to the
## upper town (foundations sunk below y = 0), twelve thatched houses
## around the lawn Main Plaza, the round Temple of the Sun and the
## stepped Intihuatana hill with its carved stone, 27 m above the foot.
static func machu_picchu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C8578", 3.0))
	lm.use("Grass", LandmarkMaterials.pbr("lawn", "#6E8A4A", 4.0))
	lm.use("Thatch", LandmarkMaterials.pbr("wood", "#A68E5A", 2.0))
	_terraces(lm)
	for h in HOUSES:
		_house(lm, float(h[0]), float(h[1]), float(h[2]), float(h[3]))
	# Temple of the Sun: curved ashlar tower under a conical thatch roof.
	var temple := Vector3(30.0, PLAZA_Y + 0.15, -24.0)
	lm.frustum("Stone", temple, 4.6, 4.2, 5.0, 16)
	lm.frustum("Thatch", temple + Vector3(0, 5.0, 0), 5.2, 0.0, 2.8, 16)
	_intihuatana(lm, Vector3(-8.0, PLAZA_Y + 0.15, -34.0))
	lm.commit(model)

## Terrace stack: each step a stone block with a grass tread, then the
## plaza platform behind the last one.
static func _terraces(lm: LandmarkMesh) -> void:
	for i in TERRACES:
		var top := TERRACE_RISE * float(i + 1)
		var z_front := 70.0 - TERRACE_DEPTH * float(i)
		var w := 104.0 - 3.0 * float(i)
		lm.box("Stone", Vector3(0, (top - 3.0) * 0.5, (z_front - 40.0) * 0.5),
			Vector3(w, top + 3.0, z_front + 40.0))
		lm.box("Grass", Vector3(0, top + 0.07, z_front - TERRACE_DEPTH * 0.5),
			Vector3(w - 1.0, 0.14, TERRACE_DEPTH - 0.6))
	lm.box("Stone", Vector3(0, (PLAZA_Y - 3.0) * 0.5, -14.0), Vector3(96.0, PLAZA_Y + 3.0, 52.0))
	lm.box("Grass", Vector3(0, PLAZA_Y + 0.07, -14.0), Vector3(95.0, 0.14, 51.0))

## Rectangular house: ashlar walls and a thatched gable ridged along Z.
static func _house(lm: LandmarkMesh, x: float, z: float, w: float, l: float) -> void:
	var y := PLAZA_Y + 0.15
	lm.box("Stone", Vector3(x, y + 1.4, z), Vector3(w, 2.8, l))
	lm.gable("Thatch", Vector3(x, y + 2.8, z), w, l, 2.4, Basis(), 0.5, "Stone")

## Stepped hill of six terraces topped by the Intihuatana gnomon.
static func _intihuatana(lm: LandmarkMesh, base: Vector3) -> void:
	for k in 6:
		var f := float(k) / 5.0
		lm.box("Stone", base + Vector3(0, 1.6 * float(k) + 0.8, 0),
			Vector3(lerpf(34.0, 9.0, f), 1.6, lerpf(26.0, 7.0, f)))
	var top := base + Vector3(0, 9.6, 0)
	lm.box("Stone", top + Vector3(0, 0.55, 0), Vector3(0.9, 1.1, 0.9), Basis(Vector3.UP, 0.4))

# --- Ahu Tongariki ---

const AHU_H := 3.2
## Heights of the fifteen moai, west to east.
const MOAI_H := [5.2, 5.6, 4.8, 5.9, 5.0, 6.0, 5.4, 5.8, 5.1, 5.6, 4.9, 5.7, 5.3, 5.5, 4.6]
const MOAI_SPACING := 6.0

## The restored 100 m ahu: dry-stone platform with a rubble ramp on the
## inland (north) side and fifteen tuff moai standing side by side,
## looking inland (-Z); one wears its red scoria topknot.
static func moai(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Ahu", LandmarkMaterials.pbr("rock", "#4F4A44", 2.5))
	lm.use("Ramp", LandmarkMaterials.pbr("gravel", "#8F8271", 3.0))
	lm.use("Moai", LandmarkMaterials.pbr("stone", "#6B6459", 1.5))
	lm.use("Pukao", LandmarkMaterials.pbr("terracotta", "#8A4630", 1.0))
	lm.box("Ahu", Vector3(0, (AHU_H - 3.0) * 0.5, 0), Vector3(104.0, AHU_H + 3.0, 10.0))
	lm.box("Ahu", Vector3(0, (AHU_H - 3.0) * 0.5, 0), Vector3(40.0, AHU_H + 3.0, 22.0))
	lm.quad("Ramp", Vector3(-42, 0.05, -44), Vector3(42, 0.05, -44), Vector3(42, 1.4, -5),
		Vector3(-42, 1.4, -5), Vector3(0, 1.0, -0.03).normalized())
	for i in MOAI_H.size():
		var x := (float(i) - 7.0) * MOAI_SPACING
		_moai(lm, x, float(MOAI_H[i]), i == 12)
	lm.commit(model)

## One statue of height h standing on the platform at x: tapered torso,
## long block head with brow, nose, chin and ears, arms carved low.
static func _moai(lm: LandmarkMesh, x: float, h: float, topknot: bool) -> void:
	var y0 := AHU_H
	lm.frustum("Moai", Vector3(x, y0, 0), 0.325 * h, 0.29 * h, 0.55 * h, 4, PI * 0.25, 1.0, 0.5)
	lm.box("Moai", Vector3(x, y0 + 0.775 * h, 0), Vector3(0.30 * h, 0.45 * h, 0.20 * h))
	lm.box("Moai", Vector3(x, y0 + 0.80 * h, -0.115 * h), Vector3(0.30 * h, 0.05 * h, 0.04 * h))
	lm.box("Moai", Vector3(x, y0 + 0.72 * h, -0.115 * h), Vector3(0.06 * h, 0.22 * h, 0.06 * h))
	lm.box("Moai", Vector3(x, y0 + 0.60 * h, -0.10 * h), Vector3(0.24 * h, 0.06 * h, 0.06 * h))
	for s in [-1.0, 1.0]:
		lm.box("Moai", Vector3(x + s * 0.17 * h, y0 + 0.74 * h, 0), Vector3(0.04 * h, 0.2 * h, 0.05 * h))
		lm.box("Moai", Vector3(x + s * 0.20 * h, y0 + 0.35 * h, -0.12 * h), Vector3(0.05 * h, 0.3 * h, 0.03 * h))
	if topknot:
		lm.frustum("Pukao", Vector3(x, y0 + h, 0), 0.17 * h, 0.16 * h, 0.12 * h, 14)
