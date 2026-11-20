extends RefCounted

## Majakka (Lighthouse), Kalasatama, 2019.
## Pekka Helin & Co tower of the Redi complex (35 storeys, 134.0 m roof
## height, fi.wikipedia and OSM building:part way 1076677105). Footprint: that OSM
## way about the registry point, yaw 0 (measured). Height 134.0 m is the
## published/OSM figure; the City LoD2 roof reads 129.1 m (docs/helsinki-
## landmark-sources.md). Grey glass tower on an irregular bent plan; its glazed top box carries a small cantilevered roof canopy toward the north-west.
## Facade colours, bay width and balcony pattern are estimates read from
## Commons photos in visual-plan/refs/landmarks/majakka/. The shared curtain-
## wall helpers are in LandmarkFhKalaParts.

const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kala_parts.gd")

const ENTRY := {"type": "majakka", "skyline": true, "skyline_priority": 1, "name": "Majakka", "lat": 60.187531, "lon": 24.979657,
	"radius_m": 6000.0, "wiki_title": "Majakka", "height_m": 134.0, "clear_m": 26.0,
	"kind": "Tower", "aliases": ["majakka", "majakka kalasatama", "majakka tower helsinki"]}

const FLAT := [-9.7, 9.6, 7.1, 11.8, 8.3, 2.8, 13.1, 3.5, 14.8, -10.5, -3.6, -16.6, -4.4, -13.0, -7.1, -1.5, -8.5, 4.5]
const TOP_M := 134.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var outline := K.W._poly(FLAT)
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#98A0A4", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#6F8A9A", 0.22, 0.45))
	lm.use("Mull", LandmarkMaterials.paint("#C6CBCD", 0.5, 0.4))
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#AEB4B7", 3.0))
	lm.use("Canopy", LandmarkMaterials.paint("#D9DBDB", 0.5, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD58A", 0.6))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2A1A", 1.2))
	var crown := {"lounge": 3.6, "inset": 1.4, "ov": 1.4, "shift": Vector2(-2.4, -1.6)}
	var shaft_top := TOP_M - 4.05
	var pitch := (shaft_top - 2.0) / 34.0
	K.shaft(lm, outline, 0.0, shaft_top, {"pitch": pitch, "bay": 1.5, "skip": 0, "lit": 0.06, "seed": 3, "mull_w": 0.24, "slab_h": 0.5, "slab_out": 0.14})
	var top := K.crown(lm, outline, shaft_top, crown)
	model.set_meta(LandmarkLights.HALO_META, K.beacons(lm, outline, top, crown))
	lm.commit(model)
