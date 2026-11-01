class_name LandmarkTowerBridge
extends RefCounted

## Tower Bridge in true metres, along +X with y = 0 at the Thames
## (LocationData `base: water`): the two Gothic towers on their river
## piers, stone-clad with corner turrets, steep slate roofs and gilded
## finials (65 m); the closed bascule leaves of the 61 m central span;
## the two high-level walkways at 42 m; and the blue-and-white
## suspension chains over the side spans to the shore abutment towers.

const TOP_M := 65.0
const TOWER := Vector3(18.0, 0.0, 22.0)
const TOWER_X := 39.5
const DECK_M := 8.6
const WALK_M := 42.0
const SHORE_X := 122.0

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
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(s * TOWER_X, 0, 0))
		_shore_tower(lm, Vector3(s * SHORE_X, 0, 0))
	# Bascule leaves (closed) between the towers, blue girders under them.
	var inner := TOWER_X - TOWER.x * 0.5
	lm.box("Deck", Vector3(0, DECK_M + 0.2, 0), Vector3(inner * 2.0, 0.4, 14.0))
	for z in [-7.4, 7.4]:
		lm.box("Blue", Vector3(0, DECK_M - 1.2, z), Vector3(inner * 2.0, 2.8, 0.6))
		lm.box("White", Vector3(0, DECK_M + 0.9, z), Vector3(inner * 2.0, 1.0, 0.3))
	# High-level walkways: lattice girders between the towers.
	for z in [-5.5, 5.5]:
		lm.box("Blue", Vector3(0, WALK_M, z), Vector3(inner * 2.0, 4.4, 3.0))
		lm.box("White", Vector3(0, WALK_M + 2.4, z), Vector3(inner * 2.0, 0.5, 3.4))
		lm.box("White", Vector3(0, WALK_M - 2.4, z), Vector3(inner * 2.0, 0.5, 3.4))
		for k in 10:
			var x := -inner + inner * 2.0 * (k + 0.5) / 10.0
			for f in [-1.0, 1.0]:
				lm.beam("White", Vector3(x - 2.5, WALK_M - 2.0, z + f * 1.55),
					Vector3(x + 2.5, WALK_M + 2.0, z + f * 1.55), 0.35, 0.2)
	# Side spans: deck, and the stiffened chains from each tower down
	# towards the deck and up to the shore tower, with hangers.
	for s in [-1.0, 1.0]:
		var x0: float = s * (TOWER_X + TOWER.x * 0.5)
		var x1: float = s * (SHORE_X - 6.0)
		lm.box("Deck", Vector3((x0 + x1) * 0.5, DECK_M + 0.2, 0), Vector3(absf(x1 - x0), 0.4, 14.0))
		for z in [-7.6, 7.6]:
			lm.box("Blue", Vector3((x0 + x1) * 0.5, DECK_M - 1.2, z), Vector3(absf(x1 - x0), 2.8, 0.6))
			var prev := Vector3(x0, 36.0, z)
			for k in range(1, 13):
				var t := float(k) / 12.0
				var p := Vector3(lerpf(x0, x1, t), lerpf(36.0, 22.0, t) - 16.0 * 4.0 * t * (1.0 - t), z)
				lm.beam("Blue", prev, p, 1.6, 0.8)
				lm.beam("White", prev + Vector3(0, 0.85, 0), p + Vector3(0, 0.85, 0), 1.65, 0.25)
				lm.beam("Blue", Vector3(p.x, DECK_M + 1.0, z), p, 0.3, 0.3)
				prev = p
	lm.commit(model)

