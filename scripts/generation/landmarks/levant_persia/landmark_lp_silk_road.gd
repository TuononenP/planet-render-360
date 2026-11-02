class_name LandmarkLpSilkRoad
extends RefCounted

## Persian and Timurid Islamic architecture in true metres: the Imam
## (Shah) Mosque of Isfahan, the Registan of Samarkand and the Po-i-Kalyan
## complex of Bukhara. Glazed tile (cobalt, turquoise) over baked brick, tall
## pointed iwan portals (pishtaqs), bulbous domes and tapering minarets.

# --- Imam (Shah) Mosque, Isfahan ---

## Built with the portal facing +Z (yaw 177 turns it onto the north-facing
## square). Courtyard 70 x 70 m turned 45 degrees to the qibla (axis towards
## +X, -Z), four iwans, arcaded walls, the sanctuary with the 52 m double-
## shell dome (swelling turquoise bulb on a cobalt drum), the twin 48 m
## minarets at its iwan, the 33 m vestibule dome and the 27 m entrance portal
## with its twin 42 m minarets between two arcaded wings.
static func imam_mosque(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C8A569", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2459A8", 2.0, 0.34))
	lm.use("Turq", LandmarkMaterials.pbr("render", "#2BA7B0", 2.0, 0.3))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E6D9B6", 2.0, 0.5))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CBB890", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#17120E", 3.0, 0.92))
	lm.use("Gold", LandmarkMaterials.gold())
	var phi := -PI * 0.25
	var rot := Basis(Vector3.UP, phi)
	lm.box("Court", Vector3(0, -0.2, 0), Vector3(80, 0.4, 80), rot)
	lm.box("Dark", rot * Vector3(0, 0.0, 0), Vector3(20, 0.15, 12), rot)
	# Courtyard walls (two storeys of blind arches) with the four iwans.
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var turn := Basis(Vector3.UP, yaw)
		var inward := turn * Vector3(0, 0, 1)
		var along := turn * Vector3(1, 0, 0)
		var sanct := k == 0
		var iw := 32.0 if sanct else 24.0
		var seg := (80.0 - iw) * 0.5
		for s in [-1.0, 1.0]:
			var cu: float = s * (iw * 0.5 + seg * 0.5)
			var wc := -inward * 37.5 + along * cu
			lm.box("Brick", rot * (wc + Vector3(0, 7.0, 0)), Vector3(seg, 14.0, 5.0), rot * turn)
			lm.box("Tile", rot * (wc + Vector3(0, 14.4, 0)), Vector3(seg, 0.8, 5.2), rot * turn)
		var face := -inward * 35.0 + inward * 0.04
		for u in [-33.5, -27.0, -20.5, 20.5, 27.0, 33.5]:
			if absf(u) < iw * 0.5 + 2.0:
				continue
			var p: Vector3 = rot * (face + along * u)
			LandmarkLpParts.arch_panel(lm, "Dark", p, yaw + phi, 1.6, 3.0, 1.6)
			LandmarkLpParts.arch_panel(lm, "Dark", p + Vector3(0, 7.0, 0), yaw + phi, 1.4, 2.4, 1.4)
		LandmarkLpParts.iwan(lm, "Tile", "Dark", rot * (-inward * 34.0), yaw + phi, iw,
			34.0 if sanct else 21.0, 7.5 if sanct else 5.0, 17.0 if sanct else 10.0,
			11.5 if sanct else 7.0, 8.0 if sanct else 5.0)
	# Sanctuary: iwan hall, chamber, side prayer halls, the 52 m dome, minarets.
	lm.box("Brick", rot * Vector3(0, 14.0, -48.0), Vector3(32, 28.0, 12), rot)
	lm.box("Brick", rot * Vector3(0, 13.5, -72.0), Vector3(36, 27.0, 36), rot)
	lm.box("Tile", rot * Vector3(0, 27.4, -72.0), Vector3(36.6, 0.8, 36.6), rot)
	for s in [-1.0, 1.0]:
		var hp := rot * Vector3(s * 28.0, 0, -72.0)
		lm.box("Brick", hp + Vector3(0, 8.0, 0), Vector3(20, 16.0, 36), rot)
		lm.frustum("Tile", hp + Vector3(0, 16.0, 0), 6.0, 6.0, 3.0, 16)
		lm.lathe("Turq", hp + Vector3(0, 19.0, 0), LandmarkLpParts.bulb_profile(6.2, 7.5, 1.08), 16)
		_tile_minaret(lm, "Brick", "Tile", rot * Vector3(s * 18.5, 0, -39.0), 2.2, 48.0)
	var dc := rot * Vector3(0, 0, -72.0)
	lm.frustum("Tile", dc + Vector3(0, 27.8, 0), 12.5, 12.5, 7.4, 28)
	lm.lathe("Turq", dc + Vector3(0, 35.2, 0), LandmarkLpParts.bulb_profile(12.7, 15.6, 1.1, 14, 1.25), 28)
	LandmarkLpParts.needle(lm, "Gold", dc + Vector3(0, 50.8, 0),
		PackedVector2Array([Vector2(0, 0.4), Vector2(1.2, 0.06)]), 8)
	# Entrance: facade wings on the square, vestibule with its dome, portal and minarets.
	var zf := 68.0
	for s in [-1.0, 1.0]:
		var wc := Vector3(-30.0 + s * 31.0, 0, zf - 3.0)
		lm.box("Brick", wc + Vector3(0, 6.5, 0), Vector3(32, 13.0, 6.0))
		lm.box("Tile", wc + Vector3(0, 13.4, 0), Vector3(32.4, 0.8, 6.2))
		for u in [-10.5, -3.5, 3.5, 10.5]:
			LandmarkLpParts.arch_panel(lm, "Dark", wc + Vector3(u, 0, 3.04), 0.0, 1.7, 3.2, 1.7)
			LandmarkLpParts.arch_panel(lm, "Dark", wc + Vector3(u, 7.2, 3.04), 0.0, 1.4, 2.4, 1.4)
	lm.box("Brick", Vector3(-30.0, 10.0, 46.0), Vector3(26, 20.0, 30))
	lm.frustum("Tile", Vector3(-30.0, 20.0, 46.0), 9.0, 9.0, 4.0, 16)
	lm.lathe("Turq", Vector3(-30.0, 24.0, 46.0), LandmarkLpParts.bulb_profile(9.2, 9.0, 1.1), 20)
	LandmarkLpParts.iwan(lm, "Tile", "Dark", Vector3(-30.0, 0, zf + 1.0), 0.0, 30.0, 27.0, 6.6, 14.0, 8.8, 8.0)
	for s in [-1.0, 1.0]:
		_tile_minaret(lm, "Brick", "Tile", Vector3(-30.0 + s * 12.8, 0, zf - 3.0), 1.9, 42.0)
	lm.commit(model)

