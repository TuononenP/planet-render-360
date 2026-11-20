class_name FtArtMuseum
extends RefCounted

## Turku Art Museum (Turun taidemuseo, Gustaf Nyström, 1904) crowning
## Puolalanmäki granite hill at the northern vista of Aurakatu.
## Origin at OSM way 26491362 centroid (60.454107 N, 22.261774 E), yaw_deg -34.7:
##   +X bears 55.3° (NE, east pavilion & Puolalanpuisto flank)
##   +Z bears 145.3° (SE, Aurakatu front facade, 3-arch portal & granite stairs)
##   -Z bears 325.3° (NW, Puolalanpuisto park rear facade)
##
## Architectural & facade spec (counted from Wikimedia Commons / Finna refs
## and OSM way 26491362: 39.4 x 32.7 m, LoD2 22.5 m, 35° roof, height_m = 22.0):
## - Rough-hewn grey & pinkish-grey Finnish granite National Romantic palace
##   on a heavy rusticated granite plinth (foundation dropped to y = -5.5 m
##   for the steep Puolalanmäki hill slope).
## - Main gallery volume (39.2 x 26.4 m, eaves 13.4 m) with steep patinated
##   copper hipped roof (y = 13.4..20.2 m) and full-length glazed rooftop
##   clerestory skylight monitor (y = 19.6..22.0 m, warm night interior glow).
## - Twin projecting front corner pavilions (+Z, centred at x = ±14.4 m,
##   9.6 m wide, projecting to z = 17.6 m) with rusticated quoins, arched
##   upper studio windows, and curved National Romantic / Jugend gables
##   peaking at 19.6 m with semicircular carved tympanum panels.
## - Central 3-arch rusticated granite entrance portal (+Z, x = -9.2..9.2)
##   with heavy piers, deeply recessed loggia, bronze-trimmed double doors,
##   carved frieze and terrace parapet.
## - Sculpted bronze portrait herms of Johan Ludvig Runeberg and Zachris
##   Topelius on tall dark-red granite pedestals flanking the front terrace.
## - Monumental multi-flight granite terrace stairs cascading down toward
##   Aurakatu (+Z, z = 15.0..30.6 m, stepping down to y = -2.8 m with heavy
##   retaining cheek walls and warm terrace lamp bollards).
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META)
##   on the 3-arch portal, twin pavilions, herms and stairs + clerestory glow.

const FOUND := -5.5
const PLINTH_Y := 3.2
const EAVE_Y := 13.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8F857E", 2.5))
	lm.use("GraniteDark", LandmarkMaterials.pbr("stone", "#6B635E", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#AEA69E", 2.2))
	lm.use("Pedestal", LandmarkMaterials.pbr("stone", "#754C46", 1.8, 0.42))
	lm.use("Copper", LandmarkFrKit.copper("#4A7060"))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	lm.use("Bronze", LandmarkMaterials.paint("#302C26", 0.42, 0.65))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#443225", 1.5))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE1A4", 0.90))

	_build_main_block(lm)
	_build_pavilions(lm)
	_build_portal_and_herms(lm)
	_build_monumental_stairs(lm)
	_build_side_and_rear(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-8.5, 2.8, 22.5), Vector3(0.0, 9.5, 13.0), 34.0, 1.10, 60.0, warm],
		[Vector3(8.5, 2.8, 22.5), Vector3(0.0, 9.5, 13.0), 34.0, 1.10, 60.0, warm],
		[Vector3(-16.0, 1.5, 25.0), Vector3(-14.4, 12.0, 17.0), 28.0, 0.95, 55.0, warm],
		[Vector3(16.0, 1.5, 25.0), Vector3(14.4, 12.0, 17.0), 28.0, 0.95, 55.0, warm],
		[Vector3(0.0, 1.0, -23.0), Vector3(0.0, 10.0, -13.0), 38.0, 0.70, 55.0, warm],
	])

