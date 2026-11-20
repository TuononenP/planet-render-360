extends RefCounted

## The House of Nobility (Ritarihuone, Hampus Dalström, 1862), Rauhankatu 1.
## Origin at the OSM outline's bounding-box centre, front +Z toward the park
## (registry yaw -3 keeps the street grid).
##
## Measured: the outline (way 17342988, a 41.6 x 28.6 m rectangle with small
## rear annexes, simplified to 1 m) and its three levels (OSM). The registry
## point lay 30 m from the building. Estimated from visual-plan/refs/
## house_of_nobility_helsinki/ (no LoD2 row in reach): red brick walls on a grey
## granite base, seven tall pointed windows with white Gothic tracery in
## the hall storey, a row of small arched windows at the base, the cream
## corbelled battlement frieze and cornice, the crowned red-and-gold coat of
## arms on the parapet. Storey heights and the 16.5 m top are read from the
## photo scale.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "house_of_nobility_helsinki", "name": "House of Nobility, Helsinki", "lat": 60.169848, "lon": 24.956250,
	"radius_m": 1500.0, "wiki_title": "House of Nobility (Finland)", "height_m": 16.5, "clear_m": 26.0,
	"yaw_deg": -3.0, "kind": "Hall", "aliases": ["house of nobility, helsinki", "ritarihuone", "riddarhuset helsingfors"]}

const OUTLINE := [-20.8, 15.2, 20.8, 15.1, 20.8, -13.7, 5.5, -13.8, 5.5, -15.2, -5.8, -15.2, -5.8, -13.6, -20.1, -13.6]
const EAVE := 14.2
const BASE := 3.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#A9502F", 2.2))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE8D8", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#85817B", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Roof", LandmarkMaterials.paint("#4C5154", 0.6, 0.3))
	lm.use("Crest", LandmarkMaterials.paint("#B23A2E", 0.5, 0.2))
	lm.use("Gold", LandmarkMaterials.gold())
	var p := D.poly(OUTLINE)
	D.block(lm, p, {"eave": EAVE, "plinth": BASE, "cornice": 0.8, "cornice_out": 0.45, "rows": 0})
	U.blk(lm, "Roof", 0.0, EAVE, 0.0, 40.0, 0.2, 27.0)
	var front_a := Vector3(-20.8, 0, 15.15)
	var front_b := Vector3(20.8, 0, 15.1)
	var out := Vector3(0, 0, 1)
	# Seven tall pointed windows with white tracery frames in the hall storey,
	# a row of small arched windows over the granite base.
	P.lancet_row(lm, "Trim", "Glass", front_a + Vector3(7.0, 0, 0), front_b - Vector3(7.0, 0, 0), out, 4.2, 7, 2.7, 7.4, 0.35)
	P.win_row(lm, "Trim", "Glass", front_a, front_b, out, 0.6, 9, 1.0, 1.8, true, 0.2)
	P.win_row(lm, "Trim", "Glass", front_a, front_a + Vector3(6.5, 0, 0), out, 5.0, 2, 1.3, 3.8, true, 0.2)
	P.win_row(lm, "Trim", "Glass", front_b - Vector3(6.5, 0, 0), front_b, out, 5.0, 2, 1.3, 3.8, true, 0.2)
	# The corbelled battlement frieze under the cornice and a string course.
	P.arch_frieze(lm, "Trim", front_a, front_b, out, EAVE - 0.8, 0.9, 0.3)
	P.band(lm, "Trim", front_a, front_b, out, BASE, 0.4, 0.25)
	P.band(lm, "Trim", front_a, front_b, out, 11.4, 0.4, 0.2)
	# Side and rear walls: arched windows in two rows.
	for run in D.runs(p):
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var o: Vector3 = run[2]
		if o.z > 0.5 or a.distance_to(b) < 6.0:
			continue
		var n := maxi(int(round(a.distance_to(b) / 4.2)), 1)
		P.win_row(lm, "Trim", "Glass", a, b, o, 5.0, n, 1.6, 6.2, true, 0.25)
		P.win_row(lm, "Trim", "Glass", a, b, o, 0.8, n, 1.2, 1.8, true, 0.2)
	# Parapet crest: the crowned arms of the nobility.
	U.blk(lm, "Trim", 0.0, EAVE + 0.2, 14.4, 7.0, 1.3, 1.0)
	U.blk(lm, "Crest", 0.0, EAVE + 1.5, 14.4, 3.4, 1.4, 0.5)
	lm.frustum("Gold", Vector3(0, EAVE + 2.9, 14.4), 0.8, 0.5, 0.6, 8)
	lm.commit(model)
	D.flood(model, [
		[Vector3(-14.0, 0.5, 30.0), Vector3(-6.0, 6.0, 15.0), 55.0, 0.9, 40.0, Color(1.0, 0.9, 0.74)],
		[Vector3(14.0, 0.5, 30.0), Vector3(6.0, 6.0, 15.0), 55.0, 0.9, 40.0, Color(1.0, 0.9, 0.74)]])
