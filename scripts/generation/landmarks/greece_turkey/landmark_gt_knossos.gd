class_name LandmarkGtKnossos
extends RefCounted

## The Minoan palace of Knossos in true metres, origin at the middle of
## the Central Court, north to -Z, east to +X. y = 0 is the ground at
## the foot of the east wing, the court lies a storey higher on the
## hill. Most of the palace is low ruined walls; Evans's reinforced
## concrete restorations of 1905-1930 (ochre plaster, painted timber
## bands, red columns tapering downward with black cushion capitals)
## stand full height.

const KN_L1 := 4.3
const KN_L2 := 8.6
const KN_L3 := 12.9

## Palace of Knossos: the 53 x 28 m Central Court; the west wing with
## the long corridor and its 18 storage magazines (pithoi still in
## place), the gypsum orthostats of the west facade, the Throne Room
## block with Evans's upper floor and the stair up from the court; the
## North Entrance with the restored west bastion and its red-columned
## portico over the charging bull relief, the North Pillar Hall; the
## east wing's Grand Staircase rising three storeys round its light
## well, the Hall of the Double Axes with its pier-and-door partitions
## and the Queen's Megaron; the South Propylaeum with the great horns of
## consecration; the West Court with its raised walkways and three
## kouloures, and the Theatral Area. Everything not restored is a field
## of room walls standing a metre or two.
static func knossos(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D9C297", 3.0))
	lm.use("Gypsum", LandmarkMaterials.pbr("limestone", "#CBBE9E", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#B03F2A", 2.0))
	lm.use("Black", LandmarkMaterials.pbr("concrete", "#2B2521", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#A39580", 3.0))
	lm.use("Court", LandmarkMaterials.pbr("gravel", "#CDBB94", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A3029", 3.0))
	lm.use("Fresco", LandmarkMaterials.pbr("render", "#C46A45", 2.0))
	lm.use("Rubble", LandmarkMaterials.pbr("stone", "#A4977F", 2.5))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#B98A4A", 2.0))
	lm.use("Clay", LandmarkMaterials.pbr("terracotta", "#B07A55", 1.5))
	# The hill under the court and the west wing, paved courts on top.
	LandmarkGtUtil.block(lm, "Gypsum", -86.0, 16.0, 0.0, KN_L1, -54.0, 54.0)
	LandmarkGtUtil.block(lm, "Court", -14.0, 14.0, KN_L1, KN_L1 + 0.04, -26.5, 26.5)
	LandmarkGtUtil.block(lm, "Court", -84.0, -48.0, KN_L1, KN_L1 + 0.04, -36.0, 40.0)
	_west_wing(lm)
	_throne_block(lm)
	_north_entrance(lm)
	_grand_staircase(lm)
	_east_ruins(lm)
	_south(lm)
	_west_court(lm)
	lm.commit(model)

# --- Parts -----------------------------------------------------------------

## Minoan column of total height h on `base`: gypsum base disc, red
## shaft tapering downward, black necking, cushion capital and abacus.
static func _minoan(lm: LandmarkMesh, base: Vector3, h: float, r: float = 0.36) -> void:
	var cap := r * 1.25
	lm.frustum("Gypsum", base, r * 1.35, r * 1.3, 0.12, 16)
	var sb := base + Vector3(0, 0.12, 0)
	var sh := h - cap - 0.12
	lm.lathe("Red", sb, PackedVector2Array([Vector2(r * 0.78, 0), Vector2(r * 0.86, sh * 0.4),
		Vector2(r, sh)]), 16)
	lm.frustum("Black", sb + Vector3(0, sh - 0.12, 0), r * 1.04, r * 1.04, 0.12, 16)
	lm.lathe("Black", sb + Vector3(0, sh, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 1.35, cap * 0.2),
		Vector2(r * 1.5, cap * 0.45), Vector2(r * 1.4, cap * 0.62), Vector2(r * 1.1, cap * 0.7)]), 16)
	lm.box("Black", base + Vector3(0, h - cap * 0.15, 0), Vector3(r * 3.0, cap * 0.3, r * 3.0))

## Ruined rubble walls of a grid of rooms over the extents at level y:
## nx x nz cells, every wall segment 0.7 m thick and standing a random
## 0.6..1 of h; a few segments are missing, as dug.
static func _rooms(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, nx: int, nz: int,
		y: float, h: float, salt: int) -> void:
	var cx := (x1 - x0) / float(nx)
	var cz := (z1 - z0) / float(nz)
	var k := 0
	for i in nx + 1:
		for j in nz:
			k += 1
			if i > 0 and i < nx and LandmarkGtUtil.hash01(k, salt) < 0.22:
				continue
			var hh := h * (0.6 + 0.4 * LandmarkGtUtil.hash01(k, salt + 1))
			var x := x0 + cx * float(i)
			LandmarkGtUtil.block(lm, "Rubble", x - 0.35, x + 0.35, y, y + hh, z0 + cz * float(j), z0 + cz * float(j + 1) - 0.05)
	for j in nz + 1:
		for i in nx:
			k += 1
			if j > 0 and j < nz and LandmarkGtUtil.hash01(k, salt) < 0.22:
				continue
			var hh2 := h * (0.6 + 0.4 * LandmarkGtUtil.hash01(k, salt + 1))
			var z := z0 + cz * float(j)
			LandmarkGtUtil.block(lm, "Rubble", x0 + cx * float(i) + 0.35, x0 + cx * float(i + 1) - 0.35, y, y + hh2, z - 0.35, z + 0.35)

## Storage jar (pithos) 1.6 m tall at `base`: flat foot, swelling body,
## rope-moulding bands and the rolled rim.
static func _pithos(lm: LandmarkMesh, base: Vector3, s: float = 1.0) -> void:
	var prof := PackedVector2Array()
	for v in [Vector2(0.22, 0), Vector2(0.38, 0.3), Vector2(0.5, 0.75), Vector2(0.48, 1.15), Vector2(0.33, 1.45),
			Vector2(0.3, 1.52), Vector2(0.36, 1.58), Vector2(0.26, 1.6)]:
		prof.append((v as Vector2) * s)
	lm.lathe("Clay", base, prof, 12)
	for y in [0.55, 0.9, 1.2]:
		var rr := (0.48 if y < 1.0 else 0.43) * s
		lm.frustum("Clay", base + Vector3(0, y * s, 0), rr + 0.03, rr + 0.03, 0.05, 12)

## Restored wall from a to b in plan (their y is ignored), from y0 up to y1, `t` thick, face
## toward `out`: ochre plaster on a gypsum dado, painted timber bands at
## the given heights and doors / windows as dark recesses with a timber
## lintel, (`openings`: [along, sill, w, h] in metres from a).
static func _restored_wall(lm: LandmarkMesh, pa: Vector3, pb: Vector3, out: Vector3, y0: float, y1: float,
		t: float, bands: Array, openings: Array) -> void:
	var a := Vector3(pa.x, 0, pa.z)
	var b := Vector3(pb.x, 0, pb.z)
	var dir := (b - a).normalized()
	var o := out.normalized()
	var run := a.distance_to(b)
	var bas := Basis(dir, Vector3.UP, o)
	var c0 := a - o * t * 0.5
	# Wall as piers between openings, with full-length spans above / below.
	var cuts: Array = openings.duplicate()
	cuts.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
	var u := 0.0
	for op in cuts:
		var x0: float = float(op[0]) - float(op[2]) * 0.5
		var x1: float = float(op[0]) + float(op[2]) * 0.5
		var s0: float = y0 + float(op[1])
		var s1: float = s0 + float(op[3])
		if x0 > u + 0.01:
			lm.box("Plaster", c0 + dir * (u + x0) * 0.5 + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(x0 - u, y1 - y0, t), bas)
		if s0 > y0 + 0.01:
			lm.box("Plaster", c0 + dir * (x0 + x1) * 0.5 + Vector3(0, (y0 + s0) * 0.5, 0), Vector3(x1 - x0, s0 - y0, t), bas)
		lm.box("Plaster", c0 + dir * (x0 + x1) * 0.5 + Vector3(0, (s1 + y1) * 0.5, 0), Vector3(x1 - x0, y1 - s1, t), bas)
		lm.box("Dark", c0 + dir * (x0 + x1) * 0.5 + Vector3(0, (s0 + s1) * 0.5, 0) - o * t * 0.3,
			Vector3(x1 - x0, s1 - s0, 0.1), bas, 0.0)
		lm.box("Ochre", c0 + dir * (x0 + x1) * 0.5 + Vector3(0, s1 + 0.12, 0) + o * t * 0.5,
			Vector3(x1 - x0 + 0.5, 0.24, 0.12), bas, 0.0)
		u = x1
	if run > u + 0.01:
		lm.box("Plaster", c0 + dir * (u + run) * 0.5 + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(run - u, y1 - y0, t), bas)
	lm.box("Gypsum", a + dir * run * 0.5 + Vector3(0, y0 + 0.45, 0) + o * 0.05, Vector3(run, 0.9, 0.12), bas, 0.0)
	for by in bands:
		lm.box("Ochre", a + dir * run * 0.5 + Vector3(0, float(by), 0) + o * 0.06, Vector3(run, 0.22, 0.14), bas, 0.0)
	lm.box("Roof", a + dir * run * 0.5 + Vector3(0, y1 + 0.15, 0) - o * t * 0.5, Vector3(run + 0.5, 0.3, t + 0.5), bas)

## Horns of consecration `h` tall on `c`, horns spread along `side`.
static func _horns(lm: LandmarkMesh, key: String, c: Vector3, side: Vector3, h: float) -> void:
	var s := side.normalized()
	var bas := Basis(s, Vector3.UP, s.cross(Vector3.UP).normalized())
	lm.box(key, c + Vector3(0, h * 0.15, 0), Vector3(h * 1.3, h * 0.3, h * 0.35), bas)
	for sg in [-1.0, 1.0]:
		var p0: Vector3 = c + s * (h * 0.42 * sg) + Vector3(0, h * 0.28, 0)
		var p1: Vector3 = c + s * (h * 0.52 * sg) + Vector3(0, h * 0.7, 0)
		var p2: Vector3 = c + s * (h * 0.45 * sg) + Vector3(0, h, 0)
		lm.beam(key, p0, p1, h * 0.26, h * 0.28, s)
		lm.beam(key, p1, p2, h * 0.16, h * 0.2, s)
	lm.box(key, c + Vector3(0, h * 0.38, 0), Vector3(h * 0.5, h * 0.18, h * 0.3), bas)

# --- West wing ---------------------------------------------------------------

## The long corridor and the 18 magazines opening off it, pithoi in
## several; the stepped west facade of gypsum orthostats on its plinth;
## the room fields between the magazines and the court.
static func _west_wing(lm: LandmarkMesh) -> void:
	var y := KN_L1
	for x in [-27.0, -24.6]:
		LandmarkGtUtil.block(lm, "Rubble", x - 0.35, x + 0.35, y, y + 2.0, -34.0, 18.0)
	for k in 19:
		var z := -32.0 + 2.6 * float(k)
		LandmarkGtUtil.block(lm, "Rubble", -45.0, -27.35, y, y + 1.6 + 0.4 * LandmarkGtUtil.hash01(k, 5), z - 0.35, z + 0.35)
		if k < 18 and LandmarkGtUtil.hash01(k, 8) > 0.45:
			for p in 3:
				_pithos(lm, Vector3(-30.0 - 2.4 * float(p), y, z + 1.3), 0.9 + 0.15 * LandmarkGtUtil.hash01(k * 3 + p, 4))
	# West facade: plinth, orthostats with set-backs, the wall above.
	for seg in [[-34.0, -22.0, -46.0], [-22.0, -6.0, -46.8], [-6.0, 6.0, -46.0], [6.0, 18.0, -46.8]]:
		var x0: float = seg[2]
		LandmarkGtUtil.block(lm, "Gypsum", x0 - 0.5, x0 + 1.0, y, y + 0.35, seg[0], seg[1])
		var n := int((float(seg[1]) - float(seg[0])) / 1.5)
		for k2 in n:
			var z0: float = float(seg[0]) + (float(seg[1]) - float(seg[0])) * float(k2) / float(n)
			var z1: float = float(seg[0]) + (float(seg[1]) - float(seg[0])) * float(k2 + 1) / float(n)
			LandmarkGtUtil.block(lm, "Gypsum", x0, x0 + 0.45, y + 0.35, y + 1.5, z0 + 0.02, z1 - 0.02)
		LandmarkGtUtil.block(lm, "Rubble", x0 + 0.1, x0 + 1.0, y + 1.5, y + 2.4, seg[0], seg[1])
	_rooms(lm, -24.2, -14.5, 0.0, 26.0, 2, 6, y, 1.8, 11)
	_rooms(lm, -46.0, -27.5, 18.0, 36.0, 4, 3, y, 1.5, 12)

## Throne Room block on the court's west side: four doors from the court
## into the anteroom, the restored upper floor with its three-column
## loggia, and the broad stair climbing beside it from the court.
static func _throne_block(lm: LandmarkMesh) -> void:
	var x0 := -24.0
	var x1 := -14.2
	var z0 := -20.0
	var z1 := -6.0
	# Court front: lower storey with the four doors, upper loggia.
	var doors: Array = []
	for k in 4:
		doors.append([2.5 + 3.0 * float(k), 0.0, 1.6, 2.6])
	_restored_wall(lm, Vector3(x1, KN_L1, z1), Vector3(x1, KN_L1, z0), Vector3.RIGHT, KN_L1, KN_L2, 0.8, [KN_L1 + 3.2], doors)
	_restored_wall(lm, Vector3(x0, KN_L1, z0), Vector3(x1, KN_L1, z0), Vector3.FORWARD, KN_L1, KN_L2, 0.8, [KN_L1 + 3.2],
		[[4.0, 1.4, 1.2, 1.2]])
	_restored_wall(lm, Vector3(x1, KN_L1, z1), Vector3(x0, KN_L1, z1), Vector3.BACK, KN_L1, KN_L2, 0.8, [KN_L1 + 3.2], [])
	_restored_wall(lm, Vector3(x0, KN_L1, z1), Vector3(x0, KN_L1, z0), Vector3.LEFT, KN_L1, KN_L2, 0.8, [KN_L1 + 3.2], [])
	LandmarkGtUtil.block(lm, "Roof", x0, x1, KN_L2 - 0.3, KN_L2, z0, z1)
	# Upper floor: back wall and roof, loggia of three columns to the court.
	_restored_wall(lm, Vector3(x0 + 4.0, KN_L2, z1), Vector3(x0 + 4.0, KN_L2, z0), Vector3.RIGHT, KN_L2, KN_L3 - 0.4, 0.7,
		[KN_L2 + 2.6], [[7.0, 0.0, 1.6, 2.4]])
	for k in 3:
		_minoan(lm, Vector3(x1 - 0.8, KN_L2, z0 + 3.5 + 3.5 * float(k)), 3.6)
	LandmarkGtUtil.block(lm, "Roof", x0 + 3.6, x1, KN_L3 - 0.7, KN_L3 - 0.4, z0, z1)
	LandmarkGtUtil.block(lm, "Ochre", x1 - 1.4, x1 + 0.1, KN_L3 - 1.0, KN_L3 - 0.7, z0, z1)
	# Stair from the court to the upper floor, with its balustrade wall.
	for k in 12:
		var yk := KN_L1 + 0.36 * float(k + 1)
		LandmarkGtUtil.block(lm, "Gypsum", x1 - 1.0 - 0.8 * float(k), x1 + 0.2, KN_L1, yk, z1 + 0.1, z1 + 3.0)
	LandmarkGtUtil.block(lm, "Plaster", x1 - 10.0, x1 + 0.2, KN_L1, KN_L2 + 0.9, z1 + 3.0, z1 + 3.5)
	_minoan(lm, Vector3(x1 - 0.2, KN_L1 + 4.3, z1 + 2.6), 3.2, 0.3)
	_rooms(lm, -24.2, -14.5, -34.0, -20.4, 2, 3, KN_L1, 1.6, 21)

# --- North -------------------------------------------------------------------

## North Entrance passage: the restored west bastion with the portico
## of three red columns over the charging bull relief, the ruined east
## bastion, and the North Pillar Hall of eight square piers.
static func _north_entrance(lm: LandmarkMesh) -> void:
	LandmarkGtUtil.block(lm, "Gypsum", -11.5, -4.0, KN_L1, KN_L1 + 3.0, -45.0, -30.0)
	for k in 10:
		LandmarkGtUtil.block(lm, "Gypsum", -4.15, -3.95, KN_L1 + 0.3, KN_L1 + 2.7, -44.6 + 1.45 * float(k), -43.3 + 1.45 * float(k))
	var py := KN_L1 + 3.0
	_restored_wall(lm, Vector3(-11.5, py, -44.5), Vector3(-11.5, py, -30.5), Vector3.RIGHT, py, py + 4.2, 0.8, [py + 3.4], [])
	_restored_wall(lm, Vector3(-11.5, py, -44.5), Vector3(-4.0, py, -44.5), Vector3.BACK, py, py + 4.2, 0.6, [py + 3.4], [])
	for k in 3:
		_minoan(lm, Vector3(-4.8, py, -42.0 + 4.5 * float(k)), 4.0, 0.42)
	LandmarkGtUtil.block(lm, "Roof", -11.8, -3.9, py + 4.0, py + 4.4, -45.0, -30.0)
	LandmarkGtUtil.block(lm, "Ochre", -4.3, -3.8, py + 3.6, py + 4.0, -45.0, -30.0)
	_bull(lm, Vector3(-11.05, py + 2.1, -37.0))
	# East side of the passage and the pillar hall below it.
	_rooms(lm, 3.5, 14.0, -44.0, -26.5, 2, 3, KN_L1, 1.8, 31)
	for k in 8:
		var pz := -52.5 + 2.4 * float(k % 4)
		var px := -1.4 + (3.4 if k >= 4 else 0.0)
		LandmarkGtUtil.block(lm, "Gypsum", px - 0.55, px + 0.55, KN_L1, KN_L1 + 1.6, pz - 0.55, pz + 0.55)
	LandmarkGtUtil.block(lm, "Rubble", -4.0, 4.0, KN_L1, KN_L1 + 1.4, -54.0, -53.3)
	_rooms(lm, -27.0, -12.0, -52.0, -45.5, 3, 1, KN_L1, 1.4, 33)

## The charging bull relief on the portico's back wall, facing east
## (+X): `c` is the middle of its panel.
static func _bull(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Gypsum", c.x - 0.05, c.x + 0.1, c.y - 1.6, c.y + 1.6, c.z - 3.4, c.z + 3.4)
	var x := c.x + 0.2
	var b := func(y0: float, y1: float, z0: float, z1: float) -> void:
		LandmarkGtUtil.block(lm, "Fresco", x - 0.12, x + 0.12, c.y + y0, c.y + y1, c.z + z0, c.z + z1)
	b.call(-0.5, 0.45, -1.7, 1.0)
	b.call(-0.2, 0.9, 0.5, 1.4)
	b.call(0.2, 0.7, 1.4, 2.3)
	lm.beam("Fresco", Vector3(x, c.y + 0.7, c.z + 2.1), Vector3(x, c.y + 1.2, c.z + 1.9), 0.1, 0.2)
	lm.beam("Fresco", Vector3(x, c.y + 0.7, c.z + 1.7), Vector3(x, c.y + 1.15, c.z + 1.4), 0.1, 0.2)
	lm.beam("Fresco", Vector3(x, c.y + 0.2, c.z - 1.7), Vector3(x, c.y - 0.6, c.z - 2.1), 0.08, 0.12)
	for lz in [-1.5, -0.9, 0.2, 0.8]:
		b.call(-1.2, -0.45, lz, lz + 0.3)

# --- East wing ---------------------------------------------------------------

## Grand Staircase: three storeys (one below the court, one at it, one
## above) round a light well open to the court side; flights of broad
## gypsum steps turning at each landing, red columns on the landings'
## balustrades, the outer walls with their doors and windows, the roof
## parapet with horns of consecration.
static func _grand_staircase(lm: LandmarkMesh) -> void:
	var x0 := 16.0
	var x1 := 32.0
	var z0 := -6.0
	var z1 := 12.0
	var levels := [0.0, KN_L1, KN_L2]
	for i in levels.size():
		var ya: float = levels[i]
		var yb := ya + KN_L1
		var win := [[4.0, 0.0 if i == 0 else 1.0, 1.8, 2.4 if i == 0 else 1.6], [9.0, 0.0, 2.0, 2.6], [14.0, 1.0, 1.8, 1.6]]
		_restored_wall(lm, Vector3(x1, ya, z1), Vector3(x1, ya, z0), Vector3.RIGHT, ya, yb - 0.3, 0.9, [ya + 3.1], win)
		_restored_wall(lm, Vector3(x0, ya, z1), Vector3(x1, ya, z1), Vector3.BACK, ya, yb - 0.3, 0.9, [ya + 3.1],
			[[5.0, 1.0, 1.6, 1.6], [11.0, 1.0, 1.6, 1.6]])
		_restored_wall(lm, Vector3(x1, ya, z0), Vector3(x0, ya, z0), Vector3.FORWARD, ya, yb - 0.3, 0.9, [ya + 3.1],
			[[6.0, 0.0, 1.8, 2.6]])
		if i == 0:
			_restored_wall(lm, Vector3(x0, ya, z0), Vector3(x0, ya, z1), Vector3.LEFT, ya, yb - 0.3, 0.9, [ya + 3.1], [])
		# Floor slab round the light well (x 18..24, z 0..8 open).
		if i > 0:
			LandmarkGtUtil.block(lm, "Roof", x0, x1, ya - 0.3, ya, z0, -0.2)
			LandmarkGtUtil.block(lm, "Roof", x0, x1, ya - 0.3, ya, 8.2, z1)
			LandmarkGtUtil.block(lm, "Roof", 24.2, x1, ya - 0.3, ya, -0.2, 8.2)
		# Flight down the west side of the well and the landing columns.
		if i < 2:
			for k in 12:
				var yk := ya + 0.36 * float(k + 1)
				var zk := 7.8 - 0.65 * float(k)
				LandmarkGtUtil.block(lm, "Gypsum", 16.0, 18.0, ya, yk, zk - 0.65, zk)
			LandmarkGtUtil.block(lm, "Plaster", 18.0, 18.6, ya, yb + 0.9, -0.2, 8.2)
			for k2 in 3:
				_minoan(lm, Vector3(18.3, yb + 0.9, 0.6 + 3.4 * float(k2)), 2.9, 0.3)
	LandmarkGtUtil.block(lm, "Roof", x0, x1, KN_L3 - 0.3, KN_L3, z0, -0.2)
	LandmarkGtUtil.block(lm, "Roof", x0, x1, KN_L3 - 0.3, KN_L3, 8.2, z1)
	LandmarkGtUtil.block(lm, "Roof", 24.2, x1, KN_L3 - 0.3, KN_L3, -0.2, 8.2)
	for s in [z0, z1]:
		LandmarkGtUtil.block(lm, "Plaster", x0, x1, KN_L3, KN_L3 + 0.35, float(s) - 0.3, float(s) + 0.3)
	for k3 in 4:
		_horns(lm, "Gypsum", Vector3(x0 + 2.0 + 4.0 * float(k3), KN_L3 + 0.35, z1), Vector3.RIGHT, 0.65)
	# Hall of the Double Axes beside it: pier-and-door partitions.
	LandmarkGtUtil.block(lm, "Court", 32.0, 46.0, 0.0, 0.04, -4.0, 10.0)
	for z in [-0.5, 5.0]:
		for k4 in 6:
			LandmarkGtUtil.block(lm, "Gypsum", 33.0 + 2.2 * float(k4), 33.7 + 2.2 * float(k4), 0.0, 3.4, z - 0.4, z + 0.4)
		LandmarkGtUtil.block(lm, "Ochre", 32.6, 46.0, 3.4, 3.8, z - 0.45, z + 0.45)
	_restored_wall(lm, Vector3(46.0, 0.0, 10.0), Vector3(46.0, 0.0, -4.0), Vector3.RIGHT, 0.0, 4.0, 0.8, [3.1],
		[[3.0, 0.0, 2.0, 2.6], [7.0, 0.0, 2.0, 2.6], [11.0, 0.0, 2.0, 2.6]])
	_minoan(lm, Vector3(44.0, 0.0, -2.5), 3.6)
	_minoan(lm, Vector3(44.0, 0.0, 8.5), 3.6)

## East wing ruins: the Queen's Megaron and its light well, workshops
## and magazines down the slope, the east bastion with its stepped
## water channel, the court's east portico and the retaining face.
static func _east_ruins(lm: LandmarkMesh) -> void:
	_rooms(lm, 32.0, 44.0, 12.0, 24.0, 3, 3, 0.0, 2.6, 41)
	LandmarkGtUtil.block(lm, "Fresco", 32.6, 43.4, 1.0, 1.9, 23.25, 23.4)
	_rooms(lm, 16.5, 32.0, 14.0, 38.0, 3, 4, 0.0, 2.2, 42)
	_rooms(lm, 16.5, 46.0, -26.0, -7.0, 5, 3, 0.0, 2.0, 43)
	_rooms(lm, 46.0, 56.0, -20.0, 30.0, 2, 6, 0.0, 1.4, 44)
	for k in 10:
		LandmarkGtUtil.block(lm, "Gypsum", 56.0 + 0.5 * float(k), 56.5 + 0.5 * float(k), 0.0, 1.8 - 0.18 * float(k), 12.0, 14.5)
	# Court portico on the east side, over the upper floor of the wing.
	for k2 in 8:
		_minoan(lm, Vector3(14.6, KN_L1, -24.0 + 3.2 * float(k2)), 3.2, 0.32)
	LandmarkGtUtil.block(lm, "Roof", 14.0, 16.0, KN_L1 + 3.2, KN_L1 + 3.6, -25.0, -1.0)

# --- South -------------------------------------------------------------------

## South Propylaeum: restored west wall with the procession fresco,
## the two column bases' red columns under its roof, the south corridor
## and, on the south front, the great horns of consecration.
static func _south(lm: LandmarkMesh) -> void:
	var y := KN_L1
	_restored_wall(lm, Vector3(-18.0, y, 42.0), Vector3(-18.0, y, 28.0), Vector3.RIGHT, y, y + 5.2, 0.9, [y + 3.6], [])
	_restored_wall(lm, Vector3(-6.0, y, 28.0), Vector3(-6.0, y, 42.0), Vector3.LEFT, y, y + 5.2, 0.9, [y + 3.6],
		[[7.0, 0.0, 2.2, 3.0]])
	LandmarkGtUtil.block(lm, "Fresco", -17.5, -17.45, y + 1.0, y + 2.6, 29.0, 41.0)
	for k in 6:
		LandmarkGtUtil.block(lm, "Red", -17.42, -17.38, y + 1.1, y + 2.5, 29.6 + 2.0 * float(k), 30.1 + 2.0 * float(k))
	for z in [32.0, 38.0]:
		_minoan(lm, Vector3(-12.0, y, z), 4.9, 0.42)
	LandmarkGtUtil.block(lm, "Roof", -18.5, -5.5, y + 4.9, y + 5.4, 30.0, 40.0)
	LandmarkGtUtil.block(lm, "Ochre", -18.5, -5.5, y + 4.5, y + 4.9, 39.7, 40.2)
	_rooms(lm, -6.0, 14.0, 27.0, 46.0, 4, 3, y, 1.6, 51)
	_rooms(lm, -46.0, -18.5, 36.0, 50.0, 4, 2, y, 1.4, 52)
	_horns(lm, "Gypsum", Vector3(-2.0, y, 49.0), Vector3.RIGHT, 2.2)

# --- West Court --------------------------------------------------------------

## West Court: raised walkways, the three kouloures (stone-lined pits
## shown as their rims) and the Theatral Area's two flights of steps.
static func _west_court(lm: LandmarkMesh) -> void:
	var y := KN_L1
	LandmarkGtUtil.block(lm, "Gypsum", -84.0, -48.0, y, y + 0.12, 8.0, 9.6)
	LandmarkGtUtil.block(lm, "Gypsum", -66.0, -64.4, y, y + 0.12, -36.0, 40.0)
	LandmarkGtUtil.block(lm, "Gypsum", -48.0, -46.5, y, y + 0.12, -36.0, 18.0)
	for p in [Vector2(-76.0, 22.0), Vector2(-70.0, 28.0), Vector2(-76.0, 32.0)]:
		lm.lathe("Rubble", Vector3(p.x, y, p.y), PackedVector2Array([Vector2(2.9, 0), Vector2(2.9, 0.6),
			Vector2(2.3, 0.6), Vector2(2.3, 0.0)]), 20, 1.0, 1.0, 0.0, false, false)
		lm.disc("Dark", Vector3(p.x, y + 0.05, p.y), Vector3.UP, 2.3, 20)
	for k in 7:
		LandmarkGtUtil.block(lm, "Gypsum", -44.0, -27.0, y, y + 0.4 * float(k + 1),
			-37.0 - 1.1 * float(k + 1), -37.0 - 1.1 * float(k))
	for k2 in 6:
		LandmarkGtUtil.block(lm, "Gypsum", -44.0 - 1.1 * float(k2 + 1), -44.0 - 1.1 * float(k2), y, y + 0.4 * float(k2 + 1),
			-45.0, -37.0)
	LandmarkGtUtil.block(lm, "Gypsum", -84.0, -50.6, y, y + 0.12, -42.0, -40.4)
