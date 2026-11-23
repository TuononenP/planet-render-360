class_name LandmarkMiPamm
extends RefCounted

## Pérez Art Museum Miami (PAMM) — Maurice A. Ferré Park MI-2A.3
## Site: 1103 Biscayne Blvd, OSM way 484587327 (25.786002, -80.186362, yaw_deg -25.2).
## Architect: Herzog & de Meuron (2013), landscapes & vertical gardens by Patrick Blanc.
## Measured envelope & materials (Commons front/quarter/side, height_m = 22.0, footprint 75 x 56 m):
##   - Raised board-formed concrete platform (y = 0..4.2 m) supported on perimeter pilotis columns,
##     with wide cascading warm-teak timber & concrete amphitheatre steps toward Biscayne Bay (+X).
##   - Three staggered board-formed concrete & dark-teal glass gallery boxes (y = 4.2..18.5 m)
##     with warm teak wood entry doors and recessed shaded verandas.
##   - Overhanging 75 x 56 m slatted warm-teak timber & concrete pergola canopy (y = 20.2..22.0 m,
##     structural concrete spine beams & skylight hanger blocks topping at exact 22.0 m) built from
##     beam slats at two densities and carried on slender tall concrete columns.
##   - Signature hanging cylindrical lush green vertical-garden tubes suspended on steel cables
##     from the pergola canopy into the bayfront and park verandas.

const HEIGHT_M := 22.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFCBC2", 3.5))
	lm.use("BoardConcrete", LandmarkMaterials.pbr("limestone", "#DAD5CA", 3.2))
	lm.use("Teak", LandmarkMaterials.pbr("wood", "#8E6642", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#1E4652"))
	lm.use("Foliage", LandmarkMaterials.pbr("grass", "#2B5E2E", 1.8))
	lm.use("Steel", LandmarkMaterials.paint("#42484D", 0.45, 0.60))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD28A", 0.50))

	_build_raised_platform_and_steps(lm)
	_build_gallery_boxes(lm)
	_build_pergola_canopy_and_columns(lm)
	_build_hanging_gardens(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.89, 0.70)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(44.0, 1.5, -14.0), Vector3(18.0, 15.0, -8.0), 54.0, 1.05, 52.0, warm],
		[Vector3(44.0, 1.5, 14.0), Vector3(18.0, 15.0, 8.0), 54.0, 1.05, 52.0, warm],
		[Vector3(-44.0, 1.5, 0.0), Vector3(-18.0, 15.0, 0.0), 56.0, 1.0, 52.0, warm],
		[Vector3(0.0, 4.8, 25.0), Vector3(0.0, 19.5, 8.0), 58.0, 0.95, 42.0, warm],
	])

static func _build_raised_platform_and_steps(lm: LandmarkMesh) -> void:
	# Undercroft parking/service core + perimeter pilotis carrying the y = 4.2 m veranda deck
	lm.box("Concrete", Vector3(-6.0, 1.75, 0.0), Vector3(50.0, 4.2, 42.0))
	for x in [-35.0, -24.0, -12.0, 0.0, 12.0, 22.0]:
		for z in [-25.5, 25.5]:
			lm.box("Concrete", Vector3(x, 1.85, z), Vector3(0.75, 4.3, 0.75))
	# Main cantilevered platform slab (x = -37.5..+24.5 m, z = -28..+28 m, y = 3.45..4.20 m)
	lm.box("Concrete", Vector3(-6.5, 3.825, 0.0), Vector3(62.0, 0.75, 56.0))
	# Teak-planked veranda deck surface on the bayfront & side terraces
	lm.box("Teak", Vector3(14.0, 4.23, 0.0), Vector3(21.0, 0.08, 54.0), Basis(), 0.0)

	# Wide cascading amphitheatre timber-and-concrete steps descending +X toward Biscayne Bay
	# (x = 24.5..37.5 m, z = -24.0..+24.0 m, y = 0.0..4.2 m)
	var tiers := 7
	var step_run := 13.0 / float(tiers)
	var step_rise := 4.2 / float(tiers)
	for i in tiers:
		var y_top := 4.2 - float(i) * step_rise
		var x_mid := 24.5 + (float(i) + 0.5) * step_run
		# Concrete structural riser/cheek & warm-teak seating/stair treads
		lm.box("Concrete", Vector3(x_mid, (y_top - 0.12) * 0.5, 0.0),
			Vector3(step_run + 0.08, y_top - 0.12, 48.0), Basis(), 0.0)
		lm.box("Teak", Vector3(x_mid, y_top - 0.06, -6.0),
			Vector3(step_run + 0.04, 0.12, 32.0), Basis(), 0.0)
		lm.box("Concrete", Vector3(x_mid, y_top - 0.06, 17.0),
			Vector3(step_run + 0.04, 0.12, 14.0), Basis(), 0.0)
	# Concrete cheek walls framing the bayfront amphitheatre stairs
	for sz in [-1.0, 1.0]:
		lm.box("BoardConcrete", Vector3(31.0, 2.55, sz * 24.3), Vector3(13.2, 5.1, 0.65))
	# West (-X) arrival stair from Biscayne Blvd / Metromover plaza
	for s in 6:
		var sy := 0.7 * float(s + 1)
		lm.box("Concrete", Vector3(-39.5 + float(s) * 0.65, sy * 0.5, -4.0),
			Vector3(1.4, sy, 16.0), Basis(), 0.0)

	# Slender dark-steel cable-mesh guardrails around the open veranda perimeter
	for sz in [-1.0, 1.0]:
		lm.beam("Steel", Vector3(-37.0, 5.25, sz * 27.6), Vector3(24.2, 5.25, sz * 27.6), 0.08, 0.08)
		for k in 13:
			var rx := -36.0 + float(k) * 5.0
			lm.beam("Steel", Vector3(rx, 4.2, sz * 27.6), Vector3(rx, 5.25, sz * 27.6), 0.06, 0.06)

