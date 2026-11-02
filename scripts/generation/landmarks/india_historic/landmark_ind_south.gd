class_name LandmarkIndSouth
extends RefCounted

## Two Dravida temples of Tamil Nadu in true metres: the Brihadisvara
## Temple of Thanjavur and the Meenakshi Amman Temple of Madurai. Both
## are built facing +X (east); the registry yaw turns Thanjavur onto its
## real bearing.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const IU = preload("res://scripts/generation/landmarks/india_historic/landmark_ind_util.gd")

## Brihadisvara Temple (66 m): the granite vimana on its plinth, two
## storeys of niched walls under 13 receding tiers, the 80-tonne
## monolithic capstone with its corner Nandis, the octagonal dome and the
## gilt kalasam; the mandapas leading east, the Nandi pavilion, the inner
## cloister with the Rajarajan gopura, the outer wall with the Keralantakan
## gopura and two shrine towers.
static func brihadisvara_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8678", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4C443C", 2.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#C9B79A", 3.0))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#A89B86", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Pave", Vector3(40, -0.45, 0), Vector3(250.0, 0.9, 130.0))
	lm.box("Granite", Vector3(0, 0.6, 0), Vector3(36.0, 1.2, 36.0))
	lm.box("Granite", Vector3(0, 3.1, 0), Vector3(32.0, 3.8, 32.0))
	lm.box("Dark", Vector3(0, 5.0, 0), Vector3(32.4, 0.3, 32.4))
	# Sanctum walls: two storeys of niches, a mid band and the heavy cornice.
	lm.box("Granite", Vector3(0, 13.4, 0), Vector3(28.0, 16.8, 28.0))
	lm.box("Granite", Vector3(0, 13.4, 0), Vector3(29.4, 0.9, 29.4))
	lm.box("Granite", Vector3(0, 22.0, 0), Vector3(30.6, 1.2, 30.6))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in 3:
			var x := (float(k) - 1.0) * 8.5
			var big := 1.25 if k == 1 else 1.0
			lm.box("Dark", b * Vector3(x, 9.2, 14.05), Vector3(3.2 * big, 5.6 * big, 0.2), b)
			lm.box("Dark", b * Vector3(x, 17.6, 14.05), Vector3(3.2 * big, 5.6 * big, 0.2), b)
	# 13 receding tiers, each a niched wall and an eave slab.
	var y := 22.6
	for i in 13:
		var w := lerpf(27.0, 9.0, pow(float(i) / 12.0, 0.95))
		lm.box("Granite", Vector3(0, y + 0.85, 0), Vector3(w, 1.7, w))
		lm.box("Granite", Vector3(0, y + 1.95, 0), Vector3(w + 1.1, 0.5, w + 1.1))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box("Dark", b * Vector3(0, y + 0.9, w * 0.5 + 0.02), Vector3(w * 0.3, 1.0, 0.2), b)
		y += 2.27
	# Capstone with Nandis, neck, octagonal dome and the kalasam: 51.5 -> 66 m.
	lm.box("Granite", Vector3(0, 52.95, 0), Vector3(8.2, 1.8, 8.2))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Granite", Vector3(sx * 3.1, 54.6, sz * 3.1), Vector3(1.7, 1.4, 1.7))
	lm.frustum("Granite", Vector3(0, 53.85, 0), 3.1, 2.9, 2.5, 8)
	lm.lathe("Granite", Vector3(0, 56.35, 0), PackedVector2Array([Vector2(3.3, 0), Vector2(3.9, 0.7),
		Vector2(3.8, 2.2), Vector2(3.1, 3.9), Vector2(1.9, 5.3), Vector2(0.9, 6.2)]), 8)
	U.finial(lm, "Gilt", Vector3(0, 62.2, 0), 3.8, 0.55)
	# Mandapas: ardha, maha and mukha, flat-roofed, with a stair at the porch.
	for blk in [[14.0, 28.0, 9.0, 12.5], [28.0, 48.0, 11.5, 13.0], [48.0, 62.0, 8.0, 9.5]]:
		var cx := (float(blk[0]) + float(blk[1])) * 0.5
		var bw := float(blk[1]) - float(blk[0])
		var hz: float = blk[2]
		var top: float = blk[3]
		lm.box("Granite", Vector3(cx, top * 0.5, 0), Vector3(bw, top, hz * 2.0))
		lm.box("Granite", Vector3(cx, top + 0.3, 0), Vector3(bw + 1.0, 0.7, hz * 2.0 + 1.0))
		for sz in [-1.0, 1.0]:
			for k in int(bw / 4.5):
				lm.box("Dark", Vector3(float(blk[0]) + 2.2 + 4.5 * float(k), 8.5, sz * (hz + 0.05)),
					Vector3(1.8, 2.8, 0.2))
	lm.box("Dark", Vector3(62.05, 7.5, 0), Vector3(0.2, 4.0, 3.2))
	IU.stairs(lm, "Granite", Vector3(62, 0, 0), Basis(Vector3.UP, PI * 0.5), 9.0, 6, 0.85, 0.9)
	# Nandi pavilion: pillared on a platform, with the 6 m Nandi.
	lm.box("Granite", Vector3(90, 0.8, 0), Vector3(17.0, 1.6, 15.0))
	for i in 4:
		for j in 4:
			lm.box("Granite", Vector3(83.0 + 4.67 * float(i), 4.0, (float(j) - 1.5) * 4.0), Vector3(0.7, 4.8, 0.7))
	lm.box("Granite", Vector3(90, 6.7, 0), Vector3(18.0, 0.7, 16.0))
	lm.spire("Plaster", Vector3(90, 7.05, 0), 8.5, 3.0, 2.0)
	lm.box("Granite", Vector3(90, 2.3, 0), Vector3(5.4, 1.4, 2.2))
	lm.box("Granite", Vector3(88.0, 3.4, 0), Vector3(3.4, 1.4, 2.0))
	lm.box("Granite", Vector3(92.4, 3.6, 0), Vector3(1.8, 1.8, 1.4))
	# Inner cloister with the Rajarajan gopura, outer wall with the Keralantakan gopura.
	_ring(lm, -62.0, 120.0, 50.0, 6.0, 7.0, 8.0)
	_ring(lm, -80.0, 160.0, 61.0, 7.0, 3.0, 10.0)
	var cols: Array[String] = ["Plaster", "Granite"]
	IU.gopura(lm, "Granite", cols, "Gilt", Vector3(120, 0, 0), Basis(Vector3.UP, PI * 0.5), 22.0, 14.0,
		10.0, 5, 3.3, 5.0, 7.5)
	IU.gopura(lm, "Granite", cols, "Gilt", Vector3(160, 0, 0), Basis(Vector3.UP, PI * 0.5), 26.0, 16.0,
		11.0, 5, 3.4, 5.5, 8.0)
	# Shrine towers: Subrahmanya (north-west) and Chandikeswara (south).
	_shrine(lm, Vector3(-30, 0, -34), 11.0, 7.0, 5, 3.4, "Plaster")
	_shrine(lm, Vector3(-4, 0, 30), 7.0, 5.0, 3, 2.6, "Plaster")
	lm.commit(model)

