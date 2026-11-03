class_name LandmarkSfBayBridge
extends RefCounted

## San Francisco-Oakland Bay Bridge, in true metres along +X with y = 0 at
## the water (LocationData `base: water`). The origin is the centre of the
## central anchorage (W4); +X runs toward Yerba Buena Island (true bearing
## 40.4 deg, registry yaw_deg -49.6). Positions follow OpenStreetMap's pier
## and pylon ways: towers W2, W3, W5, W6 at +-1081 m and +-378 m, the San
## Francisco anchorage 1435 m west and the island anchorage 1435 m east.

## West Span (1936): two suspension bridges end to end, each with a 704 m
## main span between steel towers and 354-380 m side spans, sharing the huge
## concrete central anchorage. The grey double-deck Warren truss, 18.3 m
## wide and 14.6 m deep, carries the westbound upper deck and the eastbound
## lower deck, hung by suspender pairs every 30 ft from the 0.72 m cables.
## Each tower is two tapering steel legs outside the deck, braced by
## horizontal struts and X diagonals above the roadway and by a portal
## below it. RoadBuilder leaves the OSM decks out of its span.
const BW_TOWERS := [-1081.0, -378.0, 378.0, 1081.0]
const BW_ANCH := 1435.0
const BW_END := 1535.0
const BW_TOP_M := 160.0
const BW_SADDLE := 157.0
const BW_CABLE_Z := 12.4
const BW_HALF_W := 9.15
const BW_BOTTOM := 56.0
const BW_TOP_CHORD := 70.6
const BW_LOWER := 60.0
const BW_UPPER := 66.0
const BW_ANCH_Y := 78.0
const BW_PANELS := 210
const BW_HANGER := 9.14
const BW_MAIN_SAG := 77.0
const BW_SIDE_SAG := 7.0
## Cable nodes x: anchorage, tower, tower, centre, tower, tower, anchorage.
const BW_NODES := [-1435.0, -1081.0, -378.0, 0.0, 378.0, 1081.0, 1435.0]
const BW_NODE_Y := [78.0, 157.0, 157.0, 78.0, 157.0, 157.0, 78.0]
## Tower leg stages [y0, y1, half along x at y0, half across at y0, same at y1].
const BW_LEG_STAGES := [[11.0, 56.0, 3.2, 2.5, 2.9, 2.3], [56.0, 108.0, 2.9, 2.3, 2.5, 2.0],
	[108.0, 148.0, 2.5, 2.0, 2.0, 1.7]]
const BW_STRUTS := [76.0, 98.0, 120.0, 142.0]

