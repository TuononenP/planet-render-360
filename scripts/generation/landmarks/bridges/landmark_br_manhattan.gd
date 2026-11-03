class_name LandmarkBrManhattan
extends RefCounted

## Manhattan Bridge, metres. The 448 m main span and 221 m side spans
## follow NYC DOT / ASCE; the roadway is ~41 m above the East River.
## Local +X runs from Manhattan toward Brooklyn, Y=0 at sea level.
## https://www.nyc.gov/html/dot/html/infrastructure/manhattan-bridge.shtml
## https://www.asce.org/about-civil-engineering/history-and-heritage/historic-landmarks/manhattan-bridge
const MAIN_HALF := 224.0
const ANCHOR := 445.0
## The Manhattan arch stands 1,030 m from the centre, so the approaches
## continue beyond it rather than leaving the portal detached.
const END := 1070.0
const DECK := 41.0
const TOWER := 103.0
const HALF_WIDTH := 18.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#75838A", 0.6, 0.35))
	lm.use("Cable", LandmarkMaterials.paint("#606E75", 0.55, 0.4))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Masonry", LandmarkMaterials.pbr("limestone", "#BAB5A9", 4.0))
	for side in [-1.0, 1.0]:
		_tower(lm, float(side) * MAIN_HALF)
		_anchorage(lm, float(side) * ANCHOR)
	_deck(lm)
	_cables(lm)
	_portal(lm)
	lm.commit(model)

static func _deck_y(x: float) -> float:
	var d := absf(x)
	return DECK if d <= ANCHOR else lerpf(DECK, 8.0, clampf((d - ANCHOR) / (END - ANCHOR), 0.0, 1.0))

static func _tower(lm: LandmarkMesh, x: float) -> void:
	lm.box("Masonry", Vector3(x, 5.0, 0), Vector3(20.0, 10.0, 48.0))
	for side in [-1.0, 1.0]:
		var z: float = float(side) * 16.0
		lm.box("Steel", Vector3(x, 55.0, z), Vector3(6.0, 96.0, 6.0))
		lm.box("Steel", Vector3(x, 103.0, z), Vector3(8.0, 4.0, 8.0))
		lm.box("Steel", Vector3(x, 107.0, z), Vector3(3.5, 4.0, 3.5))
	for y in [32.0, 50.0, 77.0, 99.0]:
		lm.box("Steel", Vector3(x, float(y), 0), Vector3(5.0, 4.0, 34.0))
	for face in [-1.0, 1.0]:
		var xx: float = x + float(face) * 3.2
		for band in [[51.0, 76.0], [78.0, 98.0]]:
			lm.beam("Steel", Vector3(xx, band[0], -13.0), Vector3(xx, band[1], 13.0), 1.1, 1.1)
			lm.beam("Steel", Vector3(xx, band[0], 13.0), Vector3(xx, band[1], -13.0), 1.1, 1.1)

static func _anchorage(lm: LandmarkMesh, x: float) -> void:
	lm.box("Masonry", Vector3(x, 15.0, 0), Vector3(34.0, 30.0, 48.0))
	lm.box("Masonry", Vector3(x, 31.0, 0), Vector3(31.0, 2.0, 46.0))

static func _deck(lm: LandmarkMesh) -> void:
	var n := 110
	for i in n:
		var a := lerpf(-END, END, float(i) / n)
		var b := lerpf(-END, END, float(i + 1) / n)
		var y0 := _deck_y(a)
		var y1 := _deck_y(b)
		lm.beam("Deck", Vector3(a, y0, 0), Vector3(b, y1, 0), HALF_WIDTH * 2.0, 1.2, Vector3(0, 0, 1))
		for side in [-1.0, 1.0]:
			var z: float = float(side) * 17.0
			lm.beam("Steel", Vector3(a, y0 - 7.0, z), Vector3(b, y1 - 7.0, z), 0.8, 0.8)
			lm.beam("Steel", Vector3(a, y0 + 1.0, z), Vector3(b, y1 + 1.0, z), 0.8, 0.8)
			lm.beam("Steel", Vector3(a, y0 - 7.0, z), Vector3(b, y1 + 1.0, z), 0.55, 0.55)
			lm.beam("Steel", Vector3(a, y0 + 1.0, z), Vector3(b, y1 - 7.0, z), 0.55, 0.55)
		if i % 8 == 0 and absf(a) > ANCHOR + 18.0:
			lm.box("Masonry", Vector3(a, y0 * 0.5 - 3.5, 0), Vector3(4.0, maxf(y0 - 7.0, 1.0), 24.0))

static func _cable_y(x: float) -> float:
	var ax := absf(x)
	if ax <= MAIN_HALF:
		return 48.0 + (TOWER - 48.0) * pow(ax / MAIN_HALF, 2.0)
	var t := clampf((ax - MAIN_HALF) / (ANCHOR - MAIN_HALF), 0.0, 1.0)
	return lerpf(TOWER, 31.0, t)

static func _cables(lm: LandmarkMesh) -> void:
	for z in [-17.0, -12.0, 12.0, 17.0]:
		var last := Vector3(-ANCHOR, _cable_y(-ANCHOR), float(z))
		for i in range(1, 97):
			var x := lerpf(-ANCHOR, ANCHOR, float(i) / 96.0)
			var p := Vector3(x, _cable_y(x), float(z))
			lm.beam("Cable", last, p, 0.85, 0.85)
			last = p
		for i in range(1, 72):
			var x := lerpf(-ANCHOR, ANCHOR, float(i) / 72.0)
			var y := _cable_y(x)
			if y > _deck_y(x) + 1.0:
				lm.beam("Cable", Vector3(x, _deck_y(x), float(z)), Vector3(x, y, float(z)), 0.16, 0.16)

## Carrère and Hastings' Manhattan entrance: a high stone arch and the
## curved colonnades at the city end of the approach.
static func _portal(lm: LandmarkMesh) -> void:
	var x := -1030.0
	for side in [-1.0, 1.0]:
		var z: float = float(side) * 14.0
		lm.box("Masonry", Vector3(x, 10.0, z), Vector3(10.0, 20.0, 9.0))
		lm.box("Masonry", Vector3(x, 21.0, z), Vector3(11.0, 2.0, 10.0))
	# The portal has a curved opening, not a rectangular lintel.
	LandmarkCoreBBridgeKit.pointed_arch(lm, "Masonry", x, 10.0, 0.0, 19.0, 9.5, 11.0)
	lm.box("Masonry", Vector3(x, 21.25, 0), Vector3(10.0, 1.5, 19.0))
	for face in [-1.0, 1.0]:
		LandmarkDetail.arch(lm, "Masonry", Vector3(x + float(face) * 5.05, 11.0, 0),
			Vector3(float(face), 0, 0), 19.0, 1.0, 0.3)
	lm.box("Masonry", Vector3(x, 25.0, 0), Vector3(11.0, 6.0, 38.0))
	for side in [-1.0, 1.0]:
		for i in 9:
			var t := float(i) / 8.0
			var z: float = float(side) * (20.0 + 48.0 * t)
			var cx := x + 18.0 * sin(t * PI * 0.5)
			lm.box("Masonry", Vector3(cx, 6.0, z), Vector3(2.0, 12.0, 2.0))
			if i > 0:
				var prev := float(i - 1) / 8.0
				lm.beam("Masonry", Vector3(x + 18.0 * sin(prev * PI * 0.5), 12.3,
					float(side) * (20.0 + 48.0 * prev)), Vector3(cx, 12.3, z), 2.5, 1.2)
