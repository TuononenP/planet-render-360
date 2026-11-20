extends RefCounted

## Visio, Kalasatama residential tower, 2023.
## Pekka Helin & Co tower of the Redi complex (24 storeys, 98.0 m roof
## height, fi.wikipedia and OSM building:part way 1020243045). Footprint: that OSM
## way about the registry point, yaw 0 (measured). Height 98.0 m is the
## published/OSM figure; the City LoD2 roof reads 93.9 m (docs/helsinki-
## landmark-sources.md). Pale blue-green glass tower of 240 flats with a rounded-looking ten-sided plan, balconies on a diagonal rhythm and a plain flat crown with a thin canopy and plant box.
## Facade colours, bay width and balcony pattern are estimates read from
## Commons photos in visual-plan/refs/landmarks/visio/. The shared curtain-
## wall helpers are in LandmarkFhKalaParts.

const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kala_parts.gd")

const ENTRY := {"type": "visio", "skyline": true, "name": "Visio, Kalasatama", "lat": 60.186869, "lon": 24.977701,
	"radius_m": 6000.0, "wiki_title": "Redi (shopping centre)", "height_m": 98.0, "clear_m": 30.0,
	"kind": "Tower", "aliases": ["visio, kalasatama", "visio kalasatama", "kalasataman visio"]}

const FLAT := [-7.7, -10.0, -16.3, 16.0, -13.8, 17.0, 5.3, 23.9, 15.1, -2.1, 16.0, -4.6, 5.6, -6.9, 4.7, -7.1, 3.6, -7.4, -4.7, -9.2]
const TOP_M := 98.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var outline := K.W._poly(FLAT)
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#BFCBCB", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#7FA8AE", 0.22, 0.45))
	lm.use("Mull", LandmarkMaterials.paint("#D8DEDE", 0.5, 0.3))
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#C9D1D1", 3.0))
	lm.use("Rail", LandmarkMaterials.glass("#9FBAC0"))
	lm.use("Canopy", LandmarkMaterials.paint("#CDD3D3", 0.55, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD58A", 0.6))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2A1A", 1.2))
	var crown := {"lounge": 2.2, "inset": 0.6, "ov": 0.9, "shift": Vector2.ZERO, "struts": false}
	var shaft_top := TOP_M - 2.65
	var pitch := (shaft_top - 2.0) / 23.0
	K.shaft(lm, outline, 0.0, shaft_top, {"pitch": pitch, "bay": 1.7, "glass_from": 0.1, "glass_to": 0.85,
		"lit": 0.06, "seed": 13, "bal_every": 2, "bal_mod": 3, "bal_shift": 1, "bal_out": 1.4, "slab_h": 0.22})
	var top := K.crown(lm, outline, shaft_top, crown)
	var plant := K.F.offset(outline, -6.0)
	if plant.size() >= 3:
		lm.poly_prism("Panel", plant, top, top + 0.9)
	model.set_meta(LandmarkLights.HALO_META, K.beacons(lm, outline, top, crown))
	lm.commit(model)
