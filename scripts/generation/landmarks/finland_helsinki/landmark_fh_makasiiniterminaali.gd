extends RefCounted

## Makasiini Terminal (Makasiiniterminaali, Makasiinilaituri, South Harbour):
## the Tallink Silja terminal on the pier by Kauppatori. Front +Z is the
## landward face with the entrance and the sign; the registry yaw (51) puts it
## south-west and runs the long axis along the pier, north-west to
## south-east.
##
## From the Commons photos in visual-plan/refs/landmarks/makasiiniterminaali/:
## - a two-storey hall, dark red-brown brick below and a pale grey-white
##   upper storey with a continuous band of small white-framed windows, under a
##   wide low hipped roof of light-grey sheet metal with deep eaves;
## - on the front a glazed entrance bay and, over it, a lit sign
##   MAKASIINITERMINAALI / MAGASINSTERMINALEN (visible at night);
## - beside the hall a long elevated passenger gangway, a grey-clad box with
##   glazed bands carried on steel legs along the quay, ending in a taller
##   dark tower marked M4 in red and a steel gantry over the berth.
##
## OSM maps no building here, so the position is the OSM node "Makasiini-
## terminaali" (60.16399, 24.95556), which also corrects the old registry
## point, 150 m away in the water. Measured: that position and the pier's
## axis (way 1549459636, 131 x 24 m). Everything else is estimated from
## photographs: the hall (50 x 24 m, eaves 9.4 m, ridge 12.2 m), storey
## heights, window rhythm, and the gangway (46 m, 5 m wide).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "makasiiniterminaali", "name": "Makasiini Terminal", "lat": 60.16399, "lon": 24.95556,
	"radius_m": 1500.0, "wiki_title": "South Harbour, Helsinki", "height_m": 12.2, "clear_m": 30.0,
	"yaw_deg": 51.0, "kind": "Ferry terminal", "aliases": ["makasiini terminal", "makasiiniterminaali", "magasinsterminalen"]}

const W := 50.0
const D := 24.0
const STOREY := 4.8
const EAVE := 9.4
const RISE := 2.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#6E3028", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D8D8D2", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#B7BBBE", 0.45, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#33444C"))
	lm.use("White", LandmarkMaterials.paint("#EDEDEA", 0.5, 0.3))
	lm.use("Panel", LandmarkMaterials.paint("#8E9398", 0.5, 0.6))
	lm.use("Dark", LandmarkMaterials.paint("#2D2B2B", 0.6, 0.4))
	lm.use("Lamp", LandmarkMaterials.lit("#F2EBD0", 0.9))
	_hall(lm)
	_gangway(lm)
	lm.commit(model)

