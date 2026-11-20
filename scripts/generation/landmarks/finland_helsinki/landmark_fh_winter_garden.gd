extends RefCounted

## Helsinki Winter Garden (Talvipuutarha, Gustaf Nyström, 1893), Eläintarha
## park. Origin at the centroid of OSM way 127286563 (818 m2, 60.186119 N
## 24.931643 E), yaw 205.6 so the long glass wing runs along X and the
## portico of the central pavilion faces +Z (it opens to the garden terrace).
##
## From the photographs (visual-plan/refs/landmarks/winter_garden_helsinki/):
## - A white-framed glass house: a tall central pavilion with a two-stage
##   gable, framed in a lattice of white mullions and transoms, with a small
##   gabled portico on slender columns and a finial on the ridge.
## - Two long low glass wings on either side under glazed pitched roofs
##   with ridge vents, on a low stone base.
## - A stepped stone terrace and garden stair before the portico.
##
## Measured: the plan (OSM outline simplified to 0.7 m: wings 9.8 m deep, the
## pavilion 15 x 9 m, the portico 7 x 6.5 m, the back annex) and the position
## (the registry's earlier point was 450 m away). Estimated: 15.5 m
## to the finial, 6 m to the transept eaves, wing roof pitch, mullion
## spacing, terrace steps.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "winter_garden_helsinki", "name": "Helsinki Winter Garden", "lat": 60.186119, "lon": 24.931643,
	"radius_m": 1500.0, "wiki_title": "Helsinki Winter Garden", "height_m": 15.5, "clear_m": 30.0,
	"yaw_deg": 205.6, "kind": "Glasshouse", "aliases": ["helsinki winter garden", "talvipuutarha", "vinterträdgården helsingfors"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.paint("#B4CED6", 0.15, 0.25))
	lm.use("Frame", LandmarkMaterials.paint("#EEF0EC", 0.5, 0.15))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8B84", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A5A44", 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#6E7274", 0.65, 0.3))
	lm.use("Column", LandmarkMaterials.paint("#EEF0EC", 0.5, 0.1))
	# Stone base under everything, the back annex in brick.
	U.blk(lm, "Stone", -3.9, 0.0, -3.0, 59.0, 0.9, 11.0)
	U.blk(lm, "Stone", 0.0, 0.0, 6.4, 16.0, 0.9, 10.2)
	U.blk(lm, "Brick", 0.0, 0.0, -10.2, 14.0, 4.2, 4.6)
	U.blk(lm, "Roof", 0.0, 4.2, -10.2, 14.6, 0.3, 5.2)
	# Wings: glass walls and a glazed pitched roof with a vent ridge.
	for w in [[-33.2, -7.6], [7.5, 25.3]]:
		var cx: float = (w[0] + w[1]) * 0.5
		var len: float = w[1] - w[0]
		_hall(lm, cx, -3.1, len, 9.8, 3.7, 2.7, true)
		U.blk(lm, "Frame", cx, 7.0, -3.1, len, 0.3, 0.3)
	# Central pavilion: lower transept gable, then the tall upper gable.
	_hall(lm, 0.0, 6.4, 15.2, 9.1, 6.0, 4.0, false)
	_hall(lm, 0.0, 6.4, 8.6, 9.1, 3.5, 4.0, false, 6.9)
	lm.beam("Frame", Vector3(0.0, 14.3, 6.4), Vector3(0.0, 15.5, 6.4), 0.14)
	# Portico: four slender columns, entablature, small pediment.
	for x in [-3.0, -1.0, 1.0, 3.0]:
		lm.frustum("Column", Vector3(x, 0.9, 16.4), 0.16, 0.14, 3.4, 10)
	U.blk(lm, "Column", 0.0, 4.3, 14.2, 7.2, 0.4, 5.4)
	U.ridge_z(lm, "Column", "Column", Vector3(0.0, 4.7, 14.2), 7.4, 5.6, 1.5, 0.1)
	U.blk(lm, "Stone", 0.0, 0.0, 14.2, 7.6, 0.9, 6.4)
	# Terrace stair in front.
	U.steps(lm, "Stone", Vector3(0.0, 0.0, 17.4), Vector3(0, 0, 1), 7.0, 0.4, 0.15, 6)
	lm.commit(model)

## One glazed hall: walls `wall_h` high from the plinth (or from `y0` above
## it) with white mullions and transoms, and a glazed gable roof rising
## `rise` over its length axis (X for wings, Z for the pavilion).
static func _hall(lm: LandmarkMesh, cx: float, cz: float, w: float, d: float, wall_h: float, rise: float,
		along_x: bool, y0: float = 0.9) -> void:
	var base := Vector3(cx, y0, cz)
	var wall := wall_h
	if along_x:
		lm.box("Glass", base + Vector3(0, wall * 0.5, 0), Vector3(w, wall, d), Basis(), 0.0)
		U.ridge_x(lm, "Glass", "Glass", base + Vector3(0, wall, 0), w, d, rise, 0.25)
	else:
		lm.box("Glass", base + Vector3(0, wall * 0.5, 0), Vector3(w, wall, d), Basis(), 0.0)
		U.ridge_z(lm, "Glass", "Glass", base + Vector3(0, wall, 0), w, d, rise, 0.25)
	for face in FhP.faces(cx, cz, w + 0.04, d + 0.04):
		var a: Vector3 = face[0]
		var b: Vector3 = face[1]
		var o: Vector3 = face[2]
		FhP.ribs(lm, "Frame", a, b, o, y0, y0 + wall, 1.25, 0.09, 0.08)
		for k in int(wall / 1.6):
			FhP.band(lm, "Frame", a, b, o, y0 + 1.5 + 1.6 * float(k), 0.07, 0.08)
		FhP.band(lm, "Frame", a, b, o, y0 + wall - 0.12, 0.2, 0.1)
	# Rafters over the glazed roof.
	var n := maxi(int((w if along_x else d) / 1.5), 2)
	for i in n + 1:
		var t := float(i) / float(n)
		if along_x:
			var x := cx - w * 0.5 + w * t
			lm.beam("Frame", Vector3(x, y0 + wall, cz - d * 0.5 - 0.25), Vector3(x, y0 + wall + rise, cz), 0.08)
			lm.beam("Frame", Vector3(x, y0 + wall, cz + d * 0.5 + 0.25), Vector3(x, y0 + wall + rise, cz), 0.08)
		else:
			var z := cz - d * 0.5 + d * t
			lm.beam("Frame", Vector3(cx - w * 0.5 - 0.25, y0 + wall, z), Vector3(cx, y0 + wall + rise, z), 0.08)
			lm.beam("Frame", Vector3(cx + w * 0.5 + 0.25, y0 + wall, z), Vector3(cx, y0 + wall + rise, z), 0.08)
