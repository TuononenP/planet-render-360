extends RefCounted

## Three Smiths Statue (Kolmen sepän patsas, Felix Nylund, 1932),
## Kolmensepänaukio outside Stockmann on Mannerheimintie / Aleksanterinkatu.
## Extracted from City of Helsinki 3D+ Reality Mesh (2024, CC BY 4.0) on a
## stepped granite sett apron with warm plaza uplighting.

const RealityMesh = preload("res://scripts/generation/reality_mesh_kit.gd")

const ENTRY := {"type": "three_smiths_statue", "name": "Three Smiths Statue",
	"lat": 60.1686688, "lon": 24.9409553, "radius_m": 1500.0,
	"wiki_title": "Three Smiths Statue", "height_m": 4.8, "clear_m": 6.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["three smiths statue", "three smiths", "kolmen sepän patsas", "tre smeder"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7E7770", 2.0))
	lm.use("RedGranite", LandmarkMaterials.pbr("stone", "#864D44", 1.8))
	lm.use("Bronze", LandmarkMaterials.paint("#2F3C34", 0.42, 0.65))
	# Stepped circular granite apron & lower plinth ring
	lm.frustum("Granite", Vector3.ZERO, 3.6, 3.6, 0.18, 24)
	lm.frustum("Granite", Vector3(0.0, 0.18, 0.0), 3.0, 3.0, 0.18, 24)
	lm.frustum("RedGranite", Vector3(0.0, 0.36, 0.0), 1.9, 1.8, 0.68, 20)
	lm.commit(model)
	if RealityMesh.add_textured_glb(model, "ThreeSmiths",
			"res://assets/landmarks/helsinki_3d/three_smiths.glb",
			Vector3(0.0, 1.04, 0.0), Vector3(1.02, 1.02, 1.02), 0.0, 0.68, 0.18) == null:
		var fb := LandmarkMesh.new()
		fb.use("Bronze", LandmarkMaterials.paint("#2F3C34", 0.42, 0.65))
		LandmarkKits.statue_figure(fb, "Bronze", Vector3(0.0, 1.04, 0.0), 3.76, true)
		fb.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-3.5, 0.4, 3.5), Vector3(0.0, 3.2, 0.0), 44.0, 0.85, 14.0, warm],
		[Vector3(3.5, 0.4, -3.5), Vector3(0.0, 3.2, 0.0), 44.0, 0.85, 14.0, warm],
	])
