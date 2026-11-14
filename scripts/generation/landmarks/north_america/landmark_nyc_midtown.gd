class_name LandmarkNycMidtown
extends RefCounted

## Midtown's towers on the SkyKit. Plans and tier heights follow each
## building's OSM footprint and mapped parts; +X is its long axis.

## A w x d plan with its corners cut by `c`, for tapered glass towers.
static func _chamfer(w: float, d: float, c: float) -> PackedVector2Array:
	var x := w * 0.5
	var z := d * 0.5
	return PackedVector2Array([Vector2(-x + c, -z), Vector2(x - c, -z), Vector2(x, -z + c), Vector2(x, z - c),
		Vector2(x - c, z), Vector2(-x + c, z), Vector2(-x, z - c), Vector2(-x, -z + c)])

## One Vanderbilt (2020): glass tapering on chamfered corners to a spire.
static func one_vanderbilt(model: Node3D) -> void:
	var kit := SkyKit.tower("pale_terracotta", 3.0, 4.2, [[0.0, 30.0, 65.3, 60.3]], "#b4a68e")
	var low := _chamfer(62.0, 57.0, 9.0)
	var mid := _chamfer(48.0, 44.0, 8.0)
	var high := _chamfer(28.0, 25.0, 6.0)
	kit.loft("Facade", low, mid, 30.0, 220.0)
	kit.loft("Facade", mid, high, 220.0, 397.0)
	kit.roof("Roof", high, 397.0)
	kit.lm.spire("Trim", Vector3(0, 397.0, 0), 2.4, 30.0)
	kit.lm.commit(model)

## Bank of America Tower (2009): faceted glass over a podium, a tall spire.
static func bank_of_america(model: Node3D) -> void:
	var kit := SkyKit.tower("clear_fin", 3.0, 4.2, [[0.0, 40.0, 130.7, 61.3]], "#9aa0a4")
	var low := _chamfer(60.0, 58.0, 10.0)
	var high := _chamfer(40.0, 38.0, 12.0)
	kit.loft("Facade", low, high, 40.0, 279.0)
	kit.roof("Roof", high, 279.0)
	kit.lm.spire("Trim", Vector3(0, 279.0, 0), 5.5, 86.8)
	kit.lm.commit(model)

## MetLife Building (Pan Am, 1963): an elongated octagon of precast concrete
## over a Grand Central base, with its louvred crown.
static func metlife(model: Node3D) -> void:
	var kit := SkyKit.tower("steel_panel", 3.0, 3.8, [[0.0, 38.0, 83.0, 78.0]], "#8c8f90")
	var slab := _chamfer(90.9, 42.1, 14.0)
	kit.prism("Facade", slab, 38.0, 238.0)
	kit.lm.use("Louvre", LandmarkMaterials.paint("#4f5356", 0.5, 0.5))
	kit.lm.poly_prism("Louvre", SkyKit.inset(slab, 0.4), 238.0, 246.0, true)
	kit.lm.commit(model)

## 30 Rockefeller Plaza (1933): the thin limestone slab, stepped north and
## south, its piers running unbroken to the top.
static func thirty_rock(model: Node3D) -> void:
	var kit := SkyKit.tower("limestone_pier", 2.9, 3.7, [[0.0, 30.0, 162.6, 57.3], [30.0, 133.0, 100.3, 40.0],
		[133.0, 190.0, 97.8, 31.1], [190.0, 235.0, 95.6, 31.1], [235.0, 245.0, 91.0, 25.0],
		[245.0, 259.0, 70.4, 19.2]], "#c9c0ac", 2.9)
	kit.lm.commit(model)

## 270 Park Avenue (2025): a stepped glass shaft over a fan-column lobby,
## with louvred bands at its setbacks.
static func two_seventy_park(model: Node3D) -> void:
	var kit := SkyKit.tower("clear_fin", 3.0, 4.4, [[0.0, 250.0, 57.0, 50.0], [250.0, 330.0, 56.0, 38.0],
		[330.0, 382.0, 55.0, 25.0], [382.0, 423.1, 56.9, 12.6]], "#6e7276", 3.0)
	kit.lm.commit(model)

