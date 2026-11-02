class_name LandmarkWhChambord
extends RefCounted

## The Château de Chambord in true metres, y = 0 at the ground, the
## main (north-west, river) front facing +Z.

const FRONT := 50.0
const KEEP := 44.0
const TOWER_R := 9.75
const WALL_H := 26.0

## Château de Chambord (56 m to the lantern finial; 1519-47): a 156 x
## 117 m enclosure whose river front is the 44 m square keep (donjon)
## with a 19.5 m round tower at each corner, flanked by the two lower
## wings (the royal wing east, the chapel wing west) out to the two great
## corner towers; the side and rear ranges are single-storey, their rear
## corner towers left at wall height. The tuffeau walls are ruled into
## bays by pilasters and string courses with mullion-and-transom
## windows; on the keep's roof terraces stand the steep slate roofs of
## the four apartment blocks and the towers, crowded with dormers,
## chimneys and lanterns, around the great lantern over the double-helix
## staircase.
static func chambord(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9D0B8", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#3F474D", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var kz := FRONT - KEEP * 0.5
	var h := KEEP * 0.5
	# The keep: walls in three storeys, string courses, pilastered bays.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, kz, KEEP, WALL_H, KEEP)
	for y in [0.0, 9.0, 17.5]:
		LandmarkWestKit.blk(lm, "Stone", 0, y + (0.0 if y == 0.0 else -0.35), kz, KEEP + 0.8, 0.7 if y > 0.0 else 1.2,
			KEEP + 0.8)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-h, WALL_H - 0.8, FRONT), Vector3(h, WALL_H - 0.8, FRONT),
		Vector3(0, 0, 1), 0.8, false)
	for f in [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
		var fn: Vector3 = f
		var fc := Vector3(0, 0, kz) + fn * h
		_bays(lm, fc, fn, KEEP - 2.0 * TOWER_R + 2.0, 4, [1.4, 10.4, 18.9], WALL_H)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		_tower(lm, Vector3(q.x * h, 0, kz + q.y * h), TOWER_R, WALL_H, 14.0)
	_keep_roofs(lm, kz)
	_lantern(lm, Vector3(0, WALL_H + 9.0, kz))
	# The front wings out to the two great corner towers, then the
	# single-storey ranges round the court with their stump towers.
	for sx in [-1.0, 1.0]:
		var x0: float = sx * (h + TOWER_R - 1.0)
		var x1: float = sx * 68.0
		var wx := (x0 + x1) * 0.5
		var wl := absf(x1 - x0)
		LandmarkWestKit.blk(lm, "Stone", wx, 0, FRONT - 7.0, wl, 18.0, 14.0)
		LandmarkWestKit.blk(lm, "Stone", wx, 8.6, FRONT - 7.0, wl + 0.4, 0.6, 14.6)
		lm.gable("Slate", Vector3(wx, 18.0, FRONT - 7.0), 14.0, wl, 7.5, Basis(Vector3.UP, PI * 0.5), 0.5, "Stone")
		_bays(lm, Vector3(wx, 0, FRONT), Vector3(0, 0, 1), wl - 2.0, 5, [1.4, 10.4], 18.0)
		_bays(lm, Vector3(wx, 0, FRONT - 14.0), Vector3(0, 0, -1), wl - 2.0, 5, [1.4, 10.4], 18.0)
		for k in 5:
			var dx := lerpf(x0, x1, (float(k) + 0.5) / 5.0)
			for s in [-1.0, 1.0]:
				_dormer(lm, Vector3(dx, 18.0, FRONT - 7.0 + s * 6.6), Vector3(0, 0, s), 2.2, 3.4)
		_tower(lm, Vector3(sx * 68.0, 0, FRONT - 6.0), TOWER_R, 22.0, 13.0)
		# Side range and the rear range, one storey under slate.
		var sxr: float = sx * 72.0
		LandmarkWestKit.blk(lm, "Stone", sxr, 0, FRONT - 66.0, 10.0, 8.0, 100.0)
		lm.gable("Slate", Vector3(sxr, 8.0, FRONT - 66.0), 10.0, 100.0, 4.0, Basis(), 0.4, "Stone")
		_bays(lm, Vector3(sxr - sx * 5.0, 0, FRONT - 66.0), Vector3(-sx, 0, 0), 96.0, 12, [1.6], 8.0)
		lm.frustum("Stone", Vector3(sx * 68.0, 0, FRONT - 117.0), 9.5, 9.5, 8.5, 24)
		lm.frustum("Stone", Vector3(sx * 68.0, 8.0, FRONT - 117.0), 9.9, 9.9, 0.8, 24)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, FRONT - 116.0, 128.0, 8.0, 10.0)
	lm.gable("Slate", Vector3(0, 8.0, FRONT - 116.0), 10.0, 128.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
	LandmarkWestKit.blk(lm, "Stone", 0, 0, FRONT - 111.0, 12.0, 10.0, 2.0)
	LandmarkWhKit.arch_round(lm, "Glass", Vector3(0, 0, FRONT - 109.9), Vector3(0, 0, 1), 4.0, 4.0)
	# Centre the plan: the front towers reach z = 59.75, the rear ones -76.5.
	LandmarkWhKit.shift(lm, Vector3(0, 0, 8.4))
	lm.commit(model)

## Pilastered bays on a wall whose face centre (ground) is `c`, facing
## `n`, `w` wide: a pilaster between every bay up to `top`, and a
## mullion-and-transom window in each bay at every sill height in `ys`.
static func _bays(lm: LandmarkMesh, c: Vector3, n: Vector3, w: float, bays: int, ys: Array, top: float) -> void:
	var r := LandmarkWhKit.along(n)
	var bs := Basis(r, Vector3.UP, n)
	var bw := w / float(bays)
	for i in bays + 1:
		var p := c - r * w * 0.5 + r * bw * float(i)
		lm.box("Stone", p + n * 0.15 + Vector3(0, top * 0.5, 0), Vector3(0.7, top - 1.0, 0.3), bs, 0.0)
	for i in bays:
		var p := c - r * w * 0.5 + r * bw * (float(i) + 0.5)
		for y in ys:
			_croisee(lm, p + Vector3(0, float(y), 0), n, minf(bw * 0.45, 2.4), 4.8)

## A mullion-and-transom (croisée) window, opening w x h with its sill
## at `c` on the face: glass, a moulded frame, the stone cross, a
## lintel with a small cornice.
static func _croisee(lm: LandmarkMesh, c: Vector3, n: Vector3, w: float, h: float) -> void:
	var r := LandmarkWhKit.along(n)
	var g := c + n * 0.03
	lm.quad("Glass", g - r * w * 0.5, g + r * w * 0.5, g + r * w * 0.5 + Vector3(0, h, 0), g - r * w * 0.5 + Vector3(0, h, 0), n)
	var fd := n * 0.12
	var pts: Array[Vector3] = [c - r * (w * 0.5 + 0.12), c + r * (w * 0.5 + 0.12),
		c + r * (w * 0.5 + 0.12) + Vector3(0, h + 0.12, 0), c - r * (w * 0.5 + 0.12) + Vector3(0, h + 0.12, 0),
		c - r * (w * 0.5 + 0.12)]
	LandmarkWhGothic._run(lm, "Stone", pts, n, 0.24, 0.24)
	lm.beam("Stone", c + fd, c + fd + Vector3(0, h, 0), 0.2, 0.18, r)
	lm.beam("Stone", c + fd - r * w * 0.5 + Vector3(0, h * 0.62, 0), c + fd + r * w * 0.5 + Vector3(0, h * 0.62, 0),
		0.18, 0.2, Vector3.UP)
	lm.box("Stone", c + n * 0.25 + Vector3(0, h + 0.35, 0), Vector3(w + 0.8, 0.3, 0.4), Basis(r, Vector3.UP, n), 0.0)

## Round tower at `c`: walls to `wall_h` with string courses, pilasters
## and windows, a cornice, and a tall conical slate roof (`roof_h`)
## carrying dormers, chimney stacks and a lantern with a finial.
static func _tower(lm: LandmarkMesh, c: Vector3, r: float, wall_h: float, roof_h: float) -> void:
	lm.frustum("Stone", c, r, r, wall_h, 28)
	lm.frustum("Stone", c, r + 0.4, r + 0.4, 1.2, 28)
	for y in [9.0, 17.5]:
		if y < wall_h:
			lm.frustum("Stone", c + Vector3(0, y - 0.35, 0), r + 0.3, r + 0.3, 0.7, 28)
	lm.frustum("Stone", c + Vector3(0, wall_h - 1.0, 0), r + 0.6, r + 0.6, 1.0, 28)
	for k in 10:
		var a := TAU * float(k) / 10.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Stone", c + d * (r + 0.12) + Vector3(0, wall_h * 0.5, 0), Vector3(0.7, wall_h - 1.0, 0.3),
			Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
		var wd := Vector3(cos(a + PI / 10.0), 0, sin(a + PI / 10.0))
		for y in [1.4, 10.4, 18.9]:
			if y + 4.8 < wall_h - 1.0:
				_croisee(lm, c + wd * (r - 0.02) + Vector3(0, y, 0), wd, 1.8, 4.6)
	var rb := c + Vector3(0, wall_h, 0)
	lm.lathe("Slate", rb, PackedVector2Array([Vector2(r + 0.5, 0), Vector2(r * 0.85, roof_h * 0.3),
		Vector2(r * 0.55, roof_h * 0.65), Vector2(r * 0.2, roof_h * 0.92), Vector2(0.0, roof_h)]), 24)
	for k in 6:
		var a := TAU * (float(k) + 0.25) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		_dormer(lm, rb + d * (r * 0.78), d, 1.8, 3.2)
	for k in 3:
		var a := TAU * (float(k) + 0.7) / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		_chimney(lm, rb + d * r * 0.55 + Vector3(0, roof_h * 0.2, 0), roof_h * 0.65, d)
	# Lantern turret and finial on the cone.
	var lb := rb + Vector3(0, roof_h * 0.8, 0)
	lm.frustum("Stone", lb, 1.3, 1.2, roof_h * 0.32, 10)
	for k in 6:
		var a := TAU * float(k) / 6.0
		lm.box("Glass", lb + Vector3(cos(a), 0, sin(a)) * 1.22 + Vector3(0, roof_h * 0.16, 0), Vector3(0.5, 1.4, 0.1),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	lm.lathe("Slate", lb + Vector3(0, roof_h * 0.32, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(0.6, 1.6),
		Vector2(0.0, 3.2)]), 10)
	LandmarkWhKit.ball(lm, "Gilt", lb + Vector3(0, roof_h * 0.32 + 3.2, 0), 0.25)

## A Chambord dormer on a roof at `base`, facing `n`: pilastered
## window, entablature and a tall stone gable with a shell niche and
## little candelabra pinnacles.
static func _dormer(lm: LandmarkMesh, base: Vector3, n: Vector3, w: float, h: float) -> void:
	var r := LandmarkWhKit.along(n)
	var bs := Basis(Vector3.UP, atan2(n.x, n.z))
	lm.box("Stone", base + Vector3(0, h * 0.5, 0) - n * 0.6, Vector3(w + 0.6, h, 1.6), bs)
	lm.box("Glass", base + n * 0.22 + Vector3(0, h * 0.45, 0), Vector3(w * 0.6, h * 0.62, 0.1), bs, 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", base + r * float(s) * (w * 0.5) + n * 0.25 + Vector3(0, h * 0.5, 0), Vector3(0.3, h, 0.3), bs, 0.0)
		var cp: Vector3 = base + r * float(s) * (w * 0.5) + n * 0.25 + Vector3(0, h + 0.3, 0)
		lm.frustum("Stone", cp, 0.16, 0.1, 0.7, 6)
		lm.lathe("Stone", cp + Vector3(0, 0.7, 0), LandmarkWestKit.ball(0.14), 6)
	lm.box("Stone", base + n * 0.2 + Vector3(0, h + 0.15, 0), Vector3(w + 0.8, 0.3, 0.6), bs, 0.0)
	lm.gable("Stone", base + Vector3(0, h + 0.3, 0) - n * 0.2, w, 1.2, h * 0.55, bs, 0.0, "Stone")
	LandmarkWhGothic.oculus(lm, "Glass", "Stone", base + n * 0.42 + Vector3(0, h + 0.3 + h * 0.18, 0), n, w * 0.16, false)

## A chimney stack rising `h` from `base`: a pilastered shaft with
## inlaid slate lozenges, a corniced cap and a small lantern top.
static func _chimney(lm: LandmarkMesh, base: Vector3, h: float, out: Vector3) -> void:
	var bs := Basis(Vector3.UP, atan2(out.x, out.z))
	lm.box("Stone", base + Vector3(0, h * 0.5, 0), Vector3(1.6, h, 1.1), bs)
	for s in [-1.0, 1.0]:
		lm.box("Stone", base + bs.x * float(s) * 0.8 + Vector3(0, h * 0.5, 0), Vector3(0.25, h, 1.25), bs, 0.0)
	lm.box("Slate", base + out * 0.56 + Vector3(0, h * 0.6, 0), Vector3(0.7, 0.7, 0.05), bs * Basis(Vector3(0, 0, 1),
		PI * 0.25), 0.0)
	lm.box("Stone", base + Vector3(0, h + 0.2, 0), Vector3(2.0, 0.4, 1.5), bs, 0.0)
	lm.box("Stone", base + Vector3(0, h + 0.8, 0), Vector3(1.0, 0.8, 0.8), bs, 0.0)
	lm.spire("Slate", base + Vector3(0, h + 1.2, 0), 0.6, 1.0)

## Roof terraces of the keep: between the arms of the Greek-cross halls
## stand four apartment blocks under steep hipped slate roofs crowded
## with dormers and chimney stacks; the halls carry flat terraces with
## balustrades; turrets and stacks rise at the corners of the cross.
static func _keep_roofs(lm: LandmarkMesh, kz: float) -> void:
	var h := KEEP * 0.5
	LandmarkWestKit.blk(lm, "Stone", 0, WALL_H, kz, KEEP - 1.0, 1.0, KEEP - 1.0)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var bc := Vector3(q.x * 13.5, WALL_H + 1.0, kz + q.y * 13.5)
		LandmarkWestKit.blk(lm, "Stone", bc.x, bc.y, bc.z, 13.0, 3.0, 13.0)
		LandmarkWestKit.hip(lm, "Slate", bc + Vector3(0, 3.0, 0), 13.6, 13.6, 9.0, 0.15)
		for f in [Vector3(q.x, 0, 0), Vector3(0, 0, q.y), Vector3(-q.x, 0, 0), Vector3(0, 0, -q.y)]:
			var fn: Vector3 = f
			_dormer(lm, bc + fn * 6.0 + Vector3(0, 2.6, 0), fn, 2.0, 3.0)
		_chimney(lm, bc + Vector3(q.x * 3.0, 6.0, -q.y * 3.0), 9.0, Vector3(q.x, 0, 0))
		_chimney(lm, bc + Vector3(-q.x * 3.0, 6.0, q.y * 3.0), 8.0, Vector3(0, 0, q.y))
	# Balustrades round the terraces over the halls.
	for i in 4:
		var a := TAU * float(i) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		var r := LandmarkWhKit.along(d)
		var e := Vector3(0, WALL_H + 1.0, kz) + d * (h - 0.6)
		LandmarkWhGothic.balusters(lm, "Stone", e - r * 6.5, e + r * 6.5, 1.0, 0.5)
	# Turrets at the corners of the cross arms.
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var tp := Vector3(q.x * 7.0, WALL_H + 1.0, kz + q.y * 7.0)
		lm.frustum("Stone", tp, 1.6, 1.5, 9.0, 12)
		for k in 4:
			var a := TAU * (float(k) + 0.5) / 4.0
			lm.box("Glass", tp + Vector3(cos(a), 0, sin(a)) * 1.5 + Vector3(0, 6.0, 0), Vector3(0.5, 1.4, 0.1),
				Basis(Vector3.UP, -a + PI * 0.5), 0.0)
		lm.lathe("Slate", tp + Vector3(0, 9.0, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.0, 2.5),
			Vector2(0.0, 5.5)]), 12)

