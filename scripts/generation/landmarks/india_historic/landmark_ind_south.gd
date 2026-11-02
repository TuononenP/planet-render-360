class_name LandmarkIndSouth
extends RefCounted

## Two Dravida temples of Tamil Nadu in true metres: the Brihadisvara
## Temple of Thanjavur and the Meenakshi Amman Temple of Madurai. Both
## are built facing +X (east); the registry yaw turns Thanjavur onto its
## real bearing.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")
const ID = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_detail.gd")

## Brihadisvara Temple (66 m to the kalasam; 1003-10): the granite vimana
## on its 30 m square moulded base, two storeys of walls with projecting
## bays, pilasters and deity niches, 13 receding tiers each ringed by a
## parapet of kuta and shala pavilions, the 80-tonne capstone with its
## corner Nandi pairs, the octagonal dome with its four kudu arches and
## the kalasam; the ardha, maha and mukha mandapas with their side stairs;
## the 16-pillared Nandi mandapa and the monolithic Nandi; the two-storey
## cloister round the 240 x 122 m inner court with the three-tiered
## Rajarajan gopura, the outer wall with the five-tiered Keralantakan
## gopura (30 m), and the Subrahmanya and Chandikeswara shrines.
static func brihadisvara_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8678", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4C443C", 2.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#C9B79A", 3.0))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#A89B86", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Pave", Vector3(60, 0.02, 0), Vector3(300.0, 0.04, 150.0))
	_vimana(lm)
	# Mandapas: ardha, maha and mukha, flat-roofed, pilastered walls with
	# niches, a parapet, and the side stairs of the ardha mandapa.
	for blk in [[14.0, 28.0, 9.0, 12.5], [28.0, 48.0, 11.5, 13.0], [48.0, 62.0, 8.0, 9.5]]:
		var x0: float = blk[0]
		var x1: float = blk[1]
		var cx := (x0 + x1) * 0.5
		var bw := x1 - x0
		var hz: float = blk[2]
		var top: float = blk[3]
		lm.box("Granite", Vector3(cx, 1.6, 0), Vector3(bw + 1.0, 3.2, hz * 2.0 + 1.0))
		lm.box("Granite", Vector3(cx, top * 0.5, 0), Vector3(bw, top, hz * 2.0))
		lm.box("Granite", Vector3(cx, top + 0.3, 0), Vector3(bw + 1.0, 0.7, hz * 2.0 + 1.0))
		for sz in [-1.0, 1.0]:
			var fb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
			ID.pilasters(lm, "Granite", Vector3(x0, 3.2, sz * hz), Vector3(x1, 3.2, sz * hz), Vector3(0, 0, sz),
				int(bw / 2.2), top - 3.6, 0.6, 0.35)
			ID.arcade_wall(lm, "Granite", "Dark", Vector3(cx, 4.6, sz * hz), fb, bw, 5.0, 0.3, maxi(int(bw / 4.5), 2), 1.6,
				3.6, "round")
		ID.hara(lm, "Granite", "Plaster", Vector3(cx, top + 0.65, 0), bw - 0.4, hz * 2.0 - 0.4, 1.4, 3)
	for sz in [-1.0, 1.0]:
		IU.stairs(lm, "Granite", Vector3(21.0, 0, sz * 13.5), Basis(Vector3.UP, 0.0 if sz > 0.0 else PI), 6.0, 6,
			0.53, 0.8)
		LandmarkKits.statue_figure(lm, "Granite", Vector3(17.0, 3.2, sz * 10.6), 3.6, false)
	lm.box("Dark", Vector3(62.05, 6.0, 0), Vector3(0.2, 5.0, 3.2))
	IU.stairs(lm, "Granite", Vector3(62, 0, 0), Basis(Vector3.UP, PI * 0.5), 9.0, 6, 0.53, 0.9)
	_nandi_mandapa(lm, Vector3(90, 0, 0))
	# Inner cloister round the 240 x 122 m court with the Rajarajan
	# gopura, the outer wall with the Keralantakan gopura.
	_cloister(lm, -61.0, 180.0, 61.0)
	_ring(lm, -85.0, 210.0, 76.0, 7.0, 3.0, 10.0)
	var cols: Array[String] = ["Plaster", "Granite"]
	IU.gopura(lm, "Granite", cols, "Gilt", Vector3(180, 0, 0), Basis(Vector3.UP, PI * 0.5), 22.0, 14.0,
		10.0, 3, 3.6, 5.0, 7.5)
	IU.gopura(lm, "Granite", cols, "Gilt", Vector3(210, 0, 0), Basis(Vector3.UP, PI * 0.5), 26.0, 16.0,
		11.0, 5, 3.4, 5.5, 8.0)
	# Shrine towers: Subrahmanya (north-west) and Chandikeswara (south).
	_shrine(lm, Vector3(-30, 0, -34), 11.0, 7.0, 5, 3.4, "Plaster")
	_shrine(lm, Vector3(-4, 0, 30), 7.0, 5.0, 3, 2.6, "Plaster")
	lm.commit(model)

