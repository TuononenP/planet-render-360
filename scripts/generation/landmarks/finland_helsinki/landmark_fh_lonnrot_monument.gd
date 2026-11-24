extends RefCounted

## Elias Lönnrot Monument (Emil Wikström, 1902), Lönnrotinpuistikko.
## Extracted from City of Helsinki 3D+ Reality Mesh (2024, CC BY 4.0) on a
## stepped granite park terrace with warm uplighting.

const RealityMesh = preload("res://scripts/generation/reality_mesh_kit.gd")

const ENTRY := {"type": "lonnrot_monument", "name": "Elias Lönnrot Monument",
	"lat": 60.166675, "lon": 24.938325, "radius_m": 1500.0,
	"wiki_title": "Elias Lönnrot", "height_m": 6.5, "clear_m": 6.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["elias lönnrot monument", "elias lonnrot statue", "lönnrotin patsas", "lonnrotin patsas"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#827E78", 2.0))
	lm.frustum("Granite", Vector3.ZERO, 3.8, 3.8, 0.22, 16)
	lm.frustum("Granite", Vector3(0.0, 0.22, 0.0), 3.2, 3.2, 0.20, 16)
	lm.commit(model)
	if RealityMesh.add_textured_glb(model, "LonnrotMonument",
			"res://assets/landmarks/helsinki_3d/lonnrot_monument.glb",
			Vector3(0.0, 0.42, 0.0), Vector3(0.83, 0.83, 0.83), 0.0, 0.72, 0.12) == null:
		var fb := LandmarkMesh.new()
		fb.use("Granite", LandmarkMaterials.pbr("stone", "#827E78", 2.0))
		fb.box("Granite", Vector3(0.0, 3.2, 0.0), Vector3(2.2, 5.6, 2.2))
		fb.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-3.8, 0.4, 3.8), Vector3(0.0, 4.2, 0.0), 44.0, 0.85, 15.0, warm],
		[Vector3(3.8, 0.4, -3.8), Vector3(0.0, 4.2, 0.0), 44.0, 0.80, 15.0, warm],
	])
