extends RefCounted

## Topelius Monument — "Taru ja totuus" / Fact and Fable (Ville Vallgren, 1932),
## Esplanadi park. Hybrid build: crisp granite terrace & pedestal + City of
## Helsinki 3D+ Reality Mesh (2024, CC BY 4.0) twin bronze figures.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "topelius_statue", "name": "Topelius Monument (Taru ja totuus)",
	"lat": 60.1674774, "lon": 24.9448067, "radius_m": 1500.0,
	"wiki_title": "Zachris Topelius", "height_m": 4.5, "clear_m": 5.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["topelius statue", "topelius monument", "taru ja totuus", "fact and fable"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86827C", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#36483E", 0.42, 0.65))
	lm.frustum("Granite", Vector3.ZERO, 2.7, 2.7, 0.22, 16)
	lm.frustum("Granite", Vector3(0.0, 0.22, 0.0), 2.1, 2.1, 0.20, 16)
	U.blk(lm, "Granite", 0.0, 0.42, 0.0, 1.75, 0.45, 1.75)
	if not SculptureKit.stamp_path(lm, "Bronze",
			"res://assets/landmarks/helsinki_3d/topelius_statue.glb",
			Vector3(0.0, 0.86, 0.0), Vector3(0.73, 0.73, 0.73), 0.0):
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(0.0, 0.86, 0.0), 3.64, false)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-2.8, 0.4, 2.8), Vector3(0.0, 2.8, 0.0), 44.0, 0.8, 12.0, warm],
	])
