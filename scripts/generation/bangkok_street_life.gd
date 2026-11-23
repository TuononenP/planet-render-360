class_name BangkokStreetLife
extends RefCounted

## Data-driven Bangkok street life & royal-boulevard furniture (`BK-8.1`, `BK-9.3`, `BK-9.6`, `BK-10`):
##   1. Ratchadamnoen Klang (`bangkok_ratchadamnoen`): gilded `K2.kinnari_lamp` posts,
##      potted bougainvillea / clipped `tako dat` planters & ceremonial royal-emblem bunting
##      along the central median, clear of Democracy Monument's roundabout.
##   2. Parked motorbike / scooter clusters (`4–6` bikes) along shophouse pavements & side
##      streets (`BK-9.3`), plus orange-vest `win motorsai` stand canopies near junctions.
##   3. Street-food vendor pushcarts (`rot khen`) with colourful striped umbrellas, stainless
##      soup pots, low red/blue plastic stools & warm bare-bulb `VendorLamp` (`BK-10`) on wide
##      shophouse pavements and market corners.
##   4. Blue-and-white Thai street-name signposts (`ซอย / ถนน`) at junctions, painted
##      red-and-white no-stopping kerbs near signals, gilded Thai spirit houses (`san phra phum`)
##      in civic/commercial forecourts, and potted clipped `tako dat` topiary in temple courts.

const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const RADIUS_M := 480.0
const MAX_MOTO_CLUSTERS := 75
const MAX_VENDORS := 55
const MAX_SIGNS := 80
const MAX_SHRINES := 40

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "bangkok"

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, m2u: float) -> int:
	if not applies(data) or data.roads.is_empty() or int(data.quality_preset) < RenderSettings.Preset.HIGH:
		return 0
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#5A6068", 0.36, 0.65))
	lm.use("Dark", LandmarkMaterials.paint("#1E2024", 0.72, 0.15))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("BlueSign", LandmarkMaterials.pbr("concrete", "#1B4F9C", 1.5, 0.45))
	lm.use("White", LandmarkMaterials.pbr("render", "#F3F1EA", 2.0))
	lm.use("RedPaint", LandmarkMaterials.pbr("concrete", "#C92A22", 1.5, 0.50))
	lm.use("OrangeVest", LandmarkMaterials.pbr("render", "#EE6B18", 1.5, 0.68))
	lm.use("UmbrellaA", LandmarkMaterials.pbr("render", "#D93829", 1.8, 0.80))
	lm.use("UmbrellaB", LandmarkMaterials.pbr("render", "#1F6EB8", 1.8, 0.80))
	lm.use("UmbrellaC", LandmarkMaterials.pbr("render", "#2B8A44", 1.8, 0.80))
	lm.use("Foliage", LandmarkMaterials.pbr("grass", "#355E28", 1.6))
	lm.use("Bougainvillea", LandmarkMaterials.pbr("render", "#C82874", 1.4, 0.78))
	lm.use("Pot", LandmarkMaterials.pbr("terracotta", "#8E4B2E", 1.5))
	lm.use("KinnariLamp", LandmarkMaterials.lit("#FFE39E", 2.4))
	lm.use("VendorLamp", LandmarkMaterials.lit("#FFD984", 2.1))

	var centre := View360.spawn_xz(data)
	var r2 := pow(RADIUS_M * m2u, 2.0)
	var rects := LandmarkSites.model_rect_sites(data)
	var junc := RoadSurface.junctions(data)
	var ultra := RenderQuality.ultra_desktop(data.quality_preset)
	var count := 0

	count += _ratchadamnoen_median(lm, data, ground, mask, centre, r2, rects, m2u)
	count += _street_side_life(lm, data, ground, mask, centre, r2, rects, junc, ultra, m2u)
	count += _forecourt_shrines_and_topiary(lm, data, ground, mask, centre, r2, rects, m2u)

	if count > 0:
		var holder := Node3D.new()
		holder.name = "BangkokStreetLife"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return count

