class_name RoofClutter
extends RefCounted

## Rooftop clutter on flat roofs (desktop Ultra, Phase 4 of the Ultra
## pass): what a city's roofscape actually carries beyond BuildingDetail's
## few plant boxes, keyed by city and country region so a roof reads as
## that place from above:
##   - New York: wooden water towers on steel legs;
##   - Tokyo, Seoul, Hong Kong and East Asia: banks of AC condensers,
##     rooftop tanks and steel sign frames;
##   - the Gulf, Cairo and the Middle East: white and black water tanks
##     and satellite dishes;
##   - Athens, Cyprus and the Mediterranean east: solar water heaters
##     (a tilted collector and its tank);
##   - elsewhere: skylights, roof hatches, aerial masts, the odd dish,
##     and solar arrays on big roofs.
## A stair or lift overrun stands on most roofs over 150 m² everywhere.
## Every pick is seeded by the building, so the roofscape is stable. The
## pieces go into BuildingDetail's batch (one mesh per building, merged
## per cell by LodRing).

const ASIA := ["tokyo", "seoul", "hong_kong", "shanghai", "beijing", "bangkok", "singapore"]
const ASIA_REGIONS := ["japan", "east_asia", "southeast_asia"]
const TANK_CITIES := ["dubai", "cairo", "mumbai", "istanbul"]
const TANK_REGIONS := ["middle_east", "south_asia", "sub_saharan_africa", "latin_america"]
const SOLAR_HEATER_CITIES := ["athens"]
## Solar water heaters crown most flat roofs in Greece, Cyprus and Israel.
const SOLAR_HEATER_COUNTRIES := ["GR", "CY", "IL"]

const CORNERS: Array[Vector2] = [Vector2.ZERO, Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]

static var _mats: Dictionary = {}

## Adds one flat roof's clutter to `batch`. `c`, `u`, `v`, `lu`, `lv`:
## the roof's interior point, axes and half extents (BuildingDetail.add);
## `top` the roof deck height; `country` the ISO code ("" unknown).
static func add(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis,
		look: Dictionary, seed_v: float, area_m2: float, country: String = "", wall_m: float = 0.0) -> int:
	if area_m2 < 60.0:
		return 0
	var city := str(look.get("city", ""))
	var region := str(look.get("region", ""))
	var placed := 0
	if water_tower_allowed(look, wall_m) and area_m2 > 250.0 and _h(seed_v, 71) < 0.45:
		placed += _water_tower(batch, ring, c, u, v, lu, lv, top, basis, seed_v)
	# A stair or lift overrun crowns nearly every multi-storey flat roof.
	if area_m2 > 150.0 and _h(seed_v, 70) < 0.8:
		placed += _overrun(batch, ring, c, u, v, lu, lv, top, basis, seed_v)
	if city in ASIA or region in ASIA_REGIONS:
		placed += _condensers(batch, ring, c, u, v, lu, lv, top, basis, seed_v,
			clampi(int(area_m2 / 250.0), 1, 5))
		if _h(seed_v, 73) < 0.35:
			placed += _sign_frame(batch, ring, c, u, v, lu, lv, top, basis, seed_v)
	# Before the regional tanks: Israel is in the Middle East region.
	elif city in SOLAR_HEATER_CITIES or country.to_upper() in SOLAR_HEATER_COUNTRIES:
		placed += _solar_heaters(batch, ring, c, u, v, lu, lv, top, basis, seed_v, 1 + int(_h(seed_v, 76) * 3.0))
	elif city in TANK_CITIES or region in TANK_REGIONS:
		placed += _tanks(batch, ring, c, u, v, lu, lv, top, basis, seed_v, 1 + int(_h(seed_v, 74) * 3.0))
		placed += _dishes(batch, ring, c, u, v, lu, lv, top, basis, seed_v, int(_h(seed_v, 75) * 3.0))
	else:
		placed += _skylights(batch, ring, c, u, v, lu, lv, top, basis, seed_v)
		if area_m2 > 600.0 and _h(seed_v, 77) < 0.3:
			placed += _solar_array(batch, ring, c, u, v, lu, lv, top, basis, seed_v)
	# Everywhere: a roof hatch, an aerial mast or a dish now and then.
	if _h(seed_v, 78) < 0.55:
		placed += _piece(batch, ring, c, u, v, lu, lv, basis, seed_v, 80, top + 0.25 * _m(),
			"box", Vector3(0.9, 0.5, 0.9), "steel")
	if _h(seed_v, 79) < 0.3:
		placed += _piece(batch, ring, c, u, v, lu, lv, basis, seed_v, 82, top + 2.0 * _m(),
			"cyl", Vector3(0.08, 4.0, 0.08), "steel")
	return placed

## Wooden tanks belong on older mid-rise roofs, not glass supertalls.
static func water_tower_allowed(look: Dictionary, wall_m: float) -> bool:
	var levels := roundi(wall_m / maxf(float(look.get("floor_h", 3.2)), 1.0))
	return str(look.get("city", "")) == "new_york" and levels >= 6 and levels <= 20 \
		and str(look.get("era", "")) in ["new_york", "nyc_brownstone", "nyc_prewar"]

