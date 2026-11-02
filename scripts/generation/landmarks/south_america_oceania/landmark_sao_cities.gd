class_name LandmarkSaoCities
extends RefCounted

## South American city icons in true metres: the Obelisco of Buenos
## Aires, Santiago's Gran Torre and the Teatro Amazonas of Manaus.

# --- Obelisco de Buenos Aires ---

const OBELISK_BASE := 0.9
const OBELISK_SHAFT_TOP := 63.0
const OBELISK_H := 67.5

## Alberto Prebisch's obelisk in the Plaza de la República (1936): a
## 63 m reinforced-concrete shaft from 6.8 m square to 3.5 m, its
## pyramidion rising to a blunt 0.4 m tip and a lightning rod at
## 67.5 m. One door on the west face, four small windows at the top,
## the sonnet plaque on the south face, on a low two-step granite base.
static func obelisco(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E6E1D6", 4.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#9A958C", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	lm.box("Base", Vector3(0, 0.25, 0), Vector3(15.0, 0.5, 15.0))
	lm.box("Base", Vector3(0, 0.7, 0), Vector3(9.6, 0.4, 9.6))
	# Granite kerb and four bollard posts at the corners of the base.
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Base", rot * Vector3(0, 0.62, -7.2), Vector3(14.4, 0.25, 0.6), rot)
		lm.lathe("Base", rot * Vector3(6.6, 0.5, -6.6), PackedVector2Array([Vector2(0.25, 0.0),
			Vector2(0.22, 0.8), Vector2(0.3, 0.9), Vector2(0.0, 1.05)]), 8)
	lm.spire("Stone", Vector3(0, OBELISK_BASE, 0), 3.4, OBELISK_SHAFT_TOP - OBELISK_BASE, 1.75)
	# Plinth course at the foot and a thin band where the apex starts.
	lm.spire("Stone", Vector3(0, OBELISK_BASE, 0), 3.55, 1.2, 3.5)
	lm.spire("Stone", Vector3(0, OBELISK_SHAFT_TOP - 0.3, 0), 1.82, 0.3, 1.8)
	lm.spire("Stone", Vector3(0, OBELISK_SHAFT_TOP, 0), 1.75, OBELISK_H - 0.5 - OBELISK_SHAFT_TOP, 0.2)
	lm.box("Stone", Vector3(0, OBELISK_H - 0.4, 0), Vector3(0.4, 0.2, 0.4), Basis(), 0.0)
	lm.frustum("Base", Vector3(0, OBELISK_H - 0.3, 0), 0.03, 0.01, 0.3, 4)
	# The four windows, one per face just under the apex.
	var slope := (3.4 - 1.75) / (OBELISK_SHAFT_TOP - OBELISK_BASE)
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		var y := 60.6
		var hw := 3.4 - slope * (y - OBELISK_BASE)
		var n: Vector3 = rot * Vector3(0, 0, -1)
		lm.box("Windows", rot * Vector3(0, y, -hw - 0.02), Vector3(0.7, 1.2, 0.05), rot, 0.0)
		lm.box("Stone", rot * Vector3(0, y - 0.7, -hw - 0.1), Vector3(1.1, 0.15, 0.2), rot, 0.0)
		lm.box("Stone", rot * Vector3(0, y + 0.7, -hw - 0.08), Vector3(1.0, 0.15, 0.16), rot, 0.0)
		for s in [-1.0, 1.0]:
			lm.box("Stone", rot * Vector3(float(s) * 0.45, y, -hw - 0.06), Vector3(0.15, 1.3, 0.12), rot, 0.0)
		# Course lines every 2 m, the joints scored into the 1943 render.
		for k in 30:
			var cy := OBELISK_BASE + 2.0 + 2.0 * float(k)
			var chw := 3.4 - slope * (cy - OBELISK_BASE)
			lm.box("Base", rot * Vector3(0, cy, -chw - 0.005), Vector3(chw * 2.0, 0.04, 0.02), rot, 0.0)
		if n.dot(Vector3(0, 0, 1)) > 0.9:
			lm.box("Base", rot * Vector3(0, 2.6, -3.38), Vector3(1.6, 1.0, 0.06), rot, 0.0)
	# West door with its frame and lintel.
	var dhw := 3.4 - slope * 1.6
	lm.box("Windows", Vector3(-dhw - 0.02, OBELISK_BASE + 1.15, 0), Vector3(0.05, 2.3, 1.3), Basis(), 0.0)
	lm.box("Stone", Vector3(-dhw - 0.1, OBELISK_BASE + 2.45, 0), Vector3(0.2, 0.25, 1.9), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(-dhw - 0.08, OBELISK_BASE + 1.2, float(s) * 0.8), Vector3(0.16, 2.4, 0.25), Basis(), 0.0)
	lm.commit(model)

# --- Gran Torre Santiago ---

const TORRE_H := 300.0
const TORRE_ROOF := 261.0
const TORRE_FLOORS := 62
## Plan half width at the foot and at the roof: the obelisk-like taper.
const TORRE_HW0 := 23.5
const TORRE_HW1 := 18.0
## How far each face folds out to its central ridge.
const TORRE_FOLD := 1.6
const TORRE_CHAMFER := 2.2

## César Pelli's 300 m tower of the Costanera Center (2012): 62 floors
## to 261 m in a tapering obelisk of faceted glass whose four faces each
## fold out to a ridge up their centreline, chamfered corners, and the
## open glass crown with its exposed steel frame rising another 39 m.
## Beside it the mall podium and two lower sister towers.
static func gran_torre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#3E6E78"))
	lm.use("Frame", LandmarkMaterials.paint("#8E9AA0", 0.5, 0.5))
	lm.use("Mall", LandmarkMaterials.pbr("render", "#D4CFC4", 4.0))
	lm.use("Podium glass", LandmarkMaterials.glass("#2E3A40"))
	_torre_shell(lm)
	_torre_crown(lm)
	_torre_podium(lm)
	for t in [[66.0, 130.0], [100.0, 100.0]]:
		_sister(lm, Vector3(float(t[0]), 0, -52.0), float(t[1]))
	lm.commit(model)

## Plan outline at height y: 12 points (a chamfered square with each
## face folded out to a ridge), counter-clockwise from the +X ridge.
static func _torre_plan(y: float) -> PackedVector3Array:
	var t := clampf(y / TORRE_ROOF, 0.0, 1.0)
	var hw := lerpf(TORRE_HW0, TORRE_HW1, t)
	var pts := PackedVector3Array()
	for side in 4:
		var rot := Basis(Vector3.UP, -PI * 0.5 * float(side))
		pts.append(rot * Vector3(hw + TORRE_FOLD, y, 0))
		pts.append(rot * Vector3(hw, y, hw - TORRE_CHAMFER))
		pts.append(rot * Vector3(hw - TORRE_CHAMFER, y, hw))
	return pts

## Glass facets from the ground to the roof, a spandrel ring at every
## floor and mullions up every facet.
static func _torre_shell(lm: LandmarkMesh) -> void:
	var p0 := _torre_plan(0.0)
	var p1 := _torre_plan(TORRE_ROOF)
	for i in 12:
		var j := (i + 1) % 12
		lm.quad("Glass", p0[i], p0[j], p1[j], p1[i])
		# Mullions: five per folded half face, one on each chamfer.
		var n := 1 if i % 3 == 1 else 5
		for k in n:
			var f := (float(k) + 0.5) / float(n)
			var a := p0[i].lerp(p0[j], f)
			var b := p1[i].lerp(p1[j], f)
			var out := (a - Vector3(0, a.y, 0)).normalized()
			lm.beam("Frame", a + out * 0.12, b + out * 0.12, 0.25, 0.3, (p0[j] - p0[i]).normalized())
	var storey := TORRE_ROOF / float(TORRE_FLOORS)
	for k in TORRE_FLOORS + 1:
		var ring := _torre_plan(maxf(storey * float(k), 0.35))
		for i in 12:
			var a := ring[i]
			var b := ring[(i + 1) % 12]
			var mid := (a + b) * 0.5
			var out := Vector3(mid.x, 0, mid.z).normalized()
			lm.beam("Frame", a + out * 0.15, b + out * 0.15, 0.6, 0.35, Vector3.UP)
	lm.lathe("Mall", Vector3(0, 0, 0), PackedVector2Array([Vector2(TORRE_HW0 + 3.0, 0.0),
		Vector2(TORRE_HW0 + 3.0, 0.6), Vector2(0.0, 0.6)]), 12, 1.0, 1.0, PI / 12.0)

## The crown: glass walls climbing past the roof, highest at the four
## ridges (300 m) and lower at the corners, open at the top over a
## braced steel frame of rings and diagonals.
static func _torre_crown(lm: LandmarkMesh) -> void:
	var base := _torre_plan(TORRE_ROOF)
	var tops := PackedVector3Array()
	for i in 12:
		var p := base[i]
		var shrink := 0.96
		var h := TORRE_H if i % 3 == 0 else TORRE_H - 9.0
		tops.append(Vector3(p.x * shrink, h, p.z * shrink))
	for i in 12:
		var j := (i + 1) % 12
		lm.quad("Glass", base[i], base[j], tops[j], tops[i])
		# Inner face so the open crown reads from above and inside.
		lm.quad("Glass", base[j] * Vector3(0.99, 1, 0.99), base[i] * Vector3(0.99, 1, 0.99),
			tops[i] * Vector3(0.99, 1, 0.99), tops[j] * Vector3(0.99, 1, 0.99), -(base[i] + base[j]) * Vector3(1, 0, 1))
		lm.beam("Frame", tops[i], tops[j], 0.5, 0.5)
		lm.beam("Frame", base[i], tops[i], 0.5, 0.5)
	lm.poly_prism("Frame", _flat(base, 0.95), TORRE_ROOF - 1.0, TORRE_ROOF)
	# Inner steel frame: rings and X-bracing between four corner masts.
	for k in 4:
		var y := TORRE_ROOF + 9.0 * float(k + 1)
		var r := lerpf(TORRE_HW1 - 3.0, TORRE_HW1 - 5.0, float(k) / 3.0)
		for side in 4:
			var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
			var a: Vector3 = rot * Vector3(r, y, -r)
			var b: Vector3 = rot * Vector3(r, y, r)
			lm.beam("Frame", a, b, 0.6, 0.6)
			var a0: Vector3 = rot * Vector3(r, y - 9.0, -r)
			var b0: Vector3 = rot * Vector3(r, y - 9.0, r)
			lm.beam("Frame", a0, b, 0.4, 0.4)
			lm.beam("Frame", b0, a, 0.4, 0.4)
			lm.beam("Frame", a0, a, 0.8, 0.8)
	lm.frustum("Frame", Vector3(0, TORRE_ROOF, 0), 1.0, 0.4, TORRE_H - TORRE_ROOF - 4.0, 8)

static func _flat(pts: PackedVector3Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(p.x * k, p.z * k))
	return out

## The mall podium: six storeys with glazed bands, a rooftop terrace
## edge and the entrance canopy.
static func _torre_podium(lm: LandmarkMesh) -> void:
	var c := Vector3(85.0, 0, 10.0)
	lm.box("Mall", c + Vector3(0, 12.0, 0), Vector3(110.0, 24.0, 76.0))
	for k in 5:
		var y := 3.5 + 4.2 * float(k)
		lm.box("Podium glass", c + Vector3(0, y, 38.1), Vector3(104.0, 2.2, 0.3), Basis(), 0.0)
		lm.box("Podium glass", c + Vector3(-55.1, y, 0), Vector3(0.3, 2.2, 70.0), Basis(), 0.0)
	for k in 27:
		var x := -52.0 + 4.0 * float(k)
		lm.box("Mall", c + Vector3(x, 12.0, 38.3), Vector3(0.6, 22.0, 0.6))
	lm.box("Mall", c + Vector3(0, 24.6, 0), Vector3(111.0, 1.2, 77.0))
	lm.box("Mall", c + Vector3(-30.0, 6.0, 42.0), Vector3(24.0, 0.6, 8.0))
	lm.box("Podium glass", c + Vector3(-30.0, 2.8, 38.4), Vector3(18.0, 5.4, 0.3), Basis(), 0.0)

## A sister office tower: glass box, floor spandrels, corner piers and
## a crown band.
static func _sister(lm: LandmarkMesh, c: Vector3, h: float) -> void:
	lm.box("Glass", c + Vector3(0, h * 0.5, 0), Vector3(28.0, h, 28.0), Basis(), 0.0)
	var y := 4.1
	while y < h - 2.0:
		lm.box("Frame", c + Vector3(0, y, 0), Vector3(28.4, 0.6, 28.4), Basis(), 0.0)
		y += 4.1
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Frame", c + Vector3(float(sx) * 13.6, h * 0.5, float(sz) * 13.6), Vector3(1.2, h, 1.2))
	lm.box("Frame", c + Vector3(0, h - 0.5, 0), Vector3(29.0, 1.0, 29.0))

# --- Teatro Amazonas ---

const OPERA_ROOF_Y := 20.0
const OPERA_FRONT_Z := 25.0
const OPERA_BACK_Z := -38.0
const OPERA_HW := 26.0
const DOME_Z := 0.0
const PODIUM_Y := 2.8

## The 1896 rubber-boom opera house in rose render on a raised granite
## base, facing the Praça São Sebastião (+Z): the double flight of steps,
## a projecting portico of five arches under a loggia of paired
## Corinthian columns of Carrara marble, a curved pediment, two storeys
## of framed windows between pilasters, the cornice and balustrade, the
## Alsace-tiled roof and the dome (36 m) of 36,000 glazed tiles in the
## Brazilian flag's green, yellow and blue.
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
	LandmarkSaoTeatro.build(lm)
	lm.commit(model)
