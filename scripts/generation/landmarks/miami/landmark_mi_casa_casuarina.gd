class_name LandmarkMiCasaCasuarina
extends RefCounted

## Villa Casa Casuarina (Versace Mansion) — 1116 Ocean Dr (MI-4A).
## Site: OSM way 380875533, 25.781988, -80.130662, yaw_deg 11.7.
## Local +X = east (Ocean Drive frontage), +Z = north. Alden Freeman, 1930,
## Mediterranean Revival palazzo modelled on the Alcázar de Colón (Commons views):
##   - Footprint 32.8 m (X) x 23.6 m (Z): coral-stone / warm ochre-peach stucco.
##   - Main palazzo x -11.4..-1.0 (9.5 m eaves, hipped clay barrel-tile roof) with
##     two side wings (8.0 m) wrapping a courtyard; arched loggia, wrought-iron
##     balconies, mosaic courtyard pool (x 1..8, z -4..4).
##   - Front privacy wall (3.4 m) with gate and bronze Medusa medallion at x = +11.4.
##   - Octagonal observatory tower at the rear corner, copper-domed, finial tip
##     is the model top, exactly 16.5 m.

const HEIGHT_M := 16.5
const WALL_X := 11.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Coral", LandmarkMaterials.pbr("render", "#E6B08A", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("limestone", "#D6A36A", 2.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B85A3A", 2.2))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#5E8E79", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A2A26"))
	lm.use("Iron", LandmarkMaterials.paint("#1E1E1C", 0.5, 0.5))
	lm.use("Water", LandmarkMaterials.pool_water("#2E9CC4"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Paving", LandmarkMaterials.pbr("stone", "#CDBFA6", 2.5))

	lm.box("Paving", Vector3(0.0, -0.15, 0.0), Vector3(32.8, 0.3, 23.6))
	_palazzo(lm)
	_wings(lm)
	_loggia(lm)
	_courtyard(lm)
	_gate_wall(lm)
	_tower(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.86, 0.62)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(15.5, 1.5, -9.0), Vector3(WALL_X, 5.0, -3.0), 40.0, 1.15, 30.0, warm],
		[Vector3(15.5, 1.5, 9.0), Vector3(WALL_X, 5.0, 3.0), 40.0, 1.15, 30.0, warm],
		[Vector3(2.0, 1.0, 0.0), Vector3(-7.0, 13.0, -7.0), 36.0, 1.1, 26.0, Color(0.7, 0.95, 0.85)],
	])

static func _palazzo(lm: LandmarkMesh) -> void:
	lm.box("Coral", Vector3(-6.2, 4.6, 0.0), Vector3(10.4, 9.8, 23.2))
	lm.box("Ochre", Vector3(-0.9, 9.3, 0.0), Vector3(0.7, 0.4, 23.6))
	lm.gable("Tile", Vector3(-6.2, 9.5, 0.0), 10.4, 23.2, 2.6, Basis(), 0.5, "Coral")
	for f in 2:
		var y := 2.0 + float(f) * 3.7
		for z: float in [-9.0, -5.8, 5.8, 9.0]:
			lm.box("Glass", Vector3(-0.97, y + 0.4, z), Vector3(0.1, 1.9, 1.1))
			lm.disc("Glass", Vector3(-0.96, y + 1.35, z), Vector3(1, 0, 0), 0.55, 10)
			lm.box("Ochre", Vector3(-0.8, y + 1.35, z), Vector3(0.3, 0.14, 1.6))
	# Wrought-iron balcony rails on the upper storey.
	for z: float in [-9.0, -5.8, 5.8, 9.0]:
		lm.box("Iron", Vector3(-0.35, 6.4, z), Vector3(0.05, 0.9, 1.6))
		lm.box("Ochre", Vector3(-0.45, 5.9, z), Vector3(1.0, 0.18, 1.8))

