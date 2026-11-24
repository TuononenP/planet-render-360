class_name VeniceWaterfront
extends RefCounted

## Venice canal & lagoon waterfront details (`VN-9.2`–`VN-9.4`):
##   1. Vertical weathered red-brick & Istrian-stone *fondamenta* canal retaining
##      walls with dark-green wet tidal algae waterline bands (`y = -0.05..+0.42 m`)
##      and pale Euganean trachyte *masegni* paving coping along every historic
##      Venice shoreline segment — directly eliminating the sloped/green bank gaps
##      reported in `docs/fidelity-scorecard.md:625-630`.
##   2. Iconic spiral-striped painted wooden *paline* mooring poles along Grand
##      Canal palazzo fronts.
##   3. Three-pile weathered oak *bricole* channel markers across the Bacino di
##      San Marco and Giudecca Canal.
##   4. Authentic white-and-yellow ACTV floating *imbarcadero* vaporetto pontoons
##      with shelters, yellow fascia stripes & warm `PierLamp` globes at mapped
##      Grand Canal, Bacino and Giudecca ferry stops.

const ACTV_PIERS := [
	# [id, lat, lon, bearing_deg, length_m, width_m]
	["accademia_dx", 45.43163, 12.32869, 122.0, 15.0, 4.4],
	["salute", 45.43116, 12.33436, 98.0, 14.0, 4.2],
	["giglio", 45.43145, 12.33263, 95.0, 14.0, 4.2],
	["san_marco_giardinetti", 45.43233, 12.33797, 74.0, 18.0, 4.6],
	["san_zaccaria_danieli", 45.43337, 12.34224, 84.0, 18.0, 4.6],
	["san_giorgio", 45.42946, 12.34225, 198.0, 15.0, 4.4],
	["ca_rezzonico", 45.43327, 12.32711, 20.0, 14.0, 4.2],
	["san_toma", 45.43519, 12.32790, 26.0, 15.0, 4.4],
	["rialto_c", 45.43741, 12.33541, 36.0, 18.0, 4.6],
	["ca_doro", 45.44056, 12.33391, 118.0, 14.0, 4.2],
	["zattere", 45.42916, 12.32679, 108.0, 18.0, 4.6],
	["redentore", 45.42585, 12.33255, 100.0, 15.0, 4.4],
	["ferrovia", 45.44088, 12.32102, 126.0, 18.0, 4.6],
]

## Three-pile oak *bricole* channel markers in the Bacino di San Marco & Giudecca Canal.
const BRICOLE := [
	[45.43155, 12.33910], [45.43095, 12.34120], [45.43190, 12.34340],
	[45.43030, 12.33780], [45.42880, 12.33560], [45.42780, 12.33200],
	[45.42790, 12.32820], [45.42840, 12.32420], [45.43180, 12.34620],
	[45.42740, 12.33880],
]

## Historic Venetian *campi* carved Istrian-stone wellheads (*vere da pozzo*, VN-10.2).
const CAMPI_WELLHEADS := [
	[45.43318, 12.33102],  # Campo Santo Stefano
	[45.43428, 12.32385],  # Campo Santa Margherita
	[45.43728, 12.32972],  # Campo San Polo
	[45.43312, 12.32502],  # Campo San Barnaba
	[45.43710, 12.34150],  # Campo Santa Maria Formosa
	[45.43942, 12.34138],  # Campo Santi Giovanni e Paolo
	[45.43215, 12.32960],  # Campo San Vidal
	[45.43138, 12.32820],  # Campo della Carità (Accademia)
]

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "venice"

static func build(root: Node3D, data: LocationData, ground: GroundTruth, abort: BuildAbort = null) -> int:
	if not applies(data) or ground == null or ground.shoreline == null or not ground.shoreline.ready:
		return 0
	var m2u := WorldScale.metres_to_units()
	var lm := LandmarkMesh.new()
	lm.use("BrickWall", LandmarkVnKit.brick("#9F5540", 2.4))
	lm.use("IstrianCoping", LandmarkVnKit.istrian("#E6E0D2", 2.2))
	lm.use("AlgaeBand", LandmarkVnKit.algae_plinth("#3D4B3B", 2.0))
	lm.use("Masegni", LandmarkMaterials.pbr("pavement", "#B2ABA0", 2.5))
	lm.use("OakPile", LandmarkVnKit.dark_wood("#6C5842", 1.8))
	lm.use("PalinaRed", LandmarkMaterials.pbr("wood", "#8F2A26", 1.5))
	lm.use("PalinaBlue", LandmarkMaterials.pbr("wood", "#23466E", 1.5))
	lm.use("PalinaWhite", LandmarkMaterials.pbr("wood", "#F1EEE6", 1.5))
	lm.use("ActvWhite", LandmarkMaterials.pbr("render", "#F3F1EA", 2.0))
	lm.use("ActvYellow", LandmarkMaterials.pbr("render", "#E8B72A", 2.0))
	lm.use("FloatDark", LandmarkMaterials.paint("#2E3439", 0.55, 0.35))
	lm.use("PierLamp", LandmarkVnKit.warm_lamp("#FFE3A4", 2.0))

	var walls := _fondamenta_and_paline(lm, data, ground, m2u, abort)
	var bric := _bricole(lm, data, ground, m2u)
	var piers := _actv_pontoons(lm, data, ground, m2u)
	var wells := _campi_wellheads(lm, data, ground, m2u)
	if walls + bric + piers + wells > 0:
		var holder := Node3D.new()
		holder.name = "VeniceWaterfront"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return walls + bric + piers + wells