static func _ratchadamnoen_median(lm: LandmarkMesh, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, centre: Vector2, r2: float, rects: Array, m2u: float) -> int:
	# Ratchadamnoen Klang boulevard ways in `bangkok_ratchadamnoen` get gilded kinnari lamp
	# standards + bougainvillea planters along the road edge/median (`BK-3.7` & `BK-9.6`).
	var placed := 0
	var occ := {}
	for r in data.roads:
		if not (r is Dictionary):
			continue
		var rd: Dictionary = r
		var cls := str(rd.get("class", ""))
		if cls not in ["primary", "trunk", "secondary"] or bool(rd.get("bridge", false)) or bool(rd.get("tunnel", false)):
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var half_m := float(rd.get("width_m", 10.0)) * 0.5
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg_u := a.distance_to(b)
			if seg_u < 14.0 * m2u:
				continue
			var dir := (b - a) / seg_u
			var nrm := Vector2(-dir.y, dir.x)
			var steps := int(seg_u / (22.0 * m2u))
			for k in steps:
				var c := a + dir * ((float(k) + 0.5) * 22.0 * m2u)
				if c.distance_squared_to(centre) > r2 * 1.4:
					continue
				var ll := WorldScale.latlon_from_xz(c.x, c.y, data.latitude, data.longitude)
				if CityStyles.region_at(ll.x, ll.y) != "bangkok_ratchadamnoen":
					continue
				var p := c + nrm * ((half_m + 0.85) * m2u)
				if LandmarkSites.in_model_rects(p, rects) or mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER, 0.0):
					continue
				var cell := Vector2i(floori(p.x / (14.0 * m2u)), floori(p.y / (14.0 * m2u)))
				if occ.has(cell):
					continue
				occ[cell] = true
				var gy := ground.height_at_world(p.x, p.y) / m2u
				var pos_m := Vector3(p.x / m2u, gy, p.y / m2u)
				var yaw := atan2(dir.x, dir.y)
				K2.kinnari_lamp(lm, "Dark", "Gold", "KinnariLamp", pos_m, yaw, 6.2)
				# Potted bougainvillea planter box beside every second kinnari post
				if k % 2 == 0:
					var bp := pos_m + Vector3(dir.x * 3.2, 0.0, dir.y * 3.2)
					lm.box("Pot", bp + Vector3(0, 0.28, 0), Vector3(0.75, 0.56, 1.45), Basis(Vector3.UP, yaw))
					lm.lathe("Foliage", bp + Vector3(0, 0.55, 0), PackedVector2Array([
						Vector2(0.52, 0.0), Vector2(0.58, 0.36), Vector2(0.0, 0.62)]), 7)
					lm.lathe("Bougainvillea", bp + Vector3(0, 0.72, 0), PackedVector2Array([
						Vector2(0.46, 0.0), Vector2(0.42, 0.34), Vector2(0.0, 0.50)]), 7)
				placed += 1
	return placed

