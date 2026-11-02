class_name LandmarkSaoCanberra
extends RefCounted

## Parliament House on Canberra's Capital Hill, in true metres. Built
## facing -Z; the registry yaw turns it north-east up the land axis to
## the War Memorial.

const ROOF_Y := 26.0
const MAST_TOP := 107.0
const APEX_Y := 80.0
## Curved walls: chord from z = -WALL_Z to +WALL_Z, closest together at
## the centre (x = +/-WALL_PINCH) and splaying to +/-WALL_END.
const WALL_Z := 200.0
const WALL_PINCH := 24.0
const WALL_END := 95.0
const WALL_PEAK := 27.0
## Perimeter of the grassed hill roof (half extents).
const HILL_RX := 150.0
const HILL_RZ := 195.0
## The hill is centred behind the walls so the foyer stands at its front.
const HILL_CZ := 30.0
const FOYER_Z := -185.0

## Mitchell/Giurgola & Thorp (1988): the building is dug into the hill
## and roofed in lawn. Two curved granite walls 460 m long and 27 m high
## at their peak divide it into the House (east) and Senate (west)
## wings; the four-legged stainless-steel flag mast (81 m, flag 12.8 x
## 6.4 m) stands over the Members' Hall between them, its pole tip
## 107 m above the forecourt. In front: the Great Verandah's white
## marble frame with its 22 columns and glass roof, the foyer, and the
## red-granite forecourt with Michael Nelson Jagamara's mosaic and the
## pools.
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#BFB4A2", 4.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8A4A", 5.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DED0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Steel", LandmarkMaterials.paint("#C8CBCE", 0.4, 0.6))
	lm.use("Flag", LandmarkMaterials.paint("#1E2F6A", 0.6, 0.0))
	lm.use("Granite", LandmarkMaterials.pbr("pavement", "#8A4A36", 3.0))
	_hill(lm)
	for s in [-1.0, 1.0]:
		_curved_wall(lm, float(s))
		_chamber(lm, Vector3(float(s) * 72.0, 0, 10.0))
	_members_hall(lm)
	_foyer(lm)
	_forecourt(lm)
	_flag_mast(lm)
	lm.commit(model)

## Perimeter facade (stone storeys with window bands and piers) under
## the lawn roof, which rises from the eaves to the spine.
static func _hill(lm: LandmarkMesh) -> void:
	lm.frustum("Stone", Vector3(0, 0, HILL_CZ), 1.0, 1.0, 12.0, 64, 0.0, HILL_RX, HILL_RZ)
	for y in [3.2, 7.4]:
		lm.frustum("Glass", Vector3(0, float(y), HILL_CZ), 1.002, 1.002, 2.2, 64, 0.0, HILL_RX, HILL_RZ)
	for i in 96:
		var a := TAU * float(i) / 96.0
		var p := Vector3(cos(a) * HILL_RX, 0, HILL_CZ + sin(a) * HILL_RZ)
		lm.box("Stone", p + Vector3(0, 6.0, 0), Vector3(1.2, 12.0, 1.2), Basis(Vector3.UP, -a))
	lm.frustum("Stone", Vector3(0, 11.6, HILL_CZ), 1.006, 1.006, 0.8, 64, 0.0, HILL_RX, HILL_RZ)
	lm.lathe("Lawn", Vector3(0, 0, HILL_CZ), PackedVector2Array([Vector2(1.0, 12.4), Vector2(0.86, 16.0),
		Vector2(0.66, 19.6), Vector2(0.42, 22.6), Vector2(0.2, 24.6)]), 64, HILL_RX, HILL_RZ, 0.0, true, false)
	# Flat roof of the central spine under the lawn's crown.
	lm.frustum("Stone", Vector3(0, 24.4, HILL_CZ), 0.2, 0.2, 0.4, 32, 0.0, HILL_RX, HILL_RZ)

## x of a curved wall's centreline at z (a circular arc pinched at z=0).
static func _wall_x(z: float) -> float:
	var sag := WALL_END - WALL_PINCH
	var r := (WALL_Z * WALL_Z + sag * sag) / (2.0 * sag)
	return WALL_PINCH + r - sqrt(r * r - z * z)

