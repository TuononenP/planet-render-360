extends RefCounted

## Presidential Palace (Presidentinlinna): Granstedt's merchant house of
## 1820, rebuilt by Engel in 1843, on the Market Square quay. Model origin
## is the registry point 13 m east of the OSM relation centre (relation
## 2123871, 51 x 72 m), forecourt side +Z; yaw -3 follows the street grid.
##
## From the photos (visual-plan/refs/landmarks/presidential_palace_helsinki/):
## pale yellow render with white trim, three storeys (round-headed ground
## floor, hooded piano nobile, low top floor) in a main range with a
## two-storey west wing and a low east wing round the forecourt, a dark
## grey metal roof with dormer lanterns, a central risalit of six Ionic
## columns (two storeys, spacing 2.8 m) over a balustraded deck on a
## rusticated three-arch ground floor under a pediment, and a gilt-tipped
## black iron fence on a granite plinth along the forecourt.
##
## Measured: footprint ranges (OSM relation outline, legacy trace) and
## height (LoD2 20.6 m). Counted from the photo: six columns, three rows.
## Estimated: hips and lantern sizes, east-wing height.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "presidential_palace_helsinki", "name": "Presidential Palace, Helsinki", "lat": 60.16842, "lon": 24.95654,
	"radius_m": 5000.0, "wiki_title": "Presidential Palace, Helsinki", "height_m": 20.0, "clear_m": 58.0,
	"yaw_deg": -3.0, "kind": "Palace", "aliases": ["presidential palace, helsinki", "presidentinlinna",
		"presidentens slott"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E7DC96", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F0EAD8", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#585F60", 3.0, 0.6, 0.3))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8C8A84", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var h := 16.0
	# Ranges [x0, x1, z0, z1, eave]: the main range and the two wings.
	var parts := [[-37.0, 12.9, -37.9, 12.9, h], [-35.9, -27.8, 12.9, 34.4, h], [4.4, 12.8, 12.9, 34.4, 5.0]]
	for p in parts:
		var px0: float = p[0]
		var px1: float = p[1]
		var pz0: float = p[2]
		var pz1: float = p[3]
		var eave: float = p[4]
		var w := px1 - px0
		var d := pz1 - pz0
		var cx := (px0 + px1) * 0.5
		var cz := (pz0 + pz1) * 0.5
		FhU.blk(lm, "Plinth", cx, 0.0, cz, w + 0.4, 1.0, d + 0.4)
		FhU.blk(lm, "Wall", cx, 1.0, cz, w, eave - 1.0, d)
		FhU.hip(lm, "Roof", Vector3(cx, eave + 0.4, cz), w + 0.9, d + 0.9, 3.6 if eave > 10.0 else 1.6, 0.25)
		for face in FhP.faces(cx, cz, w, d):
			var fa: Vector3 = face[0]
			var fb: Vector3 = face[1]
			var fo: Vector3 = face[2]
			LandmarkDetail.cornice(lm, "Trim", fa + Vector3(0, eave - 0.6, 0), fb + Vector3(0, eave - 0.6, 0), fo, 0.9,
				true)
			# Skip the faces hidden against the main range.
			if eave < 10.0 or (pz0 > 12.0 and fo.z < -0.5):
				FhP.pierce(lm, "Wall", "Glass", fa, fb, fo, 1.0, eave - 1.6, maxi(int(fa.distance_to(fb) / 3.8), 1),
					1, Vector2(1.3, 2.2), 0.8, 3.0, 0.2)
				continue
			var n := maxi(int(fa.distance_to(fb) / 3.8), 1)
			var skip_mid := pz1 > 12.0 and pz1 < 13.0 and fo.z > 0.5
			# Rusticated ground floor with its joints, then three window rows.
			for k in 4:
				FhP.band(lm, "Wall", fa, fb, fo, 1.0 + 1.1 * float(k + 1), 0.1, 0.06)
			FhP.band(lm, "Trim", fa, fb, fo, 5.4, 0.45, 0.2)
			if skip_mid:
				for seg in [[fa, fa.lerp(fb, 0.4)], [fa.lerp(fb, 0.7), fb]]:
					var sa: Vector3 = seg[0]
					var sb: Vector3 = seg[1]
					var m := maxi(int(sa.distance_to(sb) / 3.8), 1)
					FhP.win_row(lm, "Trim", "Glass", sa, sb, fo, 1.8, m, 1.3, 2.4, false, 0.2)
					FhP.win_row(lm, "Trim", "Glass", sa, sb, fo, 6.6, m, 1.5, 3.0, false, 0.22)
					FhP.win_row(lm, "Trim", "Glass", sa, sb, fo, 11.3, m, 1.3, 2.2, false, 0.2)
			else:
				FhP.win_row(lm, "Trim", "Glass", fa, fb, fo, 1.8, n, 1.3, 2.4, false, 0.2)
				FhP.win_row(lm, "Trim", "Glass", fa, fb, fo, 6.6, n, 1.5, 3.0, false, 0.22)
				FhP.win_row(lm, "Trim", "Glass", fa, fb, fo, 11.3, n, 1.3, 2.2, false, 0.2)
			FhP.strips(lm, "Trim", fa + fa.direction_to(fb) * 0.3, fb - fa.direction_to(fb) * 0.3, fo, 1.0,
				eave - 1.6, 2, 0.8, 0.15)
	# Central risalit on the forecourt: rusticated arcade, four Ionic
	# columns through the upper storeys, entablature and pediment.
	var rx0 := -18.9
	var rx1 := -4.2
	var rz := 14.1
	var rc := (rx0 + rx1) * 0.5
	FhU.blk(lm, "Wall", rc, 1.0, 13.5, rx1 - rx0, h - 1.0, 1.2)
	for k in 3:
		var px := rc + (float(k) - 1.0) * 4.2
		lm.quad("Glass", Vector3(px - 1.2, 1.0, rz + 0.02), Vector3(px + 1.2, 1.0, rz + 0.02),
			Vector3(px + 1.2, 4.0, rz + 0.02), Vector3(px - 1.2, 4.0, rz + 0.02), Vector3(0, 0, 1))
		LandmarkDetail.arch(lm, "Trim", Vector3(px, 4.0, rz), Vector3(0, 0, 1), 2.4, 0.35, 0.3)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 8.1, rz + 1.0), Vector3(0, 0, 1), 1.6, 3.2, true, 0.2)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 12.4, rz + 1.0), Vector3(0, 0, 1), 1.4, 2.2, false, 0.2)
	FhU.blk(lm, "Trim", rc, 5.4, rz + 0.9, rx1 - rx0, 0.6, 1.8)
	for k in 6:
		var px := rc + (float(k) - 2.5) * 2.8
		LandmarkDetail.column(lm, "Trim", Vector3(px, 6.0, rz + 1.2), 0.4, 8.6, "ionic", 20)
	FhU.blk(lm, "Trim", rc, 14.6, rz + 0.7, rx1 - rx0, 1.4, 2.2)
	lm.gable("Roof", Vector3(rc, h, rz - 2.0), rx1 - rx0, 6.2, 3.2, Basis(), 0.3, "Trim")
	LandmarkDetail.balustrade(lm, "Trim", Vector3(rc - 6.5, 6.0, rz + 1.95), Vector3(rc + 6.5, 6.0, rz + 1.95), 0.9,
		4.3)
	# Gilt-tipped iron fence on a granite plinth along the forecourt front.
	lm.use("Iron", LandmarkMaterials.paint("#222426", 0.5, 0.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	FhU.blk(lm, "Plinth", -10.9, 0.0, 36.2, 50.0, 0.7, 0.5)
	for i in 100:
		var fx := -35.9 + float(i) * 0.5
		lm.box("Iron", Vector3(fx, 1.45, 36.2), Vector3(0.05, 1.5, 0.05), Basis(), 0.0)
		lm.box("Gilt", Vector3(fx, 2.28, 36.2), Vector3(0.09, 0.18, 0.09), Basis(), 0.0)
	lm.box("Iron", Vector3(-10.9, 1.2, 36.2), Vector3(50.0, 0.06, 0.06), Basis(), 0.0)
	lm.box("Iron", Vector3(-10.9, 2.0, 36.2), Vector3(50.0, 0.06, 0.06), Basis(), 0.0)
	# Lanterns over the stair halls.
	for q in [Vector3(-11.45, 0, 4.8), Vector3(5.9, 0, 3.7)]:
		FhU.blk(lm, "Wall", q.x, h, q.z, 3.6, 2.2, 3.6)
		FhU.blk(lm, "Glass", q.x, h + 0.5, q.z, 3.65, 1.2, 3.65)
		FhU.hip(lm, "Roof", q + Vector3(0, h + 2.2, 0), 4.0, 4.0, 1.4)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-25.0, 2.0, 44.0), Vector3(-14.0, 11.0, 15.0), 44.0, 0.95, 55.0, warm],
		[Vector3(2.0, 2.0, 44.0), Vector3(-9.0, 11.0, 15.0), 44.0, 0.95, 55.0, warm],
		[Vector3(-12.0, 2.0, -52.0), Vector3(-12.0, 10.0, -37.0), 50.0, 0.8, 55.0, warm],
		[Vector3(-52.0, 2.0, 0.0), Vector3(-36.0, 10.0, 0.0), 50.0, 0.8, 55.0, warm],
		[Vector3(28.0, 2.0, 0.0), Vector3(13.0, 10.0, 0.0), 50.0, 0.8, 55.0, warm],
	])