static func _build_main_block(lm: LandmarkMesh) -> void:
	# Heavy rusticated granite basement plinth dropped to FOUND = -5.5 m.
	LandmarkFrKit.rect(lm, "GraniteDark", -20.2, 20.2, -14.0, 13.4, FOUND, PLINTH_Y)
	LandmarkFrParts.band(lm, "Trim", -20.0, 20.0, -13.8, 13.2, PLINTH_Y - 0.35, 0.40, 0.18)
	# Main rough-granite gallery body (-19.6..19.6 x -13.4..12.8).
	LandmarkFrKit.rect(lm, "Granite", -19.6, 19.6, -13.4, 12.8, PLINTH_Y, EAVE_Y)
	LandmarkFrParts.corner_strips(lm, "GraniteDark", -19.6, 19.6, -13.4, 12.8, PLINTH_Y, EAVE_Y, 0.85, 0.16)
	LandmarkFrParts.cornice_ring(lm, "Trim", -19.6, 19.6, -13.4, 12.8, EAVE_Y - 0.75, 0.75)
	# Steep 35° green-copper hipped roof (y = 13.4..20.2 m).
	LandmarkFrKit.hip(lm, "Copper", -19.6, 19.6, -13.4, 12.8, EAVE_Y, 6.8, 0.70)
	# Full-length glazed rooftop clerestory skylight monitor peaking at 22.0 m.
	LandmarkFrKit.rect(lm, "Trim", -13.4, 13.4, -3.0, 2.4, 19.0, 19.6)
	LandmarkFrKit.rect(lm, "Glass", -13.2, 13.2, -2.8, 2.2, 19.6, 21.15)
	LandmarkFrKit.rect(lm, "WarmGlow", -12.9, 12.9, -2.5, 1.9, 19.75, 20.95)
	LandmarkFrKit.gable(lm, "Glass", -13.2, 13.2, -2.8, 2.2, 21.15, 0.85, 0.18, "Trim", 1)
	# Clerestory glazing mullions along the skylight.
	for k in 13:
		var mx := lerpf(-13.0, 13.0, float(k) / 12.0)
		lm.box("Trim", Vector3(mx, 20.4, 2.25), Vector3(0.14, 1.6, 0.12), Basis(), 0.0)
		lm.box("Trim", Vector3(mx, 20.4, -2.85), Vector3(0.14, 1.6, 0.12), Basis(), 0.0)
	# Pair of stout granite chimneys rising through the rear roof slopes.
	for cx: float in [-11.5, 11.5]:
		LandmarkFrParts.chimney(lm, "GraniteDark", Vector3(cx, 16.0, -7.2), 20.8, 1.5, 1.3)

static func _build_pavilions(lm: LandmarkMesh) -> void:
	# Twin projecting National Romantic front pavilions (+Z) with curved Jugend gables.
	for sx: float in [-1.0, 1.0]:
		var cx := sx * 14.4
		var x0 := cx - 4.8
		var x1 := cx + 4.8
		var z0 := 12.4
		var z1 := 17.6
		LandmarkFrKit.rect(lm, "GraniteDark", x0 - 0.35, x1 + 0.35, z0, z1 + 0.35, FOUND, PLINTH_Y)
		LandmarkFrKit.rect(lm, "Granite", x0, x1, z0, z1, PLINTH_Y, 14.4)
		LandmarkFrParts.corner_strips(lm, "GraniteDark", x0, x1, z0, z1, PLINTH_Y, 14.4, 0.72, 0.16)
		LandmarkFrParts.band(lm, "Trim", x0, x1, z0, z1, 13.85, 0.55, 0.18)
		# Steep copper gable roof behind the sculpted front gable.
		LandmarkFrKit.gable(lm, "Copper", x0, x1, z0 - 2.0, z1, 14.4, 4.9, 0.45, "Granite", 0)
		# Curved National Romantic / Jugend front gable crest (+Z, y = 14.4..19.7 m).
		_curved_jugend_gable(lm, Vector3(cx, 14.4, z1), 9.8, 5.2)
		# Large upper arched studio window + paired lower windows on front (+Z).
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(cx, 8.0, z1), Vector3.BACK,
			3.8, 4.8, LandmarkFrParts.HEAD_ROUND, 0.38, 0.20, 2)
		lm.box("WarmGlow", Vector3(cx, 10.2, z1 + 0.02), Vector3(2.8, 2.8, 0.04), Basis(), 0.0)
		for wx: float in [-1.8, 1.8]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(cx + wx, 4.2, z1), Vector3.BACK,
				1.45, 2.6, LandmarkFrParts.HEAD_FLAT, 0.24, 0.14, 0)
		# Outer flank window on each pavilion.
		var fx := x1 if sx > 0.0 else x0
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(fx, 8.2, 15.0), Vector3(sx, 0.0, 0.0),
			2.2, 4.2, LandmarkFrParts.HEAD_ROUND, 0.30, 0.16, 1)

