extends RefCounted

## Rautatalo (Iron House, Alvar Aalto, 1955), Keskuskatu 3. Origin at the OSM
## outline's bounding-box centre, front +Z toward Keskuskatu (registry yaw 87
## turns +Z onto the west).
##
## Measured: the outline (way 34079465, simplified to 1 m: a 34.4 m street front
## with a 16 m wing, the rear wing 26 m deep), seven storeys (OSM
## building:levels). Estimated from visual-plan/refs/landmarks/rautatalo/
## (the old registry guess of bronze-brown panels was wrong): the street front
## is a grid of dark verdigris copper frames, 14 bays by eight window rows with
## a glazed shop storey under a dark band, a patinated copper fascia, and the
## blank red-brick flank at the south end rising to a stepped copper-capped
## crown. Storey heights and the 28.5 m top are read from the photo scale
## (no LoD2 row within reach); the Aalto atrium inside is not modelled.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "rautatalo", "name": "Rautatalo", "lat": 60.168430, "lon": 24.943575,
	"radius_m": 1500.0, "wiki_title": "Rautatalo", "height_m": 28.5, "clear_m": 28.0,
	"yaw_deg": 87.0, "kind": "Office", "aliases": ["rautatalo", "iron house helsinki", "järnhuset"]}

const OUTLINE := [17.2, 23.9, -17.2, 23.8, -17.2, 7.8, -9.0, 7.9, -8.8, -23.8, 9.1, -23.7, 12.7, -22.2, 17.2, -23.9]
const SHOP := 5.4
const EAVE := 26.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8C4634", 2.4))
	lm.use("Cu", LandmarkMaterials.pbr("copper", "#34524A", 2.5, 0.5, 0.4))
	lm.use("CuPier", LandmarkMaterials.pbr("copper", "#2B443C", 2.5, 0.5, 0.4))
	lm.use("Win", LandmarkMaterials.glass("#5A7078"))
	lm.use("Shop", LandmarkMaterials.glass("#37454B"))
	lm.use("Band", LandmarkMaterials.paint("#26292B", 0.6, 0.3))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#58585A", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#F2E6B8", 0.4))
	var p := D.poly(OUTLINE)
	lm.poly_prism("Brick", p, 0.0, EAVE, false)
	D.slab(lm, "Stone", p, 0.2, 0.0, 0.8)
	D.slab(lm, "Band", p, 0.15, SHOP - 0.5, 0.9)
	D.slab(lm, "Cu", p, 0.3, EAVE - 0.2, 1.4)
	for run in D.runs(p):
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var o: Vector3 = run[2]
		var run_len := a.distance_to(b)
		if run_len < 6.0 or o.x < -0.5:
			continue
		# Glazed shop storey, then the copper frame grid with eight window rows.
		P.pierce(lm, "Band", "Shop", a, b, o, 0.8, SHOP - 1.3, maxi(int(round(run_len / 4.0)), 1), 1,
			Vector2(3.4, 3.2), 0.6, 4.0, 0.25)
		D.pier_run(lm, "Cu", "CuPier", "Win", a, b, o, SHOP + 0.4, EAVE - 0.2, 2.46, 0.38, 0.22,
			Vector2(1.7, 2.15), 0.55, 2.95, 7, 0.3, 6.0)
	# The brick flank at the south end stands taller, with a stepped copper cap.
	U.blk(lm, "Brick", -13.1, EAVE, 15.85, 8.2, 3.2, 16.1)
	U.blk(lm, "Cu", -13.1, EAVE + 3.2, 15.85, 8.8, 0.4, 16.7)
	lm.box("Lamp", Vector3(-17.3, EAVE + 1.8, 8.5), Vector3(0.12, 0.8, 6.0), Basis(), 0.0)
	lm.commit(model)