static func _m() -> float:
	return WorldScale.metres_to_units()

static func _h(seed_v: float, salt: int) -> float:
	return ArchitectureStyle._h(seed_v, salt)

## A spot on the roof for a piece `half` metres across each way (along
## u, v), offset within 0.8 of the room the half extents leave it; its
## centre and corners all on the roof, else Vector2.INF (an irregular
## footprint, or a roof too small for the piece).
static func _spot(ring: PackedVector2Array, c: Vector2, u: Vector2, v: Vector2,
		lu: float, lv: float, seed_v: float, salt: int, half: Vector2 = Vector2.ZERO) -> Vector2:
	var hu := half.x * _m()
	var hv := half.y * _m()
	if hu >= lu or hv >= lv:
		return Vector2.INF
	var du := (_h(seed_v, salt) - 0.5) * (lu - hu) * 1.6
	var dv := (_h(seed_v, salt + 1) - 0.5) * (lv - hv) * 1.6
	var p := c + u * du + v * dv
	for k: Vector2 in CORNERS:
		if not RingGeometry.point_in_ring(p + u * k.x * hu + v * k.y * hv, ring):
			return Vector2.INF
	return p

## One primitive of `size` metres centred at height `y` on a seeded spot.
static func _piece(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, basis: Basis, seed_v: float,
		salt: int, y: float, kind: String, size: Vector3, mat: String) -> int:
	var p := _spot(ring, c, u, v, lu, lv, seed_v, salt, Vector2(size.x, size.z) * 0.5)
	if p == Vector2.INF:
		return 0
	batch.add(kind, Transform3D(basis.scaled_local(size * _m()), Vector3(p.x, y, p.y)), _mat(mat))
	return 1

static func _water_tower(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis, seed_v: float) -> int:
	var r := lerpf(1.8, 2.6, _h(seed_v, 92))
	var p := _spot(ring, c, u, v, lu, lv, seed_v, 90, Vector2(r, r) * 1.05)
	if p == Vector2.INF:
		return 0
	var m := _m()
	var legs := 3.0 * m
	var tank_h := lerpf(3.2, 4.4, _h(seed_v, 93))
	for k in 4:
		var a := PI * 0.5 * float(k) + PI * 0.25
		var lp := p + (u * cos(a) + v * sin(a)) * r * 0.75 * m
		batch.add("cyl", Transform3D(basis.scaled_local(Vector3(0.18, 3.0, 0.18) * m),
			Vector3(lp.x, top + legs * 0.5, lp.y)), _mat("steel"))
	batch.add("cyl", Transform3D(basis.scaled_local(Vector3(r * 2.0, tank_h, r * 2.0) * m),
		Vector3(p.x, top + legs + tank_h * 0.5 * m, p.y)), _mat("cedar"))
	batch.add("cone", Transform3D(basis.scaled_local(Vector3(r * 2.1, 1.4, r * 2.1) * m),
		Vector3(p.x, top + legs + tank_h * m + 0.7 * m, p.y)), _mat("cedar_roof"))
	return 1

static func _overrun(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis, seed_v: float) -> int:
	var h := lerpf(2.8, 3.8, _h(seed_v, 86))
	return _piece(batch, ring, c, u, v, lu, lv, basis, seed_v, 84, top + h * 0.5 * _m(), "box",
		Vector3(lerpf(3.0, 6.0, _h(seed_v, 87)), h, lerpf(2.6, 4.5, _h(seed_v, 88))), "core")

## `banks` rows of 3-6 condensers side by side, the way they line East
## Asian roofs, plus a steel water tank on half the roofs.
static func _condensers(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis,
		seed_v: float, banks: int) -> int:
	var placed := 0
	var m := _m()
	for i in banks:
		var n := 3 + int(_h(seed_v, 110 + i) * 4.0)
		var p := _spot(ring, c, u, v, lu, lv, seed_v, 100 + i * 2, Vector2(float(n) * 0.525, 0.2))
		if p == Vector2.INF:
			continue
		for k in n:
			var q := p + u * (float(k) - float(n - 1) * 0.5) * 1.05 * m
			if not RingGeometry.point_in_ring(q, ring):
				continue
			batch.add("box", Transform3D(basis.scaled_local(Vector3(0.9, 0.7, 0.4) * m),
				Vector3(q.x, top + 0.35 * m, q.y)), _mat("ac"))
			placed += 1
	if _h(seed_v, 97) < 0.5:
		placed += _piece(batch, ring, c, u, v, lu, lv, basis, seed_v, 98, top + 1.0 * _m(),
			"box", Vector3(2.0, 2.0, 1.6), "tank_steel")
	return placed

static func _sign_frame(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis, seed_v: float) -> int:
	return _piece(batch, ring, c, u, v, lu, lv, basis, seed_v, 120, top + 2.5 * _m(),
		"box", Vector3(lerpf(4.0, 8.0, _h(seed_v, 122)), 5.0, 0.25), "steel")

