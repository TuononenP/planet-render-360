class_name LandmarkTowerBridge
extends RefCounted

## Tower Bridge (1894, Horace Jones and John Wolfe Barry) in true metres,
## along +X with y = 0 at the Thames (LocationData `base: water`), the
## river flowing along Z. Key dimensions used: towers 65 m (213 ft) on
## piers 21.4 m wide (the Act's 70 ft) and 56 m long (185 ft) with
## cutwaters up and down stream, 61 m (200 ft) between the towers for the
## two 1,070-ton bascule leaves (closed, road 8.6 m above high water,
## 15 m between the parapets across the opening), two 82 m (270 ft)
## suspension side spans, 256 m overall with the shore towers, the high-
## level walkways 43 m above the river (Wikipedia: 143 ft), 61 m long and
## 3 m wide, each originally two cantilevers carrying a central girder.
## Each main tower is a steel frame clad in Cornish granite (to the
## roadway arch, here 22 m) and Portland stone above: a pointed carriage
## arch, three tiers of lancets on the river faces, string courses, the
## walkway portals at 43 m, a machicolated eaves cornice and parapet,
## stone gables, a steep slate pyramid roof with a lantern and gilded
## finial, and four octagonal corner turrets with slate spires. The
## suspension chains are stiffened (lattice) trusses at the footway
## edges, swinging from the main towers at 41 m, sagging to 17 m and
## rising into the granite-and-stone shore towers; the bridge is painted
## blue and white. Orientation: the model's +X is the bridge axis
## (registry yaw 95, span 256 m), the cutwaters point up and down the
## river (+-Z).
## https://en.wikipedia.org/wiki/Tower_Bridge

const TOP_M := 65.0
const TOWER := Vector3(18.0, 0.0, 26.0)
const TOWER_X := 39.5
const DECK_M := 8.6
const WALK_M := 45.0
const WALK_Z := 8.3
const SHORE_X := 122.0
const PIER_M := 4.0
const EAVES_M := 52.0
const ROAD_HALF := 7.5
const ARCH_SPRING := 13.0
const ARCH_RADIUS := 9.2
const CHAIN_Z := ROAD_HALF + 0.6
const CHAIN_TOP := 41.0
const CHAIN_END := 23.0
const CHAIN_SAG := 14.0
const SHORE_EAVES := 26.0
const SHORE_HX := 6.0
const SHORE_HZ := 10.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2CAB6", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8A84", 3.0))
	lm.use("Blue", LandmarkMaterials.paint("#3F78AE", 0.55, 0.3))
	lm.use("White", LandmarkMaterials.paint("#E9EEF1", 0.55, 0.2))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4A5157", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3338"))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFD9A0", 1.0))
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(float(s) * TOWER_X, 0, 0), float(s))
		_shore_tower(lm, Vector3(float(s) * SHORE_X, 0, 0), float(s))
	var inner := TOWER_X - TOWER.x * 0.5
	_bascules(lm, inner)
	_walkways(lm, inner)
	for s in [-1.0, 1.0]:
		_side_span(lm, float(s))
	lm.commit(model)

## Closed bascule leaves: deck and footways, the four blue girders
## (the outer two as haunched lattice trusses, deepest at the pivot),
## cross girders, the leaf joint, cast-iron parapets and lamp standards.
static func _bascules(lm: LandmarkMesh, inner: float) -> void:
	for s in [-1.0, 1.0]:
		var sg: float = s
		var cx: float = sg * inner * 0.5
		lm.box("Deck", Vector3(cx, DECK_M + 0.2, 0), Vector3(inner - 0.2, 0.4, ROAD_HALF * 2.0))
		for side in [-1.0, 1.0]:
			lm.box("Stone", Vector3(cx, DECK_M + 0.4, float(side) * (ROAD_HALF - 1.2)), Vector3(inner - 0.2, 0.4, 2.4))
		for gz in [-ROAD_HALF, ROAD_HALF]:
			var bot := PackedVector3Array()
			var top := PackedVector3Array()
			for k in 9:
				var t := float(k) / 8.0
				var depth := lerpf(3.6, 1.1, pow(t, 0.8))
				var x := sg * lerpf(inner, 0.2, t)
				top.append(Vector3(x, DECK_M, float(gz)))
				bot.append(Vector3(x, DECK_M - depth, float(gz)))
			LandmarkCoreBBridgeKit.truss(lm, "Blue", bot, top, 0.45, 0.24, Vector3(0, 0, 1), true, true)
		for gz in [-2.6, 2.6]:
			lm.box("Blue", Vector3(cx, DECK_M - 1.1, float(gz)), Vector3(inner - 0.3, 2.0, 0.5))
		for k in 8:
			var x: float = sg * (1.0 + (inner - 2.0) * float(k) / 7.0)
			lm.beam("Blue", Vector3(x, DECK_M - 0.9, -ROAD_HALF), Vector3(x, DECK_M - 0.9, ROAD_HALF), 0.4, 1.6)
	# Leaf joint: a dark seam with the toe plates either side.
	lm.box("Slate", Vector3(0, DECK_M + 0.42, 0), Vector3(0.35, 0.08, ROAD_HALF * 2.0), Basis(), 0.0)
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

