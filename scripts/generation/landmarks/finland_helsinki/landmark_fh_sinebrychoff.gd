extends RefCounted

## The Sinebrychoff Art Museum (Sinebrychoffin taidemuseo), Bulevardi 40: the
## Sinebrychoff mansion (Nikolai Sinebrychoff's town house, 1842) at the edge of
## Sinebrychoff Park. Origin at the OSM outline's bounding-box centre, front
## +Z on the park side with the polygonal oriel (registry yaw -35 turns the
## block onto the street grid).
##
## Measured: the outline (way 495923233, simplified to 1 m: 44 x 19 m with the
## 4 x 2.7 m oriel on +Z and the cut-back east end) and its three levels. The
## registry point lay 130 m from the building. Estimated from visual-plan/refs/
## sinebrychoff_art_museum/ (no LoD2 row in reach): ochre-yellow stucco, the
## horizontally rusticated ground storey, framed rectangular windows with dark
## brown sashes in two upper rows, 11 bays, the projecting cornice, the shallow
## dark hipped roof with metal-capped chimneys, the two-storey oriel with its
## own small roof. Storey heights and the 14 m top are read from the photo.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "sinebrychoff_art_museum", "name": "Sinebrychoff Art Museum", "lat": 60.162521, "lon": 24.932587,
	"radius_m": 1500.0, "wiki_title": "Sinebrychoff Art Museum", "height_m": 14.0, "clear_m": 24.0,
	"yaw_deg": -35.0, "kind": "Art museum",
	"aliases": ["sinebrychoff art museum", "sinebrychoffin taidemuseo", "konstmuseet sinebrychoff"]}

const OUTLINE := [-22.2, 8.3, 17.2, 8.3, 17.2, 2.0, 19.3, 2.1, 19.7, 0.3, 21.5, 0.5, 22.0, -11.0, -22.2, -11.0]
const EAVE := 11.3

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E3C98E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F0E6C8", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("render", "#D6BC82", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3C2F26"))
	lm.use("Roof", LandmarkMaterials.paint("#474B4D", 0.6, 0.3))
	lm.use("Chimney", LandmarkMaterials.paint("#3A3D3F", 0.6, 0.4))
	var p := D.poly(OUTLINE)
	D.block(lm, p, {"eave": EAVE, "plinth": 0.6, "stone": "Stone", "cornice": 0.9, "cornice_out": 0.45, "course_y": 4.4,
		"bay": 3.6, "pier_w": 0.0, "win": Vector2(1.3, 2.3), "sill": 0.9, "y0": 0.8, "storey": 3.6, "rows": 3,
		"depth": 0.25, "min_len": 6.0})
	D.slab(lm, "Trim", p, 0.12, 4.0, 0.3)
	P.slope_roof(lm, "Roof", D.grow(p, 0.5), Vector2(0.0, -1.0), 0.9, EAVE, EAVE + 1.4)
	# Chimneys with metal caps.
	for x in [-16.0, -8.0, -1.0, 4.0, 11.0, 17.0]:
		U.blk(lm, "Chimney", float(x), EAVE + 1.0, -4.0 + 0.4 * sin(float(x)), 1.7, 2.2, 1.5)
	# The oriel: three-faced bay up two storeys with its own roof.
	var oriel := PackedVector2Array([Vector2(-4.5, 8.3), Vector2(-4.5, 9.7), Vector2(-3.2, 11.0), Vector2(-1.5, 11.0), Vector2(-0.4, 9.7), Vector2(-0.4, 8.3)])
	lm.poly_prism("Wall", oriel, 0.4, 8.0, true)
	D.slab(lm, "Trim", oriel, 0.15, 7.7, 0.35)
	D.slab(lm, "Trim", oriel, 0.15, 3.9, 0.3)
	for run in D.runs(oriel):
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		if a.distance_to(b) < 1.0 or run[2].z < 0.2:
			continue
		P.win_row(lm, "Glass", "Glass", a, b, run[2], 4.6, 1, 0.9, 2.6, false, 0.1)
		P.win_row(lm, "Glass", "Glass", a, b, run[2], 0.9, 1, 0.9, 2.6, false, 0.1)
	U.hip(lm, "Roof", Vector3(-2.45, 8.0, 9.7), 5.0, 3.8, 1.2, 0.2)
	lm.commit(model)