static func _fondamenta_and_paline(lm: LandmarkMesh, data: LocationData, ground: GroundTruth,
		m2u: float, abort: BuildAbort) -> int:
	var domains: ShoreDomains = ground.shoreline.domains
	var seen := {}
	var count := 0
	var ultra := RenderQuality.ultra_desktop(data.quality_preset)
	for seg in ground.shoreline.segments:
		if abort != null and abort.requested:
			break
		var body: Dictionary = domains.bodies[int(seg["body"])]
		if bool(body.get("still_pool", false)):
			continue
		var a := (seg["a"] as Vector2) / m2u
		var b := (seg["b"] as Vector2) / m2u
		var len_m := a.distance_to(b)
		if len_m < 1.0:
			continue
		var key := str([Vector2i(roundi(a.x * 10.0), roundi(a.y * 10.0)),
			Vector2i(roundi(b.x * 10.0), roundi(b.y * 10.0))])
		if seen.has(key):
			continue
		seen[key] = true

		var mid := (a + b) * 0.5
		if mid.length() > 1700.0:
			continue
		var land: Vector2 = seg["land"]
		var wa := float(seg["water_a"]) / m2u
		var wb := float(seg["water_b"]) / m2u
		var ta := maxf(float(seg["top_a"]) / m2u, wa + 1.10)
		var tb := maxf(float(seg["top_b"]) / m2u, wb + 1.10)
		var wall_y := (ta + tb) * 0.5
		var water_y := (wa + wb) * 0.5
		var dir3 := Vector3(b.x - a.x, 0.0, b.y - a.y).normalized()
		var basis := Basis(dir3, Vector3.UP, Vector3(-land.x, 0.0, -land.y))
		var mid3 := Vector3(mid.x, 0.0, mid.y)

		# Vertical weathered red-brick canal retaining wall + dark-green wet tidal algae band + Istrian coping & masegni walk
		var h_wall := maxf(wall_y - water_y + 0.65, 1.45)
		lm.box("BrickWall", mid3 + Vector3(land.x * 0.22, water_y - 0.55 + h_wall * 0.5, land.y * 0.22),
			Vector3(len_m + 0.14, h_wall, 0.44), basis, 0.0)
		lm.box("AlgaeBand", mid3 + Vector3(-land.x * 0.02, water_y + 0.18, -land.y * 0.02),
			Vector3(len_m + 0.12, 0.46, 0.08), basis, 0.0)
		lm.box("IstrianCoping", mid3 + Vector3(land.x * 0.20, wall_y + 0.06, land.y * 0.20),
			Vector3(len_m + 0.14, 0.18, 0.48), basis, 0.0)
		lm.box("Masegni", mid3 + Vector3(land.x * 0.85, wall_y + 0.03, land.y * 0.85),
			Vector3(len_m + 0.10, 0.10, 1.10), basis, 0.0)

		# Spiral-striped Venetian *paline* mooring poles along canal banks on Ultra
		if ultra and len_m >= 5.5 and count % 5 == 0 and mid.length() <= 1100.0:
			var water_out := Vector3(-land.x, 0.0, -land.y)
			var pole_mat := "PalinaRed" if (count % 10 == 0) else "PalinaBlue"
			for off in [-1.1, 1.1]:
				var pp := mid3 + dir3 * float(off) + water_out * 1.45
				var p_u := Vector2(pp.x, pp.z) * m2u
				if ground.is_inside(p_u.x, p_u.y) and ground.water_at(p_u.x, p_u.y) > 0.5:
					lm.frustum(pole_mat, Vector3(pp.x, water_y - 0.4, pp.z), 0.13, 0.11, 3.3, 6)
					lm.frustum("PalinaWhite", Vector3(pp.x, water_y + 1.35, pp.z), 0.138, 0.13, 0.85, 6)
					lm.frustum("PalinaWhite", Vector3(pp.x, water_y + 2.82, pp.z), 0.14, 0.04, 0.22, 6)
		count += 1
	return count

