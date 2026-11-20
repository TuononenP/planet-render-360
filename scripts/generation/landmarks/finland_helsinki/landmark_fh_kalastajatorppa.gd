extends RefCounted

## Hilton Helsinki Kalastajatorppa (Hotel Kalastajatorppa), Munkkiniemi
## shore. Origin at the OSM hotel relation 7261114 (60.1922, 24.8736, yaw 0;
## the earlier registry point lay 1 km south, in Lauttasaari's bay). The
## hotel is two slabs: the 1969 wing by Markus Tavio and the 1975 curved wing
## by Einari Terasvirta; Jarl Eklund's 1936 functionalist restaurant, the
## original Kalastajatorppa, stands beside them (not separately mapped).
##
## Modelled from the two OSM outer rings: pale rendered slabs with a
## continuous horizontal window ribbon per storey, a darker projecting
## balcony slab line, a recessed top storey and a flat roof with a plant
## box. Measured: both outlines and the 15.2 m LoD2 roof. Estimated: the
## storey pitch (3.4 m, four storeys), balcony depth, plant box and colours;
## the Commons front photo (visual-plan/refs/landmarks/hotel_kalastajatorppa/) shows
## four storeys of white and grey panel with ribbon windows, blue awnings over the
## upper three, and a dark brick stair tower at one end; the model follows that.

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const ENTRY := {"type": "hotel_kalastajatorppa", "name": "Hotel Kalastajatorppa", "lat": 60.1922, "lon": 24.8736,
	"radius_m": 1500.0, "wiki_title": "Hotel Kalastajatorppa", "height_m": 15.2, "clear_m": 24.0,
	"clear_offsets_m": [[-84.0, -23.0], [-84.0, 10.0], [-76.0, -55.0], [10.0, -2.0], [22.0, 28.0],
		[32.0, 58.0], [-10.0, -40.0], [-2.0, 4.0]],
	"kind": "Hotel", "aliases": ["hotel kalastajatorppa", "kalastajatorppa", "fiskartorpet",
		"hilton helsinki kalastajatorppa"]}

const EAST := [-23.9, -51.8, -22.8, -60.1, -17.1, -59.3, -16.6, -62.9, -4.6, -61.3, -4.1, -64.9, 9.3, -63.1, 8.9, -59.8,
	11.8, -59.4, 11.6, -57.5, 5.7, -12.9, 4.2, -11.6, 6.0, -9.5, 6.9, -10.2, 11.0, -4.8, 22.7, 10.3, 32.1, 25.1,
	37.9, 39.1, 40.6, 54.9, 40.5, 68.8, 39.3, 68.6, 38.9, 71.5, 32.7, 70.7, 32.7, 71.6, 20.3, 69.5, 21.2, 62.6,
	20.5, 51.2, 17.5, 39.1, 11.9, 27.7, 4.0, 18.5, -6.0, 9.4, -18.4, 2.9, -31.3, -0.6, -29.8, -8.7, -29.1, -13.1,
	-24.9, -12.5, -20.1, -43.3, -22.8, -49.2]
const WEST := [-88.1, -8.2, -87.0, 2.0, -85.8, 19.3, -83.3, 19.2, -82.9, 25.2, -93.9, 26.0, -96.4, 26.1, -99.9, -23.0,
	-89.4, -23.7, -83.3, -68.9, -82.9, -71.5, -76.6, -70.7, -76.4, -72.4, -68.9, -71.4, -69.7, -65.7, -72.5, -66.1,
	-76.8, -37.2, -67.6, -36.1, -68.0, -31.9, -67.2, -15.5, -75.9, -14.9, -76.5, -9.1]

const PITCH := 3.4
const TOP_M := 15.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E3DFD3", 2.5))
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#B9B4A8", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2F3C42"))
	lm.use("Roof", LandmarkMaterials.paint("#6A6D6E", 0.8))
	lm.use("Awning", LandmarkMaterials.paint("#2F4FA6", 0.7, 0.1))
	lm.use("Chimney", LandmarkMaterials.pbr("brick", "#3A3532", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD9A0", 0.6))
	for flat: Array in [EAST, WEST]:
		var poly := W._poly(flat)
		lm.poly_prism("Wall", poly, 0.0, 13.6)
		# A window ribbon and a projecting slab edge on each of four storeys.
		W.ribbons(lm, "Glass", poly, 1.0, 1.7, 4, PITCH)
		for r in 5:
			lm.poly_prism("Slab", F.offset(poly, 0.25), PITCH * float(r) - 0.12 + 0.12, PITCH * float(r) + 0.2, false)
		lm.poly_prism("Roof", F.offset(poly, -0.2), 13.6, 13.8)
		# Lit ribbon on alternate storeys at night.
		for r in [0, 2]:
			lm.poly_prism("Lamp", F.offset(poly, 0.09), 1.2 + PITCH * float(r), 2.2 + PITCH * float(r), false)
		# Blue awnings over the sea-facing ribbons of the upper three storeys.
		for r in [1, 2, 3]:
			lm.poly_prism("Awning", F.offset(poly, 0.8), PITCH * float(r) + 0.2, PITCH * float(r) + 0.75, false)
		var inner := F.offset(poly, -4.0)
		if inner.size() >= 3:
			lm.poly_prism("Wall", inner, 13.8, TOP_M)
	# The dark brick stair and flue tower at the north end of the west wing.
	lm.box("Chimney", Vector3(-95.0, 8.4, -25.0), Vector3(4.0, 16.8, 4.0))
	lm.commit(model)