## High-level walkways: two glazed passages 43 m over the river from
## tower to tower, a haunched lattice cantilever off each tower face
## carrying a lighter central girder, blue frames, white posts and a
## white pitched glazed roof; pointed portals where they enter the towers.
static func _walkways(lm: LandmarkMesh, inner: float) -> void:
	var hh := 1.7
	var floor_y := WALK_M - hh
	var roof_y := WALK_M + hh + 0.2
	var cant := 12.2
	for wz in [-WALK_Z, WALK_Z]:
		var zc: float = wz
		lm.box("Blue", Vector3(0, floor_y - 0.25, zc), Vector3(inner * 2.0, 0.5, 4.0))
		lm.box("Windows", Vector3(0, WALK_M, zc), Vector3(inner * 2.0, hh * 2.0, 3.2))
		lm.box("White", Vector3(0, roof_y, zc), Vector3(inner * 2.0, 0.4, 4.2))
		lm.box("White", Vector3(0, roof_y + 0.35, zc), Vector3(inner * 2.0, 0.3, 1.2))
		for f in [-1.0, 1.0]:
			var z: float = zc + float(f) * 1.9
			# Central girder and the two cantilevers, panels of about 3 m.
			for seg in 3:
				var xa: float = -inner + (0.0 if seg == 0 else (cant if seg == 1 else inner * 2.0 - cant))
				var xb: float = -inner + (cant if seg == 0 else (inner * 2.0 - cant if seg == 1 else inner * 2.0))
				var bot := PackedVector3Array()
				var top := PackedVector3Array()
				var np := maxi(int(absf(xb - xa) / 3.0), 3)
				for k in np + 1:
					var t := float(k) / float(np)
					var x := lerpf(xa, xb, t)
					var depth := 0.9
					if seg != 1:
						# Haunch: deep at the tower, shallow at the free end.
						var u := (1.0 - t) if seg == 0 else t
						depth = 0.9 + 4.6 * pow(u, 1.5)
					top.append(Vector3(x, roof_y - 0.2, z))
					bot.append(Vector3(x, floor_y - depth, z))
				LandmarkCoreBBridgeKit.truss(lm, "Blue", bot, top, 0.4, 0.2, Vector3(0, 0, 1), true, true)
			# Glazing mullions in white, one per panel.
			var nm := int(inner * 2.0 / 3.0)
			for k in nm + 1:
				var x := -inner + inner * 2.0 * float(k) / float(nm)
				lm.box("White", Vector3(x, WALK_M, z), Vector3(0.25, hh * 2.0, 0.3), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			var sg: float = s
			LandmarkWestKit.lancet(lm, "Stone", "Windows", Vector3(sg * inner, floor_y - 0.3, zc),
				Vector3(-sg, 0, 0), 3.6, 6.4, false, 0.5)

## Side span: deck and girders, the stiffened chain (top and bottom
## booms with lattice between) from the tower at 41 m sagging to 17 m
## and up to the shore tower, and the hangers.
static func _side_span(lm: LandmarkMesh, s: float) -> void:
	var x0 := s * (TOWER_X + TOWER.x * 0.5)
	var x1 := s * (SHORE_X - SHORE_HX)
	var cx := (x0 + x1) * 0.5
	var span := absf(x1 - x0)
	lm.box("Deck", Vector3(cx, DECK_M + 0.2, 0), Vector3(span, 0.4, ROAD_HALF * 2.0))
	for side in [-1.0, 1.0]:
		lm.box("Stone", Vector3(cx, DECK_M + 0.4, float(side) * (ROAD_HALF - 1.2)), Vector3(span, 0.4, 2.4))
	for gz in [-ROAD_HALF - 0.6, ROAD_HALF + 0.6]:
		lm.box("Blue", Vector3(cx, DECK_M - 1.2, float(gz)), Vector3(span, 2.8, 0.6))
	for gz in [-2.6, 2.6]:
		lm.box("Blue", Vector3(cx, DECK_M - 0.9, float(gz)), Vector3(span, 1.6, 0.4))
	_parapet(lm, minf(x0, x1), maxf(x0, x1))
	var n := 18
	for cz in [-CHAIN_Z, CHAIN_Z]:
		var z: float = cz
		var top := PackedVector3Array()
		var bot := PackedVector3Array()
		for k in n + 1:
			var t := float(k) / n
			var y := lerpf(CHAIN_TOP, CHAIN_END, t) - CHAIN_SAG * 4.0 * t * (1.0 - t)
			top.append(Vector3(lerpf(x0, x1, t), y, z))
			bot.append(Vector3(lerpf(x0, x1, t), y - 2.4, z))
		LandmarkCoreBBridgeKit.truss(lm, "Blue", bot, top, 0.9, 0.35, Vector3(0, 0, 1), true, true)
		for k in n:
			lm.beam("White", top[k] + Vector3(0, 0.55, 0), top[k + 1] + Vector3(0, 0.55, 0), 1.0, 0.2,
				Vector3(0, 0, 1))
		for k in range(1, n):
			if bot[k].y - DECK_M > 2.5:
				lm.beam("Blue", Vector3(bot[k].x, DECK_M + 0.2, z), bot[k], 0.35, 0.35)
				lm.box("White", bot[k] - Vector3(0, 0.3, 0), Vector3(0.7, 0.4, 0.7), Basis(), 0.0)
		# Anchor casings where the chain enters each tower.
		for p in [top[0], top[n]]:
			var q: Vector3 = p
			lm.box("Blue", q - Vector3(0, 1.2, 0), Vector3(1.4, 4.4, 1.6))

## A main tower on its river pier; `s` is the side of the bridge axis
## (its span-facing face looks along -s).
static func _tower(lm: LandmarkMesh, c: Vector3, s: float) -> void:
	var hx := TOWER.x * 0.5
	var hz := TOWER.z * 0.5
	# Boat-shaped granite pier, pointed up and down stream (+-Z).
	var px := 10.7
	var pier := PackedVector2Array([Vector2(c.x - px, -20.0), Vector2(c.x - px * 0.62, -25.5),
		Vector2(c.x, -28.0), Vector2(c.x + px * 0.62, -25.5), Vector2(c.x + px, -20.0),
		Vector2(c.x + px, 20.0), Vector2(c.x + px * 0.62, 25.5), Vector2(c.x, 28.0),
		Vector2(c.x - px * 0.62, 25.5), Vector2(c.x - px, 20.0)])
	lm.poly_prism("Granite", pier, 0.0, PIER_M)
	lm.box("Granite", c + Vector3(0, PIER_M + 0.3, 0), Vector3(TOWER.x + 2.4, 0.6, TOWER.z + 2.4))
	# Granite storeys either side of the carriageway, the road through a
	# pointed arch; the passage floor under the road is solid.
	lm.box("Granite", c + Vector3(0, (PIER_M + DECK_M) * 0.5 + 0.3, 0), Vector3(TOWER.x, DECK_M - PIER_M - 0.3, ROAD_HALF * 2.0))
	lm.box("Deck", c + Vector3(0, DECK_M + 0.2, 0), Vector3(TOWER.x, 0.4, ROAD_HALF * 2.0))
	var crown := LandmarkCoreBBridgeKit.pointed_arch(lm, "Granite", c.x, TOWER.x, 0.0, ROAD_HALF * 2.0,
		ARCH_RADIUS, ARCH_SPRING)
	for side in [-1.0, 1.0]:
		var wz: float = float(side) * (ROAD_HALF + (hz - ROAD_HALF) * 0.5)
		lm.box("Granite", c + Vector3(0, (PIER_M + crown) * 0.5 + 0.3, wz), Vector3(TOWER.x, crown - PIER_M - 0.3, hz - ROAD_HALF))
	# Bascule chamber: the dark mouth of the leaf pit at the span face,
	# between granite cheeks, the blue leaf girders running into it.
	var inner_n := Vector3(-s, 0, 0)
	lm.box("Windows", c + inner_n * (hx + 0.03) + Vector3(0, 6.4, 0), Vector3(0.1, 2.4, ROAD_HALF * 2.0 - 1.2), Basis(), 0.0)
	for k in 4:
		lm.beam("Blue", c + inner_n * (hx + 0.1) + Vector3(0, 5.3, -5.4 + 3.6 * float(k)),
			c + inner_n * (hx + 0.1) + Vector3(0, 7.5, -5.4 + 3.6 * float(k)), 0.3, 0.3)
	for side in [-1.0, 1.0]:
		lm.box("Granite", c + inner_n * (hx + 0.6) + Vector3(0, PIER_M + 3.0, float(side) * (ROAD_HALF + 0.6)),
			Vector3(1.4, 2.0 * 3.0 - 0.0, 1.2))
	# Portland stone shaft above the granite, string courses between.
	lm.box("Stone", c + Vector3(0, (crown + EAVES_M) * 0.5, 0), Vector3(TOWER.x, EAVES_M - crown, TOWER.z))
	for y in [crown + 0.3, 33.5]:
		lm.box("Granite", c + Vector3(0, float(y), 0), Vector3(TOWER.x + 0.8, 0.8, TOWER.z + 0.8))
	for y in [27.5, 38.5, WALK_M - 3.6]:
		lm.box("Stone", c + Vector3(0, float(y), 0), Vector3(TOWER.x + 0.5, 0.5, TOWER.z + 0.5))
	_tower_faces(lm, c, s, crown)
	_tower_roof(lm, c)
	# Octagonal corner turrets.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_turret(lm, c + Vector3(float(sx) * hx, 0, float(sz) * hz), 2.5, PIER_M + 0.6, EAVES_M + 2.5)

## Lancet tiers, blind panels and walkway portals on the four faces.
static func _tower_faces(lm: LandmarkMesh, c: Vector3, s: float, crown: float) -> void:
	var hx := TOWER.x * 0.5
	var hz := TOWER.z * 0.5
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var river := side % 2 == 0
		var half: float = hz if river else hx
		var width: float = TOWER.x if river else TOWER.z
		var n: Vector3 = r * Vector3(0, 0, 1)
		# Pilaster strips dividing the faces into bays.
		var bays := 3 if river else 5
		for k in bays + 1:
			var x := -width * 0.5 + 0.7 + (width - 1.4) * float(k) / float(bays)
			lm.box("Stone", c + r * Vector3(x, (crown + EAVES_M) * 0.5, half + 0.15), Vector3(0.7, EAVES_M - crown, 0.4), r)
		if river:
			for ty in [[crown + 1.6, 5.4, 1.5], [crown + 8.4, 5.2, 1.5], [36.0, 5.0, 1.4], [47.0, 4.4, 1.2]]:
				for x in [-5.5, 0.0, 5.5]:
					LandmarkWestKit.lancet(lm, "Stone", "Windows", c + r * Vector3(float(x), float(ty[0]), half), n,
						float(ty[2]), float(ty[1]), float(ty[1]) > 5.0, 0.25)
		else:
			# Above the carriage arch: tiers of three, then the walkway
			# level (inner face only) and the belfry stage.
			for ty in [[crown + 1.4, 5.0, 1.4], [34.5, 4.4, 1.4]]:
				for x in [-6.0, 0.0, 6.0]:
					LandmarkWestKit.lancet(lm, "Stone", "Windows", c + r * Vector3(float(x), float(ty[0]), half), n,
						float(ty[2]), float(ty[1]), false, 0.25)
			LandmarkWestKit.lancet(lm, "Stone", "Windows", c + r * Vector3(0.0, WALK_M - 1.5, half), n, 2.2, 5.5, true, 0.25)
	# Blue steel frame casings: where the chains meet the outer face.
	for z in [-CHAIN_Z, CHAIN_Z]:
		lm.box("Blue", c + Vector3(s * (hx + 0.4), CHAIN_TOP - 1.2, float(z)), Vector3(0.9, 4.4, 1.8))
	# Cornice, then the crenellated parapet at the eaves.
	for f in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(float(f) * hx, EAVES_M, -hz), c + Vector3(float(f) * hx, EAVES_M, hz),
			Vector3(f, 0, 0), 1.0, false)
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(-hx, EAVES_M, float(f) * hz), c + Vector3(hx, EAVES_M, float(f) * hz),
			Vector3(0, 0, f), 1.0, false)
		LandmarkWestKit.merlons(lm, "Stone", c + Vector3(float(f) * (hx + 0.3), EAVES_M + 1.0, -hz),
			c + Vector3(float(f) * (hx + 0.3), EAVES_M + 1.0, hz), 1.8, 1.0, 0.9, 0.5)
		LandmarkWestKit.merlons(lm, "Stone", c + Vector3(-hx, EAVES_M + 1.0, float(f) * (hz + 0.3)),
			c + Vector3(hx, EAVES_M + 1.0, float(f) * (hz + 0.3)), 1.8, 1.0, 0.9, 0.5)

