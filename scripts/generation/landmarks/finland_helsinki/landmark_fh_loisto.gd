extends RefCounted

## Loisto (Light), Kalasatama, 2021.
## Pekka Helin & Co tower of the Redi complex (32 storeys, 124.0 m roof
## height, fi.wikipedia and OSM building:part way 1075173606). Footprint: that OSM
## way about the registry point, yaw 0 (measured). Height 124.0 m is the
## published/OSM figure; the City LoD2 roof reads 121.9 m (docs/helsinki-
## landmark-sources.md). The lightest of the five: white panels and pale blue glass, white balcony fins staggered up the faces, a glazed top box under a thin white canopy.
## Facade colours, bay width and balcony pattern are estimates read from
## Commons photos in visual-plan/refs/landmarks/loisto/. The shared curtain-
## wall helpers are in LandmarkFhKalaParts.

const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kala_parts.gd")

const ENTRY := {"type": "loisto", "skyline": true, "skyline_priority": 1, "name": "Loisto", "lat": 60.187331, "lon": 24.980888,
	"radius_m": 6000.0, "wiki_title": "Redi (shopping centre)", "height_m": 124.0, "clear_m": 26.0,
	"kind": "Tower", "aliases": ["loisto", "loisto kalasatama", "loisto tower"]}

const FLAT := [-7.9, -10.7, 13.5, -5.5, 10.7, 1.0, 8.8, 5.6, 10.1, 6.1, 7.7, 14.3, -14.0, 6.2, -12.1, 1.0, -9.0, -7.7]
const TOP_M := 124.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var outline := K.W._poly(FLAT)
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#DADCDA", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#8FB1C6", 0.22, 0.45))
	lm.use("Mull", LandmarkMaterials.paint("#EDEEEC", 0.5, 0.3))
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#E6E7E4", 3.0))
	lm.use("Rail", LandmarkMaterials.glass("#9DB5C2"))
	lm.use("Canopy", LandmarkMaterials.paint("#F0F0EE", 0.5, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD58A", 0.6))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2A1A", 1.2))
	var crown := {"lounge": 3.4, "inset": 1.2, "ov": 2.2, "shift": Vector2(1.8, 1.2)}
	var shaft_top := TOP_M - 3.85
	var pitch := (shaft_top - 2.0) / 31.0
	K.shaft(lm, outline, 0.0, shaft_top, {"pitch": pitch, "bay": 1.6, "lit": 0.06, "seed": 5,
		"bal_every": 2, "bal_mod": 4, "bal_shift": 1, "bal_out": 1.3, "slab_h": 0.18})
	var top := K.crown(lm, outline, shaft_top, crown)
	model.set_meta(LandmarkLights.HALO_META, K.beacons(lm, outline, top, crown))
	lm.commit(model)
