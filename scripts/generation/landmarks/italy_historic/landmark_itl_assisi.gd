class_name LandmarkItlAssisi
extends RefCounted

## The Basilica of St Francis of Assisi (1228-53) in true metres: a
## double church on the arched substructure of its hillside, built of
## pink and white Subasio stone, with the Sacro Convento beside it.

const FACADE_Z := 36.0
const NAVE_HX := 13.5
const LOWER_TOP := 11.5
const EAVE := 32.0
const TRANS_Z := -22.0
const BAY := 13.0

## Origin on the nave axis in the middle of the church, the upper church
## facade facing +Z (uphill onto the Piazza Superiore), the apse toward
## the valley, the friary on the +X flank; y = 0 at the lower piazza.
## The aisleless upper church of four bays (80 x 50 m over the transept)
## stands on the lower church: semicircular-plan buttresses between tall
## two-light Gothic windows, a transept and a polygonal apse. The facade
## is two zones under a plain gable: the twin Gothic portal below, the
## great rose ringed by the Evangelists' symbols above, an oculus in the
## gable, and the 1754 Benediction loggia at its left. On the left flank
## the lower church's Gothic portal under its Renaissance porch (1487) and
## the Romanesque campanile (finished 1239) beyond the sacristies; the
## friary's tiers of Romanesque arches and buttress piers hold the slope.
static func assisi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDC9B3", 3.0))
	lm.use("Stone2", LandmarkMaterials.pbr("limestone", "#E2CDBB", 3.0))
	lm.use("Facade", LandmarkMaterials.pbr("limestone", "#EDE6D8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DFCF", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A4604A", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#40382F", 3.0))
	_church(lm)
	_facade(lm)
	_lower_portal(lm)
	_campanile(lm, Vector3(-22.0, 0, -6.0))
	_friary(lm)
	lm.commit(model)

