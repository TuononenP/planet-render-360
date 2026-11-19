class_name LandmarkFtSamppalinna
extends RefCounted

## Samppalinna Outdoor Swimming Stadium (Samppalinnan maauimala, Turku):
## 1955 modernist complex by Abel Sandelin, renovated 2017 by LEMMETTI.
## Built in true metres (+X NNE lap end, -X SSW diving end, +Z ESE
## hillside terraces, -Z WNW grandstand & Volter Kilven katu) from OSM
## ways 133733723/994992137/994992138/133733721/133733722/133733720 and
## CityGML LoD2 elevations (vtj 1020076434); turned by yaw_deg = -79.5.

const POOL_X0 := -25.5
const POOL_X1 := 26.5
const DECK_Y := 0.25
const WATER_Y := 0.08
const COPING_Y := 0.32
const POOL_SEGS := 16

static func _pool_half_z(x: float) -> float:
	return 8.25 + 1.15 * cos(PI * (x - 0.5) / 52.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_pool_and_deck(lm)
	_diving_tower(lm)
	_grandstand_and_box(lm)
	_kebony_pavilion(lm)
	_sunbathing_terraces(lm)
	_stairs_and_lights(lm)
	lm.commit(model)
	_childrens_pool(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Deck", LandmarkMaterials.pbr("pavement", "#9B9B96", 3.0))
	lm.use("Coping", LandmarkMaterials.pbr("pavement", "#ECECE8", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("render", "#EEECE6", 3.0))
	lm.use("SlateDark", LandmarkMaterials.pbr("membrane", "#272E36", 3.0, 0.72))
	lm.use("Kebony", LandmarkMaterials.pbr("wood", "#68533E", 2.0, 0.72))
	lm.use("Metal", LandmarkMaterials.paint("#C8CDD0", 0.38, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#2A3B44"))
	lm.use("WaterShallow", LandmarkMaterials.pool_water("#2BC2D2", 0.08))
	lm.use("WaterDeep", LandmarkMaterials.pool_water("#1689A8", 0.08))
	lm.use("WaterKids", LandmarkMaterials.pool_water("#8ADCE6", 0.08))
	lm.use("LaneDark", LandmarkMaterials.pbr("pavement", "#0D4258", 2.0))
	lm.use("AccentBlue", LandmarkMaterials.paint("#1D8BD1", 0.45, 0.05))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF2D6", 0.8))

static func _rect(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float,
		y0: float, y1: float, bevel: float = -1.0) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)), Basis(), bevel)

static func _pool_and_deck(lm: LandmarkMesh) -> void:
	# Concrete surround around the curved 50 m opening (never covering the water).
	_rect(lm, "Deck", -37.0, POOL_X0, -22.5, 14.0, -0.8, DECK_Y)
	_rect(lm, "Deck", POOL_X1 + 3.5, 33.0, -22.5, 14.0, -0.8, DECK_Y)
	_rect(lm, "Deck", POOL_X0, POOL_X1, -22.5, -13.2, -0.8, DECK_Y)
	# Wide white east & north perimeter apron (way 994992137) + semicircular shower niches.
	_rect(lm, "Coping", POOL_X1, POOL_X1 + 3.5, -9.2, 13.1, -0.4, COPING_Y)
	_rect(lm, "Deck", POOL_X1, POOL_X1 + 3.5, -22.5, -9.2, -0.8, DECK_Y)
	_rect(lm, "Deck", POOL_X1, POOL_X1 + 3.5, 13.1, 14.0, -0.8, DECK_Y)
	_rect(lm, "Coping", -29.4, POOL_X0, -9.0, 13.1, -0.4, COPING_Y)
	# Curved side aprons, white coping strips, and basin inner walls.
	var deep_x := -7.5
	for i in POOL_SEGS:
		var t0 := float(i) / float(POOL_SEGS)
		var t1 := float(i + 1) / float(POOL_SEGS)
		var x0 := lerpf(POOL_X0, POOL_X1, t0)
		var x1 := lerpf(POOL_X0, POOL_X1, t1)
		var z0 := _pool_half_z(x0)
		var z1 := _pool_half_z(x1)
		# West curved concrete deck (-Z) + 0.7 m white coping kerb.
		_slab_quad(lm, "Deck", Vector3(x0, DECK_Y, -13.2), Vector3(x1, DECK_Y, -13.2),
			Vector3(x1, DECK_Y, -z1 - 0.7), Vector3(x0, DECK_Y, -z0 - 0.7))
		_slab_quad(lm, "Coping", Vector3(x0, COPING_Y, -z0 - 0.7), Vector3(x1, COPING_Y, -z1 - 0.7),
			Vector3(x1, COPING_Y, -z1), Vector3(x0, COPING_Y, -z0))
		# East wide white apron (+Z) from pool edge out to +12.5, then dark deck to +14.0.
		_slab_quad(lm, "Coping", Vector3(x0, COPING_Y, z0), Vector3(x1, COPING_Y, z1),
			Vector3(x1, COPING_Y, 12.5), Vector3(x0, COPING_Y, 12.5))
		_slab_quad(lm, "Deck", Vector3(x0, DECK_Y, 12.5), Vector3(x1, DECK_Y, 12.5),
			Vector3(x1, DECK_Y, 14.0), Vector3(x0, DECK_Y, 14.0))
		# Basin inner white walls down below water level.
		lm.quad("Coping", Vector3(x0, -0.4, -z0), Vector3(x1, -0.4, -z1),
			Vector3(x1, COPING_Y, -z1), Vector3(x0, COPING_Y, -z0), Vector3.BACK)
		lm.quad("Coping", Vector3(x1, -0.4, z1), Vector3(x0, -0.4, z0),
			Vector3(x0, COPING_Y, z0), Vector3(x1, COPING_Y, z1), Vector3.FORWARD)
		# Pool water surface split between deep diving end and shallow lap end.
		if x1 <= deep_x:
			_water_quad(lm, "WaterDeep", x0, x1, z0, z1)
		elif x0 >= deep_x:
			_water_quad(lm, "WaterShallow", x0, x1, z0, z1)
		else:
			var zm := _pool_half_z(deep_x)
			_water_quad(lm, "WaterDeep", x0, deep_x, z0, zm)
			_water_quad(lm, "WaterShallow", deep_x, x1, zm, z1)
	# End walls at -X and +X + depth transition stripe.
	var hz_s := _pool_half_z(POOL_X0)
	var hz_n := _pool_half_z(POOL_X1)
	lm.quad("Coping", Vector3(POOL_X0, -0.4, hz_s), Vector3(POOL_X0, -0.4, -hz_s),
		Vector3(POOL_X0, COPING_Y, -hz_s), Vector3(POOL_X0, COPING_Y, hz_s), Vector3.RIGHT)
	lm.quad("Coping", Vector3(POOL_X1, -0.4, -hz_n), Vector3(POOL_X1, -0.4, hz_n),
		Vector3(POOL_X1, COPING_Y, hz_n), Vector3(POOL_X1, COPING_Y, -hz_n), Vector3.LEFT)
	_rect(lm, "LaneDark", deep_x - 0.14, deep_x + 0.14, -_pool_half_z(deep_x) + 0.2,
		_pool_half_z(deep_x) - 0.2, WATER_Y, WATER_Y + 0.01, 0.0)
	# Semicircular shower/footwash pads mapped in way 994992137.
	for sx: float in [-25.0, -8.8, 7.0, 22.8]:
		lm.frustum("Deck", Vector3(sx, COPING_Y + 0.01, 11.4), 0.72, 0.72, 0.03, 12)
	for sz: float in [-5.2, 5.1]:
		lm.frustum("Deck", Vector3(28.3, COPING_Y + 0.01, sz), 0.72, 0.72, 0.03, 12)
	# 8 bottom lane stripes with end T-bars and 7 floating lane ropes.
	for lane in 8:
		var lz := -7.0 + float(lane) * 2.0
		_rect(lm, "LaneDark", POOL_X0 + 1.8, POOL_X1 - 1.8, lz - 0.12, lz + 0.12, WATER_Y, WATER_Y + 0.012, 0.0)
		_rect(lm, "LaneDark", POOL_X0 + 1.6, POOL_X0 + 1.9, lz - 0.5, lz + 0.5, WATER_Y, WATER_Y + 0.012, 0.0)
		_rect(lm, "LaneDark", POOL_X1 - 1.9, POOL_X1 - 1.6, lz - 0.5, lz + 0.5, WATER_Y, WATER_Y + 0.012, 0.0)
		# Starting block at the north (+X) end.
		_rect(lm, "Concrete", POOL_X1 + 0.15, POOL_X1 + 0.75, lz - 0.28, lz + 0.28, COPING_Y, COPING_Y + 0.48, 0.0)
	for rope in 7:
		var rz := -6.0 + float(rope) * 2.0
		_rect(lm, "AccentBlue", POOL_X0 + 0.2, POOL_X0 + 5.2, rz - 0.07, rz + 0.07, WATER_Y, WATER_Y + 0.05, 0.0)
		_rect(lm, "AccentBlue", POOL_X1 - 5.2, POOL_X1 - 0.2, rz - 0.07, rz + 0.07, WATER_Y, WATER_Y + 0.05, 0.0)
		for seg in 20:
			var sx0 := lerpf(POOL_X0 + 5.2, POOL_X1 - 5.2, float(seg) / 20.0)
			var sx1 := lerpf(POOL_X0 + 5.2, POOL_X1 - 5.2, float(seg + 1) / 20.0)
			_rect(lm, "Coping" if seg % 2 == 0 else "AccentBlue", sx0, sx1, rz - 0.06, rz + 0.06,
				WATER_Y, WATER_Y + 0.045, 0.0)
	# Chrome side pool ladders.
	for lx: float in [-19.0, 20.0]:
		for sgn: float in [-1.0, 1.0]:
			var lz := sgn * (_pool_half_z(lx) + 0.15)
			lm.beam("Metal", Vector3(lx - 0.3, WATER_Y, lz), Vector3(lx - 0.3, COPING_Y + 0.8, lz), 0.05)
			lm.beam("Metal", Vector3(lx + 0.3, WATER_Y, lz), Vector3(lx + 0.3, COPING_Y + 0.8, lz), 0.05)

static func _slab_quad(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	lm.quad(key, a, b, c, d, Vector3.UP)

static func _water_quad(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float) -> void:
	lm.quad(key, Vector3(x0, WATER_Y, -z0), Vector3(x1, WATER_Y, -z1),
		Vector3(x1, WATER_Y, z1), Vector3(x0, WATER_Y, z0), Vector3.UP)

static func _diving_tower(lm: LandmarkMesh) -> void:
	# 1955 sculptural white concrete diving tower at south (-X) deep end.
	var tz := 2.2
	# Central tapered spine rising to 10 m platform.
	lm.beam("Concrete", Vector3(-27.6, DECK_Y, tz), Vector3(-26.8, 10.0, tz), 0.9, 1.4, Vector3.BACK)
	lm.beam("Concrete", Vector3(-28.4, DECK_Y, tz), Vector3(-27.2, 5.1, tz), 0.7, 1.1, Vector3.BACK)
	# 10 m platform (y = 10.08 m) cantilevered forward over pool edge.
	_rect(lm, "Concrete", -29.2, -23.8, tz - 1.5, tz + 1.5, 9.80, 10.12, 0.05)
	_haunch(lm, -27.2, tz, 8.6, 9.85, -24.4, 1.1)
	_platform_rail(lm, -29.1, -24.0, tz - 1.42, tz + 1.42, 10.12)
	# 7.5 m platform cantilevered toward east (+Z).
	_rect(lm, "Concrete", -28.6, -24.3, tz + 0.8, tz + 3.4, 7.30, 7.60, 0.05)
	_haunch(lm, -27.3, tz + 1.6, 6.2, 7.35, -24.8, 0.85)
	_platform_rail(lm, -28.5, -24.4, tz + 0.9, tz + 3.32, 7.60)
	# 5.0 m platform cantilevered toward west (-Z).
	_rect(lm, "Concrete", -28.6, -24.3, tz - 3.3, tz - 0.7, 4.82, 5.10, 0.05)
	_haunch(lm, -27.4, tz - 1.5, 3.8, 4.85, -24.8, 0.85)
	_platform_rail(lm, -28.5, -24.4, tz - 3.22, tz - 0.8, 5.10)
	# Rear concrete access stair spine.
	for k in 16:
		var t := float(k) / 15.0
		var sx := lerpf(-29.9, -28.5, t)
		var sy := lerpf(DECK_Y + 0.3, 9.8, t)
		_rect(lm, "Deck", sx - 0.4, sx + 0.4, tz - 0.5, tz + 0.5, sy - 0.14, sy + 0.06, 0.0)
	lm.beam("Metal", Vector3(-30.0, DECK_Y + 1.0, tz - 0.55), Vector3(-28.6, 10.9, tz - 0.55), 0.05)
	lm.beam("Metal", Vector3(-30.0, DECK_Y + 1.0, tz + 0.55), Vector3(-28.6, 10.9, tz + 0.55), 0.05)
	# 3 m concrete board & two 1 m springboards beside the tower (-Z side).
	_rect(lm, "Concrete", -27.8, -24.6, -3.5, -1.9, DECK_Y, 3.10, 0.04)
	_rect(lm, "Concrete", -27.8, -24.3, -3.5, -1.9, 2.88, 3.12, 0.03)
	_platform_rail(lm, -27.7, -24.5, -3.42, -1.98, 3.12)
	for sz in [-4.8, -6.2]:
		_rect(lm, "Concrete", -27.3, -26.5, sz - 0.3, sz + 0.3, DECK_Y, 1.05, 0.0)
		_rect(lm, "Coping", -27.3, -24.3, sz - 0.25, sz + 0.25, 1.05, 1.13, 0.0)
		lm.beam("Metal", Vector3(-27.3, 1.85, sz - 0.32), Vector3(-25.8, 1.85, sz - 0.32), 0.04)
		lm.beam("Metal", Vector3(-27.3, 1.85, sz + 0.32), Vector3(-25.8, 1.85, sz + 0.32), 0.04)

static func _haunch(lm: LandmarkMesh, x_root: float, z: float, y0: float, y1: float, x_tip: float, w: float) -> void:
	lm.beam("Concrete", Vector3(x_root, y0, z), Vector3(x_tip, y1, z), 0.36, w, Vector3.BACK)

static func _platform_rail(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, y: float) -> void:
	for ry in [y + 0.52, y + 1.02]:
		lm.beam("Metal", Vector3(x0, ry, z0), Vector3(x1, ry, z0), 0.045)
		lm.beam("Metal", Vector3(x0, ry, z1), Vector3(x1, ry, z1), 0.045)
		lm.beam("Metal", Vector3(x0, ry, z0), Vector3(x0, ry, z1), 0.045)
	for px in [x0, (x0 + x1) * 0.5, x1]:
		lm.beam("Metal", Vector3(px, y, z0), Vector3(px, y + 1.05, z0), 0.045)
		lm.beam("Metal", Vector3(px, y, z1), Vector3(px, y + 1.05, z1), 0.045)
	lm.beam("Metal", Vector3(x0, y, (z0 + z1) * 0.5), Vector3(x0, y + 1.05, (z0 + z1) * 0.5), 0.045)

static func _grandstand_and_box(lm: LandmarkMesh) -> void:
	# Under-grandstand changing rooms extending down toward Volter Kilven katu.
	_rect(lm, "Concrete", -27.2, 26.2, -22.5, -13.2, -6.0, DECK_Y, 0.0)
	_rect(lm, "SlateDark", -27.2, 26.2, -22.5, -22.3, -6.0, -2.1, 0.0)
	_rect(lm, "Glass", -25.0, 24.0, -22.58, -22.46, -1.7, -0.55, 0.0)
	for i in 16:
		var mx := -25.0 + float(i) * (49.0 / 15.0)
		_rect(lm, "Concrete", mx - 0.12, mx + 0.12, -22.62, -22.45, -1.75, -0.5, 0.0)
	# Central Volter Kilven katu entrance recess and canopy.
	_rect(lm, "Kebony", -5.2, 0.4, -22.65, -22.2, -5.8, -2.5, 0.0)
	_rect(lm, "Concrete", -6.0, 1.2, -23.6, -22.4, -2.5, -2.15, 0.0)
	# Back promenade railing & 9 flagpoles behind the grandstand.
	lm.beam("Metal", Vector3(-27.0, DECK_Y + 1.05, -22.4), Vector3(26.0, DECK_Y + 1.05, -22.4), 0.05)
	for i in 18:
		var px := lerpf(-27.0, 26.0, float(i) / 17.0)
		lm.beam("Metal", Vector3(px, DECK_Y, -22.4), Vector3(px, DECK_Y + 1.08, -22.4), 0.04)
	# 6 stepped spectator rows with dark navy-slate slatted benches, split round the lifeguard box.
	var spans := [[-26.3, -6.5], [1.6, 25.1]]
	for sp in spans:
		var sx0: float = sp[0]
		var sx1: float = sp[1]
		for row in 6:
			var rz0 := -13.2 - float(row + 1) * 1.0
			var rz1 := -13.2 - float(row) * 1.0
			var ry := 0.55 + float(row) * 0.46
			_rect(lm, "Concrete", sx0, sx1, rz0, rz1, 0.0, ry, 0.0)
			_rect(lm, "SlateDark", sx0 + 0.15, sx1 - 0.15, rz0 + 0.18, rz1 - 0.18, ry, ry + 0.10, 0.0)
	# Concrete stair aisles across the grandstand.
	for ax in [-25.6, -14.8, -7.2, 2.3, 13.6, 24.4]:
		for row in 6:
			var rz0 := -13.2 - float(row + 1) * 1.0
			var ry := 0.58 + float(row) * 0.46
			_rect(lm, "Deck", ax - 0.65, ax + 0.65, rz0, rz0 + 1.0, ry - 0.1, ry + 0.12, 0.0)
	for i in 9:
		var fx := lerpf(-25.0, 24.0, float(i) / 8.0)
		lm.frustum("Metal", Vector3(fx, 3.3, -19.4), 0.05, 0.03, 5.2, 6)
	# Central lifeguard / timing box (way 133733721, CityGML 28.81 / 29.82 m ASL).
	_rect(lm, "Concrete", -6.4, 1.6, -18.3, -14.8, DECK_Y, 2.65, 0.05)
	_rect(lm, "SlateDark", -6.3, 1.5, -18.2, -14.9, 2.65, 2.80, 0.0)
	_rect(lm, "Concrete", -4.0, -0.7, -15.6, -12.2, DECK_Y, 4.10, 0.05)
	_rect(lm, "Glass", -4.08, -0.62, -15.4, -12.14, 2.65, 3.72, 0.0)
	_rect(lm, "SlateDark", -3.9, -0.8, -15.5, -12.3, 4.10, 4.30, 0.0)

static func _kebony_pavilion(lm: LandmarkMesh) -> void:
	# 2017 LEMMETTI Kebony timber pavilion & Kahvila Pikku Otava (CityGML vtj 1020076434).
	_rect(lm, "Deck", -46.8, -36.8, -10.8, 18.0, -2.5, DECK_Y, 0.0)
	# Slightly mono-pitched vertical Kebony volume (3.45 m rear -> 3.90 m pool front).
	var x0 := -46.5
	var x1 := -37.0
	var z0 := -10.5
	var z1 := 17.7
	var yr := 3.45
	var yf := 3.90
	lm.quad("Kebony", Vector3(x0, DECK_Y, z1), Vector3(x0, DECK_Y, z0),
		Vector3(x0, yr, z0), Vector3(x0, yr, z1), Vector3.LEFT)
	lm.quad("Kebony", Vector3(x1, DECK_Y, z0), Vector3(x1, DECK_Y, z1),
		Vector3(x1, yf, z1), Vector3(x1, yf, z0), Vector3.RIGHT)
	lm.quad("Kebony", Vector3(x0, DECK_Y, z0), Vector3(x1, DECK_Y, z0),
		Vector3(x1, yf, z0), Vector3(x0, yr, z0), Vector3.FORWARD)
	lm.quad("Kebony", Vector3(x1, DECK_Y, z1), Vector3(x0, DECK_Y, z1),
		Vector3(x0, yr, z1), Vector3(x1, yf, z1), Vector3.BACK)
	# Matte charcoal roof + low roof hatches.
	lm.quad("SlateDark", Vector3(x0 - 0.3, yr, z1 + 0.3), Vector3(x0 - 0.3, yr, z0 - 0.3),
		Vector3(x1 + 0.3, yf, z0 - 0.3), Vector3(x1 + 0.3, yf, z1 + 0.3), Vector3.UP)
	_rect(lm, "SlateDark", -43.5, -40.5, -4.0, 2.0, 3.6, 4.15, 0.0)
	_rect(lm, "SlateDark", -43.5, -40.5, 8.0, 13.0, 3.6, 4.15, 0.0)
	# Vertical timber battens + pool-facing cafe windows & doors.
	for i in 15:
		var bz := lerpf(-9.8, 17.0, float(i) / 14.0)
		_rect(lm, "SlateDark", -37.05, -36.92, bz - 0.06, bz + 0.06, DECK_Y, yf - 0.1, 0.0)
	_rect(lm, "Glass", -37.04, -36.94, -8.5, 4.5, 0.9, 2.85, 0.0)
	_rect(lm, "Glass", -45.0, -38.5, -10.56, -10.46, 0.9, 2.85, 0.0)
	# White concrete chimney/vent shaft on the SE corner.
	_rect(lm, "Concrete", -44.8, -42.8, 15.6, 17.5, 3.5, 5.6, 0.0)
	# SW cafe terrace and two bright blue parasols.
	_rect(lm, "Deck", -43.5, -36.5, -17.5, -10.5, -2.0, 0.22, 0.0)
	for pz in [-12.6, -15.6]:
		lm.frustum("Metal", Vector3(-39.4, 0.22, pz), 0.06, 0.06, 2.6, 8)
		lm.lathe("AccentBlue", Vector3(-39.4, 2.55, pz),
			PackedVector2Array([Vector2(1.75, 0.0), Vector2(0.0, 0.55)]), 8)

static func _sunbathing_terraces(lm: LandmarkMesh) -> void:
	# Three stepped concrete sunbathing tiers along east (+Z) and north (+X),
	# curving smoothly around the NE corner at (30.0, 14.0).
	var cx := 30.0
	var cz := 14.0
	var arc := 8
	for tier in 3:
		var r_in := float(tier) * 3.0
		var r_out := r_in + 3.0
		var y := 0.95 + float(tier) * 0.75
		# Solid backing riser down to -1.0 m so slope never exposes a gap.
		_rect(lm, "Deck", -29.5, cx, cz + r_in, cz + r_out, -1.0, y - 0.06, 0.0)
		_rect(lm, "Deck", -29.5, cx, cz + r_in + 0.30, cz + r_out, y - 0.06, y, 0.0)
		_rect(lm, "Coping", -29.5, cx, cz + r_in, cz + r_in + 0.32, y - 0.14, y + 0.04, 0.0)
		_rect(lm, "Deck", cx + r_in, cx + r_out, -15.0, cz, -1.0, y - 0.06, 0.0)
		_rect(lm, "Deck", cx + r_in + 0.30, cx + r_out, -15.0, cz, y - 0.06, y, 0.0)
		_rect(lm, "Coping", cx + r_in, cx + r_in + 0.32, -15.0, cz, y - 0.14, y + 0.04, 0.0)
		# Curved NE corner arc segments.
		for k in arc:
			var a0 := PI * 0.5 * float(k) / float(arc)
			var a1 := PI * 0.5 * float(k + 1) / float(arc)
			var c0 := Vector2(cos(a0), sin(a0))
			var c1 := Vector2(cos(a1), sin(a1))
			var i0 := Vector3(cx + c0.x * r_in, y, cz + c0.y * r_in)
			var i1 := Vector3(cx + c1.x * r_in, y, cz + c1.y * r_in)
			var k0 := Vector3(cx + c0.x * (r_in + 0.30), y, cz + c0.y * (r_in + 0.30))
			var k1 := Vector3(cx + c1.x * (r_in + 0.30), y, cz + c1.y * (r_in + 0.30))
			var o0 := Vector3(cx + c0.x * r_out, y, cz + c0.y * r_out)
			var o1 := Vector3(cx + c1.x * r_out, y, cz + c1.y * r_out)
			_slab_quad(lm, "Coping", i0, i1, k1, k0)
			_slab_quad(lm, "Deck", k0, k1, o1, o0)
			lm.quad("Deck", Vector3(i0.x, -1.0, i0.z), Vector3(i1.x, -1.0, i1.z),
				i1, i0, Vector3(-c0.x, 0.0, -c0.y))
	# Rear white retaining kerb behind the top terrace + central stair to children's pool.
	_rect(lm, "Coping", -29.5, 27.6, 22.8, 23.2, -1.0, 2.75, 0.0)
	_rect(lm, "Coping", 38.8, 39.2, -15.0, cz, -1.0, 2.75, 0.0)
	for step in 12:
		var t := float(step) / 11.0
		var sz := lerpf(14.0, 25.5, t)
		var sy := lerpf(0.35, 3.0, t)
		_rect(lm, "Concrete", 27.6, 30.8, sz - 0.5, sz + 0.5, sy - 0.6, sy, 0.0)

static func _stairs_and_lights(lm: LandmarkMesh) -> void:
	# NW & SW exterior street-access stairs and small NW entry booth (way 1532390121).
	for sx in [-31.0, 25.5]:
		for k in 10:
			var t := float(k) / 9.0
			var sz := lerpf(-22.4, -26.8, t)
			var sy := lerpf(DECK_Y, -3.2, t)
			_rect(lm, "Deck", sx - 1.2, sx + 1.2, sz - 0.28, sz + 0.28, sy - 0.5, sy, 0.0)
	_rect(lm, "Concrete", 30.0, 36.7, -23.7, -22.6, -2.0, 0.65, 0.0)
	_rect(lm, "SlateDark", 29.9, 36.8, -23.8, -22.5, 0.65, 0.80, 0.0)
	# Slender twin-head floodlight poles around the stadium perimeter.
	for pos in [Vector3(-18.0, 2.45, 23.0), Vector3(16.0, 2.45, 23.0), Vector3(38.8, 2.45, -2.0),
			Vector3(-27.0, 0.25, -21.8), Vector3(25.0, 0.25, -21.8), Vector3(-37.0, 0.25, 14.0)]:
		var p: Vector3 = pos
		lm.frustum("Metal", p, 0.14, 0.08, 9.2, 8)
		lm.box("Metal", p + Vector3(0.0, 9.2, 0.0), Vector3(0.3, 0.14, 1.5))
		lm.box("Lamp", p + Vector3(0.0, 9.3, -0.55), Vector3(0.24, 0.18, 0.36))
		lm.box("Lamp", p + Vector3(0.0, 9.3, 0.55), Vector3(0.24, 0.18, 0.36))

static func _childrens_pool(model: Node3D, base_lm: LandmarkMesh) -> void:
	# Upper hillside children's pool (way 133733720) seated via SEAT_META.
	var lm := LandmarkMesh.new()
	for k in ["Coping", "WaterKids", "AccentBlue"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	_rect(lm, "Coping", -9.5, 9.5, -7.2, 7.2, -3.5, 1.15, 0.0)
	_rect(lm, "Coping", -9.5, -7.2, -7.2, 7.2, 1.15, 1.26, 0.0)
	_rect(lm, "Coping", 7.2, 9.5, -7.2, 7.2, 1.15, 1.26, 0.0)
	_rect(lm, "Coping", -7.2, 7.2, -7.2, -5.2, 1.15, 1.26, 0.0)
	_rect(lm, "Coping", -7.2, 7.2, 5.2, 7.2, 1.15, 1.26, 0.0)
	# Recessed shallow turquoise children's pool water (way 133733720).
	_rect(lm, "WaterKids", -7.2, 7.2, -5.2, 5.2, 1.15, 1.19, 0.0)
	# Safety rail along downhill (-Z) rim & stairs down toward main terrace.
	lm.beam("AccentBlue", Vector3(-9.2, 2.12, -7.0), Vector3(9.2, 2.12, -7.0), 0.045)
	for i in 7:
		var px := lerpf(-9.2, 9.2, float(i) / 6.0)
		lm.beam("Coping", Vector3(px, 1.20, -7.0), Vector3(px, 2.15, -7.0), 0.045)
	for step in 7:
		var t := float(step) / 6.0
		_rect(lm, "Coping", -1.8, 1.8, lerpf(-7.2, -10.5, t) - 0.3, lerpf(-7.2, -10.5, t) + 0.3,
			lerpf(-1.0, -2.5, t), lerpf(1.15, -1.5, t), 0.0)
	# Small blue children's waterslide on the south side.
	_rect(lm, "Coping", -5.2, -4.2, -5.6, -4.8, 1.20, 2.65, 0.0)
	lm.beam("AccentBlue", Vector3(-4.7, 2.65, -5.0), Vector3(-4.2, 1.35, -2.4), 0.65, 0.22, Vector3.RIGHT)
	var child := Node3D.new()
	child.name = "ChildrensPool"
	child.position = Vector3(39.0, 0.0, 33.5)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 11.4, 22.0), Vector3(-6.0, 0.1, 0.0), 58.0, 0.8, 70.0, Color(1.0, 0.94, 0.84)],
		[Vector3(16.0, 11.4, 22.0), Vector3(8.0, 0.1, 0.0), 58.0, 0.8, 70.0, Color(1.0, 0.94, 0.84)],
		[Vector3(-27.0, 9.2, -21.0), Vector3(-12.0, 1.0, 2.0), 55.0, 0.75, 65.0, Color(1.0, 0.94, 0.84)],
		[Vector3(25.0, 9.2, -21.0), Vector3(12.0, 0.2, 0.0), 55.0, 0.75, 65.0, Color(1.0, 0.94, 0.84)],
	])
