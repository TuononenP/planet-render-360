class_name SEuIberia
extends RefCounted

## The Giralda, the Belém Tower and the Guggenheim Museum Bilbao in true
## metres.

# --- Giralda --------------------------------------------------------------

const SHAFT_TOP := 70.4

## Seville's bell tower, origin at the centre of its 13.6 m base. The
## Almohad minaret shaft (1184-98, 70 m of ochre brick): each face in
## three strips - the centre with its column of twin-arched ajimez
## windows and balconies, the sides with blind multifoil arches below
## and the raised sebka lozenge lattice above; then Hernán Ruiz's
## Renaissance belfry (1568) of the bell chamber with its arches and
## bells, the clock stage, the stage of the stars and of the lilies,
## each balustraded with flower urns at the corners, the lantern dome
## and the bronze Giraldillo weathervane (104.1 m). The cathedral's nave
## and buttresses spread to the south-west.
static func giralda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#CFA97E", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C29C", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("brick", "#6E4B36", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8B8D88", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5E5038", 2.0, 0.4, 0.7))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E8DCC0", 2.5))
	var w := 13.6
	lm.box("Stone", Vector3(0, 1.0, 0), Vector3(w + 0.4, 2.0, w + 0.4))
	lm.box("Brick", Vector3(0, SHAFT_TOP * 0.5, 0), Vector3(w, SHAFT_TOP, w))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := out * (w * 0.5)
		# Strip frames: the three vertical bands stand slightly proud.
		for s in [-1.0, 1.0]:
			lm.box("Brick", f + right * s * 2.3 + Vector3(0, 35.0, 0) + out * 0.1, Vector3(0.6, 66.0, 0.2), r, 0.0)
			lm.box("Brick", f + right * s * 6.5 + Vector3(0, 35.0, 0) + out * 0.1, Vector3(0.6, 66.0, 0.2), r, 0.0)
			var sx: float = s * 4.4
			# Side strips: blind multifoil arch at the foot of each panel,
			# then the sebka lattice up to the top.
			for p in [[22.0, 23.0], [46.0, 20.0]]:
				var y0: float = p[0]
				var ph: float = p[1]
				SEuParts.niche(lm, "Brick", "Shadow", f + right * sx + Vector3(0, y0 - 3.6, 0), out, 3.2, 3.4,
					SEuParts.HORSESHOE, 0.18, 0.25, false)
				var a0 := f + right * (sx - 1.8) + Vector3(0, y0, 0) + out * 0.12
				var a1 := f + right * (sx + 1.8) + Vector3(0, y0, 0) + out * 0.12
				lm.box("Shadow", f + right * sx + Vector3(0, y0 + ph * 0.5, 0) + out * 0.01, Vector3(3.6, ph, 0.02), r, 0.0)
				lm.lattice_panel("Brick", a0, a1, a0 + Vector3(0, ph, 0), a1 + Vector3(0, ph, 0), 0.28, int(ph / 2.6), true)
			SEuParts.niche(lm, "Brick", "Shadow", f + right * sx + Vector3(0, 6.0, 0), out, 2.6, 7.0, SEuParts.HORSESHOE, 0.2)
		# Centre strip: ajimez windows with balconies, staggered per face.
		for j in 7:
			var y := 6.0 + 8.6 * float(j) + 2.0 * float(k % 2)
			if y > 64.0:
				continue
			var o := f + Vector3(0, y, 0)
			SEuParts.niche(lm, "Stone", "Shadow", o, out, 2.4, 3.6, SEuParts.HORSESHOE, 0.25)
			lm.frustum("Stone", o + out * 0.12, 0.1, 0.1, 2.4, 6)
			lm.box("Stone", o + out * 0.5 - Vector3(0, 0.15, 0), Vector3(2.8, 0.3, 1.0), r)
			lm.box("Stone", o + out * 0.95 + Vector3(0, 0.45, 0), Vector3(2.8, 0.7, 0.1), r, 0.0)
		# String course with the inscription band at the top of the shaft.
		lm.box("Stone", f + out * 0.15 + Vector3(0, 67.0, 0), Vector3(w + 0.3, 0.8, 0.3), r)
		lm.box("Plaster", f + out * 0.08 + Vector3(0, 68.6, 0), Vector3(w, 1.6, 0.16), r, 0.0)
	# Belfry stages: (y0, y1, width, opening y, opening w, opening h, n).
	var stages := [[70.4, 80.5, 11.4, 72.0, 2.6, 6.6, 3], [80.5, 90.0, 9.6, 82.0, 2.8, 6.0, 1],
		[90.0, 94.0, 7.6, 90.8, 1.2, 2.6, 2], [94.0, 96.5, 6.2, 94.3, 1.0, 1.8, 1]]
	for st in stages:
		var y0: float = st[0]
		var y1: float = st[1]
		var sw: float = st[2]
		lm.box("Plaster", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(sw, y1 - y0, sw))
		lm.box("Stone", Vector3(0, y0 + 0.35, 0), Vector3(sw + 1.2, 0.7, sw + 1.2))
		lm.box("Stone", Vector3(0, y1 - 0.3, 0), Vector3(sw + 0.6, 0.6, sw + 0.6))
		var below: float = w if y0 < 71.0 else float((stages[stages.find(st) - 1] as Array)[2])
		for k in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(k))
			var out := r * Vector3(0, 0, 1)
			var right := r * Vector3(1, 0, 0)
			var n: int = st[6]
			for i in n:
				var x := (float(i) - float(n - 1) * 0.5) * (sw / float(n) * 0.95)
				SEuParts.niche(lm, "Stone", "Shadow", out * (sw * 0.5) + right * x + Vector3(0, float(st[3]), 0), out,
					float(st[4]) * (1.25 if n == 3 and i == 1 else 1.0), float(st[5]), SEuParts.ROUND, 0.3)
			# Corner pilasters, the balustrade on the ledge below, urns.
			for s in [-1.0, 1.0]:
				lm.box("Stone", out * (sw * 0.5) + right * s * (sw * 0.5 - 0.3) + Vector3(0, (y0 + y1) * 0.5, 0),
					Vector3(0.6, y1 - y0 - 0.6, 0.3), r)
			var bl := minf(below, sw + 1.4)
			SEuParts.rail(lm, "Stone", out * (bl * 0.5 - 0.3) - right * (bl * 0.5 - 0.3) + Vector3(0, y0, 0),
				out * (bl * 0.5 - 0.3) + right * (bl * 0.5 - 0.3) + Vector3(0, y0, 0), 1.0, 3.0)
			var corner := (out + right) * (bl * 0.5 - 0.3) + Vector3(0, y0 + 1.0, 0)
			lm.lathe("Stone", corner, PackedVector2Array([Vector2(0.25, 0), Vector2(0.45, 0.4), Vector2(0.2, 0.9),
				Vector2(0.3, 1.0), Vector2(0.0, 1.4)]), 8)
	# Bells in the arches of the bell chamber.
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		for i in 3:
			var x := (float(i) - 1.0) * 3.6
			lm.lathe("Bronze", out * 5.3 + right * x + Vector3(0, 74.2, 0), PackedVector2Array([Vector2(0.9, 0),
				Vector2(0.6, 0.5), Vector2(0.5, 1.3), Vector2(0.0, 1.5)]), 10)
	# Clock faces on the clock stage.
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		lm.disc("Stone", out * 4.85 + Vector3(0, 88.6, 0), out, 0.9, 16)
	lm.lathe("Roof", Vector3(0, 96.5, 0), SEuUtil.dome(3.4, 3.4, 6), 12, 1.0, 1.0, PI / 12.0)
	for k in 12:
		var a := TAU * float(k) / 12.0 + PI / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Stone", Vector3(0, 96.5, 0) + d * 3.45, Vector3(0, 99.4, 0) + d * 1.6, 0.2, 0.15)
	lm.frustum("Stone", Vector3(0, 99.6, 0), 0.6, 0.4, 0.4, 8)
	lm.frustum("Gold", Vector3(0, 100.0, 0), 0.5, 0.3, 0.2, 8)
	LandmarkKits.statue_figure(lm, "Gold", Vector3(0, 100.2, 0), 3.9, true)
	lm.box("Gold", Vector3(0.4, 102.6, 0), Vector3(0.1, 1.8, 1.1), Basis(Vector3.UP, 0.4))
	_seville_cathedral(lm)
	lm.commit(model)

