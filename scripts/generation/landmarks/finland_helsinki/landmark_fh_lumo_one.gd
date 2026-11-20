extends RefCounted

## Lumo One, Kalasatama, 2022.
## Pekka Helin & Co tower of the Redi complex (31 storeys, 120.0 m roof
## height, fi.wikipedia and OSM building:part way 1077211089). Footprint: that OSM
## way about the registry point, yaw 0 (measured). Height 120.0 m is the
## published/OSM figure; the City LoD2 roof reads 117.3 m (docs/helsinki-
## landmark-sources.md). Champagne-toned metal panels and blue glass in long window strips, a glazed top box under a tilted-looking canopy slab.
## Facade colours, bay width and balcony pattern are estimates read from
## Commons photos in visual-plan/refs/landmarks/lumo_one/. The shared curtain-
## wall helpers are in LandmarkFhKalaParts.

const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kala_parts.gd")

const ENTRY := {"type": "lumo_one", "skyline": true, "name": "Lumo One", "lat": 60.187716, "lon": 24.978914,
	"radius_m": 6000.0, "wiki_title": "Redi (shopping centre)", "height_m": 120.0, "clear_m": 25.0,
	"kind": "Tower", "aliases": ["lumo one", "lumo one kalasatama", "lumo one tower"]}

const FLAT := [-8.0, -6.5, -7.5, -9.3, -6.8, -9.1, 12.5, -4.0, 12.1, -1.9, 8.4, 13.6, 8.2, 14.4, -11.0, 9.8]
const TOP_M := 120.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var outline := K.W._poly(FLAT)
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#B2A892", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#6F90A8", 0.22, 0.45))
	lm.use("Mull", LandmarkMaterials.paint("#C9BFA8", 0.45, 0.5))
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#CBC2AC", 3.0))
	lm.use("Rail", LandmarkMaterials.glass("#8FA7B3"))
	lm.use("Canopy", LandmarkMaterials.paint("#D6D1C4", 0.5, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD58A", 0.6))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2A1A", 1.2))
	var crown := {"lounge": 3.6, "inset": 1.0, "ov": 2.6, "shift": Vector2(-2.2, -2.2)}
	var shaft_top := TOP_M - 4.05
	var pitch := shaft_top / 30.0
	# The shaft narrows a little with height: three stacked lifts, each inset
	# 0.45 m from the one below.
	var lifts := 3
	for k in lifts:
		var y0 := pitch * 10.0 * float(k)
		var y1 := pitch * 10.0 * float(k + 1)
		var ring := K.F.offset(outline, -0.45 * float(k))
		K.shaft(lm, ring, y0, y1, {"pitch": pitch, "bay": 1.8, "glass_from": 0.12, "glass_to": 0.82,
			"lit": 0.06, "seed": 7 + k, "bal_every": 3, "bal_mod": 5, "bal_shift": 2, "bal_out": 1.2,
			"slab_h": 0.34, "slab_out": 0.18})
	outline = K.F.offset(outline, -0.9)
	var top := K.crown(lm, outline, shaft_top, crown)
	model.set_meta(LandmarkLights.HALO_META, K.beacons(lm, outline, top, crown))
	lm.commit(model)
