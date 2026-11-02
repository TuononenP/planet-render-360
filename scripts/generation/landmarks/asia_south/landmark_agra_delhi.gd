class_name LandmarkAgraDelhi
extends RefCounted

## Mughal and colonial-Delhi monuments in true metres: the Taj Mahal,
## the Qutub Minar and India Gate. Entrances face +Z (south).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Taj Mahal (73 m to the finial): white marble tomb on a 6 m plinth
## 95.5 m square ringed by a blind arcade. The tomb is an irregular
## octagon 57 m across; each face has a 33 m pishtaq framing the iwan
## (calligraphy band, door and jali inside) between two storeys of deep
## niches, with guldasta pinnacles and a kangura parapet. The 12 m drum,
## the 23 m onion dome with its lotus crown, the 9.6 m gilt finial, four
## corner chhatris, four 40 m minarets in three stages with balconies,
## and the red sandstone mosque (west) and jawab (east) with three domes.
static func taj_mahal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EFEBE0", 3.0))
	lm.use("Sandstone", LandmarkMaterials.pbr("stone", "#94503A", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#5A5248", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Inlay", LandmarkMaterials.pbr("stone", "#2E2A27", 2.0))
	lm.box("Sandstone", Vector3(0, 0.5, 8.0), Vector3(280.0, 1.0, 110.0))
	# Plinth: 95.5 m square, 6 m high, a blind arcade on every side.
	lm.box("Marble", Vector3(0, 4.0, 0), Vector3(95.5, 6.0, 95.5))
	lm.box("Marble", Vector3(0, 6.85, 0), Vector3(96.6, 0.3, 96.6))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.arcade(lm, "Marble", "Recess", b * Vector3(0, 1.2, 47.75), b, 86.0, 5.2, 19, 0.6, 0.0, 2.9,
			1.5, 0.45, 6)
	_taj_tomb(lm)
	# Four corner minarets on the plinth corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_minaret(lm, Vector3(sx * 43.5, 7.0, sz * 43.5))
	# Mosque (west) and jawab (east) face the tomb across the terrace.
	for sx in [-1.0, 1.0]:
		_taj_mosque(lm, sx)
	lm.commit(model)

## The tomb proper on the plinth (floor at 7 m): octagonal mass to the
## 35 m parapet, pishtaqs to 40 m, the drum, dome, finial and chhatris.
static func _taj_tomb(lm: LandmarkMesh) -> void:
	var h := 28.5
	var c := 8.5
	var plan := PackedVector2Array([Vector2(-h + c, -h), Vector2(h - c, -h), Vector2(h, -h + c),
		Vector2(h, h - c), Vector2(h - c, h), Vector2(-h + c, h), Vector2(-h, h - c), Vector2(-h, -h + c)])
	lm.poly_prism("Marble", plan, 7.0, 35.0)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Pishtaq: 23 m wide, 33 m high, the iwan 11.5 m wide and 25 m to the apex.
		U.niche(lm, "Marble", "Marble", b * Vector3(0, 7.0, h), b, 23.0, 33.0, 11.5, 0.0, 17.5, 7.5, 3.0, 10)
		U.frame(lm, "Inlay", b * Vector3(0, 7.6, h + 3.0), b, 15.6, 26.6, 0.9, 0.06)
		U.frame(lm, "Marble", b * Vector3(0, 7.0, h + 3.0), b, 22.6, 32.6, 0.5, 0.35)
		# Inside the iwan: the door below, a jali window above.
		U.niche(lm, "Marble", "Recess", b * Vector3(0, 7.0, h + 0.02), b, 8.5, 13.0, 4.4, 0.0, 8.0, 3.0, 0.6, 8)
		lm.box("Recess", b * Vector3(0, 23.5, h + 0.06), Vector3(5.0, 5.0, 0.1), b, 0.0)
		U.jali(lm, "Marble", b * Vector3(0, 23.5, h + 0.2), b, 5.0, 5.0, 0.7, 0.12)
		# Kangura parapet on the pishtaq.
		U.merlons(lm, "Marble", b * Vector3(-11.0, 40.0, h + 2.4), b * Vector3(11.0, 40.0, h + 2.4), 14, 0.9, 1.4)
		# Flanking bays: two storeys of deep pointed niches each side.
		for sx in [-1.0, 1.0]:
			for y in [7.0, 21.0]:
				U.niche(lm, "Marble", "Recess", b * Vector3(sx * 15.75, y, h), b, 8.5, 14.0, 5.2, 0.0, 8.6,
					3.4, 1.2, 8)
			# Guldasta pinnacles at the pishtaq edges.
			_guldasta(lm, b * Vector3(sx * 11.8, 7.0, h + 3.2), 36.5)
		# The chamfered corner carries the same two storeys of niches.
		var d := b * Vector3(h - c * 0.5, 0, h - c * 0.5)
		var nb := Basis(Vector3.UP, PI * 0.25 + PI * 0.5 * float(side))
		for y in [7.0, 21.0]:
			U.niche(lm, "Marble", "Recess", d + Vector3(0, y, 0), nb, c * 1.414, 14.0, 6.0, 0.0, 8.4, 3.6, 1.2, 8)
		_guldasta(lm, b * Vector3(h - c, 7.0, h + 0.2), 31.0)
		_guldasta(lm, b * Vector3(h + 0.2, 7.0, h - c), 31.0)
		# Parapet along the flanking bays and the chamfer.
		for sx in [-1.0, 1.0]:
			U.merlons(lm, "Marble", b * Vector3(sx * 11.6, 35.0, h + 0.6), b * Vector3(sx * (h - c), 35.0, h + 0.6),
				6, 0.9, 1.2)
		U.merlons(lm, "Marble", d + nb * Vector3(-c * 0.7, 0, 0.6) + Vector3(0, 35.0, 0),
			d + nb * Vector3(c * 0.7, 0, 0.6) + Vector3(0, 35.0, 0), 7, 0.9, 1.2)
		# Corner chhatri on the roof by the drum.
		var ch := b * Vector3(19.0, 35.0, 19.0)
		lm.frustum("Marble", ch, 4.4, 4.4, 1.2, 8, PI / 8.0)
		U.chhatri8(lm, "Marble", "Marble", "Gilt", ch + Vector3(0, 1.2, 0), 4.0, 4.6, 4.2)
	# Drum (35 -> 41.5 m) with base and lotus mouldings and an inlay band.
	lm.frustum("Marble", Vector3(0, 35.0, 0), 11.4, 11.2, 1.2, 48)
	lm.frustum("Marble", Vector3(0, 35.0, 0), 10.6, 10.6, 6.5, 48)
	lm.frustum("Inlay", Vector3(0, 38.2, 0), 10.65, 10.65, 0.5, 48)
	lm.lathe("Marble", Vector3(0, 40.6, 0), PackedVector2Array([Vector2(10.6, 0), Vector2(11.2, 0.4),
		Vector2(11.3, 0.9)]), 48)
	# Onion dome: 23 m tall, swelling to 12.6 m radius, to 63.7 m.
	var t := [[0.84, 0.0], [0.95, 0.05], [1.0, 0.14], [1.03, 0.28], [1.0, 0.42], [0.92, 0.55],
		[0.78, 0.68], [0.6, 0.79], [0.4, 0.88], [0.22, 0.95], [0.1, 0.985], [0.0, 1.0]]
	var prof := PackedVector2Array()
	for e in t:
		prof.append(Vector2(12.6 * float(e[0]), 22.2 * float(e[1])))
	lm.lathe("Marble", Vector3(0, 41.5, 0), prof, 48)
	# Inverted lotus crown at the top of the dome.
	for i in 16:
		var a := TAU * float(i) / 16.0
		var dd := Vector3(cos(a), 0, sin(a))
		lm.beam("Marble", Vector3(0, 60.4, 0) + dd * 5.2, Vector3(0, 63.4, 0) + dd * 1.4, 1.8, 0.3,
			dd.cross(Vector3.UP))
	# Gilt finial (9.6 m): stacked kalash bulbs and the crescent, to 73 m.
	lm.lathe("Gilt", Vector3(0, 63.4, 0), PackedVector2Array([Vector2(1.3, 0), Vector2(0.6, 0.6),
		Vector2(1.3, 1.5), Vector2(0.45, 2.6), Vector2(1.05, 3.4), Vector2(0.38, 4.3),
		Vector2(0.8, 5.0), Vector2(0.25, 5.8), Vector2(0.16, 7.8), Vector2(0.0, 8.0)]), 16)
	# Crescent, horns up, on the stem.
	var cc := Vector3(0, 72.1, 0)
	var prev := cc + Vector3(cos(PI - 0.25), sin(PI - 0.25), 0) * 0.7
	for i in 10:
		var a := lerpf(PI - 0.25, TAU + 0.25, float(i + 1) / 10.0)
		var p := cc + Vector3(cos(a), sin(a), 0) * 0.7
		lm.beam("Gilt", prev, p, 0.18, 0.12)
		prev = p

## Guldasta: a slender fluted pinnacle of height h with a bud cap.
static func _guldasta(lm: LandmarkMesh, p: Vector3, h: float) -> void:
	lm.frustum("Marble", p, 0.7, 0.7, 1.0, 8, PI / 8.0)
	lm.frustum("Marble", p, 0.5, 0.42, h - 2.0, 8, PI / 8.0)
	for y in [h * 0.33, h * 0.66]:
		lm.frustum("Marble", p + Vector3(0, y, 0), 0.62, 0.62, 0.3, 8, PI / 8.0)
	lm.lathe("Marble", p + Vector3(0, h - 2.0, 0), PackedVector2Array([Vector2(0.45, 0), Vector2(0.7, 0.4),
		Vector2(0.6, 0.9), Vector2(0.25, 1.4), Vector2(0.0, 2.0)]), 8)

## Taj minaret on a plinth corner: octagonal base, a 32 m shaft in three
## stages with corbelled balconies and inlay bands, and a chhatri.
static func _minaret(lm: LandmarkMesh, p: Vector3) -> void:
	lm.frustum("Marble", p, 4.4, 4.2, 2.0, 8, PI / 8.0)
	lm.frustum("Marble", p + Vector3(0, 2.0, 0), 3.6, 3.5, 0.6, 16)
	lm.frustum("Marble", p + Vector3(0, 2.0, 0), 3.1, 2.4, 32.0, 16)
	for k in 3:
		var y0 := 2.0 + 32.0 * float(k) / 3.0
		for j in 3:
			var yb := y0 + 2.5 + 3.4 * float(j)
			var rr := lerpf(3.1, 2.4, (yb - 2.0) / 32.0) + 0.03
			lm.frustum("Inlay", p + Vector3(0, yb, 0), rr, rr, 0.18, 16)
		var yt := 2.0 + 32.0 * float(k + 1) / 3.0
		var r := lerpf(3.1, 2.4, (yt - 2.0) / 32.0)
		# Muqarnas corbels flaring to the balcony floor.
		lm.lathe("Marble", p + Vector3(0, yt - 1.8, 0), PackedVector2Array([Vector2(r, 0),
			Vector2(r + 0.3, 0.6), Vector2(r + 0.7, 1.2), Vector2(r + 1.2, 1.8)]), 16)
		for i in 16:
			var a := TAU * (float(i) + 0.5) / 16.0
			lm.box("Marble", p + Vector3(cos(a), 0, sin(a)) * (r + 0.35) + Vector3(0, yt - 1.1, 0),
				Vector3(0.25, 0.7, 0.25), Basis(Vector3.UP, -a), 0.0)
		lm.frustum("Marble", p + Vector3(0, yt, 0), r + 1.25, r + 1.25, 0.25, 16)
		if k < 2:
			for i in 16:
				var a := TAU * float(i) / 16.0
				lm.box("Marble", p + Vector3(cos(a), 0, sin(a)) * (r + 1.1) + Vector3(0, yt + 0.7, 0),
					Vector3(0.14, 0.9, 0.14), Basis(), 0.0)
			lm.frustum("Marble", p + Vector3(0, yt + 1.15, 0), r + 1.15, r + 1.15, 0.12, 16)
	U.chhatri8(lm, "Marble", "Marble", "Gilt", p + Vector3(0, 34.25, 0), 3.0, 3.2, 2.8)

## Red sandstone mosque (sx = -1, west) or jawab (east): a 56 x 23 m
## hall with the central pishtaq, two arched bays either side, marble
## frames, three marble onion domes, corner towers and chhatris.
static func _taj_mosque(lm: LandmarkMesh, sx: float) -> void:
	var x: float = 105.0 * sx
	var xf: float = x - sx * 11.5
	var bf := Basis(Vector3.UP, -sx * PI * 0.5)
	lm.box("Sandstone", Vector3(x, 8.5, 8.0), Vector3(23.0, 15.0, 56.0))
	U.niche(lm, "Sandstone", "Recess", Vector3(xf, 1.0, 8.0), bf, 15.0, 19.0, 7.6, 0.0, 9.5, 4.2, 1.6, 10)
	U.frame(lm, "Marble", Vector3(xf - sx * 1.6, 1.3, 8.0), bf, 10.8, 15.6, 0.45, 0.08)
	U.merlons(lm, "Sandstone", Vector3(xf - sx * 0.8, 20.0, 1.0), Vector3(xf - sx * 0.8, 20.0, 15.0), 9, 0.8, 1.2)
	for sz in [-1.0, 1.0]:
		U.arcade(lm, "Sandstone", "Recess", Vector3(xf, 1.0, 8.0 + sz * 17.75), bf, 20.5, 15.0, 2, 0.62,
			0.0, 8.0, 1.4, 1.0, 8)
		U.merlons(lm, "Sandstone", Vector3(xf - sx * 0.5, 16.0, 8.0 + sz * 8.0),
			Vector3(xf - sx * 0.5, 16.0, 8.0 + sz * 27.5), 12, 0.8, 1.0)
		# Corner towers with kiosks.
		for ex in [-1.0, 1.0]:
			var tp := Vector3(x + ex * 11.3, 1.0, 8.0 + sz * 27.8)
			lm.frustum("Sandstone", tp, 1.7, 1.5, 18.0, 8, PI / 8.0)
			for y in [6.0, 12.0, 16.0]:
				lm.frustum("Marble", tp + Vector3(0, y, 0), 1.75, 1.75, 0.3, 8, PI / 8.0)
			U.chhatri8(lm, "Sandstone", "Marble", "Gilt", tp + Vector3(0, 18.0, 0), 1.9, 2.0, 1.8)
		U.chhatri8(lm, "Sandstone", "Marble", "Gilt", Vector3(xf - sx * 1.0, 20.0, 8.0 + sz * 6.8), 1.4, 1.6, 1.4)
	for k in 3:
		var z := 8.0 + (float(k) - 1.0) * 17.0
		var r := 6.4 if k == 1 else 5.0
		lm.frustum("Sandstone", Vector3(x, 16.0, z), r * 0.92, r * 0.9, 2.2, 32)
		lm.frustum("Marble", Vector3(x, 18.0, z), r * 0.95, r * 0.95, 0.3, 32)
		lm.lathe("Marble", Vector3(x, 18.2, z), LandmarkKits.onion_profile(r * 0.85, r * 1.25), 32)
		U.finial(lm, "Gilt", Vector3(x, 18.0 + r * 1.2, z), r * 0.45, r * 0.05)

## Qutub Minar (72.5 m, 14.3 m across the base, 2.7 m at the top): five
## tapering storeys, the lower three red sandstone (alternate round and
## angular flutes, then round, then angular), the upper two white marble
## banded with sandstone, inscription bands, muqarnas-corbelled
## balconies with railings at each storey head and a railed top.
static func qutub_minar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("stone", "#B2502E", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6DCC8", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8C7B68", 3.0))
	lm.use("Band", LandmarkMaterials.pbr("stone", "#8E3E25", 2.0))
	lm.frustum("Plinth", Vector3.ZERO, 9.6, 9.3, 0.6, 32)
	# y0, y1, base radius, top radius, key, flute kind, flutes, relief, bands
	var storeys := [[0.6, 29.0, 7.15, 5.75, "Red", "mixed", 24, 0.75, 3],
		[29.0, 44.3, 5.2, 4.4, "Red", "round", 24, 0.6, 2],
		[44.3, 56.5, 4.0, 3.4, "Red", "angular", 16, 0.65, 1],
		[56.5, 64.2, 3.1, 2.6, "Marble", "plain", 16, 0.0, 2],
		[64.2, 71.6, 2.3, 1.45, "Marble", "plain", 12, 0.0, 2]]
	for s in storeys:
		var y0: float = s[0]
		var y1: float = s[1]
		var r0: float = s[2]
		var r1: float = s[3]
		var key: String = s[4]
		var kind: String = s[5]
		var nf: int = s[6]
		var rel: float = s[7]
		var bands: int = s[8]
		_qutub_shaft(lm, key, Vector3(0, y0, 0), r0, r1, y1 - y0, nf, kind, rel, 6)
		# Inscription (or sandstone) bands proud of the flutes.
		for j in bands:
			var t := (float(j) + 0.6) / (float(bands) + 0.4)
			var yb := y0 + (y1 - y0) * t
			var rb := lerpf(r0, r1, t) + 0.12
			_qutub_shaft(lm, "Band" if key == "Red" else "Red", Vector3(0, yb, 0), rb, rb - 0.02, 1.1, nf,
				kind, rel, 1)
		# Balcony: three tiers of muqarnas corbels under a railed ledge.
		var r := r1 + rel
		for tier in 3:
			var ty := y1 - 2.4 + 0.75 * float(tier)
			var tr := r + 0.4 * float(tier)
			lm.lathe(key, Vector3(0, ty, 0), PackedVector2Array([Vector2(tr, 0), Vector2(tr + 0.4, 0.75)]), 32)
			for i in 24:
				var a := TAU * (float(i) + 0.5 * float(tier)) / 24.0
				lm.box(key, Vector3(cos(a) * (tr + 0.2), ty + 0.35, sin(a) * (tr + 0.2)),
					Vector3(0.28, 0.5, 0.28), Basis(Vector3.UP, -a), 0.0)
		lm.frustum(key, Vector3(0, y1 - 0.15, 0), r + 1.45, r + 1.45, 0.3, 32)
		var rail_r := r + 1.3
		var posts := 28 if y1 < 70.0 else 18
		for i in posts:
			var a := TAU * float(i) / float(posts)
			lm.box(key, Vector3(cos(a) * rail_r, y1 + 0.5, sin(a) * rail_r), Vector3(0.12, 0.85, 0.12),
				Basis(), 0.0)
		lm.lathe(key, Vector3(0, y1 + 0.9, 0), PackedVector2Array([Vector2(rail_r + 0.1, 0),
			Vector2(rail_r + 0.1, 0.12), Vector2(rail_r - 0.1, 0.12), Vector2(rail_r - 0.1, 0.0)]), 32,
			1.0, 1.0, 0.0, true, false)
	# Entrance door on the north side.
	U.niche(lm, "Red", "Plinth", Vector3(0, 0.6, -7.6), Basis(Vector3.UP, PI), 3.2, 4.2, 1.6, 0.0, 2.6,
		1.1, 0.5, 6)
	lm.commit(model)

## Fluted tapering shaft as one smooth grid: `n` flutes that are round
## lobes, angular (flanged) points, the two alternating ("mixed") or a
## plain round shaft ("plain"); `rings` storeys of rows up the height.
static func _qutub_shaft(lm: LandmarkMesh, key: String, base: Vector3, r0: float, r1: float, h: float,
		n: int, kind: String, relief: float, rings: int) -> void:
	var per := 4
	var cols := n * per
	var rows: Array = []
	for j in rings + 1:
		var t := float(j) / float(rings)
		var rr := lerpf(r0, r1, t)
		var ring := PackedVector3Array()
		for i in cols + 1:
			var a := TAU * float(i) / float(cols)
			var k := i / per
			var f := float(i % per) / float(per)
			var bump := 0.0
			var angular := kind == "angular" or (kind == "mixed" and k % 2 == 1)
			if kind != "plain":
				bump = (1.0 - absf(2.0 * f - 1.0)) if angular else sin(PI * f)
			var q := rr + relief * bump
			ring.append(base + Vector3(cos(a) * q, h * t, sin(a) * q))
		rows.append(ring)
	lm.grid(key, rows, base + Vector3(0, h * 0.5, 0), true)
	lm.disc(key, base + Vector3(0, h, 0), Vector3.UP, r1 + relief * 0.5, 24)

## India Gate (42 m): the red sandstone triumphal arch on a low stepped
## Bharatpur-stone base. Two 8 m piers, each pierced by a small cross
## arch, carry the 9.1 m main arch (moulded archivolts, coffered vault
## ribs) to the frieze of imperial suns and the cornice; the attic with
## the INDIA / MCMXIV / MCMXIX inscription steps back twice to the
## shallow domed bowl on top. The names panels and the Amar Jawan Jyoti
## cenotaph stand under the arch. The passage runs along Z.
static func india_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B07254", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#76675F", 3.0))
	lm.use("Names", LandmarkMaterials.pbr("stone", "#4A4440", 2.0))
	lm.box("Granite", Vector3(0, 0.6, 0), Vector3(40.0, 1.2, 25.0))
	lm.box("Granite", Vector3(0, 1.6, 0), Vector3(32.0, 0.8, 16.0))
	var y0 := 2.0
	var top := 27.5
	var span := 9.1
	var spring := 16.0
	var dep := 10.0
	# Piers: each pierced along X by a 4 m cross arch.
	for sx in [-1.0, 1.0]:
		var pc := Vector3(sx * 8.8, y0, 0)
		U.arch_wall(lm, "Stone", pc, Basis(Vector3.UP, PI * 0.5), dep, top - y0, 8.4, 4.0, 10.0, 12)
		LandmarkDetail.arch(lm, "Stone", Vector3(sx * 13.0, y0 + 8.0, 0), Vector3(sx, 0, 0), 4.0, 0.6, 0.25)
		# Pilaster strips and names panels on the pier faces.
		for sz in [-1.0, 1.0]:
			for ex in [-1.0, 1.0]:
				lm.box("Stone", Vector3(sx * 8.8 + ex * 3.75, y0 + 12.0, sz * 5.15), Vector3(0.9, 24.0, 0.3))
			lm.box("Names", Vector3(sx * 8.8, y0 + 7.0, sz * 5.04), Vector3(4.6, 8.0, 0.1), Basis(), 0.0)
			lm.box("Stone", Vector3(sx * 8.8, y0 + 3.0, sz * 5.1), Vector3(5.2, 0.3, 0.25), Basis(), 0.0)
			lm.box("Stone", Vector3(sx * 8.8, y0 + 11.1, sz * 5.1), Vector3(5.2, 0.3, 0.25), Basis(), 0.0)
		# Impost moulding at the main arch's springing, round the pier.
		lm.box("Stone", Vector3(sx * 8.8, y0 + spring - 0.4, 0), Vector3(8.9, 0.8, dep + 0.5))
		# Plinth course round the pier foot.
		lm.box("Stone", Vector3(sx * 8.8, y0 + 0.6, 0), Vector3(8.9, 1.2, dep + 0.5))
	# Main arch: spandrels and the barrel vault, transverse ribs.
	_vault(lm, "Stone", Vector3(0, y0, 0), span, top - y0, dep, spring)
	for sz in [-1.0, 1.0]:
		LandmarkDetail.arch(lm, "Stone", Vector3(0, y0 + spring - span * 0.5 + span * 0.5, sz * dep * 0.5),
			Vector3(0, 0, sz), span, 1.1, 0.4)
		LandmarkDetail.arch(lm, "Stone", Vector3(0, y0 + spring, sz * (dep * 0.5 + 0.4)), Vector3(0, 0, sz),
			span + 2.2, 0.7, 0.25)
		lm.box("Names", Vector3(0, y0 + 22.6, sz * 5.04), Vector3(8.0, 2.0, 0.1), Basis(), 0.0)
	for z in [-3.0, 0.0, 3.0]:
		var prev := Vector3(-span * 0.5, y0 + spring, z)
		for i in 12:
			var a := PI * (1.0 - float(i + 1) / 12.0)
			var p := Vector3(cos(a) * span * 0.5, y0 + spring + sin(a) * span * 0.5, z)
			lm.beam("Stone", prev + Vector3(0, -0.2, 0), p + Vector3(0, -0.2, 0), 0.5, 0.4)
			prev = p
	# Frieze with imperial suns, then the cornice.
	lm.box("Stone", Vector3(0, top + 0.55, 0), Vector3(26.2, 1.1, dep + 0.2))
	for sz in [-1.0, 1.0]:
		for k in 7:
			lm.disc("Granite", Vector3(-10.8 + 3.6 * float(k), top + 0.55, sz * (dep * 0.5 + 0.12)),
				Vector3(0, 0, sz), 0.42, 12)
	var ct := top + 1.1
	var hw := 13.1
	var hd := dep * 0.5 + 0.1
	var corners := [Vector3(-hw, ct, hd), Vector3(hw, ct, hd), Vector3(hw, ct, -hd), Vector3(-hw, ct, -hd)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var mid := (a + b) * 0.5
		var out := Vector3(signf(mid.x) if absf(mid.x) > 1.0 else 0.0, 0, signf(mid.z) if absf(mid.z) > 1.0 else 0.0)
		LandmarkDetail.cornice(lm, "Stone", a, b, out, 1.3, true)
	# Attic with the inscription, two set-backs, the bowl.
	lm.box("Stone", Vector3(0, 32.4, 0), Vector3(24.0, 4.0, 8.6))
	for sz in [-1.0, 1.0]:
		lm.box("Names", Vector3(0, 33.0, sz * 4.32), Vector3(6.0, 1.6, 0.08), Basis(), 0.0)
		for sx in [-1.0, 1.0]:
			lm.box("Names", Vector3(sx * 7.5, 33.0, sz * 4.32), Vector3(4.6, 1.1, 0.08), Basis(), 0.0)
			lm.box("Stone", Vector3(sx * 11.2, 32.4, sz * 4.35), Vector3(1.0, 4.0, 0.2))
	lm.box("Stone", Vector3(0, 34.55, 0), Vector3(25.0, 0.3, 9.4))
	lm.box("Stone", Vector3(0, 35.9, 0), Vector3(19.0, 2.4, 7.4))
	lm.box("Stone", Vector3(0, 37.2, 0), Vector3(19.8, 0.3, 8.0))
	lm.box("Stone", Vector3(0, 38.2, 0), Vector3(13.0, 1.7, 6.4))
	lm.box("Granite", Vector3(0, 39.15, 0), Vector3(13.6, 0.2, 7.0))
	lm.lathe("Granite", Vector3(0, 39.25, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(2.6, 0.5),
		Vector2(3.4, 1.1), Vector2(3.6, 1.6), Vector2(3.3, 2.1), Vector2(2.2, 2.55), Vector2(0.6, 2.75),
		Vector2(0.0, 2.75)]), 32)
	# Amar Jawan Jyoti: black marble cenotaph with four urns.
	lm.box("Names", Vector3(0, 2.4, 0), Vector3(3.6, 0.8, 3.6))
	lm.box("Names", Vector3(0, 3.1, 0), Vector3(1.6, 0.6, 1.6))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.lathe("Names", Vector3(sx * 1.5, 2.8, sz * 1.5), PackedVector2Array([Vector2(0.15, 0),
				Vector2(0.3, 0.3), Vector2(0.25, 0.6), Vector2(0.32, 0.7)]), 10)
	lm.commit(model)

