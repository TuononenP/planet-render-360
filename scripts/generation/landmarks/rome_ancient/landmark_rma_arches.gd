class_name LandmarkRmAArches
extends RefCounted

## The Arch of Constantine, the Arch of Titus and the Porta Maggiore in
## true metres, each facing +Z with its passage along Z (yaw_deg turns
## it onto the real bearing).

# --- Arch of Constantine --------------------------------------------

## 25.9 x 7.4 m, 21 m high: three barrel-vaulted passages (6.5 and 3.4 m
## wide, 11.5 and 7.4 m to the crown), eight giallo antico Corinthian
## columns on pedestals with Dacian captives above their entablature
## blocks, tondi and a frieze over the side passages, and the attic
## with its inscription and the four reused Aurelian relief panels.
static func constantine(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CFC6B0", 3.0))
	lm.use("Giallo", LandmarkMaterials.pbr("limestone", "#C9A862", 2.0))
	lm.use("Soffit", LandmarkMaterials.pbr("stone", "#7B715F", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#A99D85", 2.0))
	var w := 25.9
	var d := 7.4
	var hw := w * 0.5
	RmAUtil.arch_wall(lm, "Marble", "Soffit", Vector3(0, 0, d * 0.5), Vector3.RIGHT, Vector3.BACK,
		-hw, hw, 0.0, 14.4, [[-8.45, 3.4, 5.7, 0.0], [0.0, 6.5, 8.25, 0.0], [8.45, 3.4, 5.7, 0.0]], d, 10)
	# Plinth blocks under the piers, main cornice, attic and its cornice.
	for px in [[-11.7, 3.1], [-5.0, 3.5], [5.0, 3.5], [11.7, 3.1]]:
		lm.box("Marble", Vector3(float(px[0]), 0.5, 0), Vector3(float(px[1]) + 0.6, 1.0, d + 0.6))
	lm.box("Marble", Vector3(0, 14.85, 0), Vector3(w + 1.0, 0.9, d + 1.0))
	lm.box("Marble", Vector3(0, 17.8, 0), Vector3(w - 0.8, 5.0, d - 0.8))
	lm.box("Marble", Vector3(0, 20.65, 0), Vector3(w + 0.4, 0.7, d + 0.4))
	for sz in [-1.0, 1.0]:
		var zf: float = sz * (d * 0.5 + 0.95)
		for cx in [-11.7, -4.9, 4.9, 11.7]:
			var x: float = cx
			lm.box("Marble", Vector3(x, 1.5, zf), Vector3(2.0, 3.0, 2.0))
			RmAUtil.column(lm, "Giallo", Vector3(x, 3.0, zf), 9.0, 0.6, "corinthian")
			lm.box("Marble", Vector3(x, 12.75, zf), Vector3(2.1, 1.5, 2.1))
			LandmarkKits.statue_figure(lm, "Marble", Vector3(x, 13.5, zf), 2.6)
		var zw: float = sz * (d * 0.5 + 0.05)
		for sx in [-8.45, 8.45]:
			var x2: float = sx
			lm.disc("Relief", Vector3(x2, 11.7, zw), Vector3(0, 0, sz), 1.4, 16)
			lm.box("Relief", Vector3(x2, 9.0, zw), Vector3(4.4, 1.0, 0.14))
		lm.box("Soffit", Vector3(0, 17.9, sz * (d * 0.5 - 0.35)), Vector3(8.2, 3.4, 0.14))
		for px in [-10.2, -6.6, 6.6, 10.2]:
			lm.box("Relief", Vector3(float(px), 17.9, sz * (d * 0.5 - 0.35)), Vector3(3.2, 3.2, 0.14))
	lm.commit(model)

# --- Arch of Titus --------------------------------------------------

## 13.5 x 4.75 m, 15.4 m high, one 5.36 x 8.3 m passage: four composite
## half-columns a face on pedestals, the triumphal frieze, the attic with
## the dedication, and the Jerusalem reliefs on the inner jambs. The
## plain blocks are Valadier's travertine restoration of 1822.
static func titus(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CDBFA3", 3.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C4B592", 3.0))
	lm.use("Soffit", LandmarkMaterials.pbr("stone", "#76695A", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#A99D85", 2.0))
	var w := 13.5
	var d := 4.75
	var hw := w * 0.5
	RmAUtil.arch_wall(lm, "Marble", "Soffit", Vector3(0, 0, d * 0.5), Vector3.RIGHT, Vector3.BACK,
		-hw, hw, 0.0, 8.9, [[0.0, 5.36, 5.62, 0.0]], d, 10)
	lm.box("Marble", Vector3(0, 9.95, 0), Vector3(w + 0.8, 2.1, d + 0.5))
	lm.box("Travertine", Vector3(0, 13.1, 0), Vector3(w - 0.6, 4.2, d - 0.5))
	lm.box("Marble", Vector3(0, 15.15, 0), Vector3(w + 0.4, 0.5, d + 0.4))
	for sz in [-1.0, 1.0]:
		var zf: float = sz * (d * 0.5 + 0.1)
		for cx in [-5.95, -3.65, 3.65, 5.95]:
			var x: float = cx
			lm.box("Travertine", Vector3(x, 0.9, zf), Vector3(1.5, 1.8, 1.3))
			RmAUtil.column(lm, "Travertine", Vector3(x, 1.8, zf), 7.1, 0.5, "corinthian", 10)
		var zw: float = sz * (d * 0.5 + 0.06)
		lm.box("Relief", Vector3(0, 9.95, zw), Vector3(w - 0.4, 1.1, 0.12))
		lm.box("Soffit", Vector3(0, 13.1, sz * (d * 0.5 - 0.3)), Vector3(5.8, 1.9, 0.12))
	for sx in [-1.0, 1.0]:
		lm.box("Relief", Vector3(sx * 2.62, 3.9, 0), Vector3(0.12, 3.0, 3.2))
	lm.commit(model)

# --- Porta Maggiore -------------------------------------------------

## Claudius' double arch of rusticated travertine carrying the Aqua
## Claudia and the Anio Novus: two 5.8 m passages (8 m to the crown),
## three pedimented tabernacles on the piers, the attic with the
## three stacked aqueduct channels and their inscriptions, and the
## brick stubs of the Aurelian Wall either side.
static func porta_maggiore(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Rustic", LandmarkMaterials.pbr("stone", "#B7AA8C", 2.5))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#CFC4A5", 3.0))
	lm.use("Soffit", LandmarkMaterials.pbr("stone", "#6C6252", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94684C", 2.5))
	var d := 5.6
	var hw := 12.1
	RmAUtil.arch_wall(lm, "Rustic", "Soffit", Vector3(0, 0, d * 0.5), Vector3.RIGHT, Vector3.BACK,
		-hw, hw, 0.0, 13.2, [[-4.8, 5.8, 5.1, 0.0], [4.8, 5.8, 5.1, 0.0]], d, 10)
	lm.box("Travertine", Vector3(0, 13.5, 0), Vector3(hw * 2.0 + 0.8, 0.7, d + 0.6))
	# Attic: three stacked channels (specus) with inscribed fronts.
	for k in 3:
		var y: float = 14.6 + 1.9 * float(k)
		lm.box("Travertine", Vector3(0, y, 0), Vector3(hw * 2.0 - 0.6, 1.5, d - 0.6))
		lm.box("Soffit", Vector3(0, y, 0), Vector3(hw * 2.0 - 3.0, 0.7, d + 0.1))
	lm.box("Travertine", Vector3(0, 18.7, 0), Vector3(hw * 2.0 + 0.4, 0.5, d + 0.4))
	for sz in [-1.0, 1.0]:
		var zf: float = sz * (d * 0.5 + 0.05)
		for k in 3:
			var tx: float = -9.6 + 9.6 * float(k)
			lm.box("Soffit", Vector3(tx, 7.5, zf), Vector3(1.8, 3.4, 0.1))
			for s in [-1.0, 1.0]:
				lm.box("Travertine", Vector3(tx + s * 1.15, 7.5, zf + sz * 0.1), Vector3(0.5, 3.8, 0.3))
			lm.box("Travertine", Vector3(tx, 9.5, zf + sz * 0.1), Vector3(2.8, 0.4, 0.3))
			RmAUtil.pediment(lm, "Travertine", Vector3(tx, 9.7, zf + sz * 0.1), Vector3.RIGHT,
				Vector3(0, 0, sz), 3.0, 1.0 if k != 1 else 1.4, 0.4)
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * (hw + 1.9), 0, 0), Vector3(sx * (hw + 15.0), 0, 0),
			3.8, 0.0, 6.0, 10.5, 1.8, sx)
		lm.box("Brick", Vector3(sx * (hw + 1.9), 5.0, 0), Vector3(3.8, 10.0, 3.8))
	lm.commit(model)
