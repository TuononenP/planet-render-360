class_name FtPuutoriEnsemble
extends RefCounted

## Puutori Square & Puutorin Vessa (1933 functionalist circular red-brick
## rotunda café) + Wäinö Aaltonen bronze monument in central Turku.
## Origin at OSM way:90081603 centroid (60.455219 N, 22.269088 E), yaw_deg 56.9.
##
## Architectural & facade spec:
## - Circular red-brick & white-trim functionalist rotunda (r = 5.4 m,
##   height 6.1 m matching turku_lod2 6.1 m) with cantilevered white terrace
##   canopy, curved clerestory ribbon windows & warm café glow.
## - Granite cobble plaza apron with low stone kerbs, timber terrace deck,
##   and Wäinö Aaltonen's bronze friendship monument on a red-granite plinth.

const FOUND := -1.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C877E", 2.5))
	lm.use("RedGranite", LandmarkMaterials.pbr("stone", "#8B5C50", 2.0))
	lm.use("Cobble", LandmarkMaterials.pbr("stone", "#7C7974", 3.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4A36", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F2EFE8", 2.0))
	lm.use("Copper", LandmarkFrKit.copper("#486E60"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8E6846", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#464C44", 0.52, 0.45))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A4", 0.95))

	# Cobblestone square apron & terrace deck around the rotunda.
	LandmarkFrKit.rect(lm, "Cobble", -18.0, 18.0, -14.0, 14.0, FOUND, 0.14)
	LandmarkFrKit.rect(lm, "Wood", -9.5, 9.5, 4.5, 11.5, 0.10, 0.34)
	for sx: float in [-18.0, 18.0]:
		LandmarkFrKit.rect(lm, "Granite", sx - 0.35, sx + 0.35, -14.2, 14.2, FOUND, 0.42)

	# Puutorin Vessa circular functionalist rotunda (r = 5.4 m, h = 6.1 m).
	lm.frustum("Granite", Vector3(0.0, FOUND, 0.0), 5.65, 5.60, 0.9 - FOUND, 28)
	lm.frustum("Brick", Vector3(0.0, 0.9, 0.0), 5.4, 5.4, 3.1, 28)
	# Sweeping white cantilevered canopy ring (y = 3.85..4.15 m, r = 6.8 m).
	lm.frustum("Trim", Vector3(0.0, 3.85, 0.0), 6.85, 6.85, 0.30, 28)
	# Recessed upper clerestory drum with warm café glow (y = 4.15..5.45 m).
	lm.frustum("WarmGlow", Vector3(0.0, 4.15, 0.0), 4.65, 4.65, 1.15, 24)
	lm.frustum("Trim", Vector3(0.0, 5.30, 0.0), 5.05, 5.05, 0.35, 24)
	# Low conical copper roof peaking at 6.1 m.
	lm.frustum("Copper", Vector3(0.0, 5.65, 0.0), 5.0, 0.25, 0.45, 24)

	# 12 slender white mullions & terrace windows around the rotunda.
	for i in 12:
		var a := TAU * float(i) / 12.0
		var n := Vector3(cos(a), 0.0, sin(a))
		var b := Basis(Vector3.UP, atan2(n.x, n.z))
		lm.box("Trim", n * 5.48 + Vector3(0.0, 2.45, 0.0), Vector3(0.24, 3.0, 0.18), b, 0.0)
		var wa := a + PI / 12.0
		var wn := Vector3(cos(wa), 0.0, sin(wa))
		var wb := Basis(Vector3.UP, atan2(wn.x, wn.z))
		lm.box("WarmGlow", wn * 5.42 + Vector3(0.0, 2.35, 0.0), Vector3(1.5, 1.9, 0.08), wb, 0.0)
		lm.box("Trim", wn * 4.72 + Vector3(0.0, 4.72, 0.0), Vector3(0.16, 1.15, 0.14), wb, 0.0)

	# Terrace tables/parasol posts & benches.
	for i in 4:
		var bx := lerpf(-6.5, 6.5, float(i) / 3.0)
		lm.frustum("Trim", Vector3(bx, 0.34, 8.2), 0.08, 0.08, 2.4, 8)
		lm.frustum("Trim", Vector3(bx, 2.65, 8.2), 1.45, 0.15, 0.45, 12)
		lm.box("Wood", Vector3(bx, 0.78, 8.2), Vector3(1.4, 0.08, 1.4), Basis(), 0.0)

	# Wäinö Aaltonen bronze monument on red-granite pedestal (SW side of plaza).
	var mx := -12.5
	var mz := -7.0
	LandmarkFrKit.rect(lm, "Granite", mx - 2.2, mx + 2.2, mz - 2.2, mz + 2.2, FOUND, 0.48)
	LandmarkFrKit.rect(lm, "RedGranite", mx - 1.35, mx + 1.35, mz - 1.35, mz + 1.35, 0.48, 2.4)
	lm.frustum("Bronze", Vector3(mx - 0.35, 2.4, mz), 0.32, 0.24, 2.35, 10)
	lm.frustum("Bronze", Vector3(mx + 0.35, 2.4, mz), 0.32, 0.24, 2.25, 10)
	lm.box("Bronze", Vector3(mx, 3.9, mz), Vector3(1.1, 0.38, 0.35), Basis(), 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 0.8, 12.5), Vector3(0.0, 3.6, 5.0), 22.0, 0.9, 60.0, warm],
		[Vector3(-12.5, 0.8, -2.5), Vector3(-12.5, 3.5, -7.0), 16.0, 0.85, 50.0, warm],
	])