static func _build_gallery_boxes(lm: LandmarkMesh) -> void:
	# Gallery Box 1 (North-Center main 2-level concrete & glass pavilion, y = 4.2..18.5 m)
	lm.box("BoardConcrete", Vector3(-6.0, 11.35, -8.5), Vector3(38.0, 14.3, 21.0))
	lm.box("Glass", Vector3(-6.0, 9.8, -19.05), Vector3(24.0, 9.6, 0.28), Basis(), 0.0)
	lm.box("Glass", Vector3(13.05, 10.2, -8.5), Vector3(0.28, 10.4, 15.0), Basis(), 0.0)
	# Framed vertical picture window + teak wood entry portal (matching side.jpg)
	lm.box("Teak", Vector3(-16.0, 6.4, 2.08), Vector3(6.8, 4.4, 0.32), Basis(), 0.0)
	lm.box("Glass", Vector3(-4.0, 12.5, 2.08), Vector3(14.5, 6.8, 0.28), Basis(), 0.0)

	# Gallery Box 2 (South-West staggered concrete gallery volume, y = 4.2..17.6 m)
	lm.box("BoardConcrete", Vector3(-17.5, 10.9, 11.5), Vector3(28.0, 13.4, 18.0))
	lm.box("Glass", Vector3(-17.5, 9.6, 20.55), Vector3(18.5, 9.2, 0.28), Basis(), 0.0)
	lm.box("Glass", Vector3(-31.55, 9.8, 11.5), Vector3(0.28, 9.6, 12.0), Basis(), 0.0)

	# Gallery Box 3 (East bay-facing glass & concrete pavilion overlooking the steps, y = 4.2..16.8 m)
	lm.box("Glass", Vector3(8.5, 10.1, 10.0), Vector3(20.0, 11.8, 16.5))
	lm.box("BoardConcrete", Vector3(8.5, 15.6, 10.0), Vector3(20.6, 2.4, 17.1))
	lm.box("BoardConcrete", Vector3(8.5, 8.2, 18.3), Vector3(12.0, 8.0, 0.65))
	lm.box("WarmLamp", Vector3(5.0, 8.5, 1.0), Vector3(16.0, 7.5, 12.0))

