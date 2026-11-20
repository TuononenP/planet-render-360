extends RefCounted

## Cable Factory (Kaapelitehdas, Kaapelitehdas Oy / Nokia cable works, built
## 1939-54), the very long industrial block on the Ruoholahti shore. Origin
## at the registry point (OSM way 14829369, five levels), yaw 0; the outline
## is in LandmarkFhInnerFootprints.
##
## From the Commons photos (visual-plan/refs/landmarks/cable_factory/):
## - Buff yellow-brown brick, one tone all round (the earlier red top band
##   is not in the photographs). A tall ground storey of three-light
##   industrial windows in brown frames, a projecting board-marked concrete
##   belt course above it, then four storeys of paired and triple multi-pane
##   windows, a plain concrete cornice and a flat roof.
## - Grey panel-clad plant boxes stand on the roof, and a steel gantry crane
##   spans the yard streets (not modelled).
##
## Measured: the outline and the five OSM levels. The City LoD2 reads up to
## 36 m for the block (rooftop plant included); the model keeps its 22.4 m
## eaves and 28 m plant boxes, which are estimates, as are the 5.2 m ground
## storey, the 3.9 m upper storey pitch and the colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENTRY := {"type": "cable_factory", "name": "Cable Factory", "lat": 60.161850, "lon": 24.903991,
	"radius_m": 3000.0, "wiki_title": "Cable Factory", "height_m": 28.0, "clear_m": 14.0,
	"clear_offsets_m": [[-67.0, 8.0], [-51.0, 30.0], [33.0, 10.0], [71.0, -4.0], [-25.0, 26.0],
		[7.0, 16.0], [-19.0, -18.0], [-45.0, -8.0], [51.0, -40.0], [19.0, -28.0], [53.0, -2.0],
		[95.0, -10.0], [1.0, -22.0], [-75.0, -2.0], [-5.0, 20.0], [39.0, -40.0], [-63.0, 18.0],
		[55.0, -42.0], [-43.0, 34.0], [-61.0, -6.0], [19.0, 18.0], [-37.0, -12.0]],
	"kind": "Arts centre", "aliases": ["cable factory", "kaapelitehdas", "kabelfabriken",
		"cable factory helsinki"]}

const TOP_M := 28.0
const BELT := 5.4
const EAVE := 22.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A8870", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 2.5))
	lm.use("Frame", LandmarkMaterials.paint("#5A4638", 0.7, 0.1))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6E6A64", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2D3436"))
	lm.use("Roof", LandmarkMaterials.paint("#5A5D5E", 0.8))
	lm.use("Metal", LandmarkMaterials.paint("#868C90", 0.5, 0.4))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD49A", 0.7))
	var poly := I.outline("cable_factory")
	lm.poly_prism("Granite", F.offset(poly, 0.12), 0.0, 0.8)
	lm.poly_prism("Brick", poly, 0.8, EAVE)
	# Board-marked concrete belt course over the ground storey, and the cornice.
	lm.poly_prism("Concrete", F.offset(poly, 0.35), BELT, BELT + 0.7, false)
	lm.poly_prism("Concrete", F.offset(poly, 0.4), EAVE - 0.7, EAVE, true)
	lm.poly_prism("Roof", F.offset(poly, 0.05), EAVE - 0.1, EAVE + 0.05)
	# Brick pilasters between the window groups.
	W.ribs(lm, "Brick", poly, 0.8, EAVE - 0.7, 8.6, 0.8, 0.25)
	# Ground storey: tall three-light windows; upper storeys: paired lights.
	W.edge_windows(lm, "Glass", poly, 1.2, 1, 4.3, 4.3, 3.4, 3.7, "Frame")
	W.edge_windows(lm, "Glass", poly, BELT + 1.2, 4, 3.9, 2.9, 2.0, 2.3, "Frame")
	# A few windows glow at night: a lit band behind the ground storey glass.
	lm.poly_prism("Lamp", F.offset(poly, -0.05), 1.0, 1.3, false)
	var yaw := atan2(0.299, 0.954)
	U.blk(lm, "Metal", 0.0, EAVE, -22.7, 34.0, TOP_M - EAVE, 11.0, yaw)
	U.blk(lm, "Metal", 40.0, EAVE, 7.0, 30.0, TOP_M - EAVE, 11.0, yaw)
	lm.commit(model, "Cable_factory_")