static func west(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#8C9296", 0.55, 0.45))
	lm.use("Cable", LandmarkMaterials.paint("#A9AEB0", 0.5, 0.5))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3E3E3E", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A8A49C", 4.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FF3B2F", 1.4))
	for x in BW_TOWERS:
		_tower(lm, float(x))
	_central_anchorage(lm)
	_end_anchorage(lm, -1.0)
	_end_anchorage(lm, 1.0)
	_cables(lm)
	_deck(lm)
	lm.commit(model)

## One tower on its pier: concrete pier, the legs in three tapering stages
## with set-back ledges, the portal below the deck, the braced panels above
## it and the cap with saddle housings and the red beacons.
static func _tower(lm: LandmarkMesh, x: float) -> void:
	lm.box("Concrete", Vector3(x, 5.5, 0), Vector3(22.0, 11.0, 36.0))
	lm.box("Concrete", Vector3(x, 11.4, 0), Vector3(19.0, 0.8, 32.0))
	for side in [-1.0, 1.0]:
		var z: float = side * BW_CABLE_Z
		for st in BW_LEG_STAGES:
			taper(lm, "Steel", Vector3(x, float(st[0]), z), float(st[2]), float(st[3]), float(st[4]),
				float(st[5]), float(st[1]) - float(st[0]))
			lm.box("Steel", Vector3(x, float(st[1]) - 0.35, z), Vector3(float(st[4]) * 2.0 + 0.7, 0.7,
				float(st[5]) * 2.0 + 0.7))
		# Fascia plates on the outer faces of the leg.
		for f in [-1.0, 1.0]:
			lm.box("Steel", Vector3(x, 80.0, z + float(f) * 2.6), Vector3(0.9, 60.0, 0.4), Basis(), 0.0)
	# Portal strut below the roadway and the cross struts above it.
	lm.box("Steel", Vector3(x, 45.5, 0), Vector3(5.0, 2.6, BW_CABLE_Z * 2.0))
	lm.beam("Steel", Vector3(x, 41.0, -BW_CABLE_Z), Vector3(x, 49.0, BW_CABLE_Z), 0.9, 1.2)
	lm.beam("Steel", Vector3(x, 41.0, BW_CABLE_Z), Vector3(x, 49.0, -BW_CABLE_Z), 0.9, 1.2)
	for i in BW_STRUTS.size():
		var y: float = BW_STRUTS[i]
		lm.box("Steel", Vector3(x, y, 0), Vector3(4.6, 2.2, BW_CABLE_Z * 2.0))
		if i + 1 < BW_STRUTS.size():
			var y1: float = BW_STRUTS[i + 1]
			lm.beam("Steel", Vector3(x, y + 1.1, -BW_CABLE_Z + 1.5), Vector3(x, y1 - 1.1, BW_CABLE_Z - 1.5), 1.0, 1.4)
			lm.beam("Steel", Vector3(x, y + 1.1, BW_CABLE_Z - 1.5), Vector3(x, y1 - 1.1, -BW_CABLE_Z + 1.5), 1.0, 1.4)
	lm.box("Steel", Vector3(x, 149.0, 0), Vector3(5.6, 2.4, BW_CABLE_Z * 2.0 + 3.0))
	for side in [-1.0, 1.0]:
		var z: float = side * BW_CABLE_Z
		lm.box("Steel", Vector3(x, 152.5, z), Vector3(7.5, 4.6, 4.6))
		lm.box("Steel", Vector3(x, 155.5, z), Vector3(5.4, 1.6, 3.6))
		lm.box("Lamp", Vector3(x, BW_TOP_M - 0.3, z), Vector3(0.6, 0.6, 0.6), Basis(), 0.0)

## Centre anchorage W4: broad concrete base and block with a raised
## shoulder either side of the roadway where the four cables are anchored.
static func _central_anchorage(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(0, 6.0, 0), Vector3(74.0, 12.0, 62.0))
	lm.box("Concrete", Vector3(0, 33.0, 0), Vector3(48.0, 42.0, 44.0))
	lm.box("Concrete", Vector3(0, 53.6, 0), Vector3(52.0, 1.6, 48.0))
	for side in [-1.0, 1.0]:
		var z: float = side * 13.5
		lm.box("Concrete", Vector3(0, 69.0, z), Vector3(42.0, 30.0, 6.0))
		lm.box("Concrete", Vector3(0, 84.4, z), Vector3(44.0, 1.0, 7.0))
		for k in 4:
			lm.box("Concrete", Vector3(0, 60.0 + 7.0 * k, z), Vector3(43.0, 0.5, 6.5), Basis(), 0.0)

## Shore anchorage block (`dir` -1 San Francisco, +1 the island): block, the
## flanking shoulders the cables enter and the approach pier under the truss.
static func _end_anchorage(lm: LandmarkMesh, dir: float) -> void:
	var c: float = dir * (BW_ANCH + 14.0)
	lm.box("Concrete", Vector3(c, 5.0, 0), Vector3(54.0, 10.0, 48.0))
	lm.box("Concrete", Vector3(c, 31.0, 0), Vector3(46.0, 42.0, 40.0))
	for side in [-1.0, 1.0]:
		var z: float = side * 13.5
		lm.box("Concrete", Vector3(c - dir * 3.0, 66.0, z), Vector3(38.0, 26.0, 6.0))
		lm.box("Concrete", Vector3(c - dir * 3.0, 79.5, z), Vector3(40.0, 1.0, 7.0))
	for side in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(dir * (BW_END - 18.0), 27.0, side * 7.0), Vector3(5.0, 54.0, 4.0))
	lm.box("Concrete", Vector3(dir * (BW_END - 18.0), 55.0, 0), Vector3(6.0, 1.6, 22.0))

