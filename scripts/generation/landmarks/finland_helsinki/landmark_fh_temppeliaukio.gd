extends RefCounted

## The Rock Church (Temppeliaukion kirkko, Timo and Tuomo Suomalainen, 1969),
## Lutherinkatu 3, hewn into the granite outcrop with its floor at street
## level. Origin at the OSM footprint centre (registry yaw -9), the dome axis
## at (-1, -5.5), entrance building to the south.
##
## Measured: the outline (way 124143121, 40 x 54 m including the entrance
## tail) and the LoD2 top 9.6 m (the registry height is 8). Checked by eye
## against visual-plan/refs/temppeliaukio_church/: from outside only the rough
## rock rim, the rubble wall of pale grey and pink boulders, the green
## patinated copper dome with its meridian seams and the board-formed concrete
## entrance front show; the dome rests on 180 radial concrete beams with the
## glazed ring between them. Estimated: the dome radius and rise (24 m, 1 m
## above its rim), the rim heights, the entrance block's size, the boulders.
##
## Night: the rubble wall and dome are lit from the rock.
const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "temppeliaukio_church", "name": "Temppeliaukio Church", "lat": 60.17296, "lon": 24.92523,
	"radius_m": 5000.0, "wiki_title": "Temppeliaukio Church", "height_m": 9.0, "clear_m": 38.0,
	"yaw_deg": -9.0, "kind": "Church", "aliases": ["temppeliaukio church", "temppeliaukion kirkko", "rock church helsinki"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8C8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7C9A86", 2.0, 0.45, 0.4))
	lm.use("Seam", LandmarkMaterials.pbr("concrete", "#628072", 2.0, 0.45, 0.4))
	lm.use("Corten", LandmarkMaterials.paint("#7B3F26", 0.8, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A52"))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A39C94", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9A9892", 3.0))
	var c := Vector3(-1.0, 0, -5.5)
	# Rock outcrop: an irregular rim of blasted granite rising to the dome.
	var rows: Array = []
	var radii := [23.5, 22.0, 20.0, 17.6, 15.2, 14.2]
	var hts := [0.0, 1.6, 3.2, 4.4, 5.0, 5.1]
	for j in radii.size():
		var row := PackedVector3Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			var n := 1.0 + 0.07 * sin(a * 5.0 + float(j)) + 0.05 * sin(a * 11.0 + 1.7 * float(j)) \
				+ 0.03 * sin(a * 23.0)
			var hn := float(hts[j]) * (1.0 + 0.12 * sin(a * 7.0 + float(j) * 0.7))
			row.append(c + Vector3(cos(a) * float(radii[j]) * n * 0.95, minf(hn, 5.1), sin(a) * float(radii[j]) * n * 1.1))
		rows.append(row)
	lm.grid("Rock", rows, c + Vector3(0, -20.0, 0), true)
	# Boulders strewn on the rim.
	for k in 16:
		var a := TAU * float(k) / 16.0 + 0.2
		var r := 17.0 + 3.0 * sin(float(k) * 2.1)
		lm.lathe("Rock", c + Vector3(cos(a) * r * 0.95, 3.0 + 0.6 * sin(float(k)), sin(a) * r * 1.1),
			FhU.ball(0.7 + 0.4 * absf(sin(float(k) * 1.3))), 7, 1.4, 1.0, float(k))
	# Rubble wall ringing the hall, laid from the blasted stone.
	lm.frustum("Rock", c + Vector3(0, 4.6, 0), 14.6, 14.2, 0.9, 40)
	for k in 60:
		var a := TAU * float(k) / 60.0
		lm.box("Granite", c + Vector3(cos(a), 0, sin(a)) * 14.4 + Vector3(0, 5.2 + 0.15 * sin(float(k) * 1.7), 0),
			Vector3(1.4, 0.55, 0.9), Basis(Vector3.UP, -a), 0.12)
	# Ring beam, the glazed band between 180 radial beams, the copper dome
	# with its concentric strips.
	lm.frustum("Concrete", c + Vector3(0, 5.5, 0), 13.8, 13.4, 0.6, 48)
	lm.frustum("Glass", c + Vector3(0, 6.1, 0), 12.9, 12.6, 0.8, 48)
	for k in 180:
		var a := TAU * float(k) / 180.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Concrete", c + d * 12.9 + Vector3(0, 6.5, 0), Vector3(0.12, 0.8, 1.6), Basis(Vector3.UP, -a), 0.0)
	lm.lathe("Copper", c + Vector3(0, 6.9, 0), PackedVector2Array([Vector2(13.4, 0), Vector2(12.0, 0.25),
		Vector2(9.5, 0.6), Vector2(6.5, 0.85), Vector2(3.5, 1.0), Vector2(0, 1.08)]), 48)
	for k in 72:
		var a := TAU * float(k) / 72.0
		var d := Vector3(cos(a), 0.0, sin(a))
		var prev := c + d * 13.4 + Vector3(0, 6.9 + 0.02, 0)
		for r in [11.0, 8.2, 5.2, 2.2]:
			var y := 6.9 + 1.08 * (1.0 - pow(float(r) / 13.4, 2.0)) + 0.03
			var q := c + d * float(r) + Vector3(0, y, 0)
			lm.beam("Seam", prev, q, 0.07, 0.04, Vector3.UP)
			prev = q
	lm.frustum("Copper", c + Vector3(0, 7.95, 0), 1.2, 1.0, 0.08, 16)
	# Granite entrance building to the south, its copper-roofed porch and steps.
	FhU.blk(lm, "Concrete", 7.0, 0.0, 19.5, 14.0, 4.6, 10.0)
	FhU.blk(lm, "Concrete", 7.0, 4.6, 19.5, 14.6, 0.5, 10.6)
	FhP.pierce(lm, "Granite", "Glass", Vector3(0.0, 0, 24.5), Vector3(14.0, 0, 24.5), Vector3(0, 0, 1), 0.0, 4.6, 5, 1,
		Vector2(1.6, 1.4), 2.4, 3.0, 0.25)
	lm.quad("Glass", Vector3(5.0, 0.0, 24.81), Vector3(9.0, 0.0, 24.81), Vector3(9.0, 3.2, 24.81),
		Vector3(5.0, 3.2, 24.81), Vector3(0, 0, 1))
	lm.box("Copper", Vector3(7.0, 3.6, 26.4), Vector3(7.0, 0.3, 3.6))
	for x in [4.0, 10.0]:
		lm.frustum("Concrete", Vector3(float(x), 0.0, 27.8), 0.2, 0.2, 3.45, 10)
	FhU.blk(lm, "Granite", -3.0, 0.0, 15.0, 6.0, 3.4, 4.0)
	# The rust-brown cross standing on the rim.
	FhU.blk(lm, "Corten", -12.0, 5.0, -16.0, 0.5, 3.4, 0.5)
	FhU.blk(lm, "Corten", -12.0, 7.2, -16.0, 2.0, 0.5, 0.5)
	lm.commit(model)
	D.flood(model, [
		[Vector3(-24.0, 0.5, 20.0), Vector3(-2.0, 5.0, -5.0), 55.0, 0.8, 45.0, Color(1.0, 0.92, 0.78)],
		[Vector3(22.0, 0.5, -26.0), Vector3(0.0, 5.0, -5.0), 55.0, 0.8, 45.0, Color(1.0, 0.92, 0.78)]])
