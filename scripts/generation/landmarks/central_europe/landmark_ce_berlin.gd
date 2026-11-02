class_name LandmarkCeBerlin
extends RefCounted

## Berlin icons in true metres: the Brandenburg Gate (sandstone Doric
## gate along X, quadriga facing east, 26 m), the Reichstag (stone block
## with the west portico, four corner towers and Foster's glass dome,
## 47 m) and the Fernsehturm (concrete shaft, steel-faceted sphere and
## red-white antenna, 368 m).

# --- Brandenburg Gate ---

const GATE_TOP := 26.0
const GATE_HALF := 32.75
## Passages across the gate (centre z, width), north to south.
const PASSAGES := [[-22.4, 3.8], [-11.2, 3.8], [0.0, 5.6], [11.2, 3.8], [22.4, 3.8]]

static func gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C4B491", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#8E8672", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6FA08B", 2.0, 0.5, 0.35))
	lm.box("Dark", Vector3(0, 0.6, 0), Vector3(14.0, 1.2, GATE_HALF * 2.0 + 2.0))
	# Wall piers between the five passages, then the lintel course.
	var edges: Array[float] = [-GATE_HALF]
	for p in PASSAGES:
		edges.append(float(p[0]) - float(p[1]) * 0.5)
		edges.append(float(p[0]) + float(p[1]) * 0.5)
	edges.append(GATE_HALF)
	for i in range(0, edges.size(), 2):
		var z0: float = edges[i]
		var z1: float = edges[i + 1]
		lm.box("Stone", Vector3(0, 6.3, (z0 + z1) * 0.5), Vector3(10.0, 10.2, z1 - z0))
	lm.box("Stone", Vector3(0, 12.0, 0), Vector3(10.0, 2.8, GATE_HALF * 2.0))
	# Twelve Doric columns, six a side, in front of the piers.
	for sx in [-1.0, 1.0]:
		for i in 6:
			var z: float = (edges[i * 2] + edges[i * 2 + 1]) * 0.5
			lm.frustum("Stone", Vector3(sx * 5.9, 1.2, z), 0.95, 0.8, 12.0, 14)
			lm.box("Stone", Vector3(sx * 5.9, 13.4, z), Vector3(2.2, 0.5, 2.2))
	lm.box("Stone", Vector3(0, 15.1, 0), Vector3(13.4, 2.3, GATE_HALF * 2.0 + 1.0))
	lm.box("Dark", Vector3(0, 15.1, 0), Vector3(13.7, 0.35, GATE_HALF * 2.0 + 1.3))
	lm.box("Stone", Vector3(0, 18.4, 0), Vector3(9.0, 4.3, GATE_HALF * 2.0 - 8.0))
	lm.box("Stone", Vector3(0, 20.8, 0), Vector3(10.0, 0.6, GATE_HALF * 2.0 - 7.0))
	# Guard houses: low Doric porticos at both ends of the gate.
	for sz in [-1.0, 1.0]:
		var gz: float = sz * (GATE_HALF + 7.0)
		lm.box("Stone", Vector3(0, 4.5, gz), Vector3(11.0, 9.0, 12.0))
		lm.gable("Dark", Vector3(0, 9.0, gz), 12.0, 11.0, 2.6, Basis(Vector3.UP, PI * 0.5), 0.5, "Stone")
		LandmarkCeParts.colonnade(lm, "Stone", Vector3(6.1, 0.0, gz), Vector3(0, 0, 1), 4, 3.4, 0.5, 0.42, 8.4, 10)
	_quadriga(lm, Vector3(0, 21.1, 0))
	lm.commit(model)

