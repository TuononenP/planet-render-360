extends RefCounted

## Elias Lönnrot Monument (Emil Wikström, 1902), Lönnrotinpuistikko.
##
## Stepped granite park terrace, tiered dark-granite monument pedestal engraved
## with "SAIN SANAT SALASTA ILMI" and the Antero Vipunen / Väinämöinen relief,
## seated bronze Elias Lönnrot writing down Kalevala verses at the summit, and
## the lyric maiden Impi (Kanteletar) seated on the lower front-right ledge
## reaching upward to exact 6.5 m.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "lonnrot_monument", "name": "Elias Lönnrot Monument",
	"lat": 60.166675, "lon": 24.938325, "radius_m": 1500.0,
	"wiki_title": "Elias Lönnrot", "height_m": 6.5, "clear_m": 6.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["elias lönnrot monument", "elias lonnrot statue", "lönnrotin patsas", "lonnrotin patsas"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Step", LandmarkMaterials.pbr("stone", "#807C76", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#5C5652", 1.8))
	lm.use("Bronze", LandmarkMaterials.paint("#2D3F36", 0.38, 0.68))
	lm.use("Gold", LandmarkMaterials.gold())

	# Stepped granite park platform
	lm.box("Step", Vector3(0.0, 0.12, 0.0), Vector3(6.4, 0.24, 5.8))
	lm.box("Step", Vector3(0.0, 0.36, 0.0), Vector3(5.2, 0.24, 4.6))
	# Tiered dark-granite monument crag & pedestal + lower front-right seat for Impi
	U.blk(lm, "Granite", 0.0, 0.48, 0.0, 3.8, 0.55, 3.2)
	U.blk(lm, "Granite", 1.05, 1.03, 0.85, 1.35, 0.82, 1.35)
	U.blk(lm, "Granite", -0.15, 1.03, 0.0, 2.35, 2.65, 2.15)
	U.blk(lm, "Granite", -0.15, 3.68, 0.0, 2.55, 0.28, 2.35)

	# Gilt Kalevala inscription ("SAIN SANAT SALASTA ILMI") & bronze Vipunen relief on +X side
	lm.box("Gold", Vector3(-0.15, 2.55, 1.10), Vector3(1.55, 0.12, 0.04), Basis(), 0.0)
	lm.box("Gold", Vector3(-0.15, 2.32, 1.10), Vector3(1.30, 0.09, 0.04), Basis(), 0.0)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "topelius_medallion.glb",
		Vector3(1.04, 2.15, 0.0), Vector3(1.15, 1.15, 1.15), PI * 0.5)

	# Seated Elias Lönnrot + lyric maiden Impi + kantele (1.30..6.50 m exact!)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "lonnrot_ensemble.glb",
		Vector3(0.0, 1.30, 0.0), Vector3.ONE, 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-4.0, 0.4, 4.0), Vector3(0.0, 4.2, 0.0), 44.0, 0.85, 15.0, warm],
		[Vector3(4.0, 0.4, -4.0), Vector3(0.0, 4.2, 0.0), 44.0, 0.80, 15.0, warm],
	])
