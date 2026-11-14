class_name LandmarkCentralPark
extends RefCounted

## Central Park's built landmarks (LandmarkRegistryCentralPark). Sizes from
## the OSM outlines in the 2026-11-14 Central Park snapshot and the parks
## department's published dimensions; +X is each one's long axis or deck.

const SANDSTONE := "#b9a58a"
const SCHIST := "#8a8479"
const GRANITE := "#a08a7c"
const BRONZE := "#4f5a46"
const CAST_IRON := "#e6dfcd"

static func _stone(lm: LandmarkMesh, key: String, hex: String) -> void:
	lm.use(key, LandmarkMaterials.pbr("stone", hex, 3.0))

## Bethesda Fountain (1873): the mapped pool's sandstone rim, the tiered
## centre with its two bowls and the bronze Angel of the Waters, 7.9 m.
static func bethesda_fountain(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_stone(lm, "Stone", SANDSTONE)
	lm.use("Bronze", LandmarkMaterials.paint(BRONZE, 0.5, 0.6))
	lm.use("Water", LandmarkMaterials.glass("#3d5866"))
	lm.lathe("Stone", Vector3.ZERO, PackedVector2Array([Vector2(13.7, -0.2), Vector2(13.7, 0.55),
		Vector2(14.6, 0.55), Vector2(14.6, -0.2)]), 48, 1.0, 1.0, 0.0, true, false)
	# Lower pedestal, the lower bowl, the column, the upper bowl, the plinth.
	lm.lathe("Stone", Vector3.ZERO, PackedVector2Array([Vector2(2.6, -0.2), Vector2(2.4, 1.1),
		Vector2(0.8, 1.3), Vector2(0.9, 1.5), Vector2(3.3, 1.9), Vector2(3.4, 2.15), Vector2(0.75, 2.2),
		Vector2(0.6, 3.4), Vector2(1.7, 3.8), Vector2(1.8, 4.0), Vector2(0.55, 4.05), Vector2(0.5, 4.6),
		Vector2(0.7, 4.7), Vector2(0.0, 4.75)]), 20)
	lm.disc("Water", Vector3(0, 2.1, 0), Vector3.UP, 3.2, 20)
	lm.disc("Water", Vector3(0, 3.95, 0), Vector3.UP, 1.6, 16)
	# The angel: robe, torso, head, raised arm and spread wings.
	lm.lathe("Bronze", Vector3(0, 4.75, 0), PackedVector2Array([Vector2(0.55, 0.0), Vector2(0.42, 0.9),
		Vector2(0.28, 1.6), Vector2(0.24, 2.0), Vector2(0.14, 2.1), Vector2(0.16, 2.35), Vector2(0.0, 2.5)]), 10)
	lm.beam("Bronze", Vector3(0.15, 6.6, 0), Vector3(0.55, 7.6, 0.1), 0.14, 0.14)
	for side in [-1.0, 1.0]:
		lm.quad("Bronze", Vector3(0, 6.5, side * 0.15), Vector3(-0.4, 6.4, side * 1.3),
			Vector3(-0.7, 7.9, side * 1.1), Vector3(-0.1, 7.0, side * 0.2), Vector3(0, 0, side))
	lm.commit(model)

## Bow Bridge (1862): a cream cast-iron arch across the Lake, 26.5 m
## between its schist abutments, a timber deck and the openwork railing
## with its planter urns. +X runs along the deck; the model's origin is at
## the deck's ends, the water DECK_M below (the registry row stands it on
## its west deck end, where the path meets it).
const DECK_M := 2.9

static func bow_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Iron", LandmarkMaterials.paint(CAST_IRON, 0.55, 0.3))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#8a7154", 2.0))
	_stone(lm, "Stone", SCHIST)
	var half := 13.25
	var deck_w := 4.4
	# Abutments with their wing walls up to the deck.
	for side in [-1.0, 1.0]:
		lm.box("Stone", Vector3(side * (half + 3.0), 1.1, 0), Vector3(6.0, 3.4, deck_w + 2.0))
	# Five arch ribs under the deck and the deck itself, cambered.
	var segs := 12
	for k in segs:
		var t0 := float(k) / float(segs)
		var t1 := float(k + 1) / float(segs)
		var x0 := lerpf(-half, half, t0)
		var x1 := lerpf(-half, half, t1)
		var y0 := 0.6 + 2.0 * sin(t0 * PI)
		var y1 := 0.6 + 2.0 * sin(t1 * PI)
		for z in [-1.9, -0.95, 0.0, 0.95, 1.9]:
			lm.beam("Iron", Vector3(x0, y0, z), Vector3(x1, y1, z), 0.22, 0.45)
		var d0 := 2.9 + 0.35 * sin(t0 * PI)
		var d1 := 2.9 + 0.35 * sin(t1 * PI)
		lm.quad("Deck", Vector3(x0, d0, -deck_w * 0.5), Vector3(x1, d1, -deck_w * 0.5),
			Vector3(x1, d1, deck_w * 0.5), Vector3(x0, d0, deck_w * 0.5), Vector3.UP)
		lm.quad("Iron", Vector3(x0, d0 - 0.25, deck_w * 0.5), Vector3(x1, d1 - 0.25, deck_w * 0.5),
			Vector3(x1, y1 + 0.2, deck_w * 0.5), Vector3(x0, y0 + 0.2, deck_w * 0.5), Vector3.BACK)
		lm.quad("Iron", Vector3(x0, d0 - 0.25, -deck_w * 0.5), Vector3(x1, d1 - 0.25, -deck_w * 0.5),
			Vector3(x1, y1 + 0.2, -deck_w * 0.5), Vector3(x0, y0 + 0.2, -deck_w * 0.5), Vector3.FORWARD)
		# Railing: rails and a baluster every segment.
		for z in [-deck_w * 0.5, deck_w * 0.5]:
			lm.beam("Iron", Vector3(x0, d0 + 1.05, z), Vector3(x1, d1 + 1.05, z), 0.1, 0.12)
			lm.beam("Iron", Vector3(x0, d0 + 0.25, z), Vector3(x1, d1 + 0.25, z), 0.08, 0.1)
			lm.beam("Iron", Vector3(x0, d0, z), Vector3(x0, d0 + 1.05, z), 0.07, 0.07)
	# The eight planter urns on the railing's end posts.
	for side in [-1.0, 1.0]:
		for z in [-deck_w * 0.5, deck_w * 0.5]:
			for x in [half - 0.3, half - 4.6]:
				var at := Vector3(side * x, 3.0, z)
				lm.box("Iron", at + Vector3(0, 0.55, 0), Vector3(0.35, 1.1, 0.35))
				lm.lathe("Iron", at + Vector3(0, 1.1, 0), PackedVector2Array([Vector2(0.12, 0.0),
					Vector2(0.32, 0.3), Vector2(0.38, 0.55), Vector2(0.3, 0.6)]), 10)
	var lowered := Node3D.new()
	lowered.name = "Deck"
	lowered.position.y = -DECK_M
	model.add_child(lowered)
	lm.commit(lowered)

