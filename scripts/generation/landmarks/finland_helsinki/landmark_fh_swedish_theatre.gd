extends RefCounted

## The Swedish Theatre (Svenska Teatern, Georg Theodor Chiewitz, 1866; rebuilt
## 1936), Pohjoisesplanadi 2 at Erottaja. Origin at the OSM outline's bounding-
## box centre, front +Z on the round front (registry yaw 87 turns +Z west).
##
## Measured: the outline (way 1235179609, simplified to 1 m): a 50 x 60 m block
## with the 35 m wide, 17 m deep semicircular front on the +Z side. The registry
## point lay 70 m from the building. Estimated from visual-plan/refs/
## swedish_theatre_helsinki/ (no LoD2 row in reach): the cream-white render,
## the grey stone plinth, two tiers of round-headed windows on the round front
## (six low arched openings, five high), the stepped cornices and the plain attic drum above,
## the low dome behind it, the flat-faced three-storey wings with their
## ordinary window rows, the dark hipped roof. Heights (eave 15.5 m, drum 19 m,
## dome 21 m) are read from the photo scale.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "swedish_theatre_helsinki", "name": "Swedish Theatre", "lat": 60.167376, "lon": 24.943542,
	"radius_m": 1500.0, "wiki_title": "Swedish Theatre (Helsinki)", "height_m": 21.0, "clear_m": 34.0,
	"yaw_deg": 87.0, "kind": "Theatre", "aliases": ["swedish theatre", "svenska teatern", "ruotsalainen teatteri"]}

## The block (the round front is added as a drum on its +Z face).
const BLOCK := [-25.1, 21.2, -24.9, -18.0, -23.8, -18.0, -23.8, -38.4, 24.0, -38.3, 23.9, -18.2, 25.1, -18.2, 24.6, 21.5]
const RC := Vector2(-1.6, 21.3)
const RR := 17.5
const EAVE := 15.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EDE8DA", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F4F0E4", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A857E", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#4C5154", 0.6, 0.3))
	lm.use("Dome", LandmarkMaterials.pbr("copper", "#7B9486", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Win", LandmarkMaterials.glass("#2B3236"))
	lm.use("Lamp", LandmarkMaterials.lit("#F4E7B8", 0.35))
	var b := D.poly(BLOCK)
	D.block(lm, b, {"eave": EAVE, "plinth": 1.4, "cornice": 0.9, "cornice_out": 0.5, "course_y": 5.0, "bay": 3.6,
		"win": Vector2(1.3, 2.2), "sill": 0.9, "y0": 1.4, "storey": 4.6, "rows": 3, "depth": 0.25, "min_len": 6.0})
	U.hip(lm, "Roof", Vector3(0.0, EAVE + 0.3, -8.5), 47.0, 56.0, 2.8, 0.55)
	# The round front: drum to the eave, two tiers of arched windows, string
	# course and cornice, an attic drum and a low dome.
	var c := Vector3(RC.x, 0.0, RC.y)
	lm.frustum("Stone", c, RR + 0.35, RR + 0.35, 1.4, 40)
	lm.frustum("Wall", c + Vector3(0, 1.4, 0), RR, RR, EAVE - 1.4, 40)
	lm.frustum("Trim", c + Vector3(0, 5.2, 0), RR + 0.25, RR + 0.25, 0.5, 40)
	lm.frustum("Trim", c + Vector3(0, EAVE - 0.9, 0), RR + 0.6, RR + 0.6, 0.9, 40)
	lm.frustum("Wall", c + Vector3(0, EAVE, 0), RR - 1.2, RR - 1.2, 3.4, 40)
	lm.frustum("Trim", c + Vector3(0, EAVE + 3.4, 0), RR - 0.6, RR - 0.6, 0.6, 40)
	lm.lathe("Roof", c + Vector3(0, EAVE + 4.0, 0), U.dome_prof(RR - 2.0, 2.2, 8), 32)
	for k in 6:
		var a := PI * (0.12 + 0.76 * float(k) / 5.0)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Win", c + d * RR + Vector3(0, 2.7, 0), d, 1.9, 4.2, true, 0.2)
	for k in 5:
		var a := PI * (0.14 + 0.72 * float(k) / 4.0)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Win", c + d * RR + Vector3(0, 8.5, 0), d, 1.9, 4.6, true, 0.2)
	for k in 4:
		var a := PI * (0.2 + 0.6 * float(k) / 3.0)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Win", c + d * (RR - 1.15) + Vector3(0, EAVE + 1.7, 0), Vector3(1.0, 1.0, 0.1), Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
	# Dim glow from the foyer windows at night.
	lm.box("Lamp", c + Vector3(0, 0.0, 0) + Vector3(0.0, 4.2, RR + 0.1), Vector3(1.6, 3.0, 0.08), Basis(), 0.0)
	lm.commit(model)
	D.flood(model, [
		[Vector3(-1.6, 0.4, 44.0), Vector3(-1.6, 9.0, 36.0), 50.0, 0.9, 40.0, Color(1.0, 0.92, 0.78)],
		[Vector3(-16.0, 0.4, 38.0), Vector3(-8.0, 9.0, 30.0), 50.0, 0.6, 35.0, Color(1.0, 0.92, 0.78)],
		[Vector3(13.0, 0.4, 38.0), Vector3(5.0, 9.0, 30.0), 50.0, 0.6, 35.0, Color(1.0, 0.92, 0.78)]])
