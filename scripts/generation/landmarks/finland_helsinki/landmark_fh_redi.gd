extends RefCounted

## Redi shopping centre (Kalasatama, 2018) with the Bryga rooftop park, from
## the mapped lot outline (LandmarkFhMallFootprints).
##
## From the photographs (visual-plan/refs/landmarks/redi_shopping_centre/):
## the podium is clad in rust-brown weathering-steel panels with green-grey
## metal sections; the Kalasatama towers rise from its deck. This version
## recolours the podium to the steel brown and adds vertical panel joints.
##
## Measured: outline; 15 m podium (estimate), the park deck and the 20 m
## top (registry height; LoD2 reads 29.9 m including the tower bases).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const ENTRY := {"type": "redi_shopping_centre", "name": "Redi Shopping Centre", "lat": 60.186915, "lon": 24.979314,
	"radius_m": 4500.0, "wiki_title": "Redi (shopping centre)", "height_m": 20.0, "clear_m": 40.0,
	"clear_offsets_m": [
		[-58.0, 20.0], [-13.0, -45.0], [57.0, -30.0], [7.0, 25.0], [-58.0, -55.0], [-38.0, 55.0],
		[17.0, -50.0], [-73.0, 15.0], [72.0, -40.0], [37.0, -10.0], [-43.0, -70.0], [-53.0, -10.0],
		[-68.0, 25.0]],
	"kind": "Shopping centre", "aliases": ["redi shopping centre", "kauppakeskus redi", "redi kalasatama"]}

## Kalasatama tower shafts standing in the Redi lot: [centre, size] in
## metres about the Redi entry, derived from the registry entries so a
## moved tower moves its deck clearance with it (the builder's own
## footprint sizes, LandmarkFhKalasatama).
const REDI_TOWER_SIZES := {"majakka": Vector2(25.0, 28.0), "loisto": Vector2(27.0, 25.0),
	"lumo_one": Vector2(24.0, 24.0), "horisontti": Vector2(32.0, 31.0), "visio": Vector2(32.0, 34.0)}

static func _redi_towers() -> Array:
	var base := LocationData.entry_for_type("redi_shopping_centre")
	var out: Array = []
	if base.is_empty():
		return out
	for type in REDI_TOWER_SIZES:
		var e := LocationData.entry_for_type(type)
		if e.is_empty():
			continue
		var east := (float(e["lon"]) - float(base["lon"])) * 111320.0 * cos(deg_to_rad(float(base["lat"])))
		var north := (float(e["lat"]) - float(base["lat"])) * 110540.0
		out.append([Vector2(east, -north), REDI_TOWER_SIZES[type]])
	return out


static func build(model: Node3D) -> void:
	# The podium the Kalasatama towers stand on, extruded from the Redi lot
	# and topped by the Bryga rooftop park (OSM leisure=park, layer 5):
	# lawn, paths, planters, trees and a pavilion on a stone parapet — not
	# a flat slab. Two park walkways run on the deck to the Majakka and
	# Lumo One shafts, so the mapped layer-5 bridges land on a finished
	# park instead of a bare roof.
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#7C4B35", 3.0, 0.6, 0.25))
	lm.use("Glass", LandmarkMaterials.glass("#40555F"))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#8E8B84", 2.5))
	lm.use("Roof", LandmarkMaterials.paint("#4C5052", 0.7))
	lm.use("Park", LandmarkMaterials.pbr("grass", "#66784A", 4.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#7A6248", 2.0))
	var poly := F.outline("redi_shopping_centre")
	lm.poly_prism("Wall", poly, 0.0, 15.0)
	# Weathering-steel panel joints: a vertical rib every 3 m on the long faces.
	for i in poly.size():
		var pa := poly[i]
		var pb := poly[(i + 1) % poly.size()]
		if pa.distance_to(pb) > 10.0:
			FhP.ribs(lm, "Trim", Vector3(pa.x, 0, pa.y), Vector3(pb.x, 0, pb.y), FhP.edge_out(poly, i), 4.8, 14.8, 3.0, 0.14, 0.1)
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
	# Park walkways from the lawn centre to the two north tower shafts
	# (Majakka and Lumo One, whichever the registry places there), with
	# rails and posts standing on the deck.
	var walk_targets: Array = []
	for t in _redi_towers():
		var centre: Vector2 = t[0]
		if centre.y < -40.0 and absf(centre.x) < 40.0:
			walk_targets.append(t)
	walk_targets.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).x < (b[0] as Vector2).x)
	for target in walk_targets:
		var x := (target[0] as Vector2).x
		var z0 := -16.0
		var z1 := (target[0] as Vector2).y + (target[1] as Vector2).y * 0.5
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
	var warm := Color(1.0, 0.88, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-50.0, 1.5, 112.0), Vector3(-40.0, 9.0, 72.0), 56.0, 0.9, 85.0, warm],
		[Vector3(65.0, 1.5, 65.0), Vector3(45.0, 9.0, 35.0), 56.0, 0.9, 85.0, warm],
		[Vector3(-40.0, 1.5, -125.0), Vector3(-40.0, 9.0, -90.0), 56.0, 0.85, 85.0, warm],
		[Vector3(124.0, 1.5, -35.0), Vector3(92.0, 9.0, -35.0), 56.0, 0.85, 85.0, warm],
	])

## True when a deck item (centre `c`, size `size`) lies on the lawn and
## clear of every tower shaft by 3 m.
static func _deck_fits(lawn: PackedVector2Array, c: Vector2, size: Vector2) -> bool:
	if not F.rect_inside(lawn, c, size):
		return false
	var item := Rect2(c - size * 0.5, size).grow(3.0)
	for t in _redi_towers():
		var shaft := Rect2((t[0] as Vector2) - (t[1] as Vector2) * 0.5, t[1])
		if item.intersects(shaft):
			return false
	return true

