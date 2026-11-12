class_name LandmarkFhMunkkiniemi
extends RefCounted

## Munkkiniemi and Kuusisaari, true metres, extruded from OpenStreetMap
## outlines (LandmarkFhWestFootprints): Alvar Aalto's own house on Riihitie
## (1936), whitewashed brick under a dark timber-clad upper volume, and
## his studio on Tiilimäki (1955), white brick with clerestory fins round
## its amphitheatre court; on Kuusisaari, Viljo Revell's Didrichsen Art
## Museum (1958–65), glass between red-brick piers under a pale fascia,
## and Villa Gyllenberg, ochre render under a red tiled hipped roof.
## Sources and estimates: docs/helsinki-landmark-sources.md.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const AALTO_HOUSE_M := 8.0
const STUDIO_M := 7.4
const DIDRICHSEN_M := 8.4
const GYLLENBERG_M := 10.0

## Whitewashed brick ground floor; upstairs the white east block and the
## dark-stained timber studio volume over the west wing, a chimney.
static func aalto_house(model: Node3D) -> void:
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

## The rectangle u0..u1 by n0..n1 in the (u, n) frame.
static func _rect(u: Vector2, n: Vector2, u0: float, u1: float, n0: float, n1: float) -> PackedVector2Array:
	return PackedVector2Array([u * u0 + n * n0, u * u1 + n * n0, u * u1 + n * n1, u * u0 + n * n1])

## White brick round the fan-shaped court; the tall studio wing on the
## long outer side, lit by clerestory glazing between white fins.
static func studio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EFEEEA", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Roof", LandmarkMaterials.paint("#4E5050", 0.8))
	var poly := W.outline("studio_aalto")
	var low := 4.2
	lm.poly_prism("White", poly, 0.0, low)
	W.edge_windows(lm, "Glass", poly, 1.0, 1, 0.0, 2.4, 1.6, 1.6, "White")
	lm.poly_prism("Roof", F.offset(poly, -0.2), low, low + 0.1)
	var a := Vector2(-16.2, 8.2)
	var b := Vector2(-3.7, -13.8)
	var inward := -W.outward(poly, a, b)
	var wing := PackedVector2Array([a, b, b + inward * 6.5, a + inward * 6.5])
	lm.poly_prism("White", wing, 0.0, STUDIO_M - 2.4)
	lm.poly_prism("Glass", F.offset(wing, 0.02), STUDIO_M - 2.4, STUDIO_M - 0.4, false)
	W.ribs(lm, "White", wing, STUDIO_M - 2.4, STUDIO_M - 0.4, 0.9, 0.25, 0.3)
	lm.poly_prism("White", F.offset(wing, 0.15), STUDIO_M - 0.4, STUDIO_M)
	lm.commit(model, "Studio_aalto_")

## Two glazed storeys between red-brick piers on a stone terrace wall, a
## pale floor band and a deep overhanging fascia.
static func didrichsen(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#33423F"))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8B3B2C", 2.5))
	lm.use("Fascia", LandmarkMaterials.pbr("concrete", "#DADAD4", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7C7066", 2.5))
	var poly := W.outline("didrichsen_art_museum")
	var eave := 7.0
	lm.poly_prism("Stone", F.offset(poly, 0.2), 0.0, 0.6)
	lm.poly_prism("Glass", F.offset(poly, -0.3), 0.6, eave)
	W.ribs(lm, "Brick", F.offset(poly, -0.3), 0.6, eave, 4.2, 0.9, 0.3)
	W.ribs(lm, "Fascia", F.offset(poly, -0.25), 0.6, eave, 1.4, 0.08, 0.1)
	lm.poly_prism("Fascia", poly, 3.5, 4.0, false)
	lm.poly_prism("Fascia", F.offset(poly, 0.9), eave, DIDRICHSEN_M)
	lm.commit(model, "Didrichsen_")

## Two rendered storeys on a granite plinth, framed windows, a red tiled
## hipped roof and a chimney.
static func gyllenberg(model: Node3D) -> void:
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