## The cathedral of Seville south-west of the tower: aisled hall nave,
## raised central vessel and crossing, the buttresses with pinnacles
## and flying arches, the tall pointed windows.
static func _seville_cathedral(lm: LandmarkMesh) -> void:
	var c := Vector3(-68.4, 0, 34.0)
	lm.box("Stone", c + Vector3(0, 13.0, 0), Vector3(123.2, 26.0, 76.0))
	lm.box("Stone", c + Vector3(0, 20.0, 0), Vector3(123.2, 40.0, 16.0))
	lm.box("Stone", c + Vector3(0, 20.0, 0), Vector3(16.0, 40.0, 76.0))
	lm.gable("Roof", c + Vector3(0, 40.0, 0), 16.0, 123.2, 4.0, Basis(Vector3.UP, PI * 0.5), 0.3)
	lm.gable("Roof", c + Vector3(0, 40.0, 0), 16.0, 76.0, 4.0, Basis(), 0.3)
	lm.frustum("Stone", c + Vector3(0, 40.0, 0), 8.0, 8.0, 8.0, 8, PI / 8.0)
	lm.lathe("Roof", c + Vector3(0, 48.0, 0), SEuUtil.dome(8.4, 5.0, 6), 8, 1.0, 1.0, PI / 8.0, false)
	for s in [-1.0, 1.0]:
		var zf: float = c.z + s * 38.0
		var out := Vector3(0, 0, s)
		for k in 14:
			var x := c.x - 61.6 + 4.4 + 8.8 * float(k)
			lm.box("Stone", Vector3(x, 13.0, zf + s * 1.6), Vector3(2.0, 26.0, 3.2))
			SEuParts.pinnacle(lm, "Stone", Vector3(x, 26.0, zf + s * 1.6), 1.2, 7.0)
			lm.beam("Stone", Vector3(x, 30.0, zf + s * 0.5), Vector3(x, 36.0, c.z + s * 8.2), 0.6, 0.9, Vector3(1, 0, 0))
			SEuParts.pinnacle(lm, "Stone", Vector3(x, 26.0, c.z + s * 21.0), 1.0, 6.0)
			if k < 13:
				var xm := x + 4.4
				SEuParts.niche(lm, "Stone", "Shadow", Vector3(xm, 8.0, zf), out, 2.6, 12.0, SEuParts.POINTED, 0.35)
				SEuParts.niche(lm, "Stone", "Shadow", Vector3(xm, 29.0, c.z + s * 8.0), out, 2.2, 8.0, SEuParts.POINTED, 0.3)
		SEuParts.rail(lm, "Stone", Vector3(c.x - 61.6, 26.0, zf - s * 0.2), Vector3(c.x + 61.6, 26.0, zf - s * 0.2), 1.2, 8.8)
	for k in 9:
		var z := c.z - 34.0 + 8.5 * float(k)
		lm.box("Stone", Vector3(c.x - 63.2, 13.0, z), Vector3(3.2, 26.0, 2.0))
		SEuParts.pinnacle(lm, "Stone", Vector3(c.x - 63.2, 26.0, z), 1.2, 7.0)
	for z in [-20.0, 0.0, 20.0]:
		SEuParts.niche(lm, "Stone", "Shadow", Vector3(c.x - 61.6, 0, c.z + float(z)), Vector3(-1, 0, 0), 5.0 if z == 0.0 else 3.6,
			12.0 if z == 0.0 else 9.0, SEuParts.POINTED, 0.8, 0.9, false)