## The vimana at the origin: base mouldings, two storeys of walls with
## the projecting bhadra bays, pilasters and two rows of deity niches,
## 13 receding tiers with their pavilion parapets, the capstone and dome.
static func _vimana(lm: LandmarkMesh) -> void:
	# Upapitha and adhishthana: plinth, rounded kumuda, kapota, yali band.
	lm.box("Granite", Vector3(0, 0.7, 0), Vector3(36.0, 1.4, 36.0))
	lm.box("Granite", Vector3(0, 2.0, 0), Vector3(32.4, 1.2, 32.4))
	lm.lathe("Granite", Vector3(0, 2.6, 0), PackedVector2Array([Vector2(15.6, 0), Vector2(16.0, 0.4),
		Vector2(16.0, 0.8), Vector2(15.6, 1.2)]), 4, 1.414, 1.414, PI * 0.25, false)
	lm.box("Granite", Vector3(0, 4.2, 0), Vector3(31.0, 0.8, 31.0))
	lm.box("Dark", Vector3(0, 4.85, 0), Vector3(31.4, 0.5, 31.4))
	# Walls: two storeys, a mid kapota band and the heavy top cornice.
	lm.box("Granite", Vector3(0, 13.4, 0), Vector3(28.0, 16.8, 28.0))
	lm.box("Granite", Vector3(0, 13.4, 0), Vector3(29.6, 0.9, 29.6))
	lm.box("Granite", Vector3(0, 22.0, 0), Vector3(30.6, 1.2, 30.6))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Projecting bays: the central bhadra and the corner karnas.
		lm.box("Granite", b * Vector3(0, 13.4, 14.4), Vector3(9.0, 16.8, 0.8), b)
		for sx in [-1.0, 1.0]:
			lm.box("Granite", b * Vector3(sx * 12.0, 13.4, 14.25), Vector3(4.0, 16.8, 0.5), b)
		for storey in [[5.1, 8.0], [13.9, 7.6]]:
			var y0: float = storey[0]
			var hh: float = storey[1]
			ID.pilasters(lm, "Granite", b * Vector3(-14.0, y0, 14.5), b * Vector3(14.0, y0, 14.5), b * Vector3(0, 0, 1), 14,
				hh, 0.55, 0.3)
			for k in 3:
				var x := (float(k) - 1.0) * 8.5
				var big := 1.25 if k == 1 else 1.0
				var z := 14.8 if k == 1 else 14.5
				ID.arcade_wall(lm, "Granite", "Dark", b * Vector3(x, y0 + 0.8, z), b, 3.6 * big, 6.0 * big, 0.4, 1,
					2.4 * big, 5.0 * big, "round")
				lm.lathe("Granite", b * Vector3(x, y0 + 0.9, z + 0.2), PackedVector2Array([Vector2(0.45 * big, 0),
					Vector2(0.55 * big, 1.6 * big), Vector2(0.42 * big, 2.8 * big), Vector2(0.3 * big, 3.3 * big),
					Vector2(0.0, 3.9 * big)]), 8)
	ID.hara(lm, "Granite", "Granite", Vector3(0, 22.6, 0), 29.0, 29.0, 1.6, 5)
	# 13 receding tiers: a pilastered wall, the kapota eave and the hara.
	var y := 22.6
	for i in 13:
		var w := lerpf(27.0, 9.0, pow(float(i) / 12.0, 0.95))
		lm.box("Granite", Vector3(0, y + 0.6, 0), Vector3(w, 1.2, w))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box("Dark", b * Vector3(0, y + 0.6, w * 0.5 + 0.02), Vector3(w * 0.22, 0.8, 0.2), b, 0.0)
			lm.box("Granite", b * Vector3(0, y + 0.6, w * 0.5 + 0.2), Vector3(w * 0.36, 1.2, 0.4), b, 0.0)
		lm.box("Granite", Vector3(0, y + 1.38, 0), Vector3(w + 0.9, 0.36, w + 0.9))
		ID.hara(lm, "Granite", "Granite", Vector3(0, y + 1.56, 0), w - 0.2, w - 0.2, 0.71, 5 if w > 18.0 else 3)
		y += 2.27
	# Capstone with Nandis, neck, octagonal dome with kudus, and the kalasam: 51.5 -> 66 m.
	lm.box("Granite", Vector3(0, 52.95, 0), Vector3(8.2, 1.8, 8.2))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_nandi(lm, Vector3(sx * 3.1, 53.85, sz * 3.1), Vector3(sx, 0, sz).normalized(), 0.75)
	lm.frustum("Granite", Vector3(0, 53.85, 0), 3.1, 2.9, 2.5, 8, PI / 8.0)
	lm.lathe("Granite", Vector3(0, 56.35, 0), PackedVector2Array([Vector2(3.3, 0), Vector2(3.9, 0.7),
		Vector2(3.8, 2.2), Vector2(3.1, 3.9), Vector2(1.9, 5.3), Vector2(0.9, 6.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		ID.arcade_wall(lm, "Granite", "Dark", b * Vector3(0, 56.6, 3.75), b, 3.0, 3.4, 0.35, 1, 1.6, 2.6, "round")
	U.finial(lm, "Gilt", Vector3(0, 62.2, 0), 3.8, 0.55)

## Seated Nandi bull of body length 4 x s at `p`, facing `dir`.
static func _nandi(lm: LandmarkMesh, p: Vector3, dir: Vector3, s: float) -> void:
	var b := Basis.looking_at(-dir)
	lm.box("Granite", p + Vector3(0, 0.25 * s, 0), Vector3(2.2 * s, 0.5 * s, 4.2 * s), b)
	lm.box("Granite", p + Vector3(0, 1.2 * s, 0) - dir * 0.2 * s, Vector3(1.9 * s, 1.5 * s, 3.4 * s), b)
	lm.box("Granite", p + Vector3(0, 2.0 * s, 0) + dir * 0.7 * s, Vector3(1.1 * s, 0.8 * s, 1.0 * s), b)
	lm.box("Granite", p + Vector3(0, 1.9 * s, 0) + dir * 1.9 * s, Vector3(0.9 * s, 1.3 * s, 0.9 * s), b)
	for sx in [-1.0, 1.0]:
		var side: Vector3 = dir.cross(Vector3.UP).normalized() * sx
		lm.beam("Granite", p + Vector3(0, 2.5 * s, 0) + dir * 1.9 * s + side * 0.3 * s,
			p + Vector3(0, 2.9 * s, 0) + dir * 1.8 * s + side * 0.6 * s, 0.16 * s, 0.16 * s)

## Nandi mandapa at `p`: the platform with its stair, 16 pillars with
## square and octagonal sections, the flat roof with its parapet, and the
## 6 m monolithic Nandi facing the sanctum (-X).
static func _nandi_mandapa(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Granite", p + Vector3(0, 0.8, 0), Vector3(17.0, 1.6, 15.0))
	IU.stairs(lm, "Granite", p + Vector3(8.5, 0, 0), Basis(Vector3.UP, PI * 0.5), 5.0, 3, 0.53, 0.8)
	for i in 4:
		for j in 4:
			var c := p + Vector3(-7.0 + 4.67 * float(i), 1.6, (float(j) - 1.5) * 4.0)
			lm.box("Granite", c + Vector3(0, 0.5, 0), Vector3(0.8, 1.0, 0.8))
			lm.frustum("Granite", c + Vector3(0, 1.0, 0), 0.38, 0.38, 2.6, 8, PI / 8.0)
			lm.box("Granite", c + Vector3(0, 3.9, 0), Vector3(0.8, 0.6, 0.8))
			lm.box("Granite", c + Vector3(0, 4.45, 0), Vector3(1.4, 0.5, 0.9), Basis(), 0.0)
	lm.box("Granite", p + Vector3(0, 6.95, 0), Vector3(18.0, 0.7, 16.0))
	ID.chhajja_ring(lm, "Granite", p + Vector3(0, 6.6, 0), 17.0, 15.0, 1.0, 0.5, 2.4)
	ID.hara(lm, "Plaster", "Plaster", p + Vector3(0, 7.3, 0), 17.0, 15.0, 1.6, 3)
	_nandi(lm, p + Vector3(0, 1.6, 0), Vector3(-1, 0, 0), 1.45)

## Inner cloister (the two-storey maaligai) round x0..x1, z = +-hz: a
## 7 m outer wall, a pillared verandah facing the court under a sloping
## roof, broken on the east side for the gopura.
static func _cloister(lm: LandmarkMesh, x0: float, x1: float, hz: float) -> void:
	var runs := [[Vector3(x0, 0, -hz), Vector3(x1, 0, -hz), Vector3(0, 0, 1)],
		[Vector3(x0, 0, hz), Vector3(x1, 0, hz), Vector3(0, 0, -1)],
		[Vector3(x0, 0, -hz), Vector3(x0, 0, hz), Vector3(1, 0, 0)],
		[Vector3(x1, 0, -hz), Vector3(x1, 0, -9.0), Vector3(-1, 0, 0)],
		[Vector3(x1, 0, 9.0), Vector3(x1, 0, hz), Vector3(-1, 0, 0)]]
	for r in runs:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var inn: Vector3 = r[2]
		var dl := a.distance_to(b)
		var dir := (b - a).normalized()
		var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		var mid := (a + b) * 0.5
		lm.box("Granite", mid + Vector3(0, 3.5, 0), Vector3(dl + 2.0, 7.0, 2.0), bas)
		lm.box("Granite", mid + inn * 3.5 + Vector3(0, 0.4, 0), Vector3(dl, 0.8, 6.0) if absf(dir.x) > 0.5 else
			Vector3(6.0, 0.8, dl))
		var n := int(dl / 3.3)
		for k in n:
			var p := a.lerp(b, (float(k) + 0.5) / float(n)) + inn * 6.0
			lm.box("Granite", p + Vector3(0, 0.9, 0), Vector3(0.6, 0.2, 0.6), Basis(), 0.0)
			lm.frustum("Granite", p + Vector3(0, 1.0, 0), 0.26, 0.26, 3.6, 8, PI / 8.0)
			lm.box("Granite", p + Vector3(0, 4.75, 0), Vector3(0.9, 0.3, 0.6), Basis(), 0.0)
		lm.box("Granite", mid + inn * 3.5 + Vector3(0, 5.05, 0), Vector3(dl, 0.3, 7.0) if absf(dir.x) > 0.5 else
			Vector3(7.0, 0.3, dl))
		lm.box("Plaster", mid + inn * 3.3 + Vector3(0, 5.6, 0), Vector3(dl, 0.8, 5.0) if absf(dir.x) > 0.5 else
			Vector3(5.0, 0.8, dl))

## Rectangular wall ring between x0..x1 and z = +-hz, `h` high and `t`
## thick, with a coping, split on the east side (x1) by a gap of `gap`
## for the gopura.
static func _ring(lm: LandmarkMesh, x0: float, x1: float, hz: float, h: float, t: float,
		gap: float) -> void:
	for sz in [-1.0, 1.0]:
		lm.box("Granite", Vector3((x0 + x1) * 0.5, h * 0.5, sz * hz), Vector3(x1 - x0, h, t))
		lm.box("Granite", Vector3((x0 + x1) * 0.5, h + 0.2, sz * hz), Vector3(x1 - x0 + t, 0.4, t + 0.6))
		var half := hz - gap * 0.5
		lm.box("Granite", Vector3(x1, h * 0.5, sz * (gap * 0.5 + half * 0.5)), Vector3(t, h, half))
		lm.box("Granite", Vector3(x1, h + 0.2, sz * (gap * 0.5 + half * 0.5)), Vector3(t + 0.6, 0.4, half))
	lm.box("Granite", Vector3(x0, h * 0.5, 0), Vector3(t, h, hz * 2.0))
	lm.box("Granite", Vector3(x0, h + 0.2, 0), Vector3(t + 0.6, 0.4, hz * 2.0))

## Small shrine: a walled cella of half width hw and height wall_h with
## pilasters and niches, under a tower of `n` receding tiers of tier_h
## with pavilion parapets and a dome cap.
static func _shrine(lm: LandmarkMesh, p: Vector3, hw: float, wall_h: float, n: int, tier_h: float,
		tier_key: String) -> void:
	lm.box("Granite", p + Vector3(0, 0.6, 0), Vector3(hw * 2.0 + 1.2, 1.2, hw * 2.0 + 1.2))
	lm.box("Granite", p + Vector3(0, wall_h * 0.5, 0), Vector3(hw * 2.0, wall_h, hw * 2.0))
	lm.box("Granite", p + Vector3(0, wall_h + 0.3, 0), Vector3(hw * 2.0 + 1.0, 0.6, hw * 2.0 + 1.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		ID.pilasters(lm, "Granite", p + b * Vector3(-hw, 1.2, hw), p + b * Vector3(hw, 1.2, hw), b * Vector3(0, 0, 1),
			int(hw * 2.0 / 2.0), wall_h - 1.4, 0.5, 0.3)
		ID.arcade_wall(lm, "Granite", "Dark", p + b * Vector3(0, 1.6, hw), b, hw * 0.8, wall_h - 2.4, 0.4, 1, hw * 0.4,
			wall_h - 3.0, "round")
	var y := wall_h + 0.6
	for i in n:
		var w := hw * 2.0 * lerpf(0.88, 0.4, float(i) / float(maxi(n - 1, 1)))
		lm.box(tier_key, p + Vector3(0, y + tier_h * 0.3, 0), Vector3(w, tier_h * 0.6, w))
		lm.box("Granite", p + Vector3(0, y + tier_h * 0.6 + 0.15, 0), Vector3(w + 0.8, 0.3, w + 0.8))
		ID.hara(lm, tier_key, tier_key, p + Vector3(0, y + tier_h * 0.6 + 0.3, 0), w, w, tier_h * 0.4 - 0.3, 3)
		y += tier_h
	U.dome(lm, "Granite", p + Vector3(0, y, 0), hw * 0.6, hw * 0.55, 8, 4)
	U.finial(lm, "Gilt", p + Vector3(0, y + hw * 0.5, 0), 1.8, 0.3)

## Meenakshi Amman Temple (52 m; mostly 16th-17th c.): the walled
## 254 x 240 m complex of concentric enclosures with the four tall outer
## nine-tiered gopurams (south 52 m, north 49 m, east 49 m, west 46 m) in
## painted stucco, each tier crowded with pavilions, four five-tiered
## inner gopurams, the two gilded sanctum vimanas of Meenakshi and
## Sundareswarar, the 50 x 37 m Golden Lotus tank in its pillared
## cloister with the gilt lotus at its centre, and the thousand-pillar
## hall with its pillared front.
static func meenakshi_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A59A88", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#463C34", 2.0))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#D9A441", 3.0))
	lm.use("Rose", LandmarkMaterials.pbr("render", "#D46A78", 3.0))
	lm.use("Teal", LandmarkMaterials.pbr("render", "#4FA39B", 3.0))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#EBDDB5", 3.0))
	lm.use("Blue", LandmarkMaterials.pbr("render", "#5C7FB8", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#B0A38E", 4.0))
	lm.box("Pave", Vector3(0, 0.02, 0), Vector3(256.0, 0.04, 242.0))
	# Outer wall (9 m) in runs round the gopura gates; inner wall (6 m)
	# likewise, each with a moulded base and a coping.
	for s in [-1.0, 1.0]:
		var gz := 31.0 if s > 0.0 else 27.0
		for e in [[-127.0, -gz], [gz, 127.0]]:
			var xl := float(e[1]) - float(e[0])
			var xm := (float(e[0]) + float(e[1])) * 0.5
			_wall(lm, Vector3(xm, 0, s * 120.0), Vector3(xl, 9.0, 4.0))
			lm.box("Dark", Vector3(xm, 6.0, s * 117.95), Vector3(xl, 2.0, 0.2))
		for e in [[-120.0, -27.0], [27.0, 120.0]]:
			_wall(lm, Vector3(s * 127.0, 0, (float(e[0]) + float(e[1])) * 0.5), Vector3(4.0, 9.0, float(e[1]) - float(e[0])))
		for e in [[-75.0, -13.0], [13.0, 75.0]]:
			_wall(lm, Vector3((float(e[0]) + float(e[1])) * 0.5, 0, s * 66.0), Vector3(62.0, 6.0, 3.0))
		for e in [[-66.0, -13.0], [13.0, 66.0]]:
			_wall(lm, Vector3(s * 75.0, 0, (float(e[0]) + float(e[1])) * 0.5), Vector3(3.0, 6.0, float(e[1]) - float(e[0])))
	var cols: Array[String] = ["Ochre", "Rose", "Teal", "Cream", "Blue"]
	# Outer gopurams: tier height tuned so each tops out at its real height.
	var spec := [[0.0, 120.0, 0.0, 60.0, 33.0, 3.43], [0.0, -120.0, PI, 52.0, 28.0, 3.2],
		[127.0, 0.0, PI * 0.5, 50.0, 28.0, 3.2], [-127.0, 0.0, -PI * 0.5, 48.0, 27.0, 2.89]]
	for g in spec:
		IU.gopura(lm, "Granite", cols, "Gilt", Vector3(float(g[0]), 0, float(g[1])),
			Basis(Vector3.UP, float(g[2])), float(g[3]), float(g[4]), 12.0, 9, float(g[5]), 6.0, 9.0)
	# Second enclosure with four smaller gopurams (five tiers, about 30 m).
	for g in [[0.0, 66.0, 0.0], [0.0, -66.0, PI], [75.0, 0.0, PI * 0.5], [-75.0, 0.0, -PI * 0.5]]:
		IU.gopura(lm, "Granite", cols, "Gilt", Vector3(float(g[0]), 0, float(g[1])),
			Basis(Vector3.UP, float(g[2])), 24.0, 14.0, 8.0, 5, 3.0, 5.0, 6.5)
	# The two gilded sanctum vimanas (Sundareswarar and Meenakshi), side by
	# side: granite cella, three gilt tiers with pavilion parapets, the
	# gilt dome and kalasa.
	for sz in [-1.0, 1.0]:
		var p := Vector3(-12, 0, sz * 17.0)
		lm.box("Granite", p + Vector3(0, 3.5, 0), Vector3(14.0, 7.0, 12.0))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			var hw := 7.0 if side % 2 == 1 else 6.0
			var run := 12.0 if side % 2 == 1 else 14.0
			ID.pilasters(lm, "Granite", p + b * Vector3(-run * 0.5, 0.0, hw), p + b * Vector3(run * 0.5, 0.0, hw),
				b * Vector3(0, 0, 1), 5, 6.6, 0.5, 0.3)
		lm.box("Granite", p + Vector3(0, 7.2, 0), Vector3(15.0, 0.4, 13.0))
		for i in 3:
			var w := 10.0 - 2.4 * float(i)
			var y := 7.4 + 2.2 * float(i)
			lm.box("Gilt", p + Vector3(0, y + 0.6, 0), Vector3(w, 1.2, w * 0.9))
			ID.hara(lm, "Gilt", "Gilt", p + Vector3(0, y + 1.2, 0), w, w * 0.9, 0.95, 3)
		U.dome(lm, "Gilt", p + Vector3(0, 13.6, 0), 2.4, 2.2, 16, 5)
		U.finial(lm, "Gilt", p + Vector3(0, 15.6, 0), 2.4, 0.4)
	_lotus_tank(lm, Vector3(30, 0, 0))
	# Thousand-pillar hall: its walls with pilaster bays, the roof and
	# parapet, and the open pillared front.
	var hc := Vector3(62, 0, -52)
	lm.box("Granite", hc + Vector3(0, 0.6, 0), Vector3(74.0, 1.2, 26.0))
	lm.box("Granite", hc + Vector3(0, 4.6, -1.5), Vector3(72.0, 8.0, 21.0))
	lm.box("Granite", hc + Vector3(0, 8.9, 0), Vector3(73.0, 0.8, 25.0))
	for sz in [-1.0, 1.0]:
		lm.box("Granite", hc + Vector3(0, 9.7, sz * 12.2), Vector3(73.0, 0.8, 0.6))
	ID.pilasters(lm, "Granite", hc + Vector3(-36, 1.2, -12), hc + Vector3(36, 1.2, -12), Vector3(0, 0, -1), 22, 7.2,
		0.6, 0.3)
	for k in 24:
		var p := hc + Vector3(-34.5 + 3.0 * float(k), 1.2, 11.5)
		for row in 2:
			var q := p - Vector3(0, 0, 2.6 * float(row))
			lm.box("Granite", q + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
			lm.frustum("Granite", q + Vector3(0, 0.8, 0), 0.36, 0.36, 5.6, 8, PI / 8.0)
			lm.box("Granite", q + Vector3(0, 6.8, 0), Vector3(1.3, 0.8, 0.9), Basis(), 0.0)
	IU.arcade(lm, "Dark", hc + Vector3(0, 1.2, 9.05), Basis(), 24, 2.95, 2.1, 5.4, false)
	lm.commit(model)

## Enclosure wall run centred at `c` (foot) of `size`: a moulded base,
## the wall and a rounded coping.
static func _wall(lm: LandmarkMesh, c: Vector3, size: Vector3) -> void:
	lm.box("Granite", c + Vector3(0, size.y * 0.5, 0), size)
	lm.box("Granite", c + Vector3(0, 0.5, 0), size + Vector3(0.8, -size.y + 1.0, 0.8))
	lm.box("Granite", c + Vector3(0, size.y + 0.25, 0), size + Vector3(0.6, -size.y + 0.5, 0.6))

## Golden Lotus tank (Potramarai Kulam, 50 x 37 m) at `c`: the water on
## its stepped stone banks inside a pillared cloister, and the gilt lotus
## on its stem at the centre.
static func _lotus_tank(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Granite", c + Vector3(0, 0.5, 0), Vector3(62.0, 1.0, 48.0))
	for k in 4:
		var f := float(k)
		lm.box("Granite", c + Vector3(0, 1.0 + 0.15 * f, 0), Vector3(56.0 - 1.4 * f, 0.3, 42.0 - 1.4 * f))
	lm.box("Granite", c + Vector3(0, 1.2, 0), Vector3(50.0, 0.3, 37.0))
	lm.box("Water", c + Vector3(0, 1.38, 0), Vector3(50.0, 0.06, 37.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var run := 62.0 if side % 2 == 0 else 48.0
		var off := (48.0 if side % 2 == 0 else 62.0) * 0.5 - 1.5
		var n := int(run / 3.5)
		for k in n:
			var p := c + b * Vector3(-run * 0.5 + run * (float(k) + 0.5) / float(n), 1.0, off)
			lm.frustum("Granite", p, 0.32, 0.32, 4.4, 8, PI / 8.0)
			lm.box("Granite", p + Vector3(0, 4.55, 0), Vector3(0.9, 0.3, 0.9), Basis(), 0.0)
		lm.box("Granite", c + b * Vector3(0, 5.85, off - 1.0), Vector3(run, 0.5, 5.0), b)
		lm.box("Granite", c + b * Vector3(0, 3.5, off + 1.5), Vector3(run, 5.0, 0.8), b)
	var lc := c + Vector3(0, 1.4, 0)
	lm.frustum("Gilt", lc, 0.25, 0.2, 4.0, 8)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gilt", lc + Vector3(0, 4.0, 0) + d * 0.3, lc + Vector3(0, 5.0, 0) + d * 1.4, 0.7, 0.12,
			d.cross(Vector3.UP))
	lm.lathe("Gilt", lc + Vector3(0, 4.0, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(0.7, 0.4),
		Vector2(0.4, 0.9), Vector2(0.0, 1.0)]), 12)