static func _street_side_life(lm: LandmarkMesh, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, centre: Vector2, r2: float, rects: Array, junc: Dictionary,
		ultra: bool, m2u: float) -> int:
	var motos := 0
	var vendors := 0
	var signs := 0
	var occ := {}
	for r in data.roads:
		if not (r is Dictionary):
			continue
		var rd: Dictionary = r
		var cls := str(rd.get("class", ""))
		if cls not in ["secondary", "tertiary", "residential", "unclassified", "primary", "living_street"] \
				or bool(rd.get("bridge", false)) or bool(rd.get("tunnel", false)) or bool(rd.get("area", false)):
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var half_m := float(rd.get("width_m", 6.0)) * 0.5
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg_u := a.distance_to(b)
			if seg_u < 12.0 * m2u:
				continue
			var dir := (b - a) / seg_u
			var nrm := Vector2(-dir.y, dir.x)

			# Junction corner: Thai blue street-name sign + red-white kerb stripe + occasional win-motorsai stand
			if signs < MAX_SIGNS and ParkedCars._near_junction(a, junc, 8.0 * m2u):
				var sp := a + dir * (5.5 * m2u) + nrm * ((half_m + 0.75) * m2u)
				if sp.distance_squared_to(centre) <= r2 and not _spot_taken(occ, sp, 12.0 * m2u) \
						and _pavement_ok(sp, ground, mask, rects):
					_mark(occ, sp, 12.0 * m2u)
					var sgy := ground.height_at_world(sp.x, sp.y) / m2u
					var sm := Vector3(sp.x / m2u, sgy, sp.y / m2u)
					var syaw := atan2(-nrm.x, -nrm.y)
					_thai_street_sign(lm, sm, syaw)
					# Painted red-and-white Thai no-parking corner kerb (`4 × 0.6 m` alternating blocks)
					var kb := a + dir * (4.0 * m2u) + nrm * ((half_m + 0.12) * m2u)
					var kgy := ground.height_at_world(kb.x, kb.y) / m2u
					var kbasis := Basis(Vector3.UP, atan2(dir.x, dir.y))
					for seg_i in 6:
						var kk := "RedPaint" if seg_i % 2 == 0 else "White"
						lm.box(kk, Vector3(kb.x / m2u, kgy + 0.09, kb.y / m2u) + kbasis * Vector3(0, 0, (float(seg_i) - 2.5) * 0.62),
							Vector3(0.22, 0.18, 0.60), kbasis)
					if ultra and _hash(sp.x, sp.y, 9.1) < 0.28:
						_win_motorsai_stand(lm, sm + Vector3(dir.x * 2.4, 0.0, dir.y * 2.4), syaw)
					signs += 1

			if not ultra:
				continue
			var steps := int(seg_u / (26.0 * m2u))
			for k in steps:
				var c := a + dir * ((float(k) + 0.5) * 26.0 * m2u)
				if c.distance_squared_to(centre) > r2 or ParkedCars._near_junction(c, junc, 9.0 * m2u):
					continue
				var ll := WorldScale.latlon_from_xz(c.x, c.y, data.latitude, data.longitude)
				var reg := CityStyles.region_at(ll.x, ll.y)
				if reg in ["bangkok_ratchadamnoen", "bangkok_civic"]:
					continue
				var side := 1.0 if _hash(c.x, c.y, 2.1) < 0.5 else -1.0
				var p := c + nrm * (side * (half_m + 1.35) * m2u)
				if _spot_taken(occ, p, 11.0 * m2u) or not _pavement_ok(p, ground, mask, rects):
					continue
				var gy := ground.height_at_world(p.x, p.y) / m2u
				var pm := Vector3(p.x / m2u, gy, p.y / m2u)
				var yaw := atan2(dir.x, dir.y)
				var h := _hash(p.x, p.y, 4.7)
				if h < 0.44 and motos < MAX_MOTO_CLUSTERS:
					_mark(occ, p, 11.0 * m2u)
					_motorbike_row(lm, pm, yaw, 4 + int(_hash(p.x, p.y, 7.3) * 2.99))
					motos += 1
				elif h > 0.66 and vendors < MAX_VENDORS and cls != "living_street":
					_mark(occ, p, 13.0 * m2u)
					_vendor_cart(lm, pm, yaw, int(_hash(p.x, p.y, 8.9) * 2.99))
					vendors += 1
	return motos + vendors + signs

static func _forecourt_shrines_and_topiary(lm: LandmarkMesh, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, centre: Vector2, r2: float, rects: Array, m2u: float) -> int:
	var placed := 0
	for b in data.buildings:
		if placed >= MAX_SHRINES or not (b is Dictionary):
			break
		var bd: Dictionary = b
		var bx := float(bd.get("x", 0.0))
		var bz := float(bd.get("z", 0.0))
		var bp := Vector2(bx, bz)
		if bp.distance_squared_to(centre) > r2 or LandmarkSites.in_model_rects(bp, rects):
			continue
		var sx := float(bd.get("size_x", 0.0)) / m2u
		var sz := float(bd.get("size_z", 0.0)) / m2u
		var kind := str(bd.get("kind", ""))
		if kind == "temple" or kind == "religious":
			# Potted clipped Thai topiary (`tako dat` cloud bonsai) flanking temple court edge (`BK-8.1`)
			for sgn in [-1.0, 1.0]:
				var tp := bp + Vector2(float(sgn) * (sx * 0.5 + 2.2) * m2u, (sz * 0.35) * m2u)
				if _pavement_ok(tp, ground, mask, rects):
					var tgy := ground.height_at_world(tp.x, tp.y) / m2u
					_tako_dat_pot(lm, Vector3(tp.x / m2u, tgy, tp.y / m2u))
					placed += 1
		elif sx * sz > 380.0 and _hash(bx, bz, 5.3) < 0.35:
			# Thai spirit house (`san phra phum`) on pedestal at forecourt corner (`BK-9.6`)
			var sp := bp + Vector2((sx * 0.5 + 1.8) * m2u, (sz * 0.5 + 1.8) * m2u)
			if _pavement_ok(sp, ground, mask, rects):
				var sgy := ground.height_at_world(sp.x, sp.y) / m2u
				_spirit_house(lm, Vector3(sp.x / m2u, sgy, sp.y / m2u))
				placed += 1
	return placed

