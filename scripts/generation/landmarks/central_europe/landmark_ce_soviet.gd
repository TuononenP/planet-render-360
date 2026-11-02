class_name LandmarkCeSoviet
extends RefCounted

## Soviet-era landmarks in true metres: the Moscow State University main
## building (1953: the 36-storey stepped tower with clock faces and a
## 58 m spire carrying a star in a wheat wreath, 240 m, its wings
## stepping down to spired corner towers), the Ostankino Tower (1967:
## ten concrete legs flaring to a 60 m base, the tapering shaft with
## its balcony rings and the Seventh Heaven pod at 330 m, the steel
## mast to 540.1 m) and The Motherland Calls on Mamayev Kurgan (1967:
## a 52 m concrete figure striding forward, cloak streaming, raising a
## 33 m sword, 85 m in all).

# --- Moscow State University ---

const MSU_TOP := 240.0
## Central tower tiers: half-width and the heights they span.
const MSU_TIERS := [[31.0, 0.0, 96.0], [24.0, 96.0, 128.0], [18.0, 128.0, 158.0], [12.5, 158.0, 183.0]]

static func msu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#CDBEA2", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#9B8E78", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E907F", 2.0, 0.55, 0.3))
	lm.use("Steel", LandmarkMaterials.paint("#8E9A94", 0.4, 0.6))
	lm.use("Gilt", LandmarkMaterials.gold())
	for ti in MSU_TIERS.size():
		var t: Array = MSU_TIERS[ti]
		var hw: float = t[0]
		var y0: float = t[1]
		var y1: float = t[2]
		lm.box("Wall", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0 - 0.8, y1 - y0, hw * 2.0 - 0.8))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			var n := r * Vector3(0, 0, 1)
			var rt := r * Vector3(1, 0, 0)
			var o := n * (hw - 0.4) - rt * hw + Vector3(0, y0, 0)
			var cols := int(hw * 2.0 / 4.0)
			_msu_face(lm, o, rt, n, hw * 2.0, y1 - y0 - 1.0, cols)
			# Vertical lesenes of darker stone at the corners and centre.
			for e in [-1.0, 0.0, 1.0]:
				var w := 3.0 if e == 0.0 else 2.2
				lm.box("Dark", n * (hw + 0.05) + rt * e * (hw - 1.1) + Vector3(0, (y0 + y1) * 0.5, 0),
					Vector3(w, y1 - y0, 0.5), r)
			LandmarkDetail.cornice(lm, "Dark", n * (hw - 0.4) - rt * hw + Vector3(0, y1 - 1.0, 0),
				n * (hw - 0.4) + rt * hw + Vector3(0, y1 - 1.0, 0), n, 1.4, false)
		lm.box("Dark", Vector3(0, y1 + 0.5, 0), Vector3(hw * 2.0 + 1.2, 1.0, hw * 2.0 + 1.2))
		# Corner obelisk pinnacles with vases on every setback.
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var q := Vector3(sx * (hw - 2.0), y1 + 1.0, sz * (hw - 2.0))
				lm.box("Wall", q + Vector3(0, 2.0, 0), Vector3(3.2, 4.0, 3.2))
				lm.frustum("Wall", q + Vector3(0, 4.0, 0), 1.6, 1.2, 6.0, 8, PI / 8.0)
				lm.lathe("Copper", q + Vector3(0, 10.0, 0), PackedVector2Array([Vector2(1.3, 0), Vector2(1.6, 1.0),
					Vector2(0.9, 2.4), Vector2(0.0, 6.0)]), 8)
	# Clock faces (9 m) on the third tier, sculpture groups at the first setback.
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		var cc := n * 18.2 + Vector3(0, 146.0, 0)
		lm.disc("Gilt", cc + n * 0.08, n, 4.6, 32)
		lm.disc("Windows", cc + n * 0.12, n, 4.0, 32)
		for k in 12:
			var a := TAU * float(k) / 12.0
			lm.box("Gilt", cc + n * 0.18 + (r * Vector3(cos(a), 0, 0) + Vector3(0, sin(a), 0)) * 3.5, Vector3(0.5, 0.5, 0.1), r, 0.0)
		lm.beam("Gilt", cc + n * 0.24, cc + n * 0.24 + Vector3(0, 3.0, 0), 0.3, 0.08, n)
		lm.beam("Gilt", cc + n * 0.26, cc + n * 0.26 + r * Vector3(2.2, 0, 0), 0.4, 0.08, n)
		for k in [-1.0, 1.0]:
			LandmarkKits.statue_figure(lm, "Wall", n * 26.0 + r * Vector3(k * 7.0, 97.0, 0), 6.0, k > 0.0)
			lm.box("Wall", n * 26.0 + r * Vector3(k * 7.0, 96.5, 0), Vector3(3.0, 1.0, 3.0), r)
	# Spire: ribbed steel needle on an octagonal base, the star in its wreath.
	lm.lathe("Wall", Vector3(0, 184.0, 0), PackedVector2Array([Vector2(9.0, 0), Vector2(8.4, 4.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	var sp := PackedVector2Array([Vector2(8.0, 0), Vector2(6.6, 8.0), Vector2(4.0, 22.0), Vector2(2.0, 34.0), Vector2(0.9, 38.0)])
	lm.lathe("Steel", Vector3(0, 188.0, 0), sp, 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in sp.size() - 1:
			lm.beam("Gilt", Vector3(0, 188.0 + sp[j].y, 0) + d * (sp[j].x * cos(PI / 8.0) + 0.1),
				Vector3(0, 188.0 + sp[j + 1].y, 0) + d * (sp[j + 1].x * cos(PI / 8.0) + 0.1), 0.35, 0.2)
	for j in 6:
		var y := 4.0 + 5.5 * j
		var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 8.0), Vector2(8, 6.6), Vector2(22, 4.0),
			Vector2(34, 2.0), Vector2(38, 0.9)]), y)
		lm.frustum("Gilt", Vector3(0, 188.0 + y, 0), rr + 0.15, rr + 0.1, 0.4, 8, PI / 8.0)
	lm.frustum("Gilt", Vector3(0, 226.0, 0), 0.8, 0.5, 5.0, 8)
	var sc := Vector3(0, 235.0, 0)
	for k in 5:
		var a := TAU * k / 5.0
		var d := Vector3(sin(a), cos(a), 0)
		var side := Vector3(cos(a), -sin(a), 0)
		for s in [-1.0, 1.0]:
			lm.tri("Gilt", sc + Vector3(0, 0, s * 0.8), sc + d * 4.6, sc + side * 1.8 + d * 1.4,
				Vector3(0, 0, s), Vector3(0, 0, s), Vector3(0, 0, s), Vector2.ZERO, Vector2(0, 4.6), Vector2(1.8, 1.4))
			lm.tri("Gilt", sc + Vector3(0, 0, s * 0.8), sc + d * 4.6, sc - side * 1.8 + d * 1.4,
				Vector3(0, 0, s), Vector3(0, 0, s), Vector3(0, 0, s), Vector2.ZERO, Vector2(0, 4.6), Vector2(-1.8, 1.4))
	for k in 16:
		var a0 := PI * 0.15 + PI * 1.7 * float(k) / 16.0
		var a1 := PI * 0.15 + PI * 1.7 * float(k + 1) / 16.0
		lm.beam("Gilt", sc + Vector3(sin(a0), -cos(a0), 0) * 5.0, sc + Vector3(sin(a1), -cos(a1), 0) * 5.0, 0.6, 0.4)
	# Four wings along the axes, each three blocks stepping down; spired
	# towers on the 18-storey blocks and the end blocks.
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * k)
		var x := 31.0
		for bi in 3:
			var blk: Array = [[50.0, 44.0, 78.0], [40.0, 38.0, 56.0], [34.0, 46.0, 42.0]][bi]
			var bl: float = blk[0]
			var wid: float = blk[1]
			var h: float = blk[2]
			var c := Vector3(x + bl * 0.5, h * 0.5, 0)
			lm.box("Wall", r * c, Vector3(bl, h, wid), r)
			lm.box("Dark", r * (c + Vector3(0, h * 0.5 + 0.5, 0)), Vector3(bl + 1.0, 1.0, wid + 1.0), r)
			for side in [-1.0, 1.0]:
				var n := r * Vector3(0, 0, side)
				var rt := r * Vector3(side, 0, 0)
				var o := r * Vector3(x + (0.0 if side > 0.0 else bl), 0, side * wid * 0.5)
				_msu_face(lm, o, rt, n, bl, h - 1.0, int(bl / 4.0))
				LandmarkDetail.cornice(lm, "Dark", o + Vector3(0, h - 1.0, 0), o + rt * bl + Vector3(0, h - 1.0, 0), n, 1.2, false)
			if bi == 2:
				var ne := r * Vector3(1, 0, 0)
				_msu_face(lm, r * Vector3(x + bl, 0, -wid * 0.5), r * Vector3(0, 0, 1), ne, wid, h - 1.0, int(wid / 4.0))
			if bi == 0 or bi == 2:
				for sz in ([0.0] if bi == 0 else [-1.0, 1.0]):
					var q := r * Vector3(c.x + (0.0 if bi == 0 else bl * 0.5 - 4.0), h + 1.0, float(sz) * (wid * 0.5 - 4.0))
					var tw := 7.0 if bi == 0 else 5.0
					lm.box("Wall", q + Vector3(0, tw * 1.2, 0), Vector3(tw, tw * 2.4, tw), r)
					lm.box("Dark", q + Vector3(0, tw * 2.4 + 0.4, 0), Vector3(tw + 0.8, 0.8, tw + 0.8), r)
					lm.frustum("Wall", q + Vector3(0, tw * 2.4 + 0.8, 0), tw * 0.4, tw * 0.35, tw * 0.8, 8, PI / 8.0)
					lm.lathe("Copper", q + Vector3(0, tw * 3.2 + 0.8, 0), PackedVector2Array([Vector2(tw * 0.38, 0),
						Vector2(tw * 0.22, tw * 1.2), Vector2(0.15, tw * 2.6)]), 8, 1.0, 1.0, PI / 8.0, false)
					lm.box("Gilt", q + Vector3(0, tw * 5.8 + 1.4, 0), Vector3(0.3, 1.6, 1.6), r, 0.0)
			x += bl
	lm.commit(model)

