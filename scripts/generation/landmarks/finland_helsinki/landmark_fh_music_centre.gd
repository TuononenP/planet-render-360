extends RefCounted

## helsinki_music_centre. Registry entry and model in one file.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "helsinki_music_centre", "skyline_priority": 1, "name": "Helsinki Music Centre", "lat": 60.17379, "lon": 24.93492,
	"radius_m": 5000.0, "wiki_title": "Helsinki Music Centre", "height_m": 21.1, "clear_m": 66.0,
	"yaw_deg": 64.0, "kind": "Concert hall", "aliases": ["helsinki music centre", "musiikkitalo",
		"helsingin musiikkitalo", "musikhuset helsingfors"]}

## From the Commons photos (visual-plan/refs/landmarks/helsinki_music_centre/):
## the hall volumes are clad in teal-green pre-patinated copper, in four
## rows of ribbon windows on the east block; the glass foyer is lower than
## the block. Measured: outline (OSM way 58023634) and the 21.1 m top (LoD2).
## Estimated: the foyer height (15-16.5 m) and window spacing.
##
## Marko Kivistö / LPR's Musiikkitalo (2011), origin at the OSM footprint
## centre, front +Z toward the Parliament across Mannerheimintie (the
## registry yaw turns it west-south-west): bronze-copper hall volumes
## behind the full-height glass foyer, granite steps and the roof held
## to the height of its neighbours.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Metal", LandmarkMaterials.pbr("concrete", "#2F7360", 2.5, 0.45, 0.55))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#235A4B", 2.5, 0.5, 0.4))
	lm.use("Glass", LandmarkMaterials.paint("#4F858D", 0.2, 0.5))
	lm.use("Frame", LandmarkMaterials.paint("#7C8A8C", 0.5, 0.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8782", 4.0))
	var base := PackedVector2Array([Vector2(-42.6, -32.1), Vector2(-7.5, -43.5), Vector2(51.2, -33.6),
		Vector2(43.5, 10.8), Vector2(43.0, 14.0), Vector2(-29.2, 14.0)])
	lm.poly_prism("Metal", base, 0.0, 17.0)
	lm.poly_prism("Dark", PackedVector2Array([Vector2(-36.0, -29.0), Vector2(-7.0, -38.0), Vector2(44.0, -30.0),
		Vector2(38.0, 4.0), Vector2(-14.0, 6.0)]), 17.0, 20.0)
	# The concert hall box on top, the roof held at 22 m.
	FhU.blk(lm, "Metal", 4.0, 19.1, -13.0, 38.0, 2.0, 30.0)
	# Glass foyer along the whole front: mullioned wall, frame and roof.
	var fx0 := -24.0
	var fx1 := 41.0
	FhU.wedge(lm, "Glass", "Frame", fx0, fx1, 14.0, 37.6, 0.0, 16.5, 15.0)
	for i in 21:
		var x := fx0 + (fx1 - fx0) * float(i) / 20.0
		lm.box("Frame", Vector3(x, 7.5, 37.7), Vector3(0.35, 15.0, 0.45))
	for k in 4:
		lm.box("Frame", Vector3((fx0 + fx1) * 0.5, 4.0 + 4.2 * float(k), 37.7), Vector3(fx1 - fx0, 0.3, 0.45))
	FhU.steps(lm, "Granite", Vector3(9.0, 0.0, 38.2), Vector3(0, 0, 1), 56.0, 0.8, 0.2, 5)
	# Windows on the side walls.
	FhU.wall_run(lm, "Glass", Vector2(-41.26, -27.49), Vector2(-30.54, 9.39), Vector2.ZERO, 4.5, 3, 4.2, 7, 3.2, 1.2)
	FhU.wall_run(lm, "Glass", Vector2(50.43, -29.16), Vector2(44.27, 6.36), Vector2.ZERO, 4.5, 3, 4.2, 6, 3.2, 1.2)
	FhU.wall_run(lm, "Glass", Vector2(-1.63, -42.5), Vector2(45.3, -34.6), Vector2.ZERO, 4.5, 3, 4.2, 10, 3.2, 1.2)
		# Hall volume rising on the slanted outline over the base.
	var hall := PackedVector2Array([Vector2(-36.0, -28.5), Vector2(-10.5, -26.8), Vector2(34.4, -18.8),
		Vector2(30.5, 9.0), Vector2(-28.0, 10.5)])
	lm.poly_prism("Metal", hall, 17.0, 20.6)
	# Pre-patinated copper skin: standing seams and panel joints.
	for i in base.size():
		var p := base[i]
		var q := base[(i + 1) % base.size()]
		if p.distance_to(q) > 10.0:
			var o := FhP.edge_out(base, i)
			FhP.ribs(lm, "Dark", Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), o, 0.0, 17.0, 2.4, 0.12, 0.08)
			for y in [5.6, 11.3]:
				FhP.band(lm, "Dark", Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), o, y, 0.12, 0.08)
	for i in hall.size():
		var p := hall[i]
		var q := hall[(i + 1) % hall.size()]
		FhP.ribs(lm, "Dark", Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), FhP.edge_out(hall, i), 17.0, 20.6, 2.4,
			0.12, 0.08)
	# Foyer glazing grid: more transoms, the roof fascia and the entrance canopy.
	for k in 8:
		lm.box("Frame", Vector3((fx0 + fx1) * 0.5, 2.0 + 2.1 * float(k), 37.75), Vector3(fx1 - fx0, 0.12, 0.3),
			Basis(), 0.0)
	FhP.band(lm, "Frame", Vector3(fx0, 0, 37.6), Vector3(fx1, 0, 37.6), Vector3(0, 0, 1), 14.6, 0.6, 0.6)
	for x in [fx0, fx1]:
		FhP.ribs(lm, "Frame", Vector3(x, 0, 14.5), Vector3(x, 0, 37.4), Vector3(signf(x - 9.0), 0, 0), 0.0, 15.0,
			2.9, 0.3, 0.3)
	lm.box("Frame", Vector3(9.0, 4.4, 40.0), Vector3(22.0, 0.35, 4.4))
	lm.commit(model)
