class_name SEuAlhambra
extends RefCounted

## The Alhambra and the Parthenon in true metres.

# --- Alhambra ---------------------------------------------------------------

const COMARES_W := 18.0

## The Nasrid palaces of the Alhambra on the Sabika hill, origin at the
## Comares Tower: the 45 m tower (its foot on the scarp below the court)
## with paired-arch windows and merlons over the Hall of the Ambassadors;
## the Court of the Myrtles (36.6 x 23 m) with its 34 m pool and the
## seven-arched porticoes at both ends; the Court of the Lions to the
## east, 124 slender marble columns round the court, the two pavilions
## with their pyramid roofs and the fountain of twelve lions; Charles V's
## square Renaissance palace (63 m, rusticated below, Ionic above) round
## its 42 m circular court of 32 Doric and 32 Ionic columns to the south;
## and, drawn closer than it stands, the Alcazaba with the Torre de la
## Vela and the keep to the west. Walls are the red-ochre rammed earth
## and brick that gave the hill its name.
static func alhambra(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#B98859", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A5583A", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBB9B", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#473F35", 3.0))
	lm.use("Water", LandmarkMaterials.glass("#2C6670"))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E2D3B2", 2.0))
	lm.use("Hedge", LandmarkMaterials.pbr("render", "#4F6B3A", 2.0))
	_comares(lm)
	_myrtles(lm)
	_lions(lm, Vector3(52.0, 0, 44.0))
	_charles(lm, Vector3(-10.0, 0, 112.0))
	_alcazaba(lm, Vector3(-128.0, 0, 30.0))
	lm.commit(model)

## Comares Tower: battered shaft, the windows of the Hall of the
## Ambassadors (three paired-arch ajimeces a side), the upper windows,
## a moulded band and the merlons.
static func _comares(lm: LandmarkMesh) -> void:
	var w := COMARES_W
	lm.box("Wall", Vector3(0, 0.6, 0), Vector3(w + 1.6, 1.2, w + 1.6))
	lm.box("Wall", Vector3(0, 22.0, 0), Vector3(w, 42.0, w))
	lm.box("Wall", Vector3(0, 43.2, 0), Vector3(w + 0.6, 0.6, w + 0.6))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := out * (w * 0.5)
		# Brick quoin strips at the corners.
		lm.box("Trim", f + right * (w * 0.5 - 0.4) + Vector3(0, 22.0, 0) + out * 0.05, Vector3(0.8, 42.0, 0.2), r, 0.0)
		# Hall windows: an arched alcove with a paired-light ajimez.
		for i in 3:
			var x := -5.6 + 5.6 * float(i)
			var o := f + right * x + Vector3(0, 27.0, 0)
			SEuParts.niche(lm, "Trim", "Shadow", o, out, 2.8, 5.2, SEuParts.ROUND, 0.35)
			lm.frustum("Trim", o + out * 0.15, 0.14, 0.12, 3.6, 8)
			SEuParts.arch_ring(lm, "Trim", o + Vector3(0, 3.6, 0) + out * 0.2 - right * 0.7, right, out, 1.2, 0.15, 0.2,
				false, 4)
			SEuParts.arch_ring(lm, "Trim", o + Vector3(0, 3.6, 0) + out * 0.2 + right * 0.7, right, out, 1.2, 0.15, 0.2,
				false, 4)
			lm.box("Trim", o + Vector3(0, 6.6, 0) + out * 0.1, Vector3(4.0, 1.4, 0.15), r, 0.0)
		for i in 2:
			SEuParts.niche(lm, "Trim", "Shadow", f + right * (-3.0 + 6.0 * float(i)) + Vector3(0, 36.5, 0), out, 1.4, 2.6,
				SEuParts.ROUND, 0.2)
		for i in 2:
			SEuParts.niche(lm, "Trim", "Shadow", f + right * (-3.0 + 6.0 * float(i)) + Vector3(0, 14.0, 0), out, 0.8, 1.6,
				SEuParts.RECT, 0.15)
		SEuUtil.crenels(lm, "Wall", f - right * (w * 0.5 - 0.6) + Vector3(0, 43.5, 0) - out * 0.4,
			f + right * (w * 0.5 - 0.6) + Vector3(0, 43.5, 0) - out * 0.4, 0.75, 1.5, 0.8)

## Court of the Myrtles south of the tower: two-storey wings, the pool
## and its hedges, the porticoes of seven arches at both ends.
static func _myrtles(lm: LandmarkMesh) -> void:
	var z0 := COMARES_W * 0.5
	var cw := 23.0
	var cl := 36.6
	var zc := z0 + 4.0 + cl * 0.5
	# Sala de la Barca between tower and court, under a tiled roof.
	lm.box("Wall", Vector3(0, 6.0, z0 + 2.0), Vector3(cw + 10.0, 12.0, 4.0))
	lm.gable("Tile", Vector3(0, 12.0, z0 + 2.0), 4.0, cw + 10.0, 1.6, Basis(Vector3.UP, PI * 0.5), 0.5)
	# Long east and west wings.
	for s in [-1.0, 1.0]:
		var wx: float = s * (cw * 0.5 + 4.0)
		lm.box("Wall", Vector3(wx, 5.5, zc), Vector3(8.0, 11.0, cl + 8.0))
		lm.gable("Tile", Vector3(wx, 11.0, zc), 8.0, cl + 8.0, 2.2, Basis(), 0.5)
		var out := Vector3(-s, 0, 0)
		for i in 6:
			var z := zc - cl * 0.5 + cl * (float(i) + 0.5) / 6.0
			SEuParts.niche(lm, "Trim", "Shadow", Vector3(s * cw * 0.5, 0.0, z), out, 1.4, 3.0, SEuParts.ROUND, 0.3, -1.0, false)
			SEuParts.niche(lm, "Trim", "Shadow", Vector3(s * cw * 0.5, 6.0, z), out, 1.0, 1.8, SEuParts.ROUND, 0.2)
			lm.box("Wall", Vector3(s * cw * 0.5 - s * 0.6, 7.0, z), Vector3(1.2, 0.2, 2.2))
	# South wing with its portico; the north portico before the Barca.
	lm.box("Wall", Vector3(0, 6.0, zc + cl * 0.5 + 4.0), Vector3(cw + 16.0, 12.0, 8.0))
	lm.gable("Tile", Vector3(0, 12.0, zc + cl * 0.5 + 4.0), 8.0, cw + 16.0, 2.2, Basis(Vector3.UP, PI * 0.5), 0.5)
	for e in [[zc - cl * 0.5 + 0.2, Vector3(0, 0, 1)], [zc + cl * 0.5 - 0.2, Vector3(0, 0, -1)]]:
		var z: float = e[0]
		var out: Vector3 = e[1]
		var pz := z + out.z * 3.2
		for i in 8:
			var x := -cw * 0.5 + 2.0 + (cw - 4.0) * float(i) / 7.0
			SEuParts.col(lm, "Trim", Vector3(x, 0, pz), 0.18, 3.6, "plain", 8)
			if i == 3 or i == 4:
				SEuParts.col(lm, "Trim", Vector3(x + (0.45 if i == 3 else -0.45), 0, pz), 0.18, 3.6, "plain", 8)
		SEuParts.arcade_wall(lm, "Trim", Vector3(-cw * 0.5 + 2.0, 3.6, pz), Vector3(cw * 0.5 - 2.0, 3.6, pz), out, 7,
			2.4, 3.2, 0.5, SEuParts.ROUND)
		lm.box("Tile", Vector3(0, 7.0, z + out.z * 1.6), Vector3(cw - 2.0, 0.3, 3.8), Basis(Vector3.RIGHT, 0.2 * out.z))
		lm.box("Stone", Vector3(0, 0.1, z + out.z * 1.6), Vector3(cw - 3.0, 0.2, 3.6))
	# The pool and its clipped myrtle hedges.
	lm.box("Stone", Vector3(0, 0.15, zc), Vector3(8.4, 0.3, 35.0))
	lm.box("Water", Vector3(0, 0.32, zc), Vector3(7.1, 0.05, 34.0))
	for s in [-1.0, 1.0]:
		lm.box("Hedge", Vector3(s * 5.0, 0.6, zc), Vector3(1.2, 1.2, 32.0))

## Court of the Lions centred on `c`: the arcaded galleries on 124
## columns (single and paired), the two pavilions on the short sides
## with their pyramid roofs, the roofs over the galleries and the
## fountain basin on its twelve lions.
static func _lions(lm: LandmarkMesh, c: Vector3) -> void:
	var cl := 28.5
	var cw := 15.7
	# Surrounding halls (Two Sisters, Abencerrajes, Kings).
	for e in [[Vector3(0, 0, -cw * 0.5 - 7.0), Vector3(cl + 14.0, 10.0, 8.0)], [Vector3(0, 0, cw * 0.5 + 7.0), Vector3(cl + 14.0, 10.0, 8.0)],
			[Vector3(cl * 0.5 + 8.0, 0, 0), Vector3(8.0, 12.0, cw + 6.0)], [Vector3(-cl * 0.5 - 8.0, 0, 0), Vector3(8.0, 9.0, cw + 6.0)]]:
		var hc: Vector3 = c + (e[0] as Vector3)
		var hs: Vector3 = e[1]
		lm.box("Wall", hc + Vector3(0, hs.y * 0.5, 0), hs)
		lm.gable("Tile", hc + Vector3(0, hs.y, 0), minf(hs.x, hs.z), maxf(hs.x, hs.z), 2.2,
			Basis() if hs.z > hs.x else Basis(Vector3.UP, PI * 0.5), 0.5)
	# Kings' hall and Two Sisters' lantern towers with tiled pyramids.
	for p in [Vector3(0, 0, -cw * 0.5 - 7.0), Vector3(0, 0, cw * 0.5 + 7.0)]:
		lm.box("Wall", c + (p as Vector3) + Vector3(0, 12.0, 0), Vector3(8.0, 4.0, 8.0))
		lm.spire("Tile", c + (p as Vector3) + Vector3(0, 14.0, 0), 4.6, 3.0)
	# Gallery round the court: columns, arcaded walls, lean-to roofs.
	var gd := 3.2
	var sides := [[Vector3(-cl * 0.5, 0, -cw * 0.5), Vector3(cl * 0.5, 0, -cw * 0.5), Vector3(0, 0, 1), 11],
		[Vector3(cl * 0.5, 0, cw * 0.5), Vector3(-cl * 0.5, 0, cw * 0.5), Vector3(0, 0, -1), 11],
		[Vector3(cl * 0.5, 0, -cw * 0.5), Vector3(cl * 0.5, 0, cw * 0.5), Vector3(-1, 0, 0), 7],
		[Vector3(-cl * 0.5, 0, cw * 0.5), Vector3(-cl * 0.5, 0, -cw * 0.5), Vector3(1, 0, 0), 7]]
	for sd in sides:
		var a: Vector3 = c + (sd[0] as Vector3)
		var b: Vector3 = c + (sd[1] as Vector3)
		var out: Vector3 = sd[2]
		var n: int = sd[3]
		var dir := (b - a).normalized()
		for i in n + 1:
			var p := a.lerp(b, float(i) / float(n))
			var paired := i % 3 == 0
			for k in (2 if paired else 1):
				SEuParts.col(lm, "Trim", p + dir * (0.32 * (float(k) - 0.5) if paired else 0.0), 0.13, 3.0, "plain", 6)
		SEuParts.arcade_wall(lm, "Trim", a + Vector3(0, 3.0, 0), b + Vector3(0, 3.0, 0), out, n,
			a.distance_to(b) / float(n) - 0.5, 1.8, 0.4, SEuParts.ROUND)
		# Pierced plaster (sebka) panel band over the arches.
		for i in n:
			var p := a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, 4.3, 0) + out * 0.02
			lm.box("Shadow", p, Vector3(a.distance_to(b) / float(n) - 0.8, 0.3, 0.04), Basis(dir, Vector3.UP, out), 0.0)
		var mid := (a + b) * 0.5 - out * gd * 0.5
		lm.box("Tile", mid + Vector3(0, 5.2, 0), Vector3(a.distance_to(b) + 1.0, 0.3, gd + 1.0),
			Basis(dir, Vector3.UP, out) * Basis(Vector3.RIGHT, -0.25))
		lm.box("Shadow", mid + Vector3(0, 0.05, 0) + Vector3.ZERO, Vector3(a.distance_to(b), 0.1, gd), Basis(dir, Vector3.UP, out), 0.0)
		SEuParts.niche(lm, "Trim", "Shadow", mid - out * (gd * 0.5 - 0.02), out, 1.6, 3.4, SEuParts.ROUND, 0.2, -1.0, false)
	# Pavilions projecting into the court at both short ends.
	for s in [-1.0, 1.0]:
		var pc := c + Vector3(s * (cl * 0.5 - 1.4), 0, 0)
		for dz in [-1.8, 1.8]:
			for dx in [-1.8, 1.8]:
				SEuParts.col(lm, "Trim", pc + Vector3(float(dx), 0, float(dz)), 0.13, 3.4, "plain", 6)
		for k in 4:
			var bas := Basis(Vector3.UP, PI * 0.5 * float(k))
			var out := bas * Vector3(0, 0, 1)
			var rt := bas * Vector3(1, 0, 0)
			SEuParts.arcade_wall(lm, "Trim", pc + out * 1.9 - rt * 1.9 + Vector3(0, 3.4, 0), pc + out * 1.9 + rt * 1.9 + Vector3(0, 3.4, 0),
				out, 1, 3.0, 1.8, 0.3, SEuParts.ROUND)
		lm.box("Wall", pc + Vector3(0, 5.6, 0), Vector3(4.2, 0.6, 4.2))
		lm.spire("Tile", pc + Vector3(0, 5.9, 0), 2.6, 3.2)
	# Fountain: twelve lions round the twelve-sided basin.
	lm.frustum("Stone", c, 2.4, 2.4, 0.3, 24)
	lm.frustum("Trim", c + Vector3(0, 0.3, 0), 1.2, 1.2, 0.8, 12)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var lb := c + d * 1.45 + Vector3(0, 0.3, 0)
		lm.box("Trim", lb + Vector3(0, 0.25, 0), Vector3(0.35, 0.5, 0.7), Basis(Vector3.UP, atan2(d.x, d.z)))
		lm.box("Trim", lb + d * 0.3 + Vector3(0, 0.55, 0), Vector3(0.32, 0.4, 0.32), Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
	lm.lathe("Trim", c + Vector3(0, 1.1, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(1.6, 0.3),
		Vector2(1.7, 0.5), Vector2(1.4, 0.5)]), 12)
	lm.frustum("Water", c + Vector3(0, 1.45, 0), 1.4, 1.4, 0.04, 12)
	lm.frustum("Trim", c + Vector3(0, 1.5, 0), 0.18, 0.12, 0.6, 8)
	# Paths crossing the court with the four channels.
	for d in [Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		lm.box("Water", c + Vector3(0, 0.05, 0), Vector3(cl - 1.0, 0.1, 0.3) if d.x > 0.0 else Vector3(0.3, 0.1, cw - 1.0), Basis(), 0.0)

## Charles V's palace centred on `pc`: square 63 m block, rusticated
## lower storey with Tuscan pilasters and pedimented windows, upper
## storey with Ionic pilasters and oculi, the portals and the circular
## court of 32 + 32 columns.
static func _charles(lm: LandmarkMesh, pc: Vector3) -> void:
	var hw := 31.5
	var cr := 15.2
	var ch := 17.0
	# Four wings round the court (the court cylinder is cut by drawing
	# the wings to the court and a ring wall).
	for e in [[Vector3(0, 0, -23.5), Vector3(63.0, ch, 16.0)], [Vector3(0, 0, 23.5), Vector3(63.0, ch, 16.0)],
			[Vector3(-23.5, 0, 0), Vector3(16.0, ch, 31.0)], [Vector3(23.5, 0, 0), Vector3(16.0, ch, 31.0)]]:
		var s2: Vector3 = e[1]
		lm.box("Stone", pc + (e[0] as Vector3) + Vector3(0, s2.y * 0.5, 0), s2)
	for k in 4:
		var bas := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := bas * Vector3(0, 0, 1)
		var rt := bas * Vector3(1, 0, 0)
		var f := pc + out * hw
		# Rustication courses on the lower storey.
		for j in 7:
			lm.box("Stone", f + out * 0.08 + Vector3(0, 0.6 + 1.1 * float(j), 0), Vector3(63.0, 0.12, 0.16), bas, 0.0)
		lm.box("Trim", f + out * 0.2 + Vector3(0, 8.4, 0), Vector3(63.6, 0.8, 0.6), bas)
		LandmarkDetail.cornice(lm, "Trim", f - rt * hw + Vector3(0, ch - 0.9, 0), f + rt * hw + Vector3(0, ch - 0.9, 0), out,
			0.9, true)
		for i in 10:
			var x := -hw + 3.15 + (hw * 2.0 - 6.3) * float(i) / 9.0
			lm.box("Stone", f + rt * (x - 3.15) + out * 0.25 + Vector3(0, 4.2, 0), Vector3(0.9, 8.4, 0.5), bas)
			lm.box("Trim", f + rt * (x - 3.15) + out * 0.2 + Vector3(0, 12.6, 0), Vector3(0.8, 7.4, 0.4), bas)
			if (k == 1 or k == 2) and (i == 4 or i == 5):
				continue
			LandmarkDetail.window(lm, "Trim", "Shadow", f + rt * x + Vector3(0, 3.6, 0) + out * 0.02, out, 1.6, 3.0, false, 0.25)
			LandmarkDetail.window(lm, "Trim", "Shadow", f + rt * x + Vector3(0, 11.6, 0) + out * 0.02, out, 1.6, 3.2, false, 0.25)
			lm.disc("Shadow", f + rt * x + Vector3(0, 15.0, 0) + out * 0.05, out, 0.55, 10)
		if k == 1 or k == 2:
			# Triumphal portal: paired columns, the arched door and relief.
			SEuParts.niche(lm, "Trim", "Shadow", f, out, 4.0, 7.0, SEuParts.ROUND, 0.6, 0.8, false)
			for s in [-1.0, 1.0]:
				for m in 2:
					SEuParts.col(lm, "Trim", f + out * 0.8 + rt * s * (3.0 + 1.1 * float(m)), 0.35, 8.0, "tuscan", 10)
			SEuParts.niche(lm, "Trim", "Shadow", f + Vector3(0, 9.6, 0), out, 2.6, 4.6, SEuParts.ROUND, 0.4)
	# Circular court: Doric colonnade below, Ionic above.
	var cc := pc
	for i in 32:
		var a := TAU * float(i) / 32.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.col(lm, "Trim", cc + d * cr, 0.35, 7.0, "tuscan", 8)
		SEuParts.col(lm, "Trim", cc + d * cr + Vector3(0, 8.6, 0), 0.3, 6.4, "corinthian", 8)
	lm.frustum("Trim", cc + Vector3(0, 7.0, 0), cr + 0.6, cr + 0.6, 1.6, 48)
	lm.frustum("Trim", cc + Vector3(0, 15.0, 0), cr + 0.6, cr + 0.6, 1.4, 48)
	SEuParts.rail(lm, "Trim", cc + Vector3(cr, 8.6, -1.5), cc + Vector3(cr, 8.6, 1.5), 1.0, 3.0)
	lm.lathe("Stone", cc, PackedVector2Array([Vector2(cr + 4.2, 0), Vector2(cr + 4.2, ch), Vector2(cr + 4.0, ch)]),
		48, 1.0, 1.0, 0.0, true, false)
	lm.frustum("Tile", cc + Vector3(0, ch - 1.0, 0), cr + 4.4, cr + 0.4, 1.0, 48)
	lm.box("Stone", cc + Vector3(0, 0.05, 0), Vector3(cr * 1.4, 0.1, cr * 1.4), Basis(), 0.0)

## The Alcazaba centred on `ac`: curtain walls with battlements, square
## towers, the keep (Torre del Homenaje) and the Torre de la Vela with
## its belfry.
static func _alcazaba(lm: LandmarkMesh, ac: Vector3) -> void:
	for e in [[Vector3(0, 0, -20.0), Vector3(54.0, 10.0, 2.5)], [Vector3(0, 0, 20.0), Vector3(54.0, 10.0, 2.5)],
			[Vector3(-26.0, 0, 0), Vector3(2.5, 10.0, 40.0)], [Vector3(26.0, 0, 0), Vector3(2.5, 10.0, 40.0)],
			[Vector3(0, 0, 0), Vector3(54.0, 7.0, 2.0)]]:
		var es: Vector3 = e[1]
		var wc: Vector3 = ac + (e[0] as Vector3)
		lm.box("Wall", wc + Vector3(0, es.y * 0.5, 0), es)
		var long_x := es.x > es.z
		var half := (es.x if long_x else es.z) * 0.5
		var dir := Vector3(1, 0, 0) if long_x else Vector3(0, 0, 1)
		var side := Vector3(0, 0, 1) if long_x else Vector3(1, 0, 0)
		for s in [-1.0, 1.0]:
			SEuUtil.crenels(lm, "Wall", wc - dir * half + side * (s * (minf(es.x, es.z) * 0.5 - 0.3)) + Vector3(0, es.y, 0),
				wc + dir * half + side * (s * (minf(es.x, es.z) * 0.5 - 0.3)) + Vector3(0, es.y, 0), 0.6, 1.2, 0.6)
	# Ruined dwellings of the military quarter (Barrio Castrense).
	for i in 8:
		var p := ac + Vector3(-20.0 + 5.6 * float(i), 0, -10.0 + 6.0 * float(i % 2))
		lm.box("Wall", p + Vector3(0, 0.6, 0), Vector3(4.4, 1.2, 0.5))
		lm.box("Wall", p + Vector3(-2.0, 0.6, 2.0), Vector3(0.5, 1.2, 4.4))
	var towers := [[Vector3(26.0, 0, -20.0), 22.0, 8.0], [Vector3(26.0, 0, 20.0), 20.0, 8.0], [Vector3(0, 0, -20.0), 18.0, 7.0],
		[Vector3(0, 0, 20.0), 16.0, 7.0], [Vector3(-26.0, 0, -20.0), 26.0, 11.0], [Vector3(-26.0, 0, 20.0), 27.0, 16.0]]
	for t in towers:
		var tp: Vector3 = ac + (t[0] as Vector3)
		var th: float = t[1]
		var tw: float = t[2]
		lm.box("Wall", tp + Vector3(0, th * 0.5, 0), Vector3(tw, th, tw))
		lm.box("Wall", tp + Vector3(0, th - 0.3, 0), Vector3(tw + 0.4, 0.6, tw + 0.4))
		for k in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(k))
			var out := r * Vector3(0, 0, 1)
			var right := r * Vector3(1, 0, 0)
			SEuUtil.crenels(lm, "Wall", out * (tw * 0.5 - 0.2) - right * (tw * 0.5) + tp + Vector3(0, th, 0),
				out * (tw * 0.5 - 0.2) + right * (tw * 0.5) + tp + Vector3(0, th, 0), 0.6, 1.2, 0.6)
			for j in int(th / 8.0):
				SEuParts.niche(lm, "Trim", "Shadow", tp + out * (tw * 0.5) + Vector3(0, 5.0 + 7.0 * float(j), 0), out,
					0.6, 1.4, SEuParts.ROUND, 0.15)
	# Torre de la Vela: the bell gable over its west tower.
	var vt := ac + Vector3(-26.0, 27.0, 20.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", vt + Vector3(0, 2.4, s * 1.4), Vector3(0.8, 4.8, 0.8))
	lm.box("Stone", vt + Vector3(0, 5.0, 0), Vector3(1.0, 0.6, 3.6))
	lm.spire("Stone", vt + Vector3(0, 5.3, 0), 0.6, 1.2)
	lm.lathe("Shadow", vt + Vector3(0, 2.6, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(0.6, 0.6),
		Vector2(0.45, 1.6), Vector2(0.0, 1.8)]), 10)

