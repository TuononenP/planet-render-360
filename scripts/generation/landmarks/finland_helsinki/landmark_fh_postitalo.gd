extends RefCounted

## Helsinki Main Post Office (Postitalo, 1938, Jorma Järvi and Ilmari
## Niemeläinen), Mannerheimintie / Asema-aukio, built on its OpenStreetMap
## outline (way 122595218, simplified to 0.6 m, recentred on its bounding
## box and turned by the entry's yaw onto the street grid, so the long
## south front runs along X and faces +Z).
##
## From the Commons photos in visual-plan/refs/landmarks/postitalo_helsinki/:
## - The long wings are functionalist ochre-yellow clinker brick, six
##   storeys of narrow upright windows on a module of about 1.8 m, under a
##   projecting green copper cornice, over a low granite base.
## - At the east end of the south front rises the tall wing (16 m wide, the
##   full 99 m depth of the block, per the 1972 aerial), about 41 m to its
##   copper-edged roof: nine pale concrete fins run the full height of its
##   south end with dark glazing between them, plain brick with windows
##   on its long sides, a long copper marquee with the POSTI letters over
##   the entrance, and a mast on the roof.
##
## Measured: the outline (OSM) and the 43.8 m top (LoD2, with the mast).
## Estimated: the 23.8 m eave and 41.5 m tower roof (scaled from the
## photo against the LoD2 top), the module and the window rows.

const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "postitalo_helsinki", "name": "Helsinki Main Post Office", "lat": 60.171565, "lon": 24.938168,
	"radius_m": 1500.0, "wiki_title": "Helsinki Main Post Office", "height_m": 43.8, "clear_m": 55.0,
	"yaw_deg": -7.6, "kind": "Post office",
	"aliases": ["helsinki main post office", "pääpostitalo", "postitalo helsinki", "huvudposthuset"]}

const OUTLINE := [21.0, 25.9, 21.0, 32.4, 33.2, 32.6, 34.6, 33.6, 35.0, 36.0, 38.9, 36.0, 38.9, 40.0, 33.0, 40.0,
	33.1, 49.6, -35.7, 49.6, -35.7, 36.0, -38.7, 36.0, -38.9, -49.6, -8.8, -49.6, -6.1, -48.2, -4.9, -46.3,
	-5.1, -44.3, -8.7, -37.8, -21.8, -37.8, -21.8, -16.2, 5.1, -16.2, 5.0, -49.5, 17.1, -49.5, 17.1, -46.2,
	20.9, -46.2, 20.9, -21.9, 23.4, -21.9, 23.4, -15.7, 20.9, -15.7, 21.0, 20.0, 23.5, 20.0, 23.5, 24.4,
	23.5, 25.9]

