class_name FtWiklund
extends RefCounted

## Sokos Wiklund & Walo Rooftop Bar (1957-63, renovated 2019) on the NE
## corner of Turku Market Square (Kauppatori), rebuilt directly from
## visual-plan/refs/landmarks/wiklund_turku/{front,quarter,side}.jpg.
## Origin at OSM way 465777801 centroid (60.451910 N, 22.268991 E), yaw_deg -35.3:
##   -X bears 234.7° (SW, Kauppiaskatu front facing Kauppatori)
##   +Z bears 144.7° (SE, Eerikinkatu front & 9-storey hotel tower corner)
##   +X bears 54.7° (NE, Brahenkatu flank)
##   -Z bears 324.7° (NW, Yliopistonkatu flank)
##
## Photo-verified massing & facade spec (66 x 60 m podium H 14.8 m, 9-storey
## corner tower flush at -X/+Z to 38.0 m):
## - Podium: warm cream-beige horizontal-ribbed travertine stone (#DDD2BE),
##   covered ground-floor arcade with square travertine piers on dark granite
##   bases, 2nd-floor recessed café balcony under 5 sloped dark-grey awnings,
##   single crisp 3rd-floor row of 12 rectangular recessed dark windows,
##   vertical green Prisma corner panel + 5 white flagpoles at NW corner, and
##   dark charcoal rooftop mechanical penthouse set back behind parapet.
## - 9-storey Sokos Hotel Wiklund tower flush with the Kauppatori (-X) &
##   Eerikinkatu (+Z) corner: solid cream travertine Kauppatori end wall split
##   by a full-height vertical dark-blue glazed stair slot, bold white "W" /
##   WIKLUND emblem on the left, tall dark-framed LED billboard & horizontal
##   signage ladder on the right; dark charcoal-slate NW/SE flanks with 6
##   continuous horizontal ribbon-window bands.
## - Full-width wraparound glass Walo Rooftop Bar crown (y = 34.2..37.4 m)
##   under a thin overhanging white fascia (38.0 m) with rooftop WALO sign
##   and tall corner flagpole.
## Surfaces: 9 merged PBR parts (Travertine, SlateDark, Awning, White,
## Granite, Roof, Glass, GreenBanner, WarmGlow).

const FOUND := -1.6
const PODIUM_H := 14.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("stone", "#DDD2BE", 2.8, 0.72))
	lm.use("SlateDark", LandmarkMaterials.paint("#3B4046", 0.55, 0.35))
	lm.use("Awning", LandmarkMaterials.paint("#52565B", 0.65, 0.15))
	lm.use("White", LandmarkMaterials.pbr("render", "#F2F0EA", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#585C62", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4C5054", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#243542"))
	lm.use("GreenBanner", LandmarkMaterials.paint("#236B42", 0.55, 0.08))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE8BA", 1.25))

	_build_podium(lm)
	_build_hotel_tower(lm)
	_build_walo_crown(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 1.5, -4.0), Vector3(-33.0, 11.0, -4.0), 54.0, 0.85, 65.0, warm],
		[Vector3(-42.0, 1.5, 21.0), Vector3(-33.0, 26.0, 21.0), 46.0, 0.95, 75.0, warm],
		[Vector3(-18.0, 1.5, 39.0), Vector3(-18.0, 24.0, 30.0), 52.0, 0.85, 70.0, warm],
	])

