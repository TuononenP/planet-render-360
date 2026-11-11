class_name LandmarkTsStatues
extends RefCounted

## The two bronze figures on the axis of Gwanghwamun Square, in true
## metres on LandmarkMesh, built about the OSM statue node with y = 0 on
## the square and the figure facing south (+Z, OSM direction=180).
## Stylised: the masses, pose and outline that read across the square.

## Statue of King Sejong (2009, Kim Young-won): the 6.2 m, 4.3 m wide
## seated gilded-bronze king on a 4.2 m stone pedestal, an open book in
## his left hand and his right hand raised; in front, the bronze
## armillary sphere, sundial and rain gauge on their stones.
static func king_sejong(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#BDB6AA", 3.0))
	lm.use("Gold", LandmarkMaterials.pbr("concrete", "#C29A4E", 2.0, 0.35, 0.85))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5A4A33", 2.0, 0.45, 0.75))
	# Pedestal: base slab, body with recessed panels, cornice (to 4.2 m).
	lm.box("Stone", Vector3(0, 0.3, 0), Vector3(10.0, 0.6, 7.4))
	lm.box("Stone", Vector3(0, 2.2, 0), Vector3(7.6, 3.2, 5.2))
	for s in [-1.0, 1.0]:
		lm.box("Bronze", Vector3(0, 2.2, s * 2.62), Vector3(6.0, 2.2, 0.06), Basis(), 0.0)
		lm.box("Bronze", Vector3(s * 3.82, 2.2, 0), Vector3(0.06, 2.2, 3.8), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 4.0, 0), Vector3(8.2, 0.4, 5.8))
	var y := 4.2
	# Throne and the robed seated body: lap and knees, sleeves, torso.
	lm.box("Gold", Vector3(0, y + 0.9, -0.6), Vector3(4.0, 1.8, 2.6))
	lm.box("Gold", Vector3(0, y + 1.25, 0.7), Vector3(4.3, 1.2, 1.6))
	lm.lathe("Gold", Vector3(0, y, 1.35), PackedVector2Array([Vector2(1.9, 0.0), Vector2(1.75, 1.0),
		Vector2(1.55, 1.65), Vector2(0.0, 1.85)]), 16, 1.15, 0.55)
	lm.lathe("Gold", Vector3(0, y + 1.7, -0.2), PackedVector2Array([Vector2(1.55, 0.0), Vector2(1.45, 1.0),
		Vector2(1.25, 2.0), Vector2(0.9, 2.55), Vector2(0.45, 2.75)]), 16, 1.25, 0.8)
	for s in [-1.0, 1.0]:
		# Wide hanging sleeves.
		lm.lathe("Gold", Vector3(s * 1.75, y + 1.9, 0.1), PackedVector2Array([Vector2(0.75, 0.0), Vector2(0.6, 1.2),
			Vector2(0.45, 1.9), Vector2(0.0, 2.2)]), 10, 0.7, 1.2)
	# Left hand holds the open book on the lap; the right forearm is
	# raised with the palm out.
	lm.box("Gold", Vector3(-0.55, y + 2.05, 1.25), Vector3(1.3, 0.12, 0.9), Basis(Vector3.RIGHT, -0.5))
	lm.beam("Gold", Vector3(1.45, y + 2.6, 0.35), Vector3(1.35, y + 3.6, 1.05), 0.55, 0.55)
	lm.box("Gold", Vector3(1.32, y + 3.95, 1.12), Vector3(0.45, 0.6, 0.14), Basis(Vector3.RIGHT, -0.2))
	# Head and the winged ikseongwan crown, to the 10.4 m top.
	lm.lathe("Gold", Vector3(0, y + 4.4, 0.0), PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.48, 0.25),
		Vector2(0.52, 0.6), Vector2(0.45, 0.95), Vector2(0.0, 1.05)]), 14)
	lm.lathe("Gold", Vector3(0, y + 5.3, -0.08), PackedVector2Array([Vector2(0.55, 0.0), Vector2(0.55, 0.35),
		Vector2(0.4, 0.55), Vector2(0.0, 0.62)]), 14)
	for s in [-1.0, 1.0]:
		lm.box("Gold", Vector3(s * 0.32, y + 5.95, -0.5), Vector3(0.36, 0.5, 0.08), Basis(Vector3.FORWARD, s * 0.35))
	# The three scientific instruments in front of the statue.
	_armillary(lm, Vector3(-4.0, 0, 9.0))
	lm.box("Stone", Vector3(0, 0.45, 9.5), Vector3(1.6, 0.9, 1.6))
	lm.lathe("Bronze", Vector3(0, 0.9, 9.5), PackedVector2Array([Vector2(0.25, 0.0), Vector2(0.75, 0.3),
		Vector2(0.85, 0.6), Vector2(0.6, 0.62)]), 16)
	lm.box("Stone", Vector3(4.0, 0.6, 9.0), Vector3(1.2, 1.2, 1.2))
	lm.lathe("Bronze", Vector3(4.0, 1.2, 9.0), PackedVector2Array([Vector2(0.4, 0.0), Vector2(0.4, 1.0),
		Vector2(0.0, 1.0)]), 14)
	lm.commit(model)

