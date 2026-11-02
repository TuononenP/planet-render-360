class_name LandmarkParisMonuments
extends RefCounted

## Arc de Triomphe, the Louvre Pyramid and the Palace of Versailles in
## true metres, y = 0 at street level.

## Arc de Triomphe (50 m): 45 x 22 m block with the 14.6 x 29.2 m main
## arch (passage along Z) and the 8.4 x 18.7 m transverse arches, sculpted
## pier groups, frieze, shield-studded attic and cornices.
static func arc_de_triomphe(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDB991", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#B3A07C", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#A8A294", 4.0))
	LandmarkWestKit.blk(lm, "Steps", 0, -1.0, 0, 52.0, 1.0, 30.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkWestKit.blk(lm, "Stone", sx * 14.9, 0, sz * 7.61, 15.19, 14.46, 6.78)
		# Transverse arch (passage along X) over its pier pair.
		LandmarkWestKit.arch_wall(lm, "Stone", Basis(Vector3.UP, PI * 0.5), Vector3(sx * 14.9, 0, 0),
			11.0, 7.595, 4.22, 14.46, 21.88)
	# Main arch block, entablature, attic and cornice.
	LandmarkWestKit.arch_wall(lm, "Stone", Basis(), Vector3.ZERO, 22.5, 11.0, 7.31, 21.88, 43.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 43.0, 0, 46.4, 1.2, 23.4)
	LandmarkWestKit.blk(lm, "Stone", 0, 44.2, 0, 44.0, 4.8, 21.2)
	LandmarkWestKit.blk(lm, "Stone", 0, 49.0, 0, 46.0, 1.0, 22.8)
	# Sculpted groups on the piers, frieze above the arches, side panels.
	for sz in [-1.0, 1.0]:
		for sx in [-1.0, 1.0]:
			LandmarkWestKit.blk(lm, "Relief", sx * 14.9, 3.0, sz * 11.45, 11.0, 14.0, 0.9)
		LandmarkWestKit.blk(lm, "Relief", 0, 34.0, sz * 11.3, 45.0, 6.0, 0.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkWestKit.blk(lm, "Relief", sx * 22.9, 3.0, sz * 7.6, 0.9, 9.0, 4.6)
		LandmarkWestKit.blk(lm, "Relief", sx * 22.8, 30.0, 0, 0.6, 6.0, 21.0)
	# Thirty shields round the attic.
	for sz in [-1.0, 1.0]:
		for k in 8:
			lm.box("Relief", Vector3(-19.25 + 5.5 * float(k), 46.6, sz * 10.8), Vector3(2.3, 2.3, 0.4))
	for sx in [-1.0, 1.0]:
		for k in 3:
			lm.box("Relief", Vector3(sx * 22.0, 46.6, -6.0 + 6.0 * float(k)), Vector3(0.4, 2.3, 2.3))
	lm.commit(model)

## Louvre Pyramid (21.64 m): 35.4 m glass pyramid with its rhombic steel
## lattice, the three small pyramids and the fountain pool in the Cour
## Napoléon.
static func louvre_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#8FA4B0"))
	lm.use("Frame", LandmarkMaterials.paint("#D5D9DC", 0.35, 0.8))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B8AE9C", 4.0))
	lm.use("Water", LandmarkMaterials.glass("#3E5560"))
	LandmarkWestKit.blk(lm, "Paving", 0, -0.2, 0, 80.0, 0.2, 80.0)
	LandmarkWestKit.blk(lm, "Water", 0, -0.1, 27.0, 40.0, 0.2, 8.0)
	_pyramid(lm, Vector3.ZERO, 17.71, 21.64, 16)
	for p in [Vector3(-27, 0, 0), Vector3(27, 0, 0), Vector3(0, 0, -27)]:
		_pyramid(lm, p, 4.3, 5.0, 4)
	lm.commit(model)

## Glass pyramid on `c` with a diagonal lattice of n x n cells per face.
static func _pyramid(lm: LandmarkMesh, c: Vector3, hw: float, h: float, n: int) -> void:
	lm.spire("Glass", c, hw, h)
	var apex := c + Vector3(0, h, 0)
	var w := hw * 0.012 + 0.08
	var corners := [Vector3(-hw, 0, -hw), Vector3(hw, 0, -hw), Vector3(hw, 0, hw), Vector3(-hw, 0, hw)]
	for i in 4:
		var a: Vector3 = c + corners[i]
		var b: Vector3 = c + corners[(i + 1) % 4]
		var out := ((a + b) * 0.5 - c).normalized() * 0.04
		lm.beam("Frame", a, b, w * 2.0)
		lm.beam("Frame", a, apex, w * 1.8)
		for k in range(1, n):
			var t := float(k) / float(n)
			var q0 := a.lerp(b, t)
			lm.beam("Frame", q0 + out, q0 + (apex - a) * (1.0 - t) + out, w)
			lm.beam("Frame", q0 + out, q0 + (apex - b) * t + out, w)

## Palace of Versailles (40 m to the Royal Chapel's spire): the 580 m
## garden front facing west (-X) with its central avant-corps, the
## brick-and-stone Louis XIII château round the Marble Court, the Royal
## Chapel, and the two long ministers' wings of the entrance court that
## close on the gilded gate (east, +X).
static func versailles(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBE9F", 4.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A4503B", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4D555B", 2.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Court", LandmarkMaterials.pbr("gravel", "#C9BFA9", 5.0))
	var rot := Basis(Vector3.UP, PI * 0.5)
	# Garden range (Hall of Mirrors at the centre) with its avant-corps.
	LandmarkWestKit.blk(lm, "Stone", -57.5, 0, 0, 35.0, 20.0, 580.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(-57.5, 20, 0), 36.0, 581.0, 5.0, 0.85)
	LandmarkWestKit.blk(lm, "Stone", -79.5, 0, 0, 9.0, 21.0, 72.0)
	LandmarkWestKit.blk(lm, "Stone", -79.5, 21.0, 0, 10.0, 1.2, 73.0)
	LandmarkWestKit.col_row(lm, "Stone", Vector3(-85.0, 0, -32.0), Vector3(-85.0, 0, 32.0), 12,
		0.7, 0.6, 15.0)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", -57.5, 0, sz * 262.0, 35.0, 22.0, 56.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(-57.5, 22, sz * 262.0), 36.0, 57.0, 6.0, 0.8)
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-75.2, 0, -286), Vector3(-75.2, 0, 286),
		Vector3(-1, 0, 0), 5.8, 1.9, 4.2, [5.5, 14.0])
	# Louis XIII château: brick U round the Marble Court.
	LandmarkWestKit.blk(lm, "Brick", -32.5, 0, 0, 15.0, 18.0, 70.0)
	LandmarkWestKit.hip(lm, "Slate", Vector3(-32.5, 18, 0), 16.0, 71.0, 9.0, 0.35)
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Brick", -4.0, 0, sz * 31.5, 56.0, 18.0, 7.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(-4.0, 18, sz * 31.5), 57.0, 8.0, 8.0, 0.4)
		LandmarkWestKit.blk(lm, "Stone", 12.0, 0, sz * 31.5, 10.0, 22.0, 9.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(12.0, 22, sz * 31.5), 11.0, 10.0, 8.0, 0.0)
	LandmarkWestKit.blk(lm, "Court", -2.0, 0, 0, 44.0, 0.3, 56.0)
	LandmarkWestKit.blk(lm, "Gilt", -24.7, 8.0, 0, 0.8, 0.5, 8.0)
	# Royal wings and the long ministers' wings round the entrance court.
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", 50.0, 0, sz * 62.0, 70.0, 19.0, 18.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(50.0, 19, sz * 62.0), 71.0, 19.0, 5.5, 0.8)
		LandmarkWestKit.blk(lm, "Stone", 160.0, 0, sz * 105.0, 200.0, 17.0, 17.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(160.0, 17, sz * 105.0), 201.0, 18.0, 5.0, 0.8)
		LandmarkWestKit.blk(lm, "Stone", 250.0, 0, sz * 105.0, 30.0, 22.0, 30.0)
		LandmarkWestKit.hip(lm, "Slate", Vector3(250.0, 22, sz * 105.0), 31.0, 31.0, 8.0, 0.0)
		LandmarkWestKit.win_line(lm, "Glass", Vector3(62.0, 0, sz * 96.4), Vector3(236.0, 0, sz * 96.4),
			Vector3(0, 0, -sz), 5.8, 1.7, 3.6, [5.0, 12.0])
		LandmarkWestKit.blk(lm, "Stone", 80.0, 0, sz * 83.0, 16.0, 17.0, 26.0)
	LandmarkWestKit.merlons(lm, "Gilt", Vector3(262.0, 0, -86.0), Vector3(262.0, 0, 86.0), 1.5, 0.2, 2.8, 0.2)
	# Royal Chapel: tall gabled nave with a slender spire (40 m).
	LandmarkWestKit.blk(lm, "Stone", -19.0, 0, -94.0, 42.0, 24.0, 22.0)
	lm.gable("Slate", Vector3(-19.0, 24.0, -94.0), 22.0, 42.0, 9.0, rot, 0.8, "Stone")
	LandmarkWestKit.win_line(lm, "Glass", Vector3(-39.0, 0, -105.2), Vector3(1.0, 0, -105.2),
		Vector3(0, 0, -1), 5.0, 1.8, 11.0, [11.0])
	lm.frustum("Stone", Vector3(-19.0, 31.0, -94.0), 3.2, 2.8, 4.0, 8)
	lm.lathe("Slate", Vector3(-19.0, 35.0, -94.0), PackedVector2Array([Vector2(3.0, 0), Vector2(1.8, 2.2),
		Vector2(0.9, 3.8), Vector2(0.0, 5.0)]), 8)
	lm.lathe("Gilt", Vector3(-19.0, 38.8, -94.0), PackedVector2Array([Vector2(0.4, 0), Vector2(0.0, 1.2)]), 6)
	lm.commit(model)