static func _build_pergola_canopy_and_columns(lm: LandmarkMesh) -> void:
	# Slender full-height square concrete columns (0.68 x 0.68 m) rising from y = 4.2 to 20.9 m
	var col_xs := [-35.5, -21.5, -7.5, 6.5, 20.5, 34.5]
	var col_zs := [-26.0, -13.0, 0.0, 13.0, 26.0]
	for cx in col_xs:
		for cz in col_zs:
			# Keep interior gallery footprints clean; perimeter & veranda columns stand in the open
			if cx > 18.0 and cz > -14.0 and cz < 14.0 and cx > 28.0:
				lm.box("Concrete", Vector3(cx, 11.2, cz), Vector3(0.68, 19.6, 0.68))
			else:
				lm.box("Concrete", Vector3(cx, 12.55, cz), Vector3(0.68, 16.7, 0.68))

	# Overhanging 75 x 56 m concrete perimeter fascia & primary N-S concrete girders (y = 20.6..21.5 m)
	for sz in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(0.0, 21.05, sz * 27.75), Vector3(75.0, 0.90, 0.50), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(sx * 37.25, 21.05, 0.0), Vector3(0.50, 0.90, 55.0), Basis(), 0.0)
	for cx in col_xs:
		lm.box("Concrete", Vector3(cx, 21.15, 0.0), Vector3(0.58, 1.10, 55.2), Basis(), 0.0)
		# Rooftop concrete spine hanger blocks along the column lines reaching exact y = 22.0 m (side.jpg)
		for cz in [-20.0, -6.5, 6.5, 20.0]:
			lm.box("BoardConcrete", Vector3(cx, 21.65, cz), Vector3(0.95, 0.70, 1.85), Basis(), 0.0)

	# Warm-teak timber pergola louvre slats at two densities across the 75 x 56 m canopy (y = 20.35..20.85 m):
	# Denser shading over the galleries & west arrival (-37..+16 m), wider spacing over bayfront steps (+16..+37 m)
	var z_dense := 36
	for i in z_dense:
		var z := -27.2 + (54.4 * (float(i) + 0.5) / float(z_dense))
		lm.beam("Teak", Vector3(-37.2, 20.55, z), Vector3(16.5, 20.55, z), 0.16, 0.42, Vector3.FORWARD)
	var z_open := 20
	for i in z_open:
		var z := -27.0 + (54.0 * (float(i) + 0.5) / float(z_open))
		lm.beam("Teak", Vector3(16.5, 20.55, z), Vector3(37.2, 20.55, z), 0.16, 0.42, Vector3.FORWARD)
	# Secondary cross-batten purlins tying the teak louvres
	for k in 11:
		var px := -34.0 + float(k) * 6.8
		lm.beam("Teak", Vector3(px, 20.82, -27.5), Vector3(px, 20.82, 27.5), 0.18, 0.22, Vector3.RIGHT)

static func _build_hanging_gardens(lm: LandmarkMesh) -> void:
	# Patrick Blanc's iconic cylindrical hanging vertical-garden columns suspended from the pergola
	var tubes := [
		Vector3(21.5, 9.2, -21.5), Vector3(24.0, 10.4, -15.5), Vector3(19.5, 8.6, -9.5),
		Vector3(23.5, 11.0, -3.5), Vector3(26.5, 9.8, 3.0), Vector3(22.0, 8.8, 9.5),
		Vector3(25.5, 10.5, 16.5), Vector3(20.5, 9.4, 22.5),
		Vector3(-24.5, 9.0, -22.5), Vector3(-18.5, 10.2, -24.0), Vector3(-11.0, 8.8, -23.0),
		Vector3(2.5, 9.6, -23.5), Vector3(11.5, 10.4, -22.0),
		Vector3(-33.5, 9.5, -8.0), Vector3(-34.0, 10.2, -1.5), Vector3(-32.5, 8.8, 19.0),
		Vector3(-6.0, 9.4, 23.5), Vector3(3.5, 10.0, 24.0),
	]
	for idx in tubes.size():
		var bot: Vector3 = tubes[idx]
		var r := 0.52 + float(idx % 3) * 0.11
		var top_y := 19.8 - float(idx % 2) * 0.6
		var h := top_y - bot.y
		# Suspension steel cable from canopy spine (y = 21.1 m) + dark planter cap + lush foliage cylinder
		lm.beam("Steel", Vector3(bot.x, top_y, bot.z), Vector3(bot.x, 21.1, bot.z), 0.06, 0.06)
		lm.frustum("Steel", bot - Vector3(0.0, 0.12, 0.0), r * 0.88, r * 0.96, 0.14, 10)
		lm.frustum("Foliage", bot, r, r * 1.04, h, 10)
		# Organic foliage texture bands along each hanging planter tube
		for b in 3:
			var by := bot.y + h * (0.22 + float(b) * 0.28)
			lm.frustum("Foliage", Vector3(bot.x, by, bot.z), r * 1.12, r * 1.06, 0.65, 10)
