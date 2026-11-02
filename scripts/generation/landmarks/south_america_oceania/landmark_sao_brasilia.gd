class_name LandmarkSaoBrasilia
extends RefCounted

## Oscar Niemeyer's Brasília: the hyperboloid Cathedral and the National
## Congress, in true metres.

# --- Cathedral of Brasília ---

const CROWN_H := 40.0
const COLUMNS := 16
const BASE_R := 30.0
## Waist of the hyperboloid: the columns meet a compression ring here.
const WAIST_R := 7.0
const WAIST_Y := 32.0
## Tangential half width of a column.
const COL_HW := 0.85

## Sixteen 90 t boomerang columns of white concrete rising from a 60 m
## ring, each in its own vertical plane, closing to a ring at the waist
## and opening again like fingers to 40 m; the glazed walls between
## them in a mullion grid; the 12 m reflecting pool around the drum
## crossed by the dark entrance tunnel; the oval baptistery, the four
## bronze Evangelists (3 m) by the entrance and the 20 m bell tower
## with its four bells.
static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D9D5CB", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2C5C86"))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#B5B0A6", 4.0))
	lm.use("Pool", LandmarkMaterials.glass("#3B6E86"))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4E4434", 2.0, 0.45, 0.7))
	lm.use("Shadow", LandmarkMaterials.pbr("concrete", "#24272A", 3.0))
	# Plaza, the pool ring with its coping, and the drum's floor ring.
	lm.frustum("Plaza", Vector3.ZERO, 62.0, 62.0, 0.15, 64)
	lm.lathe("Concrete", Vector3(0, 0.15, 0), PackedVector2Array([Vector2(BASE_R + 13.0, 0.0),
		Vector2(BASE_R + 13.0, 0.45), Vector2(BASE_R + 12.4, 0.45), Vector2(BASE_R + 12.4, 0.2)]), 64)
	lm.lathe("Pool", Vector3(0, 0.35, 0), PackedVector2Array([Vector2(BASE_R + 12.4, 0.0),
		Vector2(BASE_R + 0.6, 0.0)]), 64, 1.0, 1.0, 0.0, true, false)
	lm.frustum("Concrete", Vector3(0, 0.15, 0), BASE_R + 0.6, BASE_R + 0.6, 0.5, 64)
	_glass(lm)
	for c in COLUMNS:
		_column(lm, TAU * float(c) / float(COLUMNS))
	lm.frustum("Concrete", Vector3(0, WAIST_Y - 1.2, 0), WAIST_R + 0.6, WAIST_R + 0.4, 1.6, 32)
	lm.lathe("Glass", Vector3(0, WAIST_Y + 0.4, 0), PackedVector2Array([Vector2(WAIST_R, 0.0),
		Vector2(0.0, 1.2)]), 32)
	_entrance(lm)
	_baptistery(lm, Vector3(-30.0, 0.15, 50.0))
	_campanile(lm, Vector3(44.0, 0.15, 42.0))
	lm.commit(model)

## Radius of the column centreline at height y: a hyperbola with its
## waist at WAIST_Y, 30 m at the foot.
static func _col_r(y: float) -> float:
	var k2 := (BASE_R * BASE_R - WAIST_R * WAIST_R) / (WAIST_Y * WAIST_Y)
	return sqrt(WAIST_R * WAIST_R + k2 * (y - WAIST_Y) * (y - WAIST_Y))

## Radial depth of a column at height y: pointed foot, deep fin over
## the lower third, slim at the ring, tapering to the tip.
static func _col_depth(y: float) -> float:
	return LandmarkMesh.profile_at(PackedVector2Array([Vector2(0.0, 0.6), Vector2(5.0, 2.6),
		Vector2(12.0, 3.4), Vector2(22.0, 2.4), Vector2(WAIST_Y, 1.4), Vector2(36.0, 1.0),
		Vector2(CROWN_H, 0.3)]), y)