## Steep slate pyramid with a stone gable and lancet on every face, a
## lantern and the gilded finial that closes the 65 m height.
static func _tower_roof(lm: LandmarkMesh, c: Vector3) -> void:
	var hx := TOWER.x * 0.5
	var hz := TOWER.z * 0.5
	var base_y := EAVES_M + 1.0
	var roof_h := 9.0
	lm.lathe("Slate", c + Vector3(0, base_y, 0), PackedVector2Array([Vector2(sqrt(2.0), 0),
		Vector2(sqrt(2.0) * 0.16, roof_h)]), 4, hx, hz, PI * 0.25, false)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var river := side % 2 == 0
		var half: float = hz if river else hx
		var offs: Array = [0.0] if river else [-6.0, 6.0]
		for o in offs:
			var dc := c + r * Vector3(float(o), 0, 0) + Vector3(0, base_y, 0) + r * Vector3(0, 0, half - 1.9)
			lm.gable("Slate", dc, 6.2, 4.4, 4.0, r, 0.2, "Stone")
			LandmarkWestKit.lancet(lm, "Stone", "Windows", c + r * Vector3(float(o), base_y + 0.1, half + 0.3),
				r * Vector3(0, 0, 1), 1.3, 3.0, false, 0.2)
			lm.frustum("Gilt", dc + Vector3(0, 4.0, 0) + r * Vector3(0, 0, 2.0), 0.08, 0.02, 1.0, 4)
	var fl := c + Vector3(0, base_y + roof_h, 0)
	lm.frustum("Stone", fl, 1.3, 1.1, 1.0, 8)
	lm.lathe("Slate", fl + Vector3(0, 1.0, 0), PackedVector2Array([Vector2(1.3, 0), Vector2(0.4, 1.0)]), 8)
	lm.frustum("Gilt", fl + Vector3(0, 1.6, 0), 0.32, 0.05, TOP_M - fl.y - 1.6, 8)
	for k in 2:
		lm.lathe("Gilt", fl + Vector3(0, 2.0 + 0.55 * float(k), 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.45, 0.2),
			Vector2(0.2, 0.4)]), 8)

