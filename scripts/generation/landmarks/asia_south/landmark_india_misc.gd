class_name LandmarkIndiaMisc
extends RefCounted

## Four Indian landmarks in true metres: the Gateway of India, the Hawa
## Mahal, the Charminar and the Lotus Temple. Fronts face +Z (south).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Gateway of India (26 m): yellow basalt Indo-Saracenic arch with the
## central dome on an octagonal drum, four corner turrets and low wings.
static func gateway_of_india(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Basalt", LandmarkMaterials.pbr("stone", "#B79B6A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D2BE96", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4F4638", 3.0))
	lm.box("Trim", Vector3(0, 0.0, 0), Vector3(66.0, 2.0, 32.0))
	U.arch_wall(lm, "Basalt", Vector3(0, 1.0, 0), Basis(), 26.0, 18.0, 17.0, 9.0, 15.0)
	lm.box("Trim", Vector3(0, 19.6, 0), Vector3(28.0, 1.2, 19.0))
	lm.frustum("Basalt", Vector3(0, 20.2, 0), 7.4, 7.4, 2.2, 8, PI / 8.0)
	U.dome(lm, "Trim", Vector3(0, 22.4, 0), 7.0, 3.6, 24)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 13.0, 1.0, sz * 8.0)
			lm.frustum("Basalt", p, 2.1, 1.9, 20.5, 8, PI / 8.0)
			lm.frustum("Trim", p + Vector3(0, 19.0, 0), 2.6, 2.6, 1.0, 8, PI / 8.0)
			U.onion(lm, "Trim", p + Vector3(0, 21.5, 0), 2.2, 2.8, 12)
		# Low wing hall beside the arch, with dark windows.
		lm.box("Basalt", Vector3(sx * 22.5, 5.0, 0), Vector3(17.0, 8.0, 13.0))
		lm.box("Trim", Vector3(sx * 22.5, 9.3, 0), Vector3(18.0, 0.8, 14.0))
		for sz in [-1.0, 1.0]:
			for k in 3:
				lm.box("Recess", Vector3(sx * 22.5 + (float(k) - 1.0) * 4.5, 5.0, sz * 6.6),
					Vector3(2.0, 4.0, 0.2))
	for sz in [-1.0, 1.0]:
		for sx in [-1.0, 1.0]:
			lm.box("Recess", Vector3(sx * 9.5, 11.0, sz * 8.6), Vector3(2.4, 5.0, 0.2))
	lm.commit(model)

## Hawa Mahal (15 m): the pink sandstone "palace of winds", five stepped
## floors of projecting latticed oriels (jharokhas) under pyramid caps,
## with kiosks on the crest. Faces +Z; the real facade looks east.
static func hawa_mahal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#D4876E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EBD9C4", 3.0))
	lm.use("Lattice", LandmarkMaterials.pbr("stone", "#5C3B30", 2.0))
	# width, depth, floor height
	var floors := [[44.0, 11.0, 3.4], [38.0, 8.0, 3.0], [26.0, 6.0, 2.8], [18.0, 5.0, 2.4],
		[11.0, 4.0, 1.8]]
	var y := 0.0
	for f in floors:
		var w: float = f[0]
		var d: float = f[1]
		var h: float = f[2]
		lm.box("Pink", Vector3(0, y + h * 0.5, 0), Vector3(w, h, d))
		lm.box("Trim", Vector3(0, y + h, 0.0), Vector3(w + 0.6, 0.3, d + 0.6))
		var bays := int(w / 3.2)
		for k in bays:
			var x := -w * 0.5 + w * (float(k) + 0.5) / bays
			lm.box("Trim", Vector3(x, y + h * 0.5, d * 0.5 + 0.4), Vector3(2.5, h * 0.78, 0.9))
			lm.box("Lattice", Vector3(x, y + h * 0.5, d * 0.5 + 0.9), Vector3(1.6, h * 0.55, 0.15))
			lm.spire("Pink", Vector3(x, y + h * 0.89 + 0.1, d * 0.5 + 0.4), 1.25, 0.8, 0.1)
		y += h
	U.chhatri(lm, "Trim", "Pink", Vector3(0, y, 0), 3.4, 0.4, 0.7)
	for sx in [-1.0, 1.0]:
		U.chhatri(lm, "Trim", "Pink", Vector3(sx * 6.5, 11.6, 0), 3.0, 0.4, 0.7)
		U.chhatri(lm, "Trim", "Pink", Vector3(sx * 11.0, 9.2, 0), 3.0, 0.4, 0.7)
		U.chhatri(lm, "Trim", "Pink", Vector3(sx * 17.0, 6.4, 0), 3.0, 0.4, 0.7)
	lm.commit(model)

