extends RefCounted

## Katajanokka Terminal (Viking Line, Katajanokanlaituri 8), true metres from
## the OSM outline of way 23192841 (stored in LandmarkFhInnerFootprints, no
## yaw: +X east, +Z south): a two-level brick block on a ground floor of
## round concrete columns with flared heads, as the interior photo in
## visual-plan/refs/landmarks/katajanokka_terminal/ shows (the Commons
## photos of the exterior are mostly of the ships; the terminal is largely
## hidden behind them).
##
## Modelled: a recessed glazed ground floor behind the column ring, brown
## brick upper level with concrete sills and a concrete roof edge, a plant
## room on the flat roof. The first-floor gangway bridge to the berths is not modelled.
##
## Measured: the outline (OSM, 2 levels) and position. Estimated: the 12.6 m
## roof, the 4.2 m ground floor, and the brick hue. Exterior photos were poor, so
## the facade rhythm (window spacing 3.5 m) is a guess.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENTRY := {"type": "katajanokka_terminal", "name": "Katajanokka Terminal", "lat": 60.163806, "lon": 24.968360,
	"radius_m": 2000.0, "wiki_title": "Katajanokka Terminal", "height_m": 15.8, "clear_m": 24.0,
	"clear_offsets_m": [[20.0, -5.0], [-22.0, 0.0], [-12.0, -20.0], [15.0, 15.0]],
	"kind": "Ferry terminal", "aliases": ["katajanokka terminal", "katajanokan terminaali",
		"skatuddens terminal", "viking line terminal helsinki"]}

const EAVE := 12.6
const TOP := 14.0
const GROUND := 4.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#6A4034", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A8A49C", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2C3539"))
	lm.use("Roof", LandmarkMaterials.paint("#4B4D4E", 0.8))
	lm.use("Metal", LandmarkMaterials.paint("#2E3133", 0.5))
	var poly := I.outline("katajanokka_terminal")
	lm.poly_prism("Glass", F.offset(poly, -2.0), 0.0, GROUND)
	lm.poly_prism("Concrete", F.offset(poly, 0.0), GROUND - 0.4, GROUND + 0.2, false)
	_columns(lm, poly)
	lm.poly_prism("Brick", poly, GROUND + 0.2, EAVE)
	lm.poly_prism("Concrete", F.offset(poly, 0.1), GROUND + 0.2, GROUND + 0.6, false)
	W.edge_windows(lm, "Glass", poly, 5.4, 2, 3.5, 2.4, 1.4, 2.0, "Concrete")
	lm.poly_prism("Concrete", F.offset(poly, 0.12), EAVE - 0.3, EAVE + 0.4, false)
	lm.poly_prism("Roof", F.offset(poly, -0.2), EAVE, EAVE + 0.2)
	U.blk(lm, "Metal", 5.0, EAVE, 0.0, 14.0, TOP - EAVE, 8.0)
	# Five white flagpoles along the roof edge, as in the front photo.
	var c := F.offset(poly, -1.0)
	for k in 5:
		var p := c[0].lerp(c[1], (float(k) + 0.5) / 5.0)
		lm.beam("Concrete", Vector3(p.x, EAVE, p.y), Vector3(p.x, EAVE + 3.2, p.y), 0.12)
	lm.commit(model, "Katajanokka_terminal_")
	var warm := Color(1.0, 0.90, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-4.0, 1.5, 42.0), Vector3(-4.0, 8.0, 22.0), 52.0, 0.85, 55.0, warm],
		[Vector3(4.0, 1.5, -40.0), Vector3(4.0, 8.0, -18.0), 52.0, 0.85, 55.0, warm],
		[Vector3(50.0, 1.5, 4.0), Vector3(32.0, 8.0, 4.0), 50.0, 0.85, 50.0, warm],
		[Vector3(-48.0, 1.5, 4.0), Vector3(-30.0, 8.0, 4.0), 50.0, 0.85, 50.0, warm],
	])

## Round concrete columns with flared heads round the ground floor, every
## 4.8 m along each outline edge.
static func _columns(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var ring := F.offset(poly, -0.9)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var n := int(a.distance_to(b) / 4.8)
		if n < 1:
			continue
		for k in n + 1:
			var p := a.lerp(b, float(k) / float(n))
			lm.frustum("Concrete", Vector3(p.x, 0.0, p.y), 0.42, 0.42, GROUND - 0.9, 10)
			lm.frustum("Concrete", Vector3(p.x, GROUND - 0.9, p.y), 0.42, 0.95, 0.5, 10)