## Gapstow Bridge (1896): a single schist arch over the Pond, 13 m span,
## with its rough stone parapets. +X along the path; y = 0 at the water.
static func gapstow_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_stone(lm, "Stone", SCHIST)
	lm.use("Path", LandmarkMaterials.pbr("pavement", "#9a948a", 2.0))
	var half := 6.5
	var width := 6.0
	var deck := 4.6
	var segs := 10
	for k in segs:
		var t0 := float(k) / float(segs)
		var t1 := float(k + 1) / float(segs)
		var x0 := lerpf(-half, half, t0)
		var x1 := lerpf(-half, half, t1)
		var y0 := 3.6 * sin(t0 * PI)
		var y1 := 3.6 * sin(t1 * PI)
		# Arch barrel, and the spandrel fill above it up to the path.
		lm.beam("Stone", Vector3(x0, y0, 0), Vector3(x1, y1, 0), width, 0.8, Vector3.BACK)
		var mid := (x0 + x1) * 0.5
		var top := (y0 + y1) * 0.5 + 0.3
		lm.box("Stone", Vector3(mid, (top + deck) * 0.5, 0), Vector3(x1 - x0 + 0.02, deck - top, width))
	for side in [-1.0, 1.0]:
		lm.box("Stone", Vector3(side * (half + 2.8), deck * 0.5 - 0.5, 0), Vector3(5.6, deck + 1.0, width + 1.0))
		lm.box("Stone", Vector3(0, deck + 0.55, side * (width * 0.5 - 0.3)), Vector3(half * 2.0 + 11.0, 1.1, 0.6))
	lm.box("Path", Vector3(0, deck + 0.02, 0), Vector3(half * 2.0 + 11.0, 0.04, width - 1.2))
	lm.commit(model)