## The span over a round arch between two piers: front and back
## spandrels (springing `spring`, span w) and the barrel soffit.
static func _vault(lm: LandmarkMesh, key: String, base: Vector3, w: float, height: float, depth: float,
		spring: float) -> void:
	var r := w * 0.5
	var hd := depth * 0.5
	var steps := 16
	for side in [1.0, -1.0]:
		var z: float = hd * side
		for i in steps:
			var a0 := PI * (1.0 - float(i) / steps)
			var a1 := PI * (1.0 - float(i + 1) / steps)
			lm.quad(key, base + Vector3(r * cos(a0), spring + r * sin(a0), z),
				base + Vector3(r * cos(a1), spring + r * sin(a1), z), base + Vector3(r * cos(a1), height, z),
				base + Vector3(r * cos(a0), height, z), Vector3(0, 0, side))
	for i in steps:
		var a0 := PI * (1.0 - float(i) / steps)
		var a1 := PI * (1.0 - float(i + 1) / steps)
		var am := (a0 + a1) * 0.5
		lm.quad(key, base + Vector3(r * cos(a0), spring + r * sin(a0), -hd),
			base + Vector3(r * cos(a0), spring + r * sin(a0), hd), base + Vector3(r * cos(a1), spring + r * sin(a1), hd),
			base + Vector3(r * cos(a1), spring + r * sin(a1), -hd), Vector3(-cos(am), -sin(am), 0))