# --- Parthenon -----------------------------------------------------------------

const COL_H := 10.43
const STYLO := 1.53

## The Doric temple of Athena on the Acropolis (447-432 BC), origin at
## its centre, front to the east (+X): the three-step crepidoma (1.53 m)
## under the 69.5 x 30.9 m stylobate, 8 x 17 fluted Doric columns of
## Pentelic marble (10.43 m, 1.9 m across, 20 flutes), the architrave,
## the frieze of 92 metopes between triglyphs, the geison and both
## pediments; inside the peristyle the two six-column porches and the
## cella reduced to its low courses and the standing west cross wall,
## as the explosion of 1687 left it, with the gap in the south
## colonnade; 17.1 m from stylobate to pediment apex.
static func parthenon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D6BE", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D2BB93", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#6A5F52", 2.5))
	SEuParts.steps_block(lm, "Marble", Vector3.ZERO, 69.5, 30.9, 3, STYLO / 3.0, 0.7)
	var y0 := STYLO
	var h := COL_H
	var xs: Array[float] = []
	for i in 17:
		xs.append(-32.9 + 65.8 * float(i) / 16.0)
	var zs: Array[float] = []
	for i in 8:
		zs.append(-14.05 + 28.1 * float(i) / 7.0)
	# The south (+Z) colonnade lost its middle columns in 1687.
	var gap := func(i: int) -> bool:
		return i >= 6 and i <= 10
	for i in 17:
		_column(lm, Vector3(xs[i], y0, zs[0]), h)
		if gap.call(i):
			_drum_stump(lm, Vector3(xs[i], y0, zs[7]), 1.0 + 0.9 * float(i % 3))
		else:
			_column(lm, Vector3(xs[i], y0, zs[7]), h)
	for i in range(1, 7):
		for x in [xs[0], xs[16]]:
			_column(lm, Vector3(float(x), y0, zs[i]), h)
	# Entablature: architrave, triglyph frieze and geison on each run.
	var ey := y0 + h
	var runs := [[-1.0, 0, 16, zs[0]], [1.0, 0, 5, zs[7]], [1.0, 11, 16, zs[7]]]
	for rn in runs:
		var s: float = rn[0]
		var a: int = rn[1]
		var b: int = rn[2]
		var z: float = rn[3]
		var xa: float = xs[a] - (1.15 if a == 0 else 2.0)
		var xb: float = xs[b] + (1.15 if b == 16 else 2.0)
		var cx := (xa + xb) * 0.5
		var lx := xb - xa
		lm.box("Marble", Vector3(cx, ey + 0.67, z), Vector3(lx, 1.35, 2.0))
		lm.box("Honey", Vector3(cx, ey + 2.02, z), Vector3(lx, 1.35, 1.9))
		LandmarkDetail.cornice(lm, "Marble", Vector3(xa, ey + 2.7, z + s * 0.95), Vector3(xb, ey + 2.7, z + s * 0.95),
			Vector3(0, 0, s), 0.6, false)
		var nt := int(roundf(lx / 2.06))
		for k in nt + 1:
			var tx := xa + 0.42 + (lx - 0.84) * float(k) / float(nt)
			_triglyph(lm, Vector3(tx, ey + 2.02, z + s * 0.97), Vector3(0, 0, s))
	for x in [xs[0], xs[16]]:
		var s := signf(float(x))
		lm.box("Marble", Vector3(float(x), ey + 0.67, 0), Vector3(2.0, 1.35, 30.1))
		lm.box("Honey", Vector3(float(x), ey + 2.02, 0), Vector3(1.9, 1.35, 30.1))
		LandmarkDetail.cornice(lm, "Marble", Vector3(float(x) + s * 0.95, ey + 2.7, -15.1), Vector3(float(x) + s * 0.95, ey + 2.7, 15.1),
			Vector3(s, 0, 0), 0.6, false)
		for k in 15:
			_triglyph(lm, Vector3(float(x) + s * 0.97, ey + 2.02, -14.6 + 29.2 * float(k) / 14.0), Vector3(s, 0, 0))
		# Pediment: tympanum, raking cornices, a few surviving figures.
		var py := ey + 3.3
		lm.gable("Marble", Vector3(float(x), py, 0), 30.4, 1.4, 3.3, Basis(Vector3.UP, PI * 0.5), 0.0, "Honey")
		for side in [-1.0, 1.0]:
			lm.beam("Marble", Vector3(float(x) + s * 0.5, py + 0.1, side * 15.6), Vector3(float(x) + s * 0.5, py + 3.3, 0), 2.2, 0.7)
		if s < 0.0:
			for z in [-11.0, -8.6, 9.0, 11.6]:
				SEuParts.figure(lm, "Honey", Vector3(float(x) + s * 0.2, py, float(z)), 1.6 - absf(float(z)) * 0.03)
	# Inner porches: six columns before each end of the cella (the east
	# porch survives only in stumps).
	for i in 6:
		var z := -9.0 + 18.0 * float(i) / 5.0
		_column(lm, Vector3(-25.6, y0 + 0.3, z), 9.9, 0.85)
		if i == 0 or i == 5:
			_column(lm, Vector3(25.6, y0 + 0.3, z), 9.9, 0.85)
		else:
			_drum_stump(lm, Vector3(25.6, y0 + 0.3, z), 1.4)
	lm.box("Marble", Vector3(-25.6, y0 + 10.2 + 0.6, 0), Vector3(1.8, 1.2, 20.0))
	# Cella: low courses of the long walls, the standing west cross wall
	# with its great door, the stub of the east wall.
	lm.box("Marble", Vector3(0, y0 + 0.15, 0), Vector3(60.0, 0.3, 21.0))
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(0, y0 + 1.0, s * 9.8), Vector3(48.0, 2.0, 1.2))
		lm.box("Honey", Vector3(-17.0, y0 + 2.6, s * 9.8), Vector3(10.0, 5.2, 1.2))
	var wx := -18.0
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(wx, y0 + 5.2, s * 6.6), Vector3(1.4, 10.4, 7.0))
	lm.box("Honey", Vector3(wx, y0 + 9.0, 0), Vector3(1.4, 2.8, 6.2))
	lm.box("Marble", Vector3(wx, y0 + 7.4, 0), Vector3(1.6, 0.5, 6.4))
	lm.box("Honey", Vector3(24.0, y0 + 0.7, 0), Vector3(1.2, 1.4, 20.8))
	lm.commit(model)