static func _tanks(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis,
		seed_v: float, n: int) -> int:
	var placed := 0
	for i in n:
		var white := _h(seed_v, 190 + i) < 0.6
		placed += _piece(batch, ring, c, u, v, lu, lv, basis, seed_v, 130 + i * 3, top + 0.7 * _m(),
			"cyl", Vector3(1.2, 1.4, 1.2), "tank_white" if white else "tank_black")
	return placed

static func _dishes(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis,
		seed_v: float, n: int) -> int:
	var placed := 0
	for i in n:
		var p := _spot(ring, c, u, v, lu, lv, seed_v, 140 + i * 3, Vector2(0.5, 0.5))
		if p == Vector2.INF:
			continue
		# A dish faces up and toward the equator: tip the hemisphere over.
		var tilt := basis * Basis(Vector3.RIGHT, deg_to_rad(-60.0))
		batch.add("hemi", Transform3D(tilt.scaled_local(Vector3(1.0, 0.35, 1.0) * _m()),
			Vector3(p.x, top + 1.0 * _m(), p.y)), _mat("dish"))
		batch.add("cyl", Transform3D(basis.scaled_local(Vector3(0.06, 1.0, 0.06) * _m()),
			Vector3(p.x, top + 0.5 * _m(), p.y)), _mat("steel"))
		placed += 1
	return placed

static func _solar_heaters(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis,
		seed_v: float, n: int) -> int:
	var placed := 0
	var m := _m()
	var tilt := basis * Basis(Vector3.RIGHT, deg_to_rad(40.0))
	for i in n:
		# The collector and the tank behind it.
		var p := _spot(ring, c, u, v, lu, lv, seed_v, 150 + i * 3, Vector2(1.0, 1.2))
		if p == Vector2.INF:
			continue
		batch.add("box", Transform3D(tilt.scaled_local(Vector3(2.0, 0.08, 1.2) * m),
			Vector3(p.x, top + 0.6 * m, p.y)), _mat("solar"))
		var tp := p + v * 0.9 * m
		var side := basis * Basis(Vector3.FORWARD, PI * 0.5)
		batch.add("cyl", Transform3D(side.scaled_local(Vector3(0.55, 1.9, 0.55) * m),
			Vector3(tp.x, top + 1.2 * m, tp.y)), _mat("tank_white"))
		placed += 1
	return placed

static func _skylights(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis, seed_v: float) -> int:
	var placed := 0
	for i in int(_h(seed_v, 160) * 4.0):
		placed += _piece(batch, ring, c, u, v, lu, lv, basis, seed_v, 161 + i * 2, top + 0.2 * _m(),
			"box", Vector3(1.6, 0.4, 1.2), "skylight")
	return placed

static func _solar_array(batch: BuildingDetail.Batch, ring: PackedVector2Array, c: Vector2,
		u: Vector2, v: Vector2, lu: float, lv: float, top: float, basis: Basis, seed_v: float) -> int:
	var m := _m()
	var tilt := basis * Basis(Vector3.RIGHT, deg_to_rad(25.0))
	var rows := clampi(int(lv * 1.2 / (2.4 * m)), 1, 6)
	var cols := clampi(int(lu * 1.2 / (1.8 * m)), 1, 8)
	var placed := 0
	for r in rows:
		for k in cols:
			var du := (float(k) - float(cols - 1) * 0.5) * 1.8 * m
			var dv := (float(r) - float(rows - 1) * 0.5) * 2.4 * m
			var p := c + u * du + v * dv
			if not RingGeometry.point_in_ring(p, ring):
				continue
			batch.add("box", Transform3D(tilt.scaled_local(Vector3(1.7, 0.06, 1.1) * m),
				Vector3(p.x, top + 0.5 * m, p.y)), _mat("solar"))
			placed += 1
	return placed

static func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key] as Material
	var m := StandardMaterial3D.new()
	match key:
		"steel":
			m.albedo_color = Color(0.46, 0.47, 0.48)
			m.metallic = 0.7
			m.roughness = 0.45
		"cedar":
			m.albedo_color = Color(0.36, 0.25, 0.16)
			m.roughness = 0.9
		"cedar_roof":
			m.albedo_color = Color(0.22, 0.20, 0.19)
			m.roughness = 0.8
		"core":
			m.albedo_color = Color(0.62, 0.61, 0.58)
			m.roughness = 0.85
		"ac":
			m.albedo_color = Color(0.70, 0.71, 0.70)
			m.roughness = 0.6
		"tank_steel":
			m.albedo_color = Color(0.58, 0.60, 0.62)
			m.metallic = 0.5
			m.roughness = 0.5
		"tank_white":
			m.albedo_color = Color(0.82, 0.82, 0.80)
			m.roughness = 0.6
		"tank_black":
			m.albedo_color = Color(0.08, 0.08, 0.09)
			m.roughness = 0.5
		"dish":
			m.albedo_color = Color(0.80, 0.80, 0.78)
			m.roughness = 0.5
		"solar":
			m.albedo_color = Color(0.05, 0.07, 0.12)
			m.metallic = 0.3
			m.roughness = 0.2
		"skylight":
			m.albedo_color = Color(0.20, 0.26, 0.30)
			m.metallic = 0.4
			m.roughness = 0.15
	_mats[key] = m
	return m
