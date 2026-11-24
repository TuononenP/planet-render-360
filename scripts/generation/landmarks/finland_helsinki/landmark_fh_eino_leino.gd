extends RefCounted

## Eino Leino Statue (Lauri Leppänen, 1953), Esplanadi park.
##
## Stepped Esplanadi granite base, polished dark-red granite pedestal engraved
## with Leino's verse ("Yksi on laulu ylitse muiden..."), and the expressive
## cloak-wrapped bronze poet rising to exact 4.3 m.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "eino_leino_statue", "name": "Eino Leino Statue",
	"lat": 60.167486, "lon": 24.944260, "radius_m": 1500.0,
	"wiki_title": "Eino Leino", "height_m": 4.3, "clear_m": 5.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["eino leino statue", "eino leinon patsas", "eino leino"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Step", LandmarkMaterials.pbr("stone", "#807D78", 2.0))
	lm.use("RedGranite", LandmarkMaterials.pbr("stone", "#82453E", 1.6))
	lm.use("Bronze", LandmarkMaterials.paint("#2E4138", 0.38, 0.68))
	lm.use("Gold", LandmarkMaterials.gold())

	lm.frustum("Step", Vector3.ZERO, 2.8, 2.8, 0.18, 16)
	lm.frustum("Step", Vector3(0.0, 0.18, 0.0), 2.2, 2.2, 0.16, 16)
	U.blk(lm, "RedGranite", 0.0, 0.34, 0.0, 1.45, 1.01, 1.45)
	for row in 3:
		lm.box("Gold", Vector3(0.0, 1.02 - float(row) * 0.13, 0.74),
			Vector3(0.95 - float(row % 2) * 0.18, 0.05, 0.03), Basis(), 0.0)

	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "eino_leino_poet.glb",
		Vector3(0.0, 1.35, 0.0), Vector3.ONE, 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-3.0, 0.4, 3.0), Vector3(0.0, 2.8, 0.0), 44.0, 0.85, 12.0, warm],
		[Vector3(3.0, 0.4, -3.0), Vector3(0.0, 2.8, 0.0), 44.0, 0.80, 12.0, warm],
	])
