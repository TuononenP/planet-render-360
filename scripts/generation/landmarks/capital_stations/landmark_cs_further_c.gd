class_name LandmarkCsFurtherC
extends RefCounted

## The last capital stations hand-built after the photo review, in the
## station frame (+X along the main facade, +Z the forecourt): Ottawa,
## Podgorica, Skopje, Tbilisi Central, Monaco-Monte-Carlo's entrance,
## Ouagadougou, Abuja Idu, Bamako and Manila's Tutuban.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Ottawa station (John B. Parkin, 1966): the low glass hall under its deep
## black steel roof, a space frame of trusses carried out far over the
## forecourt, and the raised clerestory over the middle.
static func ottawa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E4E6E6", "#D8DADA", "sheet_metal", "#2B2B2B", "#222426")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#9DB4C0", 6.0, 0.2, 0.3))
	lm.box("Curtain", Vector3(0, 4.0, -6.0), Vector3(118.0, 8.0, 64.0))
	LandmarkFhParts.strips(lm, "Steel", Vector3(-58.5, 0, 26.05), Vector3(58.5, 0, 26.05), Vector3.BACK, 0.0, 8.0, 40,
		0.2, 0.15)
	# The roof: a top and bottom chord with the truss diagonals between.
	lm.box("Roof", Vector3(0, 12.6, -4.0), Vector3(134.0, 0.6, 84.0))
	lm.box("Steel", Vector3(0, 8.4, -4.0), Vector3(132.0, 0.4, 82.0))
	lm.box("Walls", Vector3(0, 10.4, 37.9), Vector3(134.0, 3.6, 0.3))
	for i in 34:
		var x := -66.0 + 4.0 * float(i)
		for z in [36.0, 20.0, -10.0, -44.0]:
			lm.beam("Steel", Vector3(x, 8.6, z), Vector3(x + 2.0, 12.3, z), 0.25, 0.25)
			lm.beam("Steel", Vector3(x + 2.0, 12.3, z), Vector3(x + 4.0, 8.6, z), 0.25, 0.25)
	# The clerestory.
	lm.box("Curtain", Vector3(0, 15.0, -6.0), Vector3(40.0, 4.2, 40.0))
	lm.box("Roof", Vector3(0, 17.4, -6.0), Vector3(44.0, 0.6, 44.0))
	lm.commit(model)

## Podgorica station (1970s): the long ochre concrete slab of three storeys
## with strip windows, its glazed ground floor under a concrete canopy, and
## the taller block at the east end.
static func podgorica(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#C9A46A", "#D8C29A", "concrete", "#A89C86")
	lm.box("Walls", Vector3(-8.0, 5.5, 0.0), Vector3(146.0, 11.0, 14.0))
	lm.box("Trim", Vector3(-8.0, 11.2, 0.0), Vector3(146.6, 0.4, 14.6))
	for y in [5.2, 8.4]:
		LandmarkFhParts.band(lm, "Glass", Vector3(-80.0, 0, 7.0), Vector3(64.0, 0, 7.0), Vector3.BACK, y, 1.5, 0.08)
	lm.box("Glass", Vector3(-8.0, 1.8, 7.05), Vector3(140.0, 3.4, 0.2))
	K.canopy(lm, "Trim", "Trim", Vector3(-80.0, 0, 7.0), Vector3(64.0, 0, 7.0), Vector3.BACK, 4.0, 3.8, 12)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 73.0, 0.0, 18.0, 16.0, 0.0, 22.0, "flat", 0.0, 3.0, 3.2)
	lm.commit(model)