## One column at azimuth a as a closed tube of four grid faces.
static func _column(lm: LandmarkMesh, a: float) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var t := Vector3(-sin(a), 0, cos(a))
	var steps := 18
	var outer: Array = []
	var inner: Array = []
	var left: Array = []
	var right: Array = []
	for i in steps + 1:
		var y := CROWN_H * float(i) / float(steps)
		var y2 := minf(y + 0.5, CROWN_H)
		var y1 := maxf(y - 0.5, 0.0)
		var c := d * _col_r(y) + Vector3(0, y, 0)
		var tang := (d * _col_r(y2) + Vector3(0, y2, 0) - d * _col_r(y1) - Vector3(0, y1, 0)).normalized()
		var nrm := tang.cross(t).normalized()
		if nrm.dot(d) < 0.0:
			nrm = -nrm
		var hd := _col_depth(y) * 0.5
		var hw := COL_HW * (0.4 if i == steps else 1.0)
		var o0 := c + nrm * hd - t * hw
		var o1 := c + nrm * hd + t * hw
		var i0 := c - nrm * hd - t * hw
		var i1 := c - nrm * hd + t * hw
		# The tilted foot section must not dip under the plaza.
		o0.y = maxf(o0.y, 0.15)
		o1.y = maxf(o1.y, 0.15)
		i0.y = maxf(i0.y, 0.15)
		i1.y = maxf(i1.y, 0.15)
		outer.append(PackedVector3Array([o0, o1]))
		inner.append(PackedVector3Array([i0, i1]))
		left.append(PackedVector3Array([i0, o0]))
		right.append(PackedVector3Array([o1, i1]))
	lm.grid("Concrete", outer, d)
	lm.grid("Concrete", inner, -d)
	lm.grid("Concrete", left, -t)
	lm.grid("Concrete", right, t)
	var tip: PackedVector3Array = outer[steps]
	var tip_i: PackedVector3Array = inner[steps]
	lm.quad("Concrete", tip[0], tip[1], tip_i[1], tip_i[0], Vector3.UP)

## Glass walls between the columns, on the hyperboloid from the floor
## ring to the waist, with ring transoms and a mid mullion per bay.
static func _glass(lm: LandmarkMesh) -> void:
	var rows := 12
	var cols := 64
	var grid_rows: Array = []
	for j in rows + 1:
		var y := 0.65 + (WAIST_Y - 1.2 - 0.65) * float(j) / float(rows)
		var r := _col_r(y) - 0.4
		var row := PackedVector3Array()
		for i in cols + 1:
			var a := TAU * float(i) / float(cols)
			row.append(Vector3(cos(a) * r, y, sin(a) * r))
		grid_rows.append(row)
		if j > 0 and j < rows:
			lm.lathe("Concrete", Vector3(0, y - 0.12, 0), PackedVector2Array([Vector2(r + 0.05, 0.0),
				Vector2(r + 0.3, 0.12), Vector2(r + 0.05, 0.24)]), cols, 1.0, 1.0, 0.0, true, false)
	lm.grid("Glass", grid_rows, Vector3(0, 12.0, 0), true)
	for c in COLUMNS:
		var a := TAU * (float(c) + 0.5) / float(COLUMNS)
		var d := Vector3(cos(a), 0, sin(a))
		var prev := Vector3.ZERO
		for j in 9:
			var y := 0.65 + (WAIST_Y - 1.85) * float(j) / 8.0
			var p := d * (_col_r(y) - 0.25) + Vector3(0, y, 0)
			if j > 0:
				lm.beam("Concrete", prev, p, 0.22, 0.3, d.cross(Vector3.UP))
			prev = p

## The entrance on +Z: a dark tunnel mouth under a concrete canopy
## that crosses the pool, its side walls, and the Evangelists.
static func _entrance(lm: LandmarkMesh) -> void:
	var z0 := BASE_R + 1.0
	var z1 := BASE_R + 24.0
	lm.box("Shadow", Vector3(0, 0.2, (z0 + z1) * 0.5), Vector3(7.0, 0.1, z1 - z0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(float(s) * 4.0, 0.7, (z0 + z1) * 0.5), Vector3(1.0, 1.4, z1 - z0))
	lm.box("Concrete", Vector3(0, 1.6, z0 + 7.5), Vector3(9.0, 0.6, 15.0))
	lm.box("Shadow", Vector3(0, 0.75, z0 + 15.02), Vector3(7.0, 1.1, 0.05), Basis(), 0.0)
	for k in 4:
		var x := -9.0 + 6.0 * float(k)
		var p := Vector3(x, 0.15, BASE_R + 30.0)
		lm.box("Concrete", p + Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 1.2))
		LandmarkKits.statue_figure(lm, "Bronze", p + Vector3(0, 0.5, 0), 3.0, k == 1)

## The baptistery: an oval concrete shell rising just out of the plaza.
static func _baptistery(lm: LandmarkMesh, c: Vector3) -> void:
	var prof := PackedVector2Array()
	for i in 9:
		var a := PI * 0.5 * float(i) / 8.0
		prof.append(Vector2(cos(a), sin(a) * 3.2))
	lm.lathe("Concrete", c, prof, 40, 11.0, 7.5)
	lm.lathe("Glass", c + Vector3(0, 3.2, 0), PackedVector2Array([Vector2(1.6, 0.0), Vector2(0.0, 0.5)]), 16)

