extends RefCounted

## Aalto House (Villa Aalto, Alvar Aalto's own house on Riihitie 20, 1936;
## UNESCO WHS part ref 1752-007). Origin at the OSM building (way 27634542,
## 60.196731, 24.876389, yaw 0). Whitewashed brick ground floor; upstairs the
## white east block and the dark-stained timber studio volume over the west
## wing, with a flat roof and one chimney.
##
## Measured: the outline and the City LoD2 roof (7.7 m). Estimated: the 3.3 m
## ground floor, 6.9 m upper top, the volume split and the colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const AALTO_HOUSE_M := 8.0

const ENTRY := {"type": "aalto_house", "name": "Aalto House", "lat": 60.196731, "lon": 24.876389,
	"radius_m": 2000.0, "wiki_title": "Villa Aalto", "height_m": 8.0, "clear_m": 11.0,
	"kind": "House museum", "aliases": ["aalto house", "villa aalto", "alvar aalto's home",
		"alvar aallon kotitalo", "aallon kotitalo", "riihitie 20"]}

## The rectangle u0..u1 by n0..n1 in the (u, n) frame.
static func _rect(u: Vector2, n: Vector2, u0: float, u1: float, n0: float, n1: float) -> PackedVector2Array:
	return PackedVector2Array([u * u0 + n * n0, u * u1 + n * n0, u * u1 + n * n1, u * u0 + n * n1])

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EEEDE8", 2.0))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#3B2E28", 1.5))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Roof", LandmarkMaterials.paint("#4E5050", 0.8))
	var poly := W.outline("aalto_house")
	var u := (Vector2(12.9, -0.7) - Vector2(-3.8, -10.0)).normalized()
	var n := Vector2(-u.y, u.x)
	var floor1 := 3.3
	var top := 6.9
	lm.poly_prism("White", poly, 0.0, floor1)
	W.edge_windows(lm, "Glass", poly, 0.9, 1, 0.0, 3.4, 2.0, 1.3)
	var east := _rect(u, n, 2.0, 10.9, -6.9, 2.0)
	var west := _rect(u, n, -8.3, 2.0, -6.9, 9.1)
	lm.poly_prism("White", east, floor1, top)
	W.edge_windows(lm, "Glass", east, 4.3, 1, 0.0, 3.5, 1.6, 1.4)
	lm.poly_prism("Timber", west, floor1, top)
	W.ribs(lm, "Timber", west, floor1, top, 0.3, 0.07, 0.05)
	lm.poly_prism("Roof", F.offset(poly, -0.2), floor1, floor1 + 0.1)
	lm.poly_prism("Roof", F.offset(east, -0.2), top, top + 0.1)
	lm.poly_prism("Roof", F.offset(west, -0.2), top, top + 0.1)
	var c := u * 4.0 + n * -2.0
	U.blk(lm, "White", c.x, top - 0.5, c.y, 0.9, AALTO_HOUSE_M - top + 0.5, 1.0)
	lm.commit(model, "Aalto_house_")