## Victory driving four horses, facing east (+X); top at GATE_TOP.
static func _quadriga(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Copper", base + Vector3(-0.3, 0.9, 0), Vector3(3.6, 1.8, 3.0))
	lm.box("Copper", base + Vector3(-1.9, 1.9, 0), Vector3(0.4, 1.8, 3.2))
	for k in 4:
		var z := (float(k) - 1.5) * 1.4
		var hp := base + Vector3(3.4, 0, z)
		lm.beam("Copper", hp + Vector3(-1.2, 1.5, 0), hp + Vector3(1.0, 1.8, 0), 0.95, 0.8)
		lm.beam("Copper", hp + Vector3(1.0, 1.8, 0), hp + Vector3(1.8, 3.1, 0), 0.6, 0.5)
		lm.beam("Copper", hp + Vector3(1.8, 3.1, 0), hp + Vector3(2.6, 2.6, 0), 0.4, 0.4)
		for lx in [-1.0, 1.0]:
			for lz in [-0.25, 0.25]:
				lm.beam("Copper", hp + Vector3(lx * 0.9 + 0.1, 1.2, lz), hp + Vector3(lx * 1.0 + 0.3, 0.0, lz), 0.2, 0.2)
	LandmarkKits.statue_figure(lm, "Copper", base + Vector3(-0.4, 1.8, 0), 3.1, true)
	lm.beam("Copper", base + Vector3(-0.3, 2.9, 0), base + Vector3(-0.3, GATE_TOP - base.y, 0), 0.14, 0.14)

# --- Reichstag ---

const RS_HALF := Vector2(48.5, 68.5)
const RS_EAVE := 24.0

static func reichstag(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B8A98B", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#7E7565", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#59605F", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Glass", LandmarkMaterials.glass("#7C98A6"))
	lm.use("Steel", LandmarkMaterials.paint("#B9BEC0", 0.3, 0.7))
	lm.box("Stone", Vector3(0, 12.0, 0), Vector3(RS_HALF.x * 2.0, RS_EAVE, RS_HALF.y * 2.0))
	lm.box("Dark", Vector3(0, 2.0, 0), Vector3(RS_HALF.x * 2.0 + 2.0, 4.0, RS_HALF.y * 2.0 + 2.0))
	lm.box("Roof", Vector3(0, RS_EAVE + 0.4, 0), Vector3(RS_HALF.x * 2.0 - 4.0, 0.8, RS_HALF.y * 2.0 - 4.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * (RS_HALF.x - 8.0), 0, sz * (RS_HALF.y - 8.0))
			lm.box("Stone", c + Vector3(0, 21.0, 0), Vector3(16.0, 42.0, 16.0))
			lm.box("Dark", c + Vector3(0, 41.0, 0), Vector3(17.4, 1.2, 17.4))
			lm.spire("Roof", c + Vector3(0, 42.0, 0), 7.0, 5.0, 1.5)
	# Window rows on the long fronts and the west entrance wall.
	for sx in [-1.0, 1.0]:
		for row in 3:
			LandmarkCeParts.windows(lm, "Windows", Vector3(sx * (RS_HALF.x + 0.1), 6.0 + 6.0 * row, 0),
				Vector3(0, 0, 1), 22, 5.6, Vector3(0.2, 3.6, 1.8))
	for sz in [-1.0, 1.0]:
		for row in 3:
			LandmarkCeParts.windows(lm, "Windows", Vector3(0, 6.0 + 6.0 * row, sz * (RS_HALF.y + 0.1)),
				Vector3(1, 0, 0), 8, 6.0, Vector3(1.8, 3.6, 0.2))
	# West portico: six columns under a pediment.
	var px := -RS_HALF.x - 5.0
	lm.box("Stone", Vector3(px + 1.0, 1.0, 0), Vector3(12.0, 2.0, 36.0))
	LandmarkCeParts.colonnade(lm, "Stone", Vector3(px - 2.0, 2.0, 0), Vector3(0, 0, 1), 6, 5.6, 1.1, 0.95, 17.0, 14)
	lm.box("Stone", Vector3(px, 20.0, 0), Vector3(10.0, 2.6, 34.0))
	lm.gable("Roof", Vector3(px, 21.3, 0), 34.0, 10.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
	# Foster's dome: ribbed glass shell over the mirror cone.
	var dome := PackedVector2Array()
	for i in 11:
		var a := PI * 0.5 * float(i) / 10.0
		dome.append(Vector2(20.0 * cos(a), 22.0 * sin(a)))
	lm.box("Stone", Vector3(0, RS_EAVE + 1.6, 0), Vector3(46.0, 1.6, 46.0))
	lm.lathe("Glass", Vector3(0, RS_EAVE + 1.0, 0), dome, 32)
	for k in 24:
		var a := TAU * k / 24.0
		var prev := Vector3(cos(a) * 20.2, RS_EAVE + 1.0, sin(a) * 20.2)
		for i in range(1, 11):
			var t := PI * 0.5 * float(i) / 10.0
			var p := Vector3(cos(a) * 20.2 * cos(t), RS_EAVE + 1.0 + 22.0 * sin(t), sin(a) * 20.2 * cos(t))
			lm.beam("Steel", prev, p, 0.3, 0.3)
			prev = p
	lm.lathe("Steel", Vector3(0, RS_EAVE + 1.0, 0), PackedVector2Array([Vector2(7.0, 0), Vector2(3.0, 12.0),
		Vector2(1.6, 19.0), Vector2(1.8, 21.0)]), 16)
	lm.commit(model)

# --- Fernsehturm ---

const TV_TOP := 368.0

static func tv_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B2AEA6", 6.0))
	lm.use("Sphere", LandmarkMaterials.paint("#C7CDD1", 0.22, 0.85))
	lm.use("Glass", LandmarkMaterials.glass("#34454E"))
	lm.use("Red", LandmarkMaterials.paint("#C23B2E", 0.5, 0.2))
	lm.use("White", LandmarkMaterials.paint("#ECECE8", 0.5, 0.2))
	lm.use("Podium", LandmarkMaterials.pbr("pavement", "#9C978D", 4.0))
	lm.box("Podium", Vector3(0, 3.0, 0), Vector3(70.0, 6.0, 54.0))
	lm.box("Podium", Vector3(-24.0, 5.0, -8.0), Vector3(28.0, 10.0, 22.0))
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(20.0, 0), Vector2(12.0, 10.0),
		Vector2(9.0, 28.0), Vector2(8.0, 90.0), Vector2(7.2, 170.0), Vector2(6.4, 192.0),
		Vector2(6.0, 204.0), Vector2(5.0, 235.0), Vector2(3.4, 252.0)]), 20)
	var sph := PackedVector2Array()
	for i in 17:
		var a := PI * float(i) / 16.0
		sph.append(Vector2(16.0 * sin(a), 205.0 - 16.0 * cos(a)))
	lm.lathe("Sphere", Vector3.ZERO, sph, 24, 1.0, 1.0, 0.0, false)
	lm.lathe("Glass", Vector3.ZERO, PackedVector2Array([Vector2(16.25, 203.0), Vector2(16.4, 205.0),
		Vector2(16.25, 208.0)]), 24)
	lm.lathe("Concrete", Vector3(0, 252.0, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(2.4, 6.0),
		Vector2(1.7, 10.0)]), 12)
	# Antenna: alternating red and white bands tapering to the tip.
	var y0 := 262.0
	var bands := 8
	for k in bands:
		var h := (TV_TOP - y0) / bands
		var r0 := lerpf(1.7, 0.18, float(k) / bands)
		var r1 := lerpf(1.7, 0.18, float(k + 1) / bands)
		lm.frustum("Red" if k % 2 == 0 else "White", Vector3(0, y0 + h * k, 0), r0, r1, h, 8)
	lm.commit(model)
