class_name LandmarkTowerBridge
extends RefCounted

## Tower Bridge (1894) in true metres, along +X with y = 0 at the
## Thames (LocationData `base: water`): the two Gothic towers on their
## boat-shaped granite river piers (cutwaters up and down stream, ±Z),
## Portland-stone and granite cladding over the steel frame, four
## octagonal corner turrets with slate spirelets, lancet windows in
## tiers, a pointed carriage arch, the steep slate pyramid roof with
## lucarnes and the gilded finial (65 m); the two bascule leaves of the
## 61 m (200 ft) central span closed at 8.6 m; the two glazed lattice
## walkways 42 m over the river; and over the 82 m side spans the
## stiffened blue-and-white suspension chains swinging down from the
## towers and up to the turreted shore towers.

const TOP_M := 65.0
const TOWER := Vector3(18.0, 0.0, 26.0)
const TOWER_X := 39.5
const DECK_M := 8.6
const WALK_M := 42.0
const SHORE_X := 122.0
const PIER_M := 4.0
const EAVES_M := 50.0
const ROAD_HALF := 7.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC6B2", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A39D94", 3.0))
	lm.use("Blue", LandmarkMaterials.paint("#4E86B5", 0.55, 0.3))
	lm.use("White", LandmarkMaterials.paint("#E9EEF1", 0.55, 0.2))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4A5157", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3338"))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFD9A0", 1.0))
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(float(s) * TOWER_X, 0, 0))
		_shore_tower(lm, Vector3(float(s) * SHORE_X, 0, 0))
	var inner := TOWER_X - TOWER.x * 0.5
	_bascules(lm, inner)
	_walkways(lm, inner)
	for s in [-1.0, 1.0]:
		_side_span(lm, float(s))
	lm.commit(model)

## Closed bascule leaves: deck, footways, the four blue main girders
## with their cross girders, the leaf joint, cast-iron parapets and
## lamp standards.
static func _bascules(lm: LandmarkMesh, inner: float) -> void:
	for s in [-1.0, 1.0]:
		var cx: float = s * inner * 0.5
		lm.box("Deck", Vector3(cx, DECK_M + 0.2, 0), Vector3(inner - 0.1, 0.4, ROAD_HALF * 2.0))
		for side in [-1.0, 1.0]:
			lm.box("Stone", Vector3(cx, DECK_M + 0.4, float(side) * (ROAD_HALF - 1.2)), Vector3(inner - 0.1, 0.4, 2.4))
		for gz in [-ROAD_HALF, -2.6, 2.6, ROAD_HALF]:
			lm.box("Blue", Vector3(cx, DECK_M - 1.4, float(gz)), Vector3(inner - 0.1, 3.0, 0.6))
		for k in 8:
			var x: float = s * (1.0 + (inner - 2.0) * float(k) / 7.0)
			lm.beam("Blue", Vector3(x, DECK_M - 0.9, -ROAD_HALF), Vector3(x, DECK_M - 0.9, ROAD_HALF), 0.4, 1.6)
	_parapet(lm, -inner, inner)

## Ornamental parapet along both deck edges from x0 to x1: blue posts,
## white rails and a lamp standard every fourth post.
static func _parapet(lm: LandmarkMesh, x0: float, x1: float) -> void:
	var n := int((x1 - x0) / 2.5)
	for side in [-1.0, 1.0]:
		var z: float = side * (ROAD_HALF + 0.1)
		lm.box("White", Vector3((x0 + x1) * 0.5, DECK_M + 1.5, z), Vector3(x1 - x0, 0.18, 0.3), Basis(), 0.0)
		lm.box("Blue", Vector3((x0 + x1) * 0.5, DECK_M + 0.6, z), Vector3(x1 - x0, 0.25, 0.3), Basis(), 0.0)
		for k in n + 1:
			var x := x0 + (x1 - x0) * float(k) / n
			lm.box("Blue", Vector3(x, DECK_M + 1.0, z), Vector3(0.2, 1.0, 0.2), Basis(), 0.0)
			if k % 2 == 1:
				lm.beam("Blue", Vector3(x - 1.25, DECK_M + 0.75, z), Vector3(x + 1.25, DECK_M + 1.4, z), 0.08, 0.08)
				lm.beam("Blue", Vector3(x - 1.25, DECK_M + 1.4, z), Vector3(x + 1.25, DECK_M + 0.75, z), 0.08, 0.08)
			if k % 6 == 3:
				LandmarkCoreBBridgeKit.lamp(lm, "Blue", "Lamp", Vector3(x, DECK_M + 0.6, z), 4.2, Vector3(0, 0, -float(side) * 0.4))

