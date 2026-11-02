class_name LandmarkMseThai
extends RefCounted

## Thai temples in true metres: Wat Chaiwatthanaram (35 m: the ruined
## Khmer-style prang of Ayutthaya on its terraces with four corner prangs
## and eight chapels in the cloister) and Wat Rong Khun, the White Temple
## of Chiang Rai (30 m: the white ubosot with its mirror-glass trim and
## bristling filigree spires, the bridge over the pond and the golden hall).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")

const PRANG_M := 35.0
const WHITE_TEMPLE_M := 30.0

# --- Wat Chaiwatthanaram ---

## Central prang (35 m) on two square terraces with stairs on the four
## faces, four corner prangs, the cloister wall ringed by eight chapels
## (corners and mid-sides) and, east of it, the ruined ordination hall
## between two twelve-cornered chedis.
static func chaiwatthanaram(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A9573A", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#8F5A3E", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#CBBCA4", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#241D18", 0.9, 0.0))
	lm.box("Laterite", Vector3(0, 0.75, 0), Vector3(58.0, 3.5, 58.0))
	lm.box("Laterite", Vector3(0, 3.0, 0), Vector3(42.0, 5.0, 42.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.stairs(lm, "Laterite", Vector3.ZERO + b * Vector3(0, 0, 21.0), b, 9.0, 8, 0.9, 5.5 / 8.0)
	U.prang(lm, "Plaster", "Dark", Vector3(0, 5.5, 0), 8.6, PRANG_M - 5.5, 4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.prang(lm, "Plaster", "Dark", Vector3(sx * 15.0, 5.5, sz * 15.0), 3.6, 15.0, 3)
	# Cloister wall (broken crest) with the eight chapels.
	var hw := 44.0
	for s in [-1.0, 1.0]:
		lm.box("Brick", Vector3(0, 2.0, s * hw), Vector3(hw * 2.0, 4.0, 2.4))
		lm.box("Brick", Vector3(s * hw, 2.0, 0), Vector3(2.4, 4.0, hw * 2.0 - 2.4))
	for c in [Vector3(-hw, 0, -hw), Vector3(hw, 0, -hw), Vector3(hw, 0, hw), Vector3(-hw, 0, hw),
			Vector3(0, 0, -hw), Vector3(hw, 0, 0), Vector3(0, 0, hw), Vector3(-hw, 0, 0)]:
		_chapel(lm, c, Basis(Vector3.UP, atan2(-c.x, -c.z) if c != Vector3.ZERO else 0.0))
	# Ruined ordination hall: two long wall stubs and the column bases,
	# between the two twelve-cornered chedis.
	var hc := Vector3(72.0, 0, 0)
	lm.box("Laterite", hc + Vector3(0, 0.4, 0), Vector3(14.0, 0.8, 30.0))
	for s in [-1.0, 1.0]:
		lm.box("Brick", hc + Vector3(s * 5.0, 2.4, 0), Vector3(1.6, 3.2, 26.0))
		for i in 8:
			lm.box("Plaster", hc + Vector3(s * 2.8, 2.2, -11.0 + 22.0 * float(i) / 7.0), Vector3(1.0, 2.8, 1.0))
		lm.lathe("Brick", hc + Vector3(0, 0, s * 25.0), PackedVector2Array([Vector2(3.8, 0), Vector2(3.5, 3.0),
			Vector2(3.0, 5.0), Vector2(2.2, 8.0), Vector2(1.2, 10.5), Vector2(0.0, 12.0)]), 12)
	lm.commit(model)

## A chapel (chedi rai) in the cloister: a stout brick block with niches
## and a corbelled stump of its roof; the front looks toward the prang.
static func _chapel(lm: LandmarkMesh, c: Vector3, b: Basis) -> void:
	lm.box("Brick", c + Vector3(0, 3.5, 0), Vector3(9.0, 7.0, 9.0), b)
	lm.box("Laterite", c + Vector3(0, 0.6, 0), Vector3(10.4, 1.2, 10.4), b)
	lm.box("Dark", c + b * Vector3(0, 3.2, 4.55), Vector3(2.6, 4.6, 0.2), b)
	lm.box("Plaster", c + Vector3(0, 7.15, 0), Vector3(9.8, 0.3, 9.8), b)
	lm.spire("Brick", c + Vector3(0, 7.3, 0), 4.3, 3.6, 1.6)

# --- Wat Rong Khun ---

## The White Temple (30 m): the ubosot's three-tier white roof lined with
## spikes and mirror-glass trim over walls of mirror panels, its porch,
## the stair and the bridge across the pond from the gate of heaven, and
## the golden hall beside the pond. The ubosot faces the bridge (south).
static func rong_khun(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F6F4EE", 3.0))
	lm.use("Mirror", LandmarkMaterials.paint("#DDE7EC", 0.1, 0.9))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.glass("#355F6B"))
	lm.use("Dark", LandmarkMaterials.paint("#2A2623", 0.9, 0.0))
	lm.box("White", Vector3(0, 0.8, 0), Vector3(28.0, 1.6, 42.0))
	lm.box("White", Vector3(0, 6.1, 0), Vector3(20.0, 9.0, 32.0))
	# Mirror-glass panels set into the walls.
	for s in [-1.0, 1.0]:
		for i in 8:
			lm.box("Mirror", Vector3(s * 10.05, 5.5, -14.0 + 4.0 * float(i)), Vector3(0.15, 6.0, 1.4))
	for i in 4:
		for s in [-1.0, 1.0]:
			lm.box("Mirror", Vector3(s * (3.0 + 4.0 * float(i)), 5.5, -16.05), Vector3(1.4, 6.0, 0.15))
	# Porch, door and the stair toward the bridge.
	lm.box("White", Vector3(0, 5.6, 18.5), Vector3(12.0, 8.0, 5.0))
	lm.box("Dark", Vector3(0, 4.6, 21.05), Vector3(4.0, 6.0, 0.2))
	U.swept_roof(lm, "White", "Mirror", "White", Vector3(0, 9.6, 18.5), Basis(), 12.0, 5.0, 3.4, 1.2, 1.0)
	U.stairs(lm, "White", Vector3(0, 0, 21.0), Basis(), 12.0, 4, 0.7, 0.4)
	# Three-tier roof: white tiles, mirror ridge caps, spiked eaves.
	var y := 10.6
	for k in 3:
		var f := 1.0 - 0.2 * float(k)
		var w := 22.0 * f
		var l := 34.0 * (1.0 - 0.12 * float(k))
		var rise := 4.5 * f
		var c := Vector3(0, y, 0)
		U.swept_roof(lm, "White", "Mirror", "White", c, Basis(), w, l, rise, 1.6, 1.0)
		U.eave_spikes(lm, "White", c, Basis(), w, l, rise, 1.6, 1.0, 1.7, 1.9)
		if k < 2:
			lm.box("White", c + Vector3(0, (rise + 1.6) * 0.5, 0), Vector3(22.0 * (f - 0.2), rise + 1.6,
				34.0 * (1.0 - 0.12 * float(k + 1))))
			y += rise + 1.6
		else:
			y += rise
	# Crown: slim spire clusters along the ridge, tallest at the middle.
	for z in [-9.0, 0.0, 9.0]:
		var h := WHITE_TEMPLE_M - y if z == 0.0 else 3.0
		lm.lathe("White", Vector3(0, y - 0.4, z), PackedVector2Array([Vector2(0.9, 0), Vector2(0.7, h * 0.3),
			Vector2(0.45, h * 0.6), Vector2(0.15, h * 0.9), Vector2(0.0, h + 0.4)]), 8)
	# Pond, bridge and the gate of heaven.
	lm.box("Water", Vector3(0, 0.1, 40.0), Vector3(60.0, 0.2, 40.0))
	lm.box("White", Vector3(0, 0.5, 40.0), Vector3(5.0, 1.0, 36.0))
	for s in [-1.0, 1.0]:
		U.posts(lm, "White", Vector3(s * 2.4, 1.0, 22.0), Vector3(s * 2.4, 1.0, 58.0), 13, 1.5, 0.4)
		lm.box("White", Vector3(s * 2.4, 2.3, 40.0), Vector3(0.3, 0.3, 36.0))
	for s in [-1.0, 1.0]:
		lm.box("White", Vector3(s * 3.0, 3.0, 24.0), Vector3(1.2, 6.0, 1.2))
	lm.box("White", Vector3(0, 6.4, 24.0), Vector3(8.0, 1.2, 1.6))
	U.swept_roof(lm, "White", "Mirror", "", Vector3(0, 7.0, 24.0), Basis(Vector3.UP, PI * 0.5), 3.0, 8.0, 1.8, 0.8, 0.6)
	# Golden hall beside the pond.
	var gc := Vector3(46.0, 0, 28.0)
	lm.box("Gold", gc + Vector3(0, 0.6, 0), Vector3(13.0, 1.2, 17.0))
	lm.box("Gold", gc + Vector3(0, 4.7, 0), Vector3(10.0, 7.0, 14.0))
	U.tiered_roof(lm, "Gold", "Gold", "Gold", gc + Vector3(0, 8.2, 0), Basis(), 11.0, 15.0, 3.0, 2, 1.0)
	lm.commit(model)
