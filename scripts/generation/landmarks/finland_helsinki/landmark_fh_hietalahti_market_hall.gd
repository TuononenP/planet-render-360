extends RefCounted

## Hietalahti Market Hall (Hietalahden kauppahalli, Selim A. Lindqvist,
## 1903), Hietalahdentori. Origin at the OSM building (way 122954081,
## 60.16302, 24.92939, yaw 0); the registry point read 110 m south of it.
##
## From the Commons photos (visual-plan/refs/landmarks/hietalahti_market_hall/):
## - Red clinker-brick piers with a granite plinth, between them cream
##   rendered panels each holding a tall round-headed multi-pane window
##   (the entrance front has five of them in groups, with a gabled brick
##   porch, a panelled door and a granite flight of steps).
## - Small brick piers with grey pyramid caps stand before the front corners.
## - A shallow-pitched roof of weathered green copper with a long glazed
##   monitor along the ridge, the "KAUPPAHALLI / SALUHALL" lettering on a
##   frame at the eaves and a small clock above the entrance.
##
## Measured: the 43-point OSM outline (hall about 68 x 25 m on a -35 deg
## axis, with its rounded ends and the entrance annex) and the LoD2 ridge,
## 12.2 m (gabled, 35 deg, 7.3 m of roof). Estimated: the 5.0 m eaves, the
## window and pier spacing, the monitor size and all colours.

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const ENTRY := {"type": "hietalahti_market_hall", "name": "Hietalahti Market Hall", "lat": 60.16302, "lon": 24.92939,
	"radius_m": 1500.0, "wiki_title": "Hietalahti Market Hall", "height_m": 13.0, "clear_m": 26.0,
	"kind": "Market hall", "aliases": ["hietalahti market hall", "hietalahden kauppahalli", "sandvikens saluhall"]}

const FLAT := [7.0, 8.2, 5.4, 5.9, -3.6, 12.2, -1.7, 14.9, 2.3, 20.5, 0.5, 21.8, -0.7, 22.6, -1.8, 23.4, -4.3, 25.1,
	-10.1, 17.2, -13.1, 19.5, -16.3, 20.8, -19.6, 20.7, -22.3, 19.5, -24.5, 17.2, -25.5, 14.2, -25.5, 11.6,
	-25.0, 10.5, -24.3, 8.8, -22.2, 6.7, -18.8, 4.3, -15.1, 1.7, 13.1, -18.1, 20.7, -23.4, 26.0, -24.7,
	28.9, -23.8, 31.0, -22.0, 32.4, -19.5, 32.6, -16.3, 31.4, -13.1, 29.5, -11.1, 25.3, -8.2, 31.1, 0.0,
	28.1, 2.1, 24.4, 4.6, 18.6, -3.5, 9.6, 2.9, 11.3, 5.2, 9.1, 6.7]

const EAVE := 5.0
const RIDGE := 12.2
## Long axis of the hall (x, z) and its yaw for a ridge along local Z.
const AXIS := Vector2(0.818, -0.575)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4A38", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#DDCDAE", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7D766E", 3.0))
	lm.use("Copper", LandmarkMaterials.paint("#79A38E", 0.55, 0.4))
	lm.use("Frame", LandmarkMaterials.paint("#E9E5DA", 0.6, 0.1))
	lm.use("Glass", LandmarkMaterials.glass("#38474F"))
	lm.use("Cap", LandmarkMaterials.paint("#4F5559", 0.6, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD9A0", 0.7))
	var poly := W._poly(FLAT)
	lm.poly_prism("Granite", F.offset(poly, 0.15), 0.0, 1.0)
	lm.poly_prism("Plaster", poly, 1.0, EAVE)
	# Brick piers between the window panels, a brick cornice and a plinth band.
	W.ribs(lm, "Brick", poly, 1.0, EAVE, 3.6, 1.0, 0.3)
	lm.poly_prism("Brick", F.offset(poly, 0.18), EAVE - 0.5, EAVE, false)
	lm.poly_prism("Brick", F.offset(poly, 0.1), 1.0, 1.7, false)
	# Round-headed windows between the piers; the longer runs get a lit pane.
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var len := a.distance_to(b)
		if len < 4.0:
			continue
		var out := W.outward(poly, a, b)
		var n := int(round(len / 3.6))
		FhP.win_row(lm, "Frame", "Glass", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(out.x, 0, out.y),
			1.7, n, 1.7, 2.9, true, 0.2)
	# The green copper roof: a shallow gable over the hall with a glazed monitor.
	var c := Vector3(-4.0, EAVE, -2.0)
	var yaw := atan2(AXIS.x, AXIS.y)
	var basis := Basis(Vector3.UP, yaw)
	lm.gable("Copper", c, 25.0, 60.0, RIDGE - EAVE, basis, 0.5, "Plaster")
	lm.box("Glass", c + Vector3(0, RIDGE - EAVE + 0.6, 0), Vector3(2.6, 1.4, 38.0), basis, 0.0)
	lm.box("Frame", c + Vector3(0, RIDGE - EAVE + 1.4, 0), Vector3(3.0, 0.2, 38.4), basis, 0.0)
	# Brick piers with pyramid caps before the entrance front.
	for p in [Vector2(-18.0, 21.0), Vector2(-7.0, 24.0)]:
		lm.box("Brick", Vector3(p.x, 1.6, p.y), Vector3(1.0, 3.2, 1.0))
		lm.lathe("Cap", Vector3(p.x, 3.2, p.y), PackedVector2Array([Vector2(0.8, 0.0), Vector2(0.0, 1.3)]), 4, 1.0, 1.0, PI * 0.25, false)
	# Brick turrets with green pyramid caps at the two ends of the hall.
	for p in [Vector2(-18.5, 11.0), Vector2(27.0, -15.5)]:
		lm.box("Brick", Vector3(p.x, 4.2, p.y), Vector3(3.2, 8.4, 3.2), Basis(Vector3.UP, yaw + PI * 0.5))
		lm.lathe("Copper", Vector3(p.x, 8.4, p.y), PackedVector2Array([Vector2(1.5, 0.0), Vector2(0.0, 3.1)]), 4, 1.0, 1.0, PI * 0.25 + yaw, false)
	lm.commit(model)