## Octagonal turret of radius r from y0 to `top` (where the open belfry
## stage sits), then a slate spirelet and a gilded finial.
static func _turret(lm: LandmarkMesh, tc: Vector3, r: float, y0: float, top: float) -> void:
	lm.frustum("Stone", tc + Vector3(0, y0, 0), r * 1.15, r * 1.15, 2.0, 8, PI / 8.0)
	lm.frustum("Stone", tc + Vector3(0, y0, 0), r, r, top - y0, 8, PI / 8.0)
	for y in [18.0, 33.0, 43.0, EAVES_M - 0.5]:
		lm.frustum("Stone", tc + Vector3(0, float(y), 0), r * 1.1, r * 1.1, 0.5, 8, PI / 8.0)
	# Arrow slits up the shaft.
	for y in [26.0, 30.0, 38.0, 47.0]:
		for k in 4:
			var a := PI * 0.25 + PI * 0.5 * float(k)
			lm.box("Windows", tc + Vector3(cos(a), 0, sin(a)) * r * 0.93 + Vector3(0, float(y), 0), Vector3(0.3, 1.6, 0.3),
				Basis(Vector3.UP, -a), 0.0)
	# Open belfry stage: eight colonnettes round a core under a cap.
	var b := tc + Vector3(0, top, 0)
	lm.frustum("Stone", b, r * 0.55, r * 0.55, 2.5, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.frustum("Stone", b + Vector3(cos(a), 0, sin(a)) * r * 0.9, 0.18, 0.18, 2.5, 6)
	lm.frustum("Stone", b + Vector3(0, 2.5, 0), r * 1.1, r * 1.1, 0.6, 8, PI / 8.0)
	lm.lathe("Slate", b + Vector3(0, 3.1, 0), PackedVector2Array([Vector2(r * 1.05, 0), Vector2(r * 0.6, 1.8),
		Vector2(0.0, 5.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Gilt", b + Vector3(0, 7.8, 0), 0.18, 0.03, 1.6, 6)

## A shore abutment tower: granite base with the carriage arch, stone
## upper stage with lancets and a crenellated cornice, a slate gable
## roof, corner turrets with slate caps, where the chains land.
static func _shore_tower(lm: LandmarkMesh, c: Vector3, s: float) -> void:
	var hx := SHORE_HX
	var hz := SHORE_HZ
	lm.box("Granite", c + Vector3(0, 0.8, 0), Vector3(hx * 2.0 + 2.0, 1.6, hz * 2.0 + 2.0))
	lm.box("Granite", c + Vector3(0, (1.6 + DECK_M) * 0.5, 0), Vector3(hx * 2.0, DECK_M - 1.6, ROAD_HALF * 2.0))
	lm.box("Deck", c + Vector3(0, DECK_M + 0.2, 0), Vector3(hx * 2.0, 0.4, ROAD_HALF * 2.0))
	var crown := LandmarkCoreBBridgeKit.pointed_arch(lm, "Granite", c.x, hx * 2.0, 0.0, ROAD_HALF * 2.0, 8.0, 10.0)
	for side in [-1.0, 1.0]:
		var wz: float = float(side) * (ROAD_HALF + (hz - ROAD_HALF) * 0.5)
		lm.box("Granite", c + Vector3(0, (1.6 + crown) * 0.5, wz), Vector3(hx * 2.0, crown - 1.6, hz - ROAD_HALF))
	lm.box("Stone", c + Vector3(0, (crown + SHORE_EAVES) * 0.5, 0), Vector3(hx * 2.0, SHORE_EAVES - crown, hz * 2.0))
	lm.box("Granite", c + Vector3(0, crown + 0.3, 0), Vector3(hx * 2.0 + 0.7, 0.7, hz * 2.0 + 0.7))
	# Windows: two tiers of lancets on the road faces, three on the river faces.
	for f in [-1.0, 1.0]:
		var fn := Vector3(float(f), 0, 0)
		for ty in [[crown + 1.4, 5.0, 1.4]]:
			for k in [-1.0, 1.0]:
				LandmarkWestKit.lancet(lm, "Stone", "Windows", c + fn * hx + Vector3(0, float(ty[0]), float(k) * 5.0), fn,
					float(ty[2]), float(ty[1]), false, 0.2)
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(float(f) * hx, SHORE_EAVES, -hz), c + Vector3(float(f) * hx, SHORE_EAVES, hz),
			fn, 0.9, false)
		LandmarkWestKit.merlons(lm, "Stone", c + Vector3(float(f) * (hx + 0.3), SHORE_EAVES + 0.9, -hz),
			c + Vector3(float(f) * (hx + 0.3), SHORE_EAVES + 0.9, hz), 1.8, 1.0, 0.8, 0.5)
		var zn := Vector3(0, 0, float(f))
		for ty in [[crown + 1.4, 5.0, 1.4]]:
			for k in [-1.0, 0.0, 1.0]:
				LandmarkWestKit.lancet(lm, "Stone", "Windows", c + zn * hz + Vector3(float(k) * 3.6, float(ty[0]), 0), zn,
					float(ty[2]), float(ty[1]), false, 0.2)
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(-hx, SHORE_EAVES, float(f) * hz), c + Vector3(hx, SHORE_EAVES, float(f) * hz),
			zn, 0.9, false)
	lm.gable("Slate", c + Vector3(0, SHORE_EAVES + 0.9, 0), hx * 2.0 - 1.0, hz * 2.0 - 1.0, 4.0, Basis(), 0.3, "Stone")
	# Chain anchor casings on the span face.
	for z in [-CHAIN_Z, CHAIN_Z]:
		lm.box("Blue", c + Vector3(-s * (hx + 0.4), CHAIN_END - 1.2, float(z)), Vector3(1.0, 4.4, 1.8))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := c + Vector3(float(sx) * hx, 0, float(sz) * hz)
			lm.frustum("Stone", tc + Vector3(0, 1.6, 0), 1.8, 1.8, SHORE_EAVES + 0.9, 8, PI / 8.0)
			lm.frustum("Stone", tc + Vector3(0, SHORE_EAVES + 2.5, 0), 2.0, 2.0, 0.6, 8, PI / 8.0)
			lm.lathe("Slate", tc + Vector3(0, SHORE_EAVES + 3.1, 0), PackedVector2Array([Vector2(2.0, 0), Vector2(0.0, 5.0)]),
				8, 1.0, 1.0, PI / 8.0, false)
			lm.frustum("Gilt", tc + Vector3(0, SHORE_EAVES + 7.9, 0), 0.12, 0.02, 1.2, 6)