## Cable height at x: a parabola per segment between the cable nodes.
static func cable_y(x: float) -> float:
	for i in BW_NODES.size() - 1:
		var xa: float = BW_NODES[i]
		var xb: float = BW_NODES[i + 1]
		if x >= xa and x <= xb:
			var t := (x - xa) / (xb - xa)
			return lerpf(float(BW_NODE_Y[i]), float(BW_NODE_Y[i + 1]), t) - _sag(i) * 4.0 * t * (1.0 - t)
	return BW_ANCH_Y

static func _sag(seg: int) -> float:
	return BW_MAIN_SAG if seg == 1 or seg == 4 else BW_SIDE_SAG

## Main cables (two per side bridge) through the tower saddles to the
## anchorages, and suspender pairs every 30 ft down to the truss.
static func _cables(lm: LandmarkMesh) -> void:
	for side in [-1.0, 1.0]:
		var z: float = side * BW_CABLE_Z
		for i in BW_NODES.size() - 1:
			var xa: float = BW_NODES[i]
			var xb: float = BW_NODES[i + 1]
			var ya: float = BW_NODE_Y[i]
			var yb: float = BW_NODE_Y[i + 1]
			var n := 110 if (i == 1 or i == 4) else 44
			LandmarkCoreBBridgeKit.tube(lm, "Cable", LandmarkCoreBBridgeKit.sag_points(Vector3(xa, ya, z),
				Vector3(xb, yb, z), _sag(i), n), 0.42, 10)
		var x := -BW_ANCH + BW_HANGER * 0.5
		while x < BW_ANCH:
			var cy := cable_y(x)
			var near_tower := false
			for tx in BW_TOWERS:
				near_tower = near_tower or absf(x - float(tx)) < 6.0
			if not near_tower and absf(x) > 26.0 and cy - BW_TOP_CHORD > 2.5 and absf(x) < BW_ANCH - 10.0:
				for o in [-0.3, 0.3]:
					lm.beam("Cable", Vector3(x + float(o), cy, z), Vector3(x + float(o), BW_TOP_CHORD - 0.2, side * (BW_HALF_W + 0.5)),
						0.1, 0.1)
				lm.box("Cable", Vector3(x, cy, z), Vector3(1.4, 1.2, 1.2), Basis(), 0.0)
				lm.box("Steel", Vector3(x, BW_TOP_CHORD, side * (BW_HALF_W + 0.5)), Vector3(1.0, 0.6, 0.8), Basis(), 0.0)
			x += BW_HANGER

