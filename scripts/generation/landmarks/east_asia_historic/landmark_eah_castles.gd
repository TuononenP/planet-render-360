class_name LandmarkEahCastles
extends RefCounted

## Japanese castle keeps in true metres: Osaka Castle (54.8 m with the
## shachi: the 1931 five-roof, eight-floor keep on the 14.7 m Tokugawa
## stone base; white plaster storeys with barred windows, verdigris
## copper roofs carrying chidori and kara gables, and the black top
## storey with its gilt tigers, cranes and railed balcony) and Matsumoto
## Castle (29.4 m: the black-and-white five-roof, six-floor keep with
## chidori gables on the second roof N/S and third roof E/W, the kara
## gable bay windows on the third floor N/S and stone-drop bays, the Inui
## small keep to the north on its covered passage, the Tatsumi turret and
## the open moon-viewing turret with red railings to the east, and the
## red Uzumi bridge over the inner moat to the west). Fronts face south
## (+Z).

const FACES := [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]

# --- Osaka Castle ---

const OSAKA_M := 55.0
const OSAKA_PLANS := [Vector2(28.0, 24.0), Vector2(24.8, 21.2), Vector2(21.6, 18.4),
	Vector2(18.4, 15.6), Vector2(15.2, 12.8)]
const OSAKA_WALLS := [6.0, 5.2, 4.8, 4.4, 4.8]
const OSAKA_RISES := [2.2, 2.0, 1.9, 1.8]
## Gables per roof on the long (south/north) and short (east/west) faces:
## 0 none, 1 one central chidori, 2 a pair of chidori, 3 a central kara.
const OSAKA_GABLES := [[1, 3], [2, 1], [3, 1], [1, 0]]