## The 20 m campanile: a tapering concrete blade carrying a cross beam
## from which the four bells hang.
static func _campanile(lm: LandmarkMesh, b: Vector3) -> void:
	lm.box("Concrete", b + Vector3(0, 0.3, 0), Vector3(4.0, 0.6, 3.0))
	lm.beam("Concrete", b + Vector3(0, 0.6, 0), b + Vector3(0, 19.2, 0), 1.8, 0.9)
	lm.box("Concrete", b + Vector3(0, 19.6, 0), Vector3(9.0, 0.8, 1.2))
	for k in 4:
		var x := -3.6 + 2.4 * float(k)
		var bell := b + Vector3(x, 17.0, 0)
		lm.beam("Concrete", bell + Vector3(0, 1.4, 0), bell + Vector3(0, 2.2, 0), 0.15, 0.15)
		lm.lathe("Bronze", bell, PackedVector2Array([Vector2(0.75, 0.0), Vector2(0.62, 0.25),
			Vector2(0.45, 0.85), Vector2(0.38, 1.25), Vector2(0.0, 1.4)]), 14)

# --- National Congress of Brazil ---

const TOWER_H := 100.0
const ROOF_Y := 10.0
const FLOORS := 28
const TOWER_L := 45.0
const TOWER_W := 11.5
## Gap between the twin towers (their long faces face north and south).
const TOWER_GAP := 8.0

## The long horizontal platform roofed at the Esplanade level, with the
## Senate's 38 m dome (north) and the Chamber of Deputies' 62 m open
## bowl (south) on its roof, the ramp up to it from the lawn (west),
## the reflecting pool in front, and behind it the twin 28-storey
## office towers (Anexo I) joined by connecting floors.
static func congress(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#E2DFD8", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#1F3340"))
	lm.use("Pool", LandmarkMaterials.pbr("pavement", "#A9A59B", 4.0))
	lm.use("Water", LandmarkMaterials.glass("#3B6E86"))
	_platform(lm)
	_ramp(lm)
	_dome(lm, Vector3(-5.0, ROOF_Y, -52.0))
	_bowl(lm, Vector3(-5.0, ROOF_Y, 52.0), 31.0)
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(40.0, 0, float(s) * (TOWER_GAP + TOWER_W) * 0.5))
	for y in [42.0, 78.0]:
		lm.box("Concrete", Vector3(40.0, float(y), 0), Vector3(16.0, 7.0, TOWER_GAP + 0.4))
		lm.box("Glass", Vector3(40.0, float(y), 0), Vector3(16.3, 5.2, TOWER_GAP - 0.6), Basis(), 0.0)
	lm.commit(model)

## The platform: roof slab with a deep fascia, the glazed walls set
## back under it behind a colonnade of slender elliptical columns, and
## the roof parapet.
static func _platform(lm: LandmarkMesh) -> void:
	var hx := 42.0
	var hz := 116.0
	lm.box("Glass", Vector3(0, (ROOF_Y - 2.0) * 0.5, 0), Vector3(hx * 2.0 - 8.0, ROOF_Y - 2.0, hz * 2.0 - 8.0), Basis(), 0.0)
	lm.box("Concrete", Vector3(0, ROOF_Y - 1.0, 0), Vector3(hx * 2.0, 2.0, hz * 2.0))
	lm.box("Concrete", Vector3(0, 0.25, 0), Vector3(hx * 2.0 - 7.0, 0.5, hz * 2.0 - 7.0))
	# Mullions on the glass and the colonnade round the edge.
	for k in 23:
		var z := -hz + 6.0 + 10.0 * float(k)
		for s in [-1.0, 1.0]:
			lm.box("Concrete", Vector3(float(s) * (hx - 1.2), (ROOF_Y - 2.0) * 0.5, z), Vector3(0.6, ROOF_Y - 2.0, 1.0))
			lm.box("Concrete", Vector3(float(s) * (hx - 4.05), (ROOF_Y - 2.0) * 0.5, z + 5.0),
				Vector3(0.12, ROOF_Y - 2.0, 0.2), Basis(), 0.0)
	for k in 8:
		var x := -hx + 6.0 + 10.4 * float(k)
		for s in [-1.0, 1.0]:
			lm.box("Concrete", Vector3(x, (ROOF_Y - 2.0) * 0.5, float(s) * (hz - 1.2)), Vector3(1.0, ROOF_Y - 2.0, 0.6))
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(float(s) * (hx - 0.2), ROOF_Y + 0.5, 0), Vector3(0.4, 1.0, hz * 2.0))
		lm.box("Concrete", Vector3(0, ROOF_Y + 0.5, float(s) * (hz - 0.2)), Vector3(hx * 2.0, 1.0, 0.4))

