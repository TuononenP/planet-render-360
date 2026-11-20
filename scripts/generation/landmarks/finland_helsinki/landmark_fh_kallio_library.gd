extends RefCounted

## Kallio Library (Kallion kirjasto, Karl Hård af Segerstad, 1912), Viides
## linja 11. Origin at the registry point; the footprint is the OSM outline
## (LandmarkFhInnerFootprints "kallio_library", 0.5-1 m simplified), yaw 0.
##
## From the photographs (visual-plan/refs/landmarks/kallio_library/): a
## dark maroon brick block of three storeys on a rough granite base, light
## sandstone quoins and window surrounds, tall paired windows, an arched
## entrance under a curved gable with an oval window, and a steep roof of
## orange-red tile with red-painted ridges and a red chimney.
##
## Measured: outline, orientation (OSM); the 19 m registry height. Estimated:
## 12 m eaves, mansard heights, window positions. This version darkens the
## brick and brightens the tile to the photographed colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const LIBRARY_M := 19.0

const ENTRY := {"type": "kallio_library", "name": "Kallio Library", "lat": 60.183619, "lon": 24.953646,
	"radius_m": 2000.0, "wiki_title": "Kallio Library", "height_m": 19.0, "clear_m": 17.0,
	"kind": "Library", "aliases": ["kallio library", "kallion kirjasto", "berghälls bibliotek"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7A382D", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCFB4", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#706B64", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#CC6A35", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	var poly := I.outline("kallio_library")
	var eave := 12.0
	lm.poly_prism("Granite", F.offset(poly, 0.15), 0.0, 1.3)
	lm.poly_prism("Brick", poly, 1.3, eave)
	lm.poly_prism("Stone", F.offset(poly, 0.1), 5.5, 5.8, false)
	lm.poly_prism("Stone", F.offset(poly, 0.25), eave - 0.4, eave, false)
	W.edge_windows(lm, "Glass", poly, 1.8, 3, 3.6, 2.6, 1.3, 2.2, "Stone")
	_quoins(lm, poly, 1.3, eave - 0.4)
	# Red tiled mansard: a steep lower skirt, a low upper hip, chimneys.
	var cen := FhP.centre(poly)
	var skirt := F.offset(poly, 0.3)
	FhP.slope_roof(lm, "Tile", skirt, cen, 0.8, eave, eave + 3.4)
	var upper := PackedVector2Array()
	for p in skirt:
		upper.append(cen + (p - cen) * 0.8)
	FhP.slope_roof(lm, "Tile", upper, cen, 0.6, eave + 3.4, eave + 5.0)
	for s: float in [-1.0, 1.0]:
		U.blk(lm, "Brick", cen.x + 4.5 * s, eave + 2.5, cen.y, 1.2, LIBRARY_M - eave - 2.5, 1.2)
	lm.commit(model, "Kallio_library_")

## Light stone quoins at every corner between two edges at least 3 m long.
static func _quoins(lm: LandmarkMesh, poly: PackedVector2Array, y0: float, y1: float) -> void:
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var prev := poly[(i + n - 1) % n]
		var next := poly[(i + 1) % n]
		if p.distance_to(prev) < 3.0 or p.distance_to(next) < 3.0:
			continue
		var along := (next - p).normalized()
		lm.box("Stone", Vector3(p.x, (y0 + y1) * 0.5, p.y), Vector3(0.9, y1 - y0, 0.9),
			Basis(Vector3.UP, atan2(-along.y, along.x)), 0.0)
