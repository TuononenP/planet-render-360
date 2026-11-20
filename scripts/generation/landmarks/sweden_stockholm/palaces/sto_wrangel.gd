extends RefCounted

## Wrangelska palatset (Wrangel Palace, 1650s), Riddarholmen. Origin at the
## OSM footprint centre (57.3 x 52.2 m), main range along +Z, the water side
## toward -X (the registry yaw -12.5 turns +Z onto north, so -X faces the
## Riddarfjärden quay, +X the land side). Four ranges round a court:
## - the water range (x -18.8..-4.3, the full 57.3 m), the north and south
##   wings (z +-14.1..28.65) and a lower east range closing the court;
## - two big round towers bulge out of the water facade at its ends
##   (centres x -18.8, z +-21.35, radius 7.3), each on a dark rusticated
##   stone base about 7.4 m high and ringed by grey string courses, under
##   a bell-shaped green copper dome with a lantern. The north tower
##   (+Z) is the taller, its dome steeper;
## - plastered cream ranges with grey-framed windows in four storeys
##   (small ones in the stone base), a black sheet-metal hip roof with
##   lunette dormers along the water range, chimney stacks, and a square
##   domed pavilion with lantern at the east end of each wing;
## - a stone portal with a stair on the court face of the water range.
##
## Sources: docs/stockholm-landmark-sources.md (way 34590009, 57.3 x 52.2 m,
## 32.5 m with the north tower's finial) and the Commons photos in
## visual-plan/refs/landmarks/wrangel_palace/: quarter.jpg (water facade, the
## two round towers, dormers), front.jpg (court and pavilion domes), side.jpg
## (tower base). Storey heights scaled from quarter.jpg against the 14.5 m
## range depth. Window counts are approximate.

const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const X_W := -18.8
const X_WE := -4.3
const X_E := 26.1
const X_EC := 11.6
const Z_END := 28.65
const Z_CT := 14.1
const EAVE := 22.6
const EAVE_E := 18.7
const PL_W := 7.4
const PL := 3.0
const TOWER_R := 7.3
const TOWER_Z := 21.35
const SILLS := [8.6, 13.7, 18.8]

static func build(model: Node3D) -> void:
	var mats := _materials()
	var lm := Kit.fresh(mats)
	var parts := {
		"lo": Kit.window(mats, "Frame", 1.2, 2.2),
		"hi": Kit.window(mats, "Frame", 1.3, 2.5),
		"small": Kit.window(mats, "Frame", 1.0, 1.4),
		"door": Kit.window(mats, "Stone", 2.2, 3.8, true, 0.3),
		"dormer": _dormer(mats),
	}
	_ranges(lm)
	_windows(lm, parts)
	_towers(lm, parts)
	_roofs(lm, parts)
	_pavilions(lm)
	_portal(lm, parts)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Wall": LandmarkMaterials.pbr("render", "#E3D9BE", 3.0),
		"Dark": LandmarkMaterials.pbr("stone", "#6B6755", 3.0),
		"Stone": LandmarkMaterials.pbr("limestone", "#B9B09C", 2.6),
		"Frame": LandmarkMaterials.pbr("render", "#9AA096", 2.5),
		"Slate": LandmarkMaterials.pbr("slate", "#3A3D3F", 2.5),
		"Copper": LandmarkMaterials.pbr("copper", "#5A8670", 2.0),
		"Glass": LandmarkMaterials.glass("#2A3236"),
		"Gold": LandmarkMaterials.gold(),
		"Brick": LandmarkMaterials.pbr("brick", "#8A5A44", 3.0),
	}

## [cx, cz, w, d, eave height] of each range.
static func _boxes() -> Array:
	return [[(X_W + X_WE) * 0.5, 0.0, X_WE - X_W, Z_END * 2.0, EAVE],
		[(X_WE + X_E) * 0.5, (Z_CT + Z_END) * 0.5, X_E - X_WE, Z_END - Z_CT, EAVE],
		[(X_WE + X_E) * 0.5, -(Z_CT + Z_END) * 0.5, X_E - X_WE, Z_END - Z_CT, EAVE],
		[(X_EC + X_E) * 0.5, 0.0, X_E - X_EC, Z_CT * 2.0, EAVE_E]]

## Plastered walls, the stone base, floor string courses and the eave band.
static func _ranges(lm: LandmarkMesh) -> void:
	for b in _boxes():
		var h: float = b[4]
		FhU.blk(lm, "Wall", b[0], 0.0, b[1], b[2], h, b[3])
		FhU.blk(lm, "Dark", b[0], 0.0, b[1], float(b[2]) + 0.3, PL, float(b[3]) + 0.3)
		for y in [8.0, 13.1, 18.2]:
			if y < h - 1.0:
				FhP.box_band(lm, "Stone", b[0], b[1], b[2], b[3], y, 0.25, 0.12)
		FhP.box_band(lm, "Stone", b[0], b[1], b[2], b[3], h - 0.7, 0.7, 0.4)
	# The taller stone base on the water side, between the towers.
	FhU.blk(lm, "Dark", X_W - 0.1, 0.0, 0.0, 0.3, PL_W, Z_CT * 2.0)
	FhU.blk(lm, "Stone", X_W - 0.05, PL_W, 0.0, 0.32, 0.4, Z_CT * 2.0)