static func _build_podium(lm: LandmarkMesh) -> void:
	# Dark granite street plinth & covered ground-floor colonnade arcade (y = 0..4.8 m).
	LandmarkFrKit.rect(lm, "Granite", -33.3, 33.3, -30.3, 30.3, FOUND, 0.55)
	LandmarkFrKit.rect(lm, "Glass", -30.6, 31.5, -28.6, 27.8, 0.55, 4.8)
	LandmarkFrKit.rect(lm, "WarmGlow", -30.2, 31.1, -28.2, 27.4, 0.9, 4.2)
	# Iconic square travertine arcade piers along Kauppatori (-X) & Eerikinkatu (+Z).
	for j in 11:
		var pz := lerpf(-29.2, 29.2, float(j) / 10.0)
		lm.box("Granite", Vector3(-32.5, 0.85, pz), Vector3(0.92, 0.65, 0.92), Basis(), 0.0)
		lm.box("Travertine", Vector3(-32.5, 2.95, pz), Vector3(0.84, 3.65, 0.84), Basis(), 0.0)
	for i in 12:
		var px := lerpf(-32.5, 32.5, float(i) / 11.0)
		lm.box("Granite", Vector3(px, 0.85, 29.4), Vector3(0.92, 0.65, 0.92), Basis(), 0.0)
		lm.box("Travertine", Vector3(px, 2.95, 29.4), Vector3(0.84, 3.65, 0.84), Basis(), 0.0)
	# Recessed 2nd-floor café balcony along Kauppatori (-X, z = -22..11) + 5 sloped grey awnings.
	LandmarkFrKit.rect(lm, "Travertine", -33.0, 33.0, -30.0, 30.0, 4.8, 5.5)
	LandmarkFrKit.rect(lm, "Travertine", -30.4, 33.0, -30.0, 30.0, 5.5, 9.2)
	LandmarkFrKit.rect(lm, "Travertine", -33.0, -30.4, -30.0, -20.5, 5.5, 9.2)
	LandmarkFrKit.rect(lm, "Travertine", -33.0, -30.4, 10.8, 30.0, 5.5, 9.2)
	LandmarkFrKit.rect(lm, "Glass", -30.55, -30.35, -20.2, 10.6, 5.6, 8.8)
	LandmarkFrKit.rect(lm, "WarmGlow", -30.1, -29.9, -19.8, 10.2, 5.9, 8.4)
	# Balcony railing + 5 sloped dark-grey café terrace awnings matching front.jpg.
	LandmarkFrParts.railing(lm, "SlateDark", Vector3(-32.85, 5.5, -20.2), Vector3(-32.85, 5.5, 10.6), 1.05, 2.4, 0.06)
	for k in 5:
		var az0 := lerpf(-20.2, 10.6, float(k) / 5.0) + 0.15
		var az1 := lerpf(-20.2, 10.6, float(k + 1) / 5.0) - 0.15
		lm.quad("Awning", Vector3(-33.15, 7.65, az0), Vector3(-33.15, 7.65, az1),
			Vector3(-30.5, 9.05, az1), Vector3(-30.5, 9.05, az0), Vector3(-0.45, 0.89, 0.0))
	# 3rd-floor solid cream-beige travertine band & parapet (y = 9.2..14.8 m).
	LandmarkFrKit.rect(lm, "Travertine", -33.0, 33.0, -30.0, 30.0, 9.2, PODIUM_H)
	LandmarkFrKit.rect(lm, "Roof", -32.4, 32.4, -29.4, 29.4, PODIUM_H, PODIUM_H + 0.35)
	# Single clean row of 12 recessed dark rectangular windows on Kauppatori front (-X).
	LandmarkFrParts.openings(lm, "SlateDark", "Glass", Vector3(-33.02, 10.0, -21.0),
		Vector3(-33.02, 10.0, 10.6), Vector3.LEFT, 12, 1.95, 2.15, LandmarkFrParts.HEAD_FLAT, 0.12, 0.10, 0)
	# Side facades (Yliopistonkatu -Z, Brahenkatu +X, Eerikinkatu +Z) clean horizontal ribbons.
	for fl in 2:
		var fy := 6.0 + float(fl) * 4.0
		LandmarkFrKit.rect(lm, "Glass", -30.5, 30.5, -30.08, -29.92, fy, fy + 2.1)
		LandmarkFrKit.rect(lm, "Glass", 32.92, 33.08, -28.0, 28.0, fy, fy + 2.1)
		LandmarkFrKit.rect(lm, "Glass", -3.0, 30.5, 29.92, 30.08, fy, fy + 2.1)
	# Iconic vertical green PRISMA banner panel on NW Kauppatori corner + 5 white flagpoles.
	lm.box("GreenBanner", Vector3(-33.10, 7.4, -27.6), Vector3(0.14, 13.6, 3.8), Basis(), 0.0)
	lm.box("White", Vector3(-33.18, 7.4, -27.6), Vector3(0.06, 9.0, 0.7), Basis(), 0.0)
	for k in 5:
		var fz := lerpf(-28.6, -20.2, float(k) / 4.0)
		lm.frustum("White", Vector3(-32.4, PODIUM_H, fz), 0.06, 0.035, 6.2, 6)
	# Dark charcoal rooftop mechanical penthouse set back behind podium parapet (front.jpg).
	LandmarkFrKit.rect(lm, "SlateDark", -18.0, 14.0, -24.0, 6.0, PODIUM_H, PODIUM_H + 3.8)

