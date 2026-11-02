class_name LandmarkSaoCities
extends RefCounted

## South American city icons in true metres: the Obelisco of Buenos
## Aires, Santiago's Gran Torre and the Teatro Amazonas of Manaus.

# --- Obelisco de Buenos Aires ---

## Plaza de la República obelisk: a 67.5 m white-stone shaft tapering
## from 6.8 m to 3.5 m square, a 5.5 m pyramidion, one small window per
## face just below it, on a low stepped base.
static func obelisco(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E6E1D6", 4.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#9A958C", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	lm.box("Base", Vector3(0, -0.5, 0), Vector3(15.0, 2.0, 15.0))
	lm.box("Base", Vector3(0, 0.8, 0), Vector3(9.6, 1.6, 9.6))
	lm.spire("Stone", Vector3(0, 1.0, 0), 3.4, 61.0, 1.75)
	lm.spire("Stone", Vector3(0, 62.0, 0), 1.75, 5.5, 0.0)
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Windows", rot * Vector3(0, 58.5, 1.9), Vector3(0.8, 1.4, 0.12), rot)
	lm.commit(model)

# --- Gran Torre Santiago ---

const TORRE_H := 300.0
## Shaft stacks as [top height, half width]: the tower steps in twice
## toward its flat crown.
const TORRE_STEPS := [[248.0, 24.0], [278.0, 20.0], [300.0, 15.0]]

## The 300 m glass tower of the Costanera Center (64 floors, steps in
## twice), its three lower sister towers and the mall podium.
static func gran_torre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#3E6E78"))
	lm.use("Frame", LandmarkMaterials.paint("#8E9AA0", 0.5, 0.5))
	lm.use("Mall", LandmarkMaterials.pbr("render", "#D4CFC4", 4.0))
	lm.use("Podium glass", LandmarkMaterials.glass("#2E3A40"))
	var y0 := 0.0
	for s in TORRE_STEPS:
		var h: float = float(s[0])
		var hw: float = float(s[1])
		lm.box("Glass", Vector3(0, (y0 + h) * 0.5, 0), Vector3(hw * 2.0, h - y0, hw * 2.0))
		var y := y0 + 4.69
		while y < h - 1.0:
			lm.box("Frame", Vector3(0, y, 0), Vector3(hw * 2.0 + 0.3, 0.8, hw * 2.0 + 0.3))
			y += 4.69
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.box("Frame", Vector3(sx * hw, (y0 + h) * 0.5, sz * hw), Vector3(1.4, h - y0, 1.4))
		y0 = h
	lm.box("Frame", Vector3(0, TORRE_H - 0.5, 0), Vector3(31.0, 1.0, 31.0))
	# Mall podium with its glazed storey band, and two sister towers.
	lm.box("Mall", Vector3(85.0, 12.0, 10.0), Vector3(110.0, 24.0, 76.0))
	lm.box("Podium glass", Vector3(85.0, 8.0, 48.15), Vector3(104.0, 5.0, 0.3))
	for t in [[66.0, 130.0], [100.0, 100.0]]:
		lm.box("Glass", Vector3(float(t[0]), float(t[1]) * 0.5, -52.0), Vector3(28.0, float(t[1]), 28.0))
		lm.box("Frame", Vector3(float(t[0]), float(t[1]) - 0.5, -52.0), Vector3(29.0, 1.0, 29.0))
	lm.commit(model)

# --- Teatro Amazonas ---

const OPERA_ROOF_Y := 20.0
const DOME_STEPS := 12

## The 1896 rubber-boom opera house in rose render: raised granite
## base, arcaded front facing south under a pedimented portico, and the
## dome (36 m) tiled in the Brazilian flag's green, yellow and blue.
static func teatro_amazonas(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#CB8B7A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E8DCC4", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#8E8578", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A5513A", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	lm.use("DomeG", LandmarkMaterials.pbr("terracotta", "#2E7D3F", 1.5, 0.35, 0.1))
	lm.use("DomeY", LandmarkMaterials.pbr("terracotta", "#E8C42A", 1.5, 0.35, 0.1))
	lm.use("DomeB", LandmarkMaterials.pbr("terracotta", "#2A4D9B", 1.5, 0.35, 0.1))
	lm.box("Base", Vector3(0, 1.0, 0), Vector3(60.0, 4.0, 54.0))
	lm.box("Wall", Vector3(0, 12.0, 0), Vector3(56.0, 16.0, 50.0))
	lm.box("Trim", Vector3(0, OPERA_ROOF_Y - 0.6, 0), Vector3(57.0, 1.2, 51.0))
	lm.gable("Roof", Vector3(0, OPERA_ROOF_Y, 0), 54.0, 48.0, 4.0, Basis(), 0.3, "Wall")
	# Front: two rows of windows and the portico.
	for k in 9:
		var x := -22.0 + 5.5 * float(k)
		lm.box("Windows", Vector3(x, 9.0, 25.05), Vector3(2.0, 4.5, 0.2))
		lm.box("Windows", Vector3(x, 15.5, 25.05), Vector3(2.0, 3.6, 0.2))
	lm.box("Trim", Vector3(0, 4.4, 30.0), Vector3(26.0, 0.8, 10.0))
	for k in 6:
		lm.frustum("Trim", Vector3(-10.0 + 4.0 * float(k), 4.8, 33.5), 0.7, 0.6, 12.0, 12)
	lm.box("Trim", Vector3(0, 17.8, 30.0), Vector3(26.0, 2.0, 10.0))
	lm.gable("Trim", Vector3(0, 18.8, 30.0), 26.0, 10.0, 2.6, Basis(), 0.2, "Trim")
	_dome(lm)
	lm.commit(model)

## Drum, banded dome, lantern and finial, rising to 36 m.
static func _dome(lm: LandmarkMesh) -> void:
	var base := Vector3(0, OPERA_ROOF_Y, 0)
	lm.frustum("Wall", base, 10.5, 10.5, 6.0, 24)
	lm.frustum("Trim", base + Vector3(0, 6.0, 0), 10.8, 10.8, 0.5, 24)
	var keys := ["DomeG", "DomeY", "DomeB"]
	var per := DOME_STEPS / 3
	for band in 3:
		var prof := PackedVector2Array()
		for i in range(band * per, (band + 1) * per + 1):
			var a := PI * 0.5 * float(i) / float(DOME_STEPS)
			prof.append(Vector2(10.3 * cos(a), 7.2 * sin(a)))
		lm.lathe(keys[band], base + Vector3(0, 6.5, 0), prof, 24)
	var top := base + Vector3(0, 13.7, 0)
	lm.frustum("Trim", top, 1.8, 1.4, 1.8, 12)
	lm.spire("Trim", top + Vector3(0, 1.8, 0), 1.0, 0.5, 0.0, 8)
