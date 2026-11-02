class_name LandmarkRmAColumns
extends RefCounted

## Trajan's Column, the Column of Marcus Aurelius and the Pyramid of
## Cestius with the Porta San Paolo, in true metres.

# --- Trajan's Column ----------------------------------------------------

## 38.5 m: the 5.4 m pedestal, laurel torus, 20-drum Carrara shaft with
## the 23-turn Dacian frieze, Doric capital and platform, and the bronze
## St Peter that Sixtus V set up in 1587.
static func trajan(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D5CDBB", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#B3A892", 2.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#BDB197", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5E6B4F", 0.5, 0.5))
	lm.box("Steps", Vector3(0, 0.2, 0), Vector3(7.6, 0.4, 7.6))
	# Pedestal: plinth, die with trophy panels and the door, cornice.
	lm.box("Marble", Vector3(0, 0.65, 0), Vector3(5.9, 0.5, 5.9))
	lm.box("Marble", Vector3(0, 2.85, 0), Vector3(5.4, 3.9, 5.4))
	lm.box("Marble", Vector3(0, 5.1, 0), Vector3(5.9, 0.6, 5.9))
	for k in 4:
		var a := PI * 0.5 * float(k)
		var out := Vector3(sin(a), 0, cos(a))
		var basis := Basis(Vector3.UP, a)
		lm.box("Relief", out * 2.72 + Vector3(0, 3.3, 0), Vector3(3.6, 2.2, 0.14), basis)
		lm.box("Relief", out * 2.72 + Vector3(0, 1.8, 0), Vector3(2.2, 0.5, 0.14), basis)
	lm.box("Relief", Vector3(0, 1.9, 2.74), Vector3(1.3, 2.3, 0.1))
	# Torus, shaft with the spiral frieze, capital, platform.
	lm.lathe("Marble", Vector3(0, 5.4, 0), PackedVector2Array([Vector2(2.6, 0), Vector2(2.75, 0.25),
		Vector2(2.6, 0.55), Vector2(2.15, 0.85), Vector2(1.9, 1.0)]), 24)
	RmAUtil.spiral_column(lm, "Marble", "Relief", Vector3(0, 6.4, 0), 27.3, 1.85, 1.6, 23.0)
	lm.lathe("Marble", Vector3(0, 33.7, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.95, 0.35),
		Vector2(2.2, 0.8)]), 24)
	lm.box("Marble", Vector3(0, 34.75, 0), Vector3(4.6, 0.5, 4.6))
	lm.box("Marble", Vector3(0, 35.25, 0), Vector3(2.0, 0.5, 2.0))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 35.5, 0), 3.0, true)
	lm.commit(model)

# --- Column of Marcus Aurelius ---------------------------------------

## 42 m: Fontana's 8.4 m pedestal of 1589, the 21-turn Marcomannic
## frieze on the 29.6 m Doric shaft and the bronze St Paul with his sword.
static func marcus_aurelius(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D2CAB8", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#AFA48E", 2.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#BDB197", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5E6B4F", 0.5, 0.5))
	lm.box("Steps", Vector3(0, 0.15, 0), Vector3(8.4, 0.3, 8.4))
	lm.box("Steps", Vector3(0, 0.5, 0), Vector3(7.2, 0.4, 7.2))
	lm.box("Marble", Vector3(0, 4.7, 0), Vector3(5.6, 7.6, 5.6))
	lm.box("Marble", Vector3(0, 1.1, 0), Vector3(6.2, 0.8, 6.2))
	lm.box("Marble", Vector3(0, 8.1, 0), Vector3(6.2, 0.6, 6.2))
	for k in 4:
		var a := PI * 0.5 * float(k)
		var out := Vector3(sin(a), 0, cos(a))
		lm.box("Relief", out * 2.84 + Vector3(0, 4.9, 0), Vector3(3.4, 3.2, 0.14), Basis(Vector3.UP, a))
	lm.lathe("Marble", Vector3(0, 8.4, 0), PackedVector2Array([Vector2(2.5, 0), Vector2(2.65, 0.3),
		Vector2(2.5, 0.6), Vector2(2.05, 0.9)]), 24)
	RmAUtil.spiral_column(lm, "Marble", "Relief", Vector3(0, 9.3, 0), 27.4, 1.95, 1.75, 21.0)
	lm.lathe("Marble", Vector3(0, 36.7, 0), PackedVector2Array([Vector2(1.6, 0), Vector2(2.05, 0.35),
		Vector2(2.3, 0.8)]), 24)
	lm.box("Marble", Vector3(0, 37.75, 0), Vector3(4.7, 0.5, 4.7))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 38.0, 0), 4.0, true)
	lm.commit(model)

# --- Pyramid of Cestius -----------------------------------------------

## The marble-faced tomb of Gaius Cestius, 29.6 m square and 37 m high,
## on its travertine foundation, with the Aurelian Wall running to the
## Porta San Paolo: two brick towers either side of the double-arched
## gate. Built square to its axes; yaw_deg turns it onto the street grid.
static func pyramid(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DDD7C9", 4.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#BFB290", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#93694E", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F463A", 3.0))
	lm.box("Travertine", Vector3(0, 0.7, 0), Vector3(30.4, 1.4, 30.4))
	lm.spire("Marble", Vector3(0, 1.4, 0), 14.8, 35.6)
	# Aurelian Wall from the pyramid to the gate, then the gate itself.
	var gate := Vector3(29.0, 0, -47.0)
	RmAUtil.ruin_wall(lm, "Brick", Vector3(14.5, 0, -14.0), gate + Vector3(-4.0, 0, 5.0), 3.6,
		0.0, 9.0, 11.0, 2.4, 2.0)
	lm.place(gate.x, gate.z, 166.0)
	for sx in [-1.0, 1.0]:
		lm.frustum("Brick", Vector3(sx * 7.6, 0, 0), 5.2, 4.8, 13.0, 16)
		lm.frustum("Travertine", Vector3(sx * 7.6, 13.0, 0), 5.5, 5.5, 0.6, 16)
		RmAUtil.merlons_ring(lm, "Brick", Vector3(sx * 7.6, 0, 0), 5.0, 13.6, 8, 1.6, 1.2, 0.8)
		for a in [0.5, 1.0]:
			lm.box("Shadow", Vector3(sx * 7.6, 6.0 + 3.5 * float(a), 4.9), Vector3(0.9, 1.7, 0.12))
	RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(0, 0, 2.0), Vector3.RIGHT, Vector3.BACK,
		-7.0, 7.0, 0.0, 11.0, [[-1.9, 3.2, 4.5, 0.0], [1.9, 3.2, 4.5, 0.0]], 4.0, 8)
	lm.box("Travertine", Vector3(0, 11.3, 0), Vector3(14.6, 0.6, 4.6))
	lm.commit(model)
