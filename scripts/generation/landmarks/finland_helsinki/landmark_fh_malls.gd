class_name LandmarkFhMalls
extends RefCounted

## Biggest capital-region shopping centres, true metres: low massing
## extruded from each mall's OpenStreetMap outline
## (LandmarkFhMallFootprints), banded facades, a glazed shopfront ring,
## an entrance canopy on the longest street face and roof plant. Heights
## are roof heights (mall block, excluding towers/parking above); see
## docs/helsinki-landmark-sources.md for ways and coordinates.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

## Kalasatama tower shafts standing in the Redi lot (centre x, z and
## size, metres about the Redi entry): deck furniture keeps clear of them.
const REDI_TOWERS: Array[Rect2] = [
	Rect2(19.0 - 12.5, -68.0 - 14.0, 25.0, 28.0), Rect2(87.0 - 13.5, -46.0 - 12.5, 27.0, 25.0),
	Rect2(-22.0 - 12.0, -89.0 - 12.0, 24.0, 24.0), Rect2(-65.0 - 16.0, -74.0 - 15.5, 32.0, 31.0),
	Rect2(-89.0 - 16.0, 5.0 - 17.0, 32.0, 34.0)]

static func _mall(model: Node3D, type: String, h: float, wall: String, accent: String) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", wall, 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#40555F"))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", accent, 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#5A5E60", 0.7))
	var poly := F.outline(type)
	lm.poly_prism("Wall", poly, 0.0, h - 2.5)
	# Shopfront ring, horizontal facade bands and an upper glazed ribbon.
	var skin := F.offset(poly, 0.06)
	lm.poly_prism("Glass", skin, 0.4, 4.0, false)
	var band_step := (h - 7.0) / 3.0
	for i in 3:
		var y := 4.5 + float(i) * band_step
		lm.poly_prism("Trim", F.offset(poly, 0.2), y, y + 0.5)
	lm.poly_prism("Glass", skin, 5.6, 4.5 + band_step - 0.6, false)
	_entrance(lm, poly, h)
	# Roof slab, then plant boxes and skylight strips that fit inside it.
	var roof := F.offset(poly, -2.0)
	lm.poly_prism("Roof", roof, h - 2.5, h - 1.3)
	var inner := F.offset(poly, -8.0)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in inner:
		lo = lo.min(p)
		hi = hi.max(p)
	for gx in range(int(lo.x / 40.0) - 1, int(hi.x / 40.0) + 2):
		for gz in range(int(lo.y / 40.0) - 1, int(hi.y / 40.0) + 2):
			var c := Vector2(float(gx) * 40.0, float(gz) * 40.0)
			if not F.rect_inside(inner, c, Vector2(22.0, 11.0)):
				continue
			if posmod(gx + gz, 2) == 0:
				U.blk(lm, "Roof", c.x, h - 1.3, c.y, 16.0, 1.3, 9.0)
			else:
				U.blk(lm, "Glass", c.x, h - 1.25, c.y, 22.0, 0.5, 5.0)
	lm.commit(model)

## Entrance canopy and accent pylon at the middle of the longest edge,
## facing out of the building.
static func _entrance(lm: LandmarkMesh, poly: PackedVector2Array, h: float) -> void:
	var best := 0
	for i in poly.size():
		if poly[i].distance_to(poly[(i + 1) % poly.size()]) > poly[best].distance_to(poly[(best + 1) % poly.size()]):
			best = i
	var a := poly[best]
	var b := poly[(best + 1) % poly.size()]
	var along := (b - a).normalized()
	var out := Vector2(along.y, -along.x)
	var mid := (a + b) * 0.5
	if Geometry2D.is_point_in_polygon(mid + out, poly):
		out = -out
	var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
	var c := mid + out * 2.5
	lm.box("Trim", Vector3(c.x, 4.05, c.y), Vector3(18.0, 0.5, 5.0), basis)
	var p := c + along * 10.5
	lm.box("Trim", Vector3(p.x, (h - 2.5) * 0.5, p.y), Vector3(0.8, h - 2.5, 0.8), basis)

