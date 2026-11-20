extends RefCounted

## Villa Gyllenberg (Kuusisaari, 1938 villa, now an art museum). Origin at the
## OSM building (way 97299146, 60.184157, 24.852147, yaw 0): ochre render on a
## granite plinth, white trim, a red tiled hipped roof and a chimney; the
## modern gallery wing is folded into the outline.
##
## Measured: the outline and the City LoD2 roof (9.9 m, complex roof 4.2 m).
## Estimated: the 6.6 m eaves, tile colour, trim and chimney.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const GYLLENBERG_M := 10.0

const ENTRY := {"type": "villa_gyllenberg", "name": "Villa Gyllenberg", "lat": 60.184157, "lon": 24.852147,
	"radius_m": 2500.0, "wiki_title": "Kuusisaari", "height_m": 10.0, "clear_m": 16.0,
	"clear_offsets_m": [[3.0, -5.0]],
	"kind": "Art museum", "aliases": ["villa gyllenberg", "gyllenbergin huvila", "gyllenbergs villa"]}


## A hipped skirt from `poly` at y0 up to `poly` inset by `inset` at y1,
## capped flat: a hipped roof over any outline whose inset keeps its
## corners; terraced bands when the inset changes the outline.
static func _hip_skirt(lm: LandmarkMesh, key: String, poly: PackedVector2Array, inset: float, y0: float,
		y1: float) -> void:
	var inner := F.offset(poly, -inset)
	if inner.size() != poly.size():
		for k in 4:
			var ring := F.offset(poly, -inset * float(k) / 4.0)
			if ring.size() >= 3:
				lm.poly_prism(key, ring, lerpf(y0, y1, float(k) / 4.0), lerpf(y0, y1, float(k + 1) / 4.0))
		return
	var shift := 0
	for j in inner.size():
		if inner[j].distance_to(poly[0]) < inner[shift].distance_to(poly[0]):
			shift = j
	var step := 1 if inner[(shift + 1) % inner.size()].distance_to(poly[1]) \
		< inner[(shift + inner.size() - 1) % inner.size()].distance_to(poly[1]) else -1
	var m := poly.size()
	for i in m:
		var j0 := (shift + step * i + m * 2) % m
		var j1 := (shift + step * (i + 1) + m * 2) % m
		var o := FhP.edge_out(poly, i)
		var nrm := (o * (y1 - y0) + Vector3.UP * inset).normalized()
		var a := poly[i]
		var b := poly[(i + 1) % m]
		lm.quad(key, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(inner[j1].x, y1, inner[j1].y),
			Vector3(inner[j0].x, y1, inner[j0].y), nrm)
	lm.poly_prism(key, inner, y1 - 0.02, y1)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#D8B98A", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EFEAE0", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6F6A64", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A9533A", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	var poly := W.outline("villa_gyllenberg")
	var eave := 6.6
	lm.poly_prism("Granite", F.offset(poly, 0.12), 0.0, 0.5)
	lm.poly_prism("Render", poly, 0.5, eave)
	W.edge_windows(lm, "Glass", poly, 1.0, 2, 3.0, 3.0, 1.2, 1.6, "Trim")
	var ridge := 8.8
	_hip_skirt(lm, "Tile", F.offset(poly, 0.4), 3.2, eave, ridge)
	var c := FhP.centre(F.offset(poly, -3.2))
	U.blk(lm, "Render", c.x, ridge - 1.0, c.y, 1.1, GYLLENBERG_M - ridge + 1.0, 1.1)
	lm.commit(model, "Villa_gyllenberg_")