## High-level walkways: two glazed lattice girders between the towers,
## each a boxed passage with dense criss-cross lattice on both faces.
static func _walkways(lm: LandmarkMesh, inner: float) -> void:
	var hh := 2.4
	for wz in [-5.5, 5.5]:
		var zc: float = wz
		lm.box("Windows", Vector3(0, WALK_M, zc), Vector3(inner * 2.0, hh * 2.0 - 0.6, 2.9))
		lm.box("White", Vector3(0, WALK_M + hh + 0.15, zc), Vector3(inner * 2.0, 0.3, 3.8))
		lm.box("White", Vector3(0, WALK_M - hh, zc), Vector3(inner * 2.0, 0.5, 3.6))
		for f in [-1.0, 1.0]:
			var z: float = zc + f * 1.6
			lm.box("Blue", Vector3(0, WALK_M + hh - 0.3, z), Vector3(inner * 2.0, 0.6, 0.4))
			lm.box("Blue", Vector3(0, WALK_M - hh + 0.4, z), Vector3(inner * 2.0, 0.6, 0.4))
			var n := int(inner * 2.0 / 2.0)
			for k in n:
				var xa := -inner + inner * 2.0 * float(k) / n
				var xb := -inner + inner * 2.0 * float(k + 1) / n
				lm.beam("Blue", Vector3(xa, WALK_M - hh + 0.6, z), Vector3(xb + 2.0, WALK_M + hh - 0.6, z).min(
					Vector3(inner, 1e9, 1e9)), 0.22, 0.12, Vector3(0, 0, 1))
				lm.beam("Blue", Vector3(xa, WALK_M + hh - 0.6, z), Vector3(xb + 2.0, WALK_M - hh + 0.6, z).min(
					Vector3(inner, 1e9, 1e9)), 0.22, 0.12, Vector3(0, 0, 1))
				if k % 3 == 0:
					lm.box("White", Vector3(xa, WALK_M, z), Vector3(0.35, hh * 2.0 - 0.6, 0.45))
		# Cantilever brackets out of the tower faces.
		for s in [-1.0, 1.0]:
			lm.beam("Blue", Vector3(s * inner, WALK_M - 8.0, zc), Vector3(s * (inner - 6.0), WALK_M - hh, zc), 0.6, 1.2)

## Side span: deck and girders, the stiffened chain (top and bottom
## booms with lattice between) from the tower down towards the deck and
## up to the shore tower, and the hangers.
static func _side_span(lm: LandmarkMesh, s: float) -> void:
	var x0 := s * (TOWER_X + TOWER.x * 0.5)
	var x1 := s * (SHORE_X - 6.0)
	var cx := (x0 + x1) * 0.5
	var span := absf(x1 - x0)
	lm.box("Deck", Vector3(cx, DECK_M + 0.2, 0), Vector3(span, 0.4, ROAD_HALF * 2.0))
	for side in [-1.0, 1.0]:
		lm.box("Stone", Vector3(cx, DECK_M + 0.4, float(side) * (ROAD_HALF - 1.2)), Vector3(span, 0.4, 2.4))
	for gz in [-ROAD_HALF - 0.6, ROAD_HALF + 0.6]:
		lm.box("Blue", Vector3(cx, DECK_M - 1.2, float(gz)), Vector3(span, 2.8, 0.6))
	_parapet(lm, minf(x0, x1), maxf(x0, x1))
	var n := 16
	for cz in [-ROAD_HALF - 0.6, ROAD_HALF + 0.6]:
		var z: float = cz
		var top := PackedVector3Array()
		var bot := PackedVector3Array()
		for k in n + 1:
			var t := float(k) / n
			var y := lerpf(36.0, 24.0, t) - 16.0 * 4.0 * t * (1.0 - t)
			top.append(Vector3(lerpf(x0, x1, t), y, z))
			bot.append(Vector3(lerpf(x0, x1, t), y - 2.2, z))
		LandmarkCoreBBridgeKit.truss(lm, "Blue", bot, top, 0.9, 0.35, Vector3(0, 0, 1), true, true)
		for k in n:
			lm.beam("White", top[k] + Vector3(0, 0.55, 0), top[k + 1] + Vector3(0, 0.55, 0), 1.0, 0.2,
				Vector3(0, 0, 1))
		for k in range(1, n):
			if bot[k].y - DECK_M > 2.5:
				lm.beam("Blue", Vector3(bot[k].x, DECK_M + 0.2, z), bot[k], 0.35, 0.35)
				lm.box("White", bot[k] - Vector3(0, 0.3, 0), Vector3(0.7, 0.4, 0.7), Basis(), 0.0)

