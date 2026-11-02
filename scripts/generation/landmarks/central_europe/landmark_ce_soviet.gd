class_name LandmarkCeSoviet
extends RefCounted

## Soviet-era landmarks in true metres: the Moscow State University main
## building (stepped Stalinist tower on a cross of wings, steel spire and
## gilt star, 240 m), the Ostankino Tower (ten-legged concrete base,
## observation pod and red-white mast, 540.1 m) and The Motherland Calls
## on Mamayev Kurgan (concrete figure with the raised sword, 85 m).

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
	for t in MSU_TIERS:
		var hw: float = t[0]
		var y0: float = t[1]
		var y1: float = t[2]
		lm.box("Wall", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0, y1 - y0, hw * 2.0))
		lm.box("Dark", Vector3(0, y1 + 0.5, 0), Vector3(hw * 2.0 + 2.0, 1.0, hw * 2.0 + 2.0))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			var rows := int((y1 - y0 - 10.0) / 12.0)
			for row in rows:
				LandmarkCeParts.windows(lm, "Windows", r * Vector3(0, y0 + 12.0 + 12.0 * row, hw + 0.1),
					Vector3(1, 0, 0), maxi(int(hw / 4.0), 2), 7.0, Vector3(2.4, 6.0, 0.2), r)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var q := Vector3(sx * (hw - 2.0), y1 + 1.0, sz * (hw - 2.0))
				lm.frustum("Wall", q, 1.8, 1.4, 8.0, 8)
				lm.spire("Copper", q + Vector3(0, 8.0, 0), 1.7, 5.0, 0.0, 8)
	lm.lathe("Steel", Vector3(0, 184.0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(6.6, 8.0),
		Vector2(4.0, 22.0), Vector2(2.0, 34.0), Vector2(0.9, 38.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Gilt", Vector3(0, 222.0, 0), 0.8, 0.5, 6.0, 8)
	var sc := Vector3(0, 234.0, 0)
	for k in 5:
		var a := TAU * k / 5.0
		lm.beam("Gilt", sc, sc + Vector3(sin(a), cos(a), 0) * 6.0, 2.0, 0.8)
	# Four stepped wings along the axes, each three blocks stepping down.
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * k)
		var x := 31.0
		for blk in [[50.0, 44.0, 78.0], [40.0, 38.0, 56.0], [34.0, 46.0, 42.0]]:
			var len: float = blk[0]
			var wid: float = blk[1]
			var h: float = blk[2]
			var c := Vector3(x + len * 0.5, h * 0.5, 0)
			lm.box("Wall", r * c, Vector3(len, h, wid), r)
			lm.box("Dark", r * (c + Vector3(0, h * 0.5 + 0.5, 0)), Vector3(len + 1.0, 1.0, wid + 1.0), r)
			for side in [-1.0, 1.0]:
				for row in int(h / 12.0):
					LandmarkCeParts.windows(lm, "Windows", r * Vector3(c.x, 8.0 + 12.0 * row, side * (wid * 0.5 + 0.1)),
						r * Vector3(1, 0, 0), int(len / 8.0), 8.0, Vector3(2.4, 6.0, 0.2), r)
			if blk[2] == 42.0:
				for sx in [-1.0, 1.0]:
					for sz in [-1.0, 1.0]:
						var q := r * Vector3(c.x + sx * (len * 0.5 - 3.0), h + 1.0, sz * (wid * 0.5 - 3.0))
						lm.frustum("Wall", q, 2.4, 2.0, 10.0, 8)
						lm.spire("Copper", q + Vector3(0, 10.0, 0), 2.3, 8.0, 0.0, 8)
			x += len
	lm.commit(model)

# --- Ostankino Tower ---

const OST_TOP := 540.1

static func ostankino(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B5AC", 8.0))
	lm.use("Glass", LandmarkMaterials.glass("#34454E"))
	lm.use("Red", LandmarkMaterials.paint("#C23B2E", 0.5, 0.2))
	lm.use("White", LandmarkMaterials.paint("#ECECE8", 0.5, 0.2))
	lm.use("Podium", LandmarkMaterials.pbr("pavement", "#9C978D", 4.0))
	lm.frustum("Podium", Vector3(0, 0, 0), 46.0, 44.0, 5.0, 24)
	# Ten legs merge into the shaft at 63 m, then the shaft to the pod.
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(32.0, 0), Vector2(26.0, 12.0),
		Vector2(18.0, 32.0), Vector2(12.0, 52.0), Vector2(9.6, 63.0)]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(9.6, 63.0), Vector2(8.4, 110.0),
		Vector2(7.4, 200.0), Vector2(7.0, 300.0), Vector2(7.4, 318.0)]), 20)
	lm.lathe("Concrete", Vector3(0, 318.0, 0), PackedVector2Array([Vector2(7.4, 0), Vector2(14.0, 8.0),
		Vector2(19.5, 15.0), Vector2(20.5, 22.0), Vector2(19.0, 36.0), Vector2(11.0, 42.0),
		Vector2(5.4, 46.0)]), 24)
	lm.lathe("Glass", Vector3(0, 318.0, 0), PackedVector2Array([Vector2(20.55, 17.0), Vector2(20.7, 21.0),
		Vector2(20.55, 26.0)]), 24)
	lm.lathe("Concrete", Vector3(0, 364.0, 0), PackedVector2Array([Vector2(5.4, 0), Vector2(4.2, 12.0),
		Vector2(3.2, 21.0)]), 14)
	# Mast: red-white bands tapering to the tip.
	var y0 := 385.0
	var bands := 10
	for k in bands:
		var h := (OST_TOP - y0) / bands
		var r0 := lerpf(3.0, 0.2, float(k) / bands)
		var r1 := lerpf(3.0, 0.2, float(k + 1) / bands)
		lm.frustum("Red" if k % 2 == 0 else "White", Vector3(0, y0 + h * k, 0), r0, r1, h, 8)
	lm.commit(model)