## Slender tiled minaret of height h: brick shaft with glazed bands, a
## corbelled balcony, an eight-sided glazed lantern and a bulb cap.
static func _tile_minaret(lm: LandmarkMesh, brick: String, tile: String, base: Vector3, r: float,
		h: float) -> void:
	var body := h * 0.8
	lm.lathe(brick, base, PackedVector2Array([Vector2(r * 1.35, 0.0), Vector2(r * 1.35, h * 0.06),
		Vector2(r * 1.12, h * 0.08), Vector2(r * 0.82, body)]), 16)
	for f in [0.2, 0.42, 0.62, 0.76]:
		var rr := r * lerpf(1.12, 0.82, (f - 0.08) / 0.72) + 0.1
		lm.frustum(tile, base + Vector3(0, h * f, 0), rr, rr, h * 0.05, 16)
	lm.frustum(brick, base + Vector3(0, body, 0), r * 0.95, r * 1.7, h * 0.03, 16)
	lm.frustum(brick, base + Vector3(0, body + h * 0.03, 0), r * 1.7, r * 1.7, h * 0.015, 16)
	lm.frustum(tile, base + Vector3(0, body + h * 0.045, 0), r * 0.9, r * 0.9, h * 0.075, 10)
	lm.lathe(tile, base + Vector3(0, body + h * 0.12, 0),
		LandmarkLpParts.bulb_profile(r * 1.0, h * 0.08, 1.15, 8), 12)

# --- Registan, Samarkand ---