## Skopje station (Kenzo Tange, 1981): the raised raw-concrete deck on its
## rows of pylons, the platforms carried over the street, and the row of
## white barrel-vault roof units across it.
static func skopje(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#9A9690", "#B8B4AC", "concrete", "#EDEBE5")
	lm.box("Walls", Vector3(0, 9.0, 0.0), Vector3(92.0, 2.4, 36.0))
	lm.box("Trim", Vector3(0, 4.0, -2.0), Vector3(60.0, 8.0, 18.0))
	for i in 8:
		var x := -42.0 + 12.0 * float(i)
		for z in [-14.0, 14.0]:
			lm.box("Walls", Vector3(x, 4.0, z), Vector3(2.6, 8.0, 2.6))
	lm.box("Walls", Vector3(0, 12.0, 0.0), Vector3(90.0, 3.6, 34.0))
	for i in 7:
		var x := -39.0 + 13.0 * float(i)
		LandmarkFhHelsinkiCity._barrel(lm, "Roof", Vector3(x, 13.8, -17.5), Vector3(x, 13.8, 17.5), 6.2, 4.2)
	lm.commit(model)

## Tbilisi Central (1980s): the long podium of glass under a ribbed
## concrete canopy fascia, and the wide white block above it banded with
## horizontal ribbon windows, its plant rooms on top.
static func tbilisi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#E8E6E0", "#D4D0C6", "concrete", "#BDB8AE")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#7F96A6", 6.0, 0.2, 0.3))
	lm.box("Curtain", Vector3(0, 5.0, -6.0), Vector3(176.0, 10.0, 120.0))
	lm.box("Roof", Vector3(0, 10.3, -4.0), Vector3(180.0, 0.6, 128.0))
	lm.box("Walls", Vector3(0, 11.6, 58.0), Vector3(182.0, 3.4, 4.0))
	LandmarkFhParts.strips(lm, "Trim", Vector3(-90.0, 0, 60.05), Vector3(90.0, 0, 60.05), Vector3.BACK, 9.9, 3.4, 61,
		0.6, 0.6)
	# The block above.
	lm.box("Walls", Vector3(0, 19.0, 30.0), Vector3(54.0, 16.0, 16.0))
	for y in [13.5, 17.5, 21.5]:
		LandmarkFhParts.band(lm, "Glass", Vector3(-26.0, 0, 38.0), Vector3(26.0, 0, 38.0), Vector3.BACK, y, 1.6, 0.08)
	lm.box("Trim", Vector3(0, 27.2, 30.0), Vector3(55.0, 0.4, 17.0))
	lm.box("Walls", Vector3(0, 28.8, 30.0), Vector3(22.0, 3.0, 8.0))
	lm.commit(model)

## The street entrance of Monaco-Monte-Carlo station (1999, the platforms
## are underground): a pale stone wall with a broad glazed opening under a
## segmental arch, sun louvres across it, the doors at its foot.
static func monaco(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#E6DED0", "#EFE9DE", "concrete", "#D9D3C6")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#6F8796", 6.0, 0.2, 0.3))
	lm.box("Walls", Vector3(0, 7.0, -6.0), Vector3(64.0, 14.0, 20.0))
	lm.box("Trim", Vector3(0, 13.8, -6.0), Vector3(64.6, 0.4, 20.6))
	lm.box("Roof", Vector3(0, 14.05, -6.0), Vector3(64.0, 0.1, 20.0))
	var f := 4.3
	lm.box("Curtain", Vector3(0, 4.8, f), Vector3(40.0, 9.6, 0.2))
	K.lunette(lm, "Trim", "Curtain", Vector3(0, 9.6, f), Vector3.BACK, 40.0, 3.4, 12, 0)
	var y := 3.4
	while y < 12.6:
		var half := 20.0 if y <= 9.6 else 20.0 * sqrt(maxf(1.0 - pow((y - 9.6) / 3.4, 2.0), 0.0))
		lm.box("Steel", Vector3(0, y, f + 0.6), Vector3(half * 2.0, 0.08, 0.7))
		y += 0.8
	for k in 6:
		var x := -20.0 + 8.0 * float(k)
		lm.box("Steel", Vector3(x, 4.8, f + 0.3), Vector3(0.3, 9.6, 0.4))
	lm.box("Steel", Vector3(0, 3.2, f + 0.4), Vector3(40.0, 0.3, 0.6))
	lm.commit(model)

## Ouagadougou station (1934, front of the 1950s): the ochre two-storey
## range and its great cantilevered concrete hood over the forecourt, a
## deep vaulted soffit of ribs, carried at the ends on legs leaning in.
static func ouagadougou(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#C8874A", "#B4743E", "render", "#9A5A38")
	# The hood in render tiled large: at the usual scale its grain tinted
	# ochre reads as timber.
	lm.use("Shell", LandmarkMaterials.pbr("render", "#B97A44", 14.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -3.0, 62.0, 18.0, 0.0, 13.0, "flat", 0.0, 4.0, 4.5)
	var x0 := -24.0
	var x1 := 24.0
	var z0 := 6.0
	var depth := 13.0
	lm.box("Shell", Vector3(0, 13.6, z0 + depth * 0.5), Vector3(x1 - x0 + 2.0, 1.2, depth))
	lm.box("Shell", Vector3(0, 12.4, z0 + depth - 0.5), Vector3(x1 - x0 + 2.0, 2.4, 1.0))
	for i in 13:
		var x := x0 + (x1 - x0) * float(i) / 12.0
		var prev := Vector3(x, 7.0, z0 + 0.6)
		for k in range(1, 7):
			var t := float(k) / 6.0
			var p := Vector3(x, 13.0 - 6.0 * cos(t * PI * 0.5), z0 + t * depth)
			lm.beam("Shell", prev, p, 0.5, 0.9)
			prev = p
	for x in [x0 - 1.0, x1 + 1.0]:
		lm.beam("Shell", Vector3(x, 13.0, z0 + depth - 0.5), Vector3(x * 0.85, 0.0, z0 + depth + 2.0), 1.4, 1.4,
			Vector3.ZERO, true)
	lm.commit(model)

## Abuja Idu station (2018): low wings of dark glass in a grid under thin
## cantilevered slabs, and the clad stone entrance block rising above them,
## a deep frame round the glazed hall with its soffit over the doors.
static func abuja(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#D8D8D4", "#C8C8C2", "concrete", "#B8B8B2")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#3E4E5C", 6.0, 0.2, 0.3))
	for s in [-1.0, 1.0]:
		var cx: float = s * 52.0
		lm.box("Curtain", Vector3(cx, 7.0, -4.0), Vector3(76.0, 14.0, 34.0))
		LandmarkFhParts.strips(lm, "Steel", Vector3(cx - 37.5, 0, 13.05), Vector3(cx + 37.5, 0, 13.05), Vector3.BACK, 0.0,
			14.0, 26, 0.2, 0.15)
		for y in [4.8, 9.4]:
			LandmarkFhParts.band(lm, "Steel", Vector3(cx - 38.0, 0, 13.0), Vector3(cx + 38.0, 0, 13.0), Vector3.BACK, y, 0.3,
				0.15)
		lm.box("Walls", Vector3(cx, 14.4, -2.0), Vector3(80.0, 0.8, 40.0))
	# The entrance block: piers, head and side walls, hollow round the hall.
	lm.box("Curtain", Vector3(0, 9.0, -2.0), Vector3(16.0, 18.0, 30.0))
	for s in [-1.0, 1.0]:
		lm.box("Walls", Vector3(s * 10.5, 12.0, 0.0), Vector3(5.0, 24.0, 36.0))
	lm.box("Walls", Vector3(0, 21.0, 0.0), Vector3(16.0, 6.0, 36.0))
	lm.box("Trim", Vector3(0, 17.9, 14.0), Vector3(16.0, 0.2, 8.0))
	lm.commit(model)

## Bamako station (1913): the ochre laterite range of two storeys with its
## string courses, the blue tiled name band across the front, and the
## centre gable with scrolled shoulders framing the round clock under a
## small pediment.
static func bamako(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "stone", "#C98E5E", "#D9A878", "concrete", "#A8806A")
	lm.use("Tile", LandmarkMaterials.pbr("render", "#3E78A8", 2.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 76.0, 34.0, 0.0, 10.0, "flat", 0.0, 4.0, 4.6, true)
	LandmarkFhParts.box_band(lm, "Trim", 0.0, -2.0, 76.0, 34.0, 5.0, 0.4, 0.2)
	lm.box("Tile", Vector3(0, 7.6, 15.1), Vector3(22.0, 1.0, 0.2))
	# The centre gable: a raised panel between scrolled shoulders.
	lm.box("Walls", Vector3(0, 12.5, 14.6), Vector3(10.0, 5.0, 1.0))
	lm.box("Trim", Vector3(0, 15.2, 14.6), Vector3(11.0, 0.5, 1.4))
	LandmarkFhUtil.hip(lm, "Trim", Vector3(0, 15.4, 14.6), 11.0, 1.4, 1.2)
	# The scrolled shoulders as solid quarter-wedges either side.
	for s in [-1.0, 1.0]:
		for k in 3:
			var hh := 2.4 - 0.8 * float(k)
			lm.box("Walls", Vector3(s * (5.6 + 1.2 * float(k)), 10.0 + hh * 0.5, 14.6), Vector3(1.2, hh, 1.0))
	K.clock(lm, "Dial", "Trim", Vector3(0, 12.6, 15.15), Vector3.BACK, 1.4)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.2, 15.05), Vector3.BACK, 4.0, 6.0, 3)
	lm.commit(model)

## Tutuban, Manila (1887): the long range with its red brick ground floor
## of arched openings, the cream timber upper storey with louvred windows
## behind a veranda, the hipped red-brown roofs and the gabled pediment
## over the centre.
static func tutuban(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#A3473A", "#EFE6CC", "terracotta", "#8C4A3A")
	lm.use("Upper", LandmarkMaterials.pbr("render", "#EDE3C4", 3.0))
	lm.box("Walls", Vector3(0, 3.0, 0.0), Vector3(104.0, 6.0, 28.0))
	K.arch_row(lm, "Trim", "Glass", Vector3(-50.0, 0, 14.05), Vector3(50.0, 0, 14.05), Vector3.BACK, 0.4, 20, 2.6, 4.6, 1)
	lm.box("Trim", Vector3(0, 6.2, 0.0), Vector3(104.8, 0.4, 28.8))
	lm.box("Upper", Vector3(0, 9.0, -1.0), Vector3(102.0, 5.6, 26.0))
	LandmarkFhUtil.window_grid(lm, "Glass", Vector3(-49.0, 0, 12.05), Vector3(49.0, 0, 12.05), Vector3.BACK, 7.4, 1, 3.0,
		26, 2.0, 3.0)
	# The veranda: a balustrade on posts under the eaves.
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-51.0, 6.4, 14.2), Vector3(51.0, 6.4, 14.2), 0.6, 0.12, 1.0, 0.12)
	lm.box("Trim", Vector3(0, 7.45, 14.2), Vector3(102.0, 0.1, 0.3))
	for i in 18:
		lm.box("Trim", Vector3(-51.0 + 6.0 * float(i), 9.2, 14.2), Vector3(0.3, 5.6, 0.3))
	K.hip_roof(lm, "Roof", Vector3(0, 11.8, 0.5), 106.0, 30.0, 4.0)
	# The centre pediment.
	K.block(lm, "Upper", "Trim", "Glass", "Roof", 0.0, 2.0, 18.0, 28.0, 6.4, 6.0, "gable_z", 4.2, 3.0, 3.0)
	lm.commit(model)
