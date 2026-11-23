extends RefCounted

## The Bank of Finland main building (Suomen Pankki, Hampus Dalström, 1883),
## Snellmaninkatu 2 / Rauhankatu. Origin at the OSM outline's bounding-box
## centre, front +Z toward Snellmaninkatu (registry yaw 87 turns +Z west).
##
## Neo-Renaissance palace in pale grey-pink granite and limestone render:
## projecting pilastered end pavilions with blind arches, central 5-bay
## rusticated projection with pedimented piano nobile windows, roundel
## entablature frieze, pitched sheet-metal hip roof to 21.0 m, stepped
## granite forecourt stair, and J.V. Snellman's bronze monument on pedestal.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "bank_of_finland", "name": "Bank of Finland", "lat": 60.171169, "lon": 24.952223,
	"radius_m": 1500.0, "wiki_title": "Bank of Finland", "height_m": 21.0, "clear_m": 40.0,
	"yaw_deg": 87.0, "kind": "Bank", "aliases": ["bank of finland", "suomen pankki", "finlands bank"]}

## Street front (+Z) recesses between the two projecting end pavilions, with a
## slight central 5-bay risalit projection.
const OUTLINE := [
	-31.4, 30.4, -31.6, 17.4, -26.9, 17.3, -26.8, 14.9, -13.7, 14.8, -13.8, 1.6,
	-19.9, 1.6, -19.9, -5.0, -23.1, -5.0, -23.1, -22.7, -20.2, -22.7, -20.3, -30.0,
	-13.4, -30.1, -13.3, -26.9, 11.8, -27.2, 11.7, -30.4, 18.6, -30.4, 18.6, -23.1,
	25.6, -23.1, 25.8, -7.5, 31.3, -7.5, 31.4, 0.0, 25.0, 0.1, 25.0, -4.0,
	18.8, -3.9, 12.6, 1.4, 12.7, 14.6, 25.7, 14.5, 25.6, 4.9, 31.4, 4.8,
	31.6, 16.9, 30.7, 30.0, 13.4, 30.1, 13.4, 27.4, 11.4, 27.4, 11.4, 28.4,
	-11.2, 28.4, -11.2, 27.4, -13.6, 27.4, -13.6, 30.3]

const EAVE := 18.6
const BASE := 7.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#CFC4B4", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#DDD5C6", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A69A92", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4A4846", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#58605E", 3.0, 0.55, 0.35))
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#4E6E5E", 2.0, 0.5, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#F6E8BC", 0.5))
	var p := D.poly(OUTLINE)
	D.block(lm, p, {"eave": EAVE, "plinth": 1.2, "stone": "Stone", "cornice": 1.4, "cornice_out": 0.75,
		"course_y": BASE, "bay": 4.2, "win": Vector2(1.9, 3.8), "sill": 1.1, "y0": 1.6, "storey": 6.4,
		"rows": 2, "depth": 0.3, "min_len": 6.0})
	D.slab(lm, "Trim", p, 0.25, BASE + 6.4, 0.45)
	_roofs(lm)
	_street_front(lm)
	_forecourt_and_snellman(lm)
	lm.commit(model)
	D.flood(model, [
		[Vector3(-22.0, 0.8, 45.0), Vector3(-22.0, 10.0, 30.3), 50.0, 0.9, 55.0, Color(1.0, 0.92, 0.78)],
		[Vector3(22.0, 0.8, 45.0), Vector3(22.0, 10.0, 30.0), 50.0, 0.9, 55.0, Color(1.0, 0.92, 0.78)],
		[Vector3(0.0, 0.8, 44.0), Vector3(0.0, 11.0, 28.4), 52.0, 1.0, 55.0, Color(1.0, 0.92, 0.78)],
	])

static func _roofs(lm: LandmarkMesh) -> void:
	# Pitched sheet-metal hip roof over the main street front (eave 18.6 -> top 21.0 m).
	U.hip(lm, "Roof", Vector3(-0.3, EAVE, 22.4), 63.6, 16.4, 2.4, 0.72)
	# Hip roofs over the rear courtyard wings.
	U.hip(lm, "Roof", Vector3(0.0, EAVE, -16.0), 46.0, 28.0, 2.2, 0.65)
	for s in [-1.0, 1.0]:
		U.hip(lm, "Roof", Vector3(s * 22.0, EAVE, 2.0), 14.0, 26.0, 2.0, 0.55)