## Honcheonui: three bronze rings on a stand over a stone block.
static func _armillary(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Stone", p + Vector3(0, 0.5, 0), Vector3(1.8, 1.0, 1.8))
	lm.beam("Bronze", p + Vector3(0, 1.0, 0), p + Vector3(0, 1.8, 0), 0.2, 0.2)
	var c := p + Vector3(0, 2.6, 0)
	for ring in [Basis(), Basis(Vector3.RIGHT, PI * 0.5), Basis(Vector3.FORWARD, 0.4) * Basis(Vector3.RIGHT, PI * 0.5)]:
		var b := ring as Basis
		var prev := c + b * Vector3(0.9, 0, 0)
		for k in range(1, 17):
			var t := TAU * float(k) / 16.0
			var q := c + b * Vector3(cos(t) * 0.9, 0, sin(t) * 0.9)
			lm.beam("Bronze", prev, q, 0.08, 0.08)
			prev = q

## Statue of Admiral Yi Sun-sin (1968, Kim Se-jung): the 6.5 m standing
## armoured admiral, a long sword point-down before him, on its 10.5 m
## pillar pedestal (17 m in all), with the bronze turtle ship (geobukseon)
## on its stone at the front.
static func yi_sun_sin(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B7B1A6", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4B4234", 2.0, 0.45, 0.75))
	lm.use("Dark", LandmarkMaterials.paint("#2A2620", 0.6, 0.4))
	# Stepped base, the tapering pillar and its cornice (to 10.5 m).
	lm.box("Stone", Vector3(0, 0.4, 0), Vector3(9.0, 0.8, 9.0))
	lm.box("Stone", Vector3(0, 1.1, 0), Vector3(7.0, 0.6, 7.0))
	lm.box("Stone", Vector3(0, 1.75, 0), Vector3(5.2, 0.7, 5.2))
	lm.lathe("Stone", Vector3(0, 2.1, 0), PackedVector2Array([Vector2(2.3, 0.0), Vector2(2.3, 0.5), Vector2(2.0, 0.7),
		Vector2(1.85, 7.4), Vector2(2.15, 7.6), Vector2(2.15, 8.0), Vector2(2.4, 8.2), Vector2(2.4, 8.4)]),
		4, 1.0, 1.0, PI * 0.25, false)
	lm.box("Dark", Vector3(0, 6.0, 1.95), Vector3(1.6, 2.4, 0.06), Basis(), 0.0)
	var y := 10.5
	# Boots and legs under the flared armour skirt.
	for s in [-1.0, 1.0]:
		lm.box("Bronze", Vector3(s * 0.38, y + 0.18, 0.15), Vector3(0.5, 0.36, 0.85))
		lm.beam("Bronze", Vector3(s * 0.36, y + 0.3, 0.05), Vector3(s * 0.3, y + 2.0, 0.0), 0.5, 0.55)
	lm.box("Bronze", Vector3(0, y + 0.08, 0.0), Vector3(2.0, 0.16, 1.6))
	lm.lathe("Bronze", Vector3(0, y + 1.3, 0), PackedVector2Array([Vector2(1.1, 0.0), Vector2(0.95, 1.0),
		Vector2(0.75, 1.6), Vector2(0.72, 3.4), Vector2(0.95, 3.75), Vector2(0.6, 4.0), Vector2(0.0, 4.05)]),
		16, 1.15, 0.8)
	# Cape down the back and the shoulder guards.
	lm.lathe("Bronze", Vector3(0, y + 0.9, -0.45), PackedVector2Array([Vector2(1.0, 0.0), Vector2(0.9, 2.0),
		Vector2(0.8, 4.3), Vector2(0.0, 4.4)]), 12, 1.1, 0.45)
	for s in [-1.0, 1.0]:
		lm.lathe("Bronze", Vector3(s * 0.85, y + 4.45, 0.0), PackedVector2Array([Vector2(0.4, 0.0), Vector2(0.35, 0.3),
			Vector2(0.0, 0.4)]), 10)
	# Hands together on the hilt of the sword, its point by the feet.
	lm.beam("Bronze", Vector3(0.0, y + 0.2, 0.85), Vector3(0.0, y + 3.0, 0.75), 0.18, 0.06)
	lm.beam("Bronze", Vector3(0.0, y + 3.0, 0.75), Vector3(0.0, y + 3.7, 0.72), 0.12, 0.12)
	lm.box("Bronze", Vector3(0, y + 3.0, 0.75), Vector3(0.6, 0.1, 0.18))
	for s in [-1.0, 1.0]:
		lm.beam("Bronze", Vector3(s * 0.85, y + 4.2, 0.1), Vector3(s * 0.25, y + 3.4, 0.7), 0.3, 0.3)
	lm.box("Bronze", Vector3(0, y + 3.4, 0.74), Vector3(0.5, 0.35, 0.3))
	# Head and the helmet with its flared neck guard and spike (17 m).
	lm.lathe("Bronze", Vector3(0, y + 5.35, 0.05), PackedVector2Array([Vector2(0.28, 0.0), Vector2(0.36, 0.3),
		Vector2(0.38, 0.6)]), 12)
	lm.lathe("Bronze", Vector3(0, y + 5.85, 0.05), PackedVector2Array([Vector2(0.55, 0.0), Vector2(0.45, 0.15),
		Vector2(0.4, 0.4), Vector2(0.28, 0.55), Vector2(0.06, 0.6)]), 14)
	lm.frustum("Bronze", Vector3(0, y + 6.4, 0.05), 0.06, 0.015, 0.1, 6)
	# Turtle ship on its stone in front of the pedestal.
	lm.box("Stone", Vector3(0, 0.45, 6.8), Vector3(2.4, 0.9, 4.4))
	var t := Vector3(0, 0.9, 6.8)
	lm.lathe("Bronze", t, PackedVector2Array([Vector2(0.4, 0.0), Vector2(0.8, 0.35), Vector2(0.75, 0.75),
		Vector2(0.0, 1.05)]), 12, 1.0, 2.2)
	lm.beam("Bronze", t + Vector3(0, 0.6, 1.6), t + Vector3(0, 1.15, 2.25), 0.3, 0.3)
	for k in 6:
		lm.frustum("Bronze", t + Vector3(0, 0.95, -1.2 + 0.45 * k), 0.06, 0.0, 0.2, 4)
	lm.commit(model)
