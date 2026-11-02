class_name LandmarkAtChurches
extends RefCounted

## The Chapel of St George on Mount Lycabettus and the Metropolitan
## Cathedral of Athens in true metres.

# --- Chapel of St George, Lycabettus -----------------------------------

## Origin at the middle of the summit platform (the hill's 277 m top is
## the ground, y = 0); front and bell tower toward +Z, apse toward -Z
## (yaw_deg turns the front west). The whitewashed single-aisle chapel
## (19th century, the belfry of 1902) under a terracotta gable with
## cover tiles, the half-round apse with its tiled half-cone and slit
## windows, the framed door and arched side windows, the corner bell
## tower with arched openings on each face, a cornice, tiled pyramid and
## cross (11.3 m), the paved courtyard inside its low parapet wall, and
## the bare rock breaking through round the terrace.
static func lycabettus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#F1EEE6", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B5643A", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8E8878", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 2.0))
	lm.use("Floor", LandmarkMaterials.pbr("stone", "#BDB6A6", 2.0))
	lm.box("Floor", Vector3(0, 0.1, 0), Vector3(17.0, 0.2, 20.0), Basis(), 0.0)
	for i in 9:
		var a := TAU * float(i) / 9.0 + 0.4
		SEuUtil.blob(lm, "Rock", Vector3(cos(a) * 10.5, 0.0, sin(a) * 11.5), 2.4 + 0.6 * float(i % 3), 1.0 + 0.4 * float(i % 2),
			2.0, Vector3.ZERO, true, 5, 10)
	var g := 0.2
	lm.box("Render", Vector3(0, g + 2.4, 0), Vector3(6.2, 4.8, 7.6))
	lm.box("Render", Vector3(0, g + 0.15, 0), Vector3(6.4, 0.3, 7.8))
	lm.box("Render", Vector3(0, g + 4.85, 0), Vector3(6.5, 0.18, 7.9), Basis(), 0.0)
	lm.gable("Tile", Vector3(0, g + 4.95, 0), 6.2, 7.6, 1.9, Basis(), 0.4, "Render")
	_tiles(lm, Vector3(0, g + 4.95, 0), 6.2, 7.6, 1.9, 0.4)
	# Apse with its tiled half-cone and three slit windows.
	lm.lathe("Render", Vector3(0, g, -3.8), PackedVector2Array([Vector2(2.3, 0), Vector2(2.3, 4.2)]), 20)
	lm.lathe("Tile", Vector3(0, g + 4.2, -3.8), PackedVector2Array([Vector2(2.5, 0), Vector2(1.2, 1.0),
		Vector2(0.0, 1.6)]), 20)
	for k in 3:
		var a := PI * 1.5 + (float(k) - 1.0) * 0.6
		var d := Vector3(cos(a), 0, sin(a))
		SEuUtil.opening(lm, "Shadow", Vector3(0, g + 1.8, -3.8) + d * 2.32, Vector3.UP.cross(d), Vector3.UP, 0.35, 1.3)
	# Bell tower on the front left corner.
	var tc := Vector3(-2.2, g, 5.0)
	lm.box("Render", tc + Vector3(0, 4.2, 0), Vector3(3.2, 8.4, 3.2))
	lm.box("Render", tc + Vector3(0, 5.3, 0), Vector3(3.4, 0.2, 3.4), Basis(), 0.0)
	for k in 3:
		lm.box("Render", tc + Vector3(0, 8.3 + 0.12 * float(k), 0), Vector3(3.4 + 0.15 * float(k), 0.12,
			3.4 + 0.15 * float(k)), Basis(), 0.0)
	lm.spire("Tile", tc + Vector3(0, 8.65, 0), 1.85, 1.55)
	lm.lathe("Render", tc + Vector3(0, 10.15, 0), SEuUtil.dome(0.18, 0.2, 3), 8)
	lm.box("Render", tc + Vector3(0, 10.75, 0), Vector3(0.12, 1.0, 0.12))
	lm.box("Render", tc + Vector3(0, 10.95, 0), Vector3(0.6, 0.1, 0.12))
	for f in 4:
		var a := PI * 0.5 * float(f)
		var d := Vector3(sin(a), 0, cos(a))
		var o := tc + d * 1.6 + Vector3(0, 5.8, 0)
		SEuUtil.opening(lm, "Shadow", o + d * 0.02, Vector3.UP.cross(d), Vector3.UP, 1.1, 2.1)
		LandmarkDetail.arch(lm, "Render", o + Vector3(0, 2.1 - 0.55, 0), d, 1.1, 0.18, 0.1)
		lm.box("Render", o + d * 0.05 + Vector3(0, -0.05, 0), Vector3(1.4, 0.1, 0.15), Basis.looking_at(-d), 0.0)
	lm.lathe("Shadow", tc + Vector3(0, 6.3, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.45, 0.5),
		Vector2(0.15, 0.7), Vector2(0.0, 0.75)]), 10)
	# Door with its frame and arched tympanum, side windows.
	AtUtil.doorway(lm, "Render", "Shadow", Vector3(1.2, g, 3.8), Vector3.BACK, 1.2, 2.3)
	LandmarkDetail.arch(lm, "Render", Vector3(1.2, g + 2.75, 3.85), Vector3.BACK, 1.2, 0.16, 0.12)
	for s in [-1.0, 1.0]:
		for k in 2:
			var c := Vector3(s * 3.1, g + 2.6, -1.5 + 3.0 * float(k))
			LandmarkDetail.window(lm, "Render", "Shadow", c, Vector3(s, 0, 0), 0.7, 1.5, true, 0.15)
	SEuUtil.opening(lm, "Shadow", Vector3(1.2, g + 5.6, 3.82), Vector3.RIGHT, Vector3.UP, 0.4, 0.8)
	# Low whitewashed courtyard wall with a gap at the entrance, coping.
	var walls := [[Vector3(0, 0, -10.0), 17.0, 0.0], [Vector3(-8.5, 0, 0), 20.0, PI * 0.5],
		[Vector3(8.5, 0, 0), 20.0, PI * 0.5], [Vector3(-5.9, 0, 10.0), 5.2, 0.0], [Vector3(5.9, 0, 10.0), 5.2, 0.0]]
	for wl in walls:
		var p: Vector3 = wl[0]
		var b := Basis(Vector3.UP, float(wl[2]))
		lm.box("Render", p + Vector3(0, 0.7, 0), Vector3(float(wl[1]), 1.0, 0.35), b)
		lm.box("Render", p + Vector3(0, 1.25, 0), Vector3(float(wl[1]) + 0.1, 0.1, 0.5), b, 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Render", Vector3(s * 3.3, 0.9, 10.0), Vector3(0.6, 1.4, 0.6))
	lm.commit(model)

## Cover-tile rows on a ridge-along-Z gable (c at the eaves, w x l).
static func _tiles(lm: LandmarkMesh, c: Vector3, w: float, l: float, rise: float, over: float) -> void:
	var n := int(l / 0.35)
	for i in n:
		var z := -l * 0.5 + l * (float(i) + 0.5) / float(n)
		for s in [-1.0, 1.0]:
			lm.beam("Tile", c + Vector3(float(s) * (w * 0.5 + over), 0.05, z), c + Vector3(0, rise + 0.05, z), 0.11, 0.08)
	lm.beam("Tile", c + Vector3(0, rise + 0.08, -l * 0.5 - over * 0.5), c + Vector3(0, rise + 0.08, l * 0.5 + over * 0.5),
		0.25, 0.18)

# --- Metropolitan Cathedral of Athens --------------------------------------

## Origin at the crossing, front toward +Z (yaw_deg turns it west onto
## Mitropoleos Square). The 1842-62 three-aisled domed basilica, 40 x 20 m
## and 24 m high, built with marble from 72 demolished churches: the
## raised nave under a tiled gable with arched clerestory windows, the
## lower aisles with their arched windows, the apse, the central
## entrance arch on Corinthian columns and pilasters under a pediment,
## the two Western-style bell towers with arched belfries, and the
## drum with its arched windows and pilasters under the dome and cross.
static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CDB2", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E9E0CC", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A9573A", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7F8689", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#3A4A5A"))
	lm.box("Marble", Vector3(0, 0.45, -2.0), Vector3(20.8, 0.9, 36.8))
	lm.box("Stone", Vector3(0, 7.75, -2.0), Vector3(11.0, 15.5, 36.0))
	lm.gable("Tile", Vector3(0, 15.5, -2.0), 11.0, 36.0, 3.2, Basis(), 0.5, "Stone")
	LandmarkDetail.cornice(lm, "Marble", Vector3(-5.5, 15.1, 16.0), Vector3(5.5, 15.1, 16.0), Vector3.BACK, 0.5)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 7.75, 5.0, -2.0), Vector3(4.5, 10.0, 36.0))
		lm.quad("Tile", Vector3(s * 10.3, 10.0, -20.3), Vector3(s * 10.3, 10.0, 16.3),
			Vector3(s * 5.5, 12.0, 16.3), Vector3(s * 5.5, 12.0, -20.3), Vector3(s * 0.3, 1.0, 0.0).normalized())
		LandmarkDetail.cornice(lm, "Marble", Vector3(s * 10.0, 9.7, -20.0), Vector3(s * 10.0, 9.7, 16.0),
			Vector3(s, 0, 0), 0.4, false)
		LandmarkDetail.cornice(lm, "Marble", Vector3(s * 5.5, 15.1, -20.0), Vector3(s * 5.5, 15.1, 16.0),
			Vector3(s, 0, 0), 0.4, false)
		lm.box("Marble", Vector3(s * 10.05, 0.9 + 1.5, -2.0), Vector3(0.2, 0.25, 36.0), Basis(), 0.0)
		for k in 8:
			var z := -16.7 + 4.2 * float(k)
			if absf(z + 2.0) < 4.0:
				continue
			LandmarkDetail.window(lm, "Marble", "Glass", Vector3(s * 10.0, 5.0, z), Vector3(s, 0, 0), 1.4, 3.6, true)
			LandmarkDetail.window(lm, "Marble", "Glass", Vector3(s * 5.5, 13.0, z), Vector3(s, 0, 0), 1.2, 2.2, true)
			lm.box("Marble", Vector3(s * 10.1, 5.0, z + 2.1), Vector3(0.25, 9.0, 0.5))
	# Apse with three windows, its tiled half-cone.
	lm.lathe("Stone", Vector3(0, 0, -20.0), PackedVector2Array([Vector2(5.5, 0), Vector2(5.5, 14.0)]), 24)
	lm.lathe("Tile", Vector3(0, 14.0, -20.0), PackedVector2Array([Vector2(5.8, 0), Vector2(3.0, 2.2),
		Vector2(0.0, 3.5)]), 24)
	for k in 3:
		var a := PI * 1.5 + (float(k) - 1.0) * 0.55
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Marble", "Glass", Vector3(0, 7.5, -20.0) + d * 5.5, d, 1.2, 3.4, true)
	# The dome on its windowed drum over the crossing, with the cross.
	LandmarkKits.dome_on_drum(lm, "Stone", "Dome", Vector3(0, 12.0, -2.0), 5.0, 8.0, 3.0, 0.0, 32, 16)
	SEuUtil.ring_openings(lm, "Glass", Vector3(0, 12.0, -2.0), 5.0, 40, 8, 2.6, 1.2, 3.6, false, 0.2)
	lm.frustum("Stone", Vector3(0, 22.85, -2.0), 0.8, 0.6, 0.35, 12)
	lm.box("Gold", Vector3(0, 23.6, -2.0), Vector3(0.14, 0.8, 0.14))
	lm.box("Gold", Vector3(0, 23.75, -2.0), Vector3(0.6, 0.12, 0.14))
	# Front: the entrance arch on paired Corinthian columns and pilasters,
	# under a pediment; the doors and windows of the west front.
	var y0 := 0.9
	AtUtil.steps(lm, "Marble", Vector3(0, y0, 17.6), 12.0, 3.2, 3, 0.3, 0.4)
	lm.box("Stone", Vector3(0, y0 + 5.5, 16.6), Vector3(9.0, 11.0, 1.2))
	for s in [-1.0, 1.0]:
		for x in [2.6, 3.6]:
			AtUtil.corinthian(lm, "Marble", Vector3(s * float(x), y0, 18.4), 6.6, 0.3, 24)
		lm.box("Marble", Vector3(s * 4.3, y0 + 3.3, 17.35), Vector3(0.7, 6.6, 0.3))
	var et := AtUtil.entab(lm, "Marble", "Stone", Vector3(0, y0 + 6.6, 18.2), 8.6, 1.2, 0.5, 0.5, 0.4)
	LandmarkDetail.arch(lm, "Marble", Vector3(0, y0 + 4.6, 17.3), Vector3.BACK, 4.2, 0.45, 0.35)
	AtUtil.roof(lm, "Tile", "Marble", "Stone", Vector3(0, et, 17.9), 8.8, 2.0, 1.6, 0.2)
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(0, y0, 17.25), Vector3.BACK, 2.4, 4.4, true)
	for s in [-1.0, 1.0]:
		AtUtil.doorway(lm, "Marble", "Shadow", Vector3(s * 7.0, y0, 16.05), Vector3.BACK, 1.4, 3.0)
		LandmarkDetail.window(lm, "Marble", "Glass", Vector3(s * 7.0, 7.0, 16.05), Vector3.BACK, 1.0, 2.2, true)
	lm.disc("Glass", Vector3(0, 12.6, 16.1), Vector3.BACK, 1.2, 20)
	lm.lathe("Marble", Vector3(0, 12.6, 16.1), PackedVector2Array([Vector2(1.2, 0), Vector2(1.45, 0)]), 20, 1.0, 1.0,
		0.0, true, false)
	for s in [-1.0, 1.0]:
		var tc := Vector3(s * 8.0, 0, 14.0)
		lm.box("Stone", tc + Vector3(0, 8.5, 0), Vector3(4.0, 17.0, 4.0))
		for k in 3:
			lm.box("Marble", tc + Vector3(0, 5.5 * float(k + 1), 0), Vector3(4.3, 0.3, 4.3), Basis(), 0.0)
		lm.box("Marble", tc + Vector3(0, 17.2, 0), Vector3(4.5, 0.4, 4.5))
		lm.spire("Tile", tc + Vector3(0, 17.4, 0), 2.0, 3.2)
		lm.box("Gold", tc + Vector3(0, 21.1, 0), Vector3(0.12, 0.9, 0.12))
		lm.box("Gold", tc + Vector3(0, 21.3, 0), Vector3(0.5, 0.1, 0.12))
		for f in 4:
			var a := PI * 0.5 * float(f)
			var d := Vector3(sin(a), 0, cos(a))
			var o := tc + d * 2.0 + Vector3(0, 12.6, 0)
			SEuUtil.opening(lm, "Shadow", o + d * 0.03, Vector3.UP.cross(d), Vector3.UP, 1.4, 3.6)
			LandmarkDetail.arch(lm, "Marble", o + Vector3(0, 3.6 - 0.7, 0), d, 1.4, 0.22, 0.15)
			for t in [-1.0, 1.0]:
				lm.box("Marble", o + Vector3.UP.cross(d) * float(t) * 1.15 + Vector3(0, 2.0, 0) + d * 0.08,
					Vector3(0.3, 4.0, 0.3), Basis.looking_at(-d))
			LandmarkDetail.window(lm, "Marble", "Glass", tc + d * 2.0 + Vector3(0, 8.0, 0), d, 0.8, 1.8, true, 0.15)
	lm.commit(model)
