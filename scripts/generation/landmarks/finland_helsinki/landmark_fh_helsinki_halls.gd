class_name LandmarkFhHelsinkiHalls
extends RefCounted

## Three concert and congress halls on Töölönlahti in true metres:
## Finlandia Hall (Aalto, white Carrara marble), the Finnish National
## Opera and Ballet (white granite and glass) and the Helsinki Music
## Centre (glass foyer in front of bronze-copper volumes). Footprints are
## the OpenStreetMap outlines in the model frame the registry yaw turns
## onto the map.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

# --- Finlandia Hall ---------------------------------------------------

## Aalto's Finlandia Hall (1971, congress wing 1975), origin at the OSM
## footprint centre, x along the 200 m long axis (north-north-west to
## south-south-east), front +Z on the Mannerheimintie side: the marble
## base, the tower-like concert hall volume with its sloping roof and the
## black trapezium on the bay wall, the wedge of the congress wing and the
## covered walk along the bay.
static func finlandia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE7E0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#DAD7D0", 3.0))
	lm.use("Black", LandmarkMaterials.pbr("concrete", "#1E1E20", 3.0, 0.5, 0.1))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E8A78", 2.0, 0.5, 0.3))
	var base := PackedVector2Array([Vector2(-58.9, 38.5), Vector2(-84.6, 2.4), Vector2(-81.0, -0.2),
		Vector2(-98.3, -24.7), Vector2(-57.2, -25.0), Vector2(-57.8, -28.0), Vector2(-40.4, -28.0),
		Vector2(-38.3, -25.1), Vector2(32.4, -25.4), Vector2(55.3, -25.8), Vector2(55.3, -28.3),
		Vector2(72.7, -28.5), Vector2(72.7, -26.7), Vector2(99.9, -26.0), Vector2(90.8, 0.4),
		Vector2(79.5, -2.7), Vector2(70.3, -1.7), Vector2(62.8, -1.0), Vector2(59.7, -5.5),
		Vector2(53.9, -4.0), Vector2(50.4, -6.5), Vector2(38.8, -2.9), Vector2(32.5, -2.9),
		Vector2(16.4, 1.3), Vector2(17.2, 4.9), Vector2(9.1, 7.1), Vector2(11.0, 14.2),
		Vector2(3.2, 17.7), Vector2(4.2, 22.0), Vector2(-52.9, 38.7)])
	lm.poly_prism("Marble", base, 0.0, 10.5)
	# Congress wing: a flat upper storey over the northern wedge.
	lm.poly_prism("Roof", PackedVector2Array([Vector2(-96.0, -23.0), Vector2(-58.5, -23.3),
		Vector2(-57.0, 36.0), Vector2(-83.0, 1.5), Vector2(-80.5, -0.8)]), 10.5, 14.0)
	# The concert hall tower, its roof falling toward the street side.
	FhU.wedge(lm, "Marble", "Roof", -14.0, 34.0, -25.7, 4.0, 0.0, 24.0, 14.0)
	lm.quad("Black", Vector3(-8.0, 4.0, -25.9), Vector3(30.0, 4.0, -25.9), Vector3(23.0, 21.0, -25.9),
		Vector3(-3.0, 21.0, -25.9), Vector3(0, 0, -1))
	# Auditorium fan on the south: lower stepped roof.
	lm.poly_prism("Roof", PackedVector2Array([Vector2(38.0, -24.0), Vector2(97.0, -25.0), Vector2(89.0, -3.0),
		Vector2(62.0, -3.0), Vector2(50.0, -6.0), Vector2(38.5, -3.8)]), 10.5, 15.0)
	# Foyer glazing along the street front and the entrance canopy.
	var ang := atan2(16.7, 57.1)
	var mid := Vector3(-24.35, 0.0, 30.35)
	var fb := Basis(Vector3.UP, ang)
	lm.box("Glass", mid + fb * Vector3(0, 4.0, 0.2), Vector3(58.0, 6.0, 0.3), fb)
	lm.box("Roof", mid + fb * Vector3(0, 7.4, 2.2), Vector3(60.0, 0.5, 6.0), fb)
	for i in 14:
		var t := (float(i) + 0.5) / 14.0
		lm.box("Marble", mid + fb * Vector3((t - 0.5) * 58.0, 3.5, 3.6), Vector3(0.6, 7.0, 0.6), fb)
	# Covered walk and slim columns on the bay side.
	lm.box("Roof", Vector3(-8.0, 4.5, -30.0), Vector3(95.0, 0.5, 6.0))
	FhU.columns(lm, "Marble", Vector3(-54.0, 0.0, -32.6), Vector3(38.0, 0.0, -32.6), 16, 4.3, 0.22, 8)
	# Ribbon windows along the bay wall west of the tower.
	FhU.wall_run(lm, "Glass", Vector2(-36.2, -25.11), Vector2(-17.1, -25.22), Vector2.ZERO, 4.5, 2, 3.0, 5, 3.0, 1.6)
	lm.commit(model)