## One curved granite wall (side s), rising out of the hill toward the
## centre: a battered slab 3 m thick with a coping.
static func _curved_wall(lm: LandmarkMesh, s: float) -> void:
	var steps := 24
	var outer: Array = []
	var inner: Array = []
	var top: Array = []
	for i in steps + 1:
		var z := lerpf(-WALL_Z, WALL_Z, float(i) / float(steps))
		var x := s * _wall_x(z)
		var h := lerpf(WALL_PEAK, 10.0, pow(absf(z) / WALL_Z, 1.5))
		outer.append(PackedVector3Array([Vector3(x + s * 1.8, 0.0, z), Vector3(x + s * 1.5, h, z)]))
		inner.append(PackedVector3Array([Vector3(x - s * 1.5, h, z), Vector3(x - s * 1.8, 0.0, z)]))
		top.append(PackedVector3Array([Vector3(x - s * 1.7, h + 0.6, z), Vector3(x + s * 1.7, h + 0.6, z)]))
	lm.grid("Stone", outer, Vector3(s, 0, 0))
	lm.grid("Stone", inner, Vector3(-s, 0, 0))
	lm.grid("Stone", top, Vector3.UP)
	# Coping edges and end faces.
	for e in [0, steps]:
		var o: PackedVector3Array = outer[e]
		var n: PackedVector3Array = inner[e]
		lm.quad("Stone", o[0], o[1], n[0], n[1], Vector3(0, 0, -1.0 if e == 0 else 1.0))
	for i in steps:
		var a: PackedVector3Array = top[i]
		var b: PackedVector3Array = top[i + 1]
		var oa: PackedVector3Array = outer[i]
		var ob: PackedVector3Array = outer[i + 1]
		lm.quad("Stone", a[1], b[1], ob[1], oa[1], Vector3(s, 0.3, 0))
		var ia: PackedVector3Array = inner[i]
		var ib: PackedVector3Array = inner[i + 1]
		lm.quad("Stone", a[0], b[0], ib[0], ia[0], Vector3(-s, 0.3, 0))

## A chamber roof standing out of the lawn: stone drum with a clerestory
## and a low copper-grey pyramid with its skylight.
static func _chamber(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 20.0, 0), Vector3(34.0, 6.0, 30.0))
	lm.box("Glass", c + Vector3(0, 24.0, 0), Vector3(32.0, 2.0, 28.0), Basis(), 0.0)
	for i in 9:
		var x := -16.0 + 4.0 * float(i)
		for sz in [-1.0, 1.0]:
			lm.box("Stone", c + Vector3(x, 24.0, float(sz) * 14.0), Vector3(0.6, 2.0, 0.6))
	lm.spire("Steel", c + Vector3(0, 25.0, 0), 17.5, 4.5, 4.0)
	lm.box("Glass", c + Vector3(0, 29.6, 0), Vector3(8.0, 0.2, 8.0), Basis(), 0.0)

## Members' Hall under the mast: a glazed pyramid between the walls.
static func _members_hall(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, ROOF_Y - 1.0, 0), Vector3(WALL_PINCH * 2.0 - 4.0, 2.0, 44.0))
	lm.spire("Glass", Vector3(0, ROOF_Y, 0), 16.0, 5.0, 2.0)
	for k in 7:
		var t := float(k) / 6.0
		var hw := lerpf(16.0, 2.0, t)
		lm.frustum("Steel", Vector3(0, ROOF_Y + 5.0 * t, 0), hw * 1.414, hw * 1.414, 0.2, 4, PI * 0.25)

## The marble foyer block, its glazed front and the Great Verandah: a
## white marble frame of 22 square columns in two rows carrying a glass
## roof, with the taller central entrance bay.
static func _foyer(lm: LandmarkMesh) -> void:
	lm.box("Marble", Vector3(0, 9.0, FOYER_Z + 20.0), Vector3(84.0, 18.0, 36.0))
	lm.box("Glass", Vector3(0, 7.0, FOYER_Z + 1.9), Vector3(76.0, 12.0, 0.2), Basis(), 0.0)
	var zf := FOYER_Z - 14.0
	for row in 2:
		var z := zf + 9.0 * float(row)
		for k in 11:
			var x := -40.0 + 8.0 * float(k)
			var h := 22.0 if absf(x) < 5.0 else 18.0
			lm.box("Marble", Vector3(x, h * 0.5, z), Vector3(1.8, h, 1.8))
			lm.box("Marble", Vector3(x, 0.3, z), Vector3(2.4, 0.6, 2.4))
	lm.box("Marble", Vector3(0, 18.6, zf + 4.5), Vector3(82.0, 1.2, 11.0))
	lm.box("Glass", Vector3(0, 19.3, zf + 4.5), Vector3(78.0, 0.2, 8.0), Basis(), 0.0)
	lm.box("Marble", Vector3(0, 22.8, zf + 4.5), Vector3(12.0, 1.6, 11.0))
	lm.box("Marble", Vector3(0, 0.15, zf + 4.5), Vector3(86.0, 0.3, 14.0))