## The great lantern over the double-helix staircase, from the terrace
## at `lc` to the fleur-de-lis finial at 56 m: an open arcaded stage on
## flying buttresses, a second stage, the ribbed cupola and the lantern
## with its crown.
static func _lantern(lm: LandmarkMesh, lc: Vector3) -> void:
	lm.frustum("Stone", lc - Vector3(0, 8.0, 0), 5.0, 5.0, 8.0, 20)
	lm.frustum("Stone", lc, 4.4, 4.2, 9.0, 20)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		# Buttress piers with flyers onto the core, candelabra pinnacles.
		lm.box("Stone", lc + d * 6.6 + Vector3(0, 4.0, 0), Vector3(0.9, 8.0, 0.9), Basis(Vector3.UP, -a), 0.0)
		LandmarkWhKit.flyer(lm, "Stone", lc + d * 6.6 + Vector3(0, 6.5, 0), lc + d * 4.3 + Vector3(0, 8.0, 0), 0.4, 0.4)
		LandmarkWhGothic.pinnacle(lm, "Stone", lc + d * 6.6 + Vector3(0, 8.0, 0), 0.4, 1.2, 1.8)
		var wd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		LandmarkWhKit.arch_round(lm, "Glass", lc + wd * 4.32 + Vector3(0, 1.5, 0), wd, 1.6, 4.0)
		LandmarkWhGothic.archivolt(lm, "Stone", lc + wd * 4.32 + Vector3(0, 5.5, 0), wd, 1.6, 0.25, 0.2)
	lm.frustum("Stone", lc + Vector3(0, 9.0, 0), 5.0, 4.8, 0.8, 20)
	LandmarkWhGothic.balusters(lm, "Stone", lc + Vector3(-4.6, 9.8, -1.9), lc + Vector3(-4.6, 9.8, 1.9), 0.9, 0.45)
	LandmarkWhGothic.balusters(lm, "Stone", lc + Vector3(4.6, 9.8, -1.9), lc + Vector3(4.6, 9.8, 1.9), 0.9, 0.45)
	# Upper stage and ribbed cupola.
	var ub := lc + Vector3(0, 9.8, 0)
	lm.frustum("Stone", ub, 3.4, 3.2, 3.6, 16)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		lm.box("Glass", ub + Vector3(cos(a), 0, sin(a)) * 3.25 + Vector3(0, 1.8, 0), Vector3(0.9, 2.4, 0.1),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	LandmarkKits.dome_on_drum(lm, "Stone", "Slate", ub + Vector3(0, 3.6, 0), 3.3, 0.6, 2.6, 0.0, 16, 8)
	var tb := ub + Vector3(0, 6.8, 0)
	lm.frustum("Stone", tb, 0.9, 0.8, 1.6, 10)
	lm.lathe("Slate", tb + Vector3(0, 1.6, 0), PackedVector2Array([Vector2(1.1, 0), Vector2(0.4, 0.9),
		Vector2(0.0, 1.6)]), 10)
	# Fleur-de-lis finial at 56 m.
	var fb := tb + Vector3(0, 3.2, 0)
	lm.frustum("Gilt", fb, 0.12, 0.1, 0.9, 6)
	lm.box("Gilt", fb + Vector3(0, 1.0, 0), Vector3(0.18, 0.7, 0.18), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.beam("Gilt", fb + Vector3(0, 0.9, 0), fb + Vector3(s * 0.35, 1.2, 0), 0.1, 0.1)