# --- Finnish National Opera and Ballet ---------------------------------

## Hyvämäki-Karhunen-Parkkinen's house (1993), origin at the OSM footprint
## centre, front +Z toward the bay (the registry yaw turns it north-east):
## the white granite base, the auditorium block, the 32 m stage tower and
## the glass foyer whose roof falls to the water.
static func opera(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("limestone", "#E4E2DC", 3.0))
	lm.use("Band", LandmarkMaterials.pbr("limestone", "#C9C6BE", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#9B9892", 3.0))
	var base := PackedVector2Array([Vector2(66.6, 9.6), Vector2(44.5, 9.5), Vector2(-32.2, 8.8),
		Vector2(-45.8, 7.8), Vector2(-44.8, 0.4), Vector2(-59.0, -1.8), Vector2(-59.0, -22.4),
		Vector2(-54.1, -26.0), Vector2(-54.1, -31.8), Vector2(-49.7, -34.5), Vector2(-23.0, -34.3),
		Vector2(-22.9, -43.0), Vector2(22.7, -42.7), Vector2(22.6, -31.5), Vector2(58.0, -31.3),
		Vector2(57.1, -23.6), Vector2(64.8, -23.6), Vector2(64.8, -20.8), Vector2(61.9, -20.8),
		Vector2(61.9, -1.5), Vector2(69.1, -1.4), Vector2(68.5, 3.7), Vector2(66.6, 3.7)])
	lm.poly_prism("Granite", base, 0.0, 12.0)
	for k in 3:
		lm.poly_prism("Band", base, 3.0 + 4.0 * float(k), 3.5 + 4.0 * float(k), false)
	# Auditorium block and the stage tower rising behind it.
	FhU.blk(lm, "Granite", 5.0, 12.0, -12.0, 70.0, 10.0, 42.0)
	FhU.blk(lm, "Roof", 5.0, 22.0, -12.0, 71.0, 0.6, 43.0)
	FhU.blk(lm, "Granite", 7.4, 12.0, -5.9, 28.0, 19.4, 30.0)
	FhU.blk(lm, "Roof", 7.4, 31.4, -5.9, 28.8, 0.6, 30.8)
	FhU.window_grid(lm, "Glass", Vector3(-4.0, 0, -20.95), Vector3(20.0, 0, -20.95), Vector3(0, 0, -1), 24.0, 1,
			4.0, 4, 1.8, 5.0)
	# Glass foyer: tall at the auditorium, sloping down to the bay front.
	FhU.wedge(lm, "Glass", "Roof", -37.0, 44.0, 9.5, 34.4, 0.0, 17.0, 7.0)
	for i in 14:
		var x := -37.0 + 81.0 * float(i) / 13.0
		lm.box("Band", Vector3(x, 3.5, 34.45), Vector3(0.7, 7.0, 0.7))
	FhU.steps(lm, "Band", Vector3(3.0, 0.0, 34.5), Vector3(0, 0, 1), 40.0, 0.7, 0.2, 5)
	# Window rows on the back and west faces.
	FhU.window_grid(lm, "Glass", Vector3(-20.0, 0, -42.9), Vector3(20.0, 0, -42.9), Vector3(0, 0, -1), 3.0, 2,
			4.0, 8, 1.6, 2.4)
	FhU.wall_run(lm, "Glass", Vector2(-59.0, -20.0), Vector2(-59.0, -4.0), Vector2.ZERO, 3.0, 2, 4.0, 4, 1.6, 2.4)
	FhU.wall_run(lm, "Glass", Vector2(-22.9, -41.0), Vector2(-22.9, -35.0), Vector2.ZERO, 3.0, 2, 4.0, 2, 1.6, 2.4)
	lm.commit(model)

# --- Helsinki Music Centre -----------------------------------------------

## Marko Kivistö / LPR's Musiikkitalo (2011), origin at the OSM footprint
## centre, front +Z toward the Parliament across Mannerheimintie (the
## registry yaw turns it west-south-west): bronze-copper hall volumes
## behind the full-height glass foyer, granite steps and the roof held
## to the height of its neighbours.
static func music(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Metal", LandmarkMaterials.pbr("concrete", "#8C6A52", 2.5, 0.45, 0.55))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#4A4540", 2.5, 0.5, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Frame", LandmarkMaterials.paint("#3A3C3E", 0.5, 0.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8782", 4.0))
	var base := PackedVector2Array([Vector2(-42.6, -32.1), Vector2(-7.5, -43.5), Vector2(51.2, -33.6),
		Vector2(43.5, 10.8), Vector2(43.0, 14.0), Vector2(-29.2, 14.0)])
	lm.poly_prism("Metal", base, 0.0, 17.0)
	lm.poly_prism("Dark", PackedVector2Array([Vector2(-36.0, -29.0), Vector2(-7.0, -38.0), Vector2(44.0, -30.0),
		Vector2(38.0, 4.0), Vector2(-14.0, 6.0)]), 17.0, 20.0)
	# The concert hall box on top, the roof held at 22 m.
	FhU.blk(lm, "Metal", 4.0, 20.0, -13.0, 38.0, 2.0, 30.0)
	# Glass foyer along the whole front: mullioned wall, frame and roof.
	var fx0 := -24.0
	var fx1 := 41.0
	FhU.wedge(lm, "Glass", "Frame", fx0, fx1, 14.0, 37.6, 0.0, 22.0, 17.0)
	for i in 21:
		var x := fx0 + (fx1 - fx0) * float(i) / 20.0
		lm.box("Frame", Vector3(x, 8.5, 37.7), Vector3(0.35, 17.0, 0.45))
	for k in 4:
		lm.box("Frame", Vector3((fx0 + fx1) * 0.5, 4.0 + 4.2 * float(k), 37.7), Vector3(fx1 - fx0, 0.3, 0.45))
	FhU.steps(lm, "Granite", Vector3(9.0, 0.0, 38.2), Vector3(0, 0, 1), 56.0, 0.8, 0.2, 5)
	# Windows on the side walls.
	FhU.wall_run(lm, "Glass", Vector2(-41.26, -27.49), Vector2(-30.54, 9.39), Vector2.ZERO, 5.0, 1, 5.0, 7, 2.0, 3.0)
	FhU.wall_run(lm, "Glass", Vector2(50.43, -29.16), Vector2(44.27, 6.36), Vector2.ZERO, 5.0, 1, 5.0, 6, 2.0, 3.0)
	FhU.wall_run(lm, "Glass", Vector2(-1.63, -42.5), Vector2(45.3, -34.6), Vector2.ZERO, 5.0, 1, 5.0, 10, 2.0, 3.0)
	lm.commit(model)