## Compass frame with the square open to the south: Ulugh Beg Madrasa (west,
## 1420), Sher-Dor (east, 1636, two ribbed turquoise domes, 38 m portal) and
## Tilya-Kori (north, 1660, long two-storey facade, blue 35 m dome), each a
## tiled pishtaq between two storeys of blind arches and four corner minarets.
static func registan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C9A872", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2A63B0", 2.0, 0.34))
	lm.use("Turq", LandmarkMaterials.pbr("render", "#30AEB6", 2.0, 0.3))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E6D9B6", 2.0, 0.5))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CFBE98", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#17120E", 3.0, 0.92))
	lm.box("Court", Vector3(0, -0.15, 29.0), Vector3(112, 0.3, 74))
	# Ulugh Beg (west, faces east) and Sher-Dor (east, faces west).
	_madrasa(lm, Vector3(-50, 0, 33.5), PI * 0.5, 58.0, 52.0, 12.0, 22.0, 35.0, 6.2, 14.0, 11.0, 33.0)
	_madrasa(lm, Vector3(50, 0, 33.5), -PI * 0.5, 62.0, 56.0, 12.5, 24.0, 38.0, 6.6, 16.0, 12.0, 30.0)
	for s in [-1.0, 1.0]:
		var dp := Vector3(50.0 + 14.0, 0, 33.5 + s * 19.5)
		lm.frustum("Tile", dp + Vector3(0, 12.5, 0), 5.6, 5.6, 8.4, 20)
		LandmarkLpParts.ribbed_dome(lm, "Turq", dp + Vector3(0, 20.9, 0),
			LandmarkLpParts.bulb_profile(6.3, 9.6, 1.12, 12, 1.15), 16, 0.045)
	# Tilya-Kori (north, faces south) with the mosque dome behind its portal.
	_madrasa(lm, Vector3(0, 0, -4.5), 0.0, 84.0, 60.0, 13.0, 22.0, 27.0, 5.6, 13.0, 9.0, 24.0)
	var dc := Vector3(0, 0, -34.0)
	lm.frustum("Tile", dc + Vector3(0, 13.0, 0), 10.0, 10.0, 8.0, 24)
	LandmarkLpParts.ribbed_dome(lm, "Turq", dc + Vector3(0, 21.0, 0),
		LandmarkLpParts.bulb_profile(10.8, 14.0, 1.1, 12, 1.2), 20, 0.03)
	lm.commit(model)

## One madrasa: a body of `width` x `depth` standing behind the front plane
## point `p` (facing `yaw`), two tiers of blind arches on the wings, the
## tiled pishtaq (pw x ph, niche half-width a, spring, rise) and four
## corner minarets (the front pair mh tall, the rear pair two thirds).
static func _madrasa(lm: LandmarkMesh, p: Vector3, yaw: float, width: float, depth: float, wall_h: float,
		pw: float, ph: float, a: float, spring: float, rise: float, mh: float) -> void:
	var r := LandmarkLpParts.across(yaw)
	var f := LandmarkLpParts.outward(yaw)
	var basis := Basis(Vector3.UP, yaw)
	lm.box("Brick", p - f * depth * 0.5 + Vector3(0, wall_h * 0.5, 0), Vector3(width, wall_h, depth), basis)
	lm.box("Tile", p + Vector3(0, wall_h + 0.4, 0) - f * 0.1, Vector3(width + 0.4, 0.8, 0.8), basis)
	var u := pw * 0.5 + 5.0
	while u < width * 0.5 - 4.0:
		for s in [-1.0, 1.0]:
			var q: Vector3 = p + r * (s * u) + f * 0.04
			LandmarkLpParts.arch_panel(lm, "Dark", q, yaw, 1.5, 2.7, 1.5)
			LandmarkLpParts.arch_panel(lm, "Dark", q + Vector3(0, 6.6, 0), yaw, 1.3, 2.2, 1.3)
		u += 5.6
	LandmarkLpParts.iwan(lm, "Tile", "Dark", p + f * 1.5, yaw, pw, ph, a, spring, rise, 5.5)
	for s in [-1.0, 1.0]:
		_tile_minaret(lm, "Brick", "Tile", p + r * (s * (width * 0.5 - 2.4)) - f * 2.4, 2.1, mh)
		_tile_minaret(lm, "Brick", "Tile", p + r * (s * (width * 0.5 - 2.4)) - f * (depth - 2.4), 2.1, mh * 0.66)

# --- Kalyan Minaret and Po-i-Kalyan, Bukhara ---