## One fluted Doric column (LandmarkDetail): 20 flutes, entasis, echinus
## and abacus; `r` the lower radius.
static func _column(lm: LandmarkMesh, base: Vector3, h: float, r: float = 0.95) -> void:
	LandmarkDetail.column(lm, "Marble", base, r, h, "doric", 20)

## The bottom drums of a fallen column, `h` tall.
static func _drum_stump(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.frustum("Marble", base, 0.95, 0.94, h, 20)
	lm.frustum("Shadow", base + Vector3(0, h, 0), 0.9, 0.0, 0.05, 12)

## A triglyph on the frieze facing `out`: the projecting block with its
## two vertical grooves and the guttae strip under it.
static func _triglyph(lm: LandmarkMesh, c: Vector3, out: Vector3) -> void:
	var basis := Basis(Vector3.UP.cross(out).normalized(), Vector3.UP, out)
	lm.box("Marble", c, Vector3(0.84, 1.3, 0.12), basis, 0.0)
	var rt := Vector3.UP.cross(out).normalized()
	for s in [-1.0, 1.0]:
		lm.box("Shadow", c + rt * 0.14 * s + out * 0.065, Vector3(0.09, 1.1, 0.02), basis, 0.0)
	lm.box("Marble", c - Vector3(0, 0.95, 0) + out * 0.04, Vector3(0.84, 0.12, 0.1), basis, 0.0)
