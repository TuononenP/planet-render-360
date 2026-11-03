class_name LandmarkSfBayBridgeEast
extends RefCounted

## Bay Bridge East Span (2013), in true metres along +X with y = 0 at the
## water. +X runs toward Oakland (true bearing 54.5 deg, registry yaw_deg
## -35.5); the run is centred 400 m east of the tower, so the tower stands
## at x = -400. Built from the self-anchored suspension span (SAS) and the
## first 650 m of the concrete skyway beyond it.
##
## The SAS: one 160 m tower of four tapering steel legs in a row along the
## bridge, tied by shear links, standing in the 20 m median between the two
## 29 m wide steel box-girder decks. A single 0.69 m cable runs from the
## tower saddle down the 385 m main span to anchor in the east end of the
## deck, and down the back span to loop round the west end under the deck
## (self-anchored: the deck carries its own cable tension). Suspender pairs
## splay from the cable to the inner edge of each deck.
const BE_TOWER_X := -400.0
const BE_START := -650.0
const BE_END := 650.0
const BE_SAS_END := -2.0
const BE_DECK_Y := 60.0
const BE_DECK_Z := 24.5
const BE_DECK_W := 29.0
const BE_DEPTH := 4.5
const BE_TOP_M := 160.0
const BE_SADDLE_Y := 158.5
const BE_MAIN := 385.0
const BE_BACK := 180.0
const BE_LEG_X := [-9.0, -3.0, 3.0, 9.0]
const BE_LEG_STAGES := [[8.0, 60.0, 2.4, 3.6, 2.2, 3.3], [60.0, 110.0, 2.2, 3.3, 1.9, 2.9],
	[110.0, 156.0, 1.9, 2.9, 1.5, 2.4]]
const BE_LINKS := [70.0, 90.0, 110.0, 130.0, 148.0]
const BE_SKYWAY_PIERS := [78.0, 238.0, 398.0, 558.0]
const BE_SKYWAY_GRADE := 0.02

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#D3D5D6", 0.5, 0.4))
	lm.use("Cable", LandmarkMaterials.paint("#EDEEEE", 0.45, 0.5))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3E3E3E", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B2AEA6", 4.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FF3B2F", 1.4))
	_tower(lm)
	_cable(lm)
	_decks(lm)
	_skyway_piers(lm)
	lm.commit(model)

## Deck top height at x: level over the SAS, falling on the skyway.
static func deck_y(x: float) -> float:
	return BE_DECK_Y - BE_SKYWAY_GRADE * maxf(x - BE_SAS_END, 0.0)

## The tower: pile cap, four legs in three tapering stages with ledges, the
## shear links between the legs, the cap beam and the saddle housing.
static func _tower(lm: LandmarkMesh) -> void:
	var x0 := BE_TOWER_X
	lm.box("Concrete", Vector3(x0, 4.0, 0), Vector3(26.0, 8.0, 37.0))
	lm.box("Concrete", Vector3(x0, 8.3, 0), Vector3(24.0, 0.7, 34.0))
	for dx in BE_LEG_X:
		for st in BE_LEG_STAGES:
			LandmarkSfBayBridge.taper(lm, "Steel", Vector3(x0 + float(dx), float(st[0]), 0), float(st[2]),
				float(st[3]), float(st[4]), float(st[5]), float(st[1]) - float(st[0]))
			lm.box("Steel", Vector3(x0 + float(dx), float(st[1]) - 0.3, 0), Vector3(float(st[4]) * 2.0 + 0.5, 0.6,
				float(st[5]) * 2.0 + 0.5))
	# Shear links: a plate box joining each pair of legs at five levels.
	for y in BE_LINKS:
		for mx in [-6.0, 0.0, 6.0]:
			lm.box("Steel", Vector3(x0 + float(mx), float(y), 0), Vector3(5.2, 2.6, 4.6))
			lm.box("Cable", Vector3(x0 + float(mx), float(y), 0), Vector3(3.4, 1.4, 4.9), Basis(), 0.0)
	lm.box("Steel", Vector3(x0, 157.2, 0), Vector3(26.0, 2.4, 5.4))
	lm.box("Steel", Vector3(x0, 158.9, 0), Vector3(7.0, 2.2, 3.2))
	for dx in [-9.0, 9.0]:
		lm.box("Lamp", Vector3(x0 + float(dx), BE_TOP_M - 0.3, 0), Vector3(0.6, 0.6, 0.6), Basis(), 0.0)
	lm.box("Lamp", Vector3(x0, BE_TOP_M - 0.3, 0), Vector3(0.6, 0.6, 0.6), Basis(), 0.0)

## Main-span cable y at x (east of the tower: sag 40 m to the deck end;
## west: back span, sag 15 m), the hangers' reference.
static func cable_y(x: float) -> float:
	if x >= BE_TOWER_X:
		var t := (x - BE_TOWER_X) / BE_MAIN
		return lerpf(BE_SADDLE_Y, BE_DECK_Y + 3.0, t) - 40.0 * 4.0 * t * (1.0 - t)
	var u := (BE_TOWER_X - x) / BE_BACK
	return lerpf(BE_SADDLE_Y, BE_DECK_Y + 3.0, u) - 15.0 * 4.0 * u * (1.0 - u)