## Ramp from the lawn up to the roof (west) with its parapets, and the
## reflecting pool either side.
static func _ramp(lm: LandmarkMesh) -> void:
	var x0 := -42.0
	var x1 := -96.0
	lm.quad("Concrete", Vector3(x0, ROOF_Y, -9), Vector3(x0, ROOF_Y, 9), Vector3(x1, 0.3, 9),
		Vector3(x1, 0.3, -9), Vector3(-ROOF_Y, x0 - x1, 0).normalized())
	for s in [-1.0, 1.0]:
		lm.beam("Concrete", Vector3(x0, ROOF_Y + 0.5, float(s) * 9.2), Vector3(x1, 0.8, float(s) * 9.2), 1.0, 0.4)
		# Ramp side walls down to the ground.
		lm.quad("Concrete", Vector3(x0, ROOF_Y, float(s) * 9.0), Vector3(x1, 0.3, float(s) * 9.0),
			Vector3(x1, 0.0, float(s) * 9.0), Vector3(x0, 0.0, float(s) * 9.0), Vector3(0, 0, float(s)))
		# Pool: a shallow basin with a coping either side of the ramp.
		var zc: float = float(s) * 60.0
		lm.box("Pool", Vector3(-70.0, 0.15, zc), Vector3(50.0, 0.3, 100.0), Basis(), 0.0)
		lm.box("Water", Vector3(-70.0, 0.32, zc), Vector3(48.0, 0.04, 98.0), Basis(), 0.0)

## The Senate dome: a low shell (38 m across, 10 m high) on a ring beam.
static func _dome(lm: LandmarkMesh, c: Vector3) -> void:
	var r := 19.0
	lm.frustum("Concrete", c, r + 0.4, r + 0.3, 0.6, 48)
	var prof := PackedVector2Array()
	for i in 13:
		var a := PI * 0.5 * float(i) / 12.0
		prof.append(Vector2(r * cos(a), 0.6 + 9.4 * sin(a)))
	lm.lathe("Concrete", c, prof, 48)
	lm.lathe("Glass", c + Vector3(0, 9.96, 0), PackedVector2Array([Vector2(1.6, 0.0), Vector2(0.0, 0.1)]), 16)

## The Chamber's open saucer (62 m across, about 10 m high): lit top
## face, outer underside, a thick rim and the short stem it rests on.
static func _bowl(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	var stem := 11.0
	lm.frustum("Concrete", c, stem, stem, 1.0, 40)
	var h := 9.0
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		var rr := lerpf(stem, r, t)
		outer.append(Vector2(rr, 1.0 + h * pow(t, 1.8)))
	for i in 13:
		var t := 1.0 - float(i) / 12.0
		var rr := lerpf(0.0, r - 0.8, t)
		inner.append(Vector2(rr, 1.6 + (h - 0.2) * pow(t, 1.7)))
	lm.lathe("Concrete", c, outer, 64, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Concrete", c, inner, 64, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Concrete", c + Vector3(0, 1.0 + h, 0), PackedVector2Array([Vector2(r, 0.0), Vector2(r + 0.1, 0.6),
		Vector2(r - 0.8, 0.6), Vector2(r - 0.8, 0.4)]), 64, 1.0, 1.0, 0.0, true, false)

## One office slab (45 x 11.5 m, long faces glazed north and south):
## closed concrete end walls, a slab edge band at each of the 28
## floors, vertical mullions on the glass and the roof plant storey.
static func _tower(lm: LandmarkMesh, c: Vector3) -> void:
	var storey := (TOWER_H - 4.0) / float(FLOORS)
	lm.box("Glass", c + Vector3(0, TOWER_H * 0.5, 0), Vector3(TOWER_L - 1.6, TOWER_H, TOWER_W - 0.4), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Concrete", c + Vector3(float(s) * (TOWER_L * 0.5 - 0.6), TOWER_H * 0.5, 0), Vector3(1.2, TOWER_H, TOWER_W))
	lm.box("Concrete", c + Vector3(0, TOWER_H - 2.0, 0), Vector3(TOWER_L, 4.0, TOWER_W))
	for k in FLOORS:
		var y := storey * float(k)
		lm.box("Concrete", c + Vector3(0, y + 0.4, 0), Vector3(TOWER_L - 1.2, 0.8, TOWER_W + 0.2), Basis(), 0.0)
	for side in [-1.0, 1.0]:
		for k in 14:
			var x := -TOWER_L * 0.5 + 1.2 + (TOWER_L - 2.4) * (float(k) + 0.5) / 14.0
			lm.box("Concrete", c + Vector3(x, (TOWER_H - 4.0) * 0.5, float(side) * (TOWER_W * 0.5 - 0.05)),
				Vector3(0.25, TOWER_H - 4.0, 0.3), Basis(), 0.0)