static func osaka(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F897D", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#F0ECE2", 3.0))
	lm.use("Black", LandmarkMaterials.paint("#1B1A19", 0.5, 0.0))
	lm.use("Copper", LandmarkMaterials.pbr("slate", "#4F8B72", 1.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	# Tokugawa stone base, its capping course and the entrance passage.
	LandmarkEahParts.stone_base(lm, "Stone", Vector2.ZERO, Vector2(36.0, 31.0), 0.0, 14.7, Vector2(11.0, 9.0))
	LandmarkEahParts.slab(lm, "Stone", Vector3(-18.3, 14.3, -15.8), Vector3(18.3, 14.9, 15.8))
	LandmarkEahParts.slab(lm, "Stone", Vector3(-9.0, 0.0, 14.0), Vector3(-3.0, 5.2, 21.0))
	LandmarkEahParts.arch_open(lm, "Shadow", Vector3(-6.0, 0, 21.0), Vector3(0, 0, 1), 0.0, 3.4, 4.2)
	var y := 14.9
	for i in 5:
		var w: Vector2 = OSAKA_PLANS[i]
		var h: float = OSAKA_WALLS[i]
		var top := i == 4
		var c := Vector3(0, y, 0)
		lm.box("Black" if top else "Plaster", c + Vector3(0, h * 0.5, 0), Vector3(w.x, h, w.y))
		# Nageshi bands under the windows and at the wall head.
		for band in [0.18, 0.92]:
			LandmarkEahDetail.ring_beams(lm, "Black" if top else "Plaster", c + Vector3(0, 0, 0), w + Vector2(0.1, 0.1),
				y + h * float(band), 0.22, 0.14)
		_osaka_windows(lm, c, w, h, top)
		if i == 0:
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var n := Vector3(0, 0, sz)
					LandmarkEahDetail.ishi_otoshi(lm, "Plaster", Vector3(sx * (w.x * 0.5 - 1.6), y + 1.2,
						sz * w.y * 0.5), n, 2.6, 2.4, 0.7)
		y += h
		if top:
			break
		var rc := Vector3(0, y, 0)
		var eave := w + Vector2(6.0, 5.0)
		var ridge := w - Vector2(2.0, 1.8)
		var rise: float = OSAKA_RISES[i]
		LandmarkAeParts.hip_roof(lm, "Copper", rc, eave, ridge, rise, 0.6)
		LandmarkAeParts.eave_fascia(lm, "Plaster", rc, eave, 0.6, 0.45, w, 0.9)
		LandmarkAeParts.hip_ridges(lm, "Copper", rc, eave, ridge, rise, 0.6, 0.4)
		_osaka_gables(lm, rc, w, rise, OSAKA_GABLES[i])
		y += rise
	# Top-storey balcony (the outer gallery with its black railing).
	var w4: Vector2 = OSAKA_PLANS[4]
	var yb := 14.9 + 6.0 + 2.2 + 5.2 + 2.0 + 4.8 + 1.9 + 4.4 + 1.8
	LandmarkEahParts.slab(lm, "Black", Vector3(-w4.x * 0.5 - 1.2, yb - 0.3, -w4.y * 0.5 - 1.2),
		Vector3(w4.x * 0.5 + 1.2, yb, w4.y * 0.5 + 1.2))
	LandmarkEahDetail.railing_loop(lm, "Black", Vector3(0, yb, 0), w4 + Vector2(2.2, 2.2), 1.0, 1.4, 0.12)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Gold", Vector3(sx * (w4.x * 0.5 + 1.1), yb + 1.08, sz * (w4.y * 0.5 + 1.1)), Vector3(0.24, 0.16, 0.24), Basis(), 0.0)
	# Great top roof (hip below, gable above), ridge roll, gilt shachi.
	var te := w4 + Vector2(7.0, 6.0)
	LandmarkEahParts.irimoya(lm, "Copper", "Plaster", Vector3(0, y, 0), te, Vector2(13.0, 9.0), 2.2, 3.0, 0.6)
	LandmarkAeParts.eave_fascia(lm, "Plaster", Vector3(0, y, 0), te, 0.6, 0.45, w4, 0.9)
	LandmarkAeParts.hip_ridges(lm, "Copper", Vector3(0, y, 0), te, Vector2(13.0, 9.0), 2.2, 0.6, 0.4)
	for s in [-1.0, 1.0]:
		lm.box("Gold", Vector3(s * 6.6, y + 3.6, 0), Vector3(0.12, 0.9, 0.9), Basis(), 0.0)
	var ridge_y := y + 5.2
	LandmarkEahDetail.ridge(lm, "Copper", -6.5, 6.5, ridge_y - 0.1, 0.0, 0.9, 0.6)
	for s in [-1.0, 1.0]:
		_shachi(lm, "Gold", Vector3(s * 6.2, ridge_y + 0.3, 0), OSAKA_M - ridge_y - 0.3, -s)
	lm.commit(model)

## Barred windows (copper-green grilles on white; gilt-trimmed on the
## black top storey) on each face, gilt tigers and cranes up top.
static func _osaka_windows(lm: LandmarkMesh, c: Vector3, w: Vector2, h: float, top: bool) -> void:
	var frame := "Gold" if top else "Copper"
	for n in FACES:
		var nv: Vector3 = n
		var run := w.x if absf(nv.z) > 0.5 else w.y
		var off := w.y * 0.5 if absf(nv.z) > 0.5 else w.x * 0.5
		var along := Vector3(absf(nv.z), 0, absf(nv.x))
		var cnt := int(run / 3.4)
		for k in cnt:
			var t := (float(k) + 0.5) / float(cnt) - 0.5
			var p := c + nv * (off + 0.02) + along * t * run + Vector3(0, h * 0.5, 0)
			if top and k % 2 == 0:
				# Gilt tiger relief under the balcony between the windows.
				lm.box("Gold", p - Vector3(0, h * 0.28, 0) + nv * 0.08, Vector3(2.0 * along.x + 0.16 * absf(nv.x),
					1.1, 2.0 * along.z + 0.16 * absf(nv.z)), Basis(), 0.0)
				lm.box("Gold", p + Vector3(0, h * 0.34, 0) + nv * 0.08, Vector3(1.4 * along.x + 0.12 * absf(nv.x),
					0.6, 1.4 * along.z + 0.12 * absf(nv.z)), Basis(), 0.0)
				continue
			LandmarkEahDetail.castle_window(lm, frame, "Shadow", p, nv, 1.5, h * 0.36, 5)

## Chidori / kara gables on one roof per OSAKA_GABLES.
static func _osaka_gables(lm: LandmarkMesh, rc: Vector3, w: Vector2, rise: float, spec: Array) -> void:
	for n in FACES:
		var nv: Vector3 = n
		var kind: int = spec[0] if absf(nv.z) > 0.5 else spec[1]
		var off := w.y * 0.5 + 1.2 if absf(nv.z) > 0.5 else w.x * 0.5 + 1.2
		var along := Vector3(absf(nv.z), 0, absf(nv.x))
		var base := rc + nv * off + Vector3(0, 0.3, 0)
		match kind:
			1:
				LandmarkEahDetail.chidori(lm, "Copper", "Plaster", "Plaster", base, nv, 7.0, 2.8, 4.0, "Gold")
			2:
				for s in [-1.0, 1.0]:
					LandmarkEahDetail.chidori(lm, "Copper", "Plaster", "Plaster", base + along * s * w.x * 0.22, nv,
						5.0, 2.2, 3.2, "Gold")
			3:
				LandmarkEahDetail.karahafu(lm, "Copper", "Plaster", "Plaster", base - Vector3(0, 0.2, 0), nv, 6.0, 1.6,
					3.0, "Gold")

## Shachi: the gilt tiger-headed carp on a ridge end, `h` tall, its head
## on the ridge and its tail flicked up and out (away from `inward`).
static func _shachi(lm: LandmarkMesh, key: String, base: Vector3, h: float, inward: float) -> void:
	var head := base + Vector3(inward * 0.25, h * 0.2, 0)
	LandmarkAeParts.tube(lm, key, base, head, 0.45, 0.5, 10)
	var prev := head
	for i in 5:
		var t := float(i + 1) / 5.0
		var p := base + Vector3(-inward * (0.15 + 0.5 * t * t), h * (0.2 + 0.7 * t), 0)
		LandmarkAeParts.tube(lm, key, prev, p, lerpf(0.5, 0.2, t - 0.2), lerpf(0.5, 0.15, t), 10)
		prev = p
	# Tail fin, pectoral fins.
	lm.box(key, prev + Vector3(-inward * 0.2, h * 0.08, 0), Vector3(0.9, h * 0.18, 0.12),
		Basis(Vector3.FORWARD, inward * 0.4), 0.0)
	for s in [-1.0, 1.0]:
		lm.box(key, base + Vector3(0, h * 0.4, s * 0.35), Vector3(0.5, 0.3, 0.08), Basis(Vector3.FORWARD, inward * 0.6), 0.0)

# --- Matsumoto Castle ---

const MATSUMOTO_M := 29.4

static func matsumoto(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#85807A", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EFEBE1", 3.0))
	lm.use("Black", LandmarkMaterials.paint("#1D1A18", 0.55, 0.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#3E4246", 1.5))
	lm.use("Red", LandmarkMaterials.paint("#B3261E", 0.55, 0.0))
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#5A4636", 2.0))
	# Main keep: five roofs, six floors (the third floor hidden under the
	# second roof), 29.4 m.
	var top := _keep(lm, Vector2.ZERO, Vector2(19.0, 16.5), 4.2,
		[Vector2(15.4, 12.8), Vector2(13.4, 11.0), Vector2(11.6, 9.8), Vector2(9.6, 8.4), Vector2(7.8, 6.8)],
		[4.0, 3.5, 2.5, 3.0, 3.2], [1.4, 1.4, 1.4, 1.3], 2.4, [[0, 0], [1, 0], [2, 1], [0, 0]])
	LandmarkEahDetail.ridge(lm, "Tile", -1.9, 1.9, top - 0.35, 0.0, 0.55, 0.45)
	for s in [-1.0, 1.0]:
		_shachi(lm, "Black", Vector3(s * 1.7, top, 0), MATSUMOTO_M - top, -s)
	# Inui small keep to the north, joined by the covered passage (watari
	# yagura) on its own stone base.
	var itop := _keep(lm, Vector2(-3.0, -17.0), Vector2(12.0, 10.4), 4.0,
		[Vector2(9.0, 7.6), Vector2(7.2, 6.2), Vector2(5.8, 5.0)], [3.6, 3.2, 3.0], [1.3, 1.2], 2.8,
		[[0, 0], [0, 0]])
	LandmarkEahDetail.ridge(lm, "Tile", -4.0, -2.0, itop - 0.3, -17.0, 0.45, 0.35)
	LandmarkEahParts.slab(lm, "Stone", Vector3(-7.0, 0.0, -13.0), Vector3(1.0, 4.2, -6.8))
	LandmarkEahParts.slab(lm, "Black", Vector3(-6.5, 4.2, -12.6), Vector3(0.5, 6.4, -7.2))
	LandmarkEahParts.slab(lm, "Plaster", Vector3(-6.6, 6.0, -12.7), Vector3(0.6, 6.4, -7.1))
	for s in [-1.0, 1.0]:
		for k in 2:
			LandmarkEahDetail.castle_window(lm, "Black", "Shadow", Vector3(-3.0 + s * 3.52, 5.2, -11.2 + 2.4 * k),
				Vector3(s, 0, 0), 1.0, 0.9, 4)
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(-3.0, 6.4, -9.9), Vector2(10.0, 8.0), Vector2(5.0, 1.2), 1.7, 0.4)
	# Tatsumi turret and the open Tsukimi (moon-viewing) turret to the east.
	LandmarkEahParts.stone_base(lm, "Stone", Vector2(11.4, 3.0), Vector2(9.4, 7.8), 0.0, 3.4, Vector2(2.6, 2.4))
	lm.box("Black", Vector3(11.4, 5.0, 3.0), Vector3(8.2, 3.2, 6.6))
	lm.box("Plaster", Vector3(11.4, 6.45, 3.0), Vector3(8.3, 0.4, 6.7))
	for n in [Vector3(0, 0, 1), Vector3(1, 0, 0)]:
		var nv: Vector3 = n
		var off := 3.31 if nv.z > 0.5 else 4.11
		for k in [-1.0, 1.0]:
			var p := Vector3(11.4, 5.0, 3.0) + nv * off + Vector3(absf(nv.z), 0, absf(nv.x)) * float(k) * 1.8
			LandmarkEahDetail.castle_window(lm, "Black", "Shadow", p, nv, 1.2, 1.0, 4)
	var tc := Vector3(11.4, 6.6, 3.0)
	LandmarkAeParts.hip_roof(lm, "Tile", tc, Vector2(11.6, 9.6), Vector2(3.0, 1.6), 2.4, 0.5)
	LandmarkAeParts.hip_ridges(lm, "Tile", tc, Vector2(11.6, 9.6), Vector2(3.0, 1.6), 2.4, 0.5, 0.3)
	LandmarkEahDetail.chidori(lm, "Tile", "Plaster", "Black", tc + Vector3(0, 0.2, 4.8), Vector3(0, 0, 1), 3.4, 1.4, 2.2)
	_tsukimi(lm, Vector3(19.6, 3.0, 3.0))
	_red_bridge(lm, Vector3(-40.0, 0.0, 6.0))
	lm.commit(model)

## A black-and-white keep centred at c on its stone base: stacked storeys
## (wall heights, plans) under hipped roofs, black boarded walls with a
## white plaster band at each wall head, barred windows, stone-drop bays
## on the first floor, and per roof [long-face, short-face] gables (0
## none, 1 chidori, 2 kara-hafu bay window). Returns the ridge height.
static func _keep(lm: LandmarkMesh, c: Vector2, base: Vector2, base_h: float, plans: Array,
		walls: Array, rises: Array, top_rise: float, gables: Array) -> float:
	LandmarkEahParts.stone_base(lm, "Stone", c, base, 0.0, base_h, Vector2(5.0, 4.0))
	var y := base_h
	for i in plans.size():
		var w: Vector2 = plans[i]
		var h: float = walls[i]
		var cc := Vector3(c.x, y, c.y)
		lm.box("Black", cc + Vector3(0, h * 0.5, 0), Vector3(w.x, h, w.y))
		lm.box("Plaster", cc + Vector3(0, h - 0.35, 0), Vector3(w.x + 0.1, 0.7, w.y + 0.1))
		# Clapboard (shitami-ita) battens every metre and a sill band.
		LandmarkEahDetail.ring_beams(lm, "Black", cc, w + Vector2(0.12, 0.12), y + 0.15, 0.3, 0.12)
		for n in FACES:
			var nv: Vector3 = n
			var run := w.x if absf(nv.z) > 0.5 else w.y
			var off := w.y * 0.5 if absf(nv.z) > 0.5 else w.x * 0.5
			var along := Vector3(absf(nv.z), 0, absf(nv.x))
			var basis := Basis(along, Vector3.UP, nv)
			for k in int(run) - 1:
				var p := cc + nv * (off + 0.05) + along * (float(k + 1) - run * 0.5) + Vector3(0, (h - 0.7) * 0.5, 0)
				lm.box("Black", p, Vector3(0.08, h - 0.75, 0.06), basis, 0.0)
			var cnt := maxi(int(run / 3.6), 1)
			for k in cnt:
				var t := (float(k) + 0.5) / float(cnt) - 0.5
				var p := cc + nv * (off + 0.06) + along * t * run * 0.8 + Vector3(0, h * 0.5, 0)
				LandmarkEahDetail.castle_window(lm, "Black", "Shadow", p, nv, 1.1, minf(h * 0.32, 1.1), 4)
			if i == 0:
				for s in [-1.0, 1.0]:
					LandmarkEahDetail.ishi_otoshi(lm, "Black", cc + nv * off + along * s * (run * 0.5 - 1.2)
						+ Vector3(0, 1.0, 0), nv, 1.8, 2.0, 0.5)
		y += h
		var eave := w + Vector2(3.6, 3.2)
		var rc := Vector3(c.x, y, c.y)
		if i == plans.size() - 1:
			var rtop := Vector2(w.x * 0.35, 1.0)
			LandmarkAeParts.hip_roof(lm, "Tile", rc, eave, rtop, top_rise, 0.5)
			LandmarkAeParts.eave_fascia(lm, "Plaster", rc, eave, 0.5, 0.3, w, 0.7)
			LandmarkAeParts.hip_ridges(lm, "Tile", rc, eave, rtop, top_rise, 0.5, 0.3)
			y += top_rise
		else:
			var nxt: Vector2 = plans[i + 1]
			var rtop := nxt + Vector2(0.6, 0.6)
			LandmarkAeParts.hip_roof(lm, "Tile", rc, eave, rtop, rises[i], 0.4)
			LandmarkAeParts.eave_fascia(lm, "Plaster", rc, eave, 0.4, 0.3, w, 0.7)
			LandmarkAeParts.hip_ridges(lm, "Tile", rc, eave, rtop, rises[i], 0.4, 0.28)
			var g: Array = gables[i]
			for n in FACES:
				var nv: Vector3 = n
				var kind: int = g[0] if absf(nv.z) > 0.5 else g[1]
				var off := (w.y if absf(nv.z) > 0.5 else w.x) * 0.5 + 0.9
				var base_p := rc + nv * off + Vector3(0, 0.2, 0)
				if kind == 1:
					LandmarkEahDetail.chidori(lm, "Tile", "Plaster", "Black", base_p, nv, 4.6, 1.8, 2.6)
				elif kind == 2:
					# Kara-hafu over a projecting bay window.
					lm.box("Black", base_p - nv * 0.6 - Vector3(0, 1.0, 0), Vector3(3.2 * absf(nv.z) + 1.4 * absf(nv.x),
						1.6, 3.2 * absf(nv.x) + 1.4 * absf(nv.z)))
					LandmarkEahDetail.karahafu(lm, "Tile", "Plaster", "Black", base_p, nv, 3.6, 1.0, 2.0)
			y += rises[i]
	return y

## The open moon-viewing turret (1635) on its low stone base: red
## railings round three open sides, black posts, plastered back.
static func _tsukimi(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkEahParts.stone_base(lm, "Stone", Vector2(c.x, c.z), Vector2(8.6, 7.2), 0.0, c.y, Vector2(2.4, 2.2))
	LandmarkEahParts.slab(lm, "Wood", Vector3(c.x - 4.2, c.y, c.z - 3.5), Vector3(c.x + 4.2, c.y + 0.25, c.z + 3.5))
	LandmarkEahParts.colonnade(lm, "Black", Vector2(c.x, c.z), Vector2(7.6, 6.2), c.y, 2.8, 4, 3, 0.14, 6)
	lm.box("Plaster", Vector3(c.x - 3.2, c.y + 1.4, c.z), Vector3(0.3, 2.8, 5.8))
	LandmarkEahDetail.ring_beams(lm, "Black", Vector3(c.x, 0, c.z), Vector2(7.6, 6.2), c.y + 2.6, 0.35, 0.2)
	# Red railings (with a lower rail) round the open sides.
	for s in [-1.0, 1.0]:
		LandmarkEahDetail.railing(lm, "Red", Vector3(c.x - 3.8, c.y + 0.25, c.z + s * 3.25),
			Vector3(c.x + 4.05, c.y + 0.25, c.z + s * 3.25), 0.95, 0.95, 0.12)
	LandmarkEahDetail.railing(lm, "Red", Vector3(c.x + 4.05, c.y + 0.25, c.z - 3.25),
		Vector3(c.x + 4.05, c.y + 0.25, c.z + 3.25), 0.95, 0.95, 0.12)
	var rc := Vector3(c.x, c.y + 2.8, c.z)
	LandmarkAeParts.hip_roof(lm, "Tile", rc, Vector2(10.6, 9.0), Vector2(3.0, 1.6), 2.3, 0.5)
	LandmarkAeParts.eave_fascia(lm, "Wood", rc, Vector2(10.6, 9.0), 0.5, 0.25, Vector2(7.6, 6.2), 0.6)
	LandmarkAeParts.hip_ridges(lm, "Tile", rc, Vector2(10.6, 9.0), Vector2(3.0, 1.6), 2.3, 0.5, 0.26)

## The vermilion Uzumi bridge over the inner moat, deck along X centred
## at c, humped, on timber trestles.
static func _red_bridge(lm: LandmarkMesh, c: Vector3) -> void:
	var prev := Vector3.ZERO
	for k in 9:
		var t := float(k) / 8.0 * 2.0 - 1.0
		var p := c + Vector3(t * 7.0, 1.2 + 0.5 * (1.0 - t * t), 0)
		if k > 0:
			lm.beam("Red", prev, p, 3.6, 0.35, Vector3.BACK)
			for s in [-1.0, 1.0]:
				lm.beam("Red", prev + Vector3(0, 1.0, s * 1.75), p + Vector3(0, 1.0, s * 1.75), 0.18, 0.18, Vector3.BACK)
				lm.beam("Red", prev + Vector3(0, 0.55, s * 1.75), p + Vector3(0, 0.55, s * 1.75), 0.12, 0.12, Vector3.BACK)
		for s in [-1.0, 1.0]:
			lm.box("Red", p + Vector3(0, 0.5, s * 1.75), Vector3(0.2, 1.0, 0.2), Basis(), 0.0)
			if k % 2 == 0:
				lm.box("Wood", Vector3(p.x, (p.y - 0.2) * 0.5, c.z + s * 1.4), Vector3(0.45, p.y - 0.2, 0.45), Basis(), 0.0)
		if k % 2 == 0:
			lm.box("Wood", Vector3(p.x, p.y - 0.4, c.z), Vector3(0.4, 0.3, 3.4), Basis(), 0.0)
		prev = p
	for e in [-1.0, 1.0]:
		lm.box("Stone", Vector3(c.x + e * 8.2, 0.7, c.z), Vector3(2.4, 1.4, 5.0))
		for s in [-1.0, 1.0]:
			lm.box("Red", Vector3(c.x + e * 7.0, 2.2, c.z + s * 1.75), Vector3(0.3, 2.0, 0.3), Basis(), 0.0)