## Forecourt: red granite paving framed by black bands, the circular
## mosaic, the flanking pools and their low curved walls.
static func _forecourt(lm: LandmarkMesh) -> void:
	var zc := FOYER_Z - 50.0
	lm.box("Granite", Vector3(0, 0.1, zc), Vector3(100.0, 0.2, 64.0), Basis(), 0.0)
	for k in 5:
		lm.box("Stone", Vector3(0, 0.21, zc - 28.0 + 14.0 * float(k)), Vector3(100.0, 0.02, 0.8), Basis(), 0.0)
	# Mosaic: concentric rings of granite setts round the central pool.
	for k in 4:
		var r := 2.0 + 1.8 * float(k)
		lm.lathe("Stone" if k % 2 == 0 else "Marble", Vector3(0, 0.2, zc + 6.0), PackedVector2Array([Vector2(r + 0.9, 0.0),
			Vector2(r, 0.04)]), 32)
	lm.lathe("Glass", Vector3(0, 0.22, zc + 6.0), PackedVector2Array([Vector2(1.8, 0.0), Vector2(0.0, 0.02)]), 16)
	for s in [-1.0, 1.0]:
		var x: float = float(s) * 36.0
		lm.box("Stone", Vector3(x, 0.4, zc), Vector3(22.0, 0.8, 40.0))
		lm.box("Glass", Vector3(x, 0.82, zc), Vector3(20.0, 0.04, 38.0), Basis(), 0.0)
		for i in 10:
			var a := PI * (0.15 + 0.7 * float(i) / 9.0)
			var p := Vector3(float(s) * (50.0 + 10.0 * sin(a)), 0.7, zc - 30.0 * cos(a))
			lm.box("Stone", p, Vector3(1.0, 1.4, 6.6), Basis(Vector3.UP, -float(s) * (a - PI * 0.5)))

## The flag mast: four stainless steel legs rising from beside the walls
## to the apex, the pole to 107 m, and the flag near the top.
static func _flag_mast(lm: LandmarkMesh) -> void:
	var feet: Array[Vector3] = []
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			feet.append(Vector3(float(sx) * (_wall_x(28.0) - 3.0), ROOF_Y + 1.0, float(sz) * 28.0))
	var apex := Vector3(0, APEX_Y, 0)
	for f in feet:
		var prev := f
		for k in range(1, 7):
			var t := float(k) / 6.0
			var p := f.lerp(apex, t) + (f - apex).normalized() * Vector3(1, 0, 1) * sin(PI * t) * 2.0
			lm.beam("Steel", prev, p, lerpf(2.4, 1.2, t), lerpf(2.4, 1.2, t))
			prev = p
		lm.box("Steel", f - Vector3(0, 0.5, 0), Vector3(3.6, 1.0, 3.6))
	lm.frustum("Steel", apex - Vector3(0, 2.0, 0), 1.4, 0.9, 4.0, 12)
	lm.frustum("Steel", apex + Vector3(0, 2.0, 0), 0.8, 0.25, MAST_TOP - APEX_Y - 2.0, 12)
	lm.lathe("Steel", Vector3(0, MAST_TOP - 0.4, 0), PackedVector2Array([Vector2(0.4, 0.0), Vector2(0.4, 0.2),
		Vector2(0.0, 0.4)]), 10)
	var fy := MAST_TOP - 1.2
	lm.quad("Flag", Vector3(0.3, fy - 6.4, 0), Vector3(13.1, fy - 6.4, 0.3), Vector3(13.1, fy, 0.3),
		Vector3(0.3, fy, 0), Vector3.BACK)
	lm.quad("Flag", Vector3(0.3, fy, 0), Vector3(13.1, fy, 0.3), Vector3(13.1, fy - 6.4, 0.3),
		Vector3(0.3, fy - 6.4, 0), Vector3.FORWARD)