static func _curved_jugend_gable(lm: LandmarkMesh, base_c: Vector3, w: float, rise: float) -> void:
	# Multi-tiered curved silhouette mimicking Nyström's National Romantic stone gables.
	var tiers := [
		[0.0, 1.2, w * 0.96],
		[1.2, 2.4, w * 0.78],
		[2.4, 3.6, w * 0.54],
		[3.6, 4.6, w * 0.34],
		[4.6, rise, w * 0.18],
	]
	for t: Array in tiers:
		var y0: float = t[0]
		var y1: float = t[1]
		var tw: float = t[2]
		lm.box("Granite", base_c + Vector3(0.0, (y0 + y1) * 0.5, 0.12), Vector3(tw, y1 - y0, 0.65), Basis(), 0.0)
		lm.box("Trim", base_c + Vector3(0.0, y1, 0.16), Vector3(tw + 0.28, 0.22, 0.78), Basis(), 0.0)
	# Central carved circular granite medallion & apex stone finial.
	lm.disc("Trim", base_c + Vector3(0.0, 2.3, 0.48), Vector3.BACK, 0.95, 16)
	lm.disc("GraniteDark", base_c + Vector3(0.0, 2.3, 0.52), Vector3.BACK, 0.62, 16)
	lm.lathe("Trim", base_c + Vector3(0.0, rise + 0.05, 0.15), LandmarkFrKit.ball(0.28), 10)

static func _build_portal_and_herms(lm: LandmarkMesh) -> void:
	# Central 3-arch rusticated granite entrance loggia (+Z, x = -9.4..9.4, z = 12.8..15.4).
	LandmarkFrKit.rect(lm, "GraniteDark", -9.6, 9.6, 12.6, 15.6, FOUND, 2.4)
	# Heavy rusticated piers framing the three semicircular arches.
	for px: float in [-8.2, -2.9, 2.9, 8.2]:
		LandmarkFrKit.rect(lm, "GraniteDark", px - 0.85, px + 0.85, 13.0, 15.45, 2.4, 8.2)
		lm.box("Trim", Vector3(px, 6.2, 15.50), Vector3(1.85, 0.35, 0.22), Basis(), 0.0)
	# Three bold semicircular rusticated granite arches across the loggia front.
	for ax: float in [-5.55, 0.0, 5.55]:
		LandmarkDetail.arch(lm, "GraniteDark", Vector3(ax, 6.0, 15.45), Vector3.BACK, 3.6, 0.75, 0.55, 12)
		# Recessed doorway / arched museum vestibule glazing inside the loggia.
		LandmarkFrParts.opening(lm, "Trim", "Door" if ax == 0.0 else "Glass",
			Vector3(ax, 2.4, 12.85), Vector3.BACK, 2.6, 5.2, LandmarkFrParts.HEAD_ROUND, 0.32, 0.18, 0)
	lm.box("WarmGlow", Vector3(0.0, 4.9, 12.92), Vector3(11.5, 4.4, 0.06), Basis(), 0.0)
	# Heavy granite spandrel wall, carved frieze, and upper balcony parapet above the 3 arches.
	LandmarkFrKit.rect(lm, "Granite", -9.6, 9.6, 12.8, 15.45, 7.8, 9.5)
	LandmarkFrParts.band(lm, "Trim", -9.6, 9.6, 12.8, 15.45, 9.2, 0.45, 0.24)
	LandmarkFrKit.rect(lm, "GraniteDark", -9.5, 9.5, 14.85, 15.45, 9.5, 10.65)
	# Three tall upper gallery windows over the entrance loggia.
	for wx: float in [-5.55, 0.0, 5.55]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 9.9, 12.8), Vector3.BACK,
			2.1, 2.8, LandmarkFrParts.HEAD_FLAT, 0.24, 0.14, 1)
	# Bronze portrait herms of Johan Ludvig Runeberg (-X) and Zachris Topelius (+X)
	# on tall polished reddish-granite pedestals flanking the entrance terrace.
	for sx: float in [-1.0, 1.0]:
		var hx := sx * 7.6
		var hz := 17.8
		LandmarkFrKit.rect(lm, "GraniteDark", hx - 0.85, hx + 0.85, hz - 0.85, hz + 0.85, FOUND, 2.55)
		LandmarkFrKit.rect(lm, "Pedestal", hx - 0.52, hx + 0.52, hz - 0.52, hz + 0.52, 2.55, 4.85)
		LandmarkFrKit.rect(lm, "Trim", hx - 0.60, hx + 0.60, hz - 0.60, hz + 0.60, 4.85, 5.05)
		# Sculpted bronze bust (shoulders + neck + head).
		lm.box("Bronze", Vector3(hx, 5.38, hz), Vector3(0.76, 0.62, 0.46), Basis(), 0.08)
		lm.frustum("Bronze", Vector3(hx, 5.68, hz), 0.15, 0.14, 0.18, 10)
		lm.lathe("Bronze", Vector3(hx, 5.84, hz), LandmarkFrKit.ball(0.24), 10)