## Lower and upper church masses, transept, apse, buttresses, windows.
static func _church(lm: LandmarkMesh) -> void:
	var along := Basis(Vector3.UP, PI * 0.5)
	var nz0 := -34.0
	var nlen := FACADE_Z - nz0
	var nzc := (FACADE_Z + nz0) * 0.5
	lm.box("Stone", Vector3(0, LOWER_TOP * 0.5, nzc - 1.0), Vector3(33.0, LOWER_TOP, nlen + 2.0))
	lm.box("Stone", Vector3(0, LOWER_TOP * 0.5, TRANS_Z), Vector3(54.0, LOWER_TOP, 12.0))
	lm.box("Facade", Vector3(0, (LOWER_TOP + EAVE) * 0.5, nzc), Vector3(NAVE_HX * 2.0, EAVE - LOWER_TOP, nlen))
	lm.gable("Tile", Vector3(0, EAVE, nzc), NAVE_HX * 2.0, nlen, 8.0, Basis(), 0.5, "Facade")
	lm.box("Facade", Vector3(0, (LOWER_TOP + EAVE) * 0.5, TRANS_Z), Vector3(54.0, EAVE - LOWER_TOP, 12.0))
	lm.gable("Tile", Vector3(0, EAVE, TRANS_Z), 12.0, 54.0, 6.0, along, 0.4, "Facade")
	# Eaves cornice on hanging arches along both nave walls.
	for sx in [-1.0, 1.0]:
		var out := Vector3(sx, 0, 0)
		LandmarkItlParts.arch_frieze(lm, "Trim", Vector3(sx * NAVE_HX, EAVE - 0.4, -16.0),
			Vector3(sx * NAVE_HX, EAVE - 0.4, FACADE_Z - 0.6), out, 1.6, 0.9)
		LandmarkItlParts.arch_frieze(lm, "Trim", Vector3(sx * 16.5, LOWER_TOP - 0.4, -16.0),
			Vector3(sx * 16.5, LOWER_TOP - 0.4, FACADE_Z - 0.6), out, 2.0, 1.0)
	# Transept ends: gable eye and a tall window each.
	for sx in [-1.0, 1.0]:
		var out := Vector3(sx, 0, 0)
		LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", Vector3(sx * 27.0, 15.0, TRANS_Z), out, 3.4, 12.0, 2)
		lm.disc("Shadow", Vector3(sx * 27.06, EAVE + 2.6, TRANS_Z), out, 1.2, 14)
		lm.disc("Trim", Vector3(sx * 27.03, EAVE + 2.6, TRANS_Z), out, 1.5, 14)
		for zs in [-1.0, 1.0]:
			lm.box("Facade", Vector3(sx * 27.3, EAVE * 0.5, TRANS_Z + zs * 5.6), Vector3(1.2, EAVE, 1.2))
	# Polygonal apse (upper) on the lower church's round one.
	var ac := Vector3(0, 0, -30.0)
	lm.frustum("Stone", ac, 9.0, 9.0, LOWER_TOP, 16)
	lm.lathe("Facade", ac + Vector3(0, LOWER_TOP, 0), PackedVector2Array([Vector2(8.6, 0),
		Vector2(8.6, EAVE - LOWER_TOP)]), 10, 1.0, 1.0, 0.0, false, false)
	lm.frustum("Tile", ac + Vector3(0, EAVE, 0), 9.0, 0.0, 6.0, 10)
	for i in 10:
		var a := TAU * float(i) / 10.0
		var d := Vector3(cos(a), 0, sin(a))
		if d.z > 0.3:
			continue
		lm.box("Facade", ac + d * 8.9 + Vector3(0, (LOWER_TOP + EAVE) * 0.5 - 1.0, 0), Vector3(1.0, EAVE - LOWER_TOP - 2.0,
			1.4), Basis.looking_at(d))
		var am := TAU * (float(i) + 0.5) / 10.0
		var dm := Vector3(cos(am), 0, sin(am))
		if dm.z < 0.2:
			LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", ac + dm * 8.2 + Vector3(0, 15.0, 0), dm, 2.4, 13.0, 2)
	# Round buttresses between the four nave bays, windows in each bay.
	for sx in [-1.0, 1.0]:
		var out := Vector3(sx, 0, 0)
		for k in 5:
			var z := -16.0 + BAY * float(k)
			if k == 4:
				z = FACADE_Z - 1.6
			var bc := Vector3(sx * (NAVE_HX + 0.6), 0, z)
			lm.lathe("Facade", bc, PackedVector2Array([Vector2(2.6, 0), Vector2(2.5, LOWER_TOP),
				Vector2(2.2, LOWER_TOP + 0.6), Vector2(2.2, EAVE - 3.0), Vector2(1.6, EAVE - 0.6),
				Vector2(0.0, EAVE + 1.6)]), 14)
			lm.frustum("Trim", bc + Vector3(0, LOWER_TOP, 0), 2.6, 2.6, 0.5, 14)
		for k in 4:
			var zc := -16.0 + BAY * (float(k) + 0.5)
			LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", Vector3(sx * NAVE_HX, 16.0, zc), out, 3.6, 13.0, 2)
			# Lower church: small round-headed window per bay.
			if sx < 0.0 or zc > 8.0:
				LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", Vector3(sx * 16.5, 4.0, zc), out, 1.4, 3.6, 1, false)

