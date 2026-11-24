class_name AmsterdamWaterfront
extends RefCounted

## Amsterdam canal & IJ waterfront realism (`AMS-6.1` & `AMS-6.2`):
##   1. Vertical weathered red-brown Dutch brick canal retaining walls with wet
##      waterline band & pale Belgian bluestone/granite coping slabs along
##      inland canal edges.
##   2. Moored glass-topped *rondvaartboten* (canal tour cruisers) & open Dutch
##      *sloepen* along Damrak, Rokin, Herengracht, Keizersgracht, Prinsengracht
##      and the Amstel.
##   3. Double-ended blue-and-white GVB IJ commuter ferries at Centraal IJ-side
##      and Buiksloterweg ferry piers.

const IJ_FERRIES := [
	# [lat, lon, bearing_deg]
	[52.38075, 4.89980, 18.0],   # Centraal -> Buiksloterweg
	[52.38320, 4.90120, 198.0],  # Approaching Buiksloterweg / EYE
	[52.38120, 4.89800, 325.0],  # Centraal -> NDSM
]

const RONDVAART_SPOTS := [
	# [lat, lon, bearing_deg, livery_idx]
	[52.37660, 4.89750, 26.0, 0],  # Damrak canal-cruise pier
	[52.37610, 4.89700, 26.0, 1],  # Damrak south
	[52.37750, 4.89990, 62.0, 2],  # Open Havenfront (Centraal)
	[52.37720, 4.90150, 66.0, 0],  # Prins Hendrikkade
	[52.37020, 4.89260, 14.0, 1],  # Rokin
	[52.36600, 4.90160, 152.0, 0], # Amstel south of Blauwbrug
	[52.36460, 4.90220, 158.0, 2], # Amstel north of Magere Brug
	[52.37380, 4.88860, 14.0, 0],  # Singel near Torensluis
	[52.37460, 4.88450, 14.0, 1],  # Prinsengracht by Westerkerk
	[52.36840, 4.88560, 12.0, 2],  # Keizersgracht
]

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "amsterdam"