static func _cable(lm: LandmarkMesh) -> void:
	var saddle := Vector3(BE_TOWER_X, BE_SADDLE_Y, 0)
	var east_end := Vector3(BE_TOWER_X + BE_MAIN, BE_DECK_Y + 3.0, 0)
	var west_end := Vector3(BE_TOWER_X - BE_BACK, BE_DECK_Y + 3.0, 0)
	LandmarkCoreBBridgeKit.tube(lm, "Cable", LandmarkCoreBBridgeKit.sag_points(saddle, east_end, 40.0, 100), 0.4, 10)
	# Back span, then the loop under the west end of the deck.
	var pts := LandmarkCoreBBridgeKit.sag_points(saddle, west_end, 15.0, 44)
	var loop := PackedVector3Array()
	loop.append_array(pts)
	for p in [Vector3(-1.5, -2.6, 0), Vector3(-3.0, -5.6, 0), Vector3(-3.6, -7.6, 0), Vector3(-2.5, -9.0, 0),
			Vector3(0.0, -9.6, 0), Vector3(12.0, -9.7, 0), Vector3(40.0, -9.7, 0)]:
		loop.append(west_end + (p as Vector3))
	LandmarkCoreBBridgeKit.tube(lm, "Cable", loop, 0.4, 10)
	lm.box("Steel", west_end + Vector3(42.0, -9.7, 0), Vector3(3.0, 1.6, 2.2))
	lm.box("Steel", east_end + Vector3(0.0, -1.5, 0), Vector3(3.0, 3.4, 2.2))
	# Suspender pairs splaying to the inner edge of each deck.
	var x := BE_TOWER_X - BE_BACK + 10.0
	while x < BE_TOWER_X + BE_MAIN - 8.0:
		var cy := cable_y(x)
		if absf(x - BE_TOWER_X) > 14.0 and cy - (BE_DECK_Y + 2.5) > 3.0:
			for side in [-1.0, 1.0]:
				lm.beam("Cable", Vector3(x, cy, 0), Vector3(x, BE_DECK_Y + 0.8, float(side) * (BE_DECK_Z - BE_DECK_W * 0.5 + 0.4)),
					0.14, 0.14)
			lm.box("Cable", Vector3(x, cy, 0), Vector3(1.0, 1.0, 1.0), Basis(), 0.0)
		x += 8.0

## The two decks: steel box girders over the SAS and the skyway's concrete
## box girders, one per carriageway, each between its pier lines.
static func _decks(lm: LandmarkMesh) -> void:
	for side in [-1.0, 1.0]:
		var zc: float = side * BE_DECK_Z
		_girder(lm, "Steel", BE_START, BE_SAS_END, zc)
		var x0 := BE_SAS_END
		for px in BE_SKYWAY_PIERS:
			_girder(lm, "Concrete", x0, float(px), zc)
			x0 = float(px)
		_girder(lm, "Concrete", x0, BE_END, zc)
		# Lamp standards on the median edge of the SAS decks.
		var lx := BE_START + 20.0
		while lx < BE_SAS_END - 10.0:
			LandmarkCoreBBridgeKit.lamp(lm, "Steel", "Lamp", Vector3(lx, BE_DECK_Y, side * (BE_DECK_Z - BE_DECK_W * 0.5 + 0.7)),
				9.0, Vector3(0, 0, side * 2.2))
			lx += 40.0

## One box girder between x0 and x1 (top surface falling per deck_y): the
## roadway, trapezoid box with sloping webs, edge barriers and end faces.
static func _girder(lm: LandmarkMesh, key: String, x0: float, x1: float, zc: float) -> void:
	var y0 := deck_y(x0)
	var y1 := deck_y(x1)
	var hw := BE_DECK_W * 0.5
	var hb := BE_DECK_W * 0.27
	var d := BE_DEPTH
	var tl0 := Vector3(x0, y0, zc - hw)
	var tr0 := Vector3(x0, y0, zc + hw)
	var tl1 := Vector3(x1, y1, zc - hw)
	var tr1 := Vector3(x1, y1, zc + hw)
	var bl0 := Vector3(x0, y0 - d, zc - hb)
	var br0 := Vector3(x0, y0 - d, zc + hb)
	var bl1 := Vector3(x1, y1 - d, zc - hb)
	var br1 := Vector3(x1, y1 - d, zc + hb)
	var tilt := Vector3(-(y1 - y0), x1 - x0, 0).normalized()
	lm.quad("Deck", tl0, tl1, tr1, tr0, tilt)
	lm.quad(key, bl0, br0, br1, bl1, -tilt)
	var slope := hw - hb
	lm.quad(key, tl0, bl0, bl1, tl1, Vector3(0, -slope, -d).normalized())
	lm.quad(key, tr0, tr1, br1, br0, Vector3(0, -slope, d).normalized())
	lm.quad(key, tl0, tr0, br0, bl0, Vector3(-1, 0, 0))
	lm.quad(key, tl1, bl1, br1, tr1, Vector3(1, 0, 0))
	for e in [-1.0, 1.0]:
		var ez: float = zc + float(e) * (hw - 0.3)
		lm.beam("Concrete", Vector3(x0, y0 + 0.45, ez), Vector3(x1, y1 + 0.45, ez), 0.5, 0.9)
	lm.beam("Concrete", Vector3(x0, y0 + 0.4, zc), Vector3(x1, y1 + 0.4, zc), 0.4, 0.8)

## Skyway piers: a tapering shaft and pier head under each deck at every
## pier line, on a pile cap at the water.
static func _skyway_piers(lm: LandmarkMesh) -> void:
	for px in BE_SKYWAY_PIERS:
		var x := float(px)
		var bottom := deck_y(x) - BE_DEPTH
		for side in [-1.0, 1.0]:
			var z: float = side * BE_DECK_Z
			lm.box("Concrete", Vector3(x, 1.0, z), Vector3(9.0, 2.0, 15.0))
			LandmarkSfBayBridge.taper(lm, "Concrete", Vector3(x, 2.0, z), 2.6, 4.4, 2.1, 3.4, bottom - 3.0 - 2.0)
			lm.box("Concrete", Vector3(x, bottom - 1.5, z), Vector3(5.0, 3.0, 11.0))
