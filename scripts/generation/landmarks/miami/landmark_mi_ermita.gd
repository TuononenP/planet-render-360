class_name LandmarkMiErmita
extends RefCounted

## Ermita de la Caridad (National Shrine of Our Lady of Charity) — MI-10 Centre E.
## Bernardo Fort-Brescia / Telesforo Cristobal (1973). Footprint 42.8 x 38.9 m, height 29.5 m.
## +X faces Biscayne Bay. Whitewashed truncated conical concrete shell (y 1.5..22.0),
## stained-glass clerestory collar, shallow cap, rooftop cross to 29.5 m, cantilevered
## angled entrance canopy facing the bay, circular granite esplanade on the seawall plaza.

const HEIGHT_M := 29.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shell", LandmarkMaterials.pbr("concrete", "#F5F2EA", 4.0, 0.7))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8A84", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("concrete", "#CFC8BA", 3.0))
	lm.use("Glass", LandmarkMaterials.lit("#E9A93B", 0.7))
	lm.use("Dark", LandmarkMaterials.glass("#26303A"))
	lm.use("Gold", LandmarkMaterials.gold())
	_build_plaza(lm)
	_build_shell(lm)
	_build_canopy(lm)
	_build_crown(lm)
	lm.commit(model)
	var gold := Color(1.0, 0.82, 0.48)
	var white := Color(1.0, 0.96, 0.88)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(18.0, 0.8, -12.0), Vector3(0.0, 14.0, 0.0), 30.0, 1.3, 40.0, gold],
		[Vector3(18.0, 0.8, 12.0), Vector3(0.0, 14.0, 0.0), 30.0, 1.3, 40.0, gold],
		[Vector3(-18.0, 0.8, 0.0), Vector3(0.0, 16.0, 0.0), 30.0, 1.3, 40.0, white],
		[Vector3(0.0, 0.8, 16.0), Vector3(0.0, 18.0, 0.0), 30.0, 1.2, 40.0, white],
	])

static func _build_plaza(lm: LandmarkMesh) -> void:
	lm.box("Paving", Vector3(0.0, 0.5, 0.0), Vector3(42.8, 1.0, 38.9), Basis(), 0.0)
	# Circular granite oceanfront esplanade ring
	lm.frustum("Granite", Vector3(0.0, 0.9, 0.0), 17.5, 17.5, 0.4, 36)
	lm.frustum("Paving", Vector3(0.0, 1.0, 0.0), 14.5, 14.5, 0.35, 36)
	# Seawall coping along bay (east) edge with bollard posts
	lm.box("Granite", Vector3(21.2, 1.2, 0.0), Vector3(0.8, 0.8, 38.9), Basis(), 0.0)
	for i: int in 13:
		var z := -18.0 + float(i) * 3.0
		lm.frustum("Granite", Vector3(21.2, 1.6, z), 0.22, 0.18, 0.8, 8)

static func _build_shell(lm: LandmarkMesh) -> void:
	# Truncated conical concrete shell: wide base flaring inward to the collar
	lm.frustum("Shell", Vector3(0.0, 1.3, 0.0), 13.0, 12.6, 0.8, 40)
	lm.lathe("Shell", Vector3(0.0, 1.5, 0.0), PackedVector2Array([
		Vector2(12.4, 0.0), Vector2(10.6, 8.0), Vector2(8.8, 14.5), Vector2(7.6, 18.5), Vector2(7.2, 19.5)]), 40)
	# Vertical rib seams
	for i: int in 16:
		var a := float(i) * TAU / 16.0
		var d := Vector3(cos(a), 0.0, sin(a))
		lm.beam("Shell", Vector3(0.0, 1.8, 0.0) + d * 12.5, Vector3(0.0, 20.8, 0.0) + d * 7.4, 0.35, 0.3)
	# Bay-side entrance doors cut into the base
	lm.box("Dark", Vector3(12.0, 4.0, 0.0), Vector3(0.5, 5.0, 6.0), Basis(), 0.0)
	lm.box("Gold", Vector3(12.25, 4.0, 0.0), Vector3(0.1, 5.2, 0.2), Basis(), 0.0)
	# Stained-glass clerestory collar
	lm.frustum("Glass", Vector3(0.0, 21.0, 0.0), 7.3, 7.0, 2.2, 40)
	for i: int in 24:
		var a := float(i) * TAU / 24.0
		var d := Vector3(cos(a), 0.0, sin(a))
		lm.beam("Shell", Vector3(0.0, 21.0, 0.0) + d * 7.35, Vector3(0.0, 23.2, 0.0) + d * 7.05, 0.28, 0.28)

static func _build_canopy(lm: LandmarkMesh) -> void:
	# Cantilevered angled entrance canopy facing the bay (+X), tilted upward
	var b := Basis(Vector3(0.0, 0.0, 1.0), 0.28)
	lm.box("Shell", Vector3(15.0, 8.0, 0.0), Vector3(8.0, 0.6, 14.0), b, 0.0)
	for sz: float in [-1.0, 1.0]:
		lm.beam("Shell", Vector3(17.0, 1.0, sz * 6.0), Vector3(14.0, 7.2, sz * 6.0), 0.8, 0.8)

static func _build_crown(lm: LandmarkMesh) -> void:
	# Shallow cap above the clerestory, then a gold-tipped white cross reaching 29.5 m
	lm.lathe("Shell", Vector3(0.0, 23.2, 0.0), PackedVector2Array([
		Vector2(7.3, 0.0), Vector2(6.2, 0.6), Vector2(4.0, 1.4), Vector2(1.6, 1.9), Vector2(0.0, 2.0)]), 40)
	lm.beam("Shell", Vector3(0.0, 25.0, 0.0), Vector3(0.0, HEIGHT_M, 0.0), 0.6, 0.6, Vector3.RIGHT, true)
	lm.beam("Gold", Vector3(-1.7, 27.6, 0.0), Vector3(1.7, 27.6, 0.0), 0.5, 0.5, Vector3.UP, true)