static func build(root: Node3D, data: LocationData, ground: GroundTruth, abort: BuildAbort = null) -> int:
	if not applies(data) or ground == null or ground.shoreline == null or not ground.shoreline.ready:
		return 0
	var m2u := WorldScale.metres_to_units()
	var lm := LandmarkMesh.new()
	lm.use("BrickWall", LandmarkMaterials.pbr("brick", "#7A3A2C", 2.4))
	lm.use("Bluestone", LandmarkMaterials.pbr("limestone", "#A6AAB0", 2.4))
	lm.use("Algae", LandmarkMaterials.pbr("concrete", "#2E3A2D", 2.2))
	lm.use("Navy", LandmarkMaterials.paint("#1B365C", 0.35, 0.2))
	lm.use("Burgundy", LandmarkMaterials.paint("#721F28", 0.38, 0.15))
	lm.use("Green", LandmarkMaterials.paint("#1C4A34", 0.38, 0.15))
	lm.use("White", LandmarkMaterials.pbr("render", "#F2EFE8", 2.0))
	lm.use("GvbBlue", LandmarkMaterials.paint("#0057A8", 0.32, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#263D4E"))
	var boat_win := LandmarkMaterials.glass("#2A4050")
	boat_win.set_meta(CityLights.META, 0.9)
	lm.use("BoatLamp", boat_win)

	var walls := _brick_canal_quays(lm, data, ground, m2u, abort)
	var boats := _rondvaart_and_ferries(lm, data, ground, m2u)
	if walls + boats > 0:
		var holder := Node3D.new()
		holder.name = "AmsterdamWaterfront"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return walls + boats

static func _brick_canal_quays(lm: LandmarkMesh, data: LocationData, ground: GroundTruth,
		m2u: float, abort: BuildAbort) -> int:
	var centre := View360.spawn_xz(data)
	var r2 := pow(950.0 * m2u, 2.0)
	var count := 0
	for seg in ground.shoreline.segments:
		if abort != null and abort.requested:
			break
		if str(seg.get("kind", "")) != "hard":
			continue
		var a: Vector2 = seg["a"]
		var b: Vector2 = seg["b"]
		var mid := (a + b) * 0.5
		if mid.distance_squared_to(centre) > r2:
			continue
		var seg_l := a.distance_to(b) / m2u
		if seg_l < 0.8 or seg_l > 80.0:
			continue
		var top_y := (float(seg["top_a"]) + float(seg["top_b"])) * 0.5 / m2u
		var wat_y := (float(seg["water_a"]) + float(seg["water_b"])) * 0.5 / m2u
		var h := clampf(top_y - wat_y, 0.5, 2.4)
		var pa := Vector3(a.x / m2u, wat_y + h * 0.5, a.y / m2u)
		var pb := Vector3(b.x / m2u, wat_y + h * 0.5, b.y / m2u)
		lm.beam("BrickWall", pa, pb, 0.45, h)
		lm.beam("Algae", Vector3(a.x / m2u, wat_y + 0.14, a.y / m2u),
			Vector3(b.x / m2u, wat_y + 0.14, b.y / m2u), 0.48, 0.30)
		lm.beam("Bluestone", Vector3(a.x / m2u, top_y + 0.06, a.y / m2u),
			Vector3(b.x / m2u, top_y + 0.06, b.y / m2u), 0.58, 0.18)
		count += 1
		if count >= 2400:
			break
	return count

static func _rondvaart_and_ferries(lm: LandmarkMesh, data: LocationData, ground: GroundTruth,
		m2u: float) -> int:
	var count := 0
	var liveries := ["Navy", "Burgundy", "Green"]
	for sp in RONDVAART_SPOTS:
		var xz := WorldScale.xz_from_latlon(float(sp[0]), float(sp[1]), data.latitude, data.longitude)
		if xz.length() > 1350.0:
			continue
		var wy := ground.water_level_at(xz.x * m2u, xz.y * m2u) / m2u
		if is_nan(wy) or wy < -200.0:
			wy = 0.0
		var rot := Basis(Vector3.UP, deg_to_rad(float(sp[2])))
		var o := Vector3(xz.x, wy, xz.y)
		var hull: String = liveries[int(sp[3]) % liveries.size()]
		# Sleek 18 m glass-topped Amsterdam *rondvaartboot*
		lm.box(hull, o + Vector3(0.0, 0.35, 0.0), Vector3(3.8, 0.85, 18.0), rot)
		lm.box("White", o + Vector3(0.0, 0.85, 0.0), Vector3(3.6, 0.25, 16.5), rot)
		lm.box("Glass", o + Vector3(0.0, 1.55, 0.0), Vector3(3.3, 1.15, 13.8), rot)
		lm.box("White", o + Vector3(0.0, 2.18, 0.0), Vector3(3.1, 0.14, 13.4), rot)
		lm.box("BoatLamp", o + Vector3(0.0, 1.45, 0.0), Vector3(2.8, 0.4, 11.0), rot)
		count += 1
	for f in IJ_FERRIES:
		var xz := WorldScale.xz_from_latlon(float(f[0]), float(f[1]), data.latitude, data.longitude)
		if xz.length() > 1600.0:
			continue
		var wy := ground.water_level_at(xz.x * m2u, xz.y * m2u) / m2u
		if is_nan(wy) or wy < -200.0:
			wy = 0.0
		var rot := Basis(Vector3.UP, deg_to_rad(float(f[2])))
		var o := Vector3(xz.x, wy, xz.y)
		# Double-ended GVB blue-and-white IJ commuter ferry (36 x 11 m)
		lm.box("GvbBlue", o + Vector3(0.0, 0.65, 0.0), Vector3(11.0, 1.6, 36.0), rot)
		lm.box("White", o + Vector3(0.0, 2.4, 0.0), Vector3(10.2, 2.0, 26.0), rot)
		lm.box("Glass", o + Vector3(0.0, 3.8, 0.0), Vector3(5.8, 1.6, 8.0), rot)
		lm.box("GvbBlue", o + Vector3(0.0, 4.75, 0.0), Vector3(6.2, 0.35, 8.6), rot)
		lm.box("BoatLamp", o + Vector3(0.0, 2.3, 0.0), Vector3(10.4, 0.35, 22.0), rot)
		count += 1
	return count