static func _street_front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	# Central 5-bay rusticated projection (z = 28.4).
	var cz := 28.4
	for k in range(1, 6):
		P.band(lm, "Dark", Vector3(-11.2, 0, cz), Vector3(11.4, 0, cz), out, 1.2 + 1.05 * float(k), 0.08, 0.05)
	for k in range(1, 7):
		P.band(lm, "Dark", Vector3(-11.2, 0, cz), Vector3(11.4, 0, cz), out, BASE + 0.5 + 1.1 * float(k), 0.06, 0.04)
	E.row(lm, "Trim", "Glass", Vector3(-10.0, 0, cz), Vector3(10.0, 0, cz), out, 1.8, 5, 1.8, 3.8, "arch")
	E.row(lm, "Trim", "Glass", Vector3(-10.0, 0, cz), Vector3(10.0, 0, cz), out, BASE + 1.4, 5, 1.8, 4.4, "hood")
	# Projecting end pavilions (west -31.4..-13.6 at z=30.35, east 13.4..30.7 at z=30.05).
	for pav in [[-31.4, -13.6, 30.35], [13.4, 30.7, 30.05]]:
		var x0: float = pav[0]
		var x1: float = pav[1]
		var pz: float = pav[2]
		var cx := (x0 + x1) * 0.5
		var w := x1 - x0
		for k in range(1, 6):
			P.band(lm, "Dark", Vector3(x0, 0, pz), Vector3(x1, 0, pz), out, 1.2 + 1.05 * float(k), 0.08, 0.05)
		P.arcade(lm, "Trim", Vector3(x0 + 1.6, 0, pz), Vector3(x1 - 1.6, 0, pz), out, 1.4, 4.8, 3, 0.22)
		P.win_row(lm, "Trim", "Glass", Vector3(x0 + 2.4, 0, pz), Vector3(x1 - 2.4, 0, pz), out, 1.9, 3, 1.4, 3.2, true, 0.2)
		# Paired giant pilasters flanking a blind-arched piano nobile bay.
		for px in [x0 + 1.0, x0 + 2.6, x1 - 2.6, x1 - 1.0]:
			E.pilaster(lm, "Trim", Vector3(px, 0, pz), out, BASE, EAVE - 2.0 - BASE, 0.75, 0.35)
		LandmarkDetail.arch(lm, "Trim", Vector3(cx, BASE + 5.0, pz), out, w * 0.42, 0.55, 0.32)
		E.win(lm, "Trim", "Glass", Vector3(cx, BASE + 1.4, pz), out, 2.0, 4.4, "arch")
	# Deep entablature frieze with classical roundel medallions across the entire front.
	var fy := EAVE - 2.55
	P.band(lm, "Trim", Vector3(-31.4, 0, 30.35), Vector3(-13.6, 0, 30.35), out, fy, 1.1, 0.25)
	P.band(lm, "Trim", Vector3(-13.6, 0, 28.4), Vector3(13.4, 0, 28.4), out, fy, 1.1, 0.25)
	P.band(lm, "Trim", Vector3(13.4, 0, 30.05), Vector3(30.7, 0, 30.05), out, fy, 1.1, 0.25)
	for seg in [[-30.0, -15.0, 30.4, 5], [-10.0, 10.0, 28.45, 7], [14.8, 29.3, 30.1, 5]]:
		var n: int = seg[3]
		for k in n:
			var rx := lerpf(float(seg[0]), float(seg[1]), (float(k) + 0.5) / float(n))
			var rc := Vector3(rx, fy + 0.55, float(seg[2]) + 0.25)
			P.ring(lm, "Trim", rc, out, 0.28, 0.42, 0.14, 12)
			lm.disc("Dark", rc + Vector3(0, 0, 0.04), out, 0.26, 12)

static func _forecourt_and_snellman(lm: LandmarkMesh) -> void:
	# Stepped granite forecourt stair in front of the central 5-bay projection.
	U.steps(lm, "Stone", Vector3(0.0, 0.0, 28.4), Vector3(0, 0, 1), 22.4, 0.65, 0.18, 9)
	# Flanking granite lamp piers with glowing globes.
	for s in [-1.0, 1.0]:
		U.blk(lm, "Stone", s * 11.4, 0.0, 34.4, 0.9, 2.2, 0.9)
		lm.frustum("Dark", Vector3(s * 11.4, 2.2, 34.4), 0.14, 0.09, 1.4, 8)
		lm.lathe("Lamp", Vector3(s * 11.4, 3.6, 34.4), U.ball(0.26), 10)
	# J.V. Snellman bronze statue (Emil Wikström, 1923) on dark granite pedestal.
	U.blk(lm, "Stone", 0.0, 0.0, 36.2, 4.2, 0.3, 4.2)
	U.blk(lm, "Dark", 0.0, 0.3, 36.2, 3.1, 3.5, 3.1)
	U.blk(lm, "Dark", 0.0, 3.8, 36.2, 3.4, 0.25, 3.4)
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0.0, 4.05, 36.2), 2.8, false)
	for s in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(s * 8.0, 0.0, 33.4), Vector3(s * 8.0, 13.0, 33.4), 0.15)
