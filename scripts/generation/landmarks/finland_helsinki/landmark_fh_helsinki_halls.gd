class_name LandmarkFhHelsinkiHalls
extends RefCounted

## Three concert and congress halls on Töölönlahti in true metres:
## Finlandia Hall (Aalto, white Carrara marble), the Finnish National
## Opera and Ballet (white granite and glass) and the Helsinki Music
## Centre (glass foyer in front of bronze-copper volumes). Footprints are
## the OpenStreetMap outlines in the model frame the registry yaw turns
## onto the map.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

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
		# Black granite plinth course under the marble.
	lm.poly_prism("Black", base, 0.0, 0.6, false)
	# The marble skin: narrow profiled slabs read as vertical fins down
	# every long wall of the base, the congress storey and the tower.
	for i in base.size():
		var p := base[i]
		var q := base[(i + 1) % base.size()]
		if p.distance_to(q) > 8.0:
			FhP.ribs(lm, "Marble", Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), FhP.edge_out(base, i), 0.6, 10.3,
				1.4, 0.3, 0.12)
	var cong := PackedVector2Array([Vector2(-96.0, -23.0), Vector2(-58.5, -23.3), Vector2(-57.0, 36.0),
		Vector2(-83.0, 1.5), Vector2(-80.5, -0.8)])
	# Ribbon window and mullions round the congress wing's upper storey.
	for i in cong.size():
		var p := cong[i]
		var q := cong[(i + 1) % cong.size()]
		var o := FhP.edge_out(cong, i)
		var a3 := Vector3(p.x, 0, p.y) + o * 0.04
		var b3 := Vector3(q.x, 0, q.y) + o * 0.04
		lm.quad("Glass", a3 + Vector3(0, 11.3, 0), b3 + Vector3(0, 11.3, 0), b3 + Vector3(0, 13.1, 0),
			a3 + Vector3(0, 13.1, 0), o)
		FhP.ribs(lm, "Marble", a3, b3, o, 11.3, 13.1, 1.8, 0.2, 0.1)
		FhP.band(lm, "Marble", a3, b3, o, 13.2, 0.8, 0.25)
	# The tower: fins on its bay and end walls, a step under the sloping
	# roof and the eaves fascia along its falling edges.
	for x in [-14.0, 34.0]:
		var sx := -1.0 if x < 0.0 else 1.0
		FhP.ribs(lm, "Marble", Vector3(x, 0, -25.7), Vector3(x, 0, 4.0), Vector3(sx, 0, 0), 10.5, 13.5, 1.6, 0.3, 0.12)
		lm.beam("Roof", Vector3(x + sx * 0.2, 24.2, -25.9), Vector3(x + sx * 0.2, 14.2, 4.2), 0.5, 0.8, Vector3(0, 0, 1))
	FhP.ribs(lm, "Marble", Vector3(-13.0, 0, -25.75), Vector3(33.0, 0, -25.75), Vector3(0, 0, -1), 10.5, 23.6, 1.6,
		0.3, 0.14)
	FhP.band(lm, "Roof", Vector3(-14.0, 0, -25.7), Vector3(34.0, 0, -25.7), Vector3(0, 0, -1), 23.6, 0.6, 0.5)
	FhU.wedge(lm, "Marble", "Roof", -6.0, 26.0, -18.0, -2.0, 24.0, 1.4, 0.8)
	# Chamber-hall fan: fins and its stepped roof edge.
	FhP.band(lm, "Marble", Vector3(38.0, 0, -24.5), Vector3(97.0, 0, -25.5), Vector3(0, 0, -1), 14.6, 0.6, 0.3)
	FhP.ribs(lm, "Marble", Vector3(38.0, 0, -24.4), Vector3(97.0, 0, -25.4), Vector3(0, 0, -1), 10.5, 14.6, 1.6, 0.3,
		0.12)
	# Entrance canopies on the street front, on slender round columns.
	for e in [Vector3(-44.0, 0, 37.5), Vector3(-6.0, 0, 26.6)]:
		var eb := Basis(Vector3.UP, ang)
		lm.box("Roof", e + eb * Vector3(0, 3.6, 3.0), Vector3(12.0, 0.4, 6.0), eb)
		for k in 4:
			lm.frustum("Marble", e + eb * Vector3(-5.0 + 3.33 * float(k), 0, 5.6), 0.16, 0.16, 3.4, 10)
	lm.commit(model)

# --- Finnish National Opera and Ballet ---------------------------------