# --- Belem Tower ---------------------------------------------------------

## Torre de Belém (Francisco de Arruda, 1514-19): Lioz limestone
## Manueline fortress on the Tagus, origin at the tower's axis, river
## front facing +Z. The hexagonal bastion with its prow to the river:
## sixteen casemate cannon ports, the cordon of twisted rope, merlons
## carved as shields with the Cross of the Order of Christ, six ribbed
## Moorish-domed watch turrets on corbels at its angles. The four-storey
## tower behind: the arcaded Renaissance loggia over the bastion with
## its balustrade, the royal arms between armillary spheres, rope-framed
## balcony windows, corner turrets and crowning shield merlons, 30 m
## above the water.
static func belem(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Lioz", LandmarkMaterials.pbr("limestone", "#E1D3B2", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE2C6", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#51493D", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("limestone", "#D2C3A0", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#6C5A3C", 2.0, 0.4, 0.7))
	var poly := PackedVector2Array([Vector2(-13.0, -8.0), Vector2(13.0, -8.0), Vector2(15.0, 3.0),
		Vector2(10.5, 11.5), Vector2(0.0, 14.5), Vector2(-10.5, 11.5), Vector2(-15.0, 3.0)])
	lm.poly_prism("Lioz", poly, 0.0, 7.5)
	var bpoly := PackedVector2Array()
	for p in poly:
		bpoly.append(p * 1.04)
	lm.poly_prism("Lioz", bpoly, 0.0, 1.2)
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var mid := (p + q) * 0.5
		var d := (q - p).normalized()
		var out := Vector3(d.y, 0, -d.x)
		if out.dot(Vector3(mid.x, 0, mid.y)) < 0.0:
			out = -out
		var bas := Basis(Vector3.UP, atan2(out.x, out.z))
		var pa := Vector3(p.x, 0, p.y)
		var qa := Vector3(q.x, 0, q.y)
		var length := p.distance_to(q)
		# Rope cordon at the terrace level.
		lm.beam("Trim", pa + Vector3(0, 5.4, 0) + out * 0.15, qa + Vector3(0, 5.4, 0) + out * 0.15, 0.35, 0.35, out)
		for k in int(length / 0.7):
			var t := (float(k) + 0.5) / float(int(length / 0.7))
			lm.box("Trim", pa.lerp(qa, t) + Vector3(0, 5.4, 0) + out * 0.3, Vector3(0.12, 0.38, 0.1),
				bas * Basis(Vector3.BACK, 0.6), 0.0)
		# Shield merlons with the cross of the Order of Christ.
		var nm := int(length / 2.2)
		for k in nm:
			var t := (float(k) + 0.5) / float(nm)
			var mc := pa.lerp(qa, t) + Vector3(0, 7.5, 0) + out * -0.3
			lm.box("Trim", mc + Vector3(0, 0.55, 0), Vector3(1.2, 1.1, 0.6), bas)
			lm.lathe("Trim", mc + Vector3(0, 1.1, 0), SEuUtil.dome(0.6, 0.5, 3), 8, 1.0, 0.5, atan2(out.x, out.z))
			lm.box("Shadow", mc + Vector3(0, 0.6, 0) + out * 0.31, Vector3(0.12, 0.6, 0.02), bas, 0.0)
			lm.box("Shadow", mc + Vector3(0, 0.7, 0) + out * 0.31, Vector3(0.5, 0.12, 0.02), bas, 0.0)
		# Casemate cannon ports along the river faces.
		if length > 8.0 and mid.y > -1.0:
			var np := int(length / 3.5)
			for k in np:
				var t := (float(k) + 0.5) / float(np)
				SEuParts.niche(lm, "Trim", "Shadow", pa.lerp(qa, t) + Vector3(0, 2.0, 0), out, 0.9, 1.1, SEuParts.ROUND, 0.2)
		# Watch turret on corbels at each salient angle.
		if i > 0:
			var a := Vector3(p.x, 0, p.y)
			var tout := Vector3(p.x, 0, p.y).normalized()
			var tc := a + tout * 0.6
			lm.lathe("Lioz", tc + Vector3(0, 4.4, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.9, 1.4),
				Vector2(1.3, 2.4), Vector2(1.3, 3.1)]), 12)
			lm.frustum("Lioz", tc + Vector3(0, 7.5, 0), 1.25, 1.2, 2.8, 12)
			for k in 4:
				var b := TAU * float(k) / 4.0
				SEuParts.niche(lm, "Trim", "Shadow", tc + Vector3(cos(b), 0, sin(b)) * 1.2 + Vector3(0, 8.0, 0),
					Vector3(cos(b), 0, sin(b)), 0.35, 1.2, SEuParts.ROUND, 0.08, 0.08, false)
			_ribbed_dome(lm, tc + Vector3(0, 10.3, 0), 1.45, 1.7)
	# The tower: four storeys over the bastion's north side.
	var tw := 11.4
	lm.box("Lioz", Vector3(0, 15.0, -2.0), Vector3(tw, 24.0, tw))
	lm.box("Trim", Vector3(0, 27.4, -2.0), Vector3(tw + 1.2, 1.2, tw + 1.2))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := Vector3(0, 0, -2.0) + out * (tw * 0.5)
		# Rope string courses between the storeys.
		for y in [12.4, 17.6, 22.6]:
			lm.beam("Trim", f - right * tw * 0.5 + Vector3(0, float(y), 0) + out * 0.12,
				f + right * tw * 0.5 + Vector3(0, float(y), 0) + out * 0.12, 0.3, 0.3, out)
		if k == 0:
			# River front: the loggia of the King's hall, arms and spheres.
			lm.box("Lioz", f + out * 1.4 + Vector3(0, 8.6, 0), Vector3(tw, 0.6, 2.8), r)
			for i in 6:
				SEuParts.col(lm, "Trim", f + out * 2.6 + right * (-5.0 + 2.0 * float(i)) + Vector3(0, 8.9, 0), 0.18, 2.6,
					"corinthian", 8)
			SEuParts.arcade_wall(lm, "Trim", f + out * 2.6 - right * 5.0 + Vector3(0, 11.5, 0),
				f + out * 2.6 + right * 5.0 + Vector3(0, 11.5, 0), out, 5, 1.6, 1.4, 0.4, SEuParts.ROUND)
			lm.box("Trim", f + out * 1.4 + Vector3(0, 13.1, 0), Vector3(tw, 0.4, 3.0), r)
			SEuParts.rail(lm, "Trim", f + out * 2.7 - right * 5.4 + Vector3(0, 8.9, 0), f + out * 2.7 + right * 5.4 + Vector3(0, 8.9, 0),
				0.9, 2.0)
			for i in 3:
				SEuParts.niche(lm, "Trim", "Shadow", f + right * (-3.4 + 3.4 * float(i)) + Vector3(0, 9.0, 0), out, 1.4, 3.0,
					SEuParts.ROUND, 0.2)
			lm.box("Trim", f + out * 0.2 + Vector3(0, 15.4, 0), Vector3(2.6, 3.0, 0.4), r)
			lm.box("Shadow", f + out * 0.42 + Vector3(0, 15.6, 0), Vector3(1.6, 1.8, 0.05), r, 0.0)
			for s in [-1.0, 1.0]:
				_sphere(lm, f + out * 0.6 + right * s * 3.4 + Vector3(0, 15.4, 0), 0.9)
			SEuParts.niche(lm, "Trim", "Shadow", f + Vector3(0, 18.4, 0), out, 1.6, 3.2, SEuParts.ROUND, 0.3)
			lm.box("Trim", f + out * 0.7 + Vector3(0, 18.2, 0), Vector3(3.0, 0.3, 1.4), r)
		else:
			for row in [[10.0, 2], [18.4, 2]]:
				var y: float = row[0]
				var n: int = row[1]
				for i in n:
					var x := (float(i) - float(n - 1) * 0.5) * 4.4
					SEuParts.niche(lm, "Trim", "Shadow", f + right * x + Vector3(0, y, 0), out, 1.5, 3.4, SEuParts.ROUND, 0.3)
					lm.box("Trim", f + right * x + out * 0.6 + Vector3(0, y - 0.15, 0), Vector3(2.4, 0.3, 1.2), r)
					SEuParts.rail(lm, "Trim", f + right * (x - 1.1) + out * 1.15 + Vector3(0, y, 0),
						f + right * (x + 1.1) + out * 1.15 + Vector3(0, y, 0), 0.9, 2.2)
			if k == 2:
				SEuParts.niche(lm, "Trim", "Shadow", f + Vector3(0, 7.5, 0), out, 1.8, 3.4, SEuParts.ROUND, 0.4, 0.4, false)
		SEuParts.niche(lm, "Trim", "Shadow", f + Vector3(0, 23.4, 0), out, 1.0, 2.2, SEuParts.ROUND, 0.2)
		# Shield merlons on the roof terrace.
		for i in 5:
			var x := -4.4 + 2.2 * float(i)
			var mc := f + right * x + Vector3(0, 28.0, 0) - out * 0.4
			lm.box("Trim", mc + Vector3(0, 0.5, 0), Vector3(1.1, 1.0, 0.6), r)
			lm.lathe("Trim", mc + Vector3(0, 1.0, 0), SEuUtil.dome(0.55, 0.45, 3), 8, 1.0, 0.5, atan2(out.x, out.z))
		# Corner turret on corbels with its ribbed dome.
		var corner := Vector3(0, 0, -2.0) + (out + right) * (tw * 0.5)
		lm.lathe("Lioz", corner + Vector3(0, 18.4, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.9, 0.8),
			Vector2(1.2, 1.6)]), 12)
		lm.frustum("Lioz", corner + Vector3(0, 20.0, 0), 1.2, 1.1, 8.2, 12)
		for b in 3:
			var ba := atan2(out.z + right.z, out.x + right.x) + (float(b) - 1.0) * 0.9
			SEuParts.niche(lm, "Trim", "Shadow", corner + Vector3(cos(ba), 0, sin(ba)) * 1.12 + Vector3(0, 23.5, 0),
				Vector3(cos(ba), 0, sin(ba)), 0.3, 1.1, SEuParts.ROUND, 0.06, 0.06, false)
		_ribbed_dome(lm, corner + Vector3(0, 28.2, 0), 1.45, 1.75)
	# The rhinoceros gargoyle under the north-west turret.
	var rh := Vector3(-tw * 0.5 - 0.6, 18.0, -2.0 - tw * 0.5 - 0.6)
	lm.box("Trim", rh, Vector3(0.7, 0.6, 1.2), Basis(Vector3.UP, PI * 0.25))
	lm.spire("Trim", rh + Vector3(-0.3, 0.2, -0.3), 0.12, 0.4)
	lm.commit(model)