static func _wings(lm: LandmarkMesh) -> void:
	for sz: float in [-1.0, 1.0]:
		lm.box("Coral", Vector3(4.6, 3.85, sz * 9.2), Vector3(11.2, 8.0, 5.2))
		lm.box("Ochre", Vector3(4.6, 8.1, sz * 9.2), Vector3(11.6, 0.4, 5.6))
		lm.gable("Tile", Vector3(4.6, 8.0, sz * 9.2), 5.2, 11.2, 2.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Coral")
		for x: float in [1.5, 4.6, 7.7]:
			var zf := sz * 6.55
			lm.box("Glass", Vector3(x, 2.3, zf), Vector3(1.1, 2.0, 0.1))
			lm.disc("Glass", Vector3(x, 3.3, zf + sz * 0.02), Vector3(0, 0, sz), 0.55, 10)
			lm.box("Iron", Vector3(x, 5.6, zf + sz * 0.3), Vector3(1.4, 0.9, 0.05))

static func _loggia(lm: LandmarkMesh) -> void:
	# Arched courtyard loggia on the palazzo's east face with a barrel-tile lean-to.
	for z: float in [-3.6, -1.2, 1.2, 3.6]:
		lm.box("Glass", Vector3(-0.97, 1.5, z), Vector3(0.1, 2.6, 1.5))
		lm.disc("Glass", Vector3(-0.96, 2.8, z), Vector3(1, 0, 0), 0.75, 12)
	for z: float in [-4.8, -2.4, 0.0, 2.4, 4.8]:
		lm.box("Ochre", Vector3(-0.2, 2.1, z), Vector3(0.7, 4.2, 0.42))
	lm.box("Ochre", Vector3(-0.2, 4.5, 0.0), Vector3(0.8, 0.5, 10.6))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(0.0, -5.4), Vector2(0.0, 5.4), 4.8, 6.4, 1.6, Vector2(1, 0))

static func _courtyard(lm: LandmarkMesh) -> void:
	lm.box("Ochre", Vector3(4.5, 0.12, 0.0), Vector3(7.8, 0.24, 8.6))
	lm.box("Water", Vector3(4.5, 0.2, 0.0), Vector3(7.0, 0.1, 7.8))
	for sz: float in [-1.0, 1.0]:
		lm.box("Ochre", Vector3(8.2, 0.55, sz * 4.5), Vector3(0.5, 1.1, 0.5))
		lm.frustum("Ochre", Vector3(8.2, 1.1, sz * 4.5), 0.34, 0.2, 0.3, 8)

static func _gate_wall(lm: LandmarkMesh) -> void:
	for sz: float in [-1.0, 1.0]:
		lm.box("Coral", Vector3(WALL_X, 1.7, sz * 7.2), Vector3(0.5, 3.4, 9.2))
		lm.box("Ochre", Vector3(WALL_X, 3.5, sz * 7.2), Vector3(0.8, 0.3, 9.6))
		lm.box("Ochre", Vector3(WALL_X, 2.0, sz * 2.2), Vector3(0.9, 4.0, 0.9))
		lm.frustum("Ochre", Vector3(WALL_X, 4.0, sz * 2.2), 0.45, 0.2, 0.5, 8)
	lm.box("Iron", Vector3(WALL_X, 1.5, 0.0), Vector3(0.1, 2.6, 3.4))
	lm.box("Ochre", Vector3(WALL_X, 3.2, 0.0), Vector3(0.6, 0.35, 3.6))
	# Bronze Medusa medallion with a laurel ring.
	lm.disc("Gold", Vector3(WALL_X + 0.28, 2.3, 7.2), Vector3(1, 0, 0), 0.6, 16)
	lm.disc("Gold", Vector3(WALL_X + 0.28, 2.3, -7.2), Vector3(1, 0, 0), 0.6, 16)

static func _tower(lm: LandmarkMesh) -> void:
	var c := Vector3(-7.0, 0.0, -7.0)
	lm.frustum("Coral", c + Vector3(0, 9.4, 0), 2.5, 2.3, 4.6, 8)
	lm.frustum("Ochre", c + Vector3(0, 13.7, 0), 2.7, 2.7, 0.3, 8)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.box("Glass", c + Vector3(cos(a) * 2.28, 11.8, sin(a) * 2.28), Vector3(0.12, 1.5, 1.0),
			Basis(Vector3.UP, -a))
	lm.frustum("Copper", c + Vector3(0, 14.0, 0), 2.5, 2.0, 0.4, 8)
	lm.frustum("Copper", c + Vector3(0, 14.4, 0), 2.0, 1.2, 0.6, 8)
	lm.frustum("Copper", c + Vector3(0, 15.0, 0), 1.2, 0.3, 0.6, 8)
	lm.beam("Gold", c + Vector3(0, 15.5, 0), c + Vector3(0, HEIGHT_M, 0), 0.14, 0.14)