## Window rows on every wall run.
static func _windows(lm: LandmarkMesh, parts: Dictionary) -> void:
	# [a, b, out, bays, sills, skip, ground row?]
	var runs := [
		[Vector3(X_W, 0, -Z_CT), Vector3(X_W, 0, Z_CT), Vector3(-1, 0, 0), 9, SILLS, [], false],
		[Vector3(X_WE, 0, -Z_CT), Vector3(X_WE, 0, Z_CT), Vector3(1, 0, 0), 9, [3.6] + SILLS, [4], true],
		[Vector3(X_W, 0, Z_END), Vector3(X_E, 0, Z_END), Vector3(0, 0, 1), 14, [3.6] + SILLS, [], true],
		[Vector3(X_W, 0, -Z_END), Vector3(X_E, 0, -Z_END), Vector3(0, 0, -1), 14, [3.6] + SILLS, [], true],
		[Vector3(X_WE, 0, Z_CT), Vector3(X_EC, 0, Z_CT), Vector3(0, 0, -1), 5, [3.6] + SILLS, [], true],
		[Vector3(X_WE, 0, -Z_CT), Vector3(X_EC, 0, -Z_CT), Vector3(0, 0, 1), 5, [3.6] + SILLS, [], true],
		[Vector3(X_EC, 0, -Z_CT), Vector3(X_EC, 0, Z_CT), Vector3(-1, 0, 0), 8, [3.6, 8.6, 13.7], [], true],
		[Vector3(X_E, 0, -Z_END), Vector3(X_E, 0, Z_END), Vector3(1, 0, 0), 17, [3.6, 8.6, 13.7], [], true],
	]
	for r in runs:
		for sill in r[4]:
			var key: String = "lo" if float(sill) < 4.0 else "hi"
			Kit.row(lm, parts[key], r[0], r[1], r[2], float(sill), int(r[3]), r[5])
	# Small windows in the water-side stone base.
	Kit.row(lm, parts["small"], Vector3(X_W, 0, -Z_CT), Vector3(X_W, 0, Z_CT), Vector3(-1, 0, 0), 2.6, 9)

## The two round towers: dark base, plastered shaft, string courses,
## cornice, windows, bell dome and lantern. Returns nothing; the north
## tower (+Z) is taller.
static func _towers(lm: LandmarkMesh, parts: Dictionary) -> void:
	for sgn in [-1.0, 1.0]:
		var c := Vector3(X_W, 0.0, float(sgn) * TOWER_Z)
		lm.frustum("Dark", c, TOWER_R + 0.2, TOWER_R + 0.12, PL_W, 32)
		lm.frustum("Stone", c + Vector3(0, PL_W, 0), TOWER_R + 0.3, TOWER_R + 0.3, 0.4, 32)
		lm.frustum("Wall", c + Vector3(0, PL_W + 0.4, 0), TOWER_R, TOWER_R, EAVE - PL_W - 0.4 - 0.7, 32)
		for y in [13.1, 18.2]:
			lm.frustum("Stone", c + Vector3(0, float(y), 0), TOWER_R + 0.12, TOWER_R + 0.12, 0.25, 32)
		lm.lathe("Stone", c + Vector3(0, EAVE - 0.7, 0), PackedVector2Array([Vector2(TOWER_R, 0), Vector2(TOWER_R + 0.45, 0.2),
			Vector2(TOWER_R + 0.6, 0.55), Vector2(TOWER_R + 0.2, 0.7), Vector2(TOWER_R - 0.2, 0.7)]), 32)
		for deg in [-80.0, -48.0, -16.0, 16.0, 48.0, 80.0]:
			var t := deg_to_rad(float(deg))
			var out := Vector3(-cos(t), 0, sin(t))
			var p := c + out * TOWER_R
			Kit.put(lm, parts["small"], Vector3(p.x, 2.6, p.z), out)
			for sill in SILLS:
				Kit.put(lm, parts["hi"], Vector3(p.x, float(sill), p.z), out)
		var north: bool = sgn > 0.0
		var k := 1.1 if north else 0.95
		var prof := PackedVector2Array()
		for q in [[7.9, 0.0], [7.95, 0.3], [7.4, 1.2], [6.6, 2.4], [5.5, 3.4], [4.2, 4.2], [2.9, 4.8], [1.7, 5.2], [1.35, 5.3]]:
			prof.append(Vector2(float(q[0]), float(q[1]) * k))
		Kit.domed_lantern(lm, {}, c + Vector3(0, EAVE - 0.7 + 0.7, 0), prof, 1.4, 0.8, 0.35 if north else 0.2)

