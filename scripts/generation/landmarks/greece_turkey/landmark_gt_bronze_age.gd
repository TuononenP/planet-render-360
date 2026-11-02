class_name LandmarkGtBronzeAge
extends RefCounted

## Aegean Bronze Age sites in true metres: the Lion Gate and Treasury of
## Atreus at Mycenae, and the Minoan palace of Knossos with Evans's
## reconstructed red columns.

# --- Mycenae ---------------------------------------------------------------

const MYC_TOP := 9.0

## Lion Gate, origin at the middle of the gate's outer face, front to +Z:
## the 3 m wide doorway under its 4.7 m lintel, the relieving triangle
## with the two lionesses about a column, the conglomerate cyclopean
## walls with the bastion that flanks the approach on the left, and,
## drawn nearer than it lies, the Treasury of Atreus (the grassed beehive
## mound, its dromos and the green-columned facade).
static func lion_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#9D917C", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#C4B696", 2.0))
	lm.use("Mound", LandmarkMaterials.pbr("lawn", "#8F8B5D", 5.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C342B", 2.5))
	lm.use("Green", LandmarkMaterials.pbr("stone", "#6C7B5E", 2.0))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#A8987C", 3.0))
	# Cyclopean wall on both sides of the passage, the bastion, and the
	# masonry over the lintel.
	_masonry(lm, -26.0, -1.5, -7.0, 0.0, 0.0, MYC_TOP, 1)
	_masonry(lm, 1.5, 26.0, -7.0, 0.0, 0.0, MYC_TOP, 2)
	_masonry(lm, -1.5, 1.5, -7.0, 0.0, 4.1, MYC_TOP, 3)
	_masonry(lm, -26.0, -8.0, 0.0, 9.5, 0.0, MYC_TOP, 4)
	for k in 3:
		LandmarkGtUtil.block(lm, "Relief", -2.35, 2.35, 3.1, 4.1, -2.1 - 2.1 * float(k), -2.1 * float(k))
	LandmarkGtUtil.block(lm, "Floor", -1.5, 1.5, 0.0, 0.05, -7.0, 0.0)
	LandmarkGtUtil.block(lm, "Floor", -8.0, 26.0, 0.0, 0.05, 0.0, 9.5)
	# Relieving triangle: the slab with the lionesses and their pillar,
	# standing 0.3 m proud of the courses.
	var rz := 0.3
	lm.tri("Relief", Vector3(-1.5, 4.1, rz), Vector3(1.5, 4.1, rz), Vector3(0, 7.5, rz),
		Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2(0, 0), Vector2(3, 0), Vector2(1.5, -3.4))
	lm.frustum("Wall", Vector3(0, 4.5, rz + 0.1), 0.2, 0.3, 1.6, 10)
	LandmarkGtUtil.block(lm, "Wall", -0.55, 0.55, 6.05, 6.35, rz, rz + 0.4)
	LandmarkGtUtil.block(lm, "Wall", -0.45, 0.45, 4.1, 4.5, rz, rz + 0.4)
	for s in [-1.0, 1.0]:
		lm.beam("Wall", Vector3(s * 1.3, 4.35, rz + 0.3), Vector3(s * 0.55, 5.55, rz + 0.3), 0.3, 0.6, Vector3.BACK)
		lm.beam("Wall", Vector3(s * 0.62, 5.55, rz + 0.3), Vector3(s * 0.45, 6.05, rz + 0.3), 0.3, 0.32, Vector3.BACK)
		lm.beam("Wall", Vector3(s * 0.55, 5.4, rz + 0.3), Vector3(s * 0.32, 4.5, rz + 0.3), 0.3, 0.22, Vector3.BACK)
		lm.beam("Wall", Vector3(s * 1.0, 4.45, rz + 0.3), Vector3(s * 1.3, 5.2, rz + 0.3), 0.3, 0.3, Vector3.BACK)
	_atreus(lm, Vector3(75.0, 0, -40.0))
	lm.commit(model)

## Masonry between the extents: courses 0.8-1.2 m high of blocks 1.3-2.9
## m long with slightly uneven faces, so the cyclopean look survives.
static func _masonry(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, y0: float,
		y1: float, salt: int) -> void:
	var y := y0
	var row := 0
	while y < y1 - 0.01:
		var hh := minf(0.8 + 0.4 * LandmarkGtUtil.hash01(row, salt), y1 - y)
		var x := x0
		var k := 0
		while x < x1 - 0.01:
			var w := minf(1.3 + 1.6 * LandmarkGtUtil.hash01(row * 31 + k, salt + 7), x1 - x)
			if x1 - x - w < 0.8:
				w = x1 - x
			var zf := z1 + 0.18 * (LandmarkGtUtil.hash01(row * 57 + k, salt + 13) - 0.3)
			LandmarkGtUtil.block(lm, "Wall", x, x + w - 0.04, y, y + hh, z0, zf)
			x += w
			k += 1
		y += hh
		row += 1

## Treasury of Atreus at `c` (the mound centre), dromos and facade to +Z.
static func _atreus(lm: LandmarkMesh, c: Vector3) -> void:
	lm.lathe("Mound", c, PackedVector2Array([Vector2(13.5, 0), Vector2(13.2, 3.5), Vector2(12.0, 6.6),
		Vector2(8.5, 8.5), Vector2(3.5, 8.95), Vector2(0, 9.0)]), 28)
	var zf := c.z + 12.0
	# Facade: ashlar either side of the 2.7 x 5.4 m door, the lintel and
	# the dark relieving triangle over it, half columns beside the jambs.
	var cx := c.x
	LandmarkGtUtil.block(lm, "Floor", cx - 3.0, cx + 3.0, 0.0, 0.05, zf, zf + 26.0)
	_masonry(lm, cx - 7.5, cx - 1.35, zf - 1.5, zf, 0.0, MYC_TOP, 21)
	_masonry(lm, cx + 1.35, cx + 7.5, zf - 1.5, zf, 0.0, MYC_TOP, 22)
	LandmarkGtUtil.block(lm, "Relief", cx - 4.0, cx + 4.0, 5.4, 6.5, zf - 1.5, zf + 0.05)
	LandmarkGtUtil.block(lm, "Shadow", cx - 1.35, cx + 1.35, 0.0, 5.4, zf - 1.45, zf - 1.35)
	lm.tri("Shadow", Vector3(cx - 1.6, 6.5, zf + 0.06), Vector3(cx + 1.6, 6.5, zf + 0.06),
		Vector3(cx, 8.7, zf + 0.06), Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2(0, 0),
		Vector2(3.2, 0), Vector2(1.6, -2.2))
	_masonry(lm, cx - 7.5, cx + 7.5, zf - 1.5, zf, 6.5, MYC_TOP, 23)
	for s in [-1.0, 1.0]:
		lm.frustum("Green", Vector3(cx + s * 1.9, 0, zf + 0.35), 0.38, 0.5, 4.6, 12)
		LandmarkGtUtil.block(lm, "Green", cx + s * 1.9 - 0.45, cx + s * 1.9 + 0.45, 4.6, 4.9, zf - 0.1, zf + 0.8)
	# Dromos: ashlar side walls stepping down to the open end.
	for s in [-1.0, 1.0]:
		for k in 12:
			var dlen := 25.0 * (1.0 - float(k) / 12.0)
			LandmarkGtUtil.block(lm, "Wall", cx + s * 3.0 - (1.5 if s < 0.0 else 0.0),
				cx + s * 3.0 + (0.0 if s < 0.0 else 1.5), 0.75 * float(k), 0.75 * float(k + 1),
				zf, zf + dlen + 1.0)

# --- Knossos ---------------------------------------------------------------

const KN_L1 := 4.3
const KN_L2 := 8.6
const KN_L3 := 12.9

## Palace of Knossos, origin at the middle of the Central Court, north
## to -Z: the court with its colonnaded east wing stepping down the
## slope in four terraces, the west wing with its upper hall and portico,
## the north entrance passage with the bull relief and its porch of
## red columns, the two-storey South Propylaeum with horns of
## consecration, the West Court with its granary pits and the Theatral
## Area. y = 0 is the ground at the foot of the east terraces; every
## column is a Minoan one, red, tapering downward, black cushion capital.
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
	# Podium under the court and the west side, paved courts on top.
	LandmarkGtUtil.block(lm, "Gypsum", -86.0, 16.0, 0.0, KN_L1, -54.0, 54.0)
	LandmarkGtUtil.block(lm, "Court", -14.0, 14.0, KN_L1, KN_L1 + 0.04, -26.0, 26.0)
	LandmarkGtUtil.block(lm, "Court", -84.0, -48.0, KN_L1, KN_L1 + 0.04, -14.0, 40.0)
	# East wing: four terraces down the hillside, porticoes on the court.
	_story(lm, 15.0, 58.0, 0.0, KN_L1, -26.0, 38.0)
	_story(lm, 15.0, 46.0, KN_L1, KN_L2, -22.0, 34.0)
	_story(lm, 17.0, 30.0, KN_L2, KN_L3, -12.0, 28.0)
	for k in 13:
		var z := -18.0 + 4.0 * float(k)
		_minoan(lm, Vector3(13.8, KN_L1, z), 3.6)
		lm.box("Dark", Vector3(15.05, KN_L1 + 1.5, z + 2.0), Vector3(0.2, 2.4, 2.0))
	LandmarkGtUtil.block(lm, "Roof", 12.6, 16.0, KN_L2 - 0.7, KN_L2, -20.0, 32.0)
	for k in 9:
		var z2 := -10.0 + 4.5 * float(k)
		_minoan(lm, Vector3(15.8, KN_L2, z2), 3.6)
		lm.box("Dark", Vector3(17.05, KN_L2 + 1.5, z2 + 2.2), Vector3(0.2, 2.4, 2.0))
	LandmarkGtUtil.block(lm, "Roof", 14.6, 18.0, KN_L3 - 0.7, KN_L3, -12.0, 28.0)
	# West wing and its upper hall with the porticoes toward the court.
	_story(lm, -46.0, -15.0, KN_L1, KN_L2, -34.0, 34.0)
	_story(lm, -38.0, -17.0, KN_L2, KN_L3, -18.0, 16.0)
	for k in 6:
		var z3 := -14.0 + 5.6 * float(k)
		_minoan(lm, Vector3(-13.8, KN_L1, z3), 3.6)
		lm.box("Dark", Vector3(-14.95, KN_L1 + 1.5, z3 + 2.8), Vector3(0.2, 2.4, 2.4))
	LandmarkGtUtil.block(lm, "Roof", -15.2, -12.6, KN_L2 - 0.7, KN_L2, -16.0, 16.0)
	for k in 5:
		_minoan(lm, Vector3(-15.8, KN_L2, -12.0 + 6.0 * float(k)), 3.6)
	LandmarkGtUtil.block(lm, "Roof", -17.4, -14.6, KN_L3 - 0.7, KN_L3, -14.0, 14.0)
	# North entrance: the two wings of the passage, its roof, the long
	# porch with three great pillars and the bull relief on the west wall.
	_story(lm, -14.0, -3.5, KN_L1, KN_L2, -36.0, -26.0)
	_story(lm, 3.5, 14.0, KN_L1, KN_L2, -36.0, -26.0)
	LandmarkGtUtil.block(lm, "Roof", -3.5, 3.5, KN_L2 - 0.5, KN_L2, -36.0, -26.0)
	LandmarkGtUtil.block(lm, "Plaster", -9.5, -8.0, KN_L1, KN_L2 + 0.8, -52.0, -36.0)
	LandmarkGtUtil.block(lm, "Plaster", 8.0, 9.5, KN_L1, KN_L2 + 0.8, -52.0, -36.0)
	LandmarkGtUtil.block(lm, "Roof", -9.8, 9.8, KN_L2 + 0.8, KN_L2 + 1.4, -52.0, -36.0)
	for x in [-4.5, 0.0, 4.5]:
		_minoan(lm, Vector3(x, KN_L1, -50.0), 4.9, 0.45)
	_bull(lm, Vector3(-8.0, KN_L1 + 2.2, -43.0))
	# South Propylaeum: two storeys of columns, horns on the parapet.
	_story(lm, -17.0, 11.0, KN_L1, KN_L3, 34.0, 46.0)
	for k in 5:
		var x2 := -12.0 + 5.5 * float(k)
		_minoan(lm, Vector3(x2, KN_L1, 47.2), 3.6)
		_minoan(lm, Vector3(x2, KN_L2, 47.2), 3.6)
		lm.box("Dark", Vector3(x2 + 2.7, KN_L1 + 1.5, 46.05), Vector3(2.4, 2.4, 0.2))
		lm.box("Dark", Vector3(x2 + 2.7, KN_L2 + 1.5, 46.05), Vector3(2.4, 2.4, 0.2))
		for hs in [-1.0, 1.0]:
			lm.beam("Gypsum", Vector3(x2 + 2.7 + hs * 0.35, KN_L3, 45.4), Vector3(x2 + 2.7 + hs * 0.75, KN_L3 + 0.9, 45.4), 0.3, 0.3)
	LandmarkGtUtil.block(lm, "Roof", -17.2, 11.2, KN_L2 - 0.7, KN_L2, 46.0, 49.0)
	LandmarkGtUtil.block(lm, "Roof", -17.2, 11.2, KN_L3 - 0.7, KN_L3, 46.0, 49.0)
	# Theatral Area and the West Court's causeways and granary pits.
	for k in 7:
		LandmarkGtUtil.block(lm, "Gypsum", -44.0, -27.0, KN_L1, KN_L1 + 0.4 * float(k + 1),
			-37.0 - 1.1 * float(k + 1), -37.0 - 1.1 * float(k))
	LandmarkGtUtil.block(lm, "Gypsum", -84.0, -48.0, KN_L1, KN_L1 + 0.12, 8.0, 9.6)
	LandmarkGtUtil.block(lm, "Gypsum", -66.0, -64.4, KN_L1, KN_L1 + 0.12, -14.0, 40.0)
	for p in [Vector2(-76.0, 22.0), Vector2(-70.0, 28.0), Vector2(-76.0, 32.0)]:
		lm.lathe("Gypsum", Vector3(p.x, KN_L1, p.y), PackedVector2Array([Vector2(2.9, 0), Vector2(2.9, 0.9),
			Vector2(2.2, 0.9), Vector2(2.2, 0)]), 16, 1.0, 1.0, 0.0, false, false)
	lm.commit(model)

## A storey block from level y0 to y1 with its flat clay-and-gypsum roof
## slab (0.3 m thick, overhanging 0.25 m).
static func _story(lm: LandmarkMesh, x0: float, x1: float, y0: float, y1: float, z0: float,
		z1: float) -> void:
	LandmarkGtUtil.block(lm, "Plaster", x0, x1, y0, y1 - 0.3, z0, z1)
	LandmarkGtUtil.block(lm, "Roof", x0 - 0.25, x1 + 0.25, y1 - 0.3, y1, z0 - 0.25, z1 + 0.25)

## Minoan column of total height h: red shaft tapering downward, black
## cushion capital and abacus.
static func _minoan(lm: LandmarkMesh, base: Vector3, h: float, r: float = 0.36) -> void:
	var cap := 0.42
	lm.lathe("Red", base, PackedVector2Array([Vector2(r * 0.78, 0), Vector2(r, h - cap)]), 12)
	lm.lathe("Black", base + Vector3(0, h - cap, 0), PackedVector2Array([Vector2(r, 0),
		Vector2(r * 1.45, cap * 0.35), Vector2(r * 1.3, cap * 0.7)]), 12)
	lm.box("Black", base + Vector3(0, h - cap * 0.15, 0), Vector3(r * 3.0, cap * 0.3, r * 3.0))

## The charging bull relief on the passage wall, facing east (+X): `c` is
## the middle of its panel.
static func _bull(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Gypsum", c.x - 0.05, c.x + 0.1, c.y - 1.6, c.y + 1.6, c.z - 3.4, c.z + 3.4)
	var x := c.x + 0.2
	LandmarkGtUtil.block(lm, "Fresco", x - 0.12, x + 0.12, c.y - 0.5, c.y + 0.45, c.z - 1.7, c.z + 1.0)
	LandmarkGtUtil.block(lm, "Fresco", x - 0.12, x + 0.12, c.y - 0.2, c.y + 0.9, c.z + 0.5, c.z + 1.4)
	LandmarkGtUtil.block(lm, "Fresco", x - 0.12, x + 0.12, c.y + 0.2, c.y + 0.7, c.z + 1.4, c.z + 2.3)
	lm.beam("Fresco", Vector3(x, c.y + 0.7, c.z + 2.1), Vector3(x, c.y + 1.2, c.z + 1.9), 0.1, 0.2)
	for lz in [-1.5, -0.9, 0.2, 0.8]:
		LandmarkGtUtil.block(lm, "Fresco", x - 0.12, x + 0.12, c.y - 1.2, c.y - 0.45, c.z + lz, c.z + lz + 0.3)