## Moorish ribbed dome of radius r and height h on `base`, with a knob.
static func _ribbed_dome(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	var prof := SEuUtil.dome(r, h, 5)
	lm.lathe("Dome", base, prof, 12)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			lm.beam("Dome", base + d * (prof[j].x + 0.04) + Vector3(0, prof[j].y, 0),
				base + d * (prof[j + 1].x + 0.04) + Vector3(0, prof[j + 1].y, 0), 0.12, 0.08)
	lm.lathe("Dome", base + Vector3(0, h - 0.05, 0), SEuUtil.dome(0.16, 0.3, 3), 6)

## Armillary sphere (King Manuel's emblem): three crossed rings.
static func _sphere(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	for k in 3:
		var bas := Basis(Vector3.UP, PI / 3.0 * float(k))
		var prev := c + bas * Vector3(r, 0, 0)
		for i in 12:
			var a := TAU * float(i + 1) / 12.0
			var p := c + bas * Vector3(cos(a) * r, sin(a) * r, 0)
			lm.beam("Bronze", prev, p, 0.1, 0.1)
			prev = p

# --- Guggenheim Bilbao ---------------------------------------------------

## Gehry's titanium museum along the Nervión (1997), origin at the
## centre of the atrium, river to the north (-Z). A cluster of leaning
## titanium "petals" (the tallest 50 m) round the glazed atrium with its
## mullioned curtain walls, the 130 m "fish" gallery running east under
## La Salve bridge to the tower beyond it, the curved west wing, the
## limestone-clad rectilinear galleries to the south, the pond on the
## river side with Maman (the 9 m bronze spider), and Jeff Koons's
## Puppy (12.4 m of flowering plants) on the entrance plaza.
static func guggenheim(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Ti", LandmarkMaterials.pbr("concrete", "#BDB8A8", 3.0, 0.28, 0.85))
	lm.use("Ti2", LandmarkMaterials.pbr("concrete", "#A9A596", 3.0, 0.3, 0.8))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CCB2", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#55565A", 4.0))
	lm.use("Red", LandmarkMaterials.paint("#B8342A", 0.5, 0.4))
	lm.use("Water", LandmarkMaterials.glass("#2C5D66"))
	lm.use("Flowers", LandmarkMaterials.pbr("render", "#8E9A4E", 1.5))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4A3E30", 2.0, 0.4, 0.7))
	# Atrium petals: (centre, rx, height, rz, lean).
	var petals := [[Vector3(0, 0, -6), 13.0, 50.0, 17.0, Vector3(0.0, 0, -0.14)],
		[Vector3(12, 0, 8), 10.0, 37.0, 13.0, Vector3(0.22, 0, 0.1)],
		[Vector3(-13, 0, 4), 11.0, 31.0, 12.0, Vector3(-0.2, 0, 0.12)],
		[Vector3(2, 0, -24), 9.0, 27.0, 12.0, Vector3(0.1, 0, -0.2)],
		[Vector3(-4, 0, 24), 12.0, 24.0, 10.0, Vector3(0.1, 0, 0.25)],
		[Vector3(18, 0, -14), 8.0, 33.0, 9.0, Vector3(0.18, 0, -0.16)],
		[Vector3(-16, 0, -16), 9.0, 29.0, 9.0, Vector3(-0.22, 0, -0.1)]]
	for i in petals.size():
		var pt: Array = petals[i]
		SEuUtil.blob(lm, "Ti" if i % 2 == 0 else "Ti2", pt[0], float(pt[1]), float(pt[2]),
			float(pt[3]), pt[4], true, 16, 32)
		_seams(lm, "Ti2" if i % 2 == 0 else "Ti", pt[0], float(pt[1]), float(pt[2]), float(pt[3]), pt[4])
	# Curved gallery wings: the long east "fish" under the bridge and
	# the west wing; the river-side gallery.
	_loaf(lm, "Ti", -96.0, -14.0, 2.0, 10.0, 15.0, 13.0, -10.0)
	_loaf(lm, "Ti2", 14.0, 132.0, -10.0, -14.0, 13.0, 17.0, 6.0)
	_loaf(lm, "Ti", -60.0, 20.0, -30.0, -32.0, 10.0, 12.0, 4.0)
	# The tower at the end of the fish gallery, beyond the bridge.
	SEuUtil.blob(lm, "Ti2", Vector3(124.0, 0, -12.0), 6.0, 40.0, 7.0, Vector3(-0.06, 0, 0.04), true, 14, 20)
	# Limestone galleries to the south with their slot windows.
	for b in [[Vector3(30.0, 0, 42.0), Vector3(48.0, 22.0, 26.0)], [Vector3(-34.0, 0, 52.0), Vector3(36.0, 18.0, 22.0)],
			[Vector3(-64.0, 0, 30.0), Vector3(24.0, 14.0, 20.0)]]:
		var bc: Vector3 = b[0]
		var bs: Vector3 = b[1]
		lm.box("Stone", bc + Vector3(0, bs.y * 0.5, 0), bs)
		lm.box("Stone", bc + Vector3(0, bs.y + 0.3, 0), bs + Vector3(0.6, 0.6, 0.6))
		var nw := int(bs.x / 11.0)
		for i in nw:
			var x := bc.x - bs.x * 0.5 + bs.x * (float(i) + 0.5) / float(nw)
			SEuParts.niche(lm, "Stone", "Glass", Vector3(x, 3.0, bc.z + bs.z * 0.5), Vector3(0, 0, 1), 4.0, bs.y - 8.0,
				SEuParts.RECT, 0.3)
	# Atrium curtain walls: glazing with a grid of mullions and transoms.
	for g in [[Vector3(-12.0, 0, 15.0), Vector3(12.0, 0, 15.0), 26.0], [Vector3(-10.0, 0, -18.0), Vector3(8.0, 0, -20.0), 34.0],
			[Vector3(12.0, 0, -4.0), Vector3(16.0, 0, 6.0), 30.0]]:
		var a: Vector3 = g[0]
		var b: Vector3 = g[1]
		var gh: float = g[2]
		var dir := (b - a).normalized()
		var nrm := Vector3.UP.cross(dir)
		lm.quad("Glass", a, b, b + Vector3(0, gh, 0), a + Vector3(0, gh, 0), nrm)
		lm.quad("Glass", b, a, a + Vector3(0, gh, 0), b + Vector3(0, gh, 0), -nrm)
		var nm := int(a.distance_to(b) / 1.8)
		for i in nm + 1:
			var p := a.lerp(b, float(i) / float(nm))
			lm.beam("Ti", p, p + Vector3(0, gh, 0), 0.15, 0.35, dir)
		for j in int(gh / 2.4) + 1:
			lm.beam("Ti", a + Vector3(0, 0.2 + 2.4 * float(j), 0), b + Vector3(0, 0.2 + 2.4 * float(j), 0), 0.12, 0.3, dir)
	# La Salve bridge over the fish gallery, its red arch portal.
	lm.box("Deck", Vector3(62.0, 16.5, -30.0), Vector3(22.0, 1.2, 120.0))
	for s in [-1.0, 1.0]:
		lm.box("Deck", Vector3(62.0 + s * 10.6, 17.6, -30.0), Vector3(0.4, 1.0, 120.0))
		for z in [-80.0, -50.0, 25.0]:
			lm.box("Stone", Vector3(62.0 + s * 8.0, 8.0, float(z)), Vector3(2.2, 16.0, 2.2))
	for s in [-1.0, 1.0]:
		lm.box("Red", Vector3(62.0 + s * 11.0, 14.0, -80.0), Vector3(1.4, 28.0, 1.4))
	lm.box("Red", Vector3(62.0, 27.0, -80.0), Vector3(24.0, 1.6, 1.6))
	lm.box("Red", Vector3(62.0 + 5.0, 22.0, -80.0), Vector3(1.0, 11.0, 1.0), Basis(Vector3.BACK, 0.5))
	lm.box("Red", Vector3(62.0 - 5.0, 22.0, -80.0), Vector3(1.0, 11.0, 1.0), Basis(Vector3.BACK, -0.5))
	# The pond along the river front and Maman on its bank.
	lm.box("Stone", Vector3(-10.0, 0.15, -44.0), Vector3(90.0, 0.3, 14.0))
	lm.box("Water", Vector3(-10.0, 0.32, -44.0), Vector3(88.0, 0.05, 12.0))
	_spider(lm, Vector3(-30.0, 0, -54.0), 9.3)
	_puppy(lm, Vector3(8.0, 0, 46.0))
	lm.commit(model)

## Panel seams over a petal (the titanium skin's courses): rings of
## thin beams following the blob surface.
static func _seams(lm: LandmarkMesh, key: String, c: Vector3, rx: float, ry: float, rz: float, lean: Vector3) -> void:
	for j in 5:
		var lat := PI * 0.49 * float(j + 1) / 6.0
		var y := ry * sin(lat)
		var rr := cos(lat) * 1.006
		var prev := Vector3.ZERO
		for i in 25:
			var a := TAU * float(i) / 24.0
			var p := c + Vector3(cos(a) * rx * rr, y, sin(a) * rz * rr) + lean * y
			if i > 0:
				lm.beam(key, prev, p, 0.12, 0.08)
			prev = p

## A rounded titanium gallery loaf along X: from x0 to x1, its axis
## moving from z0 to z1 with a sideways `bend`, half-width w, height h.
static func _loaf(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float,
		w: float, h: float, bend: float) -> void:
	var rows: Array = []
	var nx := 32
	var nu := 20
	for j in nx + 1:
		var t := float(j) / nx
		var env := pow(sin(PI * t), 0.4)
		var zc := lerpf(z0, z1, t) + bend * sin(PI * t)
		var ww := w * env * (1.0 + 0.18 * sin(t * 7.0))
		var hh := h * env * (1.0 + 0.3 * sin(t * 5.0 + 1.0))
		var row := PackedVector3Array()
		for i in nu + 1:
			var a := PI * float(i) / nu
			var cz := cos(a)
			var sy := sin(a)
			row.append(Vector3(lerpf(x0, x1, t), hh * pow(sy, 0.6), zc + ww * signf(cz) * pow(absf(cz), 0.7)))
		rows.append(row)
	SEuUtil.grid_facing(lm, key, rows, Vector3.UP)

## Louise Bourgeois's Maman: a bronze spider `h` tall, body and egg sac
## slung under eight jointed legs.
static func _spider(lm: LandmarkMesh, c: Vector3, h: float) -> void:
	var body := c + Vector3(0, h * 0.82, 0)
	SEuUtil.blob(lm, "Bronze", body, 1.4, 1.0, 1.8, Vector3.ZERO, false, 6, 10)
	SEuUtil.blob(lm, "Bronze", body + Vector3(0, -1.6, 0.6), 0.9, 1.1, 0.9, Vector3.ZERO, false, 5, 8)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var knee := body + d * h * 0.45 + Vector3(0, h * 0.18, 0)
		var foot := c + d * h * 0.9 + Vector3(0, 0.2, 0)
		lm.beam("Bronze", body + d * 0.8, knee, 0.35, 0.35)
		lm.beam("Bronze", knee, foot, 0.28, 0.28)

## Jeff Koons's Puppy (1992): a 12.4 m West Highland terrier in a skin
## of flowering plants on a stepped base.
static func _puppy(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 0.4, 0), Vector3(14.0, 0.8, 16.0))
	SEuUtil.blob(lm, "Flowers", c + Vector3(0, 0.8, 0), 4.6, 6.0, 5.4, Vector3.ZERO, true, 8, 16)
	SEuUtil.blob(lm, "Flowers", c + Vector3(0, 6.8, 1.6), 3.4, 3.0, 3.6, Vector3.ZERO, false, 8, 14)
	SEuUtil.blob(lm, "Flowers", c + Vector3(0, 9.4, 2.4), 2.8, 2.6, 2.8, Vector3.ZERO, false, 8, 14)
	SEuUtil.blob(lm, "Flowers", c + Vector3(0, 9.0, 5.2), 1.2, 1.0, 1.4, Vector3.ZERO, false, 6, 10)
	for s in [-1.0, 1.0]:
		lm.beam("Flowers", c + Vector3(s * 1.4, 11.4, 2.0), c + Vector3(s * 1.8, 12.6, 1.8), 0.7, 0.4)
		lm.frustum("Flowers", c + Vector3(s * 2.4, 0.8, 3.2), 1.0, 0.9, 2.4, 10)