static func _build_monumental_stairs(lm: LandmarkMesh) -> void:
	# Upper arrival granite terrace (z = 15.2..19.4, y = 2.4 m).
	LandmarkFrKit.rect(lm, "GraniteDark", -10.8, 10.8, 15.2, 19.4, FOUND, 2.4)
	# Flanking retaining parapet walls & warm terrace lamp bollards.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "GraniteDark", sx * 10.0 - 0.85, sx * 10.0 + 0.85, 15.4, 19.6, FOUND, 3.45)
		lm.frustum("Bronze", Vector3(sx * 9.8, 3.45, 19.1), 0.18, 0.14, 0.9, 8)
		lm.lathe("WarmGlow", Vector3(sx * 9.8, 4.35, 19.1), LandmarkFrKit.ball(0.24), 10)
	# Upper grand granite stair flight (z = 19.4..23.6, y = 2.4 down to 0.0 m).
	for s in 10:
		var sy := lerpf(2.4, 0.0, float(s) / 9.0)
		var z0 := 19.4 + float(s) * 0.42
		LandmarkFrKit.rect(lm, "GraniteDark", -7.2, 7.2, z0, z0 + 0.46, FOUND, sy)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Granite", sx * 7.8 - 0.65, sx * 7.8 + 0.65, 19.2, 23.8, FOUND, 2.2)
	# Intermediate Puolalanmäki granite landing terrace (z = 23.6..26.4, y = 0.0 m).
	LandmarkFrKit.rect(lm, "GraniteDark", -9.6, 9.6, 23.6, 26.4, FOUND, 0.0)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Granite", sx * 9.0 - 0.65, sx * 9.0 + 0.65, 23.5, 26.5, FOUND, 1.15)
		lm.frustum("Bronze", Vector3(sx * 9.0, 1.15, 26.0), 0.16, 0.12, 0.75, 8)
		lm.lathe("WarmGlow", Vector3(sx * 9.0, 1.90, 26.0), LandmarkFrKit.ball(0.22), 10)
	# Lower granite stair cascade down toward Aurakatu (z = 26.4..30.8, y = 0.0 down to -2.8 m).
	for s in 10:
		var sy := lerpf(0.0, -2.8, float(s) / 9.0)
		var z0 := 26.4 + float(s) * 0.44
		LandmarkFrKit.rect(lm, "GraniteDark", -6.4, 6.4, z0, z0 + 0.48, FOUND, sy)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Granite", sx * 7.0 - 0.65, sx * 7.0 + 0.65, 26.3, 30.9, FOUND, -0.4)

static func _build_side_and_rear(lm: LandmarkMesh) -> void:
	# Rhythmic side & rear granite gallery windows.
	for sx: float in [-1.0, 1.0]:
		var n := Vector3(sx, 0.0, 0.0)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 19.6, 4.4, -10.5),
			Vector3(sx * 19.6, 4.4, 9.5), n, 5, 1.85, 3.2, LandmarkFrParts.HEAD_FLAT, 0.26, 0.14, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 19.6, 9.2, -10.5),
			Vector3(sx * 19.6, 9.2, 9.5), n, 5, 1.85, 2.8, LandmarkFrParts.HEAD_ROUND, 0.26, 0.14, 1)
	# Rear Puolalanpuisto facade (-Z) with central stepped projection.
	LandmarkFrKit.rect(lm, "GraniteDark", -6.2, 6.2, -15.6, -13.4, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Granite", -5.8, 5.8, -15.2, -13.4, PLINTH_Y, 13.8)
	LandmarkFrKit.gable(lm, "Copper", -5.8, 5.8, -15.2, -13.4, 13.8, 3.8, 0.4, "Granite", 0)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-16.0, 4.4, -13.4), Vector3(-7.0, 4.4, -13.4),
		Vector3.FORWARD, 2, 1.9, 3.2, LandmarkFrParts.HEAD_FLAT, 0.26, 0.14, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(7.0, 4.4, -13.4), Vector3(16.0, 4.4, -13.4),
		Vector3.FORWARD, 2, 1.9, 3.2, LandmarkFrParts.HEAD_FLAT, 0.26, 0.14, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(0.0, 5.2, -15.2), Vector3.FORWARD,
		3.6, 5.2, LandmarkFrParts.HEAD_ROUND, 0.36, 0.18, 2)