## A main tower on its river pier.
static func _tower(lm: LandmarkMesh, c: Vector3) -> void:
	var hx := TOWER.x * 0.5
	var hz := TOWER.z * 0.5
	# Boat-shaped granite pier, pointed up and down stream (±Z).
	var pier := PackedVector2Array([Vector2(c.x - 13.0, -20.0), Vector2(c.x - 8.0, -28.0),
		Vector2(c.x, -32.0), Vector2(c.x + 8.0, -28.0), Vector2(c.x + 13.0, -20.0),
		Vector2(c.x + 13.0, 20.0), Vector2(c.x + 8.0, 28.0), Vector2(c.x, 32.0),
		Vector2(c.x - 8.0, 28.0), Vector2(c.x - 13.0, 20.0)])
	lm.poly_prism("Granite", pier, 0.0, PIER_M)
	lm.box("Granite", c + Vector3(0, PIER_M + 0.3, 0), Vector3(TOWER.x + 4.0, 0.6, TOWER.z + 4.0))
	# Granite base storey, the carriageway passing through a pointed arch.
	for side in [-1.0, 1.0]:
		var wz: float = side * (ROAD_HALF + (hz - ROAD_HALF) * 0.5)
		lm.box("Granite", c + Vector3(0, (PIER_M + 18.0) * 0.5, wz), Vector3(TOWER.x, 18.0 - PIER_M, hz - ROAD_HALF))
	var crown := LandmarkCoreBBridgeKit.pointed_arch(lm, "Granite", c.x, TOWER.x, 0.0, ROAD_HALF * 2.0, 9.0, 18.0)
	for side in [-1.0, 1.0]:
		var wz: float = side * (ROAD_HALF + (hz - ROAD_HALF) * 0.5)
		lm.box("Granite", c + Vector3(0, (18.0 + crown) * 0.5, wz), Vector3(TOWER.x, crown - 18.0, hz - ROAD_HALF))
	for f in [-1.0, 1.0]:
		LandmarkDetail.arch(lm, "Stone", c + Vector3(float(f) * hx, 18.0, 0), Vector3(f, 0, 0), ROAD_HALF * 2.0, 0.9, 0.5)
	# Stone shaft to the eaves, string courses.
	lm.box("Stone", c + Vector3(0, (crown + EAVES_M) * 0.5, 0), Vector3(TOWER.x, EAVES_M - crown, TOWER.z))
	for y in [crown + 0.3, WALK_M - 3.5, WALK_M + 3.0]:
		lm.box("Stone", c + Vector3(0, float(y), 0), Vector3(TOWER.x + 0.6, 0.6, TOWER.z + 0.6))
	# Lancet windows in tiers: the river faces (±Z) and the span faces.
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var half := (hz if side % 2 == 0 else hx)
		var width := (TOWER.x if side % 2 == 0 else TOWER.z) - 6.0
		var n := Vector3(r * Vector3(0, 0, 1))
		var tiers := [23.0, 31.0, 39.0, 46.5] if side % 2 == 0 else [31.5, 47.0]
		for ty in tiers:
			for k in 3:
				var x := -width * 0.5 + width * float(k) / 2.0
				LandmarkDetail.window(lm, "Stone", "Windows", c + r * Vector3(x, float(ty), half), n, 1.2, 3.6, true, 0.2)
	# Machicolated cornice and parapet at the eaves.
	for f in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(float(f) * hx, EAVES_M, -hz), c + Vector3(float(f) * hx, EAVES_M, hz),
			Vector3(f, 0, 0), 1.0, false)
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(-hx, EAVES_M, float(f) * hz), c + Vector3(hx, EAVES_M, float(f) * hz),
			Vector3(0, 0, f), 1.0, false)
	# Steep slate pyramid roof with lucarnes, flèche and gilded finial.
	var roof_h := 10.5
	lm.lathe("Slate", c + Vector3(0, EAVES_M + 1.0, 0), PackedVector2Array([Vector2(sqrt(2.0), 0),
		Vector2(sqrt(2.0) * 0.18, roof_h)]), 4, hx, hz, PI * 0.25, false)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var half := (hz if side % 2 == 0 else hx) * 0.55
		var dc := c + Vector3(0, EAVES_M + 2.6, 0) + r * Vector3(0, 0, half + 0.6)
		lm.box("Stone", dc + Vector3(0, 1.4, 0), Vector3(2.4, 2.8, 2.0), r)
		lm.box("Windows", dc + Vector3(0, 1.3, 0) + r * Vector3(0, 0, 1.02), Vector3(1.2, 1.8, 0.1), r, 0.0)
		lm.gable("Slate", dc + Vector3(0, 2.8, 0), 2.6, 2.2, 1.8, r, 0.15, "Stone")
		lm.frustum("Gilt", dc + Vector3(0, 4.6, 0) + r * Vector3(0, 0, 1.0), 0.08, 0.02, 1.0, 4)
	var fl := c + Vector3(0, EAVES_M + 1.0 + roof_h, 0)
	lm.frustum("Stone", fl, 1.3, 1.2, 1.2, 8)
	lm.lathe("Slate", fl + Vector3(0, 1.2, 0), PackedVector2Array([Vector2(1.4, 0), Vector2(0.4, 1.2)]), 8)
	lm.frustum("Gilt", fl + Vector3(0, 2.4, 0), 0.35, 0.05, TOP_M - fl.y - 2.4, 8)
	for k in 2:
		lm.lathe("Gilt", fl + Vector3(0, 2.8 + 0.7 * k, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.45, 0.2),
			Vector2(0.2, 0.4)]), 8)
	# Octagonal corner turrets: shaft, belfry stage, spirelet, finial.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_turret(lm, c + Vector3(float(sx) * hx, 0, float(sz) * hz), 2.4, PIER_M + 0.6, EAVES_M + 3.0, 7.0)