## Belvedere Castle (1869) on Vista Rock: the schist hall along the
## outline's long axis, its square tower with the octagonal stair turret at
## the north-west (-X) end over Turtle Pond, crenellations and the open
## pavilion at the south-east end.
static func belvedere_castle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_stone(lm, "Stone", SCHIST)
	_stone(lm, "Trim", "#b7ad9c")
	lm.use("Roof", LandmarkMaterials.paint("#4a4e52", 0.7, 0.1))
	lm.use("Window", LandmarkMaterials.glass("#2a3238"))
	# Terrace wall on the rock, the hall and its crenellated parapet.
	lm.box("Stone", Vector3(0, 1.0, 0), Vector3(17.0, 2.6, 7.4))
	lm.box("Stone", Vector3(-1.0, 4.4, 0), Vector3(9.0, 4.2, 5.6))
	_crenels(lm, Vector3(-1.0, 6.5, 0), 9.0, 5.6)
	# The tower and turret.
	lm.box("Stone", Vector3(-6.0, 7.2, 0), Vector3(5.6, 12.4, 5.6))
	_crenels(lm, Vector3(-6.0, 13.4, 0), 5.6, 5.6)
	lm.frustum("Stone", Vector3(-8.6, 2.2, -2.6), 1.5, 1.5, 13.6, 8)
	lm.frustum("Roof", Vector3(-8.6, 15.8, -2.6), 1.8, 0.0, 3.4, 8)
	lm.box("Trim", Vector3(-6.0, 13.0, 0), Vector3(6.0, 0.4, 6.0))
	for x in [-7.2, -4.8]:
		lm.box("Window", Vector3(x, 10.0, 2.81), Vector3(0.8, 2.2, 0.05))
		lm.box("Window", Vector3(x, 10.0, -2.81), Vector3(0.8, 2.2, 0.05))
	# The flag mast on the tower.
	lm.beam("Trim", Vector3(-6.0, 13.8, 0), Vector3(-6.0, 18.5, 0), 0.12, 0.12)
	# The open pavilion: four piers under a pyramid roof.
	for px in [4.2, 7.4]:
		for pz in [-1.8, 1.8]:
			lm.box("Stone", Vector3(px, 3.7, pz), Vector3(0.6, 2.6, 0.6))
	lm.spire("Roof", Vector3(5.8, 5.0, 0), 2.4, 2.4)
	lm.commit(model)

## Merlons round a w x d rectangle centred on `at` (its parapet top).
static func _crenels(lm: LandmarkMesh, at: Vector3, w: float, d: float) -> void:
	for side in [-1.0, 1.0]:
		var n := int(w / 1.2)
		for k in n:
			var x := at.x - w * 0.5 + (float(k) + 0.5) * w / float(n)
			lm.box("Stone", Vector3(x, at.y + 0.35, at.z + side * (d * 0.5 - 0.25)), Vector3(0.6, 0.7, 0.5))
		var m := int(d / 1.2)
		for k in m:
			var z := at.z - d * 0.5 + (float(k) + 0.5) * d / float(m)
			lm.box("Stone", Vector3(at.x + side * (w * 0.5 - 0.25), at.y + 0.35, z), Vector3(0.5, 0.7, 0.6))

## Cleopatra's Needle (c. 1450 BC, raised 1881): the red granite obelisk,
## 21.2 m with its pyramidion, on its pedestal and steps, with the bronze
## crabs under its corners.
static func cleopatras_needle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_stone(lm, "Granite", GRANITE)
	_stone(lm, "Base", "#9c968c")
	lm.use("Bronze", LandmarkMaterials.paint("#6b5a3a", 0.45, 0.7))
	var y := 0.0
	for s in [[7.0, 0.5], [6.0, 0.5], [5.0, 0.5]]:
		lm.box("Base", Vector3(0, y + float(s[1]) * 0.5, 0), Vector3(float(s[0]), float(s[1]), float(s[0])))
		y += float(s[1])
	lm.box("Base", Vector3(0, y + 0.8, 0), Vector3(3.4, 1.6, 3.4))
	y += 1.6
	for x in [-1.1, 1.1]:
		for z in [-1.1, 1.1]:
			lm.box("Bronze", Vector3(x, y + 0.2, z), Vector3(0.6, 0.4, 0.6))
	y += 0.4
	lm.spire("Granite", Vector3(0, y, 0), 1.18, 19.5, 0.8)
	lm.spire("Granite", Vector3(0, y + 19.5, 0), 0.8, 1.7)
	lm.commit(model)
