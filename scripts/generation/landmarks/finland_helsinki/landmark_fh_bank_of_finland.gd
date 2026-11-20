extends RefCounted

## The Bank of Finland main building (Suomen Pankki, Hampus Dalström, 1883),
## Snellmaninkatu 2 / Rauhankatu. Origin at the OSM outline's bounding-box
## centre, front +Z toward Snellmaninkatu (registry yaw 87 turns +Z west).
##
## Measured: the outline (way 17359600, simplified to 1 m: the 62 m street front
## with its recessed 25 m centre between two projecting pavilions, the
## wings and inner courts behind it). The registry point lay 70 m from the
## building. Estimated from visual-plan/refs/bank_of_finland/ (no LoD2 row in
## reach): pale grey-pink granite, a rusticated base with round-headed
## windows, a piano nobile with pedimented windows between the pavilions, the
## deep entablature with its roundel frieze and low hipped roof, the pilastered
## pavilions with blind arches, the broad granite stair and the bronze
## Snellman statue on its pedestal. Storey heights and the 21 m top are read
## from the photo scale.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "bank_of_finland", "name": "Bank of Finland", "lat": 60.171169, "lon": 24.952223,
	"radius_m": 1500.0, "wiki_title": "Bank of Finland", "height_m": 21.0, "clear_m": 40.0,
	"yaw_deg": 87.0, "kind": "Bank", "aliases": ["bank of finland", "suomen pankki", "finlands bank"]}

const OUTLINE := [-31.4, 30.4, -31.6, 17.4, -26.9, 17.3, -26.8, 14.9, -13.7, 14.8, -13.8, 1.6, -19.9, 1.6, -19.9, -5.0, -23.1, -5.0, -23.1, -22.7,
	-20.2, -22.7, -20.3, -30.0, -13.4, -30.1, -13.3, -26.9, 11.8, -27.2, 11.7, -30.4, 18.6, -30.4, 18.6, -23.1, 25.6, -23.1, 25.8, -7.5,
	31.3, -7.5, 31.4, 0.0, 25.0, 0.1, 25.0, -4.0, 18.8, -3.9, 12.6, 1.4, 12.7, 14.6, 25.7, 14.5, 25.6, 4.9, 31.4, 4.8, 31.6, 16.9, 30.7, 29.7]
const EAVE := 18.6
const BASE := 7.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#CFC4B4", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#DDD5C6", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A69A92", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4A4846", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Roof", LandmarkMaterials.paint("#58605E", 0.6, 0.3))
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#4E6E5E", 2.0, 0.5, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#F6E8BC", 0.4))
	var p := D.poly(OUTLINE)
	D.block(lm, p, {"eave": EAVE, "plinth": 1.2, "stone": "Stone", "cornice": 1.6, "cornice_out": 0.8, "course_y": BASE,
		"bay": 4.2, "win": Vector2(1.9, 3.8), "sill": 1.1, "y0": 1.6, "storey": 6.4, "rows": 2, "depth": 0.3, "min_len": 6.0})
	D.slab(lm, "Trim", p, 0.2, BASE + 6.0, 0.35)
	# Low hipped roof behind the deep entablature.
	D.slab(lm, "Roof", D.grow(p, -0.6), 0.0, EAVE, 2.4)
	# Rustication: horizontal joints across the base of the street front.
	var a := Vector3(-31.4, 0, 30.5)
	var b := Vector3(30.7, 0, 29.8)
	for k in range(1, 6):
		P.band(lm, "Dark", a, b, Vector3(0, 0, 1), 1.2 + 1.0 * float(k), 0.07, 0.04)
	# The five-bay centre: tall pedimented windows on the piano nobile.
	P.win_row(lm, "Trim", "Glass", Vector3(-11.0, 0, 27.0), Vector3(11.0, 0, 27.0), Vector3(0, 0, 1), BASE + 1.0, 5, 1.9, 4.4, true, 0.3)
	P.win_row(lm, "Trim", "Glass", Vector3(-11.0, 0, 27.0), Vector3(11.0, 0, 27.0), Vector3(0, 0, 1), 1.4, 5, 1.8, 3.6, true, 0.3)
	P.band(lm, "Trim", Vector3(-12.3, 0, 27.0), Vector3(12.8, 0, 27.0), Vector3(0, 0, 1), EAVE - 3.0, 1.2, 0.35)
	# Granite stair, Snellman on his pedestal, two flagpoles.
	U.steps(lm, "Stone", Vector3(0.3, 0, 27.0), Vector3(0, 0, 1), 24.0, 0.7, 0.18, 9)
	U.blk(lm, "Dark", 0.3, 0.0, 36.5, 3.4, 4.0, 3.4)
	lm.frustum("Bronze", Vector3(0.3, 4.0, 36.5), 0.75, 0.55, 1.9, 10)
	lm.lathe("Bronze", Vector3(0.3, 5.9, 36.5), U.ball(0.38), 8)
	for s in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(0.3 + s * 8.0, 0.0, 33.0), Vector3(0.3 + s * 8.0, 13.0, 33.0), 0.15)
	lm.commit(model)
	D.flood(model, [
		[Vector3(-22.0, 0.5, 46.0), Vector3(-10.0, 10.0, 30.0), 55.0, 0.9, 50.0, Color(1.0, 0.92, 0.78)],
		[Vector3(22.0, 0.5, 46.0), Vector3(10.0, 10.0, 30.0), 55.0, 0.9, 50.0, Color(1.0, 0.92, 0.78)]])