static func _hall(lm: LandmarkMesh) -> void:
	var hw := W * 0.5
	var hd := D * 0.5
	U.blk(lm, "Brick", 0.0, 0.0, 0.0, W, STOREY, D)
	U.blk(lm, "Wall", 0.0, STOREY, 0.0, W, EAVE - STOREY, D)
	U.blk(lm, "Panel", 0.0, EAVE - 0.35, 0.0, W + 0.5, 0.35, D + 0.5)
	U.hip(lm, "Roof", Vector3(0, EAVE, 0), W + 2.4, D + 2.4, RISE, 0.35)
	# Roof lights and plant on the ridge.
	for x: float in [-14.0, -4.0, 8.0, 18.0]:
		U.blk(lm, "Panel", x, EAVE + RISE - 0.1, 0.0, 2.4, 0.5, 1.6)
	var out := Vector3(0, 0, 1)
	# Lower storey: brick with a band of low windows, the glazed entrance bay.
	P.win_row(lm, "White", "Glass", Vector3(-hw + 2.0, 0, hd), Vector3(-9.0, 0, hd), out, 1.2, 5, 2.4, 1.8, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(9.0, 0, hd), Vector3(hw - 2.0, 0, hd), out, 1.2, 5, 2.4, 1.8, false, 0.15)
	lm.box("Glass", Vector3(0, 2.2, hd + 0.1), Vector3(14.0, 3.6, 0.2))
	P.ribs(lm, "White", Vector3(-7.0, 0, hd + 0.1), Vector3(7.0, 0, hd + 0.1), out, 0.4, 4.0, 1.75, 0.12, 0.12)
	lm.box("Panel", Vector3(0, 4.15, hd + 1.4), Vector3(16.0, 0.3, 3.0))
	for x: float in [-7.2, 7.2]:
		lm.beam("White", Vector3(x, 0.0, hd + 2.7), Vector3(x, 4.0, hd + 2.7), 0.25, 0.25, Vector3.BACK)
	# Upper storey: ribbon windows round all four sides.
	P.win_row(lm, "White", "Glass", Vector3(-hw + 1.5, 0, hd), Vector3(hw - 1.5, 0, hd), out, STOREY + 1.3, 20, 1.5, 1.4, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(-hw + 1.5, 0, -hd), Vector3(hw - 1.5, 0, -hd), Vector3(0, 0, -1), STOREY + 1.3, 20, 1.5, 1.4, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(-hw + 1.5, 0, -hd), Vector3(hw - 1.5, 0, -hd), Vector3(0, 0, -1), 1.2, 16, 1.5, 1.4, false, 0.15)
	for s: float in [-1.0, 1.0]:
		P.win_row(lm, "White", "Glass", Vector3(s * hw, 0, -hd + 2.0), Vector3(s * hw, 0, hd - 2.0), Vector3(s, 0, 0), STOREY + 1.3, 8, 1.5, 1.4, false, 0.15)
		P.win_row(lm, "White", "Glass", Vector3(s * hw, 0, -hd + 2.0), Vector3(s * hw, 0, hd - 2.0), Vector3(s, 0, 0), 1.2, 8, 1.5, 1.4, false, 0.15)
	# The lit sign band over the entrance.
	lm.box("Dark", Vector3(0, STOREY + 0.1, hd + 0.12), Vector3(18.0, 0.9, 0.16))
	lm.box("Lamp", Vector3(0, STOREY + 0.1, hd + 0.22), Vector3(16.0, 0.35, 0.1))

## The elevated passenger gangway along the quay and its M4 tower.
static func _gangway(lm: LandmarkMesh) -> void:
	var z := -D * 0.5 - 4.0
	U.blk(lm, "Panel", 47.0, 5.0, z, 46.0, 4.6, 5.2)
	U.blk(lm, "Roof", 47.0, 9.6, z, 46.6, 0.25, 5.6)
	P.win_row(lm, "White", "Glass", Vector3(26.0, 0, z + 2.6), Vector3(66.0, 0, z + 2.6), Vector3(0, 0, 1), 6.4, 6, 3.4, 2.0, false, 0.12)
	P.win_row(lm, "White", "Glass", Vector3(26.0, 0, z - 2.6), Vector3(66.0, 0, z - 2.6), Vector3(0, 0, -1), 6.4, 6, 3.4, 2.0, false, 0.12)
	for x: float in [27.0, 39.0, 51.0, 63.0]:
		for s: float in [-1.0, 1.0]:
			lm.beam("Dark", Vector3(x, 0.0, z + s * 2.2), Vector3(x, 5.0, z + s * 2.2), 0.45, 0.45, Vector3.BACK)
	# Connection to the hall at first-floor level.
	U.blk(lm, "Panel", 24.0, 5.0, z + 2.4, 4.0, 4.0, 5.0)
	# The tower at the far end: dark panels, red M4, a gantry over the berth.
	U.blk(lm, "Dark", 71.5, 0.0, z, 6.0, 12.0, 6.0)
	lm.box("Brick", Vector3(71.5, 8.0, z + 3.05), Vector3(3.0, 0.5, 0.1))
	lm.box("Brick", Vector3(70.3, 6.6, z + 3.05), Vector3(0.5, 3.0, 0.1))
	for a: float in [-1.0, 1.0]:
		lm.beam("Panel", Vector3(77.0, 0.0, z + a * 2.5), Vector3(77.0, 10.0, z + a * 2.5), 0.4, 0.4, Vector3.BACK)
	lm.beam("Panel", Vector3(77.0, 10.0, z - 2.5), Vector3(77.0, 10.0, z + 2.5), 0.4, 0.4, Vector3.UP)
	lm.beam("Panel", Vector3(77.0, 10.0, z), Vector3(86.0, 8.0, z), 0.5, 0.5, Vector3.BACK)
