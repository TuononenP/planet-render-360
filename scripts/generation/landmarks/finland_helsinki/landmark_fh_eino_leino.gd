extends RefCounted

## Eino Leino Statue (Lauri Leppänen, 1953), Esplanadi park.
## Hybrid build: crisp granite steps & pedestal + City of Helsinki 3D+
## Reality Mesh (2024, CC BY 4.0) bronze poet sculpture.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "eino_leino_statue", "name": "Eino Leino Statue",
	"lat": 60.167486, "lon": 24.944260, "radius_m": 1500.0,
	"wiki_title": "Eino Leino", "height_m": 5.2, "clear_m": 5.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["eino leino statue", "eino leinon patsas", "eino leino"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7E7A74", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#33443B", 0.42, 0.65))
	lm.frustum("Granite", Vector3.ZERO, 2.8, 2.8, 0.22, 16)
	U.blk(lm, "Granite", 0.0, 0.22, 0.0, 1.9, 1.1, 1.9)
	if not SculptureKit.stamp_path(lm, "Bronze",
			"res://assets/landmarks/helsinki_3d/eino_leino.glb",
			Vector3(0.0, 1.32, 0.0), Vector3(1.0, 1.0, 1.0), 0.0):
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(0.0, 1.32, 0.0), 3.88, false)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-3.0, 0.4, 3.0), Vector3(0.0, 3.5, 0.0), 44.0, 0.8, 12.0, warm],
	])
