extends RefCounted

## J. K. Paasikivi Monument — "Itä ja länsi" (Harry Kivijärvi, 1980),
## Paasikivenaukio beside Lasipalatsi. Twin sculpted black-granite monoliths
## extracted from City of Helsinki 3D+ Reality Mesh (2024, CC BY 4.0).

const RealityMesh = preload("res://scripts/generation/reality_mesh_kit.gd")

const ENTRY := {"type": "paasikivi_monument", "name": "J. K. Paasikivi Monument",
	"lat": 60.170450, "lon": 24.935550, "radius_m": 1500.0,
	"wiki_title": "Juho Kusti Paasikivi", "height_m": 5.5, "clear_m": 7.0,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["paasikivi monument", "j. k. paasikivi monument", "itä ja länsi", "paasikiven muistomerkki"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#686664", 2.0))
	lm.box("Granite", Vector3(0.0, 0.14, 0.0), Vector3(8.2, 0.28, 6.4))
	lm.commit(model)
	if RealityMesh.add_textured_glb(model, "PaasikiviMonument",
			"res://assets/landmarks/helsinki_3d/paasikivi_monument.glb",
			Vector3(0.0, 0.28, 0.0), Vector3(0.86, 0.86, 0.86), 0.0, 0.65, 0.10) == null:
		var fb := LandmarkMesh.new()
		fb.use("Granite", LandmarkMaterials.pbr("stone", "#323436", 2.0))
		fb.box("Granite", Vector3(-1.4, 2.8, 0.0), Vector3(1.8, 5.2, 2.2))
		fb.box("Granite", Vector3(1.4, 2.4, 0.0), Vector3(1.8, 4.4, 2.2))
		fb.commit(model)
	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-4.5, 0.4, 4.2), Vector3(0.0, 3.2, 0.0), 46.0, 0.85, 16.0, warm],
		[Vector3(4.5, 0.4, -4.2), Vector3(0.0, 3.2, 0.0), 46.0, 0.85, 16.0, warm],
	])