const EAVE := 23.8
const TOWER_X0 := 5.0
const TOWER_X1 := 21.0
const TOWER_Z0 := -49.4
const TOWER_Z1 := 49.6
const TOWER_TOP := 41.5
const TOP := 43.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#A97F48", 2.5))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#7C7873", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("limestone", "#B3A98F", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6F9C86", 2.0, 0.5, 0.3))
	lm.use("Window", LandmarkMaterials.paint("#3E4A54", 0.3, 0.4))
	lm.use("Glass", LandmarkMaterials.paint("#4A5762", 0.3, 0.4))
	lm.use("Roof", LandmarkMaterials.paint("#5A5C5E", 0.8))
	lm.use("Lamp", LandmarkMaterials.lit("#EDE6D0", 0.5))
	lm.use("Mast", LandmarkMaterials.paint("#C8CCCC", 0.4, 0.6))
	var poly := PackedVector2Array()
	for i in range(0, OUTLINE.size() - 1, 2):
		poly.append(Vector2(float(OUTLINE[i]), float(OUTLINE[i + 1])))
	lm.poly_prism("Wall", poly, 0.0, EAVE)
	lm.poly_prism("Base", F.offset(poly, 0.25), 0.0, 1.3)
	# Six storeys of narrow upright windows on a 1.8 m module, then the
	# projecting copper cornice and the flat roof.
	W.edge_windows(lm, "Window", poly, 2.1, 6, 3.45, 1.8, 0.95, 2.1)
	lm.poly_prism("Copper", F.offset(poly, 0.45), EAVE - 0.9, EAVE)
	lm.poly_prism("Roof", F.offset(poly, -0.2), EAVE - 0.05, EAVE + 0.1)
	# The tall east wing, 16 m wide and running the full depth of the block to
	# the tracks: brick core, glazed south front between nine pale fins, and a
	# copper-edged flat roof with a mast.
	var tw := TOWER_X1 - TOWER_X0
	var td := TOWER_Z1 - TOWER_Z0
	var cx := (TOWER_X0 + TOWER_X1) * 0.5
	var cz := (TOWER_Z0 + TOWER_Z1) * 0.5
	FhU.blk(lm, "Wall", cx, EAVE - 0.05, cz, tw - 0.1, TOWER_TOP - EAVE, td - 0.1)
	FhU.blk(lm, "Glass", cx, 4.0, TOWER_Z1 + 0.06, tw - 1.2, TOWER_TOP - 5.5, 0.1)
	for k in 9:
		var x := lerpf(TOWER_X0 + 0.6, TOWER_X1 - 0.6, float(k) / 8.0)
		FhU.blk(lm, "Concrete", x, 2.0, TOWER_Z1 + 0.15, 0.55, TOWER_TOP - 2.0, 0.5)
	FhU.blk(lm, "Concrete", cx, TOWER_TOP - 1.2, TOWER_Z1 + 0.15, tw - 0.2, 1.2, 0.5)
	# The wing's long east face and its end faces carry the same upright
	# windows as the lower wings, on the upper storeys.
	FhU.window_grid(lm, "Window", Vector3(TOWER_X1 + 0.02, 0, -46.0), Vector3(TOWER_X1 + 0.02, 0, 24.0), Vector3(1, 0, 0),
		EAVE + 0.4, 5, 3.45, 38, 0.95, 2.1)
	FhU.window_grid(lm, "Window", Vector3(TOWER_X0 - 0.02, 0, -47.0), Vector3(TOWER_X0 - 0.02, 0, -18.0), Vector3(-1, 0, 0),
		EAVE + 0.4, 5, 3.45, 16, 0.95, 2.1)
	FhU.window_grid(lm, "Window", Vector3(TOWER_X0 + 1.0, 0, TOWER_Z0 - 0.02), Vector3(TOWER_X1 - 1.0, 0, TOWER_Z0 - 0.02),
		Vector3(0, 0, -1), 2.1, 11, 3.45, 8, 0.95, 2.1)
	lm.box("Copper", Vector3(cx, TOWER_TOP + 0.2, cz), Vector3(tw + 1.0, 0.5, td + 1.0))
	lm.box("Roof", Vector3(cx, TOWER_TOP + 0.55, cz), Vector3(tw - 0.4, 0.3, td - 0.4))
	lm.frustum("Mast", Vector3(cx + 3.0, TOWER_TOP + 0.5, TOWER_Z1 - 8.0), 0.1, 0.04, TOP - TOWER_TOP - 0.5, 6)
	# Entrance marquee in copper with the lit POSTI letters, under the fins.
	lm.box("Copper", Vector3(cx, 5.2, TOWER_Z1 + 1.9), Vector3(tw + 0.6, 0.5, 3.8))
	lm.box("Copper", Vector3(cx, 5.8, TOWER_Z1 + 3.7), Vector3(tw + 0.6, 1.2, 0.2))
	lm.box("Lamp", Vector3(cx, 7.4, TOWER_Z1 + 0.5), Vector3(7.0, 1.3, 0.2))
	lm.box("Base", Vector3(cx, 0.4, TOWER_Z1 + 3.0), Vector3(tw + 1.0, 0.8, 5.0))
	lm.commit(model)