# --- The Motherland Calls ---

const MOTHER_TOP := 85.0
const FEET := 2.0

static func motherland(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B3B0A8", 5.0))
	lm.use("Steel", LandmarkMaterials.paint("#A9AEB0", 0.35, 0.8))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#8C8578", 4.0))
	lm.box("Base", Vector3(0, FEET * 0.5 - 0.5, 0), Vector3(26.0, FEET + 1.0, 16.0))
	var f := Vector3(0, FEET, 0)
	# Striding robe, forward (east) foot leading, torso leaning slightly.
	lm.lathe("Concrete", f, PackedVector2Array([Vector2(5.6, 0), Vector2(4.6, 8.0), Vector2(3.8, 18.0),
		Vector2(3.4, 28.0), Vector2(3.2, 34.0)]), 14, 1.2, 0.9)
	lm.lathe("Concrete", f + Vector3(0.6, 34.0, 0), PackedVector2Array([Vector2(3.2, 0), Vector2(3.6, 4.0),
		Vector2(3.1, 8.0), Vector2(1.5, 9.8)]), 14, 0.9, 1.1)
	lm.lathe("Concrete", f + Vector3(0.9, 43.0, 0), PackedVector2Array([Vector2(0.8, 0), Vector2(1.5, 2.2),
		Vector2(2.0, 4.6), Vector2(1.2, 6.8), Vector2(0.0, 7.2)]), 12)
	# Skirt folds streaming back, flowing hair and cloak.
	for z in [-3.0, -1.0, 1.0, 3.0]:
		lm.beam("Concrete", f + Vector3(-1.0, 22.0, z), f + Vector3(-9.0 - absf(z), 6.0, z * 1.4), 2.6, 0.9)
	lm.beam("Concrete", f + Vector3(0.0, 44.0, 1.0), f + Vector3(-9.0, 36.0, 2.5), 3.4, 0.7)
	lm.beam("Concrete", f + Vector3(0.0, 40.0, -2.0), f + Vector3(-8.0, 32.0, -3.0), 4.6, 0.7)
	# Left arm stretched forward and down, right arm raising the sword.
	lm.beam("Concrete", f + Vector3(1.5, 42.0, 3.4), f + Vector3(13.0, 36.0, 6.0), 2.4, 2.0)
	lm.beam("Concrete", f + Vector3(1.5, 43.0, -3.2), f + Vector3(5.0, 51.0, -3.6), 2.4, 2.2)
	# Sword: crossguard, blade tapering to the tip at MOTHER_TOP.
	var hand := f + Vector3(5.0, 50.0, -3.6)
	lm.beam("Steel", hand + Vector3(0, -2.0, 0), hand + Vector3(0.3, 1.0, 0), 0.9, 0.9)
	lm.beam("Steel", hand + Vector3(0.3, 1.0, -2.2), hand + Vector3(0.3, 1.0, 2.2), 0.8, 0.8)
	var tip := Vector3(hand.x + 6.0, MOTHER_TOP, hand.z)
	var root := hand + Vector3(0.3, 1.0, 0)
	var mid := root.lerp(tip, 0.4)
	lm.beam("Steel", root, mid, 2.4, 0.6, Vector3(0, 0, 1))
	lm.beam("Steel", mid, tip, 1.4, 0.5, Vector3(0, 0, 1))
	lm.commit(model)