static func _motorbike_row(lm: LandmarkMesh, origin: Vector3, street_yaw: float, n: int) -> void:
	# Angled kerbside row of parked Thai underbone scooters (`Honda Wave` / `Click` silhouette)
	var row_b := Basis(Vector3.UP, street_yaw)
	for i in n:
		var off := row_b * Vector3(0.0, 0.0, (float(i) - float(n - 1) * 0.5) * 0.88)
		var bike_b := Basis(Vector3.UP, street_yaw + 1.12)
		var body_key: String = ["RedPaint", "BlueSign", "White", "Dark"][(i + int(absf(origin.x))) % 4]
		var p := origin + off
		lm.frustum("Dark", p + bike_b * Vector3(0, 0.24, 0.58), 0.24, 0.24, 0.09, 8)
		lm.frustum("Dark", p + bike_b * Vector3(0, 0.24, -0.56), 0.24, 0.24, 0.10, 8)
		lm.box(body_key, p + bike_b * Vector3(0, 0.56, 0.10), Vector3(0.32, 0.42, 1.38), bike_b)
		lm.box("Dark", p + bike_b * Vector3(0, 0.78, -0.22), Vector3(0.28, 0.14, 0.68), bike_b)
		lm.box(body_key, p + bike_b * Vector3(0, 0.84, 0.46), Vector3(0.36, 0.46, 0.18), bike_b)
		lm.beam("Steel", p + bike_b * Vector3(-0.32, 1.04, 0.44), p + bike_b * Vector3(0.32, 1.04, 0.44), 0.04, 0.04)

static func _win_motorsai_stand(lm: LandmarkMesh, p: Vector3, yaw: float) -> void:
	# Small blue shade awning + bench + orange-vest stand board (`วินมอเตอร์ไซค์`, `BK-9.3`)
	var b := Basis(Vector3.UP, yaw)
	for sx in [-0.85, 0.85]:
		for sz in [-0.65, 0.65]:
			var post := p + b * Vector3(float(sx), 0.0, float(sz))
			lm.beam("Steel", post, post + Vector3(0, 2.05, 0), 0.04, 0.04)
	lm.box("UmbrellaB", p + Vector3(0, 2.10, 0), Vector3(1.90, 0.10, 1.50), b)
	lm.box("OrangeVest", p + b * Vector3(0.88, 1.35, 0.0), Vector3(0.06, 0.68, 0.48), b)
	lm.box("Steel", p + Vector3(0, 0.42, 0), Vector3(1.35, 0.08, 0.38), b)

static func _vendor_cart(lm: LandmarkMesh, p: Vector3, yaw: float, scheme: int) -> void:
	# Stainless-steel Bangkok pushcart (`rot khen`) + glass display case + striped umbrella +
	# plastic stools + hanging warm bare-bulb `VendorLamp` (`BK-9.6` & `BK-10`)
	var b := Basis(Vector3.UP, yaw)
	var ukey: String = ["UmbrellaA", "UmbrellaB", "UmbrellaC"][scheme % 3]
	lm.box("Steel", p + Vector3(0, 0.68, 0), Vector3(0.86, 0.56, 1.55), b)
	lm.box("White", p + b * Vector3(0.18, 1.16, -0.25), Vector3(0.42, 0.44, 0.68), b)
	lm.frustum("Steel", p + b * Vector3(-0.12, 0.96, 0.38), 0.22, 0.22, 0.28, 8)
	for sz in [-0.42, 0.42]:
		lm.frustum("Dark", p + b * Vector3(0.0, 0.26, float(sz)), 0.26, 0.26, 0.08, 8)
	lm.beam("Steel", p + Vector3(0, 0.96, 0), p + Vector3(0, 2.38, 0), 0.04, 0.04)
	lm.lathe(ukey, p + Vector3(0, 2.16, 0), PackedVector2Array([
		Vector2(1.35, 0.0), Vector2(0.75, 0.26), Vector2(0.02, 0.42)]), 8)
	lm.lathe("VendorLamp", p + b * Vector3(0.15, 1.88, 0.0), PackedVector2Array([
		Vector2(0.04, 0.0), Vector2(0.11, 0.08), Vector2(0.02, 0.16)]), 6)
	# Small table + 2 red/blue stackable plastic stools on pavement side
	var tp := p + b * Vector3(0.0, 0.0, 1.55)
	lm.box("Steel", tp + Vector3(0, 0.68, 0), Vector3(0.72, 0.05, 0.72), b)
	lm.beam("Steel", tp, tp + Vector3(0, 0.68, 0), 0.05, 0.05)
	for sgn in [-0.55, 0.55]:
		var sk := "RedPaint" if sgn < 0.0 else "UmbrellaB"
		lm.box(sk, tp + b * Vector3(float(sgn), 0.24, 0.0), Vector3(0.30, 0.46, 0.30), b)

