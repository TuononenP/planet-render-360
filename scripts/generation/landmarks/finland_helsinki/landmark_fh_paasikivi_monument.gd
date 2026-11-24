extends RefCounted

## J. K. Paasikivi Monument — "Itä ja länsi" / East and West (Harry Kivijärvi, 1980),
## Paasikivenaukio beside Lasipalatsi.
##
## Circular polished granite plaza disc with concentric stone kerb and shallow
## reflective water ring, supporting Kivijärvi's two iconic curved black-diorite
## monoliths (smooth polished concave inner faces, horizontal hand-chiseled
## ribbed outer faces) rising to exact 5.5 m.

const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "paasikivi_monument", "name": "J. K. Paasikivi Monument",
	"lat": 60.170450, "lon": 24.935550, "radius_m": 1500.0,
	"wiki_title": "Juho Kusti Paasikivi", "height_m": 5.5, "clear_m": 7.0,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["paasikivi monument", "j. k. paasikivi monument", "itä ja länsi", "paasikiven muistomerkki"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("PlazaStone", LandmarkMaterials.pbr("stone", "#7C7872", 2.2))
	lm.use("BlackDiorite", LandmarkMaterials.marble("#222528", 0.24))
	lm.use("Water", LandmarkMaterials.pool_water("#1E3038", 0.03))
	lm.use("Gold", LandmarkMaterials.gold())

	# Circular granite plaza kerb & shallow reflective basin disc
	lm.frustum("PlazaStone", Vector3.ZERO, 4.6, 4.5, 0.28, 36)
	lm.disc("Water", Vector3(0.0, 0.29, 0.0), Vector3.UP, 4.15, 36)
	lm.frustum("BlackDiorite", Vector3(0.0, 0.10, 0.0), 2.55, 2.50, 0.22, 32)
	lm.box("Gold", Vector3(0.0, 0.30, 4.32), Vector3(1.15, 0.04, 0.18), Basis(), 0.0)

	# Twin sculpted curved black-diorite monoliths with chiseled horizontal outer ribs (0.28..5.50 m exact!)
	SculptureKit.stamp_path(lm, "BlackDiorite", ASSET_DIR + "paasikivi_monoliths.glb",
		Vector3(0.0, 0.28, 0.0), Vector3.ONE, 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-4.5, 0.4, 4.2), Vector3(0.0, 3.2, 0.0), 46.0, 0.90, 16.0, warm],
		[Vector3(4.5, 0.4, -4.2), Vector3(0.0, 3.2, 0.0), 46.0, 0.90, 16.0, warm],
	])
