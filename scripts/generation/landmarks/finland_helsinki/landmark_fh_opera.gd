extends RefCounted

## Finnish National Opera and Ballet (Hyvämäki-Karhunen-Parkkinen, 1993),
## Helsinginkatu / Töölönlahti. Origin at the OSM footprint centre, yaw -123 (the
## front +Z, the glass foyer, faces the bay to the north-east).
##
## From the photographs (visual-plan/refs/landmarks/finnish_national_opera/):
## - Walls clad in white granite/ceramic tile on a small square grid, with
##   one continuous ribbon of small windows under the cornice and two rows
##   of square windows below it; grey flat roofs with plant.
## - The stage tower is a plain white box with fine vertical slots near the top.
## - On the bay side a long glazed foyer, about 9.5 m high, under a shallow
##   glazed vault on slender mullions, with a dark plinth.
## - The entrance on the Mannerheimintie side has a canopy on black columns
##   (not modelled) under a glass-block panel.
##
## Measured: footprint (OSM way 124699859 as rotated here), the 34 m height
## (LoD2 34.0 m at 4 m; the registry said 32). Estimated: storey heights,
## window sizes and counts, the foyer vault rise (4.2 m), the stage tower's
## 11.4 m above the hall roof, the terrace steps.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhM = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_massing.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "finnish_national_opera", "skyline_priority": 1, "name": "Finnish National Opera and Ballet", "lat": 60.18153, "lon": 24.92980,
	"radius_m": 5000.0, "wiki_title": "Finnish National Opera and Ballet", "height_m": 34.0, "clear_m": 82.0,
	"yaw_deg": -123.0, "kind": "Opera house", "aliases": ["finnish national opera and ballet",
		"suomen kansallisooppera", "finnish national opera", "finlands nationalopera"]}

## Hyvämäki-Karhunen-Parkkinen's house (1993), origin at the OSM footprint
## centre, front +Z toward the bay (the registry yaw turns it north-east):
## the white tiled base of five storeys with its grid of square windows,
## the six-storey auditorium mass whose front wall curves behind the
## foyer, the 30 x 28 m stage tower (eight storeys, 32 m) with its
## louvred top, and the tall glass foyer on slender mullions under a roof
## that falls toward Töölönlahti, with the terrace steps at its foot.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("limestone", "#E4E2DC", 3.0))
	lm.use("Band", LandmarkMaterials.pbr("limestone", "#C9C6BE", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#8FB0BE", 0.18, 0.3))
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
			# One glazed ribbon under the cornice with white mullions, and two
			# rows of square windows, as on the street fronts.
			var a3 := Vector3(p.x, 0, p.y) + o * 0.03
			var b3 := Vector3(q.x, 0, q.y) + o * 0.03
			lm.quad("Glass", a3 + Vector3(0, 12.6, 0), b3 + Vector3(0, 12.6, 0), b3 + Vector3(0, 13.9, 0),
				a3 + Vector3(0, 13.9, 0), o)
			FhP.ribs(lm, "Band", a3, b3, o, 12.6, 13.9, 1.9, 0.14, 0.1)
			for y in [8.4, 4.4]:
				FhP.win_row(lm, "Band", "Glass", a3, b3, o, y, int(l / 3.6), 1.5, 1.5, false, 0.15)
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
	FhU.blk(lm, "Granite", st.x, 22.0, st.z, 30.4, 11.4, 28.0)
	FhU.blk(lm, "Roof", st.x, 33.4, st.z, 31.2, 0.6, 28.8)
	for face in FhP.faces(st.x, st.z, 30.4, 28.0):
		FhP.ribs(lm, "Band", face[0], face[1], face[2], 29.0, 32.6, 0.9, 0.15, 0.2)
		FhP.band(lm, "Band", face[0], face[1], face[2], 28.6, 0.4, 0.25)
	# Glass foyer: tall at the auditorium, falling to the bay front, on a
	# grid of mullions and transoms; terrace steps below.
	# Foyer: glass walls 9.5 m high under a shallow glazed barrel vault
	# running along the bay front, as seen from Töölönlahti.
	lm.quad("Glass", Vector3(-37.0, 0, 34.4), Vector3(44.0, 0, 34.4), Vector3(44.0, 9.5, 34.4), Vector3(-37.0, 9.5, 34.4),
		Vector3(0, 0, 1))
	for sx in [-37.0, 44.0]:
		lm.quad("Glass", Vector3(sx, 0, 34.4), Vector3(sx, 0, 9.5), Vector3(sx, 9.5, 9.5), Vector3(sx, 9.5, 34.4),
			Vector3(1 if sx > 0 else -1, 0, 0))
	FhM.barrel(lm, "Glass", "Glass", -37.0, 44.0, 21.95, 12.45, 9.5, 4.2, 12)
	for i in 28:
		var x := -37.0 + 81.0 * float(i) / 27.0
		lm.box("Band", Vector3(x, 4.75, 34.5), Vector3(0.35, 9.5, 0.5), Basis(), 0.0)
		var prev := Vector3(x, 9.5, 34.4)
		for k in range(1, 7):
			var ang := PI * float(k) / 6.0
			var pt := Vector3(x, 9.5 + 4.2 * sin(ang), 21.95 + 12.45 * cos(ang))
			lm.beam("Band", prev, pt, 0.25)
			prev = pt
	for k in 4:
		lm.box("Band", Vector3(3.5, 2.1 * float(k + 1), 34.5), Vector3(81.0, 0.2, 0.45), Basis(), 0.0)
	lm.box("Roof", Vector3(3.5, 9.7, 35.4), Vector3(82.4, 0.5, 2.2))
	for i in 10:
		lm.frustum("Band", Vector3(-35.0 + 77.0 * float(i) / 9.0, 0.0, 36.0), 0.18, 0.18, 9.5, 10)
	FhU.steps(lm, "Band", Vector3(3.0, 0.0, 36.6), Vector3(0, 0, 1), 40.0, 0.7, 0.2, 5)
	lm.commit(model)
	var warm := Color(1.0, 0.90, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 1.5, 54.0), Vector3(-12.0, 9.0, 34.0), 50.0, 0.9, 60.0, warm],
		[Vector3(28.0, 1.5, 54.0), Vector3(18.0, 9.0, 34.0), 50.0, 0.9, 60.0, warm],
		[Vector3(-24.0, 1.5, -56.0), Vector3(7.9, 25.0, -12.0), 26.0, 0.95, 80.0, warm],
		[Vector3(40.0, 1.5, -54.0), Vector3(7.9, 25.0, -12.0), 26.0, 0.95, 80.0, warm],
		[Vector3(-76.0, 1.5, -12.0), Vector3(-56.0, 10.0, -12.0), 48.0, 0.8, 55.0, warm],
	])