## The 47 m baked-brick Kalyan Minaret (1127) at the south-east corner of the
## Kalyan Mosque, which fills the west of the square with its arcaded
## courtyard of small domes, its tiled portal and the blue 36 m dome; the
## Mir-i-Arab Madrasa (1535) faces it from the east with two blue domes,
## bazaar and baths on the north and south. Compass frame.
static func kalyan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C4A068", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2A63B0", 2.0, 0.34))
	lm.use("Turq", LandmarkMaterials.pbr("render", "#30AEB6", 2.0, 0.3))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CBB78E", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#17120E", 3.0, 0.92))
	lm.box("Court", Vector3(32, -0.15, -5), Vector3(60, 0.3, 80))
	# Kalyan Mosque: gallery ring round a 94 x 56 m court, sanctuary and dome.
	lm.box("Court", Vector3(-58, -0.15, -5), Vector3(116, 0.3, 80))
	lm.box("Brick", Vector3(-58, 7.0, -39.0), Vector3(120, 14.0, 12.0))
	lm.box("Brick", Vector3(-58, 7.0, 29.0), Vector3(120, 14.0, 12.0))
	lm.box("Brick", Vector3(-4.0, 7.0, -5.0), Vector3(12.0, 14.0, 80.0))
	lm.box("Brick", Vector3(-103.0, 9.5, -5.0), Vector3(30.0, 19.0, 80.0))
	for i in 22:
		for z in [-39.0, 29.0]:
			_small_dome(lm, Vector3(-112.0 + 5.4 * float(i), 14.0, z), 2.6)
	for i in 7:
		_small_dome(lm, Vector3(-4.0, 14.0, -35.0 + 11.0 * float(i)), 2.6)
	LandmarkLpParts.iwan(lm, "Tile", "Dark", Vector3(3.5, 0, -5.0), PI * 0.5, 24.0, 30.0, 6.0, 15.0, 9.5, 6.0)
	var dc := Vector3(-103.0, 19.0, -5.0)
	lm.frustum("Tile", dc, 11.0, 11.0, 6.0, 24)
	lm.lathe("Turq", dc + Vector3(0, 6.0, 0), LandmarkLpParts.bulb_profile(11.2, 11.0, 1.08, 12, 1.1), 24)
	# Mir-i-Arab Madrasa (east, faces west) with its two blue domes.
	_madrasa(lm, Vector3(62, 0, -5.0), -PI * 0.5, 70.0, 56.0, 14.0, 24.0, 30.0, 6.0, 15.0, 9.5, 24.0)
	for s in [-1.0, 1.0]:
		var dp := Vector3(62.0 + 22.0, 14.0, -5.0 + s * 16.0)
		lm.frustum("Tile", dp, 7.5, 7.5, 6.0, 20)
		lm.lathe("Turq", dp + Vector3(0, 6.0, 0), LandmarkLpParts.bulb_profile(7.8, 11.0, 1.1, 12, 1.2), 20)
	# Bazaar (north) and baths (south) of the kosh with their small domes.
	lm.box("Brick", Vector3(32, 3.5, -49.0), Vector3(60, 7.0, 10.0))
	lm.box("Brick", Vector3(32, 3.5, 40.0), Vector3(60, 7.0, 10.0))
	for x in [16.0, 28.0, 40.0, 52.0]:
		_small_dome(lm, Vector3(x, 7.0, -49.0), 3.4)
		_small_dome(lm, Vector3(x, 7.0, 40.0), 3.4)
	_kalyan_minaret(lm, Vector3(8.0, 0, 50.5))
	lm.commit(model)

static func _small_dome(lm: LandmarkMesh, base: Vector3, r: float) -> void:
	lm.lathe("Brick", base, LandmarkLpParts.dome_profile(r, r * 0.85, 3), 8)

## 47 m brick minaret: 9 m base tapering to 6 m under the rotunda, ten
## ornamental brick belts, a glazed blue inscription frieze, the muqarnas
## cornice, the sixteen-arched lantern and a small conical cap.
static func _kalyan_minaret(lm: LandmarkMesh, base: Vector3) -> void:
	lm.lathe("Brick", base + Vector3(0, -1.0, 0), PackedVector2Array([Vector2(5.5, 0.0), Vector2(5.5, 4.0),
		Vector2(4.5, 4.0), Vector2(3.0, 38.0)]), 16)
	for y in [7.0, 12.5, 17.0, 21.5, 25.5, 29.0, 34.5]:
		var rr := lerpf(4.5, 3.0, (y - 3.0) / 35.0) + 0.16
		lm.frustum("Brick", base + Vector3(0, y, 0), rr, rr, 0.6, 16)
	var rt := lerpf(4.5, 3.0, 29.5 / 35.0) + 0.14
	lm.frustum("Tile", base + Vector3(0, 30.2, 0), rt, rt, 2.4, 16)
	lm.frustum("Brick", base + Vector3(0, 37.0, 0), 3.1, 4.4, 3.0, 16)
	lm.frustum("Brick", base + Vector3(0, 40.0, 0), 4.6, 4.6, 0.5, 16)
	lm.frustum("Brick", base + Vector3(0, 40.5, 0), 3.1, 3.1, 5.5, 16)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Dark", base + Vector3(cos(a) * 3.1, 43.0, sin(a) * 3.1), Vector3(0.25, 3.4, 1.3),
			Basis(Vector3.UP, -a))
	lm.frustum("Tile", base + Vector3(0, 46.0, 0), 3.35, 3.35, 0.4, 16)
	lm.lathe("Brick", base + Vector3(0, 46.0, 0), PackedVector2Array([Vector2(3.3, 0.0), Vector2(1.6, 0.6),
		Vector2(0.1, 1.0)]), 16)