static func _build_hotel_tower(lm: LandmarkMesh) -> void:
	# 9-storey Sokos Hotel Wiklund tower FLUSH with Kauppatori (-X) & Eerikinkatu (+Z) corner!
	var x0 := -33.0
	var x1 := -2.5
	var z0 := 11.4
	var z1 := 30.0
	var top_y := 34.2
	# Solid cream-beige travertine core + dark charcoal-slate NW (-Z) & SE (+Z) flanks.
	LandmarkFrKit.rect(lm, "Travertine", x0, x1, z0, z1, PODIUM_H, top_y)
	# Signature full-height vertical dark-blue glazed stair slot splitting the Kauppatori (-X) face!
	LandmarkFrKit.rect(lm, "Glass", x0 - 0.10, x0 + 0.12, 20.0, 22.3, 4.8, top_y)
	lm.box("SlateDark", Vector3(x0 - 0.10, 19.5, 20.0), Vector3(0.14, 29.4, 0.14), Basis(), 0.0)
	lm.box("SlateDark", Vector3(x0 - 0.10, 19.5, 22.3), Vector3(0.14, 29.4, 0.14), Basis(), 0.0)
	# Bold white "W" & WIKLUND emblem on solid cream travertine left of stair slot (front.jpg).
	lm.box("White", Vector3(x0 - 0.14, 30.8, 15.8), Vector3(0.18, 3.2, 3.4), Basis(), 0.0)
	lm.box("Travertine", Vector3(x0 - 0.16, 31.3, 15.8), Vector3(0.16, 2.2, 1.4), Basis(), 0.0)
	lm.box("White", Vector3(x0 - 0.14, 28.4, 15.8), Vector3(0.16, 0.72, 4.6), Basis(), 0.0)
	# Tall dark-framed digital LED billboard & horizontal signage ladder right of stair slot (front.jpg).
	lm.box("SlateDark", Vector3(x0 - 0.14, 13.8, 26.2), Vector3(0.22, 12.6, 5.2), Basis(), 0.0)
	lm.box("WarmGlow", Vector3(x0 - 0.24, 13.8, 26.2), Vector3(0.06, 11.4, 4.4), Basis(), 0.0)
	for k in 7:
		var sy := 21.8 + float(k) * 1.65
		lm.box("White", Vector3(x0 - 0.16, sy, 26.2), Vector3(0.14, 0.42, 4.8), Basis(), 0.0)
	# Long NW (-Z) & SE (+Z, Eerikinkatu) dark charcoal flanks with 6 continuous horizontal ribbons.
	LandmarkFrKit.rect(lm, "SlateDark", x0 + 2.4, x1 - 1.2, z0 - 0.06, z0 + 0.04, PODIUM_H, top_y)
	LandmarkFrKit.rect(lm, "SlateDark", x0 + 2.4, x1 - 1.2, z1 - 0.04, z1 + 0.06, PODIUM_H, top_y)
	for fl in 6:
		var wy := 16.0 + float(fl) * 2.95
		LandmarkFrKit.rect(lm, "Glass", x0 + 2.6, x1 - 1.4, z0 - 0.10, z0 + 0.02, wy, wy + 1.55)
		LandmarkFrKit.rect(lm, "Glass", x0 + 2.6, x1 - 1.4, z1 - 0.02, z1 + 0.10, wy, wy + 1.55)
		LandmarkFrKit.rect(lm, "Glass", x1 - 0.02, x1 + 0.10, z0 + 1.4, z1 - 1.4, wy, wy + 1.55)
		if fl % 2 == 0:
			lm.box("WarmGlow", Vector3(-16.0 + float(fl) * 2.2, wy + 0.78, z0 - 0.05), Vector3(4.5, 1.25, 0.04), Basis(), 0.0)
			lm.box("WarmGlow", Vector3(-18.0 + float(fl) * 2.2, wy + 0.78, z1 + 0.05), Vector3(4.5, 1.25, 0.04), Basis(), 0.0)

static func _build_walo_crown(lm: LandmarkMesh) -> void:
	# Full-width wraparound panoramic glass Walo Rooftop Bar crown flush with tower perimeter!
	var x0 := -33.0
	var x1 := -2.5
	var z0 := 11.4
	var z1 := 30.0
	LandmarkFrKit.rect(lm, "Glass", x0 + 0.05, x1 - 0.05, z0 + 0.05, z1 - 0.05, 34.2, 37.35)
	LandmarkFrKit.rect(lm, "WarmGlow", x0 + 0.8, x1 - 0.8, z0 + 0.8, z1 - 0.8, 34.5, 37.0)
	# Crisp vertical mullions around the Walo glass crown.
	for j in 7:
		var mz := lerpf(z0 + 0.1, z1 - 0.1, float(j) / 6.0)
		lm.box("SlateDark", Vector3(x0 - 0.02, 35.78, mz), Vector3(0.14, 3.15, 0.14), Basis(), 0.0)
		lm.box("SlateDark", Vector3(x1 + 0.02, 35.78, mz), Vector3(0.14, 3.15, 0.14), Basis(), 0.0)
	for i in 10:
		var mx := lerpf(x0 + 0.1, x1 - 0.1, float(i) / 9.0)
		lm.box("SlateDark", Vector3(mx, 35.78, z0 - 0.02), Vector3(0.14, 3.15, 0.14), Basis(), 0.0)
		lm.box("SlateDark", Vector3(mx, 35.78, z1 + 0.02), Vector3(0.14, 3.15, 0.14), Basis(), 0.0)
	# Crisp thin white overhanging crown fascia (top 38.0 m) + WALO rooftop sign & corner flagpole.
	LandmarkFrKit.rect(lm, "White", x0 - 0.35, x1 + 0.35, z0 - 0.35, z1 + 0.35, 37.35, 38.0)
	LandmarkFrKit.rect(lm, "Roof", x0, x1, z0, z1, 37.9, 38.02)
	lm.box("WarmGlow", Vector3(x0 + 0.4, 38.65, 15.8), Vector3(0.16, 1.05, 5.2), Basis(), 0.0)
	lm.frustum("White", Vector3(x0 + 1.2, 38.0, 26.2), 0.06, 0.03, 1.4, 6)