static func redi(model: Node3D) -> void:
	# The podium the Kalasatama towers stand on, extruded from the Redi lot
	# and topped by the Bryga rooftop park (OSM leisure=park, layer 5):
	# lawn, paths, planters, trees and a pavilion on a stone parapet — not
	# a flat slab. Two park walkways run on the deck to the Majakka and
	# Lumo One shafts, so the mapped layer-5 bridges land on a finished
	# park instead of a bare roof.
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#9A8F82", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#40555F"))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#8E8B84", 2.5))
	lm.use("Roof", LandmarkMaterials.paint("#4C5052", 0.7))
	lm.use("Park", LandmarkMaterials.pbr("grass", "#66784A", 4.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#7A6248", 2.0))
	var poly := F.outline("redi_shopping_centre")
	lm.poly_prism("Wall", poly, 0.0, 15.0)
	var skin := F.offset(poly, 0.06)
	lm.poly_prism("Glass", skin, 0.4, 4.6, false)
	lm.poly_prism("Glass", skin, 7.0, 11.0, false)
	# Stone parapet and the dark roof deck inside it.
	lm.poly_prism("Trim", F.offset(poly, 1.0), 15.0, 15.8)
	lm.poly_prism("Roof", F.offset(poly, -4.0), 15.8, 16.5)
	# Bryga lawn with gravel paths crossing it, clipped to the lawn.
	var lawn := F.offset(poly, -12.0)
	lm.poly_prism("Park", lawn, 16.5, 16.85)
	for r in [Rect2(-120.0, -3.5, 240.0, 7.0), Rect2(-3.5, -120.0, 7.0, 240.0),
			Rect2(-60.5, -120.0, 5.0, 240.0), Rect2(55.5, -120.0, 5.0, 240.0)]:
		var rect := r as Rect2
		var path := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
			rect.end, Vector2(rect.position.x, rect.end.y)])
		for piece in Geometry2D.intersect_polygons(lawn, path):
			lm.poly_prism("Trim", piece, 16.85, 16.95)
	# Planters, benches and small park trees where the lawn has room.
	for x in [-66.0, -22.0, 22.0, 66.0]:
		for z in [-44.0, 44.0]:
			if not _deck_fits(lawn, Vector2(x, z), Vector2(9.0, 2.2)):
				continue
			U.blk(lm, "Wood", x, 16.85, z, 9.0, 0.7, 2.2)
			lm.frustum("Wood", Vector3(x, 17.55, z), 0.14, 0.18, 1.5, 8)
			lm.lathe("Park", Vector3(x, 17.9, z), U.ball(1.05), 10)
	for x in [-44.0, 0.0, 44.0]:
		if _deck_fits(lawn, Vector2(x, 10.0), Vector2(3.4, 0.9)):
			U.blk(lm, "Wood", x, 16.85, 10.0, 3.4, 0.5, 0.9)
	# Park walkways from the lawn centre to the Majakka and Lumo One
	# shafts, with rails and posts standing on the deck.
	for w in [[19.0, -54.0], [-22.0, -77.0]]:
		var x := float(w[0])
		var z0 := -16.0
		var z1 := float(w[1])
		var mid := (z0 + z1) * 0.5
		var length := z0 - z1
		U.blk(lm, "Trim", x, 16.95, mid, 4.2, 0.25, length)
		var z := z0 - 8.0
		while z > z1 + 2.0:
			U.blk(lm, "Trim", x - 2.0, 16.5, z, 0.14, 1.1, 0.14)
			U.blk(lm, "Trim", x + 2.0, 16.5, z, 0.14, 1.1, 0.14)
			z -= 20.0
		U.blk(lm, "Trim", x - 2.0, 17.55, mid, 0.1, 0.12, length)
		U.blk(lm, "Trim", x + 2.0, 17.55, mid, 0.1, 0.12, length)
	# Glass park pavilion and roof plant close at the registered height.
	U.blk(lm, "Glass", -52.0, 16.5, -30.0, 20.0, 2.6, 11.0)
	U.blk(lm, "Trim", -52.0, 19.1, -30.0, 21.0, 0.4, 12.0)
	U.blk(lm, "Roof", 60.0, 18.5, -20.0, 22.0, 1.5, 16.0)
	lm.commit(model)

## True when a deck item (centre `c`, size `size`) lies on the lawn and
## clear of every tower shaft by 3 m.
static func _deck_fits(lawn: PackedVector2Array, c: Vector2, size: Vector2) -> bool:
	if not F.rect_inside(lawn, c, size):
		return false
	var item := Rect2(c - size * 0.5, size).grow(3.0)
	for t in REDI_TOWERS:
		if item.intersects(t):
			return false
	return true

static func tripla(model: Node3D) -> void:
	_mall(model, "mall_of_tripla", 30.0, "#A8A29A", "#38505A")

static func itis(model: Node3D) -> void:
	_mall(model, "itis_shopping_centre", 25.0, "#B0A696", "#6A4A3E")

static func iso_omena(model: Node3D) -> void:
	_mall(model, "iso_omena", 24.0, "#AEA79C", "#4A5A66")

static func sello(model: Node3D) -> void:
	_mall(model, "sello_shopping_centre", 22.0, "#B5AA9C", "#5E5248")

static func jumbo(model: Node3D) -> void:
	_mall(model, "jumbo_shopping_centre", 18.0, "#A39A90", "#54626A")