## Octagonal turret of radius r from y0 to `top` (where the open stage
## sits), then a slate spirelet `spire` high and a gilded finial.
static func _turret(lm: LandmarkMesh, tc: Vector3, r: float, y0: float, top: float, spire: float) -> void:
	lm.frustum("Stone", tc + Vector3(0, y0, 0), r * 1.1, r * 1.1, 2.0, 8, PI / 8.0)
	lm.frustum("Stone", tc + Vector3(0, y0, 0), r, r, top - y0, 8, PI / 8.0)
	for y in [18.0, 32.0, EAVES_M - 0.5]:
		lm.frustum("Stone", tc + Vector3(0, float(y), 0), r * 1.08, r * 1.08, 0.5, 8, PI / 8.0)
	# Open belfry stage: eight colonnettes round a core under a cap.
	var b := tc + Vector3(0, top, 0)
	lm.frustum("Stone", b, r * 0.55, r * 0.55, 2.8, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.frustum("Stone", b + Vector3(cos(a), 0, sin(a)) * r * 0.92, 0.18, 0.18, 2.8, 6)
	lm.frustum("Stone", b + Vector3(0, 2.8, 0), r * 1.08, r * 1.08, 0.6, 8, PI / 8.0)
	lm.lathe("Slate", b + Vector3(0, 3.4, 0), PackedVector2Array([Vector2(r * 1.05, 0), Vector2(r * 0.6, spire * 0.4),
		Vector2(0.0, spire)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Gilt", b + Vector3(0, 3.4 + spire - 0.3, 0), 0.18, 0.03, 1.8, 6)

## A shore abutment tower: granite base with the carriage arch, stone
## upper stage, corner turrets with slate caps, where the chains land.
static func _shore_tower(lm: LandmarkMesh, c: Vector3) -> void:
	var hx := 6.0
	var hz := 9.5
	lm.box("Granite", c + Vector3(0, 0.8, 0), Vector3(14.0, 1.6, 21.0))
	for side in [-1.0, 1.0]:
		lm.box("Granite", c + Vector3(0, 7.0, float(side) * (ROAD_HALF + 1.25)), Vector3(12.0, 14.0, 2.5))
	var crown := LandmarkCoreBBridgeKit.pointed_arch(lm, "Granite", c.x, 12.0, 0.0, ROAD_HALF * 2.0, 8.5, 14.0)
	lm.box("Stone", c + Vector3(0, (crown + 24.0) * 0.5, 0), Vector3(12.0, 24.0 - crown, 19.0))
	for side in [-1.0, 1.0]:
		lm.box("Granite", c + Vector3(0, (14.0 + crown) * 0.5, float(side) * (ROAD_HALF + 1.25)),
			Vector3(12.0, crown - 14.0, 2.5))
	for f in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(float(f) * hx, 24.0, -hz), c + Vector3(float(f) * hx, 24.0, hz),
			Vector3(f, 0, 0), 0.8, false)
		for k in [-1.0, 1.0]:
			LandmarkDetail.window(lm, "Stone", "Windows", c + Vector3(float(f) * hx, 21.0, float(k) * 4.5),
				Vector3(f, 0, 0), 1.0, 2.6, true, 0.15)
	lm.gable("Slate", c + Vector3(0, 24.6, 0), 12.0, 17.0, 4.0, Basis(), 0.3, "Stone")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := c + Vector3(float(sx) * hx, 0, float(sz) * hz)
			lm.frustum("Stone", tc + Vector3(0, 1.6, 0), 1.8, 1.8, 24.4, 8, PI / 8.0)
			lm.frustum("Stone", tc + Vector3(0, 25.6, 0), 2.0, 2.0, 0.6, 8, PI / 8.0)
			lm.lathe("Slate", tc + Vector3(0, 26.2, 0), PackedVector2Array([Vector2(2.0, 0), Vector2(0.0, 5.0)]),
				8, 1.0, 1.0, PI / 8.0, false)
			lm.frustum("Gilt", tc + Vector3(0, 31.0, 0), 0.12, 0.02, 1.2, 6)