## 432 Park Avenue (2015): a square white concrete grid, its open plant
## floors as dark bands every twelve storeys.
static func four_thirty_two_park(model: Node3D) -> void:
	var kit := SkyKit.tower("white_panel", 4.7, 4.7, [[0.0, 30.0, 43.3, 38.2], [30.0, 425.5, 28.8, 28.1]], "#d8d6d0")
	var lm := kit.lm
	lm.use("Gap", LandmarkMaterials.paint("#26282b", 0.6, 0.1))
	var core := SkyKit.rect(29.2, 28.5)
	var y := 30.0 + 56.0
	while y < 415.0:
		lm.poly_prism("Gap", core, y, y + 4.7, false)
		y += 56.4
	lm.commit(model)

## Central Park Tower (2020): glass with vertical fins, on a stepped base.
static func central_park_tower(model: Node3D) -> void:
	var kit := SkyKit.tower("clear_fin", 3.0, 4.5, [[0.0, 127.0, 57.0, 56.0], [127.0, 332.0, 46.0, 44.0, 0.0, -3.0, 3.0],
		[332.0, 472.4, 40.0, 36.0, 0.0, -3.0, 3.0]], "#8e9396", 4.0)
	kit.lm.commit(model)

## 30 Hudson Yards (2019): a sloped glass top and the Edge's deck.
static func thirty_hudson_yards(model: Node3D) -> void:
	var kit := SkyKit.tower("lowe_blue", 3.0, 4.2, [[0.0, 40.0, 117.1, 57.9]], "#8d9498")
	var low := _chamfer(49.5, 49.3, 7.0)
	var high := _chamfer(41.5, 38.1, 7.0)
	kit.loft("Facade", low, high, 40.0, 395.0)
	kit.roof("Roof", high, 395.0)
	kit.lm.box("Trim", Vector3(12.0, 337.5, 0), Vector3(56.7, 5.0, 35.4))
	kit.lm.commit(model)

## Metropolitan Life Tower (1909): a marble campanile with clock faces and a
## pyramid under a gold lantern.
static func metlife_tower(model: Node3D) -> void:
	var kit := SkyKit.tower("limestone_pier", 2.8, 3.9, [[0.0, 40.0, 75.0, 46.0], [40.0, 175.0, 23.0, 23.0],
		[175.0, 190.0, 22.0, 22.0]], "#ddd7c8", 2.8)
	var lm := kit.lm
	lm.use("Clock", LandmarkMaterials.paint("#e9e4d6", 0.5, 0.05))
	lm.use("Gold", LandmarkMaterials.gold())
	for n in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		lm.disc("Clock", Vector3(0, 150.0, 0) + (n as Vector3) * 11.7, n as Vector3, 4.0)
	lm.spire("Trim", Vector3(0, 190.0, 0), 10.5, 15.0, 3.0)
	lm.spire("Gold", Vector3(0, 205.0, 0), 3.0, 8.0)
	lm.commit(model)

## Citigroup Center (1977): a square aluminium tower on four mega-columns
## with its roof cut at 45 degrees, sloping south (-Z).
static func citigroup(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Trim", LandmarkMaterials.paint("#b5b9bd", 0.45, 0.6))
	lm.use("Slope", LandmarkMaterials.paint("#a9adb1", 0.35, 0.8))
	var kit := SkyKit.new(lm)
	kit.wall("Facade", "silver_reflective", 3.0, 3.8)
	var s := 49.3 * 0.5
	var low_y := 279.0 - 49.3 * 0.83
	kit.prism("Facade", SkyKit.rect(49.3, 49.3), 35.0, low_y)
	for offset in [Vector2(s - 4.0, 0), Vector2(-s + 4.0, 0), Vector2(0, s - 4.0), Vector2(0, -s + 4.0)]:
		lm.box("Trim", Vector3(offset.x, 17.5, offset.y), Vector3(8.0, 35.0, 8.0))
	lm.box("Trim", Vector3(0, 17.5, 0), Vector3(14.0, 35.0, 14.0))
	# The cut: north wall to the peak, two triangular sides and the slope.
	var a := Vector3(-s, low_y, -s)
	var b := Vector3(s, low_y, -s)
	var c := Vector3(s, low_y, s)
	var d := Vector3(-s, low_y, s)
	var c2 := Vector3(s, 279.0, s)
	var d2 := Vector3(-s, 279.0, s)
	kit.face("Facade", Vector2(-s, s), Vector2(s, s), low_y, 279.0, Vector3.BACK)
	lm.tri("Slope", a, b, c2, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.tri("Slope", a, c2, d2, Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.tri("Slope", b, c, c2, Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.tri("Slope", a, d, d2, Vector3.LEFT, Vector3.LEFT, Vector3.LEFT, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.commit(model)