## A main tower: granite river pier, stone shaft with arched windows,
## four corner turrets with spirelets, the steep slate roof and finial.
static func _tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Granite", c + Vector3(0, 2.0, 0), Vector3(TOWER.x + 8.0, 8.0, TOWER.z + 10.0))
	lm.lathe("Granite", c + Vector3(-(TOWER.x + 8.0) * 0.5, -2.0, 0), PackedVector2Array([
		Vector2(TOWER.z * 0.5 + 5.0, 0), Vector2(TOWER.z * 0.5 + 5.0, 8.0)]), 12, 0.6, 1.0)
	lm.lathe("Granite", c + Vector3((TOWER.x + 8.0) * 0.5, -2.0, 0), PackedVector2Array([
		Vector2(TOWER.z * 0.5 + 5.0, 0), Vector2(TOWER.z * 0.5 + 5.0, 8.0)]), 12, 0.6, 1.0)
	var shaft := 50.0
	lm.box("Stone", c + Vector3(0, (6.0 + shaft) * 0.5, 0), Vector3(TOWER.x, shaft - 6.0, TOWER.z))
	# Arch through the tower for the roadway.
	for f in [-1.0, 1.0]:
		var face := c + Vector3(f * (TOWER.x * 0.5 + 0.05), 0, 0)
		lm.box("Windows", face + Vector3(0, DECK_M + 3.5, 0), Vector3(0.2, 7.0, 10.0))
		lm.disc("Windows", face + Vector3(f * 0.01, DECK_M + 7.0, 0), Vector3(f, 0, 0), 5.0, 16)
	# Windows in tiers on all four faces.
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var half := (TOWER.z if side % 2 == 0 else TOWER.x) * 0.5 + 0.05
		var width := TOWER.x if side % 2 == 0 else TOWER.z
		for tier in 3:
			for k in 3:
				var x := -width * 0.3 + width * 0.3 * k
				lm.box("Windows", c + r * Vector3(x, 22.0 + 9.0 * tier, half), Vector3(1.6, 4.4, 0.2), r)
	lm.box("Stone", c + Vector3(0, shaft + 0.5, 0), Vector3(TOWER.x + 1.0, 1.0, TOWER.z + 1.0))
	# Corner turrets and spirelets.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := c + Vector3(sx * TOWER.x * 0.5, 0, sz * TOWER.z * 0.5)
			lm.lathe("Stone", tc + Vector3(0, 6.0, 0), PackedVector2Array([Vector2(2.2, 0),
				Vector2(2.2, shaft - 2.0)]), 10)
			lm.lathe("Slate", tc + Vector3(0, shaft + 4.0, 0), PackedVector2Array([Vector2(2.6, 0),
				Vector2(1.2, 3.5), Vector2(0.0, 8.0)]), 10)
			lm.lathe("Stone", tc + Vector3(0, shaft + 4.0, 0) - Vector3(0, 6.0, 0), PackedVector2Array([
				Vector2(2.4, 0), Vector2(2.4, 6.0)]), 10)
			lm.frustum("Gilt", tc + Vector3(0, shaft + 12.0, 0), 0.25, 0.05, 1.6, 6)
	# Steep central roof and finial.
	lm.lathe("Slate", c + Vector3(0, shaft + 1.0, 0), PackedVector2Array([Vector2(sqrt(2.0), 0),
		Vector2(sqrt(2.0) * 0.18, 10.5)]), 4, TOWER.x * 0.5, TOWER.z * 0.5, PI * 0.25, false)
	lm.frustum("Gilt", c + Vector3(0, shaft + 11.5, 0), 0.5, 0.05, TOP_M - shaft - 11.5, 6)

## A shore abutment tower: a small stone tower with turrets where the
## chains come to ground.
static func _shore_tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 12.0, 0), Vector3(12.0, 24.0, 18.0))
	lm.box("Stone", c + Vector3(0, 24.4, 0), Vector3(12.8, 0.8, 18.8))
	for sz in [-1.0, 1.0]:
		var tc := c + Vector3(0, 0, sz * 9.0)
		lm.lathe("Slate", tc + Vector3(0, 24.8, 0), PackedVector2Array([Vector2(2.4, 0),
			Vector2(0.0, 6.0)]), 10)
	for f in [-1.0, 1.0]:
		lm.box("Windows", c + Vector3(f * 6.05, DECK_M + 3.0, 0), Vector3(0.2, 6.0, 9.0))