static func _thai_street_sign(lm: LandmarkMesh, p: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	lm.beam("Steel", p, p + Vector3(0, 2.65, 0), 0.06, 0.06)
	lm.box("BlueSign", p + b * Vector3(0.0, 2.45, 0.38), Vector3(0.06, 0.28, 0.82), b)
	lm.box("White", p + b * Vector3(0.0, 2.61, 0.38), Vector3(0.07, 0.05, 0.84), b)

static func _spirit_house(lm: LandmarkMesh, p: Vector3) -> void:
	# Traditional miniature Thai *San Phra Phum* on a fluted single white column
	lm.box("White", p + Vector3(0, 0.14, 0), Vector3(0.95, 0.28, 0.95))
	lm.frustum("White", p + Vector3(0, 0.28, 0), 0.14, 0.11, 1.05, 8)
	lm.box("White", p + Vector3(0, 1.38, 0), Vector3(0.84, 0.12, 0.84))
	lm.box("Gold", p + Vector3(0, 1.66, 0), Vector3(0.56, 0.44, 0.56))
	lm.gable("RedPaint", p + Vector3(0, 1.88, 0), 0.72, 0.78, 0.36, Basis(), 0.10, "Gold")
	lm.spire("Gold", p + Vector3(0, 2.22, 0), 0.08, 0.38, 0.0, 4)

static func _tako_dat_pot(lm: LandmarkMesh, p: Vector3) -> void:
	# Glazed terracotta pot with multi-pad cloud-pruned Thai *tako dat* bonsai (`BK-8.1`)
	lm.frustum("Pot", p, 0.34, 0.44, 0.48, 8)
	lm.beam("Dark", p + Vector3(0, 0.46, 0), p + Vector3(0.06, 1.45, 0.0), 0.09, 0.06)
	for pad in [Vector3(-0.28, 1.10, 0.08), Vector3(0.26, 1.28, -0.06), Vector3(0.04, 1.56, 0.0)]:
		lm.lathe("Foliage", p + (pad as Vector3), PackedVector2Array([
			Vector2(0.38, 0.0), Vector2(0.34, 0.16), Vector2(0.0, 0.22)]), 7)

static func _pavement_ok(p: Vector2, ground: GroundTruth, mask: VegetationMask, rects: Array) -> bool:
	if not ground.is_inside(p.x, p.y) or ground.water_at(p.x, p.y) > 0.0:
		return false
	if LandmarkSites.in_model_rects(p, rects):
		return false
	return not mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER, 0.0)

static func _spot_taken(occ: Dictionary, p: Vector2, d: float) -> bool:
	var c := Vector2i(floori(p.x / d), floori(p.y / d))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for q: Vector2 in occ.get(c + Vector2i(dx, dz), []):
				if q.distance_squared_to(p) < d * d:
					return true
	return false

static func _mark(occ: Dictionary, p: Vector2, d: float) -> void:
	var c := Vector2i(floori(p.x / d), floori(p.y / d))
	if not occ.has(c):
		occ[c] = []
	(occ[c] as Array).append(p)

static func _hash(x: float, z: float, salt: float) -> float:
	return ParkedCars._hash(x, z, salt)