## Hyvämäki-Karhunen-Parkkinen's house (1993), origin at the OSM footprint
## centre, front +Z toward the bay (the registry yaw turns it north-east):
## the white tiled base of five storeys with its grid of square windows,
## the six-storey auditorium mass whose front wall curves behind the
## foyer, the 30 x 28 m stage tower (eight storeys, 32 m) with its
## louvred top, and the tall glass foyer on slender mullions under a roof
## that falls toward Töölönlahti, with the terrace steps at its foot.
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
	lm.poly_prism("Band", base, 0.0, 1.0)
	lm.poly_prism("Granite", base, 1.0, 16.0)
	for k in 3:
		lm.poly_prism("Band", base, 4.6 + 3.8 * float(k), 4.9 + 3.8 * float(k), false)
	# Square windows in a regular grid on every long wall of the base.
	for i in base.size():
		var p := base[i]
		var q := base[(i + 1) % base.size()]
		var l := p.distance_to(q)
		if l > 12.0:
			var o := FhP.edge_out(base, i)
			FhP.pierce(lm, "Granite", "Glass", Vector3(p.x, 0, p.y) + o * 0.02, Vector3(q.x, 0, q.y) + o * 0.02, o,
				1.0, 14.6, int(l / 3.6), 4, Vector2(1.5, 1.5), 1.3, 3.8, 0.25)
	FhU.blk(lm, "Roof", 4.0, 16.0, -15.0, 120.0, 0.4, 53.0)
	# Auditorium mass, its front wall curving behind the foyer.
	var aud := PackedVector2Array([Vector2(44.4, 24.0), Vector2(23.7, 23.6), Vector2(19.1, 26.9),
		Vector2(13.9, 28.6), Vector2(8.8, 29.7), Vector2(4.1, 29.4), Vector2(-0.9, 28.9), Vector2(-5.0, 27.3),
		Vector2(-8.3, 24.8), Vector2(-11.7, 22.4), Vector2(-35.0, 21.6), Vector2(-35.0, -30.0),
		Vector2(44.4, -30.0)])
	lm.poly_prism("Granite", aud, 16.0, 22.0)
	lm.poly_prism("Band", aud, 21.6, 22.2)
	# Stage tower with louvre bands near its top.
	var st := Vector3(7.9, 0.0, -12.0)
	FhU.blk(lm, "Granite", st.x, 22.0, st.z, 30.4, 9.4, 28.0)
	FhU.blk(lm, "Roof", st.x, 31.4, st.z, 31.2, 0.6, 28.8)
	for face in FhP.faces(st.x, st.z, 30.4, 28.0):
		FhP.ribs(lm, "Band", face[0], face[1], face[2], 27.0, 30.6, 0.9, 0.15, 0.2)
		FhP.band(lm, "Band", face[0], face[1], face[2], 26.6, 0.4, 0.25)
	# Glass foyer: tall at the auditorium, falling to the bay front, on a
	# grid of mullions and transoms; terrace steps below.
	FhU.wedge(lm, "Glass", "Roof", -37.0, 44.0, 9.5, 34.4, 0.0, 17.0, 8.0)
	for i in 28:
		var x := -37.0 + 81.0 * float(i) / 27.0
		lm.box("Band", Vector3(x, 4.0, 34.5), Vector3(0.35, 8.0, 0.5), Basis(), 0.0)
	for k in 4:
		lm.box("Band", Vector3(3.5, 1.9 * float(k + 1), 34.5), Vector3(81.0, 0.2, 0.45), Basis(), 0.0)
	for z in [16.0, 22.0, 28.0]:
		var h := 17.0 + (8.0 - 17.0) * (float(z) - 9.5) / (34.4 - 9.5)
		for side in [-37.0, 44.0]:
			lm.box("Band", Vector3(float(side), h * 0.5, float(z)), Vector3(0.5, h, 0.35), Basis(), 0.0)
	lm.box("Roof", Vector3(3.5, 8.1, 35.4), Vector3(82.4, 0.5, 2.2))
	for i in 10:
		lm.frustum("Band", Vector3(-35.0 + 77.0 * float(i) / 9.0, 0.0, 36.0), 0.18, 0.18, 7.9, 10)
	FhU.steps(lm, "Band", Vector3(3.0, 0.0, 36.6), Vector3(0, 0, 1), 40.0, 0.7, 0.2, 5)
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
	FhP.band(lm, "Frame", Vector3(fx0, 0, 37.6), Vector3(fx1, 0, 37.6), Vector3(0, 0, 1), 16.6, 0.6, 0.6)
	for x in [fx0, fx1]:
		FhP.ribs(lm, "Frame", Vector3(x, 0, 14.5), Vector3(x, 0, 37.4), Vector3(signf(x - 9.0), 0, 0), 0.0, 16.8,
			2.9, 0.3, 0.3)
	lm.box("Frame", Vector3(9.0, 4.4, 40.0), Vector3(22.0, 0.35, 4.4))
	lm.commit(model)
