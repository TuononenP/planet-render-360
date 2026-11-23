class_name LandmarkMiCgCityHall
extends RefCounted

## Coral Gables City Hall (MI-10). OSM way 416557593 (25.749252, -80.263457, yaw 41.0).
## Phineas Paist (1928), 34.1 x 46.7 m, Keystone coral limestone (#DFD5C0).
##   - Semicircular Corinthian colonnade rotunda at the +Z front apex.
##   - Splayed 3-storey stone wings with terracotta hipped roofs.
##   - 3-stage Spanish Baroque clock tower: shaft, belfry with arches, dome to exactly 22.0 m.

const HEIGHT_M := 22.0
const WING_H := 11.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DFD5C0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#EDE5D2", 2.6))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B4532D", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#2F3F48"))
	lm.use("Iron", LandmarkMaterials.paint("#26292C", 0.5, 0.6))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#5E9C86", 2.4))
	lm.use("Clock", LandmarkMaterials.paint("#F4EFE0", 0.5, 0.0))
	_build_wings(lm)
	_build_rotunda(lm)
	_build_tower(lm)
	lm.commit(model)

static func _build_wings(lm: LandmarkMesh) -> void:
	for sx: float in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, sx * 0.28)
		var c := Vector3(sx * 10.5, 0.0, 2.0)
		lm.box("Stone", c + b * Vector3(0, WING_H * 0.5, 0), Vector3(11.0, WING_H, 34.0), b, 0.0)
		lm.box("Trim", c + b * Vector3(0, 0.45, 0), Vector3(11.6, 0.9, 34.6), b, 0.0)
		lm.box("Trim", c + b * Vector3(0, WING_H + 0.1, 0), Vector3(11.8, 0.4, 34.8), b, 0.0)
		lm.gable("Tile", c + b * Vector3(0, WING_H + 0.3, 0), 11.6, 34.6, 3.0, b, 0.0, "")
		# window bays on outer faces, 3 storeys
		for f: int in 3:
			var wy := 2.4 + float(f) * 3.2
			for k: int in 7:
				var wz := -14.0 + float(k) * 4.67
				for face: float in [-1.0, 1.0]:
					lm.box("Glass", c + b * Vector3(face * 5.52, wy, wz), Vector3(0.12, 1.7, 1.2), b, 0.0)
					lm.box("Trim", c + b * Vector3(face * 5.55, wy + 1.0, wz), Vector3(0.14, 0.2, 1.7), b, 0.0)

static func _build_rotunda(lm: LandmarkMesh) -> void:
	var cz := 10.0
	var r := 8.0
	lm.frustum("Stone", Vector3(0.0, 0.0, cz), 7.2, 7.2, 9.0, 24)
	lm.frustum("Trim", Vector3(0.0, 0.0, cz), 8.6, 8.6, 0.9, 24)
	# semicircular Corinthian colonnade (front half, +Z)
	var n := 11
	for i: int in n:
		var a := PI * float(i) / float(n - 1)
		var x := cos(a) * r
		var z := cz + sin(a) * r
		lm.frustum("Trim", Vector3(x, 0.9, z), 0.50, 0.44, 7.4, 10)
		lm.lathe("Trim", Vector3(x, 8.3, z), PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.48, 0.0), Vector2(0.62, 0.30),
			Vector2(0.72, 0.62), Vector2(0.0, 0.62)]), 10)
	# entablature
	var prev := Vector3(r, 9.2, cz)
	for i: int in 1 + 16:
		var a := PI * float(i) / 16.0
		var cur := Vector3(cos(a) * (r + 0.1), 9.2, cz + sin(a) * (r + 0.1))
		if i > 0:
			lm.beam("Trim", prev, cur, 1.1, 1.2, Vector3.UP)
		prev = cur
	# flat roof drum + terracotta cap
	lm.frustum("Tile", Vector3(0.0, 9.8, cz), 8.6, 5.0, 1.8, 24)
	# main central block between wings
	lm.box("Stone", Vector3(0.0, WING_H * 0.5, -4.0), Vector3(14.0, WING_H, 22.0), Basis(), 0.0)
	lm.gable("Tile", Vector3(0.0, WING_H, -4.0), 14.6, 22.6, 2.6, Basis(), 0.0, "")

static func _build_tower(lm: LandmarkMesh) -> void:
	var tz := -2.0
	# stage 1 shaft
	lm.box("Stone", Vector3(0.0, 11.0 + 2.75, tz), Vector3(6.0, 5.5, 6.0), Basis(), 0.0)
	lm.box("Trim", Vector3(0.0, 16.6, tz), Vector3(6.6, 0.4, 6.6), Basis(), 0.0)
	# clock faces on four sides
	for d: Vector3 in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		lm.disc("Clock", Vector3(0.0, 14.0, tz) + d * 3.04, d, 1.3, 20)
		lm.beam("Iron", Vector3(0.0, 14.0, tz) + d * 3.08, Vector3(0.0, 14.8, tz) + d * 3.08, 0.07, 0.04, Vector3.RIGHT)
	# stage 2 belfry with arched openings
	lm.box("Stone", Vector3(0.0, 18.0, tz), Vector3(4.6, 2.8, 4.6), Basis(), 0.0)
	for d: Vector3 in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		lm.box("Glass", Vector3(0.0, 18.0, tz) + d * 2.32, Vector3(0.12 + absf(d.z) * 1.4, 1.9, 0.12 + absf(d.x) * 1.4), Basis(), 0.0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.box("Trim", Vector3(sx * 2.3, 19.6, tz + sz * 2.3), Vector3(0.6, 0.9, 0.6), Basis(), 0.0)
	lm.box("Trim", Vector3(0.0, 19.6, tz), Vector3(5.0, 0.35, 5.0), Basis(), 0.0)
	# stage 3 dome
	lm.lathe("Copper", Vector3(0.0, 19.8, tz), PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(2.1, 0.0), Vector2(2.2, 0.35), Vector2(1.7, 1.2),
		Vector2(1.0, 1.9), Vector2(0.35, 2.05)]), 16, 1.0, 1.0, 0.0, true, false)
	lm.beam("Iron", Vector3(0.0, 21.8, tz), Vector3(0.0, HEIGHT_M, tz), 0.07, 0.07, Vector3.RIGHT, true)