## A facade of the MSU building: a pierced skin with one window per
## 4 m bay on 3.6 m storeys, over a rusticated two-storey base.
static func _msu_face(lm: LandmarkMesh, o: Vector3, rt: Vector3, n: Vector3, w: float, h: float, cols: int) -> void:
	var rows := int((h - 8.0) / 3.6)
	LandmarkDetail.pierced_face(lm, "Wall", "Windows", o, rt, n, w, h, maxi(cols, 2), rows,
		Vector2(1.6, 2.2), 7.6, 3.6, 0.35)
	lm.box("Dark", o + rt * w * 0.5 + n * 0.45 + Vector3(0, 3.5, 0), Vector3(w, 7.0, 0.5), Basis(rt, Vector3.UP, n))
	for i in maxi(cols, 2):
		var p := o + rt * (w * (float(i) + 0.5) / float(maxi(cols, 2))) + n * 0.72 + Vector3(0, 2.8, 0)
		lm.box("Windows", p, Vector3(2.0, 3.4, 0.05), Basis(rt, Vector3.UP, n), 0.0)

# --- Ostankino Tower ---

const OST_TOP := 540.1

static func ostankino(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B5AC", 8.0))
	lm.use("Glass", LandmarkMaterials.glass("#34454E"))
	lm.use("Red", LandmarkMaterials.paint("#C23B2E", 0.5, 0.2))
	lm.use("White", LandmarkMaterials.paint("#ECECE8", 0.5, 0.2))
	lm.use("Podium", LandmarkMaterials.pbr("pavement", "#9C978D", 4.0))
	lm.frustum("Podium", Vector3(0, 0, 0), 46.0, 44.0, 1.0, 40)
	# Ten legs splaying to the 60 m base, tall pointed openings between
	# them, round a core cone; they merge into the shaft at 63 m.
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(19.0, 0), Vector2(16.0, 20.0),
		Vector2(12.4, 45.0), Vector2(9.8, 63.0)]), 30)
	for k in 10:
		var a := TAU * float(k) / 10.0
		var d := Vector3(cos(a), 0, sin(a))
		var side := d.cross(Vector3.UP)
		var pts := [[29.4, 3.5, 7.0, 4.0], [26.0, 14.0, 5.6, 3.4], [20.0, 32.0, 4.4, 3.0], [14.0, 50.0, 3.6, 2.6],
			[10.4, 63.0, 3.0, 2.4]]
		for j in pts.size() - 1:
			var p0 := d * float(pts[j][0]) + Vector3(0, float(pts[j][1]), 0)
			var p1 := d * float(pts[j + 1][0]) + Vector3(0, float(pts[j + 1][1]), 0)
			lm.beam("Concrete", p0, p1, float(pts[j][2]), float(pts[j][3]), side)
		lm.box("Concrete", d * 29.6 + Vector3(0, 2.25, 0), Vector3(8.0, 4.5, 5.0), Basis(Vector3.UP, -a + PI * 0.5))
		# Glazed opening into the base between this leg and the next.
		var ga := a + TAU / 20.0
		var gd := Vector3(cos(ga), 0, sin(ga))
		lm.quad("Glass", gd * 18.95 + gd.cross(Vector3.UP) * 3.0, gd * 18.95 - gd.cross(Vector3.UP) * 3.0,
			gd * 16.5 - gd.cross(Vector3.UP) * 1.5 + Vector3(0, 18.0, 0), gd * 16.5 + gd.cross(Vector3.UP) * 1.5 + Vector3(0, 18.0, 0), gd)
	# Shaft to 385 m with balcony rings and the vertical service slots.
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(9.8, 63.0), Vector2(8.6, 110.0),
		Vector2(7.6, 200.0), Vector2(7.0, 300.0), Vector2(7.4, 318.0)]), 30)
	for y in [147.0, 269.0, 272.0, 295.0]:
		var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(63, 9.8), Vector2(110, 8.6), Vector2(200, 7.6),
			Vector2(300, 7.0)]), y)
		lm.lathe("Concrete", Vector3(0, y, 0), PackedVector2Array([Vector2(rr, 0), Vector2(rr + 4.5, 1.0),
			Vector2(rr + 4.5, 2.6), Vector2(rr, 3.2)]), 30)
		lm.lathe("Glass", Vector3(0, y + 1.0, 0), PackedVector2Array([Vector2(rr + 4.55, 0), Vector2(rr + 4.55, 1.5)]), 30, 1.0, 1.0, 0.0, true, false)
	for k in 3:
		var a := TAU * float(k) / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 40:
			var y := 70.0 + 6.0 * j
			var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(63, 9.8), Vector2(110, 8.6), Vector2(200, 7.6),
				Vector2(300, 7.0)]), y)
			lm.box("Glass", d * (rr + 0.02) + Vector3(0, y, 0), Vector3(0.8, 2.6, 0.8), Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	# Seventh Heaven pod: stacked restaurant floors and observation decks.
	lm.lathe("Concrete", Vector3(0, 318.0, 0), PackedVector2Array([Vector2(7.4, 0), Vector2(14.0, 8.0),
		Vector2(19.5, 15.0), Vector2(20.5, 22.0), Vector2(19.0, 36.0), Vector2(11.0, 42.0),
		Vector2(5.4, 46.0)]), 40)
	for g in [[17.5, 3.0], [22.0, 3.0], [26.5, 3.2], [31.0, 3.0]]:
		var gy: float = g[0]
		var gh: float = g[1]
		var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(15, 19.5), Vector2(22, 20.5), Vector2(36, 19.0)]), gy)
		lm.lathe("Glass", Vector3(0, 318.0 + gy, 0), PackedVector2Array([Vector2(rr + 0.25, 0), Vector2(rr + 0.25, gh)]), 48, 1.0, 1.0, 0.0, true, false)
		for k in 48:
			var a := TAU * float(k) / 48.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Concrete", d * (rr + 0.35) + Vector3(0, 318.0 + gy, 0), d * (rr + 0.35) + Vector3(0, 318.0 + gy + gh, 0), 0.25, 0.25)
		lm.frustum("Concrete", Vector3(0, 318.0 + gy + gh, 0), rr + 0.9, rr + 0.9, 0.4, 48)
	lm.lathe("Concrete", Vector3(0, 364.0, 0), PackedVector2Array([Vector2(5.4, 0), Vector2(4.2, 12.0),
		Vector2(3.2, 21.0)]), 20)
	# Steel mast: red-white bands, work platforms, tapering to the tip.
	var y0 := 385.0
	var bands := 14
	for k in bands:
		var h := (OST_TOP - y0) / bands
		var r0 := lerpf(3.0, 0.25, float(k) / bands)
		var r1 := lerpf(3.0, 0.25, float(k + 1) / bands)
		lm.frustum("Red" if k % 2 == 0 else "White", Vector3(0, y0 + h * k, 0), r0, r1, h, 12)
	for py in [400.0, 430.0, 460.0, 490.0, 515.0]:
		var rr := lerpf(3.0, 0.25, (py - y0) / (OST_TOP - y0))
		lm.frustum("White", Vector3(0, py, 0), rr + 1.4, rr + 1.4, 0.3, 16)
		for k in 12:
			var a := TAU * float(k) / 12.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Red", d * (rr + 1.35) + Vector3(0, py + 0.3, 0), d * (rr + 1.35) + Vector3(0, py + 1.3, 0), 0.06, 0.06)
			lm.beam("Red", d * rr + Vector3(0, py - 1.4, 0), d * (rr + 1.3) + Vector3(0, py, 0), 0.1, 0.1)
		lm.frustum("Red", Vector3(0, py + 1.25, 0), rr + 1.38, rr + 1.38, 0.08, 16)
	lm.commit(model)