## The upper church front: corner piers, two zones, portal, rose, gable.
static func _facade(lm: LandmarkMesh) -> void:
	var z := FACADE_Z
	var out := Vector3(0, 0, 1)
	var b0 := LOWER_TOP
	# Corner piers and the two cornices dividing the zones.
	for sx in [-1.0, 1.0]:
		lm.box("Facade", Vector3(sx * (NAVE_HX - 0.4), (b0 + EAVE) * 0.5, z + 0.4), Vector3(1.6, EAVE - b0, 0.8))
		lm.frustum("Facade", Vector3(sx * (NAVE_HX - 0.4), EAVE, z + 0.4), 0.7, 0.0, 2.2, 8)
	for y in [b0 + 10.6, EAVE - 0.4]:
		LandmarkDetail.cornice(lm, "Trim", Vector3(-NAVE_HX + 0.8, y, z), Vector3(NAVE_HX - 0.8, y, z), out, 0.7,
			false)
	lm.box("Trim", Vector3(0, b0 + 0.35, z + 0.4), Vector3(NAVE_HX * 2.0, 0.7, 0.8))
	# Raking cornice of the gable and the gable oculus.
	for sx in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(sx * (NAVE_HX + 0.5), EAVE + 0.2, z + 0.3), Vector3(0, EAVE + 8.3, z + 0.3), 0.7, 0.6,
			Vector3(0, 0, 1))
	_ring(lm, "Trim", Vector3(0, EAVE + 3.4, z + 0.15), out, 1.3, 0.3, 16)
	lm.disc("Shadow", Vector3(0, EAVE + 3.4, z + 0.05), out, 1.15, 16)
	# Twin portal: four orders of colonnettes and pointed archivolts.
	var pw := 6.0
	var spring := b0 + 5.4
	lm.quad("Shadow", Vector3(-pw * 0.5, b0, z + 0.03), Vector3(pw * 0.5, b0, z + 0.03),
		Vector3(pw * 0.5, spring, z + 0.03), Vector3(-pw * 0.5, spring, z + 0.03), out)
	var tympan := LandmarkItlParts.arch_pts(Vector3(0, spring, z + 0.03), Vector3.RIGHT, pw * 0.5, true, 10)
	for k in tympan.size() - 1:
		lm.tri("Facade", Vector3(0, spring, z + 0.04), tympan[k], tympan[k + 1], out, out, out,
			Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
	for o in 4:
		var hw := pw * 0.5 + 0.35 + 0.42 * float(o)
		var dz := 0.15 + 0.25 * float(o)
		for sx in [-1.0, 1.0]:
			lm.frustum("Trim", Vector3(sx * hw, b0, z + dz), 0.17, 0.15, spring - b0, 8)
			lm.box("Trim", Vector3(sx * hw, spring + 0.15, z + dz), Vector3(0.5, 0.3, 0.5), Basis(), 0.0)
		var arc := LandmarkItlParts.arch_pts(Vector3(0, spring + 0.3, z + dz), Vector3.RIGHT, hw, true, 12)
		for k in arc.size() - 1:
			lm.beam("Trim", arc[k], arc[k + 1], 0.4, 0.34, out)
	lm.box("Facade", Vector3(0, b0 + 0.5, z + 1.25), Vector3(pw + 4.4, 1.0, 2.5))
	for sx in [-1.0, 1.0]:
		lm.box("Facade", Vector3(sx * (pw * 0.5 + 2.1), (b0 + spring) * 0.5 + 1.4, z + 0.6),
			Vector3(1.0, spring - b0 + 2.8, 1.2))
	# Trumeau, the two door arches, the small rose in the tympanum.
	lm.frustum("Trim", Vector3(0, b0, z + 0.3), 0.22, 0.2, spring - b0, 8)
	for sx in [-1.0, 1.0]:
		var arc := LandmarkItlParts.arch_pts(Vector3(sx * pw * 0.25, spring - 1.2, z + 0.3), Vector3.RIGHT, pw * 0.25,
			false, 8)
		for k in arc.size() - 1:
			lm.beam("Trim", arc[k], arc[k + 1], 0.3, 0.25, out)
		lm.quad("Facade", Vector3(sx * pw * 0.5, spring - 1.2, z + 0.05), Vector3(sx * 0.2, spring - 1.2, z + 0.05),
			Vector3(sx * 0.2, spring, z + 0.05), Vector3(sx * pw * 0.5, spring, z + 0.05), out)
	_ring(lm, "Trim", Vector3(0, spring + 2.0, z + 0.12), out, 0.9, 0.18, 14)
	lm.disc("Shadow", Vector3(0, spring + 2.0, z + 0.06), out, 0.8, 14)
	_rose(lm, Vector3(0, b0 + 15.6, z), out, 4.0)
	# Evangelists' symbols round the rose.
	for q in 4:
		var a := PI * 0.25 + PI * 0.5 * float(q)
		var p := Vector3(cos(a) * 5.6, b0 + 15.6 + sin(a) * 5.6, z + 0.35)
		SEuUtil.blob(lm, "Trim", p, 0.55, 0.65, 0.3, Vector3.ZERO, false, 5, 10)
		SEuUtil.blob(lm, "Trim", p + Vector3(0, 0.8, 0), 0.25, 0.3, 0.25, Vector3.ZERO, false, 4, 8)
	# Benediction loggia (1754) at the facade's left.
	var lc := Vector3(-NAVE_HX - 3.6, b0, z - 2.2)
	lm.box("Facade", lc + Vector3(0, 4.6, 0), Vector3(7.0, 9.2, 4.4))
	SEuUtil.opening(lm, "Shadow", lc + Vector3(0, 0, 2.26), Vector3.RIGHT, Vector3.UP, 3.6, 6.4)
	LandmarkDetail.arch(lm, "Trim", lc + Vector3(0, 4.6, 2.2), out, 3.6, 0.45, 0.25)
	for sx in [-1.0, 1.0]:
		LandmarkDetail.column(lm, "Trim", lc + Vector3(sx * 2.7, 0, 2.5), 0.3, 6.6, "ionic", 0)
	LandmarkDetail.cornice(lm, "Trim", lc + Vector3(-3.7, 8.4, 2.2), lc + Vector3(3.7, 8.4, 2.2), out, 0.8, true)
	LandmarkDetail.balustrade(lm, "Trim", lc + Vector3(-3.4, 9.2, 2.0), lc + Vector3(3.4, 9.2, 2.0), 1.0, 3.4)

## The great rose: dark eye, moulded outer rings, sixteen radiating
## colonnettes joined by little round arches, a hub.
static func _rose(lm: LandmarkMesh, c: Vector3, out: Vector3, r: float) -> void:
	lm.disc("Shadow", c + out * 0.04, out, r, 24)
	_ring(lm, "Trim", c + out * 0.3, out, r + 0.35, 0.55, 28)
	_ring(lm, "Trim", c + out * 0.45, out, r - 0.15, 0.25, 28)
	_ring(lm, "Trim", c + out * 0.25, out, r * 0.32, 0.25, 16)
	lm.disc("Trim", c + out * 0.3, out, r * 0.2, 12)
	var rt := Vector3.UP.cross(out).normalized()
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := rt * cos(a) + Vector3.UP * sin(a)
		lm.beam("Trim", c + d * r * 0.32 + out * 0.25, c + d * r * 0.78 + out * 0.25, 0.14, 0.2, out)
		# Small arch between this spoke and the next.
		var a1 := TAU * float(i + 1) / 16.0
		var d1 := rt * cos(a1) + Vector3.UP * sin(a1)
		var p0 := c + d * r * 0.78 + out * 0.25
		var p1 := c + d1 * r * 0.78 + out * 0.25
		var mid := c + (d + d1).normalized() * r * 0.9 + out * 0.25
		lm.beam("Trim", p0, mid, 0.12, 0.16, out)
		lm.beam("Trim", mid, p1, 0.12, 0.16, out)

## Flat moulded ring of radius r facing `out`, `w` wide, `seg` pieces.
static func _ring(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, r: float, w: float, seg: int) -> void:
	var rt := Vector3.UP.cross(out).normalized()
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		lm.beam(key, c + (rt * cos(a0) + Vector3.UP * sin(a0)) * r, c + (rt * cos(a1) + Vector3.UP * sin(a1)) * r,
			w * 0.8, w, out)

## Lower church entrance on the left flank: the Gothic double portal with
## a rose over it and two smaller ones, under the Renaissance porch.
static func _lower_portal(lm: LandmarkMesh) -> void:
	var x := -16.5
	var zc := 8.0
	var out := Vector3(-1, 0, 0)
	LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", Vector3(x, 0.4, zc), out, 5.0, 7.6, 2, true, 0.5, 0.45)
	_ring(lm, "Trim", Vector3(x - 0.25, 9.0, zc), out, 1.3, 0.3, 16)
	lm.disc("Shadow", Vector3(x - 0.05, 9.0, zc), out, 1.15, 14)
	for s in [-1.0, 1.0]:
		_ring(lm, "Trim", Vector3(x - 0.2, 8.6, zc + float(s) * 4.2), out, 0.7, 0.2, 12)
		lm.disc("Shadow", Vector3(x - 0.05, 8.6, zc + float(s) * 4.2), out, 0.6, 12)
	# Porch: four Corinthian columns, a round arch on the front, attic.
	var px := x - 4.2
	for s in [-1.0, 1.0]:
		for d in [0.0, 3.4]:
			LandmarkDetail.column(lm, "Trim", Vector3(px + float(d), 0, zc + float(s) * 3.0), 0.3, 4.2, "corinthian", 0)
	lm.box("Facade", Vector3(px + 1.7, 6.3, zc), Vector3(4.4, 4.2, 6.8))
	LandmarkItlUtil.lunette(lm, "Shadow", Vector3(px - 0.52, 4.2, zc), Vector3(0, 0, -1), 5.4)
	LandmarkDetail.arch(lm, "Trim", Vector3(px - 0.55, 4.2, zc), out, 5.6, 0.45, 0.3)
	LandmarkDetail.cornice(lm, "Trim", Vector3(px - 0.5, 8.4, zc + 3.4), Vector3(px - 0.5, 8.4, zc - 3.4), out, 0.6,
		true)
	lm.box("Tile", Vector3(px + 1.7, 9.15, zc), Vector3(4.8, 0.3, 7.4))
	LandmarkItlParts.quoins(lm, "Trim", Vector3(-16.5, 0, FACADE_Z), Vector3(0, 0, -1), Vector3(1, 0, 0), 0.0,
		LOWER_TOP, 0.6)

## Romanesque campanile: square shaft with pilaster strips and hanging-
## arch string courses at each stage, belfry openings above, low pyramid.
static func _campanile(lm: LandmarkMesh, c: Vector3) -> void:
	var hw := 4.3
	var top := 55.0
	LandmarkItlUtil.shaft(lm, "Stone", c, hw, c + Vector3(0, top, 0), hw * 0.95)
	# Sacristies linking it to the transept.
	lm.box("Stone", Vector3(c.x + 1.0, 9.0, (c.z + TRANS_Z + 6.0) * 0.5 - 2.0), Vector3(10.0, 18.0, 8.0))
	lm.gable("Tile", Vector3(c.x + 1.0, 18.0, (c.z + TRANS_Z + 6.0) * 0.5 - 2.0), 10.0, 8.0, 2.0, Basis(), 0.3, "Stone")
	var stages := [12.0, 22.0, 32.0, 41.0, 49.0]
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var n := b * Vector3(0, 0, 1)
		var r := b * Vector3(1, 0, 0)
		for y in stages:
			var yy: float = y
			var w := lerpf(hw, hw * 0.95, yy / top)
			LandmarkItlParts.arch_frieze(lm, "Trim", c + n * w + r * -w + Vector3(0, yy, 0),
				c + n * w + r * w + Vector3(0, yy, 0), n, 1.45, 0.7)
		for s in [-1.0, 1.0]:
			lm.box("Stone", c + n * (hw - 0.05) + r * (hw - 0.45) * float(s) + Vector3(0, top * 0.5, 0),
				Vector3(0.9, top, 0.4), b)
		# Openings: slits low, a single light, paired then triple belfry lights.
		var rows := [[4.0, 1, 0.5, 2.0], [15.0, 1, 0.6, 2.4], [25.0, 1, 1.0, 3.0], [34.0, 2, 1.1, 4.0],
			[42.6, 3, 1.1, 4.2]]
		for row in rows:
			var y: float = row[0]
			var cnt: int = row[1]
			var ww: float = row[2]
			var hh: float = row[3]
			var w := lerpf(hw, hw * 0.95, y / top)
			for i in cnt:
				var s := (float(i) - float(cnt - 1) * 0.5) * (ww + 0.9)
				LandmarkItlParts.gothic_window(lm, "Trim", "Shadow", c + n * w + r * s + Vector3(0, y, 0), n, ww, hh,
					1, false, 0.2, 0.18)
	lm.box("Trim", c + Vector3(0, top + 0.3, 0), Vector3(hw * 2.0 + 0.8, 0.6, hw * 2.0 + 0.8))
	lm.spire("Tile", c + Vector3(0, top + 0.6, 0), hw + 0.3, 3.6)
	SEuUtil.finial(lm, "Trim", c + Vector3(0, top + 4.2, 0), 2.6)

## The Sacro Convento along the north flank and round the apse: tiers of
## Romanesque arches between buttress piers on the valley fronts.
static func _friary(lm: LandmarkMesh) -> void:
	var x0 := 16.5
	var x1 := 34.0
	var z0 := -56.0
	var z1 := 8.0
	var top := 22.0
	lm.box("Stone2", Vector3((x0 + x1) * 0.5, top * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, top, z1 - z0))
	lm.gable("Tile", Vector3((x0 + x1) * 0.5, top, (z0 + z1) * 0.5), x1 - x0, z1 - z0, 3.2, Basis(), 0.5, "Stone2")
	# Wing round behind the apse.
	lm.box("Stone2", Vector3(2.0, 9.0, -50.0), Vector3(29.0, 18.0, 12.0))
	lm.gable("Tile", Vector3(2.0, 18.0, -50.0), 12.0, 29.0, 2.4, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone2")
	# North front: big arches below, two tiers of smaller arcades above.
	_arcade(lm, Vector3(x1, 0, z1), Vector3(x1, 0, z0), 0.0, 10.0, 8, 2.4)
	_arcade(lm, Vector3(x1, 0, z1), Vector3(x1, 0, z0), 10.4, 5.6, 16, 1.6)
	_arcade(lm, Vector3(x1, 0, z1), Vector3(x1, 0, z0), 16.4, 4.4, 16, 1.2)
	# West fronts over the valley.
	_arcade(lm, Vector3(x1, 0, z0), Vector3(x0, 0, z0), 0.0, 10.0, 2, 2.4)
	_arcade(lm, Vector3(x1, 0, z0), Vector3(x0, 0, z0), 10.4, 5.6, 4, 1.6)
	_arcade(lm, Vector3(x1, 0, z0), Vector3(x0, 0, z0), 16.4, 4.4, 4, 1.2)
	_arcade(lm, Vector3(16.5, 0, -56.0), Vector3(-12.5, 0, -56.0), 0.0, 9.0, 4, 2.0)
	_arcade(lm, Vector3(16.5, 0, -56.0), Vector3(-12.5, 0, -56.0), 9.4, 4.8, 8, 1.4)
	# Buttress piers on the north front, stepped back at the string courses.
	for i in 9:
		var z := z1 - 8.0 * float(i)
		lm.box("Stone2", Vector3(x1 + 1.2, 5.0, z), Vector3(2.4, 10.0, 2.2))
		lm.box("Stone2", Vector3(x1 + 0.8, 13.0, z), Vector3(1.6, 6.0, 1.8))
		lm.box("Trim", Vector3(x1 + 1.3, 10.2, z), Vector3(2.8, 0.4, 2.6))
	for y in [10.2, 16.2]:
		lm.box("Trim", Vector3(x1 + 0.3, y, (z0 + z1) * 0.5), Vector3(0.6, 0.4, z1 - z0))
	LandmarkItlParts.arch_frieze(lm, "Trim", Vector3(x1, top - 0.3, z1), Vector3(x1, top - 0.3, z0), Vector3(1, 0, 0),
		1.8, 0.8)

## A tier of `count` arches along a wall from a to b (a, b on the ground
## line of the face), springing from y0 and `h` tall, `depth` reveals.
static func _arcade(lm: LandmarkMesh, a: Vector3, b: Vector3, y0: float, h: float, count: int, depth: float) -> void:
	# Walls run so that (b - a) x up points out of the building.
	var out := (b - a).cross(Vector3.UP).normalized()
	for i in count:
		var p0 := a.lerp(b, float(i) / float(count)) + out * (depth + 0.02)
		var p1 := a.lerp(b, float(i + 1) / float(count)) + out * (depth + 0.02)
		_bay(lm, p0, p1, out, y0, h, depth)

## One arched bay: piers either side, round arch with a dark reveal.
static func _bay(lm: LandmarkMesh, p0: Vector3, p1: Vector3, out: Vector3, y0: float, h: float, depth: float) -> void:
	var w := p0.distance_to(p1)
	var ow := w * 0.68
	var dir := (p1 - p0).normalized()
	var c := (p0 + p1) * 0.5
	var spring := y0 + h - ow * 0.5 - h * 0.08
	var basis := Basis(dir, Vector3.UP, out)
	# Piers.
	for s in [-1.0, 1.0]:
		lm.box("Stone2", c + dir * (w * 0.5 - (w - ow) * 0.25) * float(s) + Vector3(0, y0 + h * 0.5, 0) - out * depth * 0.5,
			Vector3((w - ow) * 0.5, h, depth), basis, 0.0)
	# Spandrel over the arch.
	var pts := LandmarkItlParts.arch_pts(c + Vector3(0, spring, 0), dir, ow * 0.5, false, 6)
	for k in pts.size() - 1:
		var p := pts[k]
		var q := pts[k + 1]
		var top := y0 + h
		lm.quad("Stone2", p, q, Vector3(q.x, top, q.z), Vector3(p.x, top, p.z), out)
		lm.quad("Shadow", p, q, q - out * depth, p - out * depth, (c + Vector3(0, spring, 0) - (p + q) * 0.5).normalized())
	lm.quad("Shadow", c - dir * ow * 0.5 + Vector3(0, y0, 0) - out * depth, c + dir * ow * 0.5 + Vector3(0, y0, 0) - out * depth,
		c + dir * ow * 0.5 + Vector3(0, spring, 0) - out * depth, c - dir * ow * 0.5 + Vector3(0, spring, 0) - out * depth, out)
	# Impost blocks at the springing.
	for p in [pts[0], pts[pts.size() - 1]]:
		lm.box("Trim", (p as Vector3) + out * 0.1 - Vector3(0, 0.15, 0), Vector3(w * 0.12 + 0.3, 0.3, 0.3), basis, 0.0)
