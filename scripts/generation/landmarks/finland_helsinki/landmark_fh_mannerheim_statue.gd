extends RefCounted

## Equestrian Statue of Marshal Mannerheim (Aimo Tukiainen, 1960),
## Mannerheiminaukio outside Kiasma and Postitalo.
## Extracted from City of Helsinki 3D+ Reality Mesh (2024, CC BY 4.0) on a
## stepped granite plaza plinth with warm architectural uplighting.

const RealityMesh = preload("res://scripts/generation/reality_mesh_kit.gd")

const ENTRY := {"type": "mannerheim_statue", "name": "Marshal Mannerheim Equestrian Statue",
	"lat": 60.1715897, "lon": 24.9363006, "radius_m": 2000.0,
	"wiki_title": "Equestrian statue of Marshal Mannerheim", "height_m": 11.1, "clear_m": 8.0,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["mannerheim statue", "marshal mannerheim statue", "mannerheimin ratsastajapatsas",
		"marsalkka mannerheimin ratsastajapatsas"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#787570", 2.2))
	lm.use("RedGranite", LandmarkMaterials.pbr("stone", "#864E46", 2.0))
	lm.box("Granite", Vector3(0.0, 0.14, 0.0), Vector3(6.8, 0.28, 8.6))
	lm.box("Granite", Vector3(0.0, 0.42, 0.0), Vector3(5.6, 0.28, 7.2))
	lm.box("RedGranite", Vector3(0.0, 0.66, 0.0), Vector3(4.2, 0.20, 5.8))
	lm.commit(model)
	if RealityMesh.add_textured_glb(model, "MannerheimEquestrian",
			"res://assets/landmarks/helsinki_3d/mannerheim_equestrian.glb",
			Vector3(0.0, 0.70, 0.0), Vector3(1.0, 1.0, 1.0), 0.0, 0.70, 0.15) == null:
		var fb := LandmarkMesh.new()
		fb.use("RedGranite", LandmarkMaterials.pbr("stone", "#864E46", 2.0))
		fb.box("RedGranite", Vector3(0.0, 3.2, 0.0), Vector3(2.8, 5.2, 5.2))
		fb.commit(model)
	var warm := Color(1.0, 0.89, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-5.0, 0.5, 5.0), Vector3(0.0, 7.5, 0.0), 42.0, 0.95, 22.0, warm],
		[Vector3(5.0, 0.5, 5.0), Vector3(0.0, 7.5, 0.0), 42.0, 0.95, 22.0, warm],
		[Vector3(0.0, 0.5, -5.5), Vector3(0.0, 7.5, 0.0), 44.0, 0.85, 22.0, warm],
	])