# --- The Motherland Calls ---

const MOTHER_TOP := 85.0
const FEET := 2.0

static func motherland(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B3B0A8", 5.0))
	lm.use("Steel", LandmarkMaterials.paint("#A9AEB0", 0.35, 0.8))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#8C8578", 4.0))
	lm.box("Base", Vector3(0, FEET * 0.5, 0), Vector3(26.0, FEET, 16.0))
	lm.box("Base", Vector3(0, FEET * 0.25, 0), Vector3(28.0, FEET * 0.5, 18.0))
	var f := Vector3(0, FEET, 0)
	# Legs: the right (east) leg striding forward, the left braced back.
	for leg in [[Vector3(5.0, 0, 1.6), Vector3(3.0, 10.0, 1.4)], [Vector3(-5.5, 0, -1.6), Vector3(-2.6, 10.0, -1.4)]]:
		var foot: Vector3 = f + (leg[0] as Vector3)
		var knee: Vector3 = f + (leg[1] as Vector3)
		lm.box("Concrete", foot + Vector3(0.8, 0.6, 0), Vector3(4.6, 1.2, 2.0))
		lm.beam("Concrete", foot + Vector3(0, 0.8, 0), knee, 2.0, 2.2)
		lm.beam("Concrete", knee, f + Vector3(0.2, 19.0, (leg[1] as Vector3).z), 3.0, 3.0)
	# Dress: a flared skirt clinging to the stride, its hem streaming back.
	lm.lathe("Concrete", f + Vector3(0, 6.0, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(5.0, 3.0),
		Vector2(4.4, 9.0), Vector2(3.8, 16.0), Vector2(3.4, 24.0), Vector2(3.2, 28.0)]), 18, 1.2, 0.85)
	for i in 9:
		var a := PI * 0.55 + PI * 0.9 * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a) * 0.8)
		lm.beam("Concrete", f + d * 3.6 + Vector3(0, 26.0, 0), f + d * 5.4 + Vector3(-3.0 - 0.6 * i, 5.5 + 0.5 * (i % 3), 0),
			1.4, 0.8, d.cross(Vector3.UP))
	# Torso, shoulders, neck and head turned back, calling.
	lm.lathe("Concrete", f + Vector3(0.6, 34.0, 0), PackedVector2Array([Vector2(3.2, 0), Vector2(3.6, 3.0),
		Vector2(3.8, 5.5), Vector2(3.4, 8.0), Vector2(1.5, 9.8)]), 16, 0.9, 1.15)
	lm.lathe("Concrete", f + Vector3(0.9, 43.4, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(1.0, 1.4),
		Vector2(1.7, 2.4), Vector2(2.1, 4.2), Vector2(2.0, 5.6), Vector2(1.4, 6.8), Vector2(0.0, 7.4)]), 14)
	# Hair blown back, the cloak streaming from the shoulders.
	for k in 5:
		var z := -1.6 + 0.8 * k
		lm.beam("Concrete", f + Vector3(0.0, 48.6, z * 0.8), f + Vector3(-4.0 - absf(z), 47.0 - 0.4 * k, z * 1.4), 1.0, 0.7)
	var prev_a := f + Vector3(-0.4, 42.0, -3.0)
	var prev_b := f + Vector3(-0.4, 42.0, 3.0)
	for j in 6:
		var t := float(j + 1) / 6.0
		var wave := sin(t * PI * 2.0) * 1.6
		var a := f + Vector3(-0.4 - 13.0 * t, 42.0 - 10.0 * t + wave, -3.0 - 3.0 * t)
		var b := f + Vector3(-0.4 - 13.0 * t, 42.0 - 6.0 * t - wave, 3.0 + 2.0 * t)
		lm.quad("Concrete", prev_a, prev_b, b, a, Vector3.UP)
		lm.quad("Concrete", prev_b + Vector3(0, -0.6, 0), prev_a + Vector3(0, -0.6, 0), a + Vector3(0, -0.6, 0),
			b + Vector3(0, -0.6, 0), Vector3.DOWN)
		prev_a = a
		prev_b = b
	# Left arm flung forward calling, hand open; right arm raising the sword.
	var ls := f + Vector3(1.0, 42.4, 3.4)
	lm.beam("Concrete", ls, f + Vector3(7.0, 40.0, 5.6), 2.4, 2.2)
	lm.beam("Concrete", f + Vector3(7.0, 40.0, 5.6), f + Vector3(13.0, 37.0, 7.0), 2.0, 1.8)
	lm.box("Concrete", f + Vector3(14.4, 36.4, 7.3), Vector3(2.4, 0.6, 1.8), Basis(Vector3.BACK, -0.4), 0.0)
	for k in 4:
		lm.beam("Concrete", f + Vector3(15.0, 36.2, 6.7 + 0.4 * k), f + Vector3(16.6, 35.6, 6.6 + 0.5 * k), 0.4, 0.3)
	var rs := f + Vector3(1.0, 43.0, -3.2)
	var el := f + Vector3(2.8, 47.6, -3.6)
	lm.beam("Concrete", rs, el, 2.4, 2.2)
	lm.beam("Concrete", el, f + Vector3(4.8, 51.0, -3.6), 2.0, 2.0)
	lm.lathe("Concrete", f + Vector3(5.0, 50.6, -3.6), PackedVector2Array([Vector2(0.9, 0), Vector2(1.3, 0.8),
		Vector2(1.2, 1.8), Vector2(0.6, 2.4)]), 10)
	# Sword: pommel, grip, crossguard and the 33 m stainless blade with
	# its fuller, tapering to the tip at MOTHER_TOP.
	var hand := f + Vector3(5.0, 51.0, -3.6)
	lm.lathe("Steel", hand + Vector3(-0.1, -2.6, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.6, 0.3),
		Vector2(0.5, 0.7), Vector2(0.25, 0.9)]), 10)
	lm.beam("Steel", hand + Vector3(-0.1, -1.8, 0), hand + Vector3(0.3, 1.4, 0), 0.7, 0.7)
	lm.beam("Steel", hand + Vector3(0.3, 1.4, -2.4), hand + Vector3(0.3, 1.4, 2.4), 0.8, 0.8)
	for s in [-1.0, 1.0]:
		lm.lathe("Steel", hand + Vector3(0.3, 1.0, s * 2.4), PackedVector2Array([Vector2(0.3, 0), Vector2(0.55, 0.4),
			Vector2(0.3, 0.8)]), 8)
	var tip := Vector3(hand.x + 6.0, MOTHER_TOP, hand.z)
	var root := hand + Vector3(0.3, 1.8, 0)
	var axis := (tip - root).normalized()
	var flat := axis.cross(Vector3(0, 0, 1)).normalized()
	var steps := 8
	for j in steps:
		var t0 := float(j) / steps
		var t1 := float(j + 1) / steps
		var w0 := lerpf(2.6, 0.5, pow(t0, 1.3))
		var w1 := lerpf(2.6, 0.5, pow(t1, 1.3)) if j < steps - 1 else 0.05
		var p0 := root.lerp(tip, t0)
		var p1 := root.lerp(tip, t1)
		for s in [-1.0, 1.0]:
			# Bevelled edges either side of the central fuller.
			lm.quad("Steel", p0 + Vector3(0, 0, s * 0.3), p1 + Vector3(0, 0, s * 0.25 * (1.0 - t1) + s * 0.03),
				p1 + flat * w1 * 0.5, p0 + flat * w0 * 0.5, Vector3(0, 0, s))
			lm.quad("Steel", p0 + Vector3(0, 0, s * 0.3), p1 + Vector3(0, 0, s * 0.25 * (1.0 - t1) + s * 0.03),
				p1 - flat * w1 * 0.5, p0 - flat * w0 * 0.5, Vector3(0, 0, s))
		lm.beam("Steel", p0 + Vector3(0, 0, 0), p1, 0.25, 0.7 * (1.0 - t0) + 0.05, Vector3(0, 0, 1))
	lm.commit(model)