static func _bricole(lm: LandmarkMesh, data: LocationData, ground: GroundTruth, m2u: float) -> int:
	var added := 0
	for pt in BRICOLE:
		var xz := WorldScale.xz_from_latlon(float(pt[0]), float(pt[1]), data.latitude, data.longitude)
		var p_u := xz * m2u
		if not ground.is_inside(p_u.x, p_u.y) or ground.water_at(p_u.x, p_u.y) < 0.5:
			continue
		var wy := ground.water_level_at(p_u.x, p_u.y) / m2u
		# Three leaning oak pilings bound tightly at the crown
		for k in 3:
			var a := TAU * float(k) / 3.0
			var bot := Vector3(xz.x + cos(a) * 0.42, wy - 0.8, xz.y + sin(a) * 0.42)
			var top := Vector3(xz.x + cos(a) * 0.16, wy + 3.4, xz.y + sin(a) * 0.16)
			lm.beam("OakPile", bot, top, 0.24, 0.24)
		lm.frustum("FloatDark", Vector3(xz.x, wy + 2.95, xz.y), 0.36, 0.34, 0.26, 8)
		added += 1
	return added

static func _actv_pontoons(lm: LandmarkMesh, data: LocationData, ground: GroundTruth, m2u: float) -> int:
	var added := 0
	for row in ACTV_PIERS:
		var xz := WorldScale.xz_from_latlon(float(row[1]), float(row[2]), data.latitude, data.longitude)
		var p_u := xz * m2u
		if not ground.is_inside(p_u.x, p_u.y):
			continue
		var wy := ground.water_level_at(p_u.x, p_u.y) / m2u
		var length := float(row[4])
		var width := float(row[5])
		var rot := Basis(Vector3.UP, -deg_to_rad(float(row[3])))
		var c := Vector3(xz.x, wy, xz.y)
		# Floating dark-steel pontoon hull + white-and-yellow ACTV waiting shelter + warm overhead lamps
		lm.box("FloatDark", c + Vector3(0, 0.30, 0), Vector3(length, 0.72, width), rot)
		lm.box("Masegni", c + Vector3(0, 0.72, 0), Vector3(length - 0.3, 0.12, width - 0.3), rot)
		# Shelter columns & roof canopy with unmistakable ACTV yellow fascia stripe
		var sh_l := length * 0.62
		for sx in [-sh_l * 0.45, 0.0, sh_l * 0.45]:
			for sz in [-width * 0.38, width * 0.38]:
				lm.box("ActvWhite", c + rot * Vector3(float(sx), 2.15, float(sz)), Vector3(0.14, 2.7, 0.14), rot)
		lm.box("ActvWhite", c + rot * Vector3(0.0, 3.55, 0.0), Vector3(sh_l, 0.28, width * 0.92), rot)
		lm.box("ActvYellow", c + rot * Vector3(0.0, 3.30, 0.0), Vector3(sh_l + 0.12, 0.32, width * 0.95), rot)
		# Mooring timber dolphins at each end of the pontoon
		for sx in [-length * 0.52, length * 0.52]:
			lm.frustum("OakPile", c + rot * Vector3(float(sx), -0.4, 0.0), 0.18, 0.16, 3.2, 8)
		lm.box("PierLamp", c + rot * Vector3(0.0, 3.10, 0.0), Vector3(sh_l * 0.7, 0.14, 0.25), rot)
		added += 1
	return added

static func _campi_wellheads(lm: LandmarkMesh, data: LocationData, ground: GroundTruth, m2u: float) -> int:
	var added := 0
	for pt in CAMPI_WELLHEADS:
		var xz := WorldScale.xz_from_latlon(float(pt[0]), float(pt[1]), data.latitude, data.longitude)
		var p_u := xz * m2u
		if not ground.is_inside(p_u.x, p_u.y) or ground.water_at(p_u.x, p_u.y) > 0.2:
			continue
		var gy := ground.height_at_world(p_u.x, p_u.y) / m2u
		# Octagonal stepped Istrian-stone wellhead (*vera da pozzo*) + bronze lid + nearby Venetian *ferale* lamp
		lm.frustum("IstrianCoping", Vector3(xz.x, gy, xz.y), 1.9, 1.8, 0.28, 8, PI / 8.0)
		lm.frustum("IstrianCoping", Vector3(xz.x, gy + 0.28, xz.y), 1.35, 1.3, 0.26, 8, PI / 8.0)
		lm.frustum("ActvWhite", Vector3(xz.x, gy + 0.54, xz.y), 0.76, 0.88, 0.92, 8, PI / 8.0)
		lm.frustum("FloatDark", Vector3(xz.x, gy + 1.46, xz.y), 0.78, 0.74, 0.12, 8, PI / 8.0)
		# Classic dark cast-iron Venetian *ferale* lamp standard with warm amber globe beside the campo edge
		var lx := xz.x + 4.2
		lm.frustum("FloatDark", Vector3(lx, gy, xz.y), 0.16, 0.08, 3.6, 8)
		lm.frustum("PierLamp", Vector3(lx, gy + 3.6, xz.y), 0.24, 0.20, 0.42, 8)
		lm.frustum("FloatDark", Vector3(lx, gy + 4.02, xz.y), 0.26, 0.04, 0.22, 8)
		added += 1
	return added