## Rectangular wall ring between x0..x1 and z = +-hz, `h` high and `t`
## thick, split on the east side (x1) by a gap of `gap` for the gopura.
static func _ring(lm: LandmarkMesh, x0: float, x1: float, hz: float, h: float, t: float,
		gap: float) -> void:
	lm.box("Granite", Vector3((x0 + x1) * 0.5, h * 0.5, hz), Vector3(x1 - x0, h, t))
	lm.box("Granite", Vector3((x0 + x1) * 0.5, h * 0.5, -hz), Vector3(x1 - x0, h, t))
	lm.box("Granite", Vector3(x0, h * 0.5, 0), Vector3(t, h, hz * 2.0))
	for sz in [-1.0, 1.0]:
		lm.box("Granite", Vector3(x1, h * 0.5, sz * (hz + gap * 0.5) * 0.5), Vector3(t, h, hz - gap * 0.5))
	lm.box("Dark", Vector3((x0 + x1) * 0.5, h * 0.55, hz - t * 0.5 - 0.05), Vector3(x1 - x0 - t, h * 0.55, 0.2))
	lm.box("Dark", Vector3((x0 + x1) * 0.5, h * 0.55, -hz + t * 0.5 + 0.05), Vector3(x1 - x0 - t, h * 0.55, 0.2))

