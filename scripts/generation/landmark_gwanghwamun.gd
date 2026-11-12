class_name LandmarkGwanghwamun
extends RefCounted

## Gwanghwamun, the main gate of Gyeongbokgung (rebuilt in Korean pine
## 2006-2010 to the 1865 design), in true metres (about 19 m to the
## ridge): the granite platform in coursed ashlar pierced by three
## rainbow-arched passages (hongyemun, the king's wider centre arch)
## that run right through it, its crenellated parapet (yeojang), and the
## two-storey timber pavilion of 3 x 2 bays on top — red columns,
## lattice doors, green-and-red dancheong bracket sets (dapo: between
## the columns as well as on them) under each eave, twin rafter layers,
## a skirt roof round the lower storey and the hipped-and-gabled upper
## roof (paljak) with concave tiled slopes, upswept corners, hip ridges
## carrying the japsang guardian figures and ridge-end ornaments. The
## pair of haetae guardians sits in front. Front faces south (+Z).

const TOP_M := 19.0
const BASE := Vector3(35.0, 5.6, 14.0)
## The platform's passages as [centre x, width, crown height] (metres,
## model frame): the stone between them is what a walker meets, the
## passages themselves are open (ViewWalk's gate solids read this).
const ARCHES := [[-9.0, 3.6, 4.0], [0.0, 5.0, 4.6], [9.0, 3.6, 4.0]]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkKoreanRoof.materials(lm)
	_platform(lm)
	# The two-storey pavilion of 3 x 2 bays (LandmarkKoreanRoof) on its
	# granite stylobate.
	var y1 := BASE.y + 0.6
	var low := Vector2(24.0, 9.6)
	lm.box("Granite", Vector3(0, BASE.y + 0.3, 0), Vector3(low.x + 2.0, 0.6, low.y + 2.0))
	LandmarkKoreanRoof.two_storey(lm, y1, low, Vector2(20.0, 6.6), 3.4, 2.6, TOP_M)
	# Haetae guardians on their plinths in front of the gate.
	for s in [-1.0, 1.0]:
		_haetae(lm, Vector3(s * 9.0, 0, BASE.z * 0.5 + 9.0))
	lm.commit(model)

