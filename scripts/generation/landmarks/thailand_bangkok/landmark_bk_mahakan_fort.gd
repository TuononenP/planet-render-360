class_name LandmarkBkMahakanFort
extends RefCounted

## Mahakan Fort & Surviving City Wall (ป้อมมหากาฬ และกำแพงพระนคร) — Bangkok BK-2.6
## Site: OSM way 103022352 (`historic=fort`), centroid 13.755597, 100.505518 (39.3 x 37.0 m),
## plus surviving 178.6 m crenellated city wall (`way:178329994`, local `(-15.8, 10.1)` ->
## `(-14.9, 27.4)` -> `(-53.2, 184.1)`) along Khlong Rop Krung at Phan Fa Lilat Bridge.
## Spec (Rama I, 1783, Commons refs):
##   - Whitewashed octagonal 3-tier battered brick-and-stucco bastion:
##       Tier 1 (ground bastion): r = 19.2 -> 18.0 m, 5.4 m tall, bai sema merlons & cannon embrasures.
##       Tier 2 (upper gun deck): r = 13.4 -> 12.6 m, 4.4 m tall, bai sema merlons & cannon embrasures.
##       Tier 3 (octagonal watchtower): r = 5.6 m, 4.6 m tall with arched windows, crowned by a
##         2-stepped octagonal terracotta tiled roof + gilded finial reaching 19.0 m.
##   - Surviving Rattanakosin crenellated city wall (~4.6 m high + 1.25 m bai sema battlements,
##     2.6 m thick walkway) with arched doorways and brick access stairs on the park side.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 19.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F3F0E6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCD5C6", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B84C27", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#241F1D", 0.9, 0.1))

	_fort(lm)
	_city_wall(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-24.0, 1.5, -14.0), Vector3(0.0, 10.0, 0.0), 50.0, 1.1, 42.0, Color(1.0, 0.92, 0.76)],
		[Vector3(24.0, 1.5, 10.0), Vector3(0.0, 10.0, 0.0), 50.0, 1.1, 42.0, Color(1.0, 0.92, 0.76)],
		[Vector3(-26.0, 1.5, 65.0), Vector3(-25.0, 4.5, 65.0), 55.0, 0.85, 36.0, Color(1.0, 0.92, 0.76)],
		[Vector3(-42.0, 1.5, 130.0), Vector3(-40.0, 4.5, 130.0), 55.0, 0.85, 36.0, Color(1.0, 0.92, 0.76)],
	])

static func _fort(lm: LandmarkMesh) -> void:
	# Base stone plinth skirt for canal-side grade
	lm.frustum("Stone", Vector3(0, -0.6, 0), 20.2, 19.6, 0.9, 8, PI / 8.0)
	# Tier 1: main octagonal bastion (y = 0.3..5.6 m)
	K2.fort_tier(lm, "Wall", "Dark", Vector3(0, 0.3, 0), 19.2, 18.0, 5.3, 8, true, true)
	# Park-side arched fortress gateway & steps facing WSW (-X)
	var gb := Basis(Vector3.UP, -PI * 0.5)
	lm.box("Wall", gb * Vector3(0, 2.7, 17.2), Vector3(4.6, 4.8, 1.8), gb)
	lm.box("Dark", gb * Vector3(0, 1.9, 18.05), Vector3(2.3, 3.4, 0.3), gb, 0.0)

	# Tier 2: second octagonal gun deck (y = 5.6..9.9 m)
	K2.fort_tier(lm, "Wall", "Dark", Vector3(0, 5.6, 0), 13.4, 12.6, 4.3, 8, true, true)

	# Tier 3: central octagonal watchtower (y = 9.9..14.4 m) + two-tier octagonal roof to 19.0 m
	var rot := PI / 8.0
	lm.lathe("Wall", Vector3(0, 9.9, 0), PackedVector2Array([
		Vector2(5.9, 0.0), Vector2(5.6, 0.4), Vector2(5.5, 4.2), Vector2(5.8, 4.5)]), 8, 1.0, 1.0, rot, false)
	var apothem := 5.5 * cos(rot)
	for s in 8:
		var a := rot + TAU * (float(s) + 0.5) / 8.0
		var fb := Basis(Vector3.UP, PI * 0.5 - a)
		lm.box("Dark", fb * Vector3(0, 12.0, apothem * 0.98), Vector3(1.15, 1.95, 0.25), fb, 0.0)
	# Stepped octagonal terracotta roof (14.4..17.9 m) + gilded finial (17.9..19.0 m)
	lm.lathe("Tile", Vector3(0, 14.3, 0), PackedVector2Array([
		Vector2(7.0, 0.0), Vector2(4.1, 1.6), Vector2(4.8, 1.75), Vector2(1.4, 3.6)]), 8, 1.0, 1.0, rot, false)
	lm.lathe("Gold", Vector3(0, 17.85, 0), PackedVector2Array([
		Vector2(0.45, 0.0), Vector2(0.22, 0.45), Vector2(0.0, 1.15)]), 8)

static func _city_wall(lm: LandmarkMesh) -> void:
	# Exact OSM way 178329994 trajectory from fort south rim along Khlong Rop Krung
	var pts := [
		Vector3(-12.5, 0.0, 12.0),
		Vector3(-15.8, 0.0, 18.0),
		Vector3(-14.9, 0.0, 27.4),
		Vector3(-34.0, 0.0, 105.5),
		Vector3(-53.2, 0.0, 184.1),
	]
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		# Continuous stone plinth + whitewashed rampart walk + bai sema battlements on outer (canal) face
		var d := b - a
		var basis := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.box("Stone", (a + b) * 0.5 + Vector3(0, 0.25, 0), Vector3(3.1, 0.9, d.length()), basis)
		K.sema_wall(lm, "Wall", a + Vector3(0, 0.4, 0), b + Vector3(0, 0.4, 0), 4.2, 2.5, 2.2)
	# Park-side arched postern doors & double brick access stairs along the long wall segment
	for frac in [0.28, 0.68]:
		var p := (pts[2] as Vector3).lerp(pts[4] as Vector3, frac)
		var d := (pts[4] as Vector3) - (pts[2] as Vector3)
		var wb := Basis(Vector3.UP, atan2(d.x, d.z) - PI * 0.5)
		lm.box("Dark", p + wb * Vector3(0, 1.8, 1.28), Vector3(1.8, 2.8, 0.2), wb, 0.0)
		U.stairs(lm, "Stone", p + wb * Vector3(4.5, 4.4, 1.3), wb, 1.6, 12, 0.34, 0.34)