## The slate roofs, lunette dormers on the water range, chimney stacks.
static func _roofs(lm: LandmarkMesh, parts: Dictionary) -> void:
	var rise := [[0.0, 0.0], [5.3, 4.4]]
	Kit.hip(lm, "Slate", Vector3((X_W + X_WE) * 0.5, EAVE, 0.0), (X_WE - X_W) * 0.5 + 0.6, Z_END + 0.6, rise)
	for s in [-1.0, 1.0]:
		var cz: float = float(s) * (Z_CT + Z_END) * 0.5
		Kit.hip(lm, "Slate", Vector3((X_WE + 18.3) * 0.5, EAVE, cz), (18.3 - X_WE) * 0.5 + 0.4, (Z_END - Z_CT) * 0.5 + 0.6, rise)
		# East end of the wing: a low roof beside its domed pavilion.
		Kit.hip(lm, "Slate", Vector3(22.2, EAVE, float(s) * 17.5), 4.3, 3.8, [[0.0, 0.0], [3.4, 3.0]])
	Kit.hip(lm, "Slate", Vector3((X_EC + X_E) * 0.5, EAVE_E, 0.0), (X_E - X_EC) * 0.5 + 0.5, Z_CT + 0.5,
		[[0.0, 0.0], [5.3, 3.8]])
	# Lunette dormers on both slopes of the water range.
	for k in 7:
		var z := -10.8 + 3.6 * float(k)
		Kit.put(lm, parts["dormer"], Vector3(-17.6, EAVE + 1.4, z), Vector3(-1, 0, 0))
		Kit.put(lm, parts["dormer"], Vector3(-5.5, EAVE + 1.4, z), Vector3(1, 0, 0))
	for p in [[-11.55, -10.0], [-11.55, 9.0], [-11.55, 0.0], [3.0, 21.4], [3.0, -21.4], [14.0, 21.4], [14.0, -21.4],
			[18.85, 6.0], [18.85, -6.0]]:
		var top := EAVE + 4.4 if float(p[0]) < 15.0 else EAVE_E + 3.8
		FhU.blk(lm, "Brick", float(p[0]), top - 0.2, float(p[1]), 1.4, 2.2, 1.4)
		FhU.blk(lm, "Stone", float(p[0]), top + 2.0, float(p[1]), 1.7, 0.25, 1.7)
	# A small domed lantern over the centre of the water range and the east range.
	var prof := PackedVector2Array([Vector2(1.9, 0), Vector2(1.9, 0.5), Vector2(1.5, 1.4), Vector2(0.9, 2.0), Vector2(0.8, 2.1)])
	Kit.domed_lantern(lm, {}, Vector3(-11.55, EAVE + 4.4, -4.0), prof, 1.0, 0.5, 0.2)

## A lunette dormer facing +Z: plastered cheeks, a slate gable, glass.
static func _dormer(mats: Dictionary) -> LandmarkMesh:
	var p := Kit.fresh(mats)
	p.box("Wall", Vector3(0, 0.6, 0.7), Vector3(1.4, 1.2, 1.4), Basis(), 0.0)
	p.gable("Slate", Vector3(0, 1.2, 0.7), 1.6, 1.6, 0.6, Basis(), 0.0, "Wall")
	p.quad("Glass", Vector3(-0.4, 0.15, 1.42), Vector3(0.4, 0.15, 1.42), Vector3(0.4, 1.0, 1.42),
		Vector3(-0.4, 1.0, 1.42), Vector3(0, 0, 1))
	return p

## Square pavilions at the east end of each wing, under round copper domes.
static func _pavilions(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var c := Vector3(22.2, EAVE, float(s) * 24.75)
		FhU.blk(lm, "Stone", c.x, EAVE, c.z, 8.6, 0.5, 8.6)
		lm.frustum("Wall", c + Vector3(0, 0.5, 0), 3.9, 3.9, 0.8, 16)
		var prof := PackedVector2Array()
		for q in [[4.3, 0.0], [4.35, 0.2], [4.0, 0.8], [3.5, 1.6], [2.8, 2.4], [2.0, 3.0], [1.3, 3.4], [1.1, 3.5]]:
			prof.append(Vector2(float(q[0]), float(q[1])))
		Kit.domed_lantern(lm, {}, c + Vector3(0, 1.3, 0), prof, 1.3, 0.7, 0.3)

## The court portal: stair, arched door, a stone pediment over it.
static func _portal(lm: LandmarkMesh, parts: Dictionary) -> void:
	var x := X_WE
	FhU.steps(lm, "Stone", Vector3(x, 0, 0), Vector3(1, 0, 0), 5.0, 0.4, 0.2, 8)
	Kit.put(lm, parts["door"], Vector3(x, 1.6, 0.0), Vector3(1, 0, 0))
	for s in [-1.0, 1.0]:
		FhU.blk(lm, "Stone", x + 0.2, 1.6, float(s) * 1.9, 0.5, 4.6, 0.5)
	lm.gable("Stone", Vector3(x + 0.4, 6.2, 0.0), 4.8, 0.8, 1.1, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