## Granite platform: coursed ashlar with real passages — piers between
## the arches, the vault through the depth, voussoir rings on both
## faces — a moulded band and the crenellated parapet with gun holes.
static func _platform(lm: LandmarkMesh) -> void:
	var hx := BASE.x * 0.5
	var hz := BASE.z * 0.5
	var x0 := -hx
	for a in ARCHES:
		var ax := float(a[0])
		var aw := float(a[1])
		var ah := float(a[2])
		var left := ax - aw * 0.5
		lm.box("Granite", Vector3((x0 + left) * 0.5, BASE.y * 0.5, 0), Vector3(left - x0, BASE.y, BASE.z))
		var spring := ah - aw * 0.5
		lm.box("Granite", Vector3(ax, (ah + BASE.y) * 0.5, 0), Vector3(aw, BASE.y - ah, BASE.z))
		_vault(lm, ax, aw * 0.5, spring, ah, hz)
		lm.box("Granite", Vector3(ax, 0.06, 0), Vector3(aw, 0.12, BASE.z), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			LandmarkDetail.arch(lm, "Granite", Vector3(ax, spring, s * hz), Vector3(0, 0, s), aw, 0.45, 0.15)
		x0 = ax + aw * 0.5
	lm.box("Granite", Vector3((x0 + hx) * 0.5, BASE.y * 0.5, 0), Vector3(hx - x0, BASE.y, BASE.z))
	# Plinth and ashlar course lines.
	lm.box("Granite", Vector3(0, 0.3, 0), Vector3(BASE.x + 0.6, 0.6, BASE.z + 0.6))
	# Course joints on the piers (not across the passages).
	var piers := [[-hx, -10.8], [-7.2, -2.5], [2.5, 7.2], [10.8, hx]]
	for k in range(1, 6):
		var y := 0.95 * k
		for pr in piers:
			var pa := float(pr[0])
			var pb := float(pr[1])
			for s in [-1.0, 1.0]:
				lm.box("Shadow", Vector3((pa + pb) * 0.5, y, s * (hz + 0.005)), Vector3(pb - pa, 0.04, 0.02), Basis(), 0.0)
	lm.box("Granite", Vector3(0, BASE.y - 0.2, 0), Vector3(BASE.x + 0.5, 0.4, BASE.z + 0.5))
	# Parapet: low wall with crenels every 2.2 m and a gun hole in each.
	for s in [-1.0, 1.0]:
		_parapet(lm, Vector3(-hx + 0.3, BASE.y, s * (hz - 0.3)), Vector3(hx - 0.3, BASE.y, s * (hz - 0.3)), Vector3(0, 0, s))
		_parapet(lm, Vector3(s * (hx - 0.3), BASE.y, -hz + 0.9), Vector3(s * (hx - 0.3), BASE.y, hz - 0.9), Vector3(s, 0, 0))

## Half-round vault through the platform: the soffit as a half cylinder
## facing inward and the spandrel fill above it on both faces.
static func _vault(lm: LandmarkMesh, ax: float, r: float, spring: float, crown: float, hz: float) -> void:
	var rows: Array = []
	var segs := 12
	for zz in [-hz, hz]:
		var line := PackedVector3Array()
		for k in segs + 1:
			var t := PI * k / segs
			line.append(Vector3(ax + cos(t) * r, spring + sin(t) * r, float(zz)))
		rows.append(line)
	lm.grid("Shadow", rows, Vector3(ax, spring, 0), true)
	# Square-sided lower passage walls.
	for s in [-1.0, 1.0]:
		lm.quad("Shadow", Vector3(ax + s * r, 0, -hz), Vector3(ax + s * r, 0, hz), Vector3(ax + s * r, spring, hz),
			Vector3(ax + s * r, spring, -hz), Vector3(-s, 0, 0))
	# Spandrels between the arch and the crown block, both faces.
	for zs in [-1.0, 1.0]:
		var z: float = zs * hz
		var n := Vector3(0, 0, zs)
		for k in segs:
			var t0 := PI * k / segs
			var t1 := PI * (k + 1) / segs
			var p0 := Vector3(ax + cos(t0) * r, spring + sin(t0) * r, z)
			var p1 := Vector3(ax + cos(t1) * r, spring + sin(t1) * r, z)
			lm.quad("Granite", p0, p1, Vector3(p1.x, crown, z), Vector3(p0.x, crown, z), n)

## Parapet a-b on the platform edge facing `out`: wall, coping, and
## crenels with a square gun hole.
static func _parapet(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	lm.box("Granite", (a + b) * 0.5 + Vector3(0, 0.45, 0), Vector3(dl, 0.9, 0.6), basis)
	var n := int(dl / 2.2)
	for k in n:
		var p := a.lerp(b, (k + 0.5) / n)
		lm.box("Granite", p + Vector3(0, 1.15, 0), Vector3(1.7, 0.5, 0.6), basis)
		lm.box("Shadow", p + Vector3(0, 0.55, 0) + out * 0.31, Vector3(0.22, 0.22, 0.02), basis, 0.0)
		lm.lathe("Granite", p + Vector3(0, 1.4, 0), PackedVector2Array([Vector2(0.85, 0), Vector2(0.0, 0.3)]),
			4, 1.0, 0.36, PI * 0.25, false)

## A haetae: a seated lion-like guardian on a stone plinth (about 2.5 m
## tall in all) looking out from the gate.
static func _haetae(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Granite", p + Vector3(0, 0.45, 0), Vector3(2.0, 0.9, 3.0))
	var b := p + Vector3(0, 0.9, 0)
	lm.lathe("Granite", b, PackedVector2Array([Vector2(0.7, 0), Vector2(0.75, 0.5), Vector2(0.6, 1.0),
		Vector2(0.45, 1.3)]), 10, 1.0, 1.5)
	lm.lathe("Granite", b + Vector3(0, 1.1, 0.7), PackedVector2Array([Vector2(0.42, 0), Vector2(0.48, 0.3),
		Vector2(0.4, 0.6), Vector2(0.0, 0.75)]), 10)
	lm.box("Granite", b + Vector3(0, 1.4, 1.15), Vector3(0.5, 0.35, 0.3))
	lm.frustum("Granite", b + Vector3(0, 1.8, 0.65), 0.12, 0.02, 0.35, 6)
	for s in [-1.0, 1.0]:
		lm.box("Granite", b + Vector3(s * 0.45, 0.4, 1.0), Vector3(0.3, 0.8, 0.3))
		lm.lathe("Granite", b + Vector3(s * 0.6, 0.2, -0.6), PackedVector2Array([Vector2(0.35, 0), Vector2(0.4, 0.3),
			Vector2(0.0, 0.5)]), 8)
	lm.beam("Granite", b + Vector3(0, 0.3, -1.1), b + Vector3(0, 1.0, -1.5), 0.25, 0.25)
