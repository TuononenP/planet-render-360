extends RefCounted

## Horisontti (Horizon), Kalasatama office tower, 2025.
## Pekka Helin & Co tower of the Redi complex (26 storeys, 109.0 m roof
## height, fi.wikipedia and OSM building:part way 1164189703). Footprint: that OSM
## way about the registry point, yaw 0 (measured). Height 109.0 m is the
## published/OSM figure; the City LoD2 roof reads 108.2 m (docs/helsinki-
## landmark-sources.md). Office tower: white panels in deep bays with bright blue glass bands, a projecting ledge about two fifths up, a glazed sky-lounge level under a canopy on slender struts.
## Facade colours, bay width and balcony pattern are estimates read from
## Commons photos in visual-plan/refs/landmarks/horisontti/. The shared curtain-
## wall helpers are in LandmarkFhKalaParts.

const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kala_parts.gd")

const ENTRY := {"type": "horisontti", "skyline": true, "name": "Horisontti", "lat": 60.187586, "lon": 24.978137,
	"radius_m": 6000.0, "wiki_title": "Horisontti", "height_m": 109.0, "clear_m": 30.0,
	"kind": "Tower", "aliases": ["horisontti", "horisontti kalasatama", "horisontti tower"]}

const FLAT := [8.6, 11.4, 13.4, -9.4, -12.3, -19.3, -18.3, 5.8]
const TOP_M := 109.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var outline := K.W._poly(FLAT)
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#E7E7E2", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#3F73B8", 0.22, 0.45))
	lm.use("Mull", LandmarkMaterials.paint("#EDEDE9", 0.5, 0.3))
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#E2E2DD", 3.0))
	lm.use("Canopy", LandmarkMaterials.paint("#E9EAE7", 0.5, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD58A", 0.6))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2A1A", 1.2))
	var crown := {"lounge": 4.6, "inset": 0.9, "ov": 2.0, "shift": Vector2(1.4, -1.0)}
	var shaft_top := TOP_M - 5.05
	var pitch := (shaft_top - 1.0) / 24.0
	K.shaft(lm, outline, 0.0, shaft_top, {"pitch": pitch, "bay": 2.6, "glass_from": 0.08, "glass_to": 0.92,
		"mull_w": 0.5, "slab_h": 0.0, "lit": 0.06, "seed": 11})
	# The ledge where the lower block meets the slimmer upper shaft.
	lm.poly_prism("Canopy", K.F.offset(outline, 1.6), 0.4 * shaft_top, 0.4 * shaft_top + 0.6)
	var top := K.crown(lm, outline, shaft_top, crown)
	model.set_meta(LandmarkLights.HALO_META, K.beacons(lm, outline, top, crown))
	lm.commit(model)