## Charminar (56 m): the four-arched granite and lime-mortar gateway with
## an arcaded gallery and mosque floor on top and a round minaret at
## each corner, each ringed by balconies and capped by a bulb dome.
static func charminar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#CBBFA6", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B9183", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#524A40", 2.0))
	lm.box("Granite", Vector3(0, 0.25, 0), Vector3(40.0, 2.5, 40.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.arch_wall(lm, "Stucco", b * Vector3(0, 1.5, 12.0), b, 30.0, 20.0, 6.0, 12.0, 15.0)
		# Arcaded gallery and mosque floor: rows of dark arched bays.
		for k in 5:
			var x := -9.6 + 4.8 * float(k)
			lm.box("Recess", b * Vector3(x, 25.0, 13.6), Vector3(2.4, 4.2, 0.3), b)
			lm.box("Recess", b * Vector3(x, 31.0, 13.6), Vector3(2.2, 4.0, 0.3), b)
		for k in 7:
			U.dome(lm, "Stucco", b * Vector3(-9.0 + 3.0 * float(k), 34.5, 14.0), 0.7, 1.0, 8, 3)
	lm.box("Stucco", Vector3(0, 21.8, 0), Vector3(30.0, 0.6, 30.0))
	lm.box("Stucco", Vector3(0, 28.0, 0), Vector3(27.0, 12.2, 27.0))
	lm.box("Stucco", Vector3(0, 34.2, 0), Vector3(30.0, 0.6, 30.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 15.0, 1.5, sz * 15.0)
			lm.frustum("Stucco", p, 3.4, 2.5, 49.0, 16)
			for y in [20.0, 27.0, 35.0, 43.0]:
				lm.lathe("Stucco", p + Vector3(0, y, 0), PackedVector2Array([Vector2(2.8, 0),
					Vector2(4.1, 0.6), Vector2(4.1, 1.4), Vector2(3.7, 1.4)]), 16)
			lm.frustum("Stucco", p + Vector3(0, 49.0, 0), 2.0, 2.0, 2.2, 12)
			U.onion(lm, "Stucco", p + Vector3(0, 51.2, 0), 2.6, 3.0, 16)
			U.finial(lm, "Stucco", p + Vector3(0, 54.0, 0), 0.5, 0.12)
	lm.commit(model)

## Lotus Temple (34.3 m): 27 free-standing marble petals in nine groups
## of three (entrance, outer and inner leaves), the inner ones leaning
## together over the central hall; reflecting pool round the base.
static func lotus_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EEEBE3", 3.0))
	lm.use("Core", LandmarkMaterials.pbr("limestone", "#CBC6BA", 3.0))
	lm.use("Pool", LandmarkMaterials.pbr("concrete", "#6C9097", 4.0, 0.12))
	lm.disc("Pool", Vector3(0, -0.3, 0), Vector3.UP, 58.0, 36)
	lm.frustum("Core", Vector3(0, -0.6, 0), 41.0, 40.0, 1.0, 36)
	lm.lathe("Core", Vector3.ZERO, PackedVector2Array([Vector2(17.0, 0), Vector2(17.0, 12.0),
		Vector2(12.0, 24.0), Vector2(4.0, 30.0), Vector2(0.0, 31.0)]), 27)
	# base radius, tip radius, height, base width: entrance, outer, inner leaves
	var leaves := [[38.0, 25.0, 12.0, 24.0], [31.0, 13.0, 22.0, 20.0], [22.0, 3.0, 34.3, 16.0]]
	for i in 9:
		var a := TAU * float(i) / 9.0
		for lf in leaves:
			_petal(lm, a, float(lf[0]), float(lf[1]), float(lf[2]), float(lf[3]))
	lm.commit(model)

## One curved shell leaf at azimuth `a`: vertical at the foot, leaning
## in toward the tip at radius r1, narrowing from w0 to a point.
static func _petal(lm: LandmarkMesh, a: float, r0: float, r1: float, h: float, w0: float) -> void:
	var dir := Vector3(cos(a), 0, sin(a))
	var tang := Vector3(-sin(a), 0, cos(a))
	var rows: Array = []
	for j in 13:
		var t := float(j) / 12.0
		var r := lerpf(r0, r1, t * t)
		var w := lerpf(w0, 0.3, pow(t, 2.4))
		var row := PackedVector3Array()
		for i in 7:
			var s := -1.0 + 2.0 * float(i) / 6.0
			var bulge := w * 0.2 * (1.0 - s * s)
			row.append(dir * (r + bulge) + tang * (s * w * 0.5) + Vector3(0, h * t, 0))
		rows.append(row)
	lm.grid("Marble", rows, Vector3.ZERO, true)