## The double-deck truss run: two Warren trusses, chord stringers, the
## upper and lower roadways with barriers and a median, floor beams at
## every panel and the lateral and sway bracing.
static func _deck(lm: LandmarkMesh) -> void:
	var length := BW_END * 2.0
	var pitch := length / float(BW_PANELS)
	for side in [-1.0, 1.0]:
		var z: float = side * BW_HALF_W
		var bottom := PackedVector3Array()
		var top := PackedVector3Array()
		for k in BW_PANELS + 1:
			var x := -BW_END + pitch * float(k)
			bottom.append(Vector3(x, BW_BOTTOM, z))
			top.append(Vector3(x, BW_TOP_CHORD, z))
		LandmarkCoreBBridgeKit.truss(lm, "Steel", bottom, top, 1.0, 0.6, Vector3(0, 0, 1), true, false)
		lm.box("Steel", Vector3(0, BW_BOTTOM, z), Vector3(length, 1.1, 1.1), Basis(), 0.0)
		lm.box("Steel", Vector3(0, BW_TOP_CHORD, z), Vector3(length, 1.1, 1.1), Basis(), 0.0)
		for y in [BW_LOWER - 0.8, BW_UPPER - 0.8]:
			lm.box("Steel", Vector3(0, y, z), Vector3(length, 0.9, 0.9), Basis(), 0.0)
	# Roadways, edge barriers and the median of each deck.
	for y in [BW_LOWER, BW_UPPER]:
		lm.box("Deck", Vector3(0, y - 0.3, 0), Vector3(length, 0.6, BW_HALF_W * 2.0 - 0.6), Basis(), 0.0)
		for side in [-1.0, 1.0]:
			lm.box("Concrete", Vector3(0, y + 0.45, side * (BW_HALF_W - 0.6)), Vector3(length, 0.9, 0.5), Basis(), 0.0)
		lm.box("Concrete", Vector3(0, y + 0.4, 0), Vector3(length, 0.8, 0.4), Basis(), 0.0)
	for k in BW_PANELS + 1:
		var x := -BW_END + pitch * float(k)
		for y in [BW_LOWER - 1.2, BW_UPPER - 1.2]:
			lm.beam("Steel", Vector3(x, y, -BW_HALF_W), Vector3(x, y, BW_HALF_W), 0.7, 1.5)
		# Sway frame across the top chords at every third panel.
		if k % 3 == 0:
			lm.beam("Steel", Vector3(x, BW_TOP_CHORD, -BW_HALF_W), Vector3(x, BW_TOP_CHORD, BW_HALF_W), 0.8, 0.9)
		if k < BW_PANELS and k % 2 == 0:
			var x1 := minf(x + pitch * 2.0, BW_END)
			lm.beam("Steel", Vector3(x, BW_BOTTOM, -BW_HALF_W), Vector3(x1, BW_BOTTOM, BW_HALF_W), 0.5, 0.5)
			lm.beam("Steel", Vector3(x, BW_BOTTOM, BW_HALF_W), Vector3(x1, BW_BOTTOM, -BW_HALF_W), 0.5, 0.5)
			lm.beam("Steel", Vector3(x, BW_TOP_CHORD, -BW_HALF_W), Vector3(x1, BW_TOP_CHORD, BW_HALF_W), 0.5, 0.5)
			lm.beam("Steel", Vector3(x, BW_TOP_CHORD, BW_HALF_W), Vector3(x1, BW_TOP_CHORD, -BW_HALF_W), 0.5, 0.5)

## Tapering rectangular shaft: half sizes (hx0, hz0) at the base and
## (hx1, hz1) at the top, `h` tall, base centre at `base`; capped on top.
static func taper(lm: LandmarkMesh, key: String, base: Vector3, hx0: float, hz0: float, hx1: float,
		hz1: float, h: float) -> void:
	var b := [Vector3(-hx0, 0, -hz0), Vector3(hx0, 0, -hz0), Vector3(hx0, 0, hz0), Vector3(-hx0, 0, hz0)]
	var t := [Vector3(-hx1, h, -hz1), Vector3(hx1, h, -hz1), Vector3(hx1, h, hz1), Vector3(-hx1, h, hz1)]
	var sx := (hx0 - hx1) / h
	var sz := (hz0 - hz1) / h
	var normals := [Vector3(0, sz, -1), Vector3(1, sx, 0), Vector3(0, sz, 1), Vector3(-1, sx, 0)]
	for i in 4:
		var j := (i + 1) % 4
		lm.quad(key, base + b[i], base + b[j], base + t[j], base + t[i], (normals[i] as Vector3).normalized())
	lm.quad(key, base + t[0], base + t[1], base + t[2], base + t[3], Vector3.UP)

## East Span: see LandmarkSfBayBridgeEast.
static func east(model: Node3D) -> void:
	LandmarkSfBayBridgeEast.build(model)