## Small shrine: walled cella of half width hw and height wall_h under a
## tower of `n` receding tiers of tier_h and a dome cap.
static func _shrine(lm: LandmarkMesh, p: Vector3, hw: float, wall_h: float, n: int, tier_h: float,
		tier_key: String) -> void:
	lm.box("Granite", p + Vector3(0, wall_h * 0.5, 0), Vector3(hw * 2.0, wall_h, hw * 2.0))
	lm.box("Granite", p + Vector3(0, wall_h + 0.3, 0), Vector3(hw * 2.0 + 1.0, 0.6, hw * 2.0 + 1.0))
	var y := wall_h + 0.6
	for i in n:
		var w := hw * 2.0 * lerpf(0.88, 0.4, float(i) / float(maxi(n - 1, 1)))
		lm.box(tier_key, p + Vector3(0, y + tier_h * 0.5, 0), Vector3(w, tier_h - 0.4, w))
		lm.box("Granite", p + Vector3(0, y + tier_h - 0.2, 0), Vector3(w + 0.8, 0.4, w + 0.8))
		y += tier_h
	U.dome(lm, "Granite", p + Vector3(0, y, 0), hw * 0.6, hw * 0.55, 12, 4)
	U.finial(lm, "Gilt", p + Vector3(0, y + hw * 0.5, 0), 1.8, 0.3)

## Meenakshi Amman Temple (52 m): the walled 254 x 240 m complex of
## concentric enclosures with the four tall outer gopurams (south 52 m,
## north 49 m, east 49 m, west 46 m) in painted stucco, four smaller inner
## gopurams, the two gilded sanctum towers, the golden-lotus tank and
## the thousand-pillar hall.
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
	lm.box("Pave", Vector3(0, -0.45, 0), Vector3(256.0, 0.9, 242.0))
	# Outer wall (9 m) in runs round the gopura gates; inner wall (6 m) likewise.
	for s in [-1.0, 1.0]:
		var gz := 31.0 if s > 0.0 else 27.0
		for e in [[-127.0, -gz], [gz, 127.0]]:
			var xl := float(e[1]) - float(e[0])
			lm.box("Granite", Vector3((float(e[0]) + float(e[1])) * 0.5, 4.5, s * 120.0), Vector3(xl, 9.0, 4.0))
			lm.box("Dark", Vector3((float(e[0]) + float(e[1])) * 0.5, 6.0, s * 117.95), Vector3(xl, 2.0, 0.2))
		for e in [[-120.0, -27.0], [27.0, 120.0]]:
			lm.box("Granite", Vector3(s * 127.0, 4.5, (float(e[0]) + float(e[1])) * 0.5),
				Vector3(4.0, 9.0, float(e[1]) - float(e[0])))
		for e in [[-75.0, -13.0], [13.0, 75.0]]:
			lm.box("Granite", Vector3((float(e[0]) + float(e[1])) * 0.5, 3.0, s * 66.0), Vector3(62.0, 6.0, 3.0))
		for e in [[-66.0, -13.0], [13.0, 66.0]]:
			lm.box("Granite", Vector3(s * 75.0, 3.0, (float(e[0]) + float(e[1])) * 0.5),
				Vector3(3.0, 6.0, float(e[1]) - float(e[0])))
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
	# The two gilded sanctum towers (Sundareswarar and Meenakshi), side by side.
	for sz in [-1.0, 1.0]:
		var p := Vector3(-12, 0, sz * 17.0)
		lm.box("Granite", p + Vector3(0, 3.5, 0), Vector3(14.0, 7.0, 12.0))
		for i in 3:
			var w := 10.0 - 2.4 * float(i)
			lm.box("Gilt", p + Vector3(0, 7.0 + 1.1 + 2.2 * float(i), 0), Vector3(w, 2.0, w * 0.9))
		U.dome(lm, "Gilt", p + Vector3(0, 13.6, 0), 2.4, 2.2, 14, 5)
		U.finial(lm, "Gilt", p + Vector3(0, 15.6, 0), 2.4, 0.4)
	# Golden Lotus tank, the thousand-pillar hall and the pillared corridor.
	lm.box("Granite", Vector3(30, 0.4, 0), Vector3(56.0, 1.0, 42.0))
	lm.box("Water", Vector3(30, 0.95, 0), Vector3(50.0, 0.1, 36.0))
	lm.box("Granite", Vector3(62, 4.0, -52), Vector3(72.0, 8.0, 24.0))
	lm.box("Granite", Vector3(62, 8.4, -52), Vector3(73.0, 0.8, 25.0))
	IU.arcade(lm, "Dark", Vector3(62, 0.2, -39.9), Basis(), 24, 2.95, 2.1, 5.4, false)
	lm.commit(model)
