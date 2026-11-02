class_name LandmarkEahChina
extends RefCounted

## Historic Beijing in true metres: Tiananmen (34.7 m since the 1970
## rebuild: the red gate platform on its marble base, pierced by five
## arched passages, carrying the nine-by-five-bay hall, 57.1 x 21.0 m,
## under its double-eave hip-and-gable roof of yellow glazed tiles; the
## portrait over the central passage, the five marble Golden Water
## Bridges with their lions in front and four huabiao columns) and the
## Tower of Buddhist Incense at the Summer Palace (61 m: the octagonal
## three-storey, four-eave tower, 41 m, of yellow tiles edged green, on
## its 20 m terraced stone platform). Fronts face south (+Z).

# --- Tiananmen ---

const TIAN_M := 34.7
## Passages [x, width, height to the crown] through the gate platform.
const TIAN_ARCHES := [[-26.0, 3.8, 5.6], [-13.0, 4.4, 6.0], [0.0, 5.2, 6.4], [13.0, 4.4, 6.0],
	[26.0, 3.8, 5.6]]
const TIAN_PLAT := Vector2(118.0, 38.0)
const TIAN_TOP := 11.4
const TIAN_HALL := Vector2(57.1, 21.0)

static func tiananmen(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4E0D6", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#9E3328", 4.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#A82E26", 0.65, 0.0))
	lm.use("Bracket", LandmarkMaterials.paint("#2F6B7E", 0.6, 0.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D9A52C", 2.0, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	lm.use("Portrait", LandmarkMaterials.paint("#5E5A52", 0.7, 0.0))
	_tian_platform(lm)
	# Marble terrace (1.2 m) with its balustrade on the platform top.
	var yt := TIAN_TOP + 1.2
	LandmarkEahParts.slab(lm, "Marble", Vector3(-32.0, TIAN_TOP, -13.5), Vector3(32.0, yt, 13.5))
	LandmarkAeParts.cn_balustrade_loop(lm, "Marble", LandmarkAeParts.rect_pts(0, 0, 64.0, 27.0), yt, 1.1, 2.0, false)
	LandmarkAeParts.steps(lm, "Marble", Vector3(0, TIAN_TOP, 13.5), Vector3(0, 0, 1), 8.0, 1.2, 5, 0.3)
	# Hall: 10 x 6 columns round the 9 x 5 bays, lattice doors in every
	# front and back bay, red end walls, tie beams.
	var hw := TIAN_HALL
	LandmarkEahParts.colonnade(lm, "Lacquer", Vector2.ZERO, hw, yt, 7.2, 9, 5, 0.42, 12)
	lm.box("Lacquer", Vector3(0, yt + 3.6, 0), Vector3(hw.x - 0.8, 7.2, hw.y - 0.8))
	LandmarkEahDetail.bays(lm, "Lacquer", "Shadow", Vector3(0, yt, 0), hw - Vector2(0.8, 0.8), 6.6, 9, 5,
		func(face: int, _i: int) -> int: return 1 if face < 2 else 0)
	LandmarkEahDetail.ring_beams(lm, "Bracket", Vector3.ZERO, hw, yt + 6.6, 0.6, 0.5)
	LandmarkEahDetail.ring_beams(lm, "Lacquer", Vector3.ZERO, hw, yt + 6.0, 0.4, 0.45)
	# Lower eave: bracket sets, skirt hip roof to the clerestory.
	var yb := yt + 7.2
	LandmarkAeParts.brackets(lm, "Bracket", Vector3(0, yb, 0), hw.x, hw.y, 1.1, 1.6)
	var y1 := yb + 1.1
	var e1 := Vector2(65.0, 29.0)
	var cl := Vector2(49.0, 13.6)
	LandmarkAeParts.hip_roof(lm, "Roof", Vector3(0, y1, 0), e1, cl, 2.4, 1.0)
	LandmarkAeParts.eave_fascia(lm, "Lacquer", Vector3(0, y1, 0), e1, 1.0, 0.35, hw, 0.7)
	LandmarkAeParts.hip_ridges(lm, "Roof", Vector3(0, y1, 0), e1, cl, 2.4, 1.0, 0.4, 5)
	# Clerestory, upper bracket band, the hip-and-gable roof.
	var y2 := y1 + 2.4
	lm.box("Lacquer", Vector3(0, y2 + 0.9, 0), Vector3(cl.x, 1.8, cl.y))
	LandmarkEahDetail.ring_beams(lm, "Bracket", Vector3.ZERO, cl + Vector2(0.2, 0.2), y2 + 1.5, 0.6, 0.3)
	var yb2 := y2 + 1.8
	LandmarkAeParts.brackets(lm, "Bracket", Vector3(0, yb2, 0), cl.x, cl.y, 1.2, 1.6)
	var y3 := yb2 + 1.2
	var e3 := Vector2(60.0, 25.0)
	var r3 := Vector2(38.0, 6.0)
	LandmarkEahParts.irimoya(lm, "Roof", "Wall", Vector3(0, y3, 0), e3, r3, 3.0, 2.0, 1.0)
	LandmarkAeParts.eave_fascia(lm, "Lacquer", Vector3(0, y3, 0), e3, 1.0, 0.35, cl, 0.7)
	LandmarkAeParts.hip_ridges(lm, "Roof", Vector3(0, y3, 0), e3, r3, 3.0, 1.0, 0.4, 9)
	var ridge := y3 + 5.0
	LandmarkEahDetail.ridge(lm, "Roof", -19.0, 19.0, ridge - 0.1, 0.0, 1.0, 0.8)
	for s in [-1.0, 1.0]:
		LandmarkAeParts.chiwen(lm, "Roof", Vector3(s * 18.4, ridge + 0.5, 0), TIAN_M - ridge - 0.5, -s)
		# Gilt studded ornament on the gable ends.
		lm.box("Gold", Vector3(s * 19.05, y3 + 3.8, 0), Vector3(0.12, 1.0, 1.0), Basis(), 0.0)
	# Golden Water Bridges, lions and huabiao.
	_water_bridges(lm, 46.0)
	for sx in [-1.0, 1.0]:
		_lion(lm, Vector3(sx * 7.2, 0, 56.0))
		_lion(lm, Vector3(sx * 7.2, 0, 35.0))
		_huabiao(lm, Vector3(sx * 22.0, 0, 60.0))
		_huabiao(lm, Vector3(sx * 22.0, 0, -32.0))
	lm.commit(model)

## The red platform: marble base course and red walls between the five
## passages, the arched heads of the passages on both faces, coping and
## parapets, the portrait over the centre and the slogan boards.
static func _tian_platform(lm: LandmarkMesh) -> void:
	var hx := TIAN_PLAT.x * 0.5
	var hz := TIAN_PLAT.y * 0.5
	var x0 := -hx
	for a in TIAN_ARCHES:
		var ax := float(a[0])
		var aw := float(a[1])
		var ah := float(a[2])
		var spring := ah - aw * 0.5
		var left := ax - aw * 0.5
		_tian_pier(lm, x0, left, hz)
		lm.box("Wall", Vector3(ax, (spring + TIAN_TOP) * 0.5, 0), Vector3(aw, TIAN_TOP - spring, TIAN_PLAT.y))
		for s in [-1.0, 1.0]:
			lm.disc("Shadow", Vector3(ax, spring, s * (hz + 0.03)), Vector3(0, 0, s), aw * 0.5, 20)
			# Marble door frame at the foot of each passage, studded leaves.
			LandmarkEahDetail.studded_door(lm, "Lacquer", "Gold", Vector3(ax, spring * 0.5, s * (hz - 3.0)),
				Vector3(0, 0, s), aw, spring, 7, 5)
		lm.box("Shadow", Vector3(ax, 0.02, 0), Vector3(aw, 0.04, TIAN_PLAT.y))
		x0 = ax + aw * 0.5
	_tian_pier(lm, x0, hx, hz)
	# Coping, parapets (crenellated to the south) and corner caps.
	lm.box("Marble", Vector3(0, TIAN_TOP - 0.2, 0), Vector3(TIAN_PLAT.x + 0.6, 0.4, TIAN_PLAT.y + 0.6))
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(0, TIAN_TOP + 0.6, s * (hz - 0.3)), Vector3(TIAN_PLAT.x, 1.2, 0.6))
		lm.box("Wall", Vector3(s * (hx - 0.3), TIAN_TOP + 0.6, 0), Vector3(0.6, 1.2, TIAN_PLAT.y - 1.2))
	for k in 46:
		var x := -hx + 1.3 + 2.5 * k
		lm.box("Wall", Vector3(x, TIAN_TOP + 1.6, hz - 0.3), Vector3(1.5, 0.8, 0.6), Basis(), 0.0)
	# Portrait over the central passage and the two slogan boards.
	lm.box("Gold", Vector3(0, 8.65, hz + 0.1), Vector3(6.2, 4.6, 0.12), Basis(), 0.0)
	lm.box("Portrait", Vector3(0, 8.65, hz + 0.18), Vector3(5.7, 4.1, 0.1), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Lacquer", Vector3(s * 19.5, 8.2, hz + 0.1), Vector3(14.0, 1.8, 0.14), Basis(), 0.0)
		for k in 9:
			lm.box("Marble", Vector3(s * 19.5 - 6.0 + 1.5 * k, 8.2, hz + 0.19), Vector3(1.1, 1.2, 0.05), Basis(), 0.0)

## One stretch of the platform between passages: the marble base course
## (with its moulding) and the red wall above, x from a to b.
static func _tian_pier(lm: LandmarkMesh, a: float, b: float, hz: float) -> void:
	var w := b - a
	var mx := (a + b) * 0.5
	lm.box("Marble", Vector3(mx, 0.7, 0), Vector3(w, 1.4, TIAN_PLAT.y + 1.2))
	lm.box("Marble", Vector3(mx, 1.5, 0), Vector3(w, 0.2, TIAN_PLAT.y + 0.8), Basis(), 0.0)
	lm.box("Wall", Vector3(mx, (1.4 + TIAN_TOP) * 0.5, 0), Vector3(w, TIAN_TOP - 1.4, TIAN_PLAT.y))

## The five marble Golden Water Bridges over the moat at z, humped decks
## with balustrades (the middle one widest), and the moat's marble rails.
static func _water_bridges(lm: LandmarkMesh, z: float) -> void:
	var xs := [-26.0, -13.0, 0.0, 13.0, 26.0]
	var ws := [4.6, 5.8, 8.6, 5.8, 4.6]
	for i in 5:
		var x: float = xs[i]
		var w: float = ws[i]
		var prev := Vector3.ZERO
		for k in 7:
			var t := float(k) / 6.0 * 2.0 - 1.0
			var p := Vector3(x, 0.4 + 1.2 * (1.0 - t * t), z + t * 6.0)
			if k > 0:
				lm.beam("Marble", prev, p, w, 0.8, Vector3.RIGHT)
				for s in [-1.0, 1.0]:
					LandmarkAeParts.cn_balustrade(lm, "Marble", prev + Vector3(s * (w * 0.5 - 0.2), 0.4, 0),
						p + Vector3(s * (w * 0.5 - 0.2), 0.4, 0), 1.0, 2.0, Vector3.ZERO, k == 6)
			prev = p
	for s in [-1.0, 1.0]:
		var zr: float = z + s * 4.2
		for seg in [[-58.0, -30.0], [-22.6, -16.6], [-9.4, -4.9], [4.9, 9.4], [16.6, 22.6], [30.0, 58.0]]:
			LandmarkAeParts.cn_balustrade(lm, "Marble", Vector3(float(seg[0]), 0.0, zr), Vector3(float(seg[1]), 0.0, zr), 1.0, 2.0)

## Seated stone lion on its pedestal.
static func _lion(lm: LandmarkMesh, at: Vector3) -> void:
	LandmarkEahParts.slab(lm, "Marble", at + Vector3(-1.0, 0, -1.5), at + Vector3(1.0, 1.4, 1.5))
	lm.box("Marble", at + Vector3(0, 1.5, 0), Vector3(2.2, 0.2, 3.2), Basis(), 0.0)
	lm.lathe("Marble", at + Vector3(0, 1.6, -0.2), PackedVector2Array([Vector2(0.7, 0), Vector2(0.75, 0.6),
		Vector2(0.6, 1.3), Vector2(0.3, 1.6)]), 10, 0.9, 1.2)
	LandmarkAeParts.ball(lm, "Marble", at + Vector3(0, 3.4, 0.25), 0.62, 12, 6)
	for s in [-1.0, 1.0]:
		lm.box("Marble", at + Vector3(s * 0.45, 2.0, 0.7), Vector3(0.35, 0.9, 0.35), Basis(), 0.0)

## Marble huabiao (about 9.6 m): railed base, octagonal shaft with a
## coiling dragon, cloud plate, disc and crowning beast.
static func _huabiao(lm: LandmarkMesh, at: Vector3) -> void:
	LandmarkEahParts.slab(lm, "Marble", at + Vector3(-1.7, 0.0, -1.7), at + Vector3(1.7, 0.8, 1.7))
	LandmarkEahParts.slab(lm, "Marble", at + Vector3(-1.2, 0.8, -1.2), at + Vector3(1.2, 1.6, 1.2))
	LandmarkAeParts.cn_balustrade_loop(lm, "Marble", LandmarkAeParts.rect_pts(at.x, at.z, 4.4, 4.4, 0.0), at.y,
		0.9, 1.4, false)
	lm.frustum("Marble", at + Vector3(0, 1.6, 0), 0.56, 0.48, 6.5, 8, PI / 8.0)
	var prev := at + Vector3(0.55, 1.9, 0)
	for k in range(1, 25):
		var a := float(k) * 0.42
		var p := at + Vector3(cos(a) * 0.55, 1.9 + 0.22 * k, sin(a) * 0.55)
		LandmarkAeParts.tube(lm, "Marble", prev, p, 0.16, 0.16, 6)
		prev = p
	lm.box("Marble", at + Vector3(0, 7.2, 0), Vector3(0.4, 1.0, 3.6), Basis(Vector3.UP, 0.0), 0.0)
	lm.box("Marble", at + Vector3(0, 8.25, 0), Vector3(0.5, 0.3, 4.4))
	lm.lathe("Marble", at + Vector3(0, 8.4, 0), PackedVector2Array([Vector2(0.75, 0), Vector2(0.75, 0.3),
		Vector2(0.4, 0.45)]), 12)
	lm.box("Marble", at + Vector3(0, 9.05, 0), Vector3(0.45, 0.9, 0.8), Basis(), 0.0)
	LandmarkAeParts.ball(lm, "Marble", at + Vector3(0, 9.55, 0.3), 0.25, 8, 4)

# --- Tower of Buddhist Incense ---

const INCENSE_M := 61.0

static func incense_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A9A395", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4E0D6", 3.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#9A2B22", 0.65, 0.0))
	lm.use("Bracket", LandmarkMaterials.paint("#2F6B7E", 0.6, 0.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D9A52C", 2.0, 0.35))
	lm.use("Green", LandmarkMaterials.pbr("terracotta", "#2F7A58", 2.0, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	# Terraced platform (20 m): battered stone stages, marble copings and
	# balustrades, central stair, the octagonal marble base of the tower.
	LandmarkAeParts.batter(lm, "Stone", 0, 0, 66.0, 42.0, 58.0, 36.0, 0.0, 7.0)
	LandmarkEahParts.slab(lm, "Marble", Vector3(-29.5, 7.0, -18.5), Vector3(29.5, 7.6, 18.5))
	LandmarkAeParts.batter(lm, "Stone", 0, 0, 50.0, 30.0, 44.0, 26.0, 7.6, 17.0)
	LandmarkEahParts.slab(lm, "Marble", Vector3(-22.5, 17.0, -14.5), Vector3(22.5, 17.8, 14.5))
	LandmarkAeParts.cn_balustrade_loop(lm, "Marble", LandmarkAeParts.rect_pts(0, 0, 59.0, 37.0), 7.6, 1.1, 2.0)
	LandmarkAeParts.cn_balustrade_loop(lm, "Marble", LandmarkAeParts.rect_pts(0, 0, 45.0, 29.0), 17.8, 1.1, 2.0)
	LandmarkEahParts.stairs(lm, "Stone", 0.0, 26.0, 0.0, 8.0, 34, 0.5, 0.38)
	for s in [-1.0, 1.0]:
		lm.beam("Marble", Vector3(s * 4.2, 1.0, 26.0), Vector3(s * 4.2, 17.8, 13.2), 0.5, 0.9, Vector3.RIGHT)
	lm.frustum("Marble", Vector3(0, 17.8, 0), 15.0, 14.2, 2.2, 8, PI / 8.0)
	_oct_balustrade(lm, 14.2, 20.0)
	# Tower, 41 m on the platform: red octagonal storeys [radius, height]
	# under four yellow eaves edged green [eave radius, top radius, rise]:
	# the ground storey's veranda skirt, then one eave per storey, the
	# top a pyramidal roof under the gilt finial.
	var y := 20.0
	var bodies := [[9.8, 8.5], [7.4, 5.5], [5.6, 5.0]]
	var roofs := [[13.4, 10.0, 2.6], [12.0, 7.6, 3.8], [10.0, 5.9, 3.6], [8.6, 0.9, 6.6]]
	# Ground storey: a ring of 16 veranda columns under the skirt eave.
	for k in 16:
		var col_r := 12.2 if k % 2 == 1 else 12.2 * cos(PI / 8.0)
		var ang := TAU * k / 16.0
		LandmarkEahParts.column(lm, "Lacquer", Vector3(col_r * cos(ang), y, col_r * sin(ang)), 4.4, 0.42, 12)
	_oct_bracket_ring(lm, y + 4.4, 12.3, 0.9, 32)
	_oct_roof(lm, y + 5.3, roofs[0])
	for t in 3:
		var r: float = bodies[t][0]
		var h: float = bodies[t][1]
		lm.frustum("Lacquer", Vector3(0, y, 0), r, r, h, 8, PI / 8.0)
		var apothem := r * cos(PI / 8.0)
		for k in 8:
			var ang := PI * 0.25 * k
			var n := Vector3(cos(ang), 0, sin(ang))
			LandmarkEahDetail.lattice(lm, "Lacquer", "Shadow", n * (apothem + 0.02) + Vector3(0, y + h * 0.45, 0), n,
				r * 0.5, h * 0.62, 6, 4)
		if t > 0:
			_oct_balustrade(lm, r + 1.4, y)
		y += h
		_oct_bracket_ring(lm, y, r + 0.3, 0.9, 24 + 8 * (2 - t))
		y += 0.9
		_oct_roof(lm, y, roofs[t + 1])
		y += float(roofs[t + 1][2])
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(1.0, 0.5),
		Vector2(0.7, 1.1), Vector2(0.25, 1.6), Vector2(0.12, INCENSE_M - y)]), 12)
	LandmarkAeParts.ball(lm, "Gold", Vector3(0, y + 1.9, 0), 0.6, 12, 6)
	lm.commit(model)

## Octagonal concave roof at y [eave radius, top radius, rise]: yellow
## tiles, the green-glazed edge band, eight hip ridges with upturned ends.
static func _oct_roof(lm: LandmarkMesh, y: float, spec: Array) -> void:
	var re: float = spec[0]
	var rt: float = spec[1]
	var rise: float = spec[2]
	var prof := PackedVector2Array([Vector2(re + 0.6, 0.5), Vector2(re, 0.0),
		Vector2(lerpf(re, rt, 0.45), rise * 0.28), Vector2(lerpf(re, rt, 0.8), rise * 0.62), Vector2(rt, rise)])
	lm.lathe("Roof", Vector3(0, y, 0), prof, 8, 1.0, 1.0, PI / 8.0, false)
	var edge := prof[1].lerp(prof[2], 0.22)
	lm.lathe("Green", Vector3(0, y + 0.06, 0), PackedVector2Array([prof[0], prof[1], edge]), 8,
		1.0, 1.0, PI / 8.0, false, false)
	var k := 1.0 / cos(PI / 8.0)
	for i in 8:
		var a := PI / 8.0 + PI * 0.25 * i
		var d := Vector3(cos(a), 0, sin(a))
		var prev := d * (re + 0.9) * k * 0.98 + Vector3(0, y + 0.9, 0)
		for j in range(1, prof.size()):
			var p := d * prof[j].x * k + Vector3(0, y + prof[j].y + 0.25, 0)
			lm.beam("Green", prev, p, 0.45, 0.4)
			prev = p

## Octagonal ring of bracket sets (dougong) at y: n sets on a circle of
## radius r, three tiers stepping out, and the ring purlin they carry.
static func _oct_bracket_ring(lm: LandmarkMesh, y: float, r: float, h: float, n: int) -> void:
	for i in n:
		var a := TAU * (float(i) + 0.5) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		var basis := Basis(d.cross(Vector3.UP).normalized(), Vector3.UP, d)
		for t in 3:
			lm.box("Bracket", d * (r + 0.15 + 0.25 * t) + Vector3(0, y + h * (float(t) + 0.5) / 3.0, 0),
				Vector3(0.4 + 0.3 * t, h / 3.0 * 0.9, 0.3 + 0.45 * t), basis, 0.0)
	lm.frustum("Bracket", Vector3(0, y + h - 0.1, 0), (r + 0.9) / cos(PI / 8.0), (r + 0.9) / cos(PI / 8.0), 0.3, 8, PI / 8.0)

## Marble balustrade round an octagon of apothem-ish radius r at y.
static func _oct_balustrade(lm: LandmarkMesh, r: float, y: float) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := PI / 8.0 + PI * 0.25 * i
		pts.append(Vector2(cos(a), sin(a)) * r)
	LandmarkAeParts.cn_balustrade_loop(lm, "Marble", pts, y, 1.0, 1.6, false)
