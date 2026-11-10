class_name LandmarkNycDowntown
extends RefCounted

## Lower Manhattan's towers on the SkyKit. Plans and tier heights follow each
## building's OSM footprint and mapped parts; +X is its long axis.

const COPPER := "#5f8f7c"
const BRONZE := "#5c4a38"

static func _copper(lm: LandmarkMesh) -> void:
	lm.use("Copper", LandmarkMaterials.paint(COPPER, 0.7, 0.2))

## Woolworth (1913): a U-plan base, the tower, and its Gothic copper crown
## with four corner turrets; pale glazed terracotta.
static func woolworth(model: Node3D) -> void:
	var kit := SkyKit.tower("terracotta_pier", 3.2, 3.8, [[0.0, 120.0, 58.2, 44.1], [120.0, 170.0, 27.0, 27.0],
		[170.0, 194.0, 24.3, 24.3], [194.0, 212.0, 20.3, 20.3]], "#d9d2bf", 3.2)
	var lm := kit.lm
	_copper(lm)
	lm.use("Gold", LandmarkMaterials.gold())
	lm.spire("Copper", Vector3(0, 212.0, 0), 10.2, 25.0, 1.6)
	for x in [-9.6, 9.6]:
		for z in [-9.6, 9.6]:
			lm.box("Trim", Vector3(x, 203.0, z), Vector3(4.8, 18.0, 4.6))
			lm.spire("Copper", Vector3(x, 212.0, z), 2.4, 9.0)
	lm.spire("Gold", Vector3(0, 237.0, 0), 1.6, 4.0)
	lm.commit(model)

## 40 Wall Street (1930): stepped brick shaft, green pyramid, spire.
static func forty_wall(model: Node3D) -> void:
	var kit := SkyKit.tower("buff_pier", 3.0, 3.6, [[0.0, 75.0, 70.7, 59.3], [75.0, 150.0, 48.0, 42.0],
		[150.0, 212.0, 28.5, 28.5], [212.0, 225.0, 26.5, 26.5], [225.0, 230.0, 24.8, 24.8]], "#b4a282", 3.0)
	_copper(kit.lm)
	kit.lm.spire("Copper", Vector3(0, 230.0, 0), 12.0, 32.0, 2.2)
	kit.lm.box("Trim", Vector3(0, 266.0, 0), Vector3(3.8, 8.0, 3.8))
	kit.lm.spire("Trim", Vector3(0, 270.0, 0), 1.0, 14.0)
	kit.lm.commit(model)

## 70 Pine (1932): limestone and brick stepping to a glazed observatory
## lantern and a slender spire.
static func seventy_pine(model: Node3D) -> void:
	var kit := SkyKit.tower("buff_pier", 3.0, 3.6, [[0.0, 90.0, 78.3, 40.2], [90.0, 165.0, 62.0, 36.0],
		[165.0, 222.0, 44.0, 32.0], [222.0, 256.0, 28.0, 24.0]], "#c2b292", 3.0)
	var lm := kit.lm
	lm.use("Lantern", LandmarkMaterials.glass("#5a7686"))
	lm.box("Lantern", Vector3(0, 260.0, 0), Vector3(8.7, 8.0, 5.7))
	lm.box("Trim", Vector3(0, 264.4, 0), Vector3(6.3, 0.8, 3.4))
	lm.spire("Trim", Vector3(0, 264.8, 0), 0.9, 25.4)
	lm.commit(model)

## New York by Gehry (8 Spruce): a school podium under a tower of rippling
## stainless steel, its folds shifting from storey band to band.
static func eight_spruce(model: Node3D) -> void:
	var kit := SkyKit.tower("steel_panel", 2.8, 3.3, [[0.0, 27.0, 60.5, 55.8]], "#a7a9ab")
	var lm := kit.lm
	var bands := 22
	var step := (271.0 - 27.0) / float(bands)
	for b in bands:
		var low := _ripple(40.6, 37.0, float(b) * 0.55)
		var high := _ripple(40.6, 37.0, float(b + 1) * 0.55)
		kit.loft("Facade", low, high, 27.0 + float(b) * step, 27.0 + float(b + 1) * step)
	kit.roof("Roof", _ripple(40.6, 37.0, float(bands) * 0.55), 271.0)
	lm.commit(model)

## A rounded w x d plan whose edges ripple by up to 1.3 m at this phase.
static func _ripple(w: float, d: float, phase: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 32:
		var a := TAU * float(i) / 32.0
		var c := cos(a)
		var s := sin(a)
		# A superellipse keeps the plan rectangular with soft corners.
		var r := pow(pow(absf(c), 6.0) + pow(absf(s) * w / d, 6.0), -1.0 / 6.0)
		var fold := 1.3 * sin(a * 8.0 + phase)
		out.append(Vector2(c, s) * (r * w * 0.5 + fold))
	return out

## 30 Park Place (Stern, 2016): limestone, stepping in toward its crown.
static func thirty_park_place(model: Node3D) -> void:
	var kit := SkyKit.tower("limestone_pier", 3.0, 3.5, [[0.0, 120.0, 45.3, 35.8], [120.0, 215.0, 38.0, 30.0],
		[215.0, 270.0, 32.0, 25.0], [270.0, 286.0, 27.1, 21.3]], "#c8bfa9", 3.0)
	kit.lm.commit(model)

## 3 World Trade Center (2018): glass over a steel diagonal grid, with four
## masts on the roof.
static func three_wtc(model: Node3D) -> void:
	var kit := SkyKit.tower("lowe_blue", 3.0, 4.0, [[0.0, 220.0, 57.5, 39.0], [220.0, 281.0, 52.9, 34.0],
		[281.0, 328.9, 46.0, 30.0]], "#5a6066")
	var lm := kit.lm
	# Diagonal bracing on the long faces, four X's up the lower shaft.
	for s in [-1.0, 1.0]:
		var z := float(s) * 19.9
		for i in 4:
			var y0 := 20.0 + float(i) * 50.0
			lm.beam("Trim", Vector3(-28.0, y0, z), Vector3(28.0, y0 + 50.0, z), 1.0)
			lm.beam("Trim", Vector3(28.0, y0, z), Vector3(-28.0, y0 + 50.0, z), 1.0)
	for x in [-18.0, 18.0]:
		for z in [-11.0, 11.0]:
			lm.spire("Trim", Vector3(x, 328.9, z), 0.8, 23.1)
	lm.commit(model)

## 7 World Trade Center (2006): a flush glass parallelogram over a steel
## lobby screen.
static func seven_wtc(model: Node3D) -> void:
	var kit := SkyKit.tower("lowe_blue", 3.0, 4.2, [[0.0, 224.0, 80.5, 49.1]], "#9aa2a8")
	kit.lm.box("Trim", Vector3(0, 225.0, 0), Vector3(17.0, 2.0, 10.9))
	kit.lm.commit(model)

## Municipal Building (1914): the wide limestone slab, drum, tempietto and
## Civic Fame.
static func municipal(model: Node3D) -> void:
	var kit := SkyKit.tower("limestone_pier", 3.2, 3.9, [[0.0, 123.0, 118.8, 54.4], [123.0, 149.0, 18.8, 18.0],
		[149.0, 164.0, 13.4, 13.3]], "#cfc5b0", 4.0)
	var lm := kit.lm
	lm.use("Gold", LandmarkMaterials.gold())
	lm.frustum("Trim", Vector3(0, 164.0, 0), 4.6, 4.2, 8.0, 16)
	lm.spire("Gold", Vector3(0, 172.0, 0), 4.2, 4.0, 1.0)
	lm.box("Gold", Vector3(0, 177.5, 0), Vector3(1.2, 7.0, 1.0))
	lm.commit(model)

## One Liberty Plaza (1973): black steel with deep exposed spandrel beams.
static func one_liberty(model: Node3D) -> void:
	var kit := SkyKit.tower("intl_bronze", 3.0, 3.9, [[0.0, 226.0, 71.8, 48.6]], "#24262a", 3.0)
	kit.lm.commit(model)

## 28 Liberty (Chase Manhattan, 1961): an aluminium grid on a slab.
static func twenty_eight_liberty(model: Node3D) -> void:
	var kit := SkyKit.tower("silver_reflective", 3.0, 3.9, [[0.0, 247.8, 85.8, 34.7]], "#c4c8cc", 6.0)
	kit.lm.commit(model)

## 140 Broadway (1967): a sheer black curtain wall with a plaza.
static func one_forty_broadway(model: Node3D) -> void:
	var kit := SkyKit.tower("intl_bronze", 3.0, 3.9, [[0.0, 209.7, 63.5, 34.9]], "#2a2c30")
	kit.lm.commit(model)

## 56 Leonard (2017): "Jenga": offset glass floor plates cantilever out.
static func fifty_six_leonard(model: Node3D) -> void:
	var tiers: Array = []
	var bands := 16
	var step := 250.2 / float(bands)
	for b in bands:
		var k := float(b)
		var taper := lerpf(1.0, 0.82, k / float(bands))
		tiers.append([k * step, (k + 1.0) * step, 39.3 * taper, 35.0 * taper, 0.0,
			sin(k * 2.4) * 2.8, cos(k * 1.7) * 2.6])
	var kit := SkyKit.tower("clear_fin", 3.0, 4.4, tiers, "#9b9fa2")
	kit.lm.commit(model)
